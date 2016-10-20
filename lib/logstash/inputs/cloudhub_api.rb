# encoding: utf-8

require "net/http"
require "json"

class CloudhubAPI
  def initialize domain, username, password
    @domain = domain
    @username = username
    @password = password
  end

  def token
    uri = URI.parse('https://anypoint.mulesoft.com/accounts/login')

    client = Net::HTTP.new(uri.host, uri.port)
    client.use_ssl = true

    request = Net::HTTP::Post.new(uri.request_uri)
    request.body = URI.encode_www_form({ 
      "username" => @username, 
      "password" => @password 
    })

    response = client.request(request)
    return JSON.parse(response.body)['access_token']
  end

  def logs startTime
    uri = URI.parse("https://anypoint.mulesoft.com/cloudhub/api/v2/applications/#{@domain}/logs")

    client = Net::HTTP.new(uri.host, uri.port)
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

    response = client.request(request)
    return JSON.parse(response.body)
  end
end
