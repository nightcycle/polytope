--!strict
-- Services
-- Packages
-- Modules
-- Types
-- Constants
local CONSTANTS = require(script.Parent.CONSTANTS)
-- Variables
-- References
-- Private Functions
-- Class
local Util = {}

function Util.clampToPlane(origin: Vector3, normal: Vector3, point: Vector3): Vector3
	--@TODO
	return Vector3.zero
end

function Util.getTriangleArea(a: Vector3, b: Vector3, c: Vector3): number
	local ab = (a - b).Magnitude
	local bc = (b - c).Magnitude
	local ca = (c - a).Magnitude

	local perimeter: number = ab + bc + ca
	local semiPerimeterLength: number = perimeter / 2

	local deltaA: number = (semiPerimeterLength - ab)
	local deltaB: number = (semiPerimeterLength - bc)
	local deltaC: number = (semiPerimeterLength - ca)

	return math.sqrt(semiPerimeterLength * deltaA * deltaB * deltaC)
end

function Util.setTriangle(
	a: Vector3,
	b: Vector3,
	c: Vector3,
	normal: Vector3,
	thickness: number,
	w1: WedgePart,
	w2: WedgePart
): (CFrame, CFrame)
	-- Render the 3D triangle
	local ab, ac, bc = b - a, c - a, c - b
	local abd, acd, bcd = ab:Dot(ab), ac:Dot(ac), bc:Dot(bc)

	if abd > acd and abd > bcd then
		c, a = a, c
	elseif acd > bcd and acd > abd then
		a, b = b, a
	end

	ab, ac, bc = b - a, c - a, c - b

	local right = ac:Cross(ab).Unit
	local up = bc:Cross(right).Unit
	local back = bc.Unit

	local height = math.abs(ab:Dot(up))

	w1.Size = Vector3.new(thickness, height, math.abs(ab:Dot(back)))
	w2.Size = Vector3.new(thickness, height, math.abs(ac:Dot(back)))

	return CFrame.fromMatrix((a + b) / 2, right, up, back) + normal * (-thickness / 2),
		CFrame.fromMatrix((a + c) / 2, -right, up, -back) + normal * (-thickness / 2)
end

function Util.join<V>(bin: { V }, newItems: { V })
	for i, v in newItems do
		table.insert(bin, v)
	end
end
function Util.parent<V>(inst: Instance, children: { Instance })
	for i, v in children do
		v.Parent = inst
	end
end

function Util.positionEq(a: Vector3, b: Vector3): boolean
	return math.abs(a.X - b.X) <= CONSTANTS.FUZZY_EQ.LENGTH
		and math.abs(a.Y - b.Y) <= CONSTANTS.FUZZY_EQ.LENGTH
		and math.abs(a.Z - b.Z) <= CONSTANTS.FUZZY_EQ.LENGTH
end

-- inspired from https://stackoverflow.com/questions/11854907/calculate-the-length-of-a-segment-of-a-quadratic-bezier
function Util.getBezierLength(p0: Vector3, p1: Vector3, p2: Vector3, t: number): number
	local a = p0 - p1 - p1 + p2
	local b = p1 + p1 - p0 - p0

	local A = 4.0 * a:Dot(a)
	local B = 4.0 * a:Dot(b)
	local C = b:Dot(b)

	local bb = B / (2.0 * A)
	local c = C / A
	local u = t + bb
	local k = c - (bb * bb)

	local L = 0.5
		* (A ^ 0.5)
		* (
			(u * (((u * u) + k) ^ 0.5))
			- (bb * (((bb * bb) + k) ^ 0.5))
			+ (k * math.log(math.abs((u + ((u * u) + k) ^ 0.5) / (bb + ((bb * bb) + k) ^ 0.5))))
		)

	return L
end
return Util
