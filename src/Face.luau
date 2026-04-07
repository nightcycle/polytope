--!strict
-- Services
-- Packages
-- Modules
local Line = require(script.Parent.Line)
local Point = require(script.Parent.Point)
local Util = require(script.Parent.Util)
-- Types
export type Line = Line.Line
export type Point = Point.Point
export type VertexPoint = Point.VertexPoint
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
	Normal: Vector3,
	Up: Vector3,
}
do
	Face.Triangle = {}

	function Face.Triangle.new(
		p1: VertexPoint,
		p2: VertexPoint,
		p3: VertexPoint,
		normal: Vector3,
		up: Vector3
	): TriangleFace
		local face = {
			Type = "Triangle" :: "Triangle",
			P1 = p1,
			P2 = p2,
			P3 = p3,
			Normal = normal,
			Up = up,
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
				face.Normal,
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

	function Face.Triangle.eq(a: TriangleFace, b: TriangleFace): boolean
		if a.Type ~= b.Type then
			return false
		end
		if not a.Normal:FuzzyEq(b.Normal, CONSTANTS.FUZZY_EQ.EPSILON) then
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
end

export type Face = TriangleFace
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

	function Face.Any.getSharedEdges(a: Face, b: Face): { Line }
		if a.Type == b.Type and Face[a.Type].getSharedEdges then
			return Face[a.Type].getSharedEdges(a, b)
		end
		local aEdges = Face.Any.getEdges(a)
		local bEdges = Face.Any.getEdges(b)
		local out: { Line } = {}
		for i, aEdge in aEdges do
			local isShared = false
			for j, bEdge in bEdges do
				if Line.Any.eq(aEdge, bEdge) then
					isShared = true
					break
				end
			end
			if isShared then
				table.insert(out, aEdge)
			end
		end
		return out
	end
end

return Face
