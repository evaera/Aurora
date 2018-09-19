return {
	AllowedInstanceTypes = {"Humanoid"};

	Reducer = function (self, values)
		local walkSpeed = math.huge

		for _, maxSpeed in ipairs(values) do
			if maxSpeed < walkSpeed then
				walkSpeed = maxSpeed
			end
		end

		return walkSpeed
	end;

	Apply = function (self, value)
		self.Instance.WalkSpeed = value
	end;

	Destructor = function (self)
		self.Instance.WalkSpeed = 16
	end;
}