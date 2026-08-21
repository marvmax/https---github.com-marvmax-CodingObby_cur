-- Services
local playerService = game:GetService("Players")

-- Modules
local dataMod = require(script.Parent.Data)

local intializeMod = {}

function intializeMod.getServices()
	local Services = setmetatable({}, {
		__index = function(self, serviceName: string)
			if game then
				local service = game:GetService(serviceName)
				rawset(self, serviceName, service)
				return service
			end
			return nil
		end,
	})
	return Services
end

function intializeMod.getStage(spawnFolder: Instance?, stageNum: number): BasePart?
	if not spawnFolder then
		return nil
	end
	for _, stagePart in spawnFolder:GetChildren() do
		if stagePart:GetAttribute("Stage") == stageNum then
			return stagePart
		end
	end
	return nil
end

function intializeMod.teleportToStage(
	character: Model,
	player: Player,
	customDataMod: any?,
	customSpawnFolder: Instance?
)
	local data = customDataMod or dataMod
	local spawnFolder = customSpawnFolder or (workspace and workspace:FindFirstChild("SpawnToParts"))

	character:WaitForChild("HumanoidRootPart")
	local stageNum = data.get(player, "Stage") or 1
	local spawnPoint = intializeMod.getStage(spawnFolder, stageNum)

	if spawnPoint then
		character:PivotTo(spawnPoint.CFrame * CFrame.new(0, 3, 0))
	end
end

function intializeMod.init(mockServices: any?, customDataMod: any?, customSpawnFolder: Instance?)
	local players = (mockServices and mockServices.Players) or playerService
	local data = customDataMod or dataMod
	local spawnFolder = customSpawnFolder or (workspace and workspace:FindFirstChild("SpawnToParts"))

	local function onCharacterAdded(player: Player, character: Model)
		intializeMod.teleportToStage(character, player, data, spawnFolder)
	end

	local function onPlayerAdded(player: Player)
		player.CharacterAdded:Connect(function(character)
			onCharacterAdded(player, character)
		end)
		if player.Character then
			task.spawn(onCharacterAdded, player, player.Character)
		end
	end

	if players.GetPlayers then
		for _, player in players:GetPlayers() do
			task.spawn(onPlayerAdded, player)
		end
	end
	players.PlayerAdded:Connect(onPlayerAdded)
end

return intializeMod
