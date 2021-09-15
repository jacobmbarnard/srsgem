require 'fileutils'

class SRSGemCleaner
  def self.clean
    if Dir.exist?("#{Dir.pwd}/output")
      FileUtils.remove_dir("#{Dir.pwd}/output")
    else
      puts "Already clean."
    end
    return true
  end
end
