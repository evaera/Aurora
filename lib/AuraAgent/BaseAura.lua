local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Resources = require(ReplicatedStorage:WaitForChild("Resources"))
local t = Resources:LoadLibrary("t")

local IsStudio = RunService:IsStudio()

local AuraStructure = {
	Title = t.string;
	Description = t.string;
	Duration = t.number;
	Visible = t.optional(t.boolean);
	Replicated = t.optional(t.boolean);
	MaxStacks = t.optional(t.number);
	ShouldAuraRefresh = t.optional(t.boolean);
	Effects = t.optional(t.table);
	Hooks = t.optional(t.interface({
		AuraAdded = t.optional(t.callback);
		AuraRemoved = t.optional(t.callback);
		AuraStackAdded = t.optional(t.callback);
		AuraStackRemoved = t.optional(t.callback);
		AuraRefreshed = t.optional(t.callback);
	}));
}

local IAuraDefinition = t.interface(AuraStructure)

local Aura = {}

function Aura.new(auraName, auraDefinition, props)
	assert(t.tuple(t.string, t.table, t.table)(auraName, auraDefinition, props))

	local self = setmetatable({
			Id = auraName;
			Stacks = 1;
		}, {
		__index = function(self, k)
			if Aura[k] then
				return Aura[k]
			end

			local value = rawget(self, k) or props[k] or auraDefinition[k]

			if type(value) == "function" then
				value = value(self) -- TODO: xpcall
			end

			return value
		end
	})

	if IsStudio then -- Only run in Studio because this a pretty expensive type check
		assert(IAuraDefinition(self:GetStatic()))

		-- Manually check that there are no weird keys in the aura info.
		-- This must be done like this because next() won't pick up keys in the hacky way we are doing it
		for _, key in pairs(auraDefinition.__keys) do -- __keys comes from the Immutable module
			if AuraStructure[key] == nil then
				error(("Unknown key %q in aura %q."):format(key, auraName), 2)
			end
		end
	end

	return self
end

function Aura:Get(k, default)
	assert(t.tuple(t.string, t.optional(t.any))(k, default))
	local value = self[k]

	if value == nil then
		value = default
	end

	if type(value) == "function" then
		value = value(self)
	end

	return value
end

--- Returns a static representation of the aura
function Aura:GetStatic()
	local staticAura = {}

	for key in pairs(AuraStructure) do
		staticAura[key] = self[key]
	end

	return staticAura
end

function Aura:FireHook(hookName, ...)
	if self.Hooks and self.Hooks[hookName] then
		return self.Hooks[hookName](self, ...)
	end
end

return Aura