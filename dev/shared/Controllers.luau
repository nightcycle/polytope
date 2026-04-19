--!strict
-- Services
-- Packages
local Osiris = require(game.ReplicatedStorage.DevPackages.Osiris)
-- Modules
-- Types
export type Osiris = {}
type WidgetCacheEntry = {
	Instance: Instance,
}
-- Constants
-- Variables
-- References
local WidgetCache: { [string]: WidgetCacheEntry? } = {}
-- Private Functions
-- Class
local Module = {}

function Module.bindToInstance(inst: Instance, cleanUps: { () -> () | Object | Instance | RBXScriptConnection })
	local destroyingConnection: RBXScriptConnection
	destroyingConnection = inst.Destroying:Connect(function()
		destroyingConnection:Disconnect()
		for i, cleanUp in cleanUps do
			task.spawn(function()
				if type(cleanUp) == "function" then
					cleanUp()
				elseif typeof(cleanUp) == "RBXScriptConnection" then
					cleanUp:Disconnect()
				elseif typeof(cleanUp) == "Content" then
					cleanUp:Destroy()
				elseif typeof(cleanUp) == "Instance" then
					cleanUp:Destroy()
				else
					warn(`invalid clean-up class: "{typeof(cleanUp)}"`)
				end
			end)
		end
	end)
end
function Module.bindToWidget<Inst, I...>(
	id: string,
	widget: Osiris.BaseWidget,
	new: () -> Inst,
	update: (Inst, I...) -> (),
	...: I...
): (I...) -> ()
	local cacheEntry = WidgetCache[id]
	if not cacheEntry then
		local newInst: Inst = new()
		local newCacheEntry: WidgetCacheEntry = {
			Instance = newInst :: any,
		}
		Module.bindToInstance(widget.Instance, {
			newInst :: any,
			function()
				if WidgetCache[id] == newCacheEntry then
					WidgetCache[id] = nil
				end
			end,
		})
		update(newInst, ...)
		WidgetCache[id] = newCacheEntry
		cacheEntry = newCacheEntry
	end
	assert(cacheEntry, `bad cacheEntry for "{id}"`)
	return function(...: I...)
		update(cacheEntry.Instance :: any, ...)
	end
end

Module.Osiris = {}

Module.Osiris.Position = {}

Module.Osiris.PositionInput = function(props: {
	States: {
		position: Osiris.State<Vector3>,
		[any]: never,
	},
	Extra: {
		parent: Osiris.BaseWidget,
		[any]: never,
	},
	[any]: never,
})
	local state = props.States.position
	local widget = props.Extra.parent
	local id = `Position.new(widget={widget.ID},state={state.ID})`
	local update = Module.bindToWidget(id, widget, function(): Part
		local part = Instance.new("Part")
		part.Name = `PositionState`
		part.Anchored = true
		part.Transparency = 0.5
		part.Shape = Enum.PartType.Ball
		part.Size = Vector3.one * 3
		part.Parent = workspace.CurrentCamera

		return part
	end, function(part: Part, pos: Vector3)
		part.Position = state:get()
	end, state:get())
	if state:changed() then
		update(state:get())
	end
end

return Module
