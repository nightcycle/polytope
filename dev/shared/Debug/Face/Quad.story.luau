--!strict
-- Services
-- Packages
local Package = require(game.ReplicatedStorage.Packages.package)
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
	pcall(function(...)
		Osiris.Init(game:GetService("CoreGui"), nil, false)
	end)
	local instList: { Instance } = {}
	local cleanUp = Osiris:Connect(function()
		local p1 = Controllers.Osiris.SavedState(`{script:GetFullName()}/P1`, CFrame.new(Vector3.zero))
		local p2 = Controllers.Osiris.SavedState(`{script:GetFullName()}/P2`, Vector3.one + Vector3.new(10, 0, 0))
		local p3 = Controllers.Osiris.SavedState(`{script:GetFullName()}/P3`, CFrame.new(Vector3.one + Vector3.new(10, 0, 10)))
		local p4 = Controllers.Osiris.SavedState(`{script:GetFullName()}/P4`, Vector3.one + Vector3.new(0, 0, 10))
		local rowCount = Controllers.Osiris.SavedState(`{script:GetFullName()}/Rows`, 6)
		-- local snapTo = Controllers.Osiris.SavedState(`{script:GetFullName()}/SnapTo`, 1)

		local widget = Osiris.Widget.Text({
			Arguments = {
				Text = script.Name,
			},
		})

		local didChange = false
		for i, v in { p1 :: any, p2, p3, p4 } do
			if typeof(v:get()) == "Vector3" then
				Controllers.Osiris.PositionInput({
					Arguments = { Size = 2, Color = Color3.new(1, 0, 0) },
					States = { value = v :: any },
					Extra = { parent = widget },
				})
			else
				Controllers.Osiris.CFrameInput({
					Arguments = { Size = 2, Color = Color3.new(0, 0, 1) },
					States = { value = v },
					Extra = { parent = widget },
				})
			end
			if v:changed() then
				didChange = true
			end
		end
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
			-- if
			-- 	Osiris.Widget
			-- 		.SliderNum({
			-- 			Arguments = {
			-- 				Text = "Snap To",
			-- 				Min = 1,
			-- 			},
			-- 			States = {
			-- 				number = snapTo,
			-- 			},
			-- 		})
			-- 		.numberChanged()
			-- then
			-- 	didChange = true
			-- end
		end)
		if didChange or #instList == 0 then
			for i, v in instList do
				v:Destroy()
			end
			local face = Package.Face.Quad.new(
				Package.Point.Vertex.new(p1:get().Position, p1:get().UpVector),
				Package.Point.Basic.new(p2:get()),
				Package.Point.Vertex.new(p3:get().Position, p3:get().UpVector),
				Package.Point.Basic.new(p4:get())
			)
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
					})--, up, r)
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
