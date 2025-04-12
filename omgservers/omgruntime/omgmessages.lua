local omgmessages
omgmessages = {
	--[[
	self,
	options = {
	},
	]]--
	create = function(self, options)
		assert(self, "Self must not be nil.")
		assert(options, "Options must not be nil.")
		
		return {
			type = "omgmessages",
			outgoing_messages = {},
			consumed_messages = {},
			add_outgoing_message = function(instance, message)
				instance.outgoing_messages[#instance.outgoing_messages + 1] = message
			end,
			pull_outgoing_messages = function(instance)
				local outgoing_messages = instance.outgoing_messages
				instance.outgoing_messages = {}
				return outgoing_messages
			end,
			add_consumed_message = function(instance, message)
				assert(message.id, "Message must have id.")
				instance.consumed_messages[#instance.consumed_messages + 1] = message.id
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