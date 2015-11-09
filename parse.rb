require 'json'
require 'fileutils'
require 'challonge-api'

class Parser

	class Member
		attr_reader :name
		attr_reader :id
		attr_reader :place
		def initialize(name, id, place)
			@name = name
			@id = id 
			@place = place
		end

		def to_s 
			"Name: " + @name + "\n\tPlace: "+ @place.to_s + "\n\tId: " + @id
		end
	end

	def initialize(str)
		str.include?("melee") ? @game = "melee" : nil
		str.include?("smash4") ? @game = "smash4" : nil
		@places = Array.new
 	end

	def raw_results
		tourn = Array.new
		place = Array.new
		Dir.foreach("tourn/#{@game}") { |file|
			tourn << file
		}
		tourn.slice!(0..1)
		tourn.each do |i|
			place = Array.new
			path = "tourn/#{@game}/#{i}/part/"
			members = Dir.new(path).to_a[2..-1]
			members.each do |file|
				json = ""
				File.open(path + file).each do |l| json = l end
				test = JSON.parse(json)["participant"]
				place << Member.new(test["name"].to_s, test["id"].to_s, test["final_rank"].to_i)
			end
			@places << {i => place}
		end
	end

	def write_results

		@places.each do |hs|
			raw_place = hs[hs.keys[0]].to_a
			test = Proc.new { |mem| mem.place }

			raw_place.sort_by!(&test)
 				
 			raw_place.each{ |i|
 				puts i.to_s
 			}

			# hs.keys.each { |name|
			# 	File.open("tourn/#{name}/results.txt", "w").each { |file|

			# 	}
			# } 
		end
	end 
end

parse = Parser.new("melee")
parse.raw_results
parse.write_results