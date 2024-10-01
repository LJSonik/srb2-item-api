---@class itemapi
local mod = {}
rawset(_G, "itemapi", mod)


---@class itemapi.Module
---@field vars table
---@field client table


---@class itemapi.Vars
mod.vars = {}

---@class itemapi.Client
mod.client = {}


addHook("NetVars", function(net)
	mod.vars = net($)
end)


---@return itemapi.Module
function mod.addModule()
	local module = {
		vars = {},
		client = {}
	}

	addHook("NetVars", function(net)
		module.vars = net($)
	end)

	return module
end


dofile "Libraries/ljrequire.lua"
mod.ljrequire = ljrequire

for _, filename in ipairs{
	"Core/Util.lua",
	"Core/Collision.lua",
	"Core/CollisionMath.lua",
	"Core/Core.lua",
	"Core/Item.lua",
	"Core/Action.lua",
	"Core/ActionAnimation.lua",
	"Core/CarrySlot.lua",
	"Core/CarriedItem.lua",
	"Core/GroundItem.lua",
	"Core/GroundItemPlacement.lua",
	"Core/LargeItemPlacement.lua",
	"Core/Inventory.lua",
	"Core/Crafting.lua",
	"Core/ModelDef.lua",
	"Core/Model.lua",
	"Core/Ticker.lua",
	"Core/Culling.lua",
	"Core/Particle.lua",
	"Core/Hunger.lua",
	"Core/SpriteText.lua",
	"Core/InfoBubbles.lua",
	"Core/Options.lua",

	"Interface/KeyBind.lua",
	"Interface/Interface.lua",
	"Interface/Mouse.lua",
	"Interface/Tooltip.lua",
	"Interface/ActionTargetIcon.lua",
	"Interface/ControlOptions.lua",

	"Interface/Modes/Game.lua",
	"Interface/Modes/Action.lua",
	"Interface/Modes/LargeItemPlacement.lua",
	"Interface/Modes/Container.lua",
	"Interface/Modes/SpotSelection.lua",

	"Interface/GUI/Menu.lua",
	"Interface/GUI/MenuList.lua",
	"Interface/GUI/InventoryWindow.lua",
	"Interface/GUI/StatsWindow.lua",
	"Interface/GUI/CraftingWindow.lua",
	"Interface/GUI/OptionsWindow.lua",
	"Interface/GUI/ControlOptionsWindow.lua",
	"Interface/GUI/Navigation.lua",
} do
	dofile(filename)
end
