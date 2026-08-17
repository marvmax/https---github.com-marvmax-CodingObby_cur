local partFunctionsMod = require(script.Parent.PartFunctions)
local playersService = game:GetService("Players")

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
	return {
		Name = name or "MockPlayer",
		UserId = userId or 123456,
		Character = character,
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

-- ============================================================================
-- Tests
-- ============================================================================

return function()
	describe("PartFunctions", function()
		describe("playerFromHit(hit, mockService)", function()
			local env

			beforeEach(function()
				env = createMockEnvironment()
			end)

			afterEach(function()
				if env and env.cleanup then
					env.cleanup()
				end
			end)

			it("should return player and char when a part inside a character is hit", function()
				local player, char = partFunctionsMod.playerFromHit(env.hitPart, env.playersService)

				expect(player).to.equal(env.player)
				expect(char).to.equal(env.character)
			end)

			it("should return nil player when character is not in Players service", function()
				local unregisteredChar = createMockCharacter("UnregisteredChar")
				local hitPart = createMockPart("RightHand", unregisteredChar)

				local player, char = partFunctionsMod.playerFromHit(hitPart, env.playersService)

				expect(player).to.equal(nil)
				expect(char).to.equal(unregisteredChar)

				unregisteredChar:Destroy()
			end)

			it("should return nil character and nil player when hitting a standalone part", function()
				local standalonePart = createMockPart("TerrainPart", workspace)

				local player, char = partFunctionsMod.playerFromHit(standalonePart, env.playersService)

				expect(player).to.equal(nil)
				expect(char).to.equal(nil)

				standalonePart:Destroy()
			end)
		end)

		describe("playerFromHit(hit) with live player", function()
			it("should return the local player running the test", function()
				local localPlayer = playersService:GetPlayers()[1] or playersService.PlayerAdded:Wait()
				if not localPlayer.Character then
					localPlayer:LoadCharacterAsync()
				end
				local localChar = localPlayer.Character or localPlayer.CharacterAdded:Wait()
				local hitPart = localChar:WaitForChild("HumanoidRootPart", 5)

				local player, char = partFunctionsMod.playerFromHit(hitPart)

				expect(player).to.be.ok()
				expect(char).to.equal(localChar)
			end)
		end)
	end)
end
