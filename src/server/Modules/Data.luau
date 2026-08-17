-- Services
local playerService = game:GetService("Players")
local dataService = game:GetService("DataStoreService")
local dataStore = dataService:GetDataStore("PlayerData")
local teleportService = game:GetService("TeleportService")

-- Modules
local utilities = require(script.Parent.Utilities)

--Variables
local sessionData = {}
local dataMod = {}
local AUTOSAVE_INTERVAL = 120 -- seconds

local defalutData = {
	Coins = 0,
	Level = 1,
}

dataMod.init = function()
	task.spawn(dataMod.autoSave)

	playerService.PlayerAdded:Connect(function(player)
		dataMod.setUpLeaderstats(player)
	end)
end

print("Data loaded yay")

dataMod.setUpLeaderstats = function(player)
	print("Player joined: " .. player.Name)
	local folder = Instance.new("Folder")
	folder.Name = "leaderstats"
	folder.Parent = player
	local coins = Instance.new("IntValue")
	coins.Name = "Coins"
	coins.Parent = folder
	coins.Value = defalutData.Coins
	local stage = Instance.new("IntValue")
	stage.Name = "Stage"
	stage.Parent = folder
	stage.Value = defalutData.Level

	dataMod.setupData(player)
end

dataMod.setupData = function(player)
	print("Setting up data for player: " .. player.Name)
	local key = player.UserId
	local data = dataMod.load(player)

	sessionData[key] = utilities.recursiveCopy(defalutData)

	if data then
		for i, v in data do
			dataMod.set()
			print("Set is passed no data first time")
			dataMod.set(player, i, v)
			print("Data is being loaded for player: " .. player.Name .. ", stat: " .. i .. ", value: " .. v)
		end
		print("Data loaded for player: " .. player.Name)
	else
		print(player.Name .. " is a new player!")
	end
end

dataMod.set = function(player, stat, value)
	print("setting data for player: " .. player.Name .. ", stat: " .. stat .. ", value: " .. value)
	local key = player.UserId
	sessionData[key][stat] = value
	local statVal = player.leaderstats:FindFirstChild(stat)
	if statVal then
		statVal.Value = value
	end
end

dataMod.get = function(player, stat)
	local key = player.UserId
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

dataMod.save = function(player)
	print("Saving data for player: " .. player.Name)
	if not player:GetAttribute("DataLoaded") then
		return
	end

	local key = player.UserId
	local data = sessionData[key]

	local success, err = utilities.promiseReturn(1, function()
		dataStore:SetAsync(key, data)
	end)

	if success then
		print("Data saved for player: " .. player.Name)
	else
		warn("Failed to save data for player: " .. player.Name .. ". Error: " .. err)
	end
end

dataMod.load = function(player)
	print("Loading data for player: " .. player.Name)
	local key = player.UserId

	local success, data = utilities.promiseReturn(1, function()
		return dataStore:GetAsync(key)
	end)

	if not success then
		teleportService:Teleport(game.PlaceId, player)
		return
	end

	local data = sessionData[key]

	player:SetAttribute("DataLoaded", true)

	return data
end

dataMod.remove = function(player)
	local key = player.UserId
	sessionData[key] = nil
	print("Data removed for player: " .. player.Name)
end

function dataMod.autoSave()
	while task.wait(AUTOSAVE_INTERVAL) do
		print("Auto-saving data for all players...")
		for key, dataTable in sessionData do
			local player = playerService:GetPlayerByUserId(key)
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
