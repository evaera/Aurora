local t = require(script.Parent.t)

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

T.ISerializePayload = t.interface({
	Instance = t.Instance;
	Auras = t.map(t.string, t.interface({
		Status = t.keys(t.string);
		Params = t.optional(t.keys(t.string));
		Display = t.optional(t.keys(t.string));
		Config = t.optional(t.keys(t.string));
		Effects = t.optional(t.keys(t.string));
	}))
})

T.ISerializeDeep = t.array(T.ISerializePayload)
T.ISerializeShallow = t.array(t.table)

return T
