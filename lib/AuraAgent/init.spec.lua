return function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local Resources = require(ReplicatedStorage:WaitForChild("Resources"))

	local Auras = require(script.Parent.Parent.Aurora).Auras
	local AuraAgent = require(script.Parent)

	describe("AuraAgent:Apply", function()
		it("Should apply auras", function()
			local agent = AuraAgent.new(workspace, Auras)

			local success = agent:Apply("TestAuraStandard")

			expect(success).to.equal(true)
			expect(agent:Has("TestAuraStandard")).to.equal(true)
			expect(agent:Get("TestAuraStandard")).to.be.a("table")
			expect(agent:Get("TestAuraStandard"):Get("Duration")).to.equal(10)
		end)

		it("Should merge aura info with given props", function()
			local agent = AuraAgent.new(workspace, Auras)

			agent:Apply("TestAuraStandard", {
				Title = "Test Title";
				Description = function(self)
					return self:Get("Title") .. "!"
				end
			})

			local aura = agent:Get("TestAuraStandard")

			expect(aura:Get("Title")).to.equal("Test Title")
			expect(aura:Get("Description")).to.equal("Test Title!")
		end)

		it("Should fire the AuraAdded event", function()
			local agent = AuraAgent.new(workspace, Auras)

			spawn(function()
				agent:Apply("TestAuraStandard")
			end)

			local eventFired = false
			agent.AuraAdded:Connect(function(aura)
				eventFired = true
				expect(aura.Id).to.equal("TestAuraStandard")
			end)

			wait()

			expect(eventFired).to.be.ok()
		end)
	end)

	it("Should fire the AuraRemoved event", function()
		local agent = AuraAgent.new(workspace, Auras)
		agent:Apply("TestAuraStandard")

		local eventFired = false
		agent.AuraRemoved:Connect(function(aura)
			eventFired = true
			expect(aura.Id).to.equal("TestAuraStandard")
		end)

		agent:Remove("TestAuraStandard")

		wait()

		expect(eventFired).to.equal(true)
	end)

	it("Should refresh duration if re-applied", function()
		local agent = AuraAgent.new(workspace, Auras)
		agent:Apply("TestAuraStandard")
		local aura1 = agent:Get("TestAuraStandard")
		agent:Apply("TestAuraStandard")
		local aura2 = agent:Get("TestAuraStandard")

		expect(aura1).never.to.equal(aura2)
		expect(aura2.Stacks).to.equal(1)
	end)

	it("Should stack stackable auras", function()
		local agent = AuraAgent.new(workspace, Auras)
		agent:Apply("TestAuraStackable")
		agent:Apply("TestAuraStackable")
		agent:Apply("TestAuraStackable")

		expect(agent:Get("TestAuraStackable").Stacks).to.equal(3)
	end)

	it("Should fire the AuraStackAdded event", function()
		local agent = AuraAgent.new(workspace, Auras)

		local callCount = 0
		agent.AuraStackAdded:Connect(function(aura)
			callCount = callCount + 1
			expect(aura.Id).to.equal("TestAuraStackable")
			expect(aura.Stacks).to.equal(callCount + 1)
		end)

		agent:Apply("TestAuraStackable")
		agent:Apply("TestAuraStackable")
		agent:Apply("TestAuraStackable")

		wait()
		expect(callCount).to.equal(2)
	end)

	itSKIP("Should fire lifecycle hooks on the aura")
end