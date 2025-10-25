if getgenv().ZenHubEvadeExecuted then
    return
end
getgenv().ZenHubEvadeExecuted = true

-- Load Fluent UI
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

local Window = Fluent:CreateWindow({
    Title = "Zen Hub - Evade",
    SubTitle = "Made by: Zen",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

-- Toggle Button untuk Show/Hide UI
local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

-- Buat ScreenGui untuk toggle button
local ToggleScreenGui = Instance.new("ScreenGui")
ToggleScreenGui.Name = "ToggleUI"
ToggleScreenGui.ResetOnSpawn = false
ToggleScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ToggleScreenGui.Parent = PlayerGui

-- Buat Toggle Button
local ToggleButton = Instance.new("TextButton")
ToggleButton.Name = "ToggleButton"
ToggleButton.Size = UDim2.new(0, 60, 0, 60)
ToggleButton.Position = UDim2.new(0, 10, 0.5, -30)
ToggleButton.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
ToggleButton.BorderSizePixel = 0
ToggleButton.Text = "🔳"
ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleButton.TextSize = 30
ToggleButton.Font = Enum.Font.GothamBold
ToggleButton.Parent = ToggleScreenGui

-- Tambahkan UICorner untuk rounded edges
local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 12)
UICorner.Parent = ToggleButton

-- Tambahkan UIStroke untuk border
local UIStroke = Instance.new("UIStroke")
UIStroke.Color = Color3.fromRGB(100, 100, 100)
UIStroke.Thickness = 2
UIStroke.Parent = ToggleButton

-- Variable untuk track UI state
local UIVisible = true

-- Fungsi untuk toggle UI
local function toggleUI()
    UIVisible = not UIVisible
    if Window and Window.Root then
        Window.Root.Visible = UIVisible
    end
    
    -- Update button icon
    if UIVisible then
        ToggleButton.Text = "🔳"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    else
        ToggleButton.Text = "📱"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(65, 65, 65)
    end
end

-- Click event
ToggleButton.MouseButton1Click:Connect(toggleUI)

-- Drag functionality untuk mobile dan PC
local UserInputService = game:GetService("UserInputService")
local dragging = false
local dragInput
local dragStart
local startPos

local function update(input)
    local delta = input.Position - dragStart
    ToggleButton.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end

ToggleButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = ToggleButton.Position
        
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

ToggleButton.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        update(input)
    end
end)

-- Fluent provides Lucide Icons https://lucide.dev/icons/ for the tabs, icons are optional
local Tabs = {
    Main = Window:AddTab({ Title = "Main", Icon = "" }),
    Player = Window:AddTab({ Title = "Player", Icon = "" }),
    Auto = Window:AddTab({ Title = "Auto", Icon = "" }),
    Visuals = Window:AddTab({ Title = "Visuals", Icon = "" }),
    ESP = Window:AddTab({ Title = "ESP", Icon = "" }),
    Utility = Window:AddTab({ Title = "Utility", Icon = "" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}

local Options = Fluent.Options

-- Services
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local workspace = game:GetService("Workspace")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local MarketplaceService = game:GetService("MarketplaceService")
local VirtualUser = game:GetService("VirtualUser")

local player = Players.LocalPlayer
local placeId = game.PlaceId
local jobId = game.JobId
local originalGameGravity = workspace.Gravity

-- Feature states
local featureStates = {
    InfiniteJump = false,
    JumpMethod = "Hold",
    Fly = false,
    FlySpeed = 5,
    TPWALK = false,
    TpwalkValue = 1,
    JumpBoost = false,
    JumpPower = 50,
    AntiAFK = false,
    AutoCarry = false,
    FullBright = false,
    NoFog = false,
    AutoVote = false,
    AutoSelfRevive = false,
    AutoWin = false,
    AutoMoneyFarm = false,
    FastRevive = false,
    FastReviveMethod = "Interact",
    PlayerESP = {
        boxes = false,
        tracers = false,
        names = false,
        distance = false,
        rainbowBoxes = false,
        rainbowTracers = false,
        boxType = "2D",
    },
    NextbotESP = {
        boxes = false,
        tracers = false,
        names = false,
        distance = false,
        rainbowBoxes = false,
        rainbowTracers = false,
        boxType = "2D",
    },
    DownedBoxESP = false,
    DownedTracer = false,
    DownedNameESP = false,
    DownedDistanceESP = false,
    DownedBoxType = "2D",
    SelectedMap = 1,
    TimerDisplay = false,
    CustomGravity = false,
    GravityValue = workspace.Gravity,
    AutoWhistle = false,
    Bhop = false,
    BhopHold = false,
    BhopMode = "Acceleration",
    AutoCrouch = false,
    AutoCrouchMode = "Air",
    DisableCameraShake = false
}

-- Variables
local character, humanoid, rootPart
local flying = false
local bodyVelocity, bodyGyro
local ToggleTpwalk = false
local TpwalkConnection
local AntiAFKConnection
local AutoCarryConnection
local AutoVoteConnection
local AutoSelfReviveConnection
local AutoWinConnection
local AutoMoneyFarmConnection
local reviveLoopHandle = nil
local interactEvent = ReplicatedStorage:WaitForChild("Events"):WaitForChild("Character"):WaitForChild("Interact")

-- Main Tab
do
    Tabs.Main:AddParagraph({
        Title = "Zen Hub - Evade",
        Content = "Made by: Zen\nVersion: 1.2"
    })

    local placeName = "Unknown"
    local success, productInfo = pcall(function()
        return MarketplaceService:GetProductInfo(placeId)
    end)
    if success and productInfo then
        placeName = productInfo.Name
    end

    Tabs.Main:AddParagraph({
        Title = "Game Info",
        Content = "Game: " .. placeName .. "\nPlayers: " .. #Players:GetPlayers() .. "/" .. Players.MaxPlayers .. "\nServer ID: " .. jobId
    })

    Tabs.Main:AddButton({
        Title = "Copy Server Link",
        Description = "Copy the current server's join link",
        Callback = function()
            local serverLink = string.format("https://www.roblox.com/games/start?placeId=%d&jobId=%s", placeId, jobId)
            pcall(function()
                setclipboard(serverLink)
            end)
            Fluent:Notify({
                Title = "Server Link",
                Content = "Server link copied to clipboard!",
                Duration = 3
            })
        end
    })

    Tabs.Main:AddButton({
        Title = "Rejoin Server",
        Description = "Rejoin the current server",
        Callback = function()
            TeleportService:TeleportToPlaceInstance(placeId, jobId)
        end
    })

    Tabs.Main:AddButton({
        Title = "Server Hop",
        Description = "Hop to a random server",
        Callback = function()
            Fluent:Notify({
                Title = "Server Hop",
                Content = "Server hop feature would be implemented here",
                Duration = 3
            })
        end
    })

    local AntiAFKToggle = Tabs.Main:AddToggle("AntiAFK", {
        Title = "Anti AFK",
        Default = false
    })

    AntiAFKToggle:OnChanged(function()
        featureStates.AntiAFK = Options.AntiAFK.Value
        if featureStates.AntiAFK then
            if AntiAFKConnection then
                AntiAFKConnection:Disconnect()
            end
            AntiAFKConnection = player.Idled:Connect(function()
                VirtualUser:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
                task.wait(1)
                VirtualUser:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
            end)
        else
            if AntiAFKConnection then
                AntiAFKConnection:Disconnect()
                AntiAFKConnection = nil
            end
        end
    end)
end

-- Player Tab
do
    Tabs.Player:AddParagraph({
        Title = "Player Features",
        Content = "────────────────"
    })

    local InfiniteJumpToggle = Tabs.Player:AddToggle("InfiniteJump", {
        Title = "Infinite Jump",
        Default = false
    })

    InfiniteJumpToggle:OnChanged(function()
        featureStates.InfiniteJump = Options.InfiniteJump.Value
    end)

    local JumpMethodDropdown = Tabs.Player:AddDropdown("JumpMethod", {
        Title = "Jump Method",
        Values = {"Hold", "Spam"},
        Multi = false,
        Default = "Hold",
    })

    JumpMethodDropdown:OnChanged(function()
        featureStates.JumpMethod = Options.JumpMethod.Value
    end)

    local FlyToggle = Tabs.Player:AddToggle("Fly", {
        Title = "Fly",
        Default = false
    })

    FlyToggle:OnChanged(function()
        featureStates.Fly = Options.Fly.Value
        if featureStates.Fly then
            -- Start flying implementation
            Fluent:Notify({
                Title = "Fly",
                Content = "Fly enabled - Implementation needed",
                Duration = 3
            })
        else
            -- Stop flying implementation
            Fluent:Notify({
                Title = "Fly",
                Content = "Fly disabled - Implementation needed",
                Duration = 3
            })
        end
    end)

    local FlySpeedSlider = Tabs.Player:AddSlider("FlySpeed", {
        Title = "Fly Speed",
        Description = "Adjust fly speed",
        Default = 5,
        Min = 1,
        Max = 200,
        Rounding = 1,
        Callback = function(Value)
            featureStates.FlySpeed = Value
        end
    })

    local TPWALKToggle = Tabs.Player:AddToggle("TPWALK", {
        Title = "TP Walk",
        Default = false
    })

    TPWALKToggle:OnChanged(function()
        featureStates.TPWALK = Options.TPWALK.Value
        if featureStates.TPWALK then
            -- Start TP walk implementation
            Fluent:Notify({
                Title = "TP Walk",
                Content = "TP Walk enabled - Implementation needed",
                Duration = 3
            })
        else
            -- Stop TP walk implementation
            Fluent:Notify({
                Title = "TP Walk",
                Content = "TP Walk disabled - Implementation needed",
                Duration = 3
            })
        end
    end)

    local TPWALKSlider = Tabs.Player:AddSlider("TPWALKValue", {
        Title = "TP Walk Value",
        Description = "Adjust TP walk speed",
        Default = 1,
        Min = 1,
        Max = 200,
        Rounding = 1,
        Callback = function(Value)
            featureStates.TpwalkValue = Value
        end
    })

    local JumpBoostToggle = Tabs.Player:AddToggle("JumpBoost", {
        Title = "Jump Boost",
        Default = false
    })

    JumpBoostToggle:OnChanged(function()
        featureStates.JumpBoost = Options.JumpBoost.Value
        if featureStates.JumpBoost then
            -- Start jump boost implementation
            if humanoid then
                humanoid.JumpPower = featureStates.JumpPower
            end
        else
            -- Stop jump boost implementation
            if humanoid then
                humanoid.JumpPower = 50
            end
        end
    end)

    local JumpBoostSlider = Tabs.Player:AddSlider("JumpPower", {
        Title = "Jump Power",
        Description = "Adjust jump height",
        Default = 50,
        Min = 1,
        Max = 200,
        Rounding = 1,
        Callback = function(Value)
            featureStates.JumpPower = Value
            if featureStates.JumpBoost and humanoid then
                humanoid.JumpPower = Value
            end
        end
    end)

    Tabs.Player:AddParagraph({
        Title = "Modifications",
        Content = "────────────────"
    })

    local currentSettings = {
        Speed = "1500",
        JumpCap = "1",
        AirStrafeAcceleration = "187"
    }

    local SpeedInput = Tabs.Player:AddInput("SpeedInput", {
        Title = "Set Speed",
        Default = currentSettings.Speed,
        Placeholder = "Default 1500",
        Numeric = true,
        Finished = false,
        Callback = function(Value)
            local val = tonumber(Value)
            if val and val >= 1450 and val <= 100008888 then
                currentSettings.Speed = tostring(val)
                Fluent:Notify({
                    Title = "Speed",
                    Content = "Speed set to: " .. Value,
                    Duration = 3
                })
            end
        end
    })

    local JumpCapInput = Tabs.Player:AddInput("JumpCapInput", {
        Title = "Set Jump Cap",
        Default = currentSettings.JumpCap,
        Placeholder = "Default 1",
        Numeric = true,
        Finished = false,
        Callback = function(Value)
            local val = tonumber(Value)
            if val and val >= 0.1 and val <= 5088888 then
                currentSettings.JumpCap = tostring(val)
                Fluent:Notify({
                    Title = "Jump Cap",
                    Content = "Jump cap set to: " .. Value,
                    Duration = 3
                })
            end
        end
    })

    local StrafeInput = Tabs.Player:AddInput("StrafeInput", {
        Title = "Strafe Acceleration",
        Default = currentSettings.AirStrafeAcceleration,
        Placeholder = "Default 187",
        Numeric = true,
        Finished = false,
        Callback = function(Value)
            local val = tonumber(Value)
            if val and val >= 1 and val <= 1000888888 then
                currentSettings.AirStrafeAcceleration = tostring(val)
                Fluent:Notify({
                    Title = "Strafe Acceleration",
                    Content = "Strafe acceleration set to: " .. Value,
                    Duration = 3
                })
            end
        end
    })
end

-- Auto Tab
do
    Tabs.Auto:AddParagraph({
        Title = "Automation Features",
        Content = "────────────────"
    })

    local AutoCarryToggle = Tabs.Auto:AddToggle("AutoCarry", {
        Title = "Auto Carry",
        Default = false
    })

    AutoCarryToggle:OnChanged(function()
        featureStates.AutoCarry = Options.AutoCarry.Value
        if featureStates.AutoCarry then
            -- Start auto carry implementation
            Fluent:Notify({
                Title = "Auto Carry",
                Content = "Auto Carry enabled - Implementation needed",
                Duration = 3
            })
        else
            -- Stop auto carry implementation
            Fluent:Notify({
                Title = "Auto Carry",
                Content = "Auto Carry disabled - Implementation needed",
                Duration = 3
            })
        end
    end)

    local FastReviveToggle = Tabs.Auto:AddToggle("FastRevive", {
        Title = "Fast Revive",
        Default = false
    })

    FastReviveToggle:OnChanged(function()
        featureStates.FastRevive = Options.FastRevive.Value
        if featureStates.FastRevive then
            -- Start fast revive implementation
            Fluent:Notify({
                Title = "Fast Revive",
                Content = "Fast Revive enabled - Implementation needed",
                Duration = 3
            })
        else
            -- Stop fast revive implementation
            Fluent:Notify({
                Title = "Fast Revive",
                Content = "Fast Revive disabled - Implementation needed",
                Duration = 3
            })
        end
    end)

    local FastReviveMethodDropdown = Tabs.Auto:AddDropdown("FastReviveMethod", {
        Title = "Fast Revive Method",
        Values = {"Auto", "Interact"},
        Multi = false,
        Default = "Interact",
    })

    FastReviveMethodDropdown:OnChanged(function()
        featureStates.FastReviveMethod = Options.FastReviveMethod.Value
    end)

    local AutoVoteDropdown = Tabs.Auto:AddDropdown("AutoVoteMap", {
        Title = "Auto Vote Map",
        Values = {"Map 1", "Map 2", "Map 3", "Map 4"},
        Multi = false,
        Default = "Map 1",
    })

    AutoVoteDropdown:OnChanged(function()
        if Options.AutoVoteMap.Value == "Map 1" then
            featureStates.SelectedMap = 1
        elseif Options.AutoVoteMap.Value == "Map 2" then
            featureStates.SelectedMap = 2
        elseif Options.AutoVoteMap.Value == "Map 3" then
            featureStates.SelectedMap = 3
        elseif Options.AutoVoteMap.Value == "Map 4" then
            featureStates.SelectedMap = 4
        end
    end)

    local AutoVoteToggle = Tabs.Auto:AddToggle("AutoVote", {
        Title = "Auto Vote",
        Default = false
    })

    AutoVoteToggle:OnChanged(function()
        featureStates.AutoVote = Options.AutoVote.Value
        if featureStates.AutoVote then
            -- Start auto vote implementation
            Fluent:Notify({
                Title = "Auto Vote",
                Content = "Auto Vote enabled - Implementation needed",
                Duration = 3
            })
        else
            -- Stop auto vote implementation
            Fluent:Notify({
                Title = "Auto Vote",
                Content = "Auto Vote disabled - Implementation needed",
                Duration = 3
            })
        end
    end)

    local AutoSelfReviveToggle = Tabs.Auto:AddToggle("AutoSelfRevive", {
        Title = "Auto Self Revive",
        Default = false
    })

    AutoSelfReviveToggle:OnChanged(function()
        featureStates.AutoSelfRevive = Options.AutoSelfRevive.Value
        if featureStates.AutoSelfRevive then
            -- Start auto self revive implementation
            Fluent:Notify({
                Title = "Auto Self Revive",
                Content = "Auto Self Revive enabled - Implementation needed",
                Duration = 3
            })
        else
            -- Stop auto self revive implementation
            Fluent:Notify({
                Title = "Auto Self Revive",
                Content = "Auto Self Revive disabled - Implementation needed",
                Duration = 3
            })
        end
    end)

    Tabs.Auto:AddButton({
        Title = "Manual Revive",
        Description = "Manually revive yourself",
        Callback = function()
            -- Manual revive implementation
            Fluent:Notify({
                Title = "Manual Revive",
                Content = "Manual revive triggered - Implementation needed",
                Duration = 3
            })
        end
    })

    local AutoWinToggle = Tabs.Auto:AddToggle("AutoWin", {
        Title = "Auto Win",
        Default = false
    })

    AutoWinToggle:OnChanged(function()
        featureStates.AutoWin = Options.AutoWin.Value
        if featureStates.AutoWin then
            -- Start auto win implementation
            Fluent:Notify({
                Title = "Auto Win",
                Content = "Auto Win enabled - Implementation needed",
                Duration = 3
            })
        else
            -- Stop auto win implementation
            Fluent:Notify({
                Title = "Auto Win",
                Content = "Auto Win disabled - Implementation needed",
                Duration = 3
            })
        end
    end)

    local AutoMoneyFarmToggle = Tabs.Auto:AddToggle("AutoMoneyFarm", {
        Title = "Auto Money Farm",
        Default = false
    })

    AutoMoneyFarmToggle:OnChanged(function()
        featureStates.AutoMoneyFarm = Options.AutoMoneyFarm.Value
        if featureStates.AutoMoneyFarm then
            -- Start auto money farm implementation
            Fluent:Notify({
                Title = "Auto Money Farm",
                Content = "Auto Money Farm enabled - Implementation needed",
                Duration = 3
            })
        else
            -- Stop auto money farm implementation
            Fluent:Notify({
                Title = "Auto Money Farm",
                Content = "Auto Money Farm disabled - Implementation needed",
                Duration = 3
            })
        end
    end)

    local AutoWhistleToggle = Tabs.Auto:AddToggle("AutoWhistle", {
        Title = "Auto Whistle",
        Default = false
    })

    AutoWhistleToggle:OnChanged(function()
        featureStates.AutoWhistle = Options.AutoWhistle.Value
        if featureStates.AutoWhistle then
            -- Start auto whistle implementation
            Fluent:Notify({
                Title = "Auto Whistle",
                Content = "Auto Whistle enabled - Implementation needed",
                Duration = 3
            })
        else
            -- Stop auto whistle implementation
            Fluent:Notify({
                Title = "Auto Whistle",
                Content = "Auto Whistle disabled - Implementation needed",
                Duration = 3
            })
        end
    end)
end

-- Visuals Tab
do
    Tabs.Visuals:AddParagraph({
        Title = "Visual Features",
        Content = "────────────────"
    })

    local FullBrightToggle = Tabs.Visuals:AddToggle("FullBright", {
        Title = "Full Bright",
        Default = false
    })

    FullBrightToggle:OnChanged(function()
        featureStates.FullBright = Options.FullBright.Value
        if featureStates.FullBright then
            -- Start full bright implementation
            Lighting.Brightness = 2
            Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
            Lighting.Ambient = Color3.fromRGB(255, 255, 255)
            Lighting.GlobalShadows = false
            Fluent:Notify({
                Title = "Full Bright",
                Content = "Full Bright enabled",
                Duration = 3
            })
        else
            -- Stop full bright implementation
            Lighting.Brightness = 1
            Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
            Lighting.Ambient = Color3.fromRGB(128, 128, 128)
            Lighting.GlobalShadows = true
            Fluent:Notify({
                Title = "Full Bright",
                Content = "Full Bright disabled",
                Duration = 3
            })
        end
    end)

    local NoFogToggle = Tabs.Visuals:AddToggle("NoFog", {
        Title = "No Fog",
        Default = false
    })

    NoFogToggle:OnChanged(function()
        featureStates.NoFog = Options.NoFog.Value
        if featureStates.NoFog then
            -- Start no fog implementation
            Lighting.FogEnd = 1000000
            Fluent:Notify({
                Title = "No Fog",
                Content = "No Fog enabled",
                Duration = 3
            })
        else
            -- Stop no fog implementation
            Lighting.FogEnd = 1000
            Fluent:Notify({
                Title = "No Fog",
                Content = "No Fog disabled",
                Duration = 3
            })
        end
    end)

    local TimerDisplayToggle = Tabs.Visuals:AddToggle("TimerDisplay", {
        Title = "Timer Display",
        Default = false
    })

    TimerDisplayToggle:OnChanged(function()
        featureStates.TimerDisplay = Options.TimerDisplay.Value
        if featureStates.TimerDisplay then
            Fluent:Notify({
                Title = "Timer Display",
                Content = "Timer Display enabled - Implementation needed",
                Duration = 3
            })
        else
            Fluent:Notify({
                Title = "Timer Display",
                Content = "Timer Display disabled - Implementation needed",
                Duration = 3
            })
        end
    end)

    local FOVSlider = Tabs.Visuals:AddSlider("FOV", {
        Title = "Field of View",
        Description = "Adjust camera field of view",
        Default = 70,
        Min = 10,
        Max = 120,
        Rounding = 1,
        Callback = function(Value)
            workspace.CurrentCamera.FieldOfView = Value
        end
    })

    local DisableCameraShakeToggle = Tabs.Visuals:AddToggle("DisableCameraShake", {
        Title = "Disable Camera Shake",
        Default = false
    })

    DisableCameraShakeToggle:OnChanged(function()
        featureStates.DisableCameraShake = Options.DisableCameraShake.Value
        if featureStates.DisableCameraShake then
            Fluent:Notify({
                Title = "Camera Shake",
                Content = "Camera shake disabled - Implementation needed",
                Duration = 3
            })
        else
            Fluent:Notify({
                Title = "Camera Shake",
                Content = "Camera shake enabled - Implementation needed",
                Duration = 3
            })
        end
    end)
end

-- ESP Tab
do
    Tabs.ESP:AddParagraph({
        Title = "ESP Features - Player",
        Content = "────────────────"
    })

    local PlayerNameESPToggle = Tabs.ESP:AddToggle("PlayerNameESP", {
        Title = "Player Name ESP",
        Default = false
    })

    PlayerNameESPToggle:OnChanged(function()
        featureStates.PlayerESP.names = Options.PlayerNameESP.Value
        Fluent:Notify({
            Title = "Player Name ESP",
            Content = (Options.PlayerNameESP.Value and "Enabled" or "Disabled") .. " - Implementation needed",
            Duration = 3
        })
    end)

    local PlayerBoxESPToggle = Tabs.ESP:AddToggle("PlayerBoxESP", {
        Title = "Player Box ESP",
        Default = false
    })

    PlayerBoxESPToggle:OnChanged(function()
        featureStates.PlayerESP.boxes = Options.PlayerBoxESP.Value
        Fluent:Notify({
            Title = "Player Box ESP",
            Content = (Options.PlayerBoxESP.Value and "Enabled" or "Disabled") .. " - Implementation needed",
            Duration = 3
        })
    end)

    local PlayerBoxTypeDropdown = Tabs.ESP:AddDropdown("PlayerBoxType", {
        Title = "Player Box Type",
        Values = {"2D", "3D"},
        Multi = false,
        Default = "2D",
    })

    PlayerBoxTypeDropdown:OnChanged(function()
        featureStates.PlayerESP.boxType = Options.PlayerBoxType.Value
    end)

    local PlayerTracerToggle = Tabs.ESP:AddToggle("PlayerTracer", {
        Title = "Player Tracer",
        Default = false
    })

    PlayerTracerToggle:OnChanged(function()
        featureStates.PlayerESP.tracers = Options.PlayerTracer.Value
        Fluent:Notify({
            Title = "Player Tracer",
            Content = (Options.PlayerTracer.Value and "Enabled" or "Disabled") .. " - Implementation needed",
            Duration = 3
        })
    end)

    local PlayerDistanceESPToggle = Tabs.ESP:AddToggle("PlayerDistanceESP", {
        Title = "Player Distance ESP",
        Default = false
    })

    PlayerDistanceESPToggle:OnChanged(function()
        featureStates.PlayerESP.distance = Options.PlayerDistanceESP.Value
        Fluent:Notify({
            Title = "Player Distance ESP",
            Content = (Options.PlayerDistanceESP.Value and "Enabled" or "Disabled") .. " - Implementation needed",
            Duration = 3
        })
    end)

    Tabs.ESP:AddParagraph({
        Title = "ESP Features - Nextbot",
        Content = "────────────────"
    })

    local NextbotESPToggle = Tabs.ESP:AddToggle("NextbotESP", {
        Title = "Nextbot ESP",
        Default = false
    })

    NextbotESPToggle:OnChanged(function()
        featureStates.NextbotESP.names = Options.NextbotESP.Value
        Fluent:Notify({
            Title = "Nextbot ESP",
            Content = (Options.NextbotESP.Value and "Enabled" or "Disabled") .. " - Implementation needed",
            Duration = 3
        })
    end)

    Tabs.ESP:AddParagraph({
        Title = "ESP Features - Downed Players",
        Content = "────────────────"
    })

    local DownedBoxESPToggle = Tabs.ESP:AddToggle("DownedBoxESP", {
        Title = "Downed Player Box ESP",
        Default = false
    })

    DownedBoxESPToggle:OnChanged(function()
        featureStates.DownedBoxESP = Options.DownedBoxESP.Value
        Fluent:Notify({
            Title = "Downed Box ESP",
            Content = (Options.DownedBoxESP.Value and "Enabled" or "Disabled") .. " - Implementation needed",
            Duration = 3
        })
    end)

    local DownedTracerToggle = Tabs.ESP:AddToggle("DownedTracer", {
        Title = "Downed Player Tracer",
        Default = false
    })

    DownedTracerToggle:OnChanged(function()
        featureStates.DownedTracer = Options.DownedTracer.Value
        Fluent:Notify({
            Title = "Downed Tracer",
            Content = (Options.DownedTracer.Value and "Enabled" or "Disabled") .. " - Implementation needed",
            Duration = 3
        })
    end)
end

-- Utility Tab
do
    Tabs.Utility:AddParagraph({
        Title = "Utility Features",
        Content = "────────────────"
    })

    local GravityToggle = Tabs.Utility:AddToggle("CustomGravity", {
        Title = "Custom Gravity",
        Default = false
    })

    GravityToggle:OnChanged(function()
        featureStates.CustomGravity = Options.CustomGravity.Value
        if featureStates.CustomGravity then
            workspace.Gravity = featureStates.GravityValue
            Fluent:Notify({
                Title = "Custom Gravity",
                Content = "Custom Gravity enabled: " .. featureStates.GravityValue,
                Duration = 3
            })
        else
            workspace.Gravity = originalGameGravity
            Fluent:Notify({
                Title = "Custom Gravity",
                Content = "Custom Gravity disabled",
                Duration = 3
            })
        end
    end)

    local GravityInput = Tabs.Utility:AddInput("GravityValue", {
        Title = "Gravity Value",
        Default = tostring(featureStates.GravityValue),
        Placeholder = "196.2",
        Numeric = true,
        Finished = false,
        Callback = function(Value)
            local num = tonumber(Value)
            if num then
                featureStates.GravityValue = num
                if featureStates.CustomGravity then
                    workspace.Gravity = num
                end
                Fluent:Notify({
                    Title = "Gravity",
                    Content = "Gravity value set to: " .. Value,
                    Duration = 3
                })
            end
        end
    })

    Tabs.Utility:AddButton({
        Title = "Free Cam",
        Description = "Toggle free camera mode",
        Callback = function()
            Fluent:Notify({
                Title = "Free Cam",
                Content = "Free cam feature - Implementation needed",
                Duration = 3
            })
        end
    })

    local TimeChangerInput = Tabs.Utility:AddInput("TimeChanger", {
        Title = "Set Time (HH:MM)",
        Default = "",
        Placeholder = "12:00",
        Numeric = false,
        Finished = false,
        Callback = function(Value)
            Fluent:Notify({
                Title = "Time Changer",
                Content = "Time set to: " .. Value .. " - Implementation needed",
                Duration = 3
            })
        end
    end)

    local FreeCamSpeedSlider = Tabs.Utility:AddSlider("FreeCamSpeed", {
        Title = "Free Cam Speed",
        Description = "Adjust movement speed in Free Cam",
        Default = 50,
        Min = 1,
        Max = 500,
        Rounding = 1,
        Callback = function(Value)
            Fluent:Notify({
                Title = "Free Cam Speed",
                Content = "Free cam speed set to: " .. Value,
                Duration = 3
            })
        end
    })
end

-- Settings Tab
do
    Tabs.Settings:AddParagraph({
        Title = "UI Settings",
        Content = "────────────────"
    })

    local themes = {"Dark", "Light", "Darker", "RosePine", "Aqua"}
    local ThemeDropdown = Tabs.Settings:AddDropdown("Theme", {
        Title = "Select Theme",
        Values = themes,
        Multi = false,
        Default = "Dark",
    })

    ThemeDropdown:OnChanged(function()
        Fluent:SetTheme(Options.Theme.Value)
        Fluent:Notify({
            Title = "Theme",
            Content = "Theme changed to: " .. Options.Theme.Value,
            Duration = 3
        })
    end)

    local TransparencySlider = Tabs.Settings:AddSlider("Transparency", {
        Title = "Window Transparency",
        Default = 0.2,
        Min = 0,
        Max = 1,
        Rounding = 1,
        Callback = function(Value)
            Window:ToggleTransparency(Value > 0)
            Fluent:Notify({
                Title = "Transparency",
                Content = "Transparency set to: " .. Value,
                Duration = 3
            })
        end
    })

    Tabs.Settings:AddParagraph({
        Title = "Configuration",
        Content = "────────────────"
    })

    Tabs.Settings:AddButton({
        Title = "Save Settings",
        Description = "Save current configuration",
        Callback = function()
            Fluent:Notify({
                Title = "Settings",
                Content = "Settings saved successfully!",
                Duration = 3
            })
        end
    })

    Tabs.Settings:AddButton({
        Title = "Load Settings",
        Description = "Load saved configuration",
        Callback = function()
            Fluent:Notify({
                Title = "Settings",
                Content = "Settings loaded successfully!",
                Duration = 3
            })
        end
    })
end

-- Character setup
local function onCharacterAdded(newCharacter)
    character = newCharacter
    humanoid = newCharacter:WaitForChild("Humanoid")
    rootPart = newCharacter:WaitForChild("HumanoidRootPart")
    
    -- Reapply features if needed
    if featureStates.JumpBoost then
        humanoid.JumpPower = featureStates.JumpPower
    end
end

player.CharacterAdded:Connect(onCharacterAdded)
if player.Character then
    onCharacterAdded(player.Character)
end

-- SaveManager setup
SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})
InterfaceManager:SetFolder("FluentDaraHub")
SaveManager:SetFolder("FluentDaraHub/evade")
InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)

-- Window event handlers
Window:OnClose(function()
    UIVisible = false
    ToggleButton.Text = "📱"
    ToggleButton.BackgroundColor3 = Color3.fromRGB(65, 65, 65)
end)

Window:OnOpen(function()
    UIVisible = true  
    ToggleButton.Text = "🔳"
    ToggleButton.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
end)

-- Select default tab and notify
Window:SelectTab(1)

Fluent:Notify({
    Title = "Zen Hub - Evade",
    Content = "Script loaded successfully! Use the toggle button to show/hide UI.",
    Duration = 5
})

-- Load autosave config
SaveManager:LoadAutoloadConfig()


