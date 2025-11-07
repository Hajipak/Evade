if getgenv().ZenHubEvadeExecuted then
    return
end
getgenv().ZenHubEvadeExecuted = true

-- Load WindUI
local WindUI
do
    local ok, result = pcall(function()
        return require("./src/Init")
    end)
    
    if ok then
        WindUI = result
    else 
        WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
    end
end

-- Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Feature States
local featureStates = {
    Speed = 1500,
    JumpCap = 1,
    StrafeAccel = 187,
    Bhop = false,
    BhopMode = "Acceleration",
    BhopAccel = -0.5,
    AutoCrouch = false,
    AutoCrouchMode = "Air",
    Bounce = false,
    BounceHeight = 0,
    SpeedPadBoost = false,
    SpeedPadValue = 1.3,
    SpeedPadDuration = 2,
    JumpPadBoost = false,
    JumpPadValue = 0,
    UnlimitedCola = false,
    ColaSpeedBoost = false,
    ColaSpeedValue = 1.4,
    ColaDuration = 3.5,
    LagSwitch = false,
    LagDuration = 0.5,
    LowGraphics = false,
    RemoveTexture = false,
    TimerDisplay = false,
    FullBright = false,
    
    -- UI Settings
    FloatingButtonScale = 1.0,
    FloatingButtonNameWidth = 80,
    FloatingButtonNameHeight = 20,
    FloatingButtonToggleWidth = 80,
    FloatingButtonToggleHeight = 30,
}

-- Localization
local Localization = WindUI:Localization({
    Enabled = true,
    Prefix = "loc:",
    DefaultLanguage = "en",
    Translations = {
        ["en"] = {
            ["SCRIPT_TITLE"] = "Evade Hub Simplified",
            ["WELCOME"] = "Simplified Version",
        }
    }
})

-- Set WindUI properties
WindUI.TransparencyValue = 0.2
WindUI:SetTheme("Dark")

-- Create WindUI window
local Window = WindUI:CreateWindow({
    Title = "loc:SCRIPT_TITLE",
    Icon = "rbxassetid://137330250139083",
    Author = "loc:WELCOME",
    Folder = "EvadeHubSimplified",
    Size = UDim2.fromOffset(580, 490),
    Theme = "Dark",
    HidePanelBackground = false,
    Acrylic = false,
    HideSearchBar = false,
    SideBarWidth = 200
})

-- Helper Functions
local function makeDraggable(frame)
    frame.Active = true
    frame.Draggable = true
    
    local dragDetector = Instance.new("UIDragDetector")
    dragDetector.Parent = frame
    
    local originalTransparency = frame.BackgroundTransparency
    
    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            frame.BackgroundTransparency = originalTransparency - 0.1
        end
    end)
    
    frame.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            frame.BackgroundTransparency = originalTransparency
        end
    end)
end

local function createFloatingButton(name, variableName, yOffset)
    local gui = playerGui:FindFirstChild(name .. "FloatingGui")
    if gui then gui:Destroy() end
    
    gui = Instance.new("ScreenGui")
    gui.Name = name .. "FloatingGui"
    gui.IgnoreGuiInset = true
    gui.ResetOnSpawn = false
    gui.Enabled = false
    gui.Parent = playerGui

    local nameWidth = featureStates.FloatingButtonNameWidth * featureStates.FloatingButtonScale
    local nameHeight = featureStates.FloatingButtonNameHeight * featureStates.FloatingButtonScale
    local toggleWidth = featureStates.FloatingButtonToggleWidth * featureStates.FloatingButtonScale
    local toggleHeight = featureStates.FloatingButtonToggleHeight * featureStates.FloatingButtonScale
    
    local totalWidth = math.max(nameWidth, toggleWidth)
    local totalHeight = nameHeight + toggleHeight

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, totalWidth, 0, totalHeight)
    frame.Position = UDim2.new(0.5, -totalWidth/2, 0.12 + yOffset, 0)
    frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    frame.BackgroundTransparency = 0.35
    frame.BorderSizePixel = 0
    frame.Parent = gui
    makeDraggable(frame)

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = frame

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(150, 150, 150)
    stroke.Thickness = 2
    stroke.Parent = frame

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "NameLabel"
    nameLabel.Text = name
    nameLabel.Size = UDim2.new(0, nameWidth, 0, nameHeight)
    nameLabel.Position = UDim2.new(0.5, -nameWidth/2, 0, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.Font = Enum.Font.Roboto
    nameLabel.TextSize = 14 * featureStates.FloatingButtonScale
    nameLabel.TextXAlignment = Enum.TextXAlignment.Center
    nameLabel.TextYAlignment = Enum.TextYAlignment.Center
    nameLabel.TextScaled = false
    nameLabel.Parent = frame

    local toggleButton = Instance.new("TextButton")
    toggleButton.Name = "ToggleButton"
    toggleButton.Text = featureStates[variableName] and "On" or "Off"
    toggleButton.Size = UDim2.new(0, toggleWidth, 0, toggleHeight)
    toggleButton.Position = UDim2.new(0.5, -toggleWidth/2, 0, nameHeight)
    toggleButton.BackgroundColor3 = featureStates[variableName] and Color3.fromRGB(0, 120, 80) or Color3.fromRGB(120, 0, 0)
    toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggleButton.Font = Enum.Font.Roboto
    toggleButton.TextSize = 14 * featureStates.FloatingButtonScale
    toggleButton.TextXAlignment = Enum.TextXAlignment.Center
    toggleButton.TextYAlignment = Enum.TextYAlignment.Center
    toggleButton.TextScaled = false
    toggleButton.Parent = frame

    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 4)
    buttonCorner.Parent = toggleButton

    toggleButton.MouseButton1Click:Connect(function()
        featureStates[variableName] = not featureStates[variableName]
        toggleButton.Text = featureStates[variableName] and "On" or "Off"
        toggleButton.BackgroundColor3 = featureStates[variableName] and Color3.fromRGB(0, 120, 80) or Color3.fromRGB(120, 0, 0)
    end)

    return gui, toggleButton, nameLabel
end

-- Config Tables Management
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

local function applyToTables(callback)
    local targets = getConfigTables()
    if #targets == 0 then return end
    
    for i, tableObj in ipairs(targets) do
        if tableObj and typeof(tableObj) == "table" then
            pcall(callback, tableObj)
        end
    end
end

-- Apply Settings Functions
local function applySpeed()
    applyToTables(function(obj)
        obj.Speed = featureStates.Speed
    end)
end

local function applyJumpCap()
    applyToTables(function(obj)
        obj.JumpCap = featureStates.JumpCap
    end)
end

local function applyStrafeAccel()
    applyToTables(function(obj)
        obj.AirStrafeAcceleration = featureStates.StrafeAccel
    end)
end

-- Bhop System
local bhopConnection = nil
local bhopSystemLoaded = false
local Character = nil
local Humanoid = nil
local HumanoidRootPart = nil
local LastJump = 0

local GROUND_CHECK_DISTANCE = 3.5
local MAX_SLOPE_ANGLE = 45

local function IsOnGround()
    if not Character or not HumanoidRootPart or not Humanoid then return false end

    local state = Humanoid:GetState()
    if state == Enum.HumanoidStateType.Jumping or 
       state == Enum.HumanoidStateType.Freefall or
       state == Enum.HumanoidStateType.Swimming then
        return false
    end

    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.FilterDescendantsInstances = {Character}
    raycastParams.IgnoreWater = true

    local rayOrigin = HumanoidRootPart.Position
    local rayDirection = Vector3.new(0, -GROUND_CHECK_DISTANCE, 0)
    local raycastResult = workspace:Raycast(rayOrigin, rayDirection, raycastParams)

    if not raycastResult then return false end

    local surfaceNormal = raycastResult.Normal
    local angle = math.deg(math.acos(surfaceNormal:Dot(Vector3.new(0, 1, 0))))

    return angle <= MAX_SLOPE_ANGLE
end

local function updateBhop()
    if not bhopSystemLoaded or not featureStates.Bhop then return end
    
    local character = player.Character
    local humanoid = character and character:FindFirstChild("Humanoid")
    if not character or not humanoid then return end

    local now = tick()
    if IsOnGround() and (now - LastJump) > 0.1 then
        humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        LastJump = now
    end
end

local function applyBhopFriction()
    if featureStates.BhopMode == "Acceleration" then
        applyToTables(function(obj)
            obj.Friction = featureStates.BhopAccel
        end)
    end
end

local function loadBhop()
    if bhopSystemLoaded then return end
    bhopSystemLoaded = true
    
    if bhopConnection then
        bhopConnection:Disconnect()
    end
    bhopConnection = RunService.Heartbeat:Connect(updateBhop)
    applyBhopFriction()
end

local function unloadBhop()
    if not bhopSystemLoaded then return end
    bhopSystemLoaded = false
    
    if bhopConnection then
        bhopConnection:Disconnect()
        bhopConnection = nil
    end
end

-- Auto Crouch System
local crouchConnection = nil
local previousCrouchState = false
local spamDown = true

local function fireKeybind(down, key)
    local ohTable = {
        ["Down"] = down,
        ["Key"] = key
    }
    local event = player:WaitForChild("PlayerScripts"):WaitForChild("Events"):WaitForChild("temporary_events"):WaitForChild("UseKeybind")
    event:Fire(ohTable)
end

local function setupAutoCrouch()
    if crouchConnection then crouchConnection:Disconnect() end
    
    crouchConnection = RunService.Heartbeat:Connect(function()
        if not featureStates.AutoCrouch then return end
        local character = player.Character
        if not character or not character:FindFirstChild("Humanoid") then return end

        local humanoid = character.Humanoid
        local mode = featureStates.AutoCrouchMode

        if mode == "Normal" then
            fireKeybind(spamDown, "Crouch")
            spamDown = not spamDown
        else
            local isAir = (humanoid.FloorMaterial == Enum.Material.Air) and (humanoid:GetState() ~= Enum.HumanoidStateType.Seated)
            local shouldCrouch = (mode == "Air" and isAir) or (mode == "Ground" and not isAir)
            if shouldCrouch ~= previousCrouchState then
                fireKeybind(shouldCrouch, "Crouch")
                previousCrouchState = shouldCrouch
            end
        end
    end)
end

-- Bounce System
local touchConnections = {}

local function setupBounce(character)
    if not featureStates.Bounce then return end
    
    local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
    
    if touchConnections[character] then
        touchConnections[character]:Disconnect()
        touchConnections[character] = nil
    end
    
    local touchConnection = humanoidRootPart.Touched:Connect(function(hit)
        ReplicatedStorage:WaitForChild("Events"):WaitForChild("Character"):WaitForChild("PassCharacterInfo"):FireServer({}, {2})
        
        if featureStates.BounceHeight > 0 then
            local bodyVel = Instance.new("BodyVelocity")
            bodyVel.MaxForce = Vector3.new(0, math.huge, 0)
            bodyVel.Velocity = Vector3.new(0, featureStates.BounceHeight, 0)
            bodyVel.Parent = humanoidRootPart
            game:GetService("Debris"):AddItem(bodyVel, 0.2)
        end
    end)
    
    touchConnections[character] = touchConnection
end

local function disableBounce()
    for character, connection in pairs(touchConnections) do
        if connection then
            connection:Disconnect()
            touchConnections[character] = nil
        end
    end
end

-- Speed Pad Booster
local speedPadConnection = nil

local function setupSpeedPadBooster()
    if speedPadConnection then
        speedPadConnection:Disconnect()
        speedPadConnection = nil
    end
    
    if not featureStates.SpeedPadBoost then return end
    
    local character = player.Character or player.CharacterAdded:Wait()
    local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
    local SPEED_PAD = workspace.Game.Effects.Deployables:WaitForChild("SpeedPad")
    local SPEED_PAD_POSITION = SPEED_PAD.PrimaryPart and SPEED_PAD.PrimaryPart.Position or SPEED_PAD:GetPivot().Position
    local MIN_DISTANCE = 1
    local MAX_DISTANCE = 9
    local alreadyBoosted = false

    local function applySpeedBoost()
        if alreadyBoosted then return end
        alreadyBoosted = true
        pcall(function()
            firesignal(ReplicatedStorage.Events.Character.SpeedBoost.OnClientEvent, "SpeedPad", featureStates.SpeedPadValue, featureStates.SpeedPadDuration, Color3.new(0.490196, 0.607843, 1.000000))
        end)
        task.wait(1)
        alreadyBoosted = false
    end

    speedPadConnection = RunService.Heartbeat:Connect(function()
        if not humanoidRootPart or not humanoidRootPart.Parent then
            character = player.Character or player.CharacterAdded:Wait()
            humanoidRootPart = character:WaitForChild("HumanoidRootPart")
            return
        end
        local distance = (humanoidRootPart.Position - SPEED_PAD_POSITION).Magnitude
        if distance >= MIN_DISTANCE and distance <= MAX_DISTANCE then
            applySpeedBoost()
        end
    end)
end

-- Jump Pad Booster
local jumpPadConnection = nil

local function setupJumpPadBooster(character)
    if jumpPadConnection then
        jumpPadConnection:Disconnect()
        jumpPadConnection = nil
    end
    
    if not featureStates.JumpPadBoost then return end
    
    local humanoid = character:WaitForChild("Humanoid")
    local rootPart = character:WaitForChild("HumanoidRootPart")
    local jumpPad = workspace.Game.Effects.Deployables:WaitForChild("JumpPad")
    local deployableEvent = ReplicatedStorage.Events.Other.DeployableUsed.OnClientEvent

    local function onDeployableUsed(deployable, usedOnPlayerModel)
        if deployable ~= jumpPad then return end
        if not usedOnPlayerModel or usedOnPlayerModel.Name ~= player.Name then return end

        rootPart.Velocity = Vector3.new(0, featureStates.JumpPadValue, 0)
        humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end

    jumpPadConnection = deployableEvent:Connect(onDeployableUsed)
end

-- Cola Systems
local colaMetatableHook = nil
local colaEventConnection = nil
local colaSpeedEventConnection = nil

local function setupUnlimitedCola()
    if colaMetatableHook then return end
    
    local RemoteEvent = ReplicatedStorage.Events.Character.ToolAction
    local mt = getrawmetatable(RemoteEvent)
    local oldNamecall = mt.__namecall

    local recentBlockTime = 0
    local blockCooldown = 0.1

    setreadonly(mt, false)

    mt.__namecall = newcclosure(function(self, ...)
        local method = getnamecallmethod()
        local args = {...}
        
        if method == "FireServer" and args[2] == 19 then
            local currentTime = tick()
            
            if currentTime - recentBlockTime >= blockCooldown then
                recentBlockTime = currentTime
                return nil
            end
        end
        
        return oldNamecall(self, ...)
    end)

    setreadonly(mt, true)
    colaMetatableHook = {mt = mt, oldNamecall = oldNamecall}

    local events = player.PlayerScripts.Events.temporary_events
    colaEventConnection = events.UseKeybind.Event:Connect(function(args)
        if args.Forced and args.Key == "Cola" and args.Down then
            wait(2.15)
            firesignal(ReplicatedStorage.Events.Character.SpeedBoost.OnClientEvent, "Cola", 1.4, 3.5, Color3.fromRGB(199, 141, 93))
        end
    end)
end

local function disableUnlimitedCola()
    if colaMetatableHook then
        local mt = colaMetatableHook.mt
        local oldNamecall = colaMetatableHook.oldNamecall
        
        setreadonly(mt, false)
        mt.__namecall = oldNamecall
        setreadonly(mt, true)
        
        colaMetatableHook = nil
    end
    
    if colaEventConnection then
        colaEventConnection:Disconnect()
        colaEventConnection = nil
    end
end

local function setupColaSpeedBooster()
    if colaSpeedEventConnection then return end
    
    local events = player.PlayerScripts.Events.temporary_events
    colaSpeedEventConnection = events.UseKeybind.Event:Connect(function(args)
        if args.Forced and args.Key == "Cola" and args.Down then
            wait(2.14)
            
            local speed = featureStates.ColaSpeedValue
            local duration = featureStates.ColaDuration
            
            firesignal(ReplicatedStorage.Events.Character.SpeedBoost.OnClientEvent, "Cola", speed, duration, Color3.fromRGB(199, 141, 93))
        end
    end)
end

local function disableColaSpeedBooster()
    if colaSpeedEventConnection then
        colaSpeedEventConnection:Disconnect()
        colaSpeedEventConnection = nil
    end
end

-- Cosmetic Changer
local cosmetic1, cosmetic2 = "", ""

local function applyCosmetics()
    pcall(function()
        if cosmetic1 == "" or cosmetic2 == "" or cosmetic1 == cosmetic2 then return end
        
        local Cosmetics = ReplicatedStorage:WaitForChild("Items"):WaitForChild("Cosmetics")
        
        local a = Cosmetics:FindFirstChild(cosmetic1)
        local b = Cosmetics:FindFirstChild(cosmetic2)
        if not a or not b then return end
        
        local tempRoot = Instance.new("Folder", Cosmetics)
        tempRoot.Name = "__temp_swap_" .. tostring(tick()):gsub("%.", "_")
        
        local tempA = Instance.new("Folder", tempRoot)
        local tempB = Instance.new("Folder", tempRoot)
        
        for _, c in ipairs(a:GetChildren()) do c.Parent = tempA end
        for _, c in ipairs(b:GetChildren()) do c.Parent = tempB end
        
        for _, c in ipairs(tempA:GetChildren()) do c.Parent = b end
        for _, c in ipairs(tempB:GetChildren()) do c.Parent = a end
        
        tempRoot:Destroy()
    end)
end

-- Emote Changer
local currentEmotes = table.create(12, "")
local selectEmotes = table.create(12, "")
local emoteEnabled = table.create(12, false)
local currentTag = nil

local function readTagFromFolder(f)
    local a = f:GetAttribute("Tag")
    if a ~= nil then return a end
    local o = f:FindFirstChild("Tag")
    if o and o:IsA("ValueBase") then return o.Value end
    return nil
end

local function onRespawn()
    repeat task.wait() until workspace:FindFirstChild("Game") and workspace.Game:FindFirstChild("Players")
    local pf = workspace.Game.Players:WaitForChild(player.Name, 10)
    if not pf then currentTag = nil; return end
    currentTag = readTagFromFolder(pf)
end

local pendingSlot = nil
local function fireSelect(slot)
    if not currentTag then return end
    local b = tonumber(currentTag)
    local buf = buffer.create(2)
    buffer.writeu8(buf, 0, b)
    buffer.writeu8(buf, 1, 17)
    local PassCharacterInfo = ReplicatedStorage:WaitForChild("Events"):WaitForChild("Character"):WaitForChild("PassCharacterInfo")
    if PassCharacterInfo.OnClientEvent then
        firesignal(PassCharacterInfo.OnClientEvent, buf, {selectEmotes[slot]})
    end
end

local function setupEmoteChanger()
    local EmoteRemote = ReplicatedStorage:WaitForChild("Events"):WaitForChild("Character"):WaitForChild("Emote")
    local PassCharacterInfo = ReplicatedStorage:WaitForChild("Events"):WaitForChild("Character"):WaitForChild("PassCharacterInfo")
    
    PassCharacterInfo.OnClientEvent:Connect(function()
        if not pendingSlot then return end
        fireSelect(pendingSlot)
        pendingSlot = nil
    end)

    local oldNamecall
    oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
        local m = getnamecallmethod()
        local a = {...}
        if m == "FireServer" and self == EmoteRemote and type(a[1]) == "string" then
            for i = 1, 12 do
                if emoteEnabled[i] and currentEmotes[i] ~= "" and a[1] == currentEmotes[i] then
                    pendingSlot = i
                    task.spawn(function()
                        task.wait(0.5)
                        if pendingSlot == i then
                            fireSelect(i)
                            pendingSlot = nil
                        end
                    end)
                    return
                end
            end
        end
        return oldNamecall(self, ...)
    end)

    if player.Character then
        onRespawn()
    end
    player.CharacterAdded:Connect(onRespawn)
end

-- Lag Switch System
local lagInputConnection = nil
local isLagActive = false
local lagSystemLoaded = false

local function loadLagSystem()
    if lagSystemLoaded then return end
    lagSystemLoaded = true
    
    if not lagInputConnection then
        lagInputConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if gameProcessed then return end
            if input.KeyCode == Enum.KeyCode.L and featureStates.LagSwitch and not isLagActive then
                isLagActive = true
                task.spawn(function()
                    local duration = featureStates.LagDuration
                    local start = tick()
                    while tick() - start < duration do
                        local a = math.random(1, 1000000) * math.random(1, 1000000)
                        a = a / math.random(1, 10000)
                    end
                    isLagActive = false
                end)
            end
        end)
    end
end

local function unloadLagSystem()
    if not lagSystemLoaded then return end
    lagSystemLoaded = false
    
    if lagInputConnection then
        lagInputConnection:Disconnect()
        lagInputConnection = nil
    end
    isLagActive = false
end

-- Visual Systems
local originalBrightness = Lighting.Brightness
local originalFogEnd = Lighting.FogEnd
local originalOutdoorAmbient = Lighting.OutdoorAmbient
local originalAmbient = Lighting.Ambient
local originalGlobalShadows = Lighting.GlobalShadows

local function startFullBright()
    originalBrightness = Lighting.Brightness
    originalOutdoorAmbient = Lighting.OutdoorAmbient
    originalAmbient = Lighting.Ambient
    originalGlobalShadows = Lighting.GlobalShadows
    Lighting.Brightness = 2
    Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
    Lighting.Ambient = Color3.fromRGB(255, 255, 255)
    Lighting.GlobalShadows = false
end

local function stopFullBright()
    Lighting.Brightness = originalBrightness
    Lighting.OutdoorAmbient = originalOutdoorAmbient
    Lighting.Ambient = originalAmbient
    Lighting.GlobalShadows = originalGlobalShadows
end

local function applyLowGraphics()
    for _, v in next, game:GetDescendants() do
        if v:IsA("Part") or v:IsA("UnionOperation") or v:IsA("BasePart") then
            v.Material = Enum.Material.SmoothPlastic
        end
        
        if v:IsA("ParticleEmitter") or v:IsA("Smoke") or v:IsA("Explosion") or v:IsA("Sparkles") or v:IsA("Fire") then
            v.Enabled = false
        end
        
        if v:IsA("BloomEffect") or v:IsA("BlurEffect") or v:IsA("DepthOfFieldEffect") or v:IsA("SunRaysEffect") then
            v.Enabled = false
        end
        
        if v:IsA("Sky") then
            v.Parent = nil
        end
    end
end

local function removeTextures()
    for _, part in ipairs(workspace:GetDescendants()) do
        if part:IsA("Part") or part:IsA("MeshPart") or part:IsA("UnionOperation") or part:IsA("WedgePart") or part:IsA("CornerWedgePart") then
            if part:IsA("Part") then
                part.Material = Enum.Material.SmoothPlastic
            end
            if part:FindFirstChildWhichIsA("Texture") then
                local texture = part:FindFirstChildWhichIsA("Texture")
                texture.Texture = "rbxassetid://0"
            end
            if part:FindFirstChildWhichIsA("Decal") then
                local decal = part:FindFirstChildWhichIsA("Decal")
                decal.Texture = "rbxassetid://0"
            end
        end
    end
end

local function setupTimerDisplay()
    local function getRoundTimer()
        local pg = player.PlayerGui
        local shared = pg:FindFirstChild("Shared")
        local hud = shared and shared:FindFirstChild("HUD")
        local overlay = hud and hud:FindFirstChild("Overlay")
        local default = overlay and overlay:FindFirstChild("Default")
        local ro = default and default:FindFirstChild("RoundOverlay")
        local round = ro and ro:FindFirstChild("Round")
        return round and round:FindFirstChild("RoundTimer")
    end

    local function setContainerVisible(visible)
        local pg = player.PlayerGui
        local main = pg:FindFirstChild("MainInterface")
        if main then
            local container = main:FindFirstChild("TimerContainer")
            if container then
                container.Visible = visible
            end
        end
    end

    if featureStates.TimerDisplay then
        task.spawn(function()
            while featureStates.TimerDisplay do
                local timer = getRoundTimer()
                if timer then
                    setContainerVisible(not timer.Visible)
                else
                    setContainerVisible(true)
                end
                task.wait(0.1)
            end
            setContainerVisible(false)
        end)
    else
        setContainerVisible(false)
    end
end

-- Character Events
RunService.Heartbeat:Connect(function()
    if not Character or not Character:IsDescendantOf(workspace) then
        Character = player.Character or player.CharacterAdded:Wait()
        if Character then
            Humanoid = Character:FindFirstChildOfClass("Humanoid")
            HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
        else
            Humanoid = nil
            HumanoidRootPart = nil
        end
    end
end)

player.CharacterAdded:Connect(function(character)
    Character = character
    Humanoid = character:WaitForChild("Humanoid")
    HumanoidRootPart = character:WaitForChild("HumanoidRootPart")
    
    if featureStates.Bounce then
        setupBounce(character)
    end
    if featureStates.JumpPadBoost then
        setupJumpPadBooster(character)
    end
end)

-- Setup GUI
local function setupGui()
    local FeatureSection = Window:Section({ Title = "Features", Opened = true })

    local Tabs = {
        Movement = FeatureSection:Tab({ Title = "Movement", Icon = "move" }),
        Boosts = FeatureSection:Tab({ Title = "Boosts", Icon = "zap" }),
        Visual = FeatureSection:Tab({ Title = "Visual", Icon = "eye" }),
        Utility = FeatureSection:Tab({ Title = "Utility", Icon = "wrench" }),
        Settings = FeatureSection:Tab({ Title = "Settings", Icon = "settings" })
    }

    -- Movement Tab
    Tabs.Movement:Section({ Title = "Movement Settings" })
    
    Tabs.Movement:Input({
        Title = "Speed",
        Placeholder = "1500",
        Value = tostring(featureStates.Speed),
        NumbersOnly = true,
        Callback = function(value)
            local num = tonumber(value)
            if num then
                featureStates.Speed = num
                applySpeed()
            end
        end
    })

    Tabs.Movement:Input({
        Title = "Jump Cap",
        Placeholder = "1",
        Value = tostring(featureStates.JumpCap),
        NumbersOnly = true,
        Callback = function(value)
            local num = tonumber(value)
            if num then
                featureStates.JumpCap = num
                applyJumpCap()
            end
        end
    })

    Tabs.Movement:Input({
        Title = "Strafe Acceleration",
        Placeholder = "187",
        Value = tostring(featureStates.StrafeAccel),
        NumbersOnly = true,
        Callback = function(value)
            local num = tonumber(value)
            if num then
                featureStates.StrafeAccel = num
                applyStrafeAccel()
            end
        end
    })

    Tabs.Movement:Section({ Title = "Bhop" })
    
    local bhopFloatingGui, bhopButton = createFloatingButton("Bhop", "Bhop", 0)
    
    Tabs.Movement:Toggle({
        Title = "Enable Bhop",
        Value = false,
        Callback = function(state)
            featureStates.Bhop = state
            if state then
                loadBhop()
            else
                unloadBhop()
            end
            if bhopButton then
                bhopButton.Text = state and "On" or "Off"
                bhopButton.BackgroundColor3 = state and Color3.fromRGB(0, 120, 80) or Color3.fromRGB(120, 0, 0)
            end
        end
    })

    Tabs.Movement:Toggle({
        Title = "Show Bhop Button",
        Value = false,
        Callback = function(state)
            if bhopFloatingGui then
                bhopFloatingGui.Enabled = state
            end
        end
    })

    Tabs.Movement:Dropdown({
        Title = "Bhop Mode",
        Values = {"Acceleration", "No Acceleration"},
        Value = "Acceleration",
        Callback = function(value)
            featureStates.BhopMode = value
            if featureStates.Bhop then
                applyBhopFriction()
            end
        end
    })

    Tabs.Movement:Input({
        Title = "Bhop Acceleration (Negative)",
        Placeholder = "-0.5",
        Value = tostring(featureStates.BhopAccel),
        Callback = function(value)
            if tostring(value):sub(1, 1) == "-" then
                local num = tonumber(value)
                if num then
                    featureStates.BhopAccel = num
                    if featureStates.Bhop then
                        applyBhopFriction()
                    end
                end
            end
        end
    })

    Tabs.Movement:Section({ Title = "Auto Crouch" })
    
    local crouchFloatingGui, crouchButton = createFloatingButton("Crouch", "AutoCrouch", 0.12)
    
    Tabs.Movement:Toggle({
        Title = "Enable Auto Crouch",
        Value = false,
        Callback = function(state)
            featureStates.AutoCrouch = state
            if state then
                setupAutoCrouch()
            else
                if crouchConnection then
                    crouchConnection:Disconnect()
                    crouchConnection = nil
                end
            end
            if crouchButton then
                crouchButton.Text = state and "On" or "Off"
                crouchButton.BackgroundColor3 = state and Color3.fromRGB(0, 120, 80) or Color3.fromRGB(120, 0, 0)
            end
        end
    })

    Tabs.Movement:Toggle({
        Title = "Show Crouch Button",
        Value = false,
        Callback = function(state)
            if crouchFloatingGui then
                crouchFloatingGui.Enabled = state
            end
        end
    })

    Tabs.Movement:Dropdown({
        Title = "Auto Crouch Mode",
        Values = {"Air", "Normal", "Ground"},
        Value = "Air",
        Callback = function(value)
            featureStates.AutoCrouchMode = value
        end
    })

    Tabs.Movement:Section({ Title = "Bounce" })
    
    local bounceFloatingGui, bounceButton = createFloatingButton("Bounce", "Bounce", 0.24)
    
    Tabs.Movement:Toggle({
        Title = "Enable Bounce",
        Value = false,
        Callback = function(state)
            featureStates.Bounce = state
            if state then
                if player.Character then
                    setupBounce(player.Character)
                end
            else
                disableBounce()
            end
            if bounceButton then
                bounceButton.Text = state and "On" or "Off"
                bounceButton.BackgroundColor3 = state and Color3.fromRGB(0, 120, 80) or Color3.fromRGB(120, 0, 0)
            end
        end
    })

    Tabs.Movement:Toggle({
        Title = "Show Bounce Button",
        Value = false,
        Callback = function(state)
            if bounceFloatingGui then
                bounceFloatingGui.Enabled = state
            end
        end
    })

    Tabs.Movement:Input({
        Title = "Bounce Height",
        Placeholder = "0",
        Value = tostring(featureStates.BounceHeight),
        NumbersOnly = true,
        Callback = function(value)
            local num = tonumber(value)
            if num then
                featureStates.BounceHeight = num
            end
        end
    })

    -- Boosts Tab
    Tabs.Boosts:Section({ Title = "Speed Pad Booster" })
    
    local speedPadFloatingGui, speedPadButton = createFloatingButton("SpeedPad", "SpeedPadBoost", 0)
    
    Tabs.Boosts:Toggle({
        Title = "Enable Speed Pad Boost",
        Value = false,
        Callback = function(state)
            featureStates.SpeedPadBoost = state
            if state then
                setupSpeedPadBooster()
            else
                if speedPadConnection then
                    speedPadConnection:Disconnect()
                    speedPadConnection = nil
                end
            end
            if speedPadButton then
                speedPadButton.Text = state and "On" or "Off"
                speedPadButton.BackgroundColor3 = state and Color3.fromRGB(0, 120, 80) or Color3.fromRGB(120, 0, 0)
            end
        end
    })

    Tabs.Boosts:Toggle({
        Title = "Show Speed Pad Button",
        Value = false,
        Callback = function(state)
            if speedPadFloatingGui then
                speedPadFloatingGui.Enabled = state
            end
        end
    })

    Tabs.Boosts:Input({
        Title = "Speed Value",
        Placeholder = "1.3",
        Value = tostring(featureStates.SpeedPadValue),
        NumbersOnly = true,
        Callback = function(value)
            local num = tonumber(value)
            if num then
                featureStates.SpeedPadValue = num
            end
        end
    })

    Tabs.Boosts:Input({
        Title = "Duration",
        Placeholder = "2",
        Value = tostring(featureStates.SpeedPadDuration),
        NumbersOnly = true,
        Callback = function(value)
            local num = tonumber(value)
            if num then
                featureStates.SpeedPadDuration = num
            end
        end
    })

    Tabs.Boosts:Section({ Title = "Jump Pad Booster" })
    
    local jumpPadFloatingGui, jumpPadButton = createFloatingButton("JumpPad", "JumpPadBoost", 0.12)
    
    Tabs.Boosts:Toggle({
        Title = "Enable Jump Pad Boost",
        Value = false,
        Callback = function(state)
            featureStates.JumpPadBoost = state
            if state then
                if player.Character then
                    setupJumpPadBooster(player.Character)
                end
            else
                if jumpPadConnection then
                    jumpPadConnection:Disconnect()
                    jumpPadConnection = nil
                end
            end
            if jumpPadButton then
                jumpPadButton.Text = state and "On" or "Off"
                jumpPadButton.BackgroundColor3 = state and Color3.fromRGB(0, 120, 80) or Color3.fromRGB(120, 0, 0)
            end
        end
    })

    Tabs.Boosts:Toggle({
        Title = "Show Jump Pad Button",
        Value = false,
        Callback = function(state)
            if jumpPadFloatingGui then
                jumpPadFloatingGui.Enabled = state
            end
        end
    })

    Tabs.Boosts:Input({
        Title = "Jump Value",
        Placeholder = "0",
        Value = tostring(featureStates.JumpPadValue),
        NumbersOnly = true,
        Callback = function(value)
            local num = tonumber(value)
            if num then
                featureStates.JumpPadValue = num
            end
        end
    })

    Tabs.Boosts:Section({ Title = "Cola Modifier" })
    
    local colaFloatingGui, colaButton = createFloatingButton("Cola", "UnlimitedCola", 0.24)
    
    Tabs.Boosts:Toggle({
        Title = "Unlimited Cola",
        Value = false,
        Callback = function(state)
            featureStates.UnlimitedCola = state
            if state then
                setupUnlimitedCola()
            else
                disableUnlimitedCola()
            end
            if colaButton then
                colaButton.Text = state and "On" or "Off"
                colaButton.BackgroundColor3 = state and Color3.fromRGB(0, 120, 80) or Color3.fromRGB(120, 0, 0)
            end
        end
    })

    Tabs.Boosts:Toggle({
        Title = "Show Cola Button",
        Value = false,
        Callback = function(state)
            if colaFloatingGui then
                colaFloatingGui.Enabled = state
            end
        end
    })

    Tabs.Boosts:Toggle({
        Title = "Cola Speed Booster",
        Value = false,
        Callback = function(state)
            featureStates.ColaSpeedBoost = state
            if state then
                setupColaSpeedBooster()
            else
                disableColaSpeedBooster()
            end
        end
    })

    Tabs.Boosts:Input({
        Title = "Cola Speed Value",
        Placeholder = "1.4",
        Value = tostring(featureStates.ColaSpeedValue),
        NumbersOnly = true,
        Callback = function(value)
            local num = tonumber(value)
            if num then
                featureStates.ColaSpeedValue = num
            end
        end
    })

    Tabs.Boosts:Input({
        Title = "Cola Duration",
        Placeholder = "3.5",
        Value = tostring(featureStates.ColaDuration),
        NumbersOnly = true,
        Callback = function(value)
            local num = tonumber(value)
            if num then
                featureStates.ColaDuration = num
            end
        end
    })

    -- Visual Tab
    Tabs.Visual:Section({ Title = "Cosmetic Changer" })
    
    Tabs.Visual:Input({
        Title = "Current Cosmetic",
        Placeholder = "Enter current cosmetic name",
        Callback = function(value)
            cosmetic1 = value
        end
    })

    Tabs.Visual:Input({
        Title = "Select Cosmetic",
        Placeholder = "Enter new cosmetic name",
        Callback = function(value)
            cosmetic2 = value
        end
    })

    Tabs.Visual:Button({
        Title = "Apply Cosmetics",
        Callback = function()
            applyCosmetics()
        end
    })

    Tabs.Visual:Section({ Title = "Emote Changer" })
    
    for i = 1, 12 do
        Tabs.Visual:Input({
            Title = "Current Emote " .. i,
            Placeholder = "Enter current emote name",
            Value = currentEmotes[i],
            Callback = function(value)
                currentEmotes[i] = value:gsub("%s+", "")
            end
        })
    end

    Tabs.Visual:Divider()

    for i = 1, 12 do
        Tabs.Visual:Input({
            Title = "Select Emote " .. i,
            Placeholder = "Enter select emote name",
            Value = selectEmotes[i],
            Callback = function(value)
                selectEmotes[i] = value:gsub("%s+", "")
            end
        })
    end

    Tabs.Visual:Button({
        Title = "Apply Emote Mappings",
        Icon = "refresh-cw",
        Callback = function()
            for i = 1, 12 do
                emoteEnabled[i] = (currentEmotes[i] ~= "" and selectEmotes[i] ~= "")
            end
            WindUI:Notify({
                Title = "Emote Changer",
                Content = "Emote mappings applied!",
                Duration = 3
            })
        end
    })

    Tabs.Visual:Button({
        Title = "Reset All Emotes",
        Icon = "trash-2",
        Callback = function()
            for i = 1, 12 do
                currentEmotes[i] = ""
                selectEmotes[i] = ""
                emoteEnabled[i] = false
            end
            WindUI:Notify({
                Title = "Emote Changer",
                Content = "All emotes reset!",
                Duration = 3
            })
        end
    })

    -- Utility Tab
    Tabs.Utility:Section({ Title = "Lag Switch" })
    
    local lagFloatingGui, lagButton = createFloatingButton("LagSwitch", "LagSwitch", 0.36)
    
    Tabs.Utility:Toggle({
        Title = "Enable Lag Switch",
        Desc = "Press L to trigger lag",
        Value = false,
        Callback = function(state)
            featureStates.LagSwitch = state
            if state then
                loadLagSystem()
            else
                unloadLagSystem()
            end
            if lagButton then
                lagButton.Text = state and "On" or "Off"
                lagButton.BackgroundColor3 = state and Color3.fromRGB(0, 120, 80) or Color3.fromRGB(120, 0, 0)
            end
        end
    })

    Tabs.Utility:Toggle({
        Title = "Show Lag Switch Button",
        Value = false,
        Callback = function(state)
            if lagFloatingGui then
                lagFloatingGui.Enabled = state
            end
        end
    })

    Tabs.Utility:Input({
        Title = "Lag Duration (seconds)",
        Placeholder = "0.5",
        Value = tostring(featureStates.LagDuration),
        NumbersOnly = true,
        Callback = function(value)
            local num = tonumber(value)
            if num and num > 0 then
                featureStates.LagDuration = num
            end
        end
    })

    Tabs.Utility:Section({ Title = "Graphics" })
    
    Tabs.Utility:Toggle({
        Title = "FullBright",
        Value = false,
        Callback = function(state)
            featureStates.FullBright = state
            if state then
                startFullBright()
            else
                stopFullBright()
            end
        end
    })

    Tabs.Utility:Button({
        Title = "Low Graphics",
        Desc = "Disable textures, effects, and optimize graphics",
        Callback = function()
            applyLowGraphics()
            WindUI:Notify({
                Title = "Low Graphics",
                Content = "Low graphics applied!",
                Duration = 3
            })
        end
    })

    Tabs.Utility:Button({
        Title = "Remove Textures",
        Desc = "Remove all textures from the game",
        Callback = function()
            removeTextures()
            WindUI:Notify({
                Title = "Remove Textures",
                Content = "Textures removed!",
                Duration = 3
            })
        end
    })

    Tabs.Utility:Toggle({
        Title = "Timer Display",
        Desc = "Show custom timer display",
        Value = false,
        Callback = function(state)
            featureStates.TimerDisplay = state
            setupTimerDisplay()
        end
    })

    -- Settings Tab
    Tabs.Settings:Section({ Title = "UI Settings" })
    
    Tabs.Settings:Slider({
        Title = "Button Scale",
        Value = { Min = 0.5, Max = 2.0, Default = 1.0, Step = 0.1 },
        Callback = function(value)
            featureStates.FloatingButtonScale = value
            
            -- Recreate all floating buttons with new scale
            for _, gui in pairs(playerGui:GetChildren()) do
                if gui.Name:match("FloatingGui$") then
                    local name = gui.Name:gsub("FloatingGui", "")
                    local variableName = name
                    gui:Destroy()
                end
            end
            
            WindUI:Notify({
                Title = "Button Scale",
                Content = "Button scale updated. Toggle buttons to see changes.",
                Duration = 3
            })
        end
    })

    Tabs.Settings:Input({
        Title = "Name Width",
        Placeholder = "80",
        Value = tostring(featureStates.FloatingButtonNameWidth),
        NumbersOnly = true,
        Callback = function(value)
            local num = tonumber(value)
            if num and num > 0 then
                featureStates.FloatingButtonNameWidth = num
                WindUI:Notify({
                    Title = "Name Width",
                    Content = "Toggle buttons to see changes.",
                    Duration = 3
                })
            end
        end
    })

    Tabs.Settings:Input({
        Title = "Name Height",
        Placeholder = "20",
        Value = tostring(featureStates.FloatingButtonNameHeight),
        NumbersOnly = true,
        Callback = function(value)
            local num = tonumber(value)
            if num and num > 0 then
                featureStates.FloatingButtonNameHeight = num
                WindUI:Notify({
                    Title = "Name Height",
                    Content = "Toggle buttons to see changes.",
                    Duration = 3
                })
            end
        end
    })

    Tabs.Settings:Input({
        Title = "Toggle Width",
        Placeholder = "80",
        Value = tostring(featureStates.FloatingButtonToggleWidth),
        NumbersOnly = true,
        Callback = function(value)
            local num = tonumber(value)
            if num and num > 0 then
                featureStates.FloatingButtonToggleWidth = num
                WindUI:Notify({
                    Title = "Toggle Width",
                    Content = "Toggle buttons to see changes.",
                    Duration = 3
                })
            end
        end
    })

    Tabs.Settings:Input({
        Title = "Toggle Height",
        Placeholder = "30",
        Value = tostring(featureStates.FloatingButtonToggleHeight),
        NumbersOnly = true,
        Callback = function(value)
            local num = tonumber(value)
            if num and num > 0 then
                featureStates.FloatingButtonToggleHeight = num
                WindUI:Notify({
                    Title = "Toggle Height",
                    Content = "Toggle buttons to see changes.",
                    Duration = 3
                })
            end
        end
    })

    Tabs.Settings:Section({ Title = "Theme" })

    local themes = {}
    for themeName, _ in pairs(WindUI:GetThemes()) do
        table.insert(themes, themeName)
    end
    table.sort(themes)

    Tabs.Settings:Dropdown({
        Title = "Select Theme",
        Values = themes,
        Value = "Dark",
        Callback = function(theme)
            WindUI:SetTheme(theme)
        end
    })

    Tabs.Settings:Slider({
        Title = "Window Transparency",
        Value = { Min = 0, Max = 1, Default = 0.2, Step = 0.1 },
        Callback = function(value)
            WindUI.TransparencyValue = tonumber(value)
            Window:ToggleTransparency(tonumber(value) > 0)
        end
    })

    Window:SelectTab(1)
end

setupGui()
setupAutoCrouch()
setupEmoteChanger()

-- Apply initial settings
applySpeed()
applyJumpCap()
applyStrafeAccel()

loadstring(game:HttpGet("https://raw.githubusercontent.com/Hajipak/Evade/refs/heads/main/Script/More-loadstring.lua"))()

WindUI:Notify({
    Title = "Evade Hub Simplified",
    Content = "Script loaded successfully!",
    Duration = 5
})
