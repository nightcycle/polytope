--!strict
-- Services
-- Packages
local Draw = require(script.Parent.Parent.Parent.Draw)
-- Modules
local PointUtil = require(script.Parent.Parent.PointUtil)
local ENV = require(script.Parent.Parent.ENV)
local Util = require(script.Parent.Parent.Util)
-- Types
export type VertexPoint = PointUtil.VertexPoint
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
local Vertex = {}

function Vertex.new(position: Vector3, normal: Vector3): VertexPoint
	local out = {
		Type = "Vertex" :: "Vertex",
		Id = Util.cantorCFrame(CFrame.lookAlong(position, normal)),
		Position = position,
		Normal = normal,
	}
	table.freeze(out)
	return out :: VertexPoint
end

function Vertex.lerp(a: VertexPoint, b: VertexPoint, alpha: number): VertexPoint
	return Vertex.new(a.Position:Lerp(b.Position, alpha), a.Normal:Lerp(b.Normal, alpha).Unit)
end

function Vertex.hash(point: VertexPoint): string return `PV{point.Id}` end

function Vertex.debug(point: VertexPoint): { Instance }
	local out: { Instance } = {}
	if ENV.DEBUG_SHOW_POINTS then
		local newPoint = Draw.point(point.Position)
		table.insert(out, newPoint)
	end
	return out
end

return Vertex
