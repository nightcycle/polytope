--!strict
-- Services
-- Packages
-- Modules
-- Types
export type BasicPoint = {
	Type: "Basic",
	Position: Vector3,
}
export type VertexPoint = {
	Type: "Vertex",
	Position: Vector3,
	Normal: Vector3,
}
export type RotatedPoint = {
	Type: "Rotated",
	CFrame: CFrame,
	Normal: Vector3,
	Position: Vector3,
	Up: Vector3,
}
export type Point = VertexPoint | BasicPoint | RotatedPoint
-- Constants

-- Variables
-- References
-- Private Functions
-- Class
local Util = {}
return Util
