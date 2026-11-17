-- WorldBuilder.luau (server module)
-- Builds the 3D world the static place does not already hold: the wandering
-- wild brainrots in the meadow, the conveyor stock in the plaza and the soup
-- wall for the tsunami. The bases, plaza, shop and decorations are also laid
-- out here from code so one function can rebuild a base the moment a player
-- claims it, with its six pedestals, its lock pad and its income sign.
-- The static Workspace in game.rbxl holds the same ground, plaza and bases,
-- so the world reads complete in the place file as well as live.

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local BrainrotData = require(Shared:WaitForChild("BrainrotData"))
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local CharacterFactory = require(script.Parent:WaitForChild("CharacterFactory"))

local WorldBuilder = {}

local function part(parent, name, size, cframe, color, material)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cframe
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

-- The centre of base i (1..8) on the ring around the plaza.
function WorldBuilder.basePosition(index)
	local angle = (index - 1) / GameConfig.MaxPlayersWithBases * math.pi * 2
	return Vector3.new(math.cos(angle) * GameConfig.BaseRingRadius, 0, math.sin(angle) * GameConfig.BaseRingRadius), angle
end

-- Build (or rebuild) one player's base: floor, back wall, six pedestals in
-- two rows, a lock pad at the door and a big sign the HUD income board uses.
function WorldBuilder.buildBase(index, ownerName)
	local folder = Instance.new("Folder")
	folder.Name = "Base" .. tostring(index)
	folder:SetAttribute("BaseIndex", index)
	local centre, angle = WorldBuilder.basePosition(index)
	local facing = CFrame.lookAt(centre, Vector3.new(0, 0, 0)) * CFrame.new(0, 0, 0)
	local function localPart(name, offset, size, color, material)
		local cf = facing * CFrame.new(offset) 
		return part(folder, name, size, cf, color, material)
	end
	localPart("Floor", Vector3.new(0, 0.25, 0), Vector3.new(30, 0.5, 22), Color3.fromRGB(88, 70, 130))
	localPart("BackWall", Vector3.new(0, 4, 10.5), Vector3.new(30, 8, 1), Color3.fromRGB(60, 48, 96))
	localPart("RoofTrim", Vector3.new(0, 8.4, 10.5), Vector3.new(31, 0.8, 2), Color3.fromRGB(255, 92, 205), Enum.Material.Neon)
	localPart("LockPad", Vector3.new(0, 0.6, -9), Vector3.new(6, 0.4, 4), Color3.fromRGB(64, 200, 255), Enum.Material.Neon)

	local pedestals = Instance.new("Folder")
	pedestals.Name = "Pedestals"
	pedestals.Parent = folder
	for slot = 1, GameConfig.BaseSlots do
		local row = slot <= 3 and -3.5 or 3.5
		local col = ((slot - 1) % 3 - 1) * 8
		local cf = facing * CFrame.new(col, 1, row + 4)
		local ped = part(pedestals, "Pedestal" .. tostring(slot), Vector3.new(3.4, 2, 3.4), cf, Color3.fromRGB(230, 225, 245), Enum.Material.Marble)
		ped:SetAttribute("Slot", slot)
	end

	local sign = Instance.new("Part")
	sign.Name = "OwnerSign"
	sign.Size = Vector3.new(16, 3, 0.4)
	sign.CFrame = facing * CFrame.new(0, 6.4, 9.8)
	sign.Color = Color3.fromRGB(35, 30, 55)
	sign.Anchored = true
	sign.Parent = folder
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.Parent = sign
	local text = Instance.new("TextLabel")
	text.Name = "SignText"
	text.Size = UDim2.fromScale(1, 1)
	text.BackgroundTransparency = 1
	text.Text = ownerName and (ownerName .. "'s Bazaar Base") or "Empty Base - walk in to claim"
	text.TextColor3 = Color3.fromRGB(255, 255, 255)
	text.TextScaled = true
	text.Font = Enum.Font.FredokaOne
	text.Parent = gui

	folder.Parent = Workspace:WaitForChild("Bases")
	return folder
end

-- A wild brainrot that wanders the meadow waiting to be caught: walk on it
-- (the economy listens for the touch) and it becomes your carried find.
function WorldBuilder.spawnWildBrainrot(random)
	local meadow = Workspace:WaitForChild("WildMeadow")
	local character = BrainrotData.Characters[random:NextInteger(1, 6)]
	local rarity = BrainrotData.rollWeighted(random, BrainrotData.Rarities)
	local mutation = BrainrotData.rollWeighted(random, BrainrotData.Mutations)
	local income = BrainrotData.incomePerSecond(character, rarity.Name, mutation.Name, 0)
	local model = CharacterFactory.build(character.Id, rarity.Name, mutation.Name, income)
	local x = random:NextNumber(-52, 52)
	local z = random:NextNumber(48, 108)
	model:PivotTo(CFrame.new(x, 3, z))
	model:SetAttribute("Wild", true)
	model.Parent = meadow
	-- Wander: drift to a new nearby point every few seconds until caught.
	task.spawn(function()
		while model.Parent do
			local target = Vector3.new(math.clamp(x + random:NextNumber(-16, 16), -58, 58), 3, math.clamp(z + random:NextNumber(-12, 12), 42, 114))
			local start = model:GetPivot().Position
			for step = 1, 20 do
				if not model.Parent then
					return
				end
				local pos = start:Lerp(target, step / 20)
				model:PivotTo(CFrame.new(pos) * CFrame.Angles(0, step * 0.15, 0))
				task.wait(0.08)
			end
			x, z = target.X, target.Z
			task.wait(random:NextNumber(0.5, 2))
		end
	end)
	return model
end

-- The plaza conveyor: a slow belt of brainrots for sale at list price.
function WorldBuilder.spawnConveyorStock(random)
	local belt = Workspace:WaitForChild("Conveyor")
	for _, old in ipairs(belt:GetChildren()) do
		if old:IsA("Model") then
			old:Destroy()
		end
	end
	for i = 1, 4 do
		local character = BrainrotData.Characters[random:NextInteger(1, #BrainrotData.Characters)]
		local rarity = BrainrotData.rollWeighted(random, BrainrotData.Rarities)
		local mutation = BrainrotData.rollWeighted(random, BrainrotData.Mutations)
		local income = BrainrotData.incomePerSecond(character, rarity.Name, mutation.Name, 0)
		local model = CharacterFactory.build(character.Id, rarity.Name, mutation.Name, income)
		model:PivotTo(CFrame.new(-18 + (i - 1) * 12, 3.2, 0) * CFrame.Angles(0, math.rad(180), 0))
		model:SetAttribute("ForSale", true)
		model:SetAttribute("Price", character.Price)
		model.Parent = belt
	end
end

-- The Soup Tsunami wall: one wide, tall, tomato-red wave part that the
-- WaveService slides across the map. Hidden below the ground between waves.
function WorldBuilder.buildWave()
	local wave = Instance.new("Part")
	wave.Name = "SoupTsunami"
	wave.Size = Vector3.new(10, 26, 300)
	wave.Color = Color3.fromRGB(232, 64, 40)
	wave.Material = Enum.Material.SmoothPlastic
	wave.Transparency = 0.15
	wave.Anchored = true
	wave.CanCollide = false
	wave.CFrame = CFrame.new(-220, -30, 0)
	wave.Parent = Workspace
	local foam = Instance.new("Part")
	foam.Name = "FoamCrest"
	foam.Size = Vector3.new(11, 3, 300)
	foam.Color = Color3.fromRGB(255, 240, 220)
	foam.Anchored = true
	foam.CanCollide = false
	foam.CFrame = CFrame.new(-220, -16, 0)
	foam.Parent = Workspace
	return wave, foam
end

return WorldBuilder
