class PandocHelper

  DEFAULT_PANDOC_COMMAND = 'pandoc'

  @@pandoc_build_command = DEFAULT_PANDOC_COMMAND
  @@pandoc_build_command_prefix = "#{@@pandoc_build_command} -s -o "

  CSS_TERM = 'css'
  CSS_TITLE = 'srs'
  CSS_FILE = "#{CSS_TITLE}.#{CSS_TERM}"

  STANDARD_TITLE_FILE = 'title.yml'

  OUTPUT_FLAGS = {
    html: 'html',
    table_of_contents: '--toc'
  }

  def self.build_standard_output(markdown_relative_filepath, output_relative_filepath)
    cmd = @@pandoc_build_command_prefix +
          output_relative_filepath    + ' ' +
          OUTPUT_FLAGS[:table_of_contents] + ' ' +
          STANDARD_TITLE_FILE + ' ' +
          "--css #{CSS_FILE} " +
          markdown_relative_filepath
    `#{cmd}`
  end

end