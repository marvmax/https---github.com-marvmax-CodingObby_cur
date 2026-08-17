local playerService = game:GetService("Players")
local physicsService = game:GetService("PhysicsService")

local physicsMod = {}
local COLLISION_GROUP = "Players"

print("Saying hola from physics mod")

physicsService:RegisterCollisionGroup(COLLISION_GROUP)
physicsService:CollisionGroupSetCollidable(COLLISION_GROUP, COLLISION_GROUP, false)

physicsMod.makeCollisionGroup = function(char)
	for _, part in pairs(char:GetChildren()) do
		if part:IsA("BasePart") then
			part.CollisionGroup = COLLISION_GROUP
		end
	end
end

playerService.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(char)
		physicsMod.makeCollisionGroup(char)
	end)
end)

return physicsMod
