require "test/unit"

require_relative "../lib/srs_gem_config"

class TestAdd < Test::Unit::TestCase
  def test_access_configs
    SRSGemConfig.populate_configs
    puts "configs: #{SRSGemConfig.configs.to_s}"
    assert_true(SRSGemConfig.configs[:keep_copy_of_plantuml_svg_with_source])
    assert_true(SRSGemConfig.configs[:build_plantuml])
  end
end
