local omghttp
omghttp = {
	--[[
	self,
	options = {
		config, -- omgconfig instance
	},
	]]--
	create = function(self, options)
		assert(self, "The self must not be nil.")
		assert(options, "The options must not be nil.")
		assert(options.config, "The value config must not be nil.")
		assert(options.config.type == "omgconfig", "The type of config must be omgconfig")

		local trace_logging = options.config.trace_logging

		return {
			type = "omghttp",
			-- Methods
			decode_response = function(instance, response_body)
				local status, result = pcall(json.decode, response_body)
				if status then
					return result
				else
					return nil, result
				end
			end,
			build_handler = function(instance, response_handler, failure_handler)
				return function(_, id, response)
					local response_status = response.status
					local response_body = response.response

					if trace_logging then
						print(socket.gettime() .. " [OMGSERVER] Response, status=" .. response_status .. ", body=" .. response_body)
					end

					local decoded_body, decoding_error = instance:decode_response(response_body)
					if decoding_error then
						failure_handler(response_status, nil, decoding_error)
					else
						if response_status >= 200 and response_status < 300 then
							response_handler(response_status, decoded_body)
						else
							failure_handler(response_status, decoded_body)
						end
					end
				end
			end,
			request_server = function(instance, url, request_body, response_handler, failure_handler, request_token)
				local request_headers = {
					["Content-Type"] = "application/json"
				}

				if request_token then
					request_headers["Authorization"] = "Bearer " .. request_token
				end

				local encoded_body = json.encode(request_body, {
					encode_empty_table_as_object = false
				})

				local method = "POST"

				if trace_logging then
					print(socket.gettime() .. " [OMGSERVER] Request, " .. method .. " " .. url .. ", body=" .. encoded_body)
				end
				
				local handler = instance:build_handler(response_handler, failure_handler)
				http.request(url, method, handler, request_headers, encoded_body)
			end,
		}
	end
}

return omghttp
