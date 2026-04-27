--!strict
-- Services
-- Packages
-- Modules
local Point = require(script.Parent.Parent.Point)
local Line = require(script.Parent.Parent.Line)
local Face = require(script.Parent.Parent.Face)
local VolumeUtil = require(script.Parent.Parent.VolumeUtil)
local Util = require(script.Parent.Parent.Util)
local InstanceCache = require(script.Parent.Parent.InstanceCache)
-- Types
export type RegularIcosahedronVolume = VolumeUtil.RegularIcosahedronVolume
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
local RegularIcosahedron = {}

function RegularIcosahedron.new(cf: CFrame, diameter: number): RegularIcosahedronVolume
	local out = {
		Type = "RegularIcosahedron" :: "RegularIcosahedron",
		Origin = cf,
		Diameter = diameter,
		Vertices = {},
		Edges = {},
		Faces = {},
	}
	table.freeze(out)
	table.freeze(out.Vertices)
	table.freeze(out.Edges)
	table.freeze(out.Faces)
	return out
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
	local parts: { BasePart } = table.create(6)
	local cfs: { CFrame } = table.create(6)
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

function RegularIcosahedron.magnitude(volume: RegularIcosahedronVolume): number
	return volume.Size.X * volume.Size.Y * volume.Size.Z
end

function RegularIcosahedron.debug(volume: RegularIcosahedronVolume): { Instance }
	local out: { Instance } = {}

	for i, face in RegularIcosahedron.faces(volume) do
		Util.join(out, Face.Any.debug(face))
	end

	return out
end

return RegularIcosahedron
