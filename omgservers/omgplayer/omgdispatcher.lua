local omgdispatcher
omgdispatcher = {
	--[[
		self,
		options = {
			config, -- omgconfig instance
			events, -- omgevents instance
			state, -- omgstate instance
		},
	]]--
	create = function(self, options)
		assert(self, "Self must not be nil.")
		assert(options, "Options must not be nil.")
		assert(options.config, "Config must not be nil.")
		assert(options.events, "Events must not be nil.")
		assert(options.state, "State must not be nil.")

		local debug_logging = options.config.debug_logging
	
		local events = options.events
		local state = options.state

		return {
			type = "omgdispatcher",
			connection = nil,
			self_disconnection = false,
			-- Methods
			connect = function(instance, connection_url, callback)
				local params = {
					protocol = "omgservers"
				}

				if debug_logging then
					print(os.date() .. " [OMGPLAYER] Connecting to dispatcher, url=" .. connection_url)
				end

				instance.self_disconnection = false
				local connection = websocket.connect(connection_url, params, function(_, _, data)
					if data.event == websocket.EVENT_DISCONNECTED then
						if debug_logging then
							print(os.date() .. " [OMGPLAYER] Dispatcher disconnected, message=" .. data.message .. ", code=" .. data.code)
						end

						if not instance.self_disconnection then
							state:fail("dipstacher disconnected, message=" .. data.message .. ", code=" .. data.code)
						end

					elseif data.event == websocket.EVENT_CONNECTED then
						if debug_logging then
							print(os.date() .. " [OMGPLAYER] Connected to dispatcher")
						end

						if callback then
							callback()
						end

					elseif data.event == websocket.EVENT_ERROR then
						state:fail("dispatcher failed, message=" .. data.message)

					elseif data.event == websocket.EVENT_MESSAGE then
						events:message_received(data.message)
					end
				end)

				instance.connection = connection
			end,
			disconnect = function(instance)
				if instance.connection then
					print(os.date() .. " [OMGPLAYER] Closing dispatcher connection")
					websocket.disconnect(instance.connection)
					instance.connection = nil
					instance.self_disconnection = true
				end
			end,
			send_text_message = function(instance, message)
				assert(instance.connection, "Dispatcher must be connected")
				assert(type(message) == "string", "Type of message must be string")

				websocket.send(instance.connection, message, {
					type = websocket.DATA_TYPE_TEXT
				})
			end,
			send_binary_buffer = function(instance, buffer)
				assert(instance.connection, "Dispatcher must be connected")
				assert(type(buffer) == "string", "Type of buffer must be string")

				websocket.send(instance.connection, buffer, {
					type = websocket.DATA_BINARY_TEXT
				})
			end,
		}
	end
}

return omgdispatcher