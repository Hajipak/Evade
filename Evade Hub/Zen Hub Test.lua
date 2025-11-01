if getgenv().EvadeHubEvadeExecuted then
    return
end
getgenv().EvadeHubEvadeExecuted = true
-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer

-- Load WindUI safely
local ok, WindUI = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()
end)
if not ok or not WindUI then
    warn("WindUI not found. UI creation will fail.")
end

-- =============== Settings & Variables ===============
local currentSettings = {
    Speed = "1500",                -- default as string (WindUI Input compatibility)
    JumpCap = "1",
    AirStrafeAcceleration = "187",
    BhopEnabled = false,
    BhopMode = "Acceleration",     -- "Acceleration" or "No Acceleration"
    BhopAccelValue = -0.5,
    AutoCrouch = false,
    AutoCrouchMode = "Air",        -- "Air", "Normal", "Ground"
    BounceEnabled = false,
    BounceHeight = 0,
    BounceEpsilon = 0.1,
    ApplyMode = "Not Optimized",   -- "Not Optimized" or "Optimized"
    FullBright = false,
    NoFog = false,
    TimerDisplay = false
}

-- Save originals for visuals
local originalLighting = {
    Brightness = Lighting and Lighting.Brightness or nil,
    FogEnd = Lighting and Lighting.FogEnd or nil,
    GlobalShadows = Lighting and Lighting.GlobalShadows or nil,
    Atmospheres = {}
}
for _, v in ipairs(Lighting:GetDescendants()) do
    if v:IsA("Atmosphere") then
        table.insert(originalLighting.Atmospheres, v:Clone())
    end
end

-- Cached config tables (the game internal tables that contain movement values)
local function hasMovementFields(tbl)
    if type(tbl) ~= "table" then return false end
    local keys = {
        "Friction", "AirStrafeAcceleration", "JumpHeight", "RunDeaccel",
        "JumpSpeedMultiplier", "JumpCap", "SprintCap", "WalkSpeedMultiplier",
        "BhopEnabled", "Speed", "AirAcceleration", "RunAccel", "SprintAcceleration"
    }
    for _, k in ipairs(keys) do
        if rawget(tbl, k) == nil then return false end
    end
    return true
end

local function getConfigTables()
    local out = {}
    for _, obj in pairs(getgc(true) or {}) do
        local ok2, res = pcall(function()
            if hasMovementFields(obj) then return obj end
        end)
        if ok2 and res then table.insert(out, res) end
    end
    return out
end

local function applyToTables(callback)
    local targets = getConfigTables()
    if #targets == 0 then return end
    if currentSettings.ApplyMode == "Optimized" then
        task.spawn(function()
            for i, t in ipairs(targets) do
                pcall(callback, t)
                if i % 3 == 0 then task.wait() end
            end
        end)
    else
        for _, t in ipairs(targets) do
            pcall(callback, t)
        end
    end
end

local function applyStoredSettings()
    applyToTables(function(obj)
        pcall(function()
            obj.Speed = tonumber(currentSettings.Speed) or obj.Speed
            obj.JumpCap = tonumber(currentSettings.JumpCap) or obj.JumpCap
            obj.AirStrafeAcceleration = tonumber(currentSettings.AirStrafeAcceleration) or obj.AirStrafeAcceleration
            obj.BhopEnabled = currentSettings.BhopEnabled and true or false
        end)
    end)
end

-- Apply on spawn or when requested
task.spawn(function()
    while true do
        applyStoredSettings()
        task.wait(2)
    end
end)

-- =============== Bhop Logic ===============
getgenv().autoJumpEnabled = false
getgenv().bhopMode = currentSettings.BhopMode
getgenv().bhopAccelValue = currentSettings.BhopAccelValue

-- bhop friction adjuster loop
task.spawn(function()
    while true do
        local friction = 5
        local isActive = getgenv().autoJumpEnabled
        if isActive and getgenv().bhopMode == "Acceleration" then
            friction = getgenv().bhopAccelValue or -0.5
        end
        for _, t in pairs(getgc(true)) do
            if type(t) == "table" and rawget(t, "Friction") then
                if getgenv().bhopMode ~= "No Acceleration" then
                    pcall(function() t.Friction = friction end)
                end
            end
        end
        task.wait(0.15)
    end
end)

-- automatic jump enabler
task.spawn(function()
    while true do
        if getgenv().autoJumpEnabled then
            local char = player.Character
            if char and char:FindFirstChild("Humanoid") then
                local hum = char.Humanoid
                if hum:GetState() ~= Enum.HumanoidStateType.Jumping and hum:GetState() ~= Enum.HumanoidStateType.Freefall then
                    pcall(function() hum:ChangeState(Enum.HumanoidStateType.Jumping) end)
                end
            end
            if getgenv().bhopMode == "No Acceleration" then
                task.wait(0.05)
            else
                task.wait()
            end
        else
            task.wait(0.1)
        end
    end
end)

-- =============== Auto Crouch Logic ===============
local previousCrouchState = false
local spamDown = true

local function fireKeybind(down, key)
    local ok, ev = pcall(function()
        return player:WaitForChild("PlayerScripts"):WaitForChild("Events"):WaitForChild("temporary_events"):WaitForChild("UseKeybind")
    end)
    if ok and ev then
        pcall(function() ev:Fire({Down = down, Key = key}) end)
    end
end

RunService.Heartbeat:Connect(function()
    if not currentSettings.AutoCrouch then
        if previousCrouchState then
            fireKeybind(false, "Crouch")
            previousCrouchState = false
        end
        return
    end
    local char = player.Character
    if not char or not char:FindFirstChild("Humanoid") then return end
    local hum = char.Humanoid
    local mode = currentSettings.AutoCrouchMode
    if mode == "Normal" then
        fireKeybind(spamDown, "Crouch")
        spamDown = not spamDown
    else
        local isAir = (hum.FloorMaterial == Enum.Material.Air) and (hum:GetState() ~= Enum.HumanoidStateType.Seated)
        local shouldCrouch = (mode == "Air" and isAir) or (mode == "Ground" and not isAir)
        if shouldCrouch ~= previousCrouchState then
            fireKeybind(shouldCrouch, "Crouch")
            previousCrouchState = shouldCrouch
        end
    end
end)

-- =============== Bounce Logic ===============
local BOUNCE_ENABLED = false
local BOUNCE_HEIGHT = 0
local BOUNCE_EPSILON = 0.1
local Debris = game:GetService("Debris")
local touchConnections = {}

local function setupBounceForCharacter(char)
    if not BOUNCE_ENABLED then return end
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    if touchConnections[char] then
        touchConnections[char]:Disconnect()
        touchConnections[char] = nil
    end
    local conn
    conn = hrp.Touched:Connect(function(hit)
        if not hit or not hit.Size then return end
        local playerBottom = hrp.Position.Y - hrp.Size.Y / 2
        local playerTop = hrp.Position.Y + hrp.Size.Y / 2
        local hitBottom = hit.Position.Y - hit.Size.Y / 2
        local hitTop = hit.Position.Y + hit.Size.Y / 2
        if hitTop <= playerBottom + BOUNCE_EPSILON then return end
        if hitBottom >= playerTop - BOUNCE_EPSILON then return end
        -- Fire remote (if exists) to simulate bounce event
        pcall(function()
            local re = ReplicatedStorage:FindFirstChild("Events") and ReplicatedStorage.Events:FindFirstChild("Character") and ReplicatedStorage.Events.Character:FindFirstChild("PassCharacterInfo")
            if re and re:IsA("RemoteEvent") then
                re:FireServer({}, {2})
            end
        end)
        if BOUNCE_HEIGHT > 0 then
            local bodyVel = Instance.new("BodyVelocity")
            bodyVel.MaxForce = Vector3.new(0, math.huge, 0)
            bodyVel.Velocity = Vector3.new(0, BOUNCE_HEIGHT, 0)
            bodyVel.Parent = hrp
            Debris:AddItem(bodyVel, 0.2)
        end
    end)
    touchConnections[char] = conn
    char.AncestryChanged:Connect(function()
        if not char.Parent then
            if touchConnections[char] then
                touchConnections[char]:Disconnect()
                touchConnections[char] = nil
            end
        end
    end)
end

if player.Character then setupBounceForCharacter(player.Character) end
player.CharacterAdded:Connect(function(char) setupBounceForCharacter(char) end)

-- =============== Visuals: FullBright & NoFog & Timer Display ===============
local function startFullBright()
    pcall(function()
        Lighting.Brightness = 2
        Lighting.GlobalShadows = false
    end)
end
local function stopFullBright()
    pcall(function()
        if originalLighting.Brightness then Lighting.Brightness = originalLighting.Brightness end
        if originalLighting.GlobalShadows ~= nil then Lighting.GlobalShadows = originalLighting.GlobalShadows end
    end)
end

local function startNoFog()
    pcall(function()
        originalLighting.FogEnd = originalLighting.FogEnd or Lighting.FogEnd
        Lighting.FogEnd = 1000000
        for _, v in pairs(Lighting:GetDescendants()) do
            if v:IsA("Atmosphere") then v:Destroy() end
        end
    end)
end
local function stopNoFog()
    pcall(function()
        if originalLighting.FogEnd then Lighting.FogEnd = originalLighting.FogEnd end
        -- restore atmospheres
        for _, atm in ipairs(originalLighting.Atmospheres) do
            if atm and atm.Parent == nil then
                atm.Parent = Lighting
            end
        end
    end)
end

-- =============== UI (WindUI) Creation ===============
if WindUI then
    WindUI.TransparencyValue = 0.2
    WindUI:SetTheme("Dark")
    local Window = WindUI:CreateWindow({
        Title = "Evade Lite",
        Icon = "rocket",
        Author = "Lite",
        Folder = "EvadeLite",
        Size = UDim2.fromOffset(520, 420),
        Theme = "Dark",
        HidePanelBackground = false,
        Acrylic = false,
        HideSearchBar = false,
        SideBarWidth = 180
    })

    local FeatureSection = Window:Section({ Title = "Features", Opened = true })
    local Tabs = {
        Player = FeatureSection:Tab({ Title = "Movement", Icon = "user" }),
        Visuals = FeatureSection:Tab({ Title = "Visuals", Icon = "camera" })
    }

    Tabs.Player:Section({ Title = "Movement", TextSize = 18 })
    Tabs.Player:Divider()

    -- Bhop
local Tabs.Player:Toggle({
        Title = "Bhop",
        Value = false,
        Callback = function(state)
            getgenv().autoJumpEnabled = state
            currentSettings.BhopEnabled = state
        end
    })

local Tabs.Player:Dropdown({
        Title = "Bhop Mode",
        Values = {"Acceleration","No Acceleration"},
        Value = getgenv().bhopMode,
        Callback = function(val)
            getgenv().bhopMode = val
            currentSettings.BhopMode = val
        end
    })

local Tabs.Player:Input({
        Title = "Bhop Acceleration (Negative Only)",
        Placeholder = "-0.5",
        Numeric = true,
        Value = tostring(getgenv().bhopAccelValue),
        Callback = function(v)
            if tostring(v):sub(1,1) == "-" then
                getgenv().bhopAccelValue = tonumber(v)
                currentSettings.BhopAccelValue = tonumber(v)
            end
        end
    })

    -- Auto Crouch
local Tabs.Player:Toggle({
        Title = "Auto Crouch",
        Value = currentSettings.AutoCrouch,
        Callback = function(state)
            currentSettings.AutoCrouch = state
        end
    })
local Tabs.Player:Dropdown({
        Title = "Auto Crouch Mode",
        Values = {"Air","Normal","Ground"},
        Value = currentSettings.AutoCrouchMode,
        Callback = function(val)
            currentSettings.AutoCrouchMode = val
        end
    })

    -- Bounce
local Tabs.Player:Toggle({
        Title = "Enable Bounce",
        Value = false,
        Callback = function(state)
            BOUNCE_ENABLED = state
            currentSettings.BounceEnabled = state
            if state and player.Character then setupBounceForCharacter(player.Character) end
        end
    })
local Tabs.Player:Input({
        Title = "Bounce Height",
        Numeric = true,
        Value = tostring(BOUNCE_HEIGHT),
        Callback = function(v)
            local n = tonumber(v)
            if n then BOUNCE_HEIGHT = math.max(0, n); currentSettings.BounceHeight = n end
        end
    })
local Tabs.Player:Input({
        Title = "Touch Epsilon",
        Numeric = true,
        Value = tostring(BOUNCE_EPSILON),
        Callback = function(v)
            local n = tonumber(v)
            if n then BOUNCE_EPSILON = math.max(0, n); currentSettings.BounceEpsilon = n end
        end
    })

    -- Strafe, Speed, JumpCap
local Tabs.Player:Input({
        Title = "Strafe Acceleration",
        Placeholder = "Default 187",
        Numeric = true,
        Value = currentSettings.AirStrafeAcceleration,
        Callback = function(v)
            local n = tonumber(v)
            if n then currentSettings.AirStrafeAcceleration = tostring(n); applyToTables(function(obj) obj.AirStrafeAcceleration = n end) end
        end
    })

local Tabs.Player:Input({
        Title = "Set Speed",
        Placeholder = "Default 1500",
        Numeric = true,
        Value = currentSettings.Speed,
        Callback = function(v)
            local n = tonumber(v)
            if n then currentSettings.Speed = tostring(n); applyToTables(function(obj) obj.Speed = n end) end
        end
    })

local Tabs.Player:Input({
        Title = "Set Jump Cap",
        Placeholder = "Default 1",
        Numeric = true,
        Value = currentSettings.JumpCap,
        Callback = function(v)
            local n = tonumber(v)
            if n then currentSettings.JumpCap = tostring(n); applyToTables(function(obj) obj.JumpCap = n end) end
        end
    })

local Tabs.Player:Dropdown({
        Title = "Apply Mode",
        Values = {"Not Optimized","Optimized"},
        Value = currentSettings.ApplyMode,
        Callback = function(val)
            currentSettings.ApplyMode = val
        end
    })

    -- Visuals tab
Tabs.Visuals:Section({ Title = "Visual", TextSize = 18 })
Tabs.Visuals:Divider()
local Tabs.Visuals:Toggle({
        Title = "FullBright",
        Value = currentSettings.FullBright,
        Callback = function(state)
            currentSettings.FullBright = state
            if state then startFullBright() else stopFullBright() end
        end
    })
local Tabs.Visuals:Toggle({
        Title = "Remove Fog",
        Value = currentSettings.NoFog,
        Callback = function(state)
            currentSettings.NoFog = state
            if state then startNoFog() else stopNoFog() end
        end
    })
    
local TimerDisplayToggle = Tabs.Visuals:Toggle({
    Title = "Timer Display",
    Value = false,
    Callback = function(state)
        featureStates.TimerDisplay = state
        if state then
            pcall(function()
                local Players = game:GetService("Players")
                local LocalPlayer = Players.LocalPlayer
                local PlayerGui = LocalPlayer.PlayerGui
                local MainInterface = PlayerGui:WaitForChild("MainInterface")
                local TimerContainer = MainInterface:WaitForChild("TimerContainer")
                TimerContainer.Visible = true
            end)
            
            task.spawn(function()
                while featureStates.TimerDisplay do
                    local success, result = pcall(function()
                        local Players = game:GetService("Players")
                        local player = Players.LocalPlayer
                        
                        if not player then
                            return false
                        end
                        
                        local playerGui = player:FindFirstChild("PlayerGui")
                        if not playerGui then
                            return false
                        end
                        
                        local shared = playerGui:WaitForChild("Shared", 1)
                        if not shared then
                            return false
                        end
                        
                        local hud = shared:WaitForChild("HUD", 1)
                        if not hud then
                            return false
                        end
                        
                        local overlay = hud:WaitForChild("Overlay", 1)
                        if not overlay then
                            return false
                        end
                        
                        local default = overlay:WaitForChild("Default", 1)
                        if not default then
                            return false
                        end
                        
                        local roundOverlay = default:WaitForChild("RoundOverlay", 1)
                        if not roundOverlay then
                            return false
                        end
                        
                        local round = roundOverlay:WaitForChild("Round", 1)
                        if not round then
                            return false
                        end
                        
                        local roundTimer = round:WaitForChild("RoundTimer", 1)
                        if not roundTimer then
                            return false
                        end
                        
                        roundTimer.Visible = false
                        return true
                    end)
                    
                    if not success or not result then
                        task.wait(0)
                    else
                        task.wait(0)
                    end
                end
            end)
        else
            pcall(function()
                local Players = game:GetService("Players")
                local LocalPlayer = Players.LocalPlayer
                local PlayerGui = LocalPlayer.PlayerGui
                local MainInterface = PlayerGui:WaitForChild("MainInterface")
                local TimerContainer = MainInterface:WaitForChild("TimerContainer")
                TimerContainer.Visible = false
            end)
        end
    end
})
