require_relative 'file_manager'

class SRSGemConfig
  CONFIG_FILE_NAME = "config.yml"

  attr_accessor :configs

  @@configs = {
    :keep_copy_of_plantuml_svg_with_source => true
  }

  def self.populate_configs
    path = FileManager.yaml_file_path(CONFIG_FILE_NAME)
    file_reader = File.new(path, "r")
    yml = file_reader.read
    file_reader.close

    yml_str = yml.to_s
    yaml_obj = YAML.load(yml_str)
    @@configs[:keep_copy_of_plantuml_svg_with_source] = yaml_obj[:keep_copy_of_plantuml_svg_with_source.to_s]
  end
end
