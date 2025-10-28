if getgenv().MovementHubExecuted then return end
getgenv().MovementHubExecuted = true

-- Load WindUI
local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()

-- Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local LocalPlayer = Players.LocalPlayer
local playerGui = LocalPlayer:WaitForChild("PlayerGui")
local isMobile = UserInputService.TouchEnabled
local originalGameGravity = workspace.Gravity

-- Inisialisasi variabel global jika belum ada
if not getgenv().autoJumpEnabled then getgenv().autoJumpEnabled = false end
if not getgenv().bhopMode then getgenv().bhopMode = "Acceleration" end
if not getgenv().bhopAccelValue then getgenv().bhopAccelValue = -0.5 end
if not getgenv().ApplyMode then getgenv().ApplyMode = "Optimized" end

-- Variabel lokal
local uiToggledViaUI = false
local BOUNCE_ENABLED = false
local BOUNCE_HEIGHT = 50
local BOUNCE_EPSILON = 0.1
local touchConnections = {}
local featureStates = {
    AutoCrouch = false,
    AutoCrouchMode = "Air",
    FullBright = false,
    TimerDisplay = false
}
local originalFOV = workspace.CurrentCamera.FieldOfView
local originalAmbient = nil
local originalEnvironmentDiffuseScale = nil
local originalEnvironmentSpecularScale = nil
local originalGlobalShadows = nil
local originalBrightness = nil
local originalClockTime = nil
local buttonSizeX = 50
local buttonSizeY = 50
local previousCrouchState = false
local spamDown = true

-- Fungsi untuk membuat GUI dapat di-drag
local function makeDraggable(frame)
    local dragging = false
    local dragStart = nil
    local startPos = nil

    local function updatePosition(input)
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
                updatePosition(input)
            end
        end
    end)
end

-- Fungsi untuk membuat tombol toggle GUI
local function createToggleGui(name, stateVar, yPosition)
    local gui = playerGui:FindFirstChild(name .. "Gui")
    if gui then gui:Destroy() end

    gui = Instance.new("ScreenGui")
    gui.Name = name .. "Gui"
    gui.IgnoreGuiInset = true
    gui.ResetOnSpawn = false
    gui.Enabled = getgenv()[stateVar] or false
    gui.Parent = playerGui

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, buttonSizeX, 0, buttonSizeY)
    frame.Position = UDim2.new(0.5, -buttonSizeX/2, yPosition, 0)
    frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    frame.BorderSizePixel = 0
    frame.Parent = gui

    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, 0, 1, 0)
    button.BackgroundColor3 = getgenv()[stateVar] and Color3.fromRGB(0, 120, 80) or Color3.fromRGB(120, 0, 0)
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.Text = getgenv()[stateVar] and "On" or "Off"
    button.Font = Enum.Font.Gotham
    button.TextSize = 14
    button.Parent = frame

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = button

    makeDraggable(frame)

    button.MouseButton1Click:Connect(function()
        local newState = not getgenv()[stateVar]
        getgenv()[stateVar] = newState
        button.Text = newState and "On" or "Off"
        button.BackgroundColor3 = newState and Color3.fromRGB(0, 120, 80) or Color3.fromRGB(120, 0, 0)
        gui.Enabled = isMobile or newState -- Tetap tampil di mobile
    end)

    return gui, button
end

-- Setup Bounce
local function setupBounceOnTouch(character)
    local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
    local touchConnection = humanoidRootPart.Touched:Connect(function(hit)
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
    touchConnections[character] = touchConnection

    character.AncestryChanged:Connect(function()
        if not character.Parent then
            if touchConnections[character] then
                touchConnections[character]:Disconnect()
                touchConnections[character] = nil
            end
        end
    end)
end

local function disableBounce()
    for character, connection in pairs(touchConnections) do
        if connection then
            connection:Disconnect()
            touchConnections[character] = nil
        end
    end
end

-- Setup Mobile Jump untuk Bhop
local function setupMobileJumpButtonForBhop()
    local success, result = pcall(function()
        local touchGui = playerGui:WaitForChild("TouchGui", 5)
        local touchControlFrame = touchGui:WaitForChild("TouchControlFrame", 5)
        local jumpButton = touchControlFrame:WaitForChild("JumpButton", 5)
        if jumpButton then
            jumpButton.MouseButton1Down:Connect(function()
                if featureStates.BhopHold then
                    getgenv().bhopHoldActive = true
                end
            end)
            jumpButton.MouseButton1Up:Connect(function()
                getgenv().bhopHoldActive = false
            end)
        end
    end)
end

-- Fungsi FullBright
local function startFullBright()
    if not originalAmbient then
        originalAmbient = workspace.Ambient
        originalEnvironmentDiffuseScale = workspace.EnvironmentDiffuseScale
        originalEnvironmentSpecularScale = workspace.EnvironmentSpecularScale
        originalGlobalShadows = workspace.GlobalShadows
        originalBrightness = workspace.Brightness
        originalClockTime = workspace.TimeOfDay
    end
    workspace.Ambient = Color3.fromRGB(255, 255, 255)
    workspace.EnvironmentDiffuseScale = 10
    workspace.EnvironmentSpecularScale = 10
    workspace.GlobalShadows = false
    workspace.Brightness = 10
    workspace.TimeOfDay = 14
end

local function stopFullBright()
    if originalAmbient then
        workspace.Ambient = originalAmbient
        workspace.EnvironmentDiffuseScale = originalEnvironmentDiffuseScale or 1
        workspace.EnvironmentSpecularScale = originalEnvironmentSpecularScale or 1
        workspace.GlobalShadows = originalGlobalShadows or true
        workspace.Brightness = originalBrightness or 1
        workspace.TimeOfDay = originalClockTime or "14:00:00"
        originalAmbient = nil
        originalEnvironmentDiffuseScale = nil
        originalEnvironmentSpecularScale = nil
        originalGlobalShadows = nil
        originalBrightness = nil
        originalClockTime = nil
    end
end

-- Fungsi Timer Display
local function updateTimerDisplay()
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    local PlayerGui = LocalPlayer.PlayerGui
    local MainInterface = PlayerGui:WaitForChild("MainInterface", 10)
    if not MainInterface then return end
    local TimerContainer = MainInterface:WaitForChild("TimerContainer", 10)
    if not TimerContainer then return end

    local TimerLabel = TimerContainer:WaitForChild("TimerLabel", 10)
    if not TimerLabel then return end

    local RunService = game:GetService("RunService")
    local startTime = tick()
    local connection

    connection = RunService.Heartbeat:Connect(function()
        if not featureStates.TimerDisplay then
            connection:Disconnect()
            return
        end
        local elapsed = tick() - startTime
        local hours = math.floor(elapsed / 3600)
        local minutes = math.floor((elapsed % 3600) / 60)
        local seconds = math.floor(elapsed % 60)
        TimerLabel.Text = string.format("%02d:%02d:%02d", hours, minutes, seconds)
    end)
end

-- Fungsi untuk input yang divalidasi
local function createValidatedInput(config)
    return function(value)
        local num = tonumber(value)
        if num and num >= config.min and num <= config.max then
            -- Cari tabel konfigurasi dan terapkan
            for _, obj in ipairs(getgc(true)) do
                if type(obj) == "table" and obj[config.field] then
                    obj[config.field] = num
                end
            end
        end
    end
end

-- Fungsi untuk menekan tombol
local function fireKeybind(down, key)
    local ohTable = {["Down"] = down,["Key"] = key}
    local success, event = pcall(function()
        return game:GetService("Players").LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild("Events"):WaitForChild("temporary_events"):WaitForChild("UseKeybind")
    end)
    if success and event then
        event:Fire(ohTable)
    end
end

-- Window
local Window = WindUI:Window({
    Title = "Movement Hub",
    SubTitle = "by User",
    Width = 300,
    ToggleKey = Enum.KeyCode.RightShift,
    Configuration = {
        Enabled = true,
        Folder = "MovementHubConfigs",
        FileName = "Config1"
    }
})

-- Tabs
local FeatureSection = Window:Section({ Title = "Features", Opened = true })
local Tabs = {
    Player = FeatureSection:Tab({ Title = "Player", Icon = "user" }),
    Visuals = FeatureSection:Tab({ Title = "Visuals", Icon = "camera" }),
    Settings = FeatureSection:Tab({ Title = "Settings", Icon = "settings" })
}

-- Player Tab
Tabs.Player:Section({ Title = "Movement Settings", TextSize = 20 })

-- Bhop
local BhopToggle = Tabs.Player:Toggle({
    Title = "Bhop",
    Value = false,
    Callback = function(state)
        getgenv().autoJumpEnabled = state
        -- Update GUI visibility based on state
        local gui = playerGui:FindFirstChild("BhopGui")
        if gui then
            gui.Enabled = state or isMobile
            local btn = gui.Frame:FindFirstChild("ToggleButton")
            if btn then
                btn.Text = state and "On" or "Off"
                btn.BackgroundColor3 = state and Color3.fromRGB(0, 120, 80) or Color3.fromRGB(120, 0, 0)
            end
        end
    end
})

local BhopHoldToggle = Tabs.Player:Toggle({
    Title = "Bhop (Hold Space/Jump)",
    Value = false,
    Callback = function(state)
        featureStates.BhopHold = state
        if not state then getgenv().bhopHoldActive = false end
    end
})

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
        if tostring(value):sub(1,1) == "-" then
            local n = tonumber(value)
            if n then getgenv().bhopAccelValue = n end
        end
    end
})

Tabs.Player:Divider()

-- Bounce
local BounceToggle = Tabs.Player:Toggle({
    Title = "Enable Bounce",
    Value = false,
    Callback = function(state)
        BOUNCE_ENABLED = state
        if state then
            if LocalPlayer.Character then setupBounceOnTouch(LocalPlayer.Character) end
        else
            disableBounce()
        end
        -- Update GUI visibility based on state
        local gui = playerGui:FindFirstChild("BounceGui")
        if gui then
            gui.Enabled = state or isMobile
            local btn = gui.Frame:FindFirstChild("ToggleButton")
            if btn then
                btn.Text = state and "On" or "Off"
                btn.BackgroundColor3 = state and Color3.fromRGB(0, 120, 80) or Color3.fromRGB(120, 0, 0)
            end
        end
    end
})

local BounceHeightInput = Tabs.Player:Input({
    Title = "Bounce Height",
    Placeholder = "50",
    Numeric = true,
    Value = tostring(BOUNCE_HEIGHT),
    Callback = function(value)
        local num = tonumber(value)
        if num then BOUNCE_HEIGHT = math.max(0, num) end
    end
})

local BounceEpsilonInput = Tabs.Player:Input({
    Title = "Touch Detection Epsilon",
    Placeholder = "0.1",
    Numeric = true,
    Value = tostring(BOUNCE_EPSILON),
    Callback = function(value)
        local num = tonumber(value)
        if num then BOUNCE_EPSILON = math.max(0, num) end
    end
})

Tabs.Player:Divider()

-- Auto Crouch
local AutoCrouchToggle = Tabs.Player:Toggle({
    Title = "Auto Crouch",
    Value = false,
    Callback = function(state)
        featureStates.AutoCrouch = state
        -- Update GUI visibility based on state
        local gui = playerGui:FindFirstChild("AutoCrouchGui")
        if gui then
            gui.Enabled = state or isMobile
            local btn = gui.Frame:FindFirstChild("ToggleButton")
            if btn then
                btn.Text = state and "On" or "Off"
                btn.BackgroundColor3 = state and Color3.fromRGB(0, 120, 80) or Color3.fromRGB(120, 0, 0)
            end
        end
    end
})

local AutoCrouchModeDropdown = Tabs.Player:Dropdown({
    Title = "Auto Crouch Mode",
    Values = {"Air", "Normal", "Ground"},
    Default = "Air",
    Callback = function(value)
        featureStates.AutoCrouchMode = value
    end
})

Tabs.Player:Divider()

-- Speed
local SpeedInput = Tabs.Player:Input({
    Title = "Set Speed",
    Placeholder = "Default 16",
    Value = "16",
    Callback = createValidatedInput({field = "Speed", min = 16, max = 50000})
})

-- Jump Cap
local JumpCapInput = Tabs.Player:Input({
    Title = "Set Jump Cap",
    Placeholder = "Default 1",
    Value = "1",
    Callback = createValidatedInput({field = "JumpCap", min = 0.1, max = 50})
})

-- Strafe Acceleration
local StrafeInput = Tabs.Player:Input({
    Title = "Strafe Acceleration",
    Placeholder = "Default 187",
    Value = "187",
    Callback = createValidatedInput({field = "AirStrafeAcceleration", min = 1, max = 1000})
})

-- Apply Method
local ApplyMethodDropdown = Tabs.Player:Dropdown({
    Title = "Select Apply Method",
    Values = { "Not Optimized", "Optimized" },
    Multi = false,
    Default = getgenv().ApplyMode,
    Callback = function(value)
        getgenv().ApplyMode = value
    end
})

-- Visuals Tab
Tabs.Visuals:Section({ Title = "Visual Settings", TextSize = 20 })

-- FullBright
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

-- Timer Display
local TimerDisplayToggle = Tabs.Visuals:Toggle({
    Title = "Timer Display",
    Value = false,
    Callback = function(state)
        featureStates.TimerDisplay = state
        if state then
            updateTimerDisplay()
        end
    end
})

-- Settings Tab
Tabs.Settings:Section({ Title = "GUI Settings", TextSize = 20 })

-- Button Size X
local ButtonSizeXInput = Tabs.Settings:Input({
    Title = "Button Size X",
    Placeholder = "50",
    Value = tostring(buttonSizeX),
    Numeric = true,
    Callback = function(value)
        local num = tonumber(value)
        if num and num > 0 then
            buttonSizeX = num
            -- Mungkin perlu reload GUI untuk menerapkan ukuran baru
        end
    end
})

-- Button Size Y
local ButtonSizeYInput = Tabs.Settings:Input({
    Title = "Button Size Y",
    Placeholder = "50",
    Value = tostring(buttonSizeY),
    Numeric = true,
    Callback = function(value)
        local num = tonumber(value)
        if num and num > 0 then
            buttonSizeY = num
            -- Mungkin perlu reload GUI untuk menerapkan ukuran baru
        end
    end
})

-- Simulasikan perubahan Speed, JumpCap, StrafeAcceleration agar tetap aktif setelah respawn
-- Ini hanya simulasi, implementasi sebenarnya tergantung pada struktur game.
-- Kita bisa menyimpan nilai-nilai ini dan menerapkannya ulang saat karakter muncul kembali.
local function applyPersistentSettings()
    -- Ambil nilai dari input
    local speedValue = tonumber(SpeedInput.Value) or 16
    local jumpCapValue = tonumber(JumpCapInput.Value) or 1
    local strafeValue = tonumber(StrafeInput.Value) or 187

    -- Cari tabel konfigurasi dan terapkan
    for _, obj in ipairs(getgc(true)) do
        local success, result = pcall(function() return obj.Speed, obj.JumpCap, obj.AirStrafeAcceleration end)
        if success and type(obj) == "table" and obj.Speed and obj.JumpCap and obj.AirStrafeAcceleration then
            obj.Speed = speedValue
            obj.JumpCap = jumpCapValue
            obj.AirStrafeAcceleration = strafeValue
        end
    end
end

-- Terapkan pengaturan persisten saat script dimuat
applyPersistentSettings()

-- Terapkan kembali saat karakter muncul
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1) -- Tunggu karakter sepenuhnya dimuat
    applyPersistentSettings()
    if BOUNCE_ENABLED then setupBounceOnTouch(LocalPlayer.Character) end
end)

-- Setup input keyboard untuk Bhop Hold
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.Space and featureStates.BhopHold then
        getgenv().bhopHoldActive = true
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.Space then
        getgenv().bhopHoldActive = false
    end
end)

-- Setup input keyboard untuk Toggle GUI Bhop
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.B and getgenv().autoJumpEnabled then
        getgenv().autoJumpEnabled = not getgenv().autoJumpEnabled
        uiToggledViaUI = false
        local gui = playerGui:FindFirstChild("BhopGui")
        if gui then
            gui.Enabled = (getgenv().autoJumpEnabled and uiToggledViaUI) or isMobile
            local btn = gui.Frame:FindFirstChild("ToggleButton")
            if btn then
                btn.Text = getgenv().autoJumpEnabled and "On" or "Off"
                btn.BackgroundColor3 = getgenv().autoJumpEnabled and Color3.fromRGB(0, 120, 80) or Color3.fromRGB(0, 0, 0)
            end
        end
    end
end)

-- Loop untuk Bhop
task.spawn(function()
    while true do
        local friction = 5
        local isBhopActive = getgenv().autoJumpEnabled or getgenv().bhopHoldActive
        if isBhopActive and getgenv().bhopMode == "Acceleration" then
            friction = getgenv().bhopAccelValue or -0.5
        end

        for _, t in pairs(getgc(true)) do
            if type(t) == "table" and rawget(t, "Friction") then
                if getgenv().bhopMode == "No Acceleration" then
                    t.Friction = 5 -- Reset ke default jika mode No Accel
                else
                    t.Friction = friction
                end
            end
        end
        task.wait(0.15)
    end
end)

-- Loop untuk Bhop State Change
task.spawn(function()
    while true do
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
                task.wait(0.05)
            else
                task.wait()
            end
        else
            task.wait()
        end
    end
end)

-- Loop untuk Auto Crouch
task.spawn(function()
    while true do
        if featureStates.AutoCrouch then
            local character = LocalPlayer.Character
            if not character or not character:FindFirstChild("Humanoid") then task.wait(1) continue end
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
        else
            if previousCrouchState then
                fireKeybind(false, "Crouch")
                previousCrouchState = false
            end
        end
        RunService.Heartbeat:Wait()
    end
end)

-- Setup Mobile
setupMobileJumpButtonForBhop()

-- Inisialisasi GUI Toggle (akan dibuat saat tombol diaktifkan pertama kali)
local jumpGui, jumpToggleBtn = nil, nil
local bounceGui, bounceToggleBtn = nil, nil
local autoCrouchGui, autoCrouchToggleBtn = nil, nil

-- Buat GUI Toggle saat script dimuat
jumpGui, jumpToggleBtn = createToggleGui("Bhop", "autoJumpEnabled", 0.04)
bounceGui, bounceToggleBtn = createToggleGui("Bounce", "bounceEnabled", 0.10)
autoCrouchGui, autoCrouchToggleBtn = createToggleGui("AutoCrouch", "autoCrouchEnabled", 0.16)
