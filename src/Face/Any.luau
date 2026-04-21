--!strict
-- Services
-- Packages
local Draw = require(script.Parent.Parent.Parent.Draw)
-- Modules
local Point = require(script.Parent.Parent.Point)
local Line = require(script.Parent.Parent.Line)
local FaceUtil = require(script.Parent.Parent.FaceUtil)
local Util = require(script.Parent.Parent.Util)
local Quad = require(script.Parent.Quad)
local Rectangle = require(script.Parent.Rectangle)
local RegularNGon = require(script.Parent.RegularNGon)
local Triangle = require(script.Parent.Triangle)
local ENV = require(script.Parent.Parent.ENV)
-- Types
export type Face = FaceUtil.Face
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
local Any = {}

function Any.fill(face: Face, thickness: number?): FaceUtil.FillResult
	if face.Type == "Triangle" then
		return Triangle.fill(face, thickness)
	elseif face.Type == "Quad" then
		return Quad.fill(face, thickness)
	elseif face.Type == "Rectangle" then
		return Rectangle.fill(face, thickness)
	elseif face.Type == "RegularNGon" then
		return RegularNGon.fill(face, thickness)
	else
		error(`bad type: "{face.Type}"`)
	end
end

function Any.eq(a: Face, b: Face): boolean
	if a.Type ~= b.Type then
		return false
	end
	if a.Type == "Triangle" then
		assert(b.Type == "Triangle", `bad b type: "{b.Type}"`)
		return Triangle.eq(a, b)
	elseif a.Type == "Quad" then
		assert(b.Type == "Quad", `bad b type: "{b.Type}"`)
		return Quad.eq(a, b)
	elseif a.Type == "Rectangle" then
		assert(b.Type == "Rectangle", `bad b type: "{b.Type}"`)
		return Rectangle.eq(a, b)
	elseif a.Type == "RegularNGon" then
		assert(b.Type == "RegularNGon", `bad b type: "{b.Type}"`)
		return RegularNGon.eq(a, b)
	else
		error(`bad type: "{a.Type}"`)
	end
end

function Any.normal(face: Face): Vector3
	if face.Type == "Triangle" then
		return Triangle.normal(face)
	elseif face.Type == "Quad" then
		return Quad.normal(face)
	elseif face.Type == "Rectangle" then
		return Rectangle.normal(face)
	elseif face.Type == "RegularNGon" then
		return RegularNGon.normal(face)
	else
		error(`bad type: "{face.Type}"`)
	end
end

function Any.up(face: Face): Vector3
	if face.Type == "Triangle" then
		return Triangle.up(face)
	elseif face.Type == "Quad" then
		return Quad.up(face)
	elseif face.Type == "Rectangle" then
		return Rectangle.up(face)
	elseif face.Type == "RegularNGon" then
		return RegularNGon.up(face)
	else
		error(`bad type: "{face.Type}"`)
	end
end

function Any.right(face: Face): Vector3
	if face.Type == "Triangle" then
		return Triangle.right(face)
	elseif face.Type == "Quad" then
		return Quad.right(face)
	elseif face.Type == "Rectangle" then
		return Rectangle.right(face)
	elseif face.Type == "RegularNGon" then
		return RegularNGon.right(face)
	else
		error(`bad type: "{face.Type}"`)
	end
end

function Any.center(face: Face): Vector3
	if face.Type == "Triangle" then
		return Triangle.center(face)
	elseif face.Type == "Quad" then
		return Quad.center(face)
	elseif face.Type == "Rectangle" then
		return Rectangle.center(face)
	elseif face.Type == "RegularNGon" then
		return RegularNGon.center(face)
	else
		error(`bad type: "{face.Type}"`)
	end
end

function Any.fit(face: Face, containmentType: FaceUtil.ContainmentType, up: Vector3?, right: Vector3?): Face
	if face.Type == "Triangle" then
		return Triangle.fit(face, containmentType, up, right)
	elseif face.Type == "Quad" then
		return Quad.fit(face, containmentType, up, right)
	elseif face.Type == "Rectangle" then
		return Rectangle.fit(face, containmentType, up, right)
	elseif face.Type == "RegularNGon" then
		return RegularNGon.fit(face, containmentType, up, right)
	else
		error(`bad type: "{face.Type}"`)
	end
end

function Any.magnitude(face: Face): number
	if face.Type == "Triangle" then
		return Triangle.magnitude(face)
	elseif face.Type == "Quad" then
		return Quad.magnitude(face)
	elseif face.Type == "Rectangle" then
		return Rectangle.magnitude(face)
	elseif face.Type == "RegularNGon" then
		return RegularNGon.magnitude(face)
	else
		error(`bad type: "{face.Type}"`)
	end
end

function Any.tile(face: Face, format: FaceUtil.TileFormat, up: Vector3?, right: Vector3?): { Face }
	if face.Type == "Triangle" then
		return Triangle.tile(face, format, up, right)
	elseif face.Type == "Quad" then
		return Quad.tile(face, format, up, right)
	elseif face.Type == "Rectangle" then
		return Rectangle.tile(face, format, up, right)
	elseif face.Type == "RegularNGon" then
		return RegularNGon.tile(face, format, up, right)
	else
		error(`bad type: "{face.Type}"`)
	end
end

function Any.isWithin(face: Face, point: Vector3): boolean
	if face.Type == "Triangle" then
		return Triangle.isWithin(face, point)
	elseif face.Type == "Quad" then
		return Quad.isWithin(face, point)
	elseif face.Type == "Rectangle" then
		return Rectangle.isWithin(face, point)
	elseif face.Type == "RegularNGon" then
		return RegularNGon.isWithin(face, point)
	else
		error(`bad type: "{face.Type}"`)
	end
end

function Any.edges(face: Face): { Line.StraightLine }
	if face.Type == "Triangle" then
		return Triangle.edges(face)
	elseif face.Type == "Quad" then
		return Quad.edges(face)
	elseif face.Type == "Rectangle" then
		return Rectangle.edges(face)
	elseif face.Type == "RegularNGon" then
		return RegularNGon.edges(face)
	else
		error(`bad type: "{face.Type}"`)
	end
end

function Any.vertices(face: Face): { Point.Point }
	if face.Type == "Triangle" then
		return Triangle.vertices(face)
	elseif face.Type == "Quad" then
		return Quad.vertices(face)
	elseif face.Type == "Rectangle" then
		return Rectangle.vertices(face)
	elseif face.Type == "RegularNGon" then
		return RegularNGon.vertices(face)
	else
		error(`bad type: "{face.Type}"`)
	end
end

function Any.sharedEdges(a: Face, b: Face): { Line.StraightLine }
	-- if a.Type == "Triangle" and b.Type == "Triangle" then
	-- 	return Triangle.sharedEdges(a, b)
	-- elseif a.Type == "Quad" and b.Type == "Quad" then
	-- 	return Quad.sharedEdges(a, b)
	-- elseif a.Type == "Rectangle" and b.Type == "Rectangle" then
	-- 	return Rectangle.sharedEdges(a, b)
	-- elseif a.Type == "RegularNGon" and b.Type == "RegularNGon" then
	-- 	return RegularNGon.sharedEdges(a, b)
	-- end
	local aEdges = Any.edges(a)
	local bEdges = Any.edges(b)
	local out: { Line.StraightLine } = {}
	for i, aEdge in aEdges do
		for j, bEdge in bEdges do
			if Line.Any.eq(aEdge, bEdge) then
				table.insert(out, aEdge)
				break
			end
		end
	end
	return out
end

function Any.sharedVertices(
	a: Face,
	b: Face,
	includeNormals: boolean?
): { [Point.BasicPoint]: {
	A: Point.Point,
	B: Point.Point,
} }
	-- if a.Type == "Triangle" and b.Type == "Triangle" then
	-- 	return Triangle.sharedVertices(a, b)
	-- elseif a.Type == "Quad" and b.Type == "Quad" then
	-- 	return Quad.sharedVertices(a, b)
	-- elseif a.Type == "Rectangle" and b.Type == "Rectangle" then
	-- 	return Rectangle.sharedVertices(a, b)
	-- elseif a.Type == "RegularNGon" and b.Type == "RegularNGon" then
	-- 	return RegularNGon.sharedVertices(a, b)
	-- end
	local aPoints = Any.vertices(a)
	local bPoints = Any.vertices(b)
	local out: { [Point.BasicPoint]: {
		A: Point.Point,
		B: Point.Point,
	} } = {}
	for i, aPoint in aPoints do
		for j, bPoint in bPoints do
			if includeNormals then
				if Point.Any.eq(aPoint, bPoint) then
					out[Point.Basic.new(aPoint.Position)] = {
						A = aPoint,
						B = bPoint,
					}
					break
				end
			else
				if Util.positionEq(aPoint.Position, bPoint.Position) then
					out[Point.Basic.new(aPoint.Position)] = {
						A = aPoint,
						B = bPoint,
					}
					break
				end
			end
		end
	end
	return out
end

function Any.debug(face: Face): { Instance }
	local out: { Instance } = {}

	for i, edge in Any.edges(face) do
		Util.join(out, Line.Any.debug(edge))
	end

	if ENV.DEBUG_SHOW_NORMALS then
		local normal = Any.normal(face)
		local up = Any.up(face)
		local right = Any.right(face)
		local center = Any.center(face)
		table.insert(out, Draw.point(center, Color3.new(1, 1, 0)))
		table.insert(out, Draw.vector(center, normal * 3, Color3.new(1, 1, 0)))
		table.insert(out, Draw.vector(center, -normal * 3, Color3.new(0, 1, 0)))
		table.insert(out, Draw.vector(center, up * 3, Color3.new(0, 0, 1)))
		table.insert(out, Draw.vector(center, right * 3, Color3.new(1, 0, 0)))
	end
	if ENV.DEBUG_SHOW_FACES then
		local result = Any.fill(face)
		Util.join(out, result.Instances)
		for i, inst in result.Instances do
			inst.Parent = workspace.CurrentCamera
		end
		local parts = {}
		local cfs = {}
		for part, cf in result.Parts do
			table.insert(parts, part)
			table.insert(cfs, cf)
		end
		workspace:BulkMoveTo(parts, cfs, Enum.BulkMoveMode.FireCFrameChanged)
	end

	return out
end

return Any
