-- EconomyService.luau (server module)
-- The whole money game, kept server-side so no client can invent cash:
-- player wallets, carried finds, buying from the conveyor, hatching the
-- Gacha Noodle Pot, placing brainrots on base pedestals where they earn
-- money per second, base locks against stealing, and rebirths.
-- State lives in one table here; the client only ever receives a snapshot
-- through the StateChanged remote and asks through the Action remote.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local BrainrotData = require(Shared:WaitForChild("BrainrotData"))
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local CharacterFactory = require(script.Parent:WaitForChild("CharacterFactory"))
local WorldBuilder = require(script.Parent:WaitForChild("WorldBuilder"))

local EconomyService = {}
EconomyService.States = {} -- [Player] = state table
EconomyService.Bases = {} -- [baseIndex] = Player

local random = Random.new()
local remotes

local function snapshot(player)
	local s = EconomyService.States[player]
	if not s then
		return nil
	end
	local placed = {}
	for slot, entry in pairs(s.Placed) do
		placed[tostring(slot)] = entry
	end
	return {
		Money = s.Money,
		Rebirths = s.Rebirths,
		Carried = s.Carried,
		Placed = placed,
		BaseIndex = s.BaseIndex,
		IncomePerSecond = EconomyService.incomePerSecond(player),
		LockReadyAt = s.LockReadyAt,
	}
end

function EconomyService.incomePerSecond(player)
	local s = EconomyService.States[player]
	if not s then
		return 0
	end
	local bonus = s.Rebirths * GameConfig.RebirthIncomeBonus
	local total = 0
	for _, entry in pairs(s.Placed) do
		local character = BrainrotData.getCharacter(entry.Id)
		if character then
			total += BrainrotData.incomePerSecond(character, entry.Rarity, entry.Mutation, bonus)
		end
	end
	return total
end

function EconomyService.sendState(player)
	if remotes then
		remotes.StateChanged:FireClient(player, snapshot(player))
	end
end

function EconomyService.giveCarriedModel(player, entry)
	-- Show the carried brainrot floating over the player's head.
	local character = player.Character
	if not character then
		return
	end
	local old = character:FindFirstChild("CarriedBrainrot")
	if old then
		old:Destroy()
	end
	local characterData = BrainrotData.getCharacter(entry.Id)
	local income = BrainrotData.incomePerSecond(characterData, entry.Rarity, entry.Mutation, 0)
	local model = CharacterFactory.build(entry.Id, entry.Rarity, entry.Mutation, income)
	model.Name = "CarriedBrainrot"
	local head = character:FindFirstChild("Head")
	if head then
		model:PivotTo(head.CFrame * CFrame.new(0, 3.4, 0))
		for _, part in ipairs(model:GetDescendants()) do
			if part:IsA("BasePart") then
				part.Anchored = false
			end
		end
		local body = model.PrimaryPart
		if body then
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = head
			weld.Part1 = body
			weld.Parent = body
		end
	end
	model.Parent = character
end

function EconomyService.clearCarriedModel(player)
	local character = player.Character
	local old = character and character:FindFirstChild("CarriedBrainrot")
	if old then
		old:Destroy()
	end
end

-- Place the carried brainrot on the first free pedestal of the player's
-- base, where it starts earning. Returns true when it was placed.
function EconomyService.placeCarried(player)
	local s = EconomyService.States[player]
	if not s or not s.Carried or not s.BaseIndex then
		return false
	end
	for slot = 1, GameConfig.BaseSlots do
		if not s.Placed[slot] then
			s.Placed[slot] = s.Carried
			s.Carried = nil
			EconomyService.clearCarriedModel(player)
			EconomyService.refreshPedestal(player, slot)
			EconomyService.sendState(player)
			return true
		end
	end
	return false
end

function EconomyService.refreshPedestal(player, slot)
	local s = EconomyService.States[player]
	local baseFolder = Workspace:WaitForChild("Bases"):FindFirstChild("Base" .. tostring(s.BaseIndex))
	if not baseFolder then
		return
	end
	local pedestals = baseFolder:WaitForChild("Pedestals")
	local pedestal = pedestals:FindFirstChild("Pedestal" .. tostring(slot))
	if not pedestal then
		return
	end
	local old = baseFolder:FindFirstChild("Display" .. tostring(slot))
	if old then
		old:Destroy()
	end
	local entry = s.Placed[slot]
	if not entry then
		return
	end
	local character = BrainrotData.getCharacter(entry.Id)
	local income = BrainrotData.incomePerSecond(character, entry.Rarity, entry.Mutation, s.Rebirths * GameConfig.RebirthIncomeBonus)
	local model = CharacterFactory.build(entry.Id, entry.Rarity, entry.Mutation, income)
	model.Name = "Display" .. tostring(slot)
	model:PivotTo(pedestal.CFrame * CFrame.new(0, 1 + character.Body.Height / 2, 0))
	model.Parent = baseFolder
end

-- Claim the first empty base for a joining player and rebuild its sign.
function EconomyService.claimBase(player)
	for index = 1, GameConfig.MaxPlayersWithBases do
		if not EconomyService.Bases[index] then
			EconomyService.Bases[index] = player
			local bases = Workspace:WaitForChild("Bases")
			local old = bases:FindFirstChild("Base" .. tostring(index))
			if old then
				old:Destroy()
			end
			WorldBuilder.buildBase(index, player.DisplayName)
			return index
		end
	end
	return nil
end

function EconomyService.buyConveyor(player, model)
	local s = EconomyService.States[player]
	if not s or s.Carried then
		return
	end
	local price = model:GetAttribute("Price")
	local id = model:GetAttribute("BrainrotId")
	if not price or not id or s.Money < price then
		return
	end
	s.Money -= price
	s.Carried = {
		Id = id,
		Rarity = model:GetAttribute("Rarity") or "Common",
		Mutation = model:GetAttribute("Mutation") or "Normal",
	}
	model:Destroy()
	EconomyService.giveCarriedModel(player, s.Carried)
	EconomyService.sendState(player)
	remotes.Toast:FireClient(player, "Bought! Carry it home and step on a pedestal.")
end

function EconomyService.rollGacha(player)
	local s = EconomyService.States[player]
	if not s or s.Carried or s.Money < GameConfig.GachaCost then
		return
	end
	s.Money -= GameConfig.GachaCost
	local character = BrainrotData.Characters[random:NextInteger(1, #BrainrotData.Characters)]
	local rarity = BrainrotData.rollWeighted(random, BrainrotData.Rarities)
	local mutation = BrainrotData.rollWeighted(random, BrainrotData.Mutations)
	s.Carried = { Id = character.Id, Rarity = rarity.Name, Mutation = mutation.Name }
	EconomyService.giveCarriedModel(player, s.Carried)
	EconomyService.sendState(player)
	remotes.Toast:FireClient(player, "The Noodle Pot gives you: " .. rarity.Name .. " " .. character.Name .. "!")
end

function EconomyService.doRebirth(player)
	local s = EconomyService.States[player]
	if not s then
		return
	end
	local cost = GameConfig.rebirthCost(s.Rebirths)
	if not cost or s.Money < cost then
		return
	end
	s.Rebirths += 1
	s.Money = 0
	s.Carried = nil
	EconomyService.clearCarriedModel(player)
	for slot in pairs(s.Placed) do
		EconomyService.refreshPedestal(player, slot)
	end
	EconomyService.sendState(player)
	remotes.Toast:FireClient(player, "REBIRTH " .. tostring(s.Rebirths) .. "! All income +50% forever.")
end

-- A visitor stepping on an unlocked base's pedestal steals that brainrot
-- into their hands if they are carrying nothing: the genre's core tension.
function EconomyService.trySteal(player, baseIndex, slot)
	local s = EconomyService.States[player]
	local owner = EconomyService.Bases[baseIndex]
	if not s or s.Carried or not owner or owner == player then
		return
	end
	local ownerState = EconomyService.States[owner]
	if not ownerState or os.clock() < (ownerState.LockUntil or 0) then
		return
	end
	local entry = ownerState.Placed[slot]
	if not entry then
		return
	end
	ownerState.Placed[slot] = nil
	s.Carried = entry
	EconomyService.refreshPedestal(owner, slot)
	EconomyService.giveCarriedModel(player, entry)
	EconomyService.sendState(player)
	EconomyService.sendState(owner)
	remotes.Toast:FireClient(owner, "STOLEN! A visitor grabbed a brainrot. Lock your base!")
	remotes.Toast:FireClient(player, "Stolen! RUN home before the owner catches up!")
end

function EconomyService.toggleLock(player)
	local s = EconomyService.States[player]
	if not s or os.clock() < (s.LockReadyAt or 0) then
		return
	end
	s.LockUntil = os.clock() + GameConfig.LockSeconds
	s.LockReadyAt = os.clock() + GameConfig.LockSeconds + GameConfig.LockCooldownSeconds
	EconomyService.sendState(player)
	remotes.Toast:FireClient(player, "Base LOCKED for " .. tostring(GameConfig.LockSeconds) .. "s.")
end

-- The tsunami caught this player outside home: the carried find is lost.
function EconomyService.dropCarried(player, reason)
	local s = EconomyService.States[player]
	if s and s.Carried then
		s.Carried = nil
		EconomyService.clearCarriedModel(player)
		EconomyService.sendState(player)
		remotes.Toast:FireClient(player, reason)
	end
end

function EconomyService.init(remoteFolder)
	remotes = {
		StateChanged = remoteFolder:WaitForChild("StateChanged"),
		Action = remoteFolder:WaitForChild("Action"),
		Toast = remoteFolder:WaitForChild("Toast"),
		WaveWarning = remoteFolder:WaitForChild("WaveWarning"),
	}
	remotes.Action.OnServerEvent:Connect(function(player, action, arg)
		if action == "RollGacha" then
			EconomyService.rollGacha(player)
		elseif action == "Rebirth" then
			EconomyService.doRebirth(player)
		elseif action == "LockBase" then
			EconomyService.toggleLock(player)
		elseif action == "PlaceCarried" then
			EconomyService.placeCarried(player)
		end
	end)

	Players.PlayerAdded:Connect(function(player)
		local state = {
			Money = GameConfig.StartingMoney,
			Rebirths = 0,
			Carried = nil,
			Placed = {},
			LockUntil = 0,
			LockReadyAt = 0,
		}
		state.BaseIndex = EconomyService.claimBase(player)
		EconomyService.States[player] = state
		local leaderstats = Instance.new("Folder")
		leaderstats.Name = "leaderstats"
		local cash = Instance.new("IntValue")
		cash.Name = "NoodleBucks"
		cash.Value = state.Money
		cash.Parent = leaderstats
		leaderstats.Parent = player
		state.CashValue = cash
		player.CharacterAdded:Connect(function()
			task.wait(0.5)
			if state.BaseIndex then
				local centre = WorldBuilder.basePosition(state.BaseIndex)
				local character = player.Character
				if character then
					character:PivotTo(CFrame.new(centre + Vector3.new(0, 4, -14)))
				end
			end
			if state.Carried then
				EconomyService.giveCarriedModel(player, state.Carried)
			end
		end)
		EconomyService.sendState(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		local s = EconomyService.States[player]
		if s and s.BaseIndex then
			EconomyService.Bases[s.BaseIndex] = nil
		end
		EconomyService.States[player] = nil
	end)

	-- The income tick: every second, placed brainrots pay their owners.
	task.spawn(function()
		while true do
			task.wait(GameConfig.IncomeTickSeconds)
			for player, s in pairs(EconomyService.States) do
				local income = EconomyService.incomePerSecond(player)
				if income > 0 then
					s.Money += income
					if s.CashValue then
						s.CashValue.Value = math.floor(s.Money)
					end
					EconomyService.sendState(player)
				end
			end
		end
	end)
end

return EconomyService
