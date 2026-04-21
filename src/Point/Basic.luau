--!strict
-- Services
-- Packages
local Draw = require(script.Parent.Parent.Parent.Draw)
-- Modules
local PointUtil = require(script.Parent.Parent.PointUtil)
local ENV = require(script.Parent.Parent.ENV)
local Util = require(script.Parent.Parent.Util)
-- Types
export type BasicPoint = PointUtil.BasicPoint
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
local Basic = {}

function Basic.new(position: Vector3): BasicPoint
	local out = {
		Type = "Basic" :: "Basic",
		Position = position,
	}
	table.freeze(out)
	return out
end

function Basic.eq(a: BasicPoint, b: BasicPoint): boolean
	if a.Type ~= b.Type then
		return false
	end
	return Util.positionEq(a.Position, b.Position)
end

function Basic.lerp(a: BasicPoint, b: BasicPoint, alpha: number): BasicPoint
	return Basic.new(a.Position:Lerp(b.Position, alpha))
end

function Basic.debug(point: BasicPoint): { Instance }
	local out: { Instance } = {}
	if ENV.DEBUG_SHOW_POINTS then
		local newPoint = Draw.point(point.Position)
		table.insert(out, newPoint)
	end
	return out
end

return Basic
