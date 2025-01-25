local omgmessages
omgmessages = {
	--[[
		self,
		options = {
		},
	]]--
	create = function(self, options)
		assert(self, "The self must not be nil.")
		assert(options, "The options must not be nil.")

		return {
			type = "omgmessages",
			message_counter = 0,
			outgoing_messages = {},
			incoming_messages = {},
			consumed_messages = {},
			-- Methods
			next_message_id = function(instance)
				local message_id = instance.message_counter
				instance.message_counter = instance.message_counter + 1
				return message_id
			end,
			add_outgoing_message = function(instance, message)
				instance.outgoing_messages[#instance.outgoing_messages + 1] = message
			end,
			add_incoming_message = function(instance, message)
				instance.incoming_messages[#instance.incoming_messages + 1] = message
				instance.consumed_messages[#instance.consumed_messages + 1] = message.id
			end,
			pull_outgoing_messages = function(instance)
				local outgoing_messages = instance.outgoing_messages
				instance.outgoing_messages = {}
				return outgoing_messages
			end,
			pull_incoming_messages = function(instance)
				local incoming_messages = instance.incoming_messages
				instance.incoming_messages = {}
				return incoming_messages
			end,
			pull_consumed_messages = function(instance)
				local consumed_messages = instance.consumed_messages
				instance.consumed_messages = {}
				return consumed_messages
			end,
		}
	end
}

return omgmessages