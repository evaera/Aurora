return {
	Display = {
		Title = "Movement Speed";
		Description = function(self)
			return ("Reduces movement speed by %d%% for %d seconds.")
			:format(math.floor(self.Effects.TestEffectWalkSpeedMax(self) / 16 * 100), self.Duration)
		end;
	};

	Status = {
		Duration = 10;
		Replicated = true;
		ShouldAuraRefresh = true;
	};

	Params = {
		Speed = 10;
		Test = 59;
	};

	Effects = {
		TestEffect = true
	}
}