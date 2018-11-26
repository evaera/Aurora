local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Resources = require(ReplicatedStorage:WaitForChild("Resources"))

local Registerable = require(script.Registerable)
local AuraAgent = Resources:LoadLibrary("AuraAgent")

local SyncEvent = Resources:GetRemoteEvent(".Aurora")
local SyncFunction = Resources:GetRemoteFunction(".Aurora")
local IsServer = RunService:IsServer()

local IsReady = false

-- Library

local Aurora = {
	Auras = Registerable.new("Auras");
	Effects = Registerable.new("Effects");
	TickRate = 0.5;
	SafeMemoryMode = true;
	MaxAgentTimeInactive = math.huge;
	SyncActionIndex = -1;
	InitialSyncCompleted = IsServer;
}

local Agents = setmetatable({}, {
	__mode = "k";
	__index = function(self, instance)
		local agent = AuraAgent.new(instance, Aurora.Auras, Aurora.Effects, IsServer and Aurora.SyncAction)
		self[instance] = agent
		return agent
	end
})

function Aurora.GetAgent(instance)
	local agent = Agents[instance]

	if not agent.Destroyed then
		return agent
	else
		Agents[instance] = nil
		return Agents[instance]
	end
end

local function warnIfTooLate()
	if IsReady then
		warn(
			"[Aurora] You are registering Auras/Effects too late. Please do not yield between your first require of Aurora"
			.. " and your register calls."
			)
	end
end

function Aurora.RegisterAurasIn(object)
	warnIfTooLate()
	Aurora.Auras:LookIn(object)
end

function Aurora.RegisterEffectsIn(object)
	warnIfTooLate()
	Aurora.Effects:LookIn(object)
end

function Aurora.SetTickRate(seconds)
	Aurora.TickRate = seconds
end

function Aurora.SetSafeMemoryMode(mode)
	Aurora.SafeMemoryMode = mode
end

function Aurora.SetMaxAgentTimeInactive(seconds)
	Aurora.MaxAgentTimeInactive = seconds
end

function Aurora.SyncAction(agent, method, ...)
	Aurora.SyncActionIndex = Aurora.SyncActionIndex + 1
	SyncEvent:FireAllClients({
		Type = "SyncAction";
		ActionIndex = Aurora.SyncActionIndex;
		Payload = {
			Instance = agent.Instance;
			Method = method;
			Args = {...}
		}
	})
end

--- Creates a snapshot of every agent's auras as they are in this moment
-- to be sent to a newly connected client (agents with no auras are excluded)
function Aurora.Serialize(filter)
	local snapshot = {}
	for instance, agent in pairs(Agents) do
		if agent.Destroyed then
			Agents[instance] = nil
		elseif agent.TimeInactive <= 0 then
			local agentSerialize = agent:Serialize(filter)

			snapshot[#snapshot + 1] = {
				Instance = instance;
				Auras = agentSerialize;
			}
		end

	end
	return snapshot
end

-- Register auras

Aurora.RegisterAurasIn(script.BuiltInAuras)
Aurora.RegisterEffectsIn(script.BuiltInEffects)

-- Event connections

if IsServer then
	local lastRequest = {}
	SyncFunction.OnServerInvoke = function (player)
		-- rate limit
		if lastRequest[player] and tick() - lastRequest[player] < 60 then
			return nil
		end
		lastRequest[player] = tick()

		return Aurora.Serialize(function(aura)
			return aura.Status.Replicated == true
		end)
	end
	game:GetService("Players").PlayerRemoving:Connect(function(player)
		lastRequest[player] = nil
	end)
end

-- Update loop

spawn(function()
	-- We delay setting up network stuff until after a cycle, to let the developer
	-- register their Auras
	if not IsServer then
		require(script.ClientNetwork)(Aurora)
	end

	IsReady = true

	while true do
		local dt = wait(Aurora.TickRate)

		for instance, agent in pairs(Agents) do
			if
				agent.TimeInactive > Aurora.MaxAgentTimeInactive
				or (
					Aurora.SafeMemoryMode == true
					and not agent.Destroyed
					and instance:IsDescendantOf(game) == false
				)
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

return Aurora