require 'fileutils'
require_relative 'gem_integration'
require_relative 'srs_template_content_filter'
require_relative 'srsgem_project'

# Provides ability for user to initialize the current empty directory
# with a bare bones SRSGem setup
class SRSInitialization
  # Creates and empty file at the provided filepath (include file extension)
  def create_empty_file_in_srs_dir(empty_file_filepath)
    FileUtils.remove(empty_file_filepath) if File.exist?(empty_file_filepath)
    FileUtils.touch(empty_file_filepath)
  end

  # Properly opens a file, writes the contents, then closes the file stream
  def populate_file_with_contents(filepath, contents)
    w_file = File.new(filepath, 'w')
    w_file.write(contents)
    w_file.close
  end

  # Scans the name of the template file to see whether any known
  # filters exist for it. If so, the contents are scanned and potentially
  # modified by the corresponding filter(s).
  def scan_and_modify_contents_of_srs_file(contents, generated_file_path)
    updt_contents = String.new(contents)
    SRSTemplateContentFilter.all_filters.each do |filter|
      updt_contents = filter.update_contents(updt_contents, generated_file_path)
    end
    filewriter = File.new(generated_file_path, 'w')
    filewriter.write(updt_contents)
  end

  # Initializes directory (./MyNewSRSWithSRSGem by default) with bare bones
  # SRS source files setup.
  def init_bare_srsgem_dir(target_dir = 'MyNewSRSWithSRSGem')
    FileUtils.mkdir(target_dir) unless Dir.exist?(target_dir)
    templates_directory = Dir.new(GemIntegration.templates_dir_from_gem_home)

    templates_directory.each do |template_filepath|
      ignore_file = false

      if template_filepath =~ /\A.*\.puml\Z/ ||
         template_filepath =~ /\A.*\.md\Z/   ||
         template_filepath =~ /\A.*\.css\Z/  ||
         template_filepath =~ /\A.*\.yml\Z/  ||
         template_filepath =~ /\A.*\.yaml\Z/  ||
         template_filepath =~ /\A.*\.png\Z/  ||
         template_filepath =~ /\A.*\.log\Z/  ||
         template_filepath =~ /\A\.gitignore-template\Z/
      else
        ignore_file = true
      end

      next if ignore_file

      filereader = File.new("#{GemIntegration.templates_dir_from_gem_home}/#{template_filepath}", 'r')
      template_contents = filereader.read
      filereader.close

      template_filepath.slice!('-template')
      generated_file_path = "#{target_dir}/#{template_filepath}"

      create_empty_file_in_srs_dir(generated_file_path)

      scan_and_modify_contents_of_srs_file(template_contents, generated_file_path)
    end

    # Create project directory
    srsgem_project_dir = Dir.mkdir("#{target_dir}/#{SRSGemProject::PROJECT_DIRECTORY_NAME}")

    # BREAKING CHANGES
    # 1. config.yml should be moved into the .srsgem folder
    FileUtils.mv("#{target_dir}/config.yml", "#{target_dir}/.srsgem/config.yml")
    FileUtils.mv("#{target_dir}/build-number.yml", "#{target_dir}/.srsgem/build-number.yml")
    FileUtils.mv("#{target_dir}/build.log", "#{target_dir}/.srsgem/build.log")



    puts "SRSGem created new SRS source files with placeholder content in #{target_dir}."
    puts 'Done.'
  end
end
