--!nocheck

local React = require(script.Parent.Parent.Parent.Parent:FindFirstChild('react'))
local ReactRoblox = require(script.Parent.Parent.Parent.Parent:FindFirstChild('react-roblox'))

return {
	name = "StudioComponents",
	storyRoots = {
		script.Parent.Parent,
	},
	packages = {
		React = React,
		ReactRoblox = ReactRoblox,
	},
}
