require 'json'
require 'fileutils'
require 'challonge-api'

class Parser
	attr_reader :tourns
	attr_reader :game
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
			"Name: " + @name + "\n\tPlace: "+ @place.to_s + "\n\tId: " + @id + "\n"
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
			@tourns = tourn
		end
	end

	def write_results
		sorter = Proc.new { |mem| mem.place }
		@places.each do |hs|
			File.open("tourn/#{@game}/#{hs.keys[0]}/results.json", "w") do |line|
				raw_place = hs[hs.keys[0]].to_a
				raw_place.sort_by!(&sorter)
				line << raw_place.to_json
			end


			# raw_place = hs[hs.keys[0]].to_a
			# test = Proc.new { |mem| mem.place }
			# raw_place.sort_by!(&sorter)
			# File.open("tourn/#{@game}/#{hs.keys[0]}/results.txt", "w") do |line|
			# 		raw_place.each do |i|
			# 			line << i.to_s
			# 	end
			# end
		end
	end 

	def total_results
		all = Array.new
		format = lambda do |name, event| 
			hs = {"#{name}" => []}
			hs["#{name}"] << event
			return hs
		end

		check = lambda do |ary, name|
			ary.each_with_index do |i,n|
				if i.key?(name)
					return n
				end
			end
			return -1
		end
		@tourns.each do |id|
			File.open("tourn/#{@game}/#{id}/results.json").each do |file|
				JSON.parse(file).each do |info|
					event = {"#{id}" => info["place"]}
					checked = check.(all, info["name"])
					if (checked >= 0)
						hash = all[checked]
						hash[hash.keys[0]] << event
						all[checked] = hash
					else
						all << format.(info["name"], event)	
					end
				end
			end
		end
		all.sort_by!(&(Proc.new do |i| i.keys[0] end))
		File.open("tourn/#{@game}/results.json", "w") do |file|
			all.each do |line|
				file << line
			end
		end
	end
end

parse = Parser.new("melee")
parse.raw_results
parse.total_results