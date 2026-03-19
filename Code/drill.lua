local RunService = game:GetService("RunService")
local ServerFunctions = require(game.ServerScriptService.ServerFunctions)
local UserId = tonumber(script.Parent.Parent.Parent.Name)
local Player = UserId and game.Players:GetPlayerByUserId(UserId)
local OreOverlapParams = OverlapParams.new()

local DrillOn = false
local NextDrillUpdate = 0

local DrillUpdateRate = 0.2
local DrillRadius = 3
local DrillPower = 4

script.Parent.Lever.ClickDetector.MouseClick:Connect(function()
	DrillOn = not DrillOn
	script.Parent.Motor.AngularVelocity = DrillOn and 16 or 0
end)

RunService.Heartbeat:Connect(function()
	if DrillOn and Player and os.clock() >= NextDrillUpdate then
		local InRadius = workspace:GetPartBoundsInRadius(script.Parent.DrillCenter.Position, DrillRadius, OreOverlapParams)

		for _, Part in InRadius do
			if Part:HasTag("Harvestable") then
				ServerFunctions.Harvest(Player, Part, DrillPower * DrillUpdateRate * math.max(1 - (script.Parent.DrillCenter.Position - Part.Position).Magnitude / DrillRadius * 0.5, 0.2))
			end
		end
		
		NextDrillUpdate = os.clock() + DrillUpdateRate
	end
end)

OreOverlapParams.FilterType = Enum.RaycastFilterType.Include
OreOverlapParams.FilterDescendantsInstances = {workspace.OreFolder, workspace.Map.Plants}