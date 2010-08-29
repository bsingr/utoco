require "rubygems"
require "capybara/dsl"

include Capybara

Capybara.current_driver = :selenium
Capybara.app_host = 'http://www.youtube.com'

def show_video(video_id)
  visit "/watch?v=#{video_id}"
end