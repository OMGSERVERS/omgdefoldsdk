local omgcommands
omgcommands = {
	--[[
	self,
	options = {
	},
	]]--
	create = function(self, options)
		assert(self, "The self must not be nil.")
		assert(options, "The options must not be nil.")
		
		return {
			type = "omgcommands",
			outgoing_commands = {},
			consumed_commands = {},
			add_outgoing_command = function(instance, command)
				instance.outgoing_commands[#instance.outgoing_commands + 1] = command
			end,
			pull_outgoing_commands = function(instance)
				local outgoing_commands = instance.outgoing_commands
				instance.outgoing_commands = {}
				return outgoing_commands
			end,
			add_consumed_command = function(instance, command)
				assert(command.id, "Consumed command must have id")
				instance.consumed_commands[#instance.consumed_commands + 1] = command.id
			end,
			pull_consumed_commands = function(instance)
				local consumed_commands = instance.consumed_commands
				instance.consumed_commands = {}
				return consumed_commands
			end,
		}
	end
}

return omgcommands