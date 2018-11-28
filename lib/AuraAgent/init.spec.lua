return function()
	local Auras = require(script.Parent.Parent).Auras
	local Effects = require(script.Parent.Parent).Effects
	local AuraAgent = require(script.Parent)

	local testValue = Instance.new("NumberValue", workspace)
	local testValue2 = Instance.new("NumberValue", workspace)

	describe("AuraAgent:Apply", function()
		it("Should apply auras", function()
			local agent = AuraAgent.new(testValue, Auras, Effects)

			local success = agent:Apply("TestAuraStandard")

			expect(success).to.equal(true)
			expect(agent:Has("TestAuraStandard")).to.equal(true)
			expect(agent:Get("TestAuraStandard")).to.be.a("table")
			expect(agent:Get("TestAuraStandard").Status.Duration).to.equal(10)
			expect(agent:Get("TestAuraStandard").Id).to.equal("TestAuraStandard")
			expect(agent:Get("TestAuraStandard").Name).to.equal("TestAuraStandard")
		end)

		it("Should allow inline auras", function()
			local agent = AuraAgent.new(testValue, Auras, Effects)

			agent:Apply(":CustomInline", ":CustomInline2")
			agent:Apply(":InlineWithEffect", {
				Effects = {
					TestEffect = true;
				}
			})

			agent:ReifyEffects()

			expect(agent:Has(":CustomInline")).to.equal(true)
			expect(agent:HasEffect("TestEffect")).to.equal(true)
			expect(agent:Get(":InlineWithEffect").Id).to.equal("_AuroraInlineAura")
		end)

		it("Should merge aura info with given props", function()
			local agent = AuraAgent.new(testValue, Auras, Effects)

			agent:Apply("TestAuraStandard", {
				Display = {
					Title = "Test Title";
					Description = function(self)
						return self.Display.Title .. "!"
					end
				};
				Status = {
					Duration = math.huge;
				};
				Config = {
					Visible = false;
				};
				Params = {
					Speed = 11;
				}
			})

			local aura = agent:Get("TestAuraStandard")

			expect(aura.Display.Title).to.equal("Test Title")
			expect(aura.Display.Description).to.equal("Test Title!")
			expect(aura.Status.Duration).to.equal(math.huge)
			expect(aura.Config.Visible).to.equal(false)
			expect(aura.Params.Speed).to.equal(11)
			expect(aura.Params.Test).to.equal(59)
		end)

		it("Should error with unknown props keys", function()
			local agent = AuraAgent.new(testValue, Auras, Effects)

			expect(function()
				agent:Apply("TestAuraStandard", {
					Display = {
						Title = "Test Title";
						Description = function(self)
							return self.Display.Title .. "!"
						end
					};
					invalid = true;
				})
			end).to.throw()
		end)

		it("Should fire the AuraAdded event and hook", function()
			local agent = AuraAgent.new(testValue, Auras, Effects)

			local hookCalled = false
			spawn(function()
				agent:Apply("TestAuraStandard", {
					Hooks = {
						AuraAdded = function()
							hookCalled = true
						end
					}
				})
			end)

			local eventFired = false
			agent.AuraAdded:Connect(function(aura)
				eventFired = true
				expect(aura.Id).to.equal("TestAuraStandard")
			end)

			wait()

			expect(eventFired).to.equal(true)
			expect(hookCalled).to.equal(true)
		end)

		it("Should refresh duration if re-applied", function()
			local agent = AuraAgent.new(testValue, Auras, Effects)
			agent:Apply("TestAuraStandard")
			local aura1 = agent:Get("TestAuraStandard")
			agent:Apply("TestAuraStandard")
			local aura2 = agent:Get("TestAuraStandard")

			expect(aura1).never.to.equal(aura2)
			expect(aura2.Status.Stacks).to.equal(1)
		end)

		it("Should stack stackable auras", function()
			local agent = AuraAgent.new(testValue, Auras, Effects)
			agent:Apply("TestAuraStackable")
			agent:Apply("TestAuraStackable")
			agent:Apply("TestAuraStackable")
			agent:Apply("TestAuraStackable")

			expect(agent:Get("TestAuraStackable").Status.Stacks).to.equal(3)
		end)

		it("Should fire the AuraStackAdded event", function()
			local agent = AuraAgent.new(testValue, Auras, Effects)

			local callCount = 0
			agent.AuraStackAdded:Connect(function(aura)
				callCount = callCount + 1
				expect(aura.Id).to.equal("TestAuraStackable")
				expect(aura.Status.Stacks).to.equal(callCount + 1)
			end)

			agent:Apply("TestAuraStackable")
			agent:Apply("TestAuraStackable")
			agent:Apply("TestAuraStackable")

			wait()
			expect(callCount).to.equal(2)
		end)

	end)

	it("Should fire the AuraRemoved event and hook", function()
		local agent = AuraAgent.new(testValue, Auras, Effects)
		local hookCalled = false
		agent:Apply("TestAuraStandard", {
			Hooks = {
				AuraRemoved = function()
					hookCalled = true
				end
			}
		})

		local eventFired = false
		agent.AuraRemoved:Connect(function(aura)
			eventFired = true
			expect(aura.Id).to.equal("TestAuraStandard")
		end)

		expect(agent:Remove("TestAuraStandard")).to.equal(true)
		expect(agent:Remove("TestAuraStandard")).to.equal(false)

		wait()

		expect(eventFired).to.equal(true)
		expect(hookCalled).to.equal(true)
	end)

	it("Should fire AuraStackRemoved when consumed", function()
		local agent = AuraAgent.new(testValue, Auras, Effects)
		local timesStackRemovedHook = 0
		local timesRemovedHook = 0
		agent:Apply("TestAuraStackable")
		agent:Apply("TestAuraStackable", { Hooks = {
			AuraStackRemoved = function ()
				timesStackRemovedHook = timesStackRemovedHook + 1
			end;
			AuraRemoved = function ()
				timesRemovedHook = timesRemovedHook + 1
			end;
		}})

		local timesStackRemovedFired = 0
		local timesRemovedFired = 0

		agent.AuraStackRemoved:Connect(function(aura)
			timesStackRemovedFired = timesStackRemovedFired + 1
			expect(aura.Id).to.equal("TestAuraStackable")
		end)

		agent.AuraRemoved:Connect(function(aura)
			timesRemovedFired = timesRemovedFired + 1
			expect(aura.Id).to.equal("TestAuraStackable")
		end)

		expect(agent:Consume("TestAuraStackable")).to.equal(true)
		expect(agent:Consume("TestAuraStackable")).to.equal(true)
		expect(agent:Consume("TestAuraStackable")).to.equal(false)

		wait()

		expect(timesStackRemovedHook).to.equal(2)
		expect(timesRemovedHook).to.equal(1)
		expect(timesStackRemovedFired).to.equal(2)
		expect(timesRemovedFired).to.equal(1)
	end)

	describe("Custom names", function()
		it("Should work with custom Aura names", function()
			local agent = AuraAgent.new(testValue, Auras, Effects)

			agent:Apply("TestAuraStandard")
			agent:Apply("TestAuraStandard", { Name = ":n1" })
			agent:Apply("TestAuraStandard", { Name = ":n2" })

			expect(agent:Has("TestAuraStandard")).to.equal(true)
			expect(agent:Has(":n1")).to.equal(true)
			expect(agent:Has(":n2")).to.equal(true)
			expect(agent:Get(":n2").Name).to.equal(":n2")
			expect(agent:Get(":n2").Id).to.equal("TestAuraStandard")

			agent:Remove(":n1")

			expect(agent:Has("TestAuraStandard")).to.equal(true)
			expect(agent:Has(":n1")).to.equal(false)
			expect(agent:Has(":n2")).to.equal(true)
		end)

		it("Should disallow distinct Auras having the same custom name", function()
			local agent = AuraAgent.new(testValue, Auras, Effects)

			expect(function()
				agent:Apply("TestAuraStandard", { Name = ":name" })
				agent:Apply("TestAuraStackable", { Name = ":name" })
			end).to.throw()

			local agent2 = AuraAgent.new(testValue, Auras, Effects)

			expect(function()
				agent2:Apply("TestAuraStackable", { Name = ":name" })
				agent2:Apply("TestAuraStackable", { Name = ":name" })

				expect(agent2:Get(":name").Status.Stacks).to.equal(2)
			end).never.to.throw()
		end)
	end)

	describe("AuraAgent:Update", function()
		local testObject = Instance.new("NumberValue", game.TestService)

		it("Should update auras when Update is called", function()
			local agent = AuraAgent.new(testObject, Auras, Effects)

			local success = agent:Apply("TestAuraStandard")

			agent:ReifyEffects()

			expect(agent:Get("TestAuraStandard").Status.TimeLeft).to.equal(10)
			expect(agent:GetLastReducedValue("TestEffect")).to.equal(1)

			agent:Update(0.2)

			expect(success).to.equal(true)
			expect(agent:Has("TestAuraStandard")).to.equal(true)
			expect(agent:HasEffect("TestEffect")).to.equal(true) -- Test HasEffect
			expect(agent:GetLastReducedValue("TestEffect")).to.equal(1)
			expect(agent:HasEffect("TestEffectPrintReduce")).to.equal(false)
			expect(agent:Get("TestAuraStandard")).to.be.a("table")
			expect(agent:Get("TestAuraStandard").Status.TimeLeft).to.equal(9.8)
			expect(agent:Get("TestAuraStandard").Status.Duration).to.equal(10)
			expect(testObject.Name).to.equal("1")
		end)

		it("Should skip lazy effects when there's no change", function()
			local agent = AuraAgent.new(testObject, Auras, Effects)

			agent:Apply("TestAuraStandard")

			agent:Update(0.2)

			local value = testObject.Value

			agent:Update(0.2)
			agent:Update(0.2)
			agent:Update(0.2)

			expect(value).to.equal(testObject.Value)
		end)
	end)

	describe("Transfer & Copy", function()
		it("Should copy Auras from one agent to another", function()
			local agent = AuraAgent.new(testValue, Auras, Effects)
			local agent2 = AuraAgent.new(testValue2, Auras, Effects)

			agent:Apply("TestAuraStandard", ":one")
			agent:Apply("TestAuraStackable", ":two")

			agent:CopyAurasTo(agent2, function(aura)
				return aura.Name == ":one"
			end)

			expect(agent:Has(":one")).to.equal(true)
			expect(agent:Has(":two")).to.equal(true)
			expect(agent2:Has(":one")).to.equal(true)
			expect(agent2:Has(":two")).to.equal(false)
		end)

		it("Should transfer Auras from one agent to another", function()
			local agent = AuraAgent.new(testValue, Auras, Effects)
			local agent2 = AuraAgent.new(testValue2, Auras, Effects)

			agent:Apply("TestAuraStandard", ":one")
			agent:Apply("TestAuraStackable", ":two")

			agent:TransferAurasTo(agent2, function(aura)
				return aura.Name == ":one"
			end)

			expect(agent:Has(":one")).to.equal(false)
			expect(agent:Has(":two")).to.equal(true)
			expect(agent2:Has(":one")).to.equal(true)
			expect(agent2:Has(":two")).to.equal(false)
		end)
	end)
end