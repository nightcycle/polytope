--!strict
-- Services
-- Packages
-- Modules
local Any = require(script.Any)
local Quad = require(script.Quad)
local Triangle = require(script.Triangle)
local Rectangle = require(script.Rectangle)
local RegularNGon = require(script.RegularNGon)
-- Types
export type Face = Any.Face
export type RectangleFace = Rectangle.RectangleFace
export type QuadFace = Quad.QuadFace
export type RegularNGonFace = RegularNGon.RegularNGonFace
export type TriangleFace = Triangle.TriangleFace
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
local Module = {}

Module.Any = Any
Module.Quad = Quad
Module.Triangle = Triangle
Module.Rectangle = Rectangle
Module.RegularNGon = RegularNGon

return Module
