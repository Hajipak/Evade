local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local VirtualUser = game:GetService("VirtualUser")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Muat library Fluent UI
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

local Window = Fluent:CreateWindow({
    Title = "Movement Hub",
    SubTitle = "by Zen",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl -- Tombol untuk meminimalkan UI
})

-- Tabs
local Tabs = {
    Player = Window:CreateTab("Player", "user"),
    Auto = Window:CreateTab("Auto", "settings"),
    Utility = Window:CreateTab("Utility", "tool"),
    Settings = Window:CreateTab("Settings", "settings-gear")
}

-- Sections
local MovementSection = Tabs.Player:CreateSection("Movement Settings")
local BounceSection = Tabs.Player:CreateSection("Bounce Settings")
local AutoFeaturesSection = Tabs.Auto:CreateSection("Auto Features")
local UtilitySection = Tabs.Utility:CreateSection("Utilities")
local SettingsSection = Tabs.Settings:CreateSection("GUI Settings")

-- Variabel Global
getgenv().autoJumpEnabled = getgenv().autoJumpEnabled or false
getgenv().bhopMode = getgenv().bhopMode or "Acceleration"
getgenv().bhopAccelValue = getgenv().bhopAccelValue or -0.5
getgenv().BOUNCE_ENABLED = getgenv().BOUNCE_ENABLED or false
getgenv().BOUNCE_HEIGHT = getgenv().BOUNCE_HEIGHT or 50
getgenv().BOUNCE_EPSILON = getgenv().BOUNCE_EPSILON or 0.1
getgenv().lagSwitchEnabled = getgenv().lagSwitchEnabled or false
getgenv().lagDuration = getgenv().lagDuration or 0.5
getgenv().timerDisplayEnabled = getgenv().timerDisplayEnabled or false
getgenv().guiButtonSizeX = getgenv().guiButtonSizeX or 60
getgenv().guiButtonSizeY = getgenv().guiButtonSizeY or 60

getgenv().featureStates = getgenv().featureStates or {
    Bhop = false,
    BhopGuiVisible = true,
    AutoCrouch = false,
    AutoCrouchGuiVisible = true,
    AutoCarry = false,
    AutoCarryGuiVisible = true,
    CustomGravity = false,
    GravityGuiVisible = true,
    LagSwitch = false,
    TimerDisplay = false,
}

getgenv().currentSettings = getgenv().currentSettings or {
    Speed = "1500",
    JumpCap = "1",
    AirStrafeAcceleration = "187",
    GravityValue = Workspace.Gravity
}

-- Fungsi Validasi Input
local function createValidatedInput(config)
    return function(input)
        local val = tonumber(input)
        if not val then return end
        if config.min and val < config.min then return end
        if config.max and val > config.max then return end
        getgenv().currentSettings[config.field] = tostring(val)
    end
end

-- Fungsi untuk membuat GUI floating yang bisa digeser
local function makeDraggable(frame)
    local UserInputService = game:GetService("UserInputService")
    local dragging
    local dragInput
    local dragStart
    local startPos

    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
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
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

-- Fungsi untuk membuat GUI floating
local function createFloatingGui(guiName, label, initialYOffset, stateVar, toggleRef)
    local existingGui = PlayerGui:FindFirstChild(guiName)
    if existingGui then existingGui:Destroy() end

    local floatingGui = Instance.new("ScreenGui")
    floatingGui.Name = guiName
    floatingGui.IgnoreGuiInset = true
    floatingGui.ResetOnSpawn = false
    floatingGui.Enabled = getgenv().featureStates[guiName .. "Visible"] or false
    floatingGui.Parent = PlayerGui

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, getgenv().guiButtonSizeX, 0, getgenv().guiButtonSizeY)
    frame.Position = UDim2.new(0.5, -getgenv().guiButtonSizeX/2, 0.12 + initialYOffset, 0)
    frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    frame.BackgroundTransparency = 0.35
    frame.BorderSizePixel = 0
    frame.Parent = floatingGui

    makeDraggable(frame)

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = frame

    local subLabel = Instance.new("TextLabel")
    subLabel.Text = label
    subLabel.Size = UDim2.new(0.9, 0, 0.4, 0)
    subLabel.Position = UDim2.new(0.05, 0, 0.1, 0)
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
    toggleButton.Text = getgenv()[stateVar] and "On" or "Off"
    toggleButton.Size = UDim2.new(0.9, 0, 0.4, 0)
    toggleButton.Position = UDim2.new(0.05, 0, 0.5, 0)
    toggleButton.BackgroundColor3 = getgenv()[stateVar] and Color3.fromRGB(0, 120, 80) or Color3.fromRGB(120, 0, 0)
    toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggleButton.Font = Enum.Font.Roboto
    toggleButton.TextSize = 12
    toggleButton.TextXAlignment = Enum.TextXAlignment.Center
    toggleButton.TextYAlignment = Enum.TextYAlignment.Center
    toggleButton.TextScaled = true
    toggleButton.Parent = frame

    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 4)
    buttonCorner.Parent = toggleButton

    toggleButton.MouseButton1Click:Connect(function()
        getgenv()[stateVar] = not getgenv()[stateVar]
        getgenv().featureStates[guiName] = getgenv()[stateVar]
        if toggleRef then toggleRef:Set(getgenv()[stateVar]) end
    end)

    return floatingGui, toggleButton
end

-- Toggles dan Inputs di UI Fluent
local BhopToggle = AutoFeaturesSection:CreateToggle({
    Title = "Bhop",
    Description = { Text = "Enable Bunny Hopping" },
    Value = getgenv().featureStates.Bhop,
    Callback = function(state)
        getgenv().autoJumpEnabled = state
        getgenv().featureStates.Bhop = state
        if BhopFloatingGui then BhopFloatingGui.Enabled = state end
        if BhopFloatingButton then
            BhopFloatingButton.Text = state and "On" or "Off"
            BhopFloatingButton.BackgroundColor3 = state and Color3.fromRGB(0, 120, 80) or Color3.fromRGB(120, 0, 0)
        end
    end
})

AutoFeaturesSection:CreateDropdown({
    Title = "Bhop Mode",
    Values = { "Acceleration", "No Acceleration" },
    Multi = false,
    Default = getgenv().bhopMode,
    Callback = function(value)
        getgenv().bhopMode = value
    end
})

AutoFeaturesSection:CreateInput({
    Title = "Bhop Accel Value (Neg)",
    Placeholder = "-0.5",
    NumbersOnly = true,
    Value = tostring(getgenv().bhopAccelValue),
    Callback = function(value)
        if tonumber(value) and tonumber(value) < 0 then
            getgenv().bhopAccelValue = tonumber(value)
        end
    end
})

local AutoCrouchToggle = AutoFeaturesSection:CreateToggle({
    Title = "Auto Crouch",
    Value = getgenv().featureStates.AutoCrouch,
    Callback = function(state)
        -- Implementasikan logika Auto Crouch di sini
        getgenv().featureStates.AutoCrouch = state
        if AutoCrouchFloatingGui then AutoCrouchFloatingGui.Enabled = state end
        if AutoCrouchFloatingButton then
            AutoCrouchFloatingButton.Text = state and "On" or "Off"
            AutoCrouchFloatingButton.BackgroundColor3 = state and Color3.fromRGB(0, 120, 80) or Color3.fromRGB(120, 0, 0)
        end
    end
})

local AutoCarryToggle = AutoFeaturesSection:CreateToggle({
    Title = "Auto Carry",
    Value = getgenv().featureStates.AutoCarry,
    Callback = function(state)
        -- Implementasikan logika Auto Carry di sini
        getgenv().featureStates.AutoCarry = state
        if AutoCarryFloatingGui then AutoCarryFloatingGui.Enabled = state end
        if AutoCarryFloatingButton then
            AutoCarryFloatingButton.Text = state and "On" or "Off"
            AutoCarryFloatingButton.BackgroundColor3 = state and Color3.fromRGB(0, 120, 80) or Color3.fromRGB(120, 0, 0)
        end
    end
})

local GravityToggle = UtilitySection:CreateToggle({
    Title = "Custom Gravity",
    Value = getgenv().featureStates.CustomGravity,
    Callback = function(state)
        -- Implementasikan logika Custom Gravity di sini
        getgenv().featureStates.CustomGravity = state
        if GravityFloatingGui then GravityFloatingGui.Enabled = state end
        if GravityFloatingButton then
            GravityFloatingButton.Text = state and "On" or "Off"
            GravityFloatingButton.BackgroundColor3 = state and Color3.fromRGB(0, 120, 80) or Color3.fromRGB(120, 0, 0)
        end
    end
})

UtilitySection:CreateInput({
    Title = "Set Gravity Value",
    Placeholder = tostring(Workspace.Gravity),
    NumbersOnly = true,
    Value = tostring(getgenv().currentSettings.GravityValue),
    Callback = function(value)
        local num = tonumber(value)
        if num then
            getgenv().currentSettings.GravityValue = num
            -- Jika gravity aktif, terapkan nilai baru
            if getgenv().featureStates.CustomGravity then
                Workspace.Gravity = num
            end
        end
    end
})

BounceSection:CreateToggle({
    Title = "Enable Bounce",
    Value = getgenv().BOUNCE_ENABLED,
    Callback = function(state)
        getgenv().BOUNCE_ENABLED = state
        -- Implementasikan logika Bounce di sini
    end
})

BounceSection:CreateInput({
    Title = "Bounce Height",
    Placeholder = "50",
    NumbersOnly = true,
    Value = tostring(getgenv().BOUNCE_HEIGHT),
    Callback = function(value)
        local num = tonumber(value)
        if num then getgenv().BOUNCE_HEIGHT = num end
    end
})

BounceSection:CreateInput({
    Title = "Touch Epsilon",
    Placeholder = "0.1",
    NumbersOnly = true,
    Value = tostring(getgenv().BOUNCE_EPSILON),
    Callback = function(value)
        local num = tonumber(value)
        if num then getgenv().BOUNCE_EPSILON = num end
    end
})

MovementSection:CreateDropdown({
    Title = "Apply Method",
    Values = { "Optimized", "Not Optimized" }, -- Tidak ada 'None'
    Multi = false,
    Default = getgenv().ApplyMode or "Optimized",
    Callback = function(value)
        getgenv().ApplyMode = value
        -- applyToTables() -- Panggil fungsi untuk menerapkan metode
    end
})

MovementSection:CreateInput({
    Title = "Set Speed",
    Placeholder = "1500",
    NumbersOnly = true,
    Value = getgenv().currentSettings.Speed,
    Callback = createValidatedInput({ field = "Speed", min = 1450 })
})

MovementSection:CreateInput({
    Title = "Set Jump Cap",
    Placeholder = "1",
    NumbersOnly = true,
    Value = getgenv().currentSettings.JumpCap,
    Callback = createValidatedInput({ field = "JumpCap", min = 0.1 })
})

MovementSection:CreateInput({
    Title = "Strafe Acceleration",
    Placeholder = "187",
    NumbersOnly = true,
    Value = getgenv().currentSettings.AirStrafeAcceleration,
    Callback = createValidatedInput({ field = "AirStrafeAcceleration", min = 1 })
})

local LagSwitchToggle = UtilitySection:CreateToggle({
    Title = "Lag Switch",
    Value = getgenv().lagSwitchEnabled,
    Callback = function(state)
        getgenv().lagSwitchEnabled = state
        getgenv().featureStates.LagSwitch = state
        if LagSwitchFloatingGui then LagSwitchFloatingGui.Enabled = state end
        if LagSwitchFloatingButton then
            LagSwitchFloatingButton.Text = state and "On" or "Off"
            LagSwitchFloatingButton.BackgroundColor3 = state and Color3.fromRGB(0, 120, 80) or Color3.fromRGB(120, 0, 0)
        end
    end
})

UtilitySection:CreateInput({
    Title = "Lag Duration (seconds)",
    Placeholder = "0.5",
    NumbersOnly = true,
    Value = tostring(getgenv().lagDuration),
    Callback = function(value)
        local num = tonumber(value)
        if num and num > 0 then getgenv().lagDuration = num end
    end
})

local TimerDisplayToggle = UtilitySection:CreateToggle({
    Title = "Timer Display",
    Value = getgenv().timerDisplayEnabled,
    Callback = function(state)
        getgenv().timerDisplayEnabled = state
        getgenv().featureStates.TimerDisplay = state
        -- Implementasikan logika tampilan timer di sini
        -- Contoh: local MainInterface = PlayerGui:WaitForChild("MainInterface", 5)
        -- if MainInterface then local TimerContainer = MainInterface:WaitForChild("TimerContainer", 5) if TimerContainer then TimerContainer.Visible = state end end
    end
})

-- Tombol Show/Hide untuk UI utama Fluent
local showHideButton = Instance.new("TextButton")
showHideButton.Name = "ShowHideButton"
showHideButton.Text = "Hide UI" -- Teks default adalah Hide, artinya UI sedang ditampilkan
showHideButton.Size = UDim2.new(0.9, 0, 0, 30) -- Atur ukuran sesuai kebutuhan
showHideButton.Position = UDim2.new(0.05, 0, 0, 0) -- Atur posisi dalam section
showHideButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50) -- Warna latar belakang
showHideButton.TextColor3 = Color3.fromRGB(255, 255, 255) -- Warna teks
showHideButton.Font = Enum.Font.Gotham -- Ganti sesuai font yang diinginkan
showHideButton.TextSize = 14
showHideButton.Parent = SettingsSection.Frame -- Tempatkan tombol ini di dalam frame section Settings

-- Fungsi untuk mengganti teks tombol
local function updateButtonText()
    showHideButton.Text = Window.IsOpen() and "Hide UI" or "Show UI"
end

-- Hubungkan tombol ke fungsi toggle
showHideButton.MouseButton1Click:Connect(function()
    Window:Toggle() -- Toggle visibilitas window utama
    updateButtonText() -- Perbarui teks setelah toggle
end)

-- Perbarui teks saat window dibuka/tutup secara eksternal (misalnya dengan tombol minimize)
Window.OnToggle:Connect(updateButtonText) -- Gunakan event OnToggle jika tersedia dari library
-- Jika library Fluent tidak menyediakan event OnToggle, maka tombol mungkin tidak selalu akurat
-- tetapi klik tombol itu sendiri akan bekerja.

-- Pengaturan Ukuran Tombol GUI Floating
SettingsSection:CreateInput({
    Title = "Button Size X",
    Placeholder = "60",
    NumbersOnly = true,
    Value = tostring(getgenv().guiButtonSizeX),
    Callback = function(value)
        local num = tonumber(value)
        if num and num > 0 then
            getgenv().guiButtonSizeX = num
            -- Update ukuran semua GUI floating yang ada
            if BhopFloatingGui and BhopFloatingGui.Frame then
                BhopFloatingGui.Frame.Size = UDim2.new(0, getgenv().guiButtonSizeX, 0, getgenv().guiButtonSizeY)
            end
            if AutoCrouchFloatingGui and AutoCrouchFloatingGui.Frame then
                AutoCrouchFloatingGui.Frame.Size = UDim2.new(0, getgenv().guiButtonSizeX, 0, getgenv().guiButtonSizeY)
            end
            if AutoCarryFloatingGui and AutoCarryFloatingGui.Frame then
                AutoCarryFloatingGui.Frame.Size = UDim2.new(0, getgenv().guiButtonSizeX, 0, getgenv().guiButtonSizeY)
            end
            if GravityFloatingGui and GravityFloatingGui.Frame then
                GravityFloatingGui.Frame.Size = UDim2.new(0, getgenv().guiButtonSizeX, 0, getgenv().guiButtonSizeY)
            end
            if LagSwitchFloatingGui and LagSwitchFloatingGui.Frame then
                LagSwitchFloatingGui.Frame.Size = UDim2.new(0, getgenv().guiButtonSizeX, 0, getgenv().guiButtonSizeY)
            end
        end
    end
})

SettingsSection:CreateInput({
    Title = "Button Size Y",
    Placeholder = "60",
    NumbersOnly = true,
    Value = tostring(getgenv().guiButtonSizeY),
    Callback = function(value)
        local num = tonumber(value)
        if num and num > 0 then
            getgenv().guiButtonSizeY = num
            -- Update ukuran semua GUI floating yang ada
             if BhopFloatingGui and BhopFloatingGui.Frame then
                BhopFloatingGui.Frame.Size = UDim2.new(0, getgenv().guiButtonSizeX, 0, getgenv().guiButtonSizeY)
            end
            if AutoCrouchFloatingGui and AutoCrouchFloatingGui.Frame then
                AutoCrouchFloatingGui.Frame.Size = UDim2.new(0, getgenv().guiButtonSizeX, 0, getgenv().guiButtonSizeY)
            end
            if AutoCarryFloatingGui and AutoCarryFloatingGui.Frame then
                AutoCarryFloatingGui.Frame.Size = UDim2.new(0, getgenv().guiButtonSizeX, 0, getgenv().guiButtonSizeY)
            end
            if GravityFloatingGui and GravityFloatingGui.Frame then
                GravityFloatingGui.Frame.Size = UDim2.new(0, getgenv().guiButtonSizeX, 0, getgenv().guiButtonSizeY)
            end
            if LagSwitchFloatingGui and LagSwitchFloatingGui.Frame then
                LagSwitchFloatingGui.Frame.Size = UDim2.new(0, getgenv().guiButtonSizeX, 0, getgenv().guiButtonSizeY)
            end
        end
    end
})

-- Buat GUI Floating
local BhopFloatingGui, BhopFloatingButton = createFloatingGui("BhopGui", "Bhop", 0, "autoJumpEnabled", BhopToggle)
local AutoCrouchFloatingGui, AutoCrouchFloatingButton = createFloatingGui("AutoCrouchGui", "Crouch", 0.07, "autoCrouchEnabled", AutoCrouchToggle) -- Sesuaikan offset Y
local AutoCarryFloatingGui, AutoCarryFloatingButton = createFloatingGui("AutoCarryGui", "Carry", 0.14, "autoCarryEnabled", AutoCarryToggle) -- Sesuaikan offset Y
local GravityFloatingGui, GravityFloatingButton = createFloatingGui("GravityGui", "Gravity", 0.21, "customGravityEnabled", GravityToggle) -- Sesuaikan offset Y
local LagSwitchFloatingGui, LagSwitchFloatingButton = createFloatingGui("LagSwitchGui", "Lag", 0.28, "lagSwitchEnabled", LagSwitchToggle) -- Sesuaikan offset Y

-- Setup SaveManager
SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})

-- Registrasi elemen untuk disimpan
SaveManager:RegisterNewElement(BhopToggle, "BhopToggle")
SaveManager:RegisterNewElement(AutoCrouchToggle, "AutoCrouchToggle")
SaveManager:RegisterNewElement(AutoCarryToggle, "AutoCarryToggle")
SaveManager:RegisterNewElement(GravityToggle, "GravityToggle")
SaveManager:RegisterNewElement(LagSwitchToggle, "LagSwitchToggle")
SaveManager:RegisterNewElement(TimerDisplayToggle, "TimerDisplayToggle")
-- Tambahkan elemen lain jika perlu

-- Tidak ada print
