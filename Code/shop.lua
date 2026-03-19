local Shop = workspace.Map:WaitForChild("Shop")
local Items = game.ReplicatedStorage.ItemIDs
local Blocks = game.ReplicatedStorage.BlockIDs
local GameSettings = require(game.ReplicatedStorage.GameSettings)
local ServerFunctions = require(game.ServerScriptService.ServerFunctions)
local shelfSpawns = {}
local ShopBound = Shop.ShopBounds
local BuyArea = Shop.BuyArea.Area

for _, part in pairs(Shop:GetDescendants()) do
	if part.Name == "ShelfSpawn" then
		table.insert(shelfSpawns, {part = part, Item = nil, Timer = 0})
	end
end

local function UpdSpawn(shelfSpawn)
	local spawnPart = shelfSpawn.part

	if shelfSpawn.Item then
		local itemPos = shelfSpawn.Item.Position
		local spawnPos = spawnPart.Position
		local minpos, maxpos = ShopBound.Position - ShopBound.Size/2, ShopBound.Position + ShopBound.Size / 2

		if not shelfSpawn.Item:HasTag("ShopItem") then
			shelfSpawn.Item = nil
		elseif itemPos.X <= minpos.X or itemPos.X >= maxpos.X or itemPos.Y <= minpos.Y or itemPos.Y >= maxpos.Y or itemPos.Z <= minpos.Z or itemPos.Z >= maxpos.Z then
			shelfSpawn.Item:Destroy()
			shelfSpawn.Item = nil
			ShopBound.StealSound:Play()
		elseif (itemPos-spawnPos).Magnitude > 5 and itemPos.Y < 3 then
			shelfSpawn.Timer = (shelfSpawn.Timer or 0) + 1
		end

		if shelfSpawn.Timer and shelfSpawn.Timer > 50 then
			shelfSpawn.Item:Destroy()
			shelfSpawn.Item = nil
			shelfSpawn.Timer = 0
		end
	end


	if not shelfSpawn.Item or not shelfSpawn.Item.Parent then
		local spawnId = spawnPart:GetAttribute("Id")

		if spawnPart:HasTag("PartBoxSpawn") then
			local Box = ServerFunctions.GenerateItem("22", {BoxedBlockID = spawnId})
			
			Box.Parent = workspace.PlayerItems["0"]
			Box.CFrame = spawnPart.CFrame
			Box:AddTag("ShopItem")
			shelfSpawn.Item = Box
		elseif spawnPart:HasTag("Itemspawn") then
			local item = ServerFunctions.GenerateItem(spawnId)

			item.Parent = workspace.PlayerItems["0"]
			item.CFrame = spawnPart.CFrame
			shelfSpawn.Item = item
			item:AddTag("ShopItem")
		end
	end
end

local Params = OverlapParams.new()

Params.FilterType = Enum.RaycastFilterType.Include

wait(4)

while task.wait(0.4) do
	for _, shelfSpawn in pairs(shelfSpawns) do
		UpdSpawn(shelfSpawn)
	end

	local cost = 0

	Params.FilterDescendantsInstances = game.CollectionService:GetTagged("ShopItem")

	local parts = workspace:GetPartsInPart(BuyArea, Params)

	for _, part in pairs(parts) do
		local ItemID = part:GetAttribute("ItemID")
		local itemCost = 0

		if ItemID == "22" then
			if GameSettings.BlockCosts[tostring(part:getAttribute("BoxedBlockID"))] then
				itemCost = GameSettings.BlockCosts[tostring(part:getAttribute("BoxedBlockID"))].Amount or 0
			end
		else
			if GameSettings.ItemCurrencyValues[ItemID] then
				itemCost = (GameSettings.ItemCurrencyValues[ItemID].Amount) * GameSettings.ItemCostMarkup
			end
		end

		cost += itemCost
	end

	Shop.CostDisplay.SurfaceGui.TextLabel.Text = "Cost: ".. cost .. " ඞ"
end