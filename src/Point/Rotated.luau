--!strict
-- Services
-- Packages
local Draw = require(script.Parent.Parent.Parent.Draw)
-- Modules
local PointUtil = require(script.Parent.Parent.PointUtil)
local ENV = require(script.Parent.Parent.ENV)
local Util = require(script.Parent.Parent.Util)
-- Types
export type RotatedPoint = PointUtil.RotatedPoint
-- Constants
local CONSTANTS = require(script.Parent.Parent.CONSTANTS)
-- Variables
-- References
-- Private Functions
-- Class
local Rotated = {}

function Rotated.new(cf: CFrame): RotatedPoint
	local out = {
		Type = "Rotated" :: "Rotated",
		CFrame = cf,
		Normal = -cf.LookVector,
		Up = cf.UpVector,
		Position = cf.Position,
	}
	table.freeze(out)
	return out
end

function Rotated.eq(a: RotatedPoint, b: RotatedPoint): boolean
	if a.Type ~= b.Type then
		return false
	end
	return Util.positionEq(a.Position, b.Position)
		and a.Normal:FuzzyEq(b.Normal, CONSTANTS.FUZZY_EQ.EPSILON)
		and a.Up:FuzzyEq(b.Up, CONSTANTS.FUZZY_EQ.EPSILON)
end

function Rotated.lerp(a: RotatedPoint, b: RotatedPoint, alpha: number): RotatedPoint
	return Rotated.new(a.CFrame:Lerp(b.CFrame, alpha))
end

function Rotated.debug(point: RotatedPoint): { Instance }
	local out: { Instance } = {}
	if ENV.DEBUG_SHOW_POINTS then
		local newCF = Draw.cframe(CFrame.fromMatrix(point.Position, (-point.Normal):Cross(point.Up), point.Up))
		table.insert(out, newCF)
	end
	return out
end

return Rotated
