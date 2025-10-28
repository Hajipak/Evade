--#region Load Libraries
local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()
local ConfigManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/addons/ConfigManager.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/addons/SaveManager.lua"))()
--#endregion

--#region Localization Setup (Optional)
local Localization = WindUI:Localization({
    Enabled = true,
    Prefix = "loc:",
    DefaultLanguage = "en",
    Translations = {
        ["en"] = {
            ["SCRIPT_TITLE"] = "Movement Hub",
            ["WELCOME"] = "Made by Zen",
            ["FEATURES"] = "Features",
            ["Player_TAB"] = "Player",
            ["AUTO_TAB"] = "Auto",
            ["VISUALS_TAB"] = "Visuals",
            ["ESP_TAB"] = "ESP",
            ["SETTINGS_TAB"] = "Settings",
        },
    }
})
--#endregion

--#region Window Creation
local Window = WindUI:CreateWindow({
    Title = "Movement Hub",
    SubTitle = "by Zen",
    Width = 500,
    Height = 400,
    Theme = "Dark",
    Version = "1.0.0",
    MinimizeKey = Enum.KeyCode.RightShift,
    SaveFolder = "MovementHubConfigs",
})

Window:CreateTopbarButton("theme-switcher", "moon", function()
    WindUI:SetTheme(WindUI:GetCurrentTheme() == "Dark" and "Light" or "Dark")
end, 990)
--#endregion

--#region Services & Variables
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local workspace = game:GetService("Workspace")
local originalGameGravity = workspace.Gravity
local HttpService = game:GetService("HttpService")
local MarketplaceService = game:GetService("MarketplaceService")
local TeleportService = game:GetService("TeleportService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local placeId = game.PlaceId
local jobId = game.JobId

local function getCharacterParts()
    local character = player.Character
    if character then
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        return character, rootPart, humanoid
    end
    return nil, nil, nil
end

-- Feature States
local featureStates = {
    Bhop = false,
    BhopMode = "Acceleration",
    AutoCrouch = false,
    AutoCrouchMode = "Air",
    Bounce = false,
    CustomGravity = false,
    GravityValue = originalGameGravity,
    AutoCarry = false,
    TimerDisplay = false,
    StrafeAcceleration = false,
    JumpCap = false,
    InfiniteSlide = false,
    -- Lag Switch states
    LagSwitchEnabled = false,
    LagDuration = 0.1,
    -- Auto Crouch states
    AutoCrouchMode = "Air",
    -- Bhop states
    BhopHold = false,
}

-- Persistent Settings
local currentSettings = {
    AirStrafeAcceleration = "187",
    JumpCap = "1",
    Speed = "1500",
}
local appliedOnce = false

-- Bhop Variables
getgenv().bhopAccelValue = -0.5
getgenv().bhopHoldActive = false
getgenv().autoJumpEnabled = false -- Sync with BhopToggle
local bhopConnection = nil
local uiToggledViaUI = true

-- Auto Crouch Variables
local autoCrouchConnection = nil
local previousCrouchState = false
local spamDown = true

-- Bounce Variables
local BOUNCE_HEIGHT = 0
local BOUNCE_EPSILON = 0.1
local bounceConnection = nil
local touchConnection = nil

-- Gravity Variables
local gravityGui = nil
local gravityGuiButton = nil
local originalGravity = workspace.Gravity

-- Auto Carry Variables
local autoCarryConnection = nil

-- Settings
getgenv().gravityGuiVisible = true
getgenv().guiButtonSizeX = 60
getgenv().guiButtonSizeY = 60
getgenv().ApplyMode = "Optimized" -- Default to "Optimized"

-- GUI Variables
local bhopGui = nil
local bhopGuiButton = nil
local autoCrouchGui = nil
local autoCrouchGuiButton = nil
local gravityGui = nil
local gravityGuiButton = nil
local autoCarryGui = nil
local autoCarryGuiButton = nil
local TimerDisplay = nil -- For Timer Display GUI
local lagGui = nil -- For Lag Switch GUI
local lagGuiButton = nil -- For Lag Switch Button

-- Config Manager
local configFile = nil
local configName = "MovementHubConfig.json"
--#endregion

--#region Utility Functions
local function fireKeybind(down, key)
    local ohTable = {
        ["Down"] = down,
        ["Key"] = key
    }
    local event = game:GetService("Players").LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild("Events"):WaitForChild("temporary_events"):WaitForChild("UseKeybind")
    if event then
        event:Fire(ohTable)
    end
end

local function createValidatedInput(config)
    return function(input)
        local val = tonumber(input)
        if not val then return end
        if config.min and val < config.min then return end
        if config.max and val > config.max then return end
        currentSettings[config.field] = tostring(val)
        -- Apply the setting immediately after validation
        if config.field == "AirStrafeAcceleration" then
            applyToTables(function(obj) obj.AirStrafeAcceleration = val end)
        elseif config.field == "JumpCap" then
            applyToTables(function(obj) obj.JumpCap = val end)
        elseif config.field == "Speed" then
            applyToTables(function(obj) obj.Speed = val end)
        end
    end
end

local function getConfigTables()
    local keys = { "AirStrafeAcceleration", "JumpCap", "Speed", "Friction" }
    local function hasAll(tbl)
        if type(tbl) ~= "table" then return false end
        for _, k in ipairs(keys) do
            if rawget(tbl, k) == nil then return false end
        end
        return true
    end
    local tables = {}
    for _, obj in ipairs(getgc(true)) do
        local success, result = pcall(function() if hasAll(obj) then return obj end end)
        if success and result then
            table.insert(tables, result)
        end
    end
    return tables
end

local function applyToTables(callback)
    local targets = getConfigTables()
    if #targets == 0 then return end
    if getgenv().ApplyMode == "Optimized" then
        task.spawn(function()
            for i, tableObj in ipairs(targets) do
                if tableObj and typeof(tableObj) == "table" then
                    pcall(callback, tableObj)
                end
                if i % 3 == 0 then task.wait() end
            end
        end)
    else -- Not Optimized (or any other mode)
        for _, tableObj in ipairs(targets) do
            if tableObj and typeof(tableObj) == "table" then
                pcall(callback, tableObj)
            end
        end
    end
end

local function applyStoredSettings()
    if appliedOnce then return end
    appliedOnce = true

    -- Apply Strafe Acceleration if enabled
    if featureStates.StrafeAcceleration then
        local val = tonumber(currentSettings.AirStrafeAcceleration)
        if val then
            applyToTables(function(obj) obj.AirStrafeAcceleration = val end)
        end
    end

    -- Apply Jump Cap if enabled
    if featureStates.JumpCap then
        local val = tonumber(currentSettings.JumpCap)
        if val then
            applyToTables(function(obj) obj.JumpCap = val end)
        end
    end

    -- Apply Speed if enabled
    if featureStates.Speed then
        local val = tonumber(currentSettings.Speed)
        if val then
            applyToTables(function(obj) obj.Speed = val end)
        end
    end

    -- Apply Gravity if enabled
    if featureStates.CustomGravity then
        workspace.Gravity = featureStates.GravityValue
    end
end
--#endregion

--#region Bhop Logic (Replaced with Evade Test Logic)
local function startBhop()
    if bhopConnection then bhopConnection:Disconnect() end
    bhopConnection = RunService.Heartbeat:Connect(function()
        local character, rootPart, humanoid = getCharacterParts()
        if not character or not rootPart or not humanoid or humanoid.PlatformStand then
            return
        end

        if getgenv().autoJumpEnabled then -- Use global state
            if getgenv().bhopHoldActive or UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                if humanoid.Sit then return end

                if getgenv().bhopMode == "Acceleration" then -- Use global state
                    if rootPart.Velocity.Y < 0.5 and rootPart.Velocity.Y > -0.5 then
                        task.spawn(function()
                            local startVelocityY = rootPart.Velocity.Y
                            local targetVelocityY = math.max(startVelocityY + getgenv().bhopAccelValue, -workspace.Gravity) -- Use global state
                            while getgenv().autoJumpEnabled and (getgenv().bhopHoldActive or UserInputService:IsKeyDown(Enum.KeyCode.Space)) and character and rootPart and humanoid and not humanoid.Sit and rootPart.Velocity.Y < 0.5 and rootPart.Velocity.Y > -0.5 do
                                if rootPart.Velocity.Y <= 0.5 and rootPart.Velocity.Y >= -0.5 then
                                    rootPart.Velocity = Vector3.new(rootPart.Velocity.X, targetVelocityY, rootPart.Velocity.Z)
                                end
                                RunService.Heartbeat:Wait()
                            end
                        end)
                    end
                elseif getgenv().bhopMode == "No Acceleration" then -- Use global state
                    if rootPart.Velocity.Y < 0.5 and rootPart.Velocity.Y > -0.5 then
                        VirtualUser:CaptureController()
                        VirtualUser:ClickButton1(Vector2.new())
                    end
                end
            end
        end
    end)
end

local function stopBhop()
    if bhopConnection then
        bhopConnection:Disconnect()
        bhopConnection = nil
    end
end
--#endregion

--#region Auto Crouch Logic
local function startAutoCrouch()
    if autoCrouchConnection then autoCrouchConnection:Disconnect() end
    autoCrouchConnection = RunService.Heartbeat:Connect(function()
        local character, rootPart, humanoid = getCharacterParts()
        if not character or not rootPart or not humanoid then return end

        if featureStates.AutoCrouch then
            local isAirCrouching = humanoid.Sit
            local isGrounded = humanoid.FloorMaterial ~= Enum.Material.Air

            if featureStates.AutoCrouchMode == "Always" then
                if not isAirCrouching then
                    fireKeybind(true, "C")
                end
            elseif featureStates.AutoCrouchMode == "Air" then
                if isAirCrouching and isGrounded then
                    fireKeybind(true, "C")
                end
            elseif featureStates.AutoCrouchMode == "Ground" then
                if not isAirCrouching and isGrounded then
                    fireKeybind(true, "C")
                end
            end
        end
    end)
end

local function stopAutoCrouch()
    if autoCrouchConnection then
        autoCrouchConnection:Disconnect()
        autoCrouchConnection = nil
    end
end
--#endregion

--#region Bounce Logic
local function setupBounceOnTouch(character)
    if touchConnection then touchConnection:Disconnect() end
    local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
    touchConnection = humanoidRootPart.Touched:Connect(function(hit)
        local playerBottom = humanoidRootPart.Position.Y - humanoidRootPart.Size.Y / 2
        local playerTop = humanoidRootPart.Position.Y + humanoidRootPart.Size.Y / 2
        local hitBottom = hit.Position.Y - hit.Size.Y / 2
        local hitTop = hit.Position.Y + hit.Size.Y / 2

        if hitTop <= playerBottom + BOUNCE_EPSILON then return
        elseif hitBottom >= playerTop - BOUNCE_EPSILON then return end

        if BOUNCE_HEIGHT > 0 then
            humanoidRootPart.Velocity = Vector3.new(humanoidRootPart.Velocity.X, BOUNCE_HEIGHT, humanoidRootPart.Velocity.Z)
        end
    end)
end

local function startBounce()
    local character = player.Character
    if character then
        setupBounceOnTouch(character)
    else
        player.CharacterAdded:Connect(setupBounceOnTouch)
    end
end

local function stopBounce()
    if touchConnection then
        touchConnection:Disconnect()
        touchConnection = nil
    end
end
--#endregion

--#region Auto Carry Logic (Placeholder)
local function startAutoCarry()
    -- Implement Auto Carry logic here
end

local function stopAutoCarry()
    -- Implement Auto Carry stop logic here
end
--#endregion

--#region Gravity Logic
local function startGravity()
    workspace.Gravity = featureStates.GravityValue
end

local function stopGravity()
    workspace.Gravity = originalGravity
end
--#endregion

--#region UI Creation
local FeatureSection = Window:Section({
    Title = "Features",
    Opened = true
})

local Tabs = {
    Player = FeatureSection:Tab({
        Title = "Movement Hub",
        Icon = "motion"
    }),
    Visuals = FeatureSection:Tab({
        Title = "Visuals",
        Icon = "eye"
    }),
    Settings = FeatureSection:Tab({
        Title = "Settings",
        Icon = "settings"
    })
}

-- Player Tab Content
Tabs.Player:Section({
    Title = "Movement Settings",
    TextSize = 20
})

local StrafeInput = Tabs.Player:Input({
    Title = "Strafe Acceleration",
    Icon = "wind",
    Placeholder = "Default 187",
    Value = currentSettings.AirStrafeAcceleration,
    Callback = createValidatedInput({
        field = "AirStrafeAcceleration",
        min = 1,
        max = 1000888888
    })
})

local JumpCapInput = Tabs.Player:Input({
    Title = "Set Jump Cap",
    Icon = "chevrons-up",
    Placeholder = "Default 1",
    Value = currentSettings.JumpCap,
    Callback = createValidatedInput({
        field = "JumpCap",
        min = 0.1,
        max = 5088888
    })
})

local SpeedInput = Tabs.Player:Input({
    Title = "Speed",
    Icon = "tachometer",
    Placeholder = "Default 1500",
    Value = currentSettings.Speed,
    Callback = createValidatedInput({
        field = "Speed",
        min = 1,
        max = 10000
    })
})

local ApplyMethodDropdown = Tabs.Player:Dropdown({
    Title = "Select Apply Method",
    Values = { "Not Optimized", "Optimized" },
    Multi = false,
    Default = getgenv().ApplyMode,
    Callback = function(value)
        getgenv().ApplyMode = value
    end
})

-- Bhop Section
Tabs.Player:Section({
    Title = "Bhop Settings",
    TextSize = 20
})

local BhopToggle = Tabs.Player:Toggle({
    Title = "Bhop",
    Value = getgenv().autoJumpEnabled, -- Use global state
    Callback = function(state)
        getgenv().autoJumpEnabled = state -- Update global state
        uiToggledViaUI = true
        if state then
            startBhop()
        else
            stopBhop()
        end
    end
})

local BhopModeDropdown = Tabs.Player:Dropdown({
    Title = "Bhop Mode",
    Values = { "Acceleration", "No Acceleration" },
    Multi = false,
    Default = getgenv().bhopMode or "Acceleration", -- Use global state
    Callback = function(value)
        getgenv().bhopMode = value -- Update global state
        if getgenv().autoJumpEnabled then -- Restart if active
            stopBhop()
            startBhop()
        end
    end
})

local BhopAccelInput = Tabs.Player:Input({
    Title = "Bhop Accel (Negative)",
    Placeholder = "-0.5",
    Value = tostring(getgenv().bhopAccelValue or -0.5), -- Use global state
    NumbersOnly = true,
    Callback = function(input)
        local val = tonumber(input)
        if val and val < 0 then
            getgenv().bhopAccelValue = val -- Update global state
        end
    end
})

-- Auto Carry Section
Tabs.Player:Section({
    Title = "Auto Carry",
    TextSize = 20
})

local AutoCarryToggle = Tabs.Player:Toggle({
    Title = "Auto Carry",
    Value = featureStates.AutoCarry,
    Callback = function(state)
        featureStates.AutoCarry = state
        if state then
            startAutoCarry()
        else
            stopAutoCarry()
        end
    end
})

-- Auto Crouch Section
Tabs.Player:Section({
    Title = "Auto Crouch",
    TextSize = 20
})

local AutoCrouchToggle = Tabs.Player:Toggle({
    Title = "Auto Crouch",
    Value = featureStates.AutoCrouch,
    Callback = function(state)
        featureStates.AutoCrouch = state
        if state then
            startAutoCrouch()
        else
            stopAutoCrouch()
        end
    end
})

local AutoCrouchModeDropdown = Tabs.Player:Dropdown({
    Title = "Crouch Mode",
    Values = { "Always", "Air", "Ground" },
    Multi = false,
    Default = featureStates.AutoCrouchMode,
    Callback = function(value)
        featureStates.AutoCrouchMode = value
    end
})

-- Bounce Section
Tabs.Player:Section({
    Title = "Bounce",
    TextSize = 20
})

local BounceToggle = Tabs.Player:Toggle({
    Title = "Bounce",
    Value = featureStates.Bounce,
    Callback = function(state)
        featureStates.Bounce = state
        if state then
            startBounce()
        else
            stopBounce()
        end
    end
})

local BounceHeightInput = Tabs.Player:Input({
    Title = "Bounce Height",
    Placeholder = "0",
    Value = tostring(BOUNCE_HEIGHT),
    NumbersOnly = true,
    Enabled = false,
    Callback = function(value)
        local num = tonumber(value)
        if num then
            BOUNCE_HEIGHT = math.max(0, num)
        end
    end
})

local EpsilonInput = Tabs.Player:Input({
    Title = "Touch Detection Epsilon",
    Placeholder = "0.1",
    Value = tostring(BOUNCE_EPSILON),
    NumbersOnly = true,
    Enabled = false,
    Callback = function(value)
        local num = tonumber(value)
        if num then
            BOUNCE_EPSILON = math.max(0, num)
        end
    end
})

BounceToggle:OnChanged(function(state)
    BounceHeightInput:Set({ Enabled = state })
    EpsilonInput:Set({ Enabled = state })
end)

-- Gravity Section
Tabs.Player:Section({
    Title = "Gravity",
    TextSize = 20
})

local GravityToggle = Tabs.Player:Toggle({
    Title = "Custom Gravity",
    Value = featureStates.CustomGravity,
    Callback = function(state)
        featureStates.CustomGravity = state
        if state then
            startGravity()
        else
            stopGravity()
        end
    end
})

local GravityInput = Tabs.Player:Input({
    Title = "Set Gravity",
    Placeholder = tostring(originalGameGravity),
    Value = tostring(featureStates.GravityValue),
    NumbersOnly = true,
    Callback = function(input)
        local val = tonumber(input)
        if val then
            featureStates.GravityValue = val
            if featureStates.CustomGravity then
                workspace.Gravity = val
            end
        end
    end
})

-- Visuals Tab Content
Tabs.Visuals:Section({
    Title = "Visual",
    TextSize = 20
})

local TimerDisplayToggle = Tabs.Visuals:Toggle({
    Title = "Timer Display",
    Value = featureStates.TimerDisplay,
    Callback = function(state)
        featureStates.TimerDisplay = state
        if state then
            -- Create Timer Display GUI
            if TimerDisplay then TimerDisplay:Destroy() end
            TimerDisplay = Instance.new("ScreenGui")
            TimerDisplay.Name = "TimerDisplay"
            TimerDisplay.IgnoreGuiInset = true
            TimerDisplay.ResetOnSpawn = false
            TimerDisplay.Parent = playerGui

            local timerFrame = Instance.new("Frame")
            timerFrame.Size = UDim2.new(0, 200, 0, 50)
            timerFrame.Position = UDim2.new(0, 10, 0, 300) -- Adjust position as needed
            timerFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
            timerFrame.BackgroundTransparency = 0.5
            timerFrame.BorderSizePixel = 0
            timerFrame.Parent = TimerDisplay

            local timerLabel = Instance.new("TextLabel")
            timerLabel.Size = UDim2.new(1, 0, 1, 0)
            timerLabel.BackgroundTransparency = 1
            timerLabel.Text = "00:00"
            timerLabel.TextScaled = true
            timerLabel.Font = Enum.Font.GothamBold
            timerLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            timerLabel.Parent = timerFrame

        else
            if TimerDisplay then
                TimerDisplay:Destroy()
                TimerDisplay = nil
            end
        end
    end
})

-- Settings Tab Content
Tabs.Settings:Section({
    Title = "Main Settings",
    TextSize = 20
})

local ButtonSizeXInput = Tabs.Settings:Input({
    Title = "Button Size X",
    Placeholder = "60",
    Value = tostring(getgenv().guiButtonSizeX),
    NumbersOnly = true,
    Callback = function(input)
        local val = tonumber(input)
        if val then
            getgenv().guiButtonSizeX = math.max(20, val)
            -- Update existing GUI button sizes if they exist
            if bhopGui and bhopGui:FindFirstChild("Frame") then
                bhopGui.Frame.Size = UDim2.new(0, getgenv().guiButtonSizeX, 0, getgenv().guiButtonSizeY)
            end
            if autoCrouchGui and autoCrouchGui:FindFirstChild("Frame") then
                autoCrouchGui.Frame.Size = UDim2.new(0, getgenv().guiButtonSizeX, 0, getgenv().guiButtonSizeY)
            end
            if gravityGui and gravityGui:FindFirstChild("Frame") then
                gravityGui.Frame.Size = UDim2.new(0, getgenv().guiButtonSizeX, 0, getgenv().guiButtonSizeY)
            end
            if autoCarryGui and autoCarryGui:FindFirstChild("Frame") then
                autoCarryGui.Frame.Size = UDim2.new(0, getgenv().guiButtonSizeX, 0, getgenv().guiButtonSizeY)
            end
            if lagGui and lagGui:FindFirstChild("Frame") then
                lagGui.Frame.Size = UDim2.new(0, getgenv().guiButtonSizeX, 0, getgenv().guiButtonSizeY)
            end
        end
    end
})

local ButtonSizeYInput = Tabs.Settings:Input({
    Title = "Button Size Y",
    Placeholder = "60",
    Value = tostring(getgenv().guiButtonSizeY),
    NumbersOnly = true,
    Callback = function(input)
        local val = tonumber(input)
        if val then
            getgenv().guiButtonSizeY = math.max(20, val)
            -- Update existing GUI button sizes if they exist
            if bhopGui and bhopGui:FindFirstChild("Frame") then
                bhopGui.Frame.Size = UDim2.new(0, getgenv().guiButtonSizeX, 0, getgenv().guiButtonSizeY)
            end
            if autoCrouchGui and autoCrouchGui:FindFirstChild("Frame") then
                autoCrouchGui.Frame.Size = UDim2.new(0, getgenv().guiButtonSizeX, 0, getgenv().guiButtonSizeY)
            end
            if gravityGui and gravityGui:FindFirstChild("Frame") then
                gravityGui.Frame.Size = UDim2.new(0, getgenv().guiButtonSizeX, 0, getgenv().guiButtonSizeY)
            end
            if autoCarryGui and autoCarryGui:FindFirstChild("Frame") then
                autoCarryGui.Frame.Size = UDim2.new(0, getgenv().guiButtonSizeX, 0, getgenv().guiButtonSizeY)
            end
            if lagGui and lagGui:FindFirstChild("Frame") then
                lagGui.Frame.Size = UDim2.new(0, getgenv().guiButtonSizeX, 0, getgenv().guiButtonSizeY)
            end
        end
    end
})

-- Lag Switch Section (Added from Evade Test)
Tabs.Settings:Section({
    Title = "Lag Switch",
    TextSize = 20
})

local LagSwitchToggle = Tabs.Settings:Toggle({
    Title = "Enable Lag Switch",
    Value = featureStates.LagSwitchEnabled,
    Callback = function(state)
        featureStates.LagSwitchEnabled = state
        if lagGui then
            lagGui.Enabled = state
        end
    end
})

local LagDurationInput = Tabs.Settings:Input({
    Title = "Lag Duration (seconds)",
    Placeholder = "0.1",
    Value = tostring(featureStates.LagDuration),
    NumbersOnly = true,
    Callback = function(input)
        local val = tonumber(input)
        if val then
            featureStates.LagDuration = val
            getgenv().lagDuration = val
        else
            getgenv().lagDuration = 0.1
        end
    end
})
getgenv().lagDuration = 0.1

--#endregion

--#region GUI Creation Functions
local function createBhopGui()
    if bhopGui then bhopGui:Destroy() end
    bhopGui = Instance.new("ScreenGui")
    bhopGui.Name = "BhopGui"
    bhopGui.IgnoreGuiInset = true
    bhopGui.ResetOnSpawn = false
    bhopGui.Enabled = getgenv().autoJumpEnabled -- Use global state
    bhopGui.Parent = playerGui

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, getgenv().guiButtonSizeX, 0, getgenv().guiButtonSizeY)
    frame.Position = UDim2.new(0, 10, 0, 100)
    frame.BackgroundColor3 = Color3.fromRGB(0, 100, 0)
    frame.BorderSizePixel = 2
    frame.BorderColor3 = Color3.fromRGB(255, 255, 255)
    frame.Parent = bhopGui

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.9, 0, 0.3, 0)
    label.Position = UDim2.new(0.05, 0, 0.05, 0)
    label.BackgroundTransparency = 1
    label.Text = "Auto"
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.Font = Enum.Font.Roboto
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Center
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.TextScaled = true
    label.Parent = frame

    local toggleButton = Instance.new("TextButton")
    toggleButton.Name = "ToggleButton"
    toggleButton.Text = getgenv().autoJumpEnabled and "On" or "Off" -- Use global state
    toggleButton.Size = UDim2.new(0.9, 0, 0.5, 0)
    toggleButton.Position = UDim2.new(0.05, 0, 0.5, 0)
    toggleButton.BackgroundColor3 = getgenv().autoJumpEnabled and Color3.fromRGB(0, 120, 80) or Color3.fromRGB(120, 0, 0) -- Use global state
    toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggleButton.Font = Enum.Font.Roboto
    toggleButton.TextSize = 14
    toggleButton.Parent = frame

    -- Make Frame Draggable
    local UserInputService = game:GetService("UserInputService")
    local dragging = false
    local dragStart = nil
    local startPos = nil

    local function updateInput(input)
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
            if dragging then
                updateInput(input)
            end
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    -- Button Click Function
    toggleButton.MouseButton1Click:Connect(function()
        getgenv().autoJumpEnabled = not getgenv().autoJumpEnabled -- Toggle global state
        uiToggledViaUI = false -- Mark that UI was NOT used to change the toggle state directly
        BhopToggle:Set(getgenv().autoJumpEnabled) -- Sync main toggle
        if getgenv().autoJumpEnabled then
            startBhop()
        else
            stopBhop()
        end
        toggleButton.Text = getgenv().autoJumpEnabled and "On" or "Off" -- Use global state
        toggleButton.BackgroundColor3 = getgenv().autoJumpEnabled and Color3.fromRGB(0, 120, 80) or Color3.fromRGB(120, 0, 0) -- Use global state
    end)

    bhopGuiButton = toggleButton
end

local function createAutoCrouchGui()
    if autoCrouchGui then autoCrouchGui:Destroy() end
    autoCrouchGui = Instance.new("ScreenGui")
    autoCrouchGui.Name = "AutoCrouchGui"
    autoCrouchGui.IgnoreGuiInset = true
    autoCrouchGui.ResetOnSpawn = false
    autoCrouchGui.Enabled = featureStates.AutoCrouch
    autoCrouchGui.Parent = playerGui

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, getgenv().guiButtonSizeX, 0, getgenv().guiButtonSizeY)
    frame.Position = UDim2.new(0, 10, 0, 170)
    frame.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    frame.BorderSizePixel = 2
    frame.BorderColor3 = Color3.fromRGB(255, 255, 255)
    frame.Parent = autoCrouchGui

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.9, 0, 0.3, 0)
    label.Position = UDim2.new(0.05, 0, 0.05, 0)
    label.BackgroundTransparency = 1
    label.Text = "Auto"
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.Font = Enum.Font.Roboto
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Center
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.TextScaled = true
    label.Parent = frame

    local subLabel = Instance.new("TextLabel")
    subLabel.Text = "Crouch"
    subLabel.Size = UDim2.new(0.9, 0, 0.3, 0)
    subLabel.Position = UDim2.new(0.05, 0, 0.3, 0)
    subLabel.BackgroundTransparency = 1
    subLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    subLabel.Font = Enum.Font.Roboto
    subLabel.TextSize = 14
    subLabel.TextXAlignment = Enum.TextXAlignment.Center
    subLabel.TextYAlignment = Enum.TextYAlignment.Center
    subLabel.TextScaled = true
    subLabel.Parent = frame

    local toggleButton = Instance.new("TextButton")
    toggleButton.Name = "ToggleButton"
    toggleButton.Text = featureStates.AutoCrouch and "On" or "Off"
    toggleButton.Size = UDim2.new(0.9, 0, 0.3, 0)
    toggleButton.Position = UDim2.new(0.05, 0, 0.65, 0)
    toggleButton.BackgroundColor3 = featureStates.AutoCrouch and Color3.fromRGB(0, 120, 80) or Color3.fromRGB(120, 0, 0)
    toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggleButton.Font = Enum.Font.Roboto
    toggleButton.TextSize = 14
    toggleButton.Parent = frame

    -- Make Frame Draggable
    local UserInputService = game:GetService("UserInputService")
    local dragging = false
    local dragStart = nil
    local startPos = nil

    local function updateInput(input)
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end

    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position

            input.ChChanged:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    frame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            if dragging then
                updateInput(input)
            end
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    -- Button Click Function
    toggleButton.MouseButton1Click:Connect(function()
        featureStates.AutoCrouch = not featureStates.AutoCrouch
        AutoCrouchToggle:Set(featureStates.AutoCrouch) -- Sync main toggle
        if featureStates.AutoCrouch then
            startAutoCrouch()
        else
            stopAutoCrouch()
        end
        toggleButton.Text = featureStates.AutoCrouch and "On" or "Off"
        toggleButton.BackgroundColor3 = featureStates.AutoCrouch and Color3.fromRGB(0, 120, 80) or Color3.fromRGB(120, 0, 0)
    end)

    autoCrouchGuiButton = toggleButton
end

local function createGravityGui()
    if gravityGui then gravityGui:Destroy() end
    gravityGui = Instance.new("ScreenGui")
    gravityGui.Name = "GravityGui"
    gravityGui.IgnoreGuiInset = true
    gravityGui.ResetOnSpawn = false
    gravityGui.Enabled = featureStates.CustomGravity -- Controlled by Gravity toggle
    gravityGui.Parent = playerGui

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, getgenv().guiButtonSizeX, 0, getgenv().guiButtonSizeY)
    frame.Position = UDim2.new(0, 10, 0, 240) -- Adjust position as needed
    frame.BackgroundColor3 = Color3.fromRGB(0, 0, 100) -- Blue
    frame.BorderSizePixel = 2
    frame.BorderColor3 = Color3.fromRGB(255, 255, 255)
    frame.Parent = gravityGui

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.9, 0, 0.3, 0)
    label.Position = UDim2.new(0.05, 0, 0.05, 0)
    label.BackgroundTransparency = 1
    label.Text = "Gravity"
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.Font = Enum.Font.Roboto
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Center
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.TextScaled = true
    label.Parent = frame

    local toggleButton = Instance.new("TextButton")
    toggleButton.Name = "ToggleButton"
    toggleButton.Text = featureStates.CustomGravity and "On" or "Off"
    toggleButton.Size = UDim2.new(0.9, 0, 0.5, 0)
    toggleButton.Position = UDim2.new(0.05, 0, 0.5, 0)
    toggleButton.BackgroundColor3 = featureStates.CustomGravity and Color3.fromRGB(0, 120, 80) or Color3.fromRGB(120, 0, 0)
    toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggleButton.Font = Enum.Font.Roboto
    toggleButton.TextSize = 14
    toggleButton.Parent = frame

    -- Make Frame Draggable
    local UserInputService = game:GetService("UserInputService")
    local dragging = false
    local dragStart = nil
    local startPos = nil

    local function updateInput(input)
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
            if dragging then
                updateInput(input)
            end
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    -- Button Click Function
    toggleButton.MouseButton1Click:Connect(function()
        featureStates.CustomGravity = not featureStates.CustomGravity
        GravityToggle:Set(featureStates.CustomGravity) -- Sync main toggle
        if featureStates.CustomGravity then
            startGravity()
        else
            stopGravity()
        end
        toggleButton.Text = featureStates.CustomGravity and "On" or "Off"
        toggleButton.BackgroundColor3 = featureStates.CustomGravity and Color3.fromRGB(0, 120, 80) or Color3.fromRGB(120, 0, 0)
    end)

    gravityGuiButton = toggleButton
end

local function createAutoCarryGui()
    if autoCarryGui then autoCarryGui:Destroy() end
    autoCarryGui = Instance.new("ScreenGui")
    autoCarryGui.Name = "AutoCarryGui"
    autoCarryGui.IgnoreGuiInset = true
    autoCarryGui.ResetOnSpawn = false
    autoCarryGui.Enabled = featureStates.AutoCarry -- Controlled by Auto Carry toggle
    autoCarryGui.Parent = playerGui

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, getgenv().guiButtonSizeX, 0, getgenv().guiButtonSizeY)
    frame.Position = UDim2.new(0, 10, 0, 310) -- Adjust position as needed
    frame.BackgroundColor3 = Color3.fromRGB(100, 0, 100) -- Purple
    frame.BorderSizePixel = 2
    frame.BorderColor3 = Color3.fromRGB(255, 255, 255)
    frame.Parent = autoCarryGui

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.9, 0, 0.3, 0)
    label.Position = UDim2.new(0.05, 0, 0.05, 0)
    label.BackgroundTransparency = 1
    label.Text = "Auto"
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.Font = Enum.Font.Roboto
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Center
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.TextScaled = true
    label.Parent = frame

    local subLabel = Instance.new("TextLabel")
    subLabel.Text = "Carry"
    subLabel.Size = UDim2.new(0.9, 0, 0.3, 0)
    subLabel.Position = UDim2.new(0.05, 0, 0.3, 0)
    subLabel.BackgroundTransparency = 1
    subLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    subLabel.Font = Enum.Font.Roboto
    subLabel.TextSize = 14
    subLabel.TextXAlignment = Enum.TextXAlignment.Center
    subLabel.TextYAlignment = Enum.TextYAlignment.Center
    subLabel.TextScaled = true
    subLabel.Parent = frame

    local toggleButton = Instance.new("TextButton")
    toggleButton.Name = "ToggleButton"
    toggleButton.Text = featureStates.AutoCarry and "On" or "Off"
    toggleButton.Size = UDim2.new(0.9, 0, 0.3, 0)
    toggleButton.Position = UDim2.new(0.05, 0, 0.65, 0)
    toggleButton.BackgroundColor3 = featureStates.AutoCarry and Color3.fromRGB(0, 120, 80) or Color3.fromRGB(120, 0, 0)
    toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggleButton.Font = Enum.Font.Roboto
    toggleButton.TextSize = 14
    toggleButton.Parent = frame

    -- Make Frame Draggable
    local UserInputService = game:GetService("UserInputService")
    local dragging = false
    local dragStart = nil
    local startPos = nil

    local function updateInput(input)
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
            if dragging then
                updateInput(input)
            end
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    -- Button Click Function
    toggleButton.MouseButton1Click:Connect(function()
        featureStates.AutoCarry = not featureStates.AutoCarry
        AutoCarryToggle:Set(featureStates.AutoCarry) -- Sync main toggle
        if featureStates.AutoCarry then
            startAutoCarry()
        else
            stopAutoCarry()
        end
        toggleButton.Text = featureStates.AutoCarry and "On" or "Off"
        toggleButton.BackgroundColor3 = featureStates.AutoCarry and Color3.fromRGB(0, 120, 80) or Color3.fromRGB(120, 0, 0)
    end)

    autoCarryGuiButton = toggleButton
end

local function createLagSwitchGui()
    if lagGui then lagGui:Destroy() end
    lagGui = Instance.new("ScreenGui")
    lagGui.Name = "LagSwitchGui"
    lagGui.IgnoreGuiInset = true
    lagGui.ResetOnSpawn = false
    lagGui.Enabled = featureStates.LagSwitchEnabled -- Controlled by Lag Switch toggle
    lagGui.Parent = playerGui

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, getgenv().guiButtonSizeX, 0, getgenv().guiButtonSizeY)
    frame.Position = UDim2.new(0, 10, 0, 380) -- Adjust position as needed
    frame.BackgroundColor3 = Color3.fromRGB(255, 85, 0) -- Orange
    frame.BorderSizePixel = 2
    frame.BorderColor3 = Color3.fromRGB(255, 255, 255)
    frame.Parent = lagGui

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.9, 0, 0.3, 0)
    label.Position = UDim2.new(0.05, 0, 0.05, 0)
    label.BackgroundTransparency = 1
    label.Text = "LAG"
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.Font = Enum.Font.Roboto
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Center
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.TextScaled = true
    label.Parent = frame

    local subLabel = Instance.new("TextLabel")
    subLabel.Text = "Switch"
    subLabel.Size = UDim2.new(0.9, 0, 0.3, 0)
    subLabel.Position = UDim2.new(0.05, 0, 0.3, 0)
    subLabel.BackgroundTransparency = 1
    subLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    subLabel.Font = Enum.Font.Roboto
    subLabel.TextSize = 14
    subLabel.TextXAlignment = Enum.TextXAlignment.Center
    subLabel.TextYAlignment = Enum.TextYAlignment.Center
    subLabel.TextScaled = true
    subLabel.Parent = frame

    local toggleButton = Instance.new("TextButton")
    toggleButton.Name = "ToggleButton"
    toggleButton.Text = "CLICK"
    toggleButton.Size = UDim2.new(0.9, 0, 0.3, 0)
    toggleButton.Position = UDim2.new(0.05, 0, 0.65, 0)
    toggleButton.BackgroundColor3 = Color3.fromRGB(200, 60, 0) -- Darker Orange
    toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggleButton.Font = Enum.Font.Roboto
    toggleButton.TextSize = 14
    toggleButton.Parent = frame

    -- Make Frame Draggable
    local UserInputService = game:GetService("UserInputService")
    local dragging = false
    local dragStart = nil
    local startPos = nil

    local function updateInput(input)
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
            if dragging then
                updateInput(input)
            end
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    -- Lag Switch Button Click Function
    toggleButton.MouseButton1Click:Connect(function()
        -- Execute the More-loadstring.lua script
        local success, err = pcall(function()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/Hajipak/Evade/refs/heads/main/Script/More-loadstring.lua"))()
        end)
        -- Error handling is done within the pcall
    end)

    lagGuiButton = toggleButton
end
--#endregion

--#region Sync GUI Visibility with Toggles
BhopToggle:OnChanged(function(state)
    if bhopGui then
        bhopGui.Enabled = state
        if bhopGuiButton then
            bhopGuiButton.Text = state and "On" or "Off"
            bhopGuiButton.BackgroundColor3 = state and Color3.fromRGB(0, 120, 80) or Color3.fromRGB(120, 0, 0)
        end
    end
end)

AutoCrouchToggle:OnChanged(function(state)
    if autoCrouchGui then
        autoCrouchGui.Enabled = state
        if autoCrouchGuiButton then
            autoCrouchGuiButton.Text = state and "On" or "Off"
            autoCrouchGuiButton.BackgroundColor3 = state and Color3.fromRGB(0, 120, 80) or Color3.fromRGB(120, 0, 0)
        end
    end
end)

GravityToggle:OnChanged(function(state)
    if gravityGui then
        gravityGui.Enabled = state
        if gravityGuiButton then
            gravityGuiButton.Text = state and "On" or "Off"
            gravityGuiButton.BackgroundColor3 = state and Color3.fromRGB(0, 120, 80) or Color3.fromRGB(120, 0, 0)
        end
    end
end)

AutoCarryToggle:OnChanged(function(state)
    if autoCarryGui then
        autoCarryGui.Enabled = state
        if autoCarryGuiButton then
            autoCarryGuiButton.Text = state and "On" or "Off"
            autoCarryGuiButton.BackgroundColor3 = state and Color3.fromRGB(0, 120, 80) or Color3.fromRGB(120, 0, 0)
        end
    end
end)

LagSwitchToggle:OnChanged(function(state)
    if lagGui then
        lagGui.Enabled = state
    end
end)
--#endregion

--#region Event Connections
local function onCharacterAdded()
    task.wait(1)
    applyStoredSettings()
    -- Re-setup bounce if it was active
    if featureStates.Bounce then
        startBounce()
    end
end

player.CharacterAdded:Connect(onCharacterAdded)
if player.Character then
    onCharacterAdded()
end

-- Mobile Bhop Hold Detection
spawn(function()
    local success, err = pcall(function()
        local touchGui = player:WaitForChild("PlayerGui"):WaitForChild("TouchGui", 5)
        if not touchGui then return end
        local touchControlFrame = touchGui:WaitForChild("TouchControlFrame", 5)
        if not touchControlFrame then return end
        local jumpButton = touchControlFrame:WaitForChild("JumpButton", 5)
        if not jumpButton then return end

        jumpButton.MouseButton1Down:Connect(function()
            getgenv().bhopHoldActive = true
        end)

        jumpButton.MouseButton1Up:Connect(function()
            getgenv().bhopHoldActive = false
        end)
    end)
    -- Error handling is done within the pcall
end)
--#endregion

--#region Config Manager Setup
configFile = ConfigManager:CreateConfig(configName)

-- Register all toggles and inputs for saving/loading
configFile:Register("BhopToggle", BhopToggle)
configFile:Register("BhopModeDropdown", BhopModeDropdown)
configFile:Register("BhopAccelInput", BhopAccelInput)
configFile:Register("AutoCrouchToggle", AutoCrouchToggle)
configFile:Register("AutoCrouchModeDropdown", AutoCrouchModeDropdown)
configFile:Register("BounceToggle", BounceToggle)
configFile:Register("BounceHeightInput", BounceHeightInput)
configFile:Register("EpsilonInput", EpsilonInput)
configFile:Register("GravityToggle", GravityToggle)
configFile:Register("GravityInput", GravityInput)
configFile:Register("AutoCarryToggle", AutoCarryToggle)
configFile:Register("StrafeInput", StrafeInput)
configFile:Register("JumpCapInput", JumpCapInput)
configFile:Register("SpeedInput", SpeedInput)
configFile:Register("ApplyMethodDropdown", ApplyMethodDropdown)
configFile:Register("TimerDisplayToggle", TimerDisplayToggle)
configFile:Register("LagSwitchToggle", LagSwitchToggle)
configFile:Register("LagDurationInput", LagDurationInput)
configFile:Register("ButtonSizeXInput", ButtonSizeXInput)
configFile:Register("ButtonSizeYInput", ButtonSizeYInput)

--#endregion

--#region Save & Load Buttons
Tabs.Settings:Button({
    Title = "Save Config",
    Icon = "save",
    Callback = function()
        configFile:Set("playerData", { -- Example: Save other player-specific data
            guiButtonSizeX = getgenv().guiButtonSizeX,
            guiButtonSizeY = getgenv().guiButtonSizeY,
            -- Add other non-UI data if needed
        })
        configFile:Set("lastSave", os.date("%Y-%m-%d %H:%M:%S"))
        configFile:Save()
        WindUI:Notify({
            Title = "Config",
            Content = "Configuration saved!",
            Duration = 2
        })
    end
})

Tabs.Settings:Button({
    Title = "Load Config",
    Icon = "folder",
    Callback = function()
        local loadedData = configFile:Load()
        if loadedData then
            -- Apply loaded data to UI elements
            if loadedData.playerData then
                local data = loadedData.playerData
                getgenv().guiButtonSizeX = data.guiButtonSizeX or 60
                getgenv().guiButtonSizeY = data.guiButtonSizeY or 60
                -- Update input fields visually
                ButtonSizeXInput:Set({ Value = tostring(getgenv().guiButtonSizeX) })
                ButtonSizeYInput:Set({ Value = tostring(getgenv().guiButtonSizeY) })
            end
            -- The ConfigManager should automatically apply values to registered UI elements

            -- Re-create GUIs to reflect loaded sizes and states
            createBhopGui()
            createAutoCrouchGui()
            createGravityGui()
            createAutoCarryGui()
            createLagSwitchGui()

            -- Apply stored settings based on loaded config
            appliedOnce = false -- Reset flag to re-apply settings
            task.wait(0.1) -- Small delay to ensure UI is updated
            applyStoredSettings()

            WindUI:Notify({
                Title = "Config",
                Content = "Configuration loaded!",
                Duration = 2
            })
        else
            WindUI:Notify({
                Title = "Config",
                Content = "No saved config found!",
                Duration = 2
            })
        end
    end
})
--#endregion

--#region Initialize GUIs
createBhopGui()
createAutoCrouchGui()
createGravityGui()
createAutoCarryGui()
createLagSwitchGui()
--#endregion
