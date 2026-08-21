local intializeMod = require(script.Parent.Intialize)

-- Helper mock signal for testing event connections
local function createMockSignal()
	local callbacks = {}
	return {
		Connect = function(_, callback)
			table.insert(callbacks, callback)
			return {
				Disconnect = function()
					local idx = table.find(callbacks, callback)
					if idx then
						table.remove(callbacks, idx)
					end
				end,
			}
		end,
		Fire = function(_, ...)
			for _, callback in ipairs(callbacks) do
				callback(...)
			end
		end,
	}
end

return function()
	describe("Intialize", function()
		describe("getServices()", function()
			it("should return the requested Roblox service", function()
				local playerServices = game:GetService("Players")
				local Services = intializeMod.getServices()
				local playerServices2 = Services.Players
				expect(playerServices).to.equal(playerServices2)
			end)
		end)

		describe("getStage(spawnFolder, stageNum)", function()
			it("should return the part matching the Stage attribute", function()
				local mockFolder = Instance.new("Folder")

				local part1 = Instance.new("Part")
				part1:SetAttribute("Stage", 1)
				part1.Parent = mockFolder

				local part2 = Instance.new("Part")
				part2:SetAttribute("Stage", 2)
				part2.Parent = mockFolder

				local result = intializeMod.getStage(mockFolder, 2)
				expect(result).to.equal(part2)

				mockFolder:Destroy()
			end)

			it("should return nil if no part matches the Stage attribute", function()
				local mockFolder = Instance.new("Folder")

				local part1 = Instance.new("Part")
				part1:SetAttribute("Stage", 1)
				part1.Parent = mockFolder

				local result = intializeMod.getStage(mockFolder, 99)
				expect(result).to.equal(nil)

				mockFolder:Destroy()
			end)

			it("should return nil if spawnFolder is nil", function()
				local result = intializeMod.getStage(nil, 1)
				expect(result).to.equal(nil)
			end)
		end)

		describe("teleportToStage(character, player, customDataMod, customSpawnFolder)", function()
			it("should position the character above the spawn point for their stage", function()
				local mockChar = Instance.new("Model")
				local hrp = Instance.new("Part")
				hrp.Name = "HumanoidRootPart"
				hrp.CFrame = CFrame.new(0, 0, 0)
				hrp.Parent = mockChar
				mockChar.PrimaryPart = hrp
				mockChar.Parent = workspace

				local mockFolder = Instance.new("Folder")
				local spawnPart = Instance.new("Part")
				spawnPart:SetAttribute("Stage", 3)
				spawnPart.CFrame = CFrame.new(10, 5, 20)
				spawnPart.Parent = mockFolder

				local mockPlayer = { Name = "MockPlayer", UserId = 12345 }
				local mockData = {
					get = function(player, key)
						if key == "Stage" then
							return 3
						end
						return nil
					end,
				}

				intializeMod.teleportToStage(mockChar, mockPlayer, mockData, mockFolder)

				-- Verify character was moved to spawnPart position + 3 studs Y
				local targetCFrame = spawnPart.CFrame * CFrame.new(0, 3, 0)
				expect(mockChar:GetPivot().Position.X).to.equal(targetCFrame.Position.X)
				expect(mockChar:GetPivot().Position.Y).to.equal(targetCFrame.Position.Y)
				expect(mockChar:GetPivot().Position.Z).to.equal(targetCFrame.Position.Z)

				mockChar:Destroy()
				mockFolder:Destroy()
			end)
		end)

		describe("init(mockServices, customDataMod, customSpawnFolder)", function()
			it("should listen to PlayerAdded and CharacterAdded and teleport the character", function()
				local playerAddedSignal = createMockSignal()
				local characterAddedSignal = createMockSignal()

				local mockServices = {
					Players = {
						PlayerAdded = playerAddedSignal,
					},
				}

				local mockChar = Instance.new("Model")
				local hrp = Instance.new("Part")
				hrp.Name = "HumanoidRootPart"
				hrp.Parent = mockChar
				mockChar.PrimaryPart = hrp
				mockChar.Parent = workspace

				local mockFolder = Instance.new("Folder")
				local spawnPart = Instance.new("Part")
				spawnPart:SetAttribute("Stage", 1)
				spawnPart.CFrame = CFrame.new(50, 0, 50)
				spawnPart.Parent = mockFolder

				local mockPlayer = {
					Name = "MockPlayer",
					CharacterAdded = characterAddedSignal,
				}

				local mockData = {
					get = function(player, key)
						return 1
					end,
				}

				-- Initialize with mocks
				intializeMod.init(mockServices, mockData, mockFolder)

				-- Fire events
				playerAddedSignal:Fire(mockPlayer)
				characterAddedSignal:Fire(mockChar)

				local targetCFrame = spawnPart.CFrame * CFrame.new(0, 3, 0)
				expect(mockChar:GetPivot().Position.X).to.equal(targetCFrame.Position.X)
				expect(mockChar:GetPivot().Position.Y).to.equal(targetCFrame.Position.Y)
				expect(mockChar:GetPivot().Position.Z).to.equal(targetCFrame.Position.Z)

				mockChar:Destroy()
				mockFolder:Destroy()
			end)
		end)
	end)
end
