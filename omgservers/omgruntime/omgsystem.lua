local omgsystem
omgsystem = {
	-- Methods
	terminate_server = function(self, code, reason)
		print(os.date() .. " [OMGSERVER] Terminated, code=" .. tostring(code) .. ", reason=" .. tostring(reason))
		os.exit(code)
	end,
}

return omgsystem