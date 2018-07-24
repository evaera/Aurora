local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Resources = require(ReplicatedStorage:WaitForChild("Resources"))

local Auras = Resources:LoadLibrary("BuffsServer")
local BuffAgent = Resources:LoadLibrary("AuraAgent")

local Aurora = {}
local Agents = setmetatable({}, {
	__mode = "k";
	__index = function(self, instance)
		local agent = BuffAgent.new(instance, Buffs)
		self[instance] = agent
		return agent
	end
})

function Aurora.GetAgent(instance)
	return Agents[instance]
end

function Aurora.RegisterAurasIn(object)
	Auras.LookIn(object)
end

function Aurora.RegisterEffectsIn(object)
	Effects.LookIn(object)
end

spawn(function()
	while true do
		local dt = wait(0.5)

		for _, agent in pairs(Agents) do
			agent:Update(dt)
		end
	end
end)

return Aurora