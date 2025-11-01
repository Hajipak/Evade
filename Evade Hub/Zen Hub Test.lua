if getgenv().MovementHubExecuted then return end
getgenv().MovementHubExecuted = true

-- Load WindUI
local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()
WindUI.TransparencyValue = 0.2
WindUI:SetTheme("Dark")

-- Create main window
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

-- Config file
local configFileName = "evade_movement_config.txt"

-- Default settings
local currentSettings = {
    Speed = "1500",
    JumpCap = "1",
    StrafeAcceleration = "187",
    ApplyMode = "-", -- belum dipilih
    Bhop = false,
    AutoCrouch = false,
    Bounce = false,
    BounceHeight = "0",
    BounceEpsilon = "0.1",
    AutoCrouchMode = "Air",
    BhopMode = "Acceleration",
    BhopAccelValue = "-0.5",
    GuiWidth = "200",
    GuiHeight = "30"
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

-- Required fields for apply
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

-- Apply stored settings
local function applyStoredSettings()
    if currentSettings.ApplyMode == "-" then return end
    applyToTables(function(obj)
        obj.Speed = tonumber(currentSettings.Speed) or 1500
        obj.JumpCap = tonumber(currentSettings.JumpCap) or 1
        obj.AirStrafeAcceleration = tonumber(currentSettings.StrafeAcceleration) or 187
    end)
end

-- Bounce
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

-- Auto Crouch
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

-- Bhop
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

-- Floating GUIs
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

local function createFloatingButton(name, varName, yOffset)
    local guiName = name .. "Gui"
    local gui = playerGui:FindFirstChild(guiName)
    if gui then gui:Destroy() end
    gui = Instance.new("ScreenGui")
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
        elseif varName == "AutoCrouch" then
            -- state already handled in heartbeat
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

createFloatingButton("Bhop", "Bhop", 0)
createFloatingButton("Auto Crouch", "AutoCrouch", 0.07)
createFloatingButton("Bounce", "Bounce", 0.14)

-- Visuals
local originalBrightness = Lighting.Brightness
local originalFogEnd = Lighting.FogEnd
local originalAtmospheres = {}
for _, v in pairs(Lighting:GetDescendants()) do
    if v:IsA("Atmosphere") then table.insert(originalAtmospheres, v) end
end

local function startFullBright()
    Lighting.Brightness = 2
    Lighting.OutdoorAmbient = Color3.fromRGB(255,255,255)
    Lighting.Ambient = Color3.fromRGB(255,255,255)
    Lighting.GlobalShadows = false
end

local function stopFullBright()
    Lighting.Brightness = originalBrightness
    Lighting.OutdoorAmbient = originalOutdoorAmbient
    Lighting.Ambient = originalAmbient
    Lighting.GlobalShadows = originalGlobalShadows
end

local function startNoFog()
    Lighting.FogEnd = 1e6
    for _, v in pairs(Lighting:GetDescendants()) do
        if v:IsA("Atmosphere") then v:Destroy() end
    end
end

local function stopNoFog()
    Lighting.FogEnd = originalFogEnd
    for _, atm in pairs(originalAtmospheres) do
        if not atm.Parent then
            local newAtm = Instance.new("Atmosphere")
            for _, prop in pairs({"Density","Offset","Color","Decay","Glare","Haze"}) do
                if atm[prop] then newAtm[prop] = atm[prop] end
            end
            newAtm.Parent = Lighting
        end
    end
end

-- UI Tabs
local FeatureSection = Window:Section({ Title = "Movement", Opened = true })
local MainTab = FeatureSection:Tab({ Title = "Movement", Icon = "user" })
local VisualTab = FeatureSection:Tab({ Title = "Visuals", Icon = "camera" })
local SettingsTab = FeatureSection:Tab({ Title = "Settings", Icon = "settings" })

-- Movement Tab
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

-- Visuals Tab
VisualTab:Toggle({
    Title = "FullBright",
    Value = false,
    Callback = function(v)
        if v then startFullBright() else stopFullBright() end
    end
})
VisualTab:Toggle({
    Title = "Remove Fog",
    Value = false,
    Callback = function(v)
        if v then startNoFog() else stopNoFog() end
    end
})
VisualTab:Toggle({
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
SettingsTab:Input({
    Title = "GUI Width",
    Value = currentSettings.GuiWidth,
    Callback = function(v)
        local num = tonumber(v)
        if num and num > 0 then
            currentSettings.GuiWidth = v
            saveConfig()
            -- Re-create floating buttons to apply new size
            createFloatingButton("Bhop", "Bhop", 0)
            createFloatingButton("Auto Crouch", "AutoCrouch", 0.07)
            createFloatingButton("Bounce", "Bounce", 0.14)
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
            createFloatingButton("Bhop", "Bhop", 0)
            createFloatingButton("Auto Crouch", "AutoCrouch", 0.07)
            createFloatingButton("Bounce", "Bounce", 0.14)
        end
    end
})
SettingsTab:Button({
    Title = "Reset GUI Size",
    Callback = function()
        currentSettings.GuiWidth = "200"
        currentSettings.GuiHeight = "30"
        saveConfig()
        createFloatingButton("Bhop", "Bhop", 0)
        createFloatingButton("Auto Crouch", "AutoCrouch", 0.07)
        createFloatingButton("Bounce", "Bounce", 0.14)
    end
})

-- Respawn / Round logic
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

-- External loadstring (Evade Test)
loadstring(game:HttpGet("https://raw.githubusercontent.com/Hajipak/Evade/refs/heads/main/Script/More-loadstring.lua"))()

-- Notify
WindUI:Notify({
    Title = "Movement Hub",
    Content = "Loaded successfully!",
    Duration = 3
})
