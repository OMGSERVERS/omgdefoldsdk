local omgconstants = require("omgservers.omgplayer.omgconstants")

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
					print(os.date() .. " [OMGPLAYER] Triggered, event=" .. json.encode(event))
				end
				instance.events[#instance.events + 1] = event
			end,
			service_pinged = function(instance, latency, message)
				local event = {
					qualifier = omgconstants.events.SERVICE_PINGED,
					body = {
						latency = latency,
						message = message,
					},
				}
				instance:add_event(event)
			end,
			signed_up = function(instance, user_id, password)
				local event = {
					qualifier = omgconstants.events.SIGNED_UP,
					body = {
						user_id = user_id,
						password = password,
					},
				}
				instance:add_event(event)
			end,
			signed_in = function(instance, client_id)
				local event = {
					qualifier = omgconstants.events.SIGNED_IN,
					body = {
						client_id = client_id,
					},
				}
				instance:add_event(event)
			end,
			player_greeted = function(instance, version_id, version_created)
				local event = {
					qualifier = omgconstants.events.PLAYER_GREETED,
					body = {
						version_id = version_id,
						version_created = version_created,
					},
				}
				instance:add_event(event)
			end,
			runtime_assigned = function(instance, runtime_qualifier, runtime_id)
				local event = {
					qualifier = omgconstants.events.RUNTIME_ASSIGNED,
					body = {
						runtime_qualifier = runtime_qualifier,
						runtime_id = runtime_id,
					},
				}
				instance:add_event(event)
			end,
			message_received = function(instance, message_body)
				local event = {
					qualifier = omgconstants.events.MESSAGE_RECEIVED,
					body = {
						message = message_body,
					}
				}
				instance:add_event(event)
			end,
			connection_dispatched = function(instance)
				local event = {
					qualifier = omgconstants.events.CONNECTION_DISPATCHED,
					body = {
					},
				}
				instance:add_event(event)
			end,
			player_failed = function(instance, reason)
				local event = {
					qualifier = omgconstants.events.PLAYER_FAILED,
					body = {
						reason = reason,
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
