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
			http.request_get('/' + URI.encode( uri.path ) ) do |response|
				response.read_body do |segment|
					size += segment.length
					yield size
					file.write(segment)
				end
			end
		ensure
			if file
				file.close
			else
				puts 'Invalid file handle ' + path
				exit
			end
		end
	end

end

files = page.scan(/<a.*?href="([^?][^\/]+?)".*?>(.+?)<\/a>/i)

if files.length == 0
	puts "No Files Found"
	exit 1
end

lastbit = /\/([^\/]*?)\/*$/;

if uri.path.to_s =~ lastbit
	dir = "OpenDir " + URI.unescape($~[1])
else
	dir = "OpenDir " + Time.now.to_s
end

Dir.mkdir( dir ) if not Dir.exists?( dir )

downloaded = []

files.each do |x|

	file = URI.join(uri.to_s, x[0])

	path = dir + lastbit.match( file.path )[0];
	if not downloaded.include? path
		print "\0337"

		download(file, path) do |size|
			kb = (size / 1000).floor
			print "\0338"
			print "Downloading #{path} " + kb.to_s + ' kb'
		end

		puts
		puts "Done!"
		downloaded.push(path)
	end
end