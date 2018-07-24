return function()
	local Debuffer = require(script.Parent.Debuffer)

	describe("Server Debuffer", function()
		it("Should return the same agent for any given object", function()
			local agent1 = Debuffer.GetAgent(workspace)
			local agent2 = Debuffer.GetAgent(workspace)

			expect(agent1).to.equal(agent2)
		end)
	end)
end