---@class itemapi
local mod = itemapi


mod.addUIMode("spot_selection", {
	---@param availableActionIndex integer
	enter = function(availableActionIndex)
		local mode = mod.client.uiMode

		mode.spotIndex = 1
		mode.availableActionIndex = availableActionIndex

		local pmo = consoleplayer.mo
		local icon = P_SpawnMobj(pmo.x, pmo.y, pmo.z, MT_ITEMAPI_ACTIONTARGETICON)
		mode.iconMobj = icon
	end,

	update = function()
		local mode = mod.client.uiMode
		local x, y, z = mod.getGroundItemSpotPosition(mod.client.actionSelection.mobj, mode.spotIndex)
		z = z + 16*FU
		P_MoveOrigin(mode.iconMobj, x, y, z)
	end,

	leave = function()
		P_RemoveMobj(mod.client.uiMode.iconMobj)
		mod.closeActionSelectionData()
	end,

	commands = {
		{
			id = "select_left",
			name = "select left",
			defaultKey = "@strafeleft",

			action = function()
				local mode = mod.client.uiMode
				local itemDef = mod.getItemDefFromMobj(mod.client.actionSelection.mobj)

				mode.spotIndex = $ - 1
				if mode.spotIndex < 1 then
					mode.spotIndex = #itemDef.spots
				end
			end
		},
		{
			id = "select_right",
			name = "select right",
			defaultKey = "@straferight",

			action = function()
				local mode = mod.client.uiMode
				local itemDef = mod.getItemDefFromMobj(mod.client.actionSelection.mobj)

				mode.spotIndex = $ + 1
				if mode.spotIndex > #itemDef.spots then
					mode.spotIndex = 1
				end
			end
		},
		{
			id = "confirm",

			action = function()
				local mode = mod.client.uiMode
				mod.sendActionNetCommand(mode.availableActionIndex, mode.spotIndex)

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
})
