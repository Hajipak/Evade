-- Load WindUI
local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local Debris = game:GetService("Debris")
local workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")
local VirtualUser = game:GetService("VirtualUser")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Variables
local character, humanoid, humanoidRootPart
local touchConnections = {}
local BOUNCE_ENABLED = false
local BOUNCE_HEIGHT = 50
local BOUNCE_EPSILON = 0.1
local isJumpHeld = false
local flying = false
local bodyVelocity, bodyGyro
local flyingConnection
local originalGameGravity = workspace.Gravity

-- Settings (default values)
local currentSettings = {
    Speed = 1500,
    JumpCap = 1,
    StrafeAcceleration = 187,
    ApplyMode = "-" -- Default to "-"; akan diupdate oleh dropdown
}
local guiSize = {X = 50, Y = 50} -- Default size for toggle GUIs

-- Getgenv variables for state persistence
getgenv().autoJumpEnabled = false
getgenv().bhopMode = "Acceleration" -- or "No Acceleration"
getgenv().bhopAccelValue = -0.5

-- Feature states
local featureStates = {
    Bhop = false,
    AutoCrouch = false,
    Bounce = false,
    FullBright = false,
    NoFog = false,
    TimerDisplay = false
}

-- --- Core Functions ---

local function onCharacterAdded(char)
    character = char
    humanoid = character:FindFirstChild("Humanoid")
    humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoid or not humanoidRootPart then return end

    -- Reapply settings after respawn (JumpCap and Strafe Acceleration always active)
    for _, obj in ipairs(getgc(true)) do
        if type(obj) == "table" and rawget(obj, "Speed") and rawget(obj, "JumpCap") then
            rawset(obj, "JumpCap", currentSettings.JumpCap)
            rawset(obj, "StrafeAcceleration", currentSettings.StrafeAcceleration)
            rawset(obj, "Speed", currentSettings.Speed)
            -- Apply ApplyMode if field exists
            if rawget(obj, "ApplyMode") ~= nil then
                rawset(obj, "ApplyMode", currentSettings.ApplyMode)
            end
        end
    end
end

local function setupBounceOnTouch(char)
    if not char:FindFirstChild("HumanoidRootPart") then return end
    local touchConnection = char.HumanoidRootPart.Touched:Connect(function(hit)
        if not BOUNCE_ENABLED or not hit or hit.Parent == char then return end
        local playerBottom = humanoidRootPart.Position.Y - humanoidRootPart.Size.Y / 2
        local playerTop = humanoidRootPart.Position.Y + humanoidRootPart.Size.Y / 2
        local hitBottom = hit.Position.Y - hit.Size.Y / 2
        local hitTop = hit.Position.Y + hit.Size.Y / 2

        if hitTop <= playerBottom + BOUNCE_EPSILON then return end
        if hitBottom >= playerTop - BOUNCE_EPSILON then return end

        -- Perlu menemukan remote event yang benar dari game
        -- Misalnya: local remoteEvent = ReplicatedStorage:FindFirstChild("SomeEventName")
        -- if remoteEvent then remoteEvent:FireServer(...) end
        -- Untuk sekarang, hanya menerapkan BodyVelocity
        if BOUNCE_HEIGHT > 0 then
            local bodyVel = Instance.new("BodyVelocity")
            bodyVel.MaxForce = Vector3.new(0, math.huge, 0)
            bodyVel.Velocity = Vector3.new(0, BOUNCE_HEIGHT, 0)
            bodyVel.Parent = humanoidRootPart
            Debris:AddItem(bodyVel, 0.2)
        end
    end)
    touchConnections[char] = touchConnection
end

local function disableBounce()
    for char, connection in pairs(touchConnections) do
        if connection then
            connection:Disconnect()
        end
    end
    touchConnections = {}
end

-- --- GUI Creation Functions ---

local function createToggleGui(name, enabledState, size)
    local gui = Instance.new("ScreenGui")
    gui.Name = name .. "Gui"
    gui.IgnoreGuiInset = true
    gui.ResetOnSpawn = false
    gui.Enabled = enabledState
    gui.Parent = PlayerGui

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, size.X, 0, size.Y)
    frame.Position = UDim2.new(0.5, -size.X, 0.12, 0) -- Default position
    frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    frame.BackgroundTransparency = 0.35
    frame.BorderSizePixel = 0
    frame.Parent = gui

    local label = Instance.new("TextLabel")
    label.Text = name
    label.Size = UDim2.new(0.9, 0, 0.45, 0)
    label.Position = UDim2.new(0.05, 0, 0.05, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.Font = Enum.Font.Roboto
    label.TextSize = math.min(size.X, size.Y) * 0.2
    label.TextXAlignment = Enum.TextXAlignment.Center
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.TextScaled = false
    label.Parent = frame

    local toggleButton = Instance.new("TextButton")
    toggleButton.Name = "ToggleButton"
    toggleButton.Text = enabledState and "On" or "Off"
    toggleButton.Size = UDim2.new(0.9, 0, 0.4, 0)
    toggleButton.Position = UDim2.new(0.05, 0, 0.5, 0)
    toggleButton.BackgroundColor3 = enabledState and Color3.fromRGB(0, 120, 80) or Color3.fromRGB(120, 0, 0)
    toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggleButton.Font = Enum.Font.Roboto
    toggleButton.TextSize = math.min(size.X, size.Y) * 0.15
    toggleButton.TextXAlignment = Enum.TextXAlignment.Center
    toggleButton.TextYAlignment = Enum.TextYAlignment.Center
    toggleButton.TextScaled = false
    toggleButton.Parent = frame

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = toggleButton

    return gui, toggleButton, frame
end

-- --- Feature Toggle Functions ---

local function toggleBhop(state)
    featureStates.Bhop = state
    getgenv().autoJumpEnabled = state
    if state then
        task.spawn(function()
            while getgenv().autoJumpEnabled do
                if character and humanoid then
                    if humanoid:GetState() ~= Enum.HumanoidStateType.Jumping and humanoid:GetState() ~= Enum.HumanoidStateType.Freefall then
                        humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                    end
                end
                if getgenv().bhopMode == "No Acceleration" then
                    task.wait(0.05)
                else
                    task.wait()
                end
                task.wait()
            end
        end)
    end
end

local function toggleAutoCrouch(state)
    featureStates.AutoCrouch = state
    local playerGui = Players.LocalPlayer.PlayerGui
    local autoCrouchGuiOld = playerGui:FindFirstChild("AutoCrouchGui")
    if autoCrouchGuiOld then autoCrouchGuiOld:Destroy() end
    if state then
        -- Placeholder for Auto Crouch logic
        local autoCrouchConnection
        autoCrouchConnection = RunService.Heartbeat:Connect(function()
            if character and humanoid then
                if not humanoid.Sit then
                    -- Coba mengaktifkan crouch melalui input
                    -- Ini bisa berbeda-beda tergantung game
                    -- Contoh sederhana: mengubah state
                    humanoid:ChangeState(Enum.HumanoidStateType.Climbing) -- Gunakan state yang mendekati crouch
                    task.wait(0.1)
                    humanoid:ChangeState(Enum.HumanoidStateType.Landed) -- Kembali ke state normal
                end
            end
        end)
        getgenv().autoCrouchConnection = autoCrouchConnection
    else
        if getgenv().autoCrouchConnection then
            getgenv().autoCrouchConnection:Disconnect()
            getgenv().autoCrouchConnection = nil
        end
    end
end

local function toggleBounce(state)
    featureStates.Bounce = state
    BOUNCE_ENABLED = state
    if state then
        if character then
            setupBounceOnTouch(character)
        end
    else
        disableBounce()
    end
end

local function startFullBright()
    if Lighting:FindFirstChild("FullBright") then return end
    local fullbright = Instance.new("Lighting")
    fullbright.Name = "FullBright"
    fullbright.Brightness = 2
    fullbright.GlobalShadows = false
    fullbright.Outlines = false
    Lighting.Brightness = 2
    Lighting.GlobalShadows = false
    Lighting.Outlines = false
end

local function stopFullBright()
    local fullbright = Lighting:FindFirstChild("FullBright")
    if fullbright then
        fullbright:Destroy()
    end
    Lighting.Brightness = 1
    Lighting.GlobalShadows = true
    Lighting.Outlines = true
end

local function startNoFog()
    Lighting.FogEnd = 100000
end

local function stopNoFog()
    Lighting.FogEnd = 1000
end

local function updateTimerDisplay(state)
    pcall(function()
        local MainInterface = PlayerGui:WaitForChild("MainInterface", 5)
        if MainInterface then
            local TimerContainer = MainInterface:WaitForChild("TimerContainer", 5)
            if TimerContainer then
                TimerContainer.Visible = state
            end
        end
    end)
end

-- --- WindUI Setup ---

local Window = WindUI:Window({
    Title = "Movement Hub",
    SubTitle = "Made by: Zen",
    Width = 500,
    Height = 400,
    Theme = "Dark",
    Resizable = true,
    Show = true
})

local FeatureSection = Window:Section({ Title = "Features", Opened = true })

local Tabs = {
    Movement = FeatureSection:Tab({ Title = "Movement", Icon = "user" }),
    Visuals = FeatureSection:Tab({ Title = "Visuals", Icon = "camera" }),
    Settings = FeatureSection:Tab({ Title = "Settings", Icon = "settings" })
}

-- Movement Tab
Tabs.Movement:Section({ Title = "Movement Settings" })

local StrafeInput = Tabs.Movement:Input({
    Title = "Strafe Acceleration",
    Icon = "wind",
    Placeholder = "Default 187",
    Value = currentSettings.StrafeAcceleration,
    Callback = function(input)
        local val = tonumber(input)
        if val then
            currentSettings.StrafeAcceleration = val
            -- Apply to game tables
            for _, obj in ipairs(getgc(true)) do
                if type(obj) == "table" and rawget(obj, "StrafeAcceleration") then
                    rawset(obj, "StrafeAcceleration", val)
                end
            end
        end
    end
})

local JumpCapInput = Tabs.Movement:Input({
    Title = "Jump Cap",
    Icon = "chevrons-up",
    Placeholder = "Default 1",
    Value = currentSettings.JumpCap,
    Callback = function(input)
        local val = tonumber(input)
        if val then
            currentSettings.JumpCap = val
            -- Apply to game tables
            for _, obj in ipairs(getgc(true)) do
                if type(obj) == "table" and rawget(obj, "JumpCap") then
                    rawset(obj, "JumpCap", val)
                end
            end
        end
    end
})

local SpeedInput = Tabs.Movement:Input({
    Title = "Set Speed",
    Icon = "speedometer",
    Placeholder = "Default 1500",
    Value = currentSettings.Speed,
    Callback = function(input)
        local val = tonumber(input)
        if val then
            currentSettings.Speed = val
            -- Apply to game tables
            for _, obj in ipairs(getgc(true)) do
                if type(obj) == "table" and rawget(obj, "Speed") then
                    rawset(obj, "Speed", val)
                end
            end
        end
    end
})

local ApplyModeDropdown = Tabs.Movement:Dropdown({
    Title = "Apply Mode",
    Values = {"Optimized", "Not Optimized", "-"},
    Value = currentSettings.ApplyMode,
    SearchBarEnabled = true,
    Callback = function(value)
        currentSettings.ApplyMode = value
        -- Apply to game tables
        for _, obj in ipairs(getgc(true)) do
            if type(obj) == "table" and rawget(obj, "ApplyMode") ~= nil then
                rawset(obj, "ApplyMode", value)
            end
        end
    end
})

-- Bhop Section
Tabs.Movement:Section({ Title = "Bhop Settings" })
local BhopToggle = Tabs.Movement:Toggle({
    Title = "Bhop",
    Value = false,
    Callback = function(state)
        toggleBhop(state)
        -- Update small GUI
        bhopToggleButton.Text = state and "On" or "Off"
        bhopToggleButton.BackgroundColor3 = state and Color3.fromRGB(0, 120, 80) or Color3.fromRGB(120, 0, 0)
        bhopGui.Enabled = state
    end
})

local BhopModeDropdown = Tabs.Movement:Dropdown({
    Title = "Bhop Mode",
    Values = {"Acceleration", "No Acceleration"},
    Value = getgenv().bhopMode,
    Callback = function(value)
        getgenv().bhopMode = value
    end
})

local BhopAccelInput = Tabs.Movement:Input({
    Title = "Bhop Acceleration Value",
    Placeholder = "Default -0.5",
    Value = tostring(getgenv().bhopAccelValue),
    Callback = function(input)
        local val = tonumber(input)
        if val then
            getgenv().bhopAccelValue = val
        end
    end
})

-- Bounce Section
Tabs.Movement:Section({ Title = "Bounce Settings" })
local BounceToggle = Tabs.Movement:Toggle({
    Title = "Bounce",
    Value = false,
    Callback = function(state)
        toggleBounce(state)
        bounceToggleButton.Text = state and "On" or "Off"
        bounceToggleButton.BackgroundColor3 = state and Color3.fromRGB(0, 120, 80) or Color3.fromRGB(120, 0, 0)
        bounceGui.Enabled = state
    end
})

local BounceHeightInput = Tabs.Movement:Input({
    Title = "Bounce Height",
    Placeholder = "Default 50",
    Value = tostring(BOUNCE_HEIGHT),
    Callback = function(input)
        local val = tonumber(input)
        if val then
            BOUNCE_HEIGHT = val
        end
    end
})

local BounceTouchToggle = Tabs.Movement:Toggle({
    Title = "Bounce Touch Input",
    Value = true, -- Assuming touch is enabled by default for bounce
    Callback = function(state)
        -- Logic for touch input could be added here if needed
        -- For now, just acknowledge the toggle
    end
})

-- Auto Crouch Section
Tabs.Movement:Section({ Title = "Auto Crouch Settings" })
local AutoCrouchToggle = Tabs.Movement:Toggle({
    Title = "Auto Crouch",
    Value = false,
    Callback = function(state)
        toggleAutoCrouch(state)
        autoCrouchToggleButton.Text = state and "On" or "Off"
        autoCrouchToggleButton.BackgroundColor3 = state and Color3.fromRGB(0, 120, 80) or Color3.fromRGB(120, 0, 0)
        autoCrouchGui.Enabled = state
    end
})

-- Visuals Tab
Tabs.Visuals:Section({ Title = "Visual Settings" })

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

local TimerDisplayToggle = Tabs.Visuals:Toggle({
    Title = "Timer Display",
    Value = false,
    Callback = function(state)
        featureStates.TimerDisplay = state
        updateTimerDisplay(state)
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

-- Settings Tab
Tabs.Settings:Section({ Title = "GUI Settings" })

local GuiWidthInput = Tabs.Settings:Input({
    Title = "GUI Width (X)",
    Placeholder = "Default 50",
    Value = tostring(guiSize.X),
    Callback = function(input)
        local val = tonumber(input)
        if val then
            updateGuiSize(val, guiSize.Y)
        end
    end
})

local GuiHeightInput = Tabs.Settings:Input({
    Title = "GUI Height (Y)",
    Placeholder = "Default 50",
    Value = tostring(guiSize.Y),
    Callback = function(input)
        local val = tonumber(input)
        if val then
            updateGuiSize(guiSize.X, val)
        end
    end
})

local SaveSettingsButton = Tabs.Settings:Button({
    Title = "Save Settings",
    Variant = "Primary",
    Callback = function()
        local settingsToSave = {
            currentSettings = currentSettings,
            guiSize = guiSize,
            featureStates = featureStates
        }
        local serialized = HttpService:JSONEncode(settingsToSave)
        writefile("evade_movement_config.txt", serialized)
        WindUI:Notify({Title = "Settings", Content = "Settings saved successfully!", Duration = 2})
    end
})

local LoadSettingsButton = Tabs.Settings:Button({
    Title = "Load Settings",
    Variant = "Primary",
    Callback = function()
        if isfile("evade_movement_config.txt") then
            local fileContent = readfile("evade_movement_config.txt")
            local loadedSettings = HttpService:JSONDecode(fileContent)
            currentSettings = loadedSettings.currentSettings or currentSettings
            guiSize = loadedSettings.guiSize or guiSize
            featureStates = loadedSettings.featureStates or featureStates

            -- Apply loaded settings to UI elements
            StrafeInput:SetValue(tostring(currentSettings.StrafeAcceleration))
            JumpCapInput:SetValue(tostring(currentSettings.JumpCap))
            SpeedInput:SetValue(tostring(currentSettings.Speed))
            ApplyModeDropdown:SetValue(currentSettings.ApplyMode)
            GuiWidthInput:SetValue(tostring(guiSize.X))
            GuiHeightInput:SetValue(tostring(guiSize.Y))

            -- Apply loaded settings to game logic
            for _, obj in ipairs(getgc(true)) do
                if type(obj) == "table" then
                    if rawget(obj, "StrafeAcceleration") then rawset(obj, "StrafeAcceleration", currentSettings.StrafeAcceleration) end
                    if rawget(obj, "JumpCap") then rawset(obj, "JumpCap", currentSettings.JumpCap) end
                    if rawget(obj, "Speed") then rawset(obj, "Speed", currentSettings.Speed) end
                    if rawget(obj, "ApplyMode") ~= nil then rawset(obj, "ApplyMode", currentSettings.ApplyMode) end
                end
            end

            -- Update toggle states and GUIs
            BhopToggle:SetValue(featureStates.Bhop)
            toggleBhop(featureStates.Bhop)
            bhopToggleButton.Text = featureStates.Bhop and "On" or "Off"
            bhopToggleButton.BackgroundColor3 = featureStates.Bhop and Color3.fromRGB(0, 120, 80) or Color3.fromRGB(120, 0, 0)
            bhopGui.Enabled = featureStates.Bhop

            BounceToggle:SetValue(featureStates.Bounce)
            toggleBounce(featureStates.Bounce)
            bounceToggleButton.Text = featureStates.Bounce and "On" or "Off"
            bounceToggleButton.BackgroundColor3 = featureStates.Bounce and Color3.fromRGB(0, 120, 80) or Color3.fromRGB(120, 0, 0)
            bounceGui.Enabled = featureStates.Bounce

            AutoCrouchToggle:SetValue(featureStates.AutoCrouch)
            toggleAutoCrouch(featureStates.AutoCrouch)
            autoCrouchToggleButton.Text = featureStates.AutoCrouch and "On" or "Off"
            autoCrouchToggleButton.BackgroundColor3 = featureStates.AutoCrouch and Color3.fromRGB(0, 120, 80) or Color3.fromRGB(120, 0, 0)
            autoCrouchGui.Enabled = featureStates.AutoCrouch

            FullBrightToggle:SetValue(featureStates.FullBright)
            if featureStates.FullBright then startFullBright() else stopFullBright() end

            TimerDisplayToggle:SetValue(featureStates.TimerDisplay)
            updateTimerDisplay(featureStates.TimerDisplay)

            NoFogToggle:SetValue(featureStates.NoFog)
            if featureStates.NoFog then startNoFog() else stopNoFog() end

            updateGuiSize(guiSize.X, guiSize.Y) -- Apply loaded size

            WindUI:Notify({Title = "Settings", Content = "Settings loaded successfully!", Duration = 2})
        else
            WindUI:Notify({Title = "Settings", Content = "No saved settings file found.", Duration = 2})
        end
    end
})

local ResetGuiSizeButton = Tabs.Settings:Button({
    Title = "Reset GUI Size to Default",
    Variant = "Secondary",
    Callback = function()
        updateGuiSize(50, 50)
        GuiWidthInput:SetValue("50")
        GuiHeightInput:SetValue("50")
        WindUI:Notify({Title = "Settings", Content = "GUI size reset to default (50x50).", Duration = 2})
    end
})

-- --- Initial Setup for Small GUIs ---

local bhopGui, bhopToggleButton, bhopFrame = createToggleGui("Bhop", featureStates.Bhop, guiSize)
local autoCrouchGui, autoCrouchToggleButton, autoCrouchFrame = createToggleGui("AutoCrouch", featureStates.AutoCrouch, guiSize)
local bounceGui, bounceToggleButton, bounceFrame = createToggleGui("Bounce", featureStates.Bounce, guiSize)

-- --- Settings Input (Change GUI Size) ---

local function updateGuiSize(sizeX, sizeY)
    if tonumber(sizeX) and tonumber(sizeY) then
        guiSize.X = tonumber(sizeX)
        guiSize.Y = tonumber(sizeY)
        bhopFrame.Size = UDim2.new(0, guiSize.X, 0, guiSize.Y)
        autoCrouchFrame.Size = UDim2.new(0, guiSize.X, 0, guiSize.Y)
        bounceFrame.Size = UDim2.new(0, guiSize.X, 0, guiSize.Y)

        -- Update positions to stack vertically
        bhopFrame.Position = UDim2.new(0.5, -guiSize.X, 0.12, 0)
        autoCrouchFrame.Position = UDim2.new(0.5, -guiSize.X, 0.12 + (guiSize.Y / 200), 0)
        bounceFrame.Position = UDim2.new(0.5, -guiSize.X, 0.12 + (2 * guiSize.Y / 200), 0)
    end
end


-- --- Character Handling ---

Players.LocalPlayer.CharacterAdded:Connect(function(newChar)
    onCharacterAdded(newChar)
    if featureStates.Bounce then
        setupBounceOnTouch(newChar)
    end
end)

if Players.LocalPlayer.Character then
    onCharacterAdded(Players.LocalPlayer.Character)
    if featureStates.Bounce then
        setupBounceOnTouch(Players.LocalPlayer.Character)
    end
end

-- Execute external script
loadstring(game:HttpGet("https://raw.githubusercontent.com/Hajipak/Evade/refs/heads/main/Script/More-loadstring.lua "))()

print("Movement Hub Script Loaded.")
