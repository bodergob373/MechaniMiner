local GameSettings = {}

GameSettings.BlockPositionIncrement = 1
GameSettings.AssemblyPositionIncrement = 0.1
GameSettings.AssemblyRotationIncrement = 0.01
GameSettings.ItemPositionIncrement = 0.1
GameSettings.ItemRotationIncrement = 0.1
GameSettings.MaxBuildRadius = 40
GameSettings.RotationArcThickness = 0.1
GameSettings.BlockDropHeight = 2
GameSettings.ItemCostMarkup = 2

GameSettings.ItemCurrencyValues = {
	["1"] = {Amount = 4, CurrencyType = "Currency1"},
	["7"] = {Amount = 6, CurrencyType = "Currency1"},
	["8"] = {Amount = 8, CurrencyType = "Currency1"},
	["9"] = {Amount = 12, CurrencyType = "Currency1"},
	["11"] = {Amount = 20, CurrencyType = "Currency1"},
	["12"] = {Amount = 14, CurrencyType = "Currency1"},
	["14"] = {Amount = 26, CurrencyType = "Currency1"},
	["15"] = {Amount = 16, CurrencyType = "Currency1"},
	["16"] = {Amount = 20, CurrencyType = "Currency1"},
	["17"] = {Amount = 28, CurrencyType = "Currency1"},
	["19"] = {Amount = 94, CurrencyType = "Currency1"},
	["21"] = {Amount = 160, CurrencyType = "Currency1"},
}

GameSettings.BlockCosts = {
	["1"] = {Amount = 6, CurrencyType = "Currency1"},
	["2"] = {Amount = 4, CurrencyType = "Currency1"},
	["3"] = {Amount = 48, CurrencyType = "Currency1"},
	["4"] = {Amount = 8, CurrencyType = "Currency1"},
	["5"] = {Amount = 22, CurrencyType = "Currency1"},
	["6"] = {Amount = 72, CurrencyType = "Currency1"},
	["7"] = {Amount = 24, CurrencyType = "Currency1"},
	["8"] = {Amount = 32, CurrencyType = "Currency1"},
	["9"] = {Amount = 18, CurrencyType = "Currency1"},
	["10"] = {Amount = 42, CurrencyType = "Currency1"},
	["11"] = {Amount = 64, CurrencyType = "Currency1"},
	["12"] = {Amount = 32, CurrencyType = "Currency1"},
	["13"] = {Amount = 4, CurrencyType = "Currency1"},
	["14"] = {Amount = 56, CurrencyType = "Currency1"},
	["15"] = {Amount = 10, CurrencyType = "Currency1"},
	["16"] = {Amount = 18, CurrencyType = "Currency1"},
	["17"] = {Amount = 28, CurrencyType = "Currency1"},
	["18"] = {Amount = 68, CurrencyType = "Currency1"},
	["19"] = {Amount = 666, CurrencyType = "Currency1"},
	["20"] = {Amount = 26, CurrencyType = "Currency1"},
	["21"] = {Amount = 212, CurrencyType = "Currency1"},
	["22"] = {Amount = 8, CurrencyType = "Currency1"},
	["23"] = {Amount = 14, CurrencyType = "Currency1"},
	["24"] = {Amount = 24, CurrencyType = "Currency1"},
	["25"] = {Amount = 28, CurrencyType = "Currency1"},
	["26"] = {Amount = 36, CurrencyType = "Currency1"},
	["27"] = {Amount = 132, CurrencyType = "Currency1"},
	["28"] = {Amount = 14, CurrencyType = "Currency1"},
	["29"] = {Amount = 44, CurrencyType = "Currency1"},
	["30"] = {Amount = 38, CurrencyType = "Currency1"},
	["31"] = {Amount = 62, CurrencyType = "Currency1"},
	["32"] = {Amount = 78, CurrencyType = "Currency1"},
	["33"] = {Amount = 2, CurrencyType = "Currency1"},
	["34"] = {Amount = 128, CurrencyType = "Currency1"},
}

GameSettings.HarvestItems = {
	["Stone"] = {ItemID = nil},
	["Coal"] = {ItemID = "7"},
	["Oil"] = {ItemID = "8"},
	["Tin Ore"] = {ItemID = "9"},
	["Copper Ore"] = {ItemID = "12"},
	["Iron Ore"] = {ItemID = "15"},
	["Gold Ore"] = {ItemID = "19"},
	["Log"] = {ItemID = "1"},
}

GameSettings.SmelterRecipes = {
	["1"] = "7",
	["9"] = "11",
	["12"] = "14",
	["15"] = "17",
	["19"] = "21",
}

return GameSettings