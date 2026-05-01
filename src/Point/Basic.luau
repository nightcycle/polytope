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
local CONSTANTS = require(script.Parent.Parent.CONSTANTS)
-- Variables
-- References
-- Private Functions
-- Class
local Basic = {}

function Basic.new(position: Vector3): BasicPoint
	local out = {
		Type = "Basic" :: "Basic",
		Id = Util.cantorV3((position / CONSTANTS.FUZZY_EQ.LENGTH):Floor()),
		Position = position,
	}
	table.freeze(out)
	return out :: BasicPoint
end
function Basic.lerp(a: BasicPoint, b: BasicPoint, alpha: number): BasicPoint
	return Basic.new(a.Position:Lerp(b.Position, alpha))
end

function Basic.hash(point: BasicPoint): string return `PB{point.Id}` end

function Basic.debug(point: BasicPoint): { Instance }
	local out: { Instance } = {}
	if ENV.DEBUG_SHOW_POINTS then
		local newPoint = Draw.point(point.Position)
		table.insert(out, newPoint)
	end
	return out
end

function Basic.addMeshVertex(point: BasicPoint, mesh: EditableMesh, origin: CFrame): number
	return mesh:AddVertex(origin:PointToObjectSpace(point.Position))
end

function Basic.findMeshVertex(point: BasicPoint, mesh: EditableMesh, origin: CFrame): number?
	local vId = mesh:FindClosestVertex(origin:PointToObjectSpace(point.Position))
	if vId and vId > 0 then
		local vPos = origin:PointToWorldSpace(mesh:GetPosition(vId))
		if (vPos - point.Position).Magnitude <= CONSTANTS.FUZZY_EQ.LENGTH then return vId end
	end
	return nil
end

return Basic
