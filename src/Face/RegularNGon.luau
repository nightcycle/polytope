--!strict
-- Services
-- Packages
-- Modules
local Point = require(script.Parent.Parent.Point)
local Line = require(script.Parent.Parent.Line)
local FaceUtil = require(script.Parent.Parent.FaceUtil)
local Triangle = require(script.Parent.Triangle)
local Rectangle = require(script.Parent.Rectangle)
local Util = require(script.Parent.Parent.Util)
-- Types
export type RegularNGonFace = FaceUtil.RegularNGonFace
-- Constants
local CONSTANTS = require(script.Parent.Parent.CONSTANTS)
-- Variables
-- References
-- Private Functions
-- Class
local RegularNGon = {}

function RegularNGon.new(center: CFrame, diameter: number, sideCount: number): RegularNGonFace
	local vertices = {}
	for i = 1, sideCount do
		local angle = math.rad((i - 1) * 360 / sideCount)
		vertices[i] = Point.Vertex.new(
			(center * CFrame.new(math.sin(angle) * diameter / 2, math.cos(angle) * diameter / 2, 0)).Position,
			center.LookVector
		)
	end

	local face = {
		Type = "RegularNGon" :: "RegularNGon",
		Id = Util.cantor3Pair(Util.cantorCFrame(center), sideCount, math.floor(diameter / CONSTANTS.FUZZY_EQ.LENGTH)),
		Triangles = {},
		Center = center,
		Vertices = vertices,
		SideCount = sideCount,
		Diameter = diameter,
	}

	if #vertices > 1 then
		local centerV = Point.Vertex.new(center.Position, center.LookVector)
		for i = 1, #vertices do
			local currentV = vertices[i]
			local nextV = vertices[i + 1] or vertices[1]
			table.insert(face.Triangles, Triangle.new(currentV, nextV, centerV))
		end
	end

	table.freeze(face.Vertices)
	table.freeze(face.Triangles)
	table.freeze(face)
	return face :: RegularNGonFace
end

function RegularNGon.fill(face: RegularNGonFace, thickness: number?): FaceUtil.FillResult
	local cfList: { CFrame } = {}
	local partList: { BasePart } = {}
	for i, tri in face.Triangles do
		local tResult = Triangle.fill(tri, thickness)
		Util.join(cfList, tResult.CFrames)
		Util.join(partList, tResult.Parts)
	end
	return {
		CFrames = cfList,
		Parts = partList,
	}
end

function RegularNGon.normal(face: RegularNGonFace): Vector3 return face.Center.LookVector end

function RegularNGon.up(face: RegularNGonFace): Vector3 return face.Center.UpVector end

function RegularNGon.right(face: RegularNGonFace): Vector3 return face.Center.RightVector end

function RegularNGon.center(face: RegularNGonFace): Vector3 return face.Center.Position end

function RegularNGon.magnitude(face: RegularNGonFace): number
	return 0.5 * face.SideCount * (face.Diameter / 2) ^ 2 * math.sin(2 * math.pi / face.SideCount)
end

function RegularNGon.isWithin(face: RegularNGonFace, point: Vector3): boolean
	for i, tri in face.Triangles do
		if Triangle.isWithin(tri, point) then return true end
	end
	return false
end

function RegularNGon.tile(
	face: RegularNGonFace,
	format: FaceUtil.TileFormat,
	up: Vector3?,
	right: Vector3?
): { FaceUtil.Face }
	local normal = RegularNGon.normal(face)
	local center = RegularNGon.center(face)
	up, right = FaceUtil.fixAdjNormals(normal, up or RegularNGon.up(face), right or RegularNGon.right(face))
	assert(up and right, `bad normals`)
	if format.Type == "Rows" then
		if format.Direction == Enum.FillDirection.Horizontal then
			local newFormat: FaceUtil.TileFormat = table.clone(format)
			assert(newFormat.Type == "Rows", `bad type`)
			newFormat.Direction = Enum.FillDirection.Vertical
			return RegularNGon.tile(face, newFormat, right, up)
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
				if y1 ~= y1 then y1 = 0 end
				local xMax = (i + 1) * actualColumnWidth - halfWidth

				local angle2 = math.acos(xMax / apothem)
				local y2 = math.abs(math.sin(angle2) * apothem)
				if y2 ~= y2 then y2 = 0 end

				local yMin = math.min(y1, y2)

				local rHeight = 2 * yMin
				local rWidth = xMax - xMin

				if rHeight < CONSTANTS.FUZZY_EQ.LENGTH then continue end

				table.insert(
					out,
					Rectangle.new(
						CFrame.fromMatrix(cf.Position + (xMin + rWidth / 2) * right, cf.XVector, cf.YVector, cf.ZVector),
						rHeight,
						rWidth
					)
				)
			end
			return out
		else
			local maxRect = RegularNGon.fit(face, "Rectangle", up, right)
			assert(maxRect.Type == "Rectangle", `bad maxRect`)
			local edges = RegularNGon.edges(face)
			return FaceUtil.tileRowsByStraightEdgeHits(maxRect, format, edges, normal, up, right) :: { FaceUtil.Face }
		end
	elseif format.Type == "Grid" then
		local maxRect = RegularNGon.fit(face, "Rectangle", up, right)
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

		local columns = RegularNGon.tile(face, {
			Type = "Rows",
			Width = {
				Type = "Length" :: "Length",
				Value = columnWidth,
			} :: FaceUtil.TileScale,
			SnapTo = rowWidth,
			Direction = Enum.FillDirection.Vertical,
		}, up, right) :: { FaceUtil.RectangleFace }
		-- if columns then
		-- 	return columns
		-- end
		local rows = RegularNGon.tile(face, {
			Type = "Rows",
			Width = {
				Type = "Length" :: "Length",
				Value = rowWidth,
			} :: FaceUtil.TileScale,
			SnapTo = columnWidth,
			Direction = Enum.FillDirection.Horizontal,
		}, up, right) :: { FaceUtil.RectangleFace }

		local cf = CFrame.lookAlong(center, normal, up)
		local out = {}

		for i, solution in FaceUtil.gridFromRowsAndColumns(cf, columns, rows) do
			table.insert(out, Rectangle.new(solution.CFrame, solution.Height, solution.Width))
		end

		return out
	else
		error(`unsupported format: "{format.Type}"`)
	end
end

function RegularNGon.fit(
	face: RegularNGonFace,
	containmentType: FaceUtil.ContainmentType,
	up: Vector3?,
	right: Vector3?
): FaceUtil.Face
	local normal = RegularNGon.normal(face)
	local center = RegularNGon.center(face)
	up, right = FaceUtil.fixAdjNormals(normal, up or RegularNGon.up(face), right or RegularNGon.right(face))
	assert(up and right, `bad normals`)
	if containmentType == "Rectangle" then
		local cf = CFrame.fromMatrix(center, right, up)
		if face.SideCount > CONSTANTS.NGON_IS_CIRCLE_AFTER then
			return Rectangle.new(cf, face.Diameter, face.Diameter)
		else
			local rectCF, width, height = FaceUtil.getMaxRect(cf, RegularNGon.vertices(face) :: { Point.Point })
			return Rectangle.new(rectCF, height, width)
		end
	else
		error(`unsupported containment type: "{containmentType}"`)
	end
end

function RegularNGon.vertices(face: RegularNGonFace): { Point.VertexPoint } return table.clone(face.Vertices) end

function RegularNGon.edges(face: RegularNGonFace): { Line.StraightLine }
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

function RegularNGon.hash(face: RegularNGonFace): string return `FRN{face.Id}` end

return RegularNGon
