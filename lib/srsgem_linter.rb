require_relative 'srs_initialization'
require_relative 'srsgem_project'

# Helps ensure SRS source directories have all that's needed to build
# an SRS using SRSGem. Also checks for system dependencies.
class SRSGemLinter
  OK = ''

  PASSED = [226, 156, 147].pack("c*")
  FAILED = "X"

  def self.check_ruby_version
    ruby_version_cmd_output = %x(ruby --version)
    if "#{ruby_version_cmd_output}".include? "ruby"
      puts "#{PASSED} ruby installed"
    else
      puts "#{FAILED} ruby not found."
      return "Ruby is required to run srsgem."
    end
    OK
  end

  def self.check_pandoc
    pandoc_version_cmd_output = %x(pandoc -v)
    if "#{pandoc_version_cmd_output}".include? "pandoc"
      puts "#{PASSED} pandoc installed"
    else
      puts "#{FAILED} pandoc not found."
      return "Visit pandoc.org to learn how to install pandoc on your system."
    end
    OK
  end

  def self.check_plantuml
    plantuml_version_cmd_output = %x(plantuml -version)
    if "#{plantuml_version_cmd_output}".include? "PlantUML version"
      puts "#{PASSED} PlantUML installed"
    else
      puts "#{FAILED} PlantUML not found."
      return "Visit plantuml.com to learn how to install PlantUML on your system."
    end
    OK
  end

  def self.check_srs_verbiage_source
    error_message = ''
    puts 'Checking directory structure of current folder...'
    missing = []
    SRSInitialization::DIR_SUBPATHS.each do |key, path|
      if !File.directory?(path)
        puts "#{FAILED} directory '#{path}' missing..."
        missing << path
      end
    end
    if missing.any?
      return "Missing directories: #{missing.join(', ')} (run srsgem init to set up structure)."
    end
    puts "#{PASSED} directory structure looks good"
    OK
  end

  def self.check_srs_diagram_source
    # Check for PlantUML source files (see issue #52)
    puml_files = Dir.glob("*.puml")
    if puml_files.empty?
      puts "#{FAILED} no PlantUML source files (*.puml) found"
      return "Add .puml diagram files (they will be converted to SVG on build)."
    end
    puts "#{PASSED} found #{puml_files.size} PlantUML diagram source file(s)"
    OK
  end

  def self.check_pandoc_required_files
    # Basic check for files Pandoc will need (see issue #52)
    required = ["README.md", "srs.css"]
    missing = required.select { |f| !File.exist?(f) }
    if missing.any?
      puts "#{FAILED} missing Pandoc input files: #{missing.join(', ')}"
      return "Ensure README.md and CSS are present (created by init)."
    end
    puts "#{PASSED} basic Pandoc input files present"
    OK
  end

  def self.check_for_readme_file
    # Check for README (see issue #52)
    if File.exist?("README.md") || File.exist?("README.markdown")
      puts "#{PASSED} README file present"
    else
      puts "#{FAILED} README.md (or .markdown) is missing"
      return "A README file is required for the SRS project."
    end
    OK
  end

  def self.check_for_css_file
    # Check for stylesheet (see issue #52)
    if File.exist?("srs.css")
      puts "#{PASSED} srs.css present"
    else
      puts "#{FAILED} srs.css is missing"
      return "CSS file is needed for styled output (copied by init as srs.css)."
    end
    OK
  end

  def self.check_for_build_number_tracker
    # Check .srsgem/build-number.yml (see issue #52)
    path = SRSGemProject.file_path("build-number.yml")
    if File.exist?(path)
      puts "#{PASSED} build-number.yml tracker present in .srsgem/"
    else
      puts "#{FAILED} build-number.yml missing"
      return "Run srsgem init or ensure .srsgem/build-number.yml exists."
    end
    OK
  end

  def self.check_for_build_log
    # Check .srsgem/build.log (see issue #52)
    path = SRSGemProject.file_path("build.log")
    if File.exist?(path)
      puts "#{PASSED} build.log present in .srsgem/"
    else
      puts "#{FAILED} build.log missing"
      return "Run srsgem init or ensure .srsgem/build.log exists."
    end
    OK
  end

  def self.lint
    SRSGemConfig.populate_configs
    issues = Array.new

    issues << check_ruby_version
    issues << check_pandoc
    issues << check_plantuml
    issues << check_srs_verbiage_source
    issues << check_srs_diagram_source
    issues << check_pandoc_required_files
    issues << check_for_readme_file
    issues << check_for_css_file
    issues << check_for_build_number_tracker
    issues << check_for_build_log

    issues.each { |issue| puts issue unless issue.eql? ''}
  end
end
