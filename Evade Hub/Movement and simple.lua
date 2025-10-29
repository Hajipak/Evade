-- Gantilah ini dengan library UI yang kamu gunakan (misalnya WindUI, Orion, dll.)
-- Kita asumsikan kamu menggunakan WindUI berdasarkan file Evade
local WindUI = nil
local ok, result = pcall(function() return require("./src/Init") end)
if ok then
    WindUI = result
else
    WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
end

-- Inisialisasi Variabel dan State
getgenv().autoJumpEnabled = getgenv().autoJumpEnabled or false -- Bhop
getgenv().bhopHoldActive = getgenv().bhopHoldActive or false -- Bhop Hold
getgenv().bhopMode = getgenv().bhopMode or "Acceleration"
getgenv().bhopAccelValue = getgenv().bhopAccelValue or -0.1

-- State fitur utama
local featureStates = {
    Bhop = false,
    BhopHold = false,
    BhopGuiVisible = true, -- Default tampil
    AutoCrouch = false,
    AutoCrouchMode = "Air",
    BounceEnabled = false,
    -- Nilai-nilai dari Evade
    Speed = 1500, -- Nilai dari Evade
    JumpCap = 1,  -- Nilai dari Evade
    StrafeAcceleration = 187 -- Nilai dari Evade (AirStrafeAcceleration)
}

local BOUNCE_HEIGHT = 10
local BOUNCE_EPSILON = 0.1

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Debris = game:GetService("Debris")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui", 5)
local isMobile = UserInputService.TouchEnabled

-- Referensi karakter
local character, humanoid, rootPart
local function onCharacterAdded(char)
    character = char
    humanoid = char:FindFirstChild("Humanoid")
    rootPart = char:FindFirstChild("HumanoidRootPart")
    if not (character and humanoid and rootPart) then return end

    -- Setup Bounce jika diaktifkan
    if featureStates.BounceEnabled then
        setupBounceOnTouch(character)
    end
end

-- --- Fitur dan GUI ---
-- Bhop
local bhopConnection = nil
local bhopLoaded = false
local bhopKeyConnection = nil

local function updateBhop()
    if not (character and humanoid and rootPart) then return end
    if not (featureStates.Bhop or getgenv().bhopHoldActive) then return end

    if getgenv().bhopMode == "Acceleration" then
        for _, t in pairs(getgc(true)) do
            if type(t) == "table" and rawget(t, "Friction") then
                t.Friction = getgenv().bhopAccelValue
            end
        end
    end

    if humanoid:GetState() ~= Enum.HumanoidStateType.Jumping and humanoid:GetState() ~= Enum.HumanoidStateType.Freefall then
        humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end

local function loadBhop()
    if bhopLoaded then return end
    bhopLoaded = true
    if bhopConnection then bhopConnection:Disconnect() end
    bhopConnection = RunService.Heartbeat:Connect(updateBhop)
end

local function unloadBhop()
    if not bhopLoaded then return end
    bhopLoaded = false
    if bhopConnection then
        bhopConnection:Disconnect()
        bhopConnection = nil
    end
    for _, t in pairs(getgc(true)) do
        if type(t) == "table" and rawget(t, "Friction") then
            t.Friction = 5 -- Kembalikan ke default
        end
    end
end

local function checkBhopState()
    local shouldLoad = getgenv().autoJumpEnabled or getgenv().bhopHoldActive
    if shouldLoad and not bhopLoaded then
        loadBhop()
    elseif not shouldLoad and bhopLoaded then
        unloadBhop()
    end
end

local function setupBhopKeybind()
    if bhopKeyConnection then bhopKeyConnection:Disconnect() end
    bhopKeyConnection = UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
        if gameProcessedEvent then return end
        if input.KeyCode == Enum.KeyCode.B and featureStates.BhopGuiVisible then
            getgenv().autoJumpEnabled = not getgenv().autoJumpEnabled
            featureStates.Bhop = getgenv().autoJumpEnabled
            checkBhopState()
            if bhopGuiButton then
                bhopGuiButton.Text = getgenv().autoJumpEnabled and "On" or "Off"
                bhopGuiButton.BackgroundColor3 = getgenv().autoJumpEnabled and Color3.fromRGB(0, 120, 80) or Color3.fromRGB(120, 0, 0)
            end
        end
    end)
end

-- GUI Bhop (Mobile)
local bhopGui, bhopGuiButton
local function createBhopGui(yOffset)
    if playerGui:FindFirstChild("BhopGui") then playerGui.BhopGui:Destroy() end

    bhopGui = Instance.new("ScreenGui")
    bhopGui.Name = "BhopGui"
    bhopGui.IgnoreGuiInset = true
    bhopGui.ResetOnSpawn = false
    bhopGui.Enabled = isMobile and featureStates.BhopGuiVisible or false
    bhopGui.Parent = playerGui

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 60, 0, 60)
    frame.Position = UDim2.new(0.5, -30, 0.12 + (yOffset or 0), 0)
    frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    frame.BackgroundTransparency = 0.35
    frame.BorderSizePixel = 0
    frame.Parent = bhopGui

    frame.Active = true
    frame.Draggable = true
    local dragDetector = Instance.new("UIDragDetector")
    dragDetector.Parent = frame

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = frame

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(150, 150, 150)
    stroke.Thickness = 2
    stroke.Parent = frame

    local label = Instance.new("TextLabel")
    label.Text = "Bhop"
    label.Size = UDim2.new(0.9, 0, 0.5, 0)
    label.Position = UDim2.new(0.05, 0, 0, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.Font = Enum.Font.Roboto
    label.TextSize = 16
    label.TextXAlignment = Enum.TextXAlignment.Center
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.TextScaled = true
    label.Parent = frame

    bhopGuiButton = Instance.new("TextButton")
    bhopGuiButton.Name = "ToggleButton"
    bhopGuiButton.Text = getgenv().autoJumpEnabled and "On" or "Off"
    bhopGuiButton.Size = UDim2.new(0.9, 0, 0.5, 0)
    bhopGuiButton.Position = UDim2.new(0.05, 0, 0.5, 0)
    bhopGuiButton.BackgroundColor3 = getgenv().autoJumpEnabled and Color3.fromRGB(0, 120, 80) or Color3.fromRGB(120, 0, 0)
    bhopGuiButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    bhopGuiButton.Font = Enum.Font.Roboto
    bhopGuiButton.TextSize = 14
    bhopGuiButton.TextXAlignment = Enum.TextXAlignment.Center
    bhopGuiButton.TextYAlignment = Enum.TextYAlignment.Center
    bhopGuiButton.TextScaled = true
    bhopGuiButton.Parent = frame

    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 4)
    buttonCorner.Parent = bhopGuiButton

    bhopGuiButton.MouseButton1Click:Connect(function()
        getgenv().autoJumpEnabled = not getgenv().autoJumpEnabled
        featureStates.Bhop = getgenv().autoJumpEnabled
        checkBhopState()
        bhopGuiButton.Text = getgenv().autoJumpEnabled and "On" or "Off"
        bhopGuiButton.BackgroundColor3 = getgenv().autoJumpEnabled and Color3.fromRGB(0, 120, 80) or Color3.fromRGB(120, 0, 0)
    end)

    return bhopGui, bhopGuiButton
end

-- Setup Bhop Hold (Spacebar)
UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
    if gameProcessedEvent then return end
    if input.KeyCode == Enum.KeyCode.Space and featureStates.BhopHold then
        getgenv().bhopHoldActive = true
        checkBhopState()
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.Space then
        getgenv().bhopHoldActive = false
        checkBhopState()
    end
end)

-- Auto Crouch
local crouchConnection = nil
local previousCrouchState = false
local spamDown = true

local function updateCrouch()
    if not featureStates.AutoCrouch then
        if previousCrouchState then
            fireKeybind(false, "Crouch")
            previousCrouchState = false
        end
        return
    end

    if not (character and humanoid) then return end

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

-- GUI Auto Crouch (Mobile)
local autoCrouchGui, autoCrouchGuiButton
local function createAutoCrouchGui(yOffset)
    if playerGui:FindFirstChild("AutoCrouchGui") then playerGui.AutoCrouchGui:Destroy() end

    autoCrouchGui = Instance.new("ScreenGui")
    autoCrouchGui.Name = "AutoCrouchGui"
    autoCrouchGui.IgnoreGuiInset = true
    autoCrouchGui.ResetOnSpawn = false
    autoCrouchGui.Enabled = isMobile and true or false
    autoCrouchGui.Parent = playerGui

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 50, 0, 50)
    frame.Position = UDim2.new(0.5, -25, 0.12 + (yOffset or 0) + 0.12, 0)
    frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    frame.BackgroundTransparency = 0.35
    frame.BorderSizePixel = 0
    frame.Parent = autoCrouchGui

    frame.Active = true
    frame.Draggable = true
    local dragDetector = Instance.new("UIDragDetector")
    dragDetector.Parent = frame

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = frame

    local label = Instance.new("TextLabel")
    label.Text = "Crouch"
    label.Size = UDim2.new(0.9, 0, 0.45, 0)
    label.Position = UDim2.new(0.05, 0, 0.05, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.Font = Enum.Font.Roboto
    label.TextSize = 30
    label.TextXAlignment = Enum.TextXAlignment.Center
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.TextScaled = true
    label.Parent = frame

    autoCrouchGuiButton = Instance.new("TextButton")
    autoCrouchGuiButton.Name = "ToggleButton"
    autoCrouchGuiButton.Text = featureStates.AutoCrouch and "On" or "Off"
    autoCrouchGuiButton.Size = UDim2.new(0.9, 0, 0.4, 0)
    autoCrouchGuiButton.Position = UDim2.new(0.05, 0, 0.5, 0)
    autoCrouchGuiButton.BackgroundColor3 = featureStates.AutoCrouch and Color3.fromRGB(0, 120, 80) or Color3.fromRGB(120, 0, 0)
    autoCrouchGuiButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    autoCrouchGuiButton.Font = Enum.Font.Roboto
    autoCrouchGuiButton.TextSize = 16
    autoCrouchGuiButton.TextXAlignment = Enum.TextXAlignment.Center
    autoCrouchGuiButton.TextYAlignment = Enum.TextYAlignment.Center
    autoCrouchGuiButton.TextScaled = true
    autoCrouchGuiButton.Parent = frame

    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 4)
    buttonCorner.Parent = autoCrouchGuiButton

    autoCrouchGuiButton.MouseButton1Click:Connect(function()
        featureStates.AutoCrouch = not featureStates.AutoCrouch
        autoCrouchGuiButton.Text = featureStates.AutoCrouch and "On" or "Off"
        autoCrouchGuiButton.BackgroundColor3 = featureStates.AutoCrouch and Color3.fromRGB(0, 120, 80) or Color3.fromRGB(120, 0, 0)
    end)

    return autoCrouchGui, autoCrouchGuiButton
end

-- Bounce
local touchConnections = {}
local function setupBounceOnTouch(char)
    if not featureStates.BounceEnabled then return end
    if touchConnections[char] then touchConnections[char]:Disconnect() end

    local touchConnection = char.HumanoidRootPart.Touched:Connect(function(hit)
        if not featureStates.BounceEnabled then return end
        local humanoidRootPart = char:FindFirstChild("HumanoidRootPart")
        if not humanoidRootPart then return end

        local playerBottom = humanoidRootPart.Position.Y - (humanoidRootPart.Size.Y / 2)
        local hitTop = hit.Position.Y + (hit.Size.Y / 2)

        if hitTop <= playerBottom + BOUNCE_EPSILON and hitTop >= playerBottom - BOUNCE_EPSILON then
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

-- GUI Bounce (Mobile)
local bounceGui, bounceGuiButton
local function createBounceGui(yOffset)
    if playerGui:FindFirstChild("BounceGui") then playerGui.BounceGui:Destroy() end

    bounceGui = Instance.new("ScreenGui")
    bounceGui.Name = "BounceGui"
    bounceGui.IgnoreGuiInset = true
    bounceGui.ResetOnSpawn = false
    bounceGui.Enabled = isMobile and true or false
    bounceGui.Parent = playerGui

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 50, 0, 50)
    frame.Position = UDim2.new(0.5, -25, 0.12 + (yOffset or 0) + 0.24, 0)
    frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    frame.BackgroundTransparency = 0.35
    frame.BorderSizePixel = 0
    frame.Parent = bounceGui

    frame.Active = true
    frame.Draggable = true
    local dragDetector = Instance.new("UIDragDetector")
    dragDetector.Parent = frame

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = frame

    local label = Instance.new("TextLabel")
    label.Text = "Bounce"
    label.Size = UDim2.new(0.9, 0, 0.45, 0)
    label.Position = UDim2.new(0.05, 0, 0.05, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.Font = Enum.Font.Roboto
    label.TextSize = 24
    label.TextXAlignment = Enum.TextXAlignment.Center
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.TextScaled = true
    label.Parent = frame

    bounceGuiButton = Instance.new("TextButton")
    bounceGuiButton.Name = "ToggleButton"
    bounceGuiButton.Text = featureStates.BounceEnabled and "On" or "Off"
    bounceGuiButton.Size = UDim2.new(0.9, 0, 0.4, 0)
    bounceGuiButton.Position = UDim2.new(0.05, 0, 0.5, 0)
    bounceGuiButton.BackgroundColor3 = featureStates.BounceEnabled and Color3.fromRGB(0, 120, 80) or Color3.fromRGB(120, 0, 0)
    bounceGuiButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    bounceGuiButton.Font = Enum.Font.Roboto
    bounceGuiButton.TextSize = 16
    bounceGuiButton.TextXAlignment = Enum.TextXAlignment.Center
    bounceGuiButton.TextYAlignment = Enum.TextYAlignment.Center
    bounceGuiButton.TextScaled = true
    bounceGuiButton.Parent = frame

    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 4)
    buttonCorner.Parent = bounceGuiButton

    bounceGuiButton.MouseButton1Click:Connect(function()
        featureStates.BounceEnabled = not featureStates.BounceEnabled
        bounceGuiButton.Text = featureStates.BounceEnabled and "On" or "Off"
        bounceGuiButton.BackgroundColor3 = featureStates.BounceEnabled and Color3.fromRGB(0, 120, 80) or Color3.fromRGB(120, 0, 0)

        if featureStates.BounceEnabled then
            if character then
                setupBounceOnTouch(character)
            end
        else
            for char, connection in pairs(touchConnections) do
                if connection then
                    connection:Disconnect()
                    touchConnections[char] = nil
                end
            end
        end
    end)

    return bounceGui, bounceGuiButton
end

-- --- UI WindUI ---
-- Buat Window dan Tab
local Window = WindUI:CreateWindow({
    Title = "Movement Features",
    Icon = "rbxassetid://137330250139083", -- Ganti dengan icon kamu
    Author = "Your Name",
    Folder = "MovementUI",
    Size = UDim2.fromOffset(580, 490), -- Sesuaikan ukuran
    Theme = "Dark",
    HidePanelBackground = false,
    Acrylic = false,
    HideSearchBar = false,
    SideBarWidth = 200
})

local FeatureSection = Window:Section({ Title = "Features", Opened = true })
local Tabs = {
    Movement = FeatureSection:Tab({ Title = "Movement", Icon = "user" }),
    Auto = FeatureSection:Tab({ Title = "Auto", Icon = "repeat-2" }),
    Visuals = FeatureSection:Tab({ Title = "Visuals", Icon = "camera" })
}

-- Tab Movement
Tabs.Movement:Section({ Title = "Movement Controls", TextSize = 20 })

-- Speed Input
local SpeedInput = Tabs.Movement:Input({
    Title = "Speed",
    Placeholder = "1500",
    NumbersOnly = true,
    Value = tostring(featureStates.Speed), -- Nilai default dari Evade
    Callback = function(value)
        local num = tonumber(value)
        if num then
            featureStates.Speed = num
            -- Terapkan ke konfigurasi permainan di sini
            applyToTables(function(obj)
                if obj["Friction"] then
                    obj["Friction"] = -0.1 -- Misalnya, sesuaikan dengan mode Bhop
                elseif obj["RunSpeed"] then
                    obj["RunSpeed"] = num
                end
            end)
        end
    end
})

-- Jump Cap Input
local JumpCapInput = Tabs.Movement:Input({
    Title = "Jump Cap",
    Placeholder = "1",
    NumbersOnly = true,
    Value = tostring(featureStates.JumpCap), -- Nilai default dari Evade
    Callback = function(value)
        local num = tonumber(value)
        if num then
            featureStates.JumpCap = num
            -- Terapkan ke konfigurasi permainan di sini
            applyToTables(function(obj)
                if obj["JumpHeight"] then
                    obj["JumpHeight"] = num
                elseif obj["JumpPower"] then
                    obj["JumpPower"] = num
                end
            end)
        end
    end
})

-- Strafe Acceleration Input
local StrafeInput = Tabs.Movement:Input({
    Title = "Strafe Acceleration",
    Placeholder = "187",
    NumbersOnly = true,
    Value = tostring(featureStates.StrafeAcceleration), -- Nilai default dari Evade
    Callback = function(value)
        local num = tonumber(value)
        if num then
            featureStates.StrafeAcceleration = num
            -- Terapkan ke konfigurasi permainan di sini
            applyToTables(function(obj)
                if obj["AirStrafeAcceleration"] then
                    obj["AirStrafeAcceleration"] = num
                end
            end)
        end
    end
})

-- Apply Mode Dropdown
local ApplyMethodDropdown = Tabs.Movement:Dropdown({
    Title = "Apply Method",
    Values = {"Optimized", "Not Optimized", "Manual"}, -- Sesuaikan nilai
    Value = "Not Optimized", -- Default dari Evade
    Callback = function(value)
        getgenv().ApplyMode = value
        -- Terapkan logika berdasarkan mode di sini
        applySettingsWithDelay() -- Panggil fungsi dari Evade jika ada
    end
})

-- Tab Auto
Tabs.Auto:Section({ Title = "Auto Features", TextSize = 20 })

-- Bhop Toggle
local BhopToggle = Tabs.Auto:Toggle({
    Title = "Bhop",
    Value = featureStates.Bhop,
    Callback = function(state)
        getgenv().autoJumpEnabled = state
        featureStates.Bhop = state
        checkBhopState()
        if bhopGuiButton then
            bhopGuiButton.Text = state and "On" or "Off"
            bhopGuiButton.BackgroundColor3 = state and Color3.fromRGB(0, 120, 80) or Color3.fromRGB(120, 0, 0)
        end
    end
})

-- Bhop Hold Toggle
local BhopHoldToggle = Tabs.Auto:Toggle({
    Title = "Bhop Hold (Space)",
    Value = featureStates.BhopHold,
    Callback = function(state)
        featureStates.BhopHold = state
        -- Cukup atur state, fungsi input handler di atas akan menangani
    end
})

-- Bhop GUI Toggle (untuk menampilkan/hide GUI mobile)
local BhopGuiToggle = Tabs.Auto:Toggle({
    Title = "Bhop GUI (Mobile)",
    Value = featureStates.BhopGuiVisible,
    Callback = function(state)
        featureStates.BhopGuiVisible = state
        if bhopGui then
            bhopGui.Enabled = isMobile and state
        end
        setupBhopKeybind() -- Re-setup keybind jika perlu
    end
})

-- Bhop Mode Dropdown
local BhopModeDropdown = Tabs.Auto:Dropdown({
    Title = "Bhop Mode",
    Values = {"Acceleration", "No Acceleration"},
    Value = getgenv().bhopMode,
    Callback = function(value)
        getgenv().bhopMode = value
    end
})

-- Bhop Accel Input
local BhopAccelInput = Tabs.Auto:Input({
    Title = "Bhop Acceleration (Negative Only)",
    Placeholder = "-0.1",
    Numeric = true,
    Value = tostring(getgenv().bhopAccelValue),
    Callback = function(value)
        if tostring(value):sub(1, 1) == "-" then
            local n = tonumber(value)
            if n then
                getgenv().bhopAccelValue = n
            end
        end
    end
})

-- Auto Crouch Toggle
local AutoCrouchToggle = Tabs.Auto:Toggle({
    Title = "Auto Crouch",
    Value = featureStates.AutoCrouch,
    Callback = function(state)
        featureStates.AutoCrouch = state
        if autoCrouchGuiButton then
            autoCrouchGuiButton.Text = state and "On" or "Off"
            autoCrouchGuiButton.BackgroundColor3 = state and Color3.fromRGB(0, 120, 80) or Color3.fromRGB(120, 0, 0)
        end
    end
})

-- Auto Crouch Mode Dropdown
local AutoCrouchModeDropdown = Tabs.Auto:Dropdown({
    Title = "Auto Crouch Mode",
    Values = {"Air", "Ground", "Normal"},
    Value = featureStates.AutoCrouchMode,
    Callback = function(value)
        featureStates.AutoCrouchMode = value
    end
})

-- Bounce Toggle
local BounceToggle = Tabs.Auto:Toggle({
    Title = "Bounce",
    Value = featureStates.BounceEnabled,
    Callback = function(state)
        featureStates.BounceEnabled = state
        if bounceGuiButton then
            bounceGuiButton.Text = state and "On" or "Off"
            bounceGuiButton.BackgroundColor3 = state and Color3.fromRGB(0, 120, 80) or Color3.fromRGB(120, 0, 0)
        end

        if state then
            if character then
                setupBounceOnTouch(character)
            end
        else
            for char, connection in pairs(touchConnections) do
                if connection then
                    connection:Disconnect()
                    touchConnections[char] = nil
                end
            end
        end
    end
})

-- Tab Visuals
Tabs.Visuals:Section({ Title = "Visual Toggles", TextSize = 20 })

-- Fullbright Toggle
local FullBrightToggle = Tabs.Visuals:Toggle({
    Title = "Fullbright",
    Value = false, -- Default off
    Callback = function(state)
        -- Implementasi Fullbright di sini
        if state then
            -- Hapus Lighting ambience
            game.Lighting.Ambient = Color3.new(0, 0, 0)
            game.Lighting.Brightness = 2
            -- Tambahkan Light jika perlu
            if not game.Lighting:FindFirstChild("FullBrightLight") then
                local light = Instance.new("Light")
                light.Name = "FullBrightLight"
                light.Brightness = 2
                light.Range = 999999999
                light.Parent = game.Lighting
            end
        else
            -- Kembalikan ke default (ganti dengan nilai awal jika disimpan)
            game.Lighting.Ambient = Color3.new(0, 0, 0)
            game.Lighting.Brightness = 1
            if game.Lighting:FindFirstChild("FullBrightLight") then
                game.Lighting.FullBrightLight:Destroy()
            end
        end
    end
})

-- Remove Fog Toggle
local RemoveFogToggle = Tabs.Visuals:Toggle({
    Title = "Remove Fog",
    Value = false, -- Default off
    Callback = function(state)
        -- Implementasi Remove Fog di sini
        if state then
            game.Lighting.FogEnd = 999999999 -- Atau disable Fog
            game.Lighting.FogStart = -1
        else
            -- Kembalikan ke default (ganti dengan nilai awal jika disimpan)
            game.Lighting.FogEnd = 100000 -- Default Roblox
            game.Lighting.FogStart = 0
        end
    end
})

-- Timer Display Toggle
local TimerDisplayToggle = Tabs.Visuals:Toggle({
    Title = "Timer Display",
    Value = false, -- Default off
    Callback = function(state)
        -- Implementasi Timer Display di sini (misalnya membuat GUI)
        if state then
            -- Buat GUI Timer
            local timerGui = Instance.new("ScreenGui")
            timerGui.Name = "TimerDisplay"
            timerGui.Parent = playerGui
            -- Tambahkan label dan logika untuk menampilkan timer
            local timerLabel = Instance.new("TextLabel")
            timerLabel.Size = UDim2.new(0, 200, 0, 50)
            timerLabel.Position = UDim2.new(0.5, -100, 0.05, 0)
            timerLabel.BackgroundTransparency = 1
            timerLabel.TextColor3 = Color3.new(1, 1, 1)
            timerLabel.TextScaled = true
            timerLabel.Parent = timerGui
            -- Update timerLabel.Text dengan nilai timer
            -- Misalnya: timerLabel.Text = "Timer: " .. game.Workspace.Game.Stats:GetAttribute("Timer")
        else
            -- Hapus GUI Timer
            if playerGui:FindFirstChild("TimerDisplay") then
                playerGui.TimerDisplay:Destroy()
            end
        end
    end
})

-- --- Setup Utama ---
-- Buat GUI Mobile Toggle
createBhopGui(0)
createAutoCrouchGui(0.12)
createBounceGui(0.24)

-- Setup karakter
onCharacterAdded(player.Character)
player.CharacterAdded:Connect(onCharacterAdded)

-- Setup loop
crouchConnection = RunService.Heartbeat:Connect(updateCrouch)

-- Setup keybind Bhop
setupBhopKeybind()

-- Fungsi bantuan untuk menerapkan ke tabel konfigurasi
-- Ini adalah contoh, kamu harus menyesuaikan dengan struktur Evade
local function applyToTables(func)
    for _, t in pairs(getgc(true)) do
        if type(t) == "table" then
            pcall(func, t) -- Gunakan pcall untuk menghindari error jika field tidak ada
        end
    end
end

-- Fungsi bantuan untuk menerapkan pengaturan dengan delay (jika ada di Evade)
-- local function applySettingsWithDelay()
--     -- Implementasi dari Evade
-- end

print("Movement UI Loaded with Evade-based values (Speed: 1500, JumpCap: 1, Strafe: 187)")
