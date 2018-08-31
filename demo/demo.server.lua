local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Resources = require(ReplicatedStorage:WaitForChild("Resources"))
local Aurora = Resources:LoadLibrary("Aurora")

local function hookCharacter(character)
	character:WaitForChild("Humanoid")
	repeat wait() until character.Parent
	while character.Parent and character:FindFirstChild("Humanoid") do
		local humanoid = character.Humanoid
		local agent = Aurora.GetAgent(humanoid)

		wait(2)
		agent:Apply("Movement")
		print(agent:Has("Movement"))
		wait(2)
		agent:Remove("Movement")
	end
end

local function hookPlayer(player)
	player.CharacterAdded:Connect(hookCharacter)
	if player.Character then
		hookCharacter(player.Character)
	end
end

game.Players.PlayerAdded:Connect(hookPlayer)
for _, player in ipairs(game.Players:GetPlayers()) do
	hookPlayer(player)
end