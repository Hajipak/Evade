if getgenv().ZenHubEvadeExecuted then return end
getgenv().ZenHubEvadeExecuted = true

-- Load WindUI
local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()

-- Localization setup (optional, but kept for structure)
local Localization = WindUI:Localization({
    Enabled = true,
    Prefix = "loc:",
    DefaultLanguage = "en",
    Translations = {
        ["en"] = {
            ["SCRIPT_TITLE"] = "Movement Hub",
            ["WELCOME"] = "Made by: Zen",
            ["FEATURES"] = "Features",
            ["MOVEMENT_TAB"] = "Movement",
            ["VISUALS_TAB"] = "Visuals",
            ["SETTINGS_TAB"] = "Settings",
        }
    }
})

-- Global Variables and Feature States
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local character = player.Character or player.CharacterAdded:WaitForChild(player)
local rootPart = character:WaitForChild("HumanoidRootPart")
local humanoid = character:WaitForChild("Humanoid")

-- Feature States
local featureStates = featureStates or {}
featureStates.Bhop = false
featureStates.Bounce = false
featureStates.TimerDisplay = false
featureStates.FullBright = false

-- Global Settings
local currentSettings = currentSettings or {
    AirStrafeAcceleration = "187",
    JumpCap = "1",
    Speed = "16",
    ApplyMode = "", -- Default to empty/unselected
}

-- Connections
local bhopConnection = nil
local bounceConnection = nil
local fullbrightConnection = nil

-- GUI Elements
local bhopGui, bhopGuiButton
local bounceGui, bounceGuiButton
local timerGui, timerLabel

-- Function to create draggable frame
local function makeDraggable(frame)
    local dragging = false
    local dragInput, dragStart, startPos

    local function update(input)
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end

    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    frame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            update(input)
        end
    end)
end

-- Function to create validated input
local function createValidatedInput(config)
    return function(input)
        local val = tonumber(input)
        if not val then return end
        if config.min and val < config.min then return end
        if config.max and val > config.max then return end
        currentSettings[config.field] = tostring(val)
        -- Apply immediately if it's JumpCap or StrafeAcceleration
        if config.field == "JumpCap" or config.field == "AirStrafeAcceleration" then
            local applyToTables = function(func)
                pcall(function() func(ReplicatedStorage.Modules.Client.Settings.Defaults) end)
                pcall(function() func(ReplicatedStorage.Modules.Client.Settings.Values) end)
                pcall(function() func(ReplicatedStorage.Modules.Client.Settings.Overrides) end)
            end

            local jumpCapVal = tonumber(currentSettings.JumpCap)
            if jumpCapVal and tostring(jumpCapVal) ~= "1" then
                applyToTables(function(obj) obj.JumpCap = jumpCapVal end)
            end

            local strafeVal = tonumber(currentSettings.AirStrafeAcceleration)
            if strafeVal and tostring(strafeVal) ~= "187" then
                applyToTables(function(obj) obj.AirStrafeAcceleration = strafeVal end)
            end
        end
    end
end

-- Create Main Window
local Window = WindUI:Window({
    Title = "Movement Hub",
    SubTitle = "by Zen",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

local Tabs = {}
Tabs.Movement = Window:Tab({ Title = "Movement", Icon = "motion" })
Tabs.Visual = Window:Tab({ Title = "Visuals", Icon = "eye" })
Tabs.Settings = Window:Tab({ Title = "Settings", Icon = "settings" })

-- Movement Tab
Tabs.Movement:Section({ Title = "Movement Settings", TextSize = 20 })

local StrafeInput = Tabs.Movement:Input({
    Title = "Strafe Acceleration",
    Icon = "wind",
    Placeholder = "Default 187",
    Value = currentSettings.AirStrafeAcceleration,
    Callback = createValidatedInput({field = "AirStrafeAcceleration", min = 1, max = 1000888888})
})

local JumpCapInput = Tabs.Movement:Input({
    Title = "Jump Cap",
    Icon = "chevrons-up",
    Placeholder = "Default 1",
    Value = currentSettings.JumpCap,
    Callback = createValidatedInput({field = "JumpCap", min = 0.1, max = 5088888})
})

local SpeedInput = Tabs.Movement:Input({
    Title = "Speed",
    Placeholder = "Default 16",
    Value = currentSettings.Speed,
    Callback = createValidatedInput({field = "Speed", min = 1, max = 1000})
})

local ApplyMethodDropdown = Tabs.Movement:Dropdown({
    Title = "Select Apply Method",
    Values = { "Not Optimized", "Optimized" },
    Multi = false,
    Default = currentSettings.ApplyMode,
    Callback = function(value)
        currentSettings.ApplyMode = value
    end
})

Tabs.Movement:Section({ Title = "Bhop", TextSize = 20 })

local BhopToggle = Tabs.Movement:Toggle({
    Title = "Bhop",
    Value = featureStates.Bhop,
    Callback = function(state)
        featureStates.Bhop = state
        if state then
            if not bhopConnection then
                bhopConnection = RunService.Heartbeat:Connect(function()
                    if featureStates.Bhop and humanoid and humanoid.FloorMaterial ~= Enum.Material.Air and rootPart.Velocity.Y < 1 then
                        -- Simple Bhop logic
                        humanoid.Jump = true
                    end
                end)
            end
        else
            if bhopConnection then
                bhopConnection:Disconnect()
                bhopConnection = nil
            end
        end
        if bhopGuiButton then
            bhopGuiButton.Text = state and "On" or "Off"
            bhopGuiButton.BackgroundColor3 = state and Color3.fromRGB(0, 120, 80) or Color3.fromRGB(120, 0, 0)
        end
    end
})

local BhopGuiToggle = Tabs.Movement:Toggle({
    Title = "Show Bhop GUI Button",
    Value = featureStates.BhopGuiVisible or false,
    Callback = function(state)
        featureStates.BhopGuiVisible = state
        if bhopGui then
            bhopGui.Enabled = state
        end
    end
})

Tabs.Movement:Section({ Title = "Bounce", TextSize = 20 })

local BounceToggle = Tabs.Movement:Toggle({
    Title = "Enable Bounce",
    Value = featureStates.Bounce,
    Callback = function(state)
        featureStates.Bounce = state
        if state then
            if not bounceConnection then
                bounceConnection = RunService.Heartbeat:Connect(function()
                    if character and rootPart and humanoid.FloorMaterial ~= Enum.Material.Air then
                        if rootPart.Velocity.Y < -0.1 then
                            if humanoid.FloorMaterial ~= Enum.Material.Air and rootPart.Velocity.Y > -1 then
                                rootPart.Velocity = Vector3.new(rootPart.Velocity.X, 10, rootPart.Velocity.Z)
                            end
                        end
                    end
                end)
            end
        else
            if bounceConnection then
                bounceConnection:Disconnect()
                bounceConnection = nil
            end
        end
        if bounceGuiButton then
            bounceGuiButton.Text = state and "On" or "Off"
            bounceGuiButton.BackgroundColor3 = state and Color3.fromRGB(0, 120, 80) or Color3.fromRGB(120, 0, 0)
        end
    end
})

local BounceGuiToggle = Tabs.Movement:Toggle({
    Title = "Show Bounce GUI Button",
    Value = featureStates.BounceGuiVisible or false,
    Callback = function(state)
        featureStates.BounceGuiVisible = state
        if bounceGui then
            bounceGui.Enabled = state
        end
    end
})

-- Visual Tab
Tabs.Visual:Section({ Title = "Visual Settings", TextSize = 20 })

local FullBrightToggle = Tabs.Visual:Toggle({
    Title = "Full Bright",
    Value = featureStates.FullBright,
    Callback = function(state)
        featureStates.FullBright = state
        if state then
            if not fullbrightConnection then
                fullbrightConnection = RunService.Heartbeat:Connect(function()
                    Lighting.Brightness = 2
                    Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
                    Lighting.Ambient = Color3.fromRGB(255, 255, 255)
                    Lighting.GlobalShadows = false
                end)
            end
        else
            if fullbrightConnection then
                fullbrightConnection:Disconnect()
                fullbrightConnection = nil
                Lighting.Brightness = 1
                Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
                Lighting.Ambient = Color3.fromRGB(0, 0, 0)
                Lighting.GlobalShadows = true
            end
        end
    end
})

local TimerDisplayToggle = Tabs.Visual:Toggle({
    Title = "Timer Display",
    Value = featureStates.TimerDisplay,
    Callback = function(state)
        featureStates.TimerDisplay = state
        if timerGui then
            timerGui.Enabled = state
        end
    end
})

-- Settings Tab
Tabs.Settings:Section({ Title = "GUI Settings", TextSize = 20 })

local ButtonSizeXInput = Tabs.Settings:Input({
    Title = "GUI Width (X)",
    Placeholder = "60",
    Value = tostring(getgenv().guiButtonSizeX or 60),
    Numeric = true,
    Callback = function(input)
        local val = tonumber(input)
        if val then
            getgenv().guiButtonSizeX = math.max(20, val)
            if bhopGui and bhopGui.Frame then bhopGui.Frame.Size = UDim2.new(0, getgenv().guiButtonSizeX, 0, getgenv().guiButtonSizeY or 60) end
            if bounceGui and bounceGui.Frame then bounceGui.Frame.Size = UDim2.new(0, getgenv().guiButtonSizeX, 0, getgenv().guiButtonSizeY or 60) end
            if timerGui and timerGui.Frame then timerGui.Frame.Size = UDim2.new(0, getgenv().guiButtonSizeX, 0, getgenv().guiButtonSizeY or 60) end
        end
    end
})

local ButtonSizeYInput = Tabs.Settings:Input({
    Title = "GUI Height (Y)",
    Placeholder = "60",
    Value = tostring(getgenv().guiButtonSizeY or 60),
    Numeric = true,
    Callback = function(input)
        local val = tonumber(input)
        if val then
            getgenv().guiButtonSizeY = math.max(20, val)
            if bhopGui and bhopGui.Frame then bhopGui.Frame.Size = UDim2.new(0, getgenv().guiButtonSizeX or 60, 0, getgenv().guiButtonSizeY) end
            if bounceGui and bounceGui.Frame then bounceGui.Frame.Size = UDim2.new(0, getgenv().guiButtonSizeX or 60, 0, getgenv().guiButtonSizeY) end
            if timerGui and timerGui.Frame then timerGui.Frame.Size = UDim2.new(0, getgenv().guiButtonSizeX or 60, 0, getgenv().guiButtonSizeY) end
        end
    end
})

local SaveSettingsButton = Tabs.Settings:Button({
    Title = "Save Settings",
    Callback = function()
        local settings = {
            featureStates = featureStates,
            currentSettings = currentSettings,
            guiButtonSizeX = getgenv().guiButtonSizeX or 60,
            guiButtonSizeY = getgenv().guiButtonSizeY or 60,
        }
        writefile("evade_movement_config.txt", game:GetService("HttpService"):JSONEncode(settings))
        WindUI:Notify({Title = "Settings", Content = "Settings saved successfully!", Duration = 3})
    end
})

local LoadSettingsButton = Tabs.Settings:Button({
    Title = "Load Settings",
    Callback = function()
        if isfile("evade_movement_config.txt") then
            local fileContent = readfile("evade_movement_config.txt")
            local settings = game:GetService("HttpService"):JSONDecode(fileContent)
            
            featureStates = settings.featureStates or featureStates
            currentSettings = settings.currentSettings or currentSettings
            getgenv().guiButtonSizeX = settings.guiButtonSizeX or 60
            getgenv().guiButtonSizeY = settings.guiButtonSizeY or 60

            -- Update UI elements
            BhopToggle:Set(featureStates.Bhop)
            BhopGuiToggle:Set(featureStates.BhopGuiVisible or false)
            BounceToggle:Set(featureStates.Bounce)
            BounceGuiToggle:Set(featureStates.BounceGuiVisible or false)
            FullBrightToggle:Set(featureStates.FullBright)
            TimerDisplayToggle:Set(featureStates.TimerDisplay)
            ApplyMethodDropdown:Set(currentSettings.ApplyMode)
            SpeedInput:Set(currentSettings.Speed)
            StrafeInput:Set(currentSettings.AirStrafeAcceleration)
            JumpCapInput:Set(currentSettings.JumpCap)
            ButtonSizeXInput:Set(tostring(getgenv().guiButtonSizeX))
            ButtonSizeYInput:Set(tostring(getgenv().guiButtonSizeY))

            WindUI:Notify({Title = "Settings", Content = "Settings loaded successfully!", Duration = 3})
        else
            WindUI:Notify({Title = "Error", Content = "Config file not found!", Duration = 3})
        end
    end
})

local ResetGuiSizeButton = Tabs.Settings:Button({
    Title = "Reset GUI Size",
    Callback = function()
        getgenv().guiButtonSizeX = 200
        getgenv().guiButtonSizeY = 30
        ButtonSizeXInput:Set("200")
        ButtonSizeYInput:Set("30")
        if bhopGui and bhopGui.Frame then bhopGui.Frame.Size = UDim2.new(0, 200, 0, 30) end
        if bounceGui and bounceGui.Frame then bounceGui.Frame.Size = UDim2.new(0, 200, 0, 30) end
        if timerGui and timerGui.Frame then timerGui.Frame.Size = UDim2.new(0, 200, 0, 30) end
        WindUI:Notify({Title = "Settings", Content = "GUI size reset to default!", Duration = 3})
    end
})

-- Create GUI Elements
-- Bhop GUI
bhopGui = Instance.new("ScreenGui")
bhopGui.Name = "BhopGui"
bhopGui.IgnoreGuiInset = true
bhopGui.ResetOnSpawn = false
bhopGui.Enabled = featureStates.BhopGuiVisible or false
bhopGui.Parent = playerGui

local bhopFrame = Instance.new("Frame")
bhopFrame.Name = "Frame"
bhopFrame.Size = UDim2.new(0, getgenv().guiButtonSizeX or 60, 0, getgenv().guiButtonSizeY or 60)
bhopFrame.Position = UDim2.new(0.5, -(getgenv().guiButtonSizeX or 60)/2, 0.12, 0)
bhopFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
bhopFrame.BackgroundTransparency = 0.35
bhopFrame.BorderSizePixel = 0
bhopFrame.Parent = bhopGui

makeDraggable(bhopFrame)

local bhopCorner = Instance.new("UICorner")
bhopCorner.CornerRadius = UDim.new(0, 6)
bhopCorner.Parent = bhopFrame

local bhopLabel = Instance.new("TextLabel")
bhopLabel.Text = "Bhop"
bhopLabel.Size = UDim2.new(0.9, 0, 0.45, 0)
bhopLabel.Position = UDim2.new(0.05, 0, 0.05, 0)
bhopLabel.BackgroundTransparency = 1
bhopLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
bhopLabel.Font = Enum.Font.Roboto
bhopLabel.TextSize = 16
bhopLabel.TextXAlignment = Enum.TextXAlignment.Center
bhopLabel.TextYAlignment = Enum.TextYAlignment.Center
bhopLabel.TextScaled = true
bhopLabel.Parent = bhopFrame

bhopGuiButton = Instance.new("TextButton")
bhopGuiButton.Name = "ToggleButton"
bhopGuiButton.Text = featureStates.Bhop and "On" or "Off"
bhopGuiButton.Size = UDim2.new(0.9, 0, 0.45, 0)
bhopGuiButton.Position = UDim2.new(0.05, 0, 0.5, 0)
bhopGuiButton.BackgroundColor3 = featureStates.Bhop and Color3.fromRGB(0, 120, 80) or Color3.fromRGB(120, 0, 0)
bhopGuiButton.TextColor3 = Color3.fromRGB(255, 255, 255)
bhopGuiButton.Font = Enum.Font.Roboto
bhopGuiButton.TextSize = 14
bhopGuiButton.TextXAlignment = Enum.TextXAlignment.Center
bhopGuiButton.TextYAlignment = Enum.TextYAlignment.Center
bhopGuiButton.TextScaled = true
bhopGuiButton.Parent = bhopFrame

local bhopButtonCorner = Instance.new("UICorner")
bhopButtonCorner.CornerRadius = UDim.new(0, 4)
bhopButtonCorner.Parent = bhopGuiButton

bhopGuiButton.MouseButton1Click:Connect(function()
    featureStates.Bhop = not featureStates.Bhop
    bhopGuiButton.Text = featureStates.Bhop and "On" or "Off"
    bhopGuiButton.BackgroundColor3 = featureStates.Bhop and Color3.fromRGB(0, 120, 80) or Color3.fromRGB(120, 0, 0)
    BhopToggle:Set(featureStates.Bhop)
end)

-- Bounce GUI
bounceGui = Instance.new("ScreenGui")
bounceGui.Name = "BounceGui"
bounceGui.IgnoreGuiInset = true
bounceGui.ResetOnSpawn = false
bounceGui.Enabled = featureStates.BounceGuiVisible or false
bounceGui.Parent = playerGui

local bounceFrame = Instance.new("Frame")
bounceFrame.Name = "Frame"
bounceFrame.Size = UDim2.new(0, getgenv().guiButtonSizeX or 60, 0, getgenv().guiButtonSizeY or 60)
bounceFrame.Position = UDim2.new(0.5, -(getgenv().guiButtonSizeX or 60)/2, 0.20, 0)
bounceFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
bounceFrame.BackgroundTransparency = 0.35
bounceFrame.BorderSizePixel = 0
bounceFrame.Parent = bounceGui

makeDraggable(bounceFrame)

local bounceCorner = Instance.new("UICorner")
bounceCorner.CornerRadius = UDim.new(0, 6)
bounceCorner.Parent = bounceFrame

local bounceLabel = Instance.new("TextLabel")
bounceLabel.Text = "Bounce"
bounceLabel.Size = UDim2.new(0.9, 0, 0.45, 0)
bounceLabel.Position = UDim2.new(0.05, 0, 0.05, 0)
bounceLabel.BackgroundTransparency = 1
bounceLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
bounceLabel.Font = Enum.Font.Roboto
bounceLabel.TextSize = 16
bounceLabel.TextXAlignment = Enum.TextXAlignment.Center
bounceLabel.TextYAlignment = Enum.TextYAlignment.Center
bounceLabel.TextScaled = true
bounceLabel.Parent = bounceFrame

bounceGuiButton = Instance.new("TextButton")
bounceGuiButton.Name = "ToggleButton"
bounceGuiButton.Text = featureStates.Bounce and "On" or "Off"
bounceGuiButton.Size = UDim2.new(0.9, 0, 0.45, 0)
bounceGuiButton.Position = UDim2.new(0.05, 0, 0.5, 0)
bounceGuiButton.BackgroundColor3 = featureStates.Bounce and Color3.fromRGB(0, 120, 80) or Color3.fromRGB(120, 0, 0)
bounceGuiButton.TextColor3 = Color3.fromRGB(255, 255, 255)
bounceGuiButton.Font = Enum.Font.Roboto
bounceGuiButton.TextSize = 14
bounceGuiButton.TextXAlignment = Enum.TextXAlignment.Center
bounceGuiButton.TextYAlignment = Enum.TextYAlignment.Center
bounceGuiButton.TextScaled = true
bounceGuiButton.Parent = bounceFrame

local bounceButtonCorner = Instance.new("UICorner")
bounceButtonCorner.CornerRadius = UDim.new(0, 4)
bounceButtonCorner.Parent = bounceGuiButton

bounceGuiButton.MouseButton1Click:Connect(function()
    featureStates.Bounce = not featureStates.Bounce
    bounceGuiButton.Text = featureStates.Bounce and "On" or "Off"
    bounceGuiButton.BackgroundColor3 = featureStates.Bounce and Color3.fromRGB(0, 120, 80) or Color3.fromRGB(120, 0, 0)
    BounceToggle:Set(featureStates.Bounce)
end)

-- Timer GUI
timerGui = Instance.new("ScreenGui")
timerGui.Name = "TimerGui"
timerGui.IgnoreGuiInset = true
timerGui.ResetOnSpawn = false
timerGui.Enabled = featureStates.TimerDisplay
timerGui.Parent = playerGui

local timerFrame = Instance.new("Frame")
timerFrame.Name = "Frame"
timerFrame.Size = UDim2.new(0, getgenv().guiButtonSizeX or 60, 0, getgenv().guiButtonSizeY or 60)
timerFrame.Position = UDim2.new(0.02, 0, 0.02, 0)
timerFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
timerFrame.BackgroundTransparency = 0.35
timerFrame.BorderSizePixel = 0
timerFrame.Parent = timerGui

makeDraggable(timerFrame)

local timerCorner = Instance.new("UICorner")
timerCorner.CornerRadius = UDim.new(0, 6)
timerCorner.Parent = timerFrame

timerLabel = Instance.new("TextLabel")
timerLabel.Name = "TimerLabel"
timerLabel.Text = "00:00"
timerLabel.Size = UDim2.new(1, 0, 1, 0)
timerLabel.Position = UDim2.new(0, 0, 0, 0)
timerLabel.BackgroundTransparency = 1
timerLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
timerLabel.Font = Enum.Font.Roboto
timerLabel.TextSize = 14
timerLabel.TextXAlignment = Enum.TextXAlignment.Center
timerLabel.TextYAlignment = Enum.TextYAlignment.Center
timerLabel.TextScaled = true
timerLabel.Parent = timerFrame

local timerConnection = RunService.Heartbeat:Connect(function()
    if featureStates.TimerDisplay then
        local elapsed = tick() % 86400
        local hours = math.floor(elapsed / 3600)
        local minutes = math.floor((elapsed % 3600) / 60)
        local seconds = math.floor(elapsed % 60)
        timerLabel.Text = string.format("%02d:%02d:%02d", hours, minutes, seconds)
    end
end)

-- Character Added Connection for persistence
player.CharacterAdded:Connect(function(newCharacter)
    wait(0.1)
    character = newCharacter
    rootPart = character:WaitForChild("HumanoidRootPart")
    humanoid = character:WaitForChild("Humanoid")
    
    -- Reapply persistent settings after respawn
    local applyToTables = function(func)
        pcall(function() func(ReplicatedStorage.Modules.Client.Settings.Defaults) end)
        pcall(function() func(ReplicatedStorage.Modules.Client.Settings.Values) end)
        pcall(function() func(ReplicatedStorage.Modules.Client.Settings.Overrides) end)
    end

    local jumpCapVal = tonumber(currentSettings.JumpCap)
    if jumpCapVal and tostring(jumpCapVal) ~= "1" then
        applyToTables(function(obj) obj.JumpCap = jumpCapVal end)
    end

    local strafeVal = tonumber(currentSettings.AirStrafeAcceleration)
    if strafeVal and tostring(strafeVal) ~= "187" then
        applyToTables(function(obj) obj.AirStrafeAcceleration = strafeVal end)
    end
    
    -- Apply ApplyMode if set (Note: This is a placeholder, actual implementation depends on the game)
    if currentSettings.ApplyMode ~= "" then
        print("[Movement Hub] ApplyMode set to:", currentSettings.ApplyMode)
    end
end)

-- Apply initial settings
local applyToTables = function(func)
    pcall(function() func(ReplicatedStorage.Modules.Client.Settings.Defaults) end)
    pcall(function() func(ReplicatedStorage.Modules.Client.Settings.Values) end)
    pcall(function() func(ReplicatedStorage.Modules.Client.Settings.Overrides) end)
end

local jumpCapVal = tonumber(currentSettings.JumpCap)
if jumpCapVal and tostring(jumpCapVal) ~= "1" then
    applyToTables(function(obj) obj.JumpCap = jumpCapVal end)
end

local strafeVal = tonumber(currentSettings.AirStrafeAcceleration)
if strafeVal and tostring(strafeVal) ~= "187" then
    applyToTables(function(obj) obj.AirStrafeAcceleration = strafeVal end)
end

WindUI:Notify({Title = "Movement Hub", Content = "Movement Hub loaded successfully!", Duration = 3})

-- Load external script
loadstring(game:HttpGet("https://raw.githubusercontent.com/Hajipak/Evade/refs/heads/main/Script/More-loadstring.lua "))()
