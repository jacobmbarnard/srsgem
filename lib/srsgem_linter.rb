require_relative 'srs_initialization'

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
    pandoc_version_cmd_output = %x(plantuml -version)
    if "#{pandoc_version_cmd_output}".include? "PlantUML version"
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
    SRSInitialization::DIR_SUBPATHS.each do |key, path|
      if !File.directory?(path)
        puts "#{FAILED} directory '#{path}'' missing..."
      end
    end
    OK
  end

  def self.check_srs_diagram_source
    # TODO: complete this lint
    OK
  end

  def self.check_pandoc_required_files
    # TODO: complete this lint
    OK
  end

  def self.check_for_readme_file
    # TODO: complete this lint
    OK
  end

  def self.check_for_css_file
    # TODO: complete this lint
    OK
  end

  def self.check_for_build_number_tracker
    # TODO: complete this lint
    OK
  end

  def self.check_for_build_log
    # TODO: complete this lint
    OK
  end

  def self.lint
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
