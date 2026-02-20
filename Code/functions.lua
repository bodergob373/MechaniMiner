local MainFunctions = {}

function MainFunctions.FindFirstAncestorChildOf(Object, TargetParent)
	local Current = Object

	while Current do
		local Parent = Current.Parent
		
		if Parent == TargetParent then
			return Current
		end
		
		Current = Parent
	end

	return nil
end

function MainFunctions.CleanRoundVector3(Value, Increment, RoundOffset)
	Value = Value or Vector3.new()
	Increment = Increment or 0
	RoundOffset = RoundOffset or Vector3.new()

	if Increment > 0 then 
		local Precision = math.ceil(math.log10(10 / Increment))
		local X, Y, Z = MainFunctions.RoundVector3(Value, Increment, RoundOffset)

		return tonumber(string.format("%." .. math.max(0, Precision) .. "f", X)), tonumber(string.format("%." .. math.max(0, Precision) .. "f", Y)), tonumber(string.format("%." .. math.max(0, Precision) .. "f", Z))
	else
		return Value.X, Value.Y, Value.Z
	end
end

function MainFunctions.RoundVector3(Value, Increment, RoundOffset)
	Value = Value or Vector3.new()
	Increment = Increment or 0
	RoundOffset = RoundOffset or Vector3.new()

	if Increment > 0 then 
		local Rounded = ((Value + RoundOffset) / Increment + Vector3.new(0.5, 0.5, 0.5)):Floor() * Increment - RoundOffset

		return Rounded.X, Rounded.Y, Rounded.Z
	else
		return Value.X, Value.Y, Value.Z
	end
end

function MainFunctions.GetBlockDimensions(Block)
	local TemplateBlock = nil
	
	if Block.Parent == game.ReplicatedStorage.Blocks then
		TemplateBlock = Block
	else
		local BlockIDValue = game.ReplicatedStorage.InventoryIDs:FindFirstChild(Block.Name)

		if BlockIDValue then
			TemplateBlock = game.ReplicatedStorage.Blocks:FindFirstChild(BlockIDValue.Value)
		end
	end
	
	if TemplateBlock and TemplateBlock:GetAttribute("BlockDimensions") then
		return TemplateBlock:GetAttribute("BlockDimensions")
	end
	
	return Vector3.new(2, 2, 2)
end

function MainFunctions.GetBlockWeldRoot(Block, WeldGroup)
	for _, BasePart in Block:GetChildren() do
		if BasePart:IsA("BasePart") and BasePart:HasTag("WeldGroupRoot") and BasePart:GetAttribute("WeldGroup") == WeldGroup then
			return BasePart
		end
	end
end

function MainFunctions.GetBlockWeldRootOffset(Block, WeldGroup)
	local BlockIDValue = game.ReplicatedStorage.InventoryIDs:FindFirstChild(Block.Name)

	if WeldGroup and BlockIDValue then
		local TemplateBlock = game.ReplicatedStorage.Blocks:FindFirstChild(BlockIDValue.Value)

		return BlockIDValue.WeldGroupRoots:FindFirstChild(WeldGroup).Value.CFrame:Inverse() * TemplateBlock:GetPivot()
	end
	
	return CFrame.new()
end

function MainFunctions.GetBlockWeldRootCenter(Block, WeldGroup)
	local Root = MainFunctions.GetBlockWeldRoot(Block, WeldGroup)
	
	if Root then
		return Root.CFrame * MainFunctions.GetBlockWeldRootOffset(Block, WeldGroup)
	end
	
	return Block:GetPivot()
end

return MainFunctions