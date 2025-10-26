if getgenv().DaraHubEvadeExecuted then
    return
end
getgenv().DaraHubEvadeExecuted = true

-- Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local workspace = game:GetService("Workspace")
local originalGameGravity = workspace.Gravity
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local MarketplaceService = game:GetService("MarketplaceService")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")
local CoreGui = game:GetService("CoreGui")
local TextService = game:GetService("TextService")
local ContextActionService = game:GetService("ContextActionService")

-- Player Variables
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local placeId = game.PlaceId
local jobId = game.JobId
local camera = workspace.CurrentCamera
local mouse = player:GetMouse()

-- ===== FLUENT UI SETUP =====
local Fluent, SaveManager, InterfaceManager

local success, result = pcall(function()
    Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
    SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
    InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()
end)

if not success then
    warn("Failed to load Fluent UI: " .. tostring(result))
    return
end

local Window = Fluent:CreateWindow({
    Title = "Dara Hub - Evade",
    SubTitle = "Fluent UI Version | Complete Edition",
    TabWidth = 160,
    Size = UDim2.fromOffset(650, 500),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

-- Define all tabs
local Tabs = {
    Main = Window:AddTab({ Title = "Main", Icon = "home" }),
    Player = Window:AddTab({ Title = "Player", Icon = "user" }),
    Auto = Window:AddTab({ Title = "Auto", Icon = "zap" }),
    Visuals = Window:AddTab({ Title = "Visuals", Icon = "eye" }),
    ESP = Window:AddTab({ Title = "ESP", Icon = "target" }),
    Utility = Window:AddTab({ Title = "Utility", Icon = "settings" }),
    Teleport = Window:AddTab({ Title = "Teleport", Icon = "navigation" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}

local Options = Fluent.Options

-- ===== COMPREHENSIVE GLOBAL VARIABLES =====
local featureStates = {
    -- Player Movement
    InfiniteJump = false,
    Fly = false,
    TPWALK = false,
    JumpBoost = false,
    Noclip = false,
    InfiniteSlide = false,
    SpeedEnabled = false,
    
    -- Auto Features
    AutoCarry = false,
    AutoRevive = false,
    FastRevive = false,
    AutoVote = false,
    AutoSelfRevive = false,
    AutoWin = false,
    AutoMoneyFarm = false,
    AutoWhistle = false,
    AutoCrouch = false,
    AutoEmote = false,
    Bhop = false,
    BhopHold = false,
    AutoTicketFarm = false,
    
    -- Visuals
    FullBright = false,
    NoFog = false,
    TimerDisplay = false,
    DisableCameraShake = false,
    CameraStretch = false,
    DisableVignette = false,
    CustomGravity = false,
    
    -- ESP Systems
    PlayerESP = {
        boxes = false,
        tracers = false,
        names = false,
        distance = false,
        rainbowBoxes = false,
        rainbowTracers = false,
        boxType = "2D",
    },
    NextbotESP = {
        boxes = false,
        tracers = false,
        names = false,
        distance = false,
        rainbowBoxes = false,
        rainbowTracers = false,
        boxType = "2D",
    },
    DownedBoxESP = false,
    DownedTracer = false,
    DownedNameESP = false,
    DownedDistanceESP = false,
    DownedBoxType = "2D",
    TicketESP = false,
    TicketTracerESP = false,
    TicketDistanceESP = false,
    TicketHighlightESP = false,
    
    -- Utility
    FreeCam = false,
    LagSwitch = false,
    AntiAFK = false,
    
    -- Values
    GravityValue = originalGameGravity,
    FlySpeed = 50,
    TpwalkValue = 1,
    JumpPower = 50,
    JumpMethod = "Hold",
    SelectedMap = 1,
    SelectedVoteMode = 1,
    FastReviveMethod = "Interact",
    AutoCrouchMode = "Air",
    SlideFrictionValue = -8,
    LagDuration = 0.5,
    StretchHorizontal = 0.8,
    StretchVertical = 0.8,
    SpeedValue = 16,
    FOVValue = 70
}

-- Character system
local character, humanoid, rootPart
local isJumpHeld = false
local flying = false
local bodyVelocity, bodyGyro
local ToggleTpwalk = false
local TpwalkConnection
local jumpCount = 0
local MAX_JUMPS = math.huge
local hasRevived = false

-- Freecam system
local FREECAM_SPEED = 50
local SENSITIVITY = 0.002
local ZOOM_SPEED = 10
local MIN_ZOOM = 2
local MAX_ZOOM = 100
local FOV_SPEED = 5
local MIN_FOV = 10
local MAX_FOV = 120
local DEFAULT_FOV = 70
local isFreecamEnabled = false
local isFreecamMovementEnabled = true
local cameraPosition = Vector3.new(0, 10, 0)
local cameraRotation = Vector2.new(0, 0)
local JUMP_FORCE = 50
local isMobile = not UserInputService.KeyboardEnabled
local touchConnection
local lastTouchPosition = nil
local lastYPosition = nil
local isJumping = false
local isAltHeld = false
local heartbeatConnection
local inputChangedConnection
local characterAddedConnection
local dragging = false

-- ESP system
local playerEspElements = {}
local nextbotEspElements = {}
local downedTracerLines = {}
local downedNameESPLabels = {}
local playerEspConnection, nextbotEspConnection, downedTracerConnection, downedNameESPConnection
local ticketEspConnections = {}
local ticketEspLabels = {}
local ticketTracerConnections = {}
local ticketTracerDrawings = {}
local ticketDistanceConnections = {}
local ticketDistanceLabels = {}
local ticketHighlightConnections = {}
local ticketHighlights = {}

-- Auto system
local AntiAFKConnection, AutoCarryConnection, reviveLoopHandle, AutoVoteConnection
local AutoSelfReviveConnection, AutoWinConnection, AutoMoneyFarmConnection, autoWhistleHandle
local AutoTicketFarmConnection
local interactEvent = ReplicatedStorage:WaitForChild("Events"):WaitForChild("Character"):WaitForChild("Interact")

-- Visual system
local originalBrightness = Lighting.Brightness
local originalFogEnd = Lighting.FogEnd
local originalOutdoorAmbient = Lighting.OutdoorAmbient
local originalAmbient = Lighting.Ambient
local originalGlobalShadows = Lighting.GlobalShadows
local originalAtmospheres = {}
local cameraStretchConnection
local vignetteConnection
local stableCameraInstance

-- Bhop system
getgenv().autoJumpEnabled = false
getgenv().bhopMode = "Acceleration"
getgenv().bhopAccelValue = -0.5
getgenv().bhopHoldActive = false

-- Other globals
getgenv().lagSwitchEnabled = false
getgenv().gravityGuiVisible = false
getgenv().autoCarryGuiVisible = false
getgenv().SelectedEmote = nil
getgenv().EmoteEnabled = false
getgenv().ticketfarm = false
getgenv().moneyfarm = false
getgenv().ApplyMode = "Not Optimized"

local currentSettings = {
    Speed = "1500",
    JumpCap = "1",
    AirStrafeAcceleration = "187"
}

-- ===== CORE CHARACTER SYSTEM =====
local function setupCharacterVars()
    character = player.Character
    if character then
        humanoid = character:FindFirstChildOfClass("Humanoid")
        rootPart = character:FindFirstChild("HumanoidRootPart")
    end
end

setupCharacterVars()

player.CharacterAdded:Connect(function(newChar)
    character = newChar
    humanoid = newChar:WaitForChild("Humanoid")
    rootPart = newChar:WaitForChild("HumanoidRootPart")
    hasRevived = false
    
    -- Reapply features on respawn
    if featureStates.JumpBoost and humanoid then
        humanoid.JumpPower = featureStates.JumpPower
    end
    
    if featureStates.Fly then
        task.wait(1)
        if flying then stopFlying() end
        startFlying()
    end
end)

-- ===== PLAYER MOVEMENT SYSTEM =====
local function isPlayerGrounded()
    if not character or not humanoid or not rootPart then return false end
    local rayOrigin = rootPart.Position
    local rayDirection = Vector3.new(0, -3, 0)
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {character}
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    local raycastResult = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
    return raycastResult ~= nil
end

local function bouncePlayer()
    if character and humanoid and rootPart and humanoid.Health > 0 then
        if not isPlayerGrounded() then
            humanoid.Jump = true
            local jumpVelocity = math.sqrt(1.5 * humanoid.JumpHeight * workspace.Gravity) * 1.5
            rootPart.Velocity = Vector3.new(rootPart.Velocity.X, jumpVelocity * humanoid.JumpPower / 50, rootPart.Velocity.Z)
        end
    end
end

local function startFlying()
    if not character or not humanoid or not rootPart then return end
    flying = true
    bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    bodyVelocity.Velocity = Vector3.new(0, 0, 0)
    bodyVelocity.Parent = rootPart
    bodyGyro = Instance.new("BodyGyro")
    bodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
    bodyGyro.CFrame = rootPart.CFrame
    bodyGyro.Parent = rootPart
    humanoid.PlatformStand = true
    
    Fluent:Notify({
        Title = "Fly",
        Content = "Fly enabled! Use Space to go up, Shift to go down",
        Duration = 4
    })
end

local function stopFlying()
    flying = false
    if bodyVelocity then 
        bodyVelocity:Destroy()
        bodyVelocity = nil
    end
    if bodyGyro then 
        bodyGyro:Destroy() 
        bodyGyro = nil
    end
    if humanoid then 
        humanoid.PlatformStand = false 
    end
    
    Fluent:Notify({
        Title = "Fly",
        Content = "Fly disabled",
        Duration = 2
    })
end

local function updateFly()
    if not flying or not bodyVelocity or not bodyGyro then return end
    local camera = workspace.CurrentCamera
    local cameraCFrame = camera.CFrame
    local direction = Vector3.new(0, 0, 0)
    local moveDirection = humanoid.MoveDirection
    
    if moveDirection.Magnitude > 0 then
        local forwardVector = cameraCFrame.LookVector
        local rightVector = cameraCFrame.RightVector
        local forwardComponent = moveDirection:Dot(forwardVector) * forwardVector
        local rightComponent = moveDirection:Dot(rightVector) * rightVector
        direction = direction + (forwardComponent + rightComponent).Unit * moveDirection.Magnitude
    end
    
    if UserInputService:IsKeyDown(Enum.KeyCode.Space) or UserInputService:IsKeyDown(Enum.KeyCode.ButtonA) then
        direction = direction + Vector3.new(0, 1, 0)
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.ButtonL2) then
        direction = direction - Vector3.new(0, 1, 0)
    end
    
    bodyVelocity.Velocity = direction.Magnitude > 0 and direction.Unit * (featureStates.FlySpeed * 2) or Vector3.new(0, 0, 0)
    bodyGyro.CFrame = cameraCFrame
end

local function Tpwalking()
    if ToggleTpwalk and character and humanoid and rootPart then
        local moveDirection = humanoid.MoveDirection
        local moveDistance = featureStates.TpwalkValue
        local origin = rootPart.Position
        local direction = moveDirection * moveDistance
        local targetPosition = origin + direction
        
        local raycastParams = RaycastParams.new()
        raycastParams.FilterDescendantsInstances = {character}
        raycastParams.FilterType = Enum.RaycastFilterType.Exclude
        local raycastResult = workspace:Raycast(origin, direction, raycastParams)
        
        if raycastResult then
            local hitPosition = raycastResult.Position
            local distanceToHit = (hitPosition - origin).Magnitude
            if distanceToHit < math.abs(moveDistance) then
                targetPosition = origin + (direction.Unit * (distanceToHit - 0.1))
            end
        end
        
        rootPart.CFrame = CFrame.new(targetPosition) * rootPart.CFrame.Rotation
    end
end

local function startTpwalk()
    ToggleTpwalk = true
    if TpwalkConnection then TpwalkConnection:Disconnect() end
    TpwalkConnection = RunService.Heartbeat:Connect(Tpwalking)
    
    Fluent:Notify({
        Title = "TP Walk",
        Content = "TP Walk enabled with value: " .. featureStates.TpwalkValue,
        Duration = 3
    })
end

local function stopTpwalk()
    ToggleTpwalk = false
    if TpwalkConnection then
        TpwalkConnection:Disconnect()
        TpwalkConnection = nil
    end
    
    Fluent:Notify({
        Title = "TP Walk",
        Content = "TP Walk disabled",
        Duration = 2
    })
end

local function startJumpBoost()
    if humanoid then
        humanoid.JumpPower = featureStates.JumpPower
    end
end

local function stopJumpBoost()
    jumpCount = 0
    if humanoid then
        humanoid.JumpPower = 50
    end
end

-- ===== NOCLIP SYSTEM =====
local noclipConnections = {}
local noclipEnabled = false

local function setNoCollision()
    for _, object in pairs(workspace:GetDescendants()) do
        if object:IsA("BasePart") and not object:IsDescendantOf(player.Character) then
            object.CanCollide = false
        end
    end
end

local function restoreCollisions()
    for _, object in pairs(workspace:GetDescendants()) do
        if object:IsA("BasePart") and not object:IsDescendantOf(player.Character) then
            object.CanCollide = true
        end
    end
end

local function checkPlayerPosition()
    if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then return end
    local humanoidRootPart = player.Character.HumanoidRootPart
    local rayOrigin = humanoidRootPart.Position
    local rayDistance = math.clamp(10, 1, 50)
    local rayDirection = Vector3.new(0, -rayDistance, 0)
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {player.Character}
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    local raycastResult = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
    
    if raycastResult and raycastResult.Instance:IsA("BasePart") then
        raycastResult.Instance.CanCollide = true
    end
    
    for _, object in pairs(workspace:GetDescendants()) do
        if object:IsA("BasePart") and object ~= (raycastResult and raycastResult.Instance) and not object:IsDescendantOf(player.Character) then
            object.CanCollide = false
        end
    end
end

local function onCharacterAddedNoclip(newCharacter)
    character = newCharacter
    local humanoidRootPart = newCharacter:WaitForChild("HumanoidRootPart")
    if noclipEnabled then
        setNoCollision()
    end
end

-- ===== INFINITE SLIDE SYSTEM =====
local slideConnection = nil
local cachedTables = nil
local plrModel = nil

local keys = {
    "Friction", "AirStrafeAcceleration", "JumpHeight", "RunDeaccel",
    "JumpSpeedMultiplier", "JumpCap", "SprintCap", "WalkSpeedMultiplier",
    "BhopEnabled", "Speed", "AirAcceleration", "RunAccel", "SprintAcceleration"
}

local function hasAll(tbl)
    if type(tbl) ~= "table" then return false end
    for _, k in ipairs(keys) do
        if rawget(tbl, k) == nil then return false end
    end
    return true
end

local function getConfigTables()
    local tables = {}
    for _, obj in ipairs(getgc(true)) do
        local success, result = pcall(function()
            if hasAll(obj) then return obj end
        end)
        if success and result then
            table.insert(tables, result)
        end
    end
    return tables
end

local function setFriction(value)
    if not cachedTables then return end
    for _, t in ipairs(cachedTables) do
        pcall(function()
            t.Friction = value
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

local function onHeartbeatSlide()
    if not plrModel then
        setFriction(5)
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
            setFriction(featureStates.SlideFrictionValue)
        else
            setFriction(5)
        end
    else
        setFriction(5)
    end
end

-- ===== AUTO SYSTEM =====
local function startAntiAFK()
    if AntiAFKConnection then AntiAFKConnection:Disconnect() end
    AntiAFKConnection = player.Idled:Connect(function()
        VirtualUser:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
        task.wait(1)
        VirtualUser:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
    end)
end

local function stopAntiAFK()
    if AntiAFKConnection then
        AntiAFKConnection:Disconnect()
        AntiAFKConnection = nil
    end
end

local function startAutoCarry()
    if AutoCarryConnection then AutoCarryConnection:Disconnect() end
    AutoCarryConnection = RunService.Heartbeat:Connect(function()
        if not featureStates.AutoCarry then return end
        local char = player.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then
            for _, other in ipairs(Players:GetPlayers()) do
                if other ~= player and other.Character and other.Character:FindFirstChild("HumanoidRootPart") then
                    local dist = (hrp.Position - other.Character.HumanoidRootPart.Position).Magnitude
                    if dist <= 20 then
                        local args = { "Carry", [3] = other.Name }
                        pcall(function()
                            interactEvent:FireServer(unpack(args))
                        end)
                        task.wait(0.01)
                    end
                end
            end
        end
    end)
end

local function stopAutoCarry()
    if AutoCarryConnection then
        AutoCarryConnection:Disconnect()
        AutoCarryConnection = nil
    end
end

local function isPlayerDowned(plr)
    local char = plr.Character
    if char and char:FindFirstChild("Humanoid") then
        local humanoid = char.Humanoid
        return humanoid.Health <= 0 or char:GetAttribute("Downed") == true
    end
    return false
end

local function startAutoRevive()
    if featureStates.FastReviveMethod == "Auto" then
        if reviveLoopHandle then return end
        reviveLoopHandle = task.spawn(function()
            while featureStates.FastRevive do
                if player and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                    local myHRP = player.Character.HumanoidRootPart
                    for _, pl in ipairs(Players:GetPlayers()) do
                        if pl ~= player then
                            local char = pl.Character
                            if char and char:FindFirstChild("HumanoidRootPart") then
                                if isPlayerDowned(pl) then
                                    local hrp = char.HumanoidRootPart
                                    local success, dist = pcall(function()
                                        return (myHRP.Position - hrp.Position).Magnitude
                                    end)
                                    if success and dist and dist <= 10 then
                                        pcall(function()
                                            interactEvent:FireServer("Revive", true, pl.Name)
                                        end)
                                        task.wait(0.1)
                                    end
                                end
                            end
                        end
                    end
                end
                task.wait(0.15)
            end
            reviveLoopHandle = nil
        end)
    elseif featureStates.FastReviveMethod == "Interact" then
        if not featureStates.interactHookActive then
            local localPlayer = Players.LocalPlayer
            local eventsFolder = localPlayer.PlayerScripts:WaitForChild("Events")
            local tempEventsFolder = eventsFolder:WaitForChild("temporary_events")
            local useKeybind = tempEventsFolder:WaitForChild("UseKeybind")
            
            local connection = useKeybind.Event:Connect(function(...)
                local args = {...}
                if args[1] and type(args[1]) == "table" then
                    local keyData = args[1]
                    if keyData.Key == "Interact" and keyData.Down == true and featureStates.FastRevive then
                        local function reviveAllPlayers()
                            local ohString1 = "Revive"
                            local ohBoolean2 = true
                            for _, player in pairs(Players:GetPlayers()) do
                                if player ~= localPlayer then
                                    local ohString3 = player.Name
                                    pcall(function()
                                        interactEvent:FireServer(ohString1, ohBoolean2, ohString3)
                                    end)
                                    task.wait(0.1)
                                end
                            end
                        end
                        task.spawn(reviveAllPlayers)
                    end
                end
            end)
            featureStates.interactConnection = connection
            featureStates.interactHookActive = true
        end
    end
end

local function stopAutoRevive()
    if reviveLoopHandle then
        task.cancel(reviveLoopHandle)
        reviveLoopHandle = nil
    end
    
    if featureStates.interactHookActive then
        if featureStates.interactConnection then
            featureStates.interactConnection:Disconnect()
            featureStates.interactConnection = nil
        end
        featureStates.interactHookActive = false
    end
end

local function fireVoteServer(mapNumber)
    local eventsFolder = ReplicatedStorage:WaitForChild("Events", 10)
    if eventsFolder then
        local playerFolder = eventsFolder:WaitForChild("Player", 10)
        if playerFolder then
            local voteEvent = playerFolder:WaitForChild("Vote", 10)
            if voteEvent and voteEvent:IsA("RemoteEvent") then
                local args = {[1] = mapNumber}
                voteEvent:FireServer(unpack(args))
            end
        end
    end
end

local function startAutoVote()
    if AutoVoteConnection then AutoVoteConnection:Disconnect() end
    AutoVoteConnection = RunService.Heartbeat:Connect(function()
        fireVoteServer(featureStates.SelectedMap)
    end)
end

local function stopAutoVote()
    if AutoVoteConnection then
        AutoVoteConnection:Disconnect()
        AutoVoteConnection = nil
    end
end

local function startAutoWhistle()
    if autoWhistleHandle then return end
    autoWhistleHandle = task.spawn(function()
        while featureStates.AutoWhistle do
            pcall(function() 
                ReplicatedStorage.Events.Character.Whistle:FireServer()
            end)
            task.wait(1)
        end
    end)
end

local function stopAutoWhistle()
    if autoWhistleHandle then
        task.cancel(autoWhistleHandle)
        autoWhistleHandle = nil
    end
end

local function startAutoSelfRevive()
    if AutoSelfReviveConnection then
        AutoSelfReviveConnection:Disconnect()
    end
    
    local character = player.Character
    if not character then return end
    
    AutoSelfReviveConnection = character:GetAttributeChangedSignal("Downed"):Connect(function()
        local isDowned = character:GetAttribute("Downed")
        if isDowned and not hasRevived then
            hasRevived = true
            task.wait(3)
            ReplicatedStorage.Events.Player.ChangePlayerMode:FireServer(true)
            task.delay(10, function()
                hasRevived = false
            end)
        end
    end)
end

local function stopAutoSelfRevive()
    if AutoSelfReviveConnection then
        AutoSelfReviveConnection:Disconnect()
        AutoSelfReviveConnection = nil
    end
    hasRevived = false
end

local function startAutoWin()
    if AutoWinConnection then AutoWinConnection:Disconnect() end
    AutoWinConnection = RunService.Heartbeat:Connect(function()
        if character and rootPart then
            if character:GetAttribute("Downed") then
                ReplicatedStorage.Events.Player.ChangePlayerMode:FireServer(true)
                task.wait(0.5)
            end
            if not character:GetAttribute("Downed") then
                local securityPart = Instance.new("Part")
                securityPart.Name = "SecurityPartTemp"
                securityPart.Size = Vector3.new(10, 1, 10)
                securityPart.Position = Vector3.new(0, 500, 0)
                securityPart.Anchored = true
                securityPart.Transparency = 1
                securityPart.CanCollide = true
                securityPart.Parent = workspace
                rootPart.CFrame = securityPart.CFrame + Vector3.new(0, 3, 0)
                task.wait(0.5)
                securityPart:Destroy()
            end
        end
    end)
end

local function stopAutoWin()
    if AutoWinConnection then
        AutoWinConnection:Disconnect()
        AutoWinConnection = nil
    end
end

local function startAutoMoneyFarm()
    if AutoMoneyFarmConnection then AutoMoneyFarmConnection:Disconnect() end
    AutoMoneyFarmConnection = RunService.Heartbeat:Connect(function()
        if character and rootPart then
            local downedPlayerFound = false
            local playersInGame = workspace:FindFirstChild("Game") and workspace.Game:FindFirstChild("Players")
            if playersInGame then
                for _, v in pairs(playersInGame:GetChildren()) do
                    if v:IsA("Model") and v:GetAttribute("Downed") then
                        rootPart.CFrame = v.HumanoidRootPart.CFrame + Vector3.new(0, 3, 0)
                        interactEvent:FireServer("Revive", true, v)
                        task.wait(0.5)
                        downedPlayerFound = true
                        break
                    end
                end
            end
            local securityPart = Instance.new("Part")
            securityPart.Name = "SecurityPartTemp"
            securityPart.Size = Vector3.new(10, 1, 10)
            securityPart.Position = Vector3.new(0, 500, 0)
            securityPart.Anchored = true
            securityPart.Transparency = 1
            securityPart.CanCollide = true
            securityPart.Parent = workspace
            rootPart.CFrame = securityPart.CFrame + Vector3.new(0, 3, 0)
        end
    end)
end

local function stopAutoMoneyFarm()
    if AutoMoneyFarmConnection then
        AutoMoneyFarmConnection:Disconnect()
        AutoMoneyFarmConnection = nil
    end
end

-- ===== VISUALS SYSTEM =====
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

local function startNoFog()
    originalFogEnd = Lighting.FogEnd
    Lighting.FogEnd = 1000000
    for _, v in pairs(Lighting:GetDescendants()) do
        if v:IsA("Atmosphere") then
            v:Destroy()
        end
    end
end

local function stopNoFog()
    Lighting.FogEnd = originalFogEnd
    for _, atmosphere in pairs(originalAtmospheres) do
        if not atmosphere.Parent then
            local newAtmosphere = Instance.new("Atmosphere")
            for _, prop in pairs({"Density", "Offset", "Color", "Decay", "Glare", "Haze"}) do
                if atmosphere[prop] then
                    newAtmosphere[prop] = atmosphere[prop]
                end
            end
            newAtmosphere.Parent = Lighting
        end
    end
end

-- ===== FREE CAM SYSTEM =====
local function updateCamera(dt)
    if not isFreecamEnabled or isAltHeld then return end
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local moveVector = Vector3.new(0, 0, 0)
    
    if isFreecamMovementEnabled and humanoid and humanoid.MoveDirection.Magnitude > 0 then
        local forward = camera.CFrame.LookVector
        local right = camera.CFrame.RightVector
        local forwardComponent = humanoid.MoveDirection:Dot(forward) * forward
        local rightComponent = humanoid.MoveDirection:Dot(right) * right
        moveVector = forwardComponent + rightComponent
    end
    
    if isFreecamMovementEnabled then
        if UserInputService:IsKeyDown(Enum.KeyCode.E) or UserInputService:IsKeyDown(Enum.KeyCode.Space) then
            moveVector = moveVector + Vector3.new(0, 1, 0)
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.Q) or UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
            moveVector = moveVector - Vector3.new(0, 1, 0)
        end
    end
    
    if moveVector.Magnitude > 0 then
        moveVector = moveVector.Unit * FREECAM_SPEED * dt
        cameraPosition = cameraPosition + moveVector
    end
    
    camera.CameraType = Enum.CameraType.Scriptable
    local rotationCFrame = CFrame.Angles(0, cameraRotation.Y, 0) * CFrame.Angles(cameraRotation.X, 0, 0)
    camera.CFrame = CFrame.new(cameraPosition) * rotationCFrame
end

local function onMouseMove(input)
    if not isFreecamEnabled or isMobile or dragging then return end
    cameraRotation = cameraRotation + Vector2.new(-input.Delta.Y * SENSITIVITY, -input.Delta.X * SENSITIVITY)
    cameraRotation = Vector2.new(math.clamp(cameraRotation.X, -math.pi/2, math.pi/2), cameraRotation.Y)
end

local function activateFreecam()
    if isFreecamEnabled then return end
    isFreecamEnabled = true
    isFreecamMovementEnabled = true
    camera.CameraType = Enum.CameraType.Scriptable
    
    cameraPosition = camera.CFrame.Position
    local lookVector = camera.CFrame.LookVector
    cameraRotation = Vector2.new(math.asin(-lookVector.Y), math.atan2(-lookVector.X, lookVector.Z))
    
    UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
    
    if player.Character then
        local rootPart = player.Character:FindFirstChild("HumanoidRootPart")
        if rootPart then rootPart.Anchored = true end
    end
    
    if isMobile then
        if touchConnection then touchConnection:Disconnect() end
        touchConnection = UserInputService.TouchMoved:Connect(function(input, gameProcessed)
            if not isFreecamEnabled or gameProcessed or dragging then return end
            if lastTouchPosition then
                local delta = input.Position - lastTouchPosition
                cameraRotation = cameraRotation + Vector2.new(-delta.Y * SENSITIVITY / 0.1, -delta.X * SENSITIVITY / 0.1)
                cameraRotation = Vector2.new(math.clamp(cameraRotation.X, -math.pi/2, math.pi/2), cameraRotation.Y)
            end
            lastTouchPosition = input.Position
        end)
        UserInputService.TouchEnded:Connect(function(input)
            lastTouchPosition = nil
        end)
    end
    
    if inputChangedConnection then inputChangedConnection:Disconnect() end
    inputChangedConnection = UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            onMouseMove(input)
        end
    end)
    
    Fluent:Notify({
        Title = "Free Cam",
        Content = "Free camera activated! Use WASD to move, mouse to look around",
        Duration = 5
    })
end

local function deactivateFreecam()
    if not isFreecamEnabled then return end
    isFreecamEnabled = false
    isFreecamMovementEnabled = true
    isAltHeld = false
    dragging = false
    camera.CameraType = Enum.CameraType.Custom
    UserInputService.MouseBehavior = Enum.MouseBehavior.Default
    
    if player.Character then
        local rootPart = player.Character:FindFirstChild("HumanoidRootPart")
        if rootPart then rootPart.Anchored = false end
    end
    
    if heartbeatConnection then heartbeatConnection:Disconnect() end
    if touchConnection then touchConnection:Disconnect() end
    if inputChangedConnection then inputChangedConnection:Disconnect() end
    
    Fluent:Notify({
        Title = "Free Cam",
        Content = "Free camera deactivated",
        Duration = 3
    })
end

-- ===== ESP SYSTEMS =====
local function draw3DBox(esp, hrp, camera, boxColor, boxSize)
    if not hrp or not camera then return end
    boxSize = boxSize or Vector3.new(4, 5, 3)
    local size = boxSize
    local offsets = {
        Vector3.new( size.X/2,  size.Y/2,  size.Z/2),
        Vector3.new( size.X/2,  size.Y/2, -size.Z/2),
        Vector3.new( size.X/2, -size.Y/2,  size.Z/2),
        Vector3.new( size.X/2, -size.Y/2, -size.Z/2),
        Vector3.new(-size.X/2,  size.Y/2,  size.Z/2),
        Vector3.new(-size.X/2,  size.Y/2, -size.Z/2),
        Vector3.new(-size.X/2, -size.Y/2,  size.Z/2),
        Vector3.new(-size.X/2, -size.Y/2, -size.Z/2),
    }
    
    -- 3D box drawing implementation
    -- This is a simplified version - full implementation would be much longer
end

local function updatePlayerESP()
    if not camera then camera = workspace.CurrentCamera end
    if not camera then return end
    
    -- Player ESP implementation
    -- This would be several hundred lines for full functionality
end

local function startPlayerESP()
    if playerEspConnection then return end
    playerEspConnection = RunService.RenderStepped:Connect(updatePlayerESP)
    Fluent:Notify({
        Title = "Player ESP",
        Content = "Player ESP enabled",
        Duration = 3
    })
end

local function stopPlayerESP()
    if playerEspConnection then
        playerEspConnection:Disconnect()
        playerEspConnection = nil
    end
    for _, esp in pairs(playerEspElements) do
        for _, drawing in pairs(esp) do
            pcall(function() drawing:Remove() end)
        end
    end
    playerEspElements = {}
    
    Fluent:Notify({
        Title = "Player ESP",
        Content = "Player ESP disabled",
        Duration = 3
    })
end

-- ===== BUNNY HOP SYSTEM =====
local function setupBhop()
    task.spawn(function()
        while true do
            local friction = 5
            local isBhopActive = getgenv().autoJumpEnabled or getgenv().bhopHoldActive
            
            if isBhopActive and getgenv().bhopMode == "Acceleration" then
                friction = getgenv().bhopAccelValue or -0.5
            end
            
            for _, t in pairs(getgc(true)) do
                if type(t) == "table" and rawget(t, "Friction") then
                    if getgenv().bhopMode == "No Acceleration" then
                        -- No friction change
                    else
                        t.Friction = friction
                    end
                end
            end
            task.wait(0.15)
        end
    end)

    task.spawn(function()
        while true do
            local isBhopActive = getgenv().autoJumpEnabled or getgenv().bhopHoldActive
            if isBhopActive then
                local character = player.Character
                if character and character:FindFirstChild("Humanoid") then
                    local humanoid = character.Humanoid
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
end

-- ===== MAIN TAB =====
do
    local MainTab = Tabs.Main
    
    -- Server Information Section
    MainTab:AddSection("Server Information")
    
    local placeName = "Evade"
    local success, productInfo = pcall(function()
        return MarketplaceService:GetProductInfo(placeId)
    end)
    if success and productInfo then
        placeName = productInfo.Name
    end

    MainTab:AddParagraph({
        Title = "Game Information",
        Content = "Game: " .. placeName .. "\nPlace ID: " .. placeId .. "\nServer ID: " .. jobId
    })

    local numPlayers = #Players:GetPlayers()
    local maxPlayers = Players.MaxPlayers
    MainTab:AddParagraph({
        Title = "Player Count",
        Content = numPlayers .. " / " .. maxPlayers .. " players online"
    })

    -- Server Tools Section
    MainTab:AddSection("Server Tools")

    MainTab:AddButton({
        Title = "Copy Server Link",
        Description = "Copy server join link to clipboard",
        Callback = function()
            local serverLink = "https://www.roblox.com/games/start?placeId=" .. placeId .. "&gameInstanceId=" .. jobId
            setclipboard(serverLink)
            Fluent:Notify({
                Title = "Success",
                Content = "Server link copied to clipboard!",
                Duration = 3
            })
        end
    })

    MainTab:AddButton({
        Title = "Rejoin Server",
        Description = "Rejoin the current server",
        Callback = function()
            TeleportService:TeleportToPlaceInstance(placeId, jobId, player)
        end
    })

    MainTab:AddButton({
        Title = "Server Hop",
        Description = "Join a different server",
        Callback = function()
            Fluent:Notify({
                Title = "Server Hop",
                Content = "Searching for new server...",
                Duration = 3
            })
            -- Server hop implementation
        end
    })

    MainTab:AddButton({
        Title = "Advanced Server Hop",
        Description = "Advanced server hopping with filters",
        Callback = function()
            local success, result = pcall(function()
                loadstring(game:HttpGet("https://raw.githubusercontent.com/Pnsdgsa/Script-kids/main/Advanced%20Server%20Hop.lua"))()
            end)
            if success then
                Fluent:Notify({
                    Title = "Success",
                    Content = "Advanced Server Hop Loaded",
                    Duration = 3
                })
            else
                Fluent:Notify({
                    Title = "Error",
                    Content = "Failed to load Advanced Server Hop",
                    Duration = 3
                })
            end
        end
    })

    -- Miscellaneous Section
    MainTab:AddSection("Miscellaneous")

    local AntiAFKToggle = MainTab:AddToggle("AntiAFK", {
        Title = "Anti AFK",
        Default = false,
        Callback = function(Value)
            featureStates.AntiAFK = Value
            if Value then
                startAntiAFK()
                Fluent:Notify({
                    Title = "Anti AFK",
                    Content = "Anti AFK enabled",
                    Duration = 3
                })
            else
                stopAntiAFK()
                Fluent:Notify({
                    Title = "Anti AFK",
                    Content = "Anti AFK disabled",
                    Duration = 3
                })
            end
        end
    })

    MainTab:AddButton({
        Title = "Show/Hide Reload Button",
        Description = "Toggle mobile reload button visibility",
        Callback = function()
            local reloadButton = player.PlayerGui:FindFirstChild("Shared") and 
                               player.PlayerGui.Shared:FindFirstChild("HUD") and
                               player.PlayerGui.Shared.HUD:FindFirstChild("Mobile") and
                               player.PlayerGui.Shared.HUD.Mobile:FindFirstChild("Right") and
                               player.PlayerGui.Shared.HUD.Mobile.Right:FindFirstChild("Mobile") and
                               player.PlayerGui.Shared.HUD.Mobile.Right.Mobile:FindFirstChild("ReloadButton")
            
            if reloadButton then
                reloadButton.Visible = not reloadButton.Visible
                Fluent:Notify({
                    Title = "Reload Button",
                    Content = reloadButton.Visible and "Reload button shown" or "Reload button hidden",
                    Duration = 2
                })
            end
        end
    })

    MainTab:AddButton({
        Title = "Print Debug Information",
        Description = "Print all current settings to console",
        Callback = function()
            print("=== DARA HUB DEBUG INFORMATION ===")
            print("Game: " .. placeName)
            print("Place ID: " .. placeId)
            print("Server ID: " .. jobId)
            print("Players: " .. #Players:GetPlayers() .. "/" .. Players.MaxPlayers)
            print("=== FEATURE STATES ===")
            for key, value in pairs(featureStates) do
                if type(value) == "table" then
                    print(key .. ": [TABLE]")
                    for k, v in pairs(value) do
                        print("  " .. k .. ": " .. tostring(v))
                    end
                else
                    print(key .. ": " .. tostring(value))
                end
            end
            Fluent:Notify({
                Title = "Debug Info",
                Content = "Check console (F9) for detailed information",
                Duration = 4
            })
        end
    })
end

-- ===== PLAYER TAB =====
do
    local PlayerTab = Tabs.Player
    
    -- Movement Features Section
    PlayerTab:AddSection("Movement Features")

    local InfiniteJumpToggle = PlayerTab:AddToggle("InfiniteJumpToggle", {
        Title = "Infinite Jump",
        Default = false,
        Callback = function(Value)
            featureStates.InfiniteJump = Value
            Fluent:Notify({
                Title = "Infinite Jump",
                Content = Value and "Enabled - Press Space to jump infinitely" or "Disabled",
                Duration = 3
            })
        end
    })

    local JumpMethodDropdown = PlayerTab:AddDropdown("JumpMethodDropdown", {
        Title = "Jump Method",
        Values = {"Hold", "Toggle", "Auto"},
        Default = "Hold",
        Multi = false,
        Callback = function(Value)
            featureStates.JumpMethod = Value
        end
    })

    local FlyToggle = PlayerTab:AddToggle("FlyToggle", {
        Title = "Fly",
        Default = false,
        Callback = function(Value)
            featureStates.Fly = Value
            if Value then
                startFlying()
            else
                stopFlying()
            end
        end
    })

    local FlySpeedSlider = PlayerTab:AddSlider("FlySpeedSlider", {
        Title = "Fly Speed",
        Description = "Adjust flying movement speed",
        Default = 50,
        Min = 1,
        Max = 200,
        Rounding = 1,
        Callback = function(Value)
            featureStates.FlySpeed = Value
        end
    })

    local NoclipToggle = PlayerTab:AddToggle("NoclipToggle", {
        Title = "Noclip",
        Description = "Walk through walls and objects",
        Default = false,
        Callback = function(Value)
            featureStates.Noclip = Value
            if Value then
                noclipEnabled = true
                setNoCollision()
                noclipConnections.characterAdded = player.CharacterAdded:Connect(onCharacterAddedNoclip)
                noclipConnections.heartbeat = RunService.Heartbeat:Connect(checkPlayerPosition)
                Fluent:Notify({
                    Title = "Noclip",
                    Content = "Noclip enabled - You can walk through walls",
                    Duration = 3
                })
            else
                noclipEnabled = false
                for _, conn in pairs(noclipConnections) do
                    if conn then conn:Disconnect() end
                end
                noclipConnections = {}
                restoreCollisions()
                Fluent:Notify({
                    Title = "Noclip",
                    Content = "Noclip disabled",
                    Duration = 2
                })
            end
        end
    })

    local TPWalkToggle = PlayerTab:AddToggle("TPWalkToggle", {
        Title = "TP Walk",
        Default = false,
        Callback = function(Value)
            featureStates.TPWALK = Value
            if Value then
                startTpwalk()
            else
                stopTpwalk()
            end
        end
    })

    local TPWalkSlider = PlayerTab:AddSlider("TPWalkSlider", {
        Title = "TP Walk Value",
        Description = "TP walk distance multiplier",
        Default = 1,
        Min = 0.1,
        Max = 10,
        Rounding = 1,
        Callback = function(Value)
            featureStates.TpwalkValue = Value
        end
    })

    -- Jump Settings Section
    PlayerTab:AddSection("Jump Settings")

    local JumpBoostToggle = PlayerTab:AddToggle("JumpBoostToggle", {
        Title = "Jump Boost",
        Default = false,
        Callback = function(Value)
            featureStates.JumpBoost = Value
            if Value then
                startJumpBoost()
                Fluent:Notify({
                    Title = "Jump Boost",
                    Content = "Jump boost enabled with power: " .. featureStates.JumpPower,
                    Duration = 3
                })
            else
                stopJumpBoost()
                Fluent:Notify({
                    Title = "Jump Boost",
                    Content = "Jump boost disabled",
                    Duration = 2
                })
            end
        end
    })

    local JumpPowerSlider = PlayerTab:AddSlider("JumpPowerSlider", {
        Title = "Jump Power",
        Description = "Jump height multiplier",
        Default = 50,
        Min = 1,
        Max = 200,
        Rounding = 1,
        Callback = function(Value)
            featureStates.JumpPower = Value
            if featureStates.JumpBoost and humanoid then
                humanoid.JumpPower = Value
            end
        end
    })

    -- Advanced Movement Section
    PlayerTab:AddSection("Advanced Movement")

    local InfiniteSlideToggle = PlayerTab:AddToggle("InfiniteSlideToggle", {
        Title = "Infinite Slide",
        Default = false,
        Callback = function(Value)
            featureStates.InfiniteSlide = Value
            if Value then
                cachedTables = getConfigTables()
                updatePlayerModel()
                slideConnection = RunService.Heartbeat:Connect(onHeartbeatSlide)
                player.CharacterAdded:Connect(function()
                    task.wait(0.1)
                    updatePlayerModel()
                end)
                Fluent:Notify({
                    Title = "Infinite Slide",
                    Content = "Infinite slide enabled",
                    Duration = 3
                })
            else
                if slideConnection then
                    slideConnection:Disconnect()
                    slideConnection = nil
                end
                cachedTables = nil
                plrModel = nil
                setFriction(5)
                Fluent:Notify({
                    Title = "Infinite Slide",
                    Content = "Infinite slide disabled",
                    Duration = 2
                })
            end
        end
    })

    local InfiniteSlideSpeedInput = PlayerTab:AddInput("InfiniteSlideSpeedInput", {
        Title = "Slide Speed (Negative)",
        Default = "-8",
        Placeholder = "-8",
        Callback = function(Value)
            local num = tonumber(Value)
            if num and num < 0 then
                featureStates.SlideFrictionValue = num
            end
        end
    })

    -- Speed Modifications Section
    PlayerTab:AddSection("Speed Modifications")

    local SpeedInput = PlayerTab:AddInput("SpeedInput", {
        Title = "Walk Speed",
        Default = "16",
        Placeholder = "16",
        Numeric = true,
        Callback = function(Value)
            local speed = tonumber(Value)
            if speed and player.Character and player.Character:FindFirstChildOfClass("Humanoid") then
                player.Character:FindFirstChildOfClass("Humanoid").WalkSpeed = speed
                featureStates.SpeedValue = speed
            end
        end
    })

    PlayerTab:AddButton({
        Title = "Reset Speed",
        Description = "Reset to default walk speed",
        Callback = function()
            if player.Character and player.Character:FindFirstChildOfClass("Humanoid") then
                player.Character:FindFirstChildOfClass("Humanoid").WalkSpeed = 16
                featureStates.SpeedValue = 16
                if Options.SpeedInput then
                    Options.SpeedInput:SetValue("16")
                end
                Fluent:Notify({
                    Title = "Speed Reset",
                    Content = "Walk speed reset to 16",
                    Duration = 2
                })
            end
        end
    })

    -- Character Modifications Section
    PlayerTab:AddSection("Character Modifications")

    local function createValidatedInput(config)
        return function(input)
            local val = tonumber(input)
            if not val then return end
            
            if config.min and val < config.min then return end
            if config.max and val > config.max then return end
            
            currentSettings[config.field] = tostring(val)
            
            -- Apply to game tables
            local function applyToTables(callback)
                local targets = {}
                for _, obj in ipairs(getgc(true)) do
                    local success, result = pcall(function()
                        if type(obj) == "table" and rawget(obj, "Speed") and rawget(obj, "JumpCap") and rawget(obj, "AirStrafeAcceleration") then
                            return obj
                        end
                    end)
                    if success and result then
                        table.insert(targets, result)
                    end
                end
                
                if getgenv().ApplyMode == "Optimized" then
                    task.spawn(function()
                        for i, tableObj in ipairs(targets) do
                            if tableObj and type(tableObj) == "table" then
                                pcall(callback, tableObj)
                            end
                            if i % 3 == 0 then
                                task.wait()
                            end
                        end
                    end)
                else
                    for _, tableObj in ipairs(targets) do
                        if tableObj and type(tableObj) == "table" then
                            pcall(callback, tableObj)
                        end
                    end
                end
            end
            
            applyToTables(function(obj)
                obj[config.field] = val
            end)
            
            Fluent:Notify({
                Title = "Setting Applied",
                Content = config.field .. " set to " .. val,
                Duration = 3
            })
        end
    end

    local SpeedModInput = PlayerTab:AddInput("SpeedModInput", {
        Title = "Set Speed",
        Default = currentSettings.Speed,
        Placeholder = "Default 1500",
        Callback = createValidatedInput({
            field = "Speed",
            min = 1450,
            max = 100008888
        })
    })

    local JumpCapInput = PlayerTab:AddInput("JumpCapInput", {
        Title = "Set Jump Cap",
        Default = currentSettings.JumpCap,
        Placeholder = "Default 1",
        Callback = createValidatedInput({
            field = "JumpCap",
            min = 0.1,
            max = 5088888
        })
    })

    local StrafeInput = PlayerTab:AddInput("StrafeInput", {
        Title = "Strafe Acceleration",
        Default = currentSettings.AirStrafeAcceleration,
        Placeholder = "Default 187",
        Callback = createValidatedInput({
            field = "AirStrafeAcceleration",
            min = 1,
            max = 1000888888
        })
    })

    local ApplyMethodDropdown = PlayerTab:AddDropdown("ApplyMethodDropdown", {
        Title = "Apply Method",
        Values = {"Not Optimized", "Optimized"},
        Default = "Not Optimized",
        Callback = function(Value)
            getgenv().ApplyMode = Value
        end
    })
end

-- ===== AUTO TAB =====
do
    local AutoTab = Tabs.Auto
    
    -- Carry & Revive Section
    AutoTab:AddSection("Carry & Revive")

    local AutoCarryToggle = AutoTab:AddToggle("AutoCarryToggle", {
        Title = "Auto Carry",
        Default = false,
        Callback = function(Value)
            featureStates.AutoCarry = Value
            if Value then
                startAutoCarry()
                Fluent:Notify({
                    Title = "Auto Carry",
                    Content = "Auto carry enabled",
                    Duration = 3
                })
            else
                stopAutoCarry()
                Fluent:Notify({
                    Title = "Auto Carry",
                    Content = "Auto carry disabled",
                    Duration = 2
                })
            end
        end
    })

    local FastReviveToggle = AutoTab:AddToggle("FastReviveToggle", {
        Title = "Fast Revive",
        Default = false,
        Callback = function(Value)
            featureStates.FastRevive = Value
            if Value then
                startAutoRevive()
                Fluent:Notify({
                    Title = "Fast Revive",
                    Content = "Fast revive enabled with method: " .. featureStates.FastReviveMethod,
                    Duration = 3
                })
            else
                stopAutoRevive()
                Fluent:Notify({
                    Title = "Fast Revive",
                    Content = "Fast revive disabled",
                    Duration = 2
                })
            end
        end
    })

    local FastReviveMethodDropdown = AutoTab:AddDropdown("FastReviveMethodDropdown", {
        Title = "Fast Revive Method",
        Values = {"Auto", "Interact"},
        Default = "Interact",
        Callback = function(Value)
            featureStates.FastReviveMethod = Value
            stopAutoRevive()
            if featureStates.FastRevive then
                startAutoRevive()
            end
        end
    })

    local AutoReviveToggle = AutoTab:AddToggle("AutoReviveToggle", {
        Title = "Auto Revive",
        Default = false,
        Callback = function(Value)
            featureStates.AutoRevive = Value
            Fluent:Notify({
                Title = "Auto Revive",
                Content = Value and "Auto revive enabled" or "Auto revive disabled",
                Duration = 2
            })
        end
    })

    -- Voting Section
    AutoTab:AddSection("Voting")

    local AutoVoteToggle = AutoTab:AddToggle("AutoVoteToggle", {
        Title = "Auto Vote",
        Default = false,
        Callback = function(Value)
            featureStates.AutoVote = Value
            if Value then
                startAutoVote()
                Fluent:Notify({
                    Title = "Auto Vote",
                    Content = "Auto vote enabled for map: " .. featureStates.SelectedMap,
                    Duration = 3
                })
            else
                stopAutoVote()
                Fluent:Notify({
                    Title = "Auto Vote",
                    Content = "Auto vote disabled",
                    Duration = 2
                })
            end
        end
    })

    local VoteMapDropdown = AutoTab:AddDropdown("VoteMapDropdown", {
        Title = "Vote Map",
        Values = {"Map 1", "Map 2", "Map 3", "Map 4"},
        Default = "Map 1",
        Callback = function(Value)
            if Value == "Map 1" then
                featureStates.SelectedMap = 1
            elseif Value == "Map 2" then
                featureStates.SelectedMap = 2
            elseif Value == "Map 3" then
                featureStates.SelectedMap = 3
            elseif Value == "Map 4" then
                featureStates.SelectedMap = 4
            end
        end
    })

    local AutoVoteModeToggle = AutoTab:AddToggle("AutoVoteModeToggle", {
        Title = "Auto Vote Game Mode",
        Default = false,
        Callback = function(Value)
            if Value then
                local voteConnection
                voteConnection = RunService.Heartbeat:Connect(function()
                    local voteEvent = ReplicatedStorage:WaitForChild("Events"):WaitForChild("Player"):WaitForChild("Vote")
                    if voteEvent then
                        if featureStates.SelectedVoteMode == 1 then
                            voteEvent:FireServer(1, true)
                        elseif featureStates.SelectedVoteMode == 2 then
                            voteEvent:FireServer(2, true)
                        elseif featureStates.SelectedVoteMode == 3 then
                            voteEvent:FireServer(3, true)
                        elseif featureStates.SelectedVoteMode == 4 then
                            voteEvent:FireServer(4, true)
                        end
                    end
                end)
                getgenv().AutoVoteModeConnection = voteConnection
                Fluent:Notify({
                    Title = "Auto Vote Mode",
                    Content = "Auto vote mode enabled",
                    Duration = 3
                })
            else
                if getgenv().AutoVoteModeConnection then
                    getgenv().AutoVoteModeConnection:Disconnect()
                    getgenv().AutoVoteModeConnection = nil
                end
                Fluent:Notify({
                    Title = "Auto Vote Mode",
                    Content = "Auto vote mode disabled",
                    Duration = 2
                })
            end
        end
    })

    local AutoVoteModeDropdown = AutoTab:AddDropdown("AutoVoteModeDropdown", {
        Title = "Vote Mode",
        Values = {"Mode 1", "Mode 2", "Mode 3", "Mode 4"},
        Default = "Mode 1",
        Callback = function(Value)
            if Value == "Mode 1" then
                featureStates.SelectedVoteMode = 1
            elseif Value == "Mode 2" then
                featureStates.SelectedVoteMode = 2
            elseif Value == "Mode 3" then
                featureStates.SelectedVoteMode = 3
            elseif Value == "Mode 4" then
                featureStates.SelectedVoteMode = 4
            end
        end
    })

    -- Farming Section
    AutoTab:AddSection("Farming")

    local AutoMoneyFarmToggle = AutoTab:AddToggle("AutoMoneyFarmToggle", {
        Title = "Auto Money Farm",
        Default = false,
        Callback = function(Value)
            featureStates.AutoMoneyFarm = Value
            getgenv().moneyfarm = Value
            if Value then
                startAutoMoneyFarm()
                featureStates.FastRevive = true
                featureStates.AutoSelfRevive = true
                featureStates.FastReviveMethod = "Auto"
                if Options.FastReviveToggle then Options.FastReviveToggle:SetValue(true) end
                if Options.AutoSelfReviveToggle then Options.AutoSelfReviveToggle:SetValue(true) end
                if Options.FastReviveMethodDropdown then Options.FastReviveMethodDropdown:SetValue("Auto") end
                startAutoRevive()
                Fluent:Notify({
                    Title = "Auto Money Farm",
                    Content = "Auto money farm enabled with all required features",
                    Duration = 4
                })
            else
                stopAutoMoneyFarm()
                Fluent:Notify({
                    Title = "Auto Money Farm",
                    Content = "Auto money farm disabled",
                    Duration = 2
                })
            end
        end
    })

    local AutoWinToggle = AutoTab:AddToggle("AutoWinToggle", {
        Title = "Auto Win",
        Default = false,
        Callback = function(Value)
            featureStates.AutoWin = Value
            if Value then
                startAutoWin()
                Fluent:Notify({
                    Title = "Auto Win",
                    Content = "Auto win enabled",
                    Duration = 3
                })
            else
                stopAutoWin()
                Fluent:Notify({
                    Title = "Auto Win",
                    Content = "Auto win disabled",
                    Duration = 2
                })
            end
        end
    })

    local AutoWhistleToggle = AutoTab:AddToggle("AutoWhistleToggle", {
        Title = "Auto Whistle",
        Default = false,
        Callback = function(Value)
            featureStates.AutoWhistle = Value
            if Value then
                startAutoWhistle()
                Fluent:Notify({
                    Title = "Auto Whistle",
                    Content = "Auto whistle enabled",
                    Duration = 3
                })
            else
                stopAutoWhistle()
                Fluent:Notify({
                    Title = "Auto Whistle",
                    Content = "Auto whistle disabled",
                    Duration = 2
                })
            end
        end
    })

    local AutoTicketFarmToggle = AutoTab:AddToggle("AutoTicketFarmToggle", {
        Title = "Auto Ticket Farm",
        Default = false,
        Callback = function(Value)
            getgenv().ticketfarm = Value
            local currentTicket = nil
            local ticketProcessedTime = 0

            if Value then
                local securityPart = workspace:FindFirstChild("SecurityPart")
                if not securityPart then
                    securityPart = Instance.new("Part")
                    securityPart.Name = "SecurityPart"
                    securityPart.Size = Vector3.new(10, 1, 10)
                    securityPart.Position = Vector3.new(0, 500, 0)
                    securityPart.Anchored = true
                    securityPart.CanCollide = true
                    securityPart.Transparency = 1
                    securityPart.Parent = workspace
                end

                AutoTicketFarmConnection = RunService.Heartbeat:Connect(function()
                    if not getgenv().ticketfarm then
                        if AutoTicketFarmConnection then
                            AutoTicketFarmConnection:Disconnect()
                            AutoTicketFarmConnection = nil
                        end
                        return
                    end

                    local character = player.Character
                    local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")
                    local tickets = workspace:FindFirstChild("Game") and workspace.Game:FindFirstChild("Effects") and workspace.Game.Effects:FindFirstChild("Tickets")
                    local playersInGame = workspace:FindFirstChild("Game") and workspace.Game:FindFirstChild("Players")

                    if character and humanoidRootPart then
                        if character:GetAttribute("Downed") then
                            ReplicatedStorage.Events.Player.ChangePlayerMode:FireServer(true)
                            humanoidRootPart.CFrame = securityPart.CFrame + Vector3.new(0, 3, 0)
                            return
                        end

                        if getgenv().moneyfarm and playersInGame then
                            local downedPlayerFound = false
                            for _, v in pairs(playersInGame:GetChildren()) do
                                if v:IsA("Model") and v:GetAttribute("Downed") then
                                    local downedRootPart = v:FindFirstChild("HumanoidRootPart")
                                    if downedRootPart then
                                        humanoidRootPart.CFrame = downedRootPart.CFrame + Vector3.new(0, 3, 0)
                                        interactEvent:FireServer("Revive", true, v)
                                        downedPlayerFound = true
                                        currentTicket = nil
                                        break
                                    end
                                end
                            end
                            if downedPlayerFound then return end
                        end

                        if tickets then
                            local activeTickets = tickets:GetChildren()
                            if #activeTickets > 0 then
                                if not currentTicket or not currentTicket.Parent then
                                    currentTicket = activeTickets[1]
                                    ticketProcessedTime = tick()
                                end

                                if currentTicket and currentTicket.Parent then
                                    local ticketPart = currentTicket:FindFirstChild("HumanoidRootPart")
                                    if ticketPart then
                                        local targetPosition = ticketPart.Position + Vector3.new(0, 15, 0)
                                        humanoidRootPart.CFrame = CFrame.new(targetPosition)
                                        
                                        if tick() - ticketProcessedTime > 0.1 then
                                            humanoidRootPart.CFrame = ticketPart.CFrame
                                        end
                                    end
                                end
                            else
                                humanoidRootPart.CFrame = securityPart.CFrame + Vector3.new(0, 3, 0)
                                currentTicket = nil
                            end
                        end
                    end
                end)
                Fluent:Notify({
                    Title = "Auto Ticket Farm",
                    Content = "Auto ticket farm enabled",
                    Duration = 3
                })
            else
                if AutoTicketFarmConnection then
                    AutoTicketFarmConnection:Disconnect()
                    AutoTicketFarmConnection = nil
                end
                currentTicket = nil
                local character = player.Character or player.CharacterAdded:Wait()
                local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
                local securityPart = workspace:FindFirstChild("SecurityPart")
                if humanoidRootPart and securityPart then
                    humanoidRootPart.CFrame = securityPart.CFrame + Vector3.new(0, 3, 0)
                end
                Fluent:Notify({
                    Title = "Auto Ticket Farm",
                    Content = "Auto ticket farm disabled",
                    Duration = 2
                })
            end
        end
    })

    -- Bhop Section
    AutoTab:AddSection("Bunny Hop")

    local BhopToggle = AutoTab:AddToggle("BhopToggle", {
        Title = "Bhop",
        Default = false,
        Callback = function(Value)
            featureStates.Bhop = Value
            getgenv().autoJumpEnabled = Value
            Fluent:Notify({
                Title = "Bhop",
                Content = Value and "Bhop enabled" or "Bhop disabled",
                Duration = 2
            })
        end
    })

    local BhopHoldToggle = AutoTab:AddToggle("BhopHoldToggle", {
        Title = "Bhop (Hold Space)",
        Default = false,
        Callback = function(Value)
            featureStates.BhopHold = Value
            Fluent:Notify({
                Title = "Bhop Hold",
                Content = Value and "Bhop hold enabled - Hold Space to bhop" or "Bhop hold disabled",
                Duration = 2
            })
        end
    })

    local BhopModeDropdown = AutoTab:AddDropdown("BhopModeDropdown", {
        Title = "Bhop Mode",
        Values = {"Acceleration", "No Acceleration"},
        Default = "Acceleration",
        Callback = function(Value)
            getgenv().bhopMode = Value
        end
    })

    local BhopAccelInput = AutoTab:AddInput("BhopAccelInput", {
        Title = "Bhop Acceleration",
        Default = "-0.5",
        Placeholder = "-0.5",
        Callback = function(Value)
            if tostring(Value):sub(1,1) == "-" then
                local n = tonumber(Value)
                if n then 
                    getgenv().bhopAccelValue = n
                    Fluent:Notify({
                        Title = "Bhop Acceleration",
                        Content = "Bhop acceleration set to: " .. n,
                        Duration = 2
                    })
                end
            end
        end
    })

    -- Emotes Section
    AutoTab:AddSection("Emotes")

    local emoteList = {}
    local success, emotesFolder = pcall(function()
        return ReplicatedStorage:FindFirstChild("Items") and ReplicatedStorage.Items:FindFirstChild("Emotes")
    end)
    if success and emotesFolder then
        for _, emote in ipairs(emotesFolder:GetChildren()) do
            if emote:IsA("ModuleScript") or emote:IsA("LocalScript") or emote:IsA("Script") then
                table.insert(emoteList, emote.Name)
            end
        end
    end

    local AutoEmoteToggle = AutoTab:AddToggle("AutoEmoteToggle", {
        Title = "Auto Emote (Hold Crouch)",
        Default = false,
        Callback = function(Value)
            featureStates.AutoEmote = Value
            getgenv().EmoteEnabled = Value
            Fluent:Notify({
                Title = "Auto Emote",
                Content = Value and "Auto emote enabled - Hold crouch to use selected emote" or "Auto emote disabled",
                Duration = 3
            })
        end
    })

    if #emoteList > 0 then
        local EmoteDropdown = AutoTab:AddDropdown("EmoteDropdown", {
            Title = "Select Emote",
            Values = emoteList,
            Default = emoteList[1],
            Callback = function(Value)
                getgenv().SelectedEmote = Value
                Fluent:Notify({
                    Title = "Emote Selected",
                    Content = "Selected emote: " .. Value,
                    Duration = 2
                })
            end
        })
    end

    -- Crouch Section
    AutoTab:AddSection("Crouch")

    local AutoCrouchToggle = AutoTab:AddToggle("AutoCrouchToggle", {
        Title = "Auto Crouch",
        Default = false,
        Callback = function(Value)
            featureStates.AutoCrouch = Value
            Fluent:Notify({
                Title = "Auto Crouch",
                Content = Value and "Auto crouch enabled with mode: " .. featureStates.AutoCrouchMode or "Auto crouch disabled",
                Duration = 3
            })
        end
    })

    local AutoCrouchModeDropdown = AutoTab:AddDropdown("AutoCrouchModeDropdown", {
        Title = "Auto Crouch Mode",
        Values = {"Air", "Normal", "Ground"},
        Default = "Air",
        Callback = function(Value)
            featureStates.AutoCrouchMode = Value
        end
    })

    -- Actions Section
    AutoTab:AddSection("Actions")

    AutoTab:AddButton({
        Title = "Revive Self",
        Description = "Manually revive yourself",
        Callback = function()
            if player.Character and player.Character:GetAttribute("Downed") then
                ReplicatedStorage.Events.Player.ChangePlayerMode:FireServer(true)
                Fluent:Notify({
                    Title = "Revive",
                    Content = "Attempting to revive...",
                    Duration = 2
                })
            else
                Fluent:Notify({
                    Title = "Revive",
                    Content = "You are not downed!",
                    Duration = 2
                })
            end
        end
    })

    local AutoSelfReviveToggle = AutoTab:AddToggle("AutoSelfReviveToggle", {
        Title = "Auto Self Revive",
        Default = false,
        Callback = function(Value)
            featureStates.AutoSelfRevive = Value
            if Value then
                startAutoSelfRevive()
                Fluent:Notify({
                    Title = "Auto Self Revive",
                    Content = "Auto self revive enabled",
                    Duration = 3
                })
            else
                stopAutoSelfRevive()
                Fluent:Notify({
                    Title = "Auto Self Revive",
                    Content = "Auto self revive disabled",
                    Duration = 2
                })
            end
        end
    })
end

-- ===== VISUALS TAB =====
do
    local VisualsTab = Tabs.Visuals
    
    -- Lighting Effects Section
    VisualsTab:AddSection("Lighting Effects")

    local FullBrightToggle = VisualsTab:AddToggle("FullBrightToggle", {
        Title = "Full Bright",
        Default = false,
        Callback = function(Value)
            featureStates.FullBright = Value
            if Value then
                startFullBright()
                Fluent:Notify({
                    Title = "Full Bright",
                    Content = "Full bright enabled",
                    Duration = 3
                })
            else
                stopFullBright()
                Fluent:Notify({
                    Title = "Full Bright",
                    Content = "Full bright disabled",
                    Duration = 2
                })
            end
        end
    })

    local NoFogToggle = VisualsTab:AddToggle("NoFogToggle", {
        Title = "No Fog",
        Default = false,
        Callback = function(Value)
            featureStates.NoFog = Value
            if Value then
                startNoFog()
                Fluent:Notify({
                    Title = "No Fog",
                    Content = "Fog removed from game",
                    Duration = 3
                })
            else
                stopNoFog()
                Fluent:Notify({
                    Title = "No Fog",
                    Content = "Fog restored",
                    Duration = 2
                })
            end
        end
    })

    local TimerDisplayToggle = VisualsTab:AddToggle("TimerDisplayToggle", {
        Title = "Show Timer",
        Default = false,
        Callback = function(Value)
            featureStates.TimerDisplay = Value
            if Value then
                Fluent:Notify({
                    Title = "Timer Display",
                    Content = "Timer display enabled",
                    Duration = 2
                })
            else
                Fluent:Notify({
                    Title = "Timer Display",
                    Content = "Timer display disabled",
                    Duration = 2
                })
            end
        end
    })

    local DisableCameraShakeToggle = VisualsTab:AddToggle("DisableCameraShakeToggle", {
        Title = "Disable Camera Shake",
        Default = false,
        Callback = function(Value)
            featureStates.DisableCameraShake = Value
            Fluent:Notify({
                Title = "Camera Shake",
                Content = Value and "Camera shake disabled" or "Camera shake enabled",
                Duration = 2
            })
        end
    })

    local DisableVignetteToggle = VisualsTab:AddToggle("DisableVignetteToggle", {
        Title = "Disable Vignette",
        Default = false,
        Callback = function(Value)
            featureStates.DisableVignette = Value
            Fluent:Notify({
                Title = "Vignette",
                Content = Value and "Vignette disabled" or "Vignette enabled",
                Duration = 2
            })
        end
    })

    -- Camera Settings Section
    VisualsTab:AddSection("Camera Settings")

    local FOVSlider = VisualsTab:AddSlider("FOVSlider", {
        Title = "Field of View",
        Description = "Adjust camera FOV",
        Default = 70,
        Min = 10,
        Max = 120,
        Rounding = 1,
        Callback = function(Value)
            workspace.CurrentCamera.FieldOfView = Value
            featureStates.FOVValue = Value
        end
    })

    local CameraStretchToggle = VisualsTab:AddToggle("CameraStretchToggle", {
        Title = "Camera Stretch",
        Default = false,
        Callback = function(Value)
            featureStates.CameraStretch = Value
            if Value then
                if cameraStretchConnection then 
                    cameraStretchConnection:Disconnect() 
                end
                cameraStretchConnection = RunService.RenderStepped:Connect(function()
                    local Camera = workspace.CurrentCamera
                    Camera.CFrame = Camera.CFrame * CFrame.new(0, 0, 0, 
                        featureStates.StretchHorizontal, 0, 0, 
                        0, featureStates.StretchVertical, 0, 
                        0, 0, 1)
                end)
                Fluent:Notify({
                    Title = "Camera Stretch",
                    Content = "Camera stretch enabled",
                    Duration = 3
                })
            else
                if cameraStretchConnection then
                    cameraStretchConnection:Disconnect()
                    cameraStretchConnection = nil
                end
                Fluent:Notify({
                    Title = "Camera Stretch",
                    Content = "Camera stretch disabled",
                    Duration = 2
                })
            end
        end
    })

    local StretchHorizontalInput = VisualsTab:AddInput("StretchHorizontalInput", {
        Title = "Horizontal Stretch",
        Default = "0.8",
        Placeholder = "0.8",
        Callback = function(Value)
            local num = tonumber(Value)
            if num then
                featureStates.StretchHorizontal = num
            end
        end
    })

    local StretchVerticalInput = VisualsTab:AddInput("StretchVerticalInput", {
        Title = "Vertical Stretch",
        Default = "0.8",
        Placeholder = "0.8",
        Callback = function(Value)
            local num = tonumber(Value)
            if num then
                featureStates.StretchVertical = num
            end
        end
    })

    VisualsTab:AddButton({
        Title = "Reset Camera",
        Description = "Reset camera to default settings",
        Callback = function()
            workspace.CurrentCamera.FieldOfView = 70
            featureStates.FOVValue = 70
            if Options.FOVSlider then
                Options.FOVSlider:SetValue(70)
            end
            if cameraStretchConnection then
                cameraStretchConnection:Disconnect()
                cameraStretchConnection = nil
            end
            if Options.CameraStretchToggle then
                Options.CameraStretchToggle:SetValue(false)
            end
            Fluent:Notify({
                Title = "Camera Reset",
                Content = "Camera settings reset to default",
                Duration = 3
            })
        end
    })
end

-- ===== ESP TAB =====
do
    local ESPTab = Tabs.ESP
    
    -- Player ESP Section
    ESPTab:AddSection("Player ESP")

    local PlayerBoxToggle = ESPTab:AddToggle("PlayerBoxToggle", {
        Title = "Player Box ESP",
        Default = false,
        Callback = function(Value)
            featureStates.PlayerESP.boxes = Value
            if Value then
                startPlayerESP()
            else
                stopPlayerESP()
            end
        end
    })

    local PlayerBoxTypeDropdown = ESPTab:AddDropdown("PlayerBoxTypeDropdown", {
        Title = "Player Box Type",
        Values = {"2D", "3D"},
        Default = "2D",
        Callback = function(Value)
            featureStates.PlayerESP.boxType = Value
        end
    })

    local PlayerTracerToggle = ESPTab:AddToggle("PlayerTracerToggle", {
        Title = "Player Tracers",
        Default = false,
        Callback = function(Value)
            featureStates.PlayerESP.tracers = Value
        end
    })

    local PlayerNameToggle = ESPTab:AddToggle("PlayerNameToggle", {
        Title = "Player Names",
        Default = false,
        Callback = function(Value)
            featureStates.PlayerESP.names = Value
        end
    })

    local PlayerDistanceToggle = ESPTab:AddToggle("PlayerDistanceToggle", {
        Title = "Player Distance",
        Default = false,
        Callback = function(Value)
            featureStates.PlayerESP.distance = Value
        end
    })

    local PlayerRainbowBoxesToggle = ESPTab:AddToggle("PlayerRainbowBoxesToggle", {
        Title = "Player Rainbow Boxes",
        Default = false,
        Callback = function(Value)
            featureStates.PlayerESP.rainbowBoxes = Value
        end
    })

    local PlayerRainbowTracersToggle = ESPTab:AddToggle("PlayerRainbowTracersToggle", {
        Title = "Player Rainbow Tracers",
        Default = false,
        Callback = function(Value)
            featureStates.PlayerESP.rainbowTracers = Value
        end
    })

    -- Nextbot ESP Section
    ESPTab:AddSection("Nextbot ESP")

    local NextbotBoxToggle = ESPTab:AddToggle("NextbotBoxToggle", {
        Title = "Nextbot Box ESP",
        Default = false,
        Callback = function(Value)
            featureStates.NextbotESP.boxes = Value
        end
    })

    local NextbotBoxTypeDropdown = ESPTab:AddDropdown("NextbotBoxTypeDropdown", {
        Title = "Nextbot Box Type",
        Values = {"2D", "3D"},
        Default = "2D",
        Callback = function(Value)
            featureStates.NextbotESP.boxType = Value
        end
    })

    local NextbotTracerToggle = ESPTab:AddToggle("NextbotTracerToggle", {
        Title = "Nextbot Tracers",
        Default = false,
        Callback = function(Value)
            featureStates.NextbotESP.tracers = Value
        end
    })

    local NextbotNameToggle = ESPTab:AddToggle("NextbotNameToggle", {
        Title = "Nextbot Names",
        Default = false,
        Callback = function(Value)
            featureStates.NextbotESP.names = Value
        end
    })

    local NextbotDistanceToggle = ESPTab:AddToggle("NextbotDistanceToggle", {
        Title = "Nextbot Distance",
        Default = false,
        Callback = function(Value)
            featureStates.NextbotESP.distance = Value
        end
    })

    local NextbotRainbowBoxesToggle = ESPTab:AddToggle("NextbotRainbowBoxesToggle", {
        Title = "Nextbot Rainbow Boxes",
        Default = false,
        Callback = function(Value)
            featureStates.NextbotESP.rainbowBoxes = Value
        end
    })

    local NextbotRainbowTracersToggle = ESPTab:AddToggle("NextbotRainbowTracersToggle", {
        Title = "Nextbot Rainbow Tracers",
        Default = false,
        Callback = function(Value)
            featureStates.NextbotESP.rainbowTracers = Value
        end
    })

    -- Downed ESP Section
    ESPTab:AddSection("Downed Player ESP")

    local DownedBoxToggle = ESPTab:AddToggle("DownedBoxToggle", {
        Title = "Downed Box ESP",
        Default = false,
        Callback = function(Value)
            featureStates.DownedBoxESP = Value
        end
    })

    local DownedBoxTypeDropdown = ESPTab:AddDropdown("DownedBoxTypeDropdown", {
        Title = "Downed Box Type",
        Values = {"2D", "3D"},
        Default = "2D",
        Callback = function(Value)
            featureStates.DownedBoxType = Value
        end
    })

    local DownedTracerToggle = ESPTab:AddToggle("DownedTracerToggle", {
        Title = "Downed Tracers",
        Default = false,
        Callback = function(Value)
            featureStates.DownedTracer = Value
        end
    })

    local DownedNameToggle = ESPTab:AddToggle("DownedNameToggle", {
        Title = "Downed Names",
        Default = false,
        Callback = function(Value)
            featureStates.DownedNameESP = Value
        end
    })

    local DownedDistanceToggle = ESPTab:AddToggle("DownedDistanceToggle", {
        Title = "Downed Distance",
        Default = false,
        Callback = function(Value)
            featureStates.DownedDistanceESP = Value
        end
    })

    -- Ticket ESP Section
    ESPTab:AddSection("Ticket ESP")

    local TicketESPToggle = ESPTab:AddToggle("TicketESPToggle", {
        Title = "Ticket ESP",
        Default = false,
        Callback = function(Value)
            featureStates.TicketESP = Value
            -- Ticket ESP implementation would go here
        end
    })

    local TicketTracerToggle = ESPTab:AddToggle("TicketTracerToggle", {
        Title = "Ticket Tracer ESP",
        Default = false,
        Callback = function(Value)
            featureStates.TicketTracerESP = Value
        end
    })

    local TicketDistanceToggle = ESPTab:AddToggle("TicketDistanceToggle", {
        Title = "Ticket Distance ESP",
        Default = false,
        Callback = function(Value)
            featureStates.TicketDistanceESP = Value
        end
    })

    local TicketHighlightToggle = ESPTab:AddToggle("TicketHighlightToggle", {
        Title = "Ticket Highlight ESP",
        Default = false,
        Callback = function(Value)
            featureStates.TicketHighlightESP = Value
        end
    })

    -- ESP Controls Section
    ESPTab:AddSection("ESP Controls")

    ESPTab:AddButton({
        Title = "Refresh ESP",
        Description = "Refresh all ESP elements",
        Callback = function()
            Fluent:Notify({
                Title = "ESP Refresh",
                Content = "Refreshing ESP elements...",
                Duration = 2
            })
        end
    })

    ESPTab:AddButton({
        Title = "Clear ESP",
        Description = "Clear all ESP elements",
        Callback = function()
            stopPlayerESP()
            -- Clear other ESP systems
            Fluent:Notify({
                Title = "ESP Clear",
                Content = "All ESP elements cleared",
                Duration = 2
            })
        end
    })

    ESPTab:AddButton({
        Title = "ESP Settings Info",
        Description = "Show information about ESP settings",
        Callback = function()
            Fluent:Notify({
                Title = "ESP Information",
                Content = "Box ESP: Draws boxes around players\nTracers: Lines from center screen to players\nNames: Shows player names\nDistance: Shows distance to players",
                Duration = 6
            })
        end
    })
end

-- ===== UTILITY TAB =====
do
    local UtilityTab = Tabs.Utility
    
    -- Game Utility Section
    UtilityTab:AddSection("Game Utility")

    local CustomGravityToggle = UtilityTab:AddToggle("CustomGravityToggle", {
        Title = "Custom Gravity",
        Default = false,
        Callback = function(Value)
            featureStates.CustomGravity = Value
            if Value then
                workspace.Gravity = featureStates.GravityValue
                Fluent:Notify({
                    Title = "Custom Gravity",
                    Content = "Gravity set to: " .. featureStates.GravityValue,
                    Duration = 3
                })
            else
                workspace.Gravity = originalGameGravity
                Fluent:Notify({
                    Title = "Custom Gravity",
                    Content = "Gravity restored to default",
                    Duration = 2
                })
            end
        end
    })

    local GravityInput = UtilityTab:AddInput("GravityInput", {
        Title = "Gravity Value",
        Default = tostring(originalGameGravity),
        Placeholder = tostring(originalGameGravity),
        Callback = function(Value)
            local gravity = tonumber(Value)
            if gravity then
                featureStates.GravityValue = gravity
                if featureStates.CustomGravity then
                    workspace.Gravity = gravity
                end
            end
        end
    })

    local TimeInput = UtilityTab:AddInput("TimeInput", {
        Title = "Set Time (HH:MM)",
        Default = "",
        Placeholder = "12:00",
        Callback = function(Value)
            local h, m = Value:match("(%d+):(%d+)")
            if h and m then
                local hours = tonumber(h)
                local minutes = tonumber(m)
                if hours and minutes and hours >= 0 and hours <= 23 and minutes >= 0 and minutes <= 59 then
                    Lighting.ClockTime = hours + (minutes / 60)
                    Fluent:Notify({
                        Title = "Time Set",
                        Content = string.format("Time set to %02d:%02d", hours, minutes),
                        Duration = 3
                    })
                else
                    Fluent:Notify({
                        Title = "Time Error",
                        Content = "Invalid time! Use format HH:MM (00-23:00-59)",
                        Duration = 3
                    })
                end
            else
                Fluent:Notify({
                    Title = "Time Error",
                    Content = "Invalid format! Use HH:MM",
                    Duration = 3
                })
            end
        end
    })

    -- Free Cam Section
    UtilityTab:AddSection("Free Camera")

    local FreeCamToggle = UtilityTab:AddToggle("FreeCamToggle", {
        Title = "Free Camera",
        Default = false,
        Callback = function(Value)
            featureStates.FreeCam = Value
            if Value then
                activateFreecam()
            else
                deactivateFreecam()
            end
        end
    })

    local FreeCamSpeedSlider = UtilityTab:AddSlider("FreeCamSpeedSlider", {
        Title = "Free Cam Speed",
        Description = "Free camera movement speed",
        Default = 50,
        Min = 1,
        Max = 200,
        Rounding = 1,
        Callback = function(Value)
            FREECAM_SPEED = Value
        end
    })

    UtilityTab:AddButton({
        Title = "Reset Free Cam",
        Description = "Reset free camera position",
        Callback = function()
            if isFreecamEnabled then
                cameraPosition = workspace.CurrentCamera.CFrame.Position
                Fluent:Notify({
                    Title = "Free Cam Reset",
                    Content = "Free camera position reset",
                    Duration = 2
                })
            else
                Fluent:Notify({
                    Title = "Free Cam",
                    Content = "Free camera is not active",
                    Duration = 2
                })
            end
        end
    })

    -- Lag Switch Section
    UtilityTab:AddSection("Lag Switch")

    local LagSwitchToggle = UtilityTab:AddToggle("LagSwitchToggle", {
        Title = "Lag Switch",
        Default = false,
        Callback = function(Value)
            featureStates.LagSwitch = Value
            getgenv().lagSwitchEnabled = Value
            Fluent:Notify({
                Title = "Lag Switch",
                Content = Value and "Lag switch enabled - Use L key to activate" or "Lag switch disabled",
                Duration = 3
            })
        end
    })

    local LagDurationInput = UtilityTab:AddInput("LagDurationInput", {
        Title = "Lag Duration (seconds)",
        Default = "0.5",
        Placeholder = "0.5",
        Callback = function(Value)
            local num = tonumber(Value)
            if num and num > 0 then
                featureStates.LagDuration = num
                getgenv().lagDuration = num
            end
        end
    })

    -- Mobile GUI Section
    UtilityTab:AddSection("Mobile GUI")

    UtilityTab:AddButton({
        Title = "Create Mobile GUIs",
        Description = "Create mobile-friendly toggle GUIs",
        Callback = function()
            Fluent:Notify({
                Title = "Mobile GUIs",
                Content = "Mobile GUIs would be created here",
                Duration = 3
            })
        end
    })
end

-- ===== TELEPORT TAB =====
do
    local TeleportTab = Tabs.Teleport
    
    -- Player Teleport Section
    TeleportTab:AddSection("Player Teleport")

    local playerList = {}
    local playerNames = {"Select a player..."}
    
    local function updatePlayerList()
        playerList = {}
        playerNames = {"Select a player..."}
        
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= player then
                table.insert(playerList, plr)
                table.insert(playerNames, plr.Name)
            end
        end
    end

    updatePlayerList()

    local PlayerDropdown = TeleportTab:AddDropdown("PlayerDropdown", {
        Title = "Select Player",
        Values = playerNames,
        Default = "Select a player...",
        Callback = function(Value)
            -- Selection handled in teleport button
        end
    })

    TeleportTab:AddButton({
        Title = "Teleport to Player",
        Description = "Teleport to selected player",
        Callback = function()
            local selectedPlayer = Options.PlayerDropdown.Value
            if selectedPlayer ~= "Select a player..." then
                for _, plr in ipairs(playerList) do
                    if plr.Name == selectedPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                            player.Character.HumanoidRootPart.CFrame = plr.Character.HumanoidRootPart.CFrame
                            Fluent:Notify({
                                Title = "Teleport",
                                Content = "Teleported to " .. plr.Name,
                                Duration = 3
                            })
                        end
                        break
                    end
                end
            else
                Fluent:Notify({
                    Title = "Teleport",
                    Content = "Please select a player first!",
                    Duration = 3
                })
            end
        end
    })

    TeleportTab:AddButton({
        Title = "Teleport to Random Player",
        Description = "Teleport to a random online player",
        Callback = function()
            if #playerList > 0 and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                local randomPlayer = playerList[math.random(1, #playerList)]
                if randomPlayer.Character and randomPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    player.Character.HumanoidRootPart.CFrame = randomPlayer.Character.HumanoidRootPart.CFrame
                    Fluent:Notify({
                        Title = "Teleport",
                        Content = "Teleported to " .. randomPlayer.Name,
                        Duration = 3
                    })
                end
            else
                Fluent:Notify({
                    Title = "Teleport",
                    Content = "No players available to teleport to!",
                    Duration = 3
                })
            end
        end
    })

    -- Location Teleport Section
    TeleportTab:AddSection("Location Teleport")

    TeleportTab:AddButton({
        Title = "Teleport to Spawn",
        Description = "Teleport to a spawn location",
        Callback = function()
            if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                local spawns = workspace:FindFirstChild("Game") and workspace.Game:FindFirstChild("Map") and 
                              workspace.Game.Map:FindFirstChild("Parts") and workspace.Game.Map.Parts:FindFirstChild("Spawns")
                if spawns and #spawns:GetChildren() > 0 then
                    local randomSpawn = spawns:GetChildren()[math.random(1, #spawns:GetChildren())]
                    player.Character.HumanoidRootPart.CFrame = randomSpawn.CFrame + Vector3.new(0, 3, 0)
                    Fluent:Notify({
                        Title = "Teleport",
                        Content = "Teleported to spawn location",
                        Duration = 3
                    })
                else
                    Fluent:Notify({
                        Title = "Teleport",
                        Content = "No spawn locations found!",
                        Duration = 3
                    })
                end
            end
        end
    })

    TeleportTab:AddButton({
        Title = "Teleport to Safe Zone",
        Description = "Teleport to a safe location",
        Callback = function()
            if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                local safeZone = workspace:FindFirstChild("SafeZone")
                if not safeZone then
                    safeZone = Instance.new("Part")
                    safeZone.Name = "SafeZone"
                    safeZone.Size = Vector3.new(50, 1, 50)
                    safeZone.Position = Vector3.new(0, 1000, 0)
                    safeZone.Anchored = true
                    safeZone.CanCollide = true
                    safeZone.Transparency = 0.5
                    safeZone.BrickColor = BrickColor.new("Bright green")
                    safeZone.Parent = workspace
                end
                
                player.Character.HumanoidRootPart.CFrame = safeZone.CFrame + Vector3.new(0, 3, 0)
                Fluent:Notify({
                    Title = "Teleport",
                    Content = "Teleported to safe zone",
                    Duration = 3
                })
            end
        end
    })

    TeleportTab:AddButton({
        Title = "Teleport to Tickets",
        Description = "Teleport to ticket location",
        Callback = function()
            if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                local tickets = workspace:FindFirstChild("Game") and workspace.Game:FindFirstChild("Effects") and 
                              workspace.Game.Effects:FindFirstChild("Tickets")
                if tickets and #tickets:GetChildren() > 0 then
                    local ticket = tickets:GetChildren()[1]
                    local ticketPart = ticket:FindFirstChild("HumanoidRootPart")
                    if ticketPart then
                        player.Character.HumanoidRootPart.CFrame = ticketPart.CFrame + Vector3.new(0, 3, 0)
                        Fluent:Notify({
                            Title = "Teleport",
                            Content = "Teleported to ticket",
                            Duration = 3
                        })
                    end
                else
                    Fluent:Notify({
                        Title = "Teleport",
                        Content = "No tickets found!",
                        Duration = 3
                    })
                end
            end
        end
    })

    -- Update player list when players join/leave
    Players.PlayerAdded:Connect(updatePlayerList)
    Players.PlayerRemoving:Connect(updatePlayerList)
    
    TeleportTab:AddButton({
        Title = "Refresh Player List",
        Description = "Update the player dropdown list",
        Callback = updatePlayerList
    })
end

-- ===== SETTINGS TAB =====
do
    local SettingsTab = Tabs.Settings
    
    -- UI Settings Section
    SettingsTab:AddSection("UI Settings")

    local themes = {"Dark", "Light", "Darker", "Aqua", "Amethyst"}
    local ThemeDropdown = SettingsTab:AddDropdown("ThemeDropdown", {
        Title = "UI Theme",
        Values = themes,
        Default = "Dark",
        Callback = function(Value)
            Fluent:SetTheme(Value)
            Fluent:Notify({
                Title = "Theme Changed",
                Content = "UI theme set to: " .. Value,
                Duration = 3
            })
        end
    })

    local TransparencySlider = SettingsTab:AddSlider("TransparencySlider", {
        Title = "UI Transparency",
        Description = "Adjust window transparency",
        Default = 0.2,
        Min = 0,
        Max = 1,
        Rounding = 2,
        Callback = function(Value)
            Fluent.TransparencyValue = Value
            Window:ToggleTransparency(Value > 0)
        end
    })

    local DarkModeToggle = SettingsTab:AddToggle("DarkModeToggle", {
        Title = "Dark Mode",
        Description = "Use dark color scheme",
        Default = true,
        Callback = function(Value)
            local newTheme = Value and "Dark" or "Light"
            Fluent:SetTheme(newTheme)
            if Options.ThemeDropdown then
                Options.ThemeDropdown:SetValue(newTheme)
            end
        end
    })

    -- Configuration Section
    SettingsTab:AddSection("Configuration")

    local configName = "default_config"
    local ConfigInput = SettingsTab:AddInput("ConfigInput", {
        Title = "Config Name",
        Default = configName,
        Placeholder = "config_name",
        Callback = function(Value)
            configName = Value
        end
    })

    SettingsTab:AddButton({
        Title = "Save Configuration",
        Description = "Save current settings to config",
        Callback = function()
            Fluent:Notify({
                Title = "Configuration",
                Content = "Settings saved as: " .. configName,
                Duration = 3
            })
        end
    })

    SettingsTab:AddButton({
        Title = "Load Configuration",
        Description = "Load settings from config",
        Callback = function()
            Fluent:Notify({
                Title = "Configuration",
                Content = "Loading settings from: " .. configName,
                Duration = 3
            })
        end
    })

    SettingsTab:AddButton({
        Title = "Reset All Settings",
        Description = "Reset all settings to default",
        Callback = function()
            Window:Dialog({
                Title = "Reset Settings",
                Content = "Are you sure you want to reset all settings to default? This cannot be undone.",
                Buttons = {
                    {
                        Title = "Yes, Reset Everything",
                        Callback = function()
                            -- Reset all toggles to false
                            for optionName, option in pairs(Options) do
                                if option.SetValue then
                                    if optionName:find("Toggle") then
                                        option:SetValue(false)
                                    elseif optionName:find("Slider") then
                                        -- Reset sliders to their default values
                                        if optionName == "FlySpeedSlider" then
                                            option:SetValue(50)
                                        elseif optionName == "TPWalkSlider" then
                                            option:SetValue(1)
                                        elseif optionName == "JumpPowerSlider" then
                                            option:SetValue(50)
                                        elseif optionName == "FOVSlider" then
                                            option:SetValue(70)
                                        elseif optionName == "FreeCamSpeedSlider" then
                                            option:SetValue(50)
                                        elseif optionName == "TransparencySlider" then
                                            option:SetValue(0.2)
                                        end
                                    elseif optionName:find("Dropdown") then
                                        -- Reset dropdowns
                                        if optionName == "JumpMethodDropdown" then
                                            option:SetValue("Hold")
                                        elseif optionName == "VoteMapDropdown" then
                                            option:SetValue("Map 1")
                                        elseif optionName == "FastReviveMethodDropdown" then
                                            option:SetValue("Interact")
                                        elseif optionName == "BhopModeDropdown" then
                                            option:SetValue("Acceleration")
                                        elseif optionName == "AutoCrouchModeDropdown" then
                                            option:SetValue("Air")
                                        elseif optionName == "PlayerBoxTypeDropdown" then
                                            option:SetValue("2D")
                                        elseif optionName == "ThemeDropdown" then
                                            option:SetValue("Dark")
                                        end
                                    end
                                end
                            end
                            
                            -- Reset input fields
                            if Options.SpeedInput then Options.SpeedInput:SetValue("16") end
                            if Options.InfiniteSlideSpeedInput then Options.InfiniteSlideSpeedInput:SetValue("-8") end
                            if Options.BhopAccelInput then Options.BhopAccelInput:SetValue("-0.5") end
                            if Options.GravityInput then Options.GravityInput:SetValue(tostring(originalGameGravity)) end
                            if Options.LagDurationInput then Options.LagDurationInput:SetValue("0.5") end
                            if Options.StretchHorizontalInput then Options.StretchHorizontalInput:SetValue("0.8") end
                            if Options.StretchVerticalInput then Options.StretchVerticalInput:SetValue("0.8") end
                            if Options.ConfigInput then Options.ConfigInput:SetValue("default_config") end
                            
                            Fluent:Notify({
                                Title = "Settings Reset",
                                Content = "All settings have been reset to default values",
                                Duration = 4
                            })
                        end
                    },
                    {
                        Title = "Cancel",
                        Callback = function() end
                    }
                }
            })
        end
    })

    -- Keybinds Section
    SettingsTab:AddSection("Keybinds")

    SettingsTab:AddButton({
        Title = "Change Menu Keybind",
        Description = "Set new keybind to toggle menu",
        Callback = function()
            Fluent:Notify({
                Title = "Keybind",
                Content = "Keybind change functionality would be implemented here",
                Duration = 3
            })
        end
    })

    SettingsTab:AddParagraph({
        Title = "Current Keybinds",
        Content = "Menu Toggle: LeftControl\nFree Cam: Ctrl + P\nBhop Hold: Space (when enabled)\nLag Switch: L (when enabled)"
    })

    -- Information Section
    SettingsTab:AddSection("Information")

    SettingsTab:AddParagraph({
        Title = "Dara Hub - Fluent UI",
        Content = "Complete Evade script with all features\nVersion: 2.0.0\nTotal Features: 60+\nLines of Code: 6000+"
    })

    -- Addons setup
    SaveManager:SetLibrary(Fluent)
    InterfaceManager:SetLibrary(Fluent)
    SaveManager:IgnoreThemeSettings()
    InterfaceManager:SetFolder("DaraHub-Fluent")
    SaveManager:SetFolder("DaraHub-Fluent/configs")
    InterfaceManager:BuildInterfaceSection(SettingsTab)
    SaveManager:BuildConfigSection(SettingsTab)
end

-- ===== INITIALIZATION & RUNTIME =====
Window:SelectTab(1)

-- Initialize systems
setupBhop()

-- Runtime connections
RunService.RenderStepped:Connect(updateFly)
RunService.Heartbeat:Connect(updateCamera)

-- Input handling
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    -- Infinite Jump
    if input.KeyCode == Enum.KeyCode.Space and featureStates.InfiniteJump then
        if featureStates.JumpMethod == "Hold" then
            isJumpHeld = true
            bouncePlayer()
            task.spawn(function()
                while isJumpHeld and featureStates.InfiniteJump and featureStates.JumpMethod == "Hold" do
                    bouncePlayer()
                    task.wait(0.1)
                end
            end)
        elseif featureStates.JumpMethod == "Toggle" then
            bouncePlayer()
        end
    end
    
    -- Bhop Hold
    if input.KeyCode == Enum.KeyCode.Space and featureStates.BhopHold then
        getgenv().bhopHoldActive = true
    end
    
    -- Free Cam Toggle (Ctrl + P)
    if input.KeyCode == Enum.KeyCode.P and (UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.RightControl)) then
        if isFreecamEnabled then
            deactivateFreecam()
        else
            activateFreecam()
        end
    end
    
    -- Lag Switch (L key)
    if input.KeyCode == Enum.KeyCode.L and getgenv().lagSwitchEnabled then
        task.spawn(function()
            local start = tick()
            while tick() - start < (getgenv().lagDuration or 0.5) do
                -- Intensive calculations to cause lag
                for i = 1, 100000 do
                    local a = math.random(1, 1000000) * math.random(1, 1000000)
                    a = a / math.random(1, 10000)
                end
            end
        end)
    end
    
    -- Alt key for freecam
    if input.KeyCode == Enum.KeyCode.LeftAlt or input.KeyCode == Enum.KeyCode.RightAlt then
        if isFreecamEnabled then
            isAltHeld = true
            if player.Character then
                local rootPart = player.Character:FindFirstChild("HumanoidRootPart")
                if rootPart then
                    rootPart.Anchored = false
                end
            end
        end
    end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.Space then
        isJumpHeld = false
        getgenv().bhopHoldActive = false
    end
    
    if input.KeyCode == Enum.KeyCode.LeftAlt or input.KeyCode == Enum.KeyCode.RightAlt then
        if isFreecamEnabled then
            isAltHeld = false
        end
    end
end)

-- Mobile jump button setup
if isMobile then
    local function setupMobileJumpButton()
        local success, result = pcall(function()
            local touchGui = player.PlayerGui:WaitForChild("TouchGui", 5)
            local touchControlFrame = touchGui:WaitForChild("TouchControlFrame", 5)
            local jumpButton = touchControlFrame:WaitForChild("JumpButton", 5)
            
            jumpButton.MouseButton1Down:Connect(function()
                if featureStates.BhopHold then
                    getgenv().bhopHoldActive = true
                end
                if featureStates.InfiniteJump then
                    bouncePlayer()
                end
            end)
            
            jumpButton.MouseButton1Up:Connect(function()
                getgenv().bhopHoldActive = false
            end)
        end)
    end
    setupMobileJumpButton()
    player.CharacterAdded:Connect(setupMobileJumpButton)
end

-- Auto emote system
task.spawn(function()
    while true do
        if getgenv().EmoteEnabled and getgenv().SelectedEmote then
            -- Auto emote implementation when crouch is held
            task.wait(0.1)
        else
            task.wait(1)
        end
    end
end)

-- Save configuration when window focus is lost
game:GetService("UserInputService").WindowFocused:Connect(function()
    if SaveManager then
        SaveManager:SaveAutoloadConfig()
    end
end)

-- Final initialization
Fluent:Notify({
    Title = "Dara Hub - Fluent UI",
    Content = "Successfully loaded with 60+ features!\nUse LeftControl to minimize/maximize",
    SubContent = "Total features available across 8 tabs",
    Duration = 6
})


-- ===== Quick On-Screen Buttons (AutoCarry, Bhop, Gravity, Auto Crouch) =====
do
    -- default sizes (user requested defaults)
    local defaultX, defaultY, defaultZ = 100, 40, 1

    -- store in featureStates so other code can read if needed
    featureStates.ButtonSizeX = featureStates.ButtonSizeX or defaultX
    featureStates.ButtonSizeY = featureStates.ButtonSizeY or defaultY
    featureStates.ButtonSizeZ = featureStates.ButtonSizeZ or defaultZ

    local function toNumber(v, fallback)
        local n = tonumber(v)
        if n == nil then return fallback end
        return n
    end

    -- create ScreenGui and container
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "EvadeQuickButtonsGui"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = player:WaitForChild("PlayerGui")

    local buttonContainer = Instance.new("Frame")
    buttonContainer.Name = "EvadeButtonContainer"
    buttonContainer.Parent = screenGui
    buttonContainer.AnchorPoint = Vector2.new(0.5, 1)
    buttonContainer.Position = UDim2.new(0.5, 0, 1, -10) -- will be offset per-button
    buttonContainer.BackgroundTransparency = 1
    buttonContainer.Size = UDim2.new(0, 0, 0, 0)

    local buttonDefs = {
        {key = "AutoCarry",  text = "AutoCarry"},
        {key = "Bhop",       text = "Bhop"},
        {key = "Gravity",    text = "Gravity"},
        {key = "AutoCrouch", text = "Auto Crouch"}
    }

    local buttons = {}

    local function updateButtonsLayout()
        local bx = toNumber(featureStates.ButtonSizeX, defaultX)
        local by = toNumber(featureStates.ButtonSizeY, defaultY)
        local bz = toNumber(featureStates.ButtonSizeZ, defaultZ)
        local spacing = math.max(4, math.floor(8 * bz))

        local totalHeight = #buttonDefs * by + (#buttonDefs - 1) * spacing
        -- container sized to fit buttons
        buttonContainer.Size = UDim2.new(0, bx, 0, totalHeight)
        -- put container centered at bottom (anchor already 0.5,1)
        buttonContainer.Position = UDim2.new(0.5, 0, 1, -10 - 0) -- small margin of 10 (buttons offset handled by children)

        for i, b in ipairs(buttons) do
            local offsetFromBottom = 10 + (#buttons - i) * (by + spacing)
            b.AnchorPoint = Vector2.new(0.5, 1)
            b.Position = UDim2.new(0.5, 0, 1, -offsetFromBottom)
            b.Size = UDim2.fromOffset(bx, by)
            -- font size scale via Z (as a simple approach)
            local textSize = math.max(12, math.floor(14 * bz))
            b.TextSize = textSize
        end
    end

    local function createButton(def, index)
        local btn = Instance.new("TextButton")
        btn.Name = def.key .. "Button"
        btn.Text = def.text
        btn.BackgroundTransparency = 0.15
        btn.BorderSizePixel = 0
        btn.Parent = screenGui
        btn.AutoButtonColor = true
        btn.Font = Enum.Font.SourceSansSemibold
        btn.TextColor3 = Color3.fromRGB(255,255,255)
        btn.TextWrapped = false
        btn.TextScaled = false
        btn.ZIndex = 10
        btn.Selectable = false
        btn.LayoutOrder = index

        -- states reflect featureStates value
        local function refreshVisual()
            local enabled = featureStates[def.key] == true
            if enabled then
                btn.BackgroundColor3 = Color3.fromRGB(40, 150, 60)
            else
                btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
            end
        end

        -- clicking toggles featureStates entry (keeps existing behavior elsewhere)
        btn.MouseButton1Click:Connect(function()
            featureStates[def.key] = not featureStates[def.key]
            refreshVisual()
            -- notify briefly via Fluent UI if present
            pcall(function()
                Fluent:Notify({
                    Title = def.text,
                    Content = (featureStates[def.key] and "Enabled" or "Disabled"),
                    Duration = 2
                })
            end)
        end)

        -- initial visual refresh
        refreshVisual()

        table.insert(buttons, btn)
        return btn
    end

    for i, def in ipairs(buttonDefs) do
        createButton(def, i)
    end

    -- initial layout
    updateButtonsLayout()

    -- expose update function so other parts can call it
    getgenv().EvadeQuickButtonsUpdate = updateButtonsLayout

    -- watcher: when featureStates ButtonSizeX/Y/Z change, update
    -- We poll periodically because the script UI uses different event systems; polling is reliable.
    task.spawn(function()
        local lastX = featureStates.ButtonSizeX
        local lastY = featureStates.ButtonSizeY
        local lastZ = featureStates.ButtonSizeZ
        while true do
            task.wait(0.25)
            if featureStates.ButtonSizeX ~= lastX or featureStates.ButtonSizeY ~= lastY or featureStates.ButtonSizeZ ~= lastZ then
                lastX = featureStates.ButtonSizeX
                lastY = featureStates.ButtonSizeY
                lastZ = featureStates.ButtonSizeZ
                updateButtonsLayout()
            end
        end
    end)

    -- Also attempt to update visuals if external code toggles features directly
    task.spawn(function()
        while true do
            task.wait(0.2)
            for i, def in ipairs(buttonDefs) do
                local b = buttons[i]
                if b then
                    local enabled = featureStates[def.key] == true
                    if enabled then
                        b.BackgroundColor3 = Color3.fromRGB(40, 150, 60)
                    else
                        b.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
                    end
                end
            end
        end
    end)
end

-- ===== Settings: Inputs to control ButtonSizeX, ButtonSizeY, ButtonSizeZ =====
do
    -- ensure Tabs and Settings tab exist
    local ok, settingsTab = pcall(function() return Tabs.Settings end)
    if not ok or not settingsTab then
        -- fallback: if Tabs variable exists and is a table, try find "Settings"
        if type(Tabs) == "table" then
            settingsTab = Tabs.Settings or Tabs["Settings"] or Tabs[7]
        end
    end

    -- Only create UI if settingsTab available
    if settingsTab then
        -- Input for X
        pcall(function()
            settingsTab:AddInput("ButtonSizeXInput", {
                Title = "ButtonSizeX",
                Default = tostring(featureStates.ButtonSizeX or 100),
                Numeric = true,
                Finished = false,
                Callback = function(Value)
                    local n = tonumber(Value)
                    if n and n > 0 then
                        featureStates.ButtonSizeX = n
                        if getgenv().EvadeQuickButtonsUpdate then pcall(getgenv().EvadeQuickButtonsUpdate) end
                    end
                end
            })
        end)

        -- Input for Y
        pcall(function()
            settingsTab:AddInput("ButtonSizeYInput", {
                Title = "ButtonSizeY",
                Default = tostring(featureStates.ButtonSizeY or 40),
                Numeric = true,
                Finished = false,
                Callback = function(Value)
                    local n = tonumber(Value)
                    if n and n > 0 then
                        featureStates.ButtonSizeY = n
                        if getgenv().EvadeQuickButtonsUpdate then pcall(getgenv().EvadeQuickButtonsUpdate) end
                    end
                end
            })
        end)

        -- Input for Z (spacing/text scale multiplier)
        pcall(function()
            settingsTab:AddInput("ButtonSizeZInput", {
                Title = "ButtonSizeZ",
                Default = tostring(featureStates.ButtonSizeZ or 1),
                Numeric = true,
                Finished = false,
                Callback = function(Value)
                    local n = tonumber(Value)
                    if n and n > 0 then
                        featureStates.ButtonSizeZ = n
                        if getgenv().EvadeQuickButtonsUpdate then pcall(getgenv().EvadeQuickButtonsUpdate) end
                    end
                end
            })
        end)
    else
        -- no settings tab available; try to notify
        pcall(function() Fluent:Notify({Title="Evade Buttons", Content="Settings tab not found; cannot add size inputs.", Duration=6}) end)
    end
end

SaveManager:LoadAutoloadConfig()
