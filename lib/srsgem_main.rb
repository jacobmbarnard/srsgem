require_relative "srs_initialization"
require_relative "srs_builder"

class SRSGemMain
  attr_accessor :srs_initializer

  def initialize()
    @srs_initializer = SRSInitialization.new
  end

  def srs_builder
    SRSBuilder.new
  end
end
