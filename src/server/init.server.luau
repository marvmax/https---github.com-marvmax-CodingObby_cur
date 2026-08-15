print("Hello world, from server!")

local mods = {}

-- Mod Folders
local workSpaceFolder = game.Workspace.WSServer
local modsFolder = script.Modules

-- Mods
local dataMod = require(modsFolder.Data)
local utilitiesMod = require(modsFolder.Utilities)
local wsServiceMod = require(workSpaceFolder.WSService)
local physicsMod = require(script.Modules.Physics)
