if getgenv().MovementHubExecuted then return end
getgenv().MovementHubExecuted = true

-- UI Library
local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()

local Window = WindUI:Window({
    Name = "Movement Hub",
    Configuration = true,
    ConfigurationFolder = "MovementHubConfigs",
    ConfigurationFile = "config"
})

local Tabs = {
    Player = Window:Tab({Name = "Player", Icon = "user", Order = 1}),
    Auto = Window:Tab({Name = "Auto", Icon = "settings", Order = 2}),
    Visuals = Window:Tab({Name = "Visuals", Icon = "eye", Order = 3})
}

-- Variables
local BOUNCE_HEIGHT = 5
local BOUNCE_EPSILON = 0.1
local BOUNCE_ENABLED = false
local touchConnections = {}
local originalFOV = workspace.CurrentCamera.FieldOfView
local originalBrightness, originalOutdoorAmbient, originalAmbient, originalGlobalShadows
local AntiAFKConnection
local VirtualUser = game:GetService("VirtualUser")
local cachedTables
local slideConnection
local infiniteSlideEnabled = false
local slideFrictionValue = 0.5
local jumpCount = 0
local featureStates = {
    Bhop = false,
    BhopHold = false,
    AutoCrouch = false,
    AutoCrouchMode = "Air",
    Bounce = false,
    CustomGravity = false,
    GravityValue = workspace.Gravity,
    TimerDisplay = false,
}
local currentSettings = {
    AirStrafeAcceleration = 187,
    JumpCap = 1,
    Speed = 1500, -- Updated default value
    JumpHeight = 50
}
local character, humanoid, rootPart
local previousCrouchState = false
local spamDown = true
local uiToggledViaUI = false
local isMobile = UserInputService.TouchEnabled
local autoJumpEnabled = false
local bhopMode = "Acceleration"
local bhopAccelValue = -0.1
local bhopHoldActive = false
local ApplyMode = "Optimized"
local SelectedEmote = nil
local autoCarryGuiVisible = false

-- Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local MarketplaceService = game:GetService("MarketplaceService")
local Debris = game:GetService("Debris")
local LocalPlayer = Players.LocalPlayer
local playerGui = LocalPlayer:WaitForChild("PlayerGui")
local workspace = game:GetService("Workspace")
local originalGameGravity = workspace.Gravity
local camera = workspace.CurrentCamera

-- GUI Creation Helper
local function createToggleGui(title, enabledVariable, yPosition, buttonSizeX, buttonSizeY)
    local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
    local existingGui = playerGui:FindFirstChild(title .. "Gui")
    if existingGui then existingGui:Destroy() end

    local gui = Instance.new("ScreenGui")
    gui.Name = title .. "Gui"
    gui.IgnoreGuiInset = true
    gui.ResetOnSpawn = false
    gui.Enabled = false -- Initially disabled, enabled by toggle
    gui.Parent = playerGui

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, buttonSizeX, 0, buttonSizeY * 2 + 10) -- Height for label and button
    frame.Position = UDim2.new(0.5, -buttonSizeX/2, yPosition, 0) -- Centered horizontally
    frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    frame.BorderSizePixel = 0
    frame.Parent = gui

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0.5, -5) -- Half the frame height minus padding
    label.Position = UDim2.new(0, 0, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = title
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextScaled = true
    label.Font = Enum.Font.Gotham
    label.Parent = frame

    local toggleButton = Instance.new("TextButton")
    toggleButton.Size = UDim2.new(1, 0, 0.5, -5) -- Half the frame height minus padding
    toggleButton.Position = UDim2.new(0, 0, 0.5, 5) -- Below the label with padding
    toggleButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0) -- Off state
    toggleButton.Text = "Off"
    toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggleButton.TextScaled = true
    toggleButton.Font = Enum.Font.Gotham
    toggleButton.BorderSizePixel = 0
    toggleButton.Parent = frame

    toggleButton.MouseButton1Click:Connect(function()
        getgenv()[enabledVariable] = not getgenv()[enabledVariable]
        toggleButton.Text = getgenv()[enabledVariable] and "On" or "Off"
        toggleButton.BackgroundColor3 = getgenv()[enabledVariable] and Color3.fromRGB(0, 120, 80) or Color3.fromRGB(120, 0, 0)
        gui.Enabled = isMobile or getgenv()[enabledVariable] -- Enable GUI if mobile or if toggle is on
    end)

    -- Sync initial state
    toggleButton.Text = getgenv()[enabledVariable] and "On" or "Off"
    toggleButton.BackgroundColor3 = getgenv()[enabledVariable] and Color3.fromRGB(0, 120, 80) or Color3.fromRGB(120, 0, 0)
    gui.Enabled = isMobile or getgenv()[enabledVariable]

    return gui, toggleButton
end

-- Auto Crouch Logic
local function fireKeybind(down, key)
    local ohTable = {["Down"] = down, ["Key"] = key}
    local event = game:GetService("Players").LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild("Events"):WaitForChild("temporary_events"):WaitForChild("UseKeybind")
    event:Fire(ohTable)
end

local function updateAutoCrouch()
    if not featureStates.AutoCrouch then
        if previousCrouchState then
            fireKeybind(false, "Crouch")
            previousCrouchState = false
        end
        return
    end

    local character = Players.LocalPlayer.Character
    if not character or not character:FindFirstChild("Humanoid") then return end
    local humanoid = character.Humanoid
    local mode = featureStates.AutoCrouchMode
    if mode == "Normal" then
        fireKeybind(spamDown, "Crouch")
        spamDown = not spamDown
    else
        local isAir = (humanoid.FloorMaterial == Enum.Material.Air) and (humanoid:GetState() ~= Enum.HumanoidStateType.Seated)
        local shouldCrouch = (mode == "Air" and isAir) or (mode == "Ground" and not isAir)

        if shouldCrouch ~= previousCrouchState then
            fireKeybind(shouldCrouch, "Crouch")
            previousCrouchState = shouldCrouch
        end
    end
end

-- Bounce Logic
local function bouncePlayer(character)
    if not character or not BOUNCE_ENABLED then return end
    local humanoid = character:FindFirstChild("Humanoid")
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoid or not humanoidRootPart then return end

    humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    task.wait(0.1) -- Small delay for consistency
end

local function setupBounceOnTouch(character)
    if not BOUNCE_ENABLED then return end
    local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

    if touchConnections[character] then
        touchConnections[character]:Disconnect()
        touchConnections[character] = nil
    end

    local touchConnection
    touchConnection = humanoidRootPart.Touched:Connect(function(hit)
        local playerBottom = humanoidRootPart.Position.Y - humanoidRootPart.Size.Y / 2
        local hitTop = hit.Position.Y + hit.Size.Y / 2
        local distance = math.abs(playerBottom - hitTop)

        if distance < BOUNCE_EPSILON then
            bouncePlayer(character)
        end
    end)
    touchConnections[character] = touchConnection
end

local function disableBounce()
    for char, connection in pairs(touchConnections) do
        if connection then
            connection:Disconnect()
        end
    end
    touchConnections = {}
    BOUNCE_ENABLED = false
end

-- Visual Functions
local function startFullBright()
    originalBrightness = workspace.Lighting.Brightness
    originalOutdoorAmbient = workspace.Lighting.OutdoorAmbient
    originalAmbient = workspace.Lighting.Ambient
    originalGlobalShadows = workspace.Lighting.GlobalShadows

    workspace.Lighting.Brightness = 2
    workspace.Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
    workspace.Lighting.Ambient = Color3.fromRGB(255, 255, 255)
    workspace.Lighting.GlobalShadows = false
end

local function stopFullBright()
    if originalBrightness then workspace.Lighting.Brightness = originalBrightness end
    if originalOutdoorAmbient then workspace.Lighting.OutdoorAmbient = originalOutdoorAmbient end
    if originalAmbient then workspace.Lighting.Ambient = originalAmbient end
    if originalGlobalShadows then workspace.Lighting.GlobalShadows = originalGlobalShadows end
end

local function startNoFog()
    workspace.Lighting.FogEnd = 9e9
    workspace.Lighting.FogStart = 0
end

local function stopNoFog()
    workspace.Lighting.FogEnd = 100000 -- Default value, adjust if needed
    workspace.Lighting.FogStart = 0
end

-- Player Tab
Tabs.Player:Section({ Title = "Movement Settings", TextSize = 20 })

-- Bhop Section
Tabs.Player:Section({ Title = "Bhop", TextSize = 16 })
local BhopToggle = Tabs.Player:Toggle({
    Title = "Bhop",
    Value = false,
    Callback = function(state)
        featureStates.Bhop = state
        if not state then
            getgenv().autoJumpEnabled = false
            if bhopGui and bhopToggleBtn then
                bhopGui.Enabled = false -- Disable GUI when feature is off
                bhopToggleBtn.Text = "Off"
                bhopToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
            end
        else
            -- Ensure GUI is enabled if mobile or if toggled via UI
            if bhopGui then
                bhopGui.Enabled = UserInputService.TouchEnabled or true
            end
        end
        -- Ensure PlayerGui exists before accessing
        if LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui") then
            local gui = LocalPlayer.PlayerGui:FindFirstChild("BhopGui")
            if gui then
                gui.Enabled = state
            end
        end
    end
})

local bhopGui, bhopToggleBtn = createToggleGui("Bhop", "autoJumpEnabled", 0.12, 100, 25) -- X=100, Y=25

local BhopModeDropdown = Tabs.Player:Dropdown({
    Title = "Bhop Mode",
    Values = {"Acceleration", "No Acceleration"},
    Multi = false,
    Default = "Acceleration",
    Callback = function(value)
        getgenv().bhopMode = value
    end
})

local BhopAccelInput = Tabs.Player:Input({
    Title = "Bhop Acceleration (Negative Only)",
    Placeholder = "-0.5",
    Numeric = true,
    Callback = function(value)
        if tostring(value):sub(1, 1) == "-" then
            local n = tonumber(value)
            if n then getgenv().bhopAccelValue = n end
        end
    end
})

local BhopHoldToggle = Tabs.Player:Toggle({
    Title = "Bhop (Hold Space)",
    Value = false,
    Callback = function(state)
        featureStates.BhopHold = state
        if not state then
            getgenv().bhopHoldActive = false
        end
    end
})

-- Bounce Section
Tabs.Player:Section({ Title = "Bounce", TextSize = 16 })
local BounceToggle = Tabs.Player:Toggle({
    Title = "Enable Bounce",
    Value = false,
    Callback = function(state)
        BOUNCE_ENABLED = state
        if state then
            if LocalPlayer.Character then
                setupBounceOnTouch(LocalPlayer.Character)
            end
        else
            disableBounce()
        end
        BounceHeightInput:Set({ Enabled = state })
        EpsilonInput:Set({ Enabled = state })
    end
})

local BounceHeightInput = Tabs.Player:Input({
    Title = "Bounce Height",
    Placeholder = "5",
    Value = tostring(BOUNCE_HEIGHT),
    Numeric = true,
    Enabled = false,
    Callback = function(value)
        local num = tonumber(value)
        if num then BOUNCE_HEIGHT = math.max(0, num) end
    end
})

local EpsilonInput = Tabs.Player:Input({
    Title = "Touch Detection Epsilon",
    Placeholder = "0.1",
    Value = tostring(BOUNCE_EPSILON),
    Numeric = true,
    Enabled = false,
    Callback = function(value)
        local num = tonumber(value)
        if num then BOUNCE_EPSILON = math.max(0, num) end
    end
})

-- Other Player Settings
Tabs.Player:Section({ Title = "Other Player Settings", TextSize = 20 })

local StrafeInput = Tabs.Player:Input({
    Title = "Strafe Acceleration",
    Icon = "wind",
    Placeholder = "Default 187",
    Value = tostring(currentSettings.AirStrafeAcceleration),
    Callback = function(value)
        local num = tonumber(value)
        if num then
            currentSettings.AirStrafeAcceleration = num
            -- Apply to game tables if needed
        end
    end
})

local JumpCapInput = Tabs.Player:Input({
    Title = "Jump Cap",
    Icon = "chevrons-up",
    Placeholder = "Default 1",
    Value = tostring(currentSettings.JumpCap),
    Callback = function(value)
        local num = tonumber(value)
        if num then
            currentSettings.JumpCap = num
            -- Apply to game tables if needed
        end
    end
})

local SpeedInput = Tabs.Player:Input({
    Title = "Speed",
    Placeholder = "Default 1500",
    Value = tostring(currentSettings.Speed),
    Callback = function(value)
        local num = tonumber(value)
        if num then
            currentSettings.Speed = num
            -- Apply to game tables if needed
        end
    end
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

-- Auto Tab
Tabs.Auto:Section({ Title = "Auto Features", TextSize = 20 })

-- Auto Crouch Section
Tabs.Auto:Section({ Title = "Auto Crouch", TextSize = 16 })
local AutoCrouchToggle = Tabs.Auto:Toggle({
    Title = "Auto Crouch",
    Value = false,
    Callback = function(state)
        featureStates.AutoCrouch = state
        -- Create or update GUI for mobile/quick access if needed
        -- For now, just update the state and logic loop
    end
})

local AutoCrouchModeDropdown = Tabs.Auto:Dropdown({
    Title = "Auto Crouch Mode",
    Values = {"Air", "Normal", "Ground"},
    Value = "Air",
    Callback = function(value)
        featureStates.AutoCrouchMode = value
    end
})

-- Visuals Tab
Tabs.Visuals:Section({ Title = "Visual Settings", TextSize = 20 })

local FullBrightToggle = Tabs.Visuals:Toggle({
    Title = "FullBright",
    Value = false,
    Callback = function(state)
        featureStates.FullBright = state
        if state then
            startFullBright()
        else
            stopFullBright()
        end
    end
})

local NoFogToggle = Tabs.Visuals:Toggle({
    Title = "Remove Fog",
    Value = false,
    Callback = function(state)
        featureStates.NoFog = state
        if state then
            startNoFog()
        else
            stopNoFog()
        end
    end
})

local TimerDisplayToggle = Tabs.Visuals:Toggle({
    Title = "Display Timer",
    Value = true, -- Assuming TimerGUI should be enabled by default if this toggle exists
    Callback = function(state)
        -- This toggle might just represent the intent; the actual GUI creation is handled by the loadstring
        -- We could potentially enable/disable the GUI created by the loadstring here if we had a reference to it
        -- For now, we'll just log the state change or let the loadstring handle it
        print("Timer Display Toggle: ", state)
    end
})

-- Main Execution Loops
RunService.Heartbeat:Connect(function()
    -- Auto Crouch Loop
    updateAutoCrouch()

    -- Bhop Logic Loop
    local isBhopActive = getgenv().autoJumpEnabled or getgenv().bhopHoldActive
    if isBhopActive then
        local character = LocalPlayer.Character
        if character and character:FindFirstChild("Humanoid") then
            local humanoid = character.Humanoid
            if humanoid:GetState() ~= Enum.HumanoidStateType.Jumping and humanoid:GetState() ~= Enum.HumanoidStateType.Freefall then
                humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end
        if getgenv().bhopMode == "No Acceleration" then
            task.wait(0.05) -- Slight delay for no acceleration mode
        else
            task.wait() -- Yield for acceleration mode
        end
    else
        task.wait() -- Yield if bhop is inactive
    end
end)

RunService.Heartbeat:Connect(function()
    -- Friction Adjustment Loop (for Bhop Acceleration mode)
    local friction = 5 -- Default friction
    local isBhopActive = getgenv().autoJumpEnabled or getgenv().bhopHoldActive
    if isBhopActive and getgenv().bhopMode == "Acceleration" then
        friction = getgenv().bhopAccelValue or -0.5
    end

    for _, t in pairs(getgc(true)) do
        if type(t) == "table" and rawget(t, "Friction") then
            if getgenv().bhopMode == "No Acceleration" then
                -- Keep default friction or set to a specific value if needed
                -- t.Friction = default_friction_value -- Define if needed
            else
                t.Friction = friction
            end
        end
    end
end)

-- Input Handling
UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
    if gameProcessedEvent then return end

    if input.KeyCode == Enum.KeyCode.B then
        getgenv().autoJumpEnabled = not getgenv().autoJumpEnabled
        if bhopGui and bhopToggleBtn then
            bhopToggleBtn.Text = getgenv().autoJumpEnabled and "On" or "Off"
            bhopToggleBtn.BackgroundColor3 = getgenv().autoJumpEnabled and Color3.fromRGB(0, 120, 80) or Color3.fromRGB(0, 0, 0)
            bhopGui.Enabled = UserInputService.TouchEnabled or getgenv().autoJumpEnabled
        end
        BhopToggle:Set(getgenv().autoJumpEnabled) -- Sync the UI toggle
    end

    if input.KeyCode == Enum.KeyCode.Space and featureStates.BhopHold then
        getgenv().bhopHoldActive = true
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.Space then
        getgenv().bhopHoldActive = false
    end
end)

-- Character Handling
Players.LocalPlayer.CharacterAdded:Connect(function(newChar)
    -- Reset Auto Crouch state
    previousCrouchState = false
    spamDown = true

    -- Reapply Bounce if enabled
    if BOUNCE_ENABLED then
        setupBounceOnTouch(newChar)
    end
end)

-- Execute the additional loadstring
task.spawn(function()
    local success, err = pcall(function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/Hajipak/Evade/refs/heads/main/Script/More-loadstring.lua"))()
    end)
    if not success then
        warn("Failed to execute More-loadstring.lua: " .. tostring(err))
    end
end)
