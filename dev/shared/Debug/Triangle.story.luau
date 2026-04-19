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
	local face = Package.Face.Triangle.new(
		Package.Point.Vertex.new(Vector3.new(2, 10, -2), Vector3.yAxis),
		Package.Point.Vertex.new(Vector3.new(0, 8, 5), Vector3.yAxis),
		Package.Point.Vertex.new(Vector3.new(5, 12, 2), Vector3.yAxis),
		Vector3.yAxis
	)

	local instList = Package.Face.Any.debug(face)

	return function()
		for i, v in instList do
			v:Destroy()
		end
	end
end
