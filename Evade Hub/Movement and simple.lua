if getgenv().MovementExecuted then return end
getgenv().MovementExecuted = true

-- 1. Load Library (WindUI)
local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()

-- 2. Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local Debris = game:GetService("Debris")

-- 3. Variables
local LocalPlayer = Players.LocalPlayer
local playerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Konfigurasi Fitur
local featureStates = {
    Bhop = false,
    BhopHold = false,
    AutoCrouch = false,
    AutoCrouchMode = "Air", -- "Air", "Normal", "Ground"
    Bounce = false,
    FullBright = false,
    NoFog = false,
    TimerDisplay = false
}

-- Pengaturan Default
local currentSettings = {
    Speed = 16,
    JumpCap = 1,
    AirStrafeAcceleration = 187,
    ApplyMode = "Optimized" -- "Not Optimized", "Optimized"
}

-- Variabel Global untuk Bhop
getgenv().autoJumpEnabled = false
getgenv().bhopMode = "Acceleration"
getgenv().bhopAccelValue = -0.1
getgenv().bhopHoldActive = false

-- Variabel untuk Auto Crouch
local previousCrouchState = false
local spamDown = true

-- Variabel untuk Bounce
local BOUNCE_ENABLED = false
local BOUNCE_HEIGHT = 50
local BOUNCE_EPSILON = 0.1
local touchConnections = {}

-- Variabel untuk Timer Display
local timerDisplayGui = nil
local timerLabel = nil
local startTime = tick()
local timerConnection = nil

-- Variabel untuk FullBright dan No Fog
local originalAmbient = Lighting.Ambient
local originalOutdoorAmbient = Lighting.OutdoorAmbient
local originalGlobalShadows = Lighting.GlobalShadows
local fog = workspace:FindFirstChild("Fog")
local originalFogEnd = fog and fog.End or 100000

-- Variabel Global lainnya
local character, humanoid, rootPart
local isWindowOpen = false
local placeId = game.PlaceId

-- 4. Localization setup
local Localization = WindUI:Localization({
    Enabled = true,
    Prefix = "loc:",
    DefaultLanguage = "en",
    Translations = {
        ["en"] = {
            ["SCRIPT_TITLE"] = "Movement Hub",
            ["WELCOME"] = "Made by: You",
            ["FEATURES"] = "Features",
            ["Player_TAB"] = "Player",
            ["AUTO_TAB"] = "Auto",
            ["VISUALS_TAB"] = "Visuals",
            ["ESP_TAB"] = "ESP",
            ["SETTINGS_TAB"] = "Settings",
            -- Tambahkan terjemahan lainnya sesuai kebutuhan
        }
    }
})

-- 5. Set WindUI properties & Create Window
WindUI.TransparencyValue = 0.2
WindUI:SetTheme("Dark")

local Window = WindUI:CreateWindow({
    Title = "loc:SCRIPT_TITLE",
    Icon = "rocket",
    Author = "loc:WELCOME",
    Folder = "DoublepunchUI",
    Size = UDim2.fromOffset(580, 490),
    Theme = "Dark",
    HidePanelBackground = false,
    Acrylic = false,
    HideSearchBar = false,
    SideBarWidth = 200
})

local FeatureSection = Window:Section({ Title = "loc:FEATURES", Opened = true })
local Tabs = {
    Main = FeatureSection:Tab({ Title = "Main", Icon = "layout-grid" }),
    Player = FeatureSection:Tab({ Title = "loc:Player_TAB", Icon = "user" }),
    Auto = FeatureSection:Tab({ Title = "loc:AUTO_TAB", Icon = "repeat-2" }),
    Visuals = FeatureSection:Tab({ Title = "loc:VISUALS_TAB", Icon = "camera" }),
    ESP = FeatureSection:Tab({ Title = "loc:ESP_TAB", Icon = "eye" }),
    Utility = FeatureSection:Tab({ Title = "Utility", Icon = "wrench"}),
    Settings = FeatureSection:Tab({ Title = "loc:SETTINGS_TAB", Icon = "settings" })
}

-- 6. Functions & Logic

-- Fungsi untuk membuat GUI bisa di-drag
local function makeDraggable(frame)
    local dragging
    local dragInput
    local dragStart
    local startPos

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

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

-- Fungsi untuk mengaktifkan Bounce
local function setupBounceOnTouch(char)
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local humanoidRootPart = char.HumanoidRootPart
    local touchConnection = humanoidRootPart.Touched:Connect(function(hit)
        if not BOUNCE_ENABLED then return end

        local playerBottom = humanoidRootPart.Position.Y - humanoidRootPart.Size.Y / 2
        local playerTop = humanoidRootPart.Position.Y + humanoidRootPart.Size.Y / 2
        local hitBottom = hit.Position.Y - hit.Size.Y / 2
        local hitTop = hit.Position.Y + hit.Size.Y / 2

        if hitTop <= playerBottom + BOUNCE_EPSILON then return end
        if hitBottom >= playerTop - BOUNCE_EPSILON then return end

        if BOUNCE_HEIGHT > 0 then
            local bodyVel = Instance.new("BodyVelocity")
            bodyVel.MaxForce = Vector3.new(0, math.huge, 0)
            bodyVel.Velocity = Vector3.new(0, BOUNCE_HEIGHT, 0)
            bodyVel.Parent = humanoidRootPart

            Debris:AddItem(bodyVel, 0.2)
        end
    end)
    touchConnections[char] = touchConnection

    char.AncestryChanged:Connect(function()
        if not char.Parent then
            if touchConnections[char] then
                touchConnections[char]:Disconnect()
                touchConnections[char] = nil
            end
        end
    end)
end

local function disableBounce()
    for char, connection in pairs(touchConnections) do
        if connection then
            connection:Disconnect()
            touchConnections[char] = nil
        end
    end
end

-- Fungsi untuk Auto Crouch
local function fireKeybind(down, key)
    local ohTable = {["Down"] = down, ["Key"] = key}
    local event = LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild("Events"):WaitForChild("temporary_events"):WaitForChild("UseKeybind")
    event:Fire(ohTable)
end

-- Fungsi untuk membuat GUI Auto Crouch
local function createAutoCrouchGui(yOffset)
    local autoCrouchGuiOld = playerGui:FindFirstChild("AutoCrouchGui")
    if autoCrouchGuiOld then autoCrouchGuiOld:Destroy() end
    local autoCrouchGui = Instance.new("ScreenGui")
    autoCrouchGui.Name = "AutoCrouchGui"
    autoCrouchGui.IgnoreGuiInset = true
    autoCrouchGui.ResetOnSpawn = false
    autoCrouchGui.Enabled = true
    autoCrouchGui.Parent = playerGui

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 50, 0, 50)
    frame.Position = UDim2.new(0.5, -50, 0.12 + (yOffset or 0), 0)
    frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    frame.BackgroundTransparency = 0.35
    frame.BorderSizePixel = 0
    frame.Parent = autoCrouchGui

    makeDraggable(frame)

    local corner = Instance.new("UICorner", frame)
    corner.CornerRadius = UDim.new(0, 6)

    local stroke = Instance.new("UIStroke", frame)
    stroke.Color = Color3.fromRGB(150, 150, 150)
    stroke.Thickness = 2

    local label = Instance.new("TextLabel", frame)
    label.Text = "Crouch"
    label.Size = UDim2.new(0.9, 0, 0.3, 0)
    label.Position = UDim2.new(0.05, 0, 0.05, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextScaled = true
    label.Font = Enum.Font.Roboto
    label.Parent = frame

    local autoCrouchGuiButton = Instance.new("TextButton")
    autoCrouchGuiButton.Name = "ToggleButton"
    autoCrouchGuiButton.Text = featureStates.AutoCrouch and "On" or "Off"
    autoCrouchGuiButton.Size = UDim2.new(0.9, 0, 0.35, 0)
    autoCrouchGuiButton.Position = UDim2.new(0.05, 0, 0.6, 0)
    autoCrouchGuiButton.BackgroundColor3 = featureStates.AutoCrouch and Color3.fromRGB(0, 120, 80) or Color3.fromRGB(120, 0, 0)
    autoCrouchGuiButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    autoCrouchGuiButton.Font = Enum.Font.Roboto
    autoCrouchGuiButton.TextScaled = true
    autoCrouchGuiButton.Parent = frame

    local buttonCorner = Instance.new("UICorner", autoCrouchGuiButton)
    buttonCorner.CornerRadius = UDim.new(0, 4)

    autoCrouchGuiButton.MouseButton1Click:Connect(function()
        featureStates.AutoCrouch = not featureStates.AutoCrouch
        autoCrouchGuiButton.Text = featureStates.AutoCrouch and "On" or "Off"
        autoCrouchGuiButton.BackgroundColor3 = featureStates.AutoCrouch and Color3.fromRGB(0, 120, 80) or Color3.fromRGB(120, 0, 0)
        -- Sinkronkan dengan toggle UI
        AutoCrouchToggle:Set(featureStates.AutoCrouch)
    end)
end

-- Fungsi untuk membuat GUI Bounce
local function createBounceGui(yOffset)
    local bounceGuiOld = playerGui:FindFirstChild("BounceGui")
    if bounceGuiOld then bounceGuiOld:Destroy() end
    local bounceGui = Instance.new("ScreenGui")
    bounceGui.Name = "BounceGui"
    bounceGui.IgnoreGuiInset = true
    bounceGui.ResetOnSpawn = false
    bounceGui.Enabled = true
    bounceGui.Parent = playerGui

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 50, 0, 50)
    frame.Position = UDim2.new(0.5, -50, 0.12 + (yOffset or 0.05), 0)
    frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    frame.BackgroundTransparency = 0.35
    frame.BorderSizePixel = 0
    frame.Parent = bounceGui

    makeDraggable(frame)

    local corner = Instance.new("UICorner", frame)
    corner.CornerRadius = UDim.new(0, 6)

    local stroke = Instance.new("UIStroke", frame)
    stroke.Color = Color3.fromRGB(150, 150, 150)
    stroke.Thickness = 2

    local label = Instance.new("TextLabel", frame)
    label.Text = "Bounce"
    label.Size = UDim2.new(0.9, 0, 0.3, 0)
    label.Position = UDim2.new(0.05, 0, 0.05, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextScaled = true
    label.Font = Enum.Font.Roboto
    label.Parent = frame

    local bounceGuiButton = Instance.new("TextButton")
    bounceGuiButton.Name = "ToggleButton"
    bounceGuiButton.Text = featureStates.Bounce and "On" or "Off"
    bounceGuiButton.Size = UDim2.new(0.9, 0, 0.35, 0)
    bounceGuiButton.Position = UDim2.new(0.05, 0, 0.6, 0)
    bounceGuiButton.BackgroundColor3 = featureStates.Bounce and Color3.fromRGB(0, 120, 80) or Color3.fromRGB(120, 0, 0)
    bounceGuiButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    bounceGuiButton.Font = Enum.Font.Roboto
    bounceGuiButton.TextScaled = true
    bounceGuiButton.Parent = frame

    local buttonCorner = Instance.new("UICorner", bounceGuiButton)
    buttonCorner.CornerRadius = UDim.new(0, 4)

    bounceGuiButton.MouseButton1Click:Connect(function()
        featureStates.Bounce = not featureStates.Bounce
        BOUNCE_ENABLED = featureStates.Bounce
        bounceGuiButton.Text = featureStates.Bounce and "On" or "Off"
        bounceGuiButton.BackgroundColor3 = featureStates.Bounce and Color3.fromRGB(0, 120, 80) or Color3.fromRGB(120, 0, 0)
        -- Sinkronkan dengan toggle UI
        BounceToggle:Set(featureStates.Bounce)
        if featureStates.Bounce then
            for _, plr in pairs(Players:GetPlayers()) do
                if plr.Character then
                    setupBounceOnTouch(plr.Character)
                end
            end
        else
            disableBounce()
        end
    end)
end

-- Fungsi untuk membuat GUI Timer Display
local function createTimerDisplayGui(yOffset)
    local timerGuiOld = playerGui:FindFirstChild("TimerDisplayGui")
    if timerGuiOld then timerGuiOld:Destroy() end
    local timerGui = Instance.new("ScreenGui")
    timerGui.Name = "TimerDisplayGui"
    timerGui.IgnoreGuiInset = true
    timerGui.ResetOnSpawn = false
    timerGui.Enabled = featureStates.TimerDisplay
    timerGui.Parent = playerGui

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 100, 0, 40)
    frame.Position = UDim2.new(0.5, -50, 0.12 + (yOffset or 0.10), 0)
    frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    frame.BackgroundTransparency = 0.5
    frame.BorderSizePixel = 0
    frame.Parent = timerGui

    makeDraggable(frame)

    local corner = Instance.new("UICorner", frame)
    corner.CornerRadius = UDim.new(0, 6)

    local stroke = Instance.new("UIStroke", frame)
    stroke.Color = Color3.fromRGB(150, 150, 150)
    stroke.Thickness = 2

    local label = Instance.new("TextLabel", frame)
    label.Name = "TimerLabel"
    label.Text = "00:00"
    label.Size = UDim2.new(0.9, 0, 0.9, 0)
    label.Position = UDim2.new(0.05, 0, 0.05, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextScaled = true
    label.Font = Enum.Font.Roboto
    label.Parent = frame

    return timerGui, label
end

-- 7. Tabs & UI Elements

-- Player Tab
Tabs.Player:Section({ Title = "Bhop", TextSize = 20 })
Tabs.Player:Divider()

local BhopToggle = Tabs.Player:Toggle({
    Title = "Bhop",
    Value = false,
    Callback = function(state)
        featureStates.Bhop = state
        getgenv().autoJumpEnabled = state
    end
})

local BhopHoldToggle = Tabs.Player:Toggle({
    Title = "Bhop Hold",
    Value = false,
    Callback = function(state)
        featureStates.BhopHold = state
    end
})

Tabs.Player:Section({ Title = "Movement", TextSize = 20 })
Tabs.Player:Divider()

local SpeedInput = Tabs.Player:Input({
    Title = "Set Speed",
    Icon = "wind",
    Placeholder = "Default 16",
    Value = currentSettings.Speed,
    Callback = function(value)
        local num = tonumber(value)
        if num then
            currentSettings.Speed = num
        end
    end
})

local JumpCapInput = Tabs.Player:Input({
    Title = "Set Jump Cap",
    Icon = "chevrons-up",
    Placeholder = "Default 1",
    Value = currentSettings.JumpCap,
    Callback = function(value)
        local num = tonumber(value)
        if num then
            currentSettings.JumpCap = num
        end
    end
})

local StrafeInput = Tabs.Player:Input({
    Title = "Strafe Acceleration",
    Icon = "wind",
    Placeholder = "Default 187",
    Value = currentSettings.AirStrafeAcceleration,
    Callback = function(value)
        local num = tonumber(value)
        if num then
            currentSettings.AirStrafeAcceleration = num
        end
    end
})

local ApplyMethodDropdown = Tabs.Player:Dropdown({
    Title = "Select Apply Method",
    Values = { "Not Optimized", "Optimized" },
    Multi = false,
    Default = currentSettings.ApplyMode,
    Callback = function(value)
        currentSettings.ApplyMode = value
    end
})

-- Auto Tab
Tabs.Auto:Section({ Title = "Auto Crouch", TextSize = 20 })
Tabs.Auto:Divider()

local AutoCrouchToggle = Tabs.Auto:Toggle({
    Title = "Auto Crouch",
    Value = false,
    Callback = function(state)
        featureStates.AutoCrouch = state
        -- Sinkronkan dengan GUI Mobile
        local playerGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
        local autoCrouchGui = playerGui:FindFirstChild("AutoCrouchGui")
        if autoCrouchGui then
            local button = autoCrouchGui.Frame:FindFirstChild("ToggleButton")
            if button then
                button.Text = state and "On" or "Off"
                button.BackgroundColor3 = state and Color3.fromRGB(0, 120, 80) or Color3.fromRGB(120, 0, 0)
            end
        end
    end
})

local AutoCrouchModeDropdown = Tabs.Auto:Dropdown({
    Title = "Select Auto Crouch Mode",
    Values = { "Air", "Normal", "Ground" },
    Multi = false,
    Default = "Air",
    Callback = function(value)
        featureStates.AutoCrouchMode = value
    end
})

Tabs.Auto:Section({ Title = "Bounce", TextSize = 20 })
Tabs.Auto:Divider()

local BounceToggle = Tabs.Auto:Toggle({
    Title = "Bounce",
    Value = false,
    Callback = function(state)
        featureStates.Bounce = state
        BOUNCE_ENABLED = state
        -- Sinkronkan dengan GUI Mobile
        local playerGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
        local bounceGui = playerGui:FindFirstChild("BounceGui")
        if bounceGui then
            local button = bounceGui.Frame:FindFirstChild("ToggleButton")
            if button then
                button.Text = state and "On" or "Off"
                button.BackgroundColor3 = state and Color3.fromRGB(0, 120, 80) or Color3.fromRGB(120, 0, 0)
            end
        end
        if state then
            for _, plr in pairs(Players:GetPlayers()) do
                if plr.Character then
                    setupBounceOnTouch(plr.Character)
                end
            end
        else
            disableBounce()
        end
    end
})

Tabs.Auto:Section({ Title = "Timer Display", TextSize = 20 })
Tabs.Auto:Divider()

local TimerDisplayToggle = Tabs.Auto:Toggle({
    Title = "Timer Display",
    Value = false,
    Callback = function(state)
        featureStates.TimerDisplay = state
        -- Sinkronkan dengan GUI Mobile
        local playerGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
        local timerGui = playerGui:FindFirstChild("TimerDisplayGui")
        if timerGui then
            timerGui.Enabled = state
        end
        if state then
            if not timerGui then
                timerDisplayGui, timerLabel = createTimerDisplayGui(0.15)
            else
                timerGui.Enabled = true
            end
            startTime = tick()
            timerConnection = RunService.Heartbeat:Connect(function()
                if featureStates.TimerDisplay and timerLabel then
                    local elapsed = tick() - startTime
                    local minutes = math.floor(elapsed / 60)
                    local seconds = math.floor(elapsed % 60)
                    timerLabel.Text = string.format("%02d:%02d", minutes, seconds)
                end
            end)
        else
            if timerConnection then
                timerConnection:Disconnect()
                timerConnection = nil
            end
        end
    end
})

-- Visuals Tab
Tabs.Visuals:Section({ Title = "Fullbright & Fog", TextSize = 20 })
Tabs.Visuals:Divider()

local FullBrightToggle = Tabs.Visuals:Toggle({
    Title = "Full Bright",
    Value = false,
    Callback = function(state)
        featureStates.FullBright = state
        if state then
            Lighting.Ambient = Color3.new(1, 1, 1)
            Lighting.OutdoorAmbient = Color3.new(1, 1, 1)
            Lighting.GlobalShadows = false
        else
            Lighting.Ambient = originalAmbient
            Lighting.OutdoorAmbient = originalOutdoorAmbient
            Lighting.GlobalShadows = originalGlobalShadows
        end
    end
})

local NoFogToggle = Tabs.Visuals:Toggle({
    Title = "Remove Fog",
    Value = false,
    Callback = function(state)
        featureStates.NoFog = state
        if fog then
            if state then
                fog.End = math.huge
            else
                fog.End = originalFogEnd
            end
        end
    end
})

-- Setup Mobile GUIs
local function setupMobileGuis()
    local success, err = pcall(function()
        local touchGui = playerGui:WaitForChild("TouchGui", 5)
        if not touchGui then return end
        local touchControlFrame = touchGui:WaitForChild("TouchControlFrame", 5)
        if not touchControlFrame then return end
        local jumpButton = touchControlFrame:WaitForChild("JumpButton", 5)
        if not jumpButton then return end

        -- Buat GUI Mobile
        createAutoCrouchGui(0.05)
        createBounceGui(0.10)
        if featureStates.TimerDisplay then
            createTimerDisplayGui(0.15)
        end
    end)
end

setupMobileGuis()

-- RunService Loop untuk Bhop
RunService.Heartbeat:Connect(function()
    local plr = Players.LocalPlayer
    local char = plr.Character
    if not char then return end

    local hum = char:FindFirstChild("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart")
    if not hum or not root then return end

    -- Bhop Logic
    if getgenv().autoJumpEnabled and (getgenv().bhopHoldActive or (not getgenv().bhopHoldActive and UserInputService:IsKeyDown(Enum.KeyCode.Space))) then
        if hum.FloorMaterial ~= Enum.Material.Air then
            hum.Jump = true
        end
    end
end)

-- RunService Loop untuk Auto Crouch
RunService.Heartbeat:Connect(function()
    if not featureStates.AutoCrouch then
        if previousCrouchState then
            fireKeybind(false, "Crouch")
            previousCrouchState = false
        end
        return
    end

    if not character or not humanoid then return end

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
end)

-- Event Connections
Players.LocalPlayer.CharacterAdded:Connect(function(newChar)
    character = newChar
    humanoid = character:WaitForChild("Humanoid")
    rootPart = character:WaitForChild("HumanoidRootPart")
    previousCrouchState = false
    spamDown = true

    -- Setup Bounce untuk karakter baru jika fitur aktif
    if featureStates.Bounce then
        setupBounceOnTouch(character)
    end
end)

-- Inisialisasi
if LocalPlayer.Character then
    character = LocalPlayer.Character
    humanoid = character:FindFirstChild("Humanoid")
    rootPart = character:FindFirstChild("HumanoidRootPart")
end

print("Doublepunch Loaded with Evade Test UI Style")
