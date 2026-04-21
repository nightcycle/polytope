--!strict
-- Services
-- Packages
-- Modules
local Any = require(script.Any)
local QuadraticBezier = require(script.QuadraticBezier)
local Straight = require(script.Straight)

-- Types
export type Line = Any.Line
export type QuadraticBezierLine = QuadraticBezier.QuadraticBezierLine
export type StraightLine = Straight.StraightLine
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
local Module = {}

Module.Any = Any
Module.QuadraticBezier = QuadraticBezier
Module.Straight = Straight

return Module
