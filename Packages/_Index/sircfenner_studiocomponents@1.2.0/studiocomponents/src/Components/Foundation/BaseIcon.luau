local React = require(script.Parent.Parent.Parent.Parent:FindFirstChild('react'))

local CommonProps = require(script.Parent.Parent.Parent:FindFirstChild('CommonProps'))

export type BaseIconConsumerProps = CommonProps.T & {
	Image: string,
	Transparency: number?,
	Color: Color3?,
	ResampleMode: Enum.ResamplerMode?,
	RectOffset: Vector2?,
	RectSize: Vector2?
}

export type BaseIconProps = BaseIconConsumerProps

local function BaseIcon(props: BaseIconProps)
	return React.createElement("ImageLabel", {
		Size = props.Size,
		Position = props.Position,
		AnchorPoint = props.AnchorPoint,
		LayoutOrder = props.LayoutOrder,
		ZIndex = props.ZIndex,
		BackgroundTransparency = 1,
		Image = props.Image,
		ImageColor3 = props.Color,
		ImageTransparency = 1 - (1 - (props.Transparency or 0)) * (1 - if props.Disabled then 0.2 else 0),
		ImageRectOffset = props.RectOffset,
		ImageRectSize = props.RectSize,
		ResampleMode = props.ResampleMode,
	})
end

return BaseIcon
