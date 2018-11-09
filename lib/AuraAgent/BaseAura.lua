local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Resources = require(ReplicatedStorage:WaitForChild("Resources"))
local t = Resources:LoadLibrary("t")
local Util = require(script.Parent.Util)

local IsStudio = RunService:IsStudio()
local IsServer = RunService:IsServer()
local IsClient = RunService:IsClient()

local AuraStructure = {
	Display = t.optional(t.keys(t.string));
	Status = t.optional(t.interface({
		Duration = t.optional(t.number);
		Visible = t.optional(t.boolean);
		Replicated = t.optional(t.boolean);
		ServerOnly = t.optional(t.boolean);
		ClientOnly = t.optional(t.boolean);
		MaxStacks = t.optional(t.number);
		ShouldAuraRefresh = t.optional(t.boolean);
	}));
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
				if k == "__keys" then -- make this not bad later
					local keys = {}
					for key in pairs(self) do
						keys[key] = true
					end
					if props[section] then
						for key in pairs(props[section]) do
							keys[key] = true
						end
					end
					if definition[section] then
						for key in pairs(definition[section]) do
							keys[key] = true
						end
					end
					return keys
				end

				local value = rawget(self, k)
				if value == nil and props[section] then
					value = props[section][k]
				end
				if value == nil and definition[section] then
					value = definition[section][k]
				end

				-- Don't pre-emptively call "Hooks" because they aren't the same as other functions
				if type(value) == "function" and section ~= "Hooks" then
					value = value(aura)
				end

				return value
			end
		}
	end
end

local Aura = {}
Aura.__index = Aura

function Aura.new(auraName, auraDefinition, props)
	assert(t.tuple(t.string, t.table, t.table)(auraName, auraDefinition, props))

	local self = setmetatable({
		Id = auraName;
		Name = props.Name or auraName;
		ChangedProperties = {};
		Props = props;
		Remote = false;
	}, Aura)

	local sectionIndex = MakeShadowedSection(self, auraDefinition, props)
	self.Status = setmetatable({}, sectionIndex("Status"))
	self.Display = setmetatable({}, sectionIndex("Display"))
	self.Params = setmetatable({}, sectionIndex("Params"))
	self.Hooks = setmetatable({}, sectionIndex("Hooks"))
	self.Effects = props.Effects or auraDefinition.Effects -- must be iterable, so apply no shadowing.

	-- Default values
	self.Status.Stacks = 1
	self.Status.TimeLeft = self.Status.Duration or math.huge

	-- keep track of which properties we need to send in snapshot
	for sectionName, section in pairs(props) do
		if REPLICATED_SECTIONS[sectionName] then
			if self.ChangedProperties[sectionName] == nil then
				self.ChangedProperties[sectionName] = {}
			end

			for key in pairs(section) do
				self.ChangedProperties[sectionName][key] = true
			end
		end
	end

	if self.Status.ClientOnly and IsServer then
		error(("[Aurora] Attempt to apply ClientOnly aura %q on server"):format(self.Id))
	elseif self.Status.ServerOnly and IsClient then
		error(("[Aurora] Attempt to apply ServerOnly aura %q on client"):format(self.Id))
	elseif self.Status.Replicated and (self.Status.ClientOnly or self.Status.ServerOnly) then
		warn(
			("[Aurora] Aura %q has both Replicated and ServerOnly/ClientOnly set to true; this does not make sense."):format(self.Id)
		)
	end


	if IsStudio then -- Only run in Studio because this a pretty expensive type check
		assert(IAuraDefinition(self:GetSections()))

		if self.Id:sub(1, 1) == ":" then
			error("[Aurora] Aura names cannot begin with a colon (:)")
		end

		-- Manually check that there are no weird keys in the aura info.
		-- This must be done like this because next() won't pick up keys in the hacky way we are doing it
		for key in pairs(auraDefinition.__keys) do -- __keys comes from the Immutable module
			if AuraStructure[key] == nil then
				error(("[Aurora] Unknown key %q in aura %q."):format(key, auraName), 2)
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
-- it is now. Does not include client-derivable properties.
function Aura:Snapshot()
	local props = {
		-- Forward custom name if it doesn't match
		Name = self.Id ~= self.Name and self.Name or nil;
	}

	for section in pairs(REPLICATED_SECTIONS) do
		if self.ChangedProperties[section] then
			props[section] = {}

			for key in pairs(self.ChangedProperties[section]) do
				props[section][key] = self[section][key]
			end
		end

		-- Effects are stored directly with no shadwoing, so this will pick up
		-- Effects from the definition. We need to exclude this.
		if section ~= "Effects" then
			for key, value in pairs(self[section]) do
				if props[section] == nil then
					props[section] = {}
				end

				props[section][key] = value
			end
		end
	end

	return Util.Staticize(self, props)
end


function Aura:FireHook(hookName, ...)
	if self.Hooks and self.Hooks[hookName] then
		return self.Hooks[hookName](self, ...)
	end
end

return Aura