-- WaveService.luau (server module)
-- The Soup Tsunami, the threat that forces a dash home. Every interval a
-- warning goes to every client (red banner, countdown in the HUD), then a
-- 26-stud wall of tomato soup sweeps the map from west to east. A player it
-- washes over loses the brainrot they are carrying -- unless they are
-- standing inside their own base, which is the safe zone. Placed brainrots
-- on pedestals are never washed away; only the carried find is at risk,
-- which is exactly the run-home-or-lose-it moment the genre lives on.

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameConfig"))
local WorldBuilder = require(script.Parent:WaitForChild("WorldBuilder"))
local EconomyService = require(script.Parent:WaitForChild("EconomyService"))

local WaveService = {}
WaveService.Running = false

local function isSafe(player)
	-- Safe = standing within their own base's floor footprint.
	local state = EconomyService.States[player]
	local character = player.Character
	if not state or not state.BaseIndex or not character then
		return false
	end
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then
		return false
	end
	local centre = WorldBuilder.basePosition(state.BaseIndex)
	local offset = root.Position - centre
	return math.abs(offset.X) <= 17 and math.abs(offset.Z) <= 13 and root.Position.Y < 14
end

function WaveService.runWave(wave, foam, remotes)
	remotes.WaveWarning:FireAllClients(GameConfig.WaveWarningSeconds)
	task.wait(GameConfig.WaveWarningSeconds)
	local startX = -170
	local endX = 170
	local steps = math.floor((endX - startX) / (GameConfig.WaveSpeed * 0.1))
	local hit = {}
	for step = 0, steps do
		local x = startX + step * GameConfig.WaveSpeed * 0.1
		wave.CFrame = CFrame.new(x, 10, 0)
		foam.CFrame = CFrame.new(x, 23.5, 0)
		for _, player in ipairs(Players:GetPlayers()) do
			if not hit[player] then
				local character = player.Character
				local root = character and character:FindFirstChild("HumanoidRootPart")
				if root and math.abs(root.Position.X - x) < 7 and root.Position.Y < 24 then
					hit[player] = true
					if not isSafe(player) then
						EconomyService.dropCarried(player, "The Soup Tsunami washed your brainrot away!")
						local humanoid = character:FindFirstChildOfClass("Humanoid")
						if humanoid then
							humanoid:TakeDamage(10)
						end
					end
				end
			end
		end
		task.wait(0.1)
	end
	wave.CFrame = CFrame.new(-220, -30, 0)
	foam.CFrame = CFrame.new(-220, -16, 0)
	remotes.WaveWarning:FireAllClients(0)
end

function WaveService.init(remotes)
	local wave, foam = WorldBuilder.buildWave()
	task.spawn(function()
		task.wait(20) -- first wave lands a little after the game settles
		while true do
			WaveService.Running = true
			WaveService.runWave(wave, foam, remotes)
			WaveService.Running = false
			task.wait(GameConfig.WaveIntervalSeconds)
		end
	end)
end

return WaveService
