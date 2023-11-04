class SRSBuildAnnouncer
  def self.announce_starting_build
    puts "Attempting to build SRS..."
  end

  def self.announce_assembling_markdown
    puts "Assembling Markdown files..."
  end

  def self.announce_copying_resources
    puts "Copying other resources..."
  end

  def self.announce_compiling_markdown
    puts "Compiling Markdown..."
  end

  def self.announce_compiling_srsgem_specific_md
    puts "Compiling SRSGem specific Markdown..."
  end

  def self.announce_done
    puts "Done!"
  end

  def self.announce_output_location(location)
    puts "Output is at #{location}."
  end
end
