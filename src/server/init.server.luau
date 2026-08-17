print("Hello world, from server!")

-- Mod Folders
local workSpaceFolder = game.Workspace.WSServer
local modsFolder = script.Modules

-- Variables
local doTest = true

-- Mods
local dataMod = require(modsFolder.Data)
dataMod.init()
require(modsFolder.Utilities)
require(workSpaceFolder.WSService)
require(modsFolder.Physics)
require(modsFolder.PartFunctions)
if doTest then
	require(modsFolder.TestRunner)
end
