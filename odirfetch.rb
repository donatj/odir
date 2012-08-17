#!/usr/bin/env ruby

require 'net/http'
require 'uri'

raise RuntimeError, 'Please provide a URL as Argument 1' unless ARGV[0] =~ /\Ahttps?:\/\//i

puts "Scanning..."

uri  = URI.parse(ARGV[0])

begin
	page = Net::HTTP.get( uri )	
rescue
	puts "Failed to connect to host"
	exit
end

puts "Starting..."

def download( uri, path )
	Net::HTTP.start( uri.host, uri.port ) do |http|
		irupt         = false
		size          = 0
		contentlength = nil
		begin
			file = File.open(path, 'wb')
			http.request_get('/' + ( uri.path ) ) do |response|

				contentlength = response['content-length'].to_i if response['content-length']

				response.read_body do |segment|
					size += segment.length 
					yield size, contentlength
					file.write(segment)
				end
			end
		rescue SystemExit, Interrupt
			irupt = true
		rescue Exception => e
			# Do Something Here?
		ensure
			if file and File.exists?(path) and not irupt
				if contentlength
					if contentlength <= size
						return {'status' => :success, 'contentlength' => contentlength, 'size' => size}
					end
				else
					return {'status' => :unconfirmable, 'size' => size}
				end
			end

			if File.exists?(path)
				File.unlink(path)
			end

			if irupt
				puts ''
				puts 'User Interrupt'
				exit
			end

			return {'status' => :error, 'contentlength' => contentlength, 'size' => size}
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

			if result['status'] != :error
				puts "\033[0;32m - Done!\033[0m"
				break
			elsif i < 2
				puts "\033[0;35m - Error Downloading, Retrying\033[0m"
				print result['msg'] if result['msg']
				p result
			else
				puts "\033[0;31m - Download Failed\033[0m"
			end
		end
		downloaded.push(path)
	end
end

puts "Finished!"