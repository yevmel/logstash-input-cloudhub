# encoding: utf-8

require_relative 'cloudhub_api'
require_relative 'sincedb'

require "logstash/inputs/base"
require "logstash/namespace"
require "stud/interval"
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

  config :proxy_host, :validate => :string
  config :proxy_port, :validate => :number
  config :proxy_username, :validate => :string
  config :proxy_password, :validate => :string

  default :codec, "plain"

  public
  def register
    @host = Socket.gethostname
    @sincedb = SinceDB.new

    startTimeSinceDB = @sincedb.read @domain
    if startTimeSinceDB > @startTime
      @startTime = startTimeSinceDB
    end
  end

  def run(queue)
    api = CloudhubAPI.new @domain, @username, @password, @proxy_host, @proxy_port, @proxy_username, @proxy_password

    while !stop?
      loop do
        logs = api.logs(@startTime, @environment_id)
        break if logs.empty?

        for log in logs do
          event = LogStash::Event.new(
            'message' => JSON.generate(log),
            'host' => @host
          )

          decorate(event)
          queue << event
        end

        @startTime = logs[-1]['event']['timestamp'] + 1
      end

      @sincedb.write @domain, @startTime
      Stud.stoppable_sleep (@interval) { stop? }
    end
  end

  def stop
  end
end
