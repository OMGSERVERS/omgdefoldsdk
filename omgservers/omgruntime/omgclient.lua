local omgconstants = require("omgservers.omgruntime.omgconstants")
local omgmessages = require("omgservers.omgruntime.omgmessages")
local omgsystem = require("omgservers.omgruntime.omgsystem")

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
		assert(self, "Self must not be nil.")
		assert(options, "Options must not be nil.")
		assert(options.config, "Config must not be nil.")
		assert(options.http, "Http must not be nil.")

		local config = options.config

		local debug_logging = config.debug_logging
		
		local service_url = config.service_url
		local runtime_id = config.runtime_id
		local password = config.password

		local http = options.http

		local create_token_url = service_url .. "/service/v1/entrypoint/runtime/request/create-token"
		local interchange_messages_url = service_url .. "/service/v1/entrypoint/runtime/request/interchange-messages"
		
		return {
			type = "omgclient",
			api_token = nil,
			dispatcher_url = nil,
			messages = nil,
			-- Methods
			create_token = function(instance, callback)
				local request_url = create_token_url
				local request_body = {
					runtime_id = runtime_id,
					password = password
				}

				local response_handler = function(response_status, response_body)
					local api_token = response_body.api_token
					local dispatcher_url = response_body.dispatcher_url

					instance.api_token = api_token
					instance.dispatcher_url = dispatcher_url
					instance.messages = omgmessages:create({})
					
					if callback then
						callback(api_token, dispatcher_url)
					end
				end

				local failure_handler = function(response_status, decoded_body, decoding_error)
					local inlined_body
					if decoded_body then
						inlined_body = json.encode(decoded_body)
					end

					omgsystem:terminate_server(omgconstants.exit_codes.API, "failed to create token, response_status=" .. tostring(response_status) .. ", decoded_body=" .. tostring(inlined_body) .. ", decoding_error=" .. tostring(decoding_error))
				end

				local api_token = nil
				http:request_server(request_url, request_body, response_handler, failure_handler, api_token)
			end,
			interchange = function(instance, callback)
				assert(instance.api_token and instance.messages, "Client must be fully fledged.")
				
				local request_url = interchange_messages_url
				local request_body = {
					outgoing_messages = instance.messages:pull_outgoing_messages(),
					consumed_messages = instance.messages:pull_consumed_messages(),
				}

				local response_handler = function(response_status, response_body)
					local incoming_messages = response_body.incoming_messages

					for _, incoming_message in ipairs(incoming_messages) do
						local message_id = incoming_message.id
						local message_qualifier = incoming_message.qualifier
						local message_body = incoming_message.body

						if debug_logging then
							print(os.date() .. " [OMGSERVER] Handle message, id=" .. string.format("%.0f", message_id) .. ", qualifier=" .. tostring(message_qualifier) .. ", body=" .. json.encode(message_body))
						end
						
						instance.messages:add_consumed_message(incoming_message)
					end
					
					if callback then
						callback(incoming_messages)
					end
				end

				local failure_handler = function(response_status, decoded_body, decoding_error)
					local inlined_body
					if decoded_body then
						inlined_body = json.encode(decoded_body)
					end

					omgsystem:terminate_server(omgconstants.exit_codes.API, "failed to interchange, response_status=" .. tostring(response_status) .. ", decoded_body=" .. tostring(inlined_body) .. ", decoding_error=" .. tostring(decoding_error))
				end

				local api_token = instance.api_token
				http:request_server(request_url, request_body, response_handler, failure_handler, api_token)
			end,
			fully_fledged = function(instance)
				return instance.api_token and instance.messages
			end,
			set_profile = function(instance, client_id, profile)
				assert(instance.messages, "Client must be fully fledged.")
				
				local outgoing_message = {
					qualifier = omgconstants.messages.SET_PROFILE,
					body = {
						client_id = client_id,
						profile = profile,
					},
				}
				instance.messages:add_outgoing_message(outgoing_message)
			end,
			respond_client = function(instance, client_id, message)
				assert(instance.messages, "Client must be fully fledged.")
				
				local outgoing_message = {
					qualifier = omgconstants.messages.RESPOND_CLIENT,
					body = {
						client_id = client_id,
						message = message,
					},
				}
				instance.messages:add_outgoing_message(outgoing_message)
			end,
			multicast_message = function(instance, clients, message)
				assert(instance.messages, "Client must be fully fledged.")
				
				local outgoing_message = {
					qualifier = omgconstants.messages.MULTICAST_MESSAGE,
					body = {
						clients = clients,
						message = message,
					},
				}
				instance.messages:add_outgoing_message(outgoing_message)
			end,
			broadcast_message = function(instance, message)
				assert(instance.messages, "Client must be fully fledged.")
				
				local outgoing_message = {
					qualifier = omgconstants.messages.BROADCAST_MESSAGE,
					body = {
						message = message,
					},
				}
				instance.messages:add_outgoing_message(outgoing_message)
			end,
			kick_client = function(instance, client_id)
				assert(instance.messages, "Client must be fully fledged.")
				
				local outgoing_message = {
					qualifier = omgconstants.messages.KICK_CLIENT,
					body = {
						client_id = client_id,
					},
				}
				instance.messages:add_outgoing_message(outgoing_message)
			end,
			request_matchmaking = function(instance, client_id, mode)
				assert(instance.messages, "Client must be fully fledged.")
				
				local outgoing_message = {
					qualifier = omgconstants.messages.REQUEST_MATCHMAKING,
					body = {
						client_id = client_id,
						mode = mode,
					},
				}
				instance.messages:add_outgoing_message(outgoing_message)
			end,
			stop_matchmaking = function(instance)
				assert(instance.messages, "Client must be fully fledged.")
				
				local outgoing_message = {
					qualifier = omgconstants.messages.STOP_MATCHMAKING,
					body = {
						__object = true
					},
				}
				instance.messages:add_outgoing_message(outgoing_message)
			end,
			upgrade_connection = function(instance, client_id)
				assert(instance.messages, "Client must be fully fledged.")
				
				local outgoing_message = {
					qualifier = omgconstants.messages.UPGRADE_CONNECTION,
					body = {
						client_id = client_id,
						protocol = omgconstants.protocols.DISPATCHER,
					},
				}
				instance.messages:add_outgoing_message(outgoing_message)
			end,
		}
	end
}

return omgclient