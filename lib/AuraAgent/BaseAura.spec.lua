return function()
	local Aura = require(script.Parent.BaseAura)
	local Auras = require(script.Parent.Parent).Auras

	describe("Serialize", function()
		it("Should send minimal snapshot with no props", function()
			local aura = Aura.new("TestAuraStandard", Auras:Find("TestAuraStandard"), {})

			aura.Status.TimeLeft = 9.8

			local snapshot = aura:Serialize()

			expect(snapshot.Status).to.be.ok()
			expect(snapshot.Status.TimeLeft).to.equal(9.8)
			expect(snapshot.Status.Stacks).to.equal(1)
			expect(snapshot.Effects).to.never.be.ok()
			expect(snapshot.Display).to.never.be.ok()
			expect(snapshot.Hooks).to.never.be.ok()
			expect(snapshot.Params).to.never.be.ok()
		end)

		it("Should work with props", function()
			local aura = Aura.new("TestAuraStandard", Auras:Find("TestAuraStandard"), {
				Params = {
					SomeVar = 4;
				};
				Display = {
					Title = "An Aura";
				}
			})

			local snapshot = aura:Serialize()

			expect(snapshot.Status).to.be.ok()
			expect(snapshot.Effects).to.never.be.ok()
			expect(snapshot.Display).to.be.ok()
			expect(snapshot.Display.Title).to.equal("An Aura")
			expect(snapshot.Hooks).to.never.be.ok()
			expect(snapshot.Params).to.be.ok()
			expect(snapshot.Params.SomeVar).to.equal(4)
		end)

		it("Should work with Effect prop", function()
			local aura = Aura.new("TestAuraStandard", Auras:Find("TestAuraStandard"), {
				Effects = {}
			})

			local snapshot = aura:Serialize()

			expect(next(aura.Effects)).to.never.be.ok()
			expect(snapshot.Effects).to.be.ok()
			expect(next(snapshot.Effects)).to.never.be.ok()
		end)
	end)
end