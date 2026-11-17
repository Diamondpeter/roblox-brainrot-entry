-- Effects.client.luau
-- Small client polish that makes the 3D world feel alive: a gentle bob and
-- spin for the brainrot floating over your head while you carry it home,
-- sparkles on Nebula-rarity finds, and a screen shake as the Soup Tsunami
-- passes. Purely visual: every rule still lives on the server.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer

local function bobCarriedBrainrot()
	local character = player.Character
	if not character then
		return
	end
	local carried = character:FindFirstChild("CarriedBrainrot")
	if not carried or not carried.PrimaryPart then
		return
	end
	-- The carried model is welded to the head; a soft scale pulse reads as a
	-- happy bounce without fighting the weld.
	local t = os.clock()
	local label = carried:FindFirstChild("NameLabel")
	if label then
		label.StudsOffset = Vector3.new(0, 2 + math.sin(t * 3) * 0.15, 0)
	end
end

local function sparkleNebulaFinds()
	-- Nebula brainrots on pedestals get a slow rainbow shimmer on their label.
	for _, base in ipairs(Workspace:WaitForChild("Bases"):GetChildren()) do
		for _, child in ipairs(base:GetChildren()) do
			if child:IsA("Model") and child:GetAttribute("Rarity") == "Nebula" then
				local label = child:FindFirstChild("NameLabel")
				local nameText = label and label:FindFirstChild("NameText")
				if nameText then
					nameText.TextColor3 = Color3.fromHSV((os.clock() * 0.2) % 1, 0.7, 1)
				end
			end
		end
	end
end

local shakeUntil = 0
local function watchTsunami()
	local wave = Workspace:WaitForChild("SoupTsunami", 10)
	if not wave then
		return
	end
	local wasUp = false
	while true do
		local up = wave.Position.Y > 0
		if up and not wasUp then
			shakeUntil = os.clock() + 2.5
		end
		wasUp = up
		task.wait(0.25)
	end
end
task.spawn(watchTsunami)

RunService.RenderStepped:Connect(function()
	bobCarriedBrainrot()
	sparkleNebulaFinds()
	if os.clock() < shakeUntil then
		local camera = Workspace.CurrentCamera
		if camera then
			local strength = 0.25
			camera.CFrame = camera.CFrame * CFrame.new(
				(math.random() - 0.5) * strength,
				(math.random() - 0.5) * strength,
				0
			)
		end
	end
end)
