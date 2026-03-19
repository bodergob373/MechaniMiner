local RunService = game:GetService("RunService")
local GameSettings = require(game.ReplicatedStorage.GameSettings)
local UserId = tonumber(script.Parent.Parent.Parent.Name)
local Player = UserId and game.Players:GetPlayerByUserId(UserId)
local ItemsFolder = UserId and workspace.PlayerItems:FindFirstChild(UserId)
local ItemOverlapParams = OverlapParams.new()

RunService.Heartbeat:Connect(function()
	if Player and ItemsFolder then
		local TouchingInput = workspace:GetPartsInPart(script.Parent.Input, ItemOverlapParams)
		
		for _, Part in TouchingInput do
			local ItemID = Part:GetAttribute("ItemID")
			
			if ItemID and Part.Parent == ItemsFolder then
				local OutputItemID = GameSettings.SmelterRecipes[ItemID]
				
				if OutputItemID and game.ReplicatedStorage.ItemIDs[OutputItemID] and game.ReplicatedStorage.ItemIDs[OutputItemID]:FindFirstChild("Item") then
					local OutputItem = game.ReplicatedStorage.ItemIDs[OutputItemID].Item:Clone()
					
					Part:Destroy()
					OutputItem.Parent = ItemsFolder
					OutputItem.Anchored = false
					OutputItem.CFrame = script.Parent.Output.CFrame
				end
			end
		end
	end
end)

ItemOverlapParams.FilterType = Enum.RaycastFilterType.Include
ItemOverlapParams.FilterDescendantsInstances = {ItemsFolder}