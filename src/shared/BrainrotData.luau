-- BrainrotData.luau
-- The single source of truth for the Brainrot Bazaar cast.
-- Every character here is an original Noodle Nebula invention: a name, a rarity,
-- a price, a money-per-second rate, a body recipe (parts the CharacterFactory
-- builds in 3D) and a one-line joke the HUD and the pedestal labels show.
-- Server and client both read this module, so a name, rate or price can never
-- disagree between the shop, the base pedestals and the collection book.

local BrainrotData = {}

-- Rarity ladder, cheapest first. The multiplier scales a character's base
-- income when it is rolled at that rarity by the Gacha Noodle Pot.
BrainrotData.Rarities = {
	{ Name = "Common", Color = Color3.fromRGB(196, 201, 212), Weight = 46, IncomeMultiplier = 1 },
	{ Name = "Rare", Color = Color3.fromRGB(64, 156, 255), Weight = 28, IncomeMultiplier = 2 },
	{ Name = "Epic", Color = Color3.fromRGB(178, 82, 255), Weight = 15, IncomeMultiplier = 4 },
	{ Name = "Legendary", Color = Color3.fromRGB(255, 176, 32), Weight = 8, IncomeMultiplier = 9 },
	{ Name = "Nebula", Color = Color3.fromRGB(255, 92, 205), Weight = 3, IncomeMultiplier = 20 },
}

-- Mutations are a second ladder rolled on top of rarity when a character is
-- bought from the conveyor or hatched from the Gacha Noodle Pot.
BrainrotData.Mutations = {
	{ Name = "Normal", Color = Color3.fromRGB(255, 255, 255), Weight = 70, IncomeMultiplier = 1 },
	{ Name = "Golden", Color = Color3.fromRGB(255, 205, 44), Weight = 18, IncomeMultiplier = 2 },
	{ Name = "Rainbow", Color = Color3.fromRGB(120, 255, 170), Weight = 9, IncomeMultiplier = 5 },
	{ Name = "Void", Color = Color3.fromRGB(90, 60, 160), Weight = 3, IncomeMultiplier = 10 },
}

-- The cast. Body = the CharacterFactory recipe: a main part shape, a body
-- colour, an accent colour, a hat style and how tall the character stands.
-- Income is money per second at Common / Normal, before rarity and mutation.
BrainrotData.Characters = {
	{
		Id = "sock_gremlin", Name = "Sock Gremlin", Price = 25, Income = 1,
		Tagline = "Lives in your laundry. Pays rent in lint.",
		Body = { Shape = "Block", Color = Color3.fromRGB(140, 200, 120), Accent = Color3.fromRGB(255, 120, 120), Hat = "Sock", Height = 2.2 },
	},
	{
		Id = "toast_goblin", Name = "Toast Goblin", Price = 60, Income = 2,
		Tagline = "Butter side up, always. Nobody knows how.",
		Body = { Shape = "Block", Color = Color3.fromRGB(232, 178, 96), Accent = Color3.fromRGB(120, 72, 30), Hat = "None", Height = 2.0 },
	},
	{
		Id = "puddle_duck", Name = "Puddle Duck", Price = 140, Income = 4,
		Tagline = "Every puddle is a five-star hotel to him.",
		Body = { Shape = "Ball", Color = Color3.fromRGB(255, 224, 84), Accent = Color3.fromRGB(255, 140, 40), Hat = "None", Height = 1.8 },
	},
	{
		Id = "banana_wizard", Name = "Banana Wizard", Price = 320, Income = 8,
		Tagline = "His spells slip people up. Literally.",
		Body = { Shape = "Block", Color = Color3.fromRGB(255, 232, 92), Accent = Color3.fromRGB(90, 60, 180), Hat = "Wizard", Height = 2.6 },
	},
	{
		Id = "chair_shark", Name = "Chair Shark", Price = 700, Income = 15,
		Tagline = "Do not sit. The chair bites back now.",
		Body = { Shape = "Block", Color = Color3.fromRGB(110, 160, 200), Accent = Color3.fromRGB(240, 240, 240), Hat = "Fin", Height = 2.4 },
	},
	{
		Id = "fridge_yeti", Name = "Fridge Yeti", Price = 1500, Income = 30,
		Tagline = "Guards the midnight snacks of the Nebula.",
		Body = { Shape = "Block", Color = Color3.fromRGB(225, 240, 245), Accent = Color3.fromRGB(90, 180, 220), Hat = "None", Height = 3.2 },
	},
	{
		Id = "disco_cactus", Name = "Disco Cactus", Price = 3200, Income = 58,
		Tagline = "Hug him and you dance forever. Spiky forever.",
		Body = { Shape = "Cylinder", Color = Color3.fromRGB(60, 180, 90), Accent = Color3.fromRGB(255, 92, 205), Hat = "DiscoBall", Height = 3.0 },
	},
	{
		Id = "traffic_cone_gnome", Name = "Traffic Cone Gnome", Price = 6500, Income = 110,
		Tagline = "Redirects destiny. And traffic. Mostly traffic.",
		Body = { Shape = "Cylinder", Color = Color3.fromRGB(255, 120, 40), Accent = Color3.fromRGB(245, 245, 245), Hat = "Cone", Height = 2.4 },
	},
	{
		Id = "moon_noodle_dragon", Name = "Moon Noodle Dragon", Price = 14000, Income = 220,
		Tagline = "Breathes steam. Smells faintly of ramen.",
		Body = { Shape = "Block", Color = Color3.fromRGB(150, 130, 255), Accent = Color3.fromRGB(255, 220, 120), Hat = "Horns", Height = 3.8 },
	},
	{
		Id = "grandma_roomba", Name = "Grandma Roomba", Price = 30000, Income = 430,
		Tagline = "Cleans the whole map and judges your life choices.",
		Body = { Shape = "Cylinder", Color = Color3.fromRGB(200, 200, 210), Accent = Color3.fromRGB(255, 150, 190), Hat = "Bun", Height = 1.6 },
	},
	{
		Id = "captain_washing_machine", Name = "Captain Washing Machine", Price = 65000, Income = 850,
		Tagline = "Spin cycle of justice. Socks fear him.",
		Body = { Shape = "Block", Color = Color3.fromRGB(210, 220, 235), Accent = Color3.fromRGB(60, 120, 255), Hat = "Cap", Height = 3.4 },
	},
	{
		Id = "emperor_spatula", Name = "Emperor Spatula", Price = 140000, Income = 1700,
		Tagline = "Flipped a pancake so hard it became a moon.",
		Body = { Shape = "Block", Color = Color3.fromRGB(255, 190, 60), Accent = Color3.fromRGB(180, 40, 60), Hat = "Crown", Height = 4.2 },
	},
}

local byId = {}
for _, character in ipairs(BrainrotData.Characters) do
	byId[character.Id] = character
end

function BrainrotData.getCharacter(id)
	return byId[id]
end

function BrainrotData.getRarity(name)
	for _, rarity in ipairs(BrainrotData.Rarities) do
		if rarity.Name == name then
			return rarity
		end
	end
	return BrainrotData.Rarities[1]
end

function BrainrotData.getMutation(name)
	for _, mutation in ipairs(BrainrotData.Mutations) do
		if mutation.Name == name then
			return mutation
		end
	end
	return BrainrotData.Mutations[1]
end

-- Weighted pick from a ladder table (Rarities or Mutations). The caller passes
-- its Random so the server stays the one rolling the dice.
function BrainrotData.rollWeighted(random, ladder)
	local total = 0
	for _, entry in ipairs(ladder) do
		total += entry.Weight
	end
	local roll = random:NextNumber(0, total)
	for _, entry in ipairs(ladder) do
		roll -= entry.Weight
		if roll <= 0 then
			return entry
		end
	end
	return ladder[1]
end

-- The money a placed character earns each second, with its rarity and
-- mutation multipliers applied and the owner's rebirth bonus on top.
function BrainrotData.incomePerSecond(character, rarityName, mutationName, rebirthBonus)
	local rarity = BrainrotData.getRarity(rarityName)
	local mutation = BrainrotData.getMutation(mutationName)
	return character.Income * rarity.IncomeMultiplier * mutation.IncomeMultiplier * (1 + (rebirthBonus or 0))
end

return BrainrotData
