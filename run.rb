#!/usr/bin/env ruby
# encoding: utf-8

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

require 'optparse'
require 'open-uri'
require_relative 'pleer_api'

options = {}
path = 'music'

optparse = OptionParser.new do |opts|
  opts.banner = "Command-line tool for downloading mp3 music from https://www.pleer.com\n"
  opts.banner += "Copyright (c) 2014 Zhussupov Zhassulan zhzhussupovkz@gmail.com\n"
  opts.banner += "While using this program, get API key from https://www.pleer.com.\n"
  opts.banner += "Usage: run.rb [options]"

  opts.on('-h', '--help', "help page") do
    puts opts
    exit
  end

  opts.on('-q', '--query QUERY', "Search for music by search term") do |q|
    options[:query] = q
  end

  opts.on('-d', '--directory DIRECTORY', "Folder, which will be downloaded music files") do |dir|
    path = dir
  end

  opts.on('-p', '--page PAGE', "Specify result page(index). Default value: 1") do |page|
    options[:page] = page
  end

end

optparse.parse!
if options.empty?
  p optparse
  exit
end

if not path or path == false
  path = 'music'
end

path = File.dirname(__FILE__) + '/' + path.to_s
Dir.mkdir(path) unless File.exists?(path)

pleer = PleerApi.new 'username', 'password'

threads = []

t1 = Time.now
tracks = pleer.tracks_search options
query = options[:query]
puts "Found " + tracks.length.to_s + " music files for search query: #{query}."
all = []
tracks.each_with_index do |e, i|
  all << e[1]['id']
end
puts "Start downloading music files to " + path.to_s + " directory."
all.each do |id|
  threads << Thread.new do
    begin
      url = pleer.tracks_get_download_link params = { :track_id => id, :reason => 'save' }
      filename = File.basename url
      filename = query.gsub(' ', '_') + '_' + filename.gsub('/.mp3/', "#{id}.mp3")
      open(url, 'rb') do |track|
        File.new("#{path}/#{filename}", 'wb').write(track.read)
        puts "Music file '" + filename + "': OK" 
      end
    rescue Exception => e
      next
    end
  end
end

threads.each do |th|
  th.join
end

t2 = Time.now
msecs = ((t2-t1).round(2)).to_s
puts "Successfully downloaded " + tracks.length.to_s + " music files at #{msecs} sec."
