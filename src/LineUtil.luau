--!strict
-- Services
-- Packages
-- Modules
local Point = require(script.Parent.Point)
-- Types
export type StraightLine = {
	Type: "Straight",
	P1: Point.VertexPoint,
	P2: Point.VertexPoint,
	Offset: Vector3,
}
export type QuadraticBezierLine = {
	Type: "QuadraticBezier",
	P1: Point.VertexPoint,
	P2: Point.VertexPoint,
	Intersection: Point.BasicPoint,
}
export type Line = StraightLine | QuadraticBezierLine
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
local Util = {}

return Util