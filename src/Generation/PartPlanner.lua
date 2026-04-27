local PartPlanner = {}

local function toByte(value)
	return math.clamp(math.floor(value * 255 + 0.5), 0, 255)
end

local function bucketChannel(value, tolerance, quantize)
	if quantize then
		local step = math.max(tolerance, 16)
		return math.clamp(math.floor(value / step + 0.5) * step, 0, 255)
	end

	if tolerance <= 0 then
		return value
	end

	return math.clamp(math.floor(value / tolerance + 0.5) * tolerance, 0, 255)
end

local function applyColorMode(color, settings)
	local r = toByte(color.R)
	local g = toByte(color.G)
	local b = toByte(color.B)

	if settings.ColorMode == "Grayscale" then
		local gray = math.floor((r * 0.299) + (g * 0.587) + (b * 0.114) + 0.5)
		return Color3.fromRGB(gray, gray, gray)
	elseif settings.ColorMode == "BlackWhite" then
		local gray = math.floor((r * 0.299) + (g * 0.587) + (b * 0.114) + 0.5)
		local value = if gray >= settings.BlackWhiteThreshold then 255 else 0
		return Color3.fromRGB(value, value, value)
	end

	return color
end

local function makeCell(pixel, x, y, settings)
	local alpha = math.clamp(math.floor((pixel.Alpha or 255) + 0.5), 0, 255)
	if settings.SkipTransparentPixels and alpha < settings.TransparencyCutoff then
		return nil
	end

	local color = applyColorMode(pixel.Color, settings)
	local r = toByte(color.R)
	local g = toByte(color.G)
	local b = toByte(color.B)
	local bucketR = r
	local bucketG = g
	local bucketB = b
	local bucketA = alpha

	if settings.MergeMode == "Similar" or settings.QuantizeColors then
		bucketR = bucketChannel(r, settings.ColorTolerance, settings.QuantizeColors)
		bucketG = bucketChannel(g, settings.ColorTolerance, settings.QuantizeColors)
		bucketB = bucketChannel(b, settings.ColorTolerance, settings.QuantizeColors)
		bucketA = bucketChannel(alpha, settings.AlphaTolerance, false)
	elseif settings.MergeMode == "Exact" then
		bucketR = r
		bucketG = g
		bucketB = b
		bucketA = alpha
	end
	if settings.IgnoreAlphaForMerging or not settings.PreserveTransparency then
		bucketA = 255
	end

	return {
		X = x,
		Y = y,
		Color = if settings.QuantizeColors then Color3.fromRGB(bucketR, bucketG, bucketB) else color,
		Alpha = if settings.MergeMode == "Similar" then bucketA else alpha,
		Key = `{bucketR}:{bucketG}:{bucketB}:{bucketA}`,
	}
end

local function getRectAverages(cells, x, y, rectWidth, rectHeight, fallbackColor, fallbackAlpha, useAverage)
	if not useAverage or rectWidth * rectHeight == 1 then
		return fallbackColor, fallbackAlpha
	end

	local r = 0
	local g = 0
	local b = 0
	local a = 0
	local count = 0
	for markY = y, y + rectHeight - 1 do
		for markX = x, x + rectWidth - 1 do
			local cell = cells[markY][markX]
			r += toByte(cell.Color.R)
			g += toByte(cell.Color.G)
			b += toByte(cell.Color.B)
			a += cell.Alpha
			count += 1
		end
	end

	return Color3.fromRGB(math.floor(r / count + 0.5), math.floor(g / count + 0.5), math.floor(b / count + 0.5)),
		math.floor(a / count + 0.5)
end

local function sameCell(cells, x, y, key)
	local row = cells[y]
	return row ~= nil and row[x] ~= nil and row[x].Key == key
end

local function planSingleParts(cells, width, height, settings)
	local parts = {}
	for y = 1, height do
		for x = 1, width do
			local cell = cells[y][x]
			if cell and settings.MinimumRegionArea <= 1 then
				table.insert(parts, {
					X = x,
					Y = y,
					Width = 1,
					Height = 1,
					Color = cell.Color,
					Alpha = cell.Alpha,
				})
			end
		end
	end
	return parts
end

local function planRectangles(cells, width, height, settings)
	local parts = {}
	local visited = {}
	for y = 1, height do
		visited[y] = {}
	end

	for y = 1, height do
		for x = 1, width do
			local cell = cells[y][x]
			if cell and not visited[y][x] then
				local key = cell.Key
				local rectWidth = 0
				while
					x + rectWidth <= width
					and not visited[y][x + rectWidth]
					and sameCell(cells, x + rectWidth, y, key)
				do
					rectWidth += 1
				end

				local rectHeight = 1
				local canGrow = true
				while y + rectHeight <= height and canGrow do
					for offsetX = 0, rectWidth - 1 do
						if
							visited[y + rectHeight][x + offsetX]
							or not sameCell(cells, x + offsetX, y + rectHeight, key)
						then
							canGrow = false
							break
						end
					end
					if canGrow then
						rectHeight += 1
					end
				end

				for markY = y, y + rectHeight - 1 do
					for markX = x, x + rectWidth - 1 do
						visited[markY][markX] = true
					end
				end

				if rectWidth * rectHeight >= settings.MinimumRegionArea then
					local color, alpha = getRectAverages(
						cells,
						x,
						y,
						rectWidth,
						rectHeight,
						cell.Color,
						cell.Alpha,
						settings.AverageMergedColors and settings.MergeMode == "Similar"
					)
					table.insert(parts, {
						X = x,
						Y = y,
						Width = rectWidth,
						Height = rectHeight,
						Color = color,
						Alpha = alpha,
					})
				end
			end
		end
	end

	return parts
end

function PartPlanner.plan(sampled, settings)
	local cells = {}
	local visiblePixels = 0

	for y = 1, sampled.Height do
		cells[y] = {}
		for x = 1, sampled.Width do
			local cell = makeCell(sampled.Pixels[y][x], x, y, settings)
			cells[y][x] = cell
			if cell then
				visiblePixels += 1
			end
		end
	end

	local parts
	if settings.MergeMode == "None" then
		parts = planSingleParts(cells, sampled.Width, sampled.Height, settings)
	else
		parts = planRectangles(cells, sampled.Width, sampled.Height, settings)
	end

	return {
		Width = sampled.Width,
		Height = sampled.Height,
		VisiblePixels = visiblePixels,
		Parts = parts,
		PartCount = #parts,
	}
end

return PartPlanner
