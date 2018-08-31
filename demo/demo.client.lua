local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Resources = require(ReplicatedStorage:WaitForChild("Resources"))
local Aurora = Resources:LoadLibrary("Aurora")


local agent = Aurora.GetAgent(script.Parent:WaitForChild("Humanoid"))

while wait(1) do
	local auras = agent:GetAuras()
	print(#auras)
	for _, aura in pairs(auras) do
		print(aura.Display.Title)
	end
end