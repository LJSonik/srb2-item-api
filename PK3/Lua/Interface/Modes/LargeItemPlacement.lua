---@class itemapi
local mod = itemapi


local nc = ljrequire "ljnetcommand"
local bs = ljrequire "bytestream"


freeslot("MT_ITEMAPI_ITEMPLACEMENTINDICATOR", "S_ITEMAPI_ITEMPLACEMENTINDICATOR")

mobjinfo[MT_ITEMAPI_ITEMPLACEMENTINDICATOR] = {
	spawnstate = S_ITEMAPI_ITEMPLACEMENTINDICATOR,
	spawnhealth = 1,
	radius = 8*FU,
	height = 16*FU,
	flags = MF_NOBLOCKMAP|MF_NOCLIP|MF_NOCLIPHEIGHT|MF_SCENERY|MF_NOTHINK|MF_NOGRAVITY
}

states[S_ITEMAPI_ITEMPLACEMENTINDICATOR] = { SPR_LCKN, C }


local netCommand_craftAndPlaceItem = nc.add(function (p, stream)
	local recipeType = bs.readUInt16(stream)
	mod.craftRecipe(p, recipeType)
end)


---@param v videolib
---@param name string
---@param cmdID string
---@param x integer
---@param y integer
---@param rightAligned? boolean
local function drawActionKey(v, name, cmdID, x, y, rightAligned)
	local keyName = mod.getUICommandKeyName(cmdID):upper()
	local keyBlinkFreq = TICRATE/2
	local keyColor = (mod.client.time / keyBlinkFreq % 2 == 0) and "\x80" or "\x8f"

	v.drawString(
		x, y,
		keyColor .. keyName .. " \x84" .. name .. "\x80",
		V_ALLOWLOWERCASE | (rightAligned and V_SNAPTORIGHT or V_SNAPTOLEFT) | V_SNAPTOBOTTOM,
		rightAligned and "right" or "left"
	)
end


mod.addUIMode("large_item_placement", {
	allowMovement = true,

	enter = function(recipeType)
		local cl = mod.client
		local mode = cl.uiMode
		local recipeDef = mod.craftingRecipeDefs[recipeType]
		local itemDef = mod.itemDefs[recipeDef.item]

		mode.largeItemPlacementRecipeType = recipeDef.index
		mode.itemType = itemDef.index

		local x, y, z = mod.findLargeItemPlacementPosition(consoleplayer, mode.itemType)
		local mo = P_SpawnMobj(x, y, z, MT_ITEMAPI_ITEMPLACEMENTINDICATOR)
		cl.uiMode.indicatorMobj = mo

		mo.sprite, mo.frame = SPR_IAPI, 0
		mo.angle = consoleplayer.mo.angle
		mo.spriteyoffset = -4*FU -- Hack to work around OpenGL rendering with an extra 4 FU y-offset
		mo.renderflags = $ | RF_FLOORSPRITE | RF_NOSPLATBILLBOARD

		local dim = itemDef.dimensions
		if dim then
			mo.spritexscale = dim[2] * FU / 64
			mo.spriteyscale = dim[1] * FU / 64
		end
	end,

	update = function()
		local cl = mod.client
		local p = consoleplayer
		local mo = cl.uiMode.indicatorMobj
		local itemType = cl.uiMode.itemType

		local x, y, z, angle = mod.findLargeItemPlacementPosition(p, itemType)
		P_MoveOrigin(mo, x, y, z)

		mo.angle = angle

		if mod.canPlaceLargeItemAtPosition(p, itemType, x, y, z, angle) then
			mo.color = SKINCOLOR_BLUE
		else
			mo.color = SKINCOLOR_RED
		end

		local trans = mod.sinCycle(cl.time, 5*FU, 8*FU, TICRATE) / FU
		mo.frame = ($ & ~FF_TRANSMASK) | (trans << FF_TRANSSHIFT)
	end,

	leave = function()
		P_RemoveMobj(mod.client.uiMode.indicatorMobj)
	end,

	commands = {
		{
			id = "confirm",

			action = function()
				local recipeType = mod.client.uiMode.largeItemPlacementRecipeType
				if not mod.canCraftRecipe(consoleplayer, recipeType) then return end

				local stream = nc.prepare(netCommand_craftAndPlaceItem)
				bs.writeUInt16(stream, recipeType)
				mod.sendNetCommand(consoleplayer, stream)

				mod.closeUI()
			end
		},
		{
			id = "cancel",

			action = function()
				mod.closeUI()
			end
		},
	},

	---@param v videolib
	draw = function(v)
		drawActionKey(v, "cancel", "cancel", 304, 162, true)
		drawActionKey(v, "place", "confirm", 304, 150, true)
	end,
})
