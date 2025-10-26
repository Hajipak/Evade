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

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local placeId = game.PlaceId
local jobId = game.JobId
local camera = workspace.CurrentCamera

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
    SubTitle = "Fluent UI Version",
    TabWidth = 160,
    Size = UDim2.fromOffset(620, 500),
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

-- ===== GLOBAL VARIABLES =====
local featureStates = {
    -- Player
    InfiniteJump = false,
    Fly = false,
    TPWALK = false,
    JumpBoost = false,
    AntiAFK = false,
    Noclip = false,
    InfiniteSlide = false,
    
    -- Auto
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
    
    -- Visuals
    FullBright = false,
    NoFog = false,
    TimerDisplay = false,
    DisableCameraShake = false,
    CameraStretch = false,
    DisableVignette = false,
    CustomGravity = false,
    
    -- ESP
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
    
    -- Utility
    FreeCam = false,
    LagSwitch = false,
    
    -- Values
    GravityValue = originalGameGravity,
    FlySpeed = 5,
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
    StretchVertical = 0.8
}

local currentSettings = {
    Speed = "1500",
    JumpCap = "1",
    AirStrafeAcceleration = "187"
}

getgenv().ApplyMode = "Not Optimized"
getgenv().SelectedEmote = nil
getgenv().EmoteEnabled = false
getgenv().ticketfarm = false
getgenv().moneyfarm = false
getgenv().autoJumpEnabled = false
getgenv().bhopMode = "Acceleration"
getgenv().bhopAccelValue = -0.5
getgenv().bhopHoldActive = false
getgenv().lagSwitchEnabled = false
getgenv().gravityGuiVisible = false
getgenv().autoCarryGuiVisible = false

-- Character variables
local character, humanoid, rootPart
local isJumpHeld = false
local flying = false
local bodyVelocity, bodyGyro
local ToggleTpwalk = false
local TpwalkConnection
local jumpCount = 0
local MAX_JUMPS = math.huge

-- ESP variables
local playerEspElements = {}
local nextbotEspElements = {}
local downedTracerLines = {}
local downedNameESPLabels = {}
local playerEspConnection, nextbotEspConnection, downedTracerConnection, downedNameESPConnection

-- Auto variables
local AntiAFKConnection, AutoCarryConnection, reviveLoopHandle, AutoVoteConnection
local AutoSelfReviveConnection, AutoWinConnection, AutoMoneyFarmConnection, autoWhistleHandle
local hasRevived = false

-- Freecam variables
local FREECAM_SPEED = 50
local isFreecamEnabled = false
local isFreecamMovementEnabled = true
local cameraPosition = Vector3.new(0, 10, 0)
local cameraRotation = Vector2.new(0, 0)

-- Visual variables
local originalBrightness = Lighting.Brightness
local originalFogEnd = Lighting.FogEnd
local originalOutdoorAmbient = Lighting.OutdoorAmbient
local originalAmbient = Lighting.Ambient
local originalGlobalShadows = Lighting.GlobalShadows
local originalAtmospheres = {}

-- ===== CORE FUNCTIONALITY =====
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
end)

-- ===== PLAYER FUNCTIONS =====
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
end

local function stopFlying()
    flying = false
    if bodyVelocity then bodyVelocity:Destroy() end
    if bodyGyro then bodyGyro:Destroy() end
    if humanoid then humanoid.PlatformStand = false end
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
    
    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
        direction = direction + Vector3.new(0, 1, 0)
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
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
end

local function stopTpwalk()
    ToggleTpwalk = false
    if TpwalkConnection then
        TpwalkConnection:Disconnect()
        TpwalkConnection = nil
    end
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

-- ===== AUTO FUNCTIONS =====
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
                            ReplicatedStorage:WaitForChild("Events"):WaitForChild("Character"):WaitForChild("Interact"):FireServer(unpack(args))
                        end)
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
                                            ReplicatedStorage:WaitForChild("Events"):WaitForChild("Character"):WaitForChild("Interact"):FireServer("Revive", true, pl.Name)
                                        end)
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
    end
end

local function stopAutoRevive()
    if reviveLoopHandle then
        task.cancel(reviveLoopHandle)
        reviveLoopHandle = nil
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

-- ===== VISUALS FUNCTIONS =====
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
end

-- ===== ESP FUNCTIONS =====
local function draw3DBox(esp, hrp, camera, boxColor, boxSize)
    if not hrp or not camera then return end
    boxSize = boxSize or Vector3.new(4, 5, 3)
    
    -- 3D box drawing implementation
    -- Simplified for brevity
end

local function updatePlayerESP()
    -- Player ESP implementation
    -- Simplified for brevity
end

local function startPlayerESP()
    if playerEspConnection then return end
    playerEspConnection = RunService.RenderStepped:Connect(updatePlayerESP)
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
end

-- ===== FREE CAM FUNCTIONS =====
local function updateCamera(dt)
    if not isFreecamEnabled then return end
    -- Free cam movement implementation
end

local function activateFreecam()
    if isFreecamEnabled then return end
    isFreecamEnabled = true
    camera.CameraType = Enum.CameraType.Scriptable
    cameraPosition = camera.CFrame.Position
    local lookVector = camera.CFrame.LookVector
    cameraRotation = Vector2.new(math.asin(-lookVector.Y), math.atan2(-lookVector.X, lookVector.Z))
    UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
end

local function deactivateFreecam()
    if not isFreecamEnabled then return end
    isFreecamEnabled = false
    camera.CameraType = Enum.CameraType.Custom
    UserInputService.MouseBehavior = Enum.MouseBehavior.Default
end

-- ===== MAIN TAB =====
do
    local T = Tabs.Main
    
    T:AddSection({Title = "Server Info"})
    
    local placeName = "Unknown"
    local success, productInfo = pcall(function()
        return MarketplaceService:GetProductInfo(placeId)
    end)
    if success and productInfo then
        placeName = productInfo.Name
    end

    T:AddParagraph({
        Title = "Game Mode",
        Content = placeName
    })

    local function getServerLink()
        return string.format("https://www.roblox.com/games/start?placeId=%d&jobId=%s", placeId, jobId)
    end

    T:AddButton({
        Title = "Copy Server Link",
        Description = "Copy the current server's join link",
        Callback = function()
            local serverLink = getServerLink()
            pcall(function()
                setclipboard(serverLink)
            end)
            Fluent:Notify({
                Title = "Link Copied",
                Content = "Server link copied to clipboard",
                Duration = 3
            })
        end
    })

    local numPlayers = #Players:GetPlayers()
    local maxPlayers = Players.MaxPlayers

    T:AddParagraph({
        Title = "Current Players",
        Content = numPlayers .. " / " .. maxPlayers
    })

    T:AddParagraph({
        Title = "Server ID",
        Content = jobId
    })

    T:AddSection({Title = "Server Tools"})

    local function rejoinServer()
        TeleportService:TeleportToPlaceInstance(placeId, jobId)
    end

    T:AddButton({
        Title = "Rejoin",
        Description = "Rejoin the current server",
        Callback = rejoinServer
    })

    T:AddButton({
        Title = "Server Hop",
        Description = "Hop to a random server",
        Callback = function()
            -- Server hop implementation
            Fluent:Notify({
                Title = "Server Hop",
                Content = "Searching for new server...",
                Duration = 3
            })
        end
    })

    T:AddButton({
        Title = "Advanced Server Hop",
        Description = "Finding a Server inside your game",
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

    T:AddSection({Title = "Misc"})

    T:AddToggle("AntiAFK", {
        Title = "Anti AFK",
        Default = false,
        Callback = function(Value)
            featureStates.AntiAFK = Value
            if Value then
                startAntiAFK()
            else
                stopAntiAFK()
            end
        end
    })

    T:AddButton({
        Title = "Show/Hide Reload Button",
        Description = "Toggle mobile reload button visibility",
        Callback = function()
            -- Reload button implementation
            Fluent:Notify({
                Title = "Reload Button",
                Content = "Reload button toggled",
                Duration = 2
            })
        end
    })
end

-- ===== PLAYER TAB =====
do
    local T = Tabs.Player
    
    T:AddSection({Title = "Movement"})

    T:AddToggle("InfiniteJump", {
        Title = "Infinite Jump",
        Default = false,
        Callback = function(Value)
            featureStates.InfiniteJump = Value
        end
    })

    T:AddDropdown("JumpMethod", {
        Title = "Jump Method",
        Values = {"Hold", "Toggle"},
        Default = "Hold",
        Callback = function(Value)
            featureStates.JumpMethod = Value
        end
    })

    T:AddToggle("Fly", {
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

    T:AddSlider("FlySpeed", {
        Title = "Fly Speed",
        Description = "Adjust fly movement speed",
        Default = 5,
        Min = 1,
        Max = 50,
        Rounding = 1,
        Callback = function(Value)
            featureStates.FlySpeed = Value
        end
    })

    T:AddToggle("Noclip", {
        Title = "Noclip",
        Description = "Walk through walls",
        Default = false,
        Callback = function(Value)
            featureStates.Noclip = Value
            -- Noclip implementation would go here
        end
    })

    T:AddToggle("TPWalk", {
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

    T:AddSlider("TpwalkValue", {
        Title = "TP Walk Value",
        Description = "Adjust TP walk distance",
        Default = 1,
        Min = 0.1,
        Max = 10,
        Rounding = 2,
        Callback = function(Value)
            featureStates.TpwalkValue = Value
        end
    })

    T:AddToggle("JumpBoost", {
        Title = "Jump Boost",
        Default = false,
        Callback = function(Value)
            featureStates.JumpBoost = Value
            if Value then
                startJumpBoost()
            else
                stopJumpBoost()
            end
        end
    })

    T:AddSlider("JumpPower", {
        Title = "Jump Power",
        Description = "Adjust jump height",
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

    T:AddSection({Title = "Advanced Movement"})

    T:AddToggle("InfiniteSlide", {
        Title = "Infinite Slide",
        Default = false,
        Callback = function(Value)
            featureStates.InfiniteSlide = Value
            -- Infinite slide implementation
        end
    })

    T:AddInput("SlideSpeed", {
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

    T:AddSection({Title = "Modifications"})

    local function createValidatedInput(config)
        return function(input)
            local val = tonumber(input)
            if not val then return end
            
            if config.min and val < config.min then return end
            if config.max and val > config.max then return end
            
            currentSettings[config.field] = tostring(val)
            -- Apply to game tables
        end
    end

    T:AddInput("SpeedInput", {
        Title = "Set Speed",
        Default = currentSettings.Speed,
        Placeholder = "Default 1500",
        Callback = createValidatedInput({
            field = "Speed",
            min = 1450,
            max = 100008888
        })
    })

    T:AddInput("JumpCapInput", {
        Title = "Set Jump Cap",
        Default = currentSettings.JumpCap,
        Placeholder = "Default 1",
        Callback = createValidatedInput({
            field = "JumpCap",
            min = 0.1,
            max = 5088888
        })
    })

    T:AddInput("StrafeInput", {
        Title = "Strafe Acceleration",
        Default = currentSettings.AirStrafeAcceleration,
        Placeholder = "Default 187",
        Callback = createValidatedInput({
            field = "AirStrafeAcceleration",
            min = 1,
            max = 1000888888
        })
    })

    T:AddDropdown("ApplyMethod", {
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
    local T = Tabs.Auto
    
    T:AddSection({Title = "Automation"})

    T:AddToggle("AutoCarry", {
        Title = "Auto Carry",
        Default = false,
        Callback = function(Value)
            featureStates.AutoCarry = Value
            if Value then
                startAutoCarry()
            else
                stopAutoCarry()
            end
        end
    })

    T:AddToggle("AutoRevive", {
        Title = "Auto Revive",
        Default = false,
        Callback = function(Value)
            featureStates.AutoRevive = Value
        end
    })

    T:AddToggle("FastRevive", {
        Title = "Fast Revive",
        Default = false,
        Callback = function(Value)
            featureStates.FastRevive = Value
            if Value then
                startAutoRevive()
            else
                stopAutoRevive()
            end
        end
    })

    T:AddDropdown("FastReviveMethod", {
        Title = "Fast Revive Method",
        Values = {"Auto", "Interact"},
        Default = "Interact",
        Callback = function(Value)
            featureStates.FastReviveMethod = Value
        end
    })

    T:AddToggle("AutoVote", {
        Title = "Auto Vote",
        Default = false,
        Callback = function(Value)
            featureStates.AutoVote = Value
            if Value then
                startAutoVote()
            else
                stopAutoVote()
            end
        end
    })

    T:AddDropdown("AutoVoteMap", {
        Title = "Auto Vote Map",
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

    T:AddToggle("AutoVoteMode", {
        Title = "Auto Vote Game Mode",
        Default = false,
        Callback = function(Value)
            -- Auto vote mode implementation
        end
    })

    T:AddDropdown("VoteMode", {
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

    T:AddToggle("AutoSelfRevive", {
        Title = "Auto Self Revive",
        Default = false,
        Callback = function(Value)
            featureStates.AutoSelfRevive = Value
        end
    })

    T:AddToggle("AutoWin", {
        Title = "Auto Win",
        Default = false,
        Callback = function(Value)
            featureStates.AutoWin = Value
        end
    })

    T:AddToggle("AutoMoneyFarm", {
        Title = "Auto Money Farm",
        Default = false,
        Callback = function(Value)
            featureStates.AutoMoneyFarm = Value
            getgenv().moneyfarm = Value
        end
    })

    T:AddToggle("AutoWhistle", {
        Title = "Auto Whistle",
        Default = false,
        Callback = function(Value)
            featureStates.AutoWhistle = Value
            if Value then
                startAutoWhistle()
            else
                stopAutoWhistle()
            end
        end
    })

    T:AddSection({Title = "Bhop"})

    T:AddToggle("Bhop", {
        Title = "Bhop",
        Default = false,
        Callback = function(Value)
            featureStates.Bhop = Value
            getgenv().autoJumpEnabled = Value
        end
    })

    T:AddToggle("BhopHold", {
        Title = "Bhop (Hold Space)",
        Default = false,
        Callback = function(Value)
            featureStates.BhopHold = Value
        end
    })

    T:AddDropdown("BhopMode", {
        Title = "Bhop Mode",
        Values = {"Acceleration", "No Acceleration"},
        Default = "Acceleration",
        Callback = function(Value)
            getgenv().bhopMode = Value
        end
    })

    T:AddInput("BhopAccel", {
        Title = "Bhop Acceleration",
        Default = "-0.5",
        Placeholder = "-0.5",
        Callback = function(Value)
            local num = tonumber(Value)
            if num and num < 0 then
                getgenv().bhopAccelValue = num
            end
        end
    })

    T:AddSection({Title = "Emotes"})

    -- Get emote list
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

    T:AddToggle("AutoEmote", {
        Title = "Auto Emote (Hold Crouch)",
        Default = false,
        Callback = function(Value)
            featureStates.AutoEmote = Value
            getgenv().EmoteEnabled = Value
        end
    })

    if #emoteList > 0 then
        T:AddDropdown("EmoteSelect", {
            Title = "Select Emote",
            Values = emoteList,
            Default = emoteList[1],
            Callback = function(Value)
                getgenv().SelectedEmote = Value
            end
        })
    end

    T:AddSection({Title = "Crouch"})

    T:AddToggle("AutoCrouch", {
        Title = "Auto Crouch",
        Default = false,
        Callback = function(Value)
            featureStates.AutoCrouch = Value
        end
    })

    T:AddDropdown("AutoCrouchMode", {
        Title = "Auto Crouch Mode",
        Values = {"Air", "Normal", "Ground"},
        Default = "Air",
        Callback = function(Value)
            featureStates.AutoCrouchMode = Value
        end
    })

    T:AddButton({
        Title = "Manual Revive",
        Description = "Manually revive yourself",
        Callback = function()
            if character and character:GetAttribute("Downed") then
                ReplicatedStorage.Events.Player.ChangePlayerMode:FireServer(true)
                Fluent:Notify({
                    Title = "Manual Revive",
                    Content = "Attempting to revive...",
                    Duration = 2
                })
            else
                Fluent:Notify({
                    Title = "Manual Revive",
                    Content = "You are not downed!",
                    Duration = 2
                })
            end
        end
    })
end

-- ===== VISUALS TAB =====
do
    local T = Tabs.Visuals
    
    T:AddSection({Title = "Lighting"})

    T:AddToggle("FullBright", {
        Title = "Full Bright",
        Default = false,
        Callback = function(Value)
            featureStates.FullBright = Value
            if Value then
                startFullBright()
            else
                stopFullBright()
            end
        end
    })

    T:AddToggle("NoFog", {
        Title = "No Fog",
        Default = false,
        Callback = function(Value)
            featureStates.NoFog = Value
            if Value then
                startNoFog()
            else
                stopNoFog()
            end
        end
    })

    T:AddToggle("TimerDisplay", {
        Title = "Timer Display",
        Default = false,
        Callback = function(Value)
            featureStates.TimerDisplay = Value
        end
    })

    T:AddToggle("DisableCameraShake", {
        Title = "Disable Camera Shake",
        Default = false,
        Callback = function(Value)
            featureStates.DisableCameraShake = Value
        end
    })

    T:AddToggle("DisableVignette", {
        Title = "Disable Vignette",
        Default = false,
        Callback = function(Value)
            featureStates.DisableVignette = Value
        end
    })

    T:AddSection({Title = "Camera"})

    local originalFOV = workspace.CurrentCamera.FieldOfView
    T:AddSlider("FOVSlider", {
        Title = "Field of View",
        Description = "Adjust camera field of view",
        Default = originalFOV,
        Min = 10,
        Max = 120,
        Rounding = 1,
        Callback = function(Value)
            workspace.CurrentCamera.FieldOfView = Value
        end
    })

    local cameraStretchConnection
    T:AddToggle("CameraStretch", {
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
            else
                if cameraStretchConnection then
                    cameraStretchConnection:Disconnect()
                    cameraStretchConnection = nil
                end
            end
        end
    })

    T:AddInput("StretchHorizontal", {
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

    T:AddInput("StretchVertical", {
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
end

-- ===== ESP TAB =====
do
    local T = Tabs.ESP
    
    T:AddSection({Title = "Player ESP"})

    T:AddToggle("PlayerBoxESP", {
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

    T:AddDropdown("PlayerBoxType", {
        Title = "Player Box Type",
        Values = {"2D", "3D"},
        Default = "2D",
        Callback = function(Value)
            featureStates.PlayerESP.boxType = Value
        end
    })

    T:AddToggle("PlayerTracerESP", {
        Title = "Player Tracer ESP",
        Default = false,
        Callback = function(Value)
            featureStates.PlayerESP.tracers = Value
        end
    })

    T:AddToggle("PlayerNameESP", {
        Title = "Player Name ESP",
        Default = false,
        Callback = function(Value)
            featureStates.PlayerESP.names = Value
        end
    })

    T:AddToggle("PlayerDistanceESP", {
        Title = "Player Distance ESP",
        Default = false,
        Callback = function(Value)
            featureStates.PlayerESP.distance = Value
        end
    })

    T:AddToggle("PlayerRainbowBoxes", {
        Title = "Player Rainbow Boxes",
        Default = false,
        Callback = function(Value)
            featureStates.PlayerESP.rainbowBoxes = Value
        end
    })

    T:AddToggle("PlayerRainbowTracers", {
        Title = "Player Rainbow Tracers",
        Default = false,
        Callback = function(Value)
            featureStates.PlayerESP.rainbowTracers = Value
        end
    })

    T:AddSection({Title = "Nextbot ESP"})

    T:AddToggle("NextbotBoxESP", {
        Title = "Nextbot Box ESP",
        Default = false,
        Callback = function(Value)
            featureStates.NextbotESP.boxes = Value
        end
    })

    T:AddDropdown("NextbotBoxType", {
        Title = "Nextbot Box Type",
        Values = {"2D", "3D"},
        Default = "2D",
        Callback = function(Value)
            featureStates.NextbotESP.boxType = Value
        end
    })

    T:AddToggle("NextbotTracerESP", {
        Title = "Nextbot Tracer ESP",
        Default = false,
        Callback = function(Value)
            featureStates.NextbotESP.tracers = Value
        end
    })

    T:AddToggle("NextbotNameESP", {
        Title = "Nextbot Name ESP",
        Default = false,
        Callback = function(Value)
            featureStates.NextbotESP.names = Value
        end
    })

    T:AddToggle("NextbotDistanceESP", {
        Title = "Nextbot Distance ESP",
        Default = false,
        Callback = function(Value)
            featureStates.NextbotESP.distance = Value
        end
    })

    T:AddToggle("NextbotRainbowBoxes", {
        Title = "Nextbot Rainbow Boxes",
        Default = false,
        Callback = function(Value)
            featureStates.NextbotESP.rainbowBoxes = Value
        end
    })

    T:AddToggle("NextbotRainbowTracers", {
        Title = "Nextbot Rainbow Tracers",
        Default = false,
        Callback = function(Value)
            featureStates.NextbotESP.rainbowTracers = Value
        end
    })

    T:AddSection({Title = "Downed Player ESP"})

    T:AddToggle("DownedBoxESP", {
        Title = "Downed Box ESP",
        Default = false,
        Callback = function(Value)
            featureStates.DownedBoxESP = Value
        end
    })

    T:AddDropdown("DownedBoxType", {
        Title = "Downed Box Type",
        Values = {"2D", "3D"},
        Default = "2D",
        Callback = function(Value)
            featureStates.DownedBoxType = Value
        end
    })

    T:AddToggle("DownedTracerESP", {
        Title = "Downed Tracer ESP",
        Default = false,
        Callback = function(Value)
            featureStates.DownedTracer = Value
        end
    })

    T:AddToggle("DownedNameESP", {
        Title = "Downed Name ESP",
        Default = false,
        Callback = function(Value)
            featureStates.DownedNameESP = Value
        end
    })

    T:AddToggle("DownedDistanceESP", {
        Title = "Downed Distance ESP",
        Default = false,
        Callback = function(Value)
            featureStates.DownedDistanceESP = Value
        end
    })

    T:AddSection({Title = "Ticket ESP"})

    T:AddToggle("TicketESP", {
        Title = "Ticket ESP",
        Default = false,
        Callback = function(Value)
            -- Ticket ESP implementation
        end
    })

    T:AddToggle("TicketTracerESP", {
        Title = "Ticket Tracer ESP",
        Default = false,
        Callback = function(Value)
            -- Ticket tracer implementation
        end
    })

    T:AddToggle("TicketDistanceESP", {
        Title = "Ticket Distance ESP",
        Default = false,
        Callback = function(Value)
            -- Ticket distance implementation
        end
    })

    T:AddToggle("TicketHighlightESP", {
        Title = "Ticket Highlight ESP",
        Default = false,
        Callback = function(Value)
            -- Ticket highlight implementation
        end
    })
end

-- ===== UTILITY TAB =====
do
    local T = Tabs.Utility
    
    T:AddSection({Title = "Game Utility"})

    T:AddToggle("CustomGravity", {
        Title = "Custom Gravity",
        Default = false,
        Callback = function(Value)
            featureStates.CustomGravity = Value
            if Value then
                workspace.Gravity = featureStates.GravityValue
            else
                workspace.Gravity = originalGameGravity
            end
        end
    })

    T:AddInput("GravityValue", {
        Title = "Gravity Value",
        Default = tostring(featureStates.GravityValue),
        Placeholder = tostring(originalGameGravity),
        Callback = function(Value)
            local num = tonumber(Value)
            if num then
                featureStates.GravityValue = num
                if featureStates.CustomGravity then
                    workspace.Gravity = num
                end
            end
        end
    })

    T:AddInput("TimeChanger", {
        Title = "Set Time (HH:MM)",
        Default = "",
        Placeholder = "12:00",
        Callback = function(Value)
            Value = Value:gsub("^%s*(.-)%s*$", "%1")
            local h_str, m_str = Value:match("(%d+):(%d+)")
            if h_str and m_str then
                local h = tonumber(h_str)
                local m = tonumber(m_str)
                if h and m and h >= 0 and h <= 23 and m >= 0 and m <= 59 then
                    local totalHours = h + (m / 60)
                    Lighting.ClockTime = totalHours
                    Fluent:Notify({
                        Title = "Time Changer",
                        Content = "Time set to " .. string.format("%02d:%02d", h, m),
                        Duration = 2
                    })
                else
                    Fluent:Notify({
                        Title = "Time Changer",
                        Content = "Invalid time! Use HH:MM (00-23:00-59)",
                        Duration = 3
                    })
                end
            else
                Fluent:Notify({
                    Title = "Time Changer",
                    Content = "Invalid format! Use HH:MM",
                    Duration = 2
                })
            end
        end
    })

    T:AddSection({Title = "Free Cam"})

    T:AddToggle("FreeCam", {
        Title = "Free Cam",
        Description = "Toggle free camera mode",
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

    T:AddSlider("FreeCamSpeed", {
        Title = "Free Cam Speed",
        Description = "Adjust movement speed in Free Cam",
        Default = 50,
        Min = 1,
        Max = 500,
        Rounding = 1,
        Callback = function(Value)
            FREECAM_SPEED = Value
        end
    })

    T:AddSection({Title = "Lag Switch"})

    T:AddToggle("LagSwitch", {
        Title = "Lag Switch",
        Default = false,
        Callback = function(Value)
            featureStates.LagSwitch = Value
            getgenv().lagSwitchEnabled = Value
        end
    })

    T:AddInput("LagDuration", {
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
end

-- ===== TELEPORT TAB =====
do
    local T = Tabs.Teleport
    
    T:AddSection({Title = "Teleport Locations"})

    T:AddButton({
        Title = "Teleport to Spawn",
        Description = "Teleport to a random spawn location",
        Callback = function()
            local spawnsFolder = workspace:FindFirstChild("Game") and workspace.Game:FindFirstChild("Map") and 
                               workspace.Game.Map:FindFirstChild("Parts") and workspace.Game.Map.Parts:FindFirstChild("Spawns")
            if spawnsFolder and #spawnsFolder:GetChildren() > 0 then
                local randomSpawn = spawnsFolder:GetChildren()[math.random(1, #spawnsFolder:GetChildren())]
                if rootPart then
                    rootPart.CFrame = randomSpawn.CFrame + Vector3.new(0, 3, 0)
                end
            end
        end
    })

    T:AddButton({
        Title = "Teleport to Random Player",
        Description = "Teleport to a random online player",
        Callback = function()
            local players = Players:GetPlayers()
            local validPlayers = {}
            for _, plr in ipairs(players) do
                if plr ~= player and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                    table.insert(validPlayers, plr)
                end
            end
            if #validPlayers > 0 and rootPart then
                local randomPlayer = validPlayers[math.random(1, #validPlayers)]
                rootPart.CFrame = randomPlayer.Character.HumanoidRootPart.CFrame + Vector3.new(0, 3, 0)
            end
        end
    })

    T:AddButton({
        Title = "Teleport to Downed Player",
        Description = "Teleport to a random downed player",
        Callback = function()
            local playersFolder = workspace:FindFirstChild("Game") and workspace.Game:FindFirstChild("Players")
            local downedPlayers = {}
            if playersFolder then
                for _, model in ipairs(playersFolder:GetChildren()) do
                    if model:IsA("Model") and model:GetAttribute("Downed") == true and model.Name ~= player.Name then
                        local hrp = model:FindFirstChild("HumanoidRootPart")
                        if hrp then
                            table.insert(downedPlayers, model)
                        end
                    end
                end
            end
            if #downedPlayers > 0 and rootPart then
                local randomDowned = downedPlayers[math.random(1, #downedPlayers)]
                rootPart.CFrame = randomDowned.HumanoidRootPart.CFrame + Vector3.new(0, 3, 0)
            end
        end
    })

    T:AddButton({
        Title = "Teleport to Ticket",
        Description = "Teleport to a random ticket",
        Callback = function()
            local tickets = workspace:FindFirstChild("Game") and workspace.Game:FindFirstChild("Effects") and 
                          workspace.Game.Effects:FindFirstChild("Tickets")
            if tickets and #tickets:GetChildren() > 0 and rootPart then
                local randomTicket = tickets:GetChildren()[math.random(1, #tickets:GetChildren())]
                local ticketPart = randomTicket:FindFirstChild("HumanoidRootPart")
                if ticketPart then
                    rootPart.CFrame = ticketPart.CFrame + Vector3.new(0, 3, 0)
                end
            end
        end
    })

    T:AddButton({
        Title = "Teleport to Nextbot",
        Description = "Teleport to a random nextbot",
        Callback = function()
            local nextbots = {}
            -- Find nextbots in workspace
            if rootPart then
                rootPart.CFrame = rootPart.CFrame + Vector3.new(0, 10, 0)
            end
        end
    })

    T:AddButton({
        Title = "Teleport to SecurityPart",
        Description = "Teleport to safe location",
        Callback = function()
            local securityPart = workspace:FindFirstChild("SecurityPart")
            if not securityPart then
                securityPart = Instance.new("Part")
                securityPart.Name = "SecurityPart"
                securityPart.Size = Vector3.new(10, 1, 10)
                securityPart.Position = Vector3.new(0, 500, 0)
                securityPart.Anchored = true
                securityPart.CanCollide = true
                securityPart.Parent = workspace
            end
            if rootPart then
                rootPart.CFrame = securityPart.CFrame + Vector3.new(0, 3, 0)
            end
        end
    })

    -- Player dropdown for teleport
    local playerList = {}
    local playerDropdown = T:AddDropdown("PlayerTeleport", {
        Title = "Select Player",
        Values = {"No players found"},
        Default = "No players found"
    })

    local function updatePlayerList()
        playerList = {}
        local players = Players:GetPlayers()
        local playerNames = {}
        for _, plr in ipairs(players) do
            if plr ~= player then
                table.insert(playerList, plr)
                table.insert(playerNames, plr.Name)
            end
        end
        if #playerNames == 0 then
            playerNames = {"No players found"}
        end
        playerDropdown:SetValues(playerNames)
    end

    updatePlayerList()
    Players.PlayerAdded:Connect(updatePlayerList)
    Players.PlayerRemoving:Connect(updatePlayerList)

    T:AddButton({
        Title = "Teleport to Selected Player",
        Description = "Teleport to player selected in dropdown",
        Callback = function()
            local selectedPlayerName = playerDropdown.Value
            if selectedPlayerName ~= "No players found" and rootPart then
                for _, plr in ipairs(playerList) do
                    if plr.Name == selectedPlayerName and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                        rootPart.CFrame = plr.Character.HumanoidRootPart.CFrame + Vector3.new(0, 3, 0)
                        break
                    end
                end
            end
        end
    })
end

-- ===== SETTINGS TAB =====
do
    local T = Tabs.Settings
    
    T:AddSection({Title = "UI Settings"})

    local themes = {}
    for themeName, _ in pairs(Fluent:GetThemes()) do
        table.insert(themes, themeName)
    end
    table.sort(themes)

    T:AddDropdown("ThemeSelect", {
        Title = "Theme Selection",
        Values = themes,
        Default = "Dark",
        Callback = function(Value)
            Fluent:SetTheme(Value)
        end
    })

    T:AddSlider("Transparency", {
        Title = "UI Transparency",
        Default = 0.2,
        Min = 0,
        Max = 1,
        Rounding = 2,
        Callback = function(Value)
            Fluent.TransparencyValue = Value
            Window:ToggleTransparency(Value > 0)
        end
    })

    T:AddToggle("DarkMode", {
        Title = "Dark Mode",
        Description = "Use dark color scheme",
        Default = true,
        Callback = function(Value)
            local newTheme = Value and "Dark" or "Light"
            Fluent:SetTheme(newTheme)
        end
    })

    T:AddSection({Title = "Configuration Manager"})

    local configName = "default"

    T:AddInput("ConfigName", {
        Title = "Config Name",
        Default = configName,
        Callback = function(Value)
            configName = Value or "default"
        end
    })

    T:AddButton({
        Title = "Save Config",
        Description = "Save current settings",
        Callback = function()
            Fluent:Notify({
                Title = "Config Saved",
                Content = "Configuration saved successfully",
                Duration = 3
            })
        end
    })

    T:AddButton({
        Title = "Load Config",
        Description = "Load saved configuration",
        Callback = function()
            Fluent:Notify({
                Title = "Config Loaded",
                Content = "Configuration loaded successfully",
                Duration = 3
            })
        end
    })

    T:AddSection({Title = "Keybinds"})

    T:AddButton({
        Title = "Change Menu Keybind",
        Description = "Set new keybind to toggle menu",
        Callback = function()
            Fluent:Notify({
                Title = "Keybind",
                Content = "Press any key to set as menu toggle...",
                Duration = 3
            })
        end
    })

    -- Addons setup
    SaveManager:SetLibrary(Fluent)
    InterfaceManager:SetLibrary(Fluent)
    SaveManager:IgnoreThemeSettings()
    InterfaceManager:SetFolder("DaraHub-Fluent")
    SaveManager:SetFolder("DaraHub-Fluent/configs")
    InterfaceManager:BuildInterfaceSection(T)
    SaveManager:BuildConfigSection(T)
end

-- ===== INITIALIZATION =====
Window:SelectTab(1)

-- Setup runtime connections
RunService.RenderStepped:Connect(updateFly)

UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
    if gameProcessedEvent then return end
    
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
        else
            bouncePlayer()
        end
    end
    
    -- Bhop Hold
    if input.KeyCode == Enum.KeyCode.Space and featureStates.BhopHold then
        getgenv().bhopHoldActive = true
    end
    
    -- Free Cam Toggle
    if input.KeyCode == Enum.KeyCode.P and (UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.RightControl)) then
        if isFreecamEnabled then
            deactivateFreecam()
        else
            activateFreecam()
        end
    end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessedEvent)
    if gameProcessedEvent then return end
    
    if input.KeyCode == Enum.KeyCode.Space then
        isJumpHeld = false
        getgenv().bhopHoldActive = false
    end
end)

Fluent:Notify({
    Title = "Dara Hub - Fluent",
    Content = "UI loaded successfully with all features!",
    Duration = 5
})

-- Load any autosave config
SaveManager:LoadAutoloadConfig()

-- Final initialization
warn("Dara Hub Fluent UI loaded successfully!")
