local omgconstants = require("omgservers.omgplayer.omgconstants")

local omgprocess
omgprocess = {
	--[[
		self,
		options = {
			config, -- omgconfig instance
			events, -- omgevents instance
			state, -- omgstate instance
			messages, -- omgmessages instance
			client, -- omgclient intance
			connector, -- omgconnector instance
			dispatcher, -- omgdispatcher instance
		},
	]]--
	create = function(self, options)
		assert(self, "Self must not be nil.")
		assert(options, "Options must not be nil.")
		assert(options.config, "Config must not be nil.")
		assert(options.events, "Events must not be nil.")
		assert(options.state, "State must not be nil.")
		assert(options.messages, "Messages must not be nil.")
		assert(options.client, "Client must not be nil.")
		assert(options.connector, "Connector must not be nil.")
		assert(options.dispatcher, "Dispatcher must not be nil.")

		local through_connector = options.config.through_connector
		local debug_logging = options.config.debug_logging
		local trace_logging = options.config.trace_logging

		local config = options.config
		local events = options.events
		local state = options.state
		local messages = options.messages
		local client = options.client
		local connector = options.connector
		local dispatcher = options.dispatcher
		
		return {
			type = "omgprocess",
			iteration_timer = 0,
			empty_iterations = 0,
			faster_iterations = true,
			interchange_requested = false,
			-- Methods
			handle_message = function(instance, incoming_message)
				local message_qualifier = incoming_message.qualifier

				if trace_logging then
					print(os.date() .. " [OMGPLAYER] Incoming message, " .. json.encode(incoming_message))
				end

				if message_qualifier == omgconstants.messages.CLIENT_GREETED then
					local version_id = incoming_message.body.version_id
					local version_created = incoming_message.body.version_created
					state:greet_player(version_id, version_created)

				elseif message_qualifier == omgconstants.messages.RUNTIME_ASSIGNED then
					local runtime_id = incoming_message.body.runtime_id
					local runtime_qualifier = incoming_message.body.runtime_qualifier

					-- Close the dispatcher connection if it exists.
					dispatcher:disconnect()
					
					if runtime_qualifier == omgconstants.runtimes.LOBBY then
						state:assign_lobby(runtime_id)

					elseif runtime_qualifier == omgconstants.runtimes.MATCH then
						state:assign_match(runtime_id)

					else
						state:fail("unsupported runtime assigned, " .. tostring(runtime_qualifier))
					end

				elseif message_qualifier == omgconstants.messages.MESSAGE_PRODUCED then
					local message_body = incoming_message.body.message
					events:message_received(message_body)

				elseif message_qualifier == omgconstants.messages.CONNECTION_UPGRADED then
					local upgrade_protocol = incoming_message.body.protocol
					if upgrade_protocol == omgconstants.protocols.DISPATCHER then
						local dispatcher_config = incoming_message.body.dispatcher_config
						local connection_url = dispatcher_config.connection_url

						dispatcher:connect(connection_url, function()
							events:connection_dispatched()
						end)
					else
						state:fail("unsupported protocol, " .. tostring(upgrade_protocol))
					end
					
				elseif message_qualifier == omgconstants.messages.CLIENT_DELETED then
					local reason = incoming_message.body.reason
					state:fail("client deleted, reason=" .. tostring(reason))
					
				end
			end,
			interchange = function(instance, dt)
				if not client:fully_fledged() then
					return
				end

				if state.failed then
					return
				end

				if through_connector then
					local outgoing_messages = messages:pull_outgoing_messages()
					for _, outgoing_message in ipairs(outgoing_messages) do
						connector:send_message(json.encode(outgoing_message))
					end

					local incoming_messages = messages:pull_incoming_messages()
					for _, incoming_message in ipairs(incoming_messages) do
						instance:handle_message(incoming_message)
					end
					
				else
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

						local incoming_messages = messages:pull_incoming_messages()

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
							instance:handle_message(incoming_message)
						end
					else
						instance.iteration_timer = iteration_timer
					end
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