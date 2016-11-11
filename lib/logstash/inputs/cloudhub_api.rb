# encoding: utf-8

require "net/http"
require "json"

class CloudhubAPI
  def initialize domain, username, password, proxy_host=nil, proxy_port=nil, proxy_username=nil, proxy_password=nil
    @domain = domain
    @username = username
    @password = password
    @proxy_host=proxy_host
    @proxy_port=proxy_port
    @proxy_username=proxy_username
    @proxy_password=proxy_password
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

  def logs startTime, environment_id=nil
    uri = URI.parse("https://anypoint.mulesoft.com/cloudhub/api/v2/applications/#{@domain}/logs")

    client = Net::HTTP.new(uri.host, uri.port, @proxy_host, @proxy_port, @proxy_username, @proxy_password)
    client.use_ssl = true

    request = Net::HTTP::Post.new(uri.request_uri)
    request.add_field("Authorization", "Bearer #{token}")
    request.content_type = 'application/json'
    request.body = JSON.generate({
      :startTime => startTime,
      :endTime => java.lang.Long::MAX_VALUE,
      :limit => 100,
      :descending => false
    })

    if environment_id.to_s.strip.length > 0
      request.add_field("X-ANYPNT-ENV-ID", environment_id)
    end

    response = client.request(request)
    return JSON.parse(response.body)
  end
end
