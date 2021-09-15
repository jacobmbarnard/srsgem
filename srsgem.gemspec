Gem::Specification.new do |s|
  s.name = "SRSGem"
  s.version = "0.0.1"
  s.summary = "Leverages PlantUML and Pandoc to convert puml and md to an Software Requirements Specification (SRS)."
  s.description = "Use srsgem CLT to create a template directory for making an SRS, fill out the template files, then run srsgem build to get beautiful HTML SRS output."
  s.authors = ["Jacob Barnard"]
  s.email = "jmbarnardg1@gmail.com"
  s.files = Dir.glob("lib/**/*", File::FNM_DOTMATCH)
  s.homepage = "https://rubygems.org/gems/srsgem"
  s.license = "Apache-2.0"

  s.executables << "srsgem"

  s.add_dependency "yaml", "~> 0.1.1"
  s.add_dependency "date", "~> 3.1.1"
  s.add_dependency "fileutils", "~> 1.5.0"
  s.add_dependency "homogeneous_descendant_linking_nestable", "~> 0.0.1"
  s.add_dependency "counter_container", "~> 0.0.2"
  s.add_dependency "pandoc-ruby", "~> 2.1.4"
end
