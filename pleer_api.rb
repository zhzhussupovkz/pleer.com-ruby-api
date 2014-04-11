=begin
/*

The MIT License (MIT)

Copyright (c) 2014 Zhussupov Zhassulan zhzhussupovkz@gmail.com

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

*/
=end

require 'net/http'
require 'base64'
require 'json'

class PleerApi

  def initialize login, password
    @login, @password = login, password
    @token_url = 'http://api.pleer.com/token.php'
    @api_url = 'http://api.pleer.com/index.php'
    @access_token = {}
    @exp = Time.now.to_i
    get_access_token
  end

  #get access token for api requests
  def get_access_token
    uri = URI.parse(@token_url)
    http = Net::HTTP.new(uri.host, uri.port)
    req = Net::HTTP::Post.new(uri.request_uri)
    auth = Base64.encode64(@login + ':' + @password).gsub("\n", "")
    req['Authorization'] = "Basic #{auth}"
    send = 'grant_type=client_credentials'
    req.body = send
    res = http.request(req)
    if res.code == "200"
      data = res.body
      result = JSON.parse(data)
      @access_token = result['access_token']
    else
      puts "Invalid getting access token"
      exit
    end
  end

  #send request to the server
  def send_request method, params = {}
    uri = URI.parse(@api_url)
    if Time.now.to_i > @exp + 3600
      get_acces_token
      @exp = Time.now.to_i
    end
    required = { 'access_token' => @access_token, 'method' => method }
    params = required.merge(params)
    params = URI.escape(params.collect{ |k,v| "#{k}=#{v}"}.join('&'))
    http = Net::HTTP.new(uri.host, uri.port)
    req = Net::HTTP::Post.new(uri.request_uri)
    req['User-Agent'] = "zhzhussupovkz pleer.com-ruby-api"
    req.body = params
    res = http.request(req)
    if res.code == "200"
      data = res.body
      result = JSON.parse(data)
    else
      puts "Invalid getting data from server"
      exit
    end
  end

  #search track by search term
  def tracks_search params = { :query => 'love', :page => 1 }
    json = send_request 'tracks_search', params
    if json['success'] == true
      json['tracks']
    else
      puts "Error: " + json['message']
      exit
    end
  end

  #get info about track
  def tracks_get_info params = { :track_id => nil }
    json = send_request 'tracks_get_info', params
    if json['success'] == true
      json['data']
    else
      puts "Error: " + json['message']
      exit
    end
  end

  #get track's lyrics
  def tracks_get_lyrics params = { :track_id => nil }
    json = send_request 'tracks_get_lyrics', params
    if json['success'] == true
      json['text']
    else
      puts "Error: " + json['message']
      exit
    end
  end

  #get download link for track
  def tracks_get_download_link params = { :track_id => nil, :reason => 'save' }
    json = send_request 'tracks_get_download_link', params
    if json['success'] == true
      json['url']
    else
      puts "Error: " + json['message']
      exit
    end
  end

  #get top tracks for period
  def get_top_list params = { :list_type => 1, :page => 1, :language => 'en' }
    json = send_request 'get_top_list', params
    if json['success'] == true
      json['tracks']
    else
      puts "Error: " + json['message']
      exit
    end
  end

end
