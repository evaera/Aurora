return {
	Title = "Movement Speed";
	Description = function(self)
		return ("Reduces movement speed by %d%% for %d seconds.")
			:format(math.floor(self.Effects.WalkSpeedMax(self) / 16 * 100), self.Duration)
	end;
	Duration = 10;
	Visible = true;
	Replicated = true;
	MaxStacks = 10;
	ShouldAuraRefresh = true;

	Effects = {
		WalkSpeedMax = function(self)
			return self:Get("Speed") or 10
		end
	}
}