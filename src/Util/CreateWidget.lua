local function CreateWidget(plugin, name, size, panel, func): DockWidgetPluginGui
	local Width, Height = size[1], size[2]

	local WidgetObject: DockWidgetPluginGui = plugin:CreateDockWidgetPluginGui(name, DockWidgetPluginGuiInfo.new(
		Enum.InitialDockState.Float,
		false,
		false,
		Width,
		Height,
		Width,
		Height
		))

	WidgetObject.Title = name
	WidgetObject.Enabled = false

	panel.Frame:Clone().Parent = WidgetObject

	func(WidgetObject)

	return WidgetObject
end

return CreateWidget
