--!strict
-- Services
-- Packages
-- Modules
local LineUtil = require(script.Parent.Parent.LineUtil)
local QuadraticBezier = require(script.Parent.QuadraticBezier)
local Straight = require(script.Parent.Straight)
-- Types
export type Line = LineUtil.Line
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
local Any = {}

function Any.eq(a: Line, b: Line): boolean
	if a.Type ~= b.Type then
		return false
	end
	if a.Type == "Straight" then
		assert(b.Type == "Straight", `bad b type: {b.Type}`)
		return Straight.eq(a, b)
	elseif a.Type == "QuadraticBezier" then
		assert(b.Type == "QuadraticBezier", `bad b type: {b.Type}`)
		return QuadraticBezier.eq(a, b)
	else
		error(`bad type: "{a.Type}"`)
	end
end

function Any.magnitude(line: Line): number
	if line.Type == "Straight" then
		return Straight.magnitude(line)
	elseif line.Type == "QuadraticBezier" then
		return QuadraticBezier.magnitude(line)
	else
		error(`bad type: "{line.Type}"`)
	end
end

function Any.debug(line: Line): { Instance }
	if line.Type == "Straight" then
		return Straight.debug(line)
	elseif line.Type == "QuadraticBezier" then
		return QuadraticBezier.debug(line)
	else
		error(`bad type: "{line.Type}"`)
	end
end

function Any.pointAt(line: Line, t: number): Vector3
	if line.Type == "Straight" then
		return Straight.pointAt(line, t)
	elseif line.Type == "QuadraticBezier" then
		return QuadraticBezier.pointAt(line, t)
	else
		error(`bad type: "{line.Type}"`)
	end
end

function Any.pointAtOffset(line: Line, offset: number): Vector3
	if line.Type == "Straight" then
		return Straight.pointAtOffset(line, offset)
	elseif line.Type == "QuadraticBezier" then
		return QuadraticBezier.pointAtOffset(line, offset)
	else
		error(`bad type: "{line.Type}"`)
	end
end

function Any.intersection(a: Line, b: Line): Vector3?
	if a.Type ~= b.Type then
		warn(`intersection() with different types of lines not currently supported`)
		return nil
	end
	if a.Type == "Straight" then
		assert(b.Type == "Straight", `bad b type: {b.Type}`)
		return Straight.intersection(a, b)
	elseif a.Type == "QuadraticBezier" then
		assert(b.Type == "QuadraticBezier", `bad b type: {b.Type}`)
		return QuadraticBezier.intersection(a, b)
	else
		error(`bad type: "{a.Type}"`)
	end
end

return Any
