local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Resources = require(ReplicatedStorage:WaitForChild("Resources"))
local Signal = Resources:LoadLibrary("Signal")
local Janitor = Resources:LoadLibrary("Janitor")
local t = Resources:LoadLibrary("t")
local Aura = require(script.BaseAura)
local Effect = require(script.BaseEffect)
local Util = require(script.Util)

local Default = Util.Default
local IsServer = RunService:IsServer()
local IsClient = RunService:IsServer() == false -- allow to run in old play solo

local AuraAgent = {
	Events = {"AuraAdded", "AuraRemoved", "AuraStackAdded", "AuraStackRemoved", "AuraRefreshed"}
}

AuraAgent.__index = AuraAgent

local function CheckDestroy(agent)
	if agent.Destroyed then
		error("[Aurora] Cannot call actions on a destroyed AuraAgent", 3)
	end
end

local function CheckClient(agent)
	if IsClient and not agent.IncomingReplication then
		error("[Aurora] Cannot modify auras from the client", 3)
	end
end

function AuraAgent.new(instance, auras, effects, syncCallback)
	assert(t.tuple(t.Instance, t.table, t.table)(instance, auras, effects))

	local self = {
		AuraList = auras;
		EffectList = effects;
		Instance = instance;
		Janitor = Janitor.new();
		Changed = Signal.new();
		ActiveAuras = {};
		ActiveEffects = {};
		Destroyed = false;
		TimeInactive = 0;
		SyncCallback = syncCallback;
		IncomingReplication = false;
		DisableHooks = false;
	}
	setmetatable(self, AuraAgent)

	self.Janitor:LinkToInstance(instance)
	self.Janitor:Add(self.Changed)
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
	CheckDestroy(self)
	CheckClient(self)
	assert(t.tuple(t.string, t.optional(t.table))(auraName, props))

	props = props or {} -- todo type check props

	local auraDefinition = self.AuraList:Find(auraName)
	if not auraDefinition then
		return warn(("[Aurora] Attempt to apply invalid aura %q to %s"):format(auraName, self.Instance:GetFullName()))
	end

	local aura = Aura.new(auraName, auraDefinition, props)

	if Default(aura.Status.Replicated, true) then
		self:Sync("Apply", auraName, aura:Snapshot())
	end

	if props.Name and props.Name:sub(1, 1) ~= ":" then
		error("[Aurora] Custom Aura names must begin with a colon (:)", 2)
	end

	if props.Name and self.ActiveAuras[props.Name] and self.ActiveAuras[props.Name].Id ~= auraName then
		print(self.ActiveAuras[props.Name].Id, auraName)
		error("[Aurora] Can't apply two distinct Auras with the same custom name at the same time.", 2)
	end

	auraName = props.Name or auraName

	if self.ActiveAuras[auraName] then
		local oldAura = self.ActiveAuras[auraName]

		if
			aura.Status.MaxStacks and aura.Status.MaxStacks > 1
			and aura.Status.MaxStacks == oldAura.Status.MaxStacks
			and oldAura.Status.Stacks ~= aura.Status.MaxStacks
		then

			if Default(aura.Status.ShouldAuraRefresh, true) then
				aura.Status.Stacks = (oldAura.Status.Stacks or 1) + 1
				self.ActiveAuras[auraName] = aura

				self:FireHook(aura, "AuraRefreshed")
				self.AuraRefreshed:Fire(aura, oldAura)
			else
				oldAura.Stacks = (oldAura.Stacks or 1) + 1
			end

			self:FireHook(aura, "AuraStackAdded")
			self.AuraStackAdded:Fire(aura)
			return true
		elseif Default(aura.Status.ShouldAuraRefresh, true) then
			self:FireHook(aura, "AuraRefreshed")
			aura.Status.Stacks = oldAura.Status.Stacks
			self.AuraRefreshed:Fire(aura, oldAura)
		else
			return false
		end
	else
		if not self.IncomingReplication then -- Don't fire AuraAdded during a sync
			self:FireHook(aura, "AuraAdded")
		end
		self.AuraAdded:Fire(aura)
	end

	self.ActiveAuras[auraName] = aura

	return true
end

function AuraAgent:Consume(auraName, cause)
	CheckDestroy(self)
	CheckClient(self)
	assert(t.tuple(t.string, t.optional(t.string))(auraName, cause))

	cause = cause or "CONSUMED"

	local aura = self:Get(auraName)

	if aura then
		self:FireHook(aura, "AuraStackRemoved", cause)
		self.AuraStackRemoved:Fire(aura, cause)

		if aura.Status.Stacks == 1 then
			return self:Remove(auraName, cause)
		end

		if Default(aura.Status.Replicated, true) then
			self:Sync("Consume", auraName, cause)
		end

		aura.Status.Stacks = aura.Status.Stacks - 1
		return true
	end

	return false
end

function AuraAgent:Remove(auraName, cause)
	CheckDestroy(self)
	CheckClient(self)
	assert(t.tuple(t.string, t.optional(t.string))(auraName, cause))

	cause = cause or "REMOVED"

	local aura = self:Get(auraName)

	if aura then
		if Default(aura.Status.Replicated, true) then
			self:Sync("Remove", auraName, cause)
		end

		self:FireHook(aura, "AuraRemoved", cause)
		self.AuraRemoved:Fire(self.ActiveAuras[auraName], cause)
		self.ActiveAuras[auraName] = nil
		return true
	end

	return false
end

function AuraAgent:FireHook(aura, ...)
	if not self.DisableHooks then
		aura:FireHook(...)
	end
end

function AuraAgent:Has(auraName)
	CheckDestroy(self)
	assert(t.string(auraName))

	return self.ActiveAuras[auraName] ~= nil
end

function AuraAgent:HasEffect(effectName)
	CheckDestroy(self)
	assert(t.string(effectName))

	return self.ActiveEffects[effectName] ~= nil
end

function AuraAgent:Get(auraName)
	CheckDestroy(self)
	assert(t.string(auraName))

	return self.ActiveAuras[auraName]
end

function AuraAgent:GetAuras()
	CheckDestroy(self)

	local auras = {}

	for _, aura in pairs(self.ActiveAuras) do
		auras[#auras + 1] = aura
	end

	return auras
end

function AuraAgent:Sync(method, ...)
	if self.SyncCallback then
		self.SyncCallback(self, method, ...)
	end
end

function AuraAgent:Snapshot()
	CheckDestroy(self)

	if self.TimeInactive > 0 then
		return nil -- return nil when there's nothing to snapshot
	end

	local snapshot = {}

	for _, aura in pairs(self.ActiveAuras) do
		if Default(aura.Status.Replicated, true) then
			snapshot[aura.Id] = aura:Snapshot()
		end
	end

	return snapshot
end

-- Reduce duration and remove expired auras
function AuraAgent:CullAuras(dt)
	for name, aura in pairs(self.ActiveAuras) do
		aura.Status.TimeLeft = math.max(aura.Status.TimeLeft - dt, 0)

		if IsServer and aura.Status.TimeLeft <= 0 then
			self:Remove(name, "EXPIRED")
		end
	end
end

-- Creates/deletes effects based on current auras
function AuraAgent:ReifyEffects()
	local activeEffects = {}

	-- Examine effects provided by current auras, and create missing effects.
	for name, aura in pairs(self.ActiveAuras) do
		local effects = aura.Effects or {}

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
					return warn(("[Aurora] Attempt to apply invalid effect %q from aura %q"):format(effectName, name))
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
							("[Aurora] Attempt to apply effect %q on disallowed instance type %q")
							:format(effectName, self.Instance.ClassName)
						)
					end
				end

				self.ActiveEffects[effectName] = Effect.new(effectName, effectDefinition, self)
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
	CheckDestroy(self)

	self:CullAuras(dt)

	self:ReifyEffects()

	if next(self.ActiveAuras) == nil then
		self.TimeInactive = self.TimeInactive + dt
	else
		self.TimeInactive = 0
	end
end

function AuraAgent:Destroy()
	if self.Destroyed then
		return
	end

	self.ActiveAuras = {}
	self:ReifyEffects()
	self.Destroyed = true
	self.Instance = nil
	self.Janitor:Cleanup()
	self.Janitor = nil
end

return AuraAgent