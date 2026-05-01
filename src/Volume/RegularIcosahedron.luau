--!strict
-- Services
-- Packages
-- Modules
local Point = require(script.Parent.Parent.Point)
local Line = require(script.Parent.Parent.Line)
local Face = require(script.Parent.Parent.Face)
local VolumeUtil = require(script.Parent.Parent.VolumeUtil)
local Util = require(script.Parent.Parent.Util)
-- Types
export type RegularIcosahedronVolume = VolumeUtil.RegularIcosahedronVolume
-- Constants
local CONSTANTS = require(script.Parent.Parent.CONSTANTS)
-- Variables
-- References
-- Private Functions
-- Class
local RegularIcosahedron = {}

function RegularIcosahedron.new(cf: CFrame, diameter: number): RegularIcosahedronVolume
	local function toVertex(p: Vector3) return Point.Vertex.new(p, (p - cf.Position).Unit) end

	local phi = (1 + math.sqrt(5)) / 2
	local circumradius = diameter / 2
	local rawLen = math.sqrt(1 + phi * phi)
	local s = circumradius / rawLen

	local rawVerts: { Vector3 } = {
		Vector3.new(0, 1, phi) * s,
		Vector3.new(0, 1, -phi) * s,
		Vector3.new(0, -1, phi) * s,
		Vector3.new(0, -1, -phi) * s,
		Vector3.new(1, phi, 0) * s,
		Vector3.new(1, -phi, 0) * s,
		Vector3.new(-1, phi, 0) * s,
		Vector3.new(-1, -phi, 0) * s,
		Vector3.new(phi, 0, 1) * s,
		Vector3.new(phi, 0, -1) * s,
		Vector3.new(-phi, 0, 1) * s,
		Vector3.new(-phi, 0, -1) * s,
	}

	local verts: { Point.VertexPoint } = table.create(12) :: { Point.VertexPoint }
	for i, rv in rawVerts do
		local worldPos = cf:PointToWorldSpace(rv)
		verts[i] = toVertex(worldPos)
	end

	local faceIndices: { { number } } = {
		{ 1, 3, 9 },
		{ 1, 9, 5 },
		{ 1, 5, 7 },
		{ 1, 7, 11 },
		{ 1, 11, 3 },
		{ 4, 10, 2 },
		{ 4, 2, 12 },
		{ 4, 12, 8 },
		{ 4, 8, 6 },
		{ 4, 6, 10 },
		{ 9, 3, 6 },
		{ 9, 6, 10 },
		{ 9, 10, 5 },
		{ 5, 10, 2 },
		{ 5, 2, 7 },
		{ 7, 2, 12 },
		{ 7, 12, 11 },
		{ 11, 12, 8 },
		{ 11, 8, 3 },
		{ 3, 8, 6 },
	}

	local edgeMap: { [string]: true } = {}
	local edges: { Line.StraightLine } = {}
	for _, tri in faceIndices do
		for j = 1, 3 do
			local a = tri[j]
			local b = tri[(j % 3) + 1]
			local lo = math.min(a, b)
			local hi = math.max(a, b)
			local key = `{lo}_{hi}`
			if not edgeMap[key] then
				edgeMap[key] = true
				table.insert(edges, Line.Straight.new(verts[lo], verts[hi]))
			end
		end
	end

	local faces: { Face.TriangleFace } = table.create(20) :: { Face.TriangleFace }
	for i, tri in faceIndices do
		faces[i] = Face.Triangle.new(verts[tri[1]], verts[tri[2]], verts[tri[3]])
	end

	local out = {
		Type = "RegularIcosahedron" :: "RegularIcosahedron",
		Id = Util.cantorPair(Util.cantorCFrame(cf), math.ceil(diameter / CONSTANTS.FUZZY_EQ.LENGTH)),
		Center = cf,
		Diameter = diameter,
		Vertices = verts,
		Edges = edges,
		Faces = faces,
	}
	table.freeze(out)
	table.freeze(out.Vertices)
	table.freeze(out.Edges)
	table.freeze(out.Faces)
	return out :: RegularIcosahedronVolume
end

function RegularIcosahedron.vertices(volume: RegularIcosahedronVolume): { Point.VertexPoint }
	return table.clone(volume.Vertices)
end

function RegularIcosahedron.edges(volume: RegularIcosahedronVolume): { Line.StraightLine }
	return table.clone(volume.Edges)
end

function RegularIcosahedron.faces(volume: RegularIcosahedronVolume): { Face.TriangleFace }
	return table.clone(volume.Faces)
end

function RegularIcosahedron.fill(volume: RegularIcosahedronVolume, thickness: number?): VolumeUtil.FillResult
	local parts: { BasePart } = table.create(6) :: { BasePart }
	local cfs: { CFrame } = table.create(6) :: { CFrame }
	for k, v in volume.Faces do
		local res = Face.Triangle.fill(v, thickness)
		Util.join(parts, res.Parts)
		Util.join(cfs, res.CFrames)
	end
	return {
		Parts = parts,
		CFrames = cfs,
	}
end

function RegularIcosahedron.cframe(volume: RegularIcosahedronVolume): CFrame return volume.Center end

function RegularIcosahedron.hash(volume: RegularIcosahedronVolume): string return `VR{volume.Id}` end

function RegularIcosahedron.magnitude(volume: RegularIcosahedronVolume): number
	local R = volume.Diameter / 2
	local a = R / math.sin(2 * math.pi / 5)
	return (5 / 12) * (3 + math.sqrt(5)) * a * a * a
end

function RegularIcosahedron.debug(volume: RegularIcosahedronVolume): { Instance }
	local out: { Instance } = {}

	for i, face in RegularIcosahedron.faces(volume) do
		Util.join(out, Face.Any.debug(face))
	end

	return out
end

return RegularIcosahedron
