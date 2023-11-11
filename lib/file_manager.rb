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
  
  def self.yaml_file_path(yaml_file_name)
    current_dir_path = Dir.pwd.to_s
    f_path = current_dir_path + '/' + yaml_file_name
  end
end
