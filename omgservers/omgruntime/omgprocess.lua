local omgprocess
omgprocess = {
	--[[
	self,
	options = {
		config, -- omgconfig instance
		events, -- omgevents instance
		client, -- omgclient intance
	},
	]]--
	create = function(self, options)
		assert(self, "The self must not be nil.")
		assert(options, "The options must not be nil.")
		assert(options.config, "The value config must not be nil.")
		assert(options.config.type == "omgconfig", "The type of config must be omgconfig")
		assert(options.events, "The value events must not be nil.")
		assert(options.events.type == "omgevents", "The type of events must be omgevents")
		assert(options.client, "The value client must not be nil.")
		assert(options.client.type == "omgclient", "The type of client must be omgclient")

		local debug_logging = options.config.debug_logging

		local config = options.config
		local events = options.events
		local client = options.client

		return {
			type = "omgprocess",
			iteration_timer = 0,
			empty_iterations = 0,
			faster_iterations = true,
			interchange_requested = false,
			-- Methods
			interchange = function(instance, dt)
				if not client:fully_fledged() then
					return
				end
				
				local iteration_timer = instance.iteration_timer + dt

				local current_interval
				if instance.faster_iterations then
					current_interval = config.faster_interval
				else
					current_interval = config.default_interval
				end

				if instance.iteration_timer > current_interval then
					instance.iteration_timer = 0

					if not instance.interchange_requested then
						instance.interchange_requested = true
						client:interchange(function(incoming_commands)
							instance.interchange_requested = false

							-- Switch between default and faster intervals
							if #incoming_commands > 0 then
								instance.empty_iterations = 0
								if not instance.faster_iterations then
									instance.faster_iterations = true

									if debug_logging then
										print(socket.gettime() .. " [OMGSERVER] Switched to faster iterations")
									end
								end
							else
								local empty_iterations = instance.empty_iterations + 1
								instance.empty_iterations = empty_iterations

								if empty_iterations >= config.iterations_threshold then
									if instance.faster_iterations then
										instance.faster_iterations = false
										if debug_logging then
											print(socket.gettime() .. " [OMGSERVER] Switched to default iterations")
										end
									end
								end
							end

							for _, incoming_command in ipairs(incoming_commands) do
								local command_qualifier = incoming_command.qualifier
								local command_body = incoming_command.body
								events:command_received(command_qualifier, command_body)
							end
						 end)
					end
				else
					instance.iteration_timer = iteration_timer
				end
			end,
			update = function(instance, dt)
				instance:interchange(dt)
				events:update()
			end
		}
	end
}

return omgprocess