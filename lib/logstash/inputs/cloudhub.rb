# encoding: utf-8

require_relative 'cloudhub_api'

require "logstash/inputs/base"
require "logstash/namespace"
require "stud/interval"
require "digest/md5"
require "fileutils"
require "socket"

class LogStash::Inputs::Cloudhub < LogStash::Inputs::Base
  config_name "cloudhub"

  config :domain, :validate => :string
  config :username, :validate => :string
  config :password, :validate => :string
  config :interval, :validate => :number, :default => 300
  config :environment_id, :validate => :string, :default => ""
  config :startTime, :validate => :number, :default => 0

  default :codec, "plain"

  public
  def register
    @host = Socket.gethostname
    FileUtils::mkdir_p sincedb_folder

    sincedb_path = construct_sincedb_path(@domain)
    if File.exists? sincedb_path
      File.open(sincedb_path, "r") { |file| 
          sincedb_startFrom = file.read.to_i
          if sincedb_startFrom > @startTime
            @startTime = sincedb_startFrom
          end 
        }
      end
  end

  def run(queue)
    api = CloudhubAPI.new @domain, @username, @password

    while !stop?
      loop do
        logs = api.logs(@startTime, @environment_id)
        break if logs.empty?

        for log in logs do
          queue << LogStash::Event.new(
            'message' => JSON.generate(log),
            'host' => @host
          )
        end

        @startTime = logs[-1]['event']['timestamp'] + 1
      end

      File.open(construct_sincedb_path(@domain), "w") { |file| file.write(@startTime) }

      Stud.stoppable_sleep (@interval) { stop? }
    end
  end

  def stop
  end

  private 
  def sincedb_folder
    File.join(Dir.home, ".logstash-input-cloudhub")
  end

  def construct_sincedb_path domain
    File.join(sincedb_folder, "sincedb_" + Digest::MD5.hexdigest(domain))
  end
end