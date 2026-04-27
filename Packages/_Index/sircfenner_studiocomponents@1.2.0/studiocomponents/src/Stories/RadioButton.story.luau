local React = require(script.Parent.Parent.Parent:FindFirstChild('react'))

local RadioButton = require(script.Parent.Parent:FindFirstChild('Components'):FindFirstChild('RadioButton'))
local createStory = require(script.Parent:FindFirstChild('Helpers'):FindFirstChild('createStory'))

local function Story()
	local value, setValue = React.useState(true)

	return React.createElement(React.Fragment, {}, {
		Enabled = React.createElement(RadioButton, {
			Label = "Enabled",
			Value = value,
			OnChanged = function()
				setValue(not value)
			end,
			LayoutOrder = 1,
		}),
		Disabled = React.createElement(RadioButton, {
			Label = "Disabled",
			Value = value,
			Disabled = true,
			LayoutOrder = 2,
		}),
	})
end

return createStory(Story)
