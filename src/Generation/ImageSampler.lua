local ImageSampler = {}

function ImageSampler.sample(image, targetWidth, targetHeight)
	local sampled = {
		Width = targetWidth,
		Height = targetHeight,
		Pixels = {},
	}

	local sourceWidth = image.Width
	local sourceHeight = image.Height

	for y = 1, targetHeight do
		local row = {}
		local sourceY = math.clamp(math.floor(((y - 0.5) / targetHeight) * sourceHeight + 0.5), 1, sourceHeight)
		for x = 1, targetWidth do
			local sourceX = math.clamp(math.floor(((x - 0.5) / targetWidth) * sourceWidth + 0.5), 1, sourceWidth)
			local color, alpha = image:GetPixel(sourceX, sourceY)
			row[x] = {
				Color = color,
				Alpha = alpha,
			}
		end
		sampled.Pixels[y] = row
	end

	return sampled
end

return ImageSampler
