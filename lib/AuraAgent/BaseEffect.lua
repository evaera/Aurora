-- Constructor
-- Reduce
-- Destructor

local Effect = {}
Effect.__index = Effect

function Effect.new(effectName, effectInfo)
	local self = {
		Name = effectName;
		Info = effectInfo;
	}
	setmetatable(self, Effect)

	self:Construct()

	return self
end

function Effect:Construct()
	if self.Info.Constructor then
		self.Info.Constructor(self) -- TODO: xpcall
	end
end

function Effect:Reduce(values)
	if self.Info.Reducer then
		self.Info.Reducer(self, values) -- TODO: xpcall
	end
end

function Effect:Destruct()
	if self.Info.Destructor then
		self.Info.Destructor(self) -- TODO: xpcall
	end
end

return Effect