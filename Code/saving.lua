function CompileCreationFolder(Folder, OriginCFrame)
	if Folder and OriginCFrame then
		local Assemblies = {}
		local CreationData = {BlockData = {}, AssemblyData = {}}

		for _, Block in Folder:GetChildren() do
			local IDValue = game.ReplicatedStorage.InventoryIDs:FindFirstChild(Block.Name)

			if IDValue and IDValue.Value and BlocksFolder:FindFirstChild(IDValue.Value) then
				local BlockInfo = {ID = Block.Name, WG = {}}

				for _, BasePart in Block:GetChildren() do
					if BasePart:IsA("BasePart") and BasePart:HasTag("WeldGroupRoot") then
						local WeldGroup = BasePart:GetAttribute("WeldGroup")

						if WeldGroup and IDValue.WeldGroupRoots and IDValue.WeldGroupRoots:FindFirstChild(WeldGroup) then
							local BlockDimensions = BlocksFolder:FindFirstChild(game.ReplicatedStorage.InventoryIDs:FindFirstChild(Block.Name).Value):GetAttribute("BlockDimensions")
							local BlockCFrame = nil
							local RoundedBRX, RoundedBRY, RoundedBRZ = nil
							local BlockBounds = nil
							local BlockRoundOffset = nil
							local RoundedBPX, RoundedBPY, RoundedBPZ = nil
							local RelativeCFrame = OriginCFrame:Inverse() * MainFunctions.GetBlockWeldRootCenter(Block, WeldGroup)

							if not Assemblies[BasePart.AssemblyRootPart] then
								local AssemblyRoundOffset = Vector3.new((BlockDimensions.X / 2) % BlockPositionIncrement, (BlockDimensions.Y / 2) % BlockPositionIncrement, (BlockDimensions.Z / 2) % BlockPositionIncrement)
								local RoundedARX, RoundedARY, RoundedARZ = MainFunctions.CleanRoundVector3(Vector3.new(RelativeCFrame:ToOrientation()) * math.deg(1), AssemblyRotationIncrement)
								local RoundedAPX, RoundedAPY, RoundedAPZ = MainFunctions.CleanRoundVector3(RelativeCFrame.Position, AssemblyPositionIncrement)

								table.insert(CreationData.AssemblyData, {PX = RoundedAPX, PY = RoundedAPY, PZ = RoundedAPZ, RX = RoundedARX, RY = RoundedARY, RZ = RoundedARZ})
								Assemblies[BasePart.AssemblyRootPart] = {AssemblyIndex = #CreationData.AssemblyData, AssemblyCFrame = RelativeCFrame, AssemblyRoundOffset = AssemblyRoundOffset}
							end

							BlockCFrame = Assemblies[BasePart.AssemblyRootPart].AssemblyCFrame:Inverse() * RelativeCFrame
							RoundedBRX, RoundedBRY, RoundedBRZ = MainFunctions.CleanRoundVector3(Vector3.new(BlockCFrame:ToOrientation()) * math.deg(1), BlockRotationIncrement)
							BlockBounds = (CFrame.fromOrientation(math.rad(RoundedBRX), math.rad(RoundedBRY), math.rad(RoundedBRZ)) * CFrame.new(BlockDimensions)).Position:Abs()
							BlockRoundOffset = Vector3.new((BlockBounds.X / 2) % BlockPositionIncrement, (BlockBounds.Y / 2) % BlockPositionIncrement, (BlockBounds.Z / 2) % BlockPositionIncrement)
							RoundedBPX, RoundedBPY, RoundedBPZ = MainFunctions.CleanRoundVector3(BlockCFrame.Position, BlockPositionIncrement, BlockRoundOffset - Assemblies[BasePart.AssemblyRootPart].AssemblyRoundOffset)

							BlockInfo.WG[WeldGroup] = {PX = RoundedBPX, PY = RoundedBPY, PZ = RoundedBPZ, RX = RoundedBRX, RY = RoundedBRY, RZ = RoundedBRZ, AI = Assemblies[BasePart.AssemblyRootPart].AssemblyIndex}
						end
					end
				end

				table.insert(CreationData.BlockData, BlockInfo)
			end
		end

		return CreationData
	end
end

function SetCreationData(Player)
	local CreationModel = workspace.PlayerBuilds:FindFirstChild(Player.Name)
	
	if CreationModel and CreationModel.CreationFolder then
		local CreationData = {BlockData = {}, AssemblyData = {}, BlockMarkers = {}, AssemblyMarkers = {}}

		for _, Block in CreationModel.CreationFolder:GetChildren() do
			local BlockInfo = {Block = Block, WeldGroups = {}}

			for _, BasePart in Block:GetChildren() do
				if BasePart:IsA("BasePart") and BasePart:HasTag("WeldGroupRoot") then
					local WeldGroup = BasePart:GetAttribute("WeldGroup")

					if WeldGroup then
						local BlockDimensions = BlocksFolder:FindFirstChild(game.ReplicatedStorage.InventoryIDs:FindFirstChild(Block.Name).Value):GetAttribute("BlockDimensions")
						local BlockCFrame = nil
						local RoundedBRX, RoundedBRY, RoundedBRZ = nil
						local BlockBounds = nil
						local BlockRoundOffset = nil
						local RoundedBPX, RoundedBPY, RoundedBPZ = nil
						local RelativeCFrame = MainFunctions.GetBlockWeldRootCenter(Block, WeldGroup)
						local RoundedCFrame = nil
						local WeldGroupInfo = nil
						local AssemblyData = CreationData.AssemblyMarkers[BasePart.AssemblyRootPart]

						if not AssemblyData then
							local AssemblyRoundOffset = Vector3.new((BlockDimensions.X / 2) % BlockPositionIncrement, (BlockDimensions.Y / 2) % BlockPositionIncrement, (BlockDimensions.Z / 2) % BlockPositionIncrement)
							
							AssemblyData = {MainPart = BasePart, AssemblyRoundOffset = AssemblyRoundOffset, AssemblyCFrameOffset = MainFunctions.GetBlockWeldRootOffset(Block, WeldGroup), BlockWeldGroups = {}}
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

			table.insert(CreationData.BlockData, BlockInfo)
			CreationData.BlockMarkers[Block] = BlockInfo
		end
		
		PlayerInfo[Player].CreationData = CreationData
	end
end

function SaveCreations(Player, SlotIndex)
	local CreationModel = workspace.PlayerBuilds:FindFirstChild(Player.Name)
	local Success = false

	if SlotIndex and CreationModel and CreationModel:FindFirstChild("CreationFolder") then
		local EncodedCreationData = HTTPService:JSONEncode(CompileCreationFolder(CreationModel.CreationFolder, CreationModel:GetPivot()))

		Success = game.ReplicatedStorage.BindableFunctions.SetData:Invoke(Player, "CreationsSlot" .. SlotIndex, EncodedCreationData)
	end

	return Success
end

function LoadCreations(Player, SlotIndex, OriginCFrame)
	local CreationModel = workspace.PlayerBuilds:FindFirstChild(Player.Name)
	local Success = false

	if SlotIndex and OriginCFrame and CreationModel and CreationModel:FindFirstChild("CreationFolder") then
		local CreationData = nil

		Success, CreationData = game.ReplicatedStorage.BindableFunctions.GetData:Invoke(Player, "CreationsSlot" .. SlotIndex)

		if Success then
			local DecodedCreationData = CreationData and HTTPService:JSONDecode(CreationData) or {}

			if DecodedCreationData.BlockData and DecodedCreationData.AssemblyData then
				local OrderedPartList = {}
				local OrderedCFrameList = {}

				for _, BlockInfo in DecodedCreationData.BlockData do
					local PickedBlock = BlocksFolder.Placeholder
					local NewBlock = nil
					local WeldGroupParts = {}

					if BlockInfo.ID then
						local IDValue = game.ReplicatedStorage.InventoryIDs:FindFirstChild(BlockInfo.ID)

						if IDValue.Value then
							local Block = BlocksFolder:FindFirstChild(game.ReplicatedStorage.InventoryIDs:FindFirstChild(BlockInfo.ID).Value)

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
						for WeldGroup, WeldGroupInfo in BlockInfo.WG do
							if WeldGroupInfo.AI then 
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
									local BRX = WeldGroupInfo.RX or 0
									local BRY = WeldGroupInfo.RY or 0
									local BRZ = WeldGroupInfo.RZ or 0

									for _, WeldGroupPart in WeldGroupParts[WeldGroup] do
										local NewCFrame = OriginCFrame * CFrame.new(APX, APY, APZ) * CFrame.fromEulerAnglesYXZ(math.rad(ARX), math.rad(ARY), math.rad(ARZ)) * CFrame.new(BPX, BPY, BPZ) * CFrame.fromEulerAnglesYXZ(math.rad(BRX), math.rad(BRY), math.rad(BRZ)) * NewBlock:GetPivot():Inverse() * WeldGroupPart.CFrame

										table.insert(OrderedPartList, WeldGroupPart)
										table.insert(OrderedCFrameList, NewCFrame)
									end
								end
							end
						end
					end
				end

				workspace:BulkMoveTo(OrderedPartList, OrderedCFrameList, Enum.BulkMoveMode.FireCFrameChanged)
			end

			task.wait(5)
			Setup(Player, CreationModel.CreationFolder)
			SetCreationData(Player)
			game.ReplicatedStorage.RemoteEvents.UpdatePlacedBlocks:FireClient(Player)
		else
			game.ReplicatedStorage.RemoteEvents.DisplayNotification:FireClient(Player, "This slot is empty.", "Message", 2)
		end
	end

	return Success
end

function SaveSlot(Player, SlotIndex)
	task.spawn(function()
		SavePlayerItems(Player, SlotIndex)
	end)

	task.spawn(function()
		SaveCreations(Player, SlotIndex)
	end)
end

function LoadSlot(Player, SlotIndex)
	local CreationModel = workspace.PlayerBuilds:FindFirstChild(Player.Name)

	if CreationModel then
		task.spawn(function()
			local SlotKey = "CurrencySlot"..SlotIndex
			local Success, Currency = game.ReplicatedStorage.BindableFunctions.GetData:Invoke(Player, SlotKey)
			if Success then
				if not Currency or typeof(Currency) ~= "number" then
					Currency = 0
					Success = game.ReplicatedStorage.BindableFunctions.SetData:Invoke(Player, SlotKey, Currency)
				end

				game.ReplicatedStorage.RemoteEvents.UpdateCurrency:FireClient(Player, SlotKey, Currency)
			end
			if not Success then
				Player:Kick("Failed to load your money. Try joining again.")
			end
		end)
		task.spawn(function()
			local Success, BlockCollection = game.ReplicatedStorage.BindableFunctions.GetData:Invoke(Player, "BlockCollectionSlot"..SlotIndex)
			if Success then
				local ModifiedData = false
				if not BlockCollection or typeof(BlockCollection) ~= "table" then
					BlockCollection = {}
					ModifiedData = true
				end
				for _, IDValue in InvIds:GetChildren() do
					if not BlockCollection[IDValue.Name] or typeof(BlockCollection[IDValue.Name]) ~= "boolean" then
						BlockCollection[IDValue.Name] = false
						ModifiedData = true
					end
				end
				if ModifiedData then
					Success = game.ReplicatedStorage.BindableFunctions.SetData:Invoke(Player, "BlockCollectionSlot"..SlotIndex, BlockCollection)
				end
				game.ReplicatedStorage.RemoteEvents.UpdateBlockCollection:FireClient(Player, BlockCollection)
			end
			if not Success then
				Player:Kick("Failed to load your BlockCollection. Try joining again.")
			end
		end)
		task.spawn(function()
			local Success = LoadCreations(Player, SlotIndex, CreationModel:GetPivot())

			if not Success then
				warn("Failed to load your creations. Try joining again.")
			end
		end)

		LoadPlayerItems(Player,SlotIndex)
	end
end

game.Players.PlayerAdded:Connect(function(Player)
	local CreationModel = Instance.new("Model")
	local CreationFolder = Instance.new("Folder")
	PlayerInfo[Player] = {Status = "Building", CreationData = nil}
	CreationModel.Parent = workspace.PlayerBuilds
	CreationModel.Name = Player.Name
	CreationModel.WorldPivot = Player.Team.BuildZone.Value.BuildArea.WorldPivot
	CreationFolder.Parent = CreationModel
	CreationFolder.Name = "CreationFolder"

	local CreationModel2 = Instance.new("Model")
	local CreationFolder2 = Instance.new("Folder")
	CreationModel2.Parent = game.ReplicatedStorage.PlayerBuilds
	CreationModel2.Name = Player.Name
	CreationModel2.WorldPivot = Player.Team.BuildZone.Value.BuildArea.WorldPivot
	CreationFolder2.Parent = CreationModel2
	CreationFolder2.Name = "CreationFolder"

	local FolderItems = Instance.new("Folder")
	FolderItems.Name = Player.Name
	FolderItems.Parent = workspace.PlayerFoldersItems
	LoadSlot(Player, 1)
end)

game.Players.PlayerRemoving:Connect(function(Player)
	if workspace.PlayerFoldersItems:FindFirstChild(Player.Name) and workspace.PlayerBuilds:FindFirstChild(Player.Name) then
		SaveSlot(Player,1)
		workspace.PlayerFoldersItems:FindFirstChild(Player.Name):Destroy()
	end
	local CreationModel = workspace.PlayerBuilds:FindFirstChild(Player.Name)
	if CreationModel then
		CreationModel:Destroy()
	end
	local CreationModel2 = game.ReplicatedStorage.PlayerBuilds:FindFirstChild(Player.Name)
	if CreationModel2 then
		CreationModel2:Destroy()
	end
	PlayerInfo[Player] = nil
end)