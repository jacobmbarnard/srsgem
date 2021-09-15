require 'fileutils'
require 'yaml'
require 'date'

require_relative 'pandoc_support/pandoc_helper'
require_relative 'srs_header_counter'
require_relative 'logit'

class SRSBuilder
  attr_accessor :header_counter

  NEWLINE = "\n"
  SINGLE_TMP_MD_RELATAIVE_FILEPATH = 'compiled_markdown.markdown'
  OUTPUT_LOCATION = 'output/srs.html'

  # A hash which Indeed, anywhen building an SRs html file.
  RSRC_RECOGNITION_HASH = {
    svg: ['.*\.svg'],
    img: ['.*\.png', '.*\.jpg'],
    doc: ['.*\.html', '.*\.rtf'],
    css: ['.*\.css']
  }

  def initialize
    @datestamp = '0000-00-00 00:00:00 -0'
    @build_number = '0'
    @header_counter = SRSHeaderCounter.new
  end

  # Replaces header hash tags with numbered header hash tags
  def numbered_headers(markdown_string)
    new_string = ''
    markdown_string.each_line do |line|
      replaced_header_line = line.dup
      replaced_header_line = @header_counter.replaced_with_numbered_header(replaced_header_line)
      new_string << replaced_header_line
    end
    new_string
  end

  # Assembles all markdown into a single string
  def assembled_markdown
    files = []
    markdown_string = ''
    current_dir_path = Dir.pwd.to_s
    current_dir = Dir.new(current_dir_path)
    current_dir.each do |file|
      files.push(file)
    end
    current_dir.close
    files.sort!

    puts "Searching for PlantUML files..."
    files.each do |item|
      if /.*\.puml/ =~ item
        puts "Converting to SVG: #{item}"
        puml_command = "plantuml #{Dir.pwd}/#{item} -svg"
        `echo $(#{puml_command}) >> #{Dir.pwd}/build.log`
      elsif (/.*\.md/ =~ item || /.*\.markdown/ =~ item) &&
            !item.upcase.eql?('README.MD') && !item.upcase.eql?('README.MARKDOWN')
        file = File.open("#{Dir.pwd}/#{item}")
        LogIt.log_it "Compiling #{item}..."
        text = '' "

#{file.read}

" ''
        markdown_string = '' "
#{markdown_string}" + "#{NEWLINE}#{NEWLINE} #{text}

[&#x21e7; Table of Contents](\#title-block-header)

" ''
      end
    end
    numbered_headers markdown_string
  end

  # Cleans out the output subdirectory
  def clear_output
    FileUtils.remove_dir('output') if File.directory?('output')
    FileUtils.mkdir('output')
  end

  def copy_resources
    LogIt.log_it('Begin copying resources...')
    output_dir = "#{Dir.pwd}/output/"
    cpy_cmd = 'cp '
    Dir.foreach(Dir.pwd.to_s) do |item|
      RSRC_RECOGNITION_HASH.each do |subdir, regex_strings|
        regex_strings.each do |pattern|
          next unless Regexp.new(pattern) =~ item

          FileUtils.mkdir_p(output_dir + subdir.to_s) unless File.directory?(File.join('output', subdir.to_s))
          FileUtils.copy(item, File.join(File.join('output', subdir.to_s), item.to_s))
          command = cpy_cmd + "#{item} " + output_dir + subdir.to_s + '/' + item.to_s
          LogIt.log_it "copying resource #{item} with '#{command}'..."
          `#{command}`
        end
      end
    end
    LogIt.log_it('End copying resources...')
  end

  def build_srs
    puts 'Attempting to build SRS...'
    LogIt.log_build
    clear_output

    puts "Assembling markdown files..."
    markdown_str = assembled_markdown

    puts "Copying other resources..."
    copy_resources
    FileUtils.touch(SINGLE_TMP_MD_RELATAIVE_FILEPATH)
    markdown_str += "\nDocument Generated: #{@datestamp} (build #{@build_number})"

    temp_compiled_markdown_file = File.new(SINGLE_TMP_MD_RELATAIVE_FILEPATH, 'w')
    temp_compiled_markdown_file.write(markdown_str)
    temp_compiled_markdown_file.close
    
    puts "Compiling markdown..."
    PandocHelper.build_standard_output(SINGLE_TMP_MD_RELATAIVE_FILEPATH, OUTPUT_LOCATION)

    FileUtils.remove(SINGLE_TMP_MD_RELATAIVE_FILEPATH)

    srs_html_file = File.new("#{Dir.pwd}/#{OUTPUT_LOCATION}", 'r')
    srs_html_file_contents = srs_html_file.read
    srs_html_file.close

    srs_html_file_contents.gsub!(/srs.css/, 'css/srs.css')

    srs_html_file_w = File.new("#{Dir.pwd}/#{OUTPUT_LOCATION}", 'w')
    srs_html_file_w.write(srs_html_file_contents)
    srs_html_file_w.close

    puts 'Done!'
    puts "Output is at #{OUTPUT_LOCATION}."
    true
  end
end
