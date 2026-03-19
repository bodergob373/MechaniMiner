local Ores = game.ReplicatedStorage:WaitForChild("Ores")
local MineBounds = workspace.Mine.MineBounds
local PreloadedArea = workspace.Mine.PreloadedArea
local LoadedOres = {}

local BlockSize = 2
local MaxLoadRecursion = 4

local OreInfo = {
	["Stone"] = {Depth = -math.huge, Rarity = 1, Transparent = false},
	["Iron Ore"] = {Depth = 6, Rarity = 0.02, Transparent = false},
	["Copper Ore"] = {Depth = 19, Rarity = 0.04, Transparent = false},
	["Tin Ore"] = {Depth = 19, Rarity = 0.02, Transparent = false},
	["Coal"] = {Depth = 4, Rarity = 0.1, Transparent = false},
	["Gold Ore"] = {Depth = 19, Rarity = 0.002, Transparent = false},
	["Oil"] = {Depth = 15, Rarity = 0.08, Transparent = true},
}

function IsInBounds(Position, Area)
	for _, AreaPart in Area:GetChildren() do
		if AreaPart:IsA("BasePart") then
			local Abs = (AreaPart.CFrame:Inverse() * CFrame.new(Position * BlockSize)).Position:Abs()
			
			if Abs.X <= AreaPart.Size.X / 2 and Abs.Y <= AreaPart.Size.Y / 2 and Abs.Z <= AreaPart.Size.Z / 2 then
				return true
			end
		end
	end
	
	return false
end

function GetOre(Position)
	local Depth = -Position.Y
	local TotalChance = 0

	for OreName, OreType in OreInfo do
		local Chance = OreType.Rarity / (1 + 1.2 ^ (OreType.Depth - Depth + 1))

		OreType.IntervalStart = TotalChance
		OreType.CurrentChance = Chance
		TotalChance += Chance
	end

	local RandomNumber = math.random() * TotalChance

	for OreName, OreType in OreInfo do
		if RandomNumber >= OreType.IntervalStart and RandomNumber < OreType.IntervalStart + OreType.CurrentChance then
			if Ores:FindFirstChild(OreName) then
				return OreName
			end
		end
	end
end

function LoadOre(Position, RecursiveLevel)
	RecursiveLevel = RecursiveLevel or 0
	
	if RecursiveLevel < MaxLoadRecursion and not LoadedOres[Position] and IsInBounds(Position, MineBounds) then
		local OreName = GetOre(Position)
		local OreTemplate = Ores:FindFirstChild(OreName)
		local PositionInfo = {OreName = OreName}

		if OreTemplate then
			local OreClone = Ores:FindFirstChild(OreName):Clone()

			OreClone.Parent = workspace.OreFolder
			OreClone.Position = Position * BlockSize
			PositionInfo.Ore = OreClone
		end
		
		LoadedOres[Position] = PositionInfo

		if OreInfo[OreName].Transparent then
			for _, NormalId in Enum.NormalId:GetEnumItems() do
				LoadOre(Position + Vector3.FromNormalId(NormalId), RecursiveLevel + 1)
			end
		end
	end
end

function MineOre(Ore)
	local Position = (Ore.Position / BlockSize + Vector3.new(0.5, 0.5, 0.5)):Floor()
	
	if LoadedOres[Position] and LoadedOres[Position].Ore == Ore then
		LoadedOres[Position].Ore = nil
		
		for _, NormalId in Enum.NormalId:GetEnumItems() do
			LoadOre(Position + Vector3.FromNormalId(NormalId))
		end
		
		Ore:Destroy()
	end
end

game.ReplicatedStorage.BindableEvents.MineOre.Event:Connect(MineOre)

for _, AreaPart in PreloadedArea:GetChildren() do
	if AreaPart:IsA("BasePart") then
		local RectangularBounds = (AreaPart.CFrame.Rotation:Inverse() * CFrame.new(AreaPart.Size / 2)).Position:Abs()
		local StartPosition = ((AreaPart.Position - RectangularBounds) / BlockSize):Ceil()
		local EndPosition = ((AreaPart.Position + RectangularBounds) / BlockSize):Floor()
		
		for X = StartPosition.X, EndPosition.X do
			for Y = StartPosition.Y, EndPosition.Y do
				for Z = StartPosition.Z, EndPosition.Z do
					local Position = Vector3.new(X, Y, Z)
					if IsInBounds(Position, PreloadedArea) then
						LoadOre(Position)
					end
				end
			end
		end
	end
end