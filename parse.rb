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
		end
	end 

	def total_results
		alts = [["Patches", "P@ches"],
			["Mac", "Macintosh"],
			["Lemon", "Neffelemon"],
			["Oldboy", "Slippy Toad"],
			["Tachibana Sylphynford", "Kuriyama Mirai", "Yakushimaru Etsuko"],
			["CasterlyChris", "Casterly Chris"],
			["White", "Walz"],
			["Beef Wellington", "Jeremy Beef"],
			["Banana", "Bananas"],
			["Sox", "OG Sox"],
			["SBY2K", "SB Y2K"],
			["555555", "David"]]
		all = Array.new
		format = lambda do |name, event| 
			hs = {"#{name}" => [], "alt" => []}
			hs["#{name}"] << event
			return hs
		end

		check = lambda do |name|
			# all.each_with_index do |i,n|
			# 	if i.key?(name)
			# 		return n
			# 	end
			# end

			all.each_with_index do |i,n|
				if i.keys[0].downcase == name.downcase
					return n
				end
			end
			return -1
		end

		alt_name = lambda do |name|
			alts.each_with_index do |i,n|
				if i.include?(name)
					#if there is an alt name found, find the first one
					#one in all and return its location
					i.each do |a| 
						loc = check.(a)
						if(loc >= 0) then return loc end
					end
				end
				# i.each do |a|
				# 	if (a.downcase == name.downcase)
				# 		loc = check.(a.downcase)
				# 		puts loc
				# 		if (loc >= 0) then return loc end
				# 	end
				# end
			end
			return -1
		end



		@tourns.each do |id|
			File.open("tourn/#{@game}/#{id}/results.json").each do |file|
				JSON.parse(file).each do |info|
					event = {"#{id}" => info["place"]}
					mult = check.(info["name"])
					alt_loc = alt_name.(info["name"])
					#check for multiple tournies entered	
					if (mult >= 0)
						hash = all[mult]
						hash[hash.keys[0]] << event
						all[mult] = hash
					#check if entered under alt name
					elsif (alt_loc >= 0)
						hash = all[alt_loc]
						hash[hash.keys[0]] << event
						hash["alt"] << info["name"].downcase
						all[alt_loc] = hash
					else
						all << format.(info["name"].downcase, event)	
					end
				end
			end
		end
		puts all
		puts all.size
		all.sort_by!(&(Proc.new do |i| i.keys[0] end))
		File.open("tourn/#{@game}results.json", "w") do |file|
			all.each do |line|
				file << line
			end
		end
	end
end

parse = Parser.new("melee")
parse.raw_results
parse.total_results