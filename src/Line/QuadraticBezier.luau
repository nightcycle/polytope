--!strict
-- Services
-- Packages
-- Modules
local Point = require(script.Parent.Parent.Point)
local LineUtil = require(script.Parent.Parent.LineUtil)
local Util = require(script.Parent.Parent.Util)
-- Types
export type QuadraticBezierLine = LineUtil.QuadraticBezierLine
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
local QuadraticBezier = {}

function QuadraticBezier.new(
	p1: Point.VertexPoint,
	p2: Point.VertexPoint,
	intersection: Point.BasicPoint
): QuadraticBezierLine
	local out = {
		Type = "QuadraticBezier" :: "QuadraticBezier",
		P1 = p1,
		P2 = p2,
		Intersection = intersection,
	} :: QuadraticBezierLine
	table.freeze(out)
	return out
end

function QuadraticBezier.eq(a: QuadraticBezierLine, b: QuadraticBezierLine): boolean
	if a.Type ~= b.Type then
		return false
	end
	if not Point.Basic.eq(a.Intersection, b.Intersection) then
		return false
	end
	if Point.Vertex.eq(a.P1, b.P1) then
		return Point.Vertex.eq(a.P2, b.P2)
	elseif Point.Vertex.eq(a.P1, b.P2) then
		return Point.Vertex.eq(a.P2, b.P1)
	end
	return false
end

function QuadraticBezier.magnitude(line: QuadraticBezierLine): number
	return Util.getBezierLength(line.P1.Position, line.Intersection.Position, line.P2.Position, 1)
end

function QuadraticBezier.debug(line: QuadraticBezierLine): { Instance }
	local out: { Instance } = {}
	Util.join(out, Point.Any.debug(line.P1))
	Util.join(out, Point.Any.debug(line.Intersection))
	Util.join(out, Point.Any.debug(line.P2))
	return out
end

function QuadraticBezier.pointAt(line: QuadraticBezierLine, t: number): Vector3
	local u = 1 - t
	return u * u * line.P1.Position + 2 * u * t * line.Intersection.Position + t * t * line.P2.Position
end

function QuadraticBezier.pointAtOffset(line: QuadraticBezierLine, offset: number): Vector3
	local len = QuadraticBezier.magnitude(line)
	return QuadraticBezier.pointAt(line, math.clamp(offset, 0, len) / len)
end

function QuadraticBezier.intersection(a: QuadraticBezierLine, other: LineUtil.Line): Vector3?
	warn(`QuadraticBezier does not currently support intersection()`)
	return nil
end

return QuadraticBezier
