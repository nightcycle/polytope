--!strict
-- Services
-- Packages
local Draw = require(script.Parent.Parent.Parent.Draw)
-- Modules
local Point = require(script.Parent.Parent.Point)
local LineUtil = require(script.Parent.Parent.LineUtil)
local ENV = require(script.Parent.Parent.ENV)
local Util = require(script.Parent.Parent.Util)
-- Types
export type StraightLine = LineUtil.StraightLine
-- Constants
local CONSTANTS = require(script.Parent.Parent.CONSTANTS)
-- Variables
-- References
-- Private Functions
-- Class
local Straight = {}

function Straight.new(p1: Point.VertexPoint, p2: Point.VertexPoint): StraightLine
	local out = {
		Type = "Straight" :: "Straight",
		P1 = p1,
		P2 = p2,
		Offset = p2.Position - p1.Position,
	} :: StraightLine
	table.freeze(out)
	return out :: StraightLine
end

function Straight.eq(a: StraightLine, b: StraightLine): boolean
	if a.Type ~= b.Type then return false end
	if Point.Vertex.eq(a.P1, b.P1) then
		return Point.Vertex.eq(a.P2, b.P2)
	elseif Point.Vertex.eq(a.P1, b.P2) then
		return Point.Vertex.eq(a.P2, b.P1)
	end
	return false
end

function Straight.magnitude(line: StraightLine): number return line.Offset.Magnitude end

function Straight.closestPoints(
	a: StraightLine,
	b: StraightLine
): {
	A: Point.VertexPoint,
	B: Point.VertexPoint,
	Distance: number,
}
	local p = a.P1.Position
	local r = a.Offset
	local q = b.P1.Position
	local s = b.Offset

	local w = p - q

	local a_ = r:Dot(r)
	local b_ = r:Dot(s)
	local c_ = s:Dot(s)
	local d_ = r:Dot(w)
	local e_ = s:Dot(w)

	local denom = a_ * c_ - b_ * b_

	local t: number
	local u: number

	if math.abs(denom) < 1e-12 then
		-- Parallel: project one endpoint onto the other segment
		t = 0
		u = if c_ > 1e-12 then e_ / c_ else 0
	else
		t = (b_ * e_ - c_ * d_) / denom
		u = (a_ * e_ - b_ * d_) / denom
	end

	-- Clamp to segment bounds
	t = math.clamp(t, 0, 1)
	u = math.clamp(u, 0, 1)

	-- Re-clamp: after clamping one parameter, the other's optimal value may shift
	-- Recompute u given clamped t
	local w2 = p + r * t - q
	u = if c_ > 1e-12 then s:Dot(w2) / c_ else u
	u = math.clamp(u, 0, 1)

	-- Recompute t given clamped u
	local w3 = q + s * u - p
	t = if a_ > 1e-12 then r:Dot(w3) / a_ else t
	t = math.clamp(t, 0, 1)

	local pointOnA = p + r * t
	local pointOnB = q + s * u

	local distance = (pointOnA - pointOnB).Magnitude

	return {
		A = Point.Vertex.new(pointOnA, a.P1.Normal:Lerp(a.P2.Normal, t / r.Magnitude).Unit),
		B = Point.Vertex.new(pointOnB, b.P1.Normal:Lerp(b.P2.Normal, u / s.Magnitude).Unit),
		Distance = distance,
	}
end

function Straight.intersection(a: StraightLine, b: StraightLine, epsilon: number?): Vector3?
	local closestPoints = Straight.closestPoints(a, b)
	if closestPoints.Distance > (epsilon or CONSTANTS.FUZZY_EQ.LENGTH) then return nil end
	-- Return the midpoint of the two closest points
	return closestPoints.A.Position:Lerp(closestPoints.B.Position, 0.5)
end

function Straight.debug(line: StraightLine): { Instance }
	local out: { Instance } = {}
	Util.join(out, Point.Any.debug(line.P1))
	Util.join(out, Point.Any.debug(line.P2))
	if ENV.DEBUG_SHOW_LINES then
		local newLine = Draw.vector(line.P1.Position, line.Offset)
		for i, child in newLine:GetDescendants() do
			if child:IsA("BasePart") then child.Locked = true end
		end
		table.insert(out, newLine)
	end
	return out
end

function Straight.pointAtOffset(line: StraightLine, offset: number): Vector3
	return line.P1.Position + line.Offset.Unit * math.clamp(offset, 0, line.Offset.Magnitude)
end

function Straight.pointAt(line: StraightLine, t: number): Vector3
	return line.P1.Position + line.Offset * math.clamp(t, 0, 1)
end

return Straight
