require_relative 'srsgem_project'
require 'yaml'

# Gets configs from config file for an SRS project.
class SRSGemConfig
  CONFIG_FILE_NAME = "config.yml"

  @@configs = {
    :build_plantuml => true,
    :keep_copy_of_plantuml_svg_with_source => true,
    # Stable ID related (loaded for #47 and future #48)
    :auto_assign_ids_on_build => false,
    :auto_assign_levels => [2, 3],
    :warn_on_missing_ids => true
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

    # Stable IDs config (partial support for #47; full in #48)
    if yaml_obj.key?('auto_assign_ids_on_build')
      @@configs[:auto_assign_ids_on_build] = !!yaml_obj['auto_assign_ids_on_build']
    end
    if yaml_obj.key?('auto_assign_levels')
      lvls = yaml_obj['auto_assign_levels']
      @@configs[:auto_assign_levels] = lvls if lvls.is_a?(Array)
    end
    if yaml_obj.key?('warn_on_missing_ids')
      @@configs[:warn_on_missing_ids] = !!yaml_obj['warn_on_missing_ids']
    end
  end
end