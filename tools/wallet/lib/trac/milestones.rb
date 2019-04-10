
require_relative './base'

module TracLib

	class Milestones < TracBase

		def get_milestone(number)
			
				return call("ticket.milestone.get",number) 	 			
		end

		def get_all_milestones()
				return call("ticket.milestone.getAll")
		end
		

	end
end
