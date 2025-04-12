local omgconstants = require("omgservers.omgruntime.omgconstants")
local omginstance = require("omgservers.omgruntime.omginstance")

local omgruntime
omgruntime = {
	constants = omgconstants,
	-- Methods
	init = function(self, options)
		return omginstance:init(options)
	end,
	start = function(self, dispatched)
		omginstance:start(dispatched)
	end,
	update = function(self, dt)
		omginstance:update(dt)
	end,
	-- Commands
	set_profile = function(self, client_id, profile)
		omginstance:set_profile(client_id, profile)
	end,
	respond_client = function(self, client_id, message)
		omginstance:respond_client(client_id, message)
	end,
	multicast_message = function(self, clients, message)
		omginstance:multicast_message(clients, message)
	end,
	broadcast_message = function(self, message)
		omginstance:broadcast_message(message)
	end,
	kick_client = function(self, client_id)
		omginstance:kick_client(client_id)
	end,
	request_matchmaking = function(self, client_id, mode)
		omginstance:request_matchmaking(client_id, mode)
	end,
	stop_matchmaking = function(self)
		omginstance:stop_matchmaking()
	end,
	upgrade_connection = function(self, client_id)
		omginstance:upgrade_connection(client_id)
	end,
	-- Messaging
	respond_text_message = function(self, client_id, message)
		omginstance:respond_text_message(client_id, message)
	end,
	respond_binary_message = function(self, client_id, message)
		omginstance:respond_binary_message(client_id, message)
	end,
	multicast_text_message = function(self, clients, message)
		omginstance:multicast_text_message(clients, message)
	end,
	multicast_binary_message = function(self, clients, message)
		omginstance:multicast_binary_message(clients, message)
	end,
	broadcast_text_message = function(self, message)
		omginstance:broadcast_text_message(message)
	end,
	broadcast_binary_message = function(self, message)
		omginstance:broadcast_binary_message(message)
	end,
}

return omgruntime