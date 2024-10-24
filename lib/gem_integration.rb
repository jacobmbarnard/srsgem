class GemIntegration
  private
  public

  def self.templates_dir_from_gem_home
    File.join(File.dirname(__FILE__), 'templates')
  end
end
