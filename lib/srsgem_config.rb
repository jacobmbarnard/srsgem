require_relative 'file_manager'
require_relative 'srsgem_project'
require 'yaml'

# Gets configs from config file for an SRS project.
class SRSGemConfig
  CONFIG_FILE_NAME = "config.yml"

  @@configs = {
    :build_plantuml => true,
    :keep_copy_of_plantuml_svg_with_source => true
  }

  def self.configs
    @@configs
  end

  def self.report_project_directory
    SRSGemProject::PROJECT_DIRECTORY_NAME
  end

  def self.populate_configs
    path = FileManager.yaml_file_path('lib/templates/config.yml')
    puts path
    file_reader = File.new(path, "r")
    yml = file_reader.read
    file_reader.close

    yml_str = yml.to_s
    yaml_obj = YAML.load(yml_str)
    @@configs[:build_plantuml] = yaml_obj[:build_plantuml.to_s]
    @@configs[:keep_copy_of_plantuml_svg_with_source] = yaml_obj[:keep_copy_of_plantuml_svg_with_source.to_s]
  end
end
