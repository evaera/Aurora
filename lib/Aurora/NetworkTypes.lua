local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Resources = require(ReplicatedStorage:WaitForChild("Resources"))
local t = Resources:LoadLibrary("t")

local T = {}

T.INetworkMessage = t.interface({
	Type = t.string;
	Payload = t.table;
	ActionIndex = t.number;
})

T.ISyncActionPayload = t.interface({
	Instance = t.Instance;
	Method = t.string;
	Args = t.table;
})

T.ISnapshotPayload = t.interface({
	Instance = t.Instance;
	Auras = t.map(t.string, t.interface({
		Status = t.keys(t.string);
		Params = t.optional(t.keys(t.string));
		Display = t.optional(t.keys(t.string));
		Effects = t.optional(t.keys(t.string));
	}))
})

T.ISnapshotDeep = t.array(T.ISnapshotPayload)
T.ISnapshotShallow = t.array(t.table)

return T
