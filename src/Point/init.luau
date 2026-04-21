--!strict
-- Services
-- Packages
-- Modules
local Any = require(script.Any)
local Basic = require(script.Basic)
local Vertex = require(script.Vertex)
local Rotated = require(script.Rotated)
-- Types
export type Point = Any.Point
export type BasicPoint = Basic.BasicPoint
export type RotatedPoint = Rotated.RotatedPoint
export type VertexPoint = Vertex.VertexPoint
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
local Module = {}

Module.Any = Any
Module.Basic = Basic
Module.Vertex = Vertex
Module.Rotated = Rotated

return Module
