local plugin: Plugin = plugin or getfenv().PluginManager():CreatePlugin()

local RunService: RunService = game:GetService("RunService")
local StudioService: StudioService = game:GetService("StudioService")

if not (RunService:IsStudio() and RunService:IsEdit()) then
	return
end

local Folder = script.Parent

local Packages = Folder:WaitForChild("Packages")
local Interface = Folder:WaitForChild("Interface")
local Util: Folder = Folder:WaitForChild("Util")

local PNG = require(Packages:WaitForChild("png"))
local StudioComponents = require(Packages:WaitForChild("studiocomponents"))
local React = require(Packages:WaitForChild("react"))

local CreateWidget = require(Util:WaitForChild("CreateWidget"))

local Toolbar: PluginToolbar = plugin:CreateToolbar("Photo2Parts")
local ToolbarButton: PluginToolbarButton = Toolbar:CreateButton("Photo2Parts", "Show or hide Photo2Parts", "rbxasset://textures/ui/SelectionBox@2x.png")

local WidgetSize: {} = {400, 200}

local CustomDecalsWidget = CreateWidget(plugin, "Custom Decals", WidgetSize, Interface["Custom Decals"], function(WidgetObject)
	local Frame = WidgetObject.Frame
	local Button = Frame.Button
	
	Button.MouseButton1Click:Connect(function()
		local ImageFile = StudioService:PromptImportFileAsync({"png"})
		
		if ImageFile then
			local Binary = ImageFile:GetBinaryContents()
			local Image = PNG.new(Binary)
			
			local Width = Image["Width"]
			local Height = Image["Height"]
				
			local Model: Model = Instance.new("Model")		
			
			Model.Name = string.split(ImageFile.Name, '.')[1]
			Model.Parent = game.Workspace

			for X = 1, Width do
				for Y = 1, Height do					
					local Color, Alpha = Image:GetPixel(X, Y)
					local Part: Part = Instance.new("Part")

					if Alpha > 0 then						
						Part.Transparency = 1 - (Alpha / 255)
						Part.Color = Color				
						Part.Material = Enum.Material.SmoothPlastic
						Part.Size = Vector3.new(5, 5, 5)
						Part.Position = Vector3.new(X * 5, 5, Y * 5)
						Part.Anchored = true
						Part.Parent = Model
					else
						Part:Destroy()
					end
				end
			end
		end
	end)
end)

ToolbarButton.Click:Connect(function()
	CustomDecalsWidget.Enabled = not CustomDecalsWidget.Enabled
end)
