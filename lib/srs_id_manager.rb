require "yaml"
require "fileutils"

require_relative "srsgem_project"

# Manages persistent storage of the last-used ID numbers per namespace/prefix
# (e.g. BR, TS, ADR, DIAG, ...). Stored in .srsgem/ids.yml similar to build-number.yml.
#
# Provides a reusable API for both the future `srsgem ids assign` command
# and optional auto-assignment during `srsgem build`.
class SRSIdManager
  IDS_FILENAME = "ids.yml"

  # Supported prefixes (can be extended in future; new prefixes will auto-start at 1)
  DEFAULT_PREFIXES = %w[BR TS BC TC DIAG BGT TGT ADR BDR REF].freeze

  def self.ids_file_path(base_dir = Dir.pwd)
    SRSGemProject.file_path(IDS_FILENAME, base_dir)
  end

  # Loads the last_ids map from disk. Returns a hash like { "BR" => 5, "ADR" => 1 }
  # Returns empty hash if file does not exist.
  def self.load_ids(base_dir = Dir.pwd)
    path = ids_file_path(base_dir)
    return {} unless File.exist?(path)

    begin
      yaml = YAML.load_file(path) || {}
      ids = yaml["last_ids"] || {}
      # Normalize keys to strings
      ids.transform_keys { |k| k.to_s.upcase }
    rescue
      {}
    end
  end

  # Saves the given last_ids hash back to disk.
  def self.save_ids(ids_hash, base_dir = Dir.pwd)
    path = ids_file_path(base_dir)
    dir = File.dirname(path)
    FileUtils.mkdir_p(dir) unless Dir.exist?(dir)

    # Normalize and only keep known or new string keys with integer values
    normalized = {}
    ids_hash.each do |k, v|
      pfx = k.to_s.upcase.sub(/-$/, "")
      normalized[pfx] = v.to_i
    end

    data = { "last_ids" => normalized }
    File.open(path, "w") { |file| file.write(data.to_yaml) }
  end

  # Returns the next full ID string for the prefix (e.g. "BR-7") and
  # immediately persists the incremented counter.
  #
  # If the prefix has never been seen, it starts at 1.
  def self.next_id(prefix, base_dir = Dir.pwd)
    pfx = normalize_prefix(prefix)
    ids = load_ids(base_dir)

    # Seed defaults on first use if completely empty
    if ids.empty? && !File.exist?(ids_file_path(base_dir))
      ids = default_last_ids
    end

    current = ids[pfx] || 0
    next_number = current + 1
    ids[pfx] = next_number

    save_ids(ids, base_dir)
    format_id(pfx, next_number)
  end

  # Returns the last assigned number for the prefix (0 if never assigned).
  def self.last_number(prefix, base_dir = Dir.pwd)
    pfx = normalize_prefix(prefix)
    ids = load_ids(base_dir)
    ids[pfx] || 0
  end

  # Explicitly sets the last used number for a prefix (useful for bootstrapping
  # from existing files that already contain manually assigned IDs).
  def self.set_last(prefix, number, base_dir = Dir.pwd)
    pfx = normalize_prefix(prefix)
    ids = load_ids(base_dir)
    ids[pfx] = number.to_i
    save_ids(ids, base_dir)
    number.to_i
  end

  # Returns a formatted ID string. Currently "PREFIX-N" (no zero padding to
  # match the examples in the stable ID issues). Can be adjusted later.
  def self.format_id(prefix, number)
    pfx = normalize_prefix(prefix)
    "#{pfx}-#{number}"
  end

  # Ensures the ids.yml file exists with default seeds (called implicitly on first next_id
  # or can be called proactively).
  def self.ensure_ids_file(base_dir = Dir.pwd)
    path = ids_file_path(base_dir)
    return if File.exist?(path)

    save_ids(default_last_ids, base_dir)
  end

  # The default map used when creating a fresh ids.yml
  def self.default_last_ids
    DEFAULT_PREFIXES.each_with_object({}) { |p, h| h[p] = 0 }
  end

  private_class_method def self.normalize_prefix(pfx)
    pfx.to_s.upcase.sub(/-$/, "")
  end
end
