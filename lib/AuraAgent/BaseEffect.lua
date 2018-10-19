-- Constructor
-- Reduce
-- Destructor

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Resources = require(ReplicatedStorage:WaitForChild("Resources"))
local t = Resources:LoadLibrary("t")

local IsStudio = RunService:IsStudio()

local EffectStructure = {
	AllowedInstanceTypes = t.optional(t.array(t.string));
	Lazy = t.optional(t.boolean);
	Reducer = t.optional(t.callback);
	ShouldApply = t.optional(t.callback);
	Apply = t.optional(t.callback);
	Constructor = t.optional(t.callback);
	Destructor = t.optional(t.callback);
}

local IEffectDefinition = t.interface(EffectStructure)

local function defaultShouldApply(_, t1, t2)
	for i = 1, math.max(#t1, #t2) do
		if t1[i] ~= t2[i] then
			return true
		end
	end

	return false
end

local Effect = {}
Effect.__index = Effect

function Effect.new(effectName, effectDefinition, agent)
	if IsStudio then
		assert(IEffectDefinition(effectDefinition))

		for key in pairs(effectDefinition.__keys) do -- __keys comes from the Immutable module
			if EffectStructure[key] == nil then
				error(("Unknown key %q in aura %q."):format(key, effectName), 2)
			end
		end
	end

	local self = {
		Name = effectName;
		Definition = effectDefinition;
		Agent = agent;
		Instance = agent.Instance;
		LastReducedValue = {};
	}
	setmetatable(self, Effect)

	self:Construct()

	return self
end

function Effect:Construct()
	if self.Definition.Constructor then
		self.Definition.Constructor(self) -- TODO: prevent yield
	end
end

function Effect:ReduceAndApply(values)
	local previousReducedValue = self.LastReducedValue

	if self.Definition.Reducer then
		self.LastReducedValue = {self.Definition.Reducer(self, values)} -- TODO: prevent yield
	else
		self.LastReducedValue = {true}
	end

	if
		self.Definition.Lazy
		and not (self.Definition.ShouldApply or defaultShouldApply)(self, previousReducedValue, self.LastReducedValue)
	then
		return
	end

	if self.Definition.Apply then
		self.Definition.Apply(self, unpack(self.LastReducedValue))
	end
end

function Effect:Destruct()
	if self.Definition.Destructor then
		self.Definition.Destructor(self) -- TODO: prevent yield
	end
end

function Effect:GetLastReducedValue()
	if not self.Definition.Reducer then
		return nil
	end

	return unpack(self.LastReducedValue)
end

return Effect