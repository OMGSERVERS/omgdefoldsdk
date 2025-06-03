local omgconfig
omgconfig = {
	--[[
		self,
		options = {
			-- Required
			tenant,
			project,
			stage,
			event_handler,
			-- Optional
			service_url,
			info_logging,
			debug_logging,
			trace_logging,
			through_connector,
			default_interval,
			faster_interval,
			iterations_threshold,
		},
	]]--
	create = function(self, options)
		assert(self, "Self must not be nil.")
		assert(options, "Options must not be nil.")
		assert(options.tenant, "Tenant must not be nil.")
		assert(options.project, "Project must not be nil.")
		assert(options.stage, "Stage must not be nil.")
		assert(options.event_handler, "Event handler must not be null.")

		local service_url = options.service_url or "https://demoserver.omgservers.com"
		local info_logging = options.info_logging or true
		local debug_logging = options.debug_logging or false
		local trace_logging = options.trace_logging or false
		local through_connector = options.through_connector or true
		local default_interval = options.default_interval or 1
		local faster_interval = options.faster_interval or 0.5
		local iterations_threshold = options.iterations_threshold or 4

		assert(default_interval > 0, "Default interval must be greater than zero.")
		assert(faster_interval > 0, "Faster interval must be greater than zero.")
		assert(iterations_threshold > 0, "Iteration threshold must be greater than zero.")
		assert(faster_interval < default_interval, "Faster interval must be less than the default.")
		
		local instance = {
			type = "omgconfig",
			tenant = options.tenant,
			project = options.project,
			stage = options.stage,
			event_handler = options.event_handler,
			service_url = service_url,
			info_logging = info_logging,
			debug_logging = debug_logging,
			trace_logging = trace_logging,
			through_connector = through_connector,
			default_interval = default_interval,
			faster_interval = faster_interval,
			iterations_threshold = iterations_threshold,
		}

		if info_logging then
			print(os.date() .. " [OMGPLAYER] Config created")
			pprint(instance)
		end
		
		return instance
	end,
}

return omgconfig
