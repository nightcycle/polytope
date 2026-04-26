--!strict
-- Services
-- Packages
-- Modules
local FaceUtil = require(script.FaceUtil)
local LineUtil = require(script.LineUtil)
local PointUtil = require(script.PointUtil)

-- Types
export type Point = PointUtil.Point
export type BasicPoint = PointUtil.BasicPoint
export type RotatedPoint = PointUtil.RotatedPoint
export type VertexPoint = PointUtil.VertexPoint
export type Line = LineUtil.Line
export type QuadraticBezierLine = LineUtil.QuadraticBezierLine
export type StraightLine = LineUtil.StraightLine
export type Face = FaceUtil.Face
export type RectangleFace = FaceUtil.RectangleFace
export type QuadFace = FaceUtil.QuadFace
export type RegularNGonFace = FaceUtil.RegularNGonFace
export type TriangleFace = FaceUtil.TriangleFace
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
local Module = {}

Module.InstanceCache = require(script.InstanceCache)
Module.Volume = require(script.Volume)
Module.Face = require(script.Face)
Module.Line = require(script.Line)
Module.Point = require(script.Point)
Module.ENV = require(script.ENV)
Module.Util = require(script.Util)
Module.Debug = require(script.Debug)

return Module