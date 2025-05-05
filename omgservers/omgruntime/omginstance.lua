local omgdispatcher = require("omgservers.omgruntime.omgdispatcher")
local omgprocess = require("omgservers.omgruntime.omgprocess")
local omgconfig = require("omgservers.omgruntime.omgconfig")
local omgclient = require("omgservers.omgruntime.omgclient")
local omgevents = require("omgservers.omgruntime.omgevents")
local omghttp = require("omgservers.omgruntime.omghttp")

local omginstance
omginstance = {
	create = function(self)
		assert(self, "Self must not be nil.")

		return {
			config = nil,
			http = nil,
			events = nil,
			client = nil,
			dispatcher = nil,
			process = nil,
			started = false,
			-- Methods
			init = function(instance, options)
				assert(instance, "Self must not be nil.")
				assert(options, "Options must not be nil.")
				assert(not instance.started, "Server already started.")

				instance.config = omgconfig:create(options)
				instance:reset()

				return instance.config
			end,
			reset = function(instance)
				assert(instance, "Self must not be nil.")

				instance.http = omghttp:create({
					config = instance.config
				})

				instance.events = omgevents:create({
					config = instance.config
				})

				instance.client = omgclient:create({
					config = instance.config,
					http = instance.http
				})

				instance.dispatcher = omgdispatcher:create({
					config = instance.config,
					events = instance.events
				})

				instance.process = omgprocess:create({
					config = instance.config,
					events = instance.events,
					client = instance.client,
				})

				instance.started = false
			end,
			start = function(instance, dispatched)
				assert(instance, "Self must not be nil.")
				assert(instance.config, "Server must be initialized.")
				assert(not instance.started, "Server already started")

				local callback = function()
					instance.started = true

					local runtime_qualifier = instance.config.runtime_qualifier
					instance.events:server_started(runtime_qualifier)
				end

				instance.client:create_token(function(api_token, dispatcher_url)
					if dispatched or false then
						instance.dispatcher:connect(dispatcher_url, callback)
					else
						callback()
					end
				end)
			end,
			update = function(instance, dt)
				assert(instance, "Self must not be nil.")
				assert(instance.config, "Server must be initialized.")

				if instance.started then
					instance.process:update(dt)
				end
			end,
			-- Commands
			set_profile = function(instance, client_id, profile)
				assert(instance.config, "Server must be initialized.")
				assert(instance.started, "The server must be started.")
				instance.client:set_profile(client_id, profile)
			end,
			respond_client = function(instance, client_id, message)
				assert(instance.config, "Server must be initialized.")
				assert(instance.started, "The server must be started.")
				instance.client:respond_client(client_id, message)
			end,
			multicast_message = function(instance, clients, message)
				assert(instance.config, "Server must be initialized.")
				assert(instance.started, "The server must be started.")
				instance.client:multicast_message(clients, message)
			end,
			broadcast_message = function(instance, message)
				assert(instance.config, "Server must be initialized.")
				assert(instance.started, "The server must be started.")
				instance.client:broadcast_message(message)
			end,
			kick_client = function(instance, client_id)
				assert(instance.config, "Server must be initialized.")
				assert(instance.started, "The server must be started.")
				instance.client:kick_client(client_id)
			end,
			request_matchmaking = function(instance, client_id, mode)
				assert(instance.config, "Server must be initialized.")
				assert(instance.started, "The server must be started.")
				instance.client:request_matchmaking(client_id, mode)
			end,
			stop_matchmaking = function(instance)
				assert(instance.config, "Server must be initialized.")
				assert(instance.started, "The server must be started.")
				instance.client:stop_matchmaking()
			end,
			upgrade_connection = function(instance, client_id)
				assert(instance.config, "Server must be initialized.")
				assert(instance.started, "The server must be started.")
				instance.client:upgrade_connection(client_id)
			end,
			-- Messaging
			respond_text_message = function(instance, client_id, message)
				assert(instance.config, "Server must be initialized.")
				assert(instance.started, "The server must be started.")
				instance.dispatcher:respond_text_message(client_id, message)
			end,
			respond_binary_message = function(instance, client_id, message)
				assert(instance.config, "Server must be initialized.")
				assert(instance.started, "The server must be started.")
				instance.dispatcher:respond_binary_message(client_id, message)
			end,
			multicast_text_message = function(instance, clients, message)
				assert(instance.config, "Server must be initialized.")
				assert(instance.started, "The server must be started.")
				instance.dispatcher:multicast_text_message(clients, message)
			end,
			multicast_binary_message = function(instance, clients, message)
				assert(instance.config, "Server must be initialized.")
				assert(instance.started, "The server must be started.")
				instance.dispatcher:multicast_binary_message(clients, message)
			end,
			broadcast_text_message = function(instance, message)
				assert(instance.config, "Server must be initialized.")
				assert(instance.started, "The server must be started.")
				instance.dispatcher:broadcast_text_message(message)
			end,
			broadcast_binary_message = function(instance, message)
				assert(instance.config, "Server must be initialized.")
				assert(instance.started, "The server must be started.")
				instance.dispatcher:broadcast_binary_message(message)
			end,
		}
	end,
}

return omginstance