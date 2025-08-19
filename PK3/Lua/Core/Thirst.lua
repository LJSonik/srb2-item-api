---@class itemapi
local mod = itemapi


---@class player_t
---@field itemapi_thirst tic_t


freeslot("SPR_ITEMAPI_INFOBUBBLE_THIRSTY", "SPR_ITEMAPI_INFOBUBBLE_DEHYDRATED")


mod.MAX_THIRST = 10*60*TICRATE
mod.MAX_THIRST = 10*60*TICRATE


---@param player player_t
local function updateInfoBubble(player)
	local bubbles = player.itemapi_infoBubbles
	local thirst = player.itemapi_thirst

	local bubbleID
	if thirst > mod.MAX_THIRST / 4 then -- 25-100%
		bubbleID = nil
	elseif thirst > mod.MAX_THIRST / 10 then -- 10-25%
		bubbleID = "thirsty"
	elseif thirst > mod.MAX_THIRST / 20 then -- 5-10%
		bubbleID = "dehydrated"
	else -- 0-5%
		bubbleID = "dehydrated"
	end

	if bubbleID == "thirsty" and not bubbles["thirsty"] then
		mod.startInfoBubble(player, {
			id = "thirsty",
			sprite = SPR_ITEMAPI_INFOBUBBLE_THIRSTY,
			frame = 0,
			scale = FU/4
		})
	elseif bubbleID ~= "thirsty" and bubbles["thirsty"] then
		mod.stopInfoBubble(player, "thirsty")
	end

	if bubbleID == "dehydrated" and not bubbles["dehydrated"] then
		mod.startInfoBubble(player, {
			id = "dehydrated",
			sprite = SPR_ITEMAPI_INFOBUBBLE_DEHYDRATED,
			frame = 0,
			scale = FU/4
		})
	elseif bubbleID ~= "dehydrated" and bubbles["dehydrated"] then
		mod.stopInfoBubble(player, "dehydrated")
	end
end

---@param player player_t
function mod.drink(player, amount)
	player.itemapi_thirst = min($ + amount, mod.MAX_THIRST)
end

---@param player player_t
function mod.updateThirst(player)
	local oldThirst = player.itemapi_thirst

	local freq
	if oldThirst > mod.MAX_THIRST / 10 then -- 10-100%
		freq = 1
	elseif oldThirst > mod.MAX_THIRST / 20 then -- 5-10%
		freq = 2
	else -- 0-5%
		freq = 5
	end

	local newThirst = oldThirst
	if leveltime % freq == 0 then
		newThirst = max($ - 1, 0)
	end

	player.itemapi_thirst = newThirst

	if newThirst == 0 and newThirst ~= oldThirst and player.mo then
		P_DamageMobj(player.mo, nil, nil, nil, DMG_INSTAKILL)
	end

	updateInfoBubble(player)
end
