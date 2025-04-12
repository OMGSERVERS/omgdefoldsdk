local omgconstants = require("omgservers.omgruntime.omgconstants")

local omgevents
omgevents = {
	--[[
	self,
	options = {
		config, -- omgconfig instance
	},
	]]--
	create = function(self, options)
		assert(self, "Self must not be nil.")
		assert(options, "Options must not be nil.")
		assert(options.config, "Config must not be nil.")

		local trace_logging = options.config.trace_logging
		local event_handler = options.config.event_handler

		return {
			type = "omgevents",
			events = {},
			-- Methods
			add_event = function(instance, event)
				if trace_logging then
					print(os.date() .. " [OMGSERVER] Triggered, event=" .. json.encode(event))
				end
				instance.events[#instance.events + 1] = event
			end,
			server_started = function(instance, runtime_qualifier)
				local event = {
					qualifier = omgconstants.events.SERVER_STARTED,
					body = {
						runtime_qualifier = runtime_qualifier,
					},
				}
				instance:add_event(event)
			end,
			message_received = function(instance, message_qualifier, message_body)
				local event = {
					qualifier = omgconstants.events.MESSAGE_RECEIVED,
					body = {
						qualifier = message_qualifier,
						body = message_body,
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
