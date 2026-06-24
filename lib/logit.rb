require 'yaml'
require_relative 'srsgem_project'

class LogIt
  def self.log_it(string)
    file_object = File.new(SRSGemProject.file_path('build.log'), 'a')
    file_object.write("#{@datestamp}: #{string} \n")
    file_object.close
  end

  def self.log_build
    build_number_path = SRSGemProject.file_path('build-number.yml')
    build_number_file_reader = File.new(build_number_path, 'r')
    yml = build_number_file_reader.read
    build_number_file_reader.close

    yml_obj = YAML.load(yml.to_s)
    build_num_string = yml_obj['last_build']['number']
    n = build_num_string.to_i
    @build_number = n.to_s
    yml_obj['last_build']['number'] = @build_number
    @datestamp = Time.now
    yml_obj['last_build']['date'] = @datestamp.to_s

    build_number_file_writer = File.new(build_number_path, 'w')
    build_number_file_writer.write(yml_obj.to_yaml)
    build_number_file_writer.close

    log_it '================================================'
    log_it "Build Number: #{@build_number}"
    log_it "YAML after mods: #{yml_obj.inspect}"
  end
end