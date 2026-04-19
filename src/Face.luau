--!strict
-- Services
-- Packages
local Draw = require(game.ReplicatedStorage.Packages.Draw)
-- Modules
local Line = require(script.Parent.Line)
local Point = require(script.Parent.Point)
local Util = require(script.Parent.Util)
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

-- Class
local Face = {}

export type RectangleFace = {
	Type: "Rectangle",
	Center: RotatedPoint,
	Height: number,
	Width: number,
}
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

	function Face.Rectangle.fitIn(face: RectangleFace, count: number, up: Vector3?, right: Vector3?): { RectangleFace }
		local normal = Face.Rectangle.normal(face)
		up = upFromNormal(normal, right)
		right = rightFromNormal(normal)

		return {}
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

	function Face.Rectangle.edges(face: RectangleFace): { Line }
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
			local a, aCF, b, bCF = Util.fillTriangle(
				face.P1.Position,
				face.P2.Position,
				face.P3.Position,
				Face.Triangle.normal(face),
				fill.Thickness or CONSTANTS.MIN_THICKNESS
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

	function Face.Triangle.fitWithin(face: TriangleFace, up: Vector3?, right: Vector3?): RectangleFace
		local normal = Face.Triangle.normal(face)
		local center = Face.Triangle.center(face)
		up = upFromNormal(normal, right)
		assert(up, `bad up`)
		right = rightFromNormal(normal)
		assert(right, `bad right`)
		local cf = CFrame.fromMatrix(center, right, up)

		local offset1 = cf:PointToObjectSpace(face.P1.Position)
		local offset2 = cf:PointToObjectSpace(face.P2.Position)
		local offset3 = cf:PointToObjectSpace(face.P3.Position)

		local width = 2 * math.max(math.abs(offset1.X), math.abs(offset2.X), math.abs(offset3.X))
		local height = 2 * math.max(math.abs(offset1.Y), math.abs(offset2.Y), math.abs(offset3.Y))

		return Face.Rectangle.new(Point.Rotated.new(cf), height, width)
	end

	function Face.Triangle.fitIn(face: TriangleFace, count: number, up: Vector3?, right: Vector3?): { RectangleFace }
		local normal = Face.Triangle.normal(face)
		-- local center = Face.Triangle.center(face)
		up = upFromNormal(normal, right)
		assert(up, `bad up`)
		right = rightFromNormal(normal)
		assert(right, `bad right`)

		local outer = Face.Triangle.fitWithin(face, up, right)
		-- https://www.sunshine2k.de/coding/java/TriangleRasterization/TriangleRasterization.html
		return {
			outer
		}
	end

	function Face.Triangle.edges(face: TriangleFace): { Line }
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

export type ConcaveNGonFace = {
	Type: "ConcaveNGon",
	Center: VertexPoint,
	Triangles: { TriangleFace },
	Vertices: { VertexPoint },
}
do
	Face.ConcaveNGon = {}

	function Face.ConcaveNGon.new(vertices: { VertexPoint }): ConcaveNGonFace
		local center: VertexPoint
		do
			local normal: Vector3
			do
				local sum = Vector3.zero
				local count = 0
				for i, v in vertices do
					sum += v.Normal
					count += 1
				end
				normal = sum / math.max(count, 1)
			end
			local position: Vector3
			do
				local sum = Vector3.zero
				local count = 0
				for i, v in vertices do
					sum += v.Position
					count += 1
				end
				position = sum / math.max(count, 1)
			end
			center = Point.Vertex.new(position, normal)
		end
		local face = {
			Type = "ConcaveNGon" :: "ConcaveNGon",
			Triangles = {},
			Center = center,
			Vertices = table.clone(vertices),
		}

		if #vertices > 1 then
			for i = 1, #vertices do
				local firstV = center
				local currentV = vertices[i]
				local nextV = vertices[i + 1] or vertices[1]
				table.insert(face.Triangles, Face.Triangle.new(currentV, nextV, firstV))
			end
		end

		table.freeze(face.Vertices)
		table.freeze(face.Triangles)
		table.freeze(face)
		return face
	end

	function Face.ConcaveNGon.fill(face: ConcaveNGonFace, fill: FillInfo, rng: Random?): FillResult
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

	function Face.ConcaveNGon.eq(a: ConcaveNGonFace, b: ConcaveNGonFace): boolean
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

	function Face.ConcaveNGon.normal(face: ConcaveNGonFace): Vector3
		local sum = Vector3.zero
		local count = 0
		for i, v in face.Triangles do
			sum += Face.Triangle.normal(v)
			count += 1
		end
		return sum / math.max(count, 1)
	end

	function Face.ConcaveNGon.up(face: ConcaveNGonFace): Vector3
		return upFromNormal(Face.ConcaveNGon.normal(face))
	end

	function Face.ConcaveNGon.right(face: ConcaveNGonFace): Vector3
		return rightFromNormal(Face.ConcaveNGon.normal(face))
	end

	function Face.ConcaveNGon.center(face: ConcaveNGonFace): Vector3
		local sum = Vector3.zero
		local count = 0
		for i, v in face.Vertices do
			sum += v.Position
			count += 1
		end
		return sum / math.max(count, 1)
	end

	function Face.ConcaveNGon.magnitude(face: ConcaveNGonFace): number
		local out = 0
		for i, tri in face.Triangles do
			out += Face.Triangle.magnitude(tri)
		end
		return out
	end

	function Face.ConcaveNGon.isWithin(face: ConcaveNGonFace, point: Vector3): boolean
		for i, tri in face.Triangles do
			if Face.Triangle.isWithin(tri, point) then
				return true
			end
		end
		return false
	end

	function Face.ConcaveNGon.fitIn(
		face: ConcaveNGonFace,
		count: number,
		up: Vector3?,
		right: Vector3?
	): { RectangleFace }
		local normal = Face.ConcaveNGon.normal(face)
		up = upFromNormal(normal, right)
		right = rightFromNormal(normal)

		return {}
	end

	function Face.ConcaveNGon.vertices(face: ConcaveNGonFace): { VertexPoint }
		return table.clone(face.Vertices)
	end

	function Face.ConcaveNGon.edges(face: ConcaveNGonFace): { Line }
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
		}
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

	function Face.Quad.fitIn(face: QuadFace, count: number, up: Vector3?, right: Vector3?): { RectangleFace }
		local normal = Face.Quad.normal(face)
		up = upFromNormal(normal, right)
		right = rightFromNormal(normal)

		return {}
	end

	function Face.Quad.vertices(face: QuadFace): { VertexPoint }
		return {
			face.T1.P1,
			face.T1.P2,
			face.T2.P1,
			face.T2.P2,
		}
	end

	function Face.Quad.edges(face: QuadFace): { Line }
		local points = Face.Quad.vertices(face)
		return {
			Line.Straight.new(points[1], points[2]),
			Line.Straight.new(points[2], points[3]),
			Line.Straight.new(points[3], points[4]),
			Line.Straight.new(points[4], points[1]),
		}
	end
end

export type Face = TriangleFace | ConcaveNGonFace | RectangleFace | QuadFace
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

	function Face.Any.fitIn(face: Face): { RectangleFace }
		local subModule = Face[face.Type] :: any
		assert(subModule.fitIn, `missing fitIn for type "{face.Type}"`)
		return subModule.fitIn(face)
	end

	function Face.Any.magnitude(face: Face): number
		local subModule = Face[face.Type] :: any
		assert(subModule.magnitude, `missing magnitude for type "{face.Type}"`)
		return subModule.magnitude(face)
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
			local isLocked = ENV.DEBUG_PARTS_LOCKED
			if isLocked then
				for i, inst in out do
					Util.lock(inst)
				end
			end
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
				Util.lock(part)
				table.insert(parts, part)
				table.insert(cfs, cf)
			end
			workspace:BulkMoveTo(parts, cfs, Enum.BulkMoveMode.FireCFrameChanged)
		end

		return out
	end
end

return Face
