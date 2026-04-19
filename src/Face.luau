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
		Type: "Splatter",
		Count: number,
		Decoration: DecorationInfo,
		Constructor: DecorationConstructor,
	}
	| {
		Type: "Stripes",
		Count: number,
		PerLine: number,
		Decoration: DecorationInfo,
		Constructor: DecorationConstructor,
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
-- Class
local Face = {}

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
		-- elseif fill.Type == "Splatter" then
		else
			error(`unsupported type: "{fill.Type}"`)
		end
	end

	function Face.Triangle.normal(face: TriangleFace): Vector3
		return (face.P1.Normal + face.P2.Normal + face.P3.Normal) / 3
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

	function Face.Triangle.getEdges(face: TriangleFace): { Line }
		return {
			Line.Straight.new(face.P1, face.P2),
			Line.Straight.new(face.P2, face.P3),
			Line.Straight.new(face.P3, face.P1),
		}
	end

	function Face.Triangle.getPoints(face: TriangleFace): { Point }
		return {
			face.P1,
			face.P2,
			face.P3,
		}
	end
end

export type ConcaveNGonFace = {
	Type: "ConcaveNGon",
	Triangles: { TriangleFace },
	Vertices: { VertexPoint },
}
do
	Face.ConcaveNGon = {}

	function Face.ConcaveNGon.new(vertices: { VertexPoint }): ConcaveNGonFace
		local face = {
			Type = "ConcaveNGon" :: "ConcaveNGon",
			Triangles = {},
			Vertices = table.clone(vertices),
		}
		for i = 2, #vertices - 1 do
			local firstV = vertices[1]
			local currentV = vertices[i]
			local nextV = vertices[i + 1]
			table.insert(face.Triangles, Face.Triangle.new(currentV, nextV, firstV))
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

	function Face.ConcaveNGon.getPoints(face: ConcaveNGonFace): { VertexPoint }
		return table.clone(face.Vertices)
	end

	function Face.ConcaveNGon.getEdges(face: ConcaveNGonFace): { Line }
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

	function Face.Quad.getPoints(face: QuadFace): { VertexPoint }
		return {
			face.T1.P1,
			face.T1.P2,
			face.T2.P1,
			face.T2.P2,
		}
	end

	function Face.Quad.getEdges(face: QuadFace): { Line }
		local points = Face.Quad.getPoints(face)
		return {
			Line.Straight.new(points[1], points[2]),
			Line.Straight.new(points[2], points[3]),
			Line.Straight.new(points[3], points[4]),
			Line.Straight.new(points[4], points[1]),
		}
	end
end

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
		return face.Center.Normal
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

	function Face.Rectangle.getPoints(face: RectangleFace): { RotatedPoint }
		local widthVec = (face.Center.Up:Cross(-face.Center.Normal)) * face.Width
		local heightVec = face.Center.Up * face.Height
		local origin = face.Center.Position - widthVec / 2 - heightVec / 2
		return {
			Point.Rotated.new(origin, face.Center.Normal, face.Center.Up),
			Point.Rotated.new(origin + widthVec, face.Center.Normal, face.Center.Up),
			Point.Rotated.new(origin + widthVec + heightVec, face.Center.Normal, face.Center.Up),
			Point.Rotated.new(origin + heightVec, face.Center.Normal, face.Center.Up),
		}
	end

	function Face.Rectangle.getEdges(face: RectangleFace): { Line }
		local points = Face.Rectangle.getPoints(face)
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

	function Face.Any.getEdges(face: Face): { Line }
		local subModule = Face[face.Type] :: any
		assert(subModule.getEdges, `missing getEdges for type "{face.Type}"`)
		return subModule.getEdges(face)
	end

	function Face.Any.getPoints(face: Face): { Point }
		local subModule = Face[face.Type] :: any
		assert(subModule.getPoints, `missing getPoints for type "{face.Type}"`)
		return subModule.getPoints(face)
	end

	function Face.Any.getSharedEdges(a: Face, b: Face): { Line }
		if a.Type == b.Type and Face[a.Type].getSharedEdges then
			return Face[a.Type].getSharedEdges(a, b)
		end
		local aEdges = Face.Any.getEdges(a)
		local bEdges = Face.Any.getEdges(b)
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
	function Face.Any.getSharedPoints(
		a: Face,
		b: Face,
		includeNormals: boolean?
	): { [BasicPoint]: {
		A: Point,
		B: Point,
	} }
		if a.Type == b.Type and Face[a.Type].getSharedPoints then
			return Face[a.Type].getSharedPoints(a, b, includeNormals)
		end
		local aPoints = Face.Any.getPoints(a)
		local bPoints = Face.Any.getPoints(b)
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

		for i, edge in Face.Any.getEdges(face) do
			Util.join(out, Line.Any.debug(edge))
		end

		if ENV.DEBUG_SHOW_NORMALS then
			-- local normal = Face.Any.normal(face)
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
			local isLocked = ENV.DEBUG_PARTS_LOCKED
			for part, cf in result.Parts do
				if isLocked then
					part.Locked = true
				end
				table.insert(parts, part)
				table.insert(cfs, cf)
			end
			workspace:BulkMoveTo(parts, cfs, Enum.BulkMoveMode.FireCFrameChanged)
		end

		return out
	end
end

return Face
