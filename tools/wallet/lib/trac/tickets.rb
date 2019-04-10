
require_relative './base'

module TracLib

	class Tickets < TracBase

		def get_ticket(number)
			
				return call("ticket.get",number) 	 			
		end

		def add_comment(number,message)
			return call("ticket.update",number,message, {'action' => 'leave'})		
		end

		def change_owner(number,message,owner)
			return call("ticket.update",number,message, {'action' => 'reassign', 'action_reassign_reassign_owner' => owner})
		end

		def get_actions(number)

			return call("ticket.getActions",number)

		end

		def accept_ticket(number,message)
			return call("ticket.update",number,message, {'action' => 'accept'})
		end

		def find_ticket(query)

			return call("ticket.query",query)
		end

	end
end
