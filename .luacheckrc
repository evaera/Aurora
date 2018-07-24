stds.roblox = {
	read_globals = {
		-- Global objects
		"script",
		"game",
		"workspace",

		-- Global functions
		"spawn",
		"warn",
		"wait",
		"tick",
		"typeof",
		"settings",

		-- Global Namespaces
		"Enum",
		"debug",

		-- Global types
		"Instance",
		"Vector2",
		"Vector3",
		"CFrame",
		"Color3",
		"UDim",
		"UDim2",
		"Rect",
		"TweenInfo"
	}
}

stds.testez = {
	read_globals = {
		"describe",
		"it", "itFOCUS", "itSKIP",
		"FOCUS", "SKIP", "HACK_NO_XPCALL",
		"expect",
	}
}

std = "lua51+roblox"

files["**/*.spec.lua"] = {
	std = "+testez",
}