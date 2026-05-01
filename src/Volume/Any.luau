--!strict
-- Services
-- Packages
local Draw = require(script.Parent.Parent.Parent.Draw)
-- Modules
local Point = require(script.Parent.Parent.Point)
local Line = require(script.Parent.Parent.Line)
local Face = require(script.Parent.Parent.Face)
local VolumeUtil = require(script.Parent.Parent.VolumeUtil)
local Util = require(script.Parent.Parent.Util)
local Box = require(script.Parent.Box)
local Icosphere = require(script.Parent.Icosphere)
local RegularIcosahedron = require(script.Parent.RegularIcosahedron)
local ENV = require(script.Parent.Parent.ENV)
-- Types
export type Volume = VolumeUtil.Volume
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
local Any = {}

function Any.fill(volume: Volume, thickness: number?): VolumeUtil.FillResult
	if volume.Type == "Box" then
		return Box.fill(volume, thickness)
	elseif volume.Type == "Icosphere" then
		return Icosphere.fill(volume, thickness)
	elseif volume.Type == "RegularIcosahedron" then
		return RegularIcosahedron.fill(volume, thickness)
	else
		error(`bad type: "{volume.Type}"`)
	end
end

function Any.eq(a: Volume, b: Volume): boolean
	if a.Type ~= b.Type then return false end
	if a.Type == "Box" then
		assert(b.Type == "Box", `bad type`)
		return Box.eq(a, b)
	elseif a.Type == "Icosphere" then
		assert(b.Type == "Icosphere", `bad type`)
		return Icosphere.eq(a, b)
	elseif a.Type == "RegularIcosahedron" then
		assert(b.Type == "RegularIcosahedron", `bad type`)
		return RegularIcosahedron.eq(a, b)
	else
		error(`bad type: "{a.Type}"`)
	end
end

function Any.hash(volume: Volume): string
	if volume.Type == "Box" then
		return Box.hash(volume)
	elseif volume.Type == "Icosphere" then
		return Icosphere.hash(volume)
	elseif volume.Type == "RegularIcosahedron" then
		return RegularIcosahedron.hash(volume)
	else
		error(`bad type: "{volume.Type}"`)
	end
end

function Any.getId(volume: Volume): number
	if volume.Type == "Box" then
		return Box.getId(volume)
	elseif volume.Type == "Icosphere" then
		return Icosphere.getId(volume)
	elseif volume.Type == "RegularIcosahedron" then
		return RegularIcosahedron.getId(volume)
	else
		error(`bad type: "{volume.Type}"`)
	end
end

function Any.cframe(volume: Volume): CFrame
	if volume.Type == "Box" then
		return Box.cframe(volume)
	elseif volume.Type == "Icosphere" then
		return Icosphere.cframe(volume)
	elseif volume.Type == "RegularIcosahedron" then
		return RegularIcosahedron.cframe(volume)
	else
		error(`bad type: "{volume.Type}"`)
	end
end

function Any.magnitude(volume: Volume): number
	if volume.Type == "Box" then
		return Box.magnitude(volume)
	elseif volume.Type == "Icosphere" then
		return Icosphere.magnitude(volume)
	elseif volume.Type == "RegularIcosahedron" then
		return RegularIcosahedron.magnitude(volume)
	else
		error(`bad type: "{volume.Type}"`)
	end
end

function Any.edges(volume: Volume): { Line.StraightLine }
	if volume.Type == "Box" then
		return Box.edges(volume)
	elseif volume.Type == "Icosphere" then
		return Icosphere.edges(volume)
	elseif volume.Type == "RegularIcosahedron" then
		return RegularIcosahedron.edges(volume)
	else
		error(`bad type: "{volume.Type}"`)
	end
end

function Any.vertices(volume: Volume): { Point.VertexPoint }
	if volume.Type == "Box" then
		return Box.vertices(volume)
	elseif volume.Type == "Icosphere" then
		return Icosphere.vertices(volume)
	elseif volume.Type == "RegularIcosahedron" then
		return RegularIcosahedron.vertices(volume)
	else
		error(`bad type: "{volume.Type}"`)
	end
end

function Any.faces(volume: Volume): { Face.Face }
	if volume.Type == "Box" then
		return Box.faces(volume) :: { Face.Face }
	elseif volume.Type == "Icosphere" then
		return Icosphere.faces(volume) :: { Face.Face }
	elseif volume.Type == "RegularIcosahedron" then
		return RegularIcosahedron.faces(volume) :: { Face.Face }
	else
		error(`bad type: "{volume.Type}"`)
	end
end

function Any.debug(volume: Volume): { Instance }
	local out: { Instance } = {}

	for i, edge in Any.edges(volume) do
		Util.join(out, Line.Any.debug(edge))
	end

	if ENV.DEBUG_SHOW_NORMALS then
		local cf = Any.cframe(volume)
		local normal = cf.LookVector
		local up = cf.UpVector
		local right = cf.RightVector
		local center = cf.Position
		table.insert(out, Draw.point(center, Color3.new(1, 1, 0)))
		table.insert(out, Draw.vector(center, normal * 3, Color3.new(1, 1, 0)))
		table.insert(out, Draw.vector(center, -normal * 3, Color3.new(0, 1, 0)))
		table.insert(out, Draw.vector(center, up * 3, Color3.new(0, 0, 1)))
		table.insert(out, Draw.vector(center, right * 3, Color3.new(1, 0, 0)))
	end
	if ENV.DEBUG_SHOW_FACES then
		local result = Any.fill(volume)
		Util.join(out :: { any }, result.Parts :: { any })
		workspace:BulkMoveTo(result.Parts, result.CFrames, Enum.BulkMoveMode.FireCFrameChanged)
		for i, inst in result.Parts do
			inst.Parent = workspace.CurrentCamera
		end
	end

	return out
end

return Any
