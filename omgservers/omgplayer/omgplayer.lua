local omgconstants = require("omgservers.omgplayer.omgconstants")
local omginstance = require("omgservers.omgplayer.omginstance")

local omgplayer
omgplayer = {
	constants = omgconstants,
	-- Methods
	create = function(self)
		local instance = omginstance:create()
		return instance
	end
}

return omgplayer
