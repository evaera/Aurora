return function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local Resources = require(ReplicatedStorage:WaitForChild("Resources"))

	local Buffs = Resources:LoadLibrary("Buffs")
	local BuffAgent = require(script.Parent.BuffAgent)

	describe("BuffAgent:Apply", function()
		it("Should apply buffs", function()
			local agent = BuffAgent.new(workspace, Buffs)

			local success = agent:Apply("TestBuffStandard")

			expect(success).to.equal(true)
			expect(agent:Has("TestBuffStandard")).to.equal(true)
			expect(agent:Get("TestBuffStandard")).to.be.a("table")
			expect(agent:Get("TestBuffStandard"):Get("Duration")).to.equal(10)
		end)

		it("Should merge buff info with given props", function()
			local agent = BuffAgent.new(workspace, Buffs)

			agent:Apply("TestBuffStandard", {
				Title = "Test Title";
				Description = function(self)
					return self:Get("Title") .. "!"
				end
			})

			local buff = agent:Get("TestBuffStandard")

			expect(buff:Get("Title")).to.equal("Test Title")
			expect(buff:Get("Description")).to.equal("Test Title!")
		end)

		it("Should fire the BuffAdded event", function()
			local agent = BuffAgent.new(workspace, Buffs)

			spawn(function()
				agent:Apply("TestBuffStandard")
			end)

			local eventFired = false
			agent.BuffAdded:Connect(function(buff)
				eventFired = true
				expect(buff.Id).to.equal("TestBuffStandard")
			end)

			wait()

			expect(eventFired).to.be.ok()
		end)
	end)

	it("Should fire the BuffRemoved event", function()
		local agent = BuffAgent.new(workspace, Buffs)
		agent:Apply("TestBuffStandard")

		local eventFired = false
		agent.BuffRemoved:Connect(function(buff)
			eventFired = true
			expect(buff.Id).to.equal("TestBuffStandard")
		end)

		agent:Remove("TestBuffStandard")

		wait()

		expect(eventFired).to.equal(true)
	end)

	it("Should refresh duration if re-applied", function()
		local agent = BuffAgent.new(workspace, Buffs)
		agent:Apply("TestBuffStandard")
		local buff1 = agent:Get("TestBuffStandard")
		agent:Apply("TestBuffStandard")
		local buff2 = agent:Get("TestBuffStandard")

		expect(buff1).never.to.equal(buff2)
		expect(buff2.Stacks).to.equal(1)
	end)

	it("Should stack stackable buffs", function()
		local agent = BuffAgent.new(workspace, Buffs)
		agent:Apply("TestBuffStackable")
		agent:Apply("TestBuffStackable")
		agent:Apply("TestBuffStackable")

		expect(agent:Get("TestBuffStackable").Stacks).to.equal(3)
	end)

	it("Should fire the BuffStackAdded event", function()
		local agent = BuffAgent.new(workspace, Buffs)

		local callCount = 0
		agent.BuffStackAdded:Connect(function(buff)
			callCount = callCount + 1
			expect(buff.Id).to.equal("TestBuffStackable")
			expect(buff.Stacks).to.equal(callCount + 1)
		end)

		agent:Apply("TestBuffStackable")
		agent:Apply("TestBuffStackable")
		agent:Apply("TestBuffStackable")

		wait()
		expect(callCount).to.equal(2)
	end)

	itSKIP("Should fire lifecycle hooks on the buff")
end