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

function Rotated.addMeshVertex(point: RotatedPoint, mesh: EditableMesh, origin: CFrame): number
	return mesh:AddVertex(origin:PointToObjectSpace(point.Position))
end

function Rotated.addMeshNormal(point: RotatedPoint, mesh: EditableMesh, origin: CFrame): number
	return mesh:AddNormal(origin:VectorToObjectSpace(point.Normal))
end

function Rotated.findMeshVertex(point: RotatedPoint, mesh: EditableMesh, origin: CFrame): number?
	local vId = mesh:FindClosestVertex(origin:PointToObjectSpace(point.Position))
	if vId and vId > 0 then
		local vPos = origin:PointToWorldSpace(mesh:GetPosition(vId))
		if (vPos - point.Position).Magnitude <= CONSTANTS.FUZZY_EQ.LENGTH then return vId end
	end
	return nil
end

return Rotated
