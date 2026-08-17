local TouchInputService = game:GetService("TouchInputService")
-- Services
local Services = setmetatable({}, {
	__index = function(self, serviceName: string)
		if game then
			local service = game:GetService(serviceName) -- 👈 Pass serviceName directly to game:GetService!
			rawset(self, serviceName, service)
			return service
		end
		return nil
	end,
})

-- Variables
local partFunctionsMod = {}
local coinCodes = {}
local playerService = Services.Players
print("Here's partFunctionsMod ready for service.")

function partFunctionsMod.playerFromHit(hit, mockService)
	local player
	local char = hit:FindFirstAncestorOfClass("Model")

	if mockService ~= nil then
		player = mockService:GetPlayerFromCharacter(char)
	else
		player = playerService:GetPlayerFromCharacter(char)
	end

	return player, char
end

function partFunctionsMod.killParts(part)
	part.Touched:Connect(function(hit)
		local player, char = partFunctionsMod.playerFromHit(hit)
		if player and char.Humanoid.Health > 0 then
			char.Humanoid.Health = 0
		end
	end)
end

return partFunctionsMod
