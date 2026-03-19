local UtilityFunctions = {}

function UtilityFunctions.FindFirstAncestorChildOf(Object: Instance, TargetParent: Instance): Instance?
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

function UtilityFunctions.GetSnappedAxis(Vector: Vector3): (Enum.Axis, number)
	local Absolute = Vector:Abs()
	local LargestAxis = Enum.Axis.X
	local LargestValue = -math.huge

	for _, Axis in Enum.Axis:GetEnumItems() do
		local Value = Absolute[Axis.Name]

		if Value > LargestValue then
			LargestAxis = Axis
			LargestValue = Value
		end
	end

	return LargestAxis, math.sign(Vector[LargestAxis.Name])
end

local function GetAxisWorldRef(AxisVector: Vector3): Vector3
	local SnapAxis, Sign = UtilityFunctions.GetSnappedAxis(AxisVector)
	
	return Vector3.FromAxis(Enum.Axis:FromValue((SnapAxis.Value + 1) % 3)) * Sign
end

function UtilityFunctions.ToAxisAngle(Value: CFrame): (Vector3, number)
	local AxisVector = Value.LookVector
	local RightVector = Value.RightVector
	local WorldRef = GetAxisWorldRef(AxisVector)
	local Ref = (WorldRef - AxisVector * AxisVector:Dot(WorldRef)).Unit
	local Cos = math.clamp(RightVector:Dot(Ref), -1, 1)
	local Sin = RightVector:Cross(Ref):Dot(AxisVector)
	local Angle = math.atan2(Sin, Cos)
	
	return AxisVector, Angle
end

function UtilityFunctions.FromAxisAngle(AxisVector: Vector3, Angle: number): CFrame
	local WorldRef = GetAxisWorldRef(AxisVector)
	local Ref = (WorldRef - AxisVector * AxisVector:Dot(WorldRef)).Unit
	local RightVector = Ref * math.cos(Angle) - AxisVector:Cross(Ref) * math.sin(Angle)
	local UpVector = -AxisVector:Cross(RightVector)
	
	return CFrame.fromMatrix(Vector3.new(), RightVector, UpVector, -AxisVector)
end

function UtilityFunctions.SnapCFrameAxis(Value: CFrame): CFrame
	local AxisVector, Angle = UtilityFunctions.ToAxisAngle(Value)
	local SnappedAxis, Sign = UtilityFunctions.GetSnappedAxis(AxisVector)
	local Rotation = math.rad(math.round(math.deg(Angle) / 90) * 90)
	
	return UtilityFunctions.FromAxisAngle(Vector3.FromAxis(SnappedAxis) * Sign, Rotation)
end

function UtilityFunctions.GetAxisRotation(Axis: Enum.Axis, Sign: number, NumRotations: number): number
	local AxisValue = Axis.Value
	local SignedAxis = Sign < 0 and AxisValue or AxisValue + 3
	
	NumRotations = NumRotations % 4
	
	return SignedAxis * 4 + NumRotations
end

function UtilityFunctions.AxisRotationToAxisAngle(AxisRotation: number): (Vector3, number)
	local SignedAxis = math.floor(AxisRotation / 4)
	local NumRotations = AxisRotation % 4
	local Axis = Enum.Axis:FromValue(SignedAxis % 3)
	local Sign = SignedAxis > 2 and 1 or -1
	
	return Vector3.FromAxis(Axis) * Sign, NumRotations * math.rad(90)
end

function UtilityFunctions.ToAxisRotation(Value: CFrame): number
	local AxisVector, Angle = UtilityFunctions.ToAxisAngle(Value)
	local SnappedAxis, Sign = UtilityFunctions.GetSnappedAxis(AxisVector)
	local NumRotations = math.round(Angle / math.rad(90)) % 4
	
	return UtilityFunctions.GetAxisRotation(SnappedAxis, Sign, NumRotations)
end

function UtilityFunctions.CleanRoundVector3(Value: Vector3, Increment: number, RoundOffset: Vector3): (number, number, number)
	Value = Value or Vector3.new()
	Increment = Increment or 0
	RoundOffset = RoundOffset or Vector3.new()

	if Increment > 0 then 
		local Precision = math.ceil(math.log10(10 / Increment))
		local Rounded = UtilityFunctions.RoundVector3(Value, Increment, RoundOffset)

		return tonumber(string.format("%." .. math.max(0, Precision) .. "f", Rounded.X)), tonumber(string.format("%." .. math.max(0, Precision) .. "f", Rounded.Y)), tonumber(string.format("%." .. math.max(0, Precision) .. "f", Rounded.Z))
	else
		return Value.X, Value.Y, Value.Z
	end
end

function UtilityFunctions.RoundVector3(Value: Vector3, Increment: number, RoundOffset: Vector3): (number, number, number)
	Value = Value or Vector3.new()
	Increment = Increment or 0
	RoundOffset = RoundOffset or Vector3.new()

	if Increment > 0 then 
		return ((Value + RoundOffset) / Increment + Vector3.new(0.5, 0.5, 0.5)):Floor() * Increment - RoundOffset
	else
		return Value
	end
end

function UtilityFunctions.GetTemplateBlock(Block: Instance): Instance
	local TemplateBlock = nil

	if Block.Name == "BlockModel" and Block.Parent.Parent == game.ReplicatedStorage.Blocks then
		TemplateBlock = Block.Parent
	else
		local BlockIDValue = game.ReplicatedStorage.BlockIDs:FindFirstChild(Block.Name)

		if BlockIDValue then
			TemplateBlock = game.ReplicatedStorage.Blocks:FindFirstChild(BlockIDValue.Value)
		end
	end
	
	return TemplateBlock
end

function UtilityFunctions.GetBlockDimensions(Block: Instance): Vector3
	local TemplateBlock = UtilityFunctions.GetTemplateBlock(Block)
	
	if TemplateBlock and TemplateBlock:GetAttribute("BlockDimensions") then
		return TemplateBlock:GetAttribute("BlockDimensions")
	end
	
	print("Failed to find dimensions of block [", Block, "]")
	
	return Vector3.new(2, 2, 2)
end

function UtilityFunctions.GetBlockWeldRoot(Block: Instance, WeldGroup: number): Instance
	for _, BasePart in Block:GetDescendants() do
		if BasePart:IsA("BasePart") and BasePart:HasTag("WeldGroupRoot") and (BasePart:GetAttribute("WeldGroup") == WeldGroup or BasePart:GetAttribute("WeldGroup") == tostring(WeldGroup)) then
			return BasePart
		end
	end
end

function UtilityFunctions.GetBlockWeldRootOffset(Block: Instance, WeldGroup: number): CFrame
	local TemplateBlock = UtilityFunctions.GetTemplateBlock(Block)

	if WeldGroup and TemplateBlock then
		return TemplateBlock.WeldGroupRoots:FindFirstChild(WeldGroup).Value.CFrame:Inverse() * TemplateBlock.BlockModel:GetPivot()
	end
	
	print("Failed to find root offset of block [", Block, "] for weld group [" .. WeldGroup .. "]")
	
	return CFrame.new()
end

function UtilityFunctions.GetBlockWeldRootCenter(Block: Instance, WeldGroup: number): CFrame
	local Root = UtilityFunctions.GetBlockWeldRoot(Block, WeldGroup)
	
	if Root then
		return Root.CFrame * UtilityFunctions.GetBlockWeldRootOffset(Block, WeldGroup)
	end
	
	print("Failed to find center of block [", Block, "] for weld group [" .. WeldGroup .. "]")
	
	return Block:GetPivot()
end

return UtilityFunctions