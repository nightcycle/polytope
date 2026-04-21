--!strict
-- Services
-- Packages
-- Modules
local Point = require(script.Parent.Parent.Point)
local Line = require(script.Parent.Parent.Line)
local FaceUtil = require(script.Parent.Parent.FaceUtil)
-- Types
export type RectangleFace = FaceUtil.RectangleFace
-- Constants
local CONSTANTS = require(script.Parent.Parent.CONSTANTS)
-- Variables
-- References
-- Private Functions
-- Class
local Rectangle = {}

function Rectangle.new(center: Point.RotatedPoint, height: number, width: number): RectangleFace
	local face = {
		Type = "Rectangle" :: "Rectangle",
		Center = center,
		Height = height,
		Width = width,
	}
	table.freeze(face)
	return face
end

function Rectangle.normal(face: RectangleFace): Vector3
	return -face.Center.CFrame.LookVector
end

function Rectangle.up(face: RectangleFace): Vector3
	return face.Center.CFrame.UpVector
end

function Rectangle.right(face: RectangleFace): Vector3
	return face.Center.CFrame.RightVector
end

function Rectangle.center(face: RectangleFace): Vector3
	return face.Center.Position
end

function Rectangle.fit(
	face: RectangleFace,
	containmentType: FaceUtil.ContainmentType,
	up: Vector3?,
	right: Vector3?
): FaceUtil.Face
	local normal = Rectangle.normal(face)
	local center = Rectangle.center(face)
	up, right = FaceUtil.fixAdjNormals(normal, up or Rectangle.up(face), right or Rectangle.right(face))
	assert(up and right, `bad normals`)
	if containmentType == "Rectangle" then
		local rectCF, width, height =
			FaceUtil.getMaxRect(CFrame.fromMatrix(center, right, up), Rectangle.vertices(face))
		return Rectangle.new(Point.Rotated.new(rectCF), height, width)
	else
		error(`unsupported containment type: "{containmentType}"`)
	end
end

function Rectangle.tile(
	face: RectangleFace,
	format: FaceUtil.TileFormat,
	up: Vector3?,
	right: Vector3?
): { FaceUtil.Face }
	local normal = Rectangle.normal(face)
	up, right = FaceUtil.fixAdjNormals(normal, up or Rectangle.up(face), right or Rectangle.right(face))
	assert(up and right, `bad normals`)

	if format.Type == "Rows" then
		if format.Direction == Enum.FillDirection.Horizontal then
			local newFormat: FaceUtil.TileFormat = table.clone(format)
			assert(newFormat.Type == "Rows", `bad type`)
			newFormat.Direction = Enum.FillDirection.Vertical
			return Rectangle.tile(face, newFormat, right, up)
		end
		local edges = Rectangle.edges(face)
		local maxRect = Rectangle.fit(face, "Rectangle", up, right)
		assert(maxRect.Type == "Rectangle", `bad maxRect`)
		return FaceUtil.tileRowsByStraightEdgeHits(maxRect, format, edges, normal, up, right)
	elseif format.Type == "Grid" then
		local maxRect = Rectangle.fit(face, "Rectangle", up, right)
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

		local columns = Rectangle.tile(face, {
			Type = "Rows",
			Width = {
				Type = "Length" :: "Length",
				Value = columnWidth,
			} :: FaceUtil.TileScale,
			SnapTo = rowWidth,
			Direction = Enum.FillDirection.Vertical,
		}, up, right) :: { FaceUtil.RectangleFace }
		local rows = Rectangle.tile(face, {
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

function Rectangle.fill(face: RectangleFace, fill: FaceUtil.FillInfo, rng: Random?): FaceUtil.FillResult
	if fill.Type == "Surface" then
		local part = Instance.new("Part")
		part.Size = Vector3.new(face.Width, face.Height, fill.Thickness or CONSTANTS.MIN_THICKNESS)
		return {
			Instances = { part },
			Parts = {
				[part] = CFrame.fromMatrix(
					face.Center.Position - face.Center.Normal * part.Size.Z / 2,
					face.Center.Up:Cross(-face.Center.Normal),
					face.Center.Up
				),
			},
		}
	else
		error(`unsupported type: "{fill.Type}"`)
	end
end

function Rectangle.eq(a: RectangleFace, b: RectangleFace): boolean
	if a.Type ~= b.Type then
		return false
	end
	if not Point.Any.eq(a.Center, b.Center) then
		return false
	end
	if math.abs(a.Height - b.Height) > CONSTANTS.FUZZY_EQ.LENGTH then
		return false
	end
	if math.abs(a.Width - b.Width) > CONSTANTS.FUZZY_EQ.LENGTH then
		return false
	end
	return true
end

function Rectangle.magnitude(face: RectangleFace): number
	return face.Width * face.Height
end

function Rectangle.isWithin(face: RectangleFace, point: Vector3): boolean
	local offset = point - face.Center.Position
	local projUp = math.abs(offset:Dot(face.Center.Up))
	local projRight = math.abs(offset:Dot(face.Center.Up:Cross(-face.Center.Normal)))
	local projNormal = math.abs(offset:Dot(face.Center.Normal))
	return projUp <= face.Height / 2 + CONSTANTS.FUZZY_EQ.LENGTH
		and projRight <= face.Width / 2 + CONSTANTS.FUZZY_EQ.LENGTH
		and projNormal < CONSTANTS.FUZZY_EQ.LENGTH
end

function Rectangle.vertices(face: RectangleFace): { Point.RotatedPoint }
	local widthVec = (face.Center.Up:Cross(-face.Center.Normal)) * face.Width
	local heightVec = face.Center.Up * face.Height
	local origin = face.Center.Position - widthVec / 2 - heightVec / 2
	return {
		Point.Rotated.new(
			CFrame.fromMatrix(
				origin,
				face.Center.CFrame.XVector,
				face.Center.CFrame.YVector,
				face.Center.CFrame.ZVector
			)
		),
		Point.Rotated.new(
			CFrame.fromMatrix(
				origin + widthVec,
				face.Center.CFrame.XVector,
				face.Center.CFrame.YVector,
				face.Center.CFrame.ZVector
			)
		),
		Point.Rotated.new(
			CFrame.fromMatrix(
				origin + widthVec + heightVec,
				face.Center.CFrame.XVector,
				face.Center.CFrame.YVector,
				face.Center.CFrame.ZVector
			)
		),
		Point.Rotated.new(
			CFrame.fromMatrix(
				origin + heightVec,
				face.Center.CFrame.XVector,
				face.Center.CFrame.YVector,
				face.Center.CFrame.ZVector
			)
		),
	}
end

function Rectangle.edges(face: RectangleFace): { Line.StraightLine }
	local points = Rectangle.vertices(face)
	local vert1 = Point.Vertex.new(points[1].Position, points[1].Normal)
	local vert2 = Point.Vertex.new(points[2].Position, points[2].Normal)
	local vert3 = Point.Vertex.new(points[3].Position, points[3].Normal)
	local vert4 = Point.Vertex.new(points[4].Position, points[4].Normal)

	return {
		Line.Straight.new(vert1, vert2),
		Line.Straight.new(vert2, vert3),
		Line.Straight.new(vert3, vert4),
		Line.Straight.new(vert4, vert1),
	}
end

return Rectangle
