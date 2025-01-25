local omgconstants = require("omgservers.omgserver.omgconstants")

local omgevents
omgevents = {
	--[[
	self,
	options = {
		config, -- omgconfig instance
	},
	]]--
	create = function(self, options)
		assert(self, "The self must not be nil.")
		assert(options, "The options must not be nil.")
		assert(options.config, "The value config must not be nil.")
		assert(options.config.type == "omgconfig", "The type of config must be omgconfig")

		local trace_logging = options.config.trace_logging
		local event_handler = options.config.event_handler

		return {
			type = "omgevents",
			events = {},
			-- Methods
			add_event = function(instance, event)
				if trace_logging then
					print(socket.gettime() .. " [OMGSERVER] Triggered, event=" .. json.encode(event))
				end
				instance.events[#instance.events + 1] = event
			end,
			server_started = function(instance, runtime_qualifier)
				local event = {
					qualifier = omgconstants.SERVER_STARTED,
					body = {
						runtime_qualifier = runtime_qualifier,
					},
				}
				instance:add_event(event)
			end,
			message_received = function(instance, client_id, message)
				local event = {
					qualifier = omgconstants.MESSAGE_RECEIVED,
					body = {
						client_id = client_id,
						message = message,
					},
				}
				instance:add_event(event)
			end,
			command_received = function(instance, qualifier, body)
				local event = {
					qualifier = omgconstants.COMMAND_RECEIVED,
					body = {
						qualifier = qualifier,
						body = body
					},
				}
				instance:add_event(event)
			end,
			update = function(instance)
				local events = instance.events
				instance.events = {}
				for event_index, event in ipairs(events) do
					event_handler(event)
				end
			end,
		}
	end
}

return omgevents
