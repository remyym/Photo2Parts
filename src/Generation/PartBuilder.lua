local PartBuilder = {}

local function getMaterial(name)
	local ok, material = pcall(function()
		return Enum.Material[name]
	end)
	if ok and material then
		return material
	end
	return Enum.Material.SmoothPlastic
end

local function getPartTransform(rect, plan, settings)
	local pixelSize = settings.PixelSize
	local thickness = settings.Thickness
	local width = rect.Width * pixelSize
	local height = rect.Height * pixelSize
	local centerX = (rect.X - 1 + rect.Width / 2) * pixelSize
	local centerY = (rect.Y - 1 + rect.Height / 2) * pixelSize

	if settings.CenterAtOrigin then
		centerX -= (plan.Width * pixelSize) / 2
		centerY -= (plan.Height * pixelSize) / 2
	end

	if settings.Plane == "XY" then
		return Vector3.new(width, height, thickness), Vector3.new(centerX, -centerY + settings.ModelYOffset, 0)
	elseif settings.Plane == "YZ" then
		return Vector3.new(thickness, height, width), Vector3.new(0, -centerY + settings.ModelYOffset, centerX)
	end

	return Vector3.new(width, thickness, height), Vector3.new(centerX, settings.ModelYOffset, centerY)
end

function PartBuilder.build(plan, settings, parentOverride)
	local parent = parentOverride or workspace
	local model
	if settings.CreateModelContainer then
		model = Instance.new("Model")
		model.Name = settings.ModelName
		model.Parent = parent
		parent = model
	end

	local material = getMaterial(settings.Material)
	local created = 0

	for index, rect in plan.Parts do
		local part = Instance.new("Part")
		part.Name = `{settings.PartNamePrefix}_{index}`
		part.Anchored = settings.Anchored
		part.CanCollide = settings.CanCollide
		part.CastShadow = settings.CastShadow
		part.Material = material
		part.Color = rect.Color
		part.Transparency = if settings.PreserveTransparency then 1 - (rect.Alpha / 255) else 0

		local size, position = getPartTransform(rect, plan, settings)
		part.Size = size
		part.Position = position
		part.Parent = parent

		created += 1
		if settings.YieldDuringGeneration and created % settings.BatchYieldSize == 0 then
			task.wait()
		end
	end

	if model then
		return model, created
	end
	return nil, created
end

return PartBuilder
