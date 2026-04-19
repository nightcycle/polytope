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
		local widget = Osiris.Widget.Text({
			Arguments = {
				Text = script.Name,
			},
		})

		local didChange = false

		local cfState = Controllers.Osiris.SavedState(`{script.Name}/CFrame`, CFrame.new(Vector3.zero))
		do
			Controllers.Osiris.CFrameInput({
				Arguments = { Size = 2, Color = Color3.new(0, 0, 1) },
				States = { value = cfState },
				Extra = { parent = widget },
			})
			if cfState:changed() then
				didChange = true
			end
		end
		local widthState = Controllers.Osiris.SavedState(`{script.Name}/Width`, 3)
		local heightState = Controllers.Osiris.SavedState(`{script.Name}/Height`, 3)

		Osiris.Widget.Window({
			Arguments = {
				Title = "Controls",
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
			local face = Package.Face.Rectangle.new(
				Package.Point.Basic.new(cfState:get().Position),
				heightState:get(),
				widthState:get(),
				-cfState:get().LookVector,
				cfState:get().UpVector
			)
			local orig = Package.ENV.DEBUG_SHOW_POINTS
			Package.ENV.DEBUG_SHOW_POINTS = false
			instList = Package.Face.Any.debug(face)
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
