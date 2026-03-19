local ServerFunctions = {}

local GameSettings = require(game.ReplicatedStorage.GameSettings)

function ServerFunctions.UpdateCurrency(Player: Player, Slot: number, CurrencyType: string, Increment: number): boolean
	local Success = false
	local NewCurrencyAmount = nil
	
	local UpdateFunction = function(CurrentAmount)
		CurrentAmount = CurrentAmount or 0
		
		if typeof(CurrentAmount) == "number" then
			return CurrentAmount + Increment
		end
	end
	
	Success, NewCurrencyAmount = game.ReplicatedStorage.BindableFunctions.UpdateData:Invoke(Player, CurrencyType .. "Slot" .. Slot, UpdateFunction)
	
	if Success then
		game.ReplicatedStorage.RemoteEvents.UpdateCurrency:FireClient(Player, CurrencyType, NewCurrencyAmount)
	else
		warn("Failed to increment currency [" .. CurrencyType .. "] by [" .. Increment .. "] for player [" .. Player.Name .. "]")
	end
	
	return Success
end

function ServerFunctions.UpdateBlockInventory(Player: Player, Slot: number, IncrementedBlocks): boolean
	local Success = false
	
	if IncrementedBlocks and next(IncrementedBlocks) then
		local NewBlockInventory = nil

		local UpdateFunction = function(BlockInventory)
			BlockInventory = BlockInventory or {}

			for BlockID, Increment in IncrementedBlocks do
				local BlockData = BlockInventory[BlockID] or {Amount = 0}
				
				BlockData.Amount = (typeof(BlockData.Amount) == "number" and BlockData.Amount or 0) + Increment
			end
			
			return BlockInventory
		end

		Success, NewBlockInventory = game.ReplicatedStorage.BindableFunctions.UpdateData:Invoke(Player, "BlockInventory" .. "Slot" .. Slot, UpdateFunction)

		if Success then
			game.ReplicatedStorage.RemoteEvents.UpdateBlockInventory:FireClient(Player, NewBlockInventory)
		else
			warn("Failed to update block inventory for player [" .. Player.Name .. "]")
		end
	end

	return Success
end

function ServerFunctions.GetItemExtraData(Item: Instance)
	local ExtraData = {}
	local ItemID = Item:GetAttribute("ItemID")
	
	if ItemID == "22" then
		local BoxedBlockID = Item:GetAttribute("BoxedBlockID")
		
		if BoxedBlockID then
			ExtraData["BoxedBlockID"] = BoxedBlockID
		end
	end
	
	return next(ExtraData) and ExtraData or nil
end

function ServerFunctions.GenerateItem(ItemID: string, ExtraData): Instance
	local IDValue = game.ReplicatedStorage.ItemIDs:FindFirstChild(ItemID)
	local ItemTemplate = IDValue and IDValue:WaitForChild("Item")
	local ItemClone = nil

	if ItemTemplate then
		ItemClone = ItemTemplate:Clone()
	else
		ItemClone = game.ReplicatedStorage:WaitForChild("Items").Placeholder:Clone()
		ItemClone:SetAttribute("ItemID", ItemID)
	end

	if ItemID == "22" then
		local BoxedBlockID = ExtraData and ExtraData["BoxedBlockID"] and tostring(ExtraData["BoxedBlockID"]) or "1"
		local BoxedBlockName = game.ReplicatedStorage.BlockIDs:FindFirstChild(BoxedBlockID).Value
		local Cost = GameSettings.BlockCosts[BoxedBlockID] and GameSettings.BlockCosts[BoxedBlockID].Amount or 0

		ItemClone:SetAttribute("BoxedBlockID", BoxedBlockID)
		ItemClone.SurfaceGui1.NameLabel.Text = BoxedBlockName
		ItemClone.SurfaceGui2.NameLabel.Text = BoxedBlockName
		ItemClone.SurfaceGui3.NameLabel.Text = BoxedBlockName
		ItemClone.SurfaceGui4.NameLabel.Text = BoxedBlockName
		ItemClone.SurfaceGui1.CostLabel.Text = Cost .. " ඞ"
		ItemClone.SurfaceGui2.CostLabel.Text = Cost .. " ඞ"
		ItemClone.SurfaceGui3.CostLabel.Text = Cost .. " ඞ"
		ItemClone.SurfaceGui4.CostLabel.Text = Cost .. " ඞ"
	end
	
	ItemClone.Anchored = false
	
	return ItemClone
end

function ServerFunctions.CheckForUnbox(Item: Instance)
	if Item:IsA("BasePart") and Item:GetAttribute("ItemID") == "22" and not Item:HasTag("ShopItem") and not Item:FindFirstChild("UnboxPrompt") then
		local BoxedBlockID = Item:GetAttribute("BoxedBlockID")

		if BoxedBlockID then
			local BoxedBlockIDValue = game.ReplicatedStorage.BlockIDs:FindFirstChild(BoxedBlockID)

			if BoxedBlockIDValue then
				local UnboxPrompt = Instance.new("ProximityPrompt")
				local Unboxing = false

				UnboxPrompt.Parent = Item
				UnboxPrompt.Name = "UnboxPrompt"
				UnboxPrompt.ActionText = "Unbox"
				UnboxPrompt.ObjectText = BoxedBlockIDValue.Value
				UnboxPrompt.HoldDuration = 1
				UnboxPrompt.KeyboardKeyCode = Enum.KeyCode.F
				UnboxPrompt.ClickablePrompt = false
				UnboxPrompt.MaxActivationDistance = 6
				
				UnboxPrompt.Triggered:Connect(function(Player)
					local ItemsFolder = workspace.PlayerItems:FindFirstChild(Player.UserId)
					
					if not Unboxing and ItemsFolder and Item.Parent == ItemsFolder then
						local Success = nil
						
						Unboxing = true
						Success = ServerFunctions.UpdateBlockInventory(Player, 1, {[BoxedBlockID] = 1})
						
						if Success then
							Item:Destroy()
						else
							Unboxing = false
						end
					end
				end)
			end
		end
	end
end

function ServerFunctions.Harvest(Player: Player, Part: BasePart, Damage: number)
	local ItemsFolder = workspace.PlayerItems:FindFirstChild(Player.UserId)
	
	if Part and ItemsFolder then
		local CurrentHealth = Part:GetAttribute("CurrentHealth")
		
		if not CurrentHealth or CurrentHealth > 0 then
			local NewHealth = (CurrentHealth or Part:FindFirstChild("Health") and Part.Health.Value or 1) - Damage
			
			Part:SetAttribute("CurrentHealth", NewHealth)

			if NewHealth <= 0 then
				if #ItemsFolder:GetChildren() < 200 and GameSettings.HarvestItems[Part.Name] and GameSettings.HarvestItems[Part.Name].ItemID then
					local Item = game.ReplicatedStorage.ItemIDs:FindFirstChild(GameSettings.HarvestItems[Part.Name].ItemID).Item:Clone()

					Item.Parent = ItemsFolder
					Item.Anchored = false
					Item.Position = Part.Position
				end

				if Part.Parent == workspace.OreFolder then
					game.ReplicatedStorage.BindableEvents.MineOre:Fire(Part)
				else
					Part:Destroy()
				end
			end
		end
	end
end

return ServerFunctions