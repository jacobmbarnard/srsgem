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
    path = SRSGemProject.file_path(CONFIG_FILE_NAME)
    return unless File.exist?(path)

    yaml_obj = YAML.load_file(path)
    @@configs[:build_plantuml] = yaml_obj.fetch('build_plantuml', @@configs[:build_plantuml])
    @@configs[:keep_copy_of_plantuml_svg_with_source] =
      yaml_obj.fetch('keep_copy_of_plantuml_svg_with_source', @@configs[:keep_copy_of_plantuml_svg_with_source])
  end
end