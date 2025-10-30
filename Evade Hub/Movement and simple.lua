-- Pastikan hanya satu instance skrip ini yang berjalan
if getgenv().MovementHubExecuted then return end
getgenv().MovementHubExecuted = true

-- Load WindUI
local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()

-- Localization setup (Opsional, bisa disesuaikan)
WindUI:Localization({
    Enabled = true,
    Prefix = "loc:",
    DefaultLanguage = "en",
    Translations = {
        ["en"] = {
            ["SCRIPT_TITLE"] = "Movement Hub",
            ["WELCOME"] = "Made by: You",
            ["Player_TAB"] = "Player",
            ["AUTO_TAB"] = "Auto",
            -- Tambahkan terjemahan lain jika diperlukan
        }
    }
})

-- Set Tema
WindUI.TransparencyValue = 0.2
WindUI:SetTheme("Dark")

-- Buat Window
local Window = WindUI:CreateWindow({
    Title = "Movement Hub",
    Icon = "rocket",
    Author = "Made by: You",
    Folder = "MovementHub",
    Size = UDim2.fromOffset(500, 400),
    Theme = "Dark",
    HidePanelBackground = false,
    Acrylic = false,
    HideSearchBar = true,
    SideBarWidth = 150
})

-- Akses atau buat Tab
local Tabs = {}
Tabs.Main = Window:Tab({ Title = "Main", Icon = "layout-grid" })
Tabs.Player = Window:Tab({ Title = "Player", Icon = "user" })
Tabs.Auto = Window:Tab({ Title = "Auto", Icon = "repeat-2" })

-- --- Variabel dan Konfigurasi ---
local currentSettings = {
    Speed = 1500,
    JumpCap = 1,
    AirStrafeAcceleration = 187
}

local getgenv = getgenv or function() return {} end

-- Variabel untuk Bhop
getgenv().autoJumpEnabled = false
getgenv().bhopMode = "Acceleration"
getgenv().bhopAccelValue = -0.5

-- Variabel untuk Bounce
local BOUNCE_HEIGHT = 0
local BOUNCE_EPSILON = 0.1
local BOUNCE_ENABLED = false
local touchConnections = {}

-- --- Services ---
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local workspace = game:GetService("Workspace")
local VirtualUser = game:GetService("VirtualUser") -- Untuk Anti-AFK

local player = Players.LocalPlayer
if not player then
    Players.PlayerAdded:Wait()
    player = Players.LocalPlayer
end

-- --- Fungsi Pendukung untuk Bounce ---
local function setupBounceOnTouch(character)
    if not BOUNCE_ENABLED then return end
    local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
    if not humanoidRootPart then return end -- Pastikan HumanoidRootPart ada

    -- Hapus koneksi lama jika ada
    if touchConnections[character] then
        touchConnections[character]:Disconnect()
        touchConnections[character] = nil
    end

    local touchConnection
    touchConnection = humanoidRootPart.Touched:Connect(function(hit)
        if not BOUNCE_ENABLED or not character or not character:FindFirstChild("HumanoidRootPart") then
            if touchConnection then touchConnection:Disconnect() end
            return
        end

        -- Pastikan menyentuh bagian yang tidak tembus (CanCollide = true) dan bukan bagian dari karakter sendiri
        if hit and hit.CanCollide and hit.Parent ~= character then
            local magnitude = character.HumanoidRootPart.Velocity.Magnitude
            local velocity = character.HumanoidRootPart.CFrame:VectorToWorldSpace(Vector3.new(0, BOUNCE_HEIGHT, 0))
            local rayParams = RaycastParams.new()
            rayParams.FilterDescendantsInstances = {character}
            rayParams.FilterType = Enum.RaycastFilterType.Blacklist
            local rayResult = workspace:Raycast(hit.Position, -hit.Normal * BOUNCE_EPSILON, rayParams)

            if magnitude > 1 and rayResult then
                character.HumanoidRootPart.Velocity = velocity
            end
        end
    end)

    touchConnections[character] = touchConnection
end

local function disableBounce()
    BOUNCE_ENABLED = false
    for char, connection in pairs(touchConnections) do
        if connection then
            connection:Disconnect()
        end
    end
    touchConnections = {}
end

-- --- Fungsi untuk Bhop ---
local function startBhop()
    -- Implementasi Bhop berdasarkan mode
    local UIS = game:GetService("UserInputService")
    local heartbeatConnection

    local function onJumpRequest()
        if player.Character and player.Character:FindFirstChild("Humanoid") then
            player.Character.Humanoid.Jump = true
        end
    end

    if UIS:IsKeyDown(Enum.KeyCode.Space) then
        onJumpRequest()
    end

    heartbeatConnection = RunService.Heartbeat:Connect(function()
        if getgenv().autoJumpEnabled and player.Character and player.Character:FindFirstChild("Humanoid") then
            if UIS:IsKeyDown(Enum.KeyCode.Space) then
                player.Character.Humanoid.Jump = true
            end
        end
    end)

    -- Simpan koneksi agar bisa dihentikan
    getgenv().bhopHeartbeatConnection = heartbeatConnection

    -- Koneksi untuk tombol ditekan (bisa digunakan untuk mode tertentu)
    UIS.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.KeyCode == Enum.KeyCode.Space and getgenv().autoJumpEnabled then
            onJumpRequest()
        end
    end)
end

local function stopBhop()
    getgenv().autoJumpEnabled = false
    if getgenv().bhopHeartbeatConnection then
        getgenv().bhopHeartbeatConnection:Disconnect()
        getgenv().bhopHeartbeatConnection = nil
    end
end

-- --- Fungsi untuk Auto Crouch (Termasuk dalam fitur gerak) ---
local autoCrouchEnabled = false
local autoCrouchMode = "normal" -- Default mode
local autoCrouchConnection

local function startAutoCrouch()
    autoCrouchConnection = RunService.Heartbeat:Connect(function()
        if autoCrouchEnabled and player.Character and player.Character:FindFirstChild("Humanoid") then
            local humanoid = player.Character.Humanoid
            -- Tambahkan logika untuk mode crouch (normal, air, ground) jika diperlukan
            if autoCrouchMode == "normal" or
               (autoCrouchMode == "air" and humanoid:GetState() == Enum.HumanoidStateType.Freefall) or
               (autoCrouchMode == "ground" and humanoid:GetState() == Enum.HumanoidStateType.Landed) then
                -- Ganti dengan metode crouch yang sesuai, misalnya dengan mengubah HipHeight
                if humanoid.Sit == false then
                    humanoid.Sit = true
                    task.wait(0.05) -- Jeda kecil untuk mencegah loop cepat
                    humanoid.Sit = false
                end
            end
        end
    end)
end

local function stopAutoCrouch()
    autoCrouchEnabled = false
    if autoCrouchConnection then
        autoCrouchConnection:Disconnect()
        autoCrouchConnection = nil
    end
end

-- --- Fungsi untuk menerapkan pengaturan ke tabel karakter ---
local function applyToTables(callback)
    -- Fungsi ini mencari tabel dalam karakter yang memiliki field yang relevan
    -- dan menerapkan perubahan. Ini adalah inti dari bagaimana Evade bekerja.
    local character = player.Character
    if not character then return end

    -- Cari tabel-tabel target (misalnya, Humanoid, Motor6D, dll.)
    -- Ganti dengan logika pencarian tabel yang sesuai dari Evade jika diperlukan
    local targets = {}
    for _, obj in pairs(character:GetDescendants()) do
        if typeof(obj) == "table" and obj.Speed and obj.JumpCap and obj.AirStrafeAcceleration then
            table.insert(targets, obj)
        end
    end

    for i, tableObj in ipairs(targets) do
        if tableObj and typeof(tableObj) == "table" then
            pcall(callback, tableObj) -- Gunakan pcall untuk menghindari error jika field tidak ditemukan
        end
    end
end

local function applyStoredSettings()
    local settings = {
        {field = "Speed", value = tonumber(currentSettings.Speed)},
        {field = "JumpCap", value = tonumber(currentSettings.JumpCap)},
        {field = "AirStrafeAcceleration", value = tonumber(currentSettings.AirStrafeAcceleration)}
    }

    for _, setting in ipairs(settings) do
        if setting.value then
            applyToTables(function(obj)
                obj[setting.field] = setting.value
            end)
        end
    end
end

-- --- Bagian UI dengan WindUI ---
-- Section untuk Movement Settings di Tab Player
local MovementSection = Tabs.Player:Section({ Title = "Movement Settings", Opened = true })

-- Speed Input
local SpeedInput = MovementSection:Input({
    Title = "Speed",
    Placeholder = "e.g., 1500",
    Value = tostring(currentSettings.Speed),
    Numeric = true,
    Callback = function(value)
        local numValue = tonumber(value)
        if numValue then
            currentSettings.Speed = numValue
            applyStoredSettings() -- Terapkan perubahan
        else
            warn("Invalid Speed value: " .. tostring(value))
        end
    end
})

-- Jump Cap Input
local JumpCapInput = MovementSection:Input({
    Title = "Jump Cap",
    Placeholder = "e.g., 1",
    Value = tostring(currentSettings.JumpCap),
    Numeric = true,
    Callback = function(value)
        local numValue = tonumber(value)
        if numValue then
            currentSettings.JumpCap = numValue
            applyStoredSettings() -- Terapkan perubahan
        else
            warn("Invalid Jump Cap value: " .. tostring(value))
        end
    end
})

-- Strafe Acceleration Input
local StrafeInput = MovementSection:Input({
    Title = "Strafe Acceleration",
    Placeholder = "e.g., 187",
    Value = tostring(currentSettings.AirStrafeAcceleration),
    Numeric = true,
    Callback = function(value)
        local numValue = tonumber(value)
        if numValue then
            currentSettings.AirStrafeAcceleration = numValue
            applyStoredSettings() -- Terapkan perubahan
        else
            warn("Invalid Strafe Acceleration value: " .. tostring(value))
        end
    end
})

-- Section untuk Auto Features di Tab Auto
local AutoSection = Tabs.Auto:Section({ Title = "Auto Features", Opened = true })

-- Bhop Toggle
local BhopToggle = AutoSection:Toggle({
    Title = "Bhop",
    Value = false,
    Callback = function(state)
        getgenv().autoJumpEnabled = state
        if state then
            startBhop()
        else
            stopBhop()
        end
    end
})

-- Auto Crouch Toggle
local AutoCrouchToggle = AutoSection:Toggle({
    Title = "Auto Crouch",
    Value = false,
    Callback = function(state)
        autoCrouchEnabled = state
        if state then
            startAutoCrouch()
        else
            stopAutoCrouch()
        end
    end
})

-- Section untuk Bounce di Tab Player
local BounceSection = Tabs.Player:Section({ Title = "Bounce", Opened = true })

-- Bounce Toggle
local BounceToggle = BounceSection:Toggle({
    Title = "Bounce",
    Value = false,
    Callback = function(state)
        BOUNCE_ENABLED = state
        if state then
            if player.Character then
                setupBounceOnTouch(player.Character)
            end
            -- Hubungkan ke event CharacterAdded jika bounce aktif
            player.CharacterAdded:Connect(function(char)
                setupBounceOnTouch(char)
            end)
        else
            disableBounce()
        end
    end
})

-- Bounce Height Input
local BounceHeightInput = BounceSection:Input({
    Title = "Bounce Height",
    Placeholder = "e.g., 50",
    Value = tostring(BOUNCE_HEIGHT),
    Numeric = true,
    Callback = function(value)
        local numValue = tonumber(value)
        if numValue then
            BOUNCE_HEIGHT = numValue
            -- Tidak perlu menerapkan langsung, hanya simpan nilai
        else
            warn("Invalid Bounce Height value: " .. tostring(value))
        end
    end
})

-- Touch Epsilon Input
local BounceEpsilonInput = BounceSection:Input({
    Title = "Touch Epsilon",
    Placeholder = "e.g., 0.1",
    Value = tostring(BOUNCE_EPSILON),
    Numeric = true,
    Callback = function(value)
        local numValue = tonumber(value)
        if numValue and numValue >= 0 then -- Harus positif atau nol
            BOUNCE_EPSILON = numValue
        else
            warn("Invalid Touch Epsilon value (must be >= 0): " .. tostring(value))
        end
    end
})

-- Panggil fungsi setup Bounce jika BounceToggle aktif saat karakter muncul
if BOUNCE_ENABLED and player.Character then
    setupBounceOnTouch(player.Character)
end
player.CharacterAdded:Connect(function(char)
    if BOUNCE_ENABLED then
        setupBounceOnTouch(char)
    end
end)

-- Terapkan pengaturan awal saat skrip dimuat
applyStoredSettings()

print("Movement Hub loaded with selected features (Speed, JumpCap, Strafe, Bhop, Bounce, AutoCrouch) and full UI implementation.")
