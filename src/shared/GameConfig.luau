-- GameConfig.luau
-- Every tuning number for Brainrot Bazaar: Noodle Nebula in one place, so the
-- server economy, the wave threat and the client HUD all read the same values.

local GameConfig = {}

GameConfig.GameName = "Brainrot Bazaar: Noodle Nebula"
GameConfig.StartingMoney = 100
GameConfig.BaseSlots = 6 -- pedestals on each player's base plot
GameConfig.MaxPlayersWithBases = 8

-- The conveyor in the plaza restocks a fresh brainrot this often; the Gacha
-- Noodle Pot can be rolled at any time for a flat fee.
GameConfig.ConveyorRestockSeconds = 8
GameConfig.GachaCost = 150

-- The Soup Tsunami: a wall of tomato soup sweeps the plaza. Anyone caught
-- outside their base when it passes drops the brainrot they are carrying.
GameConfig.WaveWarningSeconds = 10
GameConfig.WaveIntervalSeconds = 75
GameConfig.WaveSpeed = 26 -- studs per second the soup wall travels

-- Rebirths wipe money and carried finds but keep placed legends marked with a
-- star, and each rebirth permanently raises all income.
GameConfig.RebirthCosts = { 25000, 150000, 750000, 3000000, 12000000 }
GameConfig.RebirthIncomeBonus = 0.5 -- +50% income per rebirth

-- Steal defence: a base lock that a visiting player cannot pass while it is
-- up. The owner toggles it at their base; it recharges after each use.
GameConfig.LockSeconds = 20
GameConfig.LockCooldownSeconds = 45

-- How often the server pays out placed characters' income.
GameConfig.IncomeTickSeconds = 1

-- Plot layout: bases ring the plaza at this radius, shop at the centre.
GameConfig.PlazaRadius = 34
GameConfig.BaseRingRadius = 86
GameConfig.MapSize = 260

function GameConfig.formatMoney(amount)
	amount = math.floor(amount)
	if amount >= 1000000 then
		return string.format("$%.2fM", amount / 1000000)
	elseif amount >= 1000 then
		return string.format("$%.1fK", amount / 1000)
	end
	return "$" .. tostring(amount)
end

function GameConfig.rebirthCost(rebirthsDone)
	return GameConfig.RebirthCosts[rebirthsDone + 1]
end

return GameConfig
