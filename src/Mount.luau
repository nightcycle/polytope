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
local Mount = {}

export type TriangleMount = {
	Type: "Triangle",
	P1: VertexPoint,
	P2: VertexPoint,
	P3: VertexPoint,
	Normal: Vector3,
	Up: Vector3,
}
do
	Mount.Triangle = {}

	function Mount.Triangle.new(
		p1: VertexPoint,
		p2: VertexPoint,
		p3: VertexPoint,
		normal: Vector3,
		up: Vector3
	): TriangleMount
		local mount = {
			Type = "Triangle" :: "Triangle",
			P1 = p1,
			P2 = p2,
			P3 = p3,
			Normal = normal,
			Up = up,
		}
		table.freeze(mount)
		return mount
	end

	function Mount.Triangle.fill(mount: TriangleMount, fill: FillInfo, rng: Random?): FillResult
		if fill.Type == "Surface" then
			local a, aCF, b, bCF = Util.fillTriangle(
				mount.P1.Position,
				mount.P2.Position,
				mount.P3.Position,
				mount.Normal,
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

	function Mount.Triangle.eq(a: TriangleMount, b: TriangleMount): boolean
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

	function Mount.Triangle.magnitude(mount: TriangleMount): number
		return Util.getTriangleArea(mount.P1.Position, mount.P2.Position, mount.P3.Position)
	end

	function Mount.Triangle.isWithin(mount: TriangleMount, point: Vector3): boolean
		local abc = Util.getTriangleArea(mount.P1.Position, mount.P2.Position, mount.P3.Position)
		local pbc = Util.getTriangleArea(point, mount.P2.Position, mount.P3.Position)
		local abp = Util.getTriangleArea(mount.P1.Position, mount.P2.Position, point)
		local apc = Util.getTriangleArea(mount.P1.Position, point, mount.P3.Position)

		return math.abs(abc - (pbc + abp + apc)) < CONSTANTS.FUZZY_EQ.AREA
	end

	function Mount.Triangle.getEdges(mount: TriangleMount): { Line }
		return {
			Line.Straight.new(mount.P1, mount.P2),
			Line.Straight.new(mount.P2, mount.P3),
			Line.Straight.new(mount.P3, mount.P1),
		}
	end
end

export type Mount = TriangleMount
do
	Mount.Any = {}

	function Mount.Any.fill(mount: Mount, fill: FillInfo, rng: Random?): FillResult
		local subModule = Mount[mount.Type] :: any
		assert(subModule.fill, `missing fill for type "{mount.Type}"`)
		return subModule.fill(mount, fill, rng)
	end

	function Mount.Any.eq(a: Mount, b: Mount): boolean
		local subModule = Mount[a.Type] :: any
		assert(subModule.eq, `missing eq for type "{a.Type}"`)
		return subModule.eq(a, b)
	end

	function Mount.Any.magnitude(mount: Mount): number
		local subModule = Mount[mount.Type] :: any
		assert(subModule.magnitude, `missing magnitude for type "{mount.Type}"`)
		return subModule.magnitude(mount)
	end

	function Mount.Any.isWithin(mount: Mount, point: Vector3): boolean
		local subModule = Mount[mount.Type] :: any
		assert(subModule.isWithin, `missing isWithin for type "{mount.Type}"`)
		return subModule.isWithin(mount, point)
	end

	function Mount.Any.getEdges(mount: Mount): { Line }
		local subModule = Mount[mount.Type] :: any
		assert(subModule.getEdges, `missing getEdges for type "{mount.Type}"`)
		return subModule.getEdges(mount)
	end

	function Mount.Any.getSharedEdges(a: Mount, b: Mount): { Line }
		local aEdges = Mount.Any.getEdges(a)
		local bEdges = Mount.Any.getEdges(b)
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

return Mount
