local React = require(script.Parent.Parent.Parent:FindFirstChild('react'))

local DatePicker = require(script.Parent.Parent:FindFirstChild('Components'):FindFirstChild('DatePicker'))
local Label = require(script.Parent.Parent:FindFirstChild('Components'):FindFirstChild('Label'))
local createStory = require(script.Parent:FindFirstChild('Helpers'):FindFirstChild('createStory'))

local function Story()
	local date, setDate = React.useState(DateTime.now())

	return React.createElement(React.Fragment, {}, {
		Picker = React.createElement(DatePicker, {
			Date = date,
			OnChanged = setDate,
			LayoutOrder = 1,
		}),
		Display = React.createElement(Label, {
			LayoutOrder = 2,
			Size = UDim2.new(1, 0, 0, 20),
			Text = `Selected: {date:FormatUniversalTime("LL", "en-us")}`,
		}),
	})
end

return createStory(Story)
