local omgconstants = require("omgservers.omgserver.omgconstants")
local omgcommands = require("omgservers.omgserver.omgcommands")
local omgsystem = require("omgservers.omgserver.omgsystem")

local omgclient
omgclient = {
	--[[
		self,
		options = {
			config, -- omgconfig instance
			http, -- omghttp instance
		},
	]]--
	create = function(self, options)
		assert(self, "The self must not be nil.")
		assert(options, "The options must not be nil.")
		assert(options.config, "The value config must not be nil.")
		assert(options.config.type == "omgconfig", "The type of config must be omgconfig")
		assert(options.http, "The value http must not be nil.")
		assert(options.http.type == "omghttp", "The type of http must be omghttp")

		local config = options.config

		local debug_logging = config.debug_logging
		
		local service_url = config.service_url
		local runtime_id = config.runtime_id
		local password = config.password

		local http = options.http

		local create_token_url = service_url .. "/service/v1/entrypoint/runtime/request/create-token"
		local interchange_url = service_url .. "/service/v1/entrypoint/runtime/request/interchange"
		
		return {
			type = "omgclient",
			api_token = nil,
			ws_token = nil,
			commands = nil,
			-- Methods
			create_token = function(instance, callback)
				local request_url = create_token_url
				local request_body = {
					runtime_id = runtime_id,
					password = password
				}

				local response_handler = function(response_status, response_body)
					local api_token = response_body.api_token
					local ws_token = response_body.ws_token

					instance.api_token = api_token
					instance.ws_token = ws_token
					instance.commands = omgcommands:create({})
					
					if callback then
						callback(api_token, ws_token)
					end
				end

				local failure_handler = function(response_status, decoded_body, decoding_error)
					local inlined_body
					if decoded_body then
						inlined_body = json.encode(decoded_body)
					end

					omgsystem:terminate_server(omgconstants.API_EXIT_CODE, "token was not created, response_status=" .. response_status .. ", decoded_body=" .. inlined_body .. ", decoding_error=" .. tostring(decoding_error))
				end

				local api_token = nil
				http:request_server(request_url, request_body, response_handler, failure_handler, api_token)
			end,
			interchange = function(instance, callback)
				assert(instance.api_token and instance.commands, "The client must be fully fledged.")
				
				local request_url = interchange_url
				local request_body = {
					outgoing_commands = instance.commands:pull_outgoing_commands(),
					consumed_commands = instance.commands:pull_consumed_commands(),
				}

				local response_handler = function(response_status, response_body)
					local incoming_commands = response_body.incoming_commands

					for _, incoming_command in ipairs(incoming_commands) do
						local command_id = incoming_command.id
						local command_qualifier = incoming_command.qualifier
						local command_body = incoming_command.body

						if debug_logging then
							print(socket.gettime() .. " [OMGSERVER] Handle command, id=" .. string.format("%.0f", command_id) .. ", qualifier=" .. command_qualifier .. ", body=" .. json.encode(command_body))
						end
						
						instance.commands:add_consumed_command(incoming_command)
					end
					
					if callback then
						callback(incoming_commands)
					end
				end

				local failure_handler = function(response_status, decoded_body, decoding_error)
					local inlined_body
					if decoded_body then
						inlined_body = json.encode(decoded_body)
					end

					omgsystem:terminate_server(omgconstants.API_EXIT_CODE, "interchange failed, response_status=" .. response_status .. ", decoded_body=" .. inlined_body .. ", decoding_error=" .. tostring(decoding_error))
				end

				local api_token = instance.api_token
				http:request_server(request_url, request_body, response_handler, failure_handler, api_token)
			end,
			fully_fledged = function(instance)
				return instance.api_token and instance.commands
			end,
			set_attributes = function(instance, client_id, attributes)
				assert(instance.commands, "The client must be fully fledged.")
				
				local command = {
					qualifier = omgconstants.SET_ATTRIBUTES,
					body = {
						client_id = client_id,
						attributes = {
							attributes = attributes,
						},
					},
				}
				instance.commands:add_outgoing_command(command)
			end,
			set_profile = function(instance, client_id, profile)
				assert(instance.commands, "The client must be fully fledged.")
				
				local command = {
					qualifier = omgconstants.SET_PROFILE,
					body = {
						client_id = client_id,
						profile = profile,
					},
				}
				instance.commands:add_outgoing_command(command)
			end,
			respond_client = function(instance, client_id, message)
				assert(instance.commands, "The client must be fully fledged.")
				
				local command = {
					qualifier = omgconstants.RESPOND_CLIENT,
					body = {
						client_id = client_id,
						message = message,
					},
				}
				instance.commands:add_outgoing_command(command)
			end,
			multicast_message = function(instance, clients, message)
				assert(instance.commands, "The client must be fully fledged.")
				
				local command = {
					qualifier = omgconstants.MULTICAST_MESSAGE,
					body = {
						clients = clients,
						message = message,
					},
				}
				instance.commands:add_outgoing_command(command)
			end,
			broadcast_message = function(instance, message)
				assert(instance.commands, "The client must be fully fledged.")
				
				local command = {
					qualifier = omgconstants.BROADCAST_MESSAGE,
					body = {
						message = message,
					},
				}
				instance.commands:add_outgoing_command(command)
			end,
			kick_client = function(instance, client_id)
				assert(instance.commands, "The client must be fully fledged.")
				
				local command = {
					qualifier = omgconstants.KICK_CLIENT,
					body = {
						client_id = client_id,
					},
				}
				instance.commands:add_outgoing_command(command)
			end,
			request_matchmaking = function(instance, client_id, mode)
				assert(instance.commands, "The client must be fully fledged.")
				
				local command = {
					qualifier = omgconstants.REQUEST_MATCHMAKING,
					body = {
						client_id = client_id,
						mode = mode,
					},
				}
				instance.commands:add_outgoing_command(command)
			end,
			stop_matchmaking = function(instance)
				assert(instance.commands, "The client must be fully fledged.")
				
				local command = {
					qualifier = omgconstants.STOP_MATCHMAKING,
					body = {
						__object = true
					},
				}
				instance.commands:add_outgoing_command(command)
			end,
			upgrade_connection = function(instance, client_id)
				assert(instance.commands, "The client must be fully fledged.")
				
				local command = {
					qualifier = omgconstants.UPGRADE_CONNECTION,
					body = {
						client_id = client_id,
						protocol = omgconstants.DISPATCHER_PROTOCOL,
					},
				}
				instance.commands:add_outgoing_command(command)
			end,
		}
	end
}

return omgclient