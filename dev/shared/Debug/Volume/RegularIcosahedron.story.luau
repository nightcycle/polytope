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
		local sizeState = Controllers.Osiris.SavedState(`{script:GetFullName()}/Diameter`, 25)
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
							Text = "Size",
							Min = 20,
							Max = 1024,
						},
						States = {
							number = sizeState,
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
			local box = Package.Volume.RegularIcosahedron.new(cfState:get(), sizeState:get())

			local orig = Package.ENV.DEBUG_SHOW_POINTS
			Package.ENV.DEBUG_SHOW_POINTS = false
			Package.Util.join(instList, Package.Volume.RegularIcosahedron.debug(box))
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
