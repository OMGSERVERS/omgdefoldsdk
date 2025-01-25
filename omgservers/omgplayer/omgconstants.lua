local omgconstants
omgconstants = {
	-- Runtime qualifiers
	LOBBY = "LOBBY",
	MATCH = "MATCH",
	-- Message qualifiers
	SERVER_WELCOME_MESSAGE = "SERVER_WELCOME_MESSAGE",
	RUNTIME_ASSIGNMENT_MESSAGE = "RUNTIME_ASSIGNMENT_MESSAGE",
	MATCHMAKER_ASSIGNMENT_MESSAGE = "MATCHMAKER_ASSIGNMENT_MESSAGE",
	CONNECTION_UPGRADE_MESSAGE = "CONNECTION_UPGRADE_MESSAGE",
	DISCONNECTION_REASON_MESSAGE = "DISCONNECTION_REASON_MESSAGE",
	SERVER_OUTGOING_MESSAGE = "SERVER_OUTGOING_MESSAGE",
	CLIENT_OUTGOING_MESSAGE = "CLIENT_OUTGOING_MESSAGE",
	-- Player events
	SERVICE_PINGED = "SERVICE_PINGED",
	SIGNED_UP = "SIGNED_UP",
	SIGNED_IN = "SIGNED_IN",
	GREETED = "GREETED",
	ASSIGNED = "ASSIGNED",
	MESSAGE_RECEIVED = "MESSAGE_RECEIVED",
	CONNECTION_UPGRADED = "CONNECTION_UPGRADED",
	PLAYER_FAILED = "PLAYER_FAILED",
	-- Disconnection reasons
	CLIENT_INACTIVITY = "CLIENT_INACTIVITY",
	INTERNAL_FAILURE = "INTERNAL_FAILURE",
	-- Upgrade protocols
	DISPATCHER_PROTOCOL = "DISPATCHER",
}

return omgconstants
