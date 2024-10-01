---@class itemapi
local mod = itemapi


---@class itemapi.SpriteFontDef
---@field id    string
---@field index integer
---
---@field width integer
---@field height integer
---@field lineGap integer
---@field characters { [string]: { [1]: spritenum_t, [2]: integer } }


---@type { [string|integer]: itemapi.SpriteFontDef }
mod.spriteFontDefs = {}


---@param id string
---@param def itemapi.SpriteFontDef
function mod.addSpriteFont(id, def)
	if type(id) ~= "string" then
		error("missing or invalid sprite font ID", 2)
	end

	def.index = #mod.spriteFontDefs + 1
	def.id = id
	mod.spriteFontDefs[def.index] = def
	mod.spriteFontDefs[id] = def

	for character, spriteFramePair in pairs(def.characters) do
		local sprite, frame = mod.parseSpriteFramePair(spriteFramePair)
		def.characters[character] = { sprite, frame }
	end
end

---@param text string
---@param fontDef itemapi.SpriteFontDef
---@return fixed_t
function mod.calculateSpriteTextWidth(text, fontDef)
	local totalWidth = 0

	for line in text:gmatch("[^\n]+") do
		local w = #line * fontDef.width
		if w > totalWidth then
			totalWidth = w
		end
	end

	return totalWidth * FU
end

---@param text string
---@param fontDef itemapi.SpriteFontDef
---@return fixed_t
function mod.calculateSpriteTextHeight(text, fontDef)
	local _, numNewLines = text:gsub("\n", "\n")
	return (fontDef.height + (fontDef.height + fontDef.lineGap) * numNewLines) * FU
end

---@param text string
---@param fontDef itemapi.SpriteFontDef
---@param maxWidth fixed_t
---@return string
function mod.wordWrapSpriteText(text, fontDef, maxWidth)
	maxWidth = $ / FU

	local charWidth = fontDef.width

	local result = {}
	local resultLen = 0

	local cutStart = 1
	local cutEnd = nil
	local cutWidth = 0

	local uncutWidth = 0
	local wasSpace = false

	for i = 1, #text do
		local c = text:sub(i, i)

		local isSpace = (c == " ")
		if isSpace and not wasSpace then
			cutWidth = uncutWidth
			cutEnd = i - 1
		end
		wasSpace = isSpace

		uncutWidth = $ + charWidth

		if uncutWidth > maxWidth then
			if cutEnd == nil then
				if i == cutStart then
					cutEnd = i
					cutWidth = uncutWidth
				else
					cutEnd = i - 1
					cutWidth = uncutWidth - charWidth
				end
			end

			resultLen = $ + 1
			result[resultLen] = text:sub(cutStart, cutEnd) .. "\n"

			cutStart = cutEnd + 1
			cutEnd = nil
			uncutWidth = $ - cutWidth
			cutWidth = 0

			if text:sub(cutStart, cutStart) == " " then
				cutStart = $ + 1
				uncutWidth = $ - charWidth
			end
		end
	end

	resultLen = $ + 1
	result[resultLen] = text:sub(cutStart, -1)

	return table.concat(result)
end
