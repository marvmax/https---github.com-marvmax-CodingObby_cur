print("Hello world, from server!")

-- Mod Folders
local workSpaceFolder = game.Workspace.WSServer
local modsFolder = script.Modules

-- Variables
local doTest = false

-- Mods
local wsServiceMod = require(workSpaceFolder.WSService)
wsServiceMod.init()
local dataMod = require(modsFolder.Data)
dataMod.init()
local intializeMod = require(modsFolder.Intialize)
intializeMod.init()
local partFunctionsMod = require(modsFolder.PartFunctions)
partFunctionsMod.init()
require(modsFolder.Utilities)
require(modsFolder.Physics)

if doTest then
	require(modsFolder.TestRunner)
end
