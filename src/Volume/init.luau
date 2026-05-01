--!strict
-- Services
-- Packages
-- Modules
local Box = require(script.Box)
local RegularIcosahedron = require(script.RegularIcosahedron)

-- Types
export type BoxVolume = Box.BoxVolume
export type RegularIcosahedronVolume = RegularIcosahedron.RegularIcosahedronVolume
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
local Module = {}

Module.Box = Box
Module.RegularIcosahedron = RegularIcosahedron

return Module
