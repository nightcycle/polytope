--!strict
-- Services
-- Packages
local Package = require(game.ReplicatedStorage.Packages.package)
-- Modules
-- Types
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
return function()
	local face = Package.Face.Rectangle.new(
		Package.Point.Basic.new(Vector3.new(0, 10, 0)),
		5,
		3,
		Vector3.yAxis,
		Vector3.zAxis
	)

	local instList = Package.Face.Any.debug(face)

	return function()
		for i, v in instList do
			v:Destroy()
		end
	end
end
