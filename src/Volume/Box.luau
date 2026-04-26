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
export type BoxVolume = VolumeUtil.BoxVolume
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
local Box = {}

function Box.new(cf: CFrame, size: Vector3): BoxVolume
	local function toVertex(p: Vector3)
		return Point.Vertex.new(p, (p - cf.Position).Unit)
	end

	local xyz = cf:PointToWorldSpace(size * 0.5 * Vector3.new(1, 1, 1))
	local Xyz = cf:PointToWorldSpace(size * 0.5 * Vector3.new(-1, 1, 1))
	local XYz = cf:PointToWorldSpace(size * 0.5 * Vector3.new(-1, -1, 1))
	local XYZ = cf:PointToWorldSpace(size * 0.5 * Vector3.new(-1, -1, -1))
	local xYZ = cf:PointToWorldSpace(size * 0.5 * Vector3.new(1, -1, -1))
	local xyZ = cf:PointToWorldSpace(size * 0.5 * Vector3.new(1, 1, -1))
	local xYz = cf:PointToWorldSpace(size * 0.5 * Vector3.new(1, -1, 1))
	local XyZ = cf:PointToWorldSpace(size * 0.5 * Vector3.new(-1, 1, -1))

	local p_xyz = toVertex(xyz)
	local p_Xyz = toVertex(Xyz)
	local p_XYz = toVertex(XYz)
	local p_XYZ = toVertex(XYZ)
	local p_xYZ = toVertex(xYZ)
	local p_xyZ = toVertex(xyZ)
	local p_xYz = toVertex(xYz)
	local p_XyZ = toVertex(XyZ)

	local l_xy = Line.Straight.new(p_xyz, p_xyZ)
	local l_xY = Line.Straight.new(p_xYz, p_xYZ)
	local l_Xy = Line.Straight.new(p_Xyz, p_XyZ)
	local l_XY = Line.Straight.new(p_XYz, p_XYZ)

	local l_yz = Line.Straight.new(p_xyz, p_Xyz)
	local l_yZ = Line.Straight.new(p_xyz, p_XyZ)
	local l_Yz = Line.Straight.new(p_xYz, p_XYz)
	local l_YZ = Line.Straight.new(p_xYZ, p_XYZ)

	local l_xz = Line.Straight.new(p_xyz, p_xYz)
	local l_xZ = Line.Straight.new(p_xyZ, p_xYZ)
	local l_Xz = Line.Straight.new(p_Xyz, p_XYz)
	local l_XZ = Line.Straight.new(p_XyZ, p_XYZ)

	local out = {
		Type = "Box" :: "Box",
		Origin = cf,
		Size = size,
		Vertices = {
			p_xyz,
			p_Xyz,
			p_XYz,
			p_XYZ,
			p_xYZ,
			p_xyZ,
			p_xYz,
			p_XyZ,
		},
		Edges = {
			l_xy,
			l_xY,
			l_Xy,
			l_XY,
			l_yz,
			l_yZ,
			l_Yz,
			l_YZ,
			l_xz,
			l_xZ,
			l_Xz,
			l_XZ,
		},
		Faces = {
			[Enum.NormalId.Front] = Face.Rectangle.new(
				Point.Rotated.new(
					CFrame.fromMatrix(cf:PointToWorldSpace(Vector3.zAxis * size / 2), cf.RightVector, cf.UpVector)
				),
				size.Y,
				size.X
			),
			[Enum.NormalId.Back] = Face.Rectangle.new(
				Point.Rotated.new(
					CFrame.fromMatrix(cf:PointToWorldSpace(-Vector3.zAxis * size / 2), cf.RightVector, cf.UpVector)
				),
				size.Y,
				size.X
			),
			[Enum.NormalId.Right] = Face.Rectangle.new(
				Point.Rotated.new(
					CFrame.fromMatrix(cf:PointToWorldSpace(Vector3.xAxis * size / 2), -cf.LookVector, cf.UpVector)
				),
				size.Y,
				size.Z
			),
			[Enum.NormalId.Left] = Face.Rectangle.new(
				Point.Rotated.new(
					CFrame.fromMatrix(cf:PointToWorldSpace(-Vector3.xAxis * size / 2), -cf.LookVector, cf.UpVector)
				),
				size.Y,
				size.Z
			),
			[Enum.NormalId.Top] = Face.Rectangle.new(
				Point.Rotated.new(
					CFrame.fromMatrix(cf:PointToWorldSpace(Vector3.yAxis * size / 2), cf.RightVector, -cf.LookVector)
				),
				size.Z,
				size.X
			),
			[Enum.NormalId.Bottom] = Face.Rectangle.new(
				Point.Rotated.new(
					CFrame.fromMatrix(cf:PointToWorldSpace(-Vector3.yAxis * size / 2), cf.RightVector, -cf.LookVector)
				),
				size.Z,
				size.X
			),
		},
	}
	table.freeze(out)
	table.freeze(out.Vertices)
	table.freeze(out.Edges)
	table.freeze(out.Faces)
	return out
end

function Box.vertices(volume: BoxVolume): { Point.VertexPoint }
	return table.clone(volume.Vertices)
end

function Box.edges(volume: BoxVolume): { Line.StraightLine }
	return table.clone(volume.Edges)
end

function Box.faces(volume: BoxVolume): { Face.RectangleFace }
	local out = {}
	for k, v in volume.Faces do
		table.insert(out, v)
	end
	return out
end

function Box.magnitude(volume: BoxVolume): number
	return volume.Size.X * volume.Size.Y * volume.Size.Z
end

function Box.debug(volume: BoxVolume): { Instance }
	local out: { Instance } = {}

	for i, face in Box.faces(volume) do
		Util.join(out, Face.Any.debug(face))
	end

	return out
end



return Box
