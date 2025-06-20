local omgconstants = require("omgservers.omgplayer.omgconstants")

local omgclient
omgclient = {
	--[[
		self,
		options = {
			config, -- omgconfig instance
			state, -- omgstate instance
			http, -- omghttp instance
			messages, -- omgmessages instance
		},
	]]--
	create = function(self, options)
		assert(self, "Self must not be nil.")
		assert(options, "Options must not be nil.")
		assert(options.config, "Config must not be nil.")
		assert(options.state, "State must not be nil.")
		assert(options.http, "Http must not be nil.")
		assert(options.messages, "Messages must not be nil.")

		local debug_logging = options.config.debug_logging
		
		local service_url = options.config.service_url
		local tenant = options.config.tenant
		local project = options.config.project
		local stage = options.config.stage

		local state = options.state
		local http = options.http
		local messages = options.messages
		
		local ping_service_url = service_url .. "/service/v1/entrypoint/player/request/ping-service"
		local create_user_url = service_url .. "/service/v1/entrypoint/player/request/create-user"
		local create_token_url = service_url .. "/service/v1/entrypoint/player/request/create-token"
		local create_client_url = service_url .. "/service/v1/entrypoint/player/request/create-client"
		local interchange_messages_url = service_url .. "/service/v1/entrypoint/player/request/interchange-messages"
		
		return {
			type = "omgclient",
			ping_latency = nil,
			user_id = nil,
			user_password = nil,
			api_token = nil,
			client_id = nil,
			-- Methods
			ping_service = function(instance, callback)
				local request_url = ping_service_url
				local request_body = {
					message = "ping",
				}
				local request_time = socket.gettime()

				local response_handler = function(response_status, response_body)
					local latency = socket.gettime() - request_time
					local message = response_body.message

					if debug_logging then
						print(os.date() .. " [OMGPLAYER] Pong received, latency=" .. tostring(latency))
					end

					instance.ping_latency = latency
					
					if callback then
						callback(latency, message)
					end
				end

				local failure_handler = function(response_status, decoded_body, encoding_error)
					local inlined_body
					if decoded_body then
						inlined_body = json.encode(decoded_body)
					end

					print(os.date() .. " [OMGPLAYER] Failed to ping, response_status=" .. tostring(response_status) .. ", decoded_body=" .. tostring(inlined_body) .. ", encoding_error=" .. tostring(encoding_error))
				end

				local retries = 0

				http:request_server(request_url, request_body, response_handler, failure_handler, retries)
			end,
			create_user = function(instance, callback)
				local request_url = create_user_url
				local request_body = {
					__object = true
				}
				
				local response_handler = function(response_status, response_body)
					local user_id = response_body.user_id
					local password = response_body.password

					instance.user_id = user_id
					instance.user_password = password

					if debug_logging then
						print(os.date() .. " [OMGPLAYER] User created, user_id=" .. tostring(user_id) .. ", password=" .. string.sub(password, 1, 4) .. "..")
					end
					
					if callback then
						callback(user_id, password)
					end
				end
				
				local failure_handler = function(response_status, decoded_body, encoding_error)
					local inlined_body
					if decoded_body then
						inlined_body = json.encode(decoded_body)
					end
					
					state:fail("failed to create user, response_status=" .. tostring(response_status) .. ", decoded_body=" .. tostring(inlined_body) .. ", encoding_error=" .. tostring(encoding_error))
				end

				local retries = 2
				
				http:request_server(request_url, request_body, response_handler, failure_handler, retries)
			end,
			set_user = function(instance, user_id, password)
				instance.user_id = user_id
				instance.user_password = password

				if debug_logging then
					print(os.date() .. " [OMGPLAYER] User credentials set, user_id=" .. tostring(user_id) .. ", password=" .. string.sub(password, 1, 4) .. "..")
				end
			end,
			create_token = function(instance, callback)
				assert(instance.user_id and instance.user_password, "User must be created or set.")

				local request_url = create_token_url
				local request_body = {
					user_id = instance.user_id,
					password = instance.user_password,
				}
				
				local response_handler = function(response_status, decoded_body)
					local api_token = decoded_body.raw_token
					instance.api_token = api_token

					if debug_logging then
						print(os.date() .. " [OMGPLAYER] Api token received, token=" .. string.sub(api_token, 1, 4) .. "..")
					end
					
					if callback then
						callback(api_token)
					end
				end
				
				local failure_handler = function(response_status, decoded_body, encoding_error)
					local inlined_body
					if decoded_body then
						inlined_body = json.encode(decoded_body)
					end
					
					state:fail("failed to create token, response_status=" .. tostring(response_status) .. ", decoded_body=" .. tostring(inlined_body) .. ", encoding_error=" .. tostring(encoding_error))
				end

				local retries = 2
				
				http:request_server(request_url, request_body, response_handler, failure_handler, retries)
			end,
			create_client = function(instance, callback)
				assert(instance.api_token, "Token must be created.")

				local request_url = create_client_url
				local request_body = {
					tenant = tenant,
					project = project,
					stage = stage,
				}
				
				local response_handler = function(response_status, response_body)
					local client_id = response_body.client_id
					local connector_config = response_body.connector_config
					local connection_url = connector_config.connection_url
					
					instance.client_id = client_id

					if debug_logging then
						print(os.date() .. " [OMGPLAYER] Client created, client_id=" .. tostring(client_id) .. ", connection_url=" .. tostring(connection_url))
					end
					
					if callback then
						callback(client_id, connector_config)
					end
				end
				
				local failure_handler = function(response_status, decoded_body, encoding_error)
					local inlined_body
					if decoded_body then
						inlined_body = json.encode(decoded_body)
					end
					
					state:fail("failed to create client, response_status=" .. tostring(response_status) .. ", decoded_body=" .. tostring(inlined_body) .. ", encoding_error=" .. tostring(encoding_error))
				end

				local retries = 2
				local api_token = instance.api_token
				
				http:request_server(request_url, request_body, response_handler, failure_handler, retries, api_token)
			end,
			interchange = function(instance, callback)
				assert(instance.api_token, "Token must be created.")
				assert(instance.client_id, "Client must be created.")

				local request_url = interchange_messages_url
				local request_body = {
					client_id = instance.client_id,
					outgoing_messages = messages:pull_outgoing_messages(),
					consumed_messages = messages:pull_consumed_messages(),
				}
				
				local response_handler = function(response_status, response_body)
					local incoming_messages = response_body.incoming_messages

					for message_index = 1, #incoming_messages do
						local incoming_message = incoming_messages[message_index]
						messages:add_incoming_message(incoming_message)
					end

					if callback then
						callback()
					end
				end
				
				local failure_handler = function(response_status, decoded_body, encoding_error)
					local inlined_body
					if decoded_body then
						inlined_body = json.encode(decoded_body)
					end
					
					state:fail("failed to interchange messages, response_status=" .. tostring(response_status) .. ", decoded_body=" .. tostring(inlined_body) .. ", encoding_error=" .. tostring(encoding_error))
				end

				local retries = 4
				local api_token = instance.api_token
				
				http:request_server(request_url, request_body, response_handler, failure_handler, retries, api_token)
			end,
			send_message = function(instance, message)
				assert(type(message) == "string", "Type of message must be string")
				assert(instance.client_id, "Client must be created.")

				local message_id = messages:next_message_id()

				local outgoing_message = {
					id = message_id,
					qualifier = omgconstants.messages.MESSAGE_PRODUCED,
					body = {
						message = message
					}
				}
				messages:add_outgoing_message(outgoing_message)
			end,
			fully_fledged = function(instance)
				return instance.client_id ~= nil
			end
		}
	end
}

return omgclient