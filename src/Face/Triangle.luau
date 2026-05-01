--!strict
-- Services
-- Packages
-- Modules
local Point = require(script.Parent.Parent.Point)
local Line = require(script.Parent.Parent.Line)
local FaceUtil = require(script.Parent.Parent.FaceUtil)
local InstanceCache = require(script.Parent.Parent.InstanceCache)
local Util = require(script.Parent.Parent.Util)
local Rectangle = require(script.Parent.Rectangle)
-- Types
export type TriangleFace = FaceUtil.TriangleFace
-- Constants
local CONSTANTS = require(script.Parent.Parent.CONSTANTS)
-- Variables
-- References
-- Private Functions
-- Class
local Triangle = {}

function Triangle.new(p1: Point.VertexPoint, p2: Point.VertexPoint, p3: Point.VertexPoint): TriangleFace
	local face = {
		Type = "Triangle" :: "Triangle",
		P1 = p1,
		P2 = p2,
		P3 = p3,
	}
	table.freeze(face)
	return face :: TriangleFace
end

function Triangle.fill(face: TriangleFace, thickness: number?): FaceUtil.FillResult
	local a = InstanceCache.Class.WedgePart:allocate()
	local b = InstanceCache.Class.WedgePart:allocate()
	local aCF, bCF = Util.setTriangle(
		face.P1.Position,
		face.P2.Position,
		face.P3.Position,
		Triangle.normal(face),
		thickness or CONSTANTS.MIN_THICKNESS,
		a,
		b
	)
	return {
		CFrames = { aCF, bCF },
		Parts = {
			a,
			b,
		},
	}
end

function Triangle.normal(face: TriangleFace): Vector3
	local avg = (face.P1.Normal + face.P2.Normal + face.P3.Normal) / 3
	local fromPos = (face.P2.Position - face.P1.Position):Cross(face.P3.Position - face.P1.Position).Unit
	if fromPos:Dot(avg) > 0 then
		return fromPos
	else
		return -fromPos
	end
end

function Triangle.up(face: TriangleFace): Vector3 return FaceUtil.upFromNormal(Triangle.normal(face)) end

function Triangle.right(face: TriangleFace): Vector3 return FaceUtil.rightFromNormal(Triangle.normal(face)) end

function Triangle.center(face: TriangleFace): Vector3
	return (face.P1.Position + face.P2.Position + face.P3.Position) / 3
end

function Triangle.eq(a: TriangleFace, b: TriangleFace): boolean
	if a.Type ~= b.Type then return false end
	if Point.Vertex.eq(a.P1, b.P1) then
		if Point.Vertex.eq(a.P2, b.P2) then
			return Point.Vertex.eq(a.P3, b.P3)
		elseif Point.Vertex.eq(a.P2, b.P3) then
			return Point.Vertex.eq(a.P3, b.P2)
		end
	elseif Point.Vertex.eq(a.P2, b.P1) then
		if Point.Vertex.eq(a.P1, b.P2) then
			return Point.Vertex.eq(a.P3, b.P3)
		elseif Point.Vertex.eq(a.P1, b.P3) then
			return Point.Vertex.eq(a.P3, b.P2)
		end
	elseif Point.Vertex.eq(a.P3, b.P1) then
		if Point.Vertex.eq(a.P2, b.P2) then
			return Point.Vertex.eq(a.P1, b.P3)
		elseif Point.Vertex.eq(a.P2, b.P3) then
			return Point.Vertex.eq(a.P1, b.P2)
		end
	end
	return false
end

function Triangle.magnitude(face: TriangleFace): number
	return Util.getTriangleArea(face.P1.Position, face.P2.Position, face.P3.Position)
end

function Triangle.isWithin(face: TriangleFace, point: Vector3): boolean
	local abc = Util.getTriangleArea(face.P1.Position, face.P2.Position, face.P3.Position)
	local pbc = Util.getTriangleArea(point, face.P2.Position, face.P3.Position)
	local abp = Util.getTriangleArea(face.P1.Position, face.P2.Position, point)
	local apc = Util.getTriangleArea(face.P1.Position, point, face.P3.Position)

	return math.abs(abc - (pbc + abp + apc)) < CONSTANTS.FUZZY_EQ.AREA
end

function Triangle.fit(
	face: TriangleFace,
	containmentType: FaceUtil.ContainmentType,
	up: Vector3?,
	right: Vector3?
): FaceUtil.Face
	local normal = Triangle.normal(face)
	local center = Triangle.center(face)
	up, right = FaceUtil.fixAdjNormals(normal, up or Triangle.up(face), right or Triangle.right(face))
	assert(up and right, `bad normals`)
	if containmentType == "Rectangle" then
		local rectCF, width, height =
			FaceUtil.getMaxRect(CFrame.fromMatrix(center, right, up), Triangle.vertices(face) :: { Point.Point })
		local rectangle: FaceUtil.RectangleFace = {
			Type = "Rectangle",
			Center = Point.Rotated.new(rectCF),
			Height = height,
			Width = width,
		}
		return rectangle
	else
		error(`unsupported containment type: "{containmentType}"`)
	end
end

function Triangle.tile(
	face: TriangleFace,
	format: FaceUtil.TileFormat,
	up: Vector3?,
	right: Vector3?
): { FaceUtil.Face }
	local normal = Triangle.normal(face)
	up, right = FaceUtil.fixAdjNormals(normal, up or Triangle.up(face), right or Triangle.right(face))
	assert(up and right, `bad normals`)
	if format.Type == "Rows" then
		if format.Direction == Enum.FillDirection.Horizontal then
			local newFormat: FaceUtil.TileFormat = table.clone(format)
			assert(newFormat.Type == "Rows", `bad type`)
			newFormat.Direction = Enum.FillDirection.Vertical
			return Triangle.tile(face, newFormat, right, up)
		end
		local maxRect = Triangle.fit(face, "Rectangle", up, right)
		assert(maxRect.Type == "Rectangle", `bad maxRect`)
		local edges = Triangle.edges(face)
		return FaceUtil.tileRowsByStraightEdgeHits(maxRect, format, edges, normal, up, right) :: { FaceUtil.Face }
	elseif format.Type == "Grid" then
		local maxRect = Triangle.fit(face, "Rectangle", up, right)
		assert(maxRect.Type == "Rectangle", `bad maxRect`)

		assert(format.Type == "Grid", `expected "Grid", got "{format.Type}"`)
		local columnWidth = FaceUtil.solveTileScale(format.Width, maxRect.Width)
		if columnWidth <= 0 then
			return {} -- done :D
		end

		local rowWidth = FaceUtil.solveTileScale(format.Height, maxRect.Height)
		if rowWidth <= 0 then
			return {} -- done :D
		end

		local columns = Triangle.tile(face, {
			Type = "Rows",
			Width = {
				Type = "Length" :: "Length",
				Value = columnWidth,
			} :: FaceUtil.TileScale,
			SnapTo = rowWidth,
			Direction = Enum.FillDirection.Vertical,
		}, up, right) :: { FaceUtil.RectangleFace }
		local rows = Triangle.tile(face, {
			Type = "Rows",
			Width = {
				Type = "Length" :: "Length",
				Value = rowWidth,
			} :: FaceUtil.TileScale,
			SnapTo = columnWidth,
			Direction = Enum.FillDirection.Horizontal,
		}, up, right) :: { FaceUtil.RectangleFace }

		local center = maxRect.Center.CFrame.Position
		local cf = CFrame.lookAlong(center, normal, up)
		local out = {}

		for i, solution in FaceUtil.gridFromRowsAndColumns(cf, columns, rows) do
			table.insert(out, Rectangle.new(Point.Rotated.new(solution.CFrame), solution.Height, solution.Width))
		end

		return out
	else
		error(`unsupported format: "{format.Type}"`)
	end
end

function Triangle.edges(face: TriangleFace): { Line.StraightLine }
	return {
		Line.Straight.new(face.P1, face.P2),
		Line.Straight.new(face.P2, face.P3),
		Line.Straight.new(face.P3, face.P1),
	}
end

function Triangle.vertices(face: TriangleFace): { Point.VertexPoint }
	return {
		face.P1,
		face.P2,
		face.P3,
	}
end

return Triangle
