# encoding: utf-8

require "net/http"
require "json"

class CloudhubAPI
  def initialize logger, username, password, environments, events_per_call, proxy_host=nil, proxy_port=nil, proxy_username=nil, proxy_password=nil
    @logger = logger
    @username = username
    @password = password
    @environments = environments
    @events_per_call = events_per_call
    @proxy_host=proxy_host
    @proxy_port=proxy_port
    @proxy_username=proxy_username
    @proxy_password=proxy_password

    uri = URI.parse("https://anypoint.mulesoft.com/accounts/api/me")

    client = Net::HTTP.new(uri.host, uri.port, @proxy_host, @proxy_port, @proxy_username, @proxy_password)
    client.use_ssl = true

    request = Net::HTTP::Get.new(uri.request_uri)
    request.add_field("Authorization", "Bearer #{token}")
    response = client.request(request)

    body = JSON.parse(response.body)
    @organization_id = body['user']['organization']['id']
    @logger.info('Organisation ID: ' + @organization_id)
  end

  def token
    uri = URI.parse('https://anypoint.mulesoft.com/accounts/login')

    client = Net::HTTP.new(uri.host, uri.port, @proxy_host, @proxy_port, @proxy_username, @proxy_password)
    client.use_ssl = true

    request = Net::HTTP::Post.new(uri.request_uri)
    request.body = URI.encode_www_form({
      "username" => @username,
      "password" => @password
    })

    response = client.request(request)
    return JSON.parse(response.body)['access_token']
  end

  # Returns an array of hashes, sample hash:
  # {"id"=>"...", "name"=>"prod", "organizationId"=>"...", "isProduction"=>true}
  def environments cached_token=token
    uri = URI.parse("https://anypoint.mulesoft.com/accounts/api/organizations/#{@organization_id}")

    client = Net::HTTP.new(uri.host, uri.port, @proxy_host, @proxy_port, @proxy_username, @proxy_password)
    client.use_ssl = true

    request = Net::HTTP::Get.new(uri.request_uri)
    request.add_field("Authorization", "Bearer #{cached_token}")
    response = client.request(request)

    body = JSON.parse(response.body)
    if @environments.to_s.strip.length == 0
      regexp = nil
    else
      regexp = Regexp.new(@environments)
    end
    environments = Array.new
    body['environments'].each do |environment|
      id = environment['id']
      name = environment['name']
      if (regexp == nil || regexp.match(name))
        environments << { 'id' => id, 'name' => name }
      end
    end
    return environments
  end

  # Returns an array of hashes, for us is interesting:
  # { "domain"=>"my_name", "fullDomain"=>"my_name.eu.cloudhub.io", ... }
  def apps environment, cached_token=token
    uri = URI.parse("https://anypoint.mulesoft.com/cloudhub/api/v2/applications")
    client = Net::HTTP.new(uri.host, uri.port, @proxy_host, @proxy_port, @proxy_username, @proxy_password)
    client.use_ssl = true

    request = Net::HTTP::Get.new(uri.request_uri)
    request.add_field("Authorization", "Bearer #{cached_token}")
    request.add_field("X-ANYPNT-ENV-ID", environment['id'])

    response = client.request(request)

    return JSON.parse(response.body)
  end

  def logs startTime, environment_id, application, cached_token=token
    uri = URI.parse("https://anypoint.mulesoft.com/cloudhub/api/v2/applications/#{application}/logs")

    client = Net::HTTP.new(uri.host, uri.port, @proxy_host, @proxy_port, @proxy_username, @proxy_password)
    client.use_ssl = true

    request = Net::HTTP::Post.new(uri.request_uri)
    request.add_field("Authorization", "Bearer #{cached_token}")
    request.content_type = 'application/json'
    request.body = JSON.generate({
      :startTime => startTime,
      :endTime => java.lang.Long::MAX_VALUE,
      :limit => @events_per_call,
      :descending => false
    })
    request.add_field("X-ANYPNT-ENV-ID", environment_id)
    retries = 10
    while retries > 0
      response = client.request(request)
      begin
        parsed_logs = JSON.parse(response.body)
        return parsed_logs
      rescue
        retries -= 1
        if (retries == 0)
          @logger.error("Can't parse logs: " + response.body)
        end
        Stud.stoppable_sleep(5)
      end
    end
    return []
  end
end
