return {
	AllowedInstanceTypes = {"Humanoid", "NumberValue"};

	Reducer = function (_, values)
		local walkSpeed = math.huge

		for _, maxSpeed in ipairs(values) do
			if maxSpeed < walkSpeed then
				walkSpeed = maxSpeed
			end
		end

		return walkSpeed
	end;

	Apply = function (self, value)
		if self.Instance:IsA("NumberValue") then
			self.Instance.Value = value
		else
			self.Instance.WalkSpeed = value
		end
	end;

	Destructor = function (self)
		if self.Instance:IsA("NumberValue") then
			self.Instance.Value = 16
		else
			self.Instance.WalkSpeed = 16
		end
	end;
}