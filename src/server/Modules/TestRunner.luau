local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local testRunnerMod = {}

-- Require TestEZ package
local TestEZ = require(ReplicatedStorage.Packages.TestEZ)

print("🧪 Running Server Unit Tests...")

-- Point TestEZ to ServerScriptService!
TestEZ.TestBootstrap:run({
	ServerScriptService,
})

return testRunnerMod
