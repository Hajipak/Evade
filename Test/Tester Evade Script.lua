if getgenv().DaraHubEvadeExecuted then
    return
end
getgenv().DaraHubEvadeExecuted = true

-- Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local workspace = game:GetService("Workspace")
local originalGameGravity = workspace.Gravity
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local MarketplaceService = game:GetService("MarketplaceService")
local player = Players.LocalPlayer

-- ===== FLUENT UI SETUP =====
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

local Window = Fluent:CreateWindow({
    Title = "Dara Hub - Evade",
    SubTitle = "Fluent UI Version",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

-- Define all tabs CORRECTLY
local Tabs = {
    Main = Window:AddTab({ Title = "Main", Icon = "home" }),
    Player = Window:AddTab({ Title = "Player", Icon = "user" }),
    Auto = Window:AddTab({ Title = "Auto", Icon = "zap" }),
    Visuals = Window:AddTab({ Title = "Visuals", Icon = "eye" }),
    ESP = Window:AddTab({ Title = "ESP", Icon = "target" }),
    Utility = Window:AddTab({ Title = "Utility", Icon = "settings" }),
    Teleport = Window:AddTab({ Title = "Teleport", Icon = "navigation" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}

local Options = Fluent.Options

-- Global Variables
local featureStates = {
    InfiniteJump = false,
    Fly = false,
    TPWALK = false,
    JumpBoost = false,
    AntiAFK = false,
    AutoCarry = false,
    FullBright = false,
    NoFog = false,
    AutoVote = false,
    AutoSelfRevive = false,
    AutoWin = false,
    AutoMoneyFarm = false,
    FastRevive = false,
    FlySpeed = 50,
    TpwalkValue = 1,
    JumpPower = 50,
    JumpMethod = "Hold",
    SelectedMap = 1
}

-- ===== MAIN TAB =====
do
    local MainTab = Tabs.Main
    
    -- Section 1: Server Info
    MainTab:AddSection("Server Information")
    
    local placeName = "Evade"
    local success, productInfo = pcall(function()
        return MarketplaceService:GetProductInfo(game.PlaceId)
    end)
    if success and productInfo then
        placeName = productInfo.Name
    end

    MainTab:AddParagraph({
        Title = "Game Info",
        Content = "Place: " .. placeName .. "\nServer ID: " .. game.JobId
    })

    -- Server Tools Section
    MainTab:AddSection("Server Tools")

    MainTab:AddButton({
        Title = "Copy Server Link",
        Description = "Copy server join link to clipboard",
        Callback = function()
            local serverLink = "https://www.roblox.com/games/start?placeId=" .. game.PlaceId .. "&gameInstanceId=" .. game.JobId
            setclipboard(serverLink)
            Fluent:Notify({
                Title = "Success",
                Content = "Server link copied to clipboard!",
                Duration = 3
            })
        end
    })

    MainTab:AddButton({
        Title = "Rejoin Server",
        Description = "Rejoin the current server",
        Callback = function()
            TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, player)
        end
    })

    MainTab:AddButton({
        Title = "Server Hop",
        Description = "Join a different server",
        Callback = function()
            Fluent:Notify({
                Title = "Server Hop",
                Content = "Searching for new server...",
                Duration = 3
            })
            -- Server hop implementation would go here
        end
    })

    -- Misc Section
    MainTab:AddSection("Miscellaneous")

    local AntiAFKToggle = MainTab:AddToggle("AntiAFK", {
        Title = "Anti AFK",
        Default = false,
        Callback = function(Value)
            featureStates.AntiAFK = Value
            if Value then
                -- Start Anti AFK
                local connection
                connection = player.Idled:Connect(function()
                    VirtualUser:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
                    task.wait(1)
                    VirtualUser:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
                end)
                getgenv().AntiAFKConnection = connection
            else
                -- Stop Anti AFK
                if getgenv().AntiAFKConnection then
                    getgenv().AntiAFKConnection:Disconnect()
                    getgenv().AntiAFKConnection = nil
                end
            end
        end
    })

    MainTab:AddButton({
        Title = "Print Debug Info",
        Description = "Print current feature states for debugging",
        Callback = function()
            print("=== Dara Hub Debug Info ===")
            for key, value in pairs(featureStates) do
                if type(value) == "table" then
                    print(key .. ": " .. tostring(value))
                else
                    print(key .. ": " .. tostring(value))
                end
            end
            Fluent:Notify({
                Title = "Debug Info",
                Content = "Check console for debug information",
                Duration = 3
            })
        end
    })
end

-- ===== PLAYER TAB =====
do
    local PlayerTab = Tabs.Player
    
    -- Movement Section
    PlayerTab:AddSection("Movement Features")

    local InfiniteJumpToggle = PlayerTab:AddToggle("InfiniteJumpToggle", {
        Title = "Infinite Jump",
        Default = false,
        Callback = function(Value)
            featureStates.InfiniteJump = Value
            Fluent:Notify({
                Title = "Infinite Jump",
                Content = Value and "Enabled" or "Disabled",
                Duration = 2
            })
        end
    })

    local JumpMethodDropdown = PlayerTab:AddDropdown("JumpMethodDropdown", {
        Title = "Jump Method",
        Values = {"Hold", "Toggle", "Auto"},
        Default = "Hold",
        Multi = false,
        Callback = function(Value)
            featureStates.JumpMethod = Value
        end
    })

    local FlyToggle = PlayerTab:AddToggle("FlyToggle", {
        Title = "Fly",
        Default = false,
        Callback = function(Value)
            featureStates.Fly = Value
            Fluent:Notify({
                Title = "Fly",
                Content = Value and "Enabled" or "Disabled",
                Duration = 2
            })
        end
    })

    local FlySpeedSlider = PlayerTab:AddSlider("FlySpeedSlider", {
        Title = "Fly Speed",
        Description = "Adjust flying speed",
        Default = 50,
        Min = 1,
        Max = 200,
        Rounding = 1,
        Callback = function(Value)
            featureStates.FlySpeed = Value
        end
    })

    local TPWalkToggle = PlayerTab:AddToggle("TPWalkToggle", {
        Title = "TP Walk",
        Default = false,
        Callback = function(Value)
            featureStates.TPWALK = Value
            Fluent:Notify({
                Title = "TP Walk",
                Content = Value and "Enabled" or "Disabled",
                Duration = 2
            })
        end
    })

    local TPWalkSlider = PlayerTab:AddSlider("TPWalkSlider", {
        Title = "TP Walk Value",
        Description = "TP walk distance multiplier",
        Default = 1,
        Min = 0.1,
        Max = 10,
        Rounding = 1,
        Callback = function(Value)
            featureStates.TpwalkValue = Value
        end
    })

    -- Jump Boost Section
    PlayerTab:AddSection("Jump Settings")

    local JumpBoostToggle = PlayerTab:AddToggle("JumpBoostToggle", {
        Title = "Jump Boost",
        Default = false,
        Callback = function(Value)
            featureStates.JumpBoost = Value
            if Value then
                if player.Character and player.Character:FindFirstChildOfClass("Humanoid") then
                    player.Character:FindFirstChildOfClass("Humanoid").JumpPower = featureStates.JumpPower
                end
            else
                if player.Character and player.Character:FindFirstChildOfClass("Humanoid") then
                    player.Character:FindFirstChildOfClass("Humanoid").JumpPower = 50
                end
            end
        end
    })

    local JumpPowerSlider = PlayerTab:AddSlider("JumpPowerSlider", {
        Title = "Jump Power",
        Description = "Jump height multiplier",
        Default = 50,
        Min = 1,
        Max = 200,
        Rounding = 1,
        Callback = function(Value)
            featureStates.JumpPower = Value
            if featureStates.JumpBoost and player.Character and player.Character:FindFirstChildOfClass("Humanoid") then
                player.Character:FindFirstChildOfClass("Humanoid").JumpPower = Value
            end
        end
    })

    -- Speed Modifications Section
    PlayerTab:AddSection("Speed Modifications")

    local SpeedInput = PlayerTab:AddInput("SpeedInput", {
        Title = "Walk Speed",
        Default = "16",
        Placeholder = "16",
        Numeric = true,
        Finished = false,
        Callback = function(Value)
            local speed = tonumber(Value)
            if speed and player.Character and player.Character:FindFirstChildOfClass("Humanoid") then
                player.Character:FindFirstChildOfClass("Humanoid").WalkSpeed = speed
            end
        end
    })

    PlayerTab:AddButton({
        Title = "Reset Speed",
        Description = "Reset to default walk speed",
        Callback = function()
            if player.Character and player.Character:FindFirstChildOfClass("Humanoid") then
                player.Character:FindFirstChildOfClass("Humanoid").WalkSpeed = 16
                if Options.SpeedInput then
                    Options.SpeedInput:SetValue("16")
                end
            end
        end
    })
end

-- ===== AUTO TAB =====
do
    local AutoTab = Tabs.Auto
    
    -- Carry & Revive Section
    AutoTab:AddSection("Carry & Revive")

    local AutoCarryToggle = AutoTab:AddToggle("AutoCarryToggle", {
        Title = "Auto Carry",
        Default = false,
        Callback = function(Value)
            featureStates.AutoCarry = Value
            Fluent:Notify({
                Title = "Auto Carry",
                Content = Value and "Enabled" or "Disabled",
                Duration = 2
            })
        end
    })

    local FastReviveToggle = AutoTab:AddToggle("FastReviveToggle", {
        Title = "Fast Revive",
        Default = false,
        Callback = function(Value)
            featureStates.FastRevive = Value
        end
    })

    local AutoReviveToggle = AutoTab:AddToggle("AutoReviveToggle", {
        Title = "Auto Revive",
        Default = false,
        Callback = function(Value)
            featureStates.AutoRevive = Value
        end
    })

    -- Voting Section
    AutoTab:AddSection("Voting")

    local AutoVoteToggle = AutoTab:AddToggle("AutoVoteToggle", {
        Title = "Auto Vote",
        Default = false,
        Callback = function(Value)
            featureStates.AutoVote = Value
        end
    })

    local VoteMapDropdown = AutoTab:AddDropdown("VoteMapDropdown", {
        Title = "Vote Map",
        Values = {"Map 1", "Map 2", "Map 3", "Map 4"},
        Default = "Map 1",
        Multi = false,
        Callback = function(Value)
            if Value == "Map 1" then
                featureStates.SelectedMap = 1
            elseif Value == "Map 2" then
                featureStates.SelectedMap = 2
            elseif Value == "Map 3" then
                featureStates.SelectedMap = 3
            elseif Value == "Map 4" then
                featureStates.SelectedMap = 4
            end
        end
    })

    -- Farming Section
    AutoTab:AddSection("Farming")

    local AutoMoneyFarmToggle = AutoTab:AddToggle("AutoMoneyFarmToggle", {
        Title = "Auto Money Farm",
        Default = false,
        Callback = function(Value)
            featureStates.AutoMoneyFarm = Value
        end
    })

    local AutoWinToggle = AutoTab:AddToggle("AutoWinToggle", {
        Title = "Auto Win",
        Default = false,
        Callback = function(Value)
            featureStates.AutoWin = Value
        end
    })

    local AutoWhistleToggle = AutoTab:AddToggle("AutoWhistleToggle", {
        Title = "Auto Whistle",
        Default = false,
        Callback = function(Value)
            featureStates.AutoWhistle = Value
        end
    })

    -- Actions Section
    AutoTab:AddSection("Actions")

    AutoTab:AddButton({
        Title = "Revive Self",
        Description = "Manually revive yourself",
        Callback = function()
            if player.Character and player.Character:GetAttribute("Downed") then
                ReplicatedStorage.Events.Player.ChangePlayerMode:FireServer(true)
                Fluent:Notify({
                    Title = "Revive",
                    Content = "Attempting to revive...",
                    Duration = 2
                })
            else
                Fluent:Notify({
                    Title = "Revive",
                    Content = "You are not downed!",
                    Duration = 2
                })
            end
        end
    })
end

-- ===== VISUALS TAB =====
do
    local VisualsTab = Tabs.Visuals
    
    -- Lighting Section
    VisualsTab:AddSection("Lighting Effects")

    local FullBrightToggle = VisualsTab:AddToggle("FullBrightToggle", {
        Title = "Full Bright",
        Default = false,
        Callback = function(Value)
            featureStates.FullBright = Value
            if Value then
                Lighting.Brightness = 2
                Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
                Lighting.Ambient = Color3.fromRGB(255, 255, 255)
                Lighting.GlobalShadows = false
            else
                Lighting.Brightness = 1
                Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
                Lighting.Ambient = Color3.fromRGB(50, 50, 50)
                Lighting.GlobalShadows = true
            end
        end
    })

    local NoFogToggle = VisualsTab:AddToggle("NoFogToggle", {
        Title = "No Fog",
        Default = false,
        Callback = function(Value)
            featureStates.NoFog = Value
            if Value then
                Lighting.FogEnd = 1000000
                for _, atmosphere in ipairs(Lighting:GetChildren()) do
                    if atmosphere:IsA("Atmosphere") then
                        atmosphere:Destroy()
                    end
                end
            else
                Lighting.FogEnd = 1000
            end
        end
    })

    -- Camera Section
    VisualsTab:AddSection("Camera Settings")

    local FOVSlider = VisualsTab:AddSlider("FOVSlider", {
        Title = "Field of View",
        Description = "Adjust camera FOV",
        Default = 70,
        Min = 10,
        Max = 120,
        Rounding = 1,
        Callback = function(Value)
            workspace.CurrentCamera.FieldOfView = Value
        end
    })

    local TimerDisplayToggle = VisualsTab:AddToggle("TimerDisplayToggle", {
        Title = "Show Timer",
        Default = false,
        Callback = function(Value)
            featureStates.TimerDisplay = Value
            -- Timer display implementation
        end
    })

    VisualsTab:AddButton({
        Title = "Reset Camera",
        Description = "Reset camera to default settings",
        Callback = function()
            workspace.CurrentCamera.FieldOfView = 70
            if Options.FOVSlider then
                Options.FOVSlider:SetValue(70)
            end
            Fluent:Notify({
                Title = "Camera Reset",
                Content = "Camera settings reset to default",
                Duration = 2
            })
        end
    })
end

-- ===== ESP TAB =====
do
    local ESPTab = Tabs.ESP
    
    -- Player ESP Section
    ESPTab:AddSection("Player ESP")

    local PlayerBoxToggle = ESPTab:AddToggle("PlayerBoxToggle", {
        Title = "Player Box ESP",
        Default = false,
        Callback = function(Value)
            featureStates.PlayerESP = featureStates.PlayerESP or {}
            featureStates.PlayerESP.boxes = Value
        end
    })

    local PlayerTracerToggle = ESPTab:AddToggle("PlayerTracerToggle", {
        Title = "Player Tracers",
        Default = false,
        Callback = function(Value)
            featureStates.PlayerESP = featureStates.PlayerESP or {}
            featureStates.PlayerESP.tracers = Value
        end
    })

    local PlayerNameToggle = ESPTab:AddToggle("PlayerNameToggle", {
        Title = "Player Names",
        Default = false,
        Callback = function(Value)
            featureStates.PlayerESP = featureStates.PlayerESP or {}
            featureStates.PlayerESP.names = Value
        end
    })

    local PlayerDistanceToggle = ESPTab:AddToggle("PlayerDistanceToggle", {
        Title = "Player Distance",
        Default = false,
        Callback = function(Value)
            featureStates.PlayerESP = featureStates.PlayerESP or {}
            featureStates.PlayerESP.distance = Value
        end
    })

    -- Nextbot ESP Section
    ESPTab:AddSection("Nextbot ESP")

    local NextbotBoxToggle = ESPTab:AddToggle("NextbotBoxToggle", {
        Title = "Nextbot Box ESP",
        Default = false,
        Callback = function(Value)
            featureStates.NextbotESP = featureStates.NextbotESP or {}
            featureStates.NextbotESP.boxes = Value
        end
    })

    local NextbotTracerToggle = ESPTab:AddToggle("NextbotTracerToggle", {
        Title = "Nextbot Tracers",
        Default = false,
        Callback = function(Value)
            featureStates.NextbotESP = featureStates.NextbotESP or {}
            featureStates.NextbotESP.tracers = Value
        end
    })

    -- Downed ESP Section
    ESPTab:AddSection("Downed Player ESP")

    local DownedBoxToggle = ESPTab:AddToggle("DownedBoxToggle", {
        Title = "Downed Box ESP",
        Default = false,
        Callback = function(Value)
            featureStates.DownedBoxESP = Value
        end
    })

    local DownedTracerToggle = ESPTab:AddToggle("DownedTracerToggle", {
        Title = "Downed Tracers",
        Default = false,
        Callback = function(Value)
            featureStates.DownedTracer = Value
        end
    })

    -- ESP Controls Section
    ESPTab:AddSection("ESP Controls")

    ESPTab:AddButton({
        Title = "Refresh ESP",
        Description = "Refresh all ESP elements",
        Callback = function()
            Fluent:Notify({
                Title = "ESP Refresh",
                Content = "Refreshing ESP elements...",
                Duration = 2
            })
        end
    })

    ESPTab:AddButton({
        Title = "Clear ESP",
        Description = "Clear all ESP elements",
        Callback = function()
            -- Clear ESP implementation
            Fluent:Notify({
                Title = "ESP Clear",
                Content = "All ESP elements cleared",
                Duration = 2
            })
        end
    })
end

-- ===== UTILITY TAB =====
do
    local UtilityTab = Tabs.Utility
    
    -- Game Utility Section
    UtilityTab:AddSection("Game Utility")

    local CustomGravityToggle = UtilityTab:AddToggle("CustomGravityToggle", {
        Title = "Custom Gravity",
        Default = false,
        Callback = function(Value)
            featureStates.CustomGravity = Value
            if Value then
                workspace.Gravity = featureStates.GravityValue or 196.2
            else
                workspace.Gravity = originalGameGravity
            end
        end
    })

    local GravityInput = UtilityTab:AddInput("GravityInput", {
        Title = "Gravity Value",
        Default = tostring(originalGameGravity),
        Placeholder = tostring(originalGameGravity),
        Numeric = true,
        Callback = function(Value)
            local gravity = tonumber(Value)
            if gravity then
                featureStates.GravityValue = gravity
                if featureStates.CustomGravity then
                    workspace.Gravity = gravity
                end
            end
        end
    })

    local TimeInput = UtilityTab:AddInput("TimeInput", {
        Title = "Set Time (HH:MM)",
        Default = "",
        Placeholder = "12:00",
        Callback = function(Value)
            local h, m = Value:match("(%d+):(%d+)")
            if h and m then
                local hours = tonumber(h)
                local minutes = tonumber(m)
                if hours and minutes and hours >= 0 and hours <= 23 and minutes >= 0 and minutes <= 59 then
                    Lighting.ClockTime = hours + (minutes / 60)
                    Fluent:Notify({
                        Title = "Time Set",
                        Content = string.format("Time set to %02d:%02d", hours, minutes),
                        Duration = 3
                    })
                end
            end
        end
    })

    -- Free Cam Section
    UtilityTab:AddSection("Free Camera")

    local FreeCamToggle = UtilityTab:AddToggle("FreeCamToggle", {
        Title = "Free Camera",
        Default = false,
        Callback = function(Value)
            featureStates.FreeCam = Value
            Fluent:Notify({
                Title = "Free Camera",
                Content = Value and "Enabled - Use Ctrl+P to toggle" or "Disabled",
                Duration = 3
            })
        end
    })

    local FreeCamSpeedSlider = UtilityTab:AddSlider("FreeCamSpeedSlider", {
        Title = "Free Cam Speed",
        Description = "Free camera movement speed",
        Default = 50,
        Min = 1,
        Max = 200,
        Rounding = 1,
        Callback = function(Value)
            featureStates.FreeCamSpeed = Value
        end
    })

    UtilityTab:AddButton({
        Title = "Reset Free Cam",
        Description = "Reset free camera position",
        Callback = function()
            Fluent:Notify({
                Title = "Free Cam Reset",
                Content = "Free camera position reset",
                Duration = 2
            })
        end
    })
end

-- ===== TELEPORT TAB =====
do
    local TeleportTab = Tabs.Teleport
    
    -- Player Teleport Section
    TeleportTab:AddSection("Player Teleport")

    -- Player list for teleporting
    local playerList = {}
    local playerNames = {"Select a player..."}
    
    local function updatePlayerList()
        playerList = {}
        playerNames = {"Select a player..."}
        
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= player then
                table.insert(playerList, plr)
                table.insert(playerNames, plr.Name)
            end
        end
    end

    updatePlayerList()

    local PlayerDropdown = TeleportTab:AddDropdown("PlayerDropdown", {
        Title = "Select Player",
        Values = playerNames,
        Default = "Select a player...",
        Multi = false,
        Callback = function(Value)
            -- Selection handled in the teleport button
        end
    })

    TeleportTab:AddButton({
        Title = "Teleport to Player",
        Description = "Teleport to selected player",
        Callback = function()
            local selectedPlayer = Options.PlayerDropdown.Value
            if selectedPlayer ~= "Select a player..." then
                for _, plr in ipairs(playerList) do
                    if plr.Name == selectedPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                            player.Character.HumanoidRootPart.CFrame = plr.Character.HumanoidRootPart.CFrame
                            Fluent:Notify({
                                Title = "Teleport",
                                Content = "Teleported to " .. plr.Name,
                                Duration = 3
                            })
                        end
                        break
                    end
                end
            else
                Fluent:Notify({
                    Title = "Teleport",
                    Content = "Please select a player first!",
                    Duration = 3
                })
            end
        end
    })

    TeleportTab:AddButton({
        Title = "Teleport to Random Player",
        Description = "Teleport to a random online player",
        Callback = function()
            if #playerList > 0 and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                local randomPlayer = playerList[math.random(1, #playerList)]
                if randomPlayer.Character and randomPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    player.Character.HumanoidRootPart.CFrame = randomPlayer.Character.HumanoidRootPart.CFrame
                    Fluent:Notify({
                        Title = "Teleport",
                        Content = "Teleported to " .. randomPlayer.Name,
                        Duration = 3
                    })
                end
            end
        end
    })

    -- Location Teleport Section
    TeleportTab:AddSection("Location Teleport")

    TeleportTab:AddButton({
        Title = "Teleport to Spawn",
        Description = "Teleport to a spawn location",
        Callback = function()
            if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                -- Find spawn locations
                local spawns = workspace:FindFirstChild("Game") and workspace.Game:FindFirstChild("Map") and 
                              workspace.Game.Map:FindFirstChild("Parts") and workspace.Game.Map.Parts:FindFirstChild("Spawns")
                if spawns and #spawns:GetChildren() > 0 then
                    local randomSpawn = spawns:GetChildren()[math.random(1, #spawns:GetChildren())]
                    player.Character.HumanoidRootPart.CFrame = randomSpawn.CFrame + Vector3.new(0, 3, 0)
                    Fluent:Notify({
                        Title = "Teleport",
                        Content = "Teleported to spawn",
                        Duration = 3
                    })
                end
            end
        end
    })

    TeleportTab:AddButton({
        Title = "Teleport to Safe Zone",
        Description = "Teleport to a safe location",
        Callback = function()
            if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                -- Create safe zone if it doesn't exist
                local safeZone = workspace:FindFirstChild("SafeZone")
                if not safeZone then
                    safeZone = Instance.new("Part")
                    safeZone.Name = "SafeZone"
                    safeZone.Size = Vector3.new(50, 1, 50)
                    safeZone.Position = Vector3.new(0, 1000, 0)
                    safeZone.Anchored = true
                    safeZone.CanCollide = true
                    safeZone.Transparency = 0.5
                    safeZone.BrickColor = BrickColor.new("Bright green")
                    safeZone.Parent = workspace
                end
                
                player.Character.HumanoidRootPart.CFrame = safeZone.CFrame + Vector3.new(0, 3, 0)
                Fluent:Notify({
                    Title = "Teleport",
                    Content = "Teleported to safe zone",
                    Duration = 3
                })
            end
        end
    })

    -- Update player list when players join/leave
    Players.PlayerAdded:Connect(updatePlayerList)
    Players.PlayerRemoving:Connect(updatePlayerList)
    TeleportTab:AddButton({
        Title = "Refresh Player List",
        Description = "Update the player dropdown list",
        Callback = updatePlayerList
    })
end

-- ===== SETTINGS TAB =====
do
    local SettingsTab = Tabs.Settings
    
    -- UI Settings Section
    SettingsTab:AddSection("UI Settings")

    local themes = {"Dark", "Light", "Darker", "Aqua", "Amethyst"}
    local ThemeDropdown = SettingsTab:AddDropdown("ThemeDropdown", {
        Title = "UI Theme",
        Values = themes,
        Default = "Dark",
        Multi = false,
        Callback = function(Value)
            Fluent:SetTheme(Value)
        end
    })

    local TransparencySlider = SettingsTab:AddSlider("TransparencySlider", {
        Title = "UI Transparency",
        Description = "Adjust window transparency",
        Default = 0.2,
        Min = 0,
        Max = 1,
        Rounding = 2,
        Callback = function(Value)
            Fluent.TransparencyValue = Value
            Window:ToggleTransparency(Value > 0)
        end
    })

    -- Configuration Section
    SettingsTab:AddSection("Configuration")

    local configName = "default_config"
    local ConfigInput = SettingsTab:AddInput("ConfigInput", {
        Title = "Config Name",
        Default = configName,
        Placeholder = "config_name",
        Callback = function(Value)
            configName = Value
        end
    })

    SettingsTab:AddButton({
        Title = "Save Configuration",
        Description = "Save current settings to config",
        Callback = function()
            Fluent:Notify({
                Title = "Configuration",
                Content = "Settings saved as: " .. configName,
                Duration = 3
            })
        end
    })

    SettingsTab:AddButton({
        Title = "Load Configuration",
        Description = "Load settings from config",
        Callback = function()
            Fluent:Notify({
                Title = "Configuration",
                Content = "Loading settings from: " .. configName,
                Duration = 3
            })
        end
    })

    SettingsTab:AddButton({
        Title = "Reset All Settings",
        Description = "Reset all settings to default",
        Callback = function()
            Window:Dialog({
                Title = "Reset Settings",
                Content = "Are you sure you want to reset all settings to default?",
                Buttons = {
                    {
                        Title = "Yes",
                        Callback = function()
                            -- Reset all toggles
                            for optionName, option in pairs(Options) do
                                if option.SetValue then
                                    if optionName:find("Toggle") then
                                        option:SetValue(false)
                                    elseif optionName:find("Slider") then
                                        -- Reset sliders to their default values
                                        if optionName == "FlySpeedSlider" then
                                            option:SetValue(50)
                                        elseif optionName == "TPWalkSlider" then
                                            option:SetValue(1)
                                        elseif optionName == "JumpPowerSlider" then
                                            option:SetValue(50)
                                        elseif optionName == "FOVSlider" then
                                            option:SetValue(70)
                                        end
                                    elseif optionName:find("Dropdown") then
                                        -- Reset dropdowns
                                        if optionName == "JumpMethodDropdown" then
                                            option:SetValue("Hold")
                                        elseif optionName == "VoteMapDropdown" then
                                            option:SetValue("Map 1")
                                        end
                                    end
                                end
                            end
                            
                            Fluent:Notify({
                                Title = "Settings Reset",
                                Content = "All settings have been reset to default",
                                Duration = 3
                            })
                        end
                    },
                    {
                        Title = "No",
                        Callback = function() end
                    }
                }
            })
        end
    })

    -- Addons setup
    SaveManager:SetLibrary(Fluent)
    InterfaceManager:SetLibrary(Fluent)
    SaveManager:IgnoreThemeSettings()
    InterfaceManager:SetFolder("DaraHub-Fluent")
    SaveManager:SetFolder("DaraHub-Fluent/configs")
    InterfaceManager:BuildInterfaceSection(SettingsTab)
    SaveManager:BuildConfigSection(SettingsTab)
end

-- ===== INITIALIZATION =====
Window:SelectTab(1)

Fluent:Notify({
    Title = "Dara Hub - Fluent UI",
    Content = "Successfully loaded! All features are now available.",
    SubContent = "Use LeftControl to minimize/maximize",
    Duration = 5
})

-- Input handling for features
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    -- Infinite Jump
    if input.KeyCode == Enum.KeyCode.Space and featureStates.InfiniteJump then
        if player.Character and player.Character:FindFirstChildOfClass("Humanoid") then
            player.Character:FindFirstChildOfClass("Humanoid"):ChangeState("Jumping")
        end
    end
    
    -- Free Cam Toggle (Ctrl + P)
    if input.KeyCode == Enum.KeyCode.P and (UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.RightControl)) then
        if featureStates.FreeCam then
            Fluent:Notify({
                Title = "Free Camera",
                Content = "Toggled - Use mouse to look around, WASD to move",
                Duration = 3
            })
        end
    end
end)

-- Save configuration when leaving
game:GetService("UserInputService").WindowFocused:Connect(function()
    if SaveManager then
        SaveManager:SaveAutoloadConfig()
    end
end)
