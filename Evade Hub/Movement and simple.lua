if getgenv().MovementHubExecuted then return end
getgenv().MovementHubExecuted = true

-- Load WindUI
local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()
WindUI.TransparencyValue = 0.2
WindUI:SetTheme("Dark")

local Window = WindUI:CreateWindow({
    Title = "Movement Hub",
    Icon = "rocket",
    Author = "Made by Zen",
    Folder = "GameHackUI",
    Size = UDim2.fromOffset(580, 490),
    Theme = "Dark"
})

-- Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local workspace = game.workspace
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Config
local configFileName = "movement_hub_final.txt"

-- Default settings (ApplyMode kosong!)
local currentSettings = {
    Speed = "1500",
    JumpCap = "1",
    StrafeAcceleration = "187",
    ApplyMode = "",  -- KOSONG
    Bhop = "false",
    AutoCrouch = "false",
    AutoCrouchMode = "Air",
    Bounce = "false",
    BounceHeight = "0",
    BounceEpsilon = "0.1",
    BhopMode = "Acceleration",
    BhopAccelValue = "-0.5",
    InfinitySlide = "false",
    SlideFriction = "-8",
    LagSwitch = "false",
    LagDuration = "0.5",
    GuiWidth = "80",
    GuiHeight = "50",
    ShowBhopGui = "false",
    ShowAutoCrouchGui = "false",
    ShowBounceGui = "false",
    ShowInfinitySlideGui = "false",
    ShowLagSwitchGui = "false"
}

-- Load config
if isfile(configFileName) then
    local success, data = pcall(function()
        return HttpService:JSONDecode(readfile(configFileName))
    end)
    if success and type(data) == "table" then
        for k, v in pairs(data) do
            if currentSettings[k] ~= nil then
                currentSettings[k] = tostring(v)
            end
        end
    end
end

-- Save config
local function saveConfig()
    writefile(configFileName, HttpService:JSONEncode(currentSettings))
end

-- === GET GAME TABLES ===
local requiredFields = {
    Friction = true,
    AirStrafeAcceleration = true,
    JumpCap = true,
    Speed = true
}

local function hasAllFields(tbl)
    if type(tbl) ~= "table" then return false end
    for field in pairs(requiredFields) do
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

local function applyToTables(callback)
    local targets = getConfigTables()
    if #targets == 0 then return end
    if currentSettings.ApplyMode == "Optimized" then
        task.spawn(function()
            for i, t in ipairs(targets) do
                if t and type(t) == "table" then
                    pcall(callback, t)
                end
                if i % 3 == 0 then task.wait() end
            end
        end)
    else
        for _, t in ipairs(targets) do
            if t and type(t) == "table" then
                pcall(callback, t)
            end
        end
    end
end

local function applyStoredSettings()
    if currentSettings.ApplyMode == "" then return end
    applyToTables(function(obj)
        obj.Speed = tonumber(currentSettings.Speed) or 1500
        obj.JumpCap = tonumber(currentSettings.JumpCap) or 1
        obj.AirStrafeAcceleration = tonumber(currentSettings.StrafeAcceleration) or 187
    end)
end

-- === BOUNCE ===
local BOUNCE_ENABLED = currentSettings.Bounce == "true"
local BOUNCE_HEIGHT = tonumber(currentSettings.BounceHeight) or 0
local BOUNCE_EPSILON = tonumber(currentSettings.BounceEpsilon) or 0.1
local touchConnections = {}

local function setupBounceOnTouch(character)
    if not BOUNCE_ENABLED then return end
    local hrp = character:WaitForChild("HumanoidRootPart")
    local connection = hrp.Touched:Connect(function(hit)
        local playerBottom = hrp.Position.Y - hrp.Size.Y / 2
        local hitTop = hit.Position.Y + hit.Size.Y / 2
        if hitTop <= playerBottom + BOUNCE_EPSILON then return end
        if ReplicatedStorage:FindFirstChild("Events") and ReplicatedStorage.Events.Character:FindFirstChild("PassCharacterInfo") then
            ReplicatedStorage.Events.Character.PassCharacterInfo:FireServer({}, {2})
        end
        if BOUNCE_HEIGHT > 0 then
            local bodyVel = Instance.new("BodyVelocity")
            bodyVel.MaxForce = Vector3.new(0, math.huge, 0)
            bodyVel.Velocity = Vector3.new(0, BOUNCE_HEIGHT, 0)
            bodyVel.Parent = hrp
            game:GetService("Debris"):AddItem(bodyVel, 0.2)
        end
    end)
    touchConnections[character] = connection
end

local function disableBounce()
    for char, conn in pairs(touchConnections) do
        if conn then conn:Disconnect() end
    end
    touchConnections = {}
end

if player.Character then setupBounceOnTouch(player.Character) end
player.CharacterAdded:Connect(setupBounceOnTouch)

-- === AUTO CROUCH ===
local previousCrouchState = false
local spamDown = true

local function fireCrouch(down)
    local event = player:WaitForChild("PlayerScripts"):WaitForChild("Events"):WaitForChild("temporary_events"):WaitForChild("UseKeybind")
    event:Fire({ Down = down, Key = "Crouch" })
end

RunService.Heartbeat:Connect(function()
    if not (currentSettings.AutoCrouch == "true") then
        if previousCrouchState then
            fireCrouch(false)
            previousCrouchState = false
        end
        return
    end
    local char = player.Character
    if not char or not char:FindFirstChild("Humanoid") then return end
    local humanoid = char.Humanoid
    local mode = currentSettings.AutoCrouchMode
    if mode == "Normal" then
        fireCrouch(spamDown)
        spamDown = not spamDown
    else
        local isAir = humanoid.FloorMaterial == Enum.Material.Air
        local shouldCrouch = (mode == "Air" and isAir) or (mode == "Ground" and not isAir)
        if shouldCrouch ~= previousCrouchState then
            fireCrouch(shouldCrouch)
            previousCrouchState = shouldCrouch
        end
    end
end)

-- === BHOP ===
getgenv().autoJumpEnabled = currentSettings.Bhop == "true"
getgenv().bhopMode = currentSettings.BhopMode
getgenv().bhopAccelValue = tonumber(currentSettings.BhopAccelValue) or -0.5

task.spawn(function()
    while true do
        local friction = 5
        if getgenv().autoJumpEnabled and getgenv().bhopMode == "Acceleration" then
            friction = getgenv().bhopAccelValue
        end
        for _, t in pairs(getgc(true)) do
            if type(t) == "table" and rawget(t, "Friction") then
                if getgenv().bhopMode ~= "No Acceleration" then
                    t.Friction = friction
                end
            end
        end
        task.wait(0.15)
    end
end)

task.spawn(function()
    while true do
        if getgenv().autoJumpEnabled then
            local char = player.Character
            if char and char:FindFirstChild("Humanoid") then
                local humanoid = char.Humanoid
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

-- === INFINITY SLIDE (Dara Hub Style) ===
local infiniteSlideEnabled = false
local slideFrictionValue = -8
local plrModel = nil
local slideConnection = nil

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

local function setSlideFriction(value)
    local tables = getConfigTables()
    for _, tbl in ipairs(tables) do
        pcall(function()
            tbl.Friction = value
        end)
    end
end

local function updatePlayerModel()
    local GameFolder = workspace:FindFirstChild("Game")
    local PlayersFolder = GameFolder and GameFolder:FindFirstChild("Players")
    if PlayersFolder then
        plrModel = PlayersFolder:FindFirstChild(player.Name)
    else
        plrModel = nil
    end
end

local function onHeartbeat()
    if not plrModel then
        setSlideFriction(5)
        return
    end
    local success, currentState = pcall(function()
        return plrModel:GetAttribute("State")
    end)
    if success and currentState then
        if currentState == "Slide" then
            pcall(function()
                plrModel:SetAttribute("State", "EmotingSlide")
            end)
        elseif currentState == "EmotingSlide" then
            setSlideFriction(slideFrictionValue)
        else
            setSlideFriction(5)
        end
    else
        setSlideFriction(5)
    end
end

-- === DRAGGABLE ===
local function makeDraggable(frame)
    local dragging, dragStart, startPos
    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
        end
    end)
    frame.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

-- === FLOATING GUI CREATOR ===
local function createFloatingGui(guiName, titleText, buttonConfig)
    local old = playerGui:FindFirstChild(guiName)
    if old then old:Destroy() end

    local w = tonumber(currentSettings.GuiWidth) or 80
    local h = tonumber(currentSettings.GuiHeight) or 50
    local headerHeight = 20
    local buttonHeight = h - headerHeight

    local gui = Instance.new("ScreenGui")
    gui.Name = guiName
    gui.ResetOnSpawn = false
    gui.Parent = playerGui

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, w, 0, h)
    frame.Position = UDim2.new(0.5, -w/2, 0.1, 0)
    frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    frame.BackgroundTransparency = 0.3
    frame.BorderSizePixel = 0
    frame.Parent = gui

    makeDraggable(frame)

    -- Header hitam
    local header = Instance.new("TextLabel")
    header.Text = titleText
    header.BackgroundTransparency = 0
    header.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    header.TextColor3 = Color3.fromRGB(255, 255, 255)
    header.Font = Enum.Font.Roboto
    header.TextSize = 14
    header.Size = UDim2.new(0, w, 0, headerHeight)
    header.Position = UDim2.new(0, 0, 0, 0)
    header.Parent = frame

    -- Tombol
    local btn = Instance.new("TextButton")
    btn.Text = buttonConfig.text
    btn.BackgroundColor3 = buttonConfig.bgColor
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.Roboto
    btn.TextSize = 14
    btn.Size = UDim2.new(0, w, 0, buttonHeight)
    btn.Position = UDim2.new(0, 0, 0, headerHeight)
    btn.Parent = frame

    btn.MouseButton1Click:Connect(buttonConfig.onClick)

    return gui
end

-- === UI SETUP ===
local FeatureSection = Window:Section({ Title = "Movement", Opened = true })
local MainTab = FeatureSection:Tab({ Title = "Main", Icon = "user" })
local UtilityTab = FeatureSection:Tab({ Title = "Utility", Icon = "wrench" })
local SettingsTab = FeatureSection:Tab({ Title = "Settings", Icon = "settings" })

-- === CORE MOVEMENT ===
MainTab:Section({ Title = "Core Movement" })
MainTab:Input({
    Title = "Speed",
    Value = currentSettings.Speed,
    Callback = function(v)
        currentSettings.Speed = v
        if currentSettings.ApplyMode ~= "" then
            applyToTables(function(obj) obj.Speed = tonumber(v) or 1500 end)
        end
        saveConfig()
    end
})
MainTab:Input({
    Title = "Jump Cap",
    Value = currentSettings.JumpCap,
    Callback = function(v)
        currentSettings.JumpCap = v
        if currentSettings.ApplyMode ~= "" then
            applyToTables(function(obj) obj.JumpCap = tonumber(v) or 1 end)
        end
        saveConfig()
    end
})
MainTab:Input({
    Title = "Strafe Acceleration",
    Value = currentSettings.StrafeAcceleration,
    Callback = function(v)
        currentSettings.StrafeAcceleration = v
        if currentSettings.ApplyMode ~= "" then
            applyToTables(function(obj) obj.AirStrafeAcceleration = tonumber(v) or 187 end)
        end
        saveConfig()
    end
})
MainTab:Dropdown({
    Title = "ApplyMode",
    Values = { "Not Optimized", "Optimized" },
    Callback = function(v)
        currentSettings.ApplyMode = v
        applyStoredSettings()
        saveConfig()
    end
})

-- === BHOP ===
MainTab:Section({ Title = "Bhop" })
MainTab:Toggle({
    Title = "Enable Bhop",
    Value = currentSettings.Bhop == "true",
    Callback = function(v)
        currentSettings.Bhop = tostring(v)
        getgenv().autoJumpEnabled = v
        saveConfig()
    end
})
MainTab:Dropdown({
    Title = "Bhop Mode",
    Values = { "Acceleration", "No Acceleration" },
    Value = currentSettings.BhopMode,
    Callback = function(v)
        currentSettings.BhopMode = v
        getgenv().bhopMode = v
        saveConfig()
    end
})
MainTab:Input({
    Title = "Bhop Accel Value",
    Placeholder = "-0.5",
    Value = currentSettings.BhopAccelValue,
    Callback = function(v)
        if v:sub(1,1) == "-" then
            currentSettings.BhopAccelValue = v
            getgenv().bhopAccelValue = tonumber(v) or -0.5
            saveConfig()
        end
    end
})

-- === AUTO CROUCH ===
MainTab:Section({ Title = "Auto Crouch" })
MainTab:Toggle({
    Title = "Enable Auto Crouch",
    Value = currentSettings.AutoCrouch == "true",
    Callback = function(v)
        currentSettings.AutoCrouch = tostring(v)
        saveConfig()
    end
})
MainTab:Dropdown({
    Title = "Crouch Mode",
    Values = { "Air", "Ground", "Normal" },
    Value = currentSettings.AutoCrouchMode,
    Callback = function(v)
        currentSettings.AutoCrouchMode = v
        saveConfig()
    end
})

-- === BOUNCE ===
MainTab:Section({ Title = "Bounce" })
MainTab:Toggle({
    Title = "Enable Bounce",
    Value = currentSettings.Bounce == "true",
    Callback = function(v)
        currentSettings.Bounce = tostring(v)
        BOUNCE_ENABLED = v
        if v then
            if player.Character then setupBounceOnTouch(player.Character) end
        else
            disableBounce()
        end
        saveConfig()
    end
})
MainTab:Input({
    Title = "Bounce Height",
    Value = currentSettings.BounceHeight,
    Callback = function(v)
        currentSettings.BounceHeight = v
        BOUNCE_HEIGHT = tonumber(v) or 0
        saveConfig()
    end
})
MainTab:Input({
    Title = "Epsilon",
    Value = currentSettings.BounceEpsilon,
    Callback = function(v)
        currentSettings.BounceEpsilon = v
        BOUNCE_EPSILON = tonumber(v) or 0.1
        saveConfig()
    end
})

-- === INFINITY SLIDE ===
MainTab:Section({ Title = "Infinite Slide" })
MainTab:Toggle({
    Title = "Enable Infinite Slide",
    Value = currentSettings.InfinitySlide == "true",
    Callback = function(v)
        currentSettings.InfinitySlide = tostring(v)
        infiniteSlideEnabled = v
        if slideConnection then
            slideConnection:Disconnect()
            slideConnection = nil
        end
        if v then
            updatePlayerModel()
            slideConnection = RunService.Heartbeat:Connect(onHeartbeat)
            player.CharacterAdded:Connect(function()
                task.wait(0.1)
                updatePlayerModel()
            end)
        else
            plrModel = nil
            setSlideFriction(5)
        end
        saveConfig()
    end
})
MainTab:Input({
    Title = "Slide Friction (Negative)",
    Value = currentSettings.SlideFriction,
    Callback = function(v)
        if v:sub(1,1) == "-" then
            currentSettings.SlideFriction = v
            slideFrictionValue = tonumber(v) or -8
            saveConfig()
        end
    end
})

-- === LAG SWITCH ===
MainTab:Section({ Title = "Lag Switch" })
MainTab:Toggle({
    Title = "Enable Lag Switch",
    Value = currentSettings.LagSwitch == "true",
    Callback = function(v)
        currentSettings.LagSwitch = tostring(v)
        getgenv().lagSwitchEnabled = v
        saveConfig()
    end
})
MainTab:Input({
    Title = "Lag Duration (seconds)",
    Value = currentSettings.LagDuration,
    Callback = function(v)
        local num = tonumber(v)
        if num and num > 0 then
            currentSettings.LagDuration = v
            getgenv().lagDuration = num
            saveConfig()
        end
    end
})

-- === FLOATING GUI TOGGLES (di MainTab) ===
MainTab:Section({ Title = "Floating GUI" })

-- Bhop
local BhopGuiToggle = MainTab:Toggle({
    Title = "Show Bhop Button",
    Value = currentSettings.ShowBhopGui == "true",
    Callback = function(v)
        currentSettings.ShowBhopGui = tostring(v)
        if v then
            createFloatingGui("BhopGui", "Bhop", {
                text = getgenv().autoJumpEnabled and "On" or "Off",
                bgColor = getgenv().autoJumpEnabled and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(255, 0, 0),
                onClick = function()
                    getgenv().autoJumpEnabled = not getgenv().autoJumpEnabled
                    currentSettings.Bhop = tostring(getgenv().autoJumpEnabled)
                    local btn = playerGui.BhopGui.Frame:FindFirstChildOfClass("TextButton")
                    if btn then
                        btn.Text = getgenv().autoJumpEnabled and "On" or "Off"
                        btn.BackgroundColor3 = getgenv().autoJumpEnabled and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(255, 0, 0)
                    end
                    saveConfig()
                end
            })
        else
            local gui = playerGui:FindFirstChild("BhopGui")
            if gui then gui:Destroy() end
        end
        saveConfig()
    end
})

-- Auto Crouch
local AutoCrouchGuiToggle = MainTab:Toggle({
    Title = "Show Auto Crouch Button",
    Value = currentSettings.ShowAutoCrouchGui == "true",
    Callback = function(v)
        currentSettings.ShowAutoCrouchGui = tostring(v)
        if v then
            createFloatingGui("AutoCrouchGui", "Auto Crouch", {
                text = currentSettings.AutoCrouch == "true" and "On" or "Off",
                bgColor = currentSettings.AutoCrouch == "true" and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(255, 0, 0),
                onClick = function()
                    currentSettings.AutoCrouch = currentSettings.AutoCrouch == "true" and "false" or "true"
                    local btn = playerGui.AutoCrouchGui.Frame:FindFirstChildOfClass("TextButton")
                    if btn then
                        btn.Text = currentSettings.AutoCrouch == "true" and "On" or "Off"
                        btn.BackgroundColor3 = currentSettings.AutoCrouch == "true" and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(255, 0, 0)
                    end
                    saveConfig()
                end
            })
        else
            local gui = playerGui:FindFirstChild("AutoCrouchGui")
            if gui then gui:Destroy() end
        end
        saveConfig()
    end
})

-- Bounce
local BounceGuiToggle = MainTab:Toggle({
    Title = "Show Bounce Button",
    Value = currentSettings.ShowBounceGui == "true",
    Callback = function(v)
        currentSettings.ShowBounceGui = tostring(v)
        if v then
            createFloatingGui("BounceGui", "Bounce", {
                text = BOUNCE_ENABLED and "On" or "Off",
                bgColor = BOUNCE_ENABLED and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(255, 0, 0),
                onClick = function()
                    BOUNCE_ENABLED = not BOUNCE_ENABLED
                    currentSettings.Bounce = tostring(BOUNCE_ENABLED)
                    if BOUNCE_ENABLED then
                        if player.Character then setupBounceOnTouch(player.Character) end
                    else
                        disableBounce()
                    end
                    local btn = playerGui.BounceGui.Frame:FindFirstChildOfClass("TextButton")
                    if btn then
                        btn.Text = BOUNCE_ENABLED and "On" or "Off"
                        btn.BackgroundColor3 = BOUNCE_ENABLED and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(255, 0, 0)
                    end
                    saveConfig()
                end
            })
        else
            local gui = playerGui:FindFirstChild("BounceGui")
            if gui then gui:Destroy() end
        end
        saveConfig()
    end
})

-- Infinite Slide
local InfinitySlideGuiToggle = MainTab:Toggle({
    Title = "Show Infinite Slide Button",
    Value = currentSettings.ShowInfinitySlideGui == "true",
    Callback = function(v)
        currentSettings.ShowInfinitySlideGui = tostring(v)
        if v then
            createFloatingGui("InfinitySlideGui", "Infinite Slide", {
                text = currentSettings.InfinitySlide == "true" and "On" or "Off",
                bgColor = currentSettings.InfinitySlide == "true" and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(255, 0, 0),
                onClick = function()
                    local newState = currentSettings.InfinitySlide == "true" and "false" or "true"
                    currentSettings.InfinitySlide = newState
                    infiniteSlideEnabled = newState == "true"
                    if infiniteSlideEnabled then
                        updatePlayerModel()
                        slideConnection = RunService.Heartbeat:Connect(onHeartbeat)
                    else
                        plrModel = nil
                        setSlideFriction(5)
                    end
                    local btn = playerGui.InfinitySlideGui.Frame:FindFirstChildOfClass("TextButton")
                    if btn then
                        btn.Text = newState == "true" and "On" or "Off"
                        btn.BackgroundColor3 = newState == "true" and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(255, 0, 0)
                    end
                    saveConfig()
                end
            })
        else
            local gui = playerGui:FindFirstChild("InfinitySlideGui")
            if gui then gui:Destroy() end
        end
        saveConfig()
    end
})

-- Lag Switch
local LagSwitchGuiToggle = MainTab:Toggle({
    Title = "Show Lag Switch Button",
    Value = currentSettings.ShowLagSwitchGui == "true",
    Callback = function(v)
        currentSettings.ShowLagSwitchGui = tostring(v)
        if v then
            createFloatingGui("LagSwitchGui", "Lag Switch", {
                text = "Trigger",
                bgColor = Color3.fromRGB(0, 120, 80),
                onClick = function()
                    task.spawn(function()
                        local start = tick()
                        local duration = getgenv().lagDuration or 0.5
                        while tick() - start < duration do
                            local a = math.random(1e6) * math.random(1e6)
                            a = a / math.random(1e4)
                        end
                    end)
                end
            })
        else
            local gui = playerGui:FindFirstChild("LagSwitchGui")
            if gui then gui:Destroy() end
        end
        saveConfig()
    end
})

-- === UTILITY TAB ===
UtilityTab:Section({ Title = "Performance" })

-- Remove Textures
UtilityTab:Button({
    Title = "Remove Textures",
    Callback = function()
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("BasePart") then
                obj.Material = Enum.Material.SmoothPlastic
                obj.Color = Color3.fromRGB(200, 200, 200)
            end
            if obj:IsA("Decal") or obj:IsA("Texture") then
                obj.Texture = ""
            end
        end
    end
})

-- Low Graphics
UtilityTab:Button({
    Title = "Low Graphics",
    Callback = function()
        -- Matikan efek
        for _, eff in ipairs(Lighting:GetChildren()) do
            if eff:IsA("PostProcessingEffect") or eff:IsA("BloomEffect") or eff:IsA("BlurEffect") then
                eff.Enabled = false
            end
        end
        Lighting.FogEnd = 1e6
        Lighting.GlobalShadows = false
        -- Hapus partikel
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("ParticleEmitter") or obj:IsA("Fire") or obj:IsA("Smoke") then
                obj.Enabled = false
            end
        end
    end
})

-- Clear Invis Walls
UtilityTab:Button({
    Title = "Clear Invis Walls",
    Callback = function()
        local invisParts = workspace:FindFirstChild("Game")?.Map?.InvisParts
        if invisParts then
            for _, part in ipairs(invisParts:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end
    end
})

-- === SETTINGS TAB ===
SettingsTab:Section({ Title = "Floating GUI Size" })
SettingsTab:Input({
    Title = "GUI Width",
    Value = currentSettings.GuiWidth,
    Callback = function(v)
        local num = tonumber(v)
        if num and num > 0 then
            currentSettings.GuiWidth = v
            saveConfig()
            -- Re-apply
            if currentSettings.ShowBhopGui == "true" then BhopGuiToggle:Set(true) end
            if currentSettings.ShowAutoCrouchGui == "true" then AutoCrouchGuiToggle:Set(true) end
            if currentSettings.ShowBounceGui == "true" then BounceGuiToggle:Set(true) end
            if currentSettings.ShowInfinitySlideGui == "true" then InfinitySlideGuiToggle:Set(true) end
            if currentSettings.ShowLagSwitchGui == "true" then LagSwitchGuiToggle:Set(true) end
        end
    end
})
SettingsTab:Input({
    Title = "GUI Height",
    Value = currentSettings.GuiHeight,
    Callback = function(v)
        local num = tonumber(v)
        if num and num >= 50 then
            currentSettings.GuiHeight = v
            saveConfig()
            if currentSettings.ShowBhopGui == "true" then BhopGuiToggle:Set(true) end
            if currentSettings.ShowAutoCrouchGui == "true" then AutoCrouchGuiToggle:Set(true) end
            if currentSettings.ShowBounceGui == "true" then BounceGuiToggle:Set(true) end
            if currentSettings.ShowInfinitySlideGui == "true" then InfinitySlideGuiToggle:Set(true) end
            if currentSettings.ShowLagSwitchGui == "true" then LagSwitchGuiToggle:Set(true) end
        end
    end
})

-- Respawn logic
local gameStatsPath = workspace:FindFirstChild("Game") and workspace.Game:FindFirstChild("Stats")
if gameStatsPath then
    gameStatsPath:GetAttributeChangedSignal("RoundStarted"):Connect(function()
        if gameStatsPath:GetAttribute("RoundStarted") == true then
            applyStoredSettings()
        end
    end)
end

player.CharacterAdded:Connect(function()
    task.wait(0.5)
    applyStoredSettings()
    updatePlayerModel()
end)

loadstring(game:HttpGet("https://raw.githubusercontent.com/Hajipak/Evade/refs/heads/main/Script/More-loadstring.lua"))()

WindUI:Notify({
    Title = "Movement Hub",
    Content = "Loaded successfully!",
    Duration = 3
})
