return function()
	local Aurora = require(script.Parent)

	describe("Server Aurora", function()
		it("Should return the same agent for any given object", function()
			local agent1 = Aurora.GetAgent(workspace)
			local agent2 = Aurora.GetAgent(workspace)

			expect(agent1).to.equal(agent2)
		end)
	end)
end