local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Resources = require(ReplicatedStorage:WaitForChild("Resources"))
local Debug = Resources:LoadLibrary("Debug")

local NetworkTypes = require(script.Parent.NetworkTypes)

local SyncEvent = Resources:GetRemoteEvent(".Aurora")
local SyncFunction = Resources:GetRemoteFunction(".Aurora")

return function (Aurora)
	-- AuroraClientNetwork
	local AuroraClientNetwork = {
		SyncActionIndex = -1;
		PendingSince = nil;
		ActionBuffer = {};
		Handlers = {}
	}

	-- Message buffer system ensures all messages arrive in order
	function AuroraClientNetwork.CheckBuffer()
		-- If a message is dropped somehow in transmission, skip it after waiting for 5 sec.
		if AuroraClientNetwork.PendingSince and tick() - AuroraClientNetwork.PendingSince > 5 then
			AuroraClientNetwork.SyncActionIndex = AuroraClientNetwork.SyncActionIndex + 1
			AuroraClientNetwork.PendingSince = tick()
		end

		local nextMessage = AuroraClientNetwork.ActionBuffer[AuroraClientNetwork.SyncActionIndex]


		if nextMessage then
			AuroraClientNetwork.SyncActionIndex = AuroraClientNetwork.SyncActionIndex + 1
			AuroraClientNetwork.Handlers[nextMessage.Type](nextMessage.Payload)
			AuroraClientNetwork.CheckBuffer()
		else
			AuroraClientNetwork.PendingSince = nil
		end
	end

	function AuroraClientNetwork.SyncEverything()
		local snapshot = SyncFunction:InvokeServer()
		assert(NetworkTypes.ISnapshotShallow(snapshot))

		print("Snapshot:", Debug.Inspect(snapshot))

		for _, agentPayload in pairs(snapshot) do
			local ok, warning = NetworkTypes.ISnapshotPayload(agentPayload)

			if ok then
				local agent = Aurora.GetAgent(agentPayload.Instance)

				agent.IncomingReplication = true
				agent.DisableHooks = true

				for auraName, props in pairs(agentPayload.Auras) do
					agent:Apply(auraName, props)
				end

				agent.DisableHooks = false
				agent.IncomingReplication = false
			else
				warn(warning) -- debug
			end
		end

		Aurora.InitialSyncCompleted = true
	end

	-- Handlers

	function AuroraClientNetwork.Handlers.SyncAction(payload)
		assert(NetworkTypes.ISyncActionPayload(payload))

		-- Replay same method call on client agent
		local agent = Aurora.GetAgent(payload.Instance)
		agent.IncomingReplication = true -- tell agent to skip client checks
		agent[payload.Method](agent, unpack(payload.Args))
		agent.IncomingReplication = false

		print("Playback: ", payload.Instance:GetFullName(), payload.Method, Debug.Inspect(payload.Args))
	end

	-- Event connections

	SyncEvent.OnClientEvent:Connect(function(data)
		assert(NetworkTypes.INetworkMessage(data))
		assert(AuroraClientNetwork.Handlers[data.Type] ~= nil)

		if AuroraClientNetwork.SyncActionIndex == -1 then
			AuroraClientNetwork.SyncActionIndex = data.ActionIndex
		end

		if not AuroraClientNetwork.PendingSince then
			AuroraClientNetwork.PendingSince = tick()
		end

		AuroraClientNetwork.ActionBuffer[data.ActionIndex] = data
		AuroraClientNetwork.CheckBuffer()
	end)

	-- Sync everything

	spawn(AuroraClientNetwork.SyncEverything)
end
