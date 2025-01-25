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
		assert(self, "The self must not be nil.")
		assert(options, "The options must not be nil.")
		assert(options.events, "The value events must not be nil.")
		assert(options.events.type == "omgevents", "The type of events must be omgevents")

		local events = options.events
		
		return {
			type = "omgstate",
			version_id = nil,
			version_created = nil,
			greeted = false,
			lobby_id = nil,
			matchmaker_id = nil,
			match_id = nil,
			failed = false,
			-- Methods
			welcome = function(instance, version_id, version_created)
				instance.version_id = version_id
				instance.version_created = version_created
			end,
			assign_matchmaker = function(instance, matchmaker_id)
				instance.matchmaker_id = matchmaker_id
			end,
			assign_lobby = function(instance, runtime_id)
				instance.lobby_id = runtime_id
				instance.match_id = nil

				if instance.greeted then
					events:assigned(omgconstants.LOBBY, runtime_id)
				else
					instance:greet()
				end
			end,
			assign_match = function(instance, runtime_id)
				instance.lobby_id = nil
				instance.match_id = runtime_id
				
				events:assigned(omgconstants.MATCH, runtime_id)
			end,
			greet = function(instance)
				instance.greeted = true
				events:greeted(instance.version_id, instance.version_created)
			end,
			fail = function(instance, reason)
				instance.failed = true
				events:failed(reason)
			end
		}
	end
}

return omgstate