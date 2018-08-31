return function()
	local Util = require(script.Parent.Util)

	describe("Default", function()
		it("Should return a default value", function()
			expect(Util.Default(1, 2)).to.equal(1)
			expect(Util.Default(false, 2)).to.equal(false)
			expect(Util.Default(nil, 2)).to.equal(2)
		end)
	end)

	describe("Staticize", function()
		it("Should make table with functions static", function()
			local t = {
				value = function(v)
					expect(v).to.equal(5)
					return "returnvalue"
				end;

				innerTable = {
					value = function(v)
						expect(v).to.equal(5)
						return "returnvalue2"
					end;
					passThrough = 8;
				};

				passThrough = 7;
			}

			local s = Util.Staticize(5, t)

			expect(s).to.be.a("table")
			expect(s.value).to.equal("returnvalue")
			expect(s.innerTable).to.be.a("table")
			expect(s.innerTable.value).to.equal("returnvalue2")
			expect(s.passThrough).to.equal(7)
			expect(s.innerTable.passThrough).to.equal(8)
		end)

		it("Should use another table's keys if provided", function()
			local t = {
				a = true;
				b = true;
				c = {
					d = true;
				}
			}
			local v = setmetatable({}, {
				__index = {
					a = 1;
					b = 2;
					c = {
						d = 3;
					}
				}
			})
			local s = Util.Staticize(nil, v, t)

			expect(s).to.be.a("table")
			expect(s.a).to.equal(1)
			expect(s.b).to.equal(2)
			expect(s.c).to.be.a("table")
			expect(s.c.d).to.equal(3)
		end)
	end)
end