--!strict
-- Services
-- Packages
local Draw = require(script.Parent.Parent.Draw)
local TableUtil = require(script.Parent.Parent.TableUtil)

-- Modules
local Line = require(script.Parent.Line)
local Point = require(script.Parent.Point)
local Util = require(script.Parent.Util)
local InstanceCache = require(script.Parent.InstanceCache)
local ENV = require(script.Parent.ENV)
-- Types
export type Line = Line.Line
export type Point = Point.Point
export type BasicPoint = Point.BasicPoint
export type VertexPoint = Point.VertexPoint
export type RotatedPoint = Point.RotatedPoint
export type DecorationConstructor = (origin: CFrame, scale: number) -> FillResult
export type DecorationInfo = {
	Scale: NumberRange?,
	Rotation: NumberRange?,
	Wobble: NumberRange?,
	Translation: NumberRange?,
}

export type TileFormat = {
	Type: "Rows",
	Width: {
		Type: "Count",
		Value: number,
		RetryOnceIfNotExact: boolean?,
	} | {
		Type: "Length",
		Value: number,
	},
	Direction: Enum.FillDirection?,
}

export type ContainmentType = "Rectangle"
export type FillInfo =
	{
		Type: "Surface",
		Thickness: number?,
	}
	| {
		Type: "Stripes",
		Count: number,
		PerLine: number,
		Decoration: DecorationInfo,
		Constructor: DecorationConstructor,
		Direction: Enum.FillDirection,
	}

export type FillResult = {
	Instances: { Instance },
	Parts: { [BasePart]: CFrame },
}

-- Constants
local CONSTANTS = require(script.Parent.CONSTANTS)
-- Variables
-- References
-- Private Functions
function rightFromNormal(normal: Vector3): Vector3
	if math.abs(Vector3.yAxis:Dot(normal)) == 1 then
		return Vector3.zAxis:Cross(-normal).Unit
	end
	return Vector3.yAxis:Cross(-normal).Unit
end
function upFromNormal(normal: Vector3, right: Vector3?): Vector3
	right = right or rightFromNormal(normal)
	assert(right, `bad right`)
	local up = right:Cross(-normal)
	if up:Dot(Vector3.yAxis) >= 0 then
		return up.Unit
	else
		return -up.Unit
	end
end
function fixAdjNormals(normal: Vector3, up: Vector3?, right: Vector3?): (Vector3, Vector3)
	up = up or upFromNormal(normal, right)
	assert(up, `bad up`)
	right = right or rightFromNormal(normal)
	assert(right, `bad right`)
	up = right:Cross(-normal).Unit
	right = up:Cross(-normal).Unit
	return up, right
end

function getMaxRect(origin: CFrame, points: { Point.Point }): (CFrame, number, number)
	local minX = math.huge
	local maxX = 0
	local minY = 0
	local maxY = 0

	for i, point in points do
		local offset = origin:PointToObjectSpace(point.Position)
		minX = math.min(offset.X, minX)
		maxX = math.max(offset.X, maxX)
		minY = math.min(offset.Y, minY)
		maxY = math.max(offset.Y, maxY)
	end

	local width = maxX - minX
	local height = maxY - minY

	return origin * CFrame.new(minX + width / 2, minY + height / 2, 0), width, height
end

-- Class
local Face = {}

export type RectangleFace = {
	Type: "Rectangle",
	Center: RotatedPoint,
	Height: number,
	Width: number,
}

function tileRowsByStraightEdgeHits(
	maxRect: RectangleFace,
	format: TileFormat,
	edges: { Line.StraightLine },
	center: Vector3,
	normal: Vector3,
	up: Vector3,
	right: Vector3
)
	local columnWidth: number
	assert(maxRect.Type == "Rectangle", `bad maxRect`)
	if format.Width.Type == "Count" then
		if format.Width.Value <= 0 then
			return {} -- done :D
		end
		columnWidth = maxRect.Width / (format.Width.Value + 2)
	elseif format.Width.Type == "Length" then
		columnWidth = format.Width.Value
	else
		error(`unsupported type: "{format.Width.Type}"`)
	end
	local halfHeight = maxRect.Height / 2
	local cf = CFrame.lookAlong(center, normal, up)

	local function getHits(pos: Vector3, offset: Vector3): { Vector3 }
		local line = Line.Straight.new(Point.Vertex.new(pos, normal), Point.Vertex.new(pos + offset, normal))
		local hits: { Vector3 } = {}
		for i, edge in edges do
			local intersection = Line.Straight.intersection(line, edge)
			if intersection then
				table.insert(hits, intersection)
			end
		end
		return hits
	end

	local function solveSlice(offsetX: number): NumberRange?
		local lineHits = getHits(center + right * offsetX - up * halfHeight, up * maxRect.Height)
		if #lineHits ~= 2 then
			if #lineHits < 2 then
				return nil
			end
			local uniquePoints: {Vector3} = {}
			for i, hit in lineHits do
				local allUnique = true
				for j, v in uniquePoints do
					if (hit-v).Magnitude < CONSTANTS.FUZZY_EQ.LENGTH then
						allUnique = false
						break
					end
				end
				if allUnique then
					table.insert(uniquePoints, hit)
				end
			end
			if #uniquePoints == 2 then
				lineHits = uniquePoints
			end
		end
		local offsetY1 = cf:PointToObjectSpace(lineHits[1]).Y
		local offsetY2 = cf:PointToObjectSpace(lineHits[2]).Y
		return NumberRange.new(math.min(offsetY1, offsetY2), math.max(offsetY1, offsetY2))
	end

	local out = {}
	do
		local count = math.floor(maxRect.Width / columnWidth)
		local actualColumnWidth = maxRect.Width / count
		local halfWidth = maxRect.Width / 2
		for i = 0, count - 1 do
			local xMin = i * actualColumnWidth - halfWidth
			local yRange1 = solveSlice(xMin) -- or NumberRange.new(-halfHeight,halfHeight)
			if not yRange1 then
				continue
			end
			local xMax = (i + 1) * actualColumnWidth - halfWidth
			local yRange2 = solveSlice(xMax) --aor NumberRange.new(-halfHeight,halfHeight)
			if not yRange2 then
				continue
			end
			if yRange1.Max < yRange2.Min or yRange1.Min > yRange2.Max then
				continue
			end
			local yMin = math.max(yRange1.Min, yRange2.Min)
			local yMax = math.min(yRange1.Max, yRange2.Max)

			local rHeight = yMax - yMin
			if rHeight < CONSTANTS.FUZZY_EQ.LENGTH then
				continue
			end
			local rWidth = xMax - xMin
			if rWidth < CONSTANTS.FUZZY_EQ.LENGTH then
				continue
			end

			table.insert(
				out,
				Face.Rectangle.new(
					Point.Rotated.new(
						CFrame.fromMatrix(
							cf.Position + (xMin + rWidth / 2) * right + (yMin + rHeight / 2) * up,
							cf.XVector,
							cf.YVector,
							cf.ZVector
						)
					),
					rHeight,
					rWidth
				)
			)
		end
	end

	if format.Width.Type == "Count" and format.Width.Value ~= #out and format.Width.RetryOnceIfNotExact == true then
		local newFormat = TableUtil.deepCopy(format) :: typeof(format)
		local newWidth = newFormat.Width :: typeof(format.Width)
		newWidth.RetryOnceIfNotExact = false
		local dif = math.abs(format.Width.Value - #out)
		if format.Width.Value < #out then
			newWidth.Value -= dif
			return tileRowsByStraightEdgeHits(maxRect, newFormat, edges, center, normal, up, right)
		else
			newWidth.Value += dif
			newWidth.Value = math.max(newWidth.Value, 1)
			return tileRowsByStraightEdgeHits(maxRect, newFormat, edges, center, normal, up, right)
		end
	end

	return out
end
do
	Face.Rectangle = {}

	function Face.Rectangle.new(center: RotatedPoint, height: number, width: number): RectangleFace
		local face = {
			Type = "Rectangle" :: "Rectangle",
			Center = center,
			Height = height,
			Width = width,
		}
		table.freeze(face)
		return face
	end

	function Face.Rectangle.normal(face: RectangleFace): Vector3
		return -face.Center.CFrame.LookVector
	end

	function Face.Rectangle.up(face: RectangleFace): Vector3
		return face.Center.CFrame.UpVector
	end

	function Face.Rectangle.right(face: RectangleFace): Vector3
		return face.Center.CFrame.RightVector
	end

	function Face.Rectangle.center(face: RectangleFace): Vector3
		return face.Center.Position
	end

	function Face.Rectangle.fit(
		face: RectangleFace,
		containmentType: ContainmentType,
		up: Vector3?,
		right: Vector3?
	): Face
		local normal = Face.Rectangle.normal(face)
		local center = Face.Rectangle.center(face)
		up, right = fixAdjNormals(normal, up, right)
		assert(up and right, `bad normals`)
		if containmentType == "Rectangle" then
			local rectCF, width, height =
				getMaxRect(CFrame.fromMatrix(center, right, up), Face.Rectangle.vertices(face))
			return Face.Rectangle.new(Point.Rotated.new(rectCF), height, width)
		else
			error(`unsupported containment type: "{containmentType}"`)
		end
	end

	function Face.Rectangle.tile(face: RectangleFace, format: TileFormat, up: Vector3?, right: Vector3?): { Face }
		local normal = Face.Rectangle.normal(face)
		up, right = fixAdjNormals(normal, up, right)
		assert(up and right, `bad normals`)

		if format.Type == "Rows" then
			local edges = Face.Rectangle.edges(face)
			local center = Face.Rectangle.center(face)
			local maxRect = Face.Rectangle.fit(face, "Rectangle", up, right)
			assert(maxRect.Type == "Rectangle", `bad maxRect`)
			return tileRowsByStraightEdgeHits(maxRect, format, edges, center, normal, up, right)
		else
			error(`unsupported format: "{format.Type}"`)
		end
	end

	function Face.Rectangle.fill(face: RectangleFace, fill: FillInfo, rng: Random?): FillResult
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

	function Face.Rectangle.eq(a: RectangleFace, b: RectangleFace): boolean
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

	function Face.Rectangle.magnitude(face: RectangleFace): number
		return face.Width * face.Height
	end

	function Face.Rectangle.isWithin(face: RectangleFace, point: Vector3): boolean
		local offset = point - face.Center.Position
		local projUp = math.abs(offset:Dot(face.Center.Up))
		local projRight = math.abs(offset:Dot(face.Center.Up:Cross(-face.Center.Normal)))
		local projNormal = math.abs(offset:Dot(face.Center.Normal))
		return projUp <= face.Height / 2 + CONSTANTS.FUZZY_EQ.LENGTH
			and projRight <= face.Width / 2 + CONSTANTS.FUZZY_EQ.LENGTH
			and projNormal < CONSTANTS.FUZZY_EQ.LENGTH
	end

	function Face.Rectangle.vertices(face: RectangleFace): { RotatedPoint }
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

	function Face.Rectangle.edges(face: RectangleFace): { Line.StraightLine }
		local points = Face.Rectangle.vertices(face)
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
end

export type TriangleFace = {
	Type: "Triangle",
	P1: VertexPoint,
	P2: VertexPoint,
	P3: VertexPoint,
}
do
	Face.Triangle = {}

	function Face.Triangle.new(p1: VertexPoint, p2: VertexPoint, p3: VertexPoint): TriangleFace
		local face = {
			Type = "Triangle" :: "Triangle",
			P1 = p1,
			P2 = p2,
			P3 = p3,
		}
		table.freeze(face)
		return face
	end

	function Face.Triangle.fill(face: TriangleFace, fill: FillInfo, rng: Random?): FillResult
		if fill.Type == "Surface" then
			local a = InstanceCache.Class.WedgePart:allocate()
			local b = InstanceCache.Class.WedgePart:allocate()
			local aCF, bCF = Util.setTriangle(
				face.P1.Position,
				face.P2.Position,
				face.P3.Position,
				Face.Triangle.normal(face),
				fill.Thickness or CONSTANTS.MIN_THICKNESS,
				a,
				b
			)
			return {
				Instances = { a, b },
				Parts = {
					[a] = aCF,
					[b] = bCF,
				},
			}
		else
			error(`unsupported type: "{fill.Type}"`)
		end
	end

	function Face.Triangle.normal(face: TriangleFace): Vector3
		local avg = (face.P1.Normal + face.P2.Normal + face.P3.Normal) / 3
		local fromPos = (face.P2.Position - face.P1.Position):Cross(face.P3.Position - face.P1.Position).Unit
		if fromPos:Dot(avg) > 0 then
			return fromPos
		else
			return -fromPos
		end
	end

	function Face.Triangle.up(face: TriangleFace): Vector3
		return upFromNormal(Face.Triangle.normal(face))
	end

	function Face.Triangle.right(face: TriangleFace): Vector3
		return rightFromNormal(Face.Triangle.normal(face))
	end

	function Face.Triangle.center(face: TriangleFace): Vector3
		return (face.P1.Position + face.P2.Position + face.P3.Position) / 3
	end

	function Face.Triangle.eq(a: TriangleFace, b: TriangleFace): boolean
		if a.Type ~= b.Type then
			return false
		end
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

	function Face.Triangle.magnitude(face: TriangleFace): number
		return Util.getTriangleArea(face.P1.Position, face.P2.Position, face.P3.Position)
	end

	function Face.Triangle.isWithin(face: TriangleFace, point: Vector3): boolean
		local abc = Util.getTriangleArea(face.P1.Position, face.P2.Position, face.P3.Position)
		local pbc = Util.getTriangleArea(point, face.P2.Position, face.P3.Position)
		local abp = Util.getTriangleArea(face.P1.Position, face.P2.Position, point)
		local apc = Util.getTriangleArea(face.P1.Position, point, face.P3.Position)

		return math.abs(abc - (pbc + abp + apc)) < CONSTANTS.FUZZY_EQ.AREA
	end

	function Face.Triangle.fit(
		face: TriangleFace,
		containmentType: ContainmentType,
		up: Vector3?,
		right: Vector3?
	): Face
		local normal = Face.Triangle.normal(face)
		local center = Face.Triangle.center(face)
		up, right = fixAdjNormals(normal, up, right)
		assert(up and right, `bad normals`)
		if containmentType == "Rectangle" then
			local rectCF, width, height = getMaxRect(CFrame.fromMatrix(center, right, up), Face.Triangle.vertices(face))
			return Face.Rectangle.new(Point.Rotated.new(rectCF), height, width)
		else
			error(`unsupported containment type: "{containmentType}"`)
		end
	end

	function Face.Triangle.tile(face: TriangleFace, format: TileFormat, up: Vector3?, right: Vector3?): { Face }
		local normal = Face.Triangle.normal(face)
		local center = Face.Triangle.center(face)
		up, right = fixAdjNormals(normal, up, right)
		assert(up and right, `bad normals`)
		if format.Type == "Rows" then
			if format.Direction == Enum.FillDirection.Horizontal then
				local newFormat: TileFormat = table.clone(format)
				newFormat.Direction = Enum.FillDirection.Vertical
				return Face.Triangle.tile(face, newFormat, up, -(right:Cross(up)))
			end
			local maxRect = Face.Triangle.fit(face, "Rectangle", up, right)
			assert(maxRect.Type == "Rectangle", `bad maxRect`)
			local edges = Face.Triangle.edges(face)
			return tileRowsByStraightEdgeHits(maxRect, format, edges, center, normal, up, right)
		else
			error(`unsupported format: "{format.Type}"`)
		end
	end

	function Face.Triangle.edges(face: TriangleFace): { Line.StraightLine }
		return {
			Line.Straight.new(face.P1, face.P2),
			Line.Straight.new(face.P2, face.P3),
			Line.Straight.new(face.P3, face.P1),
		}
	end

	function Face.Triangle.vertices(face: TriangleFace): { VertexPoint }
		return {
			face.P1,
			face.P2,
			face.P3,
		}
	end
end

export type RegularNGonFace = {
	Type: "RegularNGon",
	Center: RotatedPoint,
	Diameter: number,
	SideCount: number,
	Triangles: { TriangleFace },
	Vertices: { VertexPoint },
}
do
	Face.RegularNGon = {}

	function Face.RegularNGon.new(center: RotatedPoint, diameter: number, sideCount: number): RegularNGonFace
		local vertices = {}
		for i = 1, sideCount do
			local angle = math.rad((i - 1) * 360 / sideCount)
			vertices[i] = Point.Vertex.new(
				(center.CFrame * CFrame.new(math.sin(angle) * diameter / 2, math.cos(angle) * diameter / 2, 0)).Position,
				center.Normal
			)
		end

		local face = {
			Type = "RegularNGon" :: "RegularNGon",
			Triangles = {},
			Center = center,
			Vertices = vertices,
			SideCount = sideCount,
			Diameter = diameter,
		}

		if #vertices > 1 then
			local centerV = Point.Vertex.new(center.Position, center.Normal)
			for i = 1, #vertices do
				local currentV = vertices[i]
				local nextV = vertices[i + 1] or vertices[1]
				table.insert(face.Triangles, Face.Triangle.new(currentV, nextV, centerV))
			end
		end

		table.freeze(face.Vertices)
		table.freeze(face.Triangles)
		table.freeze(face)
		return face
	end

	function Face.RegularNGon.fill(face: RegularNGonFace, fill: FillInfo, rng: Random?): FillResult
		if fill.Type == "Surface" then
			local instList = {}
			local map = {}
			for i, tri in face.Triangles do
				local tResult = Face.Triangle.fill(tri, fill, rng)
				for i, inst in tResult.Instances do
					table.insert(instList, inst)
				end
				for part, cf in tResult.Parts do
					map[part] = cf
				end
			end
			return {
				Instances = instList,
				Parts = map,
			}
		else
			error(`unsupported type: "{fill.Type}"`)
		end
	end

	function Face.RegularNGon.eq(a: RegularNGonFace, b: RegularNGonFace): boolean
		if a.Type ~= b.Type then
			return false
		end
		if #a.Triangles ~= #b.Triangles then
			return false
		end
		for i = 1, #a.Triangles do
			local aTri = a.Triangles[i]
			local bTri = b.Triangles[i]
			if not Face.Triangle.eq(aTri, bTri) then
				return false
			end
		end
		return true
	end

	function Face.RegularNGon.normal(face: RegularNGonFace): Vector3
		return face.Center.Normal
	end

	function Face.RegularNGon.up(face: RegularNGonFace): Vector3
		return upFromNormal(Face.RegularNGon.normal(face))
	end

	function Face.RegularNGon.right(face: RegularNGonFace): Vector3
		return rightFromNormal(Face.RegularNGon.normal(face))
	end

	function Face.RegularNGon.center(face: RegularNGonFace): Vector3
		return face.Center.Position
	end

	function Face.RegularNGon.magnitude(face: RegularNGonFace): number
		return 0.5 * face.SideCount * (face.Diameter / 2) ^ 2 * math.sin(2 * math.pi / face.SideCount)
	end

	function Face.RegularNGon.isWithin(face: RegularNGonFace, point: Vector3): boolean
		for i, tri in face.Triangles do
			if Face.Triangle.isWithin(tri, point) then
				return true
			end
		end
		return false
	end

	function Face.RegularNGon.tile(face: RegularNGonFace, format: TileFormat, up: Vector3?, right: Vector3?): { Face }
		local normal = Face.RegularNGon.normal(face)
		local center = Face.RegularNGon.center(face)
		up, right = fixAdjNormals(normal, up, right)
		assert(up and right, `bad normals`)
		if format.Type == "Rows" then
			if format.Direction == Enum.FillDirection.Horizontal then
				local newFormat: TileFormat = table.clone(format)
				newFormat.Direction = Enum.FillDirection.Vertical
				return Face.RegularNGon.tile(face, newFormat, up, -(right:Cross(up)))
			end
			if face.SideCount > CONSTANTS.NGON_IS_CIRCLE_AFTER then
				local out = {}
				local apothem = (face.Diameter / 2) * math.cos(math.pi / face.SideCount)
				local doubleApothem = apothem * 2
				local columnWidth: number
				if format.Width.Type == "Count" then
					if format.Width.Value <= 0 then
						return {} -- done :D
					end
					columnWidth = doubleApothem / (format.Width.Value + 2)
				elseif format.Width.Type == "Length" then
					columnWidth = format.Width.Value
				else
					error(`unsupported type: "{format.Width.Type}"`)
				end
				local count = math.floor(doubleApothem / columnWidth)
				local cf = CFrame.lookAlong(center, normal, up)

				local actualColumnWidth = doubleApothem / count
				local halfWidth = apothem
				for i = 0, count - 1 do
					local xMin = i * actualColumnWidth - halfWidth
					local angle1 = math.acos(xMin / apothem)
					local y1 = math.abs(math.sin(angle1) * apothem)
					if y1 ~= y1 then
						y1 = 0
					end
					local xMax = (i + 1) * actualColumnWidth - halfWidth

					local angle2 = math.acos(xMax / apothem)
					local y2 = math.abs(math.sin(angle2) * apothem)
					if y2 ~= y2 then
						y2 = 0
					end

					local yMin = math.min(y1, y2)

					local rHeight = 2 * yMin
					local rWidth = xMax - xMin

					if rHeight < CONSTANTS.FUZZY_EQ.LENGTH then
						continue
					end

					table.insert(
						out,
						Face.Rectangle.new(
							Point.Rotated.new(
								CFrame.fromMatrix(
									cf.Position + (xMin + rWidth / 2) * right,
									cf.XVector,
									cf.YVector,
									cf.ZVector
								)
							),
							rHeight,
							rWidth
						)
					)
				end
				return out
			else
				local maxRect = Face.RegularNGon.fit(face, "Rectangle", up, right)
				assert(maxRect.Type == "Rectangle", `bad maxRect`)
				local edges = Face.RegularNGon.edges(face)
				return tileRowsByStraightEdgeHits(maxRect, format, edges, center, normal, up, right)
			end
		else
			error(`unsupported format: "{format.Type}"`)
		end
	end

	function Face.RegularNGon.fit(
		face: RegularNGonFace,
		containmentType: ContainmentType,
		up: Vector3?,
		right: Vector3?
	): Face
		local normal = Face.RegularNGon.normal(face)
		local center = Face.RegularNGon.center(face)
		up, right = fixAdjNormals(normal, up, right)
		assert(up and right, `bad normals`)
		if containmentType == "Rectangle" then
			local cf = CFrame.fromMatrix(center, right, up)
			if face.SideCount > CONSTANTS.NGON_IS_CIRCLE_AFTER then
				return Face.Rectangle.new(Point.Rotated.new(cf), face.Diameter, face.Diameter)
			else
				local rectCF, width, height = getMaxRect(cf, Face.RegularNGon.vertices(face))
				return Face.Rectangle.new(Point.Rotated.new(rectCF), height, width)
			end
		else
			error(`unsupported containment type: "{containmentType}"`)
		end
	end

	function Face.RegularNGon.vertices(face: RegularNGonFace): { VertexPoint }
		return table.clone(face.Vertices)
	end

	function Face.RegularNGon.edges(face: RegularNGonFace): { Line.StraightLine }
		local priorI = #face.Vertices
		local out = {}
		for i = 1, #face.Vertices do
			local priorVert = face.Vertices[priorI]
			local nextVert = face.Vertices[i]
			priorI = i
			table.insert(out, Line.Straight.new(priorVert, nextVert))
		end
		return out
	end
end

export type QuadFace = {
	Type: "Quad",
	T1: TriangleFace,
	T2: TriangleFace,
	Flat: boolean,
}
do
	Face.Quad = {}

	function Face.Quad.new(q1: VertexPoint, q2: BasicPoint, q3: VertexPoint, q4: BasicPoint): QuadFace
		local face = {
			Type = "Quad" :: "Quad",
			T1 = Face.Triangle.new(
				q1,
				Point.Vertex.new(q2.Position, q1.Normal),
				Point.Vertex.new(q4.Position, q1.Normal)
			),
			T2 = Face.Triangle.new(
				q3,
				Point.Vertex.new(q4.Position, q3.Normal),
				Point.Vertex.new(q2.Position, q3.Normal)
			),
			Flat = false,
		}
		face.Flat = Face.Triangle.normal(face.T1):FuzzyEq(Face.Triangle.normal(face.T2), CONSTANTS.FUZZY_EQ.EPSILON)
		table.freeze(face)
		return face
	end

	function Face.Quad.normal(face: QuadFace): Vector3
		return (Face.Triangle.normal(face.T1) + Face.Triangle.normal(face.T2)) / 2
	end

	function Face.Quad.up(face: QuadFace): Vector3
		return upFromNormal(Face.Quad.normal(face))
	end

	function Face.Quad.right(face: QuadFace): Vector3
		return rightFromNormal(Face.Quad.normal(face))
	end

	function Face.Quad.center(face: QuadFace): Vector3
		return face.T1.P2.Position:Lerp(face.T2.P2.Position, 0.5)
	end

	function Face.Quad.fill(face: QuadFace, fill: FillInfo, rng: Random?): FillResult
		if fill.Type == "Surface" then
			local t1Result = Face.Triangle.fill(face.T1, fill, rng)
			local t2Result = Face.Triangle.fill(face.T2, fill, rng)
			local instList = {}
			for i, inst in t1Result.Instances do
				table.insert(instList, inst)
			end
			for i, inst in t2Result.Instances do
				table.insert(instList, inst)
			end
			local map = {}
			for part, cf in t1Result.Parts do
				map[part] = cf
			end
			for part, cf in t2Result.Parts do
				map[part] = cf
			end
			return {
				Instances = instList,
				Parts = map,
			}
		else
			error(`unsupported type: "{fill.Type}"`)
		end
	end

	function Face.Quad.eq(a: QuadFace, b: QuadFace): boolean
		if a.Type ~= b.Type then
			return false
		end
		if Face.Triangle.eq(a.T1, b.T1) then
			if Face.Triangle.eq(a.T2, b.T2) then
				return true
			end
		elseif Face.Triangle.eq(a.T1, b.T2) then
			if Face.Triangle.eq(a.T2, b.T1) then
				return true
			end
		end
		return false
	end

	function Face.Quad.magnitude(face: QuadFace): number
		return Face.Triangle.magnitude(face.T1) + Face.Triangle.magnitude(face.T2)
	end

	function Face.Quad.isWithin(face: QuadFace, point: Vector3): boolean
		return Face.Triangle.isWithin(face.T1, point) or Face.Triangle.isWithin(face.T2, point)
	end

	function Face.Quad.fit(face: QuadFace, containmentType: ContainmentType, up: Vector3?, right: Vector3?): Face
		local normal = Face.Quad.normal(face)
		up, right = fixAdjNormals(normal, up, right)
		assert(up and right, `bad normals`)
		local center = Face.Quad.center(face)
		if containmentType == "Rectangle" then
			local rectCF, width, height = getMaxRect(CFrame.fromMatrix(center, right, up), Face.Quad.vertices(face))
			return Face.Rectangle.new(Point.Rotated.new(rectCF), height, width)
		else
			error(`unsupported containmentType: "{containmentType}"`)
		end
	end

	function Face.Quad.tile(face: QuadFace, format: TileFormat, up: Vector3?, right: Vector3?): { Face }
		local normal = Face.Quad.normal(face)
		up, right = fixAdjNormals(normal, up, right)
		assert(up and right, `bad normals`)

		local out: { Face } = {}
		if format.Type == "Rows" then
			if not face.Flat then
				local t1Format = format
				local t2Format = format

				if format.Width.Type == "Count" then
					local t1Size = Face.Triangle.magnitude(face.T1)
					local t2Size = Face.Triangle.magnitude(face.T2)
					local totalSize = t1Size + t2Size
					local t1Count = math.round(format.Width.Value * t1Size / totalSize)
					local t2Count = math.max(0, format.Width.Value - t1Count)
					t1Format = TableUtil.deepCopy(t1Format) :: typeof(format)
					assert(t1Format.Width.Type == "Count", `bad width`)
					t1Format.Width.Value = t1Count + 1

					t2Format = TableUtil.deepCopy(t2Format) :: typeof(format)
					assert(t2Format.Width.Type == "Count", `bad width`)
					t2Format.Width.Value = t2Count + 1
				end

				Util.join(out, Face.Triangle.tile(face.T1, t1Format, up, right))
				Util.join(out, Face.Triangle.tile(face.T2, t2Format, up, right))
			else
				local edges = Face.Quad.edges(face)
				local center = Face.Quad.center(face)
				local maxRect = Face.Quad.fit(face, "Rectangle", up, right)
				assert(maxRect.Type == "Rectangle", `bad maxRect`)
				return tileRowsByStraightEdgeHits(maxRect, format, edges, center, normal, up, right)
			end
		else
			error(`unsupported format: "{format.Type}"`)
		end

		return out
	end

	function Face.Quad.vertices(face: QuadFace): { VertexPoint }
		return {
			face.T1.P1,
			face.T1.P2,
			face.T2.P1,
			face.T2.P2,
		}
	end

	function Face.Quad.edges(face: QuadFace): { Line.StraightLine }
		local points = Face.Quad.vertices(face)
		return {
			Line.Straight.new(points[1], points[2]),
			Line.Straight.new(points[2], points[3]),
			Line.Straight.new(points[3], points[4]),
			Line.Straight.new(points[4], points[1]),
		}
	end
end

export type Face = TriangleFace | RegularNGonFace | RectangleFace | QuadFace
do
	Face.Any = {}

	function Face.Any.fill(face: Face, fill: FillInfo, rng: Random?): FillResult
		local subModule = Face[face.Type] :: any
		assert(subModule.fill, `missing fill for type "{face.Type}"`)
		return subModule.fill(face, fill, rng)
	end

	function Face.Any.eq(a: Face, b: Face): boolean
		local subModule = Face[a.Type] :: any
		assert(subModule.eq, `missing eq for type "{a.Type}"`)
		return subModule.eq(a, b)
	end

	function Face.Any.normal(face: Face): Vector3
		local subModule = Face[face.Type] :: any
		assert(subModule.normal, `missing normal for type "{face.Type}"`)
		return subModule.normal(face)
	end

	function Face.Any.up(face: Face): Vector3
		local subModule = Face[face.Type] :: any
		assert(subModule.up, `missing up for type "{face.Type}"`)
		return subModule.up(face)
	end

	function Face.Any.right(face: Face): Vector3
		local subModule = Face[face.Type] :: any
		assert(subModule.right, `missing right for type "{face.Type}"`)
		return subModule.right(face)
	end

	function Face.Any.center(face: Face): Vector3
		local subModule = Face[face.Type] :: any
		assert(subModule.center, `missing center for type "{face.Type}"`)
		return subModule.center(face)
	end

	function Face.Any.fit(face: Face, containmentType: ContainmentType, up: Vector3?, right: Vector3?): Face
		local subModule = Face[face.Type] :: any
		assert(subModule.fit, `missing fit for type "{face.Type}"`)
		return subModule.fit(face, containmentType, up, right)
	end

	function Face.Any.magnitude(face: Face): number
		local subModule = Face[face.Type] :: any
		assert(subModule.magnitude, `missing magnitude for type "{face.Type}"`)
		return subModule.magnitude(face)
	end

	function Face.Any.tile(face: Face, format: TileFormat, up: Vector3?, right: Vector3?): { Face }
		local subModule = Face[face.Type] :: any
		assert(subModule.tile, `missing tile for type "{face.Type}"`)
		return subModule.tile(face, format, up, right)
	end

	function Face.Any.isWithin(face: Face, point: Vector3): boolean
		local subModule = Face[face.Type] :: any
		assert(subModule.isWithin, `missing isWithin for type "{face.Type}"`)
		return subModule.isWithin(face, point)
	end

	function Face.Any.edges(face: Face): { Line }
		local subModule = Face[face.Type] :: any
		assert(subModule.edges, `missing edges for type "{face.Type}"`)
		return subModule.edges(face)
	end

	function Face.Any.vertices(face: Face): { Point }
		local subModule = Face[face.Type] :: any
		assert(subModule.vertices, `missing vertices for type "{face.Type}"`)
		return subModule.vertices(face)
	end

	function Face.Any.sharedEdges(a: Face, b: Face): { Line }
		if a.Type == b.Type and Face[a.Type].sharedEdges then
			return Face[a.Type].sharedEdges(a, b)
		end
		local aEdges = Face.Any.edges(a)
		local bEdges = Face.Any.edges(b)
		local out: { Line } = {}
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
	function Face.Any.sharedVertices(
		a: Face,
		b: Face,
		includeNormals: boolean?
	): { [BasicPoint]: {
		A: Point,
		B: Point,
	} }
		if a.Type == b.Type and Face[a.Type].sharedVertices then
			return Face[a.Type].sharedVertices(a, b, includeNormals)
		end
		local aPoints = Face.Any.vertices(a)
		local bPoints = Face.Any.vertices(b)
		local out: { [BasicPoint]: {
			A: Point,
			B: Point,
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

	function Face.Any.debug(face: Face): { Instance }
		local out: { Instance } = {}

		for i, edge in Face.Any.edges(face) do
			Util.join(out, Line.Any.debug(edge))
		end

		if ENV.DEBUG_SHOW_NORMALS then
			local normal = Face.Any.normal(face)
			local up = Face.Any.up(face)
			local right = Face.Any.right(face)
			local center = Face.Any.center(face)
			table.insert(out, Draw.point(center, Color3.new(1, 1, 0)))
			table.insert(out, Draw.vector(center, normal * 3, Color3.new(1, 1, 0)))
			table.insert(out, Draw.vector(center, -normal * 3, Color3.new(0, 1, 0)))
			table.insert(out, Draw.vector(center, up * 3, Color3.new(0, 0, 1)))
			table.insert(out, Draw.vector(center, right * 3, Color3.new(1, 0, 0)))
		end
		if ENV.DEBUG_SHOW_FACES then
			local result = Face.Any.fill(face, {
				Type = "Surface",
			})
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
end

return Face
