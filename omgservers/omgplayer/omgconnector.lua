local omgconnector
omgconnector = {
	--[[
	self,
	options = {
		config, -- omgconfig instance
		state, -- omgstate instance
		message, -- omgmessage instance
	},
	]]--
	create = function(self, options)
		assert(self, "Self must not be nil.")
		assert(options, "Options must not be nil.")
		assert(options.config, "Config must not be nil.")
		assert(options.state, "State must not be nil.")
		assert(options.messages, "Messages must not be nil.")

		local debug_logging = options.config.debug_logging

		local state = options.state
		local messages = options.messages

		return {
			type = "omgconnector",
			connection = nil,
			self_disconnection = false,
			-- Methods
			connect = function(instance, connector_config, callback)
				local params = {
					protocol = connector_config.sec_web_socket_protocol
				}

				local connection_url = connector_config.connection_url
				
				if debug_logging then
					print(os.date() .. " [OMGPLAYER] Connecting to connector, url=" .. tostring(connection_url))
				end

				instance.self_disconnection = false
				local connection = websocket.connect(connection_url, params, function(_, _, data)
					if data.event == websocket.EVENT_DISCONNECTED then
						if debug_logging then
							print(os.date() .. " [OMGPLAYER] Connector disconnected, message=" .. tostring(data.message) .. ", code=" .. tostring(data.code))
						end

						if not instance.self_disconnection then
							state:fail("connector disconnected, message=" .. tostring(data.message) .. ", code=" .. tostring(data.code))
						end

					elseif data.event == websocket.EVENT_CONNECTED then
						if debug_logging then
							print(os.date() .. " [OMGPLAYER] Connected to connector")
						end

						if callback then
							callback()
						end

					elseif data.event == websocket.EVENT_ERROR then
						state:fail("connector failed, message=" .. tostring(data.message))

					elseif data.event == websocket.EVENT_MESSAGE then
						local incoming_message = data.message
						local decoded_message = json.decode(incoming_message)
						messages:add_incoming_message(decoded_message)
					end
				end)

				instance.connection = connection
			end,
			disconnect = function(instance)
				if instance.connection then
					print(os.date() .. " [OMGPLAYER] Closing connector connection")
					websocket.disconnect(instance.connection)
					instance.connection = nil
					instance.self_disconnection = true
				end
			end,
			send_message = function(instance, message)
				assert(instance.connection, "Connector must be connected")
				assert(type(message) == "string", "Type of message must be string")

				websocket.send(instance.connection, message, {
					type = websocket.DATA_TYPE_TEXT
				})
			end
		}
	end
}

return omgconnector