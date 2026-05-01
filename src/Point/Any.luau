--!strict
-- Services
-- Packages
-- Modules
local PointUtil = require(script.Parent.Parent.PointUtil)
local Basic = require(script.Parent.Basic)
local Rotated = require(script.Parent.Rotated)
local Vertex = require(script.Parent.Vertex)
-- Types
export type Point = PointUtil.Point
-- Constants
-- Variables
-- References
-- Private Functions
function toFirstCommonAncestor(a: Point, b: Point): (Point, Point)
	if a.Type == b.Type then return a, b end
	if a.Type == "Basic" then
		return a, Basic.new(b.Position)
	elseif b.Type == "Basic" then
		return Basic.new(a.Position), b
	else
		if a.Type == "Vertex" then
			return a, Vertex.new(b.Position, b.Normal)
		elseif b.Type == "Vertex" then
			return Vertex.new(a.Position, a.Normal), b
		else
			error(`unknown type: {a.Type}, {b.Type}`)
		end
	end
end
-- Class
local Any = {}

function Any.hash(point: Point): string
	if point.Type == "Basic" then
		assert(point.Type == "Basic", `bad point type: {point.Type}`)
		return Basic.hash(point)
	elseif point.Type == "Vertex" then
		assert(point.Type == "Vertex", `bad point type: {point.Type}`)
		return Vertex.hash(point)
	elseif point.Type == "Rotated" then
		assert(point.Type == "Rotated", `bad point type: {point.Type}`)
		return Rotated.hash(point)
	else
		error(`bad type: "{point.Type}"`)
	end
end

function Any.lerp(a: Point, b: Point, alpha: number): Point
	if a.Type ~= b.Type then
		local newA, newB = toFirstCommonAncestor(a, b)
		return Any.lerp(newA, newB, alpha)
	end
	if a.Type == "Basic" then
		assert(b.Type == "Basic", `bad b type: {b.Type}`)
		return Basic.lerp(a, b, alpha)
	elseif a.Type == "Vertex" then
		assert(b.Type == "Vertex", `bad b type: {b.Type}`)
		return Vertex.lerp(a, b, alpha)
	elseif a.Type == "Rotated" then
		assert(b.Type == "Rotated", `bad b type: {b.Type}`)
		return Rotated.lerp(a, b, alpha)
	else
		error(`bad type: "{a.Type}"`)
	end
end

function Any.debug(point: Point): { Instance }
	if point.Type == "Basic" then
		return Basic.debug(point)
	elseif point.Type == "Vertex" then
		return Vertex.debug(point)
	elseif point.Type == "Rotated" then
		return Rotated.debug(point)
	else
		error(`bad type: "{point.Type}"`)
	end
end

return Any
