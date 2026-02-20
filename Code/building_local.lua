local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CollectionService = game:GetService("CollectionService")
local Player = game.Players.LocalPlayer
local CreationModel = workspace.PlayerBuilds:FindFirstChild(Player.Name)
local Camera = workspace.CurrentCamera
local DeleteBox = script.DeleteBox
local GuiTweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Exponential, Enum.EasingDirection.InOut)
local SelectionTweenInfo = TweenInfo.new(0.1, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local PositionTweenInfo = TweenInfo.new(0.1, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)
local RotationTweenInfo = TweenInfo.new(0.1, Enum.EasingStyle.Circular, Enum.EasingDirection.InOut)
local PlaceTweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out)
local BoxTweenInfo = TweenInfo.new(0.1, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
local ErrorTweenInfo = TweenInfo.new(0.1, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local TweenPositionValue = Instance.new("CFrameValue")
local TweenRotationValue = Instance.new("CFrameValue")
local MouseRaycastParameters = RaycastParams.new()
local BlockRaycastParameters = RaycastParams.new()
local BlockOverlapParameters = OverlapParams.new()
local MouseIgnore = {}
local PlacedBlockTweens = {}
local ScreenGui = Player.PlayerGui.MainGui
local BuildFrame = ScreenGui:FindFirstChild("BuildFrame", true)
local StatusLabel = ScreenGui.ScreenCenter.StatusLabel
local MainFunctions = require(game.ReplicatedStorage.MainFunctions)

local MiscStorage = workspace.MiscStorage
local PlaceDistance = 20
local MoveIncrement = 1
local ArcThickness = 0.1
local BlockDropHeight = 2

local DeviceType = nil
local BuildMode = nil
local CanBuild = true
local MouseEnabled = true
local PlaceDebounce = false
local DeleteDebounce = false
local MouseRay = nil
local MouseRaycast = nil
local PlacingOnPart = nil
local PlacingOnBlock = nil
local PlacingOnWeldGroup = 0
local PlacingOnCenterOffset = CFrame.new()
local CurrentBlockPosition = Vector3.new()
local TouchBlockPosition = Vector3.new()
local RelativeBlockCFrame = CFrame.new()
local CurrentBlockRotation = CFrame.fromEulerAnglesYXZ(0, 0, 0)
local TargetBlockOffset = Vector3.new()
local CurrentBlockToDelete = nil
local TouchBlockToDelete = nil
local BlockCollection = nil
local SelectedBlockID = "1"
local SelectedBlock = nil
local BlockPreview = nil
local BlockUnion = nil
local BlockInZone = false
local BlockOverlapping = false

local SelectedVehicle = nil
local SelectedAssembly = nil

local maxBlueprints = 10

if DeviceType == "Computer" then
	StartButton = ScreenGui.ScreenLeft.StartButton
	ReturnButton = ScreenGui.ScreenLeft.ReturnButton
elseif DeviceType == "Mobile" then
	StartButton = ScreenGui.ScreenLeft.StartButton
	ReturnButton = ScreenGui.ScreenLeft.ReturnButton
end

function UpdateMouse()
	if MouseEnabled then
		local IgnoreList = table.clone(MouseIgnore)
		local NoConnections = CollectionService:GetTagged("HasNoConnections")
		
		for _, Player in game.Players:GetChildren() do
			table.insert(IgnoreList, Player.Character)
		end
		
		table.move(NoConnections, 1, #NoConnections, #IgnoreList + 1, IgnoreList)
		MouseRaycastParameters.FilterDescendantsInstances = IgnoreList
		MouseRay = Camera:ViewportPointToRay(UserInputService:GetMouseLocation().X, UserInputService:GetMouseLocation().Y)
		MouseRaycast = workspace:Raycast(MouseRay.Origin, MouseRay.Direction * 10000, MouseRaycastParameters)
	else
		MouseRaycast = nil
	end
end

function UpdateStatus(NewBuildMode)
	if not CanBuild or not BlockCollection then
		BuildMode = nil
	elseif NewBuildMode == BuildMode then
		BuildMode = nil
		game.ReplicatedStorage.Sounds.Ping1Low:Play()
	else
		BuildMode = NewBuildMode
		game.ReplicatedStorage.Sounds.Ping1High:Play()
	end
	
	if BuildMode == "Place" then
		if not BlockPreview then
			SelectBlock(SelectedBlockID)
		end
		
		UpdateBlockPosition()
		RelativeBlockCFrame = CFrame.new(RelativeBlockCFrame.Position) * CreationModel.WorldPivot.Rotation
		UpdateWorldValues()
		TweenPositionValue.Value = CFrame.new(RelativeBlockCFrame.Position)
		TweenRotationValue.Value = RelativeBlockCFrame.Rotation
		CurrentBlockToDelete = nil
		DeleteBox.Parent = script
		ScreenGui.ScreenCenter.StatusLabel.Text = "Building:"
		BuildFrame.Interactable = true
		TweenService:Create(StatusLabel, GuiTweenInfo, {Position = StatusLabel:GetAttribute("EnabledPosition")}):Play()
		TweenService:Create(BuildFrame, GuiTweenInfo, {Position = BuildFrame:GetAttribute("EnabledPosition")}):Play()
		UserInputService.MouseIcon ="rbxasset://textures\\CloneOverCursor.png" --"rbxasset://textures\\GrabRotateCursor.png"
	else
		if BlockPreview then
			BlockPreview.Parent = script
		end
		
		BuildFrame.Interactable = false
		TweenService:Create(BuildFrame, GuiTweenInfo, {Position = BuildFrame:GetAttribute("DisabledPosition")}):Play()
		
		if BuildMode == "Delete" then
			ScreenGui.ScreenCenter.StatusLabel.Text = "Deleting:"
			TweenService:Create(StatusLabel, GuiTweenInfo, {Position = StatusLabel:GetAttribute("EnabledPosition")}):Play()
			UserInputService.MouseIcon = "rbxasset://textures\\HammerOverCursor.png"
		else
			CurrentBlockToDelete = nil
			DeleteBox.Parent = script
			script.Overlay.Adornee = nil
			TweenService:Create(StatusLabel, GuiTweenInfo, {Position = StatusLabel:GetAttribute("DisabledPosition")}):Play()
			UserInputService.MouseIcon = ""
		end
	end
end

function UpdateCurrentBlockAmounts()
	if BlockCollection and SelectedVehicle then
		for _, Block in SelectedVehicle:GetChildren() do
			if BlockCollection[Block.Name] and Block:HasTag("Blueprint") then
				BlockCollection[Block.Name].PlacedBlueprints += 1
			end
		end

		for _, IDValue in game.ReplicatedStorage.InventoryIDs:GetChildren() do
			local Category = IDValue:GetAttribute("Category")

			if Category then
				local CategoryPage = BuildFrame.ScrollFrame.CategoryFrame.CategoryPages:FindFirstChild(Category)

				if CategoryPage then
					local BlockFrame = CategoryPage:FindFirstChild(IDValue.Name)

					if BlockFrame then
						BlockFrame.Amount.Text = BlockCollection[IDValue.Name].CurrentAmount

						if BlockCollection[IDValue.Name].OwnedAmount > 0 then
							BlockFrame.Visible = true
						else 
							BlockFrame.Visible = false
						end
					end
				end
			end
		end
	end
end

function SelectBlock(BlockID)
	if game.ReplicatedStorage.InventoryIDs:FindFirstChild(BlockID) and game.ReplicatedStorage.InventoryIDs:FindFirstChild(BlockID).Value and game.ReplicatedStorage.Blocks:FindFirstChild(game.ReplicatedStorage.InventoryIDs:FindFirstChild(BlockID).Value) then
		local CategoryFrame = BuildFrame.ScrollFrame.CategoryFrame
		local CategoryPage = CategoryFrame.CategoryPages:FindFirstChild(game.ReplicatedStorage.InventoryIDs:FindFirstChild(BlockID):GetAttribute("Category"))
		local BlockFrame = CategoryPage:FindFirstChild(BlockID)
		local SelectionPosition = BlockFrame.AbsolutePosition - CategoryFrame.AbsolutePosition
		local BlockModel = nil
		local Root = script.PreviewRoot:Clone()
		local OverlapModel = Instance.new("Model")
		local BlockSize = Vector3.new()
		local Arcs = {}
		local ArcRadius = 0
		local InnerRadius = 0
		local OuterRadius = 0

		if BlockPreview then
			BlockPreview:Destroy()
		end

		if BlockID ~= SelectedBlockID then
			TweenService:Create(CategoryFrame.BlockSelection, SelectionTweenInfo, {Position = UDim2.fromOffset(SelectionPosition.X, SelectionPosition.Y)}):Play()
			game.ReplicatedStorage.Sounds.Swoosh1:Play()
		end

		SelectedBlockID = BlockID
		SelectedBlock = game.ReplicatedStorage.Blocks:FindFirstChild(game.ReplicatedStorage.InventoryIDs:FindFirstChild(BlockID).Value)
		RelativeBlockCFrame = CFrame.new(RelativeBlockCFrame.Position) * CreationModel.WorldPivot.Rotation
		UpdateWorldValues()
		TweenRotationValue.Value = RelativeBlockCFrame.Rotation
		BlockSize = SelectedBlock:GetAttribute("BlockDimensions")
		BlockPreview = Instance.new("Folder")
		BlockPreview.Parent = MiscStorage
		BlockPreview.Name = "BlockPreview"
		BlockModel = SelectedBlock.BlockModel:Clone()
		BlockModel.Parent = BlockPreview
		Root.Parent = BlockPreview.BlockModel
		Root.Size = BlockSize
		Root.CFrame = BlockModel:GetPivot()
		OverlapModel.Parent = BlockPreview
		OverlapModel.Name = "OverlapModel"
		OverlapModel.WorldPivot = BlockModel.WorldPivot

		for _, Descendant in BlockPreview.BlockModel:GetDescendants() do
			if Descendant:IsA("BasePart") then
				Descendant.LocalTransparencyModifier = 0.4
				Descendant.CanCollide = false
				Descendant.CanQuery = false
				Descendant.CanTouch = false

				if Descendant.Transparency < 1 then
					Descendant.Material = Enum.Material.Glass
				end

				if Descendant:HasTag("DeterminesOverlap") then
					local OverlapPart = Descendant:Clone()
					
					OverlapPart:ClearAllChildren()
					OverlapPart.Parent = OverlapModel
					OverlapPart.Size = (OverlapPart.Size - Vector3.new(0.01, 0.01, 0.01)):Max(Vector3.new(0.01, 0.01, 0.01))
					OverlapPart.Transparency = 1
				end
			end
		end

		if SelectedBlock:HasTag("CanRotateX") then
			ArcRadius = math.max(math.sqrt(math.pow(BlockSize.Y, 2) + math.pow(BlockSize.Z, 2)), ArcRadius)
			table.insert(Arcs, script.XArc:Clone())
		end

		if SelectedBlock:HasTag("CanRotateY") then
			ArcRadius = math.max(math.sqrt(math.pow(BlockSize.X, 2) + math.pow(BlockSize.Z, 2)), ArcRadius)
			table.insert(Arcs, script.YArc:Clone())
		end

		if SelectedBlock:HasTag("CanRotateZ") then
			ArcRadius = math.max(math.sqrt(math.pow(BlockSize.X, 2) + math.pow(BlockSize.Y, 2)), ArcRadius)
			table.insert(Arcs, script.ZArc:Clone())
		end

		ArcRadius /= 2
		InnerRadius = ArcRadius + 0.8 - ArcThickness / 2
		OuterRadius = ArcRadius + 0.8 + ArcThickness / 2
		script.Overlay.Adornee = BlockPreview.BlockModel

		for _, Arc in Arcs do
			Arc.Parent = Root
			Arc.Adornee = Root
			Arc.Height = ArcThickness
			Arc.InnerRadius = InnerRadius
			Arc.Radius = OuterRadius
		end
	end
end

function GetBlockWorldCFrame(RelativeCFrame)
	return (PlacingOnPart and PlacingOnPart:IsA("BasePart") and PlacingOnPart.CFrame * PlacingOnCenterOffset or CFrame.new()) * RelativeCFrame
end

function UpdateWorldValues()
	local WorldCFrame = GetBlockWorldCFrame(RelativeBlockCFrame)
	
	CurrentBlockPosition = WorldCFrame.Position
	CurrentBlockRotation = WorldCFrame.Rotation
end

function UpdatePlacingOn()
	PlacingOnPart = nil
	PlacingOnBlock = nil
	PlacingOnWeldGroup = 0
	PlacingOnCenterOffset = CFrame.new()
	
	if MouseRaycast and MouseRaycast.Instance:IsDescendantOf(CreationModel.CreationFolder) then
		local TargetBlock = MouseRaycast.Instance
		local BlockIDValue = nil
		local BlockWeldGroup = nil

		while TargetBlock.Parent ~= CreationModel.CreationFolder do
			TargetBlock = TargetBlock.Parent
		end
		
		BlockIDValue = game.ReplicatedStorage.InventoryIDs:FindFirstChild(TargetBlock.Name)
		BlockWeldGroup = MouseRaycast.Instance:GetAttribute("WeldGroup")
		
		if BlockWeldGroup and BlockIDValue then
			PlacingOnBlock = TargetBlock
			PlacingOnWeldGroup = BlockWeldGroup
			
			for _, BasePart in TargetBlock:GetChildren() do
				if BasePart:IsA("BasePart") and BasePart:HasTag("WeldGroupRoot") and BasePart:GetAttribute("WeldGroup") == BlockWeldGroup then
					local TemplateBlock = game.ReplicatedStorage.Blocks:FindFirstChild(BlockIDValue.Value)
					
					PlacingOnPart = BasePart
					PlacingOnCenterOffset = BlockIDValue.WeldGroupRoots:FindFirstChild(BlockWeldGroup).Value.CFrame:Inverse() * TemplateBlock:GetPivot()
					break
				end
			end
		end
	end
end

function UpdateBlockPosition()
	local LastPlacingOnBlock = PlacingOnBlock
	local LastPlacingOnWeldGroup = PlacingOnWeldGroup
	
	UpdatePlacingOn()
	
	if MouseRaycast then
		local PlacingOnCenter = PlacingOnPart and PlacingOnPart.CFrame * PlacingOnCenterOffset or CFrame.new()
		local BlockBounds = (RelativeBlockCFrame.Rotation * CFrame.new(SelectedBlock:GetAttribute("BlockDimensions"))).Position:Abs()
		local PlacingOnBounds = PlacingOnBlock and game.ReplicatedStorage.Blocks:FindFirstChild(game.ReplicatedStorage.InventoryIDs:FindFirstChild(PlacingOnBlock.Name).Value):GetAttribute("BlockDimensions") or Vector3.new(0, 0, 0)
		local RoundOffset = Vector3.new(((BlockBounds.X + PlacingOnBounds.X) / 2) % MoveIncrement, ((BlockBounds.Y + PlacingOnBounds.Y) / 2) % MoveIncrement, ((BlockBounds.Z + PlacingOnBounds.Z) / 2) % MoveIncrement)
		local NormalOffset = nil
		local NewBlockPosition = nil
		
		if PlacingOnPart then
			local BlockSize = nil
			local BlockRaycast = nil
			
			if not BlockUnion or (BlockUnion and BlockUnion.Name ~= PlacingOnBlock.Name + PlacingOnWeldGroup) then
				if BlockUnion then
					BlockUnion:Destroy()
				end
				
				BlockUnion = game.ReplicatedStorage.Blocks:FindFirstChild(game.ReplicatedStorage.InventoryIDs:FindFirstChild(PlacingOnBlock.Name).Value).BlockUnions:FindFirstChild(PlacingOnWeldGroup):Clone()
				BlockUnion.Name = PlacingOnBlock.Name + PlacingOnWeldGroup
			end
			
			BlockUnion.Parent = workspace.MiscStorage
			BlockUnion:PivotTo(PlacingOnCenter)
			BlockRaycastParameters.FilterDescendantsInstances = {BlockUnion}
			BlockRaycast = workspace:Raycast(MouseRay.Origin, MouseRay.Direction * MouseRaycast.Distance * PlacingOnBounds.Magnitude, BlockRaycastParameters)
			BlockUnion.Parent = script
			
			if BlockRaycast then
				MouseRaycast = BlockRaycast
			end
		end
		
		NormalOffset = PlacingOnCenter.Rotation:PointToObjectSpace(MouseRaycast.Normal) * (BlockBounds / 2)
		TargetBlockOffset = NormalOffset * 2
		NewBlockPosition = ((PlacingOnCenter:ToObjectSpace(CFrame.new(MouseRaycast.Position)).Position + NormalOffset + RoundOffset) / MoveIncrement + Vector3.new(0.5, 0.5, 0.5)):Floor() * MoveIncrement - RoundOffset

		if NewBlockPosition ~= RelativeBlockCFrame.Position then
			TweenService:Create(TweenPositionValue, PositionTweenInfo, {Value = CFrame.new(NewBlockPosition)}):Play()
		end
		
		if (PlacingOnBlock ~= LastPlacingOnBlock or PlacingOnWeldGroup ~= LastPlacingOnWeldGroup) then
			TweenPositionValue.Value = CFrame.new(NewBlockPosition)
		end
		
		if BlockPreview.Parent == script then
			BlockPreview.Parent = MiscStorage
			TweenPositionValue.Value = CFrame.new(NewBlockPosition)
		end
		
		RelativeBlockCFrame = CFrame.new(NewBlockPosition) * RelativeBlockCFrame.Rotation
		UpdateWorldValues()
		BlockPreview.OverlapModel:PivotTo(CFrame.new(CurrentBlockPosition) * CurrentBlockRotation)
		EvaluateBlockInZone()
		EvaluateBlockOverlapping()
	else
		BlockPreview.Parent = script
	end
	
	BlockPreview.BlockModel:PivotTo(GetBlockWorldCFrame(TweenPositionValue.Value * TweenRotationValue.Value))
end

function UpdateDeleteSelection()
	if MouseRaycast and MouseRaycast.Instance:IsDescendantOf(CreationModel.CreationFolder) then
		local Block = MouseRaycast.Instance.Parent

		while Block.Parent ~= CreationModel.CreationFolder do
			Block = Block.Parent
		end

		CurrentBlockToDelete = Block
		DeleteBox.Parent = workspace.MiscStorage
		DeleteBox.CFrame = MainFunctions.GetBlockWeldRootCenter(Block, 1)
		DeleteBox.Size = game.ReplicatedStorage.Blocks:FindFirstChild(game.ReplicatedStorage.InventoryIDs:FindFirstChild(Block.Name).Value):GetAttribute("BlockDimensions")
		script.Overlay.Adornee = Block
		script.Overlay.FillColor = Color3.new(1, 0, 0)
		script.Overlay.OutlineColor = Color3.new(1, 0, 0)
	else
		CurrentBlockToDelete = nil
		DeleteBox.Parent = script
		script.Overlay.Adornee = nil
	end
end

function EvaluateBlockInZone()
	local BlockBounds = (CurrentBlockRotation * CFrame.new(SelectedBlock:GetAttribute("BlockDimensions"))).Position:Abs()
	
	BlockInZone = false
	for _, AreaPart in Player.Team.BuildZone.Value.BuildArea:GetChildren() do
		local ValidBlockArea = (AreaPart.CFrame.Rotation * CFrame.new(AreaPart.Size)).Position:Abs() - BlockBounds
		if ((CurrentBlockPosition - AreaPart.Position):Abs() - ValidBlockArea / 2):Max(Vector3.new()).Magnitude == 0 then
			BlockInZone = true
			break
		end
	end
end

function EvaluateBlockOverlapping()
	BlockOverlapping = false

	for _, OverlapPart in BlockPreview.OverlapModel:GetChildren() do
		local Overlapping = workspace:GetPartsInPart(OverlapPart, BlockOverlapParameters)
		
		for _, Part in Overlapping do
			if Part:HasTag("DeterminesOverlap") and PlacingOnPart and Part.AssemblyRootPart == PlacingOnPart.AssemblyRootPart then
				BlockOverlapping = true
				break
			end
		end
	end
end

function RotateBlock(Axis)
	if Axis and BlockPreview and BuildMode == "Place" then
		if SelectedBlock:HasTag("CanRotate" .. Axis.Name) then
			RelativeBlockCFrame  *= CFrame.fromAxisAngle(Vector3.FromAxis(Axis), math.rad(90))
			UpdateWorldValues()
			TweenService:Create(TweenRotationValue, RotationTweenInfo, {Value = RelativeBlockCFrame.Rotation}):Play()

			game.ReplicatedStorage.Sounds.Swoosh1:Play()
		else
			local ErrorTween = TweenService:Create(TweenRotationValue, ErrorTweenInfo, {Value = RelativeBlockCFrame.Rotation * CFrame.fromAxisAngle(Vector3.FromAxis(Axis), math.rad(10))})
			
			ErrorTween:Play()
			
			ErrorTween.Completed:Once(function()
				TweenService:Create(TweenRotationValue, ErrorTweenInfo, {Value = RelativeBlockCFrame.Rotation}):Play()
			end)

			game.ReplicatedStorage.Sounds.Empty1:Play()
		end
	end
end

function IsUnderBlueprintLimit()
	local totalPlaced = 0
	
	if BlockCollection and SelectedVehicle then
		for _, Block in BlockCollection do
			totalPlaced += Block.PlacedBlueprints
		end
	end
	
	return totalPlaced <= maxBlueprints
end

function CanPlace()
	return IsUnderBlueprintLimit() and BlockInZone and not BlockOverlapping and MouseRaycast and (Camera.Focus.Position - MouseRaycast.Position).Magnitude <= PlaceDistance
end

function PlaceBlock()
	if not PlaceDebounce and BlockPreview and BlockPreview.Parent == MiscStorage and BlockCollection[SelectedBlockID] then
		UpdateMouse()
		UpdateBlockPosition()
		if MouseRaycast then
			if CanPlace() then
				local BlockCFrame = CFrame.new(CurrentBlockPosition) * CurrentBlockRotation
				local TweenStart = CFrame.new(MouseRaycast.Normal * BlockDropHeight) * BlockCFrame

				PlaceDebounce = true
				game.ReplicatedStorage.Sounds.ClassicPing:Play()

				task.spawn(function()
					local Block = game.ReplicatedStorage.RemoteFunctions.PlaceBlock:InvokeServer(SelectedBlockID, RelativeBlockCFrame, PlacingOnBlock, PlacingOnWeldGroup)

					if Block then
						local CFrameValue = Instance.new("CFrameValue")
						local PlaceTween = TweenService:Create(CFrameValue, PlaceTweenInfo, {Value = BlockCFrame})
						local Clone = Block:Clone()
						local DisplayBox = script.PreviewRoot:Clone()

						for _, Descendant in Block:GetDescendants() do
							if Descendant:IsA("BasePart") then
								Descendant.LocalTransparencyModifier = 1
							end
						end

						for _, Descendant in Clone:GetDescendants() do
							if Descendant:IsA("BasePart") and Descendant.Transparency < 1 then
								Descendant.Anchored = true
								Descendant.CanCollide = false
								Descendant.CanQuery = false
								Descendant.CanTouch = false
							elseif not (Descendant:IsA("Model") or Descendant:IsA("Folder") or (Descendant:IsA("Constraint") and Descendant.Visible == true) or Descendant:IsA("Decal") or Descendant:IsA("Texture") or Descendant:IsA("SpecialMesh") or Descendant:IsA("Highlight") or Descendant:IsA("PartAdornment") or Descendant:IsA("SelectionBox")) then
								Descendant:Destroy()
							end
						end

						CFrameValue.Value = TweenStart
						PlacedBlockTweens[Clone] = CFrameValue
						Clone.Parent = MiscStorage
						DisplayBox.Parent = MiscStorage
						DisplayBox.Size = SelectedBlock:GetAttribute("BlockDimensions")
						DisplayBox.CFrame = BlockCFrame
						DisplayBox.Box.Transparency = 0.6
						DisplayBox.Box.SurfaceTransparency = 0.2
						DisplayBox.Box.Color3 = Color3.new(0, 1, 0)
						DisplayBox.Box.SurfaceColor3 = Color3.new(0, 1, 0)
						PlaceTween:Play()
						TweenService:Create(DisplayBox.Box, BoxTweenInfo, {Transparency = 1}):Play()
						TweenService:Create(DisplayBox.Box, BoxTweenInfo, {SurfaceTransparency = 1}):Play()
						UpdateCurrentBlockAmounts()
						
						if DeviceType == "Mobile" then
							MouseRay = Ray.new(MouseRay.Origin + TargetBlockOffset, MouseRay.Direction)
							MouseRaycast = workspace:Raycast(MouseRay.Origin, MouseRay.Direction * 10000, MouseRaycastParameters)
						end

						PlaceTween.Completed:Once(function()
							PlacedBlockTweens[Clone] = nil
							Clone:Destroy()
							DisplayBox:Destroy()

							for _, Descendant in Block:GetDescendants() do
								if Descendant:IsA("BasePart") then
									Descendant.LocalTransparencyModifier = 0
								end
							end
						end)
					end

					PlaceDebounce = false
				end)
			else
				game.ReplicatedStorage.Sounds.Error1:Play()
			end
		end
	end
end

function DeleteBlock()
	if not DeleteDebounce and CurrentBlockToDelete then
		local Reference = CurrentBlockToDelete:Clone()
		
		DeleteDebounce = true
		
		task.spawn(function()
			local Success = game.ReplicatedStorage.RemoteFunctions.DeleteBlock:InvokeServer(CurrentBlockToDelete)
			
			if Success then
				for _, Descendant in Reference:GetDescendants() do
					if Descendant:IsA("BasePart") and Descendant.Transparency < 1  then
						local DebrisCount = math.round(math.pow(Descendant.Mass / Descendant.CurrentPhysicalProperties.Density * 1000, 0.4) * 0.1)
						local RemainingDebris = DebrisCount
						
						while RemainingDebris > 0 do
							local RandomPosition = Descendant.Position + (Vector3.new(math.random(), math.random(), math.random()) * 2 - Vector3.one) * Descendant.Size
							
							if Descendant:GetClosestPointOnSurface(RandomPosition) == RandomPosition then
								local Debris = Descendant:Clone()
								local Tween = TweenService:Create(Debris, TweenInfo.new(0.4 + math.random(), Enum.EasingStyle.Linear, Enum.EasingDirection.Out), {Size = Vector3.new()})
								local SizeOrder = {Descendant.Size.X, Descendant.Size.Y, Descendant.Size.Z}
								
								for Index1 = 1, 3 do
									local Index2 = math.random(3)
									
									SizeOrder[Index1], SizeOrder[Index2] = SizeOrder[Index2], SizeOrder[Index1]
								end
								
								RemainingDebris -= 1
								table.insert(MouseIgnore, Debris)
								Debris.Parent = workspace.MiscStorage
								Debris.Position = RandomPosition
								Debris.Anchored = false
								Debris.Size = Vector3.new(SizeOrder[1], SizeOrder[2], SizeOrder[3]) / math.pow(DebrisCount, 0.8) * 0.6
								Debris.CustomPhysicalProperties = PhysicalProperties.new(0.1, 0.2, 0, 100, 100)
								Debris:BreakJoints()
								Debris:ApplyImpulse(((Debris.Position - MainFunctions.GetBlockWeldRootCenter(Reference, 1).Position) * 4 + Vector3.new(0, math.sqrt(workspace.Gravity) * 2, 0)) * Debris.Mass)
								Debris:ApplyAngularImpulse(Vector3.new(math.random() - 0.5, math.random() - 0.5, math.random() - 0.5) * Debris.Mass * Debris.Size.Magnitude * 4)
								Tween:Play()
								
								Tween.Completed:Once(function()
									Debris:Destroy()
									table.remove(MouseIgnore, table.find(MouseIgnore, Debris))
								end)
							end
						end
					end
				end
				
				UpdateCurrentBlockAmounts()
				UpdateMouse()
				UpdateDeleteSelection()
			end
			
			DeleteDebounce = false
			Reference:Destroy()
			game.ReplicatedStorage.Sounds.Pop2:Play()
		end)
	end
end

game.ReplicatedStorage.RemoteEvents.UpdatePlacedBlocks.OnClientEvent:Connect(UpdateCurrentBlockAmounts)

function UpdateBlockCollection(NewInventory)
	if not BlockCollection then
		BlockCollection = {}
	end

	for _, IDValue in game.ReplicatedStorage.InventoryIDs:GetChildren() do
		BlockCollection[IDValue.Name] = {Unlocked = NewInventory[IDValue.Name] or IDValue:GetAttribute("StartingAmount"), PlacedBlueprints = 0}
	end

	UpdateCurrentBlockAmounts()
end

game.ReplicatedStorage.RemoteEvents.UpdateBlockCollection.OnClientEvent:Connect(UpdateBlockCollection)

RunService.RenderStepped:Connect(function()
	for Block, Value in PlacedBlockTweens do
		Block:PivotTo(Value.Value)
	end
	
	if DeviceType == "Computer" then
		UpdateMouse()
	end

	if BuildMode == "Place" then
		if BlockPreview then
			script.Overlay.Adornee = BlockPreview.BlockModel
			UpdateBlockPosition()

			if CanPlace() then
				script.Overlay.FillColor = Color3.new(0, 1, 0)
				script.Overlay.OutlineColor = Color3.new(0, 1, 0)
				BlockPreview.BlockModel.PreviewRoot.Box.Color3 = Color3.new(0, 1, 0)
			else
				script.Overlay.FillColor = Color3.new(1, 0, 0)
				script.Overlay.OutlineColor = Color3.new(1, 0, 0)
				BlockPreview.BlockModel.PreviewRoot.Box.Color3 = Color3.new(1, 0, 0)
			end
		end
	elseif BuildMode == "Delete" then
		UpdateDeleteSelection()
	end
end)

UserInputService.InputBegan:Connect(function(Input, OnGui)
	if DeviceType == "Computer" then
		if Input.UserInputType == Enum.UserInputType.MouseMovement then
			MouseEnabled = true
		end
	elseif DeviceType == "Mobile" then
		if Input.UserInputType == Enum.UserInputType.Touch and BuildMode and not OnGui then
			TouchBlockPosition = RelativeBlockCFrame.Position
			TouchBlockToDelete = CurrentBlockToDelete
			UpdateMouse()
		end
	end
	
	if not UserInputService:GetFocusedTextBox() then
		if Input.UserInputType == Enum.UserInputType.MouseButton1 then
			if not OnGui then
				if BuildMode == "Place" then
					PlaceBlock()
				elseif BuildMode == "Delete" then
					DeleteBlock()
				end
			end
		elseif Input.KeyCode == Enum.KeyCode.Q then
			UpdateStatus("Place")
		elseif Input.KeyCode == Enum.KeyCode.E then
			UpdateStatus("Delete")
		elseif Input.KeyCode == Enum.KeyCode.R then
			RotateBlock(Enum.Axis.Y)
		elseif Input.KeyCode == Enum.KeyCode.T then
			RotateBlock(Enum.Axis.X)
		elseif Input.KeyCode == Enum.KeyCode.Y then
			RotateBlock(Enum.Axis.Z)
		end
	end
end)

UserInputService.InputEnded:Connect(function(Input, OnGui)
	if Input.UserInputType == Enum.UserInputType.MouseMovement then
		MouseEnabled = false
	end
end)

UserInputService.TouchMoved:Connect(function(Input, OnGui)
	if BuildMode and not OnGui then
		UpdateMouse()
	end
end)

UserInputService.TouchTapInWorld:Connect(function(Position, OnGui)
	if not OnGui then
		if BuildMode == "Place" then
			if RelativeBlockCFrame.Position == TouchBlockPosition then
				PlaceBlock()
			end
		elseif BuildMode == "Delete" then
			if CurrentBlockToDelete == TouchBlockToDelete then
				DeleteBlock()
			end
		end
	end
end)

ScreenGui.ScreenRight.BuildButton.MouseButton1Up:Connect(function()
	UpdateStatus("Place")
end)

ScreenGui.ScreenRight.DeleteButton.MouseButton1Up:Connect(function()
	UpdateStatus("Delete")
end)

BuildFrame.R.MouseButton1Up:Connect(function()
	RotateBlock(Enum.Axis.Y)
end)

BuildFrame.T.MouseButton1Up:Connect(function()
	RotateBlock(Enum.Axis.X)
end)

BuildFrame.Y.MouseButton1Up:Connect(function()
	RotateBlock(Enum.Axis.Z)
end)

for _, CategoryButton in BuildFrame.CategoryButtons:GetChildren() do
	CategoryButton.MouseButton1Up:Connect(function()
		TweenService:Create(BuildFrame.ScrollFrame.CategoryFrame, GuiTweenInfo, {Position = CategoryButton:GetAttribute("FramePosition")}):Play()
	end)
end

MouseRaycastParameters.FilterType = Enum.RaycastFilterType.Exclude
BlockRaycastParameters.FilterType = Enum.RaycastFilterType.Include
BlockOverlapParameters.FilterType = Enum.RaycastFilterType.Include
BlockOverlapParameters.FilterDescendantsInstances = {CreationModel.CreationFolder}

if UserInputService.KeyboardEnabled then
	DeviceType = "Computer"
else
	DeviceType = "Mobile"
end

for _, IDValue in game.ReplicatedStorage.InventoryIDs:GetChildren() do
	local Category = game.ReplicatedStorage.InventoryIDs:FindFirstChild(IDValue.Name):GetAttribute("Category")
	
	if Category and IDValue.Value then
		local CategoryPage = BuildFrame.ScrollFrame.CategoryFrame.CategoryPages:FindFirstChild(Category)
		
		if CategoryPage then
			local BlockFrame = game.ReplicatedStorage.GuiElements.BlockElement:Clone()
			local BlockViewport = IDValue.BlockViewport:Clone()

			BlockFrame.Parent = CategoryPage
			BlockFrame.Name = IDValue.Name
			BlockFrame.LayoutOrder = IDValue:GetAttribute("InventoryPosition")
			BlockViewport.Parent = BlockFrame
			BlockViewport.CurrentCamera = IDValue.BlockViewport.CurrentCamera
			
			if DeviceType == "Computer" then
				BlockFrame.Size = UDim2.fromScale(0.5, 0.5)
				BlockFrame.SizeConstraint = Enum.SizeConstraint.RelativeXX
			elseif DeviceType == "Mobile" then
				BlockFrame.Size = UDim2.fromScale(1, 1)
				BlockFrame.SizeConstraint = Enum.SizeConstraint.RelativeYY
			end

			BlockFrame.Select.MouseButton1Down:Connect(function()
				if IDValue.Name ~= SelectedBlockID then
					game.ReplicatedStorage.Sounds.Tap2Low:Play()
				else
					game.ReplicatedStorage.Sounds.Tap1:Play()
				end
			end)

			BlockFrame.Select.MouseButton1Up:Connect(function()
				if IDValue.Name ~= SelectedBlockID then
					SelectBlock(IDValue.Name)
					game.ReplicatedStorage.Sounds.Tap2High:Play()
				end
			end)
		end
	end
end

UpdateBlockCollection(game.ReplicatedStorage.RemoteFunctions.GetBlockCollection:InvokeServer())