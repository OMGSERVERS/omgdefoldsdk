local omgconfig = require("omgservers.omgplayer.omgconfig")
local omghttp = require("omgservers.omgplayer.omghttp")
local omgevents = require("omgservers.omgplayer.omgevents")
local omgstate = require("omgservers.omgplayer.omgstate")
local omgclient = require("omgservers.omgplayer.omgclient")
local omgdispatcher = require("omgservers.omgplayer.omgdispatcher")
local omgprocess = require("omgservers.omgplayer.omgprocess")

local omginstance
omginstance = {
	create = function(self)
		assert(self, "Self must not be nil.")

		return {
			type = "omginstance",
			config = nil,
			http = nil,
			events = nil,
			client = nil,
			dispatcher = nil,
			process = nil,
			-- Methods
			init = function(instance, options)
				assert(instance, "Self must not be nil.")
				assert(options, "Options must not be nil.")

				instance.config = omgconfig:create(options)
				instance:reset()
			end,
			reset = function(instance)
				assert(instance, "Self must not be nil.")

				if instance.dispatcher then
					instance.dispatcher:disconnect()
				end

				instance.events = omgevents:create({
					config = instance.config,
				})

				instance.state = omgstate:create({
					events = instance.events,
				})

				instance.http = omghttp:create({
					config = instance.config,
				})

				instance.client = omgclient:create({
					config = instance.config,
					state = instance.state,
					http = instance.http,
				})

				instance.dispatcher = omgdispatcher:create({
					config = instance.config,
					events = instance.events,
					state = instance.state,
				})

				instance.process = omgprocess:create({
					config = instance.config,
					events = instance.events,
					state = instance.state,
					client = instance.client,
					dispatcher = instance.dispatcher,
				})
			end,
			ping = function(instance)
				assert(instance, "Self must not be nil.")
				assert(instance.config, "Instanace must be initialized")
				assert(not instance.state.failed, "Instance is in a failed state, reset required.")

				instance.client:ping_service(function(latency, message)
					instance.events:service_pinged(latency)
				end)
			end,
			sign_up = function(instance)
				assert(instance, "Self must not be nil.")
				assert(instance.config, "Instanace must be initialized")
				assert(not instance.state.failed, "Instance is in a failed state, reset required.")

				instance.client:create_user(function(user_id, password)
					instance.events:signed_up(user_id, password)
				end)
			end,
			sign_in = function(instance, user_id, password)
				assert(instance, "Self must not be nil.")
				assert(user_id, "UserId must not be nil.")
				assert(password, "Password must not be nil.")
				assert(instance.config, "Instanace must be initialized")
				assert(not instance.state.failed, "Instance is in a failed state, reset required.")

				instance.client:set_user(user_id, password)

				instance.client:create_token(function(api_token)
					instance.client:create_client(function(client_id)
						instance.events:signed_in(client_id)
					end)
				end)
			end,
			send_service_message = function(instance, message)
				assert(instance, "Self must not be nil.")
				assert(message, "Message must not be nil.")
				assert(instance.config, "Instanace must be initialized")
				assert(not instance.state.failed, "Instance is in a failed state, reset required.")

				instance.client:send_message(message)
			end,
			send_text_message = function(instance, message)
				assert(instance, "Self must not be nil.")
				assert(message, "Message must not be nil.")
				assert(instance.config, "Instanace must be initialized")
				assert(not instance.state.failed, "Instance is in a failed state, reset required.")

				instance.dispatcher:send_text_message(message)
			end,
			send_binary_message = function(instance, buffer)
				assert(instance, "Self must not be nil.")
				assert(buffer, "Buffer must not be nil.")
				assert(instance.config, "Instanace must be initialized")
				assert(not instance.state.failed, "Instance is in a failed state, reset required.")

				instance.dispatcher:send_binary_buffer(buffer)
			end,
			update = function(instance, dt)
				assert(instance, "Self must not be nil.")
				assert(instance.config, "Instanace must be initialized")
				instance.process:update(dt)
			end,
		}
	end,
}

return omginstance