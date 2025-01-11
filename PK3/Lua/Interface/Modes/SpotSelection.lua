---@class itemapi
local mod = itemapi


mod.addUIMode("spot_selection", {
	showCommands = true,

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
		if mod.client.uiMode.iconMobj.valid then
			P_RemoveMobj(mod.client.uiMode.iconMobj)
		end
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
			showOnRight = true,

			action = function()
				mod.closeUI()
			end
		},
	},
})
