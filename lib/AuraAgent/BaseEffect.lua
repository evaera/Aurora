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
	Reducer = t.optional(t.callback);
	Constructor = t.optional(t.callback);
	Destructor = t.optional(t.callback);
}

local IEffectDefinition = t.interface(EffectStructure)

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
	}
	setmetatable(self, Effect)


	self:Construct()

	return self
end

function Effect:Construct()
	if self.Definition.Constructor then
		self.Definition.Constructor(self) -- TODO: xpcall
	end
end

function Effect:Reduce(values)
	if self.Definition.Reducer then
		self.Definition.Reducer(self, values) -- TODO: xpcall
	end
end

function Effect:Destruct()
	if self.Definition.Destructor then
		self.Definition.Destructor(self) -- TODO: xpcall
	end
end

return Effect