local plugin: Plugin = plugin or getfenv().PluginManager():CreatePlugin()

local RunService = game:GetService("RunService")
local Selection = game:GetService("Selection")
local StudioService = game:GetService("StudioService")

if not (RunService:IsStudio() and RunService:IsEdit()) then
	return
end

local RootFolder = script.Parent
local Packages = RootFolder:WaitForChild("Packages")

local React = require(Packages:WaitForChild("react"))
local ReactRoblox = require(Packages:WaitForChild("react-roblox"))

local StudioComponents = require(Packages:WaitForChild("studiocomponents"))
local PNG = require(Packages:WaitForChild("png"))

local App = require(RootFolder:WaitForChild("UI"):WaitForChild("App"))

local toolbar = plugin:CreateToolbar("Photo2Parts")
local toolbarButton =
	toolbar:CreateButton("Photo2Parts", "Show or hide Photo2Parts", "rbxasset://textures/ui/SelectionBox@2x.png")

local widget = plugin:CreateDockWidgetPluginGuiAsync(
	"Photo2Parts",
	DockWidgetPluginGuiInfo.new(Enum.InitialDockState.Float, false, false, 460, 680, 360, 420)
)
widget.Title = "Photo2Parts"
widget.Name = "Photo2Parts"
widget.Enabled = false

local element = React.createElement(StudioComponents.PluginProvider, {
	Plugin = plugin,
}, {
	App = React.createElement(App, {
		Plugin = plugin,
		Selection = Selection,
		StudioService = StudioService,
		PNG = PNG,
	}),
})

local root = ReactRoblox.createRoot(Instance.new("Folder"))
root:render(ReactRoblox.createPortal(element, widget))

toolbarButton.Click:Connect(function()
	widget.Enabled = not widget.Enabled
end)

plugin.Unloading:Connect(function()
	root:unmount()
end)
