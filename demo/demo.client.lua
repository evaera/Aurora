local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Resources = require(ReplicatedStorage:WaitForChild("Resources"))
local Aurora = Resources:LoadLibrary("Aurora")

-- local agent = Aurora.GetAgent(script.Parent:WaitForChild("Humanoid"))

wait(5)

local wAgent = Aurora.GetAgent(workspace)
print(wAgent:Get("TestAuraStackable").Params.Text)

while wait(1) do
	print(wAgent:Get("TestAuraStackable").Display.Title)
	-- local auras = agent:GetAuras()
	-- for _, aura in pairs(auras) do
	-- 	print(aura.Display.Title)
	-- end
end