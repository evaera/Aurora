local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Resources = require(ReplicatedStorage:WaitForChild("Resources"))
local Signal = Resources:LoadLibrary("Signal")
local Janitor = Resources:LoadLibrary("Janitor")
local t = Resources:LoadLibrary("t")
local Aura = require(script.BaseAura)

local AuraAgent = {
	Events = {"AuraAdded", "AuraRemoved", "AuraStackAdded", "AuraStackRemoved", "AuraRefreshed"}
}

AuraAgent.__index = AuraAgent

function AuraAgent.new(instance, auras)
	assert(t.tuple(t.Instance, t.table)(instance, auras))

	local self = {
		AuraList = auras;
		Instance = instance;
		Janitor = Janitor.new();
		Changed = Signal.new();
		ActiveAuras = {};
		ActiveEffects = {}; -- TODO
	}

	self.Janitor:LinkToInstance(instance)

	for _, eventName in ipairs(AuraAgent.Events) do
		self[eventName] = Signal.new()
		self.Janitor:Add(self[eventName])

		self[eventName]:Connect(function(...)
			self.Changed:Fire(eventName, ...)
		end)
	end

	setmetatable(self, AuraAgent)
	return self
end

function AuraAgent:Apply(auraName, props)
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
	assert(t.tuple(t.string)(auraName))
	if self:Has(auraName) then
		self.ActiveAuras[auraName]:FireHook("AuraRemoved")
		self.AuraRemoved:Fire(self.ActiveAuras[auraName])
		self.ActiveAuras[auraName] = nil
		return true
	end
end

function AuraAgent:Has(auraName)
	assert(t.string(auraName))
	return self.ActiveAuras[auraName] ~= nil
end

function AuraAgent:Get(auraName)
	assert(t.string(auraName))
	return self.ActiveAuras[auraName]
end

function AuraAgent:GetAuras()
	local auras = {}

	for _, aura in pairs(self.ActiveAuras) do
		auras[#auras + 1] = aura
	end

	return auras
end

function AuraAgent:Update(dt)
	-- TODO
end

return AuraAgent