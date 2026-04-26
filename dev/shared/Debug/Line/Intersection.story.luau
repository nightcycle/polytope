--!strict
-- Services
-- Packages
local Package = require(game.ReplicatedStorage.Packages.package)
local Osiris = require(game.ReplicatedStorage.DevPackages.Osiris)
local Draw = require(game.ReplicatedStorage.Packages.Draw)
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
		local o1 = Controllers.Osiris.SavedState(`{script:GetFullName()}/O1`, CFrame.new(Vector3.one + Vector3.new(10, 0, 0)))
		local o2 = Controllers.Osiris.SavedState(`{script:GetFullName()}/O2`, CFrame.new(Vector3.one + Vector3.new(0, 5, 10)))
		local windowSize = Controllers.Osiris.SavedState(`{script:GetFullName()}/ControlSize`, Vector2.new(150, 100))
		local length1 = Controllers.Osiris.SavedState(`{script:GetFullName()}/Length1`, 10)
		local length2 = Controllers.Osiris.SavedState(`{script:GetFullName()}/Length2`, 10)

		local widget = Osiris.Widget.Text({
			Arguments = {
				Text = script.Name,
			},
		})

		local didChange = false
		for i, v in { o1, o2 } do
			Controllers.Osiris.CFrameInput({
				Arguments = { Size = 2, Color = Color3.new(1, 0, 0) },
				States = { value = v },
				Extra = { parent = widget },
			})
			if v:changed() then
				didChange = true
			end
		end
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
							Text = "Line 1 Length",
							Min = 1,
						},
						States = {
							number = length1,
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
							Text = "Line 2 Length",
							Min = 1,
						},
						States = {
							number = length2,
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
			table.clear(instList)

			local line1 = Package.Line.Straight.new(
				Package.Point.Vertex.new(o1:get().Position, Vector3.yAxis),
				Package.Point.Vertex.new(o1:get().Position + o1:get().LookVector * length1:get(), Vector3.yAxis)
			)
			local line2 = Package.Line.Straight.new(
				Package.Point.Vertex.new(o2:get().Position, Vector3.yAxis),
				Package.Point.Vertex.new(o2:get().Position + o2:get().LookVector * length2:get(), Vector3.yAxis)
			)
			local orig = Package.ENV.DEBUG_SHOW_POINTS
			Package.ENV.DEBUG_SHOW_POINTS = false

			local closestPoints = Package.Line.Straight.closestPoints(line1, line2)
			if closestPoints then
				table.insert(instList, Draw.point(closestPoints.A.Position))
				table.insert(instList, Draw.point(closestPoints.B.Position))
			end

			Package.Util.join(instList, Package.Line.Straight.debug(line1))
			Package.Util.join(instList, Package.Line.Straight.debug(line2))

			Package.ENV.DEBUG_SHOW_POINTS = orig
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
