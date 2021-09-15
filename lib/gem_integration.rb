class GemIntegration
  private

  # Sorry, Linux/Unix only right now :/
  GEM_HOME_SHELL_CMD = "echo $GEM_HOME"

  public

  def self.gem_home
    results = %x(#{GEM_HOME_SHELL_CMD})
    results.delete_suffix!("\n")
  end

  def self.templates_dir_from_gem_home
    GemIntegration.gem_home + "/gems/SRSGem-0.0.1/lib/templates"
  end
end
