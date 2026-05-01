--!strict
-- Services
-- Packages
local TableUtil = require(script.Parent.Parent.Parent.TableUtil)
-- Modules
local Point = require(script.Parent.Parent.Point)
local Line = require(script.Parent.Parent.Line)
local Triangle = require(script.Parent.Triangle)
local Rectangle = require(script.Parent.Rectangle)
local FaceUtil = require(script.Parent.Parent.FaceUtil)
local Util = require(script.Parent.Parent.Util)
-- Types
export type QuadFace = FaceUtil.QuadFace
-- Constants
local CONSTANTS = require(script.Parent.Parent.CONSTANTS)
-- Variables
-- References
-- Private Functions
-- Class
local Quad = {}

function Quad.new(q1: Point.VertexPoint, q2: Point.BasicPoint, q3: Point.VertexPoint, q4: Point.BasicPoint): QuadFace
	local face = {
		Type = "Quad" :: "Quad",
		T1 = Triangle.new(q1, Point.Vertex.new(q2.Position, q1.Normal), Point.Vertex.new(q4.Position, q1.Normal)),
		T2 = Triangle.new(q3, Point.Vertex.new(q4.Position, q3.Normal), Point.Vertex.new(q2.Position, q3.Normal)),
		Flat = false,
	}
	face.Flat = Triangle.normal(face.T1):FuzzyEq(Triangle.normal(face.T2), CONSTANTS.FUZZY_EQ.EPSILON)
	table.freeze(face)
	return face :: QuadFace
end

function Quad.normal(face: QuadFace): Vector3 return (Triangle.normal(face.T1) + Triangle.normal(face.T2)) / 2 end

function Quad.up(face: QuadFace): Vector3 return FaceUtil.upFromNormal(Quad.normal(face)) end

function Quad.right(face: QuadFace): Vector3 return FaceUtil.rightFromNormal(Quad.normal(face)) end

function Quad.center(face: QuadFace): Vector3 return face.T1.P2.Position:Lerp(face.T2.P2.Position, 0.5) end

function Quad.fill(face: QuadFace, thickness: number?): FaceUtil.FillResult
	local t1Result = Triangle.fill(face.T1, thickness)
	local t2Result = Triangle.fill(face.T2, thickness)
	local cfs = table.create(#t1Result.Parts * 2) :: { CFrame }
	Util.join(cfs, t1Result.CFrames)
	Util.join(cfs, t2Result.CFrames)

	local parts = table.create(#t1Result.Parts * 2) :: { BasePart }
	Util.join(parts, t1Result.Parts)
	Util.join(parts, t2Result.Parts)
	return {
		CFrames = cfs,
		Parts = parts,
	}
end

function Quad.eq(a: QuadFace, b: QuadFace): boolean
	if a.Type ~= b.Type then return false end
	if Triangle.eq(a.T1, b.T1) then
		if Triangle.eq(a.T2, b.T2) then return true end
	elseif Triangle.eq(a.T1, b.T2) then
		if Triangle.eq(a.T2, b.T1) then return true end
	end
	return false
end

function Quad.magnitude(face: QuadFace): number return Triangle.magnitude(face.T1) + Triangle.magnitude(face.T2) end

function Quad.isWithin(face: QuadFace, point: Vector3): boolean
	return Triangle.isWithin(face.T1, point) or Triangle.isWithin(face.T2, point)
end

function Quad.fit(
	face: QuadFace,
	containmentType: FaceUtil.ContainmentType,
	up: Vector3?,
	right: Vector3?
): FaceUtil.Face
	local normal = Quad.normal(face)
	up, right = FaceUtil.fixAdjNormals(normal, up or Quad.up(face), right or Quad.right(face))
	assert(up and right, `bad normals`)
	local center = Quad.center(face)
	if containmentType == "Rectangle" then
		local rectCF, width, height =
			FaceUtil.getMaxRect(CFrame.fromMatrix(center, right, up), Quad.vertices(face) :: { Point.Point })
		return Rectangle.new(rectCF, height, width)
	else
		error(`unsupported containmentType: "{containmentType}"`)
	end
end

function Quad.tile(face: QuadFace, format: FaceUtil.TileFormat, up: Vector3?, right: Vector3?): { FaceUtil.Face }
	local normal = Quad.normal(face)
	up, right = FaceUtil.fixAdjNormals(normal, up or Quad.up(face), right or Quad.right(face))
	assert(up and right, `bad normals`)

	local out: { FaceUtil.Face } = {}
	if format.Type == "Rows" then
		if format.Direction == Enum.FillDirection.Horizontal then
			local newFormat: FaceUtil.TileFormat = table.clone(format)
			assert(newFormat.Type == "Rows", `bad type`)
			newFormat.Direction = Enum.FillDirection.Vertical
			return Quad.tile(face, newFormat, right, up)
		end
		if not face.Flat then
			local t1Format = format
			local t2Format = format

			if format.Width.Type == "Count" then
				local t1Size = Triangle.magnitude(face.T1)
				local t2Size = Triangle.magnitude(face.T2)
				local totalSize = t1Size + t2Size
				local t1Count = math.round(format.Width.Value * t1Size / totalSize)
				local t2Count = math.max(0, format.Width.Value - t1Count)
				t1Format = TableUtil.deepCopy(t1Format :: any) :: typeof(format)
				assert(t1Format.Width.Type == "Count", `bad width`)
				t1Format.Width.Value = t1Count + 1

				t2Format = TableUtil.deepCopy(t2Format :: any) :: typeof(format)
				assert(t2Format.Width.Type == "Count", `bad width`)
				t2Format.Width.Value = t2Count + 1
			end

			Util.join(out, Triangle.tile(face.T1, t1Format, up, right))
			Util.join(out, Triangle.tile(face.T2, t2Format, up, right))
		else
			local edges = Quad.edges(face)
			local maxRect = Quad.fit(face, "Rectangle", up, right)
			assert(maxRect.Type == "Rectangle", `bad maxRect`)
			return FaceUtil.tileRowsByStraightEdgeHits(maxRect, format, edges, normal, up, right) :: { FaceUtil.Face }
		end
	elseif format.Type == "Grid" then
		if not face.Flat then
			local t1Format = format
			local t2Format = format

			if format.Width.Type == "Count" then
				local t1Size = Triangle.magnitude(face.T1)
				local t2Size = Triangle.magnitude(face.T2)
				local totalSize = t1Size + t2Size
				local t1Count = math.round(format.Width.Value * t1Size / totalSize)
				local t2Count = math.max(0, format.Width.Value - t1Count)
				t1Format = TableUtil.deepCopy(t1Format :: any) :: typeof(format)
				assert(t1Format.Width.Type == "Count", `bad width`)
				t1Format.Width.Value = t1Count + 1

				t2Format = TableUtil.deepCopy(t2Format :: any) :: typeof(format)
				assert(t2Format.Width.Type == "Count", `bad width`)
				t2Format.Width.Value = t2Count + 1
			end
			if format.Height.Type == "Count" then
				local t1Size = Triangle.magnitude(face.T1)
				local t2Size = Triangle.magnitude(face.T2)
				local totalSize = t1Size + t2Size
				local t1Count = math.round(format.Height.Value * t1Size / totalSize)
				local t2Count = math.max(0, format.Height.Value - t1Count)
				t1Format = TableUtil.deepCopy(t1Format :: any) :: typeof(format)
				assert(t1Format.Height.Type == "Count", `bad width`)
				t1Format.Height.Value = t1Count + 1

				t2Format = TableUtil.deepCopy(t2Format :: any) :: typeof(format)
				assert(t2Format.Height.Type == "Count", `bad width`)
				t2Format.Height.Value = t2Count + 1
			end

			Util.join(out, Triangle.tile(face.T1, t1Format, up, right))
			Util.join(out, Triangle.tile(face.T2, t2Format, up, right))
		else
			local maxRect = Quad.fit(face, "Rectangle", up, right)
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

			local columns = Quad.tile(face, {
				Type = "Rows",
				Width = {
					Type = "Length" :: "Length",
					Value = columnWidth,
				} :: FaceUtil.TileScale,
				SnapTo = rowWidth,
				Direction = Enum.FillDirection.Vertical,
			}, up, right) :: { FaceUtil.RectangleFace }
			local rows = Quad.tile(face, {
				Type = "Rows",
				Width = {
					Type = "Length" :: "Length",
					Value = rowWidth,
				} :: FaceUtil.TileScale,
				SnapTo = columnWidth,
				Direction = Enum.FillDirection.Horizontal,
			}, up, right) :: { FaceUtil.RectangleFace }

			local center = maxRect.Center.Position
			local cf = CFrame.lookAlong(center, normal, up)

			for i, solution in FaceUtil.gridFromRowsAndColumns(cf, columns, rows) do
				table.insert(out, Rectangle.new(solution.CFrame, solution.Height, solution.Width))
			end
		end
	else
		error(`unsupported format: "{format.Type}"`)
	end

	return out
end

function Quad.vertices(face: QuadFace): { Point.VertexPoint }
	return {
		face.T1.P1,
		face.T1.P2,
		face.T2.P1,
		face.T2.P2,
	}
end

function Quad.getId(face: QuadFace): number
	return Util.cantorPairUnordered(
		Util.cantorPair(Point.Vertex.getId(face.T1.P1), Point.Vertex.getId(face.T1.P2)),
		Util.cantorPair(Point.Vertex.getId(face.T2.P1), Point.Vertex.getId(face.T2.P2))
	)
end

function Quad.hash(face: QuadFace): string return `FQ{Quad.getId(face)}` end

function Quad.edges(face: QuadFace): { Line.StraightLine }
	local points = Quad.vertices(face)
	return {
		Line.Straight.new(points[1], points[2]),
		Line.Straight.new(points[2], points[3]),
		Line.Straight.new(points[3], points[4]),
		Line.Straight.new(points[4], points[1]),
	}
end

return Quad
