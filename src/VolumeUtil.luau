--!strict
-- Services
-- Packages
-- Modules
local Point = require(script.Parent.Point)
local Line = require(script.Parent.Line)
local Face = require(script.Parent.Face)
-- Types
export type BlockVolume = {
	Type: "Block",
	Faces: { [Enum.NormalId]: Face.RectangleFace },
	Vertices: { Point.VertexPoint },
	Edges: { Line.StraightLine },
	Origin: CFrame,
	Size: Vector3,
}

export type Volume = BlockVolume
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
local Util = {}

return Util
