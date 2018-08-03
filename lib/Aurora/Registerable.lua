
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Resources = require(ReplicatedStorage:WaitForChild("Resources"))
local Immutable = Resources:LoadLibrary("Immutable")

local IsServer = RunService:IsServer()

local Registerable = {}
Registerable.__index = Registerable

local Caches = setmetatable({}, { __mode = "k" })

function Registerable.new(name)
	local self = {
		Name = name;
		Roots = {};
	}
	setmetatable(self, Registerable)

	Caches[self] = {}

	return self
end

function Registerable:LookIn(object)
	self.Roots[#self.Roots + 1] = object
end

function Registerable:Find(name, skipServerCheck)
	if Caches[self][name] then
		return Caches[self][name]
	end

	local serverEquiv
	if IsServer and not skipServerCheck then
		serverEquiv = self:Find(name .. "Server", true)
	end

	for _, root in ipairs(self.Roots) do
		local code = root:FindFirstChild(name)
		if code then
			local module = require(code)

			if serverEquiv then
				for key, value in pairs(serverEquiv) do
					module[key] = value
				end
			end

			Caches[self][name] = Immutable.Lock(module)
			return Caches[self][name]
		end
	end
end

return Registerable