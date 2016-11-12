require "digest/md5"

class SinceDB
    def initialize folder=nil, file_prefix='sincedb_'
        @folder = folder
        if @folder.to_s.strip.length == 0
            @folder = File.join(Dir.home, ".logstash-input-cloudhub")
        end

        @file_prefix = file_prefix
    end

    def write domain, content
        FileUtils::mkdir_p @folder

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
        File.join(@folder, @file_prefix + Digest::MD5.hexdigest(domain))
    end
end