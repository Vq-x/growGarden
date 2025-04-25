local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local player = game.Players.LocalPlayer
local Plants = {
	ORANGE_TULIP = "Orange Tulip",
	CARROT = "Carrot",
}

function filter(sequence, predicate)
	local newlist = {}
	for i, v in ipairs(sequence) do
		if predicate(v) then
			table.insert(newlist, v)
		end
	end
	return newlist
end

function autoCollectPlants()
	local proximityPrompts = {}
	for _, Farm in pairs(workspace.Farm:GetChildren()) do
		if Farm.Important.Data.Owner.Value == player.Name then
			for _, plant in pairs(Farm.Important.Plants_Physical:GetChildren()) do
				for _, v in pairs(plant:GetDescendants()) do
					if v:IsA("ProximityPrompt") and v.Parent:IsA("Part")then
						table.insert(proximityPrompts, v.Parent.Position)
					end
				end
			end
		end
	end
	local originalCFrame = CFrame.new(player.Character.HumanoidRootPart.Position)
	for _, proximityPrompt in pairs(proximityPrompts) do
		while _G.selling do
			player.Character.HumanoidRootPart.CFrame = CFrame.new(workspace.NPCS["Sell Stands"].PrimaryPart.Position)
			task.wait(0.1)
		end
		player.Character.HumanoidRootPart.CFrame = CFrame.new(proximityPrompt) + Vector3.new(0, 5, 0)
		task.wait(0.1)
		instantHarvestAura()
		task.wait(0.1)
		player.Character.HumanoidRootPart.CFrame = originalCFrame
	end
	
end

function instantHarvestAura()
	for _, Farm in pairs(workspace.Farm:GetChildren()) do
		if Farm.Important.Data.Owner.Value == player.Name then
			for _, plant in pairs(Farm.Important.Plants_Physical:GetChildren()) do
				for _, v in pairs(plant:GetDescendants()) do
					if v:IsA("ProximityPrompt") then
						v.Enabled = true
						fireproximityprompt(v)
					end
				end
			end
		end
	end
end

function getInStockSeeds()
	local inStockSeeds = {}
	for _, v in pairs(game:GetService("Players").LocalPlayer.PlayerGui.Seed_Shop.Frame.ScrollingFrame:GetDescendants()) do
		if v:IsA("Frame") then
			if v.Name == "In_Stock" and v.Visible then
				table.insert(inStockSeeds, v.Parent.Parent.Parent.Name)
			end
		end
	end
	return inStockSeeds
end

function listPlantNames()
	local plantNames = {}
	for _, seed in pairs(game:GetService("ReplicatedStorage").Seed_Models:GetChildren()) do
		table.insert(plantNames, seed.Name)
	end
	return plantNames
end

function buySeed(seed, amount)
	local args = {
		[1] = seed,
	}
	for i = 1, amount do
		game:GetService("ReplicatedStorage")
			:WaitForChild("GameEvents")
			:WaitForChild("BuySeedStock")
			:FireServer(unpack(args))
	end
end

function buyEasterStock(seed, amount)
	local args = {
		[1] = seed,
	}
	for i = 1, amount do
		game:GetService("ReplicatedStorage"):WaitForChild("GameEvents"):WaitForChild("BuyEasterStock"):FireServer(unpack(args))
	end
end

function autoSellPlants()

	local seedsInInventory = player.Backpack:GetChildren()
	local plantsInInventory = filter(seedsInInventory, function(v)
		return v:IsA("Tool") and v:GetAttribute("ITEM_TYPE") == "Holdable" and v:GetAttribute("Favorite") ~= true
	end)
	-- print("Plants in inventory: " .. #plantsInInventory)
	if #plantsInInventory > _G.autoSellPlantsAmount then
		_G.selling = true
		sellInventory()
		_G.selling = false
	end
end

function autoPlantSeeds()
	local seedsInInventory = player.Backpack:GetChildren()
	local originalCFrame = CFrame.new(player.Character.HumanoidRootPart.Position)
	for _, seed in pairs(seedsInInventory) do
		if seed:IsA("Tool") and seed:GetAttribute("ITEM_TYPE") == "Seed" then
			if table.find(_G.autoPlantSeedsList, seed:GetAttribute("Seed")) then
				-- teleport user to their farm
				for _, farm in pairs(workspace.Farm:GetChildren()) do
					if farm.Important.Data.Owner.Value == player.Name then
						-- for _, plantable in pairs(farm.Important.Plant_Locations:GetChildren()) do
						local plantable = filter(farm.Important.Plant_Locations:GetChildren(), function(v)
							return v.Name == "Can_Plant"
						end)
						local randomPlantable = plantable[math.random(1, #plantable)]

						player.Character.HumanoidRootPart.CFrame = CFrame.new(randomPlantable.Position)
							+ Vector3.new(0, 5, 0)
					end
				end
				-- bring the seed to the players hand
				seed.Parent = player.Character
				for i = 1, 10 do
					plantOnFarm()
					task.wait(0.1)
				end
				-- put the seed back in the players inventory
				if seed:FindFirstChild("Handle") then
					seed.Parent = player.Backpack
				end
				player.Character.HumanoidRootPart.CFrame = originalCFrame
			end
		end
	end
end

function removePlant(plant)
	local args = {
		[1] = plant,
	}

	game:GetService("ReplicatedStorage"):WaitForChild("GameEvents"):WaitForChild("Remove_Item"):FireServer(unpack(args))
end


function removePlantsAura()
	local found = false
	for _, Farm in pairs(workspace.Farm:GetChildren()) do
		if Farm.Important.Data.Owner.Value == player.Name then
			for _, plant in pairs(Farm.Important.Plants_Physical:GetChildren()) do
				if plant:IsA("Model") and table.find(_G.removePlantsAuraList, plant.Name) then
					if not found then
						player.Backpack["Shovel [Destroy Plants]"].Parent = player.Character
						found = true
					end
					
					removePlant(plant.PrimaryPart)
					
				end
			end
		end
	end
	if found then
		player.Character.Humanoid:UnequipTools()
		task.wait(0.1)
		found = false
	end
end

function autoBuySeeds()
	local inStockSeeds = getInStockSeeds()
	for _, seed in pairs(inStockSeeds) do
		if table.find(_G.autoBuySeedsList, seed) then
			buySeed(seed, 50)
			buyEasterStock(seed, 50)
		end
	end
end

function collectAllPlants()
	local originalCFrame = CFrame.new(player.Character.HumanoidRootPart.Position)
	for _, Farm in pairs(workspace.Farm:GetChildren()) do
		if Farm.Important.Data.Owner.Value == player.Name then
			for _, plant in pairs(Farm.Important.Plants_Physical:GetChildren()) do
				for _, v in pairs(plant:GetDescendants()) do
					if v:IsA("ProximityPrompt") then
						v.Enabled = true
						player.Character.HumanoidRootPart.CFrame = CFrame.new(v.Parent.CFrame.Position)
							+ Vector3.new(0, 3, 0)
						task.wait(0.1)
						fireproximityprompt(v)
						task.wait(0.1)
					end
				end
			end
		end
	end
	player.Character.HumanoidRootPart.CFrame = originalCFrame
end

function sellInventory()
	local originalCFrame = CFrame.new(player.Character.HumanoidRootPart.Position)
	player.Character.HumanoidRootPart.CFrame = CFrame.new(workspace.NPCS["Sell Stands"].PrimaryPart.Position)
	task.wait(1)
	game:GetService("ReplicatedStorage"):WaitForChild("GameEvents"):WaitForChild("Sell_Inventory"):FireServer()
	task.wait(1)
	player.Character.HumanoidRootPart.CFrame = originalCFrame
end

function toggleEasterMenu()
	player.PlayerGui["Easter_Shop"].Enabled = not player.PlayerGui["Easter_Shop"].Enabled
end

function toggleGearShop()
	player.PlayerGui["Gear_Shop"].Enabled = not player.PlayerGui["Gear_Shop"].Enabled
end

function toggleSeedShop()
	player.PlayerGui["Seed_Shop"].Enabled = not player.PlayerGui["Seed_Shop"].Enabled
end

function plantOnPlayer()
	plant(player.Character.HumanoidRootPart.Position.X, player.Character.HumanoidRootPart.Position.Z, Plants.CARROT)
end

function plantOnFarm()
	local toolInPlayerHand = player.Character:FindFirstChildWhichIsA("Tool")
	if not toolInPlayerHand then
		Rayfield:Notify({
			Title = "Nothing in hand",
			Content = "Please hold a tool in your hand to plant",
			Duration = 6.5,
			Image = 4483362458,
		})
		return
	else
		if toolInPlayerHand:GetAttribute("ITEM_TYPE") ~= "Seed" then
			Rayfield:Notify({
				Title = "Wrong tool",
				Content = "Please hold a seed in your hand to plant",
				Duration = 6.5,
				Image = 4483362458,
			})
			return
		end
	end

	for _, Farm in pairs(workspace.Farm:GetChildren()) do
		if Farm.Important.Data.Owner.Value == player.Name then
			local plantable = filter(Farm.Important.Plant_Locations:GetChildren(), function(v)
				return v.Name == "Can_Plant"
			end)
			local randomPlantable = plantable[math.random(1, #plantable)]

			local randomPlantablePosition = Vector3.new(
				math.random(
					randomPlantable.Position.X - randomPlantable.Size.X / 2,
					randomPlantable.Position.X + randomPlantable.Size.X / 2
				),
				0,
				math.random(
					randomPlantable.Position.Z - randomPlantable.Size.Z / 2,
					randomPlantable.Position.Z + randomPlantable.Size.Z / 2
				)
			)
			plant(randomPlantablePosition.X, randomPlantablePosition.Z, toolInPlayerHand:GetAttribute("Seed"))
		end
	end
end

function plant(x, z, plant: string)
	local args = {
		[1] = Vector3.new(x, 0.1355254054069519, z),
		[2] = plant,
	}

	game:GetService("ReplicatedStorage"):WaitForChild("GameEvents"):WaitForChild("Plant_RE"):FireServer(unpack(args))
end

local Window = Rayfield:CreateWindow({
	Name = "Tyler's Hub",
	Icon = 0, -- Icon in Topbar. Can use Lucide Icons (string) or Roblox Image (number). 0 to use no icon (default).
	LoadingTitle = "Grow A Garden Script",
	LoadingSubtitle = "by Tyler",
	Theme = "Default", -- Check https://docs.sirius.menu/rayfield/configuration/themes

	DisableRayfieldPrompts = true,
	DisableBuildWarnings = false, -- Prevents Rayfield from warning when the script has a version mismatch with the interface

	ConfigurationSaving = {
		Enabled = true,
		FolderName = nil, -- Create a custom folder for your hub/game
		FileName = "Grow Garden",
	},

	Discord = {
		Enabled = false, -- Prompt the user to join your Discord server if their executor supports it
		Invite = "noinvitelink", -- The Discord invite code, do not include discord.gg/. E.g. discord.gg/ ABCD would be ABCD
		RememberJoins = true, -- Set this to false to make them join the discord every time they load it up
	},

	KeySystem = false, -- Set this to true to use our key system
	KeySettings = {
		Title = "Untitled",
		Subtitle = "Key System",
		Note = "No method of obtaining the key is provided", -- Use this to tell the user how to get a key
		FileName = "Key", -- It is recommended to use something unique as other scripts using Rayfield may overwrite your key file
		SaveKey = true, -- The user's key will be saved, but if you change the key, they will be unable to use your script
		GrabKeyFromSite = false, -- If this is true, set Key below to the RAW site you would like Rayfield to get the key from
		Key = { "Hello" }, -- List of keys that will be accepted by the system, can be RAW file links (pastebin, github etc) or simple strings ("hello","key22")
	},
})

local mainTab = Window:CreateTab("Main")

local menusTab = Window:CreateTab("Menus")

local autoFarmTab = Window:CreateTab("Auto Farm")

local collectFruitsButton = mainTab:CreateButton({
	Name = "Collect All Plants (even if not fully grown)",
	Callback = collectAllPlants,
})

local instantHarvestAuraToggle = mainTab:CreateToggle({
	Name = "Instant Harvest Aura",
	CurrentValue = false,
	Flag = "instantHarvestAuraToggle",
	Callback = function(Value)
		if Value then
			_G.instantHarvestThread = task.spawn(function()
				while true do
					instantHarvestAura()
					task.wait(0.25)
				end
			end)
		else
			if _G.instantHarvestThread then
				task.cancel(_G.instantHarvestThread)
				_G.instantHarvestThread = nil
			end
		end
	end,
})

local toggleEasterMenuButton = menusTab:CreateButton({
	Name = "Toggle Easter Shop",
	Callback = toggleEasterMenu,
})

local toggleGearShopButton = menusTab:CreateButton({
	Name = "Toggle Gear Shop",
	Callback = toggleGearShop,
})

local toggleSeedShopButton = menusTab:CreateButton({
	Name = "Toggle Seed Shop",
	Callback = toggleSeedShop,
})

local sellInventoryButton = mainTab:CreateButton({
	Name = "Sell Inventory",
	Callback = sellInventory,
})

local plantOnPlayerButton = mainTab:CreateButton({
	Name = "Plant On Player",
	Callback = plantOnPlayer,
})

local plantOnFarmButton = mainTab:CreateButton({
	Name = "Plant On Farm",
	Callback = plantOnFarm,
})

local autoCollectPlantsToggle = autoFarmTab:CreateToggle({
	Name = "Auto Collect Plants",
	CurrentValue = false,
	Flag = "autoCollectPlantsToggle",
	Callback = function(Value)
		if Value then
			_G.autoCollectPlantsTask = task.spawn(function()
				while true do
					while _G.selling do
						task.wait(0.1)
					end
					autoCollectPlants()
					
					task.wait(_G.autoCollectPlantsInterval)
					
				end
			end)
		else
			if _G.autoCollectPlantsTask then
				task.cancel(_G.autoCollectPlantsTask)
				_G.autoCollectPlantsTask = nil
			end
		end
	end,
})

local autoCollectPlantsInterval = autoFarmTab:CreateSlider({
	Name = "Auto Collect Plants Interval",
	Range = { 1, 60 },
	Increment = 1,
	Suffix = "Seconds",
	CurrentValue = 5,
	Flag = "autoCollectPlantsInterval",
	Callback = function(Value)
		_G.autoCollectPlantsInterval = Value
	end,
})


local autoBuySeedsToggle = autoFarmTab:CreateToggle({
	Name = "Auto Buy Seeds",
	CurrentValue = false,
	Flag = "autoBuySeedsToggle",
	Callback = function(Value)
		if Value then
			_G.autoBuySeedsTask = task.spawn(function()
				while true do
					autoBuySeeds()
					task.wait(5)
				end
			end)
		else
			if _G.autoBuySeedsTask then
				task.cancel(_G.autoBuySeedsTask)
				_G.autoBuySeedsTask = nil
			end
		end
	end,
})

local autoBuySeedsList = autoFarmTab:CreateDropdown({
	Name = "Select Seeds to Auto Buy",
	Options = listPlantNames(),
	CurrentOption = nil,
	MultipleOptions = true,
	Flag = "autoBuySeedsList", -- A flag is the identifier for the configuration file, make sure every element has a different flag if you're using configuration saving to ensure no overlaps
	Callback = function(Options)
		if #Options ~= 0 then
			Rayfield:Notify({
				Title = "Auto Buy Seeds",
				Content = "Auto buying seeds for " .. table.concat(Options, ", "),
				Duration = 6.5,
				Image = 4483362458,
			})
		end
		_G.autoBuySeedsList = Options
	end,
})

local autoPlantSeedsToggle = autoFarmTab:CreateToggle({
	Name = "Auto Plant Seeds",
	CurrentValue = false,
	Flag = "autoPlantSeedsToggle",
	Callback = function(Value)
		if Value then
			_G.autoPlantSeedsTask = task.spawn(function()
				while true do
					autoPlantSeeds()
					task.wait(0.1)
				end
			end)
		else
			if _G.autoPlantSeedsTask then
				task.cancel(_G.autoPlantSeedsTask)
				_G.autoPlantSeedsTask = nil
			end
		end
	end,
})

local autoPlantSeedsList = autoFarmTab:CreateDropdown({
	Name = "Auto Plant Seeds",
	Options = listPlantNames(),
	CurrentOption = nil,
	MultipleOptions = true,
	Flag = "autoPlantSeedsList",
	Callback = function(Options)
		_G.autoPlantSeedsList = Options
	end,
})

local autoSellPlantsToggle = autoFarmTab:CreateToggle({
	Name = "Auto Sell Plants",
	CurrentValue = false,
	Flag = "autoSellPlantsToggle",
	Callback = function(Value)
		if Value then
			_G.autoSellPlantsTask = task.spawn(function()
				while true do
					autoSellPlants()
					task.wait(1)
				end
			end)
		else
			if _G.autoSellPlantsTask then
				task.cancel(_G.autoSellPlantsTask)
				_G.autoSellPlantsTask = nil
			end
		end
	end,
})

local autoSellPlantsAmount = autoFarmTab:CreateSlider({
	Name = "Auto Sell Plants Amount",
	Range = { 0, 100 },
	Increment = 5,
	Suffix = "Plants",
	CurrentValue = 20,
	Flag = "autoSellPlantsAmount",
	Callback = function(Value)
		_G.autoSellPlantsAmount = Value
	end,
})



local removePlantsAuraToggle = autoFarmTab:CreateToggle({
	Name = "Remove Plants Aura",
	CurrentValue = false,
	Flag = "removePlantsAuraToggle",
	Callback = function(Value)
		if Value then
			_G.removePlantsAuraTask = task.spawn(function()
				while true do
					removePlantsAura()
					task.wait(0.25)
				end
			end)
		else
			if _G.removePlantsAuraTask then
				task.cancel(_G.removePlantsAuraTask)
				_G.removePlantsAuraTask = nil
			end
		end
	end,
})

local removePlantsAuraList = autoFarmTab:CreateDropdown({
	Name = "Remove Plants Aura",
	Options = listPlantNames(),
	CurrentOption = nil,
	MultipleOptions = true,
	Flag = "removePlantsAuraList",
	Callback = function(Options)
		_G.removePlantsAuraList = Options
	end,
})




local destroyGuiButton = mainTab:CreateButton({
	Name = "Destroy GUI",
	Callback = function()
		Rayfield:Destroy()
	end,
})
