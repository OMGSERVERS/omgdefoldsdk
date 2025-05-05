local omgconstants = require("omgservers.omgruntime.omgconstants")
local omginstance = require("omgservers.omgruntime.omginstance")

local omgruntime
omgruntime = {
	constants = omgconstants,
	-- Methods
	create = function(self)
		local instance = omginstance:create()
		return instance
	end,
}

return omgruntime