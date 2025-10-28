-- Muat library Fluent UI *PERTAMA*
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

-- Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local VirtualUser = game:GetService("VirtualUser")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local MarketplaceService = game:GetService("MarketplaceService")
local StarterGui = game:GetService("StarterGui")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Variabel Global (diambil dan disesuaikan dari Evade Test.txt)
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
getgenv().autoCrouchEnabled = getgenv().autoCrouchEnabled or false
getgenv().autoCarryEnabled = getgenv().autoCarryEnabled or false
getgenv().customGravityEnabled = getgenv().customGravityEnabled or false
getgenv().customGravityValue = getgenv().customGravityValue or Workspace.Gravity

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
    -- Tambahkan state lainnya sesuai kebutuhan
}

getgenv().currentSettings = getgenv().currentSettings or {
    Speed = "1500",
    JumpCap = "1",
    AirStrafeAcceleration = "187",
    GravityValue = Workspace.Gravity
}

getgenv().originalGameGravity = getgenv().originalGameGravity or Workspace.Gravity

-- --- Logika Tambahan ---
-- Contoh fungsi dasar (perlu diimplementasikan sepenuhnya sesuai kebutuhan)
local function applyToTables(callback)
    -- Fungsi ini mencari tabel konfigurasi di memori dan menerapkan perubahan
    -- Potongan dari Evade Test.txt menunjukkan ini mencari objek dengan field tertentu
    local requiredFields = {Friction = true, AirStrafeAcceleration = true, JumpHeight = true, RunDeaccel = true, JumpSpeedMultiplier = true, JumpCap = true, SprintCap = true, WalkSpeedMultiplier = true, BhopEnabled = true, Speed = true, AirAcceleration = true, RunAccel = true, SprintAcceleration = true}
    local function hasAllFields(tbl)
        if type(tbl) ~= "table" then return false end
        for field, _ in pairs(requiredFields) do
            if rawget(tbl, field) == nil then return false end
        end
        return true
    end
    for _, obj in ipairs(getgc(true)) do
        local success, result = pcall(function()
            if hasAllFields(obj) then return obj end
        end)
        if success and result then
            callback(result)
        end
    end
end

local function startBhop()
    if getgenv().bhopConnection then getgenv().bhopConnection:Disconnect() end
    getgenv().bhopConnection = RunService.Heartbeat:Connect(function()
        if getgenv().autoJumpEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local humanoid = LocalPlayer.Character.Humanoid
            local rootPart = LocalPlayer.Character.HumanoidRootPart
            if humanoid.FloorMaterial ~= Enum.Material.Air then
                if getgenv().bhopMode == "No Acceleration" then
                    -- Logika No Accel Bhop (mungkin hanya Humanoid:ChangeState)
                    humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                    task.wait(0.05)
                else -- Acceleration Bhop
                    -- Logika Accel Bhop (mungkin modifikasi kecepatan)
                    if rootPart.Velocity.Y < 0.1 then -- Hanya lompat saat turun
                        humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                        task.wait()
                    else
                        task.wait()
                    end
                end
            else
                task.wait()
            end
        end
    end)
end

local function stopBhop()
    if getgenv().bhopConnection then
        getgenv().bhopConnection:Disconnect()
        getgenv().bhopConnection = nil
    end
end

local function startAutoCrouch()
    -- Implementasi Auto Crouch (mungkin dengan menekan tombol secara virtual atau mengubah CFrame)
    -- Contoh sederhana: Simulasi menekan tombol jongkok
    if getgenv().autoCrouchConnection then getgenv().autoCrouchConnection:Disconnect() end
    getgenv().autoCrouchConnection = RunService.Heartbeat:Connect(function()
        if getgenv().autoCrouchEnabled then
            -- Simulasi input tombol crouch jika tersedia
            -- VirtualUser:CaptureController() -> Crouch()
            -- Atau manipulasi CFrame jika memungkinkan
            -- local char = LocalPlayer.Character
            -- if char and char:FindFirstChild("Humanoid") then
            --    char.Humanoid.Sit = true
            -- end
        end
    end)
end

local function stopAutoCrouch()
    if getgenv().autoCrouchConnection then
        getgenv().autoCrouchConnection:Disconnect()
        getgenv().autoCrouchConnection = nil
    end
end

local function startAutoCarry()
    -- Implementasi Auto Carry (mungkin dengan mencari pemain lain dan memanggil remote)
    if getgenv().autoCarryConnection then getgenv().autoCarryConnection:Disconnect() end
    getgenv().autoCarryConnection = RunService.Heartbeat:Connect(function()
        if getgenv().autoCarryEnabled then
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                for _, other in ipairs(Players:GetPlayers()) do
                    if other ~= LocalPlayer and other.Character and other.Character:FindFirstChild("HumanoidRootPart") then
                        local dist = (hrp.Position - other.Character.HumanoidRootPart.Position).Magnitude
                        if dist <= 20 then -- Jarak carry
                            -- Panggil remote untuk carry (ganti dengan remote event yang benar)
                            -- local remote = ReplicatedStorage:WaitForChild("SomeRemoteForCarry")
                            -- remote:FireServer(other.Name)
                        end
                    end
                end
            end
        end
    end)
end

local function stopAutoCarry()
    if getgenv().autoCarryConnection then
        getgenv().autoCarryConnection:Disconnect()
        getgenv().autoCarryConnection = nil
    end
end

local function setupBounceOnTouch(character)
    if not character then return end
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return end

    if getgenv().touchConnection then getgenv().touchConnection:Disconnect() end

    getgenv().touchConnection = humanoidRootPart.Touched:Connect(function(hit)
        if not getgenv().BOUNCE_ENABLED then return end -- Periksa apakah bounce aktif
        local playerBottom = humanoidRootPart.Position.Y - humanoidRootPart.Size.Y / 2
        local playerTop = humanoidRootPart.Position.Y + humanoidRootPart.Size.Y / 2
        local hitBottom = hit.Position.Y - hit.Size.Y / 2
        local hitTop = hit.Position.Y + hit.Size.Y / 2

        if hitTop <= playerBottom + getgenv().BOUNCE_EPSILON then return end
        if hitBottom >= playerTop - getgenv().BOUNCE_EPSILON then return end

        -- Terapkan kecepatan ke atas
        if getgenv().BOUNCE_HEIGHT > 0 then
            local bodyVelocity = Instance.new("BodyVelocity")
            bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
            bodyVelocity.Velocity = Vector3.new(0, getgenv().BOUNCE_HEIGHT, 0)
            bodyVelocity.Parent = humanoidRootPart
            game:GetService("Debris"):AddItem(bodyVelocity, 0.1) -- Hapus setelah 0.1 detik
        end
    end)
end

local function disableBounce()
    if getgenv().touchConnection then
        getgenv().touchConnection:Disconnect()
        getgenv().touchConnection = nil
    end
end

local function updateGravity()
    if getgenv().customGravityEnabled then
        Workspace.Gravity = getgenv().customGravityValue
    else
        Workspace.Gravity = getgenv().originalGameGravity
    end
end

-- Buat Window dan Tabs *SETELAH* library dimuat
local Window = Fluent:CreateWindow({
    Title = "Movement Hub",
    SubTitle = "by Zen",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
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

-- Fungsi Validasi Input
local function createValidatedInput(config)
    return function(input)
        local val = tonumber(input)
        if not val then return end
        if config.min and val < config.min then return end
        if config.max and val > config.max then return end
        getgenv().currentSettings[config.field] = tostring(val)
        -- Terapkan ke tabel konfigurasi
        applyToTables(function(obj) obj[config.field] = val end)
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
        -- Panggil fungsi logika saat toggle berubah
        if stateVar == "autoJumpEnabled" then
            if getgenv()[stateVar] then startBhop() else stopBhop() end
        elseif stateVar == "autoCrouchEnabled" then
            if getgenv()[stateVar] then startAutoCrouch() else stopAutoCrouch() end
        elseif stateVar == "autoCarryEnabled" then
            if getgenv()[stateVar] then startAutoCarry() else stopAutoCarry() end
        elseif stateVar == "customGravityEnabled" then
            updateGravity()
        end
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
        -- Panggil logika
        if state then startBhop() else stopBhop() end
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
        getgenv().autoCrouchEnabled = state
        getgenv().featureStates.AutoCrouch = state
        if AutoCrouchFloatingGui then AutoCrouchFloatingGui.Enabled = state end
        if AutoCrouchFloatingButton then
            AutoCrouchFloatingButton.Text = state and "On" or "Off"
            AutoCrouchFloatingButton.BackgroundColor3 = state and Color3.fromRGB(0, 120, 80) or Color3.fromRGB(120, 0, 0)
        end
        -- Panggil logika
        if state then startAutoCrouch() else stopAutoCrouch() end
    end
})

local AutoCarryToggle = AutoFeaturesSection:CreateToggle({
    Title = "Auto Carry",
    Value = getgenv().featureStates.AutoCarry,
    Callback = function(state)
        getgenv().autoCarryEnabled = state
        getgenv().featureStates.AutoCarry = state
        if AutoCarryFloatingGui then AutoCarryFloatingGui.Enabled = state end
        if AutoCarryFloatingButton then
            AutoCarryFloatingButton.Text = state and "On" or "Off"
            AutoCarryFloatingButton.BackgroundColor3 = state and Color3.fromRGB(0, 120, 80) or Color3.fromRGB(120, 0, 0)
        end
        -- Panggil logika
        if state then startAutoCarry() else stopAutoCarry() end
    end
})

local GravityToggle = UtilitySection:CreateToggle({
    Title = "Custom Gravity",
    Value = getgenv().featureStates.CustomGravity,
    Callback = function(state)
        getgenv().customGravityEnabled = state
        getgenv().featureStates.CustomGravity = state
        if GravityFloatingGui then GravityFloatingGui.Enabled = state end
        if GravityFloatingButton then
            GravityFloatingButton.Text = state and "On" or "Off"
            GravityFloatingButton.BackgroundColor3 = state and Color3.fromRGB(0, 120, 80) or Color3.fromRGB(120, 0, 0)
        end
        -- Panggil logika
        updateGravity()
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
            getgenv().customGravityValue = num
            -- Jika gravity aktif, terapkan nilai baru
            if getgenv().featureStates.CustomGravity then
                updateGravity()
            end
        end
    end
})

BounceSection:CreateToggle({
    Title = "Enable Bounce",
    Value = getgenv().BOUNCE_ENABLED,
    Callback = function(state)
        getgenv().BOUNCE_ENABLED = state
        -- Panggil logika
        if state then
            if LocalPlayer.Character then setupBounceOnTouch(LocalPlayer.Character) end
            -- Hubungkan ke event CharacterAdded jika perlu
            -- LocalPlayer.CharacterAdded:Connect(setupBounceOnTouch)
        else
            disableBounce()
        end
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
        -- Implementasi logika Lag Switch di sini jika diperlukan
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
showHideButton.Text = "Hide UI"
showHideButton.Size = UDim2.new(0.9, 0, 0, 30)
showHideButton.Position = UDim2.new(0.05, 0, 0, 0)
showHideButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
showHideButton.TextColor3 = Color3.fromRGB(255, 255, 255)
showHideButton.Font = Enum.Font.Gotham
showHideButton.TextSize = 14
showHideButton.Parent = SettingsSection.Frame

local function updateButtonText()
    showHideButton.Text = Window.IsOpen() and "Hide UI" or "Show UI"
end

showHideButton.MouseButton1Click:Connect(function()
    Window:Toggle()
    updateButtonText()
end)

Window.OnToggle:Connect(updateButtonText)

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
local AutoCrouchFloatingGui, AutoCrouchFloatingButton = createFloatingGui("AutoCrouchGui", "Crouch", 0.07, "autoCrouchEnabled", AutoCrouchToggle)
local AutoCarryFloatingGui, AutoCarryFloatingButton = createFloatingGui("AutoCarryGui", "Carry", 0.14, "autoCarryEnabled", AutoCarryToggle)
local GravityFloatingGui, GravityFloatingButton = createFloatingGui("GravityGui", "Gravity", 0.21, "customGravityEnabled", GravityToggle)
local LagSwitchFloatingGui, LagSwitchFloatingButton = createFloatingGui("LagSwitchGui", "Lag", 0.28, "lagSwitchEnabled", LagSwitchToggle)

-- Setup SaveManager
SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})

SaveManager:RegisterNewElement(BhopToggle, "BhopToggle")
SaveManager:RegisterNewElement(AutoCrouchToggle, "AutoCrouchToggle")
SaveManager:RegisterNewElement(AutoCarryToggle, "AutoCarryToggle")
SaveManager:RegisterNewElement(GravityToggle, "GravityToggle")
SaveManager:RegisterNewElement(LagSwitchToggle, "LagSwitchToggle")
SaveManager:RegisterNewElement(TimerDisplayToggle, "TimerDisplayToggle")
