#!/usr/bin/env ruby

require 'net/http'
require 'uri'

raise RuntimeError, 'Please provide a URL as Argument 1' unless ARGV[0] =~ /\Ahttps?:\/\//i

puts "Scanning..."

uri  = URI.parse(ARGV[0])
page = Net::HTTP.get( uri )

puts "Starting..."

def download( uri, path )

	Net::HTTP.start( uri.host, uri.port ) do |http|
		size = 0;
		begin
			file = open(path, 'wb')
			http.request_get('/' + uri.path) do |response|
				response.read_body do |segment|
					size += segment.length
					yield size
					file.write(segment)
				end
			end
		ensure
			file.close
		end
	end

end

files = page.scan(/<a.*?href="([^?][^\/]+?)".*?>(.+?)<\/a>/i)

if files.length == 0
	puts "No Files Found"
	exit 1
end

if uri.path.to_s =~ /\/([^\/]*?)\/*$/
	dir = "OpenDir " + URI.unescape($~[1])
else
	dir = "OpenDir " + Time.now.to_s
end

Dir.mkdir( dir )

files.each do |x|

	file = URI.parse(x[0])
	if !file.scheme
		file.scheme = uri.scheme
		file.host   = uri.host
		file.path   = (uri.path + '/').gsub(/\/\/$/, '/') + file.path
		
		print "\0337"

		download(file, dir + '/' + x[1]) do |size|
			kb = (size / 1000).floor
			print "\0338"
			print "Downloading #{x[1]} " + kb.to_s + ' kb'
		end

		puts
		puts "Done!"
	end
end