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
		Id = Util.cantorPair(Util.cantorPairUnordered(p1.Id, p2.Id), intersection.Id),
		P1 = p1,
		P2 = p2,
		Intersection = intersection,
	} :: QuadraticBezierLine
	table.freeze(out)
	return out :: QuadraticBezierLine
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

function QuadraticBezier.hash(line: QuadraticBezierLine) return `LQ{line.Id}` end

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
