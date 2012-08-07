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
		contentlength = nil
		begin
			file = open(path, 'wb')
			http.request_get('/' + ( uri.path ) ) do |response|

				contentlength = response['content-length'].to_i if response['content-length']

				response.read_body do |segment|
					size += segment.length 
					yield size, contentlength
					file.write(segment)
				end
			end
		rescue
			if file
				file.close
				File.unlink(path)
			end
		ensure
			if file
				file.close
				if contentlength
					if contentlength >= File.size(path)
						return :success
					else
						File.unlink(path)
						return :error
					end
				else
					return :unconfirmable
				end
			else
				return :error
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

	path = dir + URI.decode(lastbit.match( file.path )[0]);
	if not downloaded.include? path and not File.exists? path
		print "\0337"

		for i in 0..2

			result = download(file, path) do |size, maxlength|
				kb      = (size / 1000).floor
				percent = ((size.to_f / maxlength.to_f) * 100).floor if maxlength 
				
				print "\0338"
				print "Downloading #{path} " + kb.to_s + ' kb'
				print " #{percent}%" if maxlength
			end

			if result != :error
				puts " - Done!"
			elsif i < 2
				puts " - Error Downloading, Retrying"
			else
				puts " - Download Failed"
			end
				

		end
		downloaded.push(path)
	end
end

puts "Finished!"