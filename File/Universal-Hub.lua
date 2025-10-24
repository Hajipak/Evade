-- Load WindUI
local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()

-- Localization setup
local Localization = WindUI:Localization({
    Enabled = true,
    Prefix = "loc:",
    DefaultLanguage = "en",
    Translations = {
        ["en"] = {
            ["SCRIPT_TITLE"] = "Dara Hub",
            ["WELCOME"] = "Made by: Pnsdg And Yomka",
            ["FEATURES"] = "Features",
            ["Player_TAB"] = "Player",
            ["VISUALS_TAB"] = "Visuals",
            ["ESP_TAB"] = "ESP",
            ["SETTINGS_TAB"] = "Settings",
            ["MISC_TAB"] = "Misc",
            ["UTILITY_TAB"] = "Utility",
            ["INFINITE_JUMP"] = "Infinite Jump",
            ["JUMP_METHOD"] = "Infinite Jump Method",
            ["FLY"] = "Fly",
            ["FLY_SPEED"] = "Fly Speed",
            ["TPWALK"] = "TP WALK",
            ["TPWALK_VALUE"] = "TPWALK VALUE",
            ["JUMP_HEIGHT"] = "Jump Height",
            ["JUMP_POWER"] = "Jump Height",
            ["ANTI_AFK"] = "Anti AFK",
            ["FULL_BRIGHT"] = "FullBright",
            ["NO_FOG"] = "Remove Fog",
            ["SPEED_HACK"] = "Speed Hack",
            ["PLAYER_NAME_ESP"] = "Player Name ESP",
            ["PLAYER_BOX_ESP"] = "Player Box ESP",
            ["BOX_TYPE"] = "Box Type",
            ["PLAYER_TRACER"] = "Player Tracer",
            ["PLAYER_DISTANCE_ESP"] = "Player Distance ESP",
            ["HIGHLIGHTS"] = "Highlights",
            ["SAVE_CONFIG"] = "Save Configuration",
            ["LOAD_CONFIG"] = "Load Configuration",
            ["THEME_SELECT"] = "Select Theme",
            ["TRANSPARENCY"] = "Window Transparency"
        }
    }
})

-- Set WindUI properties
WindUI.TransparencyValue = 0.2
WindUI:SetTheme("Dark")

-- Create WindUI window
local Window = WindUI:CreateWindow({
    Title = "loc:SCRIPT_TITLE",
    Icon = "rocket",
    Author = "loc:WELCOME",
    Folder = "GameHackUI",
    Size = UDim2.fromOffset(580, 490),
    Theme = "Dark",
    HidePanelBackground = false,
    Acrylic = false,
    HideSearchBar = false,
    SideBarWidth = 200,
    User = {
        Enabled = true,
        Anonymous = true,
        Callback = function()
        end
    }
})

local keybindFile = "keybind_config.txt"

local function getCleanKeyName(keyCode)
    local keyString = tostring(keyCode)
    return keyString:gsub("Enum%.KeyCode%.", "")
end

local function saveKeybind(keyCode)
    writefile(keybindFile, tostring(keyCode))
end

local function loadKeybind()
    if isfile(keybindFile) then
        local savedKey = readfile(keybindFile)
        for _, key in pairs(Enum.KeyCode:GetEnumItems()) do
            if tostring(key) == savedKey then
                return key
            end
        end
    end
    return Enum.KeyCode.RightControl
end

local initialKey = loadKeybind()
local initialKeyName = getCleanKeyName(initialKey)
Window:SetToggleKey(initialKey)

-- Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local MarketplaceService = game:GetService("MarketplaceService")
local VirtualUser = game:GetService("VirtualUser")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")
local originalGameGravity = workspace.Gravity
local player = Players.LocalPlayer
local placeId = game.PlaceId
local jobId = game.JobId
local playerGui = player:WaitForChild("PlayerGui")

-- Fling Features Setup
workspace.FallenPartsDestroyHeight = 0/0
game:GetService("CoreGui").RobloxGui["CoreScripts/NetworkPause"]:Destroy()

local flingActive = false
local hiddenfling = false
local AntiFlingEnabled = false
local AntiKillPartsEnabled = false
local processedPlayers = {}
local currentInput = ""
local SteppedConnection = nil
local isNoclipEnabled = false
local flingMode = 1
local isStrengthened = false
local connections_strength = {}
local originalProperties = {}
local spawnpointActive = false
local savedPosition = nil
local needsRespawn = false
local respawnConnection = nil
local as = false
local XenoAntiFlingEnabled = false
local XenoAntiFlingConnection = nil
local infinitePositionEnabled = false
local savedInfinitePosition = nil
local infinitePositionConnection = nil
local positionTolerance = 0.1
local afdEnabled = false
local afdConnections = {}
local noSitEnabled = false
local movePart = nil
local currentPos = Vector3.new()
local currentYaw = 0
local rotateSmooth = 0.2
local joystickGui = nil
local InvisEnabled = false
local InvisCooldown = false
local InvisSeat = nil
local antiRagdollEnabled = false
local antiRagdollDisconnectFunc = nil
local fpdProtectionEnabled = false
local fpdProtectionConnection = nil
local oldNewIndex = nil
local wasFlingActiveBeforeFPD = false

local localPlayer = Players.LocalPlayer

local featureStates = {
    InfiniteJump = false,
    Fly = false,
    TPWALK = false,
    JumpBoost = false,
    AntiAFK = false,
    FullBright = false,
    NoFog = false,
    SpeedHack = false,
    FlySpeed = 5,
    TpwalkValue = 1,
    JumpPower = 5,
    JumpMethod = "Hold",
    Speed = 16,
    PlayerESP = {
        name = false,
        box = false,
        tracer = false,
        distance = false,
        highlights = false,
        boxType = "2D"
    }
}

local flying = false
local bodyVelocity, bodyGyro
local ToggleTpwalk = false
local TpwalkConnection
local AntiAFKConnection
local isJumpHeld = false
local antiAFKConnection = nil
local playerEspElements = {}
local espConnection

local function getServerLink()
    return "https://www.roblox.com/games/" .. placeId .. "/" .. jobId
end

local function rejoinServer()
    TeleportService:TeleportToPlaceInstance(placeId, jobId, player)
end

local function serverHop()
    local servers = HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. placeId .. "/servers/Public?sortOrder=Asc&limit=100"))
    local randomServer = servers.data[math.random(1, #servers.data)]
    TeleportService:TeleportToPlaceInstance(placeId, randomServer.id, player)
end

local function hopToSmallServer()
    local servers = HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. placeId .. "/servers/Public?sortOrder=Asc&limit=100"))
    table.sort(servers.data, function(a, b) return a.playing < b.playing end)
    if servers.data[1] then
        TeleportService:TeleportToPlaceInstance(placeId, servers.data[1].id, player)
    end
end

local function startAntiAFK()
    if antiAFKConnection then return end
    antiAFKConnection = RunService.Heartbeat:Connect(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end)
end

local function stopAntiAFK()
    if antiAFKConnection then
        antiAFKConnection:Disconnect()
        antiAFKConnection = nil
    end
end

local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")
local camera = workspace.CurrentCamera
local flySpeed = 5

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
    if bodyVelocity then
        bodyVelocity:Destroy()
        bodyVelocity = nil
    end
    if bodyGyro then
        bodyGyro:Destroy()
        bodyGyro = nil
    end
    humanoid.PlatformStand = false
end

local function updateFly()
    if not flying or not bodyVelocity or not bodyGyro then return end
    
    local camCFrame = camera.CFrame
    local direction = Vector3.new(0, 0, 0)
    
    local moveDirection = humanoid.MoveDirection
    if moveDirection.Magnitude > 0 then
        local forwardVector = camCFrame.LookVector
        local rightVector = camCFrame.RightVector
        local forwardComponent = moveDirection:Dot(forwardVector) * forwardVector
        local rightComponent = moveDirection:Dot(rightVector) * rightVector
        direction = direction + (forwardComponent + rightComponent).Unit * moveDirection.Magnitude
    end
    
    if UserInputService:IsKeyDown(Enum.KeyCode.Space) or humanoid.Jump then
        direction = direction + Vector3.new(0, 1, 0)
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
        direction = direction - Vector3.new(0, 1, 0)
    end
    bodyVelocity.Velocity = direction.Magnitude > 0 and direction.Unit * (flySpeed * 16) or Vector3.new(0, 0, 0)
    bodyGyro.CFrame = camCFrame
end

local updateFlyConnection = RunService.RenderStepped:Connect(updateFly)
-- Fling Functions
local function manageStrength(character, enable)
    if not character or not character:IsA("Model") then return end
    
    for _, conn in pairs(connections_strength) do
        conn:Disconnect()
    end
    connections_strength = {}
    
    if enable then
        for _, part in pairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                if not originalProperties[part] then
                    originalProperties[part] = part.CustomPhysicalProperties or PhysicalProperties.new(0.7, 0.3, 0.5)
                end
                
                part.CustomPhysicalProperties = PhysicalProperties.new(100, 0.3, 0.5)
                
                table.insert(connections_strength, part:GetPropertyChangedSignal("CustomPhysicalProperties"):Connect(function()
                    if isStrengthened then
                        local current = part.CustomPhysicalProperties
                        if not current or current.Density < 100 then
                            part.CustomPhysicalProperties = PhysicalProperties.new(100, 0.3, 0.5)
                        end
                    end
                end))
            end
        end
    else
        for part, props in pairs(originalProperties) do
            if part:IsA("BasePart") and part.Parent then
                part.CustomPhysicalProperties = props
            end
        end
        originalProperties = {}
    end
end

local function setupSpawnpoint()
    localPlayer.CharacterAdded:Connect(function(character)
        if not spawnpointActive then return end
        
        local rootPart = character:WaitForChild("HumanoidRootPart", 1)
        if not rootPart then return end
        
        task.wait(0.01)
        
        if savedPosition then
            rootPart.CFrame = savedPosition
            needsRespawn = false
        end
    end)

    RunService.Stepped:Connect(function()
        local character = localPlayer.Character
        if not character then return end
        
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        
        if spawnpointActive and humanoid and humanoid.Health <= 0 then
            if rootPart then
                savedPosition = rootPart.CFrame
                needsRespawn = true
            end
        end
    end)
end

local function dobv(v, char)
    local undo = false
    if as then
        if v:IsA("BodyAngularVelocity") then
            undo = true
            v:Destroy()
        elseif v:IsA("BodyGyro") and v.MaxTorque ~= Vector3.new(8999999488, 8999999488, 8999999488) and v.D ~= 500 and v.D ~= 50 and v.P ~= 90000 then
            undo = true
            v:Destroy()
        elseif v:IsA("BodyVelocity") and v.MaxForce ~= Vector3.new(8999999488, 8999999488, 8999999488) and v.Velocity ~= Vector3.new(0,0,0) then
            undo = true
            v:Destroy()
        elseif v:IsA("BasePart") then
            v.ChildAdded:Connect(function(v2)
                dobv(v2, char)
            end)
        end
        if undo and char and char:FindFirstChild("Humanoid") then
            char.Humanoid.Sit = false
            char.Humanoid.PlatformStand = false
        end
    end
end

local function dc(c)
    for i,v in pairs(c:GetChildren()) do
        dobv(v, c)
        for i,v in pairs(v:GetChildren()) do
            dobv(v, c)
        end
    end
    c.ChildAdded:Connect(function(v)
        dobv(v, c)
    end)
end

local function toggleXenoAntiFling(state)
    XenoAntiFlingEnabled = state
    
    if state then
        XenoAntiFlingConnection = game:GetService("RunService").Stepped:Connect(function()
            pcall(function()
                local players = game:GetService("Players"):GetPlayers()
                local plr = game:GetService("Players").LocalPlayer
                
                for _, p in pairs(players) do
                    if p ~= plr and p.Character then
                        for _, v in pairs(p.Character:GetChildren()) do
                            pcall(function()
                                if v:IsA("BasePart") then
                                    v.CanCollide = false
                                    v.Velocity = Vector3.new(0,0,0)
                                    v.RotVelocity = Vector3.new(0,0,0)
                                    v.CustomPhysicalProperties = PhysicalProperties.new(0,0,0,0,0)
                                    v.Massless = true
                                elseif v:IsA("Accessory") then
                                    v.Handle.CanCollide = false
                                    v.Handle.Velocity = Vector3.new(0,0,0)
                                    v.Handle.RotVelocity = Vector3.new(0,0,0)
                                    v.Handle.CustomPhysicalProperties = PhysicalProperties.new(0,0,0,0,0)
                                    v.Handle.Massless = true
                                end
                            end)
                        end
                    end
                end
            end)
        end)
    else
        if XenoAntiFlingConnection then
            XenoAntiFlingConnection:Disconnect()
            XenoAntiFlingConnection = nil
        end
    end
end

local function handleRespawn()
    if not infinitePositionEnabled or not savedInfinitePosition then return end
    
    local rootPart = localPlayer.Character:WaitForChild("HumanoidRootPart", 1)
    if rootPart then
        task.wait(0.0001)
        rootPart.CFrame = savedInfinitePosition
        rootPart.Velocity = Vector3.new()
        rootPart.RotVelocity = Vector3.new()
    end
end

local function checkPosition()
    if not infinitePositionEnabled or not savedInfinitePosition then return end
    if flingActive then return end
    
    local character = localPlayer.Character
    if not character then return end
    
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end

    if (rootPart.Position - savedInfinitePosition.Position).Magnitude > positionTolerance then
        task.wait(0.0001)
        
        if infinitePositionEnabled and not flingActive and character.Parent and rootPart then
            if (rootPart.Position - savedInfinitePosition.Position).Magnitude > positionTolerance then
                rootPart.CFrame = savedInfinitePosition
                rootPart.Velocity = Vector3.new()
                rootPart.RotVelocity = Vector3.new()
            end
        end
    end
end

local function setupInfinitePosition()
    localPlayer.CharacterAdded:Connect(handleRespawn)
    
    if infinitePositionConnection then
        infinitePositionConnection:Disconnect()
    end
    
    infinitePositionConnection = RunService.Heartbeat:Connect(function()
        if not infinitePositionEnabled then return end
        checkPosition()
    end)
end

local function toggleAFD(state)
    afdEnabled = state
    
    if state then
        local function setupAFD(character)
            if not character then return end
            
            local rootPart = character:WaitForChild("HumanoidRootPart", 1)
            if not rootPart then return end
            
            local connection = game:GetService("RunService").Heartbeat:Connect(function()
                if not rootPart.Parent then
                    connection:Disconnect()
                    return
                end
                local velocity = rootPart.AssemblyLinearVelocity
                rootPart.AssemblyLinearVelocity = Vector3.zero
                game:GetService("RunService").RenderStepped:Wait()
                rootPart.AssemblyLinearVelocity = velocity
            end)
            
            table.insert(afdConnections, connection)
        end
        
        if localPlayer.Character then
            setupAFD(localPlayer.Character)
        end
        
        table.insert(afdConnections, localPlayer.CharacterAdded:Connect(setupAFD))
    else
        for _, conn in ipairs(afdConnections) do
            if conn then
                conn:Disconnect()
            end
        end
        afdConnections = {}
    end
end

local function toggleNoSit(state)
    noSitEnabled = state
    
    local character = localPlayer.Character
    if character then
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            if state then
                humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
                if humanoid.Sit then
                    humanoid.Sit = false
                end
                humanoid.Sit = true
            else
                humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
                humanoid.Sit = false
            end
        end
    end
end


local function toggleInvis(state)
    if InvisCooldown then return end
    InvisCooldown = true
    
    InvisEnabled = state
    local Player = game.Players.LocalPlayer
    local Camera = workspace.CurrentCamera

    if state then
        if not Player.Character or not Player.Character:FindFirstChild("HumanoidRootPart") then
            InvisCooldown = false
            return 
        end
        
        Camera.CameraType = Enum.CameraType.Scriptable
        local SavedPos = Player.Character.HumanoidRootPart.CFrame
        
        Player.Character:MoveTo(Vector3.new(0, -10000, 0))
        wait(0.15)

        InvisSeat = Instance.new('Seat', workspace)
        InvisSeat.Anchored = false
        InvisSeat.CanCollide = false
        InvisSeat.Name = 'InvisChair'
        InvisSeat.Transparency = 1
        InvisSeat.Position = Vector3.new(0, -10000, 0)

        local Weld = Instance.new("Weld", InvisSeat)
        Weld.Part0 = InvisSeat
        Weld.Part1 = Player.Character:FindFirstChild("Torso") or Player.Character:FindFirstChild("UpperTorso")
        
        wait()
        InvisSeat.CFrame = SavedPos
        Camera.CameraType = Enum.CameraType.Custom
        
        local humanoid = Player.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            local deathConnection
            deathConnection = humanoid.Died:Connect(function()
                if InvisEnabled then
                    InvisEnabled = false
                    
                    if InvisSeat then
                        InvisSeat:Destroy()
                        InvisSeat = nil
                    end
                end
                if deathConnection then
                    deathConnection:Disconnect()
                end
            end)
        end
    else
        if InvisSeat then
            local character = Player.Character
            if character and character:FindFirstChild("HumanoidRootPart") then
                character.HumanoidRootPart.CFrame = InvisSeat.CFrame
            end
            InvisSeat:Destroy()
            InvisSeat = nil
        end
    end

    wait(0.1)
    InvisCooldown = false
end

local function createAntiRagdoll(character)
    local connections = {}
    local humanoid = character:WaitForChild("Humanoid")
    
    humanoid.PlatformStand = false
    
    local function onStateChanged(_, newState)
        if newState == Enum.HumanoidStateType.Physics or 
           newState == Enum.HumanoidStateType.FallingDown or 
           newState == Enum.HumanoidStateType.Ragdoll then
            humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
        end
    end
    
    local function onPlatformStandChanged()
        if humanoid.PlatformStand then
            humanoid.PlatformStand = false
        end
    end
    
    table.insert(connections, humanoid.StateChanged:Connect(onStateChanged))
    table.insert(connections, humanoid:GetPropertyChangedSignal("PlatformStand"):Connect(onPlatformStandChanged))
    
    return function()
        for _, connection in ipairs(connections) do
            connection:Disconnect()
        end
        table.clear(connections)
    end
end

local function toggleNoclip(state)
    isNoclipEnabled = state
    
    if state then
        if SteppedConnection then return end
        SteppedConnection = RunService.Stepped:Connect(function()
            local character = localPlayer.Character
            if character then
                for _, v in pairs(character:GetChildren()) do
                    if v:IsA("BasePart") then
                        v.CanCollide = false
                    end
                end
            end
        end)
    else
        if SteppedConnection then
            SteppedConnection:Disconnect()
            SteppedConnection = nil
            local character = localPlayer.Character
            if character then
                for _, v in pairs(character:GetChildren()) do
                    if v:IsA("BasePart") then
                        v.CanCollide = true
                    end
                end
            end
        end
    end
end

local function setCanCollideOfModelDescendants(model, bval)
    if not model then
        return
    end
    for i, v in pairs(model:GetDescendants()) do
        if v:IsA("BasePart") then
            v.CanCollide = bval
        end
    end
end

local function toggleAntiKillParts(state)
    AntiKillPartsEnabled = state
    
    if state then
        coroutine.wrap(function()
            while AntiKillPartsEnabled and task.wait() do
                if localPlayer.Character then
                    local humanoidRootPart = localPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if humanoidRootPart then
                        local parts = workspace:GetPartBoundsInRadius(humanoidRootPart.Position, 10)
                        for _, part in ipairs(parts) do
                            part.CanTouch = false
                        end
                    end
                end
            end
        end)()
    else
        if localPlayer.Character then
            local humanoidRootPart = localPlayer.Character:FindFirstChild("HumanoidRootPart")
            if humanoidRootPart then
                local parts = workspace:GetPartBoundsInRadius(humanoidRootPart.Position, 15000)
                for _, part in ipairs(parts) do
                    part.CanTouch = true
                end
            end
        end
    end
end

local function toggleAntiFling(state)
    AntiFlingEnabled = state
    
    if state then
        for i, v in pairs(Players:GetPlayers()) do
            if v ~= Players.LocalPlayer and v.Character then
                setCanCollideOfModelDescendants(v.Character, false)
            end
        end
    else
        for i, v in pairs(Players:GetPlayers()) do
            if v ~= Players.LocalPlayer and v.Character then
                setCanCollideOfModelDescendants(v.Character, true)
            end
        end
    end
end

local function fling()
    local lp = Players.LocalPlayer
    local c, hrp, vel, movel = nil, nil, nil, 0.1

    while hiddenfling do
        RunService.Heartbeat:Wait()
        c = lp.Character
        hrp = c and c:FindFirstChild("HumanoidRootPart")

        if hrp then
            vel = hrp.Velocity
            hrp.Velocity = vel * 1e35 + Vector3.new(0, 1e35, 0)
            RunService.RenderStepped:Wait()
            hrp.Velocity = vel
            RunService.Stepped:Wait()
            hrp.Velocity = vel + Vector3.new(0, movel, 0)
            movel = -movel
        end
    end
end

local function sortPlayersAlphabetically(players)
    table.sort(players, function(a, b)
        return string.lower(a.Name) < string.lower(b.Name)
    end)
    return players
end

local function SkidFling(TargetPlayer, duration)
    -- Copy the full SkidFling function from the provided code
    local startTime = tick()
    local Character = localPlayer.Character
    local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
    local RootPart = Humanoid and Humanoid.RootPart

    local TCharacter = TargetPlayer.Character
    local THumanoid
    local TRootPart
    local THead
    local Accessory
    local Handle

    if TCharacter:FindFirstChildOfClass("Humanoid") then
        THumanoid = TCharacter:FindFirstChildOfClass("Humanoid")
    end
    if THumanoid and THumanoid.RootPart then
        TRootPart = THumanoid.RootPart
    end
    if TCharacter:FindFirstChild("Head") then
        THead = TCharacter.Head
    end
    if TCharacter:FindFirstChildOfClass("Accessory") then
        Accessory = TCharacter:FindFirstChildOfClass("Accessory")
    end
    if Accessory and Accessory:FindFirstChild("Handle") then
        Handle = Accessory.Handle
    end

    if Character and Humanoid and RootPart then
        if RootPart.Velocity.Magnitude < 50 then
            getgenv().OldPos = RootPart.CFrame
        end
        if THead then
            workspace.CurrentCamera.CameraSubject = THead
        elseif not THead and Handle then
            workspace.CurrentCamera.CameraSubject = Handle
        elseif THumanoid and TRootPart then
            workspace.CurrentCamera.CameraSubject = THumanoid
        end
        if not TCharacter:FindFirstChildWhichIsA("BasePart") then
            return
        end
        
        local FPos = function(BasePart, Pos, Ang)
            RootPart.CFrame = CFrame.new(BasePart.Position) * Pos * Ang
            Character:SetPrimaryPartCFrame(CFrame.new(BasePart.Position) * Pos * Ang)
            RootPart.Velocity = Vector3.new(9e7, 9e7 * 10, 9e7)
            RootPart.RotVelocity = Vector3.new(9e8, 9e8, 9e8)
        end
        
        local SFBasePart = function(BasePart)
            local TimeToWait = duration or 2
            local Time = tick()
            local Angle = 0

            repeat
                if RootPart and THumanoid then
                    if BasePart.Velocity.Magnitude < 50 then
                        Angle = Angle + 100

                        FPos(BasePart, CFrame.new(0, 1.5, 0) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle),0 ,0))
                        task.wait()

                        FPos(BasePart, CFrame.new(0, -1.5, 0) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle), 0, 0))
                        task.wait()

                        FPos(BasePart, CFrame.new(2.25, 1.5, -2.25) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle), 0, 0))
                        task.wait()

                        FPos(BasePart, CFrame.new(-2.25, -1.5, 2.25) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle), 0, 0))
                        task.wait()

                        FPos(BasePart, CFrame.new(0, 1.5, 0) + THumanoid.MoveDirection,CFrame.Angles(math.rad(Angle), 0, 0))
                        task.wait()

                        FPos(BasePart, CFrame.new(0, -1.5, 0) + THumanoid.MoveDirection,CFrame.Angles(math.rad(Angle), 0, 0))
                        task.wait()
                    else
                        FPos(BasePart, CFrame.new(0, 1.5, THumanoid.WalkSpeed), CFrame.Angles(math.rad(90), 0, 0))
                        task.wait()

                        FPos(BasePart, CFrame.new(0, -1.5, -THumanoid.WalkSpeed), CFrame.Angles(0, 0, 0))
                        task.wait()

                        FPos(BasePart, CFrame.new(0, 1.5, THumanoid.WalkSpeed), CFrame.Angles(math.rad(90), 0, 0))
                        task.wait()
                        
                        FPos(BasePart, CFrame.new(0, 1.5, TRootPart.Velocity.Magnitude / 1.25), CFrame.Angles(math.rad(90), 0, 0))
                        task.wait()

                        FPos(BasePart, CFrame.new(0, -1.5, -TRootPart.Velocity.Magnitude / 1.25), CFrame.Angles(0, 0, 0))
                        task.wait()

                        FPos(BasePart, CFrame.new(0, 1.5, TRootPart.Velocity.Magnitude / 1.25), CFrame.Angles(math.rad(90), 0, 0))
                        task.wait()

                        FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(math.rad(90), 0, 0))
                        task.wait()

                        FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(0, 0, 0))
                        task.wait()

                        FPos(BasePart, CFrame.new(0, -1.5 ,0), CFrame.Angles(math.rad(-90), 0, 0))
                        task.wait()

                        FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(0, 0, 0))
                        task.wait()
                    end
                else
                    break
                end
            until not flingActive or BasePart.Velocity.Magnitude > 500 or BasePart.Parent ~= TargetPlayer.Character or TargetPlayer.Parent ~= Players or not TargetPlayer.Character == TCharacter or THumanoid.Sit or tick() > Time + TimeToWait
        end
        
        local previousDestroyHeight = workspace.FallenPartsDestroyHeight
        workspace.FallenPartsDestroyHeight = 0/0
        
        local BV = Instance.new("BodyVelocity")
        BV.Name = "EpixVel"
        BV.Parent = RootPart
        BV.Velocity = Vector3.new(9e8, 9e8, 9e8)
        BV.MaxForce = Vector3.new(1/0, 1/0, 1/0)
        
        Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
        
        if TRootPart and THead then
            if (TRootPart.CFrame.p - THead.CFrame.p).Magnitude > 5 then
                SFBasePart(THead)
            else
                SFBasePart(TRootPart)
            end
        elseif TRootPart and not THead then
            SFBasePart(TRootPart)
        elseif not TRootPart and THead then
            SFBasePart(THead)
        elseif not TRootPart and not THead and Accessory and Handle then
            SFBasePart(Handle)
        end
        
        BV:Destroy()
        Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
        workspace.CurrentCamera.CameraSubject = Humanoid
        
        repeat
            if Character and Humanoid and RootPart and getgenv().OldPos then
                RootPart.CFrame = getgenv().OldPos * CFrame.new(0, .5, 0)
                Character:SetPrimaryPartCFrame(getgenv().OldPos * CFrame.new(0, .5, 0))
                Humanoid:ChangeState("GettingUp")
                table.foreach(Character:GetChildren(), function(_, x)
                    if x:IsA("BasePart") then
                        x.Velocity, x.RotVelocity = Vector3.new(), Vector3.new()
                    end
                end)
            end
            task.wait()
        until not flingActive or (RootPart and getgenv().OldPos and (RootPart.Position - getgenv().OldPos.p).Magnitude < 25)
        workspace.FallenPartsDestroyHeight = previousDestroyHeight
    end
end

-- Add other functions like shhhlol, yeet, getPlayers, updateStatus, addPlayerToProcessed, flingPlayers, toggleFlingMode, toggleFling in a similar way

local function shhhlol(TargetPlayer)
    -- Copy the full shhhlol function
    -- (Omitted for brevity, add the full code here)
end

local function yeet(targetPlayer)
    -- Copy the full yeet function
    -- (Omitted for brevity, add the full code here)
end

local function getPlayers(input)
    -- Copy the full getPlayers function
    local players = {}
    input = string.lower(input or "")
    
    if input == "all" then
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= localPlayer then
                table.insert(players, player)
            end
        end
        players = sortPlayersAlphabetically(players)
    elseif input == "nonfriends" then
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= localPlayer then
                local success, isFriend = pcall(function()
                    return player:IsFriendsWith(localPlayer.UserId)
                end)
                if not (success and isFriend) then
                    table.insert(players, player)
                end
            end
        end
        players = sortPlayersAlphabetically(players)
    else
        local searchTerms = {}
        for term in string.gmatch(input, "([^,]+)") do
            term = string.match(term, "^%s*(.-)%s*$")
            if term ~= "" then
                table.insert(searchTerms, term)
            end
        end
        
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= localPlayer then
                local playerName = string.lower(player.Name)
                local displayName = player.DisplayName and string.lower(player.DisplayName) or ""
                
                for _, term in ipairs(searchTerms) do
                    if string.find(playerName, term) or string.find(displayName, term) then
                        table.insert(players, player)
                        break
                    end
                end
            end
        end
    end
    
    return players
end

local function updateStatus()
    -- Not needed for WindUI, but if needed for notify
end

local function addPlayerToProcessed(player)
    if not player or player == localPlayer then return end
    
    local matchesFilter = false
    local input = string.lower(currentInput)
    
    if input == "all" then
        matchesFilter = true
    elseif input == "nonfriends" then
        local success, isFriend = pcall(function()
            return player:IsFriendsWith(localPlayer.UserId)
        end)
        matchesFilter = not (success and isFriend)
    else
        local searchTerms = {}
        for term in string.gmatch(input, "([^,]+)") do
            term = string.match(term, "^%s*(.-)%s*$")
            if term ~= "" then
                table.insert(searchTerms, term)
            end
        end
        
        local playerName = string.lower(player.Name)
        local displayName = player.DisplayName and string.lower(player.DisplayName) or ""
        
        for _, term in ipairs(searchTerms) do
            if string.find(playerName, term) or string.find(displayName, term) then
                matchesFilter = true
                break
            end
        end
    end
    
    if matchesFilter then
        processedPlayers[player] = true
    end
end

local function flingPlayers()
    local players = {}
    for player, _ in pairs(processedPlayers) do
        if player and player.Character and player.Character.Parent ~= nil then
            table.insert(players, player)
        end
    end
    
    if currentInput == "all" or currentInput == "nonfriends" then
        players = sortPlayersAlphabetically(players)
    end
    
    for _, player in ipairs(players) do
        if not flingActive then break end
        
        if player and player.Character and player.Character.Parent ~= nil then
            local duration = (currentInput == "all" or currentInput == "nonfriends") and 1.5 or nil
            
            if flingMode == 1 then
                SkidFling(player, duration)
            elseif flingMode == 2 then
                shhhlol(player)
            elseif flingMode == 3 then
                yeet(player)
                if currentInput == "all" or currentInput == "nonfriends" then
                    task.wait(1.5)
                end
            end
        end
    end
    
    if flingActive then
        task.wait()
        flingPlayers()
    end
end

local function toggleFlingMode()
    flingMode = flingMode == 1 and 2 or flingMode == 2 and 3 or 1
end

local function toggleFling(state)
    flingActive = state
    
    if state then
        currentInput = string.lower(currentInput)
        local players = getPlayers(currentInput)
        
        if #players == 0 then
            flingActive = false
            return
        end
        
        processedPlayers = {}
        for _, player in ipairs(players) do
            addPlayerToProcessed(player)
        end
        
        coroutine.wrap(flingPlayers)()
    else
        processedPlayers = {}
    end
end

local function toggleFPDProtection(state)
    fpdProtectionEnabled = state
    
    if state then
        local mt = getrawmetatable(workspace)
        oldNewIndex = mt.__newindex
        
        setreadonly(mt, false)
        
        mt.__newindex = function(t, k, v)
            if k == "FallenPartsDestroyHeight" then
                rawset(t, k, 0/0)
                return
            end
            oldNewIndex(t, k, v)
        end
        
        setreadonly(mt, true)
        
        if fpdProtectionConnection then fpdProtectionConnection:Disconnect() end
        fpdProtectionConnection = game:GetService("RunService").Heartbeat:Connect(function()
            if workspace.FallenPartsDestroyHeight == workspace.FallenPartsDestroyHeight then
                workspace.FallenPartsDestroyHeight = 0/0
            end
        end)
        
        wasFlingActiveBeforeFPD = flingActive
        if flingActive then
            toggleFling(false)
        end
    else
        if fpdProtectionConnection then
            fpdProtectionConnection:Disconnect()
            fpdProtectionConnection = nil
        end
        
        if oldNewIndex then
            local mt = getrawmetatable(workspace)
            setreadonly(mt, false)
            mt.__newindex = oldNewIndex
            setreadonly(mt, true)
        end
        
        if wasFlingActiveBeforeFPD and not flingActive then
            toggleFling(true)
        end
    end
end

local function enableAntiKick()
    if not hookmetamethod then 
        warn("Your exploit does not support this anti-kick (missing hookmetamethod)")
        return false
    end
    
    local LocalPlayer = game:GetService("Players").LocalPlayer
    if not LocalPlayer then return false end
    
    local oldhmmi
    local oldhmmnc
    local oldKickFunction
    
    if hookfunction and LocalPlayer.Kick then
        oldKickFunction = hookfunction(LocalPlayer.Kick, function() end)
    end
    
    oldhmmi = hookmetamethod(game, "__index", function(self, method)
        if self == LocalPlayer and method:lower() == "kick" then
            return error("Expected ':' not '.' calling member function Kick", 2)
        end
        return oldhmmi(self, method)
    end)
    
    oldhmmnc = hookmetamethod(game, "__namecall", function(self, ...)
        if self == LocalPlayer and getnamecallmethod():lower() == "kick" then
            return nil
        end
        return oldhmmnc(self, ...)
    end)
    
    return true
end

enableAntiKick()

-- Create Tabs
local MainTab = Window:Tab({
    Icon = "home",
    Title = "Main"
})

local PlayerTab = Window:Tab({
    Icon = "user",
    Title = "loc:Player_TAB"
})

local VisualsTab = Window:Tab({
    Icon = "eye",
    Title = "loc:VISUALS_TAB"
})

local ESPTab = Window:Tab({
    Icon = "target",
    Title = "loc:ESP_TAB"
})

local MiscTab = Window:Tab({
    Icon = "settings",
    Title = "loc:MISC_TAB"
})

local UtilityTab = Window:Tab({
    Icon = "tool",
    Title = "loc:UTILITY_TAB"
})

local SettingsTab = Window:Tab({
    Icon = "settings",
    Title = "loc:SETTINGS_TAB"
})

-- Main Tab
MainTab:Section({ Title = "Server Info", TextSize = 20 })
MainTab:Divider()

local placeName = "Unknown"
local success, productInfo = pcall(function()
    return MarketplaceService:GetProductInfo(placeId)
end)
if success and productInfo then
    placeName = productInfo.Name
end

MainTab:Paragraph({
    Title = "Game Mode",
    Desc = placeName
})

MainTab:Button({
    Title = "Copy Server Link",
    Desc = "Copy the current server's join link",
    Icon = "link",
    Callback = function()
        local serverLink = getServerLink()
        pcall(function()
            setclipboard(serverLink)
        end)
        WindUI:Notify({
            Icon = "link",
            Title = "Link Copied",
            Content = "The server invite link has been copied to your clipboard",
            Duration = 3
        })
    end
})

local numPlayers = #Players:GetPlayers()
local maxPlayers = Players.MaxPlayers

MainTab:Paragraph({
    Title = "Current Players",
    Desc = numPlayers .. " / " .. maxPlayers
})

MainTab:Paragraph({
    Title = "Server ID",
    Desc = jobId
})

MainTab:Paragraph({
    Title = "Place ID",
    Desc = tostring(placeId)
})

MainTab:Section({ Title = "Server Tools", TextSize = 20 })
MainTab:Divider()

MainTab:Button({
    Title = "Rejoin",
    Desc = "Rejoin the current place",
    Icon = "refresh-cw",
    Callback = function()
        rejoinServer()
    end
})

MainTab:Button({
    Title = "Server Hop",
    Desc = "Hop to a random server",
    Icon = "shuffle",
    Callback = function()
        serverHop()
    end
})

MainTab:Button({
    Title = "Hop to Small Server",
    Desc = "Hop to the smallest available server",
    Icon = "minimize",
    Callback = function()
        hopToSmallServer()
    end
})

MainTab:Button({
    Title = "Advanced Server Hop",
    Desc = "Finding a Server inside your game",
    Icon = "server",
    Callback = function()
        local success, result = pcall(function()
            local script = loadstring(game:HttpGet("https://raw.githubusercontent.com/Pnsdgsa/Script-kids/refs/heads/main/Advanced%20Server%20Hop.lua"))()
        end)
        if not success then
            WindUI:Notify({
                Title = "Error",
                Content = "Oopsie Daisy Some thing wrong happening with the Github Repository link, Unfortunately this script no longer exsit: " .. tostring(result),
                Duration = 4
            })
        else
            WindUI:Notify({
                Title = "Success",
                Content = "Script Is Loaded",
                Duration = 3
            })
        end
    end
})


-- Player Tab
PlayerTab:Section({ Title = "loc:FEATURES", TextSize = 40 })
PlayerTab:Section({ Title = "Movement and Player Features", TextSize = 20 })
PlayerTab:Divider()

local InfiniteJumpToggle = PlayerTab:Toggle({
    Title = "loc:INFINITE_JUMP",
    Value = false,
    Callback = function(state)
        featureStates.InfiniteJump = state
    end
})

local JumpMethodDropdown = PlayerTab:Dropdown({
    Title = "loc:JUMP_METHOD",
    Values = {"Hold", "Toggle"},
    Value = "Hold",
    Callback = function(value)
        featureStates.JumpMethod = value
    end
})


local FlyToggle = PlayerTab:Toggle({
    Title = "loc:FLY",
    Value = false,
    Callback = function(state)
        featureStates.Fly = state
        if state then
            startFlying()
        else
            stopFlying()
        end
    end
})

local FlySpeedSlider = PlayerTab:Slider({
    Title = "loc:FLY_SPEED",
    Value = { Min = 1, Max = 500, Default = 5 },
    Callback = function(value)
        flySpeed = value
    end
})

local SpeedHackToggle = PlayerTab:Toggle({
    Title = "loc:SPEED_HACK",
    Value = false,
    Callback = function(state)
        featureStates.SpeedHack = state
        if state and character and humanoid then
            humanoid.WalkSpeed = featureStates.Speed
        else
            if character and humanoid then
                humanoid.WalkSpeed = 16
            end
        end
    end
})

local SpeedSlider = PlayerTab:Slider({
    Title = "Speed Value",
    Value = { Min = 16, Max = 500, Default = 16 },
    Callback = function(value)
        featureStates.Speed = value
        if featureStates.SpeedHack and character and humanoid then
            humanoid.WalkSpeed = value
        end
    end
})

local TPWALKToggle = PlayerTab:Toggle({
    Title = "loc:TPWALK",
    Value = false,
    Callback = function(state)
        featureStates.TPWALK = state
        ToggleTpwalk = state
        if state then
            TpwalkConnection = RunService.Heartbeat:Connect(function()
                if character and rootPart and humanoid then
                    local moveVector = humanoid.MoveDirection * featureStates.TpwalkValue
                    rootPart.CFrame = rootPart.CFrame + moveVector
                end
            end)
        else
            if TpwalkConnection then
                TpwalkConnection:Disconnect()
                TpwalkConnection = nil
            end
        end
    end
})

local TPWALKSlider = PlayerTab:Slider({
    Title = "loc:TPWALK_VALUE",
    Value = { Min = 1, Max = 100, Default = 1 },
    Callback = function(value)
        featureStates.TpwalkValue = value
    end
})

local JumpBoostToggle = PlayerTab:Toggle({
    Title = "loc:JUMP_HEIGHT",
    Value = false,
    Callback = function(state)
        featureStates.JumpBoost = state
        if character and humanoid then
            humanoid.JumpPower = state and featureStates.JumpPower or 50
        end
    end
})

local JumpBoostSlider = PlayerTab:Slider({
    Title = "loc:JUMP_POWER",
    Value = { Min = 1, Max = 100, Default = 5 },
    Callback = function(value)
        featureStates.JumpPower = value
        if featureStates.JumpBoost and character and humanoid then
            humanoid.JumpPower = value
        end
    end
})

-- Visuals Tab
VisualsTab:Section({ Title = "loc:FEATURES", TextSize = 40 })
VisualsTab:Section({ Title = "Visual Enhancements", TextSize = 20 })
VisualsTab:Divider()

local FullBrightToggle = VisualsTab:Toggle({
    Title = "loc:FULL_BRIGHT",
    Value = false,
    Callback = function(state)
        featureStates.FullBright = state
        if state then
            Lighting.Brightness = 2
            Lighting.ClockTime = 14
            Lighting.FogEnd = 100000
            Lighting.GlobalShadows = false
            Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
        else
            Lighting.Brightness = 1
            Lighting.ClockTime = 12
            Lighting.FogEnd = 100
            Lighting.GlobalShadows = true
            Lighting.OutdoorAmbient = Color3.fromRGB(64, 64, 64)
        end
    end
})

local NoFogToggle = VisualsTab:Toggle({
    Title = "loc:NO_FOG",
    Value = false,
    Callback = function(state)
        featureStates.NoFog = state
        Lighting.FogEnd = state and 100000 or 100
    end
})

-- ESP Tab
ESPTab:Section({ Title = "Player ESP", TextSize = 20 })
ESPTab:Divider()

local PlayerNameESPToggle = ESPTab:Toggle({
    Title = "loc:PLAYER_NAME_ESP",
    Value = false,
    Callback = function(state)
        featureStates.PlayerESP.name = state
    end
})

local PlayerBoxESPToggle = ESPTab:Toggle({
    Title = "loc:PLAYER_BOX_ESP",
    Value = false,
    Callback = function(state)
        featureStates.PlayerESP.box = state
    end
})

local BoxTypeDropdown = ESPTab:Dropdown({
    Title = "loc:BOX_TYPE",
    Values = {"2D", "3D"},
    Value = "2D",
    Callback = function(value)
        featureStates.PlayerESP.boxType = value
    end
})

local PlayerTracerToggle = ESPTab:Toggle({
    Title = "loc:PLAYER_TRACER",
    Value = false,
    Callback = function(state)
        featureStates.PlayerESP.tracer = state
    end
})

local PlayerDistanceESPToggle = ESPTab:Toggle({
    Title = "loc:PLAYER_DISTANCE_ESP",
    Value = false,
    Callback = function(state)
        featureStates.PlayerESP.distance = state
    end
})

local HighlightsToggle = ESPTab:Toggle({
    Title = "loc:HIGHLIGHTS",
    Value = false,
    Callback = function(state)
        featureStates.PlayerESP.highlights = state
        if state then
            for _, plr in pairs(Players:GetPlayers()) do
                if plr ~= player and plr.Character then
                    local highlight = plr.Character:FindFirstChild("Highlight")
                    if not highlight then
                        highlight = Instance.new("Highlight")
                        highlight.Parent = plr.Character
                        highlight.FillColor = Color3.new(0, 1, 0)
                        highlight.OutlineColor = Color3.new(1, 1, 1)
                    end
                    highlight.Enabled = true
                end
            end
        else
            for _, plr in pairs(Players:GetPlayers()) do
                if plr ~= player and plr.Character then
                    local highlight = plr.Character:FindFirstChild("Highlight")
                    if highlight then
                        highlight.Enabled = false
                    end
                end
            end
        end
    end
})

-- ESP Implementation
local function createEspElements(plr)
    if plr == player then return end
    playerEspElements[plr] = {
        name = Drawing.new("Text"),
        box = Drawing.new("Square"),
        tracer = Drawing.new("Line"),
        distance = Drawing.new("Text")
    }
    playerEspElements[plr].name.Size = 16
    playerEspElements[plr].name.Center = true
    playerEspElements[plr].name.Outline = true
    playerEspElements[plr].name.Color = Color3.new(1, 1, 1)
    playerEspElements[plr].box.Size = Vector2.new(0, 0)
    playerEspElements[plr].box.Color = Color3.new(0, 1, 0)
    playerEspElements[plr].box.Thickness = 2
    playerEspElements[plr].box.Filled = false
    playerEspElements[plr].tracer.Color = Color3.new(0, 1, 0)
    playerEspElements[plr].tracer.Thickness = 1
    playerEspElements[plr].distance.Size = 16
    playerEspElements[plr].distance.Center = true
    playerEspElements[plr].distance.Outline = true
    playerEspElements[plr].distance.Color = Color3.new(1, 1, 1)
    
    -- 3D Box Lines
    for i = 1, 12 do
        local line = Drawing.new("Line")
        line.Color = Color3.new(0, 1, 0)
        line.Thickness = 2
        line.Transparency = 1
        line.Visible = false
        playerEspElements[plr]["line" .. i] = line
    end
    playerEspElements[plr].name.Visible = false
    playerEspElements[plr].box.Visible = false
    playerEspElements[plr].tracer.Visible = false
    playerEspElements[plr].distance.Visible = false
end

local function cleanupEsp(plr)
    if playerEspElements[plr] then
        for _, drawing in pairs(playerEspElements[plr]) do
            drawing:Remove()
        end
        playerEspElements[plr] = nil
    end
end

Players.PlayerRemoving:Connect(cleanupEsp)

local function updateEsp()
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= player and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            local char = plr.Character
            local hrp = char.HumanoidRootPart
            local vector, onScreen = camera:WorldToViewportPoint(hrp.Position)
            if not playerEspElements[plr] then
                createEspElements(plr)
            end
            local esp = playerEspElements[plr]
            if onScreen then
                local head = char:FindFirstChild("Head")
                if head then
                    local top = camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
                    local leg = camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0))
                    local size = math.abs(leg.Y - top.Y)
                    local width = size / 2

                    if featureStates.PlayerESP.name then
                        esp.name.Text = plr.Name
                        esp.name.Position = Vector2.new(vector.X, top.Y - 16)
                        esp.name.Visible = true
                    else
                        esp.name.Visible = false
                    end

                    if featureStates.PlayerESP.tracer then
                        esp.tracer.From = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y)
                        esp.tracer.To = Vector2.new(vector.X, vector.Y)
                        esp.tracer.Visible = true
                    else
                        esp.tracer.Visible = false
                    end

                    if featureStates.PlayerESP.distance then
                        local dist = (rootPart.Position - hrp.Position).Magnitude
                        esp.distance.Text = math.floor(dist) .. "m"
                        esp.distance.Position = Vector2.new(vector.X, vector.Y + size / 2 + 16)
                        esp.distance.Visible = true
                    else
                        esp.distance.Visible = false
                    end

                    if featureStates.PlayerESP.box then
                        if featureStates.PlayerESP.boxType == "2D" then
                            esp.box.Size = Vector2.new(width * 2, size)
                            esp.box.Position = Vector2.new(vector.X - width, top.Y)
                            esp.box.Visible = true
                            -- Hide 3D lines
                            for i = 1, 12 do
                                local line = esp["line" .. i]
                                if line then line.Visible = false end
                            end
                        else
                            -- 3D box
                            esp.box.Visible = false
                            local Scale = head.Size.Y / 2
                            local cSize = Vector3.new(2, 3, 1.5) * (Scale * 2)
                            local cf = hrp.CFrame
                            local Top1 = camera:WorldToViewportPoint((cf * CFrame.new(-cSize.X, cSize.Y, -cSize.Z)).Position)
                            local Top2 = camera:WorldToViewportPoint((cf * CFrame.new(-cSize.X, cSize.Y, cSize.Z)).Position)
                            local Top3 = camera:WorldToViewportPoint((cf * CFrame.new(cSize.X, cSize.Y, cSize.Z)).Position)
                            local Top4 = camera:WorldToViewportPoint((cf * CFrame.new(cSize.X, cSize.Y, -cSize.Z)).Position)
                            local Bottom1 = camera:WorldToViewportPoint((cf * CFrame.new(-cSize.X, -cSize.Y, -cSize.Z)).Position)
                            local Bottom2 = camera:WorldToViewportPoint((cf * CFrame.new(-cSize.X, -cSize.Y, cSize.Z)).Position)
                            local Bottom3 = camera:WorldToViewportPoint((cf * CFrame.new(cSize.X, -cSize.Y, cSize.Z)).Position)
                            local Bottom4 = camera:WorldToViewportPoint((cf * CFrame.new(cSize.X, -cSize.Y, -cSize.Z)).Position)

                            -- Top
                            esp.line1.From = Vector2.new(Top1.X, Top1.Y)
                            esp.line1.To = Vector2.new(Top2.X, Top2.Y)
                            esp.line2.From = Vector2.new(Top2.X, Top2.Y)
                            esp.line2.To = Vector2.new(Top3.X, Top3.Y)
                            esp.line3.From = Vector2.new(Top3.X, Top3.Y)
                            esp.line3.To = Vector2.new(Top4.X, Top4.Y)
                            esp.line4.From = Vector2.new(Top4.X, Top4.Y)
                            esp.line4.To = Vector2.new(Top1.X, Top1.Y)

                            -- Bottom
                            esp.line5.From = Vector2.new(Bottom1.X, Bottom1.Y)
                            esp.line5.To = Vector2.new(Bottom2.X, Bottom2.Y)
                            esp.line6.From = Vector2.new(Bottom2.X, Bottom2.Y)
                            esp.line6.To = Vector2.new(Bottom3.X, Bottom3.Y)
                            esp.line7.From = Vector2.new(Bottom3.X, Bottom3.Y)
                            esp.line7.To = Vector2.new(Bottom4.X, Bottom4.Y)
                            esp.line8.From = Vector2.new(Bottom4.X, Bottom4.Y)
                            esp.line8.To = Vector2.new(Bottom1.X, Bottom1.Y)

                            -- Sides
                            esp.line9.From = Vector2.new(Bottom1.X, Bottom1.Y)
                            esp.line9.To = Vector2.new(Top1.X, Top1.Y)
                            esp.line10.From = Vector2.new(Bottom2.X, Bottom2.Y)
                            esp.line10.To = Vector2.new(Top2.X, Top2.Y)
                            esp.line11.From = Vector2.new(Bottom3.X, Bottom3.Y)
                            esp.line11.To = Vector2.new(Top3.X, Top3.Y)
                            esp.line12.From = Vector2.new(Bottom4.X, Bottom4.Y)
                            esp.line12.To = Vector2.new(Top4.X, Top4.Y)

                            -- Show lines
                            for i = 1, 12 do
                                local line = esp["line" .. i]
                                if line then line.Visible = true end
                            end
                        end
                    else
                        esp.box.Visible = false
                        for i = 1, 12 do
                            local line = esp["line" .. i]
                            if line then line.Visible = false end
                        end
                    end
                else
                    -- No head, hide ESP elements
                    esp.name.Visible = false
                    esp.box.Visible = false
                    esp.tracer.Visible = false
                    esp.distance.Visible = false
                    for i = 1, 12 do
                        local line = esp["line" .. i]
                        if line then line.Visible = false end
                    end
                end
            else
                esp.name.Visible = false
                esp.box.Visible = false
                esp.tracer.Visible = false
                esp.distance.Visible = false
                for i = 1, 12 do
                    local line = esp["line" .. i]
                    if line then line.Visible = false end
                end
            end
        else
            if playerEspElements[plr] then
                for _, obj in pairs(playerEspElements[plr]) do
                    obj.Visible = false
                end
            end
        end
    end
end

espConnection = RunService.Heartbeat:Connect(updateEsp)

Players.PlayerAdded:Connect(function(plr)
    plr.CharacterAdded:Connect(function()
        -- Optional: wait(1) if needed for char stability
    end)
end)

-- Misc Tab
MiscTab:Section({ Title = "Anti AFK", TextSize = 20 })
MiscTab:Divider()

local AntiAFKToggle = MiscTab:Toggle({
    Title = "loc:ANTI_AFK",
    Value = false,
    Callback = function(state)
        featureStates.AntiAFK = state
        if state then
            startAntiAFK()
        else
            stopAntiAFK()
        end
    end
})

MiscTab:Section({ Title = "Fling Features", TextSize = 20 })
MiscTab:Divider()

local FlingInput = MiscTab:Input({
    Title = "Fling Player Name (all, nonfriends, names)",
    Value = "",
    Callback = function(value)
        currentInput = value
    end
})

local FlingModeDropdown = MiscTab:Dropdown({
    Title = "Fling Mode",
    Values = {"1", "2", "3"},
    Value = "1",
    Callback = function(value)
        flingMode = tonumber(value)
    end
})

local FlingToggle = MiscTab:Toggle({
    Title = "Fling Players",
    Value = false,
    Callback = function(state)
        toggleFling(state)
    end
})

local TouchFlingToggle = MiscTab:Toggle({
    Title = "Touch Fling",
    Value = false,
    Callback = function(state)
        hiddenfling = state
        if state then
            coroutine.wrap(fling)()
        end
    end
})

local AntiFlingToggle = MiscTab:Toggle({
    Title = "Anti Fling",
    Value = false,
    Callback = function(state)
        toggleAntiFling(state)
    end
})

local AntiKillPartsToggle = MiscTab:Toggle({
    Title = "Anti Kill Parts",
    Value = false,
    Callback = function(state)
        toggleAntiKillParts(state)
    end
})

local NoclipToggle = MiscTab:Toggle({
    Title = "Noclip",
    Value = false,
    Callback = function(state)
        toggleNoclip(state)
    end
})

local StrengthToggle = MiscTab:Toggle({
    Title = "Strength",
    Value = false,
    Callback = function(state)
        isStrengthened = state
        if localPlayer.Character then
            manageStrength(localPlayer.Character, state)
        end
        localPlayer.CharacterAdded:Connect(function(newChar)
            if isStrengthened then
                manageStrength(newChar, true)
            end
        end)
    end
})

local SpawnpointToggle = MiscTab:Toggle({
    Title = "Spawnpoint",
    Value = false,
    Callback = function(state)
        spawnpointActive = state
        if state then
            local character = localPlayer.Character
            if character and character:FindFirstChild("HumanoidRootPart") then
                savedPosition = character.HumanoidRootPart.CFrame
            end
            setupSpawnpoint()
        else
            savedPosition = nil
            needsRespawn = false
            
            if respawnConnection then
                respawnConnection:Disconnect()
                respawnConnection = nil
            end
        end
    end
})

local AntiSlapToggle = MiscTab:Toggle({
    Title = "Anti Slap",
    Value = false,
    Callback = function(state)
        as = state
        if state then
            if localPlayer.Character then
                dc(localPlayer.Character)
            end
        end
    end
})

localPlayer.CharacterAdded:Connect(dc)

local XenoAntiFlingToggle = MiscTab:Toggle({
    Title = "Xeno AntiFling",
    Value = false,
    Callback = function(state)
        toggleXenoAntiFling(state)
    end
})

local InfinitePositionToggle = MiscTab:Toggle({
    Title = "Infinite Position",
    Value = false,
    Callback = function(state)
        infinitePositionEnabled = state
        if state then
            local character = localPlayer.Character
            if character and character:FindFirstChild("HumanoidRootPart") then
                savedInfinitePosition = character.HumanoidRootPart.CFrame
            end
            setupInfinitePosition()
        else
            savedInfinitePosition = nil
            if infinitePositionConnection then
                infinitePositionConnection:Disconnect()
                infinitePositionConnection = nil
            end
        end
    end
})

local NDSAntiFallDamageToggle = MiscTab:Toggle({
    Title = "NDS Anti Fall Damage",
    Value = false,
    Callback = function(state)
        toggleAFD(state)
    end
})

local AntiSitToggle = MiscTab:Toggle({
    Title = "Anti Sit",
    Value = false,
    Callback = function(state)
        toggleNoSit(state)
        localPlayer.CharacterAdded:Connect(function(character)
            if state then
                local humanoid = character:WaitForChildOfClass("Humanoid")
                humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
                
                if humanoid.Sit then
                    humanoid.Sit = false
                end
                humanoid.Sit = true
            end
        end)
    end
})


local InvisToggle = MiscTab:Toggle({
    Title = "Invis",
    Value = false,
    Callback = function(state)
        toggleInvis(state)
    end
})

local AntiRagdollToggle = MiscTab:Toggle({
    Title = "Anti Ragdoll",
    Value = false,
    Callback = function(state)
        antiRagdollEnabled = state
        
        if state then
            if antiRagdollDisconnectFunc then
                antiRagdollDisconnectFunc()
            end
            
            if localPlayer.Character then
                local humanoid = localPlayer.Character:FindFirstChildOfClass("Humanoid")
                if humanoid then
                    humanoid.PlatformStand = false
                end
                antiRagdollDisconnectFunc = createAntiRagdoll(localPlayer.Character)
            end
        else
            if antiRagdollDisconnectFunc then
                antiRagdollDisconnectFunc()
                antiRagdollDisconnectFunc = nil
            end
        end
    end
})

local FPDToggle = MiscTab:Toggle({
    Title = "FPD Protection",
    Value = false,
    Callback = function(state)
        toggleFPDProtection(state)
    end
})

Players.PlayerAdded:Connect(function(player)
    if flingActive then
        addPlayerToProcessed(player)
        if player.Character then
            if flingMode == 1 then
                local duration = (currentInput == "all" or currentInput == "nonfriends") and 1.5 or nil
                SkidFling(player, duration)
            elseif flingMode == 2 then
                shhhlol(player)
            elseif flingMode == 3 then
                yeet(player)
            end
        else
            player.CharacterAdded:Connect(function()
                if flingActive then
                    addPlayerToProcessed(player)
                    if flingMode == 1 then
                        local duration = (currentInput == "all" or currentInput == "nonfriends") and 1.5 or nil
                        SkidFling(player, duration)
                    elseif flingMode == 2 then
                        shhhlol(player)
                    elseif flingMode == 3 then
                        yeet(player)
                    end
                end
            end)
        end
    end
end)

localPlayer.CharacterAdded:Connect(function()
    if flingActive then
        task.wait(1)
        coroutine.wrap(flingPlayers)()
    end
    if isStrengthened then
        manageStrength(character, true)
    end
    if noSitEnabled then
        toggleNoSit(true)
    end
    if antiRagdollEnabled then
        antiRagdollDisconnectFunc = createAntiRagdoll(character)
    end
    if isNoclipEnabled then
        enableNoclip()
    end
    if AntiKillPartsEnabled then
        coroutine.wrap(applyAntiKillParts)()
    end
end)

-- Utility Tab
UtilityTab:Section({ Title = "Tools", TextSize = 20 })
UtilityTab:Divider()

UtilityTab:Button({
    Title = "Punch Fling",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/FilteringEnabled/FE/main/punch"))()
    end
})

UtilityTab:Button({
    Title = "Fire Parts Tool",
    Callback = function()
        loadstring(game:HttpGet("https://glot.io/snippets/h9wgykubaz/raw/FireParts.lua"))()
    end
})
player.CharacterAdded:Connect(function(newCharacter)
    character = newCharacter
    humanoid = character:WaitForChild("Humanoid")
    rootPart = character:WaitForChild("HumanoidRootPart")
    if featureStates.SpeedHack then
        humanoid.WalkSpeed = featureStates.Speed
    end
    if flying then
        startFlying()
    end
    
end)

-- Settings Tab
SettingsTab:Section({ Title = "Settings", TextSize = 40 })
SettingsTab:Section({ Title = "Personalize", TextSize = 20 })
SettingsTab:Divider()

local themes = {}
for themeName, _ in pairs(WindUI:GetThemes()) do
    table.insert(themes, themeName)
end
table.sort(themes)

local canChangeTheme = true
local canChangeDropdown = true

local ThemeDropdown = SettingsTab:Dropdown({
    Title = "loc:THEME_SELECT",
    Values = themes,
    SearchBarEnabled = true,
    MenuWidth = 280,
    Value = "Dark",
    Callback = function(theme)
        if canChangeDropdown then
            canChangeTheme = false
            WindUI:SetTheme(theme)
            canChangeTheme = true
        end
    end
})

local TransparencySlider = SettingsTab:Slider({
    Title = "loc:TRANSPARENCY",
    Value = { Min = 0, Max = 1, Default = 0.2, Step = 0.1 },
    Callback = function(value)
        WindUI.TransparencyValue = tonumber(value)
        Window:ToggleTransparency(tonumber(value) > 0)
    end
})

local ThemeToggle = SettingsTab:Toggle({
    Title = "Enable Dark Mode",
    Desc = "Use dark color scheme",
    Value = true,
    Callback = function(state)
        if canChangeTheme then
            local newTheme = state and "Dark" or "Light"
            WindUI:SetTheme(newTheme)
            if canChangeDropdown then
                ThemeDropdown:Select(newTheme)
            end
        end
    end
})

WindUI:OnThemeChange(function(theme)
    canChangeTheme = false
    ThemeToggle:Set(theme == "Dark")
    canChangeTheme = true
end)

-- Configuration Manager
local configName = "default"
local configFile = nil

SettingsTab:Section({ Title = "Configuration Manager", TextSize = 20 })
SettingsTab:Section({ Title = "Save and load your settings", TextSize = 16, TextTransparency = 0.25 })
SettingsTab:Divider()

local ConfigNameInput = SettingsTab:Input({
    Title = "Config Name",
    Value = configName,
    Callback = function(value)
        configName = value or "default"
    end
})

local ConfigManager = Window.ConfigManager
if ConfigManager then
    ConfigManager:Init(Window)
    
    SettingsTab:Button({
        Title = "loc:SAVE_CONFIG",
        Icon = "save",
        Variant = "Primary",
        Callback = function()
            configFile = ConfigManager:CreateConfig(configName)
            configFile:Register("InfiniteJumpToggle", InfiniteJumpToggle)
            configFile:Register("JumpMethodDropdown", JumpMethodDropdown)
            configFile:Register("FlyToggle", FlyToggle)
            configFile:Register("FlySpeedSlider", FlySpeedSlider)
            configFile:Register("SpeedHackToggle", SpeedHackToggle)
            configFile:Register("SpeedSlider", SpeedSlider)
            configFile:Register("TPWALKToggle", TPWALKToggle)
            configFile:Register("TPWALKSlider", TPWALKSlider)
            configFile:Register("JumpBoostToggle", JumpBoostToggle)
            configFile:Register("JumpBoostSlider", JumpBoostSlider)
            configFile:Register("AntiAFKToggle", AntiAFKToggle)
            configFile:Register("FullBrightToggle", FullBrightToggle)
            configFile:Register("NoFogToggle", NoFogToggle)
            configFile:Register("PlayerNameESPToggle", PlayerNameESPToggle)
            configFile:Register("PlayerBoxESPToggle", PlayerBoxESPToggle)
            configFile:Register("BoxTypeDropdown", BoxTypeDropdown)
            configFile:Register("PlayerTracerToggle", PlayerTracerToggle)
            configFile:Register("PlayerDistanceESPToggle", PlayerDistanceESPToggle)
            configFile:Register("HighlightsToggle", HighlightsToggle)
            configFile:Register("ThemeDropdown", ThemeDropdown)
            configFile:Register("TransparencySlider", TransparencySlider)
            configFile:Register("ThemeToggle", ThemeToggle)
            -- Add new toggles
            configFile:Register("FlingToggle", FlingToggle)
            configFile:Register("TouchFlingToggle", TouchFlingToggle)
            configFile:Register("AntiFlingToggle", AntiFlingToggle)
            configFile:Register("AntiKillPartsToggle", AntiKillPartsToggle)
            configFile:Register("NoclipToggle", NoclipToggle)
            configFile:Register("StrengthToggle", StrengthToggle)
            configFile:Register("SpawnpointToggle", SpawnpointToggle)
            configFile:Register("AntiSlapToggle", AntiSlapToggle)
            configFile:Register("XenoAntiFlingToggle", XenoAntiFlingToggle)
            configFile:Register("InfinitePositionToggle", InfinitePositionToggle)
            configFile:Register("NDSAntiFallDamageToggle", NDSAntiFallDamageToggle)
            configFile:Register("AntiSitToggle", AntiSitToggle)
            configFile:Register("InvisToggle", InvisToggle)
            configFile:Register("AntiRagdollToggle", AntiRagdollToggle)
            configFile:Register("FPDToggle", FPDToggle)
            configFile:Save()
            WindUI:Notify({
                Title = "Config Saved",
                Content = "Configuration saved successfully.",
                Duration = 2
            })
        end
    })

    SettingsTab:Button({
        Title = "loc:LOAD_CONFIG",
        Icon = "folder",
        Callback = function()
            configFile = ConfigManager:CreateConfig(configName)
            local loadedData = configFile:Load()
            if loadedData then
                if loadedData.InfiniteJumpToggle then InfiniteJumpToggle:Set(loadedData.InfiniteJumpToggle) end
                if loadedData.JumpMethodDropdown then JumpMethodDropdown:Select(loadedData.JumpMethodDropdown) end
                if loadedData.FlyToggle then FlyToggle:Set(loadedData.FlyToggle) end
                if loadedData.FlySpeedSlider then FlySpeedSlider:Set(loadedData.FlySpeedSlider) end
                if loadedData.SpeedHackToggle then SpeedHackToggle:Set(loadedData.SpeedHackToggle) end
                if loadedData.SpeedSlider then SpeedSlider:Set(loadedData.SpeedSlider) end
                if loadedData.TPWALKToggle then TPWALKToggle:Set(loadedData.TPWALKToggle) end
                if loadedData.TPWALKSlider then TPWALKSlider:Set(loadedData.TPWALKSlider) end
                if loadedData.JumpBoostToggle then JumpBoostToggle:Set(loadedData.JumpBoostToggle) end
                if loadedData.JumpBoostSlider then JumpBoostSlider:Set(loadedData.JumpBoostSlider) end
                if loadedData.AntiAFKToggle then AntiAFKToggle:Set(loadedData.AntiAFKToggle) end
                if loadedData.FullBrightToggle then FullBrightToggle:Set(loadedData.FullBrightToggle) end
                if loadedData.NoFogToggle then NoFogToggle:Set(loadedData.NoFogToggle) end
                if loadedData.PlayerNameESPToggle then PlayerNameESPToggle:Set(loadedData.PlayerNameESPToggle) end
                if loadedData.PlayerBoxESPToggle then PlayerBoxESPToggle:Set(loadedData.PlayerBoxESPToggle) end
                if loadedData.BoxTypeDropdown then BoxTypeDropdown:Select(loadedData.BoxTypeDropdown) end
                if loadedData.PlayerTracerToggle then PlayerTracerToggle:Set(loadedData.PlayerTracerToggle) end
                if loadedData.PlayerDistanceESPToggle then PlayerDistanceESPToggle:Set(loadedData.PlayerDistanceESPToggle) end
                if loadedData.HighlightsToggle then HighlightsToggle:Set(loadedData.HighlightsToggle) end
                if loadedData.ThemeDropdown then ThemeDropdown:Select(loadedData.ThemeDropdown) end
                if loadedData.TransparencySlider then TransparencySlider:Set(loadedData.TransparencySlider) end
                if loadedData.ThemeToggle ~= nil then ThemeToggle:Set(loadedData.ThemeToggle) end
                -- Load new
                if loadedData.FlingToggle then FlingToggle:Set(loadedData.FlingToggle) end
                if loadedData.TouchFlingToggle then TouchFlingToggle:Set(loadedData.TouchFlingToggle) end
                if loadedData.AntiFlingToggle then AntiFlingToggle:Set(loadedData.AntiFlingToggle) end
                if loadedData.AntiKillPartsToggle then AntiKillPartsToggle:Set(loadedData.AntiKillPartsToggle) end
                if loadedData.NoclipToggle then NoclipToggle:Set(loadedData.NoclipToggle) end
                if loadedData.StrengthToggle then StrengthToggle:Set(loadedData.StrengthToggle) end
                if loadedData.SpawnpointToggle then SpawnpointToggle:Set(loadedData.SpawnpointToggle) end
                if loadedData.AntiSlapToggle then AntiSlapToggle:Set(loadedData.AntiSlapToggle) end
                if loadedData.XenoAntiFlingToggle then XenoAntiFlingToggle:Set(loadedData.XenoAntiFlingToggle) end
                if loadedData.InfinitePositionToggle then InfinitePositionToggle:Set(loadedData.InfinitePositionToggle) end
                if loadedData.NDSAntiFallDamageToggle then NDSAntiFallDamageToggle:Set(loadedData.NDSAntiFallDamageToggle) end
                if loadedData.AntiSitToggle then AntiSitToggle:Set(loadedData.AntiSitToggle) end
                if loadedData.InvisToggle then InvisToggle:Set(loadedData.InvisToggle) end
                if loadedData.AntiRagdollToggle then AntiRagdollToggle:Set(loadedData.AntiRagdollToggle) end
                if loadedData.FPDToggle then FPDToggle:Set(loadedData.FPDToggle) end
                WindUI:Notify({
                    Title = "Config Loaded",
                    Content = "Configuration loaded successfully.",
                    Duration = 2
                })
            else
                WindUI:Notify({
                    Title = "Config Error",
                    Content = "No configuration found.",
                    Duration = 2
                })
            end
        end
    })
else
    SettingsTab:Paragraph({
        Title = "Config Manager Not Available",
        Desc = "This feature requires ConfigManager",
        Image = "alert-triangle",
        ImageSize = 20,
        Color = "White"
    })
end

-- Keybind Settings
SettingsTab:Section({ Title = "Keybind Settings", TextSize = 20 })
SettingsTab:Section({ Title = "Change toggle key for GUI", TextSize = 16, TextTransparency = 0.25 })
SettingsTab:Divider()

SettingsTab:Keybind({
    Flag = "keybind ui toggles",
    Title = "Keybind",
    Desc = "Keybind to open ui",
    Value = initialKeyName,
    Callback = function(v)
        local keyCode = Enum.KeyCode[v]
        Window:SetToggleKey(keyCode)
        saveKeybind(keyCode)
    end
})

-- Implementations
UserInputService.JumpRequest:Connect(function()
    if featureStates.InfiniteJump then
        if featureStates.JumpMethod == "Hold" then
            isJumpHeld = true
        elseif featureStates.JumpMethod == "Toggle" then
            featureStates.InfiniteJump = not featureStates.InfiniteJump
            InfiniteJumpToggle:Set(featureStates.InfiniteJump)
        end
        if character and humanoid then
            humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.Space then
        isJumpHeld = false
    end
end)

RunService.Heartbeat:Connect(function()
    if featureStates.InfiniteJump and isJumpHeld and character and humanoid then
        humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
    
    if flying and bodyVelocity and bodyGyro and rootPart then
        local moveVector = humanoid.MoveDirection * featureStates.FlySpeed
        bodyVelocity.Velocity = Vector3.new(moveVector.X, featureStates.FlySpeed, moveVector.Z)
        bodyGyro.CFrame = workspace.CurrentCamera.CFrame
    end
    
    if character and humanoid then
        if featureStates.SpeedHack then
            humanoid.WalkSpeed = featureStates.Speed
        end
    end
    
    updateEsp()
end)

player.CharacterAdded:Connect(function(newCharacter)
    character = newCharacter
    humanoid = character:WaitForChild("Humanoid")
    rootPart = character:WaitForChild("HumanoidRootPart")
    if featureStates.SpeedHack then
        humanoid.WalkSpeed = featureStates.Speed
    end
end)

Window:SelectTab(1)

Window:UnlockAll()

Window:OnClose(function()
    print("Press " .. initialKeyName .. " To Reopen")
    if not game:GetService("UserInputService").TouchEnabled then
        pcall(function()
            WindUI:Notify({
                Title = "GUI Closed",
                Content = "Press " .. initialKeyName .. " To Reopen",
                Duration = 3
            })
        end)
    end
end)

Window:OnOpen(function()
    print("Window opened")
end)
