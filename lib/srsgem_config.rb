require_relative 'srsgem_project'
require 'yaml'

# Gets configs from config file for an SRS project.
class SRSGemConfig
  CONFIG_FILE_NAME = "config.yml"

  @@configs = {
    :build_plantuml => true,
    :keep_copy_of_plantuml_svg_with_source => true,
    :markdown_search_folder => '.',
    :markdown_search_is_recursive => false,
    :yaml_mappings_search_folder => '.',
    :yaml_mappings_search_is_recursive => false
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
    @@configs[:markdown_search_folder] =
      yaml_obj.fetch('markdown_search_folder', @@configs[:markdown_search_folder])
    @@configs[:markdown_search_is_recursive] =
      yaml_obj.fetch('markdown_search_is_recursive', @@configs[:markdown_search_is_recursive])
    @@configs[:yaml_mappings_search_folder] =
      yaml_obj.fetch('yaml_mappings_search_folder', @@configs[:yaml_mappings_search_folder])
    @@configs[:yaml_mappings_search_is_recursive] =
      yaml_obj.fetch('yaml_mappings_search_is_recursive', @@configs[:yaml_mappings_search_is_recursive])
  end
end