---@class itemapi
local mod = itemapi


local gui = ljrequire "ljgui"


local windowStyle = {
	bdSize = FU,
	bdColor = 25,

	titleBarSize = 8*FU,
	titleBarColor = 28,

	bgColor = 27,
}


---@param item ljgui.Item
---@param v videolib
local function drawStats(item, v)
	local x, y = item.cachedLeft, item.cachedTop
	local hunger = FixedMul(FixedDiv(consoleplayer.itemapi_hunger, mod.MAX_HUNGER), 100)
	local thirst = FixedMul(FixedDiv(consoleplayer.itemapi_thirst, mod.MAX_THIRST), 100)

	local padding = 2*FU
	x = x + padding
	y = y + padding

	-- Hunger bar
	local barX = x + 26*FU
	local barWidth = 32*FU
	local filledBarWidth = hunger * barWidth / 100
	gui.drawFill(v, barX, y, barWidth, 4*FU, 44)
	gui.drawFill(v, barX, y, filledBarWidth, 4*FU, 36)

	gui.drawString(v, x, y, "Hunger")
	gui.drawString(v, barX + 10*FU, y, hunger .. "%")
	y = y + 5*FU

	-- Thirst bar
	local barX = x + 26*FU
	local barWidth = 32*FU
	local filledBarWidth = thirst * barWidth / 100
	gui.drawFill(v, barX, y, barWidth, 4*FU, 156)
	gui.drawFill(v, barX, y, filledBarWidth, 4*FU, 151)

	gui.drawString(v, x, y, "Thirst")
	gui.drawString(v, barX + 10*FU, y, thirst .. "%")
	y = y + 5*FU
end


---@class itemapi.StatsWindow : ljgui.Window
local Stats = gui.addItem("StatsWindow", {
	base = gui.Window,

	baseProps = {
		width = 64*FU,
		height = 32*FU,

		movable = false,
		resizable = false,

		style = windowStyle,

		mainArea = {
			layout = "flow"
		}
	},

	setup = function(self)
		self.mainArea.draw = drawStats
	end,
})
mod.StatsWindow = Stats
