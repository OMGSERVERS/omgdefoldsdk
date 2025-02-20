local omgsystem
omgsystem = {
	-- Methods
	terminate_server = function(self, code, reason)
		print(os.date() .. " [OMGSERVER] Terminated, code=" .. code .. ", reason=" .. reason)
		os.exit(code)
	end,
}

return omgsystem