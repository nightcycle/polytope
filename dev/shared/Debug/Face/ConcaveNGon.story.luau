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
return function(frame)
	pcall(function(...)
		Osiris.Init(game:GetService("CoreGui"), nil, false)
	end)
	local instList: { Instance } = {}
	local cleanUp = Osiris:Connect(function(): ()
		local pointNumber = Controllers.Osiris.SavedState(`{script.Name}/PointNumber`, 8)
		local length = Controllers.Osiris.SavedState(`{script.Name}/Length`, 5)
		local windowSize = Controllers.Osiris.SavedState(`{script.Name}/ControlSize`, Vector2.new(150, 100))

		local didChange = false
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
							Text = "Points",
							Min = 3,
						},
						States = {
							number = pointNumber,
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
							Text = "Length",
							Min = 1,
						},
						States = {
							number = length,
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
			local points = {}
			for i = 1, pointNumber:get() do
				local angle = math.rad((i - 1) * 360 / pointNumber:get())
				points[i] = Package.Point.Vertex.new(
					Vector3.new(math.sin(angle) * length:get(), 10, math.cos(angle) * length:get()),
					Vector3.yAxis
				)
			end
			local face = Package.Face.ConcaveNGon.new(points)
			instList = Package.Face.Any.debug(face)
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
