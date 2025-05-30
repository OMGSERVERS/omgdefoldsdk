local omgconstants = require("omgservers.omgruntime.omgconstants")
local omgsystem = require("omgservers.omgruntime.omgsystem")

local omgconfig
omgconfig = {
	--[[
	self,
	options = {
		-- Required
		event_handler, 
		-- Optional
		info_logging,
		debug_logging,
		trace_logging,
		default_interval, 
		faster_interval,
		iterations_threshold
	},
	]]--
	create = function(self, options)
		assert(self, "Self must not be nil.")
		assert(options, "Options must not be nil.")
		assert(options.event_handler, "Event handler must not be null.")

		local info_logging = options.debug_logging or true
		local debug_logging = options.debug_logging or false
		local trace_logging = options.trace_logging or false
		local default_interval = options.default_interval or 1
		local faster_interval = options.faster_interval or 0.5
		local iterations_threshold = options.iterations_threshold or 4

		assert(default_interval > 0, "Default interval must be greater than zero.")
		assert(faster_interval > 0, "Faster interval must be greater than zero.")
		assert(iterations_threshold > 0, "Iteration threshold must be greater than zero.")
		assert(faster_interval < default_interval, "Faster interval must be less than the default.")

		local service_url = os.getenv(omgconstants.environment.SERVICE_URL)
		if not service_url then
			omgsystem:terminate_server(omgconstants.exit_codes.ENVIRONMENT, "missing environment variable, variable=" .. tostring(omgconstants.environment.SERVICE_URL))
		end

		local runtime_id = os.getenv(omgconstants.environment.RUNTIME_ID)
		if not runtime_id then
			omgsystem:terminate_server(omgconstants.exit_codes.ENVIRONMENT, "missing environment variable, variable=" .. tostring(omgconstants.environment.RUNTIME_ID))
		end

		local password = os.getenv(omgconstants.environment.PASSWORD)
		if not password then
			omgsystem:terminate_server(omgconstants.exit_codes.ENVIRONMENT, "missing environment variable, variable=" .. tostring(omgconstants.environment.PASSWORD))
		end

		local qualifier = os.getenv(omgconstants.environment.QUALIFIER)
		if not qualifier then
			omgsystem:terminate_server(omgconstants.exit_codes.ENVIRONMENT, "missing environment variable, variable=" .. tostring(omgconstants.environment.QUALIFIER))
		end
		
		local instance = {
			type = "omgconfig",
			event_handler = options.event_handler,
			service_url = service_url,
			runtime_id = runtime_id,
			password = "<hidden>",
			runtime_qualifier = qualifier,
			info_logging = info_logging,
			debug_logging = debug_logging,
			trace_logging = trace_logging,
			default_interval = default_interval,
			faster_interval = faster_interval,
			iterations_threshold = iterations_threshold,
		}

		if info_logging then
			print(os.date() .. " [OMGSERVER] Config created")
			pprint(instance)
		end

		instance.password = password

		return instance
	end
}

return omgconfig