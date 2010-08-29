require "FileUtils"
require "rubygems"
require "sinatra"

TMP_DIR_INGOING_FILES = File.dirname(__FILE__)+"/tmp/ingoing_files"
TMP_DIR_OUTGOING_FILES = File.dirname(__FILE__)+"/tmp/outgoing_files"

set :bind, "0.0.0.0"
set :public, Proc.new { TMP_DIR_OUTGOING_FILES }

before do
	FileUtils.mkpath(TMP_DIR_INGOING_FILES)
	FileUtils.mkpath(TMP_DIR_OUTGOING_FILES)
end

get "/" do
  "utoco says hello to my friend Andy :) ..... please use: /mp3/YOUTUBE-WATCH-V-ID"
end

get "/:format/:video_id" do
  video_id = params[:video_id]
  url = "http://www.youtube.com/watch?v=#{video_id}"
  begin
		fetch_ingoing :url => url do |ingoing_file|
		  convert({:ingoing_file => ingoing_file, :format => params[:format]}) do |outgoing_file|
		    redirect "/#{outgoing_file}"
		  end
	  end
	rescue => e
		puts e.to_s
    e.to_s
  end
end

helpers do
	def fetch_ingoing(opts = {:url => nil})
		raise ArgumentError "No url given" unless opts[:url]
	  fetch_command =  "./vendor/youtube-dl/youtube-dl -i -o '#{TMP_DIR_INGOING_FILES}/%(stitle)s.%(ext)s' #{opts[:url]}"
	  puts "PROCESSING: #{fetch_command}"
		IO.popen(fetch_command) do |io|
			ingoing_file = nil
			io.each do |line|
				puts "Progress: #{line}"
				if match = line.chomp.match(/.download. Destination: (.*)/)
					ingoing_file = match.captures.first
				end
			end
			if ingoing_file
			  yield(ingoing_file)
			else
				raise "Could not fetch ingoing file"
			end
		end
  rescue => e
	  raise "Fetching ingoing failed: #{e}"
	end

	def convert(opts = {:ingoing_file => nil, :format => "mp3"})
	  raise ArgumentError, "No ingoing file given" unless opts[:ingoing_file]
		raise ArgumentError,"No format given" unless opts[:format]
		
		filename = File.basename(opts[:ingoing_file]).sub(File.extname(opts[:ingoing_file]))
	  outgoing_file = "#{TMP_DIR_OUTGOING_FILES}/}.#{format.to_s}"
	
	  case opts[:format]
	  when "mp3"
			IO.popen "ffmpeg -ab 192k -i #{ingoing_file} #{outgoing_file}" do |io|
				io.each do |line|
					puts "Progress: #{line}"
				end
				yield(outgoing_file)
			end
		else
	    raise ArgumentError, "Unsupported format: '#{opts[:format]}'"
	  end
	rescue => e
		puts e.backtrace
		raise "Converting ingoing file failed: #{e}"
	end
end