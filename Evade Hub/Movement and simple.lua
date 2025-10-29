-- Pastikan untuk menjalankan skrip ini *setelah* WindUI telah dimuat dan jendela utama dibuat.
-- Diasumsikan variabel seperti Players, RunService, UserInputService, dll. sudah tersedia.

if getgenv().ZenHubEvadeExecuted then return end
getgenv().ZenHubEvadeExecuted = true

-- Load WindUI
local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()

-- Localization setup
local Localization = WindUI:Localization({
    Enabled = true,
    Prefix = "loc:",
    DefaultLanguage = "en",
    Translations = {
        ["en"] = {
            ["SCRIPT_TITLE"] = "Zen Hub",
            ["WELCOME"] = "Made by: Zen",
            ["FEATURES"] = "Features",
            ["Player_TAB"] = "Player",
            ["AUTO_TAB"] = "Auto",
            ["VISUALS_TAB"] = "Visuals",
            ["ESP_TAB"] = "ESP",
            ["SETTINGS_TAB"] = "Settings",
            ["INFINITE_JUMP"] = "Infinite Jump",
            -- Tambahkan terjemahan lainnya sesuai kebutuhan
        }
    }
})

-- Set WindUI properties
WindUI.TransparencyValue = 0.2
WindUI:SetTheme("Dark")

-- Create WindUI window
local Window = WindUI:CreateWindow({
    Title = "loc:SCRIPT_TITLE",
    Icon = "rocket",
    Author = "loc:WELCOME",
    Folder = "GameHackUI",
    Size = UDim2.fromOffset(580, 490),
    Theme = "Dark",
    HidePanelBackground = false,
    Acrylic = false,
    HideSearchBar = false,
    SideBarWidth = 200
})

local isWindowOpen = false
local function updateWindowOpenState()
    if Window and type(Window.IsOpen) == "function" then
        isWindowOpen = Window:IsOpen()
    end
end

local FeatureSection = Window:Section({ Title = "loc:FEATURES", Opened = true })

local Tabs = {
    Main = FeatureSection:Tab({ Title = "Main", Icon = "layout-grid" }),
    Player = FeatureSection:Tab({ Title = "loc:Player_TAB", Icon = "user" }),
    Auto = FeatureSection:Tab({ Title = "loc:AUTO_TAB", Icon = "repeat-2" }),
    Visuals = FeatureSection:Tab({ Title = "loc:VISUALS_TAB", Icon = "camera" }),
    ESP = FeatureSection:Tab({ Title = "loc:ESP_TAB", Icon = "eye" }),
    Settings = FeatureSection:Tab({ Title = "loc:SETTINGS_TAB", Icon = "settings" }),
    -- Tambahkan tab lain jika diperlukan
}

Window:SelectTab(1)

-- --- Variabel dan Konfigurasi Awal ---
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui", 5)

local currentSettings = {
    Speed = "1500",
    JumpCap = "1",
    AirStrafeAcceleration = "187"
}

local featureStates = {
    Bhop = false,
    BhopHold = false, -- Toggle untuk mode Bhop saat menekan tombol
    AutoCrouch = false,
    AutoCrouchMode = "Air", -- Default mode
    -- Tambahkan state lain jika diperlukan
}

-- Variabel untuk Bounce
local BOUNCE_ENABLED = false
local BOUNCE_HEIGHT = 5
local BOUNCE_EPSILON = 0.1
local originalGameGravity = workspace.Gravity
local character, humanoid, rootPart

-- Variabel global untuk toggle
getgenv().autoJumpEnabled = false
getgenv().bhopMode = "Acceleration"
getgenv().bhopAccelValue = -0.1
getgenv().bounceEnabled = false -- Tambahkan variabel global untuk bounce
getgenv().autoCrouchEnabled = false -- Tambahkan variabel global untuk auto crouch

-- --- Fungsi untuk membuat GUI Toggle (diambil dari bagian skrip yang relevan) ---
local function createToggleGui(guiName, genvVarName, positionOffset)
    local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui", 5)
    if not playerGui then return nil, nil end

    local existingGui = playerGui:FindFirstChild(guiName .. "Gui")
    if existingGui then existingGui:Destroy() end

    local toggleGui = Instance.new("ScreenGui")
    toggleGui.Name = guiName .. "Gui"
    toggleGui.IgnoreGuiInset = true
    toggleGui.ResetOnSpawn = false
    toggleGui.Enabled = false -- Akan diaktifkan oleh toggle utama
    toggleGui.Parent = playerGui

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 50, 0, 50)
    frame.Position = UDim2.new(0.5, -50, 0.12 + (positionOffset or 0), 0) -- Sesuaikan offset posisi
    frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    frame.BackgroundTransparency = 0.35
    frame.BorderSizePixel = 0
    frame.Parent = toggleGui

    local label = Instance.new("TextLabel")
    label.Text = guiName
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

    local toggleButton = Instance.new("TextButton")
    toggleButton.Name = "ToggleButton"
    local state = getgenv()[genvVarName]
    toggleButton.Text = state and "On" or "Off"
    toggleButton.Size = UDim2.new(0.9, 0, 0.4, 0)
    toggleButton.Position = UDim2.new(0.05, 0, 0.5, 0)
    toggleButton.BackgroundColor3 = state and Color3.fromRGB(0, 120, 80) or Color3.fromRGB(120, 0, 0)
    toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggleButton.Font = Enum.Font.Roboto
    toggleButton.TextSize = 16
    toggleButton.TextXAlignment = Enum.TextXAlignment.Center
    toggleButton.TextYAlignment = Enum.TextYAlignment.Center
    toggleButton.TextScaled = true
    toggleButton.Parent = frame

    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 4)
    buttonCorner.Parent = toggleButton

    toggleButton.MouseButton1Click:Connect(function()
        getgenv()[genvVarName] = not getgenv()[genvVarName]
        toggleButton.Text = getgenv()[genvVarName] and "On" or "Off"
        toggleButton.BackgroundColor3 = getgenv()[genvVarName] and Color3.fromRGB(0, 120, 80) or Color3.fromRGB(120, 0, 0)
        -- Opsional: Sinkronkan dengan featureStates jika diperlukan
        -- featureStates[guiName] = getgenv()[genvVarName]
    end)

    return toggleGui, toggleButton
end
-- --- Akhir Fungsi Pembuatan GUI ---

-- --- Setup GUI Toggle Awal ---
-- Buat GUI Toggle saat skrip dimuat, tetapi jangan aktifkan kecuali togglenya dinyalakan
-- Bhop
if getgenv().autoJumpEnabled then
    bhopGui, bhopToggleBtn = createToggleGui("Bhop", "autoJumpEnabled", 0.12)
    if bhopGui then bhopGui.Enabled = getgenv().autoJumpEnabled end
end

-- Auto Crouch
if getgenv().autoCrouchEnabled then
    autoCrouchGui, autoCrouchToggleBtn = createToggleGui("AutoCrouch", "autoCrouchEnabled", 0.36) -- Sesuaikan offset
    if autoCrouchGui then autoCrouchGui.Enabled = getgenv().autoCrouchEnabled end
end

-- Bounce
if getgenv().bounceEnabled then
    bounceGui, bounceToggleBtn = createToggleGui("Bounce", "bounceEnabled", 0.24) -- Sesuaikan offset
    if bounceGui then bounceGui.Enabled = getgenv().bounceEnabled end
end


-- --- Bagian UI WindUI ---
-- --- Tab Player ---
Tabs.Player:Section({ Title = "Modifications" })

-- Fungsi bantuan untuk input yang divalidasi
local function createValidatedInput(config)
    return function(input)
        local val = tonumber(input)
        if not val then return end
        if config.min and val < config.min then return end
        if config.max and val > config.max then return end
        currentSettings[config.field] = tostring(val)
        -- applyToTables(function(obj) obj[config.field] = val end) -- Jika fungsi applyToTables digunakan
    end
end

-- Input untuk Speed
local SpeedInput = Tabs.Player:Input({
    Title = "Set Speed",
    Icon = "speedometer",
    Placeholder = "Default 1500",
    Value = currentSettings.Speed,
    Callback = createValidatedInput({field = "Speed", min = 1450, max = 100008888})
})

-- Input untuk Jump Cap
local JumpCapInput = Tabs.Player:Input({
    Title = "Set Jump Cap",
    Icon = "chevrons-up",
    Placeholder = "Default 1",
    Value = currentSettings.JumpCap,
    Callback = createValidatedInput({field = "JumpCap", min = 0.1, max = 5088888})
})

-- Input untuk Strafe Acceleration
local StrafeInput = Tabs.Player:Input({
    Title = "Strafe Acceleration",
    Icon = "wind",
    Placeholder = "Default 187",
    Value = currentSettings.AirStrafeAcceleration,
    Callback = createValidatedInput({field = "AirStrafeAcceleration", min = 1, max = 1000888888})
})

-- Section untuk Bounce (di Tab Player)
Tabs.Player:Section({ Title = "Bounce Settings", TextSize = 20 })

-- Toggle untuk Bounce
local BounceToggle = Tabs.Player:Toggle({
    Title = "Bounce",
    Value = false,
    Callback = function(state)
        getgenv().bounceEnabled = state -- Gunakan variabel global
        BOUNCE_ENABLED = state
        -- Perbarui GUI sesuai state
        if bounceGui and bounceToggleBtn then
            bounceGui.Enabled = state
            bounceToggleBtn.Text = state and "On" or "Off"
            bounceToggleBtn.BackgroundColor3 = state and Color3.fromRGB(0, 120, 80) or Color3.fromRGB(120, 0, 0)
        else
            -- Jika GUI belum dibuat, buat sekarang
            if state then
                bounceGui, bounceToggleBtn = createToggleGui("Bounce", "bounceEnabled", 0.24) -- Offset posisi
                if bounceGui then bounceGui.Enabled = state end
            end
        end
    end
})

-- Input untuk Bounce Height
local BounceHeightInput = Tabs.Player:Input({
    Title = "Bounce Height",
    Placeholder = "0",
    Value = tostring(BOUNCE_HEIGHT),
    Numeric = true,
    Enabled = false,
    Callback = function(value)
        local num = tonumber(value)
        if num then
            BOUNCE_HEIGHT = math.max(0, num)
        end
    end
})

-- Input untuk Touch Detection Epsilon
local EpsilonInput = Tabs.Player:Input({
    Title = "Touch Detection Epsilon",
    Placeholder = "0.1",
    Value = tostring(BOUNCE_EPSILON),
    Numeric = true,
    Enabled = false,
    Callback = function(value)
        local num = tonumber(value)
        if num then
            BOUNCE_EPSILON = math.max(0, num)
        end
    end
})

-- Perbarui input agar enabled/disabled sesuai toggle bounce
BounceToggle:Set(false) -- Set awal ke off
BounceHeightInput:Set({ Enabled = false })
EpsilonInput:Set({ Enabled = false })

-- --- Tab Auto ---
Tabs.Auto:Section({ Title = "Auto", TextSize = 40 })

-- Toggle untuk Bhop
local BhopToggle = Tabs.Auto:Toggle({
    Title = "Bhop",
    Value = false,
    Callback = function(state)
        getgenv().autoJumpEnabled = state
        -- Perbarui GUI sesuai state
        if bhopGui and bhopToggleBtn then
            bhopGui.Enabled = state
            bhopToggleBtn.Text = state and "On" or "Off"
            bhopToggleBtn.BackgroundColor3 = state and Color3.fromRGB(0, 120, 80) or Color3.fromRGB(120, 0, 0)
        else
            -- Jika GUI belum dibuat, buat sekarang
            if state then
                bhopGui, bhopToggleBtn = createToggleGui("Bhop", "autoJumpEnabled", 0.12) -- Offset posisi
                if bhopGui then bhopGui.Enabled = state end
            end
        end
    end
})

-- Dropdown untuk Bhop Mode
Tabs.Auto:Dropdown({
    Title = "Bhop Mode",
    Values = {"Acceleration", "No Acceleration"},
    Value = "Acceleration", -- Gunakan 'Value' bukan 'Default' untuk Dropdown
    Callback = function(value)
        getgenv().bhopMode = value
    end
})

-- Input untuk Bhop Acceleration
Tabs.Auto:Input({
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

-- Toggle untuk Bhop Hold (opsional, sesuai skrip asli)
local BhopHoldToggle = Tabs.Auto:Toggle({
    Title = "Bhop (Jump button or Space)",
    Value = false,
    Callback = function(state)
        featureStates.BhopHold = state
        getgenv().bhopHoldActive = state
    end
})

-- Toggle untuk Auto Crouch
local AutoCrouchToggle = Tabs.Auto:Toggle({
    Title = "Auto Crouch",
    Icon = "arrow-down",
    Value = false,
    Callback = function(state)
        getgenv().autoCrouchEnabled = state -- Gunakan variabel global
        featureStates.AutoCrouch = state
        -- Perbarui GUI sesuai state
        if autoCrouchGui and autoCrouchToggleBtn then
            autoCrouchGui.Enabled = state
            autoCrouchToggleBtn.Text = state and "On" or "Off"
            autoCrouchToggleBtn.BackgroundColor3 = state and Color3.fromRGB(0, 120, 80) or Color3.fromRGB(120, 0, 0)
        else
            -- Jika GUI belum dibuat, buat sekarang
            if state then
                autoCrouchGui, autoCrouchToggleBtn = createToggleGui("AutoCrouch", "autoCrouchEnabled", 0.36) -- Offset posisi
                if autoCrouchGui then autoCrouchGui.Enabled = state end
            end
        end
    end
})

-- Dropdown untuk Auto Crouch Mode
local AutoCrouchModeDropdown = Tabs.Auto:Dropdown({
    Title = "Auto Crouch Mode",
    Values = {"Air", "Normal", "Ground"},
    Value = "Air",
    Callback = function(value)
        featureStates.AutoCrouchMode = value
    end
})

-- --- Setup Loop dan Fungsi ---
-- Loop Bhop
task.spawn(function()
    while true do
        local friction = 5
        local isBhopActive = getgenv().autoJumpEnabled or getgenv().bhopHoldActive
        if isBhopActive and getgenv().bhopMode == "Acceleration" then
            friction = getgenv().bhopAccelValue or -0.5
        end
        for _, t in pairs(getgc(true)) do
            if type(t) == "table" and rawget(t, "Friction") then
                t.Friction = friction
            end
        end
        task.wait(0.15)
    end
end)

task.spawn(function()
    while true do
        local isBhopActive = getgenv().autoJumpEnabled or getgenv().bhopHoldActive
        if isBhopActive then
            if character and humanoid then
                local state = humanoid:GetState()
                if state ~= Enum.HumanoidStateType.Jumping and state ~= Enum.HumanoidStateType.Freefall then
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

-- Loop Auto Crouch
task.spawn(function()
    local lastCrouchState = false
    while true do
        if getgenv().autoCrouchEnabled and character and humanoid then -- Gunakan variabel global
            local currentState = humanoid.Sit
            local shouldCrouch = false
            if featureStates.AutoCrouchMode == "Air" then
                local state = humanoid:GetState()
                shouldCrouch = (state == Enum.HumanoidStateType.Freefall or state == Enum.HumanoidStateType.Jumping)
            elseif featureStates.AutoCrouchMode == "Ground" then
                shouldCrouch = humanoid:GetState() == Enum.HumanoidStateType.Landed
            else -- "Normal" atau lainnya
                shouldCrouch = true -- Crouch terus-menerus jika mode normal
            end

            if shouldCrouch and not currentState and not lastCrouchState then
                -- Ganti fireKeybind dengan fungsi crouch yang sesuai
                -- Misalnya, jika ada fungsi global atau remote untuk crouch:
                -- game:GetService("ReplicatedStorage"):WaitForChild("CrouchRemote"):FireServer(shouldCrouch)
                -- Atau jika bisa langsung:
                humanoid.Sit = true
                lastCrouchState = true
            elseif not shouldCrouch and currentState and lastCrouchState then
                -- game:GetService("ReplicatedStorage"):WaitForChild("CrouchRemote"):FireServer(shouldCrouch)
                humanoid.Sit = false
                lastCrouchState = false
            elseif not shouldCrouch then
                lastCrouchState = false -- Reset jika tidak seharusnya crouch
            end
        else
            if lastCrouchState then
                if character and humanoid and humanoid.Sit then
                    -- game:GetService("ReplicatedStorage"):WaitForChild("CrouchRemote"):FireServer(false)
                    humanoid.Sit = false
                end
                lastCrouchState = false
            end
        end
        task.wait(0.1) -- Delay kecil untuk mengurangi beban CPU
    end
end)

-- Setup Bounce
local touchConnections = {}
local function setupBounceOnTouch(char)
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    if touchConnections[char] then touchConnections[char]:Disconnect() end

    local humanoidRootPart = char.HumanoidRootPart
    local touchConnection = humanoidRootPart.Touched:Connect(function(hit)
        if not getgenv().bounceEnabled or not hit then return end -- Gunakan variabel global
        if hit.Parent:FindFirstChild("Humanoid") or hit.Parent.Parent:FindFirstChild("Humanoid") then return end

        local playerBottom = humanoidRootPart.Position.Y - humanoidRootPart.Size.Y / 2
        local playerTop = humanoidRootPart.Position.Y + humanoidRootPart.Size.Y / 2
        local hitBottom = hit.Position.Y - hit.Size.Y / 2
        local hitTop = hit.Position.Y + hit.Size.Y / 2

        if hitTop <= playerBottom + BOUNCE_EPSILON then return end
        if hitBottom >= playerTop - BOUNCE_EPSILON then return end

        -- remoteEvent:FireServer({}, {2}) -- Ganti dengan event game yang sesuai jika ada

        if BOUNCE_HEIGHT > 0 then
            local bodyVel = Instance.new("BodyVelocity")
            bodyVel.MaxForce = Vector3.new(0, math.huge, 0)
            bodyVel.Velocity = Vector3.new(0, BOUNCE_HEIGHT, 0)
            bodyVel.Parent = humanoidRootPart
            game:GetService("Debris"):AddItem(bodyVel, 0.2)
        end
    end)

    touchConnections[char] = touchConnection
end

local function disableBounce()
    for char, connection in pairs(touchConnections) do
        if connection then
            connection:Disconnect()
            touchConnections[char] = nil
        end
    end
end

-- Hubungkan ke karakter saat ini dan karakter yang baru
if player.Character then
    setupBounceOnTouch(player.Character)
end
player.CharacterAdded:Connect(setupBounceOnTouch)

-- Setup Tombol Bhop Hold (Space dan Jump Button)
-- Ganti 'player' dengan Players.LocalPlayer jika belum
local UIS = game:GetService("UserInputService")
UIS.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.Space and featureStates.BhopHold then
        getgenv().bhopHoldActive = true
    end
end)
UIS.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.Space then
        getgenv().bhopHoldActive = false
    end
end)

-- Setup untuk tombol lompat di mobile (jika ada)
local function setupJumpButton()
    local success, err = pcall(function()
        local touchGui = player:WaitForChild("PlayerGui"):WaitForChild("TouchGui", 5)
        if not touchGui then return end
        local touchControlFrame = touchGui:WaitForChild("TouchControlFrame", 5)
        if not touchControlFrame then return end
        local jumpButton = touchControlFrame:WaitForChild("JumpButton", 5)
        if not jumpButton then return end

        jumpButton.MouseButton1Down:Connect(function()
            if featureStates.BhopHold then
                getgenv().bhopHoldActive = true
            end
        end)
        jumpButton.MouseButton1Up:Connect(function()
            getgenv().bhopHoldActive = false
        end)
    end)
    if not success then
        warn("Failed to setup jump button: " .. tostring(err))
    end
end

setupJumpButton()
player.CharacterAdded:Connect(setupJumpButton)

-- --- Setup karakter ---
player.CharacterAdded:Connect(function(char)
    character = char
    humanoid = character:WaitForChild("Humanoid")
    rootPart = character:WaitForChild("HumanoidRootPart")
    -- Setup ulang bounce jika karakter respawn
    setupBounceOnTouch(char)
end)

if player.Character then
    character = player.Character
    humanoid = character:WaitForChild("Humanoid")
    rootPart = character:WaitForChild("HumanoidRootPart")
end

-- --- Akhir Skrip ---
