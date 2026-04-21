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
local CONSTANTS = require(script.Parent.Parent.CONSTANTS)
-- Variables
-- References
-- Private Functions
-- Class
local Vertex = {}

function Vertex.new(position: Vector3, normal: Vector3): VertexPoint
	local out = {
		Type = "Vertex" :: "Vertex",
		Position = position,
		Normal = normal,
	}
	table.freeze(out)
	return out
end

function Vertex.eq(a: VertexPoint, b: VertexPoint): boolean
	if a.Type ~= b.Type then
		return false
	end
	return Util.positionEq(a.Position, b.Position) and a.Normal:FuzzyEq(b.Normal, CONSTANTS.FUZZY_EQ.EPSILON)
end

function Vertex.lerp(a: VertexPoint, b: VertexPoint, alpha: number): VertexPoint
	return Vertex.new(a.Position:Lerp(b.Position, alpha), a.Normal:Lerp(b.Normal, alpha).Unit)
end

function Vertex.debug(point: VertexPoint): { Instance }
	local out: { Instance } = {}
	if ENV.DEBUG_SHOW_POINTS then
		local newPoint = Draw.point(point.Position)
		table.insert(out, newPoint)
	end
	return out
end

return Vertex
