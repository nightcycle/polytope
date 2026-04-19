--!strict
-- Services
-- Packages
local Draw = require(script.Parent.Parent.Draw)
-- Modules
local Point = require(script.Parent.Point)
local Util = require(script.Parent.Util)
local ENV = require(script.Parent.ENV)
-- Types
export type Point = Point.Point
export type VertexPoint = Point.VertexPoint
export type RotatedPoint = Point.RotatedPoint
export type BasicPoint = Point.BasicPoint
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
local Line = {}

export type StraightLine = {
	Type: "Straight",
	P1: VertexPoint,
	P2: VertexPoint,
	Offset: Vector3,
}
do
	Line.Straight = {}

	function Line.Straight.new(p1: VertexPoint, p2: VertexPoint): StraightLine
		local out = {
			Type = "Straight" :: "Straight",
			P1 = p1,
			P2 = p2,
			Offset = p2.Position - p1.Position,
		} :: StraightLine
		table.freeze(out)
		return out
	end

	function Line.Straight.eq(a: StraightLine, b: StraightLine): boolean
		if a.Type ~= b.Type then
			return false
		end
		if Point.Vertex.eq(a.P1, b.P1) then
			return Point.Vertex.eq(a.P2, b.P2)
		elseif Point.Vertex.eq(a.P1, b.P2) then
			return Point.Vertex.eq(a.P2, b.P1)
		end
		return false
	end

	function Line.Straight.magnitude(line: StraightLine): number
		return line.Offset.Magnitude
	end

	function Line.Straight.intersection(a: StraightLine, b: StraightLine): Vector3?
		local p = a.P1.Position
		local r = a.Offset
		local q = b.P1.Position
		local s = b.Offset

		local rxs = r.X * s.Z - r.Z * s.X
		if math.abs(rxs) < 1e-9 then
			return nil -- parallel or collinear
		end

		local qp = q - p
		local t = (qp.X * s.Z - qp.Z * s.X) / rxs
		local u = (qp.X * r.Z - qp.Z * r.X) / rxs

		if t >= 0 and t <= 1 and u >= 0 and u <= 1 then
			return p + r * t
		end

		return nil
	end

	function Line.Straight.debug(line: StraightLine): { Instance }
		local out: { Instance } = {}
		Util.join(out, Point.Any.debug(line.P1))
		Util.join(out, Point.Any.debug(line.P2))
		if ENV.DEBUG_SHOW_LINES then
			local newLine = Draw.vector(line.P1.Position, line.Offset)
			if ENV.DEBUG_PARTS_LOCKED then
				newLine.Locked = true
			end
			for i, child in newLine:GetDescendants() do
				if child:IsA("BasePart") then
					child.Locked = true
				end
			end
			table.insert(out, newLine)
		end
		return out
	end

	function Line.Straight.pointAtOffset(line: StraightLine, offset: number): Vector3
		return line.P1.Position + line.Offset.Unit * math.clamp(offset, 0, line.Offset.Magnitude)
	end

	function Line.Straight.pointAt(line: StraightLine, t: number): Vector3
		return line.P1.Position + line.Offset * math.clamp(t, 0, 1)
	end
end

export type QuadraticBezierLine = {
	Type: "QuadraticBezier",
	P1: VertexPoint,
	P2: VertexPoint,
	Intersection: BasicPoint,
}
do
	Line.QuadraticBezier = {}

	function Line.QuadraticBezier.new(p1: VertexPoint, p2: VertexPoint, intersection: BasicPoint): QuadraticBezierLine
		local out = {
			Type = "QuadraticBezier" :: "QuadraticBezier",
			P1 = p1,
			P2 = p2,
			Intersection = intersection,
		} :: QuadraticBezierLine
		table.freeze(out)
		return out
	end

	function Line.QuadraticBezier.eq(a: QuadraticBezierLine, b: QuadraticBezierLine): boolean
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

	function Line.QuadraticBezier.magnitude(line: QuadraticBezierLine): number
		return Util.getBezierLength(line.P1.Position, line.Intersection.Position, line.P2.Position, 1)
	end

	function Line.QuadraticBezier.debug(line: QuadraticBezierLine): { Instance }
		local out: { Instance } = {}
		Util.join(out, Point.Any.debug(line.P1))
		Util.join(out, Point.Any.debug(line.Intersection))
		Util.join(out, Point.Any.debug(line.P2))
		return out
	end

	function Line.QuadraticBezier.pointAt(line: QuadraticBezierLine, t: number): Vector3
		local u = 1 - t
		return u * u * line.P1.Position + 2 * u * t * line.Intersection.Position + t * t * line.P2.Position
	end

	function Line.QuadraticBezier.pointAtOffset(line: QuadraticBezierLine, offset: number): Vector3
		local len = Line.QuadraticBezier.magnitude(line)
		return Line.QuadraticBezier.pointAt(line, math.clamp(offset, 0, len) / len)
	end

	function Line.QuadraticBezier.intersection(a: QuadraticBezierLine, other: Line): Vector3?
		warn(`QuadraticBezier does not currently support intersection()`)
		return nil
	end
end

export type Line = StraightLine | QuadraticBezierLine
do
	Line.Any = {}

	function Line.Any.eq(a: Line, b: Line): boolean
		local subModule = Line[a.Type] :: any
		assert(subModule.eq, `missing eq for type "{a.Type}"`)
		return subModule.eq(a, b)
	end

	function Line.Any.magnitude(line: Line): boolean
		local subModule = Line[line.Type] :: any
		assert(subModule.magnitude, `missing magnitude for type "{line.Type}"`)
		return subModule.magnitude(line)
	end

	function Line.Any.debug(line: Line): { Instance }
		local subModule = Line[line.Type] :: any
		assert(subModule.debug, `missing debug for type "{line.Type}"`)
		return subModule.debug(line)
	end

	function Line.Any.pointAt(line: Line, t: number): Vector3
		local subModule = Line[line.Type] :: any
		assert(subModule.pointAt, `missing pointAt for type "{line.Type}"`)
		return subModule.pointAt(line, t)
	end

	function Line.Any.pointAtOffset(line: Line, offset: number): Vector3
		local subModule = Line[line.Type] :: any
		assert(subModule.pointAtOffset, `missing pointAtOffset for type "{line.Type}"`)
		return subModule.pointAtOffset(line, offset)
	end

	function Line.Any.intersection(a: Line, b: Line): Vector3?
		local subModule = Line[a.Type] :: any
		assert(subModule.intersection, `missing pointAtOffset for type "{a.Type}"`)
		return subModule.intersection(a,b)
	end
end

return Line
