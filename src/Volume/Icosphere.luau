--!strict
-- Services
-- Packages
-- Modules
local Point = require(script.Parent.Parent.Point)
local Line = require(script.Parent.Parent.Line)
local Face = require(script.Parent.Parent.Face)
local VolumeUtil = require(script.Parent.Parent.VolumeUtil)
local RegularIcosahedron = require(script.Parent.RegularIcosahedron)
local Util = require(script.Parent.Parent.Util)
-- Types
export type IcosphereVolume = VolumeUtil.IcosphereVolume
export type TriangleFace = Face.TriangleFace
-- Constants
local CONSTANTS = require(script.Parent.Parent.CONSTANTS)
-- Variables
-- References
-- Private Functions

function getEdgeKey(a: Vector3, b: Vector3): string
	local ax = math.round(a.X * 1000)
	local ay = math.round(a.Y * 1000)
	local az = math.round(a.Z * 1000)
	local bx = math.round(b.X * 1000)
	local by = math.round(b.Y * 1000)
	local bz = math.round(b.Z * 1000)

	local aHash = ax * 1000000 + ay * 1000 + az
	local bHash = bx * 1000000 + by * 1000 + bz

	if aHash < bHash then
		return `{aHash}_{bHash}`
	else
		return `{bHash}_{aHash}`
	end
end

function getMidpoint(
	a: Point.VertexPoint,
	b: Point.VertexPoint,
	center: Vector3,
	radius: number,
	cache: { [string]: Point.VertexPoint }
): Point.VertexPoint
	local key = getEdgeKey(a.Position, b.Position)
	local cached = cache[key]
	if cached then return cached end

	-- Lerp to midpoint then project onto sphere
	local midPos = a.Position:Lerp(b.Position, 0.5)
	local direction = (midPos - center).Unit
	local projectedPos = center + direction * radius
	local normal = direction

	local vertex = Point.Vertex.new(projectedPos, normal)
	cache[key] = vertex
	return vertex
end

function subdivide(faces: { TriangleFace }, center: Vector3, radius: number): { TriangleFace }
	local midpointCache: { [string]: Point.VertexPoint } = {}
	local newFaces: { TriangleFace } = table.create(#faces * 4) :: { TriangleFace }

	for _, face in faces do
		local p1 = face.P1
		local p2 = face.P2
		local p3 = face.P3

		local m12 = getMidpoint(p1, p2, center, radius, midpointCache)
		local m23 = getMidpoint(p2, p3, center, radius, midpointCache)
		local m31 = getMidpoint(p3, p1, center, radius, midpointCache)

		table.insert(newFaces, Face.Triangle.new(p1, m12, m31))
		table.insert(newFaces, Face.Triangle.new(p2, m23, m12))
		table.insert(newFaces, Face.Triangle.new(p3, m31, m23))
		table.insert(newFaces, Face.Triangle.new(m12, m23, m31))
	end

	return newFaces
end

-- Class
local Icosphere = {}

function Icosphere.new(center: CFrame, diameter: number, subdivisions: number): IcosphereVolume
	local volume = RegularIcosahedron.new(center, diameter)
	local radius = diameter / 2

	-- Start with the 20 icosahedron faces, then subdivide to form an icosphere
	local faces: { TriangleFace } = RegularIcosahedron.faces(volume)
	for i = 1, subdivisions do
		faces = subdivide(faces, center.Position, radius)
	end

	return {
		Type = "Icosphere" :: "Icosphere",
		Id = Util.cantor3Pair(Util.cantorCFrame(center), math.ceil(diameter / CONSTANTS.FUZZY_EQ.LENGTH), subdivisions),
		Center = center,
		Diameter = diameter,
		Subdivisions = subdivisions,
		Volume = volume,
		Faces = faces,
	}
end

function Icosphere.fill(
	planet: IcosphereVolume,
	thickness: number?,
	filter: ((face: TriangleFace) -> boolean)?
): VolumeUtil.FillResult
	local faces = planet.Faces
	local parts: { BasePart } = table.create(#faces * 2) :: { BasePart }
	local cframes: { CFrame } = table.create(#faces * 2) :: { CFrame }

	for _, face in faces do
		if filter and not filter(face) then continue end
		local res = Face.Triangle.fill(face, thickness)
		Util.join(parts, res.Parts)
		Util.join(cframes, res.CFrames)
	end

	return {
		Parts = parts,
		CFrames = cframes,
	}
end

function Icosphere.edges(volume: IcosphereVolume): { Line.StraightLine }
	local edges: { Line.StraightLine } = {}
	local map: { [number]: true? } = {}
	for _, face in volume.Faces do
		for _, edge in Face.Triangle.edges(face) do
			local id = edge.Id
			if map[id] then continue end
			map[id] = true
			table.insert(edges, edge)
		end
	end
	return edges
end

function Icosphere.vertices(volume: IcosphereVolume): { Point.VertexPoint }
	local vertices: { Point.VertexPoint } = {}
	local map: { [number]: true? } = {}
	for _, face in volume.Faces do
		for _, vertex in Face.Triangle.vertices(face) do
			local id = vertex.Id
			if map[id] then continue end
			map[id] = true
			table.insert(vertices, vertex)
		end
	end
	return vertices
end

function Icosphere.magnitude(volume: IcosphereVolume): number
	local triangleArea = Face.Triangle.magnitude(volume.Faces[1])
	local triangleCount = #volume.Faces
	local r = volume.Diameter / 2
	local side = math.sqrt(4 * triangleArea / math.sqrt(3))
	local triCircumradius = side / math.sqrt(3)
	local apothem = math.sqrt(r ^ 2 - triCircumradius ^ 2)
	local sliceVolume = (1 / 3) * triangleArea * apothem
	return sliceVolume * triangleCount
end

function Icosphere.faces(volume: IcosphereVolume): { Face.TriangleFace } return table.clone(volume.Faces) end

function Icosphere.cframe(volume: IcosphereVolume): CFrame return volume.Center end

function Icosphere.hash(volume: IcosphereVolume): string return `VR{volume.Id}` end

return Icosphere
