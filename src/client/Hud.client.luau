-- Hud.client.luau
-- The ScreenGui HUD over the 3D world: money and income-per-second counters,
-- the carried brainrot card, the placed collection list, buttons for the
-- Gacha Noodle Pot, the base lock and rebirth, a toast line for server news
-- and the big Soup Tsunami warning banner with its countdown.
-- HUD text is kept clear of the top-left corner, where Roblox's own menu
-- buttons sit over the play view.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local BrainrotData = require(Shared:WaitForChild("BrainrotData"))
local GameConfig = require(Shared:WaitForChild("GameConfig"))

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("BrainrotRemotes")
local stateChanged = remotes:WaitForChild("StateChanged")
local action = remotes:WaitForChild("Action")
local toastEvent = remotes:WaitForChild("Toast")
local waveWarning = remotes:WaitForChild("WaveWarning")

local gui = Instance.new("ScreenGui")
gui.Name = "BrainrotHud"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false

local function label(parent, name, position, size, text, color, textSize)
	local l = Instance.new("TextLabel")
	l.Name = name
	l.Position = position
	l.Size = size
	l.BackgroundTransparency = 1
	l.Text = text
	l.TextColor3 = color or Color3.fromRGB(255, 255, 255)
	l.TextStrokeTransparency = 0.5
	l.TextSize = textSize or 20
	l.Font = Enum.Font.FredokaOne
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.Parent = parent
	return l
end

local function panel(parent, name, position, size, color)
	local f = Instance.new("Frame")
	f.Name = name
	f.Position = position
	f.Size = size
	f.BackgroundColor3 = color
	f.BackgroundTransparency = 0.15
	f.BorderSizePixel = 0
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = f
	f.Parent = parent
	return f
end

local function button(parent, name, position, size, text, color)
	local b = Instance.new("TextButton")
	b.Name = name
	b.Position = position
	b.Size = size
	b.BackgroundColor3 = color
	b.Text = text
	b.TextColor3 = Color3.fromRGB(255, 255, 255)
	b.TextStrokeTransparency = 0.5
	b.TextSize = 18
	b.Font = Enum.Font.FredokaOne
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = b
	b.Parent = parent
	return b
end

-- Top-centre wallet panel (clear of the top-left Roblox menu corner).
local wallet = panel(gui, "Wallet", UDim2.new(0.5, -170, 0, 10), UDim2.fromOffset(340, 64), Color3.fromRGB(35, 30, 55))
local moneyLabel = label(wallet, "Money", UDim2.new(0, 14, 0, 4), UDim2.new(0.6, 0, 0, 30), "$100", Color3.fromRGB(120, 255, 140), 26)
local incomeLabel = label(wallet, "Income", UDim2.new(0, 14, 0, 34), UDim2.new(0.6, 0, 0, 24), "+$0/s on your base", Color3.fromRGB(255, 220, 120), 17)
local rebirthLabel = label(wallet, "Rebirths", UDim2.new(0.62, 0, 0, 12), UDim2.new(0.38, -8, 0, 40), "Rebirths: 0", Color3.fromRGB(255, 140, 220), 17)
rebirthLabel.TextXAlignment = Enum.TextXAlignment.Right

-- Right side: carried card + placed collection.
local side = panel(gui, "Collection", UDim2.new(1, -264, 0, 92), UDim2.fromOffset(254, 300), Color3.fromRGB(35, 30, 55))
local carriedLabel = label(side, "Carried", UDim2.new(0, 12, 0, 8), UDim2.new(1, -24, 0, 52), "Hands empty - catch one in the meadow!", Color3.fromRGB(255, 255, 255), 17)
carriedLabel.TextWrapped = true
local placedLabel = label(side, "Placed", UDim2.new(0, 12, 0, 66), UDim2.new(1, -24, 1, -74), "", Color3.fromRGB(220, 220, 235), 15)
placedLabel.TextWrapped = true
placedLabel.TextYAlignment = Enum.TextYAlignment.Top

-- Bottom-centre action buttons.
local bar = panel(gui, "Actions", UDim2.new(0.5, -270, 1, -74), UDim2.fromOffset(540, 58), Color3.fromRGB(35, 30, 55))
local gachaButton = button(bar, "Gacha", UDim2.new(0, 8, 0, 8), UDim2.fromOffset(168, 42), "Noodle Pot $150", Color3.fromRGB(255, 120, 60))
local lockButton = button(bar, "Lock", UDim2.new(0, 184, 0, 8), UDim2.fromOffset(168, 42), "Lock Base", Color3.fromRGB(64, 156, 255))
local rebirthButton = button(bar, "Rebirth", UDim2.new(0, 360, 0, 8), UDim2.fromOffset(168, 42), "Rebirth", Color3.fromRGB(178, 82, 255))
gachaButton.MouseButton1Click:Connect(function()
	action:FireServer("RollGacha")
end)
lockButton.MouseButton1Click:Connect(function()
	action:FireServer("LockBase")
end)
rebirthButton.MouseButton1Click:Connect(function()
	action:FireServer("Rebirth")
end)

-- Toast line, bottom, and the tsunami banner, upper centre.
local toast = label(gui, "Toast", UDim2.new(0.5, -300, 1, -118), UDim2.fromOffset(600, 34), "", Color3.fromRGB(255, 255, 160), 20)
toast.TextXAlignment = Enum.TextXAlignment.Center
local banner = label(gui, "WaveBanner", UDim2.new(0.5, -320, 0, 92), UDim2.fromOffset(640, 56), "", Color3.fromRGB(255, 90, 70), 34)
banner.TextXAlignment = Enum.TextXAlignment.Center

local toastToken = 0
toastEvent.OnClientEvent:Connect(function(message)
	toastToken += 1
	local token = toastToken
	toast.Text = message
	task.delay(4, function()
		if toastToken == token then
			toast.Text = ""
		end
	end)
end)

waveWarning.OnClientEvent:Connect(function(secondsLeft)
	if secondsLeft and secondsLeft > 0 then
		banner.Text = "SOUP TSUNAMI IN " .. tostring(math.ceil(secondsLeft)) .. " - RUN HOME!"
		task.spawn(function()
			local left = secondsLeft
			while left > 0 and banner.Text ~= "" do
				task.wait(1)
				left -= 1
				if left > 0 then
					banner.Text = "SOUP TSUNAMI IN " .. tostring(math.ceil(left)) .. " - RUN HOME!"
				end
			end
		end)
	else
		banner.Text = "SOUP TSUNAMI! HOLD ON TO YOUR NOODLES!"
		task.delay(4, function()
			banner.Text = ""
		end)
	end
end)

local function describeEntry(entry)
	local character = BrainrotData.getCharacter(entry.Id)
	if not character then
		return "?"
	end
	local rarity = BrainrotData.getRarity(entry.Rarity)
	local income = BrainrotData.incomePerSecond(character, entry.Rarity, entry.Mutation, 0)
	local prefix = entry.Mutation ~= "Normal" and (entry.Mutation .. " ") or ""
	return prefix .. character.Name .. " (" .. rarity.Name .. ", $" .. tostring(income) .. "/s)"
end

stateChanged.OnClientEvent:Connect(function(state)
	if not state then
		return
	end
	moneyLabel.Text = GameConfig.formatMoney(state.Money)
	incomeLabel.Text = "+" .. GameConfig.formatMoney(state.IncomePerSecond) .. "/s on your base"
	rebirthLabel.Text = "Rebirths: " .. tostring(state.Rebirths)
	if state.Carried then
		carriedLabel.Text = "Carrying: " .. describeEntry(state.Carried) .. " - step on your pedestal!"
	else
		carriedLabel.Text = "Hands empty - catch one in the meadow!"
	end
	local lines = {}
	for slot = 1, GameConfig.BaseSlots do
		local entry = state.Placed[tostring(slot)] or state.Placed[slot]
		if entry then
			table.insert(lines, tostring(slot) .. ". " .. describeEntry(entry))
		end
	end
	placedLabel.Text = #lines > 0 and table.concat(lines, "\n") or "No brainrots placed yet."
	local cost = GameConfig.rebirthCost(state.Rebirths)
	rebirthButton.Text = cost and ("Rebirth " .. GameConfig.formatMoney(cost)) or "MAX REBIRTH"
end)

-- Help line, bottom-left, small: how the loop works in one breath.
local help = label(gui, "Help", UDim2.new(0, 12, 1, -40), UDim2.fromOffset(520, 30), "Catch or buy a brainrot, carry it home, place it, earn $/s. Beware the soup.", Color3.fromRGB(230, 230, 240), 15)

gui.Parent = player:WaitForChild("PlayerGui")
