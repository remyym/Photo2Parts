local Settings = {}

Settings.Materials = {
	"SmoothPlastic",
	"Plastic",
	"Neon",
	"Glass",
	"Metal",
	"Wood",
	"Concrete",
	"Brick",
	"Slate",
	"Granite",
	"Marble",
	"Sand",
	"Grass",
	"Fabric",
}

Settings.PlaneOptions = {
	{ Id = "XZ", Text = "Flat XZ" },
	{ Id = "XY", Text = "Wall XY" },
	{ Id = "YZ", Text = "Wall YZ" },
}

Settings.ScalingModes = {
	{ Id = "MaxDimension", Text = "Max dimension" },
	{ Id = "ExactSize", Text = "Exact width/height" },
	{ Id = "Original", Text = "Original size" },
}

Settings.MergeModes = {
	{ Id = "None", Text = "No merging" },
	{ Id = "Exact", Text = "Exact color rectangles" },
	{ Id = "Similar", Text = "Similar color rectangles" },
}

Settings.ColorModes = {
	{ Id = "Original", Text = "Original color" },
	{ Id = "Grayscale", Text = "Grayscale" },
	{ Id = "BlackWhite", Text = "Black and white" },
}

Settings.ThicknessPresets = {
	{ Id = "Thin", Text = "Thin" },
	{ Id = "Cube", Text = "Cube" },
	{ Id = "Custom", Text = "Custom" },
}

Settings.Default = {
	PixelSize = 5,
	OutputWidth = 128,
	OutputHeight = 128,
	MaxDimension = 128,
	TransparencyCutoff = 1,
	ColorTolerance = 8,
	AlphaTolerance = 12,
	BatchYieldSize = 750,
	BlackWhiteThreshold = 128,
	MinimumRegionArea = 1,
	ModelYOffset = 5,
	Thickness = 0.4,
	ColorMode = "Original",
	Material = "SmoothPlastic",
	Plane = "XZ",
	ScalingMode = "MaxDimension",
	MergeMode = "Exact",
	ThicknessPreset = "Cube",
	ModelName = "Photo2Parts",
	PartNamePrefix = "Pixel",
	PreserveTransparency = true,
	Anchored = true,
	CastShadow = false,
	CanCollide = false,
	SkipTransparentPixels = true,
	QuantizeColors = false,
	AverageMergedColors = true,
	IgnoreAlphaForMerging = false,
	YieldDuringGeneration = true,
	CenterAtOrigin = true,
	CreateModelContainer = true,
}

Settings.Presets = {
	{
		Name = "Default",
		Description = "Balanced defaults for most images.",
		Settings = {},
	},
	{
		Name = "Pixel Art",
		Description = "Keeps hard edges and exact colors for sprites, icons, and pixel art.",
		Settings = {
			MaxDimension = 128,
			ColorMode = "Original",
			MergeMode = "Exact",
			ColorTolerance = 0,
			AlphaTolerance = 0,
			QuantizeColors = false,
			AverageMergedColors = false,
			MinimumRegionArea = 1,
			ThicknessPreset = "Cube",
			Material = "SmoothPlastic",
		},
	},
	{
		Name = "Low Part Count",
		Description = "Aggressively reduces part count for large or detailed photos.",
		Settings = {
			MaxDimension = 96,
			MergeMode = "Similar",
			ColorTolerance = 28,
			AlphaTolerance = 48,
			QuantizeColors = true,
			AverageMergedColors = true,
			IgnoreAlphaForMerging = true,
			MinimumRegionArea = 3,
			ThicknessPreset = "Thin",
			CastShadow = false,
			CanCollide = false,
		},
	},
	{
		Name = "Detailed Photo",
		Description = "Keeps more color detail while still merging similar rectangles.",
		Settings = {
			MaxDimension = 192,
			ColorMode = "Original",
			MergeMode = "Similar",
			ColorTolerance = 8,
			AlphaTolerance = 12,
			QuantizeColors = false,
			AverageMergedColors = true,
			MinimumRegionArea = 1,
			ThicknessPreset = "Thin",
		},
	},
	{
		Name = "Sign / Logo",
		Description = "Good for clean graphics with transparency and simple shapes.",
		Settings = {
			MaxDimension = 160,
			MergeMode = "Exact",
			TransparencyCutoff = 8,
			SkipTransparentPixels = true,
			PreserveTransparency = true,
			MinimumRegionArea = 1,
			Material = "SmoothPlastic",
			ThicknessPreset = "Thin",
		},
	},
	{
		Name = "Black & White Silhouette",
		Description = "Turns the image into bold black-and-white blocks.",
		Settings = {
			MaxDimension = 128,
			ColorMode = "BlackWhite",
			BlackWhiteThreshold = 128,
			MergeMode = "Exact",
			QuantizeColors = false,
			MinimumRegionArea = 2,
			Material = "SmoothPlastic",
		},
	},
	{
		Name = "Neon Display",
		Description = "Creates bright, non-shadow-casting parts for signs and displays.",
		Settings = {
			MaxDimension = 128,
			MergeMode = "Similar",
			ColorTolerance = 12,
			AlphaTolerance = 24,
			Material = "Neon",
			ThicknessPreset = "Thin",
			CastShadow = false,
			CanCollide = false,
		},
	},
}

local function clampNumber(value, min, max, fallback)
	local number = tonumber(value)
	if number == nil or number ~= number then
		return fallback
	end
	return math.clamp(number, min, max)
end

function Settings.copyDefaults()
	return table.clone(Settings.Default)
end

function Settings.applyPreset(baseSettings, preset)
	local output = if preset.Name == "Default" then Settings.copyDefaults() else table.clone(baseSettings)
	for key, value in preset.Settings do
		output[key] = value
	end
	return Settings.sanitize(output)
end

function Settings.sanitize(input)
	local output = Settings.copyDefaults()
	for key in output do
		if input[key] ~= nil then
			output[key] = input[key]
		end
	end

	output.PixelSize = clampNumber(output.PixelSize, 0.05, 1000, Settings.Default.PixelSize)
	output.OutputWidth = math.floor(clampNumber(output.OutputWidth, 1, 2048, Settings.Default.OutputWidth))
	output.OutputHeight = math.floor(clampNumber(output.OutputHeight, 1, 2048, Settings.Default.OutputHeight))
	output.MaxDimension = math.floor(clampNumber(output.MaxDimension, 1, 2048, Settings.Default.MaxDimension))
	output.TransparencyCutoff = math.floor(clampNumber(output.TransparencyCutoff, 0, 255, Settings.Default.TransparencyCutoff))
	output.ColorTolerance = math.floor(clampNumber(output.ColorTolerance, 0, 255, Settings.Default.ColorTolerance))
	output.AlphaTolerance = math.floor(clampNumber(output.AlphaTolerance, 0, 255, Settings.Default.AlphaTolerance))
	output.BatchYieldSize = math.floor(clampNumber(output.BatchYieldSize, 1, 10000, Settings.Default.BatchYieldSize))
	output.BlackWhiteThreshold = math.floor(clampNumber(output.BlackWhiteThreshold, 0, 255, Settings.Default.BlackWhiteThreshold))
	output.MinimumRegionArea = math.floor(clampNumber(output.MinimumRegionArea, 1, 4096, Settings.Default.MinimumRegionArea))
	output.ModelYOffset = clampNumber(output.ModelYOffset, -100000, 100000, Settings.Default.ModelYOffset)
	output.Thickness = clampNumber(output.Thickness, 0.01, 1000, Settings.Default.Thickness)
	output.ModelName = tostring(output.ModelName == "" and Settings.Default.ModelName or output.ModelName)
	output.PartNamePrefix = tostring(output.PartNamePrefix == "" and Settings.Default.PartNamePrefix or output.PartNamePrefix)

	if output.ThicknessPreset == "Cube" then
		output.Thickness = output.PixelSize
	elseif output.ThicknessPreset == "Thin" then
		output.Thickness = math.max(output.PixelSize * 0.08, 0.05)
	end

	return output
end

function Settings.getTargetSize(image, settings)
	local width = image.Width
	local height = image.Height
	if settings.ScalingMode == "Original" then
		return width, height
	elseif settings.ScalingMode == "ExactSize" then
		return settings.OutputWidth, settings.OutputHeight
	end

	local maxDimension = math.max(1, settings.MaxDimension)
	local scale = math.min(maxDimension / math.max(width, height), 1)
	return math.max(1, math.floor(width * scale + 0.5)), math.max(1, math.floor(height * scale + 0.5))
end

return Settings
