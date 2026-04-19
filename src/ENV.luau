--!strict
-- Services
-- Packages
-- Modules
-- Types
-- Constants
local PREFIX = "__MOUNT3D__"
-- Variables
-- References
-- Private Functions
-- Class
local DEFAULT_ENV = {
	IS_VERBOSE = false,
	DEBUG_SHOW_POINTS = true,
	DEBUG_SHOW_LINES = true,
	DEBUG_SHOW_NORMALS = true,
	DEBUG_SHOW_FACES = true,
	DEBUG_PARTS_LOCKED = true,
}
local out: any = setmetatable({}, {
	__index = function(_, readableKey: string): any?
		local k = PREFIX .. readableKey
		local v = _G[k]
		local dV = rawget(DEFAULT_ENV, readableKey)
		if dV == nil then
			error(`Attempt to access undefined key "{readableKey}" in ENV`)
		end
		if typeof(v) == "string" then
			if typeof(dV) == "boolean" then
				if v == "true" then
					return true
				elseif v == "false" then
					return false
				else
					return dV
				end
			elseif typeof(dV) == "number" then
				local n = tonumber(v)
				if n ~= nil then
					return n
				else
					return dV
				end
			end
		end
		if v == nil then
			return dV
		else
			return v
		end
	end,
	__newindex = function(_, readableKey, v)
		local k = PREFIX .. readableKey
		assert(rawget(DEFAULT_ENV, readableKey) ~= nil, `Attempt to set undefined key "{readableKey}" in ENV`)
		_G[k] = v
	end,
})

return out :: typeof(DEFAULT_ENV)
