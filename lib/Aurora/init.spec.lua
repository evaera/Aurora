return function()
	local Aurora = require(script.Parent)

	describe("Server Aurora", function()
		it("Should return the same agent for any given object", function()
			local agent1 = Aurora.GetAgent(workspace)
			local agent2 = Aurora.GetAgent(workspace)

			expect(agent1).to.equal(agent2)
		end)

		itSKIP("Should not prevent garbage collection", function()

		end)
	end)
end