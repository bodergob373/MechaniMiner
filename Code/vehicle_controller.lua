local UtilityFunctions = require(game.ReplicatedStorage.UtilityFunctions)
local Wheels = {}

script.Parent.Changed:Connect(function()
	script.Parent.Parent.SteerHinge.TargetAngle = script.Parent.SteerFloat * -135
	script.Parent.Parent.ThrottleHinge.TargetAngle = math.abs(script.Parent.ThrottleFloat) * -30
	if (math.abs(script.Parent.AssemblyLinearVelocity.Z) > 0.4 and script.Parent.ThrottleFloat==0)then
	script.Parent.Parent.BrakeHinge.TargetAngle = -30
	
	else
	script.Parent.Parent.BrakeHinge.TargetAngle = 0
	end
	
	for _, wheel in Wheels do
		local relative = script.Parent.CFrame:ToObjectSpace(wheel.Root.CFrame).Position
		
		if math.abs(relative.X) < 8 and math.abs(relative.Z) < 24 then
			if wheel.Drive then
			wheel.Drive.MotorMaxAcceleration = 1000
			wheel.Drive.MotorMaxTorque = 20000
			wheel.Drive.AngularVelocity = script.Parent.ThrottleFloat * 50 * wheel.VelocityFactor
			end
			if wheel.Steer then
				wheel.Steer.TargetAngle = -script.Parent.SteerFloat * (wheel.Steerable and 30 or 0)
			end
		else
			if wheel.Drive then
			wheel.Drive.MotorMaxAcceleration = 0
			wheel.Drive.MotorMaxTorque = 1000000
			wheel.Drive.AngularVelocity = 0
			end
			if wheel.Steer then
				wheel.Steer.TargetAngle = 0
			end
		end
	end
end)

function addwheel(blok)
	local Steer = blok:FindFirstChild("Steer")
	local SideOffset = script.Parent.CFrame:ToObjectSpace(UtilityFunctions.GetBlockWeldRootCenter(blok, 1)).Position.X
	local RX, RY, RZ = script.Parent.CFrame:ToObjectSpace(UtilityFunctions.GetBlockWeldRootCenter(blok, 1)).Rotation:ToOrientation()
	local Dot = math.cos(RY)
	local canSteer = Steer and script.Parent.CFrame:ToObjectSpace(UtilityFunctions.GetBlockWeldRootCenter(blok, 1)).Position.Z < 0 or blok.Name == "30"
	local root = blok.Hitbox
	table.insert(Wheels, {Root = root, Drive = blok:FindFirstChild("Drive"), Steer = Steer, Steerable = canSteer, VelocityFactor = Dot, SideOffset = SideOffset})
end

game.ReplicatedStorage.updateblocks.OnServerEvent:Connect(function(player, folder)
	Wheels = {}
	
	for _, blok in folder:GetChildren() do
		if blok.Name == "11" or blok.Name == "27" or blok.Name == "29" or blok.Name == "30" then
			addwheel(blok)
		end
	end
end)