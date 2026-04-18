--!strict
-- Services
-- Packages
local Package = require(game.ReplicatedStorage.Packages.package)
local Osiris = require(game.ReplicatedStorage.DevPackages.Osiris)
-- Modules
-- Types
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
return function()
	Osiris.Init(game:GetService("CoreGui"), nil, true)
	local instList: { Instance } = {}
	local cleanUp = Osiris:Connect(function()
		local p1 = Osiris.State(Vector3.zero)
		local p2 = Osiris.State(Vector3.one + Vector3.new(10, 0, 0))
		local p3 = Osiris.State(Vector3.one + Vector3.new(10, 0, 10))
		local p4 = Osiris.State(Vector3.one + Vector3.new(0, 0, 10))

		local didChange = false
		Osiris.Widget.Window({
			Arguments = {
				Title = "Controls",
			},
		}, function(_)
			for i, v in { p1, p2, p3, p4 } do
				if
					Osiris.Widget
						.InputVector3({
							Arguments = {
								Text = `P{i}`,
							},
							States = {
								number = v,
							},
						})
						.numberChanged()
				then
					didChange = true
				end
			end
		end)

		if didChange or #instList == 0 then
			for i, v in instList do
				v:Destroy()
			end
			local face = Package.Face.Quad.new(
				Package.Point.Vertex.new(p1:get(), Vector3.yAxis),
				Package.Point.Basic.new(p2:get()),
				Package.Point.Vertex.new(p3:get(), Vector3.yAxis),
				Package.Point.Basic.new(p4:get())
			)

			instList = Package.Face.Any.debug(face)
		end
	end)

	return function()
		cleanUp()
		for i, v in instList do
			v:Destroy()
		end
	end
end
