local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Resources = require(ReplicatedStorage:WaitForChild("Resources"))
local t = Resources:LoadLibrary("t")
local Util = require(script.Parent.Util)

local IsStudio = RunService:IsStudio()

local AuraStructure = {
	Display = t.optional(t.keys(t.string));
	Status = t.interface({
		Duration = t.number;
		Visible = t.optional(t.boolean);
		Replicated = t.optional(t.boolean);
		MaxStacks = t.optional(t.number);
		ShouldAuraRefresh = t.optional(t.boolean);
	});
	Params = t.optional(t.keys(t.string));
	Effects = t.optional(t.keys(t.string));
	Hooks = t.optional(t.interface({
		AuraAdded = t.optional(t.callback);
		AuraRemoved = t.optional(t.callback);
		AuraStackAdded = t.optional(t.callback);
		AuraStackRemoved = t.optional(t.callback);
		AuraRefreshed = t.optional(t.callback);
	}));
}

local REPLICATED_SECTIONS = {
	Status = true;
	Params = true;
	Display = true;
	Effects = true;
}

local IAuraDefinition = t.interface(AuraStructure)

local function MakeShadowedSection(aura, definition, props)
	return function (section)
		return {
			__index = function (self, k)
				local value = rawget(self, k)
				if value == nil and props[section] then
					value = props[section][k]
				end
				if value == nil and definition[section] then
					value = definition[section][k]
				end

				if type(value) == "function" then
					value = value(aura)
				end

				return value
			end
		}
	end
end

local Aura = {}
Aura.__index = Aura

function Aura.PruneNonReplicatedSections(props)
	local pruned = {}

	for key, value in pairs(props) do
		if REPLICATED_SECTIONS[key] then
			pruned[key] = value
		end
	end

	return pruned
end

function Aura.new(auraName, auraDefinition, props)
	assert(t.tuple(t.string, t.table, t.table)(auraName, auraDefinition, props))

	local self = setmetatable({
		Id = auraName;
		ReplicatedSections = {
			Status = true; -- Status is always replicated, because it is always modified
		};
		Props = props;
	}, Aura)

	local sectionIndex = MakeShadowedSection(self, auraDefinition, props)
	self.Status = setmetatable({
		Stacks = 1;
	}, sectionIndex("Status"))
	self.Display = setmetatable({}, sectionIndex("Display"))
	self.Params = setmetatable({}, sectionIndex("Params"))
	self.Hooks = setmetatable({}, sectionIndex("Hooks"))
	self.Effects = props.Effects or auraDefinition.Effects -- must be iterable, so apply no shadowing.

	-- keep track of which sections we need to send in snapshot
	for key in pairs(props) do
		if REPLICATED_SECTIONS[key] then
			self.ReplicatedSections[key] = true
		end
	end


	if IsStudio then -- Only run in Studio because this a pretty expensive type check
		assert(IAuraDefinition(self:GetSections()))

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

--- Returns a table containing all section tables from this aura
function Aura:GetSections()
	local sections = {}

	for key in pairs(AuraStructure) do
		sections[key] = self[key]
	end

	return sections
end

--- Returns a set of static props that can be used to re-create this aura as
-- it is now. Does not include client-derivable sections.
function Aura:Snapshot()
	local static = {}

	for section in pairs(self.ReplicatedSections) do
		static[section] = Util.Staticize(self, self[section], AuraStructure[section])
	end

	return static
end

function Aura:FireHook(hookName, ...)
	if self.Hooks and self.Hooks[hookName] then
		return self.Hooks[hookName](self, ...)
	end
end

return Aura