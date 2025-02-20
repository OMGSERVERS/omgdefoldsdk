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
		assert(self, "The self must not be nil.")
		assert(options, "The options must not be nil.")
		assert(options.config, "The value config must not be nil.")
		assert(options.config.type == "omgconfig", "The type of config must be omgconfig")
		assert(options.events, "The value events must not be nil.")
		assert(options.events.type == "omgevents", "The type of events must be omgevents")

		local debug_logging = options.config.debug_logging
		local trace_logging = options.config.trace_logging
		local service_url = options.config.service_url
	
		local events = options.events
		
		local dispatcher_url = service_url .. "/dispatcher/v1/entrypoint/websocket/endpoint"

		return {
			type = "omgdispatcher",
			connection = nil,
			-- Methods
			connect = function(instance, ws_token, callback)
				local connection_url = dispatcher_url .. "?ws_token=" .. ws_token
				local params = {
					protocol = "omgservers"
				}

				if debug_logging then
					print(os.date() .. " [OMGSERVER] Connect to the dispatcher, url=" .. connection_url)
				end

				local connection = websocket.connect(connection_url, params, function(_, _, data)
					if data.event == websocket.EVENT_DISCONNECTED then
						if debug_logging then
							print(os.date() .. " [OMGSERVER] The connection to the dispatcher was disconnected")
						end

						omgsystem:terminate_server(omgconstants.WS_EXIT_CODE, "the connection to the dispatcher was disconnected")

					elseif data.event == websocket.EVENT_CONNECTED then
						if debug_logging then
							print(os.date() .. " [OMGSERVER] Server was connected to the dispatcher")
						end
						
						if callback then
							callback()
						end

					elseif data.event == websocket.EVENT_ERROR then
						omgsystem:terminate_server(omgconstants.WS_EXIT_CODE, "the connection to the dispatcher failed, message=" .. data.message)

					elseif data.event == websocket.EVENT_MESSAGE then
						local decoded_message = json.decode(data.message)
						local client_id = decoded_message.client_id
						local encoding = decoded_message.encoding

						local message
						if encoding == omgconstants.BASE64_ENCODED then
							message = crypt.decode_base64(decoded_message.message)
						elseif encoding == omgconstants.PLAIN_TEXT then
							message = decoded_message.message
						end

						events:message_received(client_id, message)
					end
				end)

				instance.connection = connection
			end,
			send_text_message = function(instance, clients, encoding, message)
				assert(encoding, "The encoding must not be nil.")
				assert(encoding == omgconstants.BASE64_ENCODED or encoding == omgconstants.PLAIN_TEXT, "The encoding has wrong value")
				assert(message, "The message must not be nil.")
				assert(type(message) == "string", "The type of message must be a string.")
				assert(instance.connection, "The connection was not created.")

				local encoded_message = json.encode({
					clients = clients,
					encoding = encoding,
					message = message,
				})

				if trace_logging then
					print(os.date() .. " [OMGSERVER] Outgoing message, encoded_message=" .. encoded_message)
				end

				websocket.send(instance.connection, encoded_message, {
					type = websocket.DATA_TYPE_TEXT
				})
			end,
			respond_text_message = function(instance, client_id, message)
				assert(client_id, "The client_id must not be nil.")
				instance:send_text_message({ client_id }, omgconstants.PLAIN_TEXT, message)
			end,
			respond_binary_message = function(instance, client_id, message)
				assert(client_id, "The client_id must not be nil.")
				local encoded_message = crypt.encode_base64(message)
				instance:send_text_message({ client_id }, omgconstants.BASE64_ENCODED, encoded_message)
			end,
			multicast_text_message = function(instance, clients, message)
				assert(clients, "The clients must not be nil.")
				assert(#clients > 0, "The clients must not be empty.")
				instance:send_text_message(clients, omgconstants.PLAIN_TEXT, message)
			end,
			multicast_binary_message = function(instance, clients, message)
				assert(clients, "The clients must not be nil.")
				assert(#clients > 0, "The clients must not be empty.")
				local encoded_message = crypt.encode_base64(message)
				instance:send_text_message(clients, omgconstants.BASE64_ENCODED, encoded_message)
			end,
			broadcast_text_message = function(instance, message)
				instance:send_text_message(nil, omgconstants.PLAIN_TEXT, message)
			end,
			broadcast_binary_message = function(instance, message)
				local encoded_message = crypt.encode_base64(message)
				instance:send_text_message(nil, omgconstants.BASE64_ENCODED, encoded_message)
			end,
		}
	end
}

return omgdispatcher