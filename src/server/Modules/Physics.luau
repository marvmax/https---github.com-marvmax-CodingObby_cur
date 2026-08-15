local playerService = game:GetService("Players")
local physicsService = game:GetService("PhysicsService")

local physicsMod = {}

print("Saying hola from physics mod")

physicsService:RegisterCollisionGroup("Players")
physicsService:CollisionGroupSetCollidable("Players", "Players", false)

physicsMod.makeCollisionGroup = function(char)
	for _, part in pairs(char.Children:GetDescendats()) do
		if part:IsA("BasePart") then
			part.CollisionGroup = "Players"
		end
	end
end

playerService.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(char)
		physicsMod.makeCollisionGroup(char)
	end)
end)

return physicsMod
