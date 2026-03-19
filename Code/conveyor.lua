local ItemsWithForce = {}
local ConveyorSpeed = 5
local Params = OverlapParams.new()

Params.FilterType = Enum.RaycastFilterType.Include
Params.FilterDescendantsInstances = {game.Workspace.PlayerItems}

while task.wait(0.1) do
	local Parts = game.Workspace:GetPartsInPart(script.Parent.Hitbox, Params)

	for _, Part in Parts do
		if Part and not table.find(ItemsWithForce, Part) then
			local Force = Instance.new("LinearVelocity")
			local attachment = Instance.new("Attachment")

			Force.Name = "ConveyorForce"
			Force.Parent = script
			attachment.Name = "ConveyorAttachment"
			attachment.Parent = Part
			Force.Attachment0 = attachment
			Force.RelativeTo = Enum.ActuatorRelativeTo.World
			Force.ReactionForceEnabled = true
			Force.VelocityConstraintMode = Enum.VelocityConstraintMode.Line
			Force.LineDirection = script.Parent.Hitbox.CFrame.LookVector
			Force.LineVelocity = ConveyorSpeed
			Force.MaxForce = 10000
			table.insert(ItemsWithForce, Part)
		end
	end

	for _, Part in ItemsWithForce do
		if not table.find(Parts, Part) then
			if Part:FindFirstChild("ConveyorForce") then
				Part.ConveyorForce:Destroy()
			end

			if Part:FindFirstChild("ConveyorAttachment") then
				Part.ConveyorAttachment:Destroy()
			end

			table.remove(ItemsWithForce, table.find(ItemsWithForce, Part))
		end
	end
end