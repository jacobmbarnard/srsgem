class SRSGemProject
  PROJECT_DIRECTORY_NAME = '.srsgem'

  def self.directory_path(base_dir = Dir.pwd)
    File.join(base_dir.to_s, PROJECT_DIRECTORY_NAME)
  end

  def self.file_path(filename, base_dir = Dir.pwd)
    File.join(directory_path(base_dir), filename)
  end
end