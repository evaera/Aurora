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
		Visible = true;
		Replicated = true;
		ShouldAuraRefresh = true;
		MaxStacks = 3;
	};

	Params = {
		Speed = 10;
	};
}