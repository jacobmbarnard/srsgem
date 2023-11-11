require "test/unit"

require_relative "../lib/srs_gem_config"

class TestAdd < Test::Unit::TestCase
  def test_increment
    SRSGemConfig.populate_configs
    puts SRSGemConfig.configs
  end
end
