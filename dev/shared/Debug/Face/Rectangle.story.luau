--!strict
-- Services
-- Packages
local Package = require(game.ReplicatedStorage.Packages.Polytope)
local Osiris = require(game.ReplicatedStorage.DevPackages.Osiris)
-- Modules
local Controllers = require(game.ReplicatedStorage.Shared.Controllers)
-- Types
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
return function()
	pcall(function(...) Osiris.Init(game:GetService("CoreGui"), nil, false) end)
	local instList: { Instance } = {}
	local cleanUp = Osiris:Connect(function()
		local widget = Osiris.Widget.Text({
			Arguments = {
				Text = script.Name,
			},
		})

		local didChange = false

		local cfState = Controllers.Osiris.SavedState(`{script:GetFullName()}/CFrame`, CFrame.new(Vector3.zero))
		do
			Controllers.Osiris.CFrameInput({
				Arguments = { Size = 2, Color = Color3.new(0, 0, 1) },
				States = { value = cfState },
				Extra = { parent = widget },
			})
			if cfState:changed() then didChange = true end
		end
		local widthState = Controllers.Osiris.SavedState(`{script:GetFullName()}/Width`, 3)
		local rowCount = Controllers.Osiris.SavedState(`{script:GetFullName()}/Rows`, 6)
		local heightState = Controllers.Osiris.SavedState(`{script:GetFullName()}/Height`, 3)
		local windowSize = Controllers.Osiris.SavedState(`{script:GetFullName()}/ControlSize`, Vector2.new(150, 100))

		Osiris.Widget.Window({
			Arguments = {
				Title = "Controls",
			},
			States = {
				size = windowSize,
			},
		}, function(_)
			if
				Osiris.Widget
					.SliderNum({
						Arguments = {
							Text = "Width",
							Min = 1,
						},
						States = {
							number = widthState,
						},
					})
					.numberChanged()
			then
				didChange = true
			end
			if
				Osiris.Widget
					.SliderNum({
						Arguments = {
							Text = "Rows",
							Min = 1,
						},
						States = {
							number = rowCount,
						},
					})
					.numberChanged()
			then
				didChange = true
			end
			if
				Osiris.Widget
					.SliderNum({
						Arguments = {
							Text = "Height",
							Min = 1,
						},
						States = {
							number = heightState,
						},
					})
					.numberChanged()
			then
				didChange = true
			end
		end)

		if didChange or #instList == 0 then
			for i, v in instList do
				v:Destroy()
			end
			local face = Package.Face.Rectangle.new(cfState:get(), heightState:get(), widthState:get())
			do
				Package.ENV.DEBUG_SHOW_NORMALS = false
				-- local n = Package.Face.Any.normal(face).Unit
				-- local up = Vector3.zAxis:Cross(-n).Unit
				-- local r = up:Cross(n).Unit
				for i, rect in
					Package.Face.Any.tile(face, {
						Type = "Grid",
						Width = {
							Type = "Count",
							Value = rowCount:get(),
							RetryOnceIfNotExact = true,
						},
						Height = {
							Type = "Count",
							Value = rowCount:get(),
							RetryOnceIfNotExact = true,
						},
					}) --, up, r)
				do
					local rectInsts = Package.Face.Any.debug(rect)
					Package.Debug.color(rectInsts, Color3.new(1, 0.5, 0), "Part")
					Package.Debug.color(rectInsts, Color3.new(1, 1, 0), "Line")
					Package.Debug.transparency(rectInsts, 0, "Line")
					Package.Util.join(instList, rectInsts)
				end
				Package.ENV.DEBUG_SHOW_NORMALS = true
			end
			local orig = Package.ENV.DEBUG_SHOW_POINTS
			Package.ENV.DEBUG_SHOW_POINTS = false
			Package.Util.join(instList, Package.Face.Any.debug(face))
			Package.ENV.DEBUG_SHOW_POINTS = orig
			Package.Debug.lock(instList, true)
		end
	end)
	return function()
		cleanUp()
		for i, v in instList do
			v:Destroy()
		end
		Package.InstanceCache.clearAll(true)
	end
end
