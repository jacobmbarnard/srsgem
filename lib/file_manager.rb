class FileManager
  def self.files_in_cur_dir
    files = []
    current_dir_path = Dir.pwd.to_s
    current_dir = Dir.new(current_dir_path)
    current_dir.each do |file|
      files.push(file)
    end
    current_dir.close
    files.sort!
  end
  
  # Recursively finds all files in the current directory and subdirectories
  # Returns an array of relative file paths, sorted lexicographically
  def self.all_files_recursive(exclude_dirs = ['.srsgem', 'output', '.git'])
    files = []
    
    def self.scan_directory(base_path, current_path, files, exclude_dirs)
      begin
        dir = Dir.new(current_path)
        dir.each do |entry|
          next if entry == '.' || entry == '..'
          
          full_path = File.join(current_path, entry)
          relative_path = File.join(base_path, entry)
          
          if File.directory?(full_path)
            # Skip excluded directories
            next if exclude_dirs.include?(entry)
            scan_directory(relative_path, full_path, files, exclude_dirs)
          else
            files.push(relative_path)
          end
        end
        dir.close
      rescue Errno::EACCES
        # Skip directories we can't access
      end
    end
    
    scan_directory('.', Dir.pwd.to_s, files, exclude_dirs)
    files.sort!
  end
  
  def self.yaml_file_path(yaml_file_name)
    current_dir_path = Dir.pwd.to_s
    f_path = current_dir_path + '/' + yaml_file_name
  end
end
