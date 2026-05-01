--!strict
-- Services
-- Packages
-- Modules
local Point = require(script.Parent.Point)
local Line = require(script.Parent.Line)
local Face = require(script.Parent.Face)
-- Types
export type BoxVolume = {
	Type: "Box",
	Faces: { [Enum.NormalId]: Face.RectangleFace },
	Vertices: { Point.VertexPoint },
	Edges: { Line.StraightLine },
	Center: CFrame,
	Size: Vector3,
}
export type RegularIcosahedronVolume = {
	Type: "RegularIcosahedron",
	Faces: { Face.TriangleFace },
	Vertices: { Point.VertexPoint },
	Edges: { Line.StraightLine },
	Center: CFrame,
	Diameter: number,
}
export type IcosphereVolume = {
	Type: "Icosphere",
	Center: CFrame,
	Diameter: number,
	Subdivisions: number,
	Faces: { Face.TriangleFace },
}

export type FillResult = {
	Parts: { BasePart },
	CFrames: { CFrame },
}

export type Volume = BoxVolume | IcosphereVolume | RegularIcosahedronVolume
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
local Util = {}

return Util
