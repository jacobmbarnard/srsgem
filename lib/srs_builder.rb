require "fileutils"
require "yaml"
require "date"

require_relative "markdown_enhancements/srs_business_glossary_markdown_tag"
require_relative "markdown_enhancements/srs_technical_glossary_markdown_tag"
require_relative "markdown_enhancements/srs_section_markdown_tag"

require_relative "pandoc_support/pandoc_helper"
require_relative "srs_header_counter"
require_relative "logit"

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

  def files_in_cur_dir
    files = []
    current_dir_path = Dir.pwd.to_s
    current_dir = Dir.new(current_dir_path)
    current_dir.each do |file|
      files.push(file)
    end
    current_dir.close
    files.sort!
  end

  # Gets all the YAML mapping files locating the same directory as the markdown
  def yaml_file_names
    #TODO: write me
    files = files_in_cur_dir
    yaml_fns = Array.new
    files.each do |item|
      puts "found a .yaml extension!" if /.*\.yaml/ =~ item
      if (/.*\.yml/ =~ item || /.*\.yaml/ =~ item) &&
         !(item.eql?("title-template.yml")) && !(item.eql?("build-number-template.yml"))
        file = File.open("#{Dir.pwd}/#{item}")
        puts "PUSHING YAML FILE: #{item}"
        LogIt.log_it "Compiling YAML mapping #{item}..."
        yaml_fns.push(item)
      end
    end
    yaml_fns
  end

  # Converts the YAML into a bullet list mapping top-level items to the
  # lower level items, and automatically generating a markdown anchor
  # link for them
  #
  # @returns a markdown string showing the mapping indicated in the YAML
  def yaml_mapping_to_markdown
    #TODO: write me
  end

  # Assembles all markdown into a single string
  def assembled_markdown
    markdown_string = ""
    files = files_in_cur_dir
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
        # TODO: finish writing me
        LogIt.log_it "Transpiling YAML mapping #{item} to markdown"
        yaml_file_reader = File.new("#{Dir.pwd}/#{item}", 'r')
        yml = yaml_file_reader.read
        yaml_file_reader.close
  
        yml_str = yml.to_s
        yaml_obj = YAML.load(yml_str)
        yaml_mapping = Array.new
        yaml_mapping = yaml_obj[:mapping]
        markdown_string += "\n"
        yaml_obj.each do |k, v|
          val = yaml_obj[k]
          if k.eql? 'title'
            markdown_string += "# #{val}\n"
            markdown_string += "\n"
          elsif k.eql? 'comments'
            markdown_string += "#{val}\n"
          elsif k.eql? 'mapping'
            markdown_string += "\n"
            val.each do |mapping_obj|
              mapping_obj.each do |map_obj_k, map_obj_v|
                mapping_object_md = "- [#{map_obj_k}](##{map_obj_k.downcase.gsub(' ', '-')})\n"
                markdown_string += mapping_object_md
                map_obj_v.each do |map_obj_v_elem|
                  mapping_object_md = "  - [#{map_obj_v_elem}](##{map_obj_v_elem.downcase.gsub(' ', '-')})\n"
                  markdown_string += mapping_object_md
                end
              end
            end
          end
        end
      end
    end
    numbered_headers markdown_string
  end

  def export_svgs_from_plantuml
    files = files_in_cur_dir
    puts "Searching for PlantUML files..."
    files.each do |item|
      if /.*\.puml/ =~ item
        puts "Converting to SVG: #{item}"
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

  def build_srs(build_plantuml = true)
    puts "Attempting to build SRS..."
    LogIt.log_build

    clear_output

    export_svgs_from_plantuml unless build_plantuml == false

    # TODO: Build markdown from YAML files
    # use NNN-mapping- as file prefix to convert

    puts "Assembling markdown files..."
    markdown_str = assembled_markdown

    puts "Copying other resources..."
    copy_resources
    FileUtils.touch(SINGLE_TMP_MD_RELATAIVE_FILEPATH)
    markdown_str += "\nDocument Generated: #{@datestamp} (build #{@build_number})"

    puts "Transpiling SRSGem-specific Markdown..."
    markdown_str = SRSSectionMarkdownTag.new.transpile_matches_in(markdown_str)
    markdown_str = SRSBusinessGlossaryMarkdownTag.new.transpile_matches_in(markdown_str)
    markdown_str = SRSTechnicalGlossaryMarkdownTag.new.transpile_matches_in(markdown_str)

    temp_compiled_markdown_file = File.new(SINGLE_TMP_MD_RELATAIVE_FILEPATH, "w")
    temp_compiled_markdown_file.write(markdown_str)
    temp_compiled_markdown_file.close

    puts "Compiling markdown..."
    PandocHelper.build_standard_output(SINGLE_TMP_MD_RELATAIVE_FILEPATH, OUTPUT_LOCATION)

    FileUtils.remove(SINGLE_TMP_MD_RELATAIVE_FILEPATH)

    adjust_html_output_css_filepath

    puts "Done!"
    puts "Output is at #{OUTPUT_LOCATION}."
    true
  end
end
