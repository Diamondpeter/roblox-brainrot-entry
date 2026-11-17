-- CharacterFactory.luau (server module)
-- Builds a brainrot character as a 3D Model of parts from its BrainrotData
-- body recipe: a shaped body, two eyes, a hat that matches its joke, and a
-- floating BillboardGui label with its name, rarity and money-per-second.
-- Used for conveyor stock, wandering wild brainrots, gacha reveals and the
-- copies that stand on a player's base pedestals earning money.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BrainrotData = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("BrainrotData"))

local CharacterFactory = {}

local function makePart(name, shape, size, color, material)
	local part = Instance.new("Part")
	part.Name = name
	part.Shape = shape
	part.Size = size
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.CanCollide = false
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	return part
end

local function addHat(model, body, hatStyle, accent, height)
	if hatStyle == "None" then
		return
	end
	local hat
	if hatStyle == "Wizard" then
		hat = makePart("Hat", Enum.PartType.Cylinder, Vector3.new(0.2, 1.4, 1.4), accent)
		hat.CFrame = body.CFrame * CFrame.new(0, height / 2 + 0.6, 0) * CFrame.Angles(0, 0, math.rad(90))
	elseif hatStyle == "Cone" or hatStyle == "Sock" then
		hat = makePart("Hat", Enum.PartType.Block, Vector3.new(0.9, 1.1, 0.9), accent)
		hat.CFrame = body.CFrame * CFrame.new(0, height / 2 + 0.5, 0) * CFrame.Angles(0, 0, math.rad(12))
	elseif hatStyle == "DiscoBall" then
		hat = makePart("Hat", Enum.PartType.Ball, Vector3.new(1.1, 1.1, 1.1), accent, Enum.Material.Neon)
		hat.CFrame = body.CFrame * CFrame.new(0, height / 2 + 0.7, 0)
	elseif hatStyle == "Crown" then
		hat = makePart("Hat", Enum.PartType.Block, Vector3.new(1.3, 0.5, 1.3), Color3.fromRGB(255, 205, 44), Enum.Material.Metal)
		hat.CFrame = body.CFrame * CFrame.new(0, height / 2 + 0.25, 0)
	elseif hatStyle == "Fin" then
		hat = makePart("Hat", Enum.PartType.Block, Vector3.new(0.2, 1.0, 0.9), accent)
		hat.CFrame = body.CFrame * CFrame.new(0, height / 2 + 0.4, 0)
	elseif hatStyle == "Horns" then
		hat = makePart("Hat", Enum.PartType.Ball, Vector3.new(1.5, 0.4, 0.4), accent)
		hat.CFrame = body.CFrame * CFrame.new(0, height / 2 + 0.3, 0)
	elseif hatStyle == "Cap" or hatStyle == "Bun" then
		hat = makePart("Hat", Enum.PartType.Ball, Vector3.new(1.0, 0.5, 1.0), accent)
		hat.CFrame = body.CFrame * CFrame.new(0, height / 2 + 0.2, 0)
	else
		hat = makePart("Hat", Enum.PartType.Ball, Vector3.new(0.8, 0.8, 0.8), accent)
		hat.CFrame = body.CFrame * CFrame.new(0, height / 2 + 0.5, 0)
	end
	hat.Parent = model
end

-- build(characterId, rarityName, mutationName, incomePerSec) -> Model
-- The model carries attributes the economy and the HUD read: BrainrotId,
-- Rarity, Mutation and IncomePerSecond, plus a Name label over its head.
function CharacterFactory.build(characterId, rarityName, mutationName, incomePerSec)
	local character = BrainrotData.getCharacter(characterId)
	assert(character, "unknown brainrot id " .. tostring(characterId))
	local rarity = BrainrotData.getRarity(rarityName)
	local mutation = BrainrotData.getMutation(mutationName)
	local recipe = character.Body
	local height = recipe.Height

	local model = Instance.new("Model")
	model.Name = character.Name
	model:SetAttribute("BrainrotId", characterId)
	model:SetAttribute("Rarity", rarity.Name)
	model:SetAttribute("Mutation", mutation.Name)
	model:SetAttribute("IncomePerSecond", incomePerSec)

	local shape = Enum.PartType.Block
	if recipe.Shape == "Ball" then
		shape = Enum.PartType.Ball
	elseif recipe.Shape == "Cylinder" then
		shape = Enum.PartType.Cylinder
	end
	local bodyColor = recipe.Color
	if mutation.Name == "Golden" then
		bodyColor = Color3.fromRGB(255, 205, 44)
	elseif mutation.Name == "Void" then
		bodyColor = Color3.fromRGB(60, 40, 110)
	end
	local body = makePart("Body", shape, Vector3.new(1.8, height, 1.8), bodyColor)
	if mutation.Name == "Rainbow" then
		body.Material = Enum.Material.Neon
	end
	body.CanCollide = true
	body.Parent = model
	model.PrimaryPart = body

	-- Two white eyes with dark pupils on the body's front face.
	for _, side in ipairs({ -0.45, 0.45 }) do
		local eye = makePart("Eye", Enum.PartType.Ball, Vector3.new(0.42, 0.42, 0.42), Color3.fromRGB(255, 255, 255))
		eye.CFrame = body.CFrame * CFrame.new(side, height * 0.18, -0.85)
		eye.Parent = model
		local pupil = makePart("Pupil", Enum.PartType.Ball, Vector3.new(0.2, 0.2, 0.2), Color3.fromRGB(20, 20, 25))
		pupil.CFrame = body.CFrame * CFrame.new(side, height * 0.18, -1.05)
		pupil.Parent = model
	end

	addHat(model, body, recipe.Hat, recipe.Accent, height)

	-- A little accent belly plate so each silhouette reads at a distance.
	local belly = makePart("Belly", Enum.PartType.Block, Vector3.new(1.1, height * 0.4, 0.15), recipe.Accent)
	belly.CFrame = body.CFrame * CFrame.new(0, -height * 0.2, -0.95)
	belly.Parent = model

	-- Floating label: name, rarity in its rarity colour, and the earn rate.
	local label = Instance.new("BillboardGui")
	label.Name = "NameLabel"
	label.Size = UDim2.fromOffset(220, 64)
	label.StudsOffset = Vector3.new(0, height / 2 + 1.6, 0)
	label.AlwaysOnTop = true
	label.MaxDistance = 90

	local nameText = Instance.new("TextLabel")
	nameText.Name = "NameText"
	nameText.Size = UDim2.new(1, 0, 0.5, 0)
	nameText.BackgroundTransparency = 1
	nameText.Text = (mutation.Name ~= "Normal" and (mutation.Name .. " ") or "") .. character.Name
	nameText.TextColor3 = rarity.Color
	nameText.TextStrokeTransparency = 0.4
	nameText.TextScaled = true
	nameText.Font = Enum.Font.FredokaOne
	nameText.Parent = label

	local rateText = Instance.new("TextLabel")
	rateText.Name = "RateText"
	rateText.Position = UDim2.new(0, 0, 0.5, 0)
	rateText.Size = UDim2.new(1, 0, 0.5, 0)
	rateText.BackgroundTransparency = 1
	rateText.Text = rarity.Name .. "  $" .. tostring(incomePerSec) .. "/s"
	rateText.TextColor3 = Color3.fromRGB(255, 255, 255)
	rateText.TextStrokeTransparency = 0.4
	rateText.TextScaled = true
	rateText.Font = Enum.Font.FredokaOne
	rateText.Parent = label

	label.Adornee = body
	label.Parent = model

	-- Weld every extra part to the body so the model moves as one character.
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") and part ~= body then
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = body
			weld.Part1 = part
			weld.Parent = body
		end
	end

	return model
end

return CharacterFactory
