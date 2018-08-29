local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Resources = require(ReplicatedStorage:WaitForChild("Resources"))

local Registerable = require(script.Registerable)
local BuffAgent = Resources:LoadLibrary("AuraAgent")

local Aurora = {
	Auras = Registerable.new("Auras");
	Effects = Registerable.new("Effects");
	TickRate = 0.5;
	SafeMemoryMode = true;
}

local Agents = setmetatable({}, {
	__mode = "k";
	__index = function(self, instance)
		local agent = BuffAgent.new(instance, Aurora.Auras, Aurora.Effects)
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

function Aurora.SetTickRate(seconds)
	Aurora.TickRate = seconds
end

spawn(function()
	while true do
		local dt = wait(Aurora.TickRate)

		for instance, agent in pairs(Agents) do
			if
				Aurora.SafeMemoryMode
				and not agent.Destroyed
				and instance:IsDescendantOf(game) == false
			then
				-- dump agents referring to instances that are not parented to the game tree
				agent:Destroy()
				Agents[instance] = nil
			elseif agent.Destroyed then
				-- agent was destroyed externally
				Agents[instance] = nil
			else
				agent:Update(dt)
			end
		end
	end
end)

Aurora.RegisterAurasIn(script.BuiltInAuras)
Aurora.RegisterEffectsIn(script.BuiltInEffects)

return Aurora