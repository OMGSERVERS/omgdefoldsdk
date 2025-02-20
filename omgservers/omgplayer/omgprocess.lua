local omgconstants = require("omgservers.omgplayer.omgconstants")

local omgprocess
omgprocess = {
	--[[
		self,
		options = {
			config, -- omgconfig instance
			events, -- omgevents instance
			state, -- omgstate instance
			client, -- omgclient intance
			dispatcher, -- omgdispatcher instance
		},
	]]--
	create = function(self, options)
		assert(self, "The self must not be nil.")
		assert(options, "The options must not be nil.")
		assert(options.config, "The value config must not be nil.")
		assert(options.config.type == "omgconfig", "The type of config must be omgconfig")
		assert(options.events, "The value events must not be nil.")
		assert(options.events.type == "omgevents", "The type of events must be omgevents")
		assert(options.state, "The value state must not be nil.")
		assert(options.state.type == "omgstate", "The type of state must be omgstate")
		assert(options.client, "The value client must not be nil.")
		assert(options.client.type == "omgclient", "The type of client must be omgclient")
		assert(options.dispatcher, "The value dispatcher must not be nil.")
		assert(options.dispatcher.type == "omgdispatcher", "The type of dispatcher must be omgdispatcher")

		local debug_logging = options.config.debug_logging
		local trace_logging = options.config.trace_logging

		local config = options.config
		local events = options.events
		local state = options.state
		local client = options.client
		local dispatcher = options.dispatcher
		
		return {
			type = "omgprocess",
			iteration_timer = 0,
			empty_iterations = 0,
			faster_iterations = true,
			interchange_requested = false,
			-- Methods
			handle = function(instance, incoming_message)
				local message_qualifier = incoming_message.qualifier

				if trace_logging then
					print(os.date() .. " [OMGPLAYER] Incoming message, incoming_message=" .. json.encode(incoming_message))
				end

				if message_qualifier == omgconstants.SERVER_WELCOME_MESSAGE then
					local version_id = incoming_message.body.version_id
					local version_created = incoming_message.body.version_created
					state:welcome(version_id, version_created)

				elseif message_qualifier == omgconstants.MATCHMAKER_ASSIGNMENT_MESSAGE then
					local matchmaker_id = incoming_message.body.matchmaker_id
					state:assign_matchmaker(matchmaker_id)

				elseif message_qualifier == omgconstants.RUNTIME_ASSIGNMENT_MESSAGE then
					local runtime_id = incoming_message.body.runtime_id
					local runtime_qualifier = incoming_message.body.runtime_qualifier

					-- Close the dispatcher connection if it exists.
					dispatcher:disconnect()
					
					if runtime_qualifier == omgconstants.LOBBY then
						state:assign_lobby(runtime_id)

					elseif runtime_qualifier == omgconstants.MATCH then
						state:assign_match(runtime_id)

					else
						state:fail("an unknown runtime qualifier was assigned, runtime_qualifier=" .. runtime_qualifier)
					end

				elseif message_qualifier == omgconstants.SERVER_OUTGOING_MESSAGE then
					local message_body = incoming_message.body.message
					events:message_received(message_body)

				elseif message_qualifier == omgconstants.CONNECTION_UPGRADE_MESSAGE then
					local upgrade_protocol = incoming_message.body.protocol
					if upgrade_protocol == omgconstants.DISPATCHER_PROTOCOL then
						local web_socket_config = incoming_message.body.web_socket_config
						local ws_token = web_socket_config.ws_token

						dispatcher:connect(ws_token, function()
							events:connection_dispatched()
						end)
					else
						state:fail("unsupported connection upgrade protocol, protocol=" .. upgrade_protocol)
					end
					
				elseif message_qualifier == omgconstants.DISCONNECTION_REASON_MESSAGE then
					local reason = incoming_message.body.reason
					state:fail("client was disconnected by the server, reason=" .. reason)
					
				end
			end,
			interchange = function(instance, dt)
				if not client:fully_fledged() then
					return
				end

				if state.failed then
					return
				end
				
				local iteration_timer = instance.iteration_timer + dt

				local current_interval
				if instance.faster_iterations then
					current_interval = config.faster_interval
				else
					current_interval = config.default_interval
				end

				if instance.iteration_timer > current_interval then
					instance.iteration_timer = 0

					if not instance.interchange_requested then
						instance.interchange_requested = true
						client:interchange(function() instance.interchange_requested = false end)
					end

					local incoming_messages = client:pull_incoming_messages()

					-- Switch between default and faster intervals
					if #incoming_messages > 0 then
						instance.empty_iterations = 0
						if not instance.faster_iterations then
							instance.faster_iterations = true

							if debug_logging then
								print(os.date() .. " [OMGPLAYER] Switched to faster iterations")
							end
						end
					else
						local empty_iterations = instance.empty_iterations + 1
						instance.empty_iterations = empty_iterations

						if empty_iterations >= config.iterations_threshold then
							if instance.faster_iterations then
								instance.faster_iterations = false
								if debug_logging then
									print(os.date() .. " [OMGPLAYER] Switched to default iterations")
								end
							end
						end
					end

					for _, incoming_message in ipairs(incoming_messages) do
						instance:handle(incoming_message)
					end
				else
					instance.iteration_timer = iteration_timer
				end
			end,
			update = function(instance, dt)
				instance:interchange(dt)
				events:update()
			end
		}
	end
}

return omgprocess