local omgconstants = require("omgservers.omgplayer.omgconstants")

local omgstate
omgstate = {
	--[[
		self,
		options = {
			events, -- omgevents instance
		},
	]]--
	create = function(self, options)
		assert(self, "Self must not be nil.")
		assert(options, "Options must not be nil.")
		assert(options.events, "Events must not be nil.")

		local events = options.events
		
		return {
			type = "omgstate",
			version_id = nil,
			version_created = nil,
			lobby_id = nil,
			match_id = nil,
			failed = false,
			-- Methods
			greet_player = function(instance, version_id, version_created)
				instance.version_id = version_id
				instance.version_created = version_created
				events:player_greeted(instance.version_id, instance.version_created)
			end,
			assign_lobby = function(instance, runtime_id)
				instance.lobby_id = runtime_id
				instance.match_id = nil

				events:runtime_assigned(omgconstants.runtimes.LOBBY, runtime_id)
			end,
			assign_match = function(instance, runtime_id)
				instance.lobby_id = nil
				instance.match_id = runtime_id
				
				events:runtime_assigned(omgconstants.runtimes.MATCH, runtime_id)
			end,
			fail = function(instance, reason)
				instance.failed = true
				events:player_failed(reason)
			end
		}
	end
}

return omgstate