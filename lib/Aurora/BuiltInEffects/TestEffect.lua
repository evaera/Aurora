return {
	AllowedInstanceTypes = {"BoolValue"};

	Reducer = function (self, values)
		self.Instance.Name = #values
	end;

	Destructor = function (self)
		self.Instance.Name = "Destructed"
	end;
}