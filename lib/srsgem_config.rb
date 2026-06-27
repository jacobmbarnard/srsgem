require_relative 'srsgem_project'
require 'yaml'

# Gets configs from config file for an SRS project.
class SRSGemConfig
  CONFIG_FILE_NAME = "config.yml"

  @@configs = {
    :build_plantuml => true,
    :keep_copy_of_plantuml_svg_with_source => true,
    :pandoc_command => 'pandoc',
    :plantuml_jar_path => '',
    :plantuml_command => 'plantuml',
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

    @@configs[:pandoc_command] = yaml_obj.fetch('pandoc_command', @@configs[:pandoc_command])
    @@configs[:plantuml_jar_path] = yaml_obj.fetch('plantuml_jar_path', @@configs[:plantuml_jar_path]).to_s
    @@configs[:plantuml_command] = yaml_obj.fetch('plantuml_command', @@configs[:plantuml_command])

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

  def self.plantuml_command_for(input_path, output_flag = '-svg')
    if plantuml_jar_path_configured?
      "java -jar #{@@configs[:plantuml_jar_path]} #{input_path} #{output_flag}"
    else
      "#{@@configs[:plantuml_command]} #{input_path} #{output_flag}"
    end
  end

  def self.plantuml_version_command
    if plantuml_jar_path_configured?
      "java -jar #{@@configs[:plantuml_jar_path]} -version"
    else
      "#{@@configs[:plantuml_command]} -version"
    end
  end

  def self.plantuml_jar_path_configured?
    !@@configs[:plantuml_jar_path].to_s.strip.empty?
  end
end