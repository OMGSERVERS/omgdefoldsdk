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
		debug_logging, 
		trace_logging,
		default_interval, 
		faster_interval,
		iterations_threshold
	},
	]]--
	create = function(self, options)
		assert(self, "The self must not be nil.")
		assert(options, "The options must not be nil.")
		assert(options.event_handler, "The value event_handler must not be null.")

		local debug_logging = options.debug_logging or false
		local trace_logging = options.trace_logging or false
		local default_interval = options.default_interval or 1
		local faster_interval = options.faster_interval or 0.5
		local iterations_threshold = options.iterations_threshold or 4

		assert(default_interval > 0, "The default interval must be greater than zero.")
		assert(faster_interval > 0, "The faster interval must be greater than zero.")
		assert(iterations_threshold > 0, "The iteration threshold must be greater than zero.")
		assert(faster_interval < default_interval, "The faster interval must be less than the default.")

		local service_url = os.getenv(omgconstants.SERVICE_URL)
		if not service_url then
			omgsystem:terminate_server(omgconstants.ENVIRONMENT_EXIT_CODE, "environment variable is nil, variable=service_url")
		end

		local runtime_id = os.getenv(omgconstants.RUNTIME_ID)
		if not runtime_id then
			omgsystem:terminate_server(omgconstants.ENVIRONMENT_EXIT_CODE, "environment variable is nil, variable=runtime_id")
		end

		local password = os.getenv(omgconstants.PASSWORD)
		if not password then
			omgsystem:terminate_server(omgconstants.ENVIRONMENT_EXIT_CODE, "environment variable is nil, variable=password")
		end

		local runtime_qualifier = os.getenv(omgconstants.RUNTIME_QUALIFIER)
		if not runtime_qualifier then
			omgsystem:terminate_server(omgconstants.ENVIRONMENT_EXIT_CODE, "environment variable is nil, variable=runtime_qualifier")
		end
		
		local instance = {
			type = "omgconfig",
			event_handler = options.event_handler,
			service_url = service_url,
			runtime_id = runtime_id,
			password = "<hidden>",
			runtime_qualifier = runtime_qualifier,
			debug_logging = debug_logging,
			trace_logging = trace_logging,
			default_interval = default_interval,
			faster_interval = faster_interval,
			iterations_threshold = iterations_threshold,
		}

		if debug_logging then
			print(os.date() .. " [OMGSERVER] Config was created")
			pprint(instance)
		end

		instance.password = password

		return instance
	end
}

return omgconfig