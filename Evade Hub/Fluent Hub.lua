local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

local Window = Fluent:CreateWindow({
    Title = "Movement Hub" .. Fluent.Version,
    SubTitle = "by Zen",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true, -- The blur may be detectable, setting this to false disables blur entirely
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl -- Used when theres no MinimizeKeybind
})

--Fluent provides Lucide Icons https://lucide.dev/icons/ for the tabs, icons are optional
-- local Tabs = {} -- Didefinisikan setelah Window

-- Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local VirtualUser = game:GetService("VirtualUser")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local rootPart = character:WaitForChild("HumanoidRootPart")
local humanoid = character:WaitForChild("Humanoid")

-- Variabel Global dan Status Fitur
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
if not getgenv().toggleButtonSizeX then getgenv().toggleButtonSizeX = 60 end -- Ukuran default tombol toggle
if not getgenv().toggleButtonSizeY then getgenv().toggleButtonSizeY = 60 end -- Ukuran default tombol toggle

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
    }
end

if not currentSettings then
    currentSettings = {
        AirStrafeAcceleration = "187",
        JumpCap = "1",
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

-- GUI Variables
local playerGui = player:WaitForChild("PlayerGui")
local bhopGui, bhopGuiButton
local autoCarryGui, autoCarryGuiButton
local autoCrouchGui, autoCrouchGuiButton
local gravityGui, gravityGuiButton

-- Buat Toggle Button UI Eksternal (Hanya Gambar) - DITEMPATKAN DI ATAS
local ToggleScreenGui = Instance.new("ScreenGui")
ToggleScreenGui.Name = "ToggleUI"
ToggleScreenGui.ResetOnSpawn = false
ToggleScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ToggleScreenGui.Parent = playerGui

local ToggleImageButton = Instance.new("ImageButton")
ToggleImageButton.Name = "ToggleImageButton"
ToggleImageButton.Size = UDim2.new(0, getgenv().toggleButtonSizeX, 0, getgenv().toggleButtonSizeY) -- Gunakan ukuran dari variabel
ToggleImageButton.Position = UDim2.new(0, 10, 0.02, 0) -- Atur posisi di atas (0.02 dari atas)
ToggleImageButton.BackgroundTransparency = 1 -- Transparan
ToggleImageButton.BorderSizePixel = 0
ToggleImageButton.Image = "rbxassetid://75870247392911" -- Ganti dengan ID aset Roblox Anda
ToggleImageButton.ImageColor3 = Color3.fromRGB(255, 255, 255) -- Warna gambar (default putih)
ToggleImageButton.ImageTransparency = 0 -- Transparansi gambar (0 = tidak transparan)
ToggleImageButton.Parent = ToggleScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 12) -- Atur radius sesuai keinginan
UICorner.Parent = ToggleImageButton

-- Variable untuk track UI state
local UIVisible = true

-- Fungsi untuk toggle UI
local function toggleUI()
    UIVisible = not UIVisible
    if Window and Window.Root then
        Window.Root.Visible = UIVisible
    end
    -- (Opsional) Ubah transparansi gambar berdasarkan status
    -- ToggleImageButton.ImageTransparency = UIVisible and 0 or 0.5
end

-- Click event
ToggleImageButton.MouseButton1Click:Connect(toggleUI)

-- Drag functionality untuk mobile dan PC
local dragging
local dragInput
local dragStart
local startPos

local function update(input)
    local delta = input.Position - dragStart
    local targetPosition = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    TweenService:Create(ToggleImageButton, TweenInfo.new(0.2), {Position = targetPosition}):Play()
end

ToggleImageButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = ToggleImageButton.Position

        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

ToggleImageButton.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        update(input)
    end
end)

-- Fungsi Validasi Input
if not createValidatedInput then
    function createValidatedInput(config)
        return function(input)
            local val = tonumber(input)
            if not val then return end
            if config.min and val < config.min then return end
            if config.max and val > config.max then return end
            currentSettings[config.field] = tostring(val)
        end
    end
end

-- Fungsi untuk membuat GUI yang bisa digeser
local function makeDraggable(frame)
    frame.Active = true
    frame.Draggable = true
    local dragDetector = Instance.new("UIDragDetector")
    dragDetector.Parent = frame
end

-- Fungsi untuk mencari tabel konfigurasi (mengikuti pola dari DaraHub)
local requiredFields = {
    Friction = true,
    AirStrafeAcceleration = true,
    JumpHeight = true,
    RunDeaccel = true,
    JumpSpeedMultiplier = true,
    JumpCap = true,
    SprintCap = true,
    WalkSpeedMultiplier = true,
    BhopEnabled = true,
    Speed = true,
    AirAcceleration = true,
    RunAccel = true,
    SprintAcceleration = true
}

local function hasAllFields(tbl)
    if type(tbl) ~= "table" then return false end
    for field, _ in pairs(requiredFields) do
        if rawget(tbl, field) == nil then return false end
    end
    return true
end

local function getConfigTables()
    local tables = {}
    for _, obj in ipairs(getgc(true)) do
        local success, result = pcall(function()
            if hasAllFields(obj) then return obj end
        end)
        if success and result then
            table.insert(tables, result)
        end
    end
    return tables
end

-- Fungsi untuk menerapkan nilai-nilai ke tabel konfigurasi (mengikuti pola dari DaraHub)
local function applyToTables(callback)
    local targets = getConfigTables()
    if #targets == 0 then return end
    -- Gunakan metode "Not Optimized" untuk keamanan
    for i, tableObj in ipairs(targets) do
        if tableObj and typeof(tableObj) == "table" then
            pcall(callback, tableObj)
        end
    end
end

-- Fungsi untuk menerapkan nilai-nilai yang disimpan (Air Strafe, Jump Cap)
local function applyStoredSettings()
    -- Cek jika nilai-nilai telah diubah dari default
    local airStrafeVal = tonumber(currentSettings.AirStrafeAcceleration)
    local jumpCapVal = tonumber(currentSettings.JumpCap)

    if airStrafeVal and tostring(airStrafeVal) ~= "187" then
        applyToTables(function(obj) obj.AirStrafeAcceleration = airStrafeVal end)
    end

    if jumpCapVal and tostring(jumpCapVal) ~= "1" then
        applyToTables(function(obj) obj.JumpCap = jumpCapVal end)
    end
end

-- Buat Tab Utama (setelah variabel dan fungsi lainnya didefinisikan)
local Tabs = {}
Tabs.Main = Window:AddTab({ Title = "Main", Icon = "home" })
Tabs.Movement = Window:AddTab({ Title = "Movement", Icon = "motion" })
Tabs.Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })

-- Tab Main
Tabs.Main:AddParagraph("Welcome", "Welcome to Zen Hub v" .. Fluent.Version)

-- Main Settings Section
Tabs.Main:AddSection({ Title = "Main Settings", TextSize = 20 })

local ButtonSizeXInput = Tabs.Main:AddInput("ButtonSizeXInput", {
    Title = "Button Size X",
    Placeholder = "60",
    Default = tostring(getgenv().guiButtonSizeX),
    Numeric = true,
    Callback = function(input)
        local val = tonumber(input)
        if val then
            getgenv().guiButtonSizeX = math.max(20, val)
            if bhopGui and bhopGui.Frame then bhopGui.Frame.Size = UDim2.new(0, getgenv().guiButtonSizeX, 0, getgenv().guiButtonSizeY) end
            if autoCarryGui and autoCarryGui.Frame then autoCarryGui.Frame.Size = UDim2.new(0, getgenv().guiButtonSizeX, 0, getgenv().guiButtonSizeY) end
            if autoCrouchGui and autoCrouchGui.Frame then autoCrouchGui.Frame.Size = UDim2.new(0, getgenv().guiButtonSizeX, 0, getgenv().guiButtonSizeY) end
            if gravityGui and gravityGui.Frame then gravityGui.Frame.Size = UDim2.new(0, getgenv().guiButtonSizeX, 0, getgenv().guiButtonSizeY) end
        end
    end
})

local ButtonSizeYInput = Tabs.Main:AddInput("ButtonSizeYInput", {
    Title = "Button Size Y",
    Placeholder = "60",
    Default = tostring(getgenv().guiButtonSizeY),
    Numeric = true,
    Callback = function(input)
        local val = tonumber(input)
        if val then
            getgenv().guiButtonSizeY = math.max(20, val)
            if bhopGui and bhopGui.Frame then bhopGui.Frame.Size = UDim2.new(0, getgenv().guiButtonSizeX, 0, getgenv().guiButtonSizeY) end
            if autoCarryGui and autoCarryGui.Frame then autoCarryGui.Frame.Size = UDim2.new(0, getgenv().guiButtonSizeX, 0, getgenv().guiButtonSizeY) end
            if autoCrouchGui and autoCrouchGui.Frame then autoCrouchGui.Frame.Size = UDim2.new(0, getgenv().guiButtonSizeX, 0, getgenv().guiButtonSizeY) end
            if gravityGui and gravityGui.Frame then gravityGui.Frame.Size = UDim2.new(0, getgenv().guiButtonSizeX, 0, getgenv().guiButtonSizeY) end
        end
    end
})

-- Tab Movement
-- === Section: Bhop ===
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
    Title = "Bhop Accel (Negative)",
    Placeholder = "-0.5",
    Default = tostring(getgenv().bhopAccelValue),
    Numeric = true,
    Callback = function(input)
        local val = tonumber(input)
        if val and val < 0 then
            getgenv().bhopAccelValue = val
        end
    end
})

local BhopHoldToggle = Tabs.Movement:AddToggle("BhopHoldToggle", {
    Title = "Bhop (Hold Space/Jump)",
    Default = getgenv().bhopHoldActive,
    Callback = function(state)
        getgenv().bhopHoldActive = state
    end
})

local BhopGuiToggle = Tabs.Movement:AddToggle("BhopGuiToggle", {
    Title = "Show Bhop GUI Button",
    Default = featureStates.BhopGuiVisible,
    Callback = function(state)
        featureStates.BhopGuiVisible = state
        if bhopGui then
            bhopGui.Enabled = state
        end
    end
})

-- === Section: Infinite Slide ===
Tabs.Movement:AddSection({ Title = "Infinite Slide", TextSize = 20 })

local InfiniteSlideToggle = Tabs.Movement:AddToggle("InfiniteSlideToggle", {
    Title = "Infinite Slide",
    Default = false,
    Callback = function(state)
        if state then
            if not slideConnection then
                slideConnection = RunService.Heartbeat:Connect(function()
                    if character and rootPart and humanoid.FloorMaterial ~= Enum.Material.Air then
                        local bodyVelocity = rootPart:FindFirstChild("SlideBodyVelocity")
                        if not bodyVelocity then
                            bodyVelocity = Instance.new("BodyVelocity")
                            bodyVelocity.MaxForce = Vector3.new(4000, 0, 4000)
                            bodyVelocity.Velocity = Vector3.new(rootPart.Velocity.X * 0.95, 0, rootPart.Velocity.Z * 0.95)
                            bodyVelocity.Parent = rootPart
                        else
                            bodyVelocity.Velocity = Vector3.new(rootPart.Velocity.X * 0.95, 0, rootPart.Velocity.Z * 0.95)
                        end
                    else
                        local bodyVelocity = rootPart:FindFirstChild("SlideBodyVelocity")
                        if bodyVelocity then
                            bodyVelocity:Destroy()
                        end
                    end
                end)
            end
        else
            if slideConnection then
                slideConnection:Disconnect()
                slideConnection = nil
                local bodyVelocity = rootPart:FindFirstChild("SlideBodyVelocity")
                if bodyVelocity then
                    bodyVelocity:Destroy()
                end
            end
        end
    end
})

local InfiniteSlideSpeedInput = Tabs.Movement:AddInput("InfiniteSlideSpeedInput", {
    Title = "Slide Speed (Negative)",
    Placeholder = "-8",
    Default = tostring(getgenv().slideSpeed),
    Numeric = true,
    Callback = function(input)
        local val = tonumber(input)
        if val and val < 0 then
            getgenv().slideSpeed = val
        end
    end
})

-- === Section: Air Strafe & Jump ===
Tabs.Movement:AddSection({ Title = "Air Strafe & Jump", TextSize = 20 })

local AirStrafeAccelInput = Tabs.Movement:AddInput("AirStrafeAccelInput", {
    Title = "Air Strafe Accel",
    Icon = "wind",
    Placeholder = "Default 187",
    Default = currentSettings.AirStrafeAcceleration,
    Callback = createValidatedInput({field = "AirStrafeAcceleration", min = 1, max = 1000888888})
})

local JumpCapInput = Tabs.Movement:AddInput("JumpCapInput", {
    Title = "Jump Cap",
    Icon = "chevrons-up",
    Placeholder = "Default 1",
    Default = currentSettings.JumpCap,
    Callback = createValidatedInput({field = "JumpCap", min = 0.1, max = 5088888})
})

-- === Section: Bounce ===
Tabs.Movement:AddSection({ Title = "Bounce", TextSize = 20 })

local BounceToggle = Tabs.Movement:AddToggle("BounceToggle", {
    Title = "Enable Bounce",
    Default = getgenv().bounceEnabled,
    Callback = function(state)
        getgenv().bounceEnabled = state
        if state then
            if not bounceConnection then
                bounceConnection = RunService.Heartbeat:Connect(function()
                    if character and rootPart and humanoid.FloorMaterial ~= Enum.Material.Air then
                        if rootPart.Velocity.Y < -getgenv().bounceEpsilon then
                            if humanoid.FloorMaterial ~= Enum.Material.Air and rootPart.Velocity.Y > -1 then
                                rootPart.Velocity = Vector3.new(rootPart.Velocity.X, getgenv().bounceHeight, rootPart.Velocity.Z)
                            end
                        end
                    end
                end)
            end
        else
            if bounceConnection then
                bounceConnection:Disconnect()
                bounceConnection = nil
            end
        end
    end
})

local BounceHeightInput = Tabs.Movement:AddInput("BounceHeightInput", {
    Title = "Bounce Height",
    Placeholder = "Default 0",
    Default = tostring(getgenv().bounceHeight),
    Numeric = true,
    Callback = function(input)
        local val = tonumber(input)
        if val then
            getgenv().bounceHeight = math.max(0, val)
        end
    end
})

local BounceEpsilonInput = Tabs.Movement:AddInput("BounceEpsilonInput", {
    Title = "Touch Detection Epsilon",
    Placeholder = "Default 0.1",
    Default = tostring(getgenv().bounceEpsilon),
    Numeric = true,
    Callback = function(input)
        local val = tonumber(input)
        if val then
            getgenv().bounceEpsilon = math.max(0, val)
        end
    end
})

BounceToggle:OnChanged(function()
    local enabled = getgenv().bounceEnabled
    BounceHeightInput:Set({ Enabled = enabled })
    BounceEpsilonInput:Set({ Enabled = enabled })
end)

-- === Section: Gameplay Features (Auto Carry, Auto Crouch, Gravity) ===
Tabs.Movement:AddSection({ Title = "Gameplay Features", TextSize = 20 })

local AutoCarryToggle = Tabs.Movement:AddToggle("AutoCarryToggle", {
    Title = "Auto Carry",
    Default = featureStates.AutoCarry,
    Callback = function(state)
        featureStates.AutoCarry = state
        if state then
            if not autoCarryConnection then
                autoCarryConnection = RunService.Heartbeat:Connect(function()
                    if character and rootPart then
                        for _, otherPlayer in pairs(Players:GetPlayers()) do
                            if otherPlayer ~= player and otherPlayer.Character then
                                local otherHRP = otherPlayer.Character:FindFirstChild("HumanoidRootPart")
                                if otherHRP then
                                    local dist = (rootPart.Position - otherHRP.Position).Magnitude
                                    if dist <= 20 then
                                        local args = { "Carry", [3] = otherPlayer.Name }
                                        pcall(function()
                                            ReplicatedStorage:WaitForChild("Events"):WaitForChild("Character"):WaitForChild("Interact"):FireServer(unpack(args))
                                        end)
                                        task.wait(0.01)
                                    end
                                end
                            end
                        end
                    end
                end)
            end
        else
            if autoCarryConnection then
                autoCarryConnection:Disconnect()
                autoCarryConnection = nil
            end
        end
        if autoCarryGuiButton then
            autoCarryGuiButton.Text = state and "On" or "Off"
            autoCarryGuiButton.BackgroundColor3 = state and Color3.fromRGB(0, 120, 80) or Color3.fromRGB(120, 0, 0)
        end
    end
})

local AutoCarryGuiToggle = Tabs.Movement:AddToggle("AutoCarryGuiToggle", {
    Title = "Show Auto Carry GUI Button",
    Default = featureStates.AutoCarryGuiVisible,
    Callback = function(state)
        featureStates.AutoCarryGuiVisible = state
        if autoCarryGui then
            autoCarryGui.Enabled = state
        end
    end
})

local AutoCrouchToggle = Tabs.Movement:AddToggle("AutoCrouchToggle", {
    Title = "Auto Crouch",
    Default = getgenv().autoCrouchEnabled,
    Callback = function(state)
        getgenv().autoCrouchEnabled = state
        if state then
            if not autoCrouchConnection then
                autoCrouchConnection = RunService.Heartbeat:Connect(function()
                    if character and humanoid then
                        if not character:GetAttribute("Crouched") then
                            pcall(function()
                                ReplicatedStorage:WaitForChild("Events"):WaitForChild("Character"):WaitForChild("Crouch"):FireServer(true)
                            end)
                        end
                    end
                end)
            end
        else
            if autoCrouchConnection then
                autoCrouchConnection:Disconnect()
                autoCrouchConnection = nil
            end
             pcall(function()
                ReplicatedStorage:WaitForChild("Events"):WaitForChild("Character"):WaitForChild("Crouch"):FireServer(false)
            end)
        end
        if autoCrouchGuiButton then
            autoCrouchGuiButton.Text = state and "On" or "Off"
            autoCrouchGuiButton.BackgroundColor3 = state and Color3.fromRGB(0, 120, 80) or Color3.fromRGB(120, 0, 0)
        end
    end
})

local AutoCrouchGuiToggle = Tabs.Movement:AddToggle("AutoCrouchGuiToggle", {
    Title = "Show Auto Crouch GUI Button",
    Default = featureStates.AutoCrouchGuiVisible,
    Callback = function(state)
        featureStates.AutoCrouchGuiVisible = state
        if autoCrouchGui then
            autoCrouchGui.Enabled = state
        end
    end
})

local GravityToggle = Tabs.Movement:AddToggle("GravityToggle", {
    Title = "Custom Gravity",
    Default = getgenv().customGravityEnabled,
    Callback = function(state)
        getgenv().customGravityEnabled = state
        if state then
            workspace.Gravity = getgenv().customGravityValue
        else
            workspace.Gravity = originalGravity
        end
        if gravityGuiButton then
            gravityGuiButton.Text = state and "On" or "Off"
            gravityGuiButton.BackgroundColor3 = state and Color3.fromRGB(0, 120, 80) or Color3.fromRGB(120, 0, 0)
        end
    end
})

local GravityInput = Tabs.Movement:AddInput("GravityInput", {
    Title = "Gravity Value",
    Placeholder = tostring(originalGravity),
    Default = tostring(getgenv().customGravityValue),
    Numeric = true,
    Callback = function(input)
        local val = tonumber(input)
        if val then
            getgenv().customGravityValue = val
            if getgenv().customGravityEnabled then
                workspace.Gravity = val
            end
        end
    end
})

GravityToggle:OnChanged(function()
    local enabled = getgenv().customGravityEnabled
    GravityInput:Set({ Enabled = enabled })
    if not enabled then
        workspace.Gravity = originalGravity
    else
        workspace.Gravity = getgenv().customGravityValue
    end
end)

local GravityGuiToggle = Tabs.Movement:AddToggle("GravityGuiToggle", {
    Title = "Show Gravity GUI Button",
    Default = featureStates.GravityGuiVisible,
    Callback = function(state)
        featureStates.GravityGuiVisible = state
        if gravityGui then
            gravityGui.Enabled = state
        end
    end
})

-- Tab Settings
Tabs.Settings:AddParagraph("Fluent", "The script has been loaded.")
Tabs.Settings:AddButton("Button", {
    Title = "Button",
    Description = "This is a button",
    Callback = function()
        Window:Dialog({
            Title = "Title",
            Content = "This is a dialog",
            Buttons = {
                { Title = "Confirm", Callback = function() end },
                { Title = "Cancel", Callback = function() end }
            }
        })
    end
})

-- Konfigurasi SaveManager dan InterfaceManager
SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)

-- Ignore keys that are used by ThemeManager.
-- (we dont want configs to save themes, do we?)
SaveManager:IgnoreThemeSettings()
-- You can add indexes of elements the save manager should ignore
SaveManager:SetIgnoreIndexes({})

-- Buat GUI untuk masing-masing fitur
-- Bhop GUI
bhopGui = Instance.new("ScreenGui")
bhopGui.Name = "BhopGui"
bhopGui.IgnoreGuiInset = true
bhopGui.ResetOnSpawn = false
bhopGui.Enabled = featureStates.BhopGuiVisible
bhopGui.Parent = playerGui

local bhopFrame = Instance.new("Frame")
bhopFrame.Size = UDim2.new(0, getgenv().guiButtonSizeX, 0, getgenv().guiButtonSizeY)
bhopFrame.Position = UDim2.new(0.5, -getgenv().guiButtonSizeX/2, 0.12, 0)
bhopFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
bhopFrame.BackgroundTransparency = 0.35
bhopFrame.BorderSizePixel = 0
bhopFrame.Parent = bhopGui

makeDraggable(bhopFrame)

local bhopCorner = Instance.new("UICorner")
bhopCorner.CornerRadius = UDim.new(0, 6)
bhopCorner.Parent = bhopFrame

local bhopLabel = Instance.new("TextLabel")
bhopLabel.Text = "Bhop"
bhopLabel.Size = UDim2.new(0.9, 0, 0.45, 0)
bhopLabel.Position = UDim2.new(0.05, 0, 0.05, 0)
bhopLabel.BackgroundTransparency = 1
bhopLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
bhopLabel.Font = Enum.Font.Roboto
bhopLabel.TextSize = 16
bhopLabel.TextXAlignment = Enum.TextXAlignment.Center
bhopLabel.TextYAlignment = Enum.TextYAlignment.Center
bhopLabel.TextScaled = true
bhopLabel.Parent = bhopFrame

bhopGuiButton = Instance.new("TextButton")
bhopGuiButton.Name = "ToggleButton"
bhopGuiButton.Text = getgenv().autoJumpEnabled and "On" or "Off"
bhopGuiButton.Size = UDim2.new(0.9, 0, 0.45, 0)
bhopGuiButton.Position = UDim2.new(0.05, 0, 0.5, 0)
bhopGuiButton.BackgroundColor3 = getgenv().autoJumpEnabled and Color3.fromRGB(0, 120, 80) or Color3.fromRGB(120, 0, 0)
bhopGuiButton.TextColor3 = Color3.fromRGB(255, 255, 255)
bhopGuiButton.Font = Enum.Font.Roboto
bhopGuiButton.TextSize = 14
bhopGuiButton.TextXAlignment = Enum.TextXAlignment.Center
bhopGuiButton.TextYAlignment = Enum.TextYAlignment.Center
bhopGuiButton.TextScaled = true
bhopGuiButton.Parent = bhopFrame

local bhopButtonCorner = Instance.new("UICorner")
bhopButtonCorner.CornerRadius = UDim.new(0, 4)
bhopButtonCorner.Parent = bhopGuiButton

bhopGuiButton.MouseButton1Click:Connect(function()
    getgenv().autoJumpEnabled = not getgenv().autoJumpEnabled
    featureStates.Bhop = getgenv().autoJumpEnabled
    bhopGuiButton.Text = getgenv().autoJumpEnabled and "On" or "Off"
    bhopGuiButton.BackgroundColor3 = getgenv().autoJumpEnabled and Color3.fromRGB(0, 120, 80) or Color3.fromRGB(120, 0, 0)
    if BhopToggle then BhopToggle:Set(featureStates.Bhop) end
end)

-- Auto Carry GUI
autoCarryGui = Instance.new("ScreenGui")
autoCarryGui.Name = "AutoCarryGui"
autoCarryGui.IgnoreGuiInset = true
autoCarryGui.ResetOnSpawn = false
autoCarryGui.Enabled = featureStates.AutoCarryGuiVisible
autoCarryGui.Parent = playerGui

local autoCarryFrame = Instance.new("Frame")
autoCarryFrame.Size = UDim2.new(0, getgenv().guiButtonSizeX, 0, getgenv().guiButtonSizeY)
autoCarryFrame.Position = UDim2.new(0.5, -getgenv().guiButtonSizeX/2 - 70, 0.12, 0)
autoCarryFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
autoCarryFrame.BackgroundTransparency = 0.35
autoCarryFrame.BorderSizePixel = 0
autoCarryFrame.Parent = autoCarryGui

makeDraggable(autoCarryFrame)

local autoCarryCorner = Instance.new("UICorner")
autoCarryCorner.CornerRadius = UDim.new(0, 6)
autoCarryCorner.Parent = autoCarryFrame

local autoCarryLabel = Instance.new("TextLabel")
autoCarryLabel.Text = "Carry"
autoCarryLabel.Size = UDim2.new(0.9, 0, 0.45, 0)
autoCarryLabel.Position = UDim2.new(0.05, 0, 0.05, 0)
autoCarryLabel.BackgroundTransparency = 1
autoCarryLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
autoCarryLabel.Font = Enum.Font.Roboto
autoCarryLabel.TextSize = 16
autoCarryLabel.TextXAlignment = Enum.TextXAlignment.Center
autoCarryLabel.TextYAlignment = Enum.TextYAlignment.Center
autoCarryLabel.TextScaled = true
autoCarryLabel.Parent = autoCarryFrame

autoCarryGuiButton = Instance.new("TextButton")
autoCarryGuiButton.Name = "ToggleButton"
autoCarryGuiButton.Text = featureStates.AutoCarry and "On" or "Off"
autoCarryGuiButton.Size = UDim2.new(0.9, 0, 0.45, 0)
autoCarryGuiButton.Position = UDim2.new(0.05, 0, 0.5, 0)
autoCarryGuiButton.BackgroundColor3 = featureStates.AutoCarry and Color3.fromRGB(0, 120, 80) or Color3.fromRGB(120, 0, 0)
autoCarryGuiButton.TextColor3 = Color3.fromRGB(255, 255, 255)
autoCarryGuiButton.Font = Enum.Font.Roboto
autoCarryGuiButton.TextSize = 14
autoCarryGuiButton.TextXAlignment = Enum.TextXAlignment.Center
autoCarryGuiButton.TextYAlignment = Enum.TextYAlignment.Center
autoCarryGuiButton.TextScaled = true
autoCarryGuiButton.Parent = autoCarryFrame

local autoCarryButtonCorner = Instance.new("UICorner")
autoCarryButtonCorner.CornerRadius = UDim.new(0, 4)
autoCarryButtonCorner.Parent = autoCarryGuiButton

autoCarryGuiButton.MouseButton1Click:Connect(function()
    featureStates.AutoCarry = not featureStates.AutoCarry
    autoCarryGuiButton.Text = featureStates.AutoCarry and "On" or "Off"
    autoCarryGuiButton.BackgroundColor3 = featureStates.AutoCarry and Color3.fromRGB(0, 120, 80) or Color3.fromRGB(120, 0, 0)
    if AutoCarryToggle then AutoCarryToggle:Set(featureStates.AutoCarry) end
    if featureStates.AutoCarry then
        if not autoCarryConnection then
            autoCarryConnection = RunService.Heartbeat:Connect(function()
                if character and rootPart then
                    for _, otherPlayer in pairs(Players:GetPlayers()) do
                        if otherPlayer ~= player and otherPlayer.Character then
                            local otherHRP = otherPlayer.Character:FindFirstChild("HumanoidRootPart")
                            if otherHRP then
                                local dist = (rootPart.Position - otherHRP.Position).Magnitude
                                if dist <= 20 then
                                    local args = { "Carry", [3] = otherPlayer.Name }
                                    pcall(function()
                                        ReplicatedStorage:WaitForChild("Events"):WaitForChild("Character"):WaitForChild("Interact"):FireServer(unpack(args))
                                    end)
                                    task.wait(0.01)
                                end
                            end
                        end
                    end
                end
            end)
        end
    else
        if autoCarryConnection then
            autoCarryConnection:Disconnect()
            autoCarryConnection = nil
        end
    end
end)

-- Auto Crouch GUI
autoCrouchGui = Instance.new("ScreenGui")
autoCrouchGui.Name = "AutoCrouchGui"
autoCrouchGui.IgnoreGuiInset = true
autoCrouchGui.ResetOnSpawn = false
autoCrouchGui.Enabled = featureStates.AutoCrouchGuiVisible
autoCrouchGui.Parent = playerGui

local autoCrouchFrame = Instance.new("Frame")
autoCrouchFrame.Size = UDim2.new(0, getgenv().guiButtonSizeX, 0, getgenv().guiButtonSizeY)
autoCrouchFrame.Position = UDim2.new(0.5, -getgenv().guiButtonSizeX/2 + 70, 0.12, 0)
autoCrouchFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
autoCrouchFrame.BackgroundTransparency = 0.35
autoCrouchFrame.BorderSizePixel = 0
autoCrouchFrame.Parent = autoCrouchGui

makeDraggable(autoCrouchFrame)

local autoCrouchCorner = Instance.new("UICorner")
autoCrouchCorner.CornerRadius = UDim.new(0, 6)
autoCrouchCorner.Parent = autoCrouchFrame

local autoCrouchLabel = Instance.new("TextLabel")
autoCrouchLabel.Text = "Crouch"
autoCrouchLabel.Size = UDim2.new(0.9, 0, 0.45, 0)
autoCrouchLabel.Position = UDim2.new(0.05, 0, 0.05, 0)
autoCrouchLabel.BackgroundTransparency = 1
autoCrouchLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
autoCrouchLabel.Font = Enum.Font.Roboto
autoCrouchLabel.TextSize = 16
autoCrouchLabel.TextXAlignment = Enum.TextXAlignment.Center
autoCrouchLabel.TextYAlignment = Enum.TextYAlignment.Center
autoCrouchLabel.TextScaled = true
autoCrouchLabel.Parent = autoCrouchFrame

autoCrouchGuiButton = Instance.new("TextButton")
autoCrouchGuiButton.Name = "ToggleButton"
autoCrouchGuiButton.Text = getgenv().autoCrouchEnabled and "On" or "Off"
autoCrouchGuiButton.Size = UDim2.new(0.9, 0, 0.45, 0)
autoCrouchGuiButton.Position = UDim2.new(0.05, 0, 0.5, 0)
autoCrouchGuiButton.BackgroundColor3 = getgenv().autoCrouchEnabled and Color3.fromRGB(0, 120, 80) or Color3.fromRGB(120, 0, 0)
autoCrouchGuiButton.TextColor3 = Color3.fromRGB(255, 255, 255)
autoCrouchGuiButton.Font = Enum.Font.Roboto
autoCrouchGuiButton.TextSize = 14
autoCrouchGuiButton.TextXAlignment = Enum.TextXAlignment.Center
autoCrouchGuiButton.TextYAlignment = Enum.TextYAlignment.Center
autoCrouchGuiButton.TextScaled = true
autoCrouchGuiButton.Parent = autoCrouchFrame

local autoCrouchButtonCorner = Instance.new("UICorner")
autoCrouchButtonCorner.CornerRadius = UDim.new(0, 4)
autoCrouchButtonCorner.Parent = autoCrouchGuiButton

autoCrouchGuiButton.MouseButton1Click:Connect(function()
    getgenv().autoCrouchEnabled = not getgenv().autoCrouchEnabled
    featureStates.AutoCrouch = getgenv().autoCrouchEnabled
    autoCrouchGuiButton.Text = getgenv().autoCrouchEnabled and "On" or "Off"
    autoCrouchGuiButton.BackgroundColor3 = getgenv().autoCrouchEnabled and Color3.fromRGB(0, 120, 80) or Color3.fromRGB(120, 0, 0)
    if AutoCrouchToggle then AutoCrouchToggle:Set(featureStates.AutoCrouch) end
    if getgenv().autoCrouchEnabled then
        if not autoCrouchConnection then
            autoCrouchConnection = RunService.Heartbeat:Connect(function()
                if character and humanoid then
                    if not character:GetAttribute("Crouched") then
                        pcall(function()
                            ReplicatedStorage:WaitForChild("Events"):WaitForChild("Character"):WaitForChild("Crouch"):FireServer(true)
                        end)
                    end
                end
            end)
        end
    else
        if autoCrouchConnection then
            autoCrouchConnection:Disconnect()
            autoCrouchConnection = nil
        end
         pcall(function()
            ReplicatedStorage:WaitForChild("Events"):WaitForChild("Character"):WaitForChild("Crouch"):FireServer(false)
        end)
    end
end)

-- Gravity GUI
gravityGui = Instance.new("ScreenGui")
gravityGui.Name = "GravityGui"
gravityGui.IgnoreGuiInset = true
gravityGui.ResetOnSpawn = false
gravityGui.Enabled = featureStates.GravityGuiVisible
gravityGui.Parent = playerGui

local gravityFrame = Instance.new("Frame")
gravityFrame.Size = UDim2.new(0, getgenv().guiButtonSizeX, 0, getgenv().guiButtonSizeY)
gravityFrame.Position = UDim2.new(0.5, -getgenv().guiButtonSizeX/2, 0.12 + 0.08, 0)
gravityFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
gravityFrame.BackgroundTransparency = 0.35
gravityFrame.BorderSizePixel = 0
gravityFrame.Parent = gravityGui

makeDraggable(gravityFrame)

local gravityCorner = Instance.new("UICorner")
gravityCorner.CornerRadius = UDim.new(0, 6)
gravityCorner.Parent = gravityFrame

local gravityLabel = Instance.new("TextLabel")
gravityLabel.Text = "Gravity"
gravityLabel.Size = UDim2.new(0.9, 0, 0.45, 0)
gravityLabel.Position = UDim2.new(0.05, 0, 0.05, 0)
gravityLabel.BackgroundTransparency = 1
gravityLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
gravityLabel.Font = Enum.Font.Roboto
gravityLabel.TextSize = 16
gravityLabel.TextXAlignment = Enum.TextXAlignment.Center
gravityLabel.TextYAlignment = Enum.TextYAlignment.Center
gravityLabel.TextScaled = true
gravityLabel.Parent = gravityFrame

gravityGuiButton = Instance.new("TextButton")
gravityGuiButton.Name = "ToggleButton"
gravityGuiButton.Text = getgenv().customGravityEnabled and "On" or "Off"
gravityGuiButton.Size = UDim2.new(0.9, 0, 0.45, 0)
gravityGuiButton.Position = UDim2.new(0.05, 0, 0.5, 0)
gravityGuiButton.BackgroundColor3 = getgenv().customGravityEnabled and Color3.fromRGB(0, 120, 80) or Color3.fromRGB(120, 0, 0)
gravityGuiButton.TextColor3 = Color3.fromRGB(255, 255, 255)
gravityGuiButton.Font = Enum.Font.Roboto
gravityGuiButton.TextSize = 14
gravityGuiButton.TextXAlignment = Enum.TextXAlignment.Center
gravityGuiButton.TextYAlignment = Enum.TextYAlignment.Center
gravityGuiButton.TextScaled = true
gravityGuiButton.Parent = gravityFrame

local gravityButtonCorner = Instance.new("UICorner")
gravityButtonCorner.CornerRadius = UDim.new(0, 4)
gravityButtonCorner.Parent = gravityGuiButton

gravityGuiButton.MouseButton1Click:Connect(function()
    getgenv().customGravityEnabled = not getgenv().customGravityEnabled
    featureStates.CustomGravity = getgenv().customGravityEnabled
    gravityGuiButton.Text = getgenv().customGravityEnabled and "On" or "Off"
    gravityGuiButton.BackgroundColor3 = getgenv().customGravityEnabled and Color3.fromRGB(0, 120, 80) or Color3.fromRGB(120, 0, 0)
    if GravityToggle then GravityToggle:Set(featureStates.CustomGravity) end
    if getgenv().customGravityEnabled then
        workspace.Gravity = getgenv().customGravityValue
    else
        workspace.Gravity = originalGravity
    end
end)

-- Hubungkan fungsi applyStoredSettings ke CharacterAdded dan RoundStarted
characterAddedConnection = player.CharacterAdded:Connect(function(newCharacter)
    task.wait(0.1)
    applyStoredSettings()
end)

local success, gameStats = pcall(function()
    return workspace:WaitForChild("Game", 10):WaitForChild("Stats", 10)
end)

if success and gameStats then
    roundStartedConnection = gameStats:GetAttributeChangedSignal("RoundStarted"):Connect(function()
        local roundStarted = gameStats:GetAttribute("RoundStarted")
        if roundStarted == true then
            applyStoredSettings()
        end
    end)
    if gameStats:GetAttribute("RoundStarted") == true then
        applyStoredSettings()
    end
end

-- Muat tema dan tata letak
InterfaceManager:SetFolder("ZenHub") -- Ganti dengan nama folder Anda jika perlu
SaveManager:SetFolder("ZenHub") -- Ganti dengan nama folder Anda jika perlu
InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)

Window:SelectTab(1)

Fluent:Notify({
    Title = "Zen Hub Loaded",
    Content = "Movement features and persistent settings are ready.",
    Duration = 8
})

-- Eksekusi loadstring tambahan
loadstring(game:HttpGet('https://raw.githubusercontent.com/Hajipak/Evade/refs/heads/main/Script/More-loadstring.lua'))()

-- Muat konfigurasi otomatis jika ada
SaveManager:LoadAutoloadConfig()
