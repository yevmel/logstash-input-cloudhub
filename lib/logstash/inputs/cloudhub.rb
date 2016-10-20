# encoding: utf-8

require_relative 'cloudhub_api'

require "logstash/inputs/base"
require "logstash/namespace"
require "stud/interval"
require "socket"

class LogStash::Inputs::Cloudhub < LogStash::Inputs::Base
  config_name "cloudhub"

  config :domain, :validate => :string
  config :username, :validate => :string
  config :password, :validate => :string
  config :interval, :validate => :number, :default => 300
  config :startTime, :validate => :number, :default => 0

  default :codec, "plain"

  public
  def register
    @host = Socket.gethostname
  end

  def run(queue)
    api = CloudhubAPI.new @domain, @username, @password

    while !stop?
      loop do
        logs = api.logs(@startTime)
        break if logs.empty?

        for log in logs do
          queue << LogStash::Event.new(
            'message' => JSON.generate(log),
            'host' => @host
          )
        end

        @startTime = logs[-1]['event']['timestamp'] + 1
      end

      Stud.stoppable_sleep (@interval) { stop? }
    end
  end

  def stop
  end
end