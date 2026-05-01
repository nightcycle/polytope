--!strict
-- Services
-- Packages
-- Modules
local Box = require(script.Box)
local RegularIcosahedron = require(script.RegularIcosahedron)
local Icosphere = require(script.Icosphere)

-- Types
export type BoxVolume = Box.BoxVolume
export type RegularIcosahedronVolume = RegularIcosahedron.RegularIcosahedronVolume
export type IcosphereVolume = Icosphere.IcosphereVolume
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
local Module = {}

Module.Box = Box
Module.RegularIcosahedron = RegularIcosahedron
Module.Icosphere = Icosphere

return Module
