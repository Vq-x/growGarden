local player = game.Players.LocalPlayer
function collectAllFruits()
   local originalCFrame = CFrame.new(player.Character.HumanoidRootPart.Position)
	for _, Farm in pairs(workspace.Farm:GetChildren()) do
		if Farm.Important.Data.Owner.Value == player.Name then
			for _, plant in pairs(Farm.Important.Plants_Physical:GetChildren()) do
				for _, v in pairs(plant:GetDescendants()) do
					if v:IsA("ProximityPrompt") and v.Enabled == true then
                  player.Character.HumanoidRootPart.CFrame = CFrame.new(v.Parent.CFrame.Position)
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















local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "Tyler's Hub",
   Icon = 0, -- Icon in Topbar. Can use Lucide Icons (string) or Roblox Image (number). 0 to use no icon (default).
   LoadingTitle = "Grow A Garden Script",
   LoadingSubtitle = "by Tyler",
   Theme = "Default", -- Check https://docs.sirius.menu/rayfield/configuration/themes

   DisableRayfieldPrompts = false,
   DisableBuildWarnings = false, -- Prevents Rayfield from warning when the script has a version mismatch with the interface

   ConfigurationSaving = {
      Enabled = true,
      FolderName = nil, -- Create a custom folder for your hub/game
      FileName = "Big Hub"
   },

   Discord = {
      Enabled = false, -- Prompt the user to join your Discord server if their executor supports it
      Invite = "noinvitelink", -- The Discord invite code, do not include discord.gg/. E.g. discord.gg/ ABCD would be ABCD
      RememberJoins = true -- Set this to false to make them join the discord every time they load it up
   },

   KeySystem = false, -- Set this to true to use our key system
   KeySettings = {
      Title = "Untitled",
      Subtitle = "Key System",
      Note = "No method of obtaining the key is provided", -- Use this to tell the user how to get a key
      FileName = "Key", -- It is recommended to use something unique as other scripts using Rayfield may overwrite your key file
      SaveKey = true, -- The user's key will be saved, but if you change the key, they will be unable to use your script
      GrabKeyFromSite = false, -- If this is true, set Key below to the RAW site you would like Rayfield to get the key from
      Key = {"Hello"} -- List of keys that will be accepted by the system, can be RAW file links (pastebin, github etc) or simple strings ("hello","key22")
   }
})

local mainTab = Window:CreateTab("Main")

local collectFruitsButton = mainTab:CreateButton({
	Name = "Collect All Fruit",
	Callback = collectAllFruits
})

local destroyGuiButton = mainTab:CreateButton({
	Name = "Destroy GUI",
	Callback = function()
		Rayfield:Destroy()
	end
})



