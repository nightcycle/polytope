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

function Util.getInstance(className: string): Instance
	return Instance.new(className)
end

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

function Util.fillTriangle(
	a: Vector3,
	b: Vector3,
	c: Vector3,
	normal: Vector3,
	thickness: number
): (WedgePart, CFrame, WedgePart, CFrame)
	local w1 = Util.getInstance("WedgePart") :: WedgePart
	local w2 = Util.getInstance("WedgePart") :: WedgePart

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

	return w1,
		CFrame.fromMatrix((a + b) / 2, right, up, back) + normal * (-thickness / 2),
		w2,
		CFrame.fromMatrix((a + c) / 2, -right, up, -back) + normal * (-thickness / 2)
end

function Util.positionEq(a: Vector3, b: Vector3): boolean
	return math.abs(a.X - b.X) <= CONSTANTS.FUZZY_EQ.LENGTH
		and math.abs(a.Y - b.Y) <= CONSTANTS.FUZZY_EQ.LENGTH
		and math.abs(a.Z - b.Z) <= CONSTANTS.FUZZY_EQ.LENGTH
end

return Util
