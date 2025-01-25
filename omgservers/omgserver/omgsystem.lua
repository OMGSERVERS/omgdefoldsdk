local omgsystem
omgsystem = {
	-- Methods
	terminate_server = function(self, code, reason)
		print(socket.gettime() .. " [OMGSERVER] Terminated, code=" .. code .. ", reason=" .. reason)
		os.exit(code)
	end,
}

return omgsystem