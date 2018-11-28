return {
	AllowedInstanceTypes = {"NumberValue"};

	Reducer = function (_, values)
		return #values
	end;

	Apply = function (self, name)
		self.Instance.Name = name
		self.Instance.Value = tick()
	end;

	Destructor = function (self)
		self.Instance.Name = "Destructed"
	end;
}