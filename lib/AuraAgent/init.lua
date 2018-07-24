local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Resources = require(ReplicatedStorage:WaitForChild("Resources"))
local Signal = Resources:LoadLibrary("Signal")
local Janitor = Resources:LoadLibrary("Janitor")
local t = Resources:LoadLibrary("t")
local Buff = Resources:LoadLibrary("BaseBuff")

local BuffAgent = {
	Events = {"BuffAdded", "BuffRemoved", "BuffStackAdded", "BuffStackRemoved", "BuffRefreshed"}
}

BuffAgent.__index = BuffAgent

function BuffAgent.new(instance, buffList)
	assert(t.tuple(t.Instance, t.table)(instance, buffList))

	local self = {
		BuffList = buffList;
		Instance = instance;
		Janitor = Janitor.new();
		Changed = Signal.new();
		ActiveBuffs = {};
		ActiveEffects = {}; -- TODO
	}

	self.Janitor:LinkToInstance(instance)

	for _, eventName in ipairs(BuffAgent.Events) do
		self[eventName] = Signal.new()
		self.Janitor:Add(self[eventName])

		self[eventName]:Connect(function(...)
			self.Changed:Fire(eventName, ...)
		end)
	end

	setmetatable(self, BuffAgent)
	return self
end

function BuffAgent:Apply(buffName, props)
	assert(t.tuple(t.string, t.optional(t.table))(buffName, props))
	props = props or {}
	if not self.BuffList[buffName] then
		return warn(("Attempt to apply invalid buff %q to %s"):format(buffName, self.Instance))
	end

	local buff = Buff.new(buffName, self.BuffList[buffName], props)

	if self.ActiveBuffs[buffName] then
		local oldBuff = self.ActiveBuffs[buffName]

		if
			buff:Get("MaxStacks") and buff:Get("MaxStacks") > 1
			and buff:Get("MaxStacks") == oldBuff:Get("MaxStacks")
			and oldBuff:Get("Stacks") ~= buff:Get("MaxStacks")
		then

			if buff:Get("ShouldBuffRefresh", true) then
				buff.Stacks = (oldBuff.Stacks or 1) + 1
				self.ActiveBuffs[buffName] = buff

				buff:FireHook("BuffRefreshed")
				self.BuffRefreshed:Fire(buff, oldBuff)
			else
				oldBuff.Stacks = (oldBuff.Stacks or 1) + 1
			end

			buff:FireHook("BuffStackAdded")
			self.BuffStackAdded:Fire(buff)
			return true
		elseif buff:Get("ShouldBuffRefresh", true) then
			buff:FireHook("BuffRefreshed")
			self.BuffRefreshed:Fire(buff, oldBuff)
		else
			return false
		end
	else
		buff:FireHook("BuffAdded")
		self.BuffAdded:Fire(buff)
	end

	self.ActiveBuffs[buffName] = buff

	return true
end

function BuffAgent:Remove(buffName)
	assert(t.tuple(t.string)(buffName))
	if self:Has(buffName) then
		self.ActiveBuffs[buffName]:FireHook("BuffRemoved")
		self.BuffRemoved:Fire(self.ActiveBuffs[buffName])
		self.ActiveBuffs[buffName] = nil
		return true
	end
end

function BuffAgent:Has(buffName)
	assert(t.string(buffName))
	return self.ActiveBuffs[buffName] ~= nil
end

function BuffAgent:Get(buffName)
	assert(t.string(buffName))
	return self.ActiveBuffs[buffName]
end

function BuffAgent:GetBuffs()
	local buffs = {}

	for _, buff in pairs(self.ActiveBuffs) do
		buffs[#buffs + 1] = buff
	end

	return buffs
end

function BuffAgent:Update(dt)
	-- TODO
end

return BuffAgent