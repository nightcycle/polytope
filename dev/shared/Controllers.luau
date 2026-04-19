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

Module.Osiris.SavedState = function<V>(key: string, initial: V): Osiris.State<V>
	local attrKey = `SAVEDSTATE_{key}`
	local savedInitial = workspace:GetAttribute(attrKey)
	if savedInitial ~= nil and typeof(savedInitial) == typeof(initial) then
		initial = savedInitial :: any
	end
	local state = Osiris.State(initial)
	if state:changed() then
		workspace:SetAttribute(attrKey, state:get())
	end
	return state
end

Module.Osiris.Position = {}

Module.Osiris.PositionInput = function(props: {
	Arguments: {
		Transparency: number?,
		Color: Color3?,
		Size: number?,
		[any]: never,
	}?,
	States: {
		value: Osiris.State<Vector3>,
		[any]: never,
	},
	Extra: {
		parent: Osiris.BaseWidget,
		[any]: never,
	},
	[any]: never,
})
	local state = props.States.value
	local widget = props.Extra.parent
	local id = `Position.new(widget={widget.ID},state={state.ID})`
	local update = Module.bindToWidget(
		id,
		widget,
		function(): Part
			local part = Instance.new("Part")
			part.Name = `PositionInput<{id}>`
			part.Anchored = true
			part.Shape = Enum.PartType.Ball
			part.Parent = workspace.CurrentCamera
			Module.bindToInstance(part, {
				part:GetPropertyChangedSignal("Position"):Connect(function()
					state:set(part.Position)
				end),
			})
			return part
		end,
		function(part: Part, pos: Vector3, color: Color3?, transparency: number?, size: number?)
			part.Position = pos
			part.Transparency = transparency or 0.5
			part.Color = color or Color3.new(0.5, 0.5, 0.5)
			part.Size = Vector3.one * (size or 3)
		end,
		state:get(),
		props.Arguments and props.Arguments.Color,
		props.Arguments and props.Arguments.Transparency,
		props.Arguments and props.Arguments.Size
	)
	update(
		state:get(),
		props.Arguments and props.Arguments.Color,
		props.Arguments and props.Arguments.Transparency,
		props.Arguments and props.Arguments.Size
	)
end
Module.Osiris.CFrameInput = function(props: {
	Arguments: {
		Transparency: number?,
		Color: Color3?,
		Size: number?,
		[any]: never,
	}?,
	States: {
		value: Osiris.State<CFrame>,
		[any]: never,
	},
	Extra: {
		parent: Osiris.BaseWidget,
		[any]: never,
	},
	[any]: never,
})
	local state = props.States.value
	local widget = props.Extra.parent
	local id = `Position.new(widget={widget.ID},state={state.ID})`
	local update = Module.bindToWidget(
		id,
		widget,
		function(): Part
			local part = Instance.new("Part")
			part.Name = `CFrameInput<{id}>`
			part.Anchored = true
			part.Shape = Enum.PartType.Block
			part.Parent = workspace.CurrentCamera
			Module.bindToInstance(part, {
				part:GetPropertyChangedSignal("CFrame"):Connect(function()
					state:set(part.CFrame)
				end),
			})
			return part
		end,
		function(part: Part, cf: CFrame, color: Color3?, transparency: number?, size: number?)
			part.CFrame = cf
			part.Transparency = transparency or 0.5
			part.Color = color or Color3.new(0.5, 0.5, 0.5)
			part.Size = Vector3.one * (size or 3)
		end,
		state:get(),
		props.Arguments and props.Arguments.Color,
		props.Arguments and props.Arguments.Transparency,
		props.Arguments and props.Arguments.Size
	)
	update(
		state:get(),
		props.Arguments and props.Arguments.Color,
		props.Arguments and props.Arguments.Transparency,
		props.Arguments and props.Arguments.Size
	)
end

return Module
