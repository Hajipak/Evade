-- Load Fluent dan Addons
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

-- Buat Window
local Window = Fluent:CreateWindow({
    Title = "Movement Hub",
    SubTitle = "by Zen",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

-- Services (Ambil dari DaraHub-Evade Test.txt)
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local VirtualUser = game:GetService("VirtualUser")
local HttpService = game:GetService("HttpService")
local Debris = game:GetService("Debris")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local rootPart = character:WaitForChild("HumanoidRootPart")
local humanoid = character:WaitForChild("Humanoid")

-- Variabel Global dan Status Fitur (Ambil dan sesuaikan dari DaraHub-Evade Test.txt)
if not getgenv().bounceEnabled then getgenv().bounceEnabled = false end
if not getgenv().bounceHeight then getgenv().bounceHeight = 0 end
if not getgenv().bounceEpsilon then getgenv().bounceEpsilon = 0.1 end
if not getgenv().bhopMode then getgenv().bhopMode = "Acceleration" end
if not getgenv().bhopAccelValue then getgenv().bhopAccelValue = -0.1 end
if not getgenv().bhopHoldActive then getgenv().bhopHoldActive = false end
if not getgenv().autoJumpEnabled then getgenv().autoJumpEnabled = false end
if not getgenv().autoCrouchEnabled then getgenv().autoCrouchEnabled = false end
if not getgenv().customGravityEnabled then getgenv().customGravityEnabled = false end
if not getgenv().customGravityValue then getgenv().customGravityValue = workspace.Gravity end
if not getgenv().slideSpeed then getgenv().slideSpeed = -8 end
if not getgenv().guiButtonSizeX then getgenv().guiButtonSizeX = 60 end
if not getgenv().guiButtonSizeY then getgenv().guiButtonSizeY = 60 end
if not getgenv().ApplyMode then getgenv().ApplyMode = "None" end -- Tambahkan ApplyMode

if not featureStates then
    featureStates = {
        Bhop = false,
        BhopHold = false,
        BhopGuiVisible = false,
        AutoCarry = false,
        AutoCarryGuiVisible = false,
        AutoCrouch = false,
        AutoCrouchGuiVisible = false,
        CustomGravity = false,
        GravityValue = workspace.Gravity,
        GravityGuiVisible = false,
        AutoCrouchMode = "Air", -- Tambahkan default mode
        -- Tambahkan state lain jika perlu
    }
end

if not currentSettings then
    currentSettings = {
        AirStrafeAcceleration = "187",
        JumpCap = "1",
        Speed = "1500",
        -- Tambahkan setting lain jika perlu
    }
end

-- Koneksi dan variabel logika
local bhopConnection = nil
local slideConnection = nil
local bounceConnection = nil
local autoCarryConnection = nil
local autoCrouchConnection = nil
local gravityConnection = nil
local originalGravity = workspace.Gravity
local roundStartedConnection = nil
local characterAddedConnection = nil

-- [Fungsi-fungsi penting dari DaraHub-Evade Test.txt]
-- Fungsi untuk mendapatkan tabel konfigurasi
local function hasAllFields(tbl)
    if type(tbl) ~= "table" then return false end
    local requiredFields = {Friction = true, AirStrafeAcceleration = true, JumpHeight = true, RunDeaccel = true, JumpSpeedMultiplier = true, JumpCap = true, SprintCap = true, WalkSpeedMultiplier = true, BhopEnabled = true, Speed = true, AirAcceleration = true, RunAccel = true, SprintAcceleration = true}
    for field, _ in pairs(requiredFields) do
        if rawget(tbl, field) == nil then return false end
    end
    return true
end

local function getConfigTables()
    local tables = {}
    for _, obj in ipairs(getgc(true)) do -- getgc() untuk mendapatkan semua objek
        local success, result = pcall(function() if hasAllFields(obj) then return obj end end)
        if success and result then
            table.insert(tables, result)
        end
    end
    return tables
end

-- Fungsi untuk menerapkan pengaturan ke tabel-tabel
local function applyToTables(callback)
    local targets = getConfigTables()
    if #targets == 0 then return end
    if getgenv().ApplyMode == "Optimized" then
        task.spawn(function()
            for i, tableObj in ipairs(targets) do
                if tableObj and typeof(tableObj) == "table" then
                    pcall(callback, tableObj)
                end
                if i % 3 == 0 then -- Yield setiap 3 tabel
                    task.wait()
                end
            end
        end)
    elseif getgenv().ApplyMode == "Not Optimized" then
        for i, tableObj in ipairs(targets) do
            if tableObj and typeof(tableObj) == "table" then
                pcall(callback, tableObj)
            end
        end
    end
    -- Jika ApplyMode adalah "None", tidak menerapkan apa-apa
end

-- Fungsi untuk membuat input tervalidasi
local function createValidatedInput(config)
    return function(input)
        local val = tonumber(input)
        if not val then return end
        if config.min and val < config.min then return end
        if config.max and val > config.max then return end
        currentSettings[config.field] = tostring(val)
        applyToTables(function(obj) obj[config.field] = val end)
    end
end

-- Fungsi untuk menerapkan pengaturan yang disimpan
local function applyStoredSettings()
    local settings = {
        {field = "Speed", value = tonumber(currentSettings.Speed)},
        {field = "JumpCap", value = tonumber(currentSettings.JumpCap)},
        {field = "AirStrafeAcceleration", value = tonumber(currentSettings.AirStrafeAcceleration)}
    }
    for _, setting in ipairs(settings) do
        if setting.value and tostring(setting.value) ~= "1500" and tostring(setting.value) ~= "1" and tostring(setting.value) ~= "187" then
            applyToTables(function(obj) obj[setting.field] = setting.value end)
        end
    end
end

-- Fungsi untuk Auto Carry (ambil dari DaraHub-Evade Test.txt)
local function startAutoCarry()
    if autoCarryConnection then autoCarryConnection:Disconnect() end
    autoCarryConnection = RunService.Heartbeat:Connect(function()
        if not featureStates.AutoCarry then return end
        local char = player.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then
            for _, other in ipairs(Players:GetPlayers()) do
                if other ~= player and other.Character then
                    local otherHrp = other.Character:FindFirstChild("HumanoidRootPart")
                    if otherHrp then
                        local dist = (hrp.Position - otherHrp.Position).Magnitude
                        if dist <= 10 then -- Ganti dengan jarak yang diinginkan
                            local args = { "Carry", [3] = other.Name }
                            pcall(function() ReplicatedStorage:WaitForChild("Events"):WaitForChild("Character"):WaitForChild("Interact"):FireServer(unpack(args)) end)
                            task.wait(0.01) -- Delay kecil
                        end
                    end
                end
            end
        end
    end)
end

local function stopAutoCarry()
    if autoCarryConnection then
        autoCarryConnection:Disconnect()
        autoCarryConnection = nil
    end
end

-- Fungsi untuk Auto Crouch (ambil dari DaraHub-Evade Test.txt)
local previousCrouchState = false
local spamDown = true
local holding = false
local validHold = false

-- Fungsi fireKeybind (gantilah dengan implementasi Anda jika tidak ada)
local function fireKeybind(state, action)
    -- Contoh implementasi (gantilah dengan fungsi asli dari DaraHub-Evade jika berbeda)
    if action == "Crouch" then
        if state then
            -- Simulasikan menekan tombol crouch
            -- VirtualUser:PressButton(Enum.KeyCode.LeftControl) -- Contoh
        else
            -- Simulasikan melepaskan tombol crouch
            -- VirtualUser:ReleaseButton(Enum.KeyCode.LeftControl) -- Contoh
        end
    elseif action == "Jump" then
        -- Implementasi untuk jump jika diperlukan
    end
end

-- Fungsi checkBhopState (gantilah dengan implementasi Anda jika tidak ada)
local function checkBhopState()
    -- Logika untuk menyesuaikan tombol Bhop berdasarkan getgenv().bhopHoldActive dan getgenv().autoJumpEnabled
    -- Contoh:
    -- if getgenv().autoJumpEnabled and getgenv().bhopHoldActive then
    --     -- Aktifkan keybind hold space
    -- else
    --     -- Nonaktifkan keybind hold space
    -- end
end

local function startAutoCrouch()
    if autoCrouchConnection then autoCrouchConnection:Disconnect() end
    autoCrouchConnection = RunService.Heartbeat:Connect(function()
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
        else -- "Air" atau "Ground"
            local isAirborne = humanoid.FloorMaterial == Enum.Material.Air
            local shouldCrouch = (mode == "Air" and isAirborne) or (mode == "Ground" and not isAirborne)
            if shouldCrouch and not previousCrouchState then
                fireKeybind(true, "Crouch")
                previousCrouchState = true
            elseif not shouldCrouch and previousCrouchState then
                fireKeybind(false, "Crouch")
                previousCrouchState = false
            end
        end
    end)
end

local function stopAutoCrouch()
    if autoCrouchConnection then
        autoCrouchConnection:Disconnect()
        autoCrouchConnection = nil
    end
    fireKeybind(false, "Crouch") -- Reset posisi
    previousCrouchState = false
end

-- Fungsi untuk Infinite Slide (ambil dari DaraHub-Evade Test.txt)
local cachedTables = {}
local plrModel = nil
local currentState = "Normal"

local function setFriction(value)
    if not plrModel then return end
    for _, part in pairs(plrModel:GetChildren()) do
        if part:IsA("BasePart") then
            part.CustomPhysicalProperties = PhysicalProperties.new(0.7, value, 0.5) -- Friction, Density, Elasticity
        end
    end
end

local function updatePlayerModel()
    plrModel = player.Character
    if plrModel then
        setFriction(5) -- Default friction
    end
end

local function onHeartbeat()
    if not plrModel then return end
    if currentState == "Sliding" or currentState == "EmotingSlide" then
        setFriction(getgenv().slideSpeed)
    else
        setFriction(5) -- Default
    end
end

-- Fungsi untuk Bounce (ambil dari DaraHub-Evade Test.txt - Contoh placeholder, ganti dengan yang asli jika kompleks)
local function setupBounceOnTouch(char)
    -- Logika untuk mendeteksi sentuhan dan menerapkan kecepatan
    -- Contoh: iterate parts dan connect .Touched
    -- bounceConnection = part.Touched:Connect(function(hit)
    --     if hit.Parent and hit.Parent:FindFirstChild("Humanoid") then
    --         local bounceVelocity = Vector3.new(0, getgenv().bounceHeight, 0)
    --         rootPart.Velocity = bounceVelocity
    --     end
    -- end)
    print("Bounce Setup for", char.Name) -- Placeholder
end

local function disableBounce()
    -- Logika untuk mematikan bounce
    -- Hapus koneksi-koneksi Touched
    if bounceConnection then
        bounceConnection:Disconnect()
        bounceConnection = nil
    end
    print("Bounce Disabled") -- Placeholder
end

-- Fungsi untuk membuat GUI yang bisa digeser
local function makeDraggable(frame)
    frame.Active = true
    frame.Draggable = true
    local dragDetector = Instance.new("UIDragDetector")
    dragDetector.Parent = frame
    local originalBackground = frame.BackgroundColor3
    local originalTransparency = frame.BackgroundTransparency

    local dragging
    local dragInput
    local dragStart
    local startPos

    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position

            frame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
            frame.BackgroundTransparency = originalTransparency - 0.1
        end
    end)

    frame.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    frame.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false

            frame.BackgroundColor3 = originalBackground
            frame.BackgroundTransparency = originalTransparency
        end
    end)
end

-- Buat Tab
local Tabs = {}
Tabs.Movement = Window:AddTab({ Title = "Movement", Icon = "motion" })
Tabs.Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })

-- Tab Movement
Tabs.Movement:AddSection({ Title = "Bhop", TextSize = 20 })

local BhopToggle = Tabs.Movement:AddToggle("BhopToggle", {
    Title = "Bhop",
    Default = featureStates.Bhop,
    Callback = function(state)
        featureStates.Bhop = state
        getgenv().autoJumpEnabled = state
        if state then
            if not bhopConnection then
                bhopConnection = RunService.Heartbeat:Connect(function()
                    if getgenv().autoJumpEnabled and humanoid and humanoid.FloorMaterial ~= Enum.Material.Air and rootPart.Velocity.Y < 1 then
                        if getgenv().bhopMode == "Acceleration" then
                            rootPart.Velocity = Vector3.new(rootPart.Velocity.X, math.abs(rootPart.Velocity.Y) + getgenv().bhopAccelValue, rootPart.Velocity.Z)
                        else
                            humanoid.Jump = true
                        end
                    end
                end)
            end
        else
            if bhopConnection then
                bhopConnection:Disconnect()
                bhopConnection = nil
            end
        end
        -- Update GUI button jika ada
        if bhopGuiButton then
            bhopGuiButton.Text = state and "On" or "Off"
            bhopGuiButton.BackgroundColor3 = state and Color3.fromRGB(0, 120, 80) or Color3.fromRGB(120, 0, 0)
        end
    end
})

local BhopModeDropdown = Tabs.Movement:AddDropdown("BhopModeDropdown", {
    Title = "Bhop Mode",
    Values = {"Acceleration", "No Acceleration"},
    Multi = false,
    Default = getgenv().bhopMode,
    Callback = function(value)
        getgenv().bhopMode = value
    end
})

local BhopAccelInput = Tabs.Movement:AddInput("BhopAccelInput", {
    Title = "Bhop Acceleration (Negative Only)",
    Placeholder = "-0.5",
    Default = tostring(getgenv().bhopAccelValue),
    Numeric = true,
    Callback = function(value)
        if tostring(value):sub(1, 1) == "-" then
            local n = tonumber(value)
            if n then
                getgenv().bhopAccelValue = n
            end
        end
    end
})

local BhopHoldToggle = Tabs.Movement:AddToggle("BhopHoldToggle", {
    Title = "Bhop (Hold Space/Jump)",
    Default = featureStates.BhopHold,
    Callback = function(state)
        featureStates.BhopHold = state
        getgenv().bhopHoldActive = state
        -- checkBhopState() -- Panggil fungsi untuk update keybind jika ada
    end
})

-- Tombol untuk menampilkan/menyembunyikan GUI Bhop
local BhopGuiToggle = Tabs.Movement:AddToggle("BhopGuiToggle", {
    Title = "Bhop GUI Toggle",
    Default = featureStates.BhopGuiVisible,
    Callback = function(state)
        featureStates.BhopGuiVisible = state
        if bhopGui then
            bhopGui.Enabled = state
        end
    end
})

Tabs.Movement:AddSection({ Title = "Infinite Slide", TextSize = 20 })

local InfiniteSlideToggle = Tabs.Movement:AddToggle("InfiniteSlideToggle", {
    Title = "Infinite Slide",
    Default = false,
    Callback = function(state)
        infiniteSlideEnabled = state
        if slideConnection then
            slideConnection:Disconnect()
            slideConnection = nil
        end
        if state then
            cachedTables = getConfigTables()
            updatePlayerModel()
            slideConnection = RunService.Heartbeat:Connect(onHeartbeat)
            player.CharacterAdded:Connect(function() task.wait(0.1) updatePlayerModel() end)
        else
            cachedTables = nil
            plrModel = nil
            setFriction(5) -- Kembalikan ke default
        end
    end
})

local InfiniteSlideSpeedInput = Tabs.Movement:AddInput("InfiniteSlideSpeedInput", {
    Title = "Set Infinite Slide Speed (Negative Only)",
    Placeholder = "-8 (negative only)",
    Default = tostring(getgenv().slideSpeed),
    Numeric = true,
    Callback = function(text)
        local num = tonumber(text)
        if num and num < 0 then
            getgenv().slideSpeed = num
            -- Jika Infinite Slide aktif, terapkan perubahan segera
            if infiniteSlideEnabled then
                -- Fungsi onHeartbeat akan menerapkan nilai baru saat berikutnya
            end
        end
    end
})

Tabs.Movement:AddSection({ Title = "Player Movement", TextSize = 20 })

local JumpCapInput = Tabs.Movement:AddInput("JumpCapInput", {
    Title = "Set Jump Cap",
    Icon = "chevrons-up",
    Placeholder = "Default 1",
    Default = currentSettings.JumpCap,
    Callback = createValidatedInput({field = "JumpCap", min = 0.1, max = 5088888})
})

local StrafeInput = Tabs.Movement:AddInput("StrafeInput", {
    Title = "Strafe Acceleration",
    Icon = "wind",
    Placeholder = "Default 187",
    Default = currentSettings.AirStrafeAcceleration,
    Callback = createValidatedInput({field = "AirStrafeAcceleration", min = 1, max = 1000888888})
})

-- Tambahkan ApplyMode Dropdown di sini, di bawah Strafe Acceleration
local ApplyMethodDropdown = Tabs.Movement:AddDropdown("ApplyMethodDropdown", {
    Title = "Select Apply Method",
    Values = { "None", "Not Optimized", "Optimized" }, -- Tambahkan "None"
    Multi = false,
    Default = getgenv().ApplyMode, -- Gunakan nilai default "None"
    Callback = function(value)
        getgenv().ApplyMode = value
        -- applyStoredSettings() -- Opsional: Terapkan kembali jika mode berubah
    end
})

Tabs.Movement:AddSection({ Title = "Bounce", TextSize = 20 })

local BounceToggle = Tabs.Movement:AddToggle("BounceToggle", {
    Title = "Enable Bounce",
    Default = getgenv().bounceEnabled,
    Callback = function(state)
        getgenv().bounceEnabled = state
        if state then
            -- Panggil fungsi setupBounceOnTouch(character) jika karakter ada
            if player.Character then
                setupBounceOnTouch(player.Character)
            end
        else
            disableBounce()
        end
    end
})

local BounceHeightInput = Tabs.Movement:AddInput("BounceHeightInput", {
    Title = "Bounce Height",
    Placeholder = "0",
    Default = tostring(getgenv().bounceHeight),
    Numeric = true,
    Callback = function(value)
        local num = tonumber(value)
        if num then
            getgenv().bounceHeight = math.max(0, num)
        end
    end
})

local EpsilonInput = Tabs.Movement:AddInput("EpsilonInput", {
    Title = "Touch Detection Epsilon",
    Placeholder = "0.1",
    Default = tostring(getgenv().bounceEpsilon),
    Numeric = true,
    Callback = function(value)
        local num = tonumber(value)
        if num then
            getgenv().bounceEpsilon = math.max(0, num)
        end
    end
})

Tabs.Movement:AddSection({ Title = "Auto Features", TextSize = 20 })

local AutoCrouchToggle = Tabs.Movement:AddToggle("AutoCrouchToggle", {
    Title = "Auto Crouch",
    Default = featureStates.AutoCrouch,
    Callback = function(state)
        featureStates.AutoCrouch = state
        getgenv().autoCrouchEnabled = state
        if state then
            startAutoCrouch()
        else
            stopAutoCrouch()
        end
    end
})

local AutoCarryToggle = Tabs.Movement:AddToggle("AutoCarryToggle", {
    Title = "Auto Carry",
    Default = featureStates.AutoCarry,
    Callback = function(state)
        featureStates.AutoCarry = state
        if state then
            startAutoCarry()
        else
            stopAutoCarry()
        end
    end
})

local CustomGravityToggle = Tabs.Movement:AddToggle("CustomGravityToggle", {
    Title = "Custom Gravity",
    Default = featureStates.CustomGravity,
    Callback = function(state)
        featureStates.CustomGravity = state
        getgenv().customGravityEnabled = state
        if gravityConnection then
            gravityConnection:Disconnect()
            gravityConnection = nil
        end
        if state then
            workspace.Gravity = getgenv().customGravityValue
            gravityConnection = RunService.Heartbeat:Connect(function()
                if workspace.Gravity ~= getgenv().customGravityValue then
                    workspace.Gravity = getgenv().customGravityValue
                end
            end)
        else
            workspace.Gravity = originalGravity
        end
    end
})

local GravityValueInput = Tabs.Movement:AddInput("GravityValueInput", {
    Title = "Gravity Value",
    Placeholder = tostring(originalGravity),
    Default = tostring(getgenv().customGravityValue),
    Numeric = true,
    Callback = function(text)
        local num = tonumber(text)
        if num then
            getgenv().customGravityValue = num
            if getgenv().customGravityEnabled then
                workspace.Gravity = num
            end
        end
    end
})

-- Tombol untuk menampilkan/menyembunyikan GUI Auto Crouch
local AutoCrouchGuiToggle = Tabs.Movement:AddToggle("AutoCrouchGuiToggle", {
    Title = "Auto Crouch GUI Toggle",
    Default = featureStates.AutoCrouchGuiVisible,
    Callback = function(state)
        featureStates.AutoCrouchGuiVisible = state
        if autoCrouchGui then
            autoCrouchGui.Enabled = state
        end
    end
})

-- Tombol untuk menampilkan/menyembunyikan GUI Auto Carry
local AutoCarryGuiToggle = Tabs.Movement:AddToggle("AutoCarryGuiToggle", {
    Title = "Auto Carry GUI Toggle",
    Default = featureStates.AutoCarryGuiVisible,
    Callback = function(state)
        featureStates.AutoCarryGuiVisible = state
        if autoCarryGui then
            autoCarryGui.Enabled = state
        end
    end
})

-- Tombol untuk menampilkan/menyembunyikan GUI Gravity
local GravityGuiToggle = Tabs.Movement:AddToggle("GravityGuiToggle", {
    Title = "Gravity GUI Toggle",
    Default = featureStates.GravityGuiVisible,
    Callback = function(state)
        featureStates.GravityGuiVisible = state
        if gravityGui then
            gravityGui.Enabled = state
        end
    end
})

Tabs.Movement:AddSection({ Title = "Feature GUI Toggles (Button Size)", TextSize = 20 })

local ButtonSizeXInput = Tabs.Movement:AddInput("ButtonSizeXInput", {
    Title = "Button Size X",
    Placeholder = "60",
    Default = tostring(getgenv().guiButtonSizeX),
    Numeric = true,
    Callback = function(input)
        local val = tonumber(input)
        if val then
            getgenv().guiButtonSizeX = math.max(20, val)
            -- Update ukuran GUI jika sudah dibuat
            if bhopGui and bhopGui.Frame then bhopGui.Frame.Size = UDim2.new(0, getgenv().guiButtonSizeX, 0, getgenv().guiButtonSizeY) end
            if autoCarryGui and autoCarryGui.Frame then autoCarryGui.Frame.Size = UDim2.new(0, getgenv().guiButtonSizeX, 0, getgenv().guiButtonSizeY) end
            if autoCrouchGui and autoCrouchGui.Frame then autoCrouchGui.Frame.Size = UDim2.new(0, getgenv().guiButtonSizeX, 0, getgenv().guiButtonSizeY) end
            if gravityGui and gravityGui.Frame then gravityGui.Frame.Size = UDim2.new(0, getgenv().guiButtonSizeX, 0, getgenv().guiButtonSizeY) end
        end
    end
})

local ButtonSizeYInput = Tabs.Movement:AddInput("ButtonSizeYInput", {
    Title = "Button Size Y",
    Placeholder = "60",
    Default = tostring(getgenv().guiButtonSizeY),
    Numeric = true,
    Callback = function(input)
        local val = tonumber(input)
        if val then
            getgenv().guiButtonSizeY = math.max(20, val)
            -- Update ukuran GUI jika sudah dibuat
            if bhopGui and bhopGui.Frame then bhopGui.Frame.Size = UDim2.new(0, getgenv().guiButtonSizeX, 0, getgenv().guiButtonSizeY) end
            if autoCarryGui and autoCarryGui.Frame then autoCarryGui.Frame.Size = UDim2.new(0, getgenv().guiButtonSizeX, 0, getgenv().guiButtonSizeY) end
            if autoCrouchGui and autoCrouchGui.Frame then autoCrouchGui.Frame.Size = UDim2.new(0, getgenv().guiButtonSizeX, 0, getgenv().guiButtonSizeY) end
            if gravityGui and gravityGui.Frame then gravityGui.Frame.Size = UDim2.new(0, getgenv().guiButtonSizeX, 0, getgenv().guiButtonSizeY) end
        end
    end
})

-- Konfigurasi SaveManager dan InterfaceManager
SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})
InterfaceManager:SetFolder("FluentMovementHub")
SaveManager:SetFolder("FluentMovementHub/specific-game")
InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)
Window:SelectTab(1)

Fluent:Notify({
    Title = "Movement Hub",
    Content = "The Movement Hub has been loaded.",
    Duration = 5
})

SaveManager:LoadAutoloadConfig()

-- --- Pembuatan GUI Tombol ---
local playerGui = player:WaitForChild("PlayerGui")

-- Bhop GUI
local bhopGui, bhopGuiButton
local function createBhopGui(yOffset)
    local bhopGuiOld = playerGui:FindFirstChild("BhopGui")
    if bhopGuiOld then bhopGuiOld:Destroy() end

    bhopGui = Instance.new("ScreenGui")
    bhopGui.Name = "BhopGui"
    bhopGui.IgnoreGuiInset = true
    bhopGui.ResetOnSpawn = false
    bhopGui.Enabled = featureStates.BhopGuiVisible
    bhopGui.Parent = playerGui

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, getgenv().guiButtonSizeX, 0, getgenv().guiButtonSizeY)
    frame.Position = UDim2.new(0.5, -getgenv().guiButtonSizeX/2, 0.12 + (yOffset or 0), 0) -- Atur posisi Y
    frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    frame.BackgroundTransparency = 0.35
    frame.BorderSizePixel = 0
    frame.Parent = bhopGui

    makeDraggable(frame) -- Buat bisa digeser

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = frame

    local label = Instance.new("TextLabel")
    label.Text = "Bhop"
    label.Size = UDim2.new(0.9, 0, 0.35, 0)
    label.Position = UDim2.new(0.05, 0, 0.05, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.Font = Enum.Font.Roboto
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Center
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.TextScaled = true
    label.Parent = frame

    bhopGuiButton = Instance.new("TextButton")
    bhopGuiButton.Name = "ToggleButton"
    bhopGuiButton.Text = getgenv().autoJumpEnabled and "On" or "Off"
    bhopGuiButton.Size = UDim2.new(0.9, 0, 0.5, 0)
    bhopGuiButton.Position = UDim2.new(0.05, 0, 0.4, 0)
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
        bhopGuiButton.Text = getgenv().autoJumpEnabled and "On" or "Off"
        bhopGuiButton.BackgroundColor3 = getgenv().autoJumpEnabled and Color3.fromRGB(0, 120, 80) or Color3.fromRGB(120, 0, 0)
        if BhopToggle then BhopToggle:Set(getgenv().autoJumpEnabled) end
        checkBhopState() -- Panggil fungsi update keybind jika ada
    end)

    return bhopGui, bhopGuiButton
end
createBhopGui(0) -- Buat GUI Bhop di offset Y = 0

-- Auto Carry GUI
local autoCarryGui, autoCarryGuiButton
local function createAutoCarryGui(yOffset)
    local autoCarryGuiOld = playerGui:FindFirstChild("AutoCarryGui")
    if autoCarryGuiOld then autoCarryGuiOld:Destroy() end

    autoCarryGui = Instance.new("ScreenGui")
    autoCarryGui.Name = "AutoCarryGui"
    autoCarryGui.IgnoreGuiInset = true
    autoCarryGui.ResetOnSpawn = false
    autoCarryGui.Enabled = featureStates.AutoCarryGuiVisible
    autoCarryGui.Parent = playerGui

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, getgenv().guiButtonSizeX, 0, getgenv().guiButtonSizeY)
    frame.Position = UDim2.new(0.5, -getgenv().guiButtonSizeX/2 - 70, 0.12 + (yOffset or 0), 0) -- Atur posisi Y dan X (offset ke kiri)
    frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    frame.BackgroundTransparency = 0.35
    frame.BorderSizePixel = 0
    frame.Parent = autoCarryGui

    makeDraggable(frame) -- Buat bisa digeser

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = frame

    local label = Instance.new("TextLabel")
    label.Text = "Carry"
    label.Size = UDim2.new(0.9, 0, 0.35, 0)
    label.Position = UDim2.new(0.05, 0, 0.05, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.Font = Enum.Font.Roboto
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Center
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.TextScaled = true
    label.Parent = frame

    autoCarryGuiButton = Instance.new("TextButton")
    autoCarryGuiButton.Name = "ToggleButton"
    autoCarryGuiButton.Text = featureStates.AutoCarry and "On" or "Off"
    autoCarryGuiButton.Size = UDim2.new(0.9, 0, 0.5, 0)
    autoCarryGuiButton.Position = UDim2.new(0.05, 0, 0.4, 0)
    autoCarryGuiButton.BackgroundColor3 = featureStates.AutoCarry and Color3.fromRGB(0, 120, 80) or Color3.fromRGB(120, 0, 0)
    autoCarryGuiButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    autoCarryGuiButton.Font = Enum.Font.Roboto
    autoCarryGuiButton.TextSize = 14
    autoCarryGuiButton.TextXAlignment = Enum.TextXAlignment.Center
    autoCarryGuiButton.TextYAlignment = Enum.TextYAlignment.Center
    autoCarryGuiButton.TextScaled = true
    autoCarryGuiButton.Parent = frame

    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 4)
    buttonCorner.Parent = autoCarryGuiButton

    autoCarryGuiButton.MouseButton1Click:Connect(function()
        featureStates.AutoCarry = not featureStates.AutoCarry
        if featureStates.AutoCarry then
            startAutoCarry()
        else
            stopAutoCarry()
        end
        autoCarryGuiButton.Text = featureStates.AutoCarry and "On" or "Off"
        autoCarryGuiButton.BackgroundColor3 = featureStates.AutoCarry and Color3.fromRGB(0, 120, 80) or Color3.fromRGB(120, 0, 0)
        if AutoCarryToggle then AutoCarryToggle:Set(featureStates.AutoCarry) end
    end)

    return autoCarryGui, autoCarryGuiButton
end
createAutoCarryGui(0) -- Buat GUI Auto Carry di offset Y = 0

-- Auto Crouch GUI
local autoCrouchGui, autoCrouchGuiButton
local function createAutoCrouchGui(yOffset)
    local autoCrouchGuiOld = playerGui:FindFirstChild("AutoCrouchGui")
    if autoCrouchGuiOld then autoCrouchGuiOld:Destroy() end

    autoCrouchGui = Instance.new("ScreenGui")
    autoCrouchGui.Name = "AutoCrouchGui"
    autoCrouchGui.IgnoreGuiInset = true
    autoCrouchGui.ResetOnSpawn = false
    autoCrouchGui.Enabled = featureStates.AutoCrouchGuiVisible
    autoCrouchGui.Parent = playerGui

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, getgenv().guiButtonSizeX, 0, getgenv().guiButtonSizeY)
    frame.Position = UDim2.new(0.5, -getgenv().guiButtonSizeX/2 + 70, 0.12 + (yOffset or 0), 0) -- Atur posisi Y dan X (offset ke kanan)
    frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    frame.BackgroundTransparency = 0.35
    frame.BorderSizePixel = 0
    frame.Parent = autoCrouchGui

    makeDraggable(frame) -- Buat bisa digeser

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = frame

    local label = Instance.new("TextLabel")
    label.Text = "Crouch"
    label.Size = UDim2.new(0.9, 0, 0.35, 0)
    label.Position = UDim2.new(0.05, 0, 0.05, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.Font = Enum.Font.Roboto
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Center
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.TextScaled = true
    label.Parent = frame

    autoCrouchGuiButton = Instance.new("TextButton")
    autoCrouchGuiButton.Name = "ToggleButton"
    autoCrouchGuiButton.Text = featureStates.AutoCrouch and "On" or "Off"
    autoCrouchGuiButton.Size = UDim2.new(0.9, 0, 0.5, 0)
    autoCrouchGuiButton.Position = UDim2.new(0.05, 0, 0.4, 0)
    autoCrouchGuiButton.BackgroundColor3 = featureStates.AutoCrouch and Color3.fromRGB(0, 120, 80) or Color3.fromRGB(120, 0, 0)
    autoCrouchGuiButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    autoCrouchGuiButton.Font = Enum.Font.Roboto
    autoCrouchGuiButton.TextSize = 14
    autoCrouchGuiButton.TextXAlignment = Enum.TextXAlignment.Center
    autoCrouchGuiButton.TextYAlignment = Enum.TextYAlignment.Center
    autoCrouchGuiButton.TextScaled = true
    autoCrouchGuiButton.Parent = frame

    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 4)
    buttonCorner.Parent = autoCrouchGuiButton

    autoCrouchGuiButton.MouseButton1Click:Connect(function()
        featureStates.AutoCrouch = not featureStates.AutoCrouch
        if featureStates.AutoCrouch then
            startAutoCrouch()
        else
            stopAutoCrouch()
        end
        autoCrouchGuiButton.Text = featureStates.AutoCrouch and "On" or "Off"
        autoCrouchGuiButton.BackgroundColor3 = featureStates.AutoCrouch and Color3.fromRGB(0, 120, 80) or Color3.fromRGB(120, 0, 0)
        if AutoCrouchToggle then AutoCrouchToggle:Set(featureStates.AutoCrouch) end
    end)

    return autoCrouchGui, autoCrouchGuiButton
end
createAutoCrouchGui(0) -- Buat GUI Auto Crouch di offset Y = 0

-- Gravity GUI
local gravityGui, gravityGuiButton
local function createGravityGui(yOffset)
    local gravityGuiOld = playerGui:FindFirstChild("GravityGui")
    if gravityGuiOld then gravityGuiOld:Destroy() end

    gravityGui = Instance.new("ScreenGui")
    gravityGui.Name = "GravityGui"
    gravityGui.IgnoreGuiInset = true
    gravityGui.ResetOnSpawn = false
    gravityGui.Enabled = featureStates.GravityGuiVisible
    gravityGui.Parent = playerGui

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, getgenv().guiButtonSizeX, 0, getgenv().guiButtonSizeY)
    frame.Position = UDim2.new(0.5, -getgenv().guiButtonSizeX/2, 0.12 + (yOffset or 0) + 0.07, 0) -- Atur posisi Y (offset sedikit ke bawah)
    frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    frame.BackgroundTransparency = 0.35
    frame.BorderSizePixel = 0
    frame.Parent = gravityGui

    makeDraggable(frame) -- Buat bisa digeser

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = frame

    local label = Instance.new("TextLabel")
    label.Text = "Gravity"
    label.Size = UDim2.new(0.9, 0, 0.35, 0)
    label.Position = UDim2.new(0.05, 0, 0.05, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.Font = Enum.Font.Roboto
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Center
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.TextScaled = true
    label.Parent = frame

    gravityGuiButton = Instance.new("TextButton")
    gravityGuiButton.Name = "ToggleButton"
    gravityGuiButton.Text = featureStates.CustomGravity and "On" or "Off"
    gravityGuiButton.Size = UDim2.new(0.9, 0, 0.5, 0)
    gravityGuiButton.Position = UDim2.new(0.05, 0, 0.4, 0)
    gravityGuiButton.BackgroundColor3 = featureStates.CustomGravity and Color3.fromRGB(0, 120, 80) or Color3.fromRGB(120, 0, 0)
    gravityGuiButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    gravityGuiButton.Font = Enum.Font.Roboto
    gravityGuiButton.TextSize = 14
    gravityGuiButton.TextXAlignment = Enum.TextXAlignment.Center
    gravityGuiButton.TextYAlignment = Enum.TextYAlignment.Center
    gravityGuiButton.TextScaled = true
    gravityGuiButton.Parent = frame

    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 4)
    buttonCorner.Parent = gravityGuiButton

    gravityGuiButton.MouseButton1Click:Connect(function()
        featureStates.CustomGravity = not featureStates.CustomGravity
        if featureStates.CustomGravity then
            workspace.Gravity = featureStates.GravityValue
        else
            workspace.Gravity = originalGravity
        end
        gravityGuiButton.Text = featureStates.CustomGravity and "On" or "Off"
        gravityGuiButton.BackgroundColor3 = featureStates.CustomGravity and Color3.fromRGB(0, 120, 80) or Color3.fromRGB(120, 0, 0)
        if CustomGravityToggle then CustomGravityToggle:Set(featureStates.CustomGravity) end
    end)

    return gravityGui, gravityGuiButton
end
createGravityGui(0.07) -- Buat GUI Gravity di offset Y = 0.07 (sedikit di bawah Bhop)

-- Tombol Show/UnShow UI dengan Gambar
local ToggleScreenGui = Instance.new("ScreenGui")
ToggleScreenGui.Name = "UIToggleGui"
ToggleScreenGui.IgnoreGuiInset = true
ToggleScreenGui.ResetOnSpawn = false
ToggleScreenGui.Parent = playerGui

local ToggleButtonFrame = Instance.new("Frame")
ToggleButtonFrame.Size = UDim2.new(0, 60, 0, 60)
ToggleButtonFrame.Position = UDim2.new(0, 10, 0, 100)
ToggleButtonFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
ToggleButtonFrame.BorderSizePixel = 0
ToggleButtonFrame.Parent = ToggleScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 12)
UICorner.Parent = ToggleButtonFrame

local UIStroke = Instance.new("UIStroke")
UIStroke.Color = Color3.fromRGB(100, 100, 100)
UIStroke.Thickness = 2
UIStroke.Parent = ToggleButtonFrame

local ToggleImageButton = Instance.new("ImageButton")
ToggleImageButton.Size = UDim2.new(1, 0, 1, 0)
ToggleImageButton.Position = UDim2.new(0, 0, 0, 0)
ToggleImageButton.BackgroundTransparency = 1
ToggleImageButton.Image = "rbxassetid://75870247392911" -- Gambar dari URL
ToggleImageButton.ScaleType = Enum.ScaleType.Fit
ToggleImageButton.Parent = ToggleButtonFrame

local UIVisible = true -- Track status UI

local function toggleUI()
    UIVisible = not UIVisible
    if Window and Window.Root then
        Window.Root.Visible = UIVisible
    end
    -- Update warna frame untuk indikasi
    if UIVisible then
        ToggleButtonFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    else
        ToggleButtonFrame.BackgroundColor3 = Color3.fromRGB(65, 65, 65)
    end
end

ToggleImageButton.MouseButton1Click:Connect(toggleUI)

makeDraggable(ToggleButtonFrame)
