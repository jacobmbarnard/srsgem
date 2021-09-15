class LogIt
  def self.log_it(string)
    file_object = File.new("#{Dir.pwd}/build.log", 'a')
    file_object.write("#{@datestamp}: #{string} \n")
    file_object.close
  end

  def self.log_build
    build_number_file_reader = File.new("#{Dir.pwd}/build-number.yml", 'r')
    yml = build_number_file_reader.read
    build_number_file_reader.close

    yml_str = yml.to_s
    yml_obj = YAML.load(yml_str)
    build_num_string = yml_obj['last_build']['number']
    n = build_num_string.to_i(16)
    n += 0x1
    @build_number = n.to_s(16)
    yml_obj['last_build']['number'] = @build_number
    @datestamp = Time.now
    yml_obj['last_build']['date'] = @datestamp.to_s

    # Write the build number to the YAML file which tracks
    # the build number for number of times SRS has been compiled...
    build_number_file_writer = File.new("#{Dir.pwd}/build-number.yml", 'w')
    build_number_file_writer.write(yml_obj.to_yaml)
    build_number_file_writer.close

    # Write the build number to the log debug log file...
    log_it '================================================'
    log_it "Build Number: #{@build_number}"
    log_it "YAML after mods: #{yml_obj.inspect}"
  end
end