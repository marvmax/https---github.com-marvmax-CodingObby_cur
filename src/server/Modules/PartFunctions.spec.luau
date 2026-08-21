local partFunctionsMod = require(script.Parent.PartFunctions)
local EncodingService = game:GetService("EncodingService")
local playersService = game:GetService("Players")
local dataMod = require(script.Parent.Data)

-- ============================================================================
-- Reusable Mock Factory Functions
-- ============================================================================

local function createMockCharacter(name: string?)
	local mockChar = Instance.new("Model")
	mockChar.Name = name or "MockCharacter"

	local humanoid = Instance.new("Humanoid")
	humanoid.Health = 100
	humanoid.MaxHealth = 100
	humanoid.Parent = mockChar

	local rootPart = Instance.new("Part")
	rootPart.Name = "HumanoidRootPart"
	rootPart.Parent = mockChar
	mockChar.PrimaryPart = rootPart

	mockChar.Parent = workspace
	return mockChar
end

local function createMockPart(name: string?, parent: Instance?)
	local part = Instance.new("Part")
	part.Name = name or "MockPart"
	if parent then
		part.Parent = parent
	end
	return part
end

local function createMockPlayer(name: string?, userId: number?, character: Model?)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	-- 🏷️ Create Stage value inside leaderstats
	local stageValue = Instance.new("IntValue")
	stageValue.Name = "Stage"
	stageValue.Value = 1
	stageValue.Parent = leaderstats
	local coinValue = Instance.new("IntValue")
	coinValue.Name = "Coins"
	coinValue.Value = 0
	coinValue.Parent = leaderstats
	return {
		Name = name or "MockPlayer",
		UserId = userId or 123456,
		Character = character,
		leaderstats = leaderstats,
	}
end

local function createMockPlayersService(playerMap: { [Model]: any })
	return {
		GetPlayerFromCharacter = function(_, char)
			return playerMap[char]
		end,
		GetPlayers = function(_)
			local players = {}
			for _, player in pairs(playerMap) do
				table.insert(players, player)
			end
			return players
		end,
	}
end

-- Sets up a full mock environment with cleanup for individual or group tests
local function createMockEnvironment(playerName: string?, charName: string?)
	local mockChar = createMockCharacter(charName or "MarvmaxChar")
	local mockPlayer = createMockPlayer(playerName or "Marvmax11", 123456, mockChar)
	local hitPart = createMockPart("LeftHand", mockChar)

	local playerMap = {
		[mockChar] = mockPlayer,
	}
	local mockPlayersService = createMockPlayersService(playerMap)

	local function cleanup()
		if mockChar and mockChar.Parent then
			mockChar:Destroy()
		end
	end
	return {
		character = mockChar,
		player = mockPlayer,
		hitPart = hitPart,
		playersService = mockPlayersService,
		cleanup = cleanup,
	}
end

--The new one with attributes
local function createMockTouchablePart(initialAttributes)
	local callbacks = {}
	local attributes = initialAttributes or {} -- 👈 Holds attributes like { Damage = 25 }

	return {
		Touched = {
			Connect = function(_, callback)
				table.insert(callbacks, callback)
				return {
					Disconnect = function()
						table.clear(callbacks)
					end,
				}
			end,
		},

		-- 🏷️ Mimics Roblox's part:GetAttribute("Damage")
		GetAttribute = function(_, name: string)
			return attributes[name]
		end,

		-- 🏷️ Mimics Roblox's part:SetAttribute("Damage", 25)
		SetAttribute = function(_, name: string, value: any)
			attributes[name] = value
		end,

		fireTouch = function(hitPart)
			for _, callback in ipairs(callbacks) do
				callback(hitPart)
			end
		end,
		destroy = function()
			table.clear(callbacks)
			table.clear(attributes)
		end,
	}
end

-- ============================================================================
-- Tests
-- ============================================================================

return function()
	describe("PartFunctions", function()
		describe("playerFromHit(hit, mockService)", function()
			beforeEach(function(context)
				context.env = createMockEnvironment()
			end)

			afterEach(function(context)
				if context.env and context.env.cleanup then
					context.env.cleanup()
				end
			end)

			it("should return player and char when a part inside a character is hit", function(context)
				local env = context.env
				local player, char = partFunctionsMod.playerFromHit(env.hitPart, env.playersService)

				expect(player).to.equal(env.player)
				expect(char).to.equal(env.character)
			end)

			it("should return nil player when character is not in Players service", function(context)
				local env = context.env
				local unregisteredChar = createMockCharacter("UnregisteredChar")
				local hitPart = createMockPart("RightHand", unregisteredChar)

				local player, char = partFunctionsMod.playerFromHit(hitPart, env.playersService)

				expect(player).to.equal(nil)
				expect(char).to.equal(unregisteredChar)

				unregisteredChar:Destroy()
			end)

			it("should return nil character and nil player when hitting a standalone part", function(context)
				local env = context.env
				local standalonePart = createMockPart("TerrainPart", workspace)

				local player, char = partFunctionsMod.playerFromHit(standalonePart, env.playersService)

				expect(player).to.equal(nil)
				expect(char).to.equal(nil)

				standalonePart:Destroy()
			end)
		end)

		describe("killPart(part, mockService)", function()
			beforeEach(function(context)
				context.env = createMockEnvironment()
			end)

			afterEach(function(context)
				if context.env and context.env.cleanup then
					context.env.cleanup()
				end
			end)

			it("should kill the character by setting humanoid health to 0 when touched", function(context)
				local env = context.env
				local mockKillBrick = createMockTouchablePart()

				-- 1. Verify health starts at 100
				expect(env.character.Humanoid.Health).to.equal(100)

				-- 2. Connect killPart to the mock part's Touched event
				partFunctionsMod.KillParts(mockKillBrick, env.playersService)

				-- 3. Simulate/mock the character's body part touching the kill brick
				mockKillBrick.fireTouch(env.hitPart)

				-- 4. Verify health is now 0
				expect(env.character.Humanoid.Health).to.equal(0)

				mockKillBrick.destroy()
			end)
		end)

		describe("damageParts(part, mockService)", function()
			beforeEach(function(context)
				context.env = createMockEnvironment()
			end)

			afterEach(function(context)
				if context.env and context.env.cleanup then
					context.env.cleanup()
				end
			end)
			it("Should cause the player the damage set for the part", function(context)
				local env = context.env
				local damageAmount = 10
				local mockDamageBrick = createMockTouchablePart({ Damage = damageAmount })

				-- 1. Verify health starts at 100
				expect(env.character.Humanoid.Health).to.equal(100)

				-- 2. Connect damageParts to the mock part's Touched event
				partFunctionsMod.DamageParts(mockDamageBrick, env.playersService)

				-- 3. Simulate/mock the character's body part touching the damage brick
				mockDamageBrick.fireTouch(env.hitPart)

				-- 4. Verify health is now 0
				expect(env.character.Humanoid.Health).to.equal(100 - damageAmount)

				mockDamageBrick.destroy()
			end)
		end)

		describe("spawnParts(part,mockService)", function()
			beforeEach(function(context)
				context.env = createMockEnvironment()
			end)

			afterEach(function(context)
				if context.env and context.env.cleanup then
					context.env.cleanup()
				end
			end)

			local dataMod = require(script.Parent.Data)

			it("It should set the player stage to the stage of the part", function(context)
				local env = context.env
				local partStage = 2
				local spawnPart = createMockTouchablePart({ Stage = partStage })

				partFunctionsMod.SpawnParts(spawnPart, env.playersService)
				spawnPart.fireTouch(env.hitPart)

				expect(env.player.leaderstats.Stage.Value).to.equal(partStage)

				spawnPart.destroy()
			end)

			it("It should teleport the character to the matching SpawnToParts location", function(context)
				local env = context.env
				local partStage = 2
				local spawnPart = createMockTouchablePart({ Stage = partStage })

				local mockSpawnToFolder = Instance.new("Folder")
				local spawnToPart = Instance.new("Part")
				spawnToPart:SetAttribute("Stage", partStage)
				spawnToPart.CFrame = CFrame.new(150, 20, 200)
				spawnToPart.Parent = mockSpawnToFolder

				partFunctionsMod.SpawnParts(spawnPart, env.playersService, nil, mockSpawnToFolder)
				spawnPart.fireTouch(env.hitPart)

				local targetCFrame = spawnToPart.CFrame * CFrame.new(0, 3, 0)
				expect(env.character:GetPivot().Position.X).to.equal(targetCFrame.Position.X)
				expect(env.character:GetPivot().Position.Y).to.equal(targetCFrame.Position.Y)
				expect(env.character:GetPivot().Position.Z).to.equal(targetCFrame.Position.Z)

				spawnPart.destroy()
				mockSpawnToFolder:Destroy()
			end)
		end)
	end)
end
