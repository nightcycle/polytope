--!strict
-- Services
-- Packages
local Draw = require(script.Parent.Parent.Draw)
-- Modules
local Util = require(script.Parent.Util)
local ENV = require(script.Parent.ENV)
-- Types
-- Constants
local CONSTANTS = require(script.Parent.CONSTANTS)
-- Variables
-- References
-- Private Functions
-- Class
local Point = {}
export type BasicPoint = {
	Type: "Basic",
	Position: Vector3,
}
do
	Point.Basic = {}

	function Point.Basic.new(position: Vector3): BasicPoint
		local out = {
			Type = "Basic" :: "Basic",
			Position = position,
		}
		table.freeze(out)
		return out
	end

	function Point.Basic.eq(a: BasicPoint, b: BasicPoint): boolean
		if a.Type ~= b.Type then
			return false
		end
		return Util.positionEq(a.Position, b.Position)
	end

	function Point.Basic.lerp(a: BasicPoint, b: BasicPoint, alpha: number): BasicPoint
		return Point.Basic.new(a.Position:Lerp(b.Position, alpha))
	end

	function Point.Basic.debug(point: BasicPoint): { Instance }
		local out: { Instance } = {}
		if ENV.DEBUG_SHOW_POINTS then
			local newPoint = Draw.point(point.Position)
			if ENV.DEBUG_PARTS_LOCKED then
				newPoint.Locked = true
			end
			table.insert(out, newPoint)
		end
		return out
	end
end

export type VertexPoint = {
	Type: "Vertex",
	Position: Vector3,
	Normal: Vector3,
}
do
	Point.Vertex = {}

	function Point.Vertex.new(position: Vector3, normal: Vector3): VertexPoint
		local out = {
			Type = "Vertex" :: "Vertex",
			Position = position,
			Normal = normal,
		}
		table.freeze(out)
		return out
	end

	function Point.Vertex.eq(a: VertexPoint, b: VertexPoint): boolean
		if a.Type ~= b.Type then
			return false
		end
		return Util.positionEq(a.Position, b.Position) and a.Normal:FuzzyEq(b.Normal, CONSTANTS.FUZZY_EQ.EPSILON)
	end

	function Point.Vertex.lerp(a: VertexPoint, b: VertexPoint, alpha: number): VertexPoint
		return Point.Vertex.new(a.Position:Lerp(b.Position, alpha), a.Normal:Lerp(b.Normal, alpha).Unit)
	end

	function Point.Vertex.debug(point: VertexPoint): { Instance }
		local out: { Instance } = {}
		if ENV.DEBUG_SHOW_POINTS then
			local newPoint = Draw.point(point.Position)
			if ENV.DEBUG_PARTS_LOCKED then
				newPoint.Locked = true
			end
			table.insert(out, newPoint)
		end
		return out
	end
end

export type RotatedPoint = {
	Type: "Rotated",
	CFrame: CFrame,
	Normal: Vector3,
	Position: Vector3,
	Up: Vector3,
}
do
	Point.Rotated = {}

	function Point.Rotated.new(cf: CFrame): RotatedPoint
		local out = {
			Type = "Rotated" :: "Rotated",
			CFrame = cf,
			Normal = -cf.LookVector,
			Up = cf.UpVector,
			Position = cf.Position,
		}
		table.freeze(out)
		return out
	end

	function Point.Rotated.eq(a: RotatedPoint, b: RotatedPoint): boolean
		if a.Type ~= b.Type then
			return false
		end
		return Util.positionEq(a.Position, b.Position)
			and a.Normal:FuzzyEq(b.Normal, CONSTANTS.FUZZY_EQ.EPSILON)
			and a.Up:FuzzyEq(b.Up, CONSTANTS.FUZZY_EQ.EPSILON)
	end

	function Point.Rotated.lerp(a: RotatedPoint, b: RotatedPoint, alpha: number): RotatedPoint
		return Point.Rotated.new(a.CFrame:Lerp(b.CFrame, alpha))
	end

	function Point.Rotated.debug(point: RotatedPoint): { Instance }
		local out: { Instance } = {}
		if ENV.DEBUG_SHOW_POINTS then
			local newCF = Draw.cframe(CFrame.fromMatrix(point.Position, (-point.Normal):Cross(point.Up), point.Up))
			if ENV.DEBUG_PARTS_LOCKED then
				if newCF:IsA("BasePart") then
					newCF.Locked = true
				end
			end
			table.insert(out, newCF)
		end
		return out
	end
end

export type Point = VertexPoint | RotatedPoint | BasicPoint
do
	Point.Any = {}

	function Point.Any.eq(a: Point, b: Point): boolean
		local subModule = Point[a.Type] :: any
		assert(subModule.eq, `missing eq for type "{a.Type}"`)
		return subModule.eq(a, b)
	end

	function Point.Any.lerp(a: Point, b: Point, alpha: number): Point
		local subModule = Point[a.Type] :: any
		assert(subModule.lerp, `missing lerp for type "{a.Type}"`)
		if a.Type == b.Type then
			return subModule.lerp(a, b, alpha)
		else
			return Point.Basic.new(a.Position:Lerp(b.Position, alpha))
		end
	end

	function Point.Any.debug(point: Point): { Instance }
		local subModule = Point[point.Type] :: any
		assert(subModule.debug, `missing debug for type "{point.Type}"`)
		return subModule.debug(point)
	end
end

return Point
