function FlipTable(t)
	local flipped = {}
	for i = #t, 1, -1 do
		flipped[#flipped + 1] = t[i]
	end
	return flipped
end

return FlipTable
