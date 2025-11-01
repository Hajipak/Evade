if getgenv().MovementHubExecuted then return end
getgenv().MovementHubExecuted = true

-- Load WindUI
local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()
WindUI.TransparencyValue = 0.2
WindUI:SetTheme("Dark")

local Window = WindUI:CreateWindow({
    Title = "Movement Hub",
    Icon = "rocket",
    Author = "Made by Pnsdg & Yomka",
    Folder = "GameHackUI",
    Size = UDim2.fromOffset(580, 400),
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
local configFileName = "movement_hub_config.txt"

-- Default settings
local currentSettings = {
    Speed = "1500",
    JumpCap = "1",
    StrafeAcceleration = "187",
    ApplyMode = "-",
    Bhop = "false",
    AutoCrouch = "false",
    Bounce = "false",
    BounceHeight = "0",
    BounceEpsilon = "0.1",
    AutoCrouchMode = "Air",
    BhopMode = "Acceleration",
    BhopAccelValue = "-0.5",
    GuiWidth = "200",
    GuiHeight = "30",
    ShowBhopGui = "false",
    ShowAutoCrouchGui = "false",
    ShowBounceGui = "false",
    LagSwitch = "false",
    LagDuration = "0.5"
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
    local data = {}
    for k, v in pairs(currentSettings) do
        local num = tonumber(v)
        data[k] = num and num or v
    end
    writefile(configFileName, HttpService:JSONEncode(data))
end

-- Required fields checker
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
    if currentSettings.ApplyMode == "-" then return end
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

if player.Character then
    setupBounceOnTouch(player.Character)
end
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

-- === DRAGGABLE FUNCTION ===
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
local function createFloatingGui(name, varName, yOffset)
    local guiName = name:gsub(" ", "") .. "Gui"
    local existing = playerGui:FindFirstChild(guiName)
    if existing then existing:Destroy() end

    local gui = Instance.new("ScreenGui")
    gui.Name = guiName
    gui.ResetOnSpawn = false
    gui.Parent = playerGui

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, tonumber(currentSettings.GuiWidth) or 200, 0, tonumber(currentSettings.GuiHeight) or 30)
    frame.Position = UDim2.new(0.5, -frame.Size.X.Offset/2, 0.1 + yOffset, 0)
    frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    frame.BackgroundTransparency = 0.3
    frame.BorderSizePixel = 0
    frame.Parent = gui

    makeDraggable(frame)

    local label = Instance.new("TextLabel")
    label.Text = name
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.Font = Enum.Font.Roboto
    label.TextSize = 14
    label.Size = UDim2.new(0.6, 0, 1, 0)
    label.Position = UDim2.new(0, 0, 0, 0)
    label.Parent = frame

    local btn = Instance.new("TextButton")
    btn.Text = currentSettings[varName] == "true" and "On" or "Off"
    btn.BackgroundColor3 = currentSettings[varName] == "true" and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(200, 0, 0)
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.Roboto
    btn.TextSize = 14
    btn.Size = UDim2.new(0.4, 0, 1, 0)
    btn.Position = UDim2.new(0.6, 0, 0, 0)
    btn.Parent = frame

    btn.MouseButton1Click:Connect(function()
        currentSettings[varName] = tostring(currentSettings[varName] ~= "true")
        btn.Text = currentSettings[varName] == "true" and "On" or "Off"
        btn.BackgroundColor3 = currentSettings[varName] == "true" and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(200, 0, 0)
        if varName == "Bhop" then
            getgenv().autoJumpEnabled = currentSettings[varName] == "true"
        elseif varName == "Bounce" then
            BOUNCE_ENABLED = currentSettings[varName] == "true"
            if BOUNCE_ENABLED then
                if player.Character then setupBounceOnTouch(player.Character) end
            else
                disableBounce()
            end
        end
        saveConfig()
    end)

    return gui
end

-- === LAG SWITCH ===
getgenv().lagSwitchEnabled = currentSettings.LagSwitch == "true"
getgenv().lagDuration = tonumber(currentSettings.LagDuration) or 0.5

local function createLagSwitchGui()
    local lagGui = playerGui:FindFirstChild("LagSwitchGui")
    if lagGui then lagGui:Destroy() end

    lagGui = Instance.new("ScreenGui")
    lagGui.Name = "LagSwitchGui"
    lagGui.ResetOnSpawn = false
    lagGui.Parent = playerGui

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 180, 0, 60)
    frame.Position = UDim2.new(0.5, -90, 0.15, 0)
    frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    frame.BackgroundTransparency = 0.3
    frame.BorderSizePixel = 0
    frame.Parent = lagGui

    makeDraggable(frame)

    local label = Instance.new("TextLabel")
    label.Text = "Lag Switch"
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.Font = Enum.Font.Roboto
    label.TextSize = 14
    label.Size = UDim2.new(0.6, 0, 0.5, 0)
    label.Position = UDim2.new(0, 0, 0, 0)
    label.Parent = frame

    local btn = Instance.new("TextButton")
    btn.Text = "Trigger"
    btn.BackgroundColor3 = Color3.fromRGB(0, 120, 80)
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.Roboto
    btn.TextSize = 14
    btn.Size = UDim2.new(0.4, 0, 0.5, 0)
    btn.Position = UDim2.new(0.6, 0, 0, 0)
    btn.Parent = frame

    btn.MouseButton1Click:Connect(function()
        task.spawn(function()
            local start = tick()
            local duration = getgenv().lagDuration
            while tick() - start < duration do
                local a = math.random(1e6) * math.random(1e6)
                a = a / math.random(1e4)
            end
        end)
    end)

    return lagGui
end

-- === UI SETUP ===
local FeatureSection = Window:Section({ Title = "Movement", Opened = true })
local MainTab = FeatureSection:Tab({ Title = "Main", Icon = "user" })
local VisualsTab = FeatureSection:Tab({ Title = "Visuals", Icon = "camera" })
local SettingsTab = FeatureSection:Tab({ Title = "Settings", Icon = "settings" })

-- Main Tab
MainTab:Section({ Title = "Core Movement" })
MainTab:Input({
    Title = "Speed",
    Value = currentSettings.Speed,
    Callback = function(v)
        currentSettings.Speed = v
        if currentSettings.ApplyMode ~= "-" then
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
        if currentSettings.ApplyMode ~= "-" then
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
        if currentSettings.ApplyMode ~= "-" then
            applyToTables(function(obj) obj.AirStrafeAcceleration = tonumber(v) or 187 end)
        end
        saveConfig()
    end
})
MainTab:Dropdown({
    Title = "ApplyMode",
    Values = { "-", "Not Optimized", "Optimized" },
    Value = currentSettings.ApplyMode,
    Callback = function(v)
        currentSettings.ApplyMode = v
        if v ~= "-" then applyStoredSettings() end
        saveConfig()
    end
})

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

MainTab:Section({ Title = "Lag Switch" })
MainTab:Toggle({
    Title = "Enable Lag Switch",
    Value = currentSettings.LagSwitch == "true",
    Callback = function(v)
        currentSettings.LagSwitch = tostring(v)
        getgenv().lagSwitchEnabled = v
        if v then
            createLagSwitchGui()
        else
            local gui = playerGui:FindFirstChild("LagSwitchGui")
            if gui then gui:Destroy() end
        end
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

-- Visuals Tab
VisualsTab:Toggle({
    Title = "FullBright",
    Value = false,
    Callback = function(v)
        if v then
            Lighting.Brightness = 2
            Lighting.OutdoorAmbient = Color3.fromRGB(255,255,255)
            Lighting.Ambient = Color3.fromRGB(255,255,255)
            Lighting.GlobalShadows = false
        else
            Lighting.Brightness = 1
            Lighting.OutdoorAmbient = Color3.fromRGB(0,0,0)
            Lighting.Ambient = Color3.fromRGB(0,0,0)
            Lighting.GlobalShadows = true
        end
    end
})
VisualsTab:Toggle({
    Title = "Remove Fog",
    Value = false,
    Callback = function(v)
        if v then
            Lighting.FogEnd = 1e6
            for _, atm in pairs(Lighting:GetDescendants()) do
                if atm:IsA("Atmosphere") then atm:Destroy() end
            end
        else
            Lighting.FogEnd = 100000
        end
    end
})
VisualsTab:Toggle({
    Title = "Timer Display",
    Value = false,
    Callback = function(v)
        pcall(function()
            local timer = playerGui:WaitForChild("MainInterface"):WaitForChild("TimerContainer")
            timer.Visible = v
        end)
    end
})

-- Settings Tab
SettingsTab:Section({ Title = "Floating GUI Controls" })
SettingsTab:Toggle({
    Title = "Show Bhop Button",
    Value = currentSettings.ShowBhopGui == "true",
    Callback = function(v)
        currentSettings.ShowBhopGui = tostring(v)
        if v then
            createFloatingGui("Bhop", "Bhop", 0)
        else
            local gui = playerGui:FindFirstChild("BhopGui")
            if gui then gui:Destroy() end
        end
        saveConfig()
    end
})
SettingsTab:Toggle({
    Title = "Show Auto Crouch Button",
    Value = currentSettings.ShowAutoCrouchGui == "true",
    Callback = function(v)
        currentSettings.ShowAutoCrouchGui = tostring(v)
        if v then
            createFloatingGui("Auto Crouch", "AutoCrouch", 0.07)
        else
            local gui = playerGui:FindFirstChild("AutoCrouchGui")
            if gui then gui:Destroy() end
        end
        saveConfig()
    end
})
SettingsTab:Toggle({
    Title = "Show Bounce Button",
    Value = currentSettings.ShowBounceGui == "true",
    Callback = function(v)
        currentSettings.ShowBounceGui = tostring(v)
        if v then
            createFloatingGui("Bounce", "Bounce", 0.14)
        else
            local gui = playerGui:FindFirstChild("BounceGui")
            if gui then gui:Destroy() end
        end
        saveConfig()
    end
})
SettingsTab:Toggle({
    Title = "Show Lag Switch Button",
    Value = currentSettings.ShowLagSwitchGui == "true",
    Callback = function(v)
        currentSettings.ShowLagSwitchGui = tostring(v)
        if v then
            createLagSwitchGui()
        else
            local gui = playerGui:FindFirstChild("LagSwitchGui")
            if gui then gui:Destroy() end
        end
        saveConfig()
    end
})

SettingsTab:Section({ Title = "GUI Size" })
SettingsTab:Input({
    Title = "GUI Width",
    Value = currentSettings.GuiWidth,
    Callback = function(v)
        local num = tonumber(v)
        if num and num > 0 then
            currentSettings.GuiWidth = v
            saveConfig()
        end
    end
})
SettingsTab:Input({
    Title = "GUI Height",
    Value = currentSettings.GuiHeight,
    Callback = function(v)
        local num = tonumber(v)
        if num and num > 0 then
            currentSettings.GuiHeight = v
            saveConfig()
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
end)

loadstring(game:HttpGet("https://raw.githubusercontent.com/Hajipak/Evade/refs/heads/main/Script/More-loadstring.lua"))()

-- Final notify
WindUI:Notify({
    Title = "Movement Hub",
    Content = "Loaded successfully!",
    Duration = 3
})
