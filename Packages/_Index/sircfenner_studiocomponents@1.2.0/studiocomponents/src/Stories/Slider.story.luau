local React = require(script.Parent.Parent.Parent:FindFirstChild('react'))

local Slider = require(script.Parent.Parent:FindFirstChild('Components'):FindFirstChild('Slider'))
local createStory = require(script.Parent:FindFirstChild('Helpers'):FindFirstChild('createStory'))

local function StoryItem(props: {
	LayoutOrder: number,
	Disabled: boolean?
})
	local value, setValue = React.useState(3)
	return React.createElement(Slider, {
		Value = value,
		Min = 0,
		Max = 10,
		Step = 0,
		OnChanged = setValue,
		Disabled = props.Disabled,
	})
end

local function Story()
	return React.createElement(React.Fragment, {}, {
		Enabled = React.createElement(StoryItem, {
			LayoutOrder = 1,
		}),
		Disabled = React.createElement(StoryItem, {
			LayoutOrder = 2,
			Disabled = true,
		}),
	})
end

return createStory(Story)
