return {
	AllowedInstanceTypes = {"Humanoid"};

	Reduce = function (self, values)
		local walkSpeed = math.huge

		for _, maxSpeed in ipairs(values) do
			if maxSpeed < walkSpeed then
				walkSpeed = maxSpeed
			end
		end

		self.Instance.WalkSpeed = walkSpeed
	end;

	Destructor = function (self)
		self.Instance.WalkSpeed = 16
	end;
}