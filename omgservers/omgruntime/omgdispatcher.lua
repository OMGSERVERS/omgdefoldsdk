local omgconstants = require("omgservers.omgruntime.omgconstants")
local omgsystem = require("omgservers.omgruntime.omgsystem")

local omgdispatcher
omgdispatcher = {
	--[[
		self,
		options = {
			config, -- omgconfig instance
			events, -- omgevents instance
		},
	]]--
	create = function(self, options)
		assert(self, "Self must not be nil.")
		assert(options, "Options must not be nil.")
		assert(options.config, "Config must not be nil.")
		assert(options.events, "Events must not be nil.")

		local debug_logging = options.config.debug_logging
		local trace_logging = options.config.trace_logging
	
		local events = options.events

		return {
			type = "omgdispatcher",
			connection = nil,
			-- Methods
			connect = function(instance, dispatcher_config, callback)
				local params = {
					protocol = dispatcher_config.sec_web_socket_protocol
				}

				local connection_url = dispatcher_config.connection_url
				
				if debug_logging then
					print(os.date() .. " [OMGSERVER] Connecting to dispatcher, url=" .. tostring(connection_url))
				end

				local connection = websocket.connect(connection_url, params, function(_, _, data)
					if data.event == websocket.EVENT_DISCONNECTED then
						if debug_logging then
							print(os.date() .. " [OMGSERVER] Dispatcher disconnected")
						end

						omgsystem:terminate_server(omgconstants.exit_codes.WS, "dispatcher disconnected")

					elseif data.event == websocket.EVENT_CONNECTED then
						if debug_logging then
							print(os.date() .. " [OMGSERVER] Dispatcher connected")
						end
						
						if callback then
							callback()
						end

					elseif data.event == websocket.EVENT_ERROR then
						omgsystem:terminate_server(omgconstants.exit_codes.WS, "dispatcher failed, message=" .. tostring(data.message))

					elseif data.event == websocket.EVENT_MESSAGE then
						local decoded_message = json.decode(data.message)
						local client_id = decoded_message.client_id
						local encoding = decoded_message.encoding

						local message
						if encoding == omgconstants.protocols.BASE64 then
							message = crypt.decode_base64(decoded_message.message)
						elseif encoding == omgconstants.protocols.PLAIN_TEXT then
							message = decoded_message.message
						end

						events:message_received(omgconstants.messages.MESSAGE_RECEIVED, {
							client_id = client_id,
							message = message,
						})
					end
				end)

				instance.connection = connection
			end,
			send_text_message = function(instance, clients, encoding, message)
				assert(encoding, "Encoding must not be nil.")
				assert(encoding == omgconstants.protocols.BASE64 or encoding == omgconstants.protocols.PLAIN_TEXT, "Encoding has wrong value")
				assert(message, "Message must not be nil.")
				assert(type(message) == "string", "Type of message must be a string.")
				assert(instance.connection, "Connection was not created.")

				local encoded_message = json.encode({
					clients = clients,
					encoding = encoding,
					message = message,
				})

				if trace_logging then
					print(os.date() .. " [OMGSERVER] Outgoing message, encoded_message=" .. tostring(encoded_message))
				end

				websocket.send(instance.connection, encoded_message, {
					type = websocket.DATA_TYPE_TEXT
				})
			end,
			respond_text_message = function(instance, client_id, message)
				assert(client_id, "ClientId must not be nil.")
				instance:send_text_message({ client_id }, omgconstants.protocols.PLAIN_TEXT, message)
			end,
			respond_binary_message = function(instance, client_id, message)
				assert(client_id, "ClientId must not be nil.")
				local encoded_message = crypt.encode_base64(message)
				instance:send_text_message({ client_id }, omgconstants.protocols.BASE64, encoded_message)
			end,
			multicast_text_message = function(instance, clients, message)
				assert(clients, "Clients must not be nil.")
				assert(#clients > 0, "Clients must not be empty.")
				instance:send_text_message(clients, omgconstants.protocols.PLAIN_TEXT, message)
			end,
			multicast_binary_message = function(instance, clients, message)
				assert(clients, "Clients must not be nil.")
				assert(#clients > 0, "Clients must not be empty.")
				local encoded_message = crypt.encode_base64(message)
				instance:send_text_message(clients, omgconstants.protocols.BASE64, encoded_message)
			end,
			broadcast_text_message = function(instance, message)
				instance:send_text_message(nil, omgconstants.protocols.PLAIN_TEXT, message)
			end,
			broadcast_binary_message = function(instance, message)
				local encoded_message = crypt.encode_base64(message)
				instance:send_text_message(nil, omgconstants.protocols.BASE64, encoded_message)
			end,
		}
	end
}

return omgdispatcher