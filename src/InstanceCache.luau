--!strict
-- Services
-- Packages
-- Modules
local PartTemplates = require(script.Parent.PartTemplates)
-- Types
export type CacheHandler<V> = {
	create: (self: CacheHandler<V>) -> V,
	allocate: (self: CacheHandler<V>) -> V,
	store: (self: CacheHandler<V>, v: V) -> (),
	remove: (self: CacheHandler<V>, v: V) -> (),
	clear: (self: CacheHandler<V>, includeBorroed: boolean) -> (),
	borrowed: (self: CacheHandler<V>) -> { V },
	cached: (self: CacheHandler<V>) -> { V },
	size: (self: CacheHandler<V>) -> number,
	[any]: never,
}
-- Constants
-- Variables
-- References
-- Private Functions
function newCache<V>(constructor: () -> V): CacheHandler<V>
	local cache: { V } = {}
	local borrowed: { V } = {}
	local out = {
		create = function(self: CacheHandler<V>)
			return constructor()
		end,
		allocate = function(self: CacheHandler<V>)
			local v: V?
			if #cache > 0 then
				v = table.remove(cache, 1)
			else
				v = constructor()
			end
			assert(v ~= nil, `bad cache entry: {v}`)
			table.insert(borrowed, v)
			return v
		end,
		store = function(self: CacheHandler<V>, v: V)
			table.insert(cache, v)
		end,
		remove = function(self: CacheHandler<V>, v: V)
			pcall(function()
				local a: any = v
				a:Destroy()
			end)
		end,
		borrowed = function(self: CacheHandler<V>): { V }
			return table.clone(borrowed)
		end,
		cached = function(self: CacheHandler<V>): { V }
			return table.clone(cache)
		end,
		clear = function(self: CacheHandler<V>, includeBorrowed: boolean)
			do
				local oldCache = cache
				cache = {}
				for i, v in oldCache do
					pcall(function(...)
						local a: any = v
						a:Destroy()
					end)
				end
			end
			if includeBorrowed then
				local oldBorrowed = borrowed
				borrowed = {}
				for i, v in oldBorrowed do
					pcall(function(...)
						local a: any = v
						a:Destroy()
					end)
				end
			end
		end,
		size = function(self: CacheHandler<V>): number
			return #cache
		end,
	}
	return out
end
-- Class
local Module = {}

Module.Class = {}
Module.Class.WedgePart = newCache(function(): WedgePart
	return Instance.new("WedgePart")
end)
Module.Class.TriangleFace = newCache(function(): MeshPart
	return PartTemplates.Face.Triangle:Clone()
end)
Module.Class.RectangleFace = newCache(function(): MeshPart
	return PartTemplates.Face.Rectangle:Clone()
end)


function Module.clearAll(includeBorrowed: boolean)
	for k: string, v: CacheHandler<any> in Module.Class :: any do
		v:clear(includeBorrowed)
	end
end

return Module
