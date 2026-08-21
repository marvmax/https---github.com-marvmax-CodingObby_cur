-- Services
local playerService = game:GetService("Players")
local dataService = game:GetService("DataStoreService")
local dataStore = dataService:GetDataStore("PlayerData_2")
local teleportService = game:GetService("TeleportService")

local RunService = game:GetService("RunService")

-- Modules
local utilities = require(script.Parent.Utilities)

-- Variables
local sessionData = {}
local dataMod = {}
local AUTOSAVE_INTERVAL = 120 -- seconds

-- 🛠️ Set to true if you want to reset your Stage/Coins to default (Stage 1) every time you test
local RESET_DATA_ON_JOIN = true

local defalutData = {
	Coins = 0,
	Stage = 1,
}

dataMod.init = function()
	task.spawn(dataMod.autoSave)

	local function onPlayerAdded(player: Player)
		dataMod.setUpLeaderstats(player)
	end

	-- Handle players already present (e.g. in Studio Play Solo)
	for _, player in playerService:GetPlayers() do
		task.spawn(onPlayerAdded, player)
	end
	playerService.PlayerAdded:Connect(onPlayerAdded)
end

print("Data loaded yay")

dataMod.setUpLeaderstats = function(player)
	print("Player joined: " .. player.Name .. " Setting up leaderstats")
	local folder = player:FindFirstChild("leaderstats") or Instance.new("Folder")
	folder.Name = "leaderstats"
	folder.Parent = player

	local coins = folder:FindFirstChild("Coins") or Instance.new("IntValue")
	coins.Name = "Coins"
	coins.Value = defalutData.Coins
	coins.Parent = folder

	local stage = folder:FindFirstChild("Stage") or Instance.new("IntValue")
	stage.Name = "Stage"
	stage.Value = defalutData.Stage
	stage.Parent = folder

	dataMod.setupData(player)
end

dataMod.setupData = function(player)
	print("Setting up data for player: " .. player.Name)
	local key = player.UserId

	sessionData[key] = utilities.recursiveCopy(defalutData)

	-- If testing reset flag is enabled, wipe and reset back to Stage 1
	if RESET_DATA_ON_JOIN then
		print("🔁 RESET_DATA_ON_JOIN is active: Resetting " .. player.Name .. " to Stage 1")
		player:SetAttribute("DataLoaded", true)
		dataMod.set(player, "Stage", defalutData.Stage)
		dataMod.set(player, "Coins", defalutData.Coins)
		return
	end

	local data = dataMod.load(player)

	if data then
		for i, v in data do
			dataMod.set(player, i, v)
			print("Data is being loaded for player: " .. player.Name .. ", stat: " .. i .. ", value: " .. tostring(v))
		end
		print("Data loaded for player: " .. player.Name)
	else
		print(player.Name .. " is a new player or using default data (Stage " .. tostring(defalutData.Stage) .. ")!")
	end
end

dataMod.set = function(player, stat, value)
	print("setting data for player: " .. player.Name .. ", stat: " .. stat .. ", value: " .. tostring(value))
	local key = player.UserId
	if not sessionData[key] then
		sessionData[key] = {}
	end
	sessionData[key][stat] = value
	if player.leaderstats then
		local statVal = player.leaderstats:FindFirstChild(stat)
		if statVal then
			statVal.Value = value
		end
	end
end

dataMod.get = function(player, stat)
	local key = player.UserId
	if not sessionData[key] then
		return nil
	end
	return sessionData[key][stat]
end

dataMod.increment = function(player, stat, value)
	local key = player.UserId
	sessionData[key][stat] = sessionData[key][stat] + value
	local statVal = player.leaderstats:FindFirstChild(stat)
	if statVal then
		statVal.Value = dataMod.get(player, stat)
	end
end

dataMod.reset = function(player)
	if not player then
		return
	end
	print("Resetting data to Stage 1 for player: " .. player.Name)
	local key = player.UserId
	sessionData[key] = utilities.recursiveCopy(defalutData)
	dataMod.set(player, "Stage", defalutData.Stage)
	dataMod.set(player, "Coins", defalutData.Coins)
	dataMod.save(player)
end

dataMod.save = function(player)
	if not player then
		return
	end

	print("Saving data for player: " .. player.Name)
	if not player:GetAttribute("DataLoaded") then
		return
	end

	local key = tostring(player.UserId)
	local data = sessionData[player.UserId] or sessionData[key]

	local success, err = utilities.promiseReturn(1, function()
		dataStore:SetAsync(key, data)
	end)

	if success then
		print("Data saved for player: " .. player.Name)
	else
		warn("Failed to save data for player: " .. player.Name .. ". Error: " .. tostring(err))
	end
end

dataMod.load = function(player)
	if not player then
		return nil
	end

	print("Loading data for player: " .. player.Name)
	local key = tostring(player.UserId)

	local success, loadedData = utilities.promiseReturn(1, function()
		return dataStore:GetAsync(key)
	end)

	if not success then
		if RunService:IsStudio() then
			warn(
				"⚠️ DataStore request failed in Studio. (If API access is disabled in Game Settings > Security, using default Stage 1 data for testing)."
			)
			player:SetAttribute("DataLoaded", true)
			return nil
		else
			teleportService:Teleport(game.PlaceId, player)
			return nil
		end
	end

	player:SetAttribute("DataLoaded", true)

	return loadedData
end

dataMod.remove = function(player)
	if not player then
		return
	end
	local key = player.UserId
	sessionData[key] = nil
	sessionData[tostring(key)] = nil
	print("Data removed for player: " .. player.Name)
end

function dataMod.autoSave()
	while task.wait(AUTOSAVE_INTERVAL) do
		print("Auto-saving data for all players...")
		for _, player in playerService:GetPlayers() do
			dataMod.save(player)
		end
	end
end

game:BindToClose(function()
	print("Msg from BindToClose: Game is closing. Saving data for all players...")
	for key, player in playerService:GetPlayers() do
		dataMod.save(player)
		player:Kick("Shutting down game. All data saved")
	end
end)

playerService.PlayerRemoving:Connect(function(player)
	print("Player leaving (hopefully he died): " .. player.Name)
	dataMod.save(player)
	dataMod.remove(player)
end)

return dataMod
