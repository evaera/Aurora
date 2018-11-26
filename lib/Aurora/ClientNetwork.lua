local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Resources = require(ReplicatedStorage:WaitForChild("Resources"))
local Debug = Resources:LoadLibrary("Debug")

local NetworkTypes = require(script.Parent.NetworkTypes)

local SyncEvent = Resources:GetRemoteEvent(".Aurora")
local SyncFunction = Resources:GetRemoteFunction(".Aurora")

local DEBUG = false

local function dprint(...)
	if DEBUG then
		print(...)
	end
end

return function (Aurora)
	local AuroraClientNetwork = {
		Handlers = {}
	}

	--[[
		Possible bug: Client may receive mirrored updates from before it requests the snapshot.
		All mirrored changes are played back after the update.
		May need to add mechanism to add timestamp to snapshot and all mirrors.
		Discard any mirror data sent before the snapshot timestamp.
	]]

	function AuroraClientNetwork.SyncEverything()
		local snapshot = SyncFunction:InvokeServer()
		assert(NetworkTypes.ISnapshotShallow(snapshot))

		dprint("Snapshot:", Debug.Inspect(snapshot))

		for _, agentPayload in pairs(snapshot) do
			local ok, warning = NetworkTypes.ISnapshotPayload(agentPayload)

			if ok then
				local agent = Aurora.GetAgent(agentPayload.Instance)

				agent.IncomingReplication = true
				agent:ApplySnapshot(agentPayload.Auras)
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
		agent.IncomingReplication = true -- tell agent to set Remote
		agent[payload.Method](agent, unpack(payload.Args))
		agent.IncomingReplication = false

		dprint("Playback: ", payload.Instance:GetFullName(), payload.Method, Debug.Inspect(payload.Args))
	end

	-- Sync everything *BEFORE* connecting event listener, so they can queue.

	AuroraClientNetwork.SyncEverything()

	-- Event connections

	SyncEvent.OnClientEvent:Connect(function(data)
		assert(NetworkTypes.INetworkMessage(data))
		assert(AuroraClientNetwork.Handlers[data.Type] ~= nil)

		AuroraClientNetwork.Handlers[data.Type](data.Payload)
	end)
end
