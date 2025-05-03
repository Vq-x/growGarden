local Rayfield =
	loadstring(game:HttpGet("https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/main/source.lua"))()

local guy = game:GetService("VirtualUser")
game:GetService("Players").LocalPlayer.Idled:Connect(function()
	guy:CaptureController()
	guy:ClickButton2(Vector2.new()) -- this clicks a thing to stop ur dumb 20 min idle kick lol have fun roblox
	task.wait(2)
end)

local player = game.Players.LocalPlayer

-- Utility functions
function filter(sequence, predicate)
	local newlist = {}
	for i, v in ipairs(sequence) do
		if predicate(v) then
			table.insert(newlist, v)
		end
	end
	return newlist
end

-- Grow Garden Game Class
local growGarden = {}
growGarden.__index = growGarden

function growGarden.new()
    local self = setmetatable({}, growGarden)
    self.player = game.Players.LocalPlayer
    self.jimRequestCache = nil

    -- Load all functions into memory
    function self:favoritePlant(plant)
        local args = {
            [1] = plant,
        }
    
        game:GetService("ReplicatedStorage")
            :WaitForChild("GameEvents")
            :WaitForChild("Favorite_Item")
            :FireServer(unpack(args))
    end
    
    function self:autoFavorite()
        local backpack = self.player.Backpack or self.player:WaitForChild("Backpack")
        local seedsInInventory = backpack:GetChildren()
        local plantsInInventory = filter(seedsInInventory, function(v)
            return v:IsA("Tool") and v:GetAttribute("ITEM_TYPE") == "Holdable" and v:GetAttribute("Favorite") ~= true
        end)
        for _, plant in pairs(plantsInInventory) do
            if
                plant and plant:WaitForChild("Weight") and plant.Weight.Value > _G.autoFavoriteWeight
                or plant:GetAttribute("Variant") and table.find(_G.autoFavoriteVariance, plant:GetAttribute("Variant"))
            then
                self:favoritePlant(plant)
            end
        end
    end
    
    function self:autoOpenSeedPack()
        local backpack = self.player.Backpack or self.player:WaitForChild("Backpack")
        local seedsInInventory = backpack:GetChildren()
        local seedsInInventory = filter(seedsInInventory, function(v)
            return v:IsA("Tool") and v:GetAttribute("ITEM_TYPE") == "Seed Pack"
        end)
        for _, seedPack in pairs(seedsInInventory) do
            self.player.Character.Humanoid:EquipTool(seedPack)
            task.wait(0.1)
            for i = 1, seedPack:GetAttribute("Uses") do
                seedPack:Activate()
                task.wait(0.1)
            end
            self.player.Character.Humanoid:UnequipTools()
            task.wait(0.1)
        end
    end
    
    function self:getJimRequest()
        game:GetService("SoundService").NPC_Text.Volume = 0
        fireproximityprompt(workspace.SeedPack.JimTheFlytrap.Model.Base.Head.ProximityPrompt)
        local jimRequest =
            workspace.SeedPack.JimTheFlytrap.Model.Base.Head:WaitForChild("Talk_UI"):WaitForChild("TextLabel").Text
        print(jimRequest)
        if string.find(jimRequest, "Feed me a") then
            print("Found")
            self.jimRequestCache = jimRequest
            return jimRequest
        else
            return self.jimRequestCache
        end
    end
    
    function self:parseJimRequest(jimRequest)
        local plant, weight = jimRequest:match("Feed me a%s+([%a%s]+)%s+that weighs at least%s+([%d%.]+)kg")
        return plant, tonumber(weight)
    end
    
    function self:autoCollectDroppedSeed()
        for _, v in pairs(workspace:GetChildren()) do
            if v:IsA("Model") and v:GetAttribute("OWNER") == self.player.Name and string.find(v.Name, "Collectable") then
                while v ~= nil do
                    firetouchinterest(v.PrimaryPart, self.player.Character.HumanoidRootPart, true)
                    firetouchinterest(v.PrimaryPart, self.player.Character.HumanoidRootPart, false)
                    task.wait(1)
                end
            end
        end
    end
    
    function self:giveHeldPlant()
        local args = {
            [1] = "SubmitHeldPlant",
        }
    
        game:GetService("ReplicatedStorage")
            :WaitForChild("GameEvents")
            :WaitForChild("SeedPackGiverEvent")
            :FireServer(unpack(args))
    end
    
    function self:extractAdjectives(inputString)
        local adjList = inputString:match("%[(.-)%]")
        if adjList then
            local result = {}
            for adj in adjList:gmatch("([^,]+)") do
                adj = adj:match("^%s*(.-)%s*$")
                table.insert(result, adj)
            end
            return result
        else
            return {}
        end
    end
    
    function self:wordInStringFromList(inputString, list)
        for _, word in pairs(list) do
            if not string.find(inputString, word) then
                return false
            end
        end
        return true
    end
    
    function self:autoFeedJim()
        local plantName, weight = self:parseJimRequest(self:getJimRequest())
        local backpack = self.player.Backpack or self.player:WaitForChild("Backpack")
        local seedsInInventory = backpack:GetChildren()
        local plantsInInventory = filter(seedsInInventory, function(v)
            return v:IsA("Tool") and v:GetAttribute("ITEM_TYPE") == "Holdable" and v:GetAttribute("Favorite") ~= true
        end)
    
        for _, plant in pairs(plantsInInventory) do
            if
                plant:GetAttribute("ItemName") == plantName
                and plant:WaitForChild("Weight")
                and plant.Weight.Value >= weight
                and self:wordInStringFromList(plant.Name, self:extractAdjectives(plantName))
            then
                _G.feedingJim = true
                while plant ~= nil do
                    self.player.Character.Humanoid:EquipTool(plant)
                    task.wait(1)
                    self:giveHeldPlant()
                    task.wait(1)
                    self.player.Character.Humanoid:UnequipTools()
                    task.wait(1)
                end
            end
        end
        _G.feedingJim = false
    end
    
    function self:autoCollectPlants()
        local proximityPrompts = {}
        for _, Farm in pairs(workspace.Farm:GetChildren()) do
            if Farm.Important.Data.Owner.Value == self.player.Name then
                for _, plant in pairs(Farm.Important.Plants_Physical:GetChildren()) do
                    for _, v in pairs(plant:GetDescendants()) do
                        if v:IsA("ProximityPrompt") and v.Parent:IsA("Part") then
                            table.insert(proximityPrompts, v.Parent.Position)
                        end
                    end
                end
            end
        end
        local originalCFrame = CFrame.new(self.player.Character.HumanoidRootPart.Position)
        for _, proximityPrompt in pairs(proximityPrompts) do
            while _G.selling do
                self.player.Character.HumanoidRootPart.CFrame = CFrame.new(workspace.NPCS["Sell Stands"].PrimaryPart.Position)
                task.wait(0.1)
            end
            self.player.Character.HumanoidRootPart.CFrame = CFrame.new(proximityPrompt) + Vector3.new(0, 5, 0)
            task.wait(0.1)
            self:instantHarvestAura()
            task.wait(0.1)
            self.player.Character.HumanoidRootPart.CFrame = originalCFrame
        end
    end
    
    function self:instantHarvestAura()
        for _, Farm in pairs(workspace.Farm:GetChildren()) do
            if Farm.Important.Data.Owner.Value == self.player.Name then
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
    
    function self:getInStockSeeds()
        local inStockSeeds = {}
        for _, v in pairs(game:GetService("Players").LocalPlayer.PlayerGui.Seed_Shop.Frame.ScrollingFrame:GetDescendants()) do
            if v:IsA("Frame") then
                if v.Name == "In_Stock" and v.Visible then
                    table.insert(inStockSeeds, v.Parent.Parent.Parent.Name)
                end
            end
        end
        for _, v in
            pairs(game:GetService("Players").LocalPlayer.PlayerGui.Easter_Shop.Frame.ScrollingFrame:GetDescendants())
        do
            if v:IsA("Frame") then
                if v.Name == "In_Stock" and v.Visible then
                    table.insert(inStockSeeds, v.Parent.Parent.Parent.Name)
                end
            end
        end
        return inStockSeeds
    end
    
    function self:listPlantNames()
        local plantNames = {}
        for _, seed in pairs(game:GetService("ReplicatedStorage").Seed_Models:GetChildren()) do
            table.insert(plantNames, seed.Name)
        end
        return plantNames
    end
    
    function self:buySeed(seed, amount)
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
    
    function self:buyEasterStock(seed, amount)
        print("buying easter stock")
        print(seed)
        local args = {
            [1] = seed,
        }
        for i = 1, amount do
            game:GetService("ReplicatedStorage")
                :WaitForChild("GameEvents")
                :WaitForChild("BuyEasterStock")
                :FireServer(unpack(args))
        end
    end
    
    function self:autoSellPlants()
        local backpack = self.player.Backpack or self.player:WaitForChild("Backpack")
        local seedsInInventory = backpack:GetChildren()
        local plantsInInventory = filter(seedsInInventory, function(v)
            return v:IsA("Tool") and v:GetAttribute("ITEM_TYPE") == "Holdable" and v:GetAttribute("Favorite") ~= true
        end)
        local numberOfPlantsInInventory = plantsInInventory and #plantsInInventory or 0
        if not _G.autoSellPlantsAmount then
            _G.autoSellPlantsAmount = 20
        end
        if numberOfPlantsInInventory > _G.autoSellPlantsAmount then
            _G.selling = true
            self:sellInventory()
            _G.selling = false
        end
    end
    
    function self:autoPlantSeeds()
        local seedsInInventory = self.player.Backpack:GetChildren()
        local originalCFrame = CFrame.new(self.player.Character.HumanoidRootPart.Position)
        for _, seed in pairs(seedsInInventory) do
            if seed:IsA("Tool") and seed:GetAttribute("ITEM_TYPE") == "Seed" then
                if table.find(_G.autoPlantSeedsList, seed:GetAttribute("Seed")) then
                    for _, farm in pairs(workspace.Farm:GetChildren()) do
                        if farm.Important.Data.Owner.Value == self.player.Name then
                            local plantable = filter(farm.Important.Plant_Locations:GetChildren(), function(v)
                                return v.Name == "Can_Plant"
                            end)
                            local randomPlantable = plantable[math.random(1, #plantable)]
    
                            self.player.Character.HumanoidRootPart.CFrame = CFrame.new(randomPlantable.Position)
                                + Vector3.new(0, 5, 0)
                        end
                    end
                    seed.Parent = self.player.Character
                    for i = 1, 10 do
                        self:plantOnFarm()
                        task.wait(0.1)
                    end
                    if seed:FindFirstChild("Handle") then
                        seed.Parent = self.player.Backpack
                    end
                    self.player.Character.HumanoidRootPart.CFrame = originalCFrame
                end
            end
        end
    end
    
    function self:removePlant(plant)
        local args = {
            [1] = plant,
        }
    
        game:GetService("ReplicatedStorage"):WaitForChild("GameEvents"):WaitForChild("Remove_Item"):FireServer(unpack(args))
    end
    
    function self:removePlantsAura()
        self.player.Character.Humanoid:UnequipTools()
        local found = false
        for _, Farm in pairs(workspace.Farm:GetChildren()) do
            if Farm.Important.Data.Owner.Value == self.player.Name then
                for _, plant in pairs(Farm.Important.Plants_Physical:GetChildren()) do
                    if plant:IsA("Model") and table.find(_G.removePlantsAuraList, plant.Name) then
                        print("Model: " .. plant.Name)
                        if found == false then
                            task.wait(0.5)
                            self.player.Character.Humanoid:EquipTool(self.player.Backpack["Shovel [Destroy Plants]"])
                            task.wait(0.5)
                            found = true
                        end
                        self:removePlant(plant.PrimaryPart)
                    end
                end
            end
        end
        if found then
            task.wait(1)
            self.player.Character.Humanoid:UnequipTools()
            task.wait(0.1)
            found = false
        end
    end
    
    function self:autoBuySeeds()
        local inStockSeeds = self:getInStockSeeds()
        for _, seed in pairs(inStockSeeds) do
            if table.find(_G.autoBuySeedsList, seed) then
                self:buySeed(seed, 5)
                self:buyEasterStock(seed, 5)
            end
        end
    end
    
    function self:collectAllPlants()
        local originalCFrame = CFrame.new(self.player.Character.HumanoidRootPart.Position)
        for _, Farm in pairs(workspace.Farm:GetChildren()) do
            if Farm.Important.Data.Owner.Value == self.player.Name then
                for _, plant in pairs(Farm.Important.Plants_Physical:GetChildren()) do
                    for _, v in pairs(plant:GetDescendants()) do
                        if v:IsA("ProximityPrompt") then
                            v.Enabled = true
                            self.player.Character.HumanoidRootPart.CFrame = CFrame.new(v.Parent.CFrame.Position)
                                + Vector3.new(0, 3, 0)
                            task.wait(0.1)
                            fireproximityprompt(v)
                            task.wait(0.1)
                        end
                    end
                end
            end
        end
        self.player.Character.HumanoidRootPart.CFrame = originalCFrame
    end
    
    function self:sellInventory()
        local originalCFrame = CFrame.new(self.player.Character.HumanoidRootPart.Position)
        self.player.Character.HumanoidRootPart.CFrame = CFrame.new(workspace.NPCS["Sell Stands"].PrimaryPart.Position)
        task.wait(1)
        game:GetService("ReplicatedStorage"):WaitForChild("GameEvents"):WaitForChild("Sell_Inventory"):FireServer()
        task.wait(1)
        self.player.Character.HumanoidRootPart.CFrame = originalCFrame
    end
    
    function self:toggleEasterMenu()
        self.player.PlayerGui["Easter_Shop"].Enabled = not self.player.PlayerGui["Easter_Shop"].Enabled
    end
    
    function self:toggleGearShop()
        self.player.PlayerGui["Gear_Shop"].Enabled = not self.player.PlayerGui["Gear_Shop"].Enabled
    end
    
    function self:toggleSeedShop()
        self.player.PlayerGui["Seed_Shop"].Enabled = not self.player.PlayerGui["Seed_Shop"].Enabled
    end
    
    function self:toggleDailyQuests()
        game:GetService("Players").LocalPlayer.PlayerGui.DailyQuests_UI.Enabled =
            not game:GetService("Players").LocalPlayer.PlayerGui.DailyQuests_UI.Enabled
    end
    
    function self:plantOnFarm()
        local toolInPlayerHand = self.player.Character:FindFirstChildWhichIsA("Tool")
        if not toolInPlayerHand then
            return
        else
            if toolInPlayerHand:GetAttribute("ITEM_TYPE") ~= "Seed" then
                return
            end
        end
    
        for _, Farm in pairs(workspace.Farm:GetChildren()) do
            if Farm.Important.Data.Owner.Value == self.player.Name then
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
                self:plant(randomPlantablePosition.X, randomPlantablePosition.Z, toolInPlayerHand:GetAttribute("Seed"))
            end
        end
    end
    
    function self:plant(x, z, plant)
        local args = {
            [1] = Vector3.new(x, 0.1355254054069519, z),
            [2] = plant,
        }
    
        game:GetService("ReplicatedStorage"):WaitForChild("GameEvents"):WaitForChild("Plant_RE"):FireServer(unpack(args))
    end

    return self
end


--============================================================--
--====================[ Grow Garden Script ]====================--
--============================================================--

if game.GameId == 7436755782 then
    -- Create an instance of the growGarden class
    local garden = growGarden.new()

    local Window = Rayfield:CreateWindow({
        Name = "Pulse Hub",
        Icon = 0, -- Icon in Topbar. Can use Lucide Icons (string) or Roblox Image (number). 0 to use no icon (default).
        LoadingTitle = "Grow A Garden Script",
        LoadingSubtitle = "by Vector",
        Theme = "Default", -- Check https://docs.sirius.menu/rayfield/configuration/themes

        DisableRayfieldPrompts = true,
        DisableBuildWarnings = false, -- Prevents Rayfield from warning when the script has a version mismatch with the interface

        ConfigurationSaving = {
            Enabled = true,
            FolderName = nil, -- Create a custom folder for your hub/game
            FileName = "Grow Garden",
        },

        Discord = {
            Enabled = true, -- Prompt the user to join your Discord server if their executor supports it
            Invite = "EF7C37HJbU", -- The Discord invite code, do not include discord.gg/. E.g. discord.gg/ ABCD would be ABCD
            RememberJoins = true, -- Set this to false to make them join the discord every time they load it up
        },

        KeySystem = false, -- Set this to true to use our key system
        KeySettings = {
            Title = "Grow Garden",
            Subtitle = "by Tyler",
            Note = "No method of obtaining the key is provided", -- Use this to tell the user how to get a key
            FileName = "GrowGardenKey", -- It is recommended to use something unique as other scripts using Rayfield may overwrite your key file
            SaveKey = true, -- The user's key will be saved, but if you change the key, they will be unable to use your script
            GrabKeyFromSite = false, -- If this is true, set Key below to the RAW site you would like Rayfield to get the key from
            Key = { "Hello" }, -- List of keys that will be accepted by the system, can be RAW file links (pastebin, github etc) or simple strings ("hello","key22")
        },
    })

    local mainTab = Window:CreateTab("Main")

    local menusTab = Window:CreateTab("Menus")

    local autoFarmTab = Window:CreateTab("Auto Farm")

    local autoFavoriteTab = Window:CreateTab("Auto Favorite")

    local removePlantsTab = Window:CreateTab("Remove Plants")

    local informationTab = Window:CreateTab("Info")

    local collectFruitsButton = mainTab:CreateButton({
        Name = "Collect All Plants (even if not fully grown)",
        Callback = function()
            garden:collectAllPlants()
        end,
    })

    local instantHarvestAuraToggle = mainTab:CreateToggle({
        Name = "Instant Harvest Aura",
        CurrentValue = false,
        Flag = "instantHarvestAuraToggle",
        Callback = function(Value)
            if Value then
                _G.instantHarvestThread = task.spawn(function()
                    while true do
                        garden:instantHarvestAura()
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
        Callback = function()
            garden:toggleEasterMenu()
        end,
    })

    local toggleDailyQuestsButton = menusTab:CreateButton({
        Name = "Toggle Daily Quests",
        Callback = function()
            garden:toggleDailyQuests()
        end,
    })

    local toggleGearShopButton = menusTab:CreateButton({
        Name = "Toggle Gear Shop",
        Callback = function()
            garden:toggleGearShop()
        end,
    })

    local toggleSeedShopButton = menusTab:CreateButton({
        Name = "Toggle Seed Shop",
        Callback = function()
            garden:toggleSeedShop()
        end,
    })

    local sellInventoryButton = mainTab:CreateButton({
        Name = "Sell Inventory",
        Callback = function()
            garden:sellInventory()
        end,
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
                        garden:autoCollectPlants()
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
                        garden:autoBuySeeds()
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
        Options = garden:listPlantNames(),
        CurrentOption = nil,
        MultipleOptions = true,
        Flag = "autoBuySeedsList",
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
                        garden:autoPlantSeeds()
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
        Options = garden:listPlantNames(),
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
                        while _G.feedingJim do
                            task.wait(0.1)
                        end
                        garden:autoSellPlants()
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
            if not Value then
                Value = 20
            end
            _G.autoSellPlantsAmount = Value
        end,
    })
    _G.autoSellPlantsAmount = 20

    local removePlantsAuraToggle = removePlantsTab:CreateToggle({
        Name = "Remove Plants Aura",
        CurrentValue = false,
        Flag = "removePlantsAuraToggle",
        Callback = function(Value)
            if Value then
                _G.removePlantsAuraTask = task.spawn(function()
                    while true do
                        garden:removePlantsAura()
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

    local removePlantsAuraList = removePlantsTab:CreateDropdown({
        Name = "Remove Plants Aura",
        Options = garden:listPlantNames(),
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

    local backPackEvent = nil
    _G.autoFavoriteWeight = 20
    local autoFavoriteWeight = autoFavoriteTab:CreateSlider({
        Name = "Auto if over X KGs",
        Range = { 0, 100 },
        Increment = 1,
        Suffix = "KGs",
        CurrentValue = 20,
        Flag = "autoFavoriteWeight",
        Callback = function(Value)
            _G.autoFavoriteWeight = Value
        end,
    })

    local autoFavoriteVariance = autoFavoriteTab:CreateDropdown({
        Name = "Auto Favorite Variance",
        Options = { "Normal", "Gold", "Rainbow" },
        CurrentOption = "Rainbow",
        Flag = "autoFavoriteVariance",
        MultipleOptions = true,
        Callback = function(Options)
            _G.autoFavoriteVariance = Options
        end,
    })

    local autoFavoriteToggle = autoFavoriteTab:CreateToggle({
        Name = "Auto Favorite",
        CurrentValue = false,
        Flag = "autoFavoriteToggle",
        Callback = function(Value)
            if Value then
                _G.autoFavoriteTask = task.spawn(function()
                    garden:autoFavorite()
                    backPackEvent = player.Backpack.ChildAdded:Connect(function(child)
                        if child:IsA("Tool") and child:GetAttribute("ITEM_TYPE") == "Holdable" then
                            garden:autoFavorite()
                        end
                    end)
                end)
            else
                if _G.autoFavoriteTask then
                    task.cancel(_G.autoFavoriteTask)
                    _G.autoFavoriteTask = nil
                    backPackEvent:Disconnect()
                end
            end
        end,
    })

    local workspaceEvent = nil
    local autoCollectDroppedSeedToggle = autoFarmTab:CreateToggle({
        Name = "Auto Collect Dropped Seed",
        CurrentValue = false,
        Flag = "autoCollectDroppedSeedToggle",
        Callback = function(Value)
            if Value then
                _G.autoCollectDroppedSeedTask = task.spawn(function()
                    garden:autoCollectDroppedSeed()
                    workspaceEvent = workspace.ChildAdded:Connect(function(child)
                        garden:autoCollectDroppedSeed()
                    end)
                end)
            else
                if _G.autoCollectDroppedSeedTask then
                    task.cancel(_G.autoCollectDroppedSeedTask)
                    _G.autoCollectDroppedSeedTask = nil
                    workspaceEvent:Disconnect()
                end
            end
        end,
    })

    local jimBackpackEvent = nil
    local autoFeedJimToggle = autoFarmTab:CreateToggle({
        Name = "Auto Feed Jim",
        CurrentValue = false,
        Flag = "autoFeedJimToggle",
        Callback = function(Value)
            if Value then
                _G.autoFeedJimTask = task.spawn(function()
                    garden:autoFeedJim()
                    jimBackpackEvent = player.Backpack.ChildAdded:Connect(function(child)
                        if child:IsA("Tool") and child:GetAttribute("ITEM_TYPE") == "Holdable" then
                            garden:autoFeedJim()
                        end
                    end)
                end)
            else
                if _G.autoFeedJimTask then
                    task.cancel(_G.autoFeedJimTask)
                    _G.autoFeedJimTask = nil
                    jimBackpackEvent:Disconnect()
                end
            end
        end,
    })

    local seedPackBackpackEvent = nil
    local autoOpenSeedPackToggle = autoFarmTab:CreateToggle({
        Name = "Auto Open Seed Pack",
        CurrentValue = false,
        Flag = "autoOpenSeedPackToggle",
        Callback = function(Value)
            if Value then
                _G.autoOpenSeedPackTask = task.spawn(function()
                    garden:autoOpenSeedPack()
                    seedPackBackpackEvent = player.Backpack.ChildAdded:Connect(function(child)
                        if child:IsA("Tool") and child:GetAttribute("ITEM_TYPE") == "Seed Pack" then
                            garden:autoOpenSeedPack()
                        end
                    end)
                end)
            else
                if _G.autoOpenSeedPackTask then
                    task.cancel(_G.autoOpenSeedPackTask)
                    _G.autoOpenSeedPackTask = nil
                    seedPackBackpackEvent:Disconnect()
                end
            end
        end,
    })

    local hungryPlantInfo = informationTab:CreateLabel("Hungry Plant Info", 4483362458)
    local hungryPlantDescription = informationTab:CreateParagraph({ Title = "Hungry Plant Needs", Content = "Nil" })

    task.spawn(function()
        while true do
            task.wait(5)
            if garden.jimRequestCache ~= nil then
                hungryPlantDescription:Set({ Title = "Hungry Plant Needs", Content = garden.jimRequestCache })
            end
        end
    end)

    Rayfield:LoadConfiguration()
end
