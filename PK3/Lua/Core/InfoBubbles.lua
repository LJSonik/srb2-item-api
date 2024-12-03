---@class itemapi
local mod = itemapi


---@class itemapi.InfoBubble
---@field id? string
---@field duration? tic_t
---
---@field sprite? spritenum_t
---@field frame? integer
---@field scale? fixed_t
---
---@field text? string
---
---@field bubbleMobj? mobj_t
---@field tailMobj? mobj_t
---@field iconMobj? mobj_t
---
---@field textMobjs? mobj_t[]
---@field textWidth? fixed_t
---@field textHeight? fixed_t


---@class player_t
---@field itemapi_infoBubbles? { [integer|string]: itemapi.InfoBubble }


local SCALE = FU*3/4
local Z_OFFSET = 12*FU


freeslot("MT_ITEMAPI_INFOBUBBLE", "S_ITEMAPI_INFOBUBBLE")

mobjinfo[MT_ITEMAPI_INFOBUBBLE] = {
	spawnstate = S_ITEMAPI_INFOBUBBLE,
	spawnhealth = 1,
	radius = 8*FU,
	height = 16*FU,
	flags = MF_NOBLOCKMAP|MF_NOCLIP|MF_NOCLIPHEIGHT|MF_SCENERY|MF_NOGRAVITY
}

states[S_ITEMAPI_INFOBUBBLE] = { SPR_IAPI, B }


---@param bubble itemapi.InfoBubble
local function spawnTextMobjs(bubble, x, y, z)
	local fontDef = mod.spriteFontDefs["normal"]

	bubble.textMobjs = {}

	for i = 1, #bubble.text do
		local c = bubble.text:sub(i, i)

		if c == "\n" then
			bubble.textMobjs[i] = nil
		else
			local textMobj = P_SpawnMobj(x, y, z, MT_ITEMAPI_INFOBUBBLE)
			bubble.textMobjs[i] = textMobj

			local spriteFrame = fontDef.characters[c] or fontDef.characters[" "]
			textMobj.sprite, textMobj.frame = spriteFrame[1], spriteFrame[2]

			textMobj.spritexscale, textMobj.spriteyscale = SCALE, SCALE
			textMobj.renderflags = $ | RF_PAPERSPRITE | RF_FULLBRIGHT
			textMobj.dispoffset = 1
			textMobj.spriteyoffset = -4*FU -- Hack to work around OpenGL rendering with an extra 4 FU y-offset
		end
	end
end

---@param player player_t
---@param bubble itemapi.InfoBubble
local function spawnMobjs(player, bubble)
	bubble.scale = $ or FU

	local pmo = player.mo
	local x, y, z = pmo.x, pmo.y, pmo.z + pmo.height

	local bubbleMobj = P_SpawnMobj(x, y, z, MT_ITEMAPI_INFOBUBBLE)
	bubble.bubbleMobj = bubbleMobj
	bubbleMobj.renderflags = $ | RF_PAPERSPRITE | RF_FULLBRIGHT
	bubbleMobj.spriteyoffset = -4*FU -- Hack to work around OpenGL rendering with an extra 4 FU y-offset

	if bubble.text then
		bubbleMobj.sprite, bubbleMobj.frame = SPR_IAPI, E
		bubbleMobj.frame = $ & ~FF_TRANSMASK | FF_TRANS50

		-- 	local tail = P_SpawnMobj(x, y, z, MT_ITEMAPI_INFOBUBBLE)
		-- 	tail.sprite, tail.frame = SPR_IAPI, E
		-- 	tail.dispoffset = 1
		--  tail.renderflags = $ | RF_PAPERSPRITE | RF_FULLBRIGHT
	end

	if bubble.sprite then
		local icon = P_SpawnMobj(x, y, z, MT_ITEMAPI_INFOBUBBLE)
		bubble.iconMobj = icon

		icon.dispoffset = 1

		icon.sprite = bubble.sprite
		icon.frame = bubble.frame

		local scale = FixedMul(bubble.scale, 2 * SCALE)
		icon.spritexscale, icon.spriteyscale = scale, scale
		icon.renderflags = $ | RF_PAPERSPRITE | RF_FULLBRIGHT
		icon.spriteyoffset = -4*FU -- Hack to work around OpenGL rendering with an extra 4 FU y-offset
	end

	if bubble.text then
		spawnTextMobjs(bubble, x, y, z)
	end
end

---@param bubble itemapi.InfoBubble
local function removeMobjs(bubble)
	if bubble.bubbleMobj and bubble.bubbleMobj.valid then
		P_RemoveMobj(bubble.bubbleMobj)
	end

	if bubble.tailMobj and bubble.tailMobj.valid then
		P_RemoveMobj(bubble.tailMobj)
	end

	if bubble.iconMobj and bubble.iconMobj.valid then
		P_RemoveMobj(bubble.iconMobj)
	end

	if bubble.textMobjs then
		for i = 1, #bubble.text do
			local mo = bubble.textMobjs[i]
			if mo and mo.valid then
				P_RemoveMobj(mo)
			end
		end

		bubble.textMobjs = nil
	end
end

---@param bubble itemapi.InfoBubble
---@param cx fixed_t
---@param cy fixed_t
---@param cz fixed_t
---@param angle angle_t
local function updateText(bubble, cx, cy, cz, angle)
	local mobjs = bubble.textMobjs
	local fontDef = mod.spriteFontDefs["normal"]

	local dx = FixedMul(fontDef.width,  SCALE) * cos(angle)
	local dy = FixedMul(fontDef.height, SCALE) * sin(angle)
	local newlineStep = (fontDef.height + fontDef.lineGap) * SCALE

	local dist = FixedMul(bubble.textWidth / 2, SCALE)
	local startX = cx - FixedMul(dist, cos(angle))
	local startY = cy - FixedMul(dist, sin(angle))
	local startZ = cz + FixedMul(bubble.textHeight / 2, SCALE)

	local x, y, z = startX, startY, startZ

	for i = 1, #bubble.text do
		local mo = mobjs[i]

		if mo then
			P_MoveOrigin(mo, x, y, z)
			mo.angle = angle

			x = x + dx
			y = y + dy
		else
			x, y = startX, startY
			z = z - newlineStep
		end
	end
end

---@param bubbles itemapi.InfoBubble[]
local function findHighestPriorityBubble(bubbles)
	local best = bubbles[1]

	for i = 2, #bubbles do
		local bubble = bubbles[i]

		if bubble.duration ~= nil
		and (best.duration == nil or best.duration > bubble.duration) then
			best = bubble
		end
	end

	return best
end

---@param player player_t
---@param bubble itemapi.InfoBubble
---@return itemapi.InfoBubble
function mod.startInfoBubble(player, bubble)
	local bubbles = player.itemapi_infoBubbles

	bubbles[#bubbles + 1] = bubble
	if bubble.id then
		bubbles[bubble.id] = bubble
	end

	if bubble.text then
		local fontDef = mod.spriteFontDefs["normal"]
		bubble.textWidth = mod.calculateSpriteTextWidth(bubble.text, fontDef)
		bubble.textHeight = mod.calculateSpriteTextHeight(bubble.text, fontDef)
	end

	return bubble
end

---@param player player_t
---@param bubble itemapi.InfoBubble|string
function mod.stopInfoBubble(player, bubble)
	local bubbles = player.itemapi_infoBubbles

	if type(bubble) == "string" then
		bubble = bubbles[bubble]
	end

	mod.removeValueFromArray(bubbles, bubble)
	if bubble.id then
		bubbles[bubble.id] = nil
	end

	removeMobjs(bubble)
end

---@param player player_t
function mod.updateInfoBubbles(player)
	local bubbles = player.itemapi_infoBubbles
	if #bubbles == 0 then return end

	local bubble = findHighestPriorityBubble(bubbles)

	-- Hide unshown bubbles
	for i = 1, #bubbles do
		local otherBubble = bubbles[i]

		if otherBubble ~= bubble and otherBubble.bubbleMobj then
			removeMobjs(otherBubble)
		end
	end

	if bubble.duration ~= nil then
		bubble.duration = $ - 1

		if bubble.duration == 0 then
			mod.stopInfoBubble(player, bubble)
			return
		end
	end

	if not displayplayer then return end

	if not (bubble.bubbleMobj and bubble.bubbleMobj.valid) then
		spawnMobjs(player, bubble)
	end

	local angle
	if camera.chase or not (displayplayer.mo and displayplayer.mo.valid) then
		angle = camera.angle
	else
		angle = displayplayer.mo.angle
	end
	angle = angle - ANGLE_90

	local pmo = player.mo
	local floatOffset = Z_OFFSET + mod.sinCycle(leveltime, 0, 2*FU, 2*TICRATE)
	local x, y, z = pmo.x, pmo.y, pmo.z + pmo.height + floatOffset

	local textZ = z
	local scaleX, scaleY
	if bubble.text then
		local w = max(bubble.textWidth, 32*FU) + 8*FU
		local h = max(bubble.textHeight, 16*FU) + 8*FU
		w = FixedMul(w, SCALE)
		h = FixedMul(h, SCALE)

		scaleX = w / 64
		scaleY = h / 64

		textZ = z + h / 2
	else
		local maxSquiggleScale = FU * 9/8
		local squiggleSpeed = 2*TICRATE

		scaleX = mod.sinCycle(leveltime, maxSquiggleScale, FU, squiggleSpeed)
		scaleY = mod.sinCycle(leveltime, FU, maxSquiggleScale, squiggleSpeed)

		scaleX = FixedMul($, SCALE / 2)
		scaleY = FixedMul($, SCALE / 2)
	end

	local bubbleMobj = bubble.bubbleMobj
	P_MoveOrigin(bubbleMobj, x, y, z)
	bubbleMobj.angle = angle
	bubbleMobj.spritexscale = scaleX
	bubbleMobj.spriteyscale = scaleY

	local tail = bubble.tailMobj
	if tail then
		P_MoveOrigin(tail, x, y, z)
		bubbleMobj.angle = angle
		tail.spritexscale = FU/16
		tail.spriteyscale = scaleY
	end

	if bubble.iconMobj then
		P_MoveOrigin(bubble.iconMobj, x, y, z + 32 * scaleY)
		bubble.iconMobj.angle = angle
	end

	if bubble.textMobjs then
		updateText(bubble, x, y, textZ, angle)
	end
end


addHook("MapChange", function()
	for p in players.iterate do
		local bubbles = p.itemapi_infoBubbles

		for i = 1, #bubbles do
			removeMobjs(bubbles[i])
		end
	end
end)
