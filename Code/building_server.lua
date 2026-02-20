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
	local CreationModel = workspace.PlayerBuilds:FindFirstChild(Player.Name)
	
	if OnBlock and OnWeldGroup and WeldBlock and CreationModel then
		local OnAssemblyRootPart = MainFunctions.GetBlockWeldRoot(OnBlock, OnWeldGroup).AssemblyRootPart
		
		if OnAssemblyRootPart then
			local OnAssembly = PlayerInfo[Player].CreationData.AssemblyMarkers[OnAssemblyRootPart]

			if OnAssembly then
				local AssemblyCenterCFrame = OnAssembly.MainPart.CFrame * OnAssembly.AssemblyCFrameOffset
				local WeldBlockCFrame = MainFunctions.GetBlockWeldRootCenter(OnBlock, OnWeldGroup) * CFrameOn
				local WeldBlockValue = game.ReplicatedStorage.InventoryIDs:FindFirstChild(WeldBlock.Name)
				local ConnectionOverlapParameters = OverlapParams.new()
				local FilteredParts = {}
				local WeldBlockConnections = {}
				local AssemblyConnectionRoots = {}

				if WeldBlockValue and WeldBlockValue.Value then
					local StoredBlock = BlocksFolder:FindFirstChild(WeldBlockValue.Value)

					if StoredBlock and StoredBlock:FindFirstChild("BlockModel") and StoredBlock:FindFirstChild("Connections") then
						for _, ConnectionReference in StoredBlock.Connections:GetChildren() do
							local ConnectionWeldGroup = ConnectionReference:GetAttribute("WeldGroup")
							local WeldGroupAssemblyOffset = AssemblyCenterCFrame:Inverse() * WeldBlockCFrame
							local ConnectionOffset = MainFunctions.GetBlockWeldRootCenter(StoredBlock, ConnectionWeldGroup):Inverse() * ConnectionReference.CFrame
							local ConnectionCFrame = WeldGroupAssemblyOffset * ConnectionOffset
							local ConnectionPart = ConnectionReference:Clone()

							ConnectionPart.Parent = workspace.MiscStorage
							ConnectionPart.CFrame = ConnectionCFrame
							WeldBlockConnections[ConnectionPart] = ConnectionWeldGroup
						end
					end
				end
				
				for _, BlockWeldGroupInfo in OnAssembly.BlockWeldGroups do
					local Block = BlockWeldGroupInfo.BlockInfo.Block
					local BlockValue = game.ReplicatedStorage.InventoryIDs:FindFirstChild(Block.Name)

					if BlockValue and BlockValue.Value then
						local StoredBlock = BlocksFolder:FindFirstChild(BlockValue.Value)

						if StoredBlock and StoredBlock:FindFirstChild("BlockModel") and StoredBlock:FindFirstChild("Connections") then
							local WeldGroup = BlockWeldGroupInfo.WeldGroup
							local BlockRoot = MainFunctions.GetBlockWeldRoot(Block, WeldGroup)

							for _, ConnectionReference in StoredBlock.Connections:GetChildren() do
								local ConnectionWeldGroup = ConnectionReference:GetAttribute("WeldGroup")

								if ConnectionWeldGroup == WeldGroup then
									local WeldGroupAssemblyOffset = AssemblyCenterCFrame:Inverse() * MainFunctions.GetBlockWeldRootCenter(Block, WeldGroup)
									local ConnectionOffset = MainFunctions.GetBlockWeldRootCenter(StoredBlock, ConnectionWeldGroup):Inverse() * ConnectionReference.CFrame
									local ConnectionCFrame = WeldGroupAssemblyOffset * ConnectionOffset
									local ConnectionPart = ConnectionReference:Clone()

									ConnectionPart.Parent = workspace.MiscStorage
									ConnectionPart.CFrame = ConnectionCFrame
									AssemblyConnectionRoots[ConnectionPart] = BlockRoot
									table.insert(FilteredParts, ConnectionPart)
								end
							end
						end
					end
				end

				ConnectionOverlapParameters.FilterType = Enum.RaycastFilterType.Include
				ConnectionOverlapParameters.FilterDescendantsInstances = FilteredParts

				for Connection, WeldGroup in WeldBlockConnections do
					local OverlappingConnections = workspace:GetPartsInPart(Connection, ConnectionOverlapParameters)

					for _, OverlappingConnection in OverlappingConnections do
						local RootPart = MainFunctions.GetBlockWeldRoot(WeldBlock, WeldGroup)
						local RootPartOffset = MainFunctions.GetBlockWeldRootOffset(WeldBlock, WeldGroup)
						local WeldBlockAssemblyCFrame = AssemblyCenterCFrame:Inverse() * WeldBlockCFrame
						local WeldToAssemblyCFrame = AssemblyCenterCFrame:Inverse() * AssemblyConnectionRoots[OverlappingConnection].CFrame
						local WeldBlockAssemblyPosition = Vector3.new(MainFunctions.CleanRoundVector3(WeldBlockAssemblyCFrame.Position, BlockPositionIncrement / 2))
						local WeldBlockAssemblyRotation = CFrame.fromOrientation(MainFunctions.RoundVector3(Vector3.new(WeldBlockAssemblyCFrame.Rotation:ToOrientation()), math.rad(BlockRotationIncrement)))
						local Weld = Instance.new("Weld")

						Weld.Parent = RootPart
						Weld.Part0 = RootPart
						Weld.Part1 = AssemblyConnectionRoots[OverlappingConnection]
						Weld.C0 = (CFrame.new(WeldBlockAssemblyPosition) * WeldBlockAssemblyRotation * RootPartOffset:Inverse()):Inverse() * WeldToAssemblyCFrame
					end

					Connection:Destroy()
				end

				for Connection, RootPart in AssemblyConnectionRoots do
					Connection:Destroy()
				end
				
				UpdateAssemblyRootParts(PlayerInfo[Player].CreationData)
			end
		end
	end
end

function PlaceBlock(Player, BlockID, BlockCFrame, OnBlock, OnWeldGroup)
	local CreationModel = workspace.PlayerBuilds:FindFirstChild(Player.Name)
	
	if CreationModel and PlayerInfo[Player].Status == "Building" and InvIds:FindFirstChild(BlockID) and InvIds:FindFirstChild(BlockID).Value then
		local Block = BlocksFolder:FindFirstChild(InvIds:FindFirstChild(BlockID).Value)
		local CreationData = PlayerInfo[Player].CreationData

		if Block and CreationData then
			local BlockPosition = Vector3.new(MainFunctions.CleanRoundVector3(BlockCFrame.Position, BlockPositionIncrement / 2))
			local BlockRotation = CFrame.fromOrientation(MainFunctions.RoundVector3(Vector3.new(BlockCFrame.Rotation:ToOrientation()), math.rad(BlockRotationIncrement)))
			local BlockClone = Block.BlockModel:Clone()
			local BlockInfo = {Block = BlockClone, WeldGroups = {}}
			
			BlockCFrame = CFrame.new(BlockPosition) * BlockRotation
			BlockClone.Parent = CreationModel.CreationFolder	
			BlockClone.Name = BlockID
			table.insert(CreationData.BlockData, BlockInfo)
			CreationData.BlockMarkers[BlockClone] = BlockInfo

			if OnBlock and OnWeldGroup then
				BlockClone:PivotTo(MainFunctions.GetBlockWeldRootCenter(OnBlock, OnWeldGroup) * BlockCFrame)
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
						local BlockDimensions = MainFunctions.GetBlockDimensions(BlockClone)
						local BlockCFrame = nil
						local RoundedBRX, RoundedBRY, RoundedBRZ = nil
						local BlockBounds = nil
						local BlockRoundOffset = nil
						local RoundedBPX, RoundedBPY, RoundedBPZ = nil
						local RelativeCFrame = MainFunctions.GetBlockWeldRootCenter(BlockClone, WeldGroup)
						local RoundedCFrame = nil
						local WeldGroupInfo = nil
						local AssemblyData = CreationData.AssemblyMarkers[BasePart.AssemblyRootPart]

						if not AssemblyData then
							local AssemblyRoundOffset = Vector3.new((BlockDimensions.X / 2) % BlockPositionIncrement, (BlockDimensions.Y / 2) % BlockPositionIncrement, (BlockDimensions.Z / 2) % BlockPositionIncrement)

							AssemblyData = {MainPart = BasePart, AssemblyRoundOffset = AssemblyRoundOffset, AssemblyCFrameOffset = MainFunctions.GetBlockWeldRootOffset(BlockClone, WeldGroup), BlockWeldGroups = {}}
							table.insert(CreationData.AssemblyData, AssemblyData)
							CreationData.AssemblyMarkers[BasePart.AssemblyRootPart] = AssemblyData
						end

						BlockCFrame = (AssemblyData.MainPart.CFrame * AssemblyData.AssemblyCFrameOffset):Inverse() * RelativeCFrame
						RoundedBRX, RoundedBRY, RoundedBRZ = MainFunctions.CleanRoundVector3(Vector3.new(BlockCFrame:ToOrientation()) * math.deg(1), BlockRotationIncrement)
						BlockBounds = (CFrame.fromOrientation(math.rad(RoundedBRX), math.rad(RoundedBRY), math.rad(RoundedBRZ)) * CFrame.new(BlockDimensions)).Position:Abs()
						BlockRoundOffset = Vector3.new((BlockBounds.X / 2) % BlockPositionIncrement, (BlockBounds.Y / 2) % BlockPositionIncrement, (BlockBounds.Z / 2) % BlockPositionIncrement)
						RoundedBPX, RoundedBPY, RoundedBPZ = MainFunctions. RoundVector3(BlockCFrame.Position, BlockPositionIncrement, BlockRoundOffset - AssemblyData.AssemblyRoundOffset)
						RoundedCFrame = CFrame.new(RoundedBPX, RoundedBPY, RoundedBPZ) * CFrame.fromOrientation(math.rad(RoundedBRX), math.rad(RoundedBRY), math.rad(RoundedBRZ))
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
				local AssemblyRootPart = MainFunctions.GetBlockWeldRoot(BlockWeldGroup.BlockInfo.Block, BlockWeldGroup.WeldGroup).AssemblyRootPart
				
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
					local MainBlockDimensions = MainFunctions.GetBlockDimensions(MainBlockInfo.Block)
					local NewMainPart = MainFunctions.GetBlockWeldRoot(MainBlockInfo.Block, MainPartWeldGroup)
					local NewAssemblyRoundOffset = Vector3.new((MainBlockDimensions.X / 2) % BlockPositionIncrement, (MainBlockDimensions.Y / 2) % BlockPositionIncrement, (MainBlockDimensions.Z / 2) % BlockPositionIncrement)
					
					NewAssemblyData.AssemblyCFrameOffset = MainFunctions.GetBlockWeldRootOffset(MainBlockInfo.Block, MainPartWeldGroup) * MainWeldGroupRelativeCFrame:Inverse()
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