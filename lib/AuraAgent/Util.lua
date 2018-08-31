local Util = {}

--- Returns value if it is not nil, otherwise defaultValue
function Util.Default(value, defaultValue)
	if value == nil then
		return defaultValue
	end
	return value
end

--- Deep copies a table that may have functions, runs the functions passing
-- `self` to them, and returns a matching table with only static values
-- acquired from the return values (letting non-function values pass through)
-- Optionally takes keys from a table as third parameter and fetches values from
-- the original table for those keys; this works with the "structure" tables found
-- in the other project files. This is because shadowed sections are not iterable.
function Util.Staticize(self, t, structure)
	local s = {}

	for key in pairs(structure or t) do
		local value = t[key]
		if type(value) == "function" then
			s[key] = value(self)
		elseif type(value) == "table" then
			s[key] = Util.Staticize(self, value, structure and structure[key])
		else
			s[key] = value
		end
	end

	return s
end

return Util