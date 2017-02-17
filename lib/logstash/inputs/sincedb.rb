# encoding: utf-8

class SinceDB
  def initialize folder=nil, file_prefix='sincedb-'
    
    @folder = folder
    if @folder.to_s.strip.length == 0
      @folder = ::File.join(LogStash::SETTINGS.get('path.data'), 'plugins', 'cloudhub')
      FileUtils::mkdir_p(@folder)
    end
  
    @file_prefix = file_prefix
  end
  
  def write domain, content
    file_path = construct_file_path(domain)
    File.open(file_path, "w") { |file| file.write(content) }
  end
  
  def read domain
    result = 0
    file_path = construct_file_path(domain)
    if File.exists? file_path
        result = File.open(file_path, 'r') { 
            |file| file.read.to_i 
        }
    end
  
    return result
  end
  
  private
  def construct_file_path domain
    File.join(@folder, @file_prefix + sanitize(domain))
  end
  
  private
  def sanitize(filename)
    # Remove any character that aren't 0-9, A-Z, a-z, or -
    filename.gsub(/[^0-9A-Z\\-]/i, '_')
  end
end

