local omgconstants
omgconstants = {
	exit_codes = {
		ENVIRONMENT = 1,
		TOKEN = 2,
		CONFIG = 3,
		API = 4,
		WS = 5,
	},
	environment = {
		SERVICE_URL = "OMGSERVERS_SERVICE_URL",
		RUNTIME_ID = "OMGSERVERS_RUNTIME_ID",
		PASSWORD = "OMGSERVERS_PASSWORD",
		QUALIFIER = "OMGSERVERS_QUALIFIER",
	},
	runtimes = {
		LOBBY = "LOBBY",
		MATCH = "MATCH",
	},
	events = {
		SERVER_STARTED = "SERVER_STARTED",
		MESSAGE_RECEIVED = "MESSAGE_RECEIVED",
	},
	messages = {
		-- Service -> Runtime
		RUNTIME_CREATED = "RUNTIME_CREATED",
		CLIENT_ASSIGNED = "CLIENT_ASSIGNED",
		CLIENT_REMOVED = "CLIENT_REMOVED",
		MESSAGE_RECEIVED = "MESSAGE_RECEIVED",
		-- Runtime -> Service
		RESPOND_CLIENT = "RESPOND_CLIENT",
		SET_PROFILE = "SET_PROFILE",
		MULTICAST_MESSAGE = "MULTICAST_MESSAGE",
		BROADCAST_MESSAGE = "BROADCAST_MESSAGE",
		REQUEST_MATCHMAKING = "REQUEST_MATCHMAKING",
		KICK_CLIENT = "KICK_CLIENT",
		STOP_MATCHMAKING = "STOP_MATCHMAKING",
		UPGRADE_CONNECTION = "UPGRADE_CONNECTION",
	},
	protocols = {
		DISPATCHER = "DISPATCHER",
		BASE64 = "B64",
		PLAIN_TEXT = "TXT",
	}
}

return omgconstants