local wsServiceMod = {}

print("Hello from workspace and were loaded")

local function getOrCreateFolder(parent: Instance, folderName: string): Folder
	local folder = parent:FindFirstChild(folderName)
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = folderName
		folder.Parent = parent
	end
	return folder
end

function wsServiceMod.createParts(customWorkspace: Instance?)
	local ws = customWorkspace or workspace
	local partSize = Vector3.new(4, 1, 2)
	local partMaterial = Enum.Material.Plastic

	-- 1. Create the four folders in Workspace
	local killPartsFolder = getOrCreateFolder(ws, "KillParts")
	local damagePartsFolder = getOrCreateFolder(ws, "DamageParts")
	local spawnPartsFolder = getOrCreateFolder(ws, "SpawnParts")
	local spawnToPartsFolder = getOrCreateFolder(ws, "SpawnToParts")

	-- 2. KillPart (Instantly kills player on touch)
	if not killPartsFolder:FindFirstChild("KillPart1") then
		local killPart = Instance.new("Part")
		killPart.Name = "KillPart1"
		killPart.Size = partSize
		killPart.Position = Vector3.new(20, 0.5, 44)
		killPart.BrickColor = BrickColor.new("Bright blue")
		killPart.Material = partMaterial
		killPart.Anchored = true
		killPart.CanCollide = true
		killPart.Parent = killPartsFolder
	end

	-- 3. DamagePart (Damages player on touch with Damage attribute)
	if not damagePartsFolder:FindFirstChild("DamagePart1") then
		local damagePart = Instance.new("Part")
		damagePart.Name = "DamagePart1"
		damagePart.Size = partSize
		damagePart.Position = Vector3.new(4, 0.5, 12)
		damagePart.BrickColor = BrickColor.new("Lime green")
		damagePart.Material = partMaterial
		damagePart.Anchored = true
		damagePart.CanCollide = true
		damagePart:SetAttribute("Damage", 20)
		damagePart.Parent = damagePartsFolder
	end

	-- 4. SpawnParts (Checkpoint trigger to advance to Stage 2)
	if not spawnPartsFolder:FindFirstChild("spawnPart2") then
		local spawnPart = Instance.new("Part")
		spawnPart.Name = "spawnPart2"
		spawnPart.Size = partSize
		spawnPart.Position = Vector3.new(57, 0.5, 0)
		spawnPart.BrickColor = BrickColor.new(180, 32, 175)
		spawnPart.Material = partMaterial
		spawnPart.Anchored = true
		spawnPart.CanCollide = true
		spawnPart:SetAttribute("Stage", 2)
		spawnPart.Parent = spawnPartsFolder
	end

	if not spawnPartsFolder:FindFirstChild("spawnPart3") then
		local spawnPart = Instance.new("Part")
		spawnPart.Name = "spawnPart3"
		spawnPart.Size = partSize
		spawnPart.Position = Vector3.new(5, 0.5, -13)
		spawnPart.BrickColor = BrickColor.new(180, 32, 175)
		spawnPart.Material = partMaterial
		spawnPart.Anchored = true
		spawnPart.CanCollide = true
		spawnPart:SetAttribute("Stage", 3)
		spawnPart.Parent = spawnPartsFolder
	end

	-- 5. SpawnToParts (Destination spawn platforms)
	-- Stage 1 initial spawn platform
	if not spawnToPartsFolder:FindFirstChild("SpawnToPart1") then
		local spawnTo1 = Instance.new("Part")
		spawnTo1.Name = "SpawnToPart1"
		spawnTo1.Size = partSize
		spawnTo1.Position = Vector3.new(0, 0.5, 0)
		spawnTo1.BrickColor = BrickColor.new(117, 0, 0)
		spawnTo1.Material = partMaterial
		spawnTo1.Anchored = true
		spawnTo1.CanCollide = true
		spawnTo1:SetAttribute("Stage", 1)
		spawnTo1.Parent = spawnToPartsFolder
	end

	-- Stage 2 destination spawn platform
	if not spawnToPartsFolder:FindFirstChild("SpawnToPart2") then
		local spawnTo2 = Instance.new("Part")
		spawnTo2.Name = "SpawnToPart2"
		spawnTo2.Size = partSize
		spawnTo2.Position = Vector3.new(56, 0.5, 10)
		spawnTo2.BrickColor = BrickColor.new(117, 0, 0)
		spawnTo2.Material = partMaterial
		spawnTo2.Anchored = true
		spawnTo2.CanCollide = true
		spawnTo2:SetAttribute("Stage", 2)
		spawnTo2.Parent = spawnToPartsFolder
	end

	-- Stage 3 destination spawn platform
	if not spawnToPartsFolder:FindFirstChild("SpawnToPart3") then
		local spawnTo3 = Instance.new("Part")
		spawnTo3.Name = "SpawnToPart3"
		spawnTo3.Size = partSize
		spawnTo3.Position = Vector3.new(20, 0.5, 13)
		spawnTo3.BrickColor = BrickColor.new(117, 0, 0)
		spawnTo3.Material = partMaterial
		spawnTo3.Anchored = true
		spawnTo3.CanCollide = true
		spawnTo3:SetAttribute("Stage", 3)
		spawnTo3.Parent = spawnToPartsFolder
	end

	print("✅ Obby folders and parts created in Workspace!")

	--[[return {
		KillParts = killPartsFolder,
		DamageParts = damagePartsFolder,
		SpawnParts = spawnPartsFolder,
		SpawnToParts = spawnToPartsFolder,
	}]]
end

function wsServiceMod.init(customWorkspace: Instance?)
	return wsServiceMod.createParts(customWorkspace)
end

return wsServiceMod
