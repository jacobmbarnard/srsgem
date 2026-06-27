require "json"
require "fileutils"

require_relative "srsgem_project"

# Manages persistent storage of the last-used ID numbers per namespace/prefix
# (e.g. BR, TS, ADR, DIAG, ...) and the verbatim ID + header bindings.
# Stored in .srsgem/ids.json (using JSON for better resilience, portability,
# and schema evolution compared to YAML).
#
# Headers are now stored grouped under "headers_by_prefix" (sub-dictionaries keyed
# by prefix). Each sub-dictionary contains:
#   - "prefix": e.g. "ADR"
#   - "full_name": e.g. "Architectural Decision Record"
#   - "ids": array of { "id": "...", "header": "verbatim markdown header text" }
#
# This structure (plus the verbatim headers) supports future linter checks for
# changes that would break traceability.
# The flat load_headers_by_id() is still provided for compatibility.
#
# Provides a reusable API for both `srsgem ids assign` and build-time use.
class SRSIdManager
  IDS_FILENAME = "ids.json"

  # Supported prefixes (can be extended in future; new prefixes will auto-start at 1)
  DEFAULT_PREFIXES = %w[BR TS BC TC DIAG BGT TGT ADR BDR REF].freeze

  # Maps prefix to the full human-readable name of the artifact type.
  # Used when organizing headers_by_prefix for better structure and future tooling/linting.
  PREFIX_FULL_NAMES = {
    "BR" => "Business Requirement",
    "TS" => "Technical Specification",
    "BC" => "Business Constraint",
    "TC" => "Technical Constraint",
    "DIAG" => "Diagram",
    "BGT" => "Business Glossary Term",
    "TGT" => "Technical Glossary Term",
    "ADR" => "Architectural Decision Record",
    "BDR" => "Business Decision Record",
    "REF" => "Reference"
  }.freeze

  def self.ids_file_path(base_dir = Dir.pwd)
    SRSGemProject.file_path(IDS_FILENAME, base_dir)
  end

  # Loads the full ids data. Returns { "last_ids" => {...}, "headers_by_prefix" => {...} }
  # Supports migration from the old flat "headers_by_id" format.
  def self.load_data(base_dir = Dir.pwd)
    path = ids_file_path(base_dir)
    return default_data unless File.exist?(path)

    begin
      json = JSON.parse(File.read(path)) || {}
      last = (json["last_ids"] || {}).transform_keys { |k| k.to_s.upcase }
      hbp = json["headers_by_prefix"] || {}
      if hbp.empty? && json.key?("headers_by_id")
        hbp = migrate_from_headers_by_id(json["headers_by_id"])
      end
      hbp = normalize_headers_by_prefix(hbp)
      { "last_ids" => last, "headers_by_prefix" => hbp }
    rescue
      default_data
    end
  end

  # Loads just the last_ids counters map. { "BR" => 5, "ADR" => 1 }
  # (For backward compatibility of callers.)
  def self.load_ids(base_dir = Dir.pwd)
    load_data(base_dir)["last_ids"]
  end

  # Returns a flat map { "BR-7" => "The verbatim header text here", ... }
  # for convenience and compatibility (built from the grouped headers_by_prefix).
  def self.load_headers_by_id(base_dir = Dir.pwd)
    hbp = load_data(base_dir)["headers_by_prefix"] || {}
    flat = {}
    hbp.each_value do |group|
      (group["ids"] || []).each do |entry|
        id = entry["id"] || entry[:id]
        header = entry["header"] || entry[:header]
        flat[normalize_id(id)] = header.to_s.strip if id
      end
    end
    flat
  end

  # Returns the recorded header text for a given full ID (e.g. "BR-7"), or nil.
  def self.header_for_id(full_id, base_dir = Dir.pwd)
    load_headers_by_id(base_dir)[normalize_id(full_id)]
  end

  def self.default_data
    { "last_ids" => default_last_ids, "headers_by_prefix" => default_headers_by_prefix }
  end

  # Saves only the last_ids portion (preserving any existing headers_by_prefix data).
  def self.save_ids(ids_hash, base_dir = Dir.pwd)
    data = load_data(base_dir)
    normalized = {}
    ids_hash.each do |k, v|
      pfx = k.to_s.upcase.sub(/-$/, "")
      normalized[pfx] = v.to_i
    end
    data["last_ids"] = normalized
    save_data(data, base_dir)
  end

  # Saves the full data structure (last_ids + headers_by_prefix) as pretty JSON
  # for human readability while using a more resilient/portable format.
  def self.save_data(data, base_dir = Dir.pwd)
    path = ids_file_path(base_dir)
    dir = File.dirname(path)
    FileUtils.mkdir_p(dir) unless Dir.exist?(dir)

    last = (data["last_ids"] || {})
    normalized_last = {}
    last.each do |k, v|
      pfx = k.to_s.upcase.sub(/-$/, "")
      normalized_last[pfx] = v.to_i
    end

    hbp = data["headers_by_prefix"] || {}
    normalized_hbp = normalize_headers_by_prefix(hbp)

    out = { "last_ids" => normalized_last, "headers_by_prefix" => normalized_hbp }
    File.open(path, "w") { |file| file.write(JSON.pretty_generate(out) + "\n") }
  end

  # Returns the next full ID string for the prefix (e.g. "BR-7") and
  # immediately persists the incremented counter.
  #
  # If the prefix has never been seen, it starts at 1.
  def self.next_id(prefix, base_dir = Dir.pwd)
    pfx = normalize_prefix(prefix)
    data = load_data(base_dir)
    ids = data["last_ids"]

    # Seed defaults on first use if completely empty
    if ids.empty? && !File.exist?(ids_file_path(base_dir))
      ids = default_last_ids
      data["last_ids"] = ids
    end

    current = ids[pfx] || 0
    next_number = current + 1
    ids[pfx] = next_number

    save_data(data, base_dir)
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

  # Records (idempotently) the verbatim binding of a full ID (e.g. "BR-7") to
  # the exact markdown header text it identifies.
  #
  # The data is stored grouped under headers_by_prefix (by prefix, with full_name
  # and array of id+header entries).
  # Only records if this ID has not been seen before
  # (preserves the original assigned header text for future linter drift detection).
  # Also ensures the corresponding last_ids counter is at least this high.
  def self.record_header_for_id(full_id, header_text, base_dir = Dir.pwd)
    return nil if full_id.to_s.strip.empty?
    norm_id = normalize_id(full_id)
    data = load_data(base_dir)
    hbp = data["headers_by_prefix"] ||= {}

    pfx = norm_id.split("-").first
    group = hbp[pfx] ||= init_prefix_group(pfx)
    ids_array = group["ids"] ||= []

    if ids_array.any? { |e| (e["id"] || e[:id]) == norm_id }
      # Already recorded: do not overwrite (preserve original verbatim header)
      return norm_id
    end

    ids_array << { "id" => norm_id, "header" => header_text.to_s.strip }

    # Bump last_ids if this number is higher
    if (m = norm_id.match(/\A([A-Z0-9]+)-(\d+)\z/))
      pfx = m[1]
      num = m[2].to_i
      last = data["last_ids"][pfx] || 0
      if num > last
        data["last_ids"][pfx] = num
      end
    end

    save_data(data, base_dir)
    norm_id
  end

  # Returns a formatted ID string. Currently "PREFIX-N" (no zero padding to
  # match the examples in the stable ID issues). Can be adjusted later.
  def self.format_id(prefix, number)
    pfx = normalize_prefix(prefix)
    "#{pfx}-#{number}"
  end

  def self.init_prefix_group(prefix)
    pfx = normalize_prefix(prefix)
    {
      "prefix" => pfx,
      "full_name" => PREFIX_FULL_NAMES[pfx] || pfx,
      "ids" => []
    }
  end

  def self.default_headers_by_prefix
    DEFAULT_PREFIXES.each_with_object({}) { |p, h| h[p] = init_prefix_group(p) }
  end

  # Migrate legacy flat headers_by_id into the grouped headers_by_prefix structure.
  def self.migrate_from_headers_by_id(old_flat)
    groups = {}
    old_flat.each do |id_str, header|
      norm_id = normalize_id(id_str)
      pfx = norm_id.split("-").first
      groups[pfx] ||= init_prefix_group(pfx)
      groups[pfx]["ids"] << { "id" => norm_id, "header" => header.to_s.strip }
    end
    groups
  end

  # Ensure the headers_by_prefix structure is complete and normalized.
  # Adds any missing prefixes from DEFAULT, normalizes keys/entries, sorts ids.
  def self.normalize_headers_by_prefix(groups)
    groups = (groups || {}).transform_keys { |k| normalize_prefix(k) }

    DEFAULT_PREFIXES.each do |p|
      groups[p] ||= init_prefix_group(p)
      g = groups[p]
      g["prefix"] ||= p
      g["full_name"] ||= PREFIX_FULL_NAMES[p] || p
      g["ids"] ||= []

      g["ids"] = g["ids"].map do |e|
        if e.is_a?(Hash) || e.is_a?(Array) # handle old possible formats
          iid = e["id"] || e[:id] || (e[0] if e.is_a?(Array))
          ihdr = e["header"] || e[:header] || (e[1] if e.is_a?(Array))
          { "id" => normalize_id(iid), "header" => ihdr.to_s.strip }
        else
          { "id" => normalize_id(e), "header" => "" }
        end
      end

      # Sort by numeric ID for determinism
      g["ids"].sort_by! { |e| (e["id"].split("-").last || "0").to_i }
    end

    groups
  end

  # Ensures the ids.json file exists with default seeds (called implicitly on first next_id
  # or can be called proactively).
  def self.ensure_ids_file(base_dir = Dir.pwd)
    path = ids_file_path(base_dir)
    return if File.exist?(path)

    save_data(default_data, base_dir)
  end

  # The default last_ids map used when creating a fresh ids.json
  def self.default_last_ids
    DEFAULT_PREFIXES.each_with_object({}) { |p, h| h[p] = 0 }
  end

  def self.normalize_id(id)
    id.to_s.strip.upcase
  end

  private_class_method def self.normalize_prefix(pfx)
    pfx.to_s.upcase.sub(/-$/, "")
  end
end
