require "fileutils"
require "yaml"
require "date"

require_relative "markdown_enhancements/srs_business_glossary_markdown_tag"
require_relative "markdown_enhancements/srs_technical_glossary_markdown_tag"
require_relative "markdown_enhancements/srs_section_markdown_tag"

require_relative "markdown_enhancements/srs_yaml_transpiler"

require_relative "file_manager"
require_relative "pandoc_support/pandoc_helper"
require_relative "srs_header_counter"
require_relative "logit"
require_relative "srsgem_config"
require_relative "srsgem_project"
require_relative "srs_build_announcer"

class SRSBuilder
  attr_accessor :header_counter

  NEWLINE = "\n"
  SINGLE_TMP_MD_RELATAIVE_FILEPATH = "compiled_markdown.markdown"
  OUTPUT_LOCATION = "output/srs.html"

  RSRC_RECOGNITION_HASH = {
    svg: ['.*\.svg'],
    img: ['.*\.png', '.*\.jpg'],
    doc: ['.*\.html', '.*\.rtf'],
    css: ['.*\.css'],
  }

  def initialize
    @datestamp = "0000-00-00 00:00:00 -0"
    @build_number = "0"
    @header_counter = SRSHeaderCounter.new
  end

  def project_file_path(relative_path)
    File.join(Dir.pwd, relative_path)
  end

  def markdown_source_files
    FileManager.project_files(
      search_folder: SRSGemConfig.configs[:markdown_search_folder],
      recursive: SRSGemConfig.configs[:markdown_search_is_recursive]
    )
  end

  def yaml_mapping_source_files
    FileManager.project_files(
      search_folder: SRSGemConfig.configs[:yaml_mappings_search_folder],
      recursive: SRSGemConfig.configs[:yaml_mappings_search_is_recursive]
    )
  end

  def assembly_source_files
    files = []
    markdown_source_files.each { |item| files << item if markdown_source_file?(item) }
    yaml_mapping_source_files.each { |item| files << item if yaml_mapping_source_file?(item) }
    files.uniq.sort
  end

  def markdown_source_file?(item)
    /.*\.md\z/i =~ item || /.*\.markdown\z/i =~ item
  end

  def yaml_mapping_source_file?(item)
    (/.*\.yml\z/i =~ item || /.*\.yaml\z/i =~ item) &&
      !item.eql?("title-template.yml") && !item.eql?("build-number-template.yml")
  end

  def readme_file?(item)
    File.basename(item).upcase.eql?("README.MD") || File.basename(item).upcase.eql?("README.MARKDOWN")
  end

  # Replaces header hash tags with numbered header hash tags
  def numbered_headers(markdown_string)
    new_string = ""
    markdown_string.each_line do |line|
      replaced_header_line = line.dup
      replaced_header_line = @header_counter.replaced_with_numbered_header(replaced_header_line)
      new_string << replaced_header_line
    end
    new_string
  end

  # Gets all the YAML mapping files locating the same directory as the markdown
  def yaml_file_names
    yaml_file_names = Array.new
    yaml_mapping_source_files.each do |item|
      next unless yaml_mapping_source_file?(item)

      LogIt.log_it "found a .yaml extension!" if /.*\.yaml/ =~ item
      LogIt.log_it "PUSHING YAML FILE: #{item}"
      LogIt.log_it "Compiling YAML mapping #{item}..."
      yaml_file_names.push(item)
    end
    yaml_file_names
  end

  # Assembles all markdown into a single string
  def assembled_markdown
    markdown_string = ""
    assembly_source_files.each do |item|
      if markdown_source_file?(item) && !readme_file?(item)
        file = File.open(project_file_path(item))
        LogIt.log_it "Compiling #{item}..."
        text = "" "

#{file.read}

" ""
        file.close
        markdown_string = "" "
#{markdown_string}" + "#{NEWLINE}#{NEWLINE} #{text}

[&#x21e7; Table of Contents](\#title-block-header)

" ""
      elsif yaml_mapping_source_file?(item)
        LogIt.log_it "Transpiling YAML mapping #{item} to markdown"
        yaml_file_reader = File.new(project_file_path(item), "r")
        yml = yaml_file_reader.read
        yaml_file_reader.close

        yml_str = yml.to_s
        yaml_obj = YAML.load(yml_str)
        markdown_string += "\n"
        markdown_string = SRSYAMLTranspiler.yaml_to_markdown(yaml_obj, markdown_string)
      end
    end
    numbered_headers markdown_string
  end

  def export_svgs_from_plantuml
    LogIt.log_it "Searching for PlantUML files..."
    markdown_source_files.each do |item|
      next unless /.*\.puml\z/i =~ item

      LogIt.log_it "Converting to SVG: #{item}"
      puml_command = "plantuml #{project_file_path(item)} -svg"
      %x(#{puml_command})
      LogIt.log_it(puml_command)
    end
  end

  # Cleans out the output subdirectory
  def clear_output
    FileUtils.remove_dir("output") if File.directory?("output")
    FileUtils.mkdir("output")
  end

  def copy_resources
    LogIt.log_it("Begin copying resources...")
    output_root = File.join(Dir.pwd, 'output')

    markdown_source_files.each do |item|
      RSRC_RECOGNITION_HASH.each do |subdir, regex_strings|
        regex_strings.each do |pattern|
          next unless Regexp.new(pattern) =~ File.basename(item)

          relative_dir = File.dirname(item)
          relative_dir = '' if relative_dir == '.'
          destination_dir = File.join(output_root, subdir.to_s, relative_dir)
          FileUtils.mkdir_p(destination_dir)
          destination_path = File.join(destination_dir, File.basename(item))
          FileUtils.copy(project_file_path(item), destination_path)
          LogIt.log_it "copying resource #{item} to #{destination_path}..."
        end
      end
    end
    LogIt.log_it("End copying resources...")
  end

  def adjust_html_output_css_filepath
    srs_html_file = File.new(File.join(Dir.pwd, OUTPUT_LOCATION), "r")
    srs_html_file_contents = srs_html_file.read
    srs_html_file.close

    srs_html_file_contents.gsub!(/srs.css/, "css/srs.css")

    srs_html_file_w = File.new(File.join(Dir.pwd, OUTPUT_LOCATION), "w")
    srs_html_file_w.write(srs_html_file_contents)
    srs_html_file_w.close
  end

  def build_timestamp_and_number_markdown
    yaml_file_reader = File.new(SRSGemProject.file_path('build-number.yml'), "r")
    yml = yaml_file_reader.read
    yaml_file_reader.close

    yml_str = yml.to_s
    yaml_obj = YAML.load(yml_str)
    build_number = yaml_obj["last_build"]["number"].to_i
    @build_number = build_number
    datestamp = yaml_obj["last_build"]["date"].to_s
    @datestamp = datestamp
    str = "\nDocument Generated: #{@datestamp} (build #{@build_number})"
    str
  end

  def update_build_num_and_timestamp
    file_path = SRSGemProject.file_path('build-number.yml')
    yaml_obj = YAML.load_file(file_path)
    @build_number = yaml_obj["last_build"]["number"].to_i + 1
    @datestamp = Time.now.to_s
    yaml_obj["last_build"]["number"] = @build_number
    yaml_obj["last_build"]["date"] = @datestamp
    File.open(file_path, "w") { |file| file.write yaml_obj.to_yaml }
  end

  def transpile_specific_markdown(markdown_str)
    markdown_str = SRSSectionMarkdownTag.new.transpile_matches_in(markdown_str)
    markdown_str = SRSBusinessGlossaryMarkdownTag.new.transpile_matches_in(markdown_str)
    markdown_str = SRSTechnicalGlossaryMarkdownTag.new.transpile_matches_in(markdown_str)
    markdown_str
  end

  def compile_markdown(markdown_str)
    temp_compiled_markdown_file = File.new(SINGLE_TMP_MD_RELATAIVE_FILEPATH, "w")
    temp_compiled_markdown_file.write(markdown_str)
    temp_compiled_markdown_file.close
    PandocHelper.build_standard_output(SINGLE_TMP_MD_RELATAIVE_FILEPATH, OUTPUT_LOCATION)
  end

  # Used to build human-readable documentation. Transpiles/compiles
  # project code into a clean, styled, SRS.
  #
  # @param [Boolean] build_plantuml whether or not to include PlantUML in the build
  # @return whether the build succeeded
  def build_srs(build_plantuml = true)
    SRSGemConfig.populate_configs
    SRSBuildAnnouncer.announce_starting_build
    LogIt.log_build
    clear_output
    if build_plantuml
      export_svgs_from_plantuml
    elsif SRSGemConfig.configs[:build_plantuml]
      export_svgs_from_plantuml
    end
    SRSBuildAnnouncer.announce_assembling_markdown
    markdown_str = assembled_markdown
    SRSBuildAnnouncer.announce_copying_resources
    copy_resources
    FileUtils.touch(SINGLE_TMP_MD_RELATAIVE_FILEPATH)
    update_build_num_and_timestamp
    markdown_str += build_timestamp_and_number_markdown
    SRSBuildAnnouncer.announce_compiling_srsgem_specific_md
    markdown_str = transpile_specific_markdown(markdown_str)
    SRSBuildAnnouncer.announce_compiling_markdown
    compile_markdown(markdown_str)
    FileUtils.remove(SINGLE_TMP_MD_RELATAIVE_FILEPATH)
    adjust_html_output_css_filepath
    SRSBuildAnnouncer.announce_done
    SRSBuildAnnouncer.announce_output_location(OUTPUT_LOCATION)
    true
  end
end
