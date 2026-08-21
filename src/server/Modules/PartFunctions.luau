-- Services
-- We need initial mod to load services
local intializeMod = require(script.Parent.Intialize)
local Services = intializeMod.getServices()

local touchInputService = Services.TouchInputService
local replicatedStorage = Services.ReplicatedStorage
local badgeService = Services.BadgeService

-- Services

-- Variables
local dataMod = require(script.Parent.Data)
local utilitiesMod = require(script.Parent.Utilities)
local partFunctionsMod = {}
local coinCodes = {}
local playerService = Services.Players
local uniqueCode = 0
local damageDebounce = setmetatable({}, { __mode = "k" })
local touchDebounce = setmetatable({}, { __mode = "k" })
print("Here's partFunctionsMod ready for service.")

function partFunctionsMod.init(customWorkspace, mockService)
	partFunctionsMod.registerParts(customWorkspace, mockService)
end

function partFunctionsMod.playerFromHit(hit, mockService)
	local player
	local char = hit:FindFirstAncestorOfClass("Model")

	if mockService ~= nil then
		player = mockService:GetPlayerFromCharacter(char)
	else
		player = playerService:GetPlayerFromCharacter(char)
	end

	return player, char
end

function partFunctionsMod.KillParts(part, mockService)
	part.Touched:Connect(function(hit)
		local player, char = partFunctionsMod.playerFromHit(hit, mockService)
		if player and char then
			local humanoid = char:FindFirstChildOfClass("Humanoid")
			if humanoid and humanoid.Health > 0 then
				humanoid.Health = 0
			end
		end
	end)
end

function partFunctionsMod.DamageParts(part, mockService)
	part.Touched:Connect(function(hit)
		local player, char = partFunctionsMod.playerFromHit(hit, mockService)
		if player and char then
			local humanoid = char:FindFirstChildOfClass("Humanoid")
			if humanoid and humanoid.Health > 0 then
				local now = os.clock()
				local lastHit = damageDebounce[humanoid] or 0
				if now - lastHit >= 0.5 then
					damageDebounce[humanoid] = now
					local damage = (part.GetAttribute and part:GetAttribute("Damage")) or 10
					humanoid.Health = math.max(0, humanoid.Health - damage)
				end
			end
		end
	end)
end

function partFunctionsMod.SpawnParts(part, mockService, customDataMod, customSpawnFolder, customIntializeMod)
	local stage = (part.GetAttribute and part:GetAttribute("Stage")) or 1
	local data = customDataMod or dataMod
	local initMod = customIntializeMod or intializeMod
	local spawnFolder = customSpawnFolder or (workspace and workspace:FindFirstChild("SpawnToParts"))

	part.Touched:Connect(function(hit)
		local player, char = partFunctionsMod.playerFromHit(hit, mockService)
		local humanoid = char and char:FindFirstChildOfClass("Humanoid")
		if player and humanoid then
			local now = os.clock()
			local lastHit = touchDebounce[humanoid] or 0

			if now - lastHit >= 0.5 then
				touchDebounce[humanoid] = now

				local playerStage = data.get(player, "Stage")
					or (player.leaderstats and player.leaderstats:FindFirstChild("Stage") and player.leaderstats.Stage.Value)
					or 1

				print(
					player.Name,
					"hit",
					part.Name,
					"(Stage " .. tostring(stage) .. ") with body part:",
					hit.Name,
					"Current player stage:",
					playerStage
				)

				if playerStage == (stage - 1) then
					data.set(player, "Stage", stage)
					if initMod and initMod.teleportToStage then
						initMod.teleportToStage(char, player, data, spawnFolder)
					end
				end
			end
		end
	end)
end

function partFunctionsMod.RewardParts(part)
	local reward = part:GetAttribute("Reward")
	uniqueCode += 1
	local code = uniqueCode

	part.Touched:Connect(function(hit)
		local player, char = partFunctionsMod.playerFromHit(hit, mockService)
		if player then
			local playerCoinCodes = coinCodes[player.UserId]
			if not table.find(playerCoinCodes, code) then
				dataMod.increment(player, "Coins", reward)
				table.insert(playerCoinCodes, code)
				replicatedStorage.Effect:FireClient(player, part)
			end
		end
	end)
end

function partFunctionsMod.BadgeParts(part)
	local badgeId = part:GetAttribute("BadgeId")
	part.Touched:Connect(function(hit)
		local player = partFunctionsMod.playerFromHit(hit, mockService)
		if player then
			local key = player.UserId
			local hasBadge = utilitiesMod.promiseReturn(1, function()
				return badgeService:UserHasBadgeAsync(key, badgeId)
			end)
			if not hasBadge then
				utilitiesMod.promiseReturn(1, function()
					badgeService:AwardBadgeAsync(key, badgeId)
				end)
			end
		end
	end)
end

function partFunctionsMod.registerParts(customWorkspace, mockService)
	local ws = customWorkspace or workspace
	local spawnToFolder = ws and ws:FindFirstChild("SpawnToParts")
	local folderNames = {
		"DamageParts",
		"KillParts",
		"SpawnParts",
		"RewardParts",
		"BadgeParts",
	}
	for _, folderName in ipairs(folderNames) do
		local folder = ws and ws:FindFirstChild(folderName)
		if folder then
			for _, part in ipairs(folder:GetChildren()) do
				if part:IsA("BasePart") then
					local func = partFunctionsMod[folderName]
					if func then
						if folderName == "SpawnParts" then
							func(part, mockService, nil, spawnToFolder)
						else
							func(part, mockService)
						end
					end
				end
			end
		end
	end
end

return partFunctionsMod
