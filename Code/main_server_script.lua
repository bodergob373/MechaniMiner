local GeometryService = game:GetService("GeometryService")
local UtilityFunctions = require(game.ReplicatedStorage.UtilityFunctions)
local GameSettings = require(game.ReplicatedStorage.GameSettings)
local ServerFunctions = require(game.ServerScriptService.ServerFunctions)
local BlockIDs = game.ReplicatedStorage.BlockIDs
local SellButtons = CollectionService:GetTagged("SellButton")
local BuyButtons = CollectionService:GetTagged("BuyButton")

function UpdateAssemblyRootParts(CreationData)
	for LastAssemblyRootPart, AssemblyData in CreationData.AssemblyMarkers do
		local ActualAssemblyRootPart = AssemblyData.MainPart.AssemblyRootPart
		
		if ActualAssemblyRootPart then
			if ActualAssemblyRootPart ~= LastAssemblyRootPart then
				CreationData.AssemblyMarkers[LastAssemblyRootPart] = nil
				CreationData.AssemblyMarkers[ActualAssemblyRootPart] = AssemblyData
			end
		end
	end
end

function WeldBlock(Player, WeldBlock, CFrameOn, OnBlock, OnWeldGroup)
	local CreationModel = workspace.PlayerBuilds:FindFirstChild(Player.UserId)
	
	if OnBlock and OnWeldGroup and WeldBlock and CreationModel then
		local OnAssemblyRootPart = UtilityFunctions.GetBlockWeldRoot(OnBlock, OnWeldGroup).AssemblyRootPart
		
		if OnAssemblyRootPart then
			local OnAssembly = PlayerInfo[Player].CreationData.AssemblyMarkers[OnAssemblyRootPart]

			if OnAssembly then
				local AssemblyCenterCFrame = OnAssembly.MainPart.CFrame * OnAssembly.AssemblyCFrameOffset
				local WeldBlockCFrame = UtilityFunctions.GetBlockWeldRootCenter(OnBlock, OnWeldGroup) * CFrameOn
				local WeldBlockValue = game.ReplicatedStorage.BlockIDs:FindFirstChild(WeldBlock.Name)
				local ConnectionOverlapParameters = OverlapParams.new()
				local FilterDescendantsInstances = {}
				local WeldBlockConnections = {}
				local AssemblyConnectionRoots = {}
				local CreatedWelds = {}

				if WeldBlockValue and WeldBlockValue.Value then
					local BlockTemplate = BlocksFolder:FindFirstChild(WeldBlockValue.Value)

					if BlockTemplate and BlockTemplate:FindFirstChild("BlockModel") and BlockTemplate:FindFirstChild("Connections") then
						for _, ConnectionReference in BlockTemplate.Connections:GetChildren() do
							local ConnectionWeldGroup = ConnectionReference:GetAttribute("WeldGroup")
							local WeldGroupAssemblyOffset = AssemblyCenterCFrame:Inverse() * WeldBlockCFrame
							local ConnectionOffset = UtilityFunctions.GetBlockWeldRootCenter(BlockTemplate.BlockModel, ConnectionWeldGroup):Inverse() * ConnectionReference.CFrame
							local ConnectionPart = ConnectionReference:Clone()

							ConnectionPart.Parent = workspace.MiscStorage
							ConnectionPart.CFrame = WeldGroupAssemblyOffset * ConnectionOffset
							WeldBlockConnections[ConnectionPart] = ConnectionWeldGroup
						end
					end
				end
				
				for _, BlockWeldGroupInfo in OnAssembly.BlockWeldGroups do
					local Block = BlockWeldGroupInfo.BlockInfo.Block
					local BlockValue = game.ReplicatedStorage.BlockIDs:FindFirstChild(Block.Name)

					if BlockValue and BlockValue.Value then
						local BlockTemplate = BlocksFolder:FindFirstChild(BlockValue.Value)

						if BlockTemplate and BlockTemplate:FindFirstChild("BlockModel") and BlockTemplate:FindFirstChild("Connections") then
							local WeldGroup = BlockWeldGroupInfo.WeldGroup
							local TemplateCenter = UtilityFunctions.GetBlockWeldRootCenter(BlockTemplate.BlockModel, WeldGroup)

							for _, ConnectionReference in BlockTemplate.Connections:GetChildren() do
								if ConnectionReference:GetAttribute("WeldGroup") == WeldGroup then
									local WeldGroupAssemblyOffset = AssemblyCenterCFrame:Inverse() * UtilityFunctions.GetBlockWeldRootCenter(Block, WeldGroup)
									local ConnectionOffset = TemplateCenter:Inverse() * ConnectionReference.CFrame
									local ConnectionPart = ConnectionReference:Clone()

									ConnectionPart.Parent = workspace.MiscStorage
									ConnectionPart.CFrame = WeldGroupAssemblyOffset * ConnectionOffset
									AssemblyConnectionRoots[ConnectionPart] = UtilityFunctions.GetBlockWeldRoot(Block, WeldGroup)
									table.insert(FilterDescendantsInstances, ConnectionPart)
								end
							end
						end
					end
				end

				ConnectionOverlapParameters.FilterType = Enum.RaycastFilterType.Include
				ConnectionOverlapParameters.FilterDescendantsInstances = FilterDescendantsInstances

				for Connection, WeldGroup in WeldBlockConnections do
					local OverlappingConnections = workspace:GetPartsInPart(Connection, ConnectionOverlapParameters)

					for _, OverlappingConnection in OverlappingConnections do
						local RootPart = UtilityFunctions.GetBlockWeldRoot(WeldBlock, WeldGroup)
						local RootPartOffset = UtilityFunctions.GetBlockWeldRootOffset(WeldBlock, WeldGroup)
						local WeldBlockAssemblyCFrame = AssemblyCenterCFrame:Inverse() * WeldBlockCFrame
						local WeldToAssemblyCFrame = AssemblyCenterCFrame:Inverse() * AssemblyConnectionRoots[OverlappingConnection].CFrame
						local WeldBlockAssemblyPosition =UtilityFunctions.RoundVector3(WeldBlockAssemblyCFrame.Position, GameSettings.BlockPositionIncrement / 2)
						--local WeldBlockAssemblyRotation = CFrame.fromOrientation(UtilityFunctions.RoundVector3(Vector3.new(WeldBlockAssemblyCFrame.Rotation:ToOrientation()), math.rad(BlockRotationIncrement)))
						local WeldBlockAssemblyRotation = UtilityFunctions.SnapCFrameAxis(WeldBlockAssemblyCFrame.Rotation)
						local WeldInfo = {RootPart = RootPart, ConnectionRoot = AssemblyConnectionRoots[OverlappingConnection], RootOffset = CFrame.new(WeldBlockAssemblyPosition) * WeldBlockAssemblyRotation * RootPartOffset:Inverse(), ConnectionOffset = WeldToAssemblyCFrame}
						
						table.insert(CreatedWelds, WeldInfo)
					end

					Connection:Destroy()
				end

				for Connection, RootPart in AssemblyConnectionRoots do
					Connection:Destroy()
				end
				
				for _, WeldInfo in CreatedWelds do
					local Weld = Instance.new("Weld")

					Weld.Parent = WeldInfo.RootPart
					Weld.Part0 = WeldInfo.RootPart
					Weld.Part1 = WeldInfo.ConnectionRoot
					Weld.C0 = WeldInfo.RootOffset:Inverse() * WeldInfo.ConnectionOffset
				end
				
				UpdateAssemblyRootParts(PlayerInfo[Player].CreationData)
			end
		end
	end
end

function PlaceBlock(Player, BlockID, BlockCFrame, OnBlock, OnWeldGroup)
	local CreationModel = workspace.PlayerBuilds:FindFirstChild(Player.UserId)
	
	if CreationModel and PlayerInfo[Player].Status == "Building" and BlockIDs:FindFirstChild(BlockID) and BlockIDs:FindFirstChild(BlockID).Value then
		local Block = BlocksFolder:FindFirstChild(BlockIDs:FindFirstChild(BlockID).Value)
		local CreationData = PlayerInfo[Player].CreationData

		if Block and CreationData then
			local BlockPosition = UtilityFunctions.RoundVector3(BlockCFrame.Position, GameSettings.BlockPositionIncrement / 2)
			--local BlockRotation = CFrame.fromOrientation(UtilityFunctions.RoundVector3(Vector3.new(BlockCFrame.Rotation:ToOrientation()), math.rad(BlockRotationIncrement)))
			local BlockRotation = UtilityFunctions.SnapCFrameAxis(BlockCFrame.Rotation)
			local BlockClone = Block.BlockModel:Clone()
			local BlockInfo = {Block = BlockClone, WeldGroups = {}}
			
			BlockCFrame = CFrame.new(BlockPosition) * BlockRotation
			BlockClone.Parent = CreationModel.CreationFolder	
			BlockClone.Name = BlockID
			table.insert(CreationData.BlockData, BlockInfo)
			CreationData.BlockMarkers[BlockClone] = BlockInfo

			if OnBlock and OnWeldGroup then
				BlockClone:PivotTo(UtilityFunctions.GetBlockWeldRootCenter(OnBlock, OnWeldGroup) * BlockCFrame)
			else
				BlockClone:PivotTo(BlockCFrame)
			end

			for _, Part in BlockClone:GetDescendants() do
				if Part:IsA("BasePart") then
					Part.Anchored = false
				end
			end
			
			WeldBlock(Player, BlockClone, BlockCFrame, OnBlock, OnWeldGroup)
			
			for _, BasePart in BlockClone:GetChildren() do
				if BasePart:IsA("BasePart") and BasePart:HasTag("WeldGroupRoot") then
					local WeldGroup = BasePart:GetAttribute("WeldGroup")

					if WeldGroup then
						local BlockDimensions = UtilityFunctions.GetBlockDimensions(BlockClone)
						local BlockCFrame = nil
						local BlockAxisRotation = nil
						local RoundedBlockRotation = nil
						local BlockBounds = nil
						local BlockRoundOffset = nil
						local RoundedBPX, RoundedBPY, RoundedBPZ = nil
						local RelativeCFrame = UtilityFunctions.GetBlockWeldRootCenter(BlockClone, WeldGroup)
						local RoundedCFrame = nil
						local WeldGroupInfo = nil
						local AssemblyData = CreationData.AssemblyMarkers[BasePart.AssemblyRootPart]

						if not AssemblyData then
							local AssemblyRoundOffset = Vector3.new((BlockDimensions.X / 2) % GameSettings.BlockPositionIncrement, (BlockDimensions.Y / 2) % GameSettings.BlockPositionIncrement, (BlockDimensions.Z / 2) % GameSettings.BlockPositionIncrement)

							AssemblyData = {MainPart = BasePart, AssemblyRoundOffset = AssemblyRoundOffset, AssemblyCFrameOffset = UtilityFunctions.GetBlockWeldRootOffset(BlockClone, WeldGroup), BlockWeldGroups = {}}
							table.insert(CreationData.AssemblyData, AssemblyData)
							CreationData.AssemblyMarkers[BasePart.AssemblyRootPart] = AssemblyData
						end

						BlockCFrame = (AssemblyData.MainPart.CFrame * AssemblyData.AssemblyCFrameOffset):Inverse() * RelativeCFrame
						--RoundedBRX, RoundedBRY, RoundedBRZ = UtilityFunctions.CleanRoundVector3(Vector3.new(BlockCFrame:ToOrientation()) * math.deg(1), BlockRotationIncrement)
						--BlockAxisRotation = UtilityFunctions.AxisAngleToAxisRotation(BlockCFrame.Rotation:ToAxisAngle())
						BlockAxisRotation = UtilityFunctions.ToAxisRotation(BlockCFrame.Rotation)
						--RoundedBlockRotation = CFrame.fromAxisAngle(UtilityFunctions.AxisRotationToAxisAngle(BlockAxisRotation))
						RoundedBlockRotation = UtilityFunctions.FromAxisAngle(UtilityFunctions.AxisRotationToAxisAngle(BlockAxisRotation))
						--BlockBounds = (CFrame.fromOrientation(math.rad(RoundedBRX), math.rad(RoundedBRY), math.rad(RoundedBRZ)) * CFrame.new(BlockDimensions)).Position:Abs()
						BlockBounds = (RoundedBlockRotation * CFrame.new(BlockDimensions)).Position:Abs()
						BlockRoundOffset = Vector3.new((BlockBounds.X / 2) % GameSettings.BlockPositionIncrement, (BlockBounds.Y / 2) % GameSettings.BlockPositionIncrement, (BlockBounds.Z / 2) % GameSettings.BlockPositionIncrement)
						RoundedBPX, RoundedBPY, RoundedBPZ = UtilityFunctions. RoundVector3(BlockCFrame.Position, GameSettings.BlockPositionIncrement, BlockRoundOffset - AssemblyData.AssemblyRoundOffset)
						RoundedCFrame = CFrame.new(RoundedBPX, RoundedBPY, RoundedBPZ) * RoundedBlockRotation
						WeldGroupInfo = {BlockInfo = BlockInfo, WeldGroup = WeldGroup}
						BlockInfo.WeldGroups[WeldGroup] = {WeldGroupInfo = WeldGroupInfo, RelativeCFrame = RoundedCFrame}
						table.insert(AssemblyData.BlockWeldGroups, WeldGroupInfo)
					end
				end
			end

			return BlockClone
		end
	end
end

function DeleteBlock(Player, Block)
	if PlayerInfo[Player].Status == "Building" then
		local CreationData = PlayerInfo[Player].CreationData
		local BlockInfo = CreationData.BlockMarkers[Block]
		local ConnectedAssemblies = {}
		
		for _, BasePart in Block:GetChildren() do
			if BasePart:IsA("BasePart") and BasePart:HasTag("WeldGroupRoot") then
				local WeldGroup = BasePart:GetAttribute("WeldGroup")
				local WeldGroupInfo = BlockInfo.WeldGroups[WeldGroup].WeldGroupInfo
				local AssemblyData = CreationData.AssemblyMarkers[BasePart.AssemblyRootPart]
				
				if WeldGroup and WeldGroupInfo and AssemblyData then
					local AssemblyWeldGroups = AssemblyData.BlockWeldGroups
					local ConnectedAssemblyInfo = {LastAssemblyRootPart = BasePart.AssemblyRootPart, AssemblyData = AssemblyData}
					
					table.remove(AssemblyWeldGroups, table.find(AssemblyWeldGroups, WeldGroupInfo))

					if not table.find(ConnectedAssemblies, ConnectedAssemblyInfo) then
						table.insert(ConnectedAssemblies, ConnectedAssemblyInfo)
					end
				end
			end
		end
		
		table.remove(CreationData.BlockData, table.find(CreationData.BlockData, BlockInfo))
		CreationData.BlockMarkers[Block] = nil
		Block:Destroy()
		
		for _, ConnectedAssemblyInfo in ConnectedAssemblies do
			local SortedWeldGroupAssemblies = {}
			
			for _, BlockWeldGroup in ConnectedAssemblyInfo.AssemblyData.BlockWeldGroups do
				local AssemblyRootPart = UtilityFunctions.GetBlockWeldRoot(BlockWeldGroup.BlockInfo.Block, BlockWeldGroup.WeldGroup).AssemblyRootPart
				
				if not SortedWeldGroupAssemblies[AssemblyRootPart] then
					SortedWeldGroupAssemblies[AssemblyRootPart] = {}
				end
				
				table.insert(SortedWeldGroupAssemblies[AssemblyRootPart], BlockWeldGroup)
			end
			
			table.remove(CreationData.AssemblyData, table.find(CreationData.AssemblyData, ConnectedAssemblyInfo.AssemblyData))
			CreationData.AssemblyMarkers[ConnectedAssemblyInfo.LastAssemblyRootPart] = nil
			
			for AssemblyRootPart, WeldGroups in SortedWeldGroupAssemblies do
				local NewAssemblyData = table.clone(ConnectedAssemblyInfo.AssemblyData)
				
				NewAssemblyData.BlockWeldGroups = WeldGroups
				
				if not NewAssemblyData.MainPart:IsDescendantOf(workspace) or NewAssemblyData.MainPart.AssemblyRootPart ~= AssemblyRootPart then
					local MainWeldGroupInfo = WeldGroups[1]
					local MainPartWeldGroup = MainWeldGroupInfo.WeldGroup
					local MainBlockInfo = MainWeldGroupInfo.BlockInfo
					local MainWeldGroupRelativeCFrame = MainBlockInfo.WeldGroups[MainPartWeldGroup].RelativeCFrame
					local MainBlockDimensions = UtilityFunctions.GetBlockDimensions(MainBlockInfo.Block)
					local NewMainPart = UtilityFunctions.GetBlockWeldRoot(MainBlockInfo.Block, MainPartWeldGroup)
					local NewAssemblyRoundOffset = Vector3.new((MainBlockDimensions.X / 2) % GameSettings.BlockPositionIncrement, (MainBlockDimensions.Y / 2) % GameSettings.BlockPositionIncrement, (MainBlockDimensions.Z / 2) % GameSettings.BlockPositionIncrement)
					
					NewAssemblyData.AssemblyCFrameOffset = UtilityFunctions.GetBlockWeldRootOffset(MainBlockInfo.Block, MainPartWeldGroup) * MainWeldGroupRelativeCFrame:Inverse()
					NewAssemblyData.AssemblyRoundOffset = NewAssemblyRoundOffset
					NewAssemblyData.MainPart = NewMainPart
				end
				
				table.insert(CreationData.AssemblyData, NewAssemblyData)
				CreationData.AssemblyMarkers[AssemblyRootPart] = NewAssemblyData
			end
		end
		
		UpdateAssemblyRootParts(CreationData)
		
		return true
	end

	return false
end

function CompileCreationFolder(Folder, OriginCFrame)
	if Folder and OriginCFrame then
		local Assemblies = {}
		local CreationData = {BlockData = {}, AssemblyData = {}}

		for _, Block in Folder:GetChildren() do
			local BlockInfo = {ID = Block.Name, WG = {}}

			for _, BasePart in Block:GetChildren() do
				if BasePart:IsA("BasePart") and BasePart:HasTag("WeldGroupRoot") then
					local WeldGroup = BasePart:GetAttribute("WeldGroup")

					if WeldGroup then
						local BlockDimensions = UtilityFunctions.GetBlockDimensions(Block)
						local BlockCFrame = nil
						local BlockAxisRotation = nil
						local RoundedBlockRotation = nil
						local BlockBounds = nil
						local BlockRoundOffset = nil
						local RoundedBPX, RoundedBPY, RoundedBPZ = nil
						local RelativeCFrame = OriginCFrame:Inverse() * UtilityFunctions.GetBlockWeldRootCenter(Block, WeldGroup)

						if not Assemblies[BasePart.AssemblyRootPart] then
							local AssemblyRoundOffset = Vector3.new((BlockDimensions.X / 2) % GameSettings.BlockPositionIncrement, (BlockDimensions.Y / 2) % GameSettings.BlockPositionIncrement, (BlockDimensions.Z / 2) % GameSettings.BlockPositionIncrement)
							local RoundedARX, RoundedARY, RoundedARZ = UtilityFunctions.CleanRoundVector3(Vector3.new(RelativeCFrame:ToOrientation()) * 2 / math.pi, GameSettings.AssemblyRotationIncrement)
							local RoundedAPX, RoundedAPY, RoundedAPZ = UtilityFunctions.CleanRoundVector3(RelativeCFrame.Position, GameSettings.AssemblyPositionIncrement)

							table.insert(CreationData.AssemblyData, {PX = RoundedAPX, PY = RoundedAPY, PZ = RoundedAPZ, RX = RoundedARX, RY = RoundedARY, RZ = RoundedARZ})
							Assemblies[BasePart.AssemblyRootPart] = {AssemblyIndex = #CreationData.AssemblyData, AssemblyCFrame = RelativeCFrame, AssemblyRoundOffset = AssemblyRoundOffset}
						end

						BlockCFrame = Assemblies[BasePart.AssemblyRootPart].AssemblyCFrame:Inverse() * RelativeCFrame
						--RoundedBRX, RoundedBRY, RoundedBRZ = UtilityFunctions.CleanRoundVector3(Vector3.new(BlockCFrame:ToOrientation()) * math.deg(1), BlockRotationIncrement)
						--BlockAxisRotation = UtilityFunctions.AxisAngleToAxisRotation(BlockCFrame.Rotation:ToAxisAngle())
						BlockAxisRotation = UtilityFunctions.ToAxisRotation(BlockCFrame.Rotation)
						--RoundedBlockRotation = CFrame.fromAxisAngle(UtilityFunctions.AxisRotationToAxisAngle(BlockAxisRotation))
						RoundedBlockRotation = UtilityFunctions.FromAxisAngle(UtilityFunctions.AxisRotationToAxisAngle(BlockAxisRotation))
						--BlockBounds = (CFrame.fromOrientation(math.rad(RoundedBRX), math.rad(RoundedBRY), math.rad(RoundedBRZ)) * CFrame.new(BlockDimensions)).Position:Abs()
						BlockBounds = (RoundedBlockRotation * CFrame.new(BlockDimensions)).Position:Abs()
						BlockRoundOffset = Vector3.new((BlockBounds.X / 2) % GameSettings.BlockPositionIncrement, (BlockBounds.Y / 2) % GameSettings.BlockPositionIncrement, (BlockBounds.Z / 2) % GameSettings.BlockPositionIncrement)
						RoundedBPX, RoundedBPY, RoundedBPZ = UtilityFunctions.CleanRoundVector3(BlockCFrame.Position, GameSettings.BlockPositionIncrement, BlockRoundOffset - Assemblies[BasePart.AssemblyRootPart].AssemblyRoundOffset)
						BlockInfo.WG[WeldGroup] = {PX = RoundedBPX, PY = RoundedBPY, PZ = RoundedBPZ, AR = BlockAxisRotation, AI = Assemblies[BasePart.AssemblyRootPart].AssemblyIndex}
					end
				end
			end

			table.insert(CreationData.BlockData, BlockInfo)
		end

		return CreationData
	end
end

function SetCreationData(Player)
	local CreationModel = workspace.PlayerBuilds:FindFirstChild(Player.UserId)
	
	if CreationModel and CreationModel.CreationFolder then
		local CreationData = {BlockData = {}, AssemblyData = {}, BlockMarkers = {}, AssemblyMarkers = {}}

		for _, Block in CreationModel.CreationFolder:GetChildren() do
			local BlockInfo = {Block = Block, WeldGroups = {}}

			for _, BasePart in Block:GetChildren() do
				if BasePart:IsA("BasePart") and BasePart:HasTag("WeldGroupRoot") then
					local WeldGroup = BasePart:GetAttribute("WeldGroup")

					if WeldGroup then
						local BlockDimensions = UtilityFunctions.GetBlockDimensions(Block)
						local BlockCFrame = nil
						local BlockAxisRotation = nil
						local RoundedBlockRotation = nil
						local BlockBounds = nil
						local BlockRoundOffset = nil
						local RoundedBPX, RoundedBPY, RoundedBPZ = nil
						local RelativeCFrame = UtilityFunctions.GetBlockWeldRootCenter(Block, WeldGroup)
						local RoundedCFrame = nil
						local WeldGroupInfo = nil
						local AssemblyData = CreationData.AssemblyMarkers[BasePart.AssemblyRootPart]

						if not AssemblyData then
							local AssemblyRoundOffset = Vector3.new((BlockDimensions.X / 2) % GameSettings.BlockPositionIncrement, (BlockDimensions.Y / 2) % GameSettings.BlockPositionIncrement, (BlockDimensions.Z / 2) % GameSettings.BlockPositionIncrement)
							
							AssemblyData = {MainPart = BasePart, AssemblyRoundOffset = AssemblyRoundOffset, AssemblyCFrameOffset = UtilityFunctions.GetBlockWeldRootOffset(Block, WeldGroup), BlockWeldGroups = {}}
							table.insert(CreationData.AssemblyData, AssemblyData)
							CreationData.AssemblyMarkers[BasePart.AssemblyRootPart] = AssemblyData
						end

						BlockCFrame = (AssemblyData.MainPart.CFrame * AssemblyData.AssemblyCFrameOffset):Inverse() * RelativeCFrame
						--RoundedBRX, RoundedBRY, RoundedBRZ = UtilityFunctions.CleanRoundVector3(Vector3.new(BlockCFrame:ToOrientation()) * math.deg(1), BlockRotationIncrement)
						--BlockAxisRotation = UtilityFunctions.AxisAngleToAxisRotation(BlockCFrame.Rotation:ToAxisAngle())
						BlockAxisRotation = UtilityFunctions.ToAxisRotation(BlockCFrame.Rotation)
						--RoundedBlockRotation = CFrame.fromAxisAngle(UtilityFunctions.AxisRotationToAxisAngle(BlockAxisRotation))
						RoundedBlockRotation = UtilityFunctions.FromAxisAngle(UtilityFunctions.AxisRotationToAxisAngle(BlockAxisRotation))
						--BlockBounds = (CFrame.fromOrientation(math.rad(RoundedBRX), math.rad(RoundedBRY), math.rad(RoundedBRZ)) * CFrame.new(BlockDimensions)).Position:Abs()
						BlockBounds = (RoundedBlockRotation * CFrame.new(BlockDimensions)).Position:Abs()
						BlockRoundOffset = Vector3.new((BlockBounds.X / 2) % GameSettings.BlockPositionIncrement, (BlockBounds.Y / 2) % GameSettings.BlockPositionIncrement, (BlockBounds.Z / 2) % GameSettings.BlockPositionIncrement)
						RoundedBPX, RoundedBPY, RoundedBPZ = UtilityFunctions. RoundVector3(BlockCFrame.Position, GameSettings.BlockPositionIncrement, BlockRoundOffset - AssemblyData.AssemblyRoundOffset)
						RoundedCFrame = CFrame.new(RoundedBPX, RoundedBPY, RoundedBPZ) * RoundedBlockRotation
						WeldGroupInfo = {BlockInfo = BlockInfo, WeldGroup = WeldGroup}
						BlockInfo.WeldGroups[WeldGroup] = {WeldGroupInfo = WeldGroupInfo, RelativeCFrame = RoundedCFrame}
						table.insert(AssemblyData.BlockWeldGroups, WeldGroupInfo)
					end
				end
			end

			table.insert(CreationData.BlockData, BlockInfo)
			CreationData.BlockMarkers[Block] = BlockInfo
		end
		
		PlayerInfo[Player].CreationData = CreationData
	end
end

function SavePlayerCreation(Player, SlotIndex)
	local CreationModel = workspace.PlayerBuilds:FindFirstChild(Player.UserId)
	local Success = false

	if SlotIndex and CreationModel and CreationModel:FindFirstChild("CreationFolder") then
		--local Clone = CreationModel:Clone()
		--local EncodedCreationData = HTTPService:JSONEncode(CompileCreationFolder(Clone.CreationFolder, Clone:GetPivot()))
		local EncodedCreationData = HTTPService:JSONEncode(CompileCreationFolder(CreationModel.CreationFolder, CreationModel:GetPivot()))

		Success = game.ReplicatedStorage.BindableFunctions.SetData:Invoke(Player, "CreationsSlot" .. SlotIndex, EncodedCreationData)
		--Clone:Destroy()
	end

	return Success
end

function LoadCreations(Player, SlotIndex, OriginCFrame)
	local CreationModel = workspace.PlayerBuilds:FindFirstChild(Player.UserId)
	local Success = false

	if SlotIndex and OriginCFrame and CreationModel and CreationModel:FindFirstChild("CreationFolder") then
		local CreationData = nil

		Success, CreationData = game.ReplicatedStorage.BindableFunctions.GetData:Invoke(Player, "CreationsSlot" .. SlotIndex)

		if Success then
			local DecodedCreationData = CreationData and HTTPService:JSONDecode(CreationData) or {}

			if DecodedCreationData.BlockData and DecodedCreationData.AssemblyData then
				local AssemblyWeldData = {}
				local OrderedPartList = {}
				local OrderedCFrameList = {}

				for _, BlockInfo in DecodedCreationData.BlockData do
					local PickedBlock = BlocksFolder.Placeholder
					local NewBlock = nil
					local WeldGroupParts = {}

					if BlockInfo.ID then
						local IDValue = game.ReplicatedStorage.BlockIDs:FindFirstChild(BlockInfo.ID)

						if IDValue and IDValue.Value then
							local Block = BlocksFolder:FindFirstChild(game.ReplicatedStorage.BlockIDs:FindFirstChild(BlockInfo.ID).Value)

							if Block and Block:FindFirstChild("BlockModel") then
								PickedBlock = Block
							end
						end
					end

					NewBlock = PickedBlock.BlockModel:Clone()
					NewBlock.Parent = CreationModel.CreationFolder
					NewBlock.Name = BlockInfo.ID

					for _, Descendant in NewBlock:GetDescendants() do
						if Descendant:IsA("BasePart") then
							local PartWeldGroup = Descendant:GetAttribute("WeldGroup")

							if PartWeldGroup then
								if not WeldGroupParts[PartWeldGroup] then
									WeldGroupParts[PartWeldGroup] = {}
								end

								table.insert(WeldGroupParts[PartWeldGroup], Descendant)
							end
						end
					end

					if BlockInfo.WG then
						local BlockCFrame = CFrame.new()
						
						for WeldGroup, Parts in WeldGroupParts do
							local WeldGroupInfo = BlockInfo.WG[WeldGroup]
							
							if WeldGroupInfo and WeldGroupInfo.AI then
								local AssemblyInfo = DecodedCreationData.AssemblyData[WeldGroupInfo.AI]

								if AssemblyInfo then
									local APX = AssemblyInfo.PX or 0
									local APY = AssemblyInfo.PY or 0
									local APZ = AssemblyInfo.PZ or 0
									local ARX = AssemblyInfo.RX or 0
									local ARY = AssemblyInfo.RY or 0
									local ARZ = AssemblyInfo.RZ or 0
									local BPX = WeldGroupInfo.PX or 0
									local BPY = WeldGroupInfo.PY or 0
									local BPZ = WeldGroupInfo.PZ or 0
									local BAR = WeldGroupInfo.AR or 0
									local BlockCFrameOffset = CFrame.new(BPX, BPY, BPZ) * UtilityFunctions.FromAxisAngle(UtilityFunctions.AxisRotationToAxisAngle(BAR))
									
									BlockCFrame = OriginCFrame * CFrame.new(APX, APY, APZ) * CFrame.fromOrientation(ARX * math.pi / 2, ARY * math.pi / 2, ARZ * math.pi / 2) * BlockCFrameOffset
									
									if not AssemblyWeldData[WeldGroupInfo.AI] then
										AssemblyWeldData[WeldGroupInfo.AI] = {}
									end

									table.insert(AssemblyWeldData[WeldGroupInfo.AI], {WeldGroup = WeldGroup, Block = NewBlock, BlockTemplate = PickedBlock, BlockCFrameOffset = BlockCFrameOffset})
								end
							end
							
							for _, Part in Parts do
								local PartCFrame = BlockCFrame * NewBlock:GetPivot():Inverse() * Part.CFrame

								table.insert(OrderedPartList, Part)
								table.insert(OrderedCFrameList, PartCFrame)
							end
						end
					end
				end

				workspace:BulkMoveTo(OrderedPartList, OrderedCFrameList, Enum.BulkMoveMode.FireCFrameChanged)
				
				for _, WeldData in AssemblyWeldData do
					local ConnectionOverlapParameters = OverlapParams.new()
					local AssemblyConnectionRoots = {}
					local FilterDescendantsInstances = {}
					
					for _, WeldGroupInfo in WeldData do
						if WeldGroupInfo.BlockTemplate:FindFirstChild("Connections") then
							local WeldGroupRoot = UtilityFunctions.GetBlockWeldRoot(WeldGroupInfo.Block, WeldGroupInfo.WeldGroup)
							local TemplateCenter = UtilityFunctions.GetBlockWeldRootCenter(WeldGroupInfo.BlockTemplate.BlockModel, WeldGroupInfo.WeldGroup)
							
							for _, ConnectionReference in WeldGroupInfo.BlockTemplate.Connections:GetChildren() do
								local ConnectionWeldGroup = ConnectionReference:GetAttribute("WeldGroup")

								if ConnectionWeldGroup == WeldGroupInfo.WeldGroup then
									local ConnectionOffset = TemplateCenter:Inverse() * ConnectionReference.CFrame
									local ConnectionPart = ConnectionReference:Clone()

									ConnectionPart.Parent = workspace.MiscStorage
									ConnectionPart.CFrame = WeldGroupInfo.BlockCFrameOffset * ConnectionOffset
									AssemblyConnectionRoots[ConnectionPart] = WeldGroupRoot
									table.insert(FilterDescendantsInstances, ConnectionPart)
								end
							end
						end
					end
					
					ConnectionOverlapParameters.FilterType = Enum.RaycastFilterType.Include
					ConnectionOverlapParameters.FilterDescendantsInstances = FilterDescendantsInstances
					
					for ConnectionPart, RootPart in AssemblyConnectionRoots do
						local OverlappingConnections = workspace:GetPartsInPart(ConnectionPart, ConnectionOverlapParameters)

						for _, OverlappingConnection in OverlappingConnections do
							if RootPart ~= AssemblyConnectionRoots[OverlappingConnection] then
								local Weld = Instance.new("Weld")

								Weld.Parent = RootPart
								Weld.Part0 = RootPart
								Weld.Part1 = AssemblyConnectionRoots[OverlappingConnection]
								Weld.C0 = RootPart.CFrame:Inverse() * AssemblyConnectionRoots[OverlappingConnection].CFrame
							end
						end

						ConnectionPart:Destroy()
					end
				end
				
				for _, Part in OrderedPartList do
					Part.Anchored = false
					
					if Part:CanSetNetworkOwnership() then
						Part:SetNetworkOwner(Player)
					end
				end
			end

			SetCreationData(Player)
			game.ReplicatedStorage.RemoteEvents.UpdatePlacedBlocks:FireClient(Player)
		else
			game.ReplicatedStorage.RemoteEvents.DisplayNotification:FireClient(Player, "This slot is empty.", "Message", 2)
		end
	end

	return Success
end

function SavePlayerItems(Player, SlotIndex)
	local Plot = PlayerInfo[Player].Team.BuildZone.Value
	local CreationModel = workspace.PlayerBuilds:FindFirstChild(Player.UserId)
	local ItemFolder = workspace.PlayerItems:FindFirstChild(Player.UserId)
	local Success = false
	
	if ItemFolder and CreationModel and SlotIndex and Plot and Plot:FindFirstChild("ItemSaveArea") then
		local OriginCFrame = CreationModel:GetPivot()
		local ItemsOnPlot = {}
		local ItemData = {}
		local EncodedItemData = nil
		local ItemOverlapParameters = OverlapParams.new()
		
		ItemOverlapParameters.FilterType = Enum.RaycastFilterType.Include
		ItemOverlapParameters.FilterDescendantsInstances = {ItemFolder}
		
		for _, AreaPart in Plot.ItemSaveArea:GetChildren() do
			if AreaPart:IsA("BasePart") then
				local Overlapping = workspace:GetPartsInPart(AreaPart, ItemOverlapParameters)
				
				for _, Item in Overlapping do
					local ItemID = Item:GetAttribute("ItemID")
					
					if ItemID then
						ItemsOnPlot[Item] = ItemID
					end
				end
			end
		end
		
		for _, Item in ItemFolder:GetChildren() do
			local ItemID = ItemsOnPlot[Item]
			
			if ItemID then
				local RelativeCFrame = OriginCFrame:Inverse() * Item.CFrame
				local RoundedPX, RoundedPY, RoundedPZ = UtilityFunctions.CleanRoundVector3(RelativeCFrame.Position, GameSettings.ItemPositionIncrement)
				local RoundedRX, RoundedRY, RoundedRZ = UtilityFunctions.CleanRoundVector3(Vector3.new(RelativeCFrame.Rotation:ToOrientation()) * 2 / math.pi, GameSettings.ItemRotationIncrement)
				local ExtraData = ServerFunctions.GetItemExtraData(Item)
				print(ExtraData)

				table.insert(ItemData, {ID = ItemID, PX = RoundedPX, PY = RoundedPY, PZ = RoundedPZ, RX = RoundedRX, RY = RoundedRY, RZ = RoundedRZ, ExtraData = ExtraData})
			else
				Item.Parent = workspace.PlayerItems["0"]
			end
		end
		
		EncodedItemData = HTTPService:JSONEncode(ItemData)
		Success = game.ReplicatedStorage.BindableFunctions.SetData:Invoke(Player, "ItemsSlot" .. SlotIndex, EncodedItemData)
	end

	return Success
end

function LoadPlayerItems(Player, SlotIndex, OriginCFrame)
	local ItemFolder = workspace.PlayerItems:FindFirstChild(Player.UserId)
	local Success = false

	if SlotIndex and OriginCFrame and ItemFolder then
		local ItemData = nil

		Success, ItemData = game.ReplicatedStorage.BindableFunctions.GetData:Invoke(Player, "ItemsSlot" .. SlotIndex)

		if Success then
			local DecodedCreationData = ItemData and HTTPService:JSONDecode(ItemData) or {}

			for _, ItemData in DecodedCreationData do
				if ItemData.ID then
					local Item = ServerFunctions.GenerateItem(ItemData.ID, ItemData.ExtraData)
					local PX = ItemData.PX or 0
					local PY = ItemData.PY or 0
					local PZ = ItemData.PZ or 0
					local RX = ItemData.RX or 0
					local RY = ItemData.RY or 0
					local RZ = ItemData.RZ or 0
					
					if ItemData.ID == "22" then
						ServerFunctions.CheckForUnbox(Item)
					end
					
					Item.Parent = ItemFolder
					Item.CFrame = OriginCFrame * CFrame.new(PX, PY, PZ) * CFrame.fromOrientation(RX * math.pi / 2, RY * math.pi / 2, RZ * math.pi / 2)
				end
			end
		end
	end

	return Success
end

function SaveSlot(Player, SlotIndex)
	if PlayerInfo[Player].CreationLoaded and PlayerInfo[Player].ItemsLoaded then
		local CreationSaveDone = false
		local ItemsSaveDone = false
		local CreationSuccess = false
		local ItemsSuccess = false
		
		task.spawn(function()
			CreationSuccess = SavePlayerCreation(Player, SlotIndex)
			CreationSaveDone = true
		end)
		
		task.spawn(function()
			ItemsSuccess = SavePlayerItems(Player, SlotIndex)
			ItemsSaveDone = true
		end)
		
		while not CreationSaveDone or not ItemsSaveDone do
			task.wait(0.1)
		end
		
		if CreationSuccess and ItemsSuccess then
			print("Slot [", SlotIndex, "] for player [", Player, "] saved.")
		else
			warn("Failed to save slot [", SlotIndex, "] for player [", Player, "].")
		end
	else
		warn("Slot [", SlotIndex, "] for player [", Player, "] is not ready to be saved.")
	end
end

function LoadSlot(Player, SlotIndex)
	local CreationModel = workspace.PlayerBuilds:FindFirstChild(Player.UserId)

	if CreationModel then
		task.spawn(function()
			local CurrencyName = "Currency1"
			local SlotKey = CurrencyName .. "Slot".. SlotIndex
			local Success, Currency = game.ReplicatedStorage.BindableFunctions.GetData:Invoke(Player, SlotKey)
			
			if Success then
				if not Currency or typeof(Currency) ~= "number" then
					Currency = 0
					Success = game.ReplicatedStorage.BindableFunctions.SetData:Invoke(Player, SlotKey, Currency)
				end
				game.ReplicatedStorage.RemoteEvents.UpdateCurrency:FireClient(Player, CurrencyName, Currency)
			end
			
			if not Success then
				Player:Kick("Failed to load your money data. Try joining again.")
			end
		end)
		
		task.spawn(function()
			local SlotKey = "BlockInventorySlot".. SlotIndex
			local Success, BlockInventory = game.ReplicatedStorage.BindableFunctions.GetData:Invoke(Player, SlotKey)

			if Success then
				local ModifiedData = false

				if not BlockInventory or typeof(BlockInventory) ~= "table" then
					BlockInventory = {}
					ModifiedData = true
				end

				for _, IDValue in game.ReplicatedStorage.BlockIDs:GetChildren() do
					if not BlockInventory[IDValue.Name] or typeof(BlockInventory[IDValue.Name]) ~= "table" then
						BlockInventory[IDValue.Name] = {Amount = 0}
						ModifiedData = true
					end
				end

				PlayerInfo[Player].BlockInventory = BlockInventory
				game.ReplicatedStorage.RemoteEvents.UpdateBlockInventory:FireClient(Player, PlayerInfo[Player].BlockInventory)

				if ModifiedData then
					Success = game.ReplicatedStorage.BindableFunctions.SetData:Invoke(Player, SlotKey, BlockInventory)
				end
			end

			if not Success then
				Player:Kick("Failed to load your inventory. Try joining again.")
			end
		end)
		
		task.spawn(function()
			local Success = LoadCreations(Player, SlotIndex, CreationModel:GetPivot())
			
			if Success then
				Success = LoadPlayerItems(Player, SlotIndex, CreationModel:GetPivot())
				
				if PlayerInfo[Player] then
					PlayerInfo[Player].CreationLoaded = true
				end
				
				if Success then
					if PlayerInfo[Player] then
						PlayerInfo[Player].ItemsLoaded = true
					end
				else
					Player:Kick("Failed to load your items. Try joining again.")
				end
			else
				Player:Kick("Failed to load your creation data. Try joining again.")
			end
		end)
	end
end

game.Players.PlayerAdded:Connect(function(Player)
	local CreationModel = Instance.new("Model")
	local CreationFolder = Instance.new("Folder")
	local ItemsFolder = Instance.new("Folder")
	
	PlayerInfo[Player] = {Status = "Building", CurrentSlot = 1, Team = Player.Team, CreationData = nil}
	CreationModel.Parent = workspace.PlayerBuilds
	CreationModel.Name = Player.UserId
	CreationModel.WorldPivot = Player.Team.BuildZone.Value.BuildArea.WorldPivot
	CreationFolder.Parent = CreationModel
	CreationFolder.Name = "CreationFolder"
	ItemsFolder.Name = Player.UserId
	ItemsFolder.Parent = workspace.PlayerItems
	LoadSlot(Player, 1)
end)

game.Players.PlayerRemoving:Connect(function(Player)
	local ItemsFolder = workspace.PlayerItems:FindFirstChild(Player.UserId)
	local CreationModel = workspace.PlayerBuilds:FindFirstChild(Player.UserId)
	
	if ItemsFolder and CreationModel then
		SaveSlot(Player, PlayerInfo[Player].CurrentSlot)
		ItemsFolder:Destroy()
		CreationModel:Destroy()
	end
	
	PlayerInfo[Player] = nil
end)

CollectionService:GetInstanceRemovedSignal("ShopItem"):Connect(ServerFunctions.CheckForUnbox)

for _, SellButton in SellButtons do
	if SellButton:IsA("ClickDetector") then
		SellButton.MouseClick:Connect(function(Player)
			local SellAreaValue = SellButton:FindFirstChild("SellArea")
			local ItemsFolder = workspace.PlayerItems:FindFirstChild(Player.UserId)
			
			if ItemsFolder and SellAreaValue and SellAreaValue.Value then
				local ItemOverlapParams = OverlapParams.new()
				
				ItemOverlapParams.FilterType = Enum.RaycastFilterType.Include
				ItemOverlapParams.FilterDescendantsInstances = {ItemsFolder}
				
				for _, SellPart in SellAreaValue.Value:GetChildren() do
					if SellPart:IsA("BasePart") then
						local InSellPart = workspace:GetPartsInPart(SellPart, ItemOverlapParams)
						local SellTotals = {}
						
						for _, Item in InSellPart do
							local ItemID = Item:GetAttribute("ItemID")
							
							if Item.Parent == ItemsFolder and ItemID then
								local SellInfo = GameSettings.ItemCurrencyValues[ItemID]
								
								if SellInfo and SellInfo.Amount and SellInfo.CurrencyType then
									SellTotals[SellInfo.CurrencyType] = (SellTotals[SellInfo.CurrencyType] or 0) + SellInfo.Amount
									Item:Destroy()
								end
							end
						end
						
						for CurrencyType, SellTotal in SellTotals do
							if SellTotal ~= 0 then
								task.spawn(ServerFunctions.UpdateCurrency, Player, PlayerInfo[Player].CurrentSlot, CurrencyType, SellTotal)
							end
						end
					end
				end
			end
		end)
	end
end

for _, BuyButton in BuyButtons do
	if BuyButton:IsA("ClickDetector") then
		BuyButton.MouseClick:Connect(function(Player)
			local BuyAreaValue = BuyButton:FindFirstChild("BuyArea")
			local ItemsFolder = workspace.PlayerItems:FindFirstChild(Player.UserId)

			if ItemsFolder and BuyAreaValue and BuyAreaValue.Value then
				local ItemOverlapParams = OverlapParams.new()

				ItemOverlapParams.FilterType = Enum.RaycastFilterType.Include
				ItemOverlapParams.FilterDescendantsInstances = {ItemsFolder}

				for _, BuyPart in BuyAreaValue.Value:GetChildren() do
					if BuyPart:IsA("BasePart") then
						local InBuyPart = workspace:GetPartsInPart(BuyPart, ItemOverlapParams)
						local SortedCosts = {}

						for _, Item in InBuyPart do
							local ItemID = Item:GetAttribute("ItemID")

							if Item.Parent == ItemsFolder and ItemID and Item:HasTag("ShopItem") then
								local BuyInfo = nil
								local Markup = 1
								
								if ItemID == "22" and Item:GetAttribute("BoxedBlockID") then
									BuyInfo = GameSettings.BlockCosts[tostring(Item:GetAttribute("BoxedBlockID"))]
								else
									BuyInfo = GameSettings.ItemCurrencyValues[ItemID]
									Markup = GameSettings.ItemCostMarkup
								end

								if BuyInfo and BuyInfo.Amount and BuyInfo.CurrencyType then
									if not SortedCosts[BuyInfo.CurrencyType] then
										SortedCosts[BuyInfo.CurrencyType] = {CostTotal = 0, ItemsToBuy = {}}
									end
									
									SortedCosts[BuyInfo.CurrencyType].CostTotal += BuyInfo.Amount * Markup
									table.insert(SortedCosts[BuyInfo.CurrencyType].ItemsToBuy, {Item = Item, CostAmount = BuyInfo.Amount * Markup})
								end
							end
						end
						
						for CurrencyType, CostInfo in SortedCosts do
							if CostInfo.CostTotal ~= 0 then
								task.spawn(function()
									local Success, CurrencyAmount = game.ReplicatedStorage.BindableFunctions.GetData:Invoke(Player, CurrencyType)
									
									if Success and CurrencyAmount >= CostInfo.CostTotal then
										local UpdatedCostTotal = 0
										
										for _, ItemInfo in CostInfo.ItemsToBuy do
											if ItemInfo.Item.Parent == ItemsFolder and ItemInfo.Item:HasTag("ShopItem") then
												UpdatedCostTotal += ItemInfo.CostAmount
												ItemInfo.Item:RemoveTag("ShopItem")
											end
										end
										
										if UpdatedCostTotal ~= 0 then
											ServerFunctions.UpdateCurrency(Player, PlayerInfo[Player].CurrentSlot, CurrencyType, -UpdatedCostTotal)
										end
									end
								end)
							end
						end
					end
				end
			end
		end)
	end
end

for _, TemplateBlock in BlocksFolder:GetChildren() do
	local WeldGroupRootFolder = Instance.new("Folder")
	local BlockRoot = nil
	local WeldableParts = {}
	local WeldGroupRoots = {}
	local UnionParts = {}
	local ConnectionParts = {}
	
	WeldGroupRootFolder.Parent = TemplateBlock
	WeldGroupRootFolder.Name = "WeldGroupRoots"

	for _, Connection in TemplateBlock.Connections:GetChildren() do
		if Connection:IsA("BasePart") then
			local WeldGroup = Connection:GetAttribute("WeldGroup")
			
			if typeof(WeldGroup) ~= "number" then
				WeldGroup = tonumber(WeldGroup) or 1
				Connection:SetAttribute("WeldGroup", WeldGroup)
			end

			if WeldGroup then
				if not ConnectionParts[WeldGroup] then
					ConnectionParts[WeldGroup] = {}
				end

				table.insert(ConnectionParts[WeldGroup], Connection)
			end
		end
	end

	for _, Descendant in TemplateBlock.BlockModel:GetDescendants() do
		if Descendant:IsA("BasePart") then
			local WeldGroup = Descendant:GetAttribute("WeldGroup")
			
			if typeof(WeldGroup) ~= "number" then
				WeldGroup = tonumber(WeldGroup) or 1
				Descendant:SetAttribute("WeldGroup", WeldGroup)
			end
			
			if not BlockRoot or (BlockRoot and WeldGroup < BlockRoot:GetAttribute("WeldGroup")) then
				BlockRoot = Descendant
			end

			if WeldGroup then
				table.insert(WeldableParts, Descendant)

				if not ConnectionParts[WeldGroup] then
					Descendant:AddTag("HasNoConnections")
				end

				if not WeldGroupRoots[WeldGroup] or (WeldGroupRoots[WeldGroup] and Descendant.Mass > WeldGroupRoots[WeldGroup].Mass) then
					WeldGroupRoots[WeldGroup] = Descendant
				end

				if (Descendant.CanCollide or Descendant.CanQuery) and not Descendant:IsA("MeshPart") and not Descendant:IsA("TrussPart") then
					if not UnionParts[WeldGroup] then
						UnionParts[WeldGroup] = {Parts = {}, Root = WeldGroupRoots[WeldGroup]}
					end

					table.insert(UnionParts[WeldGroup].Parts, Descendant)
				end
			end
		end
	end

	for WeldGroup, WeldGroupRoot in WeldGroupRoots do
		local RootValue = Instance.new("ObjectValue")
		
		if ConnectionParts[WeldGroup] then
			WeldGroupRoot:AddTag("HasConnections")
		end
		
		RootValue.Parent = WeldGroupRootFolder
		RootValue.Name = WeldGroup
		RootValue.Value = WeldGroupRoot
		WeldGroupRoot:AddTag("WeldGroupRoot")
		WeldGroupRoot.RootPriority = 127
	end

	for _, Part in WeldableParts do
		local WeldRoot = WeldGroupRoots[Part:GetAttribute("WeldGroup")]

		if Part ~= WeldRoot then
			local Weld = Instance.new("Weld")

			Weld.Parent = WeldRoot
			Weld.Part0 = WeldRoot
			Weld.Part1 = Part
			Weld.C0 = WeldRoot.CFrame:Inverse() * Part.CFrame
		end
	end

	if BlockRoot then
		local BlockUnionFolder = Instance.new("Folder")

		BlockRoot.PivotOffset =BlockRoot.CFrame:Inverse() * TemplateBlock.BlockModel:GetPivot()
		TemplateBlock.BlockModel.PrimaryPart = BlockRoot
		BlockUnionFolder.Parent = TemplateBlock
		BlockUnionFolder.Name = "BlockUnions"

		task.spawn(function()
			for WeldGroup, UnionWeldGroup in UnionParts do
				local UnionOptions = {CollisionFidelity = Enum.CollisionFidelity.Hull, RenderFidelity = Enum.RenderFidelity.Performance, FluidFidelity = Enum.FluidFidelity.UseCollisionGeometry, SplitApart = false}
				local Union = GeometryService:UnionAsync(UnionWeldGroup.Root, UnionWeldGroup.Parts, UnionOptions)[1]

				Union.Parent = BlockUnionFolder
				Union.Name = WeldGroup
				Union.PivotOffset = Union.CFrame:Inverse() * TemplateBlock.BlockModel:GetPivot()
				Union.Transparency = 0
				Union.CanCollide = false
				Union.CanQuery = true
				Union.CanTouch = false
				Union.Material = Enum.Material.SmoothPlastic
			end
		end)
	end
end

for _, BlockID in game.ReplicatedStorage.BlockIDs:GetChildren() do
	local BlockDisplay = game.ReplicatedStorage.GuiElements.BlockViewport:Clone()
	local Block = nil
	
	if not BlockID.Value or not BlocksFolder:FindFirstChild(BlockID.Value) then
		BlockID.Value = "Placeholder"
	end
	
	BlockDisplay.Parent = BlockID
	BlockDisplay.Name = "BlockDisplay"
	Block = game.ReplicatedStorage.Blocks:FindFirstChild(BlockID.Value)

	if Block then
		local Dimensions = Block:GetAttribute("BlockDimensions")
		local BlockClone = Block.BlockModel:Clone()

		BlockClone.Parent = BlockDisplay
		BlockClone:PivotTo(CFrame.new())
		BlockClone:ScaleTo(0.4 + 1.2 / math.max(Dimensions.X, Dimensions.Y, Dimensions.Z))
	end
end

for _, ItemID in game.ReplicatedStorage.ItemIDs:GetChildren() do
	local ItemFolder = game.ReplicatedStorage:WaitForChild("Items")
	local ItemClone = nil
	
	if not ItemID.Value or not ItemFolder:FindFirstChild(ItemID.Value) then
		ItemClone = ItemFolder.Placeholder:Clone()
	else
		ItemClone = ItemFolder:FindFirstChild(ItemID.Value):Clone()
	end
	
	ItemClone.Parent = ItemID
	ItemClone.Name = "Item"
	ItemClone:SetAttribute("ItemID", ItemID.Name)
end