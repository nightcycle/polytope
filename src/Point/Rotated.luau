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
-- Variables
-- References
-- Private Functions
-- Class
local Rotated = {}

function Rotated.new(cf: CFrame): RotatedPoint
	local out = {
		Type = "Rotated" :: "Rotated",
		Id = Util.cantorCFrame(cf),
		CFrame = cf,
		Normal = -cf.LookVector,
		Up = cf.UpVector,
		Position = cf.Position,
	}
	table.freeze(out)
	return out :: RotatedPoint
end

function Rotated.lerp(a: RotatedPoint, b: RotatedPoint, alpha: number): RotatedPoint
	return Rotated.new(a.CFrame:Lerp(b.CFrame, alpha))
end
function Rotated.hash(point: RotatedPoint): string return `PR{point.Id}` end

function Rotated.debug(point: RotatedPoint): { Instance }
	local out: { Instance } = {}
	if ENV.DEBUG_SHOW_POINTS then
		local newCF = Draw.cframe(CFrame.fromMatrix(point.Position, (-point.Normal):Cross(point.Up), point.Up))
		table.insert(out, newCF)
	end
	return out
end

return Rotated
