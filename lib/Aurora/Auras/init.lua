
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Resources = require(ReplicatedStorage:WaitForChild("Resources"))
local Immutable = Resources:LoadLibrary("Immutable")

local IsServer = RunService:IsServer()

local Auras = {
	Roots = {}
}

function Auras.LookIn(object)
	Auras.Roots[#Auras.Roots + 1] = object
end

local Buffs = setmetatable({}, {
	__index = function(self, i)
		-- Check in all roots
		-- If IsServer, also search for name.."Server" and apply that on top
		if script:FindFirstChild(i) then
			self[i] = Immutable.Lock(require(script[i]))

			return self[i]
		end
	end
})
return Buffs