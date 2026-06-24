require "test/unit"
require "fileutils"
require "yaml"

require_relative "../lib/srs_initialization"
require_relative "../lib/srsgem_config"
require_relative "../lib/srsgem_project"

class TestAdd < Test::Unit::TestCase
  def test_access_configs_from_project_srsgem_directory
    tmp_proj_dir_name = 'tmp_config_proj'
    SRSInitialization.new.init_bare_srsgem_dir(tmp_proj_dir_name)

    Dir.chdir(tmp_proj_dir_name) do
      SRSGemConfig.populate_configs
      assert_true(SRSGemConfig.configs[:keep_copy_of_plantuml_svg_with_source])
      assert_true(SRSGemConfig.configs[:build_plantuml])
    end
  ensure
    FileUtils.remove_dir(tmp_proj_dir_name) if Dir.exist?(tmp_proj_dir_name)
  end

  def test_populate_configs_reads_project_config_file
    tmp_proj_dir_name = 'tmp_config_override_proj'
    SRSInitialization.new.init_bare_srsgem_dir(tmp_proj_dir_name)

    Dir.chdir(tmp_proj_dir_name) do
      config_path = SRSGemProject.file_path('config.yml')
      config = YAML.load_file(config_path)
      config['build_plantuml'] = false
      File.write(config_path, config.to_yaml)

      SRSGemConfig.populate_configs
      assert_false(SRSGemConfig.configs[:build_plantuml])
    end
  ensure
    FileUtils.remove_dir(tmp_proj_dir_name) if Dir.exist?(tmp_proj_dir_name)
  end

  def test_plantuml_command_uses_jar_when_configured
    tmp_proj_dir_name = 'tmp_plantuml_jar_proj'
    SRSInitialization.new.init_bare_srsgem_dir(tmp_proj_dir_name)

    Dir.chdir(tmp_proj_dir_name) do
      config_path = SRSGemProject.file_path('config.yml')
      config = YAML.load_file(config_path)
      config['plantuml_jar_path'] = '/opt/plantuml/plantuml.jar'
      File.write(config_path, config.to_yaml)

      SRSGemConfig.populate_configs
      command = SRSGemConfig.plantuml_command_for('/tmp/example.puml')
      assert_equal('java -jar /opt/plantuml/plantuml.jar /tmp/example.puml -svg', command)
    end
  ensure
    FileUtils.remove_dir(tmp_proj_dir_name) if Dir.exist?(tmp_proj_dir_name)
  end

  def test_plantuml_command_uses_path_command_by_default
    tmp_proj_dir_name = 'tmp_plantuml_default_proj'
    SRSInitialization.new.init_bare_srsgem_dir(tmp_proj_dir_name)

    Dir.chdir(tmp_proj_dir_name) do
      SRSGemConfig.populate_configs
      command = SRSGemConfig.plantuml_command_for('/tmp/example.puml')
      assert_equal('plantuml /tmp/example.puml -svg', command)
    end
  ensure
    FileUtils.remove_dir(tmp_proj_dir_name) if Dir.exist?(tmp_proj_dir_name)
  end

  def test_access_project_source
    assert_true(SRSGemConfig.report_project_directory.eql? '.srsgem')
  end
end