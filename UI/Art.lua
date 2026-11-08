local _, ns = ...

local Art = {}
ns.Art = Art

-- The Who list's row art (common-button-list-large and its hover and selected pieces) is 169x69 and slices only
-- horizontally, so the client draws it at native height on a 69-high row (WhoList.xml: LFGWhoListButtonTemplate).
-- Our rows are shorter: stretching the texture to them squashes the art vertically (WFA-27).
local NATIVE_HEIGHT = 69

-- Draw a row atlas at its native height and scale the whole texture down to the row. The atlas's horizontal-only
-- slice still stretches its middle by design; its height never stretches. Offsets follow the texture's scale.
function Art.RowAtlas(row, atlas, layer, blend, x, y)
	local texture = row:CreateTexture(nil, layer)
	texture:SetAtlas(atlas)
	if blend then
		texture:SetBlendMode(blend)
	end
	local function Fit()
		local height, width = row:GetHeight(), row:GetWidth()
		if not height or height <= 0 or not width or width <= 0 then
			return
		end
		local scale = height / NATIVE_HEIGHT
		texture:SetScale(scale)
		texture:SetSize(width / scale, NATIVE_HEIGHT)
		texture:ClearAllPoints()
		texture:SetPoint("TOPLEFT", row, "TOPLEFT", (x or 0) / scale, (y or 0) / scale)
	end
	Fit()
	row:HookScript("OnSizeChanged", Fit)
	return texture
end

-- A file icon, square as every one is, `size` across and whole: a texture that drew an atlas before keeps that
-- atlas's crop until it is reset.
---@param texture Texture
---@param file string|integer
---@param size number
function Art.Icon(texture, file, size)
	texture:SetTexCoord(0, 1, 0, 1)
	texture:SetTexture(file)
	texture:SetSize(size, size)
end

return Art
