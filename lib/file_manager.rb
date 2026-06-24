require 'pathname'

class FileManager
  EXCLUDED_DIRECTORY_NAMES = %w[.srsgem output .git ADRs].freeze

  def self.files_in_cur_dir
    project_files(search_folder: '.', recursive: false)
  end

  def self.project_files(search_folder: '.', recursive: false)
    project_root = Dir.pwd.to_s
    search_root = File.expand_path(search_folder, project_root)
    return [] unless File.directory?(search_root)

    files = []
    if recursive
      collect_files_recursive(search_root, project_root, files)
    else
      collect_files_flat(search_root, project_root, files)
    end
    files.sort!
  end

  def self.yaml_file_path(yaml_file_name)
    File.join(Dir.pwd.to_s, yaml_file_name)
  end

  def self.collect_files_flat(search_root, project_root, files)
    Dir.children(search_root).sort.each do |entry|
      next if entry == '.' || entry == '..'

      absolute_path = File.join(search_root, entry)
      next if File.directory?(absolute_path)

      files << relative_path_for(absolute_path, project_root)
    end
  end

  def self.collect_files_recursive(search_root, project_root, files)
    Dir.children(search_root).sort.each do |entry|
      next if entry == '.' || entry == '..'

      absolute_path = File.join(search_root, entry)
      if File.directory?(absolute_path)
        next if EXCLUDED_DIRECTORY_NAMES.include?(entry)

        collect_files_recursive(absolute_path, project_root, files)
      else
        files << relative_path_for(absolute_path, project_root)
      end
    end
  end

  def self.relative_path_for(absolute_path, project_root)
    path = Pathname.new(absolute_path).relative_path_from(Pathname.new(project_root)).to_s
    path.tr('\\', '/')
  end

  private_class_method :collect_files_flat, :collect_files_recursive, :relative_path_for
end
