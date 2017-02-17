# encoding: utf-8

require_relative 'cloudhub_api'
require_relative 'sincedb'

require "logstash/inputs/base"
require "logstash/namespace"
require "stud/interval"
require "fileutils"
require "socket"

# This input plugin reads log messages from the Anypoint REST API.
# You don't need to configure your environments/applications, the
# plugin will fetch all.
class LogStash::Inputs::Cloudhub < LogStash::Inputs::Base
  config_name "cloudhub"

  # Organization ID of the Anypoint company account
  config :organization_id, :validate => :string
  
  # Anypoint user name
  config :username, :validate => :string
  
  # Anypoint password
  config :password, :validate => :string
  
  # Interval (in seconds) between two log fetches.
  # (End of previous fetch to start of next fetch)
  # Default value: 300
  config :interval, :validate => :number, :default => 300
  
  # How many events should be fetched in one REST call?
  # Default: 100
  config :events_per_call, :validate => :number, :default => 100

  # Host name of web proxy
  config :proxy_host, :validate => :string
  
  # Port of web proxy
  config :proxy_port, :validate => :number
  
  # User name of web proxy
  config :proxy_username, :validate => :string
  
  # Password of web proxy
  config :proxy_password, :validate => :string

  default :codec, "plain"

  public
  def register
    @host = Socket.gethostname
    @sincedb = SinceDB.new
  end

  def run(queue)
    api = CloudhubAPI.new @logger, @organization_id, @username, @password, @events_per_call, @proxy_host, @proxy_port, @proxy_username, @proxy_password

    while !stop?
        
      # get the token once per main loop (more efficient than fetching it for each API call)
      token = api.token()
        
      environments = api.environments(token)
      environments.each do |environment|
        applications = api.apps(environment, token)
        applications.each do |application|
          application_name = application['domain']
          begin
            @logger.info("Fetching logs for " + application_name)
            
            first_start_time = @sincedb.read application_name
            start_time = first_start_time
            while !stop?
              logs = api.logs(start_time, environment['id'], application_name, token)
              break if logs.empty?
              
              start_time = logs[-1]['event']['timestamp'] + 1
              push_logs logs, environment['name'], application_name, queue
            end
          rescue => exception
            puts exception.backtrace
          end
          if (start_time > first_start_time)
            @sincedb.write application_name, start_time
          end
          break if stop?
        end
        break if stop?
      end
      Stud.stoppable_sleep(@interval) { stop? }
    end
  end

  def push_logs logs, environment, domain, queue
    for log in logs do
      event = log['event']
      log_event = LogStash::Event.new(
        'host' => @host,
        'environment' => environment,
        'application' => domain,

        'deploymentId' => log['deploymentId'],
        'instanceId' => log['instanceId'],
        'recordId' => log['recordId'],

        'line' => log['line'],
        'loggerName' => event['loggerName'],
        'threadName' => event['threadName'],
        'priority' => event['priority'],
        'timestamp' => event['timestamp'],
        'message' => event['message']
      )
      decorate(log_event)
      queue << log_event
    end
  end

  def stop
    @logger.info("Stopping CloudHub plugin")
  end
  
end
