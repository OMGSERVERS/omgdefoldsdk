local omgconstants
omgconstants = {
	-- Runtime qualifiers
	runtimes = {
		LOBBY = "LOBBY",
		MATCH = "MATCH",
	},
	messages = {
		CLIENT_GREETED = "CLIENT_GREETED",
		RUNTIME_ASSIGNED = "RUNTIME_ASSIGNED",
		CONNECTION_UPGRADED = "CONNECTION_UPGRADED",
		CLIENT_DELETED = "CLIENT_DELETED",
		MESSAGE_PRODUCED = "MESSAGE_PRODUCED",
	},
	events = {
		SERVICE_PINGED = "SERVICE_PINGED",
		SIGNED_UP = "SIGNED_UP",
		SIGNED_IN = "SIGNED_IN",
		PLAYER_GREETED = "PLAYER_GREETED",
		RUNTIME_ASSIGNED = "RUNTIME_ASSIGNED",
		MESSAGE_RECEIVED = "MESSAGE_RECEIVED",
		CONNECTION_DISPATCHED = "CONNECTION_DISPATCHED",
		PLAYER_FAILED = "PLAYER_FAILED",
	},
	reasons = {
		CLIENT_INACTIVITY = "CLIENT_INACTIVITY",
		INTERNAL_FAILURE = "INTERNAL_FAILURE",
	},
	protocols = {
		DISPATCHER = "DISPATCHER",
	},
}

return omgconstants
