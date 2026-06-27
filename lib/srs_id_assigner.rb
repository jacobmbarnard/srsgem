require "fileutils"
require "yaml"

require_relative "srsgem_config"
require_relative "srsgem_project"
require_relative "srs_id_manager"

# Responsible for scanning Markdown source for headers and assigning
# stable/traceable IDs (e.g. BR-7, ADR-12) where missing.
#
# This is the core reusable logic for:
# - the explicit `srsgem ids assign` command (recommended)
# - future optional auto-assign during `srsgem build` (when enabled in config)
#
# Design goals from #47:
# - safe + idempotent (never overwrites existing IDs)
# - respects namespaces/prefixes
# - uses persisted counters from .srsgem/ids.yml (via SRSIdManager)
# - primary for Markdown headers
class SRSIdAssigner
  # Prefix inference rules (keyword in header title or ancestor context -> prefix)
  # Order matters; first match wins. Loosened to catch both section titles and item titles.
  PREFIX_RULES = [
    [/\b(ADR|architectural decision record)/i, "ADR"],
    [/\b(BDR|business decision record)/i, "BDR"],
    [/\b(BR|business requirement|requirement)/i, "BR"],
    [/\b(TS|technical specification|specification)/i, "TS"],
    [/\b(BC|business constraint)/i, "BC"],
    [/\b(TC|technical constraint)/i, "TC"],
    [/\b(BGT|business glossary)/i, "BGT"],
    [/\b(TGT|technical glossary)/i, "TGT"],
    [/\b(REF|reference)/i, "REF"],
    [/\b(DIAG|diagram)/i, "DIAG"], # future for #44, headers in MD that reference
  ].freeze

  DEFAULT_LEVELS = [1, 2, 3].freeze

  # Matches an already-assigned stable ID at the start of a header title.
  # Captures: 1=prefix, 2=number, 3=rest of title
  STABLE_ID_RE = /\A([A-Z]{2,5})-(\d+)[:\s-]?\s*(.*)\z/i

  attr_reader :levels, :changes, :files_modified

  def initialize(levels: nil)
    SRSGemConfig.populate_configs
    @levels = normalize_levels(levels || SRSGemConfig.configs[:auto_assign_levels] || DEFAULT_LEVELS)
    @changes = []
    @files_modified = []
  end

  # Main entry point.
  # Scans project, bootstraps counters from existing IDs, then assigns to missing ones.
  def assign(dry_run: false)
    puts "srsgem ids assign"
    puts "  Target header levels: #{@levels.join(', ')}"
    puts "  (use --dry-run to preview without writing)"
    puts ""

    # 1. Bootstrap: make sure our counters know about any manually/previously assigned IDs
    bootstrap_from_existing_ids

    # 2. Find candidate source files (Markdown)
    md_files = find_markdown_files
    if md_files.empty?
      puts "No Markdown files found to process."
      return
    end

    puts "Scanning #{md_files.size} Markdown file(s)..."

    # 3. Process each file
    md_files.each do |rel_path|
      process_file(rel_path, dry_run: dry_run)
    end

    # 4. Report
    print_summary(dry_run)
  end

  private

  def normalize_levels(lvls)
    Array(lvls).map(&:to_i).select { |n| n >= 1 && n <= 6 }.uniq.sort
  end

  def find_markdown_files
    # Recursive for usefulness (addresses part of open #33 for this feature).
    # Skips build artifacts and obvious non-content.
    Dir.glob("**/*.{md,markdown}")
       .select { |f| File.file?(f) }
       .reject { |f| f.start_with?(".srsgem/") || f =~ %r{/(output|node_modules|vendor)/}i }
       .reject { |f| File.basename(f).downcase.match?(/readme/) }
       .sort
  end

  # First pass: scan everything and push any discovered stable IDs into the counters.
  # This ensures we continue numbering correctly even if some IDs were written by hand.
  def bootstrap_from_existing_ids
    count = 0
    find_markdown_files.each do |file|
      begin
        File.foreach(file) do |line|
          if parsed = parse_header(line)
            _level, title = parsed
            if m = title.match(STABLE_ID_RE)
              prefix = m[1].upcase
              num = m[2].to_i
              current = SRSIdManager.last_number(prefix)
              if num > current
                SRSIdManager.set_last(prefix, num)
                count += 1
              end
            end
          end
        end
      rescue => e
        # non-fatal for a single file
        warn "  Warning: could not read #{file}: #{e}"
      end
    end
    puts "  Bootstrapped counters from #{count} pre-existing ID(s)." if count > 0
  end

  def parse_header(line)
    # Returns [level, title_text] or nil
    # Use (#+) to avoid Ruby regex interpolation issues with #{...}
    return nil unless line =~ /\A(#+)\s+(.*)/
    level = $1.length
    title = $2.strip
    [level, title]
  end

  def process_file(rel_path, dry_run: false)
    full_path = File.expand_path(rel_path)
    lines = File.readlines(full_path)
    file_modified = false
    new_lines = []

    lines.each do |line|
      parsed = parse_header(line)
      unless parsed
        new_lines << line
        next
      end

      level, title = parsed

      unless @levels.include?(level)
        new_lines << line
        next
      end

      if title.match(STABLE_ID_RE)
        # Already has stable ID - leave untouched
        new_lines << line
        next
      end

      # No ID yet at a target level -> assign one
      prefix = infer_prefix(title)
      if prefix.nil?
        # No strong context match; leave it alone (user can add PREFIX manually or adjust rules)
        new_lines << line
        next
      end

      new_id = SRSIdManager.next_id(prefix)
      # Convention: "PREFIX-NNN: Original Title"
      new_title = "#{new_id}: #{title}"
      hashes = "#" * level
      new_line = "#{hashes} #{new_title}\n"   # readlines keeps original line endings; we normalize to \n for simplicity

      new_lines << new_line

      @changes << {
        file: rel_path,
        level: level,
        prefix: prefix,
        old_title: title,
        new_title: new_title,
        id: new_id
      }
      file_modified = true
    end

    if file_modified
      unless dry_run
        File.write(full_path, new_lines.join)
        @files_modified << rel_path
        puts "  Assigned IDs in #{rel_path} (#{@changes.count { |c| c[:file] == rel_path }} new)"
      else
        puts "  [dry-run] Would assign in #{rel_path}"
      end
    end
  end

  # Simple inference: look at the title itself for keywords.
  # Because many placeholder titles contain the section type ("Business Constraint", "Requirement Title"),
  # this catches both container headers and the items beneath them.
  #
  # A more sophisticated version could maintain a context stack while walking headers.
  def infer_prefix(title)
    PREFIX_RULES.each do |regex, prefix|
      return prefix if title =~ regex
    end
    nil
  end

  def print_summary(dry_run)
    assigned = @changes.size
    if assigned == 0
      puts "\nNo new stable IDs were needed (all target headers already had IDs or no matches)."
      return
    end

    puts "\nSummary:"
    puts "  New IDs assigned: #{assigned}"
    if dry_run
      puts "  (dry-run mode - no files were modified)"
    else
      puts "  Files modified: #{@files_modified.size}"
    end

    # Group by prefix for nice output
    by_prefix = @changes.group_by { |c| c[:prefix] }
    by_prefix.keys.sort.each do |pfx|
      ids = by_prefix[pfx].map { |c| c[:id] }.sort
      puts "  #{pfx}: #{ids.join(', ')}"
    end

    puts "\nTip: run `srsgem build` to see them in the generated HTML."
    puts "     (Future: auto-assign can also be enabled via config for `build`.)"
  end
end
