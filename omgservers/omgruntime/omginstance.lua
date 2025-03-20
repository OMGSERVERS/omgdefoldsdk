local omgdispatcher = require("omgservers.omgruntime.omgdispatcher")
local omgprocess = require("omgservers.omgruntime.omgprocess")
local omgconfig = require("omgservers.omgruntime.omgconfig")
local omgclient = require("omgservers.omgruntime.omgclient")
local omgevents = require("omgservers.omgruntime.omgevents")
local omghttp = require("omgservers.omgruntime.omghttp")

local omginstance
omginstance = {
	config = nil,
	http = nil,
	events = nil,
	client = nil,
	dispatcher = nil,
	process = nil,
	started = false,
	-- Methods
	init = function(self, options)
		assert(self, "The self must not be nil.")
		assert(options, "The options must not be nil.")
		assert(not self.started, "The server already started.")

		self.config = omgconfig:create(options)
		self:reset()
		
		return self.config.runtime_qualifier
	end,
	reset = function(self)
		assert(self, "The self must not be nil.")

		self.http = omghttp:create({
			config = self.config
		})

		self.events = omgevents:create({
			config = self.config
		})
		
		self.client = omgclient:create({
			config = self.config,
			http = self.http
		})

		self.dispatcher = omgdispatcher:create({
			config = self.config,
			events = self.events
		})

		self.process = omgprocess:create({
			config = self.config,
			events = self.events,
			client = self.client,
		})

		self.started = false
	end,
	start = function(self, dispatched)
		assert(self, "The self must not be nil.")
		assert(self.config, "The server must be initialized.")
		assert(not self.started, "The server already started")

		local callback = function()
			self.started = true

			local runtime_qualifier = self.config.runtime_qualifier
			self.events:server_started(runtime_qualifier)
		end
		
		self.client:create_token(function(api_token, ws_token)
			if dispatched or false then
				self.dispatcher:connect(ws_token, callback)
			else
				callback()
			end
		end)
	end,
	update = function(self, dt)
		assert(self, "The self must not be nil.")
		assert(self.config, "The server must be initialized.")

		if self.started then
			self.process:update(dt)
		end
	end,
	-- Commands
	set_attributes = function(self, client_id, attributes)
		assert(self.config, "The server must be initialized.")
		assert(self.started, "The server must be started.")
		self.client:set_attributes(client_id, attributes)
	end,
	set_profile = function(self, client_id, profile)
		assert(self.config, "The server must be initialized.")
		assert(self.started, "The server must be started.")
		self.client:set_profile(client_id, profile)
	end,
	respond_client = function(self, client_id, message)
		assert(self.config, "The server must be initialized.")
		assert(self.started, "The server must be started.")
		self.client:respond_client(client_id, message)
	end,
	multicast_message = function(self, clients, message)
		assert(self.config, "The server must be initialized.")
		assert(self.started, "The server must be started.")
		self.client:multicast_message(clients, message)
	end,
	broadcast_message = function(self, message)
		assert(self.config, "The server must be initialized.")
		assert(self.started, "The server must be started.")
		self.client:broadcast_message(message)
	end,
	kick_client = function(self, client_id)
		assert(self.config, "The server must be initialized.")
		assert(self.started, "The server must be started.")
		self.client:kick_client(client_id)
	end,
	request_matchmaking = function(self, client_id, mode)
		assert(self.config, "The server must be initialized.")
		assert(self.started, "The server must be started.")
		self.client:request_matchmaking(client_id, mode)
	end,
	stop_matchmaking = function(self)
		assert(self.config, "The server must be initialized.")
		assert(self.started, "The server must be started.")
		self.client:stop_matchmaking()
	end,
	upgrade_connection = function(self, client_id)
		assert(self.config, "The server must be initialized.")
		assert(self.started, "The server must be started.")
		self.client:upgrade_connection(client_id)
	end,
	-- Messaging
	respond_text_message = function(self, client_id, message)
		assert(self.config, "The server must be initialized.")
		assert(self.started, "The server must be started.")
		self.dispatcher:respond_text_message(client_id, message)
	end,
	respond_binary_message = function(self, client_id, message)
		assert(self.config, "The server must be initialized.")
		assert(self.started, "The server must be started.")
		self.dispatcher:respond_binary_message(client_id, message)
	end,
	multicast_text_message = function(self, clients, message)
		assert(self.config, "The server must be initialized.")
		assert(self.started, "The server must be started.")
		self.dispatcher:multicast_text_message(clients, message)
	end,
	multicast_binary_message = function(self, clients, message)
		assert(self.config, "The server must be initialized.")
		assert(self.started, "The server must be started.")
		self.dispatcher:multicast_binary_message(clients, message)
	end,
	broadcast_text_message = function(self, message)
		assert(self.config, "The server must be initialized.")
		assert(self.started, "The server must be started.")
		self.dispatcher:broadcast_text_message(message)
	end,
	broadcast_binary_message = function(self, message)
		assert(self.config, "The server must be initialized.")
		assert(self.started, "The server must be started.")
		self.dispatcher:broadcast_binary_message(message)
	end,
}

return omginstance