--!strict
-- Services
-- Packages
-- Modules
-- Types
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
local Util = {}

function Util.lock(inst: Instance | { Instance }, isLocked: boolean)
	if type(inst) == "table" then
		for i, v in inst do
			Util.lock(v, isLocked)
		end
	else
		if inst:IsA("BasePart") then
			inst.Locked = isLocked
		end
		for i, v in inst:GetChildren() do
			Util.lock(v, isLocked)
		end
	end
end

type DebugInstFocus = "Part" | "Line" | "Point"

function Util.transparency(inst: Instance | { Instance }, transparency: number, focus: DebugInstFocus?)
	if type(inst) == "table" then
		for i, v in inst do
			Util.transparency(v, transparency, focus)
		end
	else
		if inst:IsA("BasePart") then
			if
				focus == nil
				or (focus == "Part" and inst.Name ~= "DebugRay" and inst.Name ~= "DebugPoint")
				or (focus == "Line" and inst.Name == "DebugRay")
				or (focus == "Point" and inst.Name == "DebugPoint")
			then
				inst.Transparency = transparency
			end
		elseif inst:IsA("HandleAdornment") then
			if
				focus == nil
				or (focus == "Line" and inst.Parent and (inst.Parent.Name == "DebugRay" or inst.Parent.Name == "RotatedPart"))
				or (focus == "Point" and inst.Parent and inst.Parent.Name == "DebugPoint")
			then
				inst.Transparency = transparency
			end
		end
		for i, v in inst:GetChildren() do
			Util.transparency(v, transparency, focus)
		end
	end
end
function Util.color(inst: Instance | { Instance }, color: Color3, focus: DebugInstFocus?)
	if type(inst) == "table" then
		for i, v in inst do
			Util.color(v, color, focus)
		end
	else
		if inst:IsA("BasePart") then
			if
				focus == nil
				or (focus == "Part" and inst.Name ~= "DebugRay" and inst.Name ~= "DebugPoint")
				or (focus == "Line" and inst.Name == "DebugRay")
				or (focus == "Point" and inst.Name == "DebugPoint")
			then
				inst.Color = color
			end
		elseif inst:IsA("HandleAdornment") then
			if
				focus == nil
				or (focus == "Line" and inst.Parent and (inst.Parent.Name == "DebugRay" or inst.Parent.Name == "RotatedPart"))
				or (focus == "Point" and inst.Parent and inst.Parent.Name == "DebugPoint")
			then
				inst.Color3 = color
			end
		end
		for i, v in inst:GetChildren() do
			Util.color(v, color, focus)
		end
	end
end

return Util
