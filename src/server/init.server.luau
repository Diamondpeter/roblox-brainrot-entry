-- init.server.luau (ServerScriptService.Server)
-- Brainrot Bazaar: Noodle Nebula -- server entry point.
-- Creates the remotes, starts the economy, restocks the plaza conveyor,
-- keeps the wild meadow full of wandering brainrots to catch, wires the
-- touch points (conveyor buying, pedestal placing and stealing, base locks,
-- the gacha pot) and starts the Soup Tsunami cycle.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local WorldBuilder = require(script:WaitForChild("WorldBuilder"))
local EconomyService = require(script:WaitForChild("EconomyService"))
local WaveService = require(script:WaitForChild("WaveService"))

local random = Random.new(20261117)

-- Remotes the client HUD talks through. Created here so no client can make
-- its own and pretend to be the server.
local remotesFolder = Instance.new("Folder")
remotesFolder.Name = "BrainrotRemotes"
for _, name in ipairs({ "StateChanged", "Toast", "WaveWarning" }) do
	local event = Instance.new("RemoteEvent")
	event.Name = name
	event.Parent = remotesFolder
end
local action = Instance.new("RemoteEvent")
action.Name = "Action"
action.Parent = remotesFolder
remotesFolder.Parent = ReplicatedStorage

EconomyService.init(remotesFolder)
WaveService.init({
	WaveWarning = remotesFolder:WaitForChild("WaveWarning"),
})

-- Conveyor stock, refreshed on a timer so new rarities keep arriving.
WorldBuilder.spawnConveyorStock(random)
task.spawn(function()
	while true do
		task.wait(GameConfig.ConveyorRestockSeconds * 4)
		WorldBuilder.spawnConveyorStock(random)
	end
end)

-- Keep six wild brainrots wandering the meadow at all times.
task.spawn(function()
	while true do
		local meadow = Workspace:WaitForChild("WildMeadow")
		local count = 0
		for _, child in ipairs(meadow:GetChildren()) do
			if child:IsA("Model") then
				count += 1
			end
		end
		while count < 6 do
			WorldBuilder.spawnWildBrainrot(random)
			count += 1
		end
		task.wait(3)
	end
end)

-- Touch wiring ------------------------------------------------------------
local function playerFromPart(part)
	local character = part:FindFirstAncestorOfClass("Model")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		local Players = game:GetService("Players")
		return Players:GetPlayerFromCharacter(character)
	end
	return nil
end

local touchCooldown = {}
local function onTouch(key, part, handler)
	if touchCooldown[key] and os.clock() - touchCooldown[key] < 0.6 then
		return
	end
	local player = playerFromPart(part)
	if not player then
		return
	end
	touchCooldown[key] = os.clock()
	handler(player)
end

-- Stepping on a conveyor brainrot buys it (if you can afford it and your
-- hands are free); stepping on the gacha pot's pad rolls the pot.
local conveyor = Workspace:WaitForChild("Conveyor")
conveyor.ChildAdded:Connect(function(model)
	if not model:IsA("Model") then
		return
	end
	local body = model:WaitForChild("Body", 5)
	if body then
		body.Touched:Connect(function(part)
			onTouch(model, part, function(player)
				EconomyService.buyConveyor(player, model)
			end)
		end)
	end
end)

local gachaPad = Workspace:WaitForChild("Plaza"):WaitForChild("GachaPad")
gachaPad.Touched:Connect(function(part)
	onTouch("gacha", part, function(player)
		EconomyService.rollGacha(player)
	end)
end)

-- Pedestals and lock pads on every base: your own pedestal places your
-- carried brainrot; someone else's pedestal (unlocked) is a steal; your
-- lock pad locks the base. Bases are rebuilt when claimed, so wire each
-- base folder as it appears.
local bases = Workspace:WaitForChild("Bases")
local function wireBase(baseFolder)
	local pedestals = baseFolder:WaitForChild("Pedestals")
	for _, pedestal in ipairs(pedestals:GetChildren()) do
		pedestal.Touched:Connect(function(part)
			onTouch(baseFolder.Name .. pedestal.Name, part, function(player)
				local state = EconomyService.States[player]
				local baseIndex = baseFolder:GetAttribute("BaseIndex")
				if state and state.BaseIndex == baseIndex then
					EconomyService.placeCarried(player)
				else
					EconomyService.trySteal(player, baseIndex, pedestal:GetAttribute("Slot"))
				end
			end)
		end)
	end
	local lockPad = baseFolder:WaitForChild("LockPad")
	lockPad.Touched:Connect(function(part)
		onTouch(baseFolder.Name .. "Lock", part, function(player)
			local state = EconomyService.States[player]
			if state and state.BaseIndex == baseFolder:GetAttribute("BaseIndex") then
				EconomyService.toggleLock(player)
			end
		end)
	end)
end
for _, baseFolder in ipairs(bases:GetChildren()) do
	task.spawn(wireBase, baseFolder)
end
bases.ChildAdded:Connect(function(baseFolder)
	task.spawn(wireBase, baseFolder)
end)

-- Catching a wild brainrot: walk into it and it becomes your carried find.
local meadow = Workspace:WaitForChild("WildMeadow")
meadow.ChildAdded:Connect(function(model)
	if not model:IsA("Model") then
		return
	end
	local body = model:WaitForChild("Body", 5)
	if not body then
		return
	end
	body.Touched:Connect(function(part)
		onTouch(model, part, function(player)
			local state = EconomyService.States[player]
			if state and not state.Carried and model.Parent then
				state.Carried = {
					Id = model:GetAttribute("BrainrotId"),
					Rarity = model:GetAttribute("Rarity") or "Common",
					Mutation = model:GetAttribute("Mutation") or "Normal",
				}
				model:Destroy()
				EconomyService.giveCarriedModel(player, state.Carried)
				EconomyService.sendState(player)
			end
		end)
	end)
end)

print(GameConfig.GameName .. " server ready: conveyor stocked, tsunami armed.")
