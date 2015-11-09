require 'open-uri'
require 'nokogiri'
require 'fileutils'
require 'challonge-api'
require 'net/https'

class Getter 
		attr_reader :api
		attr_reader :melee
		attr_reader :smash4
	def initialize
		File.open('api.txt') do |e| 
			#1 is brian, 2 is me
			@api =  e.to_a[0].delete!("\n")
		end
		Challonge::API.username = 'briantse6'
		Challonge::API.key = @api
		FileUtils::mkdir_p "tourn/"
		@melee = Array.new
		@smash4 = Array.new
	end
	#394 IS MELEE'S CODE
	def call 
		list = Challonge::Tournament.find(:all, :params => {:created_after => "2015-09-09"})
		list.each do |i|
			#update to game codes
			i.name.include?("Melee") ? @melee << i : nil
			i.name.include?("Smash 4") ? @smash4 << i : nil
		end
	end
	def write(game)
		game.downcase!

		matches = Array.new
		if (game.include?("melee"))
			matches = @melee
		elsif (game.include?("smash4"))
			matches = @smash4
		end	

		FileUtils::mkdir_p "tourn/#{game}/"
		matches.each do |i|
			FileUtils::mkdir_p "tourn/#{game}/#{i.url}/matches"
			File.open("tourn/#{game}/#{i.url}/info.json", "w") do |file| 
				file.write(i.to_json)
			end
			i.matches.each { |match| 
				File.open("tourn/#{game}/#{i.url}/matches/#{match.id}.json", "w") do |file|
					file.write(match.to_json)
				end
			}
			FileUtils::mkdir_p "tourn/#{game}/#{i.url}/part"
			i.participants.each { |part|
				File.open("tourn/#{game}/#{i.url}/part/#{part.name}.json", "w") do |file|
					file.write(part.to_json)
				end
			}
		end
	end


	def test 

	end
end

get = Getter.new

get.call
get.write("melee")
