local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Resources = require(ReplicatedStorage:WaitForChild("Resources"))
local Signal = Resources:LoadLibrary("Signal")
local Janitor = Resources:LoadLibrary("Janitor")
local t = Resources:LoadLibrary("t")
local Aura = require(script.BaseAura)
local Effect = require(script.BaseEffect)

local AuraAgent = {
	Events = {"AuraAdded", "AuraRemoved", "AuraStackAdded", "AuraStackRemoved", "AuraRefreshed"}
}

AuraAgent.__index = AuraAgent

function AuraAgent.new(instance, auras, effects)
	assert(t.tuple(t.Instance, t.table, t.table)(instance, auras, effects))

	local self = {
		AuraList = auras;
		EffectList = effects;
		Instance = instance;
		Janitor = Janitor.new();
		Changed = Signal.new();
		ActiveAuras = {};
		ActiveEffects = {}; -- TODO
		Destroyed = false;
	}
	setmetatable(self, AuraAgent)

	self.Janitor:LinkToInstance(instance)
	self.Janitor:Add(function()
		if not self.Destroyed then
			self:Destroy()
		end
	end)

	for _, eventName in ipairs(AuraAgent.Events) do
		self[eventName] = Signal.new()
		self.Janitor:Add(self[eventName])

		self[eventName]:Connect(function(...)
			self.Changed:Fire(eventName, ...)
		end)
	end

	return self
end

function AuraAgent:Apply(auraName, props)
	if self.Destroyed then
		error("Cannot call actions on a destroyed AuraAgent", 2)
	end

	assert(t.tuple(t.string, t.optional(t.table))(auraName, props))
	props = props or {}

	local auraDefinition = self.AuraList:Find(auraName)
	if not auraDefinition then
		return warn(("Attempt to apply invalid aura %q to %s"):format(auraName, self.Instance:GetFullName()))
	end

	local aura = Aura.new(auraName, auraDefinition, props)

	if self.ActiveAuras[auraName] then
		local oldAura = self.ActiveAuras[auraName]

		if
			aura:Get("MaxStacks") and aura:Get("MaxStacks") > 1
			and aura:Get("MaxStacks") == oldAura:Get("MaxStacks")
			and oldAura:Get("Stacks") ~= aura:Get("MaxStacks")
		then

			if aura:Get("ShouldAuraRefresh", true) then
				aura.Stacks = (oldAura.Stacks or 1) + 1
				self.ActiveAuras[auraName] = aura

				aura:FireHook("AuraRefreshed")
				self.AuraRefreshed:Fire(aura, oldAura)
			else
				oldAura.Stacks = (oldAura.Stacks or 1) + 1
			end

			aura:FireHook("AuraStackAdded")
			self.AuraStackAdded:Fire(aura)
			return true
		elseif aura:Get("ShouldAuraRefresh", true) then
			aura:FireHook("AuraRefreshed")
			self.AuraRefreshed:Fire(aura, oldAura)
		else
			return false
		end
	else
		aura:FireHook("AuraAdded")
		self.AuraAdded:Fire(aura)
	end

	self.ActiveAuras[auraName] = aura

	return true
end

function AuraAgent:Remove(auraName)
	if self.Destroyed then
		error("Cannot call actions on a destroyed AuraAgent", 2)
	end

	assert(t.tuple(t.string)(auraName))
	if self:Has(auraName) then
		self.ActiveAuras[auraName]:FireHook("AuraRemoved")
		self.AuraRemoved:Fire(self.ActiveAuras[auraName])
		self.ActiveAuras[auraName] = nil
		return true
	end
end

function AuraAgent:Has(auraName)
	if self.Destroyed then
		error("Cannot call actions on a destroyed AuraAgent", 2)
	end

	assert(t.string(auraName))
	return self.ActiveAuras[auraName] ~= nil
end

function AuraAgent:Get(auraName)
	if self.Destroyed then
		error("Cannot call actions on a destroyed AuraAgent", 2)
	end

	assert(t.string(auraName))
	return self.ActiveAuras[auraName]
end

function AuraAgent:GetAuras()
	if self.Destroyed then
		error("Cannot call actions on a destroyed AuraAgent", 2)
	end

	local auras = {}

	for _, aura in pairs(self.ActiveAuras) do
		auras[#auras + 1] = aura
	end

	return auras
end

-- Reduce duration and remove expired auras
function AuraAgent:CullAuras(dt)
	for name, aura in pairs(self.ActiveAuras) do
		aura.Duration = aura.Duration - dt

		if aura.Duration <= 0 then
			self:Remove(name)
		end
	end
end

-- Creates/deletes effects based on current auras
function AuraAgent:ReifyEffects()
	local activeEffects = {}

	-- Examine effects provided by current auras, and create missing effects.
	for name, aura in pairs(self.ActiveAuras) do
		local effects = aura:Get("Effects", {})

		for effectName, effectValue in pairs(effects) do
			if not activeEffects[effectName] then
				activeEffects[effectName] = {}
			end

			if type(effectValue) == "function" then
				effectValue = effectValue(aura)
			end

			table.insert(activeEffects[effectName], effectValue)

			if not self.ActiveEffects[effectName] then
				local effectDefinition = self.EffectList:Find(effectName)
				if not effectDefinition then
					return warn(("Attempt to apply invalid effect %q from aura %q"):format(effectName, name))
				end

				if effectDefinition.AllowedInstanceTypes then
					local allowed = false
					for _, className in ipairs(effectDefinition.AllowedInstanceTypes) do
						if self.Instance:IsA(className) then
							allowed = true
							break
						end
					end

					if not allowed then
						return warn(
							("Attempt to apply effect %q on disallowed instance type %q")
							:format(effectName, self.Instance.ClassName)
						)
					end
				end

				self.ActiveEffects[effectName] = Effect.new(effectName, effectDefinition, self) -- todo: xpcall to prevent yielding
			end
		end
	end

	-- Reduce active effects and remove effects that are no longer in use
	for name, effect in pairs(self.ActiveEffects) do
		if activeEffects[name] then
			effect:Reduce(activeEffects[name])
		else
			effect:Destruct()
			self.ActiveEffects[name] = nil
		end
	end
end

function AuraAgent:Update(dt)
	if self.Destroyed then
		error("Cannot call actions on a destroyed AuraAgent", 2)
	end

	self:CullAuras(dt)

	self:ReifyEffects()
end

function AuraAgent:Destroy()
	print('destroy')
	self.ActiveAuras = {}
	self:ReifyEffects()
	self.Destroyed = true
	self.Instance = nil
	self.Janitor:Cleanup()
end

return AuraAgent