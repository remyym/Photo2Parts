local React = require(script.Parent.Parent.Parent:FindFirstChild('react'))

local LoadingDots = require(script.Parent.Parent:FindFirstChild('Components'):FindFirstChild('LoadingDots'))
local createStory = require(script.Parent:FindFirstChild('Helpers'):FindFirstChild('createStory'))

local function Story()
	return React.createElement(LoadingDots, {})
end

return createStory(Story)
