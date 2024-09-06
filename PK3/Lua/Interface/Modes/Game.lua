---@class itemapi
local mod = itemapi


mod.addUIMode("game", {
	allowMovement = true,

	update = function()
		mod.client.aimedMobj = mod.findAimedMobj(consoleplayer)
	end,

	leave = function()
		mod.client.aimedMobj = nil
	end,

	commands = {
		{
			id = "open_action_selection",
			name = "open action selection",
			defaultKey = "@custom1",

			action = function()
				if not consoleplayer.itemapi_action then
					mod.openActionSelection()
				end
			end
		},
		{
			id = "perform_default_action",
			name = "perform default action",
			defaultKey = "long @custom1",

			action = function()
				if consoleplayer.itemapi_action then return end

				mod.openActionSelection()

				local sel = mod.client.actionSelection
				if not sel then return end

				local availableAction = sel.availableActions[1]
				if not availableAction then return end

				if availableAction.type == "ground_item" then
					local actionDef = mod.getActionDefFromMobj(sel.mobj, availableAction.index)

					if actionDef.selectSpot then
						mod.client.uiMode.selectingSpot = true
						mod.setUIMode("spot_selection", 1)
					else
						mod.sendActionNetCommand(1)
					end
				else
					mod.sendActionNetCommand(1)
				end
			end
		},
		{
			id = "open_menu",
			name = "open menu",
			defaultKey = "@custom2",

			action = function()
				mod.openMenu()
			end
		},
	},
})
