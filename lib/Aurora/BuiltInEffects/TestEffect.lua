return {
	AllowedInstanceTypes = {"BoolValue"};

	Reducer = function (self, values)
		return #values
	end;

	Apply = function (self, name)
		self.Instance.Name = name
	end;

	Destructor = function (self)
		self.Instance.Name = "Destructed"
	end;
}