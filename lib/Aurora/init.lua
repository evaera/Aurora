local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Resources = require(ReplicatedStorage:WaitForChild("Resources"))

local Registerable = require(script.Registerable)
local BuffAgent = Resources:LoadLibrary("AuraAgent")

local Aurora = {
	Auras = Registerable.new("Auras");
	Effects = Registerable.new("Effects");
}

local Agents = setmetatable({}, {
	__mode = "k";
	__index = function(self, instance)
		local agent = BuffAgent.new(instance, Aurora.Auras)
		self[instance] = agent
		return agent
	end
})

function Aurora.GetAgent(instance)
	return Agents[instance]
end

function Aurora.RegisterAurasIn(object)
	Aurora.Auras:LookIn(object)
end

function Aurora.RegisterEffectsIn(object)
	Aurora.Effects:LookIn(object)
end

spawn(function()
	while true do
		local dt = wait(0.5)

		for _, agent in pairs(Agents) do
			agent:Update(dt)
		end
	end
end)

Aurora.RegisterAurasIn(script.BuiltInAuras)
Aurora.RegisterAurasIn(script.BuiltInEffects)

return Aurora