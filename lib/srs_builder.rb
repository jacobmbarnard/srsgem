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
    #TODO: write me
    files = FileManager.files_in_cur_dir
    yaml_file_names = Array.new
    files.each do |item|
      LogIt.log_it "found a .yaml extension!" if /.*\.yaml/ =~ item
      if (/.*\.yml/ =~ item || /.*\.yaml/ =~ item) &&
         !(item.eql?("title-template.yml")) && !(item.eql?("build-number-template.yml"))
        file = File.open("#{Dir.pwd}/#{item}")
        LogIt.log_it "PUSHING YAML FILE: #{item}"
        LogIt.log_it "Compiling YAML mapping #{item}..."
        yaml_file_names.push(item)
      end
    end
    yaml_file_names
  end

  # Assembles all markdown into a single string
  def assembled_markdown
    markdown_string = ""
    files = FileManager.files_in_cur_dir
    files.each do |item|
      if (/.*\.md/ =~ item || /.*\.markdown/ =~ item) &&
         !item.upcase.eql?("README.MD") && !item.upcase.eql?("README.MARKDOWN")
        file = File.open("#{Dir.pwd}/#{item}")
        LogIt.log_it "Compiling #{item}..."
        text = "" "

#{file.read}

" ""
        markdown_string = "" "
#{markdown_string}" + "#{NEWLINE}#{NEWLINE} #{text}

[&#x21e7; Table of Contents](\#title-block-header)

" ""
      elsif (/.*\.yml/ =~ item || /.*\.yaml/ =~ item) && !(item.eql?("title-template.yml")) && !(item.eql?("build-number-template.yml"))
        LogIt.log_it "Transpiling YAML mapping #{item} to markdown"
        yaml_file_reader = File.new("#{Dir.pwd}/#{item}", "r")
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
    files = FileManager.files_in_cur_dir
    LogIt.log_it "Searching for PlantUML files..."
    files.each do |item|
      if /.*\.puml/ =~ item
        LogIt.log_it "Converting to SVG: #{item}"
        puml_command = "plantuml #{Dir.pwd}/#{item} -svg"
        %x(#{puml_command})
        log_file_object = File.new("#{Dir.pwd}/build.log", "a")
        log_file_object.write(puml_command.to_s)
        log_file_object.write(NEWLINE)
        log_file_object.close
      end
    end
  end

  # Cleans out the output subdirectory
  def clear_output
    FileUtils.remove_dir("output") if File.directory?("output")
    FileUtils.mkdir("output")
  end

  def copy_resources
    LogIt.log_it("Begin copying resources...")
    output_dir = "#{Dir.pwd}/output/"
    cpy_cmd = "cp "
    Dir.foreach(Dir.pwd.to_s) do |item|
      RSRC_RECOGNITION_HASH.each do |subdir, regex_strings|
        regex_strings.each do |pattern|
          next unless Regexp.new(pattern) =~ item

          FileUtils.mkdir_p(output_dir + subdir.to_s) unless File.directory?(File.join("output", subdir.to_s))
          FileUtils.copy(item, File.join(File.join("output", subdir.to_s), item.to_s))
          command = cpy_cmd + "#{item} " + output_dir + subdir.to_s + "/" + item.to_s
          LogIt.log_it "copying resource #{item} with '#{command}'..."
          `#{command}`
        end
      end
    end
    LogIt.log_it("End copying resources...")
  end

  def adjust_html_output_css_filepath
    srs_html_file = File.new("#{Dir.pwd}/#{OUTPUT_LOCATION}", "r")
    srs_html_file_contents = srs_html_file.read
    srs_html_file.close

    srs_html_file_contents.gsub!(/srs.css/, "css/srs.css")

    srs_html_file_w = File.new("#{Dir.pwd}/#{OUTPUT_LOCATION}", "w")
    srs_html_file_w.write(srs_html_file_contents)
    srs_html_file_w.close
  end

  def build_timestamp_and_number_markdown
    yaml_file_reader = File.new("#{Dir.pwd}/#{"build-number.yml"}", "r")
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
    file_path = "#{Dir.pwd}/build-number.yml"
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
    SRSBuildAnnouncer.announce_starting_build
    LogIt.log_build
    clear_output
    export_svgs_from_plantuml unless build_plantuml == false
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
