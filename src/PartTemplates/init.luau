--!strict
-- Services
-- Packages
-- Modules
-- Types
-- Constants
-- Variables
-- References
-- Private Functions
-- Class

return {
	Block = {
		CornerTriangle = script:WaitForChild("Block"):WaitForChild("CornerTriangle") :: MeshPart,
		InvertedCornerTriangle = script:WaitForChild("Block"):WaitForChild("InvertedCornerTriangle") :: MeshPart,
	},
	Face = {
		Rectangle = script:WaitForChild("Face"):WaitForChild("Rectangle") :: MeshPart,
		Triangle = script:WaitForChild("Face"):WaitForChild("Triangle") :: MeshPart,
	},
}
