local RootFolder = script.Parent.Parent
local Packages = RootFolder:WaitForChild("Packages")

local React = require(Packages:WaitForChild("react"))
local StudioComponents = require(Packages:WaitForChild("studiocomponents"))

local Settings = require(RootFolder:WaitForChild("Generation"):WaitForChild("Settings"))
local ImageSampler = require(RootFolder:WaitForChild("Generation"):WaitForChild("ImageSampler"))
local PartPlanner = require(RootFolder:WaitForChild("Generation"):WaitForChild("PartPlanner"))
local PartBuilder = require(RootFolder:WaitForChild("Generation"):WaitForChild("PartBuilder"))

local ROW_HEIGHT = 28

local function optionItems(values)
	local items = {}
	for _, value in values do
		table.insert(items, if type(value) == "table" then value else tostring(value))
	end
	return items
end

local materialItems = optionItems(Settings.Materials)

local function mergeSetting(settings, key, value)
	local nextSettings = table.clone(settings)
	nextSettings[key] = value
	return nextSettings
end

local function row(label, order, child)
	return React.createElement("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, ROW_HEIGHT),
		LayoutOrder = order,
	}, {
		Label = React.createElement(StudioComponents.Label, {
			Text = label,
			Size = UDim2.new(0.42, -6, 1, 0),
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
		}),
		Input = React.createElement("Frame", {
			BackgroundTransparency = 1,
			Position = UDim2.fromScale(0.42, 0),
			Size = UDim2.fromScale(0.58, 1),
		}, {
			child,
		}),
	})
end

local function numericRow(label, order, settings, setSettings, key, props)
	props = props or {}
	return row(label, order, React.createElement(StudioComponents.NumericInput, {
		Value = settings[key],
		Min = props.Min,
		Max = props.Max,
		Step = props.Step or 1,
		Arrows = props.Arrows ~= false,
		Slider = props.Slider == true,
		Size = UDim2.new(1, 0, 0, 22),
		OnValidChanged = function(value)
			setSettings(mergeSetting(settings, key, value))
		end,
	}))
end

local function textRow(label, order, settings, setSettings, key)
	return row(label, order, React.createElement(StudioComponents.TextInput, {
		Text = settings[key],
		Size = UDim2.new(1, 0, 0, 22),
		ClearTextOnFocus = false,
		OnChanged = function(value)
			setSettings(mergeSetting(settings, key, value))
		end,
	}))
end

local function dropdownRow(label, order, settings, setSettings, key, items)
	return row(label, order, React.createElement(StudioComponents.Dropdown, {
		Items = items,
		SelectedItem = settings[key],
		Size = UDim2.new(1, 0, 0, 22),
		MaxVisibleRows = 8,
		OnItemSelected = function(value)
			if value then
				setSettings(mergeSetting(settings, key, value))
			end
		end,
	}))
end

local function checkbox(label, order, settings, setSettings, key)
	return React.createElement(StudioComponents.Checkbox, {
		Label = label,
		Value = settings[key],
		Size = UDim2.new(1, 0, 0, 24),
		LayoutOrder = order,
		OnChanged = function()
			setSettings(mergeSetting(settings, key, not settings[key]))
		end,
	})
end

local function panel(children)
	return React.createElement(StudioComponents.ScrollFrame, {
		Size = UDim2.fromScale(1, 1),
		ScrollingDirection = Enum.ScrollingDirection.Y,
		PaddingLeft = UDim.new(0, 10),
		PaddingRight = UDim.new(0, 10),
		PaddingTop = UDim.new(0, 10),
		PaddingBottom = UDim.new(0, 10),
		Layout = {
			ClassName = "UIListLayout",
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 6),
		},
	}, children)
end

local function makePlan(image, settings)
	local cleanSettings = Settings.sanitize(settings)
	local targetWidth, targetHeight = Settings.getTargetSize(image, cleanSettings)
	local sampled = ImageSampler.sample(image, targetWidth, targetHeight)
	local plan = PartPlanner.plan(sampled, cleanSettings)
	return cleanSettings, plan
end

local function getSelectionParent(selectionService)
	local selected = selectionService:Get()
	for _, instance in selected do
		if instance:IsA("Folder") or instance:IsA("Model") or instance:IsA("WorldModel") or instance:IsA("DataModel") then
			return instance
		end
		local parent = instance.Parent
		if parent then
			return parent
		end
	end
	return nil
end

local function getParentLabel(parentTarget)
	if parentTarget == nil then
		return "Workspace"
	end
	if not parentTarget:IsDescendantOf(game) and parentTarget ~= game then
		return "Workspace"
	end
	return parentTarget:GetFullName()
end

local function App(props)
	local settings, setSettings = React.useState(Settings.copyDefaults())
	local selectedTab, setSelectedTab = React.useState("Output")
	local image, setImage = React.useState(nil)
	local fileName, setFileName = React.useState("")
	local status, setStatus = React.useState("Import a PNG to begin.")
	local planInfo, setPlanInfo = React.useState(nil)
	local busy, setBusy = React.useState(false)
	local parentTarget, setParentTarget = React.useState(nil)

	React.useEffect(function()
		if not image then
			setPlanInfo(nil)
			return
		end

		local cancelled = false
		setPlanInfo(nil)
		task.defer(function()
			local ok, cleanSettings, plan = pcall(makePlan, image, settings)
			if cancelled then
				return
			end
			if ok then
				setPlanInfo({
					Width = plan.Width,
					Height = plan.Height,
					VisiblePixels = plan.VisiblePixels,
					PartCount = plan.PartCount,
					Settings = cleanSettings,
				})
			else
				setStatus(`Estimate failed: {cleanSettings}`)
			end
		end)

		return function()
			cancelled = true
		end
	end, { image, settings })

	local function importPng()
		if busy then
			return
		end

		setBusy(true)
		setStatus("Waiting for PNG import...")
		local ok, imported = pcall(function()
			return props.StudioService:PromptImportFileAsync({ "png" })
		end)

		if not ok then
			setStatus(`Import failed: {imported}`)
			setBusy(false)
			return
		end

		if not imported then
			setStatus("Import cancelled.")
			setBusy(false)
			return
		end

		local decodeOk, decoded = pcall(function()
			return props.PNG.new(imported:GetBinaryContents())
		end)
		if not decodeOk then
			setStatus(`PNG decode failed: {decoded}`)
			setBusy(false)
			return
		end

		local baseName = string.split(imported.Name, ".")[1]
		setImage(decoded)
		setFileName(imported.Name)
		setSettings(function(current)
			local nextSettings = table.clone(current)
			nextSettings.ModelName = baseName
			return nextSettings
		end)
		setStatus(`Imported {imported.Name} ({decoded.Width} x {decoded.Height}).`)
		setBusy(false)
	end

	local function generate()
		if busy or not image then
			return
		end

		setBusy(true)
		setStatus("Planning parts...")
		task.defer(function()
			local ok, cleanSettings, plan = pcall(makePlan, image, settings)
			if not ok then
				setStatus(`Generation failed while planning: {cleanSettings}`)
				setBusy(false)
				return
			end

			setPlanInfo({
				Width = plan.Width,
				Height = plan.Height,
				VisiblePixels = plan.VisiblePixels,
				PartCount = plan.PartCount,
				Settings = cleanSettings,
			})

			local targetParent = if parentTarget and parentTarget:IsDescendantOf(game) then parentTarget else workspace
			setStatus(`Creating {plan.PartCount} parts...`)
			local buildOk, _, created = pcall(PartBuilder.build, plan, cleanSettings, targetParent)
			if buildOk then
				setStatus(`Generated {created} parts from {plan.Width} x {plan.Height} pixels.`)
			else
				setStatus(`Generation failed while building: {_}`)
			end
			setBusy(false)
		end)
	end

	local function parentButtons(order)
		return React.createElement("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 58),
			LayoutOrder = order,
		}, {
			Parent = React.createElement(StudioComponents.Label, {
				Text = `Parent: {getParentLabel(parentTarget)}`,
				Size = UDim2.new(1, 0, 0, 24),
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
			}),
			Workspace = React.createElement(StudioComponents.Button, {
				Text = "Use Workspace",
				Position = UDim2.fromOffset(0, 30),
				Size = UDim2.new(0.5, -4, 0, 24),
				OnActivated = function()
					setParentTarget(nil)
				end,
			}),
			Selection = React.createElement(StudioComponents.Button, {
				Text = "Use Selection",
				Position = UDim2.new(0.5, 4, 0, 30),
				Size = UDim2.new(0.5, -4, 0, 24),
				OnActivated = function()
					local target = getSelectionParent(props.Selection)
					setParentTarget(target)
					setStatus(if target then `Parent set to {target:GetFullName()}.` else "No valid selection parent.")
				end,
			}),
		})
	end

	local cleanSettings = Settings.sanitize(settings)
	local targetText = "No image"
	if image then
		local width, height = Settings.getTargetSize(image, cleanSettings)
		targetText = `{width} x {height}`
	end

	local estimateText = "Import an image to estimate."
	if image and planInfo then
		estimateText = `{planInfo.VisiblePixels} visible pixels -> {planInfo.PartCount} parts`
	elseif image then
		estimateText = "Estimating..."
	end

	local function buildOutputTab()
		local order = 0
		local function nextOrder()
			order += 1
			return order
		end
		return panel({
			ModelName = textRow("Model name", nextOrder(), settings, setSettings, "ModelName"),
			PartPrefix = textRow("Part prefix", nextOrder(), settings, setSettings, "PartNamePrefix"),
			Parent = parentButtons(nextOrder()),
			PixelSize = numericRow("Pixel size", nextOrder(), settings, setSettings, "PixelSize", {
				Min = 0.05,
				Max = 100,
				Step = 0.25,
				Slider = true,
			}),
			ModelYOffset = numericRow("Y offset", nextOrder(), settings, setSettings, "ModelYOffset", {
				Min = -500,
				Max = 500,
				Step = 1,
			}),
			Plane = dropdownRow("Plane", nextOrder(), settings, setSettings, "Plane", Settings.PlaneOptions),
			Center = checkbox("Center at origin", nextOrder(), settings, setSettings, "CenterAtOrigin"),
			Container = checkbox("Create model container", nextOrder(), settings, setSettings, "CreateModelContainer"),
		})
	end

	local function buildScalingTab()
		local order = 0
		local function nextOrder()
			order += 1
			return order
		end
		return panel({
			ScalingMode = dropdownRow("Mode", nextOrder(), settings, setSettings, "ScalingMode", Settings.ScalingModes),
			OutputWidth = numericRow("Output width", nextOrder(), settings, setSettings, "OutputWidth", {
				Min = 1,
				Max = 2048,
				Step = 1,
			}),
			OutputHeight = numericRow("Output height", nextOrder(), settings, setSettings, "OutputHeight", {
				Min = 1,
				Max = 2048,
				Step = 1,
			}),
			MaxDimension = numericRow("Max dimension", nextOrder(), settings, setSettings, "MaxDimension", {
				Min = 1,
				Max = 2048,
				Step = 1,
				Slider = true,
			}),
			ColorMode = dropdownRow("Color mode", nextOrder(), settings, setSettings, "ColorMode", Settings.ColorModes),
			BlackWhiteThreshold = numericRow("B/W threshold", nextOrder(), settings, setSettings, "BlackWhiteThreshold", {
				Min = 0,
				Max = 255,
				Step = 1,
				Slider = true,
			}),
		})
	end

	local function buildOptimizationTab()
		local order = 0
		local function nextOrder()
			order += 1
			return order
		end
		return panel({
			MergeMode = dropdownRow("Merge mode", nextOrder(), settings, setSettings, "MergeMode", Settings.MergeModes),
			ColorTolerance = numericRow("Color tolerance", nextOrder(), settings, setSettings, "ColorTolerance", {
				Min = 0,
				Max = 80,
				Step = 1,
				Slider = true,
			}),
			AlphaTolerance = numericRow("Alpha tolerance", nextOrder(), settings, setSettings, "AlphaTolerance", {
				Min = 0,
				Max = 255,
				Step = 1,
				Slider = true,
			}),
			TransparencyCutoff = numericRow("Alpha cutoff", nextOrder(), settings, setSettings, "TransparencyCutoff", {
				Min = 0,
				Max = 255,
				Step = 1,
				Slider = true,
			}),
			MinimumRegionArea = numericRow("Minimum area", nextOrder(), settings, setSettings, "MinimumRegionArea", {
				Min = 1,
				Max = 256,
				Step = 1,
			}),
			BatchYieldSize = numericRow("Batch size", nextOrder(), settings, setSettings, "BatchYieldSize", {
				Min = 1,
				Max = 10000,
				Step = 50,
			}),
			SkipTransparent = checkbox("Skip transparent pixels", nextOrder(), settings, setSettings, "SkipTransparentPixels"),
			Quantize = checkbox("Quantize colors", nextOrder(), settings, setSettings, "QuantizeColors"),
			Average = checkbox("Average merged colors", nextOrder(), settings, setSettings, "AverageMergedColors"),
			IgnoreAlpha = checkbox("Ignore alpha for merging", nextOrder(), settings, setSettings, "IgnoreAlphaForMerging"),
			Yielding = checkbox("Yield during generation", nextOrder(), settings, setSettings, "YieldDuringGeneration"),
		})
	end

	local function buildPartPropertiesTab()
		local order = 0
		local function nextOrder()
			order += 1
			return order
		end
		return panel({
			Material = dropdownRow("Material", nextOrder(), settings, setSettings, "Material", materialItems),
			ThicknessPreset = dropdownRow("Thickness", nextOrder(), settings, setSettings, "ThicknessPreset", Settings.ThicknessPresets),
			CustomThickness = numericRow("Custom thickness", nextOrder(), settings, setSettings, "Thickness", {
				Min = 0.01,
				Max = 100,
				Step = 0.05,
			}),
			PreserveTransparency = checkbox("Preserve transparency", nextOrder(), settings, setSettings, "PreserveTransparency"),
			Anchored = checkbox("Anchored", nextOrder(), settings, setSettings, "Anchored"),
			Collide = checkbox("Can collide", nextOrder(), settings, setSettings, "CanCollide"),
			Shadows = checkbox("Cast shadows", nextOrder(), settings, setSettings, "CastShadow"),
		})
	end

	return React.createElement(StudioComponents.Background, {}, {
		Header = React.createElement("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, -24, 0, 112),
			Position = UDim2.fromOffset(12, 10),
		}, {
			Layout = React.createElement("UIListLayout", {
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 6),
			}),
			Buttons = React.createElement("Frame", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 30),
				LayoutOrder = 1,
			}, {
				Import = React.createElement(StudioComponents.Button, {
					Text = "Import PNG",
					Size = UDim2.new(0.5, -4, 0, 26),
					Disabled = busy,
					OnActivated = importPng,
				}),
				Generate = React.createElement(StudioComponents.MainButton, {
					Text = "Generate Parts",
					Position = UDim2.new(0.5, 4, 0, 0),
					Size = UDim2.new(0.5, -4, 0, 26),
					Disabled = busy or image == nil,
					OnActivated = generate,
				}),
			}),
			Status = React.createElement(StudioComponents.Label, {
				Text = status,
				Size = UDim2.new(1, 0, 0, 36),
				TextWrapped = true,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Top,
				LayoutOrder = 2,
			}),
			Meta = React.createElement(StudioComponents.Label, {
				Text = `File: {if fileName == "" then "None" else fileName}\nTarget: {targetText}\nEstimate: {estimateText}`,
				Size = UDim2.new(1, 0, 0, 42),
				TextWrapped = true,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Top,
				LayoutOrder = 3,
			}),
		}),
		Tabs = React.createElement(StudioComponents.TabContainer, {
			Position = UDim2.fromOffset(12, 150),
			Size = UDim2.new(1, -24, 1, -150),
			SelectedTab = selectedTab,
			OnTabSelected = setSelectedTab,
		}, {
			Output = {
				LayoutOrder = 1,
				Content = buildOutputTab(),
			},
			Scaling = {
				LayoutOrder = 2,
				Content = buildScalingTab(),
			},
			Optimization = {
				LayoutOrder = 3,
				Content = buildOptimizationTab(),
			},
			["Part Properties"] = {
				LayoutOrder = 4,
				Content = buildPartPropertiesTab(),
			},
		}),
	})
end

return App
