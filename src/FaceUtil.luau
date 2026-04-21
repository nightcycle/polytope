--!strict
-- Services
-- Packages
local TableUtil = require(script.Parent.Parent.TableUtil)
-- Modules
local Point = require(script.Parent.Point)
local Line = require(script.Parent.Line)
-- Types
export type RectangleFace = {
	Type: "Rectangle",
	Center: Point.RotatedPoint,
	Height: number,
	Width: number,
}
export type TriangleFace = {
	Type: "Triangle",
	P1: Point.VertexPoint,
	P2: Point.VertexPoint,
	P3: Point.VertexPoint,
}
export type RegularNGonFace = {
	Type: "RegularNGon",
	Center: Point.RotatedPoint,
	Diameter: number,
	SideCount: number,
	Triangles: { TriangleFace },
	Vertices: { Point.VertexPoint },
}
export type QuadFace = {
	Type: "Quad",
	T1: TriangleFace,
	T2: TriangleFace,
	Flat: boolean,
}

export type Face = RectangleFace | TriangleFace | RegularNGonFace | QuadFace
export type DecorationConstructor = (origin: CFrame, scale: number) -> FillResult
export type DecorationInfo = {
	Scale: NumberRange?,
	Rotation: NumberRange?,
	Wobble: NumberRange?,
	Translation: NumberRange?,
}

export type TileScale =
	{
		Type: "Count",
		Value: number,
		RetryOnceIfNotExact: boolean?,
	}
	| {
		Type: "Length",
		Value: number,
	}
export type TileFormat =
	{
		Type: "Rows",
		Width: TileScale,
		SnapTo: number?,
		Direction: Enum.FillDirection?,
	}
	| {
		Type: "Grid",
		Width: TileScale,
		Height: TileScale,
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

-- Class
local Util = {}
function Util.rightFromNormal(normal: Vector3): Vector3
	if math.abs(Vector3.yAxis:Dot(normal)) == 1 then
		return Vector3.zAxis:Cross(-normal).Unit
	end
	return Vector3.yAxis:Cross(-normal).Unit
end
function Util.upFromNormal(normal: Vector3, right: Vector3?): Vector3
	right = right or Util.rightFromNormal(normal)
	assert(right, `bad right`)
	local up = right:Cross(-normal)
	if up:Dot(Vector3.yAxis) >= 0 then
		return up.Unit
	else
		return -up.Unit
	end
end
function Util.fixAdjNormals(normal: Vector3, up: Vector3?, right: Vector3?): (Vector3, Vector3)
	up = up or Util.upFromNormal(normal, right)
	assert(up, `bad up`)
	right = right or Util.rightFromNormal(normal)
	assert(right, `bad right`)
	up = right:Cross(-normal).Unit
	right = up:Cross(-normal).Unit
	return up, right
end

function Util.getMaxRect(origin: CFrame, points: { Point.Point }): (CFrame, number, number)
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
function Util.solveTileScale(tileScale: TileScale, maxRectDim: number): number
	if tileScale.Type == "Count" then
		if tileScale.Value <= 0 then
			return 0
		end
		return maxRectDim / (tileScale.Value + 2)
	elseif tileScale.Type == "Length" then
		return tileScale.Value
	else
		error(`unsupported type: "{tileScale.Type}"`)
	end
end
function Util.tileRowsByStraightEdgeHits(
	maxRect: RectangleFace,
	format: TileFormat,
	edges: { Line.StraightLine },
	normal: Vector3,
	up: Vector3,
	right: Vector3
): { RectangleFace }
	assert(format.Type == "Rows", `expected "Rows", got "{format.Type}"`)
	local columnWidth = Util.solveTileScale(format.Width, maxRect.Width)
	if columnWidth <= 0 then
		return {} -- done :D
	end
	local halfHeight = maxRect.Height / 2
	local center = maxRect.Center.CFrame.Position
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
			local uniquePoints: { Vector3 } = {}
			for i, hit in lineHits do
				local allUnique = true
				for j, v in uniquePoints do
					if (hit - v).Magnitude < CONSTANTS.FUZZY_EQ.LENGTH then
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
			else
				return nil
			end
		end
		local offsetY1 = cf:PointToObjectSpace(lineHits[1]).Y
		local offsetY2 = cf:PointToObjectSpace(lineHits[2]).Y
		return NumberRange.new(math.min(offsetY1, offsetY2), math.max(offsetY1, offsetY2))
	end

	local out: { RectangleFace } = {}
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
			local yRange2 = solveSlice(xMax) -- or NumberRange.new(-halfHeight,halfHeight)
			if not yRange2 then
				continue
			end
			local yMin1 = yRange1.Min
			local yMin2 = yRange2.Min
			local yMax1 = yRange1.Max
			local yMax2 = yRange2.Max
			if format.SnapTo then
				yMin1 = math.ceil(yMin1 / format.SnapTo) * format.SnapTo
				yMin2 = math.ceil(yMin2 / format.SnapTo) * format.SnapTo
				yMax1 = math.floor(yMax1 / format.SnapTo) * format.SnapTo
				yMax2 = math.floor(yMax2 / format.SnapTo) * format.SnapTo
			end
			if yMax1 < yMin2 or yMin1 > yMax2 then
				continue
			end
			local yMin = math.max(yMin1, yMin2)

			local yMax = math.min(yMax1, yMax2)

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
				table.freeze({
					Type = "Rectangle",
					Center = Point.Rotated.new(
						CFrame.fromMatrix(
							cf.Position + (xMin + rWidth / 2) * right + (yMin + rHeight / 2) * up,
							cf.XVector,
							cf.YVector,
							cf.ZVector
						)
					),
					Height = rHeight,
					Width = rWidth,
				} :: RectangleFace)
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
			return Util.tileRowsByStraightEdgeHits(maxRect, newFormat, edges, normal, up, right)
		else
			newWidth.Value += dif
			newWidth.Value = math.max(newWidth.Value, 1)
			return Util.tileRowsByStraightEdgeHits(maxRect, newFormat, edges, normal, up, right)
		end
	end

	return out
end

function Util.gridFromRowsAndColumns(
	cf: CFrame,
	columns: { RectangleFace },
	rows: { RectangleFace }
): {
	{
		CFrame: CFrame,
		Height: number,
		Width: number,
	}
}
	local out = {}

	for x, column in columns do
		local colOffset = cf:PointToObjectSpace(column.Center.CFrame.Position)

		local colXHalfLength = column.Width / 2
		local colXMin = colOffset.X - colXHalfLength
		local colXMax = colOffset.X + colXHalfLength

		local xOffset = colOffset.X

		local colYHalfWidth = column.Height / 2
		local colYMin = colOffset.Y - colYHalfWidth
		local colYMax = colOffset.Y + colYHalfWidth

		for y, row in rows do
			local rowYOffset = cf:PointToObjectSpace(row.Center.CFrame.Position)

			local yOffset = rowYOffset.Y

			local rowYHalfLength = row.Width / 2
			local rowYMin = rowYOffset.Y - rowYHalfLength
			local rowYMax = rowYOffset.Y + rowYHalfLength

			local rowXHalfWidth = row.Height / 2
			local rowXMin = rowYOffset.X - rowXHalfWidth
			local rowXMax = rowYOffset.X + rowXHalfWidth

			if not (colXMin >= rowXMin and colXMax <= rowXMax) then
				continue
			end

			if not (rowYMin >= colYMin and rowYMax <= colYMax) then
				continue
			end

			table.insert(out, {
				CFrame = cf * CFrame.new(xOffset, yOffset, 0),
				Height = row.Width,
				Width = column.Width,
			})
		end
	end
	return out
end

return Util
