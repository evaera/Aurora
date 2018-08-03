local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Resources = require(ReplicatedStorage:WaitForChild("Resources"))
local Debug = Resources:LoadLibrary("Debug")
local t = Resources:LoadLibrary("t")

local IsStudio = RunService:IsStudio()

local BuffStructure = {
	Title = t.string;
	Description = t.string;
	Duration = t.number;
	Visible = t.optional(t.boolean);
	Replicated = t.optional(t.boolean);
	MaxStacks = t.optional(t.number);
	ShouldBuffRefresh = t.optional(t.boolean);
	Effects = t.optional(t.interface({
		WalkSpeedMax = t.optional(t.callback);
	}));
	Hooks = t.optional(t.interface({
		BuffAdded = t.optional(t.callback);
		BuffRemoved = t.optional(t.callback);
		BuffStackAdded = t.optional(t.callback);
		BuffStackRemoved = t.optional(t.callback);
		BuffRefreshed = t.optional(t.callback);
	}));
}

local IBuff = t.interface(BuffStructure)

local Buff = {}

function Buff.new(buffName, buffInfo, props)
	assert(t.tuple(t.string, t.table, t.table)(buffName, buffInfo, props))

	local self = setmetatable({
			Id = buffName;
			Stacks = 1;
		}, {
		__index = function(self, k)
			if Buff[k] then
				return Buff[k]
			end

			local value = rawget(self, k) or props[k] or buffInfo[k]

			if type(value) == "function" then
				value = value(self) -- TODO: xpcall
			end

			return value
		end
	})

	if IsStudio then -- Only run in Studio because this a pretty expensive type check
		assert(IBuff(self:GetStatic()))

		-- Manually check that there are no weird keys in the buff info.
		-- This must be done like this because next() won't pick up keys in the hacky way we are doing it
		for _, key in pairs(buffInfo.__keys) do -- __keys comes from the Immutable module
			if BuffStructure[key] == nil then
				error(("Unknown key %q in buff %q."):format(key, buffName), 2)
			end
		end
	end

	return self
end

function Buff:Get(k, default)
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

--- Returns a static representation of the buff
function Buff:GetStatic()
	local staticBuff = {}

	for key in pairs(BuffStructure) do
		staticBuff[key] = self[key]
	end

	return staticBuff
end

function Buff:FireHook(hookName, ...)
	if self.Hooks and self.Hooks[hookName] then
		return self.Hooks[hookName](self, ...)
	end
end

return Buff