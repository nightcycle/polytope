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
		local p1 = Controllers.Osiris.SavedState(`{script.Name}/P1`, CFrame.new(Vector3.one + Vector3.new(10, 0, 0)))
		local p2 = Controllers.Osiris.SavedState(`{script.Name}/P2`, CFrame.new(Vector3.one + Vector3.new(0, 5, 10)))
		local p3 = Controllers.Osiris.SavedState(`{script.Name}/P3`, CFrame.new(Vector3.one + Vector3.new(2, 3, 2)))

		local widget = Osiris.Widget.Text({
			Arguments = {
				Text = script.Name,
			},
		})

		local didChange = false
		for i, v in { p1 :: any, p2, p3 } do
			Controllers.Osiris.CFrameInput({
				Arguments = { Size = 2, Color = Color3.new(1, 0, 0) },
				States = { value = v },
				Extra = { parent = widget },
			})
			if v:changed() then
				didChange = true
			end
		end
		if didChange or #instList == 0 then
			for i, v in instList do
				v:Destroy()
			end
			local face = Package.Face.Triangle.new(
				Package.Point.Vertex.new(p1:get().Position, p1:get().UpVector),
				Package.Point.Vertex.new(p2:get().Position, p2:get().UpVector),
				Package.Point.Vertex.new(p3:get().Position, p3:get().UpVector)
			)
			local orig = Package.ENV.DEBUG_SHOW_POINTS
			Package.ENV.DEBUG_SHOW_POINTS = false
			instList = Package.Face.Any.debug(face)

			do
				Package.ENV.DEBUG_SHOW_NORMALS = false
				for i, rect in Package.Face.Triangle.fitIn(face, 40) do
					for j, inst in Package.Face.Any.debug(rect) do
						table.insert(instList, inst)
					end
				end
				Package.ENV.DEBUG_SHOW_NORMALS = true
			end

			Package.ENV.DEBUG_SHOW_POINTS = orig
		end
	end)

	return function()
		cleanUp()
		for i, v in instList do
			v:Destroy()
		end
	end
end
