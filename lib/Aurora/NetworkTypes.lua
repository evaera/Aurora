local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Resources = require(ReplicatedStorage:WaitForChild("Resources"))
local t = Resources:LoadLibrary("t")

return {
	INetworkMessage = t.interface({
		Type = t.string;
		Payload = t.table;
		ActionIndex = t.number;
	});

	ISyncActionPayload = t.interface({
		Instance = t.Instance;
		Method = t.string;
		Args = t.table;
	})
}