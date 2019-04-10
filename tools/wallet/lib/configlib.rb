
require 'yaml'

class ConfigLib

	def initialize(filename)
		super()
		@config = YAML.load_file(filename)

		@filename = filename
	end

	def get(key)
	
		value = nil

		key.split(".").each do |key|

			if value == nil
				value = @config.fetch(key)
			else
				if value.class == Hash && value.has_key?(key)
					value = value.fetch(key)
				else
					return nil
				end
			end

		end

		return value

	end

	

	def set(key,value)

		parts = key.split(".",)

		newset = result = Hash.new

		parts.each do |key|


			if(parts.last == key)
				result[key] = value
			else
				result[key] = Hash.new
				result = result[key]
			end	
		end

		
		@config =  @config.merge(newset){|key, oldval, newval| newval.merge(oldval)}
	end

	def save(filename="")


		filename = @filename if filename.empty?

		yamlstr = YAML.dump(@config);

		# Create a new file and write to it  
		File.open(filename, 'w') do |f2|
			    f2.puts yamlstr
		end  

	end


end
