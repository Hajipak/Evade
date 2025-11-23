if getgenv().DaraHubEvadeExecuted then
    return
end
getgenv().DaraHubEvadeExecuted = true

WindUI = nil

do
    ok, result = pcall(function()
        return require("./src/Init")
    end)
    
    if ok then
        WindUI = result
    else 
        WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
    end
end

WindUI.TransparencyValue = 0.2
WindUI:SetTheme("Dark")

Window = WindUI:CreateWindow({
    Title = "Dara Hub",
    Icon = "rbxassetid://137330250139083",
    Author = "Made by: Pnsdg And Yomka",
    Folder = "DaraHub",
    Size = UDim2.fromOffset(580, 490),
    Theme = "Dark",
    HidePanelBackground = false,
    Acrylic = false,
    HideSearchBar = false,
    SideBarWidth = 200
})

isWindowOpen = false
updateWindowOpenState = function()
    if Window and type(Window.IsOpen) == "function" then
        ok, val = pcall(function() return Window:IsOpen() end)
        if ok and type(val) == "boolean" then
            isWindowOpen = val
            return
        end
    end
    if Window and Window.Opened ~= nil then
        isWindowOpen = Window.Opened
        return
    end
    isWindowOpen = isWindowOpen or false
end

pcall(updateWindowOpenState)
Window:SetIconSize(48)
Window:Tag({
    Title = "V1",
    Color = Color3.fromHex("#30ff6a")
})

Window:CreateTopbarButton("theme-switcher", "moon", function()
    WindUI:SetTheme(WindUI:GetCurrentTheme() == "Dark" and "Light" or "Dark")
end, 990)

Players = game:GetService("Players")
UserInputService = game:GetService("UserInputService")
RunService = game:GetService("RunService")
VirtualUser = game:GetService("VirtualUser")
Lighting = game:GetService("Lighting")
ReplicatedStorage = game:GetService("ReplicatedStorage")
workspace = game:GetService("Workspace")
originalGameGravity = workspace.Gravity
TeleportService = game:GetService("TeleportService")
HttpService = game:GetService("HttpService")
MarketplaceService = game:GetService("MarketplaceService")
player = Players.LocalPlayer
playerGui = player:WaitForChild("PlayerGui")
placeId = game.PlaceId
jobId = game.JobId

featureStates = {
    InfiniteJump = false,
    Fly = false,
    FlySpeed = 5,
    TPWALK = false,
    TpwalkValue = 1,
    JumpBoost = false,
    JumpPower = 5,
    AntiAFK = false,
    SpeedHack = false,
    SpeedValue = 16,
    Noclip = false,
    InnocentESP = {names = false, boxes = false, tracers = false, distance = false, boxType = "2D"},
    MurderESP = {names = false, boxes = false, tracers = false, distance = false, boxType = "2D"},
    HeroSheriffESP = {names = false, boxes = false, tracers = false, distance = false, boxType = "2D"},
    InnocentHighlights = false,
    MurderHighlights = false,
    SheriffHeroHighlights = false
}

local function IsAlive(Player, currentRoles)
    for i, v in pairs(currentRoles) do
        if Player.Name == i then
            if not v.Killed and not v.Dead then
                return true
            else
                return false
            end
        end
    end
    return false
end

local function getOutlineColor(c)
    local lum = 0.299 * c.R + 0.587 * c.G + 0.114 * c.B
    if lum > 0.5 then
        return Color3.new(0,0,0)
    else
        return Color3.new(1,1,1)
    end
end

FeatureSection = Window:Section({ Title = "Features", Opened = true })

Tabs = {
    Main = FeatureSection:Tab({ Title = "Main", Icon = "layout-grid" }),
    Player = FeatureSection:Tab({ Title = "Player", Icon = "user" }),
    Combat = FeatureSection:Tab({ Title = "Combat", Icon = "swords" }),
    Visuals = FeatureSection:Tab({ Title = "Visuals", Icon = "camera" }),
    Esp = FeatureSection:Tab({ Title = "Esp", Icon = "eye" }),
    Teleport = FeatureSection:Tab({ Title = "Teleport", Icon = "navigation" }),
    Misc = FeatureSection:Tab({ Title = "Misc", Icon = "star" }),
    Utility = FeatureSection:Tab({ Title = "Utility", Icon = "wrench" }),
    Settings = FeatureSection:Tab({ Title = "Settings", Icon = "settings" })
}

Tabs.Main:Section({ Title = "Server Info", TextSize = 20 })
Tabs.Main:Divider()

placeName = "Unknown"
success, productInfo = pcall(function()
    return MarketplaceService:GetProductInfo(placeId)
end)
if success and productInfo then
    placeName = productInfo.Name
end

Tabs.Main:Paragraph({
    Title = "Game Mode",
    Desc = placeName
})

Tabs.Main:Button({
    Title = "Copy Server Link",
    Desc = "Copy the current server's join link",
    Icon = "link",
    Callback = function()
        serverLink = string.format("https://www.roblox.com/games/start?placeId=%d&jobId=%s", placeId, jobId)
        pcall(function()
            setclipboard(serverLink)
        end)
    end
})

numPlayers = #Players:GetPlayers()
maxPlayers = Players.MaxPlayers

playerCountParagraph = Tabs.Main:Paragraph({
    Title = "Current Players",
    Desc = numPlayers .. " / " .. maxPlayers
})

RunService.Heartbeat:Connect(function()
    local modelCount = 0
    
    for _, player in ipairs(Players:GetPlayers()) do
        if workspace:FindFirstChild(player.Name) then
            modelCount = modelCount + 1
        end
    end
    
    playerCountParagraph:SetDesc(numPlayers .. " Online/ " .. maxPlayers .. "Max | Player Models Found: " .. modelCount .. "")
end)
ModelPlayerAntiBrokenServer = Tabs.Main:Paragraph({
    Title = "Player Model Server Status",
    Desc = "Waiting..."
})

playerModelCheckConnection = RunService.Heartbeat:Connect(function()
    local playerCount = #Players:GetPlayers()
    local modelCount = 0
    
    for _, player in ipairs(Players:GetPlayers()) do
        if workspace:FindFirstChild(player.Name) then
            modelCount = modelCount + 1
        end
    end
    
    if playerCount == modelCount then
        ModelPlayerAntiBrokenServer:SetDesc("Player Model Is Correct Definitely Playable")
    else
        ModelPlayerAntiBrokenServer:SetDesc("Unplayable Server Detected! Missing Player Model, Find a new server")
    end
end)
Tabs.Main:Paragraph({
    Title = "Server ID",
    Desc = jobId
})

Tabs.Main:Paragraph({
    Title = "Place ID",
    Desc = tostring(placeId)
})

Tabs.Main:Section({ Title = "Server Tools", TextSize = 20 })
Tabs.Main:Divider()

Tabs.Main:Button({
    Title = "Rejoin",
    Desc = "Rejoin the current server",
    Icon = "refresh-cw",
    Callback = function()
        TeleportService:Teleport(game.PlaceId, player)
    end
})

Tabs.Main:Button({
    Title = "Server Hop",
    Desc = "Hop to a random server",
    Icon = "shuffle",
    Callback = function()
        AllIDs = {}
        foundAnything = ""
        actualHour = os.date("!*t").hour
        Deleted = false
        S_T = game:GetService("TeleportService")
        S_H = game:GetService("HttpService")

        File = pcall(function()
            AllIDs = S_H:JSONDecode(readfile("server-hop-temp.json"))
        end)
        if not File then
            table.insert(AllIDs, actualHour)
            pcall(function()
                writefile("server-hop-temp.json", S_H:JSONEncode(AllIDs))
            end)
        end

        function TPReturner(placeId)
            local Site;
            if foundAnything == "" then
                Site = S_H:JSONDecode(game:HttpGet('https://games.roblox.com/v1/games/' .. placeId .. '/servers/Public?sortOrder=Asc&limit=100'))
            else
                Site = S_H:JSONDecode(game:HttpGet('https://games.roblox.com/v1/games/' .. placeId .. '/servers/Public?sortOrder=Asc&limit=100&cursor=' .. foundAnything))
            end
            local ID = ""
            if Site.nextPageCursor and Site.nextPageCursor ~= "null" and Site.nextPageCursor ~= nil then
                foundAnything = Site.nextPageCursor
            end
            local num = 0;
            for i,v in pairs(Site.data) do
                local Possible = true
                ID = tostring(v.id)
                if tonumber(v.maxPlayers) > tonumber(v.playing) then
                    for _,Existing in pairs(AllIDs) do
                        if num ~= 0 then
                            if ID == tostring(Existing) then
                                Possible = false
                            end
                        else
                            if tonumber(actualHour) ~= tonumber(Existing) then
                                local delFile = pcall(function()
                                    delfile("server-hop-temp.json")
                                    AllIDs = {}
                                    table.insert(AllIDs, actualHour)
                                end)
                            end
                        end
                        num = num + 1
                    end
                    if Possible == true then
                        table.insert(AllIDs, ID)
                        wait()
                        pcall(function()
                            writefile("server-hop-temp.json", S_H:JSONEncode(AllIDs))
                            wait()
                            S_T:TeleportToPlaceInstance(placeId, ID, game.Players.LocalPlayer)
                        end)
                        wait(4)
                    end
                end
            end
        end

        function Teleport(placeId)
            while wait() do
                pcall(function()
                    TPReturner(placeId)
                    if foundAnything ~= "" then
                        TPReturner(placeId)
                    end
                end)
            end
        end

        Teleport(game.PlaceId)
    end
})

Tabs.Main:Button({
    Title = "Hop to Small Server",
    Desc = "Hop to the smallest available server",
    Icon = "minimize",
    Callback = function()
        request = request or (http and http.request) or (syn and syn.request)
        if not request then
            return
        end

        response = request({
            Url = "https://games.roblox.com/v1/games/" .. placeId .. "/servers/Public?sortOrder=Asc&limit=100",
            Method = "GET",
        })

        if response.StatusCode == 200 then
            serverData = HttpService:JSONDecode(response.Body)
            smallestServer = nil
            smallestPlayerCount = math.huge

            for _, server in pairs(serverData.data) do
                if server.id ~= jobId and server.playing < server.maxPlayers and server.playing < smallestPlayerCount then
                    smallestPlayerCount = server.playing
                    smallestServer = server
                end
            end

            if smallestServer then
                TeleportService:TeleportToPlaceInstance(placeId, smallestServer.id, player)
            end
        end
    end
})

Tabs.Main:Button({
    Title = "Advanced Server Hop",
    Desc = "Finding a Server inside your game",
    Icon = "server",
    Callback = function()
        success, result = pcall(function()
            script = loadstring(game:HttpGet("https://raw.githubusercontent.com/Pnsdgsa/Script-kids/refs/heads/main/Advanced%20Server%20Hop.lua"))()
        end)
    end
})

Tabs.Player:Section({ Title = "Player", TextSize = 40 })
Tabs.Player:Divider()

character = nil
humanoid = nil
rootPart = nil

function onCharacterAdded(newCharacter)
    character = newCharacter
    humanoid = character:WaitForChild("Humanoid", 5)
    rootPart = character:WaitForChild("HumanoidRootPart", 5)
    if featureStates.JumpBoost and humanoid then
        humanoid.JumpPower = featureStates.JumpPower
        humanoid.JumpHeight = featureStates.JumpPower
        setupJumpBoost()
    end
    if featureStates.SpeedHack and humanoid then
        humanoid.WalkSpeed = featureStates.SpeedValue
    end
end

player.CharacterAdded:Connect(onCharacterAdded)
if player.Character then
    onCharacterAdded(player.Character)
end

UserInputService.JumpRequest:connect(function()
    if featureStates.InfiniteJump then
        player.Character:FindFirstChildOfClass'Humanoid':ChangeState("Jumping")
    end
end)

InfiniteJumpToggle = Tabs.Player:Toggle({
    Title = "Infinite Jump",
    Value = featureStates.InfiniteJump,
    Callback = function(state)
        featureStates.InfiniteJump = state
    end
})

SpeedToggle = Tabs.Player:Toggle({
    Title = "Speed Hack",
    Value = featureStates.SpeedHack,
    Callback = function(state)
        featureStates.SpeedHack = state
        if state and humanoid then
            humanoid.WalkSpeed = featureStates.SpeedValue
        elseif humanoid then
            humanoid.WalkSpeed = 16
        end
    end
})

SpeedSlider = Tabs.Player:Slider({
    Title = "Speed Value",
    Desc = "Adjust walk speed",
    Value = { Min = 16, Max = 200, Default = featureStates.SpeedValue, Step = 1 },
    Callback = function(value)
        featureStates.SpeedValue = value
        if featureStates.SpeedHack and humanoid then
            humanoid.WalkSpeed = value
        end
    end
})

Noclip = nil
Clip = nil

function noclip()
    Clip = false
    local function Nocl()
        if Clip == false and player.Character ~= nil then
            for _,v in pairs(player.Character:GetDescendants()) do
                if v:IsA('BasePart') and v.CanCollide then
                    v.CanCollide = false
                end
            end
        end
        wait(0.21)
    end
    Noclip = RunService.Stepped:Connect(Nocl)
end

function clip()
    if Noclip then 
        Noclip:Disconnect() 
    end
    Clip = true
    if player.Character then
        for _,v in pairs(player.Character:GetDescendants()) do
            if v:IsA('BasePart') then
                v.CanCollide = true
            end
        end
    end
end

NoclipToggle = Tabs.Player:Toggle({
    Title = "Noclip",
    Value = featureStates.Noclip,
    Callback = function(state)
        featureStates.Noclip = state
        if state then
            noclip()
        else
            clip()
        end
    end
})

flying = false
bodyVelocity = nil
bodyGyro = nil
flyConnection = nil

function startFlying()
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

function stopFlying()
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
end

function updateFly()
    if not flying or not bodyVelocity or not bodyGyro then return end
    camera = workspace.CurrentCamera
    cameraCFrame = camera.CFrame
    direction = Vector3.new(0, 0, 0)
    moveDirection = humanoid.MoveDirection
    if moveDirection.Magnitude > 0 then
        forwardVector = cameraCFrame.LookVector
        rightVector = cameraCFrame.RightVector
        forwardComponent = moveDirection:Dot(forwardVector) * forwardVector
        rightComponent = moveDirection:Dot(rightVector) * rightVector
        direction = direction + (forwardComponent + rightComponent).Unit * moveDirection.Magnitude
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.Space) or humanoid.Jump then
        direction = direction + Vector3.new(0, 1, 0)
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
        direction = direction - Vector3.new(0, 1, 0)
    end
    bodyVelocity.Velocity = direction.Magnitude > 0 and direction.Unit * (featureStates.FlySpeed * 2) or Vector3.new(0, 0, 0)
    bodyGyro.CFrame = cameraCFrame
end

FlyToggle = Tabs.Player:Toggle({
    Title = "Fly",
    Value = featureStates.Fly,
    Callback = function(state)
        featureStates.Fly = state
        if state then
            startFlying()
            flyConnection = RunService.Heartbeat:Connect(updateFly)
        else
            stopFlying()
            if flyConnection then
                flyConnection:Disconnect()
                flyConnection = nil
            end
        end
    end
})

FlySpeedSlider = Tabs.Player:Slider({
    Title = "Fly Speed",
    Value = { Min = 1, Max = 200, Default = featureStates.FlySpeed, Step = 1 },
    Desc = "Adjust fly speed",
    Callback = function(value)
        featureStates.FlySpeed = value
    end
})
local godModeEnabled = false
local godModeConnection = nil
local godModeMethod = "Health Math.huge"

local function applyHumanoidReplacement()
    local Char = player.Character
    local Human = Char and Char:FindFirstChildWhichIsA("Humanoid")
    if not Human then return end
    
    local nHuman = Human:Clone()
    nHuman.Parent = Char
    player.Character = nil
    nHuman:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
    nHuman:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
    nHuman:SetStateEnabled(Enum.HumanoidStateType.Physics, false)
    nHuman.BreakJointsOnDeath = true
    nHuman.MaxHealth = math.huge
    nHuman.Health = math.huge
    Human:Destroy()
    player.Character = Char
    nHuman.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
    
    local Script = Char:FindFirstChild("Animate")
    if Script then
        Script.Disabled = true
        wait()
        Script.Disabled = false
    end
end

local function applyHealthMathHuge()
    local Char = player.Character
    local Human = Char and Char:FindFirstChildWhichIsA("Humanoid")
    if not Human then return end
    
    Human.MaxHealth = math.huge
    Human.Health = math.huge
    
    Human:GetPropertyChangedSignal("Health"):Connect(function()
        if godModeEnabled and Human.Health < Human.MaxHealth then
            Human.Health = Human.MaxHealth
        end
    end)
end

local function applyGodMode()
    if godModeMethod == "Humanoid Replacement (Very buggy)" then
        applyHumanoidReplacement()
    elseif godModeMethod == "Health Math.huge" then
        applyHealthMathHuge()
    end
end

local function startGodMode()
    if godModeConnection then return end
    
    godModeConnection = RunService.Heartbeat:Connect(function()
        if godModeEnabled and player.Character then
            local Human = player.Character:FindFirstChildWhichIsA("Humanoid")
            if Human and Human.Health < math.huge then
                applyGodMode()
            end
        end
    end)
end

local function stopGodMode()
    if godModeConnection then
        godModeConnection:Disconnect()
        godModeConnection = nil
    end
end

GodModeToggle = Tabs.Player:Toggle({
    Title = "God Mode",
    Desc = "Become invincible",
    Value = false,
    Callback = function(state)
        godModeEnabled = state
        if state then
            applyGodMode()
            startGodMode()
        else
            stopGodMode()
        end
    end
})

GodModeMethodDropdown = Tabs.Player:Dropdown({
    Title = "God Mode Method",
    Values = {"Health Math.huge", "Humanoid Replacement (Very buggy)"},
    Value = "Health Math.huge",
    MenuWidth = 400,
    Callback = function(value)
        godModeMethod = value
        if godModeEnabled then
            applyGodMode()
        end
    end
})
ToggleTpwalk = false
TpwalkConnection = nil

function Tpwalking()
    if ToggleTpwalk and character and humanoid and rootPart then
        moveDirection = humanoid.MoveDirection
        moveDistance = featureStates.TpwalkValue
        origin = rootPart.Position
        direction = moveDirection * moveDistance
        targetPosition = origin + direction
        raycastParams = RaycastParams.new()
        raycastParams.FilterDescendantsInstances = {character}
        raycastParams.FilterType = Enum.RaycastFilterType.Exclude
        raycastResult = workspace:Raycast(origin, direction, raycastParams)
        if raycastResult then
            hitPosition = raycastResult.Position
            distanceToHit = (hitPosition - origin).Magnitude
            if distanceToHit < math.abs(moveDistance) then
                targetPosition = origin + (direction.Unit * (distanceToHit - 0.1))
            end
        end
        rootPart.CFrame = CFrame.new(targetPosition) * rootPart.CFrame.Rotation
        rootPart.CanCollide = true
    end
end

function startTpwalk()
    ToggleTpwalk = true
    if TpwalkConnection then
        TpwalkConnection:Disconnect()
    end
    TpwalkConnection = RunService.Heartbeat:Connect(Tpwalking)
end

function stopTpwalk()
    ToggleTpwalk = false
    if TpwalkConnection then
        TpwalkConnection:Disconnect()
        TpwalkConnection = nil
    end
    if rootPart then
        rootPart.CanCollide = false
    end
end

TPWALKToggle = Tabs.Player:Toggle({
    Title = "TP WALK",
    Value = featureStates.TPWALK,
    Callback = function(state)
        featureStates.TPWALK = state
        if state then
            startTpwalk()
        else
            stopTpwalk()
        end
    end
})

TPWALKSlider = Tabs.Player:Slider({
    Title = "TPWALK VALUE",
    Desc = "Adjust TPWALK speed",
    Value = { Min = 1, Max = 200, Default = featureStates.TpwalkValue, Step = 1 },
    Callback = function(value)
        featureStates.TpwalkValue = value
    end
})

jumpCount = 0
MAX_JUMPS = math.huge

function setupJumpBoost()
    if not character or not humanoid then return end
    humanoid.StateChanged:Connect(function(oldState, newState)
        if newState == Enum.HumanoidStateType.Landed then
            jumpCount = 0
        end
    end)
    humanoid.Jumping:Connect(function(isJumping)
        if isJumping and featureStates.JumpBoost and jumpCount < MAX_JUMPS then
            jumpCount = jumpCount + 1
            humanoid.JumpHeight = featureStates.JumpPower
            if jumpCount > 1 then
                rootPart:ApplyImpulse(Vector3.new(0, featureStates.JumpPower * rootPart.Mass, 0))
            end
        end
    end)
end

function startJumpBoost()
    if humanoid then
        humanoid.JumpPower = featureStates.JumpPower
        humanoid.JumpHeight = featureStates.JumpPower
    end
    setupJumpBoost()
end

function stopJumpBoost()
    jumpCount = 0
    if humanoid then
        humanoid.JumpPower = 50
        humanoid.JumpHeight = 50
    end
end

JumpBoostToggle = Tabs.Player:Toggle({
    Title = "Jump Height",
    Value = featureStates.JumpBoost,
    Callback = function(state)
        featureStates.JumpBoost = state
        if state then
            startJumpBoost()
        else
            stopJumpBoost()
        end
    end
})

JumpBoostSlider = Tabs.Player:Slider({
    Title = "Jump Power",
    Desc = "Adjust jump height",
    Value = { Min = 1, Max = 200, Default = featureStates.JumpPower, Step = 1 },
    Callback = function(value)
        featureStates.JumpPower = value
        if featureStates.JumpBoost then
            if humanoid then
                humanoid.JumpPower = featureStates.JumpPower
                humanoid.JumpHeight = featureStates.JumpPower
            end
        end
    end
})
Tabs.Combat:Section({ Title = "Combat", TextSize = 40 })
Tabs.Combat:Section({ Title = "Aimbot", TextSize = 20 })
Tabs.Combat:Divider()

local aimbotEnabled = false
local wallCheckEnabled = false
local smoothnessValue = 1
local targetRoles = {}
local aimPart = "Head"
local showFOV = false
local fovRadius = 100
local fovColor = Color3.fromRGB(128, 0, 128)

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local Cam = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local FOVring = Drawing.new("Circle")
FOVring.Visible = false
FOVring.Thickness = 2
FOVring.Color = fovColor
FOVring.Filled = false
FOVring.Radius = fovRadius
FOVring.Position = Cam.ViewportSize / 2

local function updateDrawings()
    FOVring.Position = Cam.ViewportSize / 2
    FOVring.Visible = showFOV and aimbotEnabled
    FOVring.Radius = fovRadius
    FOVring.Color = fovColor
end

local function getAimPart(character)
    if aimPart == "Head" then
        return character:FindFirstChild("Head")
    elseif aimPart == "Body" then
        return character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso") or character:FindFirstChild("HumanoidRootPart")
    elseif aimPart == "Legs" then
        return character:FindFirstChild("LowerTorso") or character:FindFirstChild("HumanoidRootPart")
    else
        return character:FindFirstChild("Head") or character:FindFirstChild("HumanoidRootPart")
    end
end

local function lookAt(pos)
    local currentCFrame = Cam.CFrame
    local lookVector = (pos - currentCFrame.Position).Unit
    local targetCFrame = CFrame.new(currentCFrame.Position, currentCFrame.Position + lookVector)
    
    Cam.CFrame = currentCFrame:Lerp(targetCFrame, 1 / smoothnessValue)
end

local function isVisible(part)
    if not wallCheckEnabled then return true end
    
    local origin = Cam.CFrame.Position
    local direction = part.Position - origin
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Blacklist
    rayParams.FilterDescendantsInstances = {LocalPlayer.Character}

    local result = workspace:Raycast(origin, direction, rayParams)
    return not result or result.Instance:IsDescendantOf(part.Parent)
end

local function getPlayerRole(plr)
    local playerKey = plr.Name
    return roleData[playerKey] and roleData[playerKey].Role
end

local function getClosestEnemyInFOV()
    local closestPlayer = nil
    local closestDistance = math.huge
    local screenCenter = Cam.ViewportSize / 2

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local char = player.Character
            if char then
                local aimPartInstance = getAimPart(char)
                if aimPartInstance then
                    local playerRole = getPlayerRole(player)
                    local shouldTarget = false
                    
                    if #targetRoles == 0 then
                        shouldTarget = true
                    else
                        for _, role in ipairs(targetRoles) do
                            if role == "Murderer" and playerRole == "Murderer" then
                                shouldTarget = true
                                break
                            elseif role == "Sheriff" and playerRole == "Sheriff" then
                                shouldTarget = true
                                break
                            elseif role == "Hero" and playerRole == "Hero" then
                                shouldTarget = true
                                break
                            elseif role == "Innocent" and (playerRole == "Innocent" or playerRole == nil) then
                                shouldTarget = true
                                break
                            end
                        end
                    end
                    
                    if shouldTarget then
                        local screenPos, visible = Cam:WorldToViewportPoint(aimPartInstance.Position)
                        local distance = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude

                        if visible and distance < fovRadius and distance < closestDistance and isVisible(aimPartInstance) then
                            closestDistance = distance
                            closestPlayer = player
                        end
                    end
                end
            end
        end
    end

    return closestPlayer
end

local aimbotConnection = nil

local function startAimbot()
    if aimbotConnection then return end
    
    aimbotConnection = RunService:BindToRenderStep("AimbotUpdate", Enum.RenderPriority.Camera.Value + 1, function()
        updateDrawings()
        if aimbotEnabled then
            local target = getClosestEnemyInFOV()
            if target and target.Character then
                local aimPartInstance = getAimPart(target.Character)
                if aimPartInstance then
                    lookAt(aimPartInstance.Position)
                end
            end
        end
    end)
end

local function stopAimbot()
    if aimbotConnection then
        RunService:UnbindFromRenderStep("AimbotUpdate")
        aimbotConnection = nil
    end
    FOVring.Visible = false
end

AimbotToggle = Tabs.Combat:Toggle({
    Title = "Camera Look Aimbot",
    Value = false,
    Callback = function(state)
        aimbotEnabled = state
        if state then
            startAimbot()
        else
            stopAimbot()
        end
    end
})

AimPartDropdown = Tabs.Combat:Dropdown({
    Title = "Aim Part",
    Values = {"Head", "Body", "Legs"},
    Value = "Head",
    Callback = function(value)
        aimPart = value
    end
})

TargetRoleDropdown = Tabs.Combat:Dropdown({
    Title = "Target Role",
    Values = {"Murderer", "Sheriff", "Hero", "Innocent"},
    Value = {},
    Multi = true,
    AllowNone = true,
    Callback = function(values)
        targetRoles = values
    end
})

SmoothnessSlider = Tabs.Combat:Slider({
    Title = "Smoothness",
    Desc = "Adjust aimbot smoothness",
    Value = { Min = 1, Max = 10, Default = 1, Step = 1 },
    Callback = function(value)
        smoothnessValue = value
    end
})

WallCheckToggle = Tabs.Combat:Toggle({
    Title = "Wall Check",
    Value = false,
    Callback = function(state)
        wallCheckEnabled = state
    end
})

Tabs.Combat:Section({ Title = "FOV Settings", TextSize = 20 })
Tabs.Combat:Divider()

ShowFOVToggle = Tabs.Combat:Toggle({
    Title = "Show FOV",
    Value = false,
    Callback = function(state)
        showFOV = state
        updateDrawings()
    end
})

FOVRadiusSlider = Tabs.Combat:Slider({
    Title = "FOV Radius",
    Desc = "Adjust FOV circle radius",
    Value = { Min = 10, Max = 500, Default = 100, Step = 1 },
    Callback = function(value)
        fovRadius = value
        updateDrawings()
    end
})

FOVColorPicker = Tabs.Combat:Colorpicker({
    Title = "FOV Color",
    Desc = "FOV Circle Color",
    Default = Color3.fromRGB(128, 0, 128),
    Transparency = 0,
    Locked = false,
    Callback = function(color) 
        fovColor = color
        updateDrawings()
    end
})
Tabs.Combat:Section({ Title = "Gun Combat", TextSize = 20 })
Tabs.Combat:Divider()
local sheriffButton = nil
local sheriffGui = nil
local sheriffButtonActive = false
local shotType = "Default"
local buttonSize = 60
local autoShootEnabled = false
local shootOffset = 0
local pingMultiplier = 0

local function makeDraggable(frame)
    frame.Active = true
    frame.Draggable = true
    
    local dragDetector = Instance.new("UIDragDetector")
    dragDetector.Parent = frame
    
    local originalBackground = frame.BackgroundColor3
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

local function GetMurderer()
    local success, roles = pcall(function()
        return ReplicatedStorage:FindFirstChild("GetPlayerData", true):InvokeServer()
    end)
    
    if not success or not roles then
        return nil
    end
    
    for name, data in pairs(roles) do
        if data.Role == "Murderer" then
            return Players:FindFirstChild(name)
        end
    end
    return nil
end

local function IsMurdererVisible(murderer)
    if not murderer or not murderer.Character then return false end
    
    local localChar = LocalPlayer.Character
    if not localChar then return false end
    
    local localHead = localChar:FindFirstChild("Head")
    local murdererHead = murderer.Character:FindFirstChild("Head")
    
    if not localHead or not murdererHead then return false end
    
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.FilterDescendantsInstances = {localChar, murderer.Character}
    
    local direction = (murdererHead.Position - localHead.Position)
    local raycastResult = workspace:Raycast(localHead.Position, direction, raycastParams)
    
    return raycastResult == nil
end

local function ShootMurderer()
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("Humanoid") or LocalPlayer.Character.Humanoid.Health <= 0 then
        return false
    end
    
    local murderer = GetMurderer()
    if not murderer or not murderer.Character or not murderer.Character:FindFirstChild("Humanoid") or murderer.Character.Humanoid.Health <= 0 then
        return false
    end
    
    if not IsMurdererVisible(murderer) then
        return false
    end
    
    local gun = LocalPlayer.Character:FindFirstChild("Gun") or LocalPlayer.Backpack:FindFirstChild("Gun")
    if not gun then
        return false
    end
    
    if gun and not LocalPlayer.Character:FindFirstChild("Gun") then
        gun.Parent = LocalPlayer.Character
    end
    
    gun = LocalPlayer.Character:FindFirstChild("Gun")
    if gun and gun:FindFirstChild("KnifeLocal") then
        local targetPart = murderer.Character:FindFirstChild("HumanoidRootPart")
        if targetPart then
            local targetPos = targetPart.Position
            local murdererHumanoid = murderer.Character:FindFirstChildOfClass("Humanoid")
            
            if shootOffset ~= 0 and murdererHumanoid then
                local moveDirection = murdererHumanoid.MoveDirection
                if moveDirection.Magnitude > 0 then
                    local offsetDirection = moveDirection.Unit
                    local finalOffset = shootOffset * pingMultiplier
                    targetPos = targetPos + (offsetDirection * finalOffset)
                end
            end
            
            local args = {[1] = 1, [2] = targetPos, [3] = "AH2"}
            gun.KnifeLocal.CreateBeam.RemoteFunction:InvokeServer(unpack(args))
            return true
        end
    end
    return false
end

local function startAutoShoot()
    while autoShootEnabled do
        ShootMurderer()
        task.wait(0.1)
    end
end

local function createSheriffGui()
    if sheriffGui then
        sheriffGui:Destroy()
        sheriffGui = nil
    end
    
    sheriffGui = Instance.new("ScreenGui")
    sheriffGui.Name = "SheriffGui"
    sheriffGui.IgnoreGuiInset = true
    sheriffGui.ResetOnSpawn = false
    sheriffGui.Enabled = true
    sheriffGui.Parent = game:GetService("CoreGui")

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, buttonSize, 0, buttonSize)
    frame.Position = UDim2.new(0.5, -30, 0.12, 0)
    frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    frame.BackgroundTransparency = 0.35
    frame.BorderSizePixel = 0
    frame.Parent = sheriffGui
    makeDraggable(frame)

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = frame

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(150, 150, 150)
    stroke.Thickness = 2
    stroke.Parent = frame

    local label = Instance.new("TextLabel")
    label.Text = "SHOT"
    label.Size = UDim2.new(0.9, 0, 0.5, 0)
    label.Position = UDim2.new(0.05, 0, 0, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.Font = Enum.Font.Roboto
    label.TextSize = 16
    label.TextXAlignment = Enum.TextXAlignment.Center
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.TextScaled = true
    label.Parent = frame

    sheriffButton = Instance.new("TextButton")
    sheriffButton.Name = "TriggerButton"
    sheriffButton.Text = "FIRE"
    sheriffButton.Size = UDim2.new(0.9, 0, 0.5, 0)
    sheriffButton.Position = UDim2.new(0.05, 0, 0.5, 0)
    sheriffButton.BackgroundColor3 = Color3.fromRGB(180, 0, 0)
    sheriffButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    sheriffButton.Font = Enum.Font.Roboto
    sheriffButton.TextSize = 14
    sheriffButton.TextXAlignment = Enum.TextXAlignment.Center
    sheriffButton.TextYAlignment = Enum.TextYAlignment.Center
    sheriffButton.TextScaled = true
    sheriffButton.Parent = frame

    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 4)
    buttonCorner.Parent = sheriffButton

    sheriffButton.MouseButton1Click:Connect(function()
        ShootMurderer()
    end)
    
    sheriffButtonActive = true
end

local function removeSheriffGui()
    if sheriffGui then
        sheriffGui:Destroy()
        sheriffGui = nil
    end
    sheriffButton = nil
    sheriffButtonActive = false
end

Tabs.Combat:Toggle({
    Title = "Auto Shoot Murderer",
    Value = false,
    Callback = function(state)
        autoShootEnabled = state
        if state then
            task.spawn(startAutoShoot)
        end
    end
})

Tabs.Combat:Input({
    Title = "Shoot Position Offset",
    Placeholder = "0",
    Value = "0",
    Callback = function(text)
        shootOffset = tonumber(text) or 0
    end
})

Tabs.Combat:Input({
    Title = "Offset-to-Ping Multiplier",
    Placeholder = "0",
    Value = "0",
    Callback = function(text)
        pingMultiplier = tonumber(text) or 1
    end
})

Tabs.Combat:Button({
    Title = "Shoot Murderer",
    Callback = function()
        ShootMurderer()
    end
})

Tabs.Combat:Button({
    Title = "Toggle Shot Button",
    Callback = function()
        if sheriffButtonActive then
            removeSheriffGui()
        else
            createSheriffGui()
        end
    end
})

Tabs.Combat:Slider({
    Title = "Button Size",
    Step = 1,
    Value = {Min = 40, Max = 100, Default = 60},
    Callback = function(size)
        buttonSize = size
        if sheriffButtonActive then
            removeSheriffGui()
            createSheriffGui()
        end
    end
})
local murderTpEnabled = false
local murderTpConnection = nil
local tpOffset = Vector3.new(0, 15, 0)

local function parseOffsetInput(input)
    local x, y, z = 0, 15, 0
    
    if input and input ~= "" then
        local cleaned = input:gsub("%s+", " "):gsub(",", " "):gsub("^%s+", ""):gsub("%s+$", "")
        local parts = {}
        for part in cleaned:gmatch("[%-%d%.]+") do
            table.insert(parts, tonumber(part))
        end
        
        if #parts >= 1 then x = parts[1] or 0 end
        if #parts >= 2 then y = parts[2] or 15 end
        if #parts >= 3 then z = parts[3] or 0 end
    end
    
    return Vector3.new(x, y, z)
end

local function StartMurderTp()
    if murderTpConnection then return end
    
    murderTpConnection = RunService.Heartbeat:Connect(function()
        if not murderTpEnabled then return end
        
        local character = LocalPlayer.Character
        if not character then return end
        
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if not rootPart then return end
        
        local murderer = GetMurderer()
        if not murderer or not murderer.Character then return end
        
        local murderRoot = murderer.Character:FindFirstChild("HumanoidRootPart")
        if not murderRoot then return end
        
        rootPart.CFrame = murderRoot.CFrame + tpOffset
        rootPart.Velocity = Vector3.new(0, 0, 0)
        rootPart.RotVelocity = Vector3.new(0, 0, 0)
        
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.PlatformStand = true
        end
    end)
end

local function StopMurderTp()
    if murderTpConnection then
        murderTpConnection:Disconnect()
        murderTpConnection = nil
    end
    
    local character = LocalPlayer.Character
    if character then
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.PlatformStand = false
        end
    end
end

Tabs.Combat:Input({
    Title = "TP Offset (X Y Z)",
    Placeholder = "0 15 0",
    Value = "0 15 0",
    Callback = function(text)
        tpOffset = parseOffsetInput(text)
    end
})

Tabs.Combat:Toggle({
    Title = "Murder CFrame TP",
    Value = false,
    Callback = function(state)
        murderTpEnabled = state
        if state then
            StartMurderTp()
        else
            StopMurderTp()
        end
    end
})
local GunSystem = {
    AutoGrabEnabled = false,
    NotifyGun = false,
    GunDropCheckInterval = 1,
    ActiveGunDrops = {},
    Mode = "Grab only"
}

local notifiedGunPickups = {}
local notifiedGunSpawns = {}

local character = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
local originalPosition = humanoidRootPart.Position

local function ScanForGunDrops()
    GunSystem.ActiveGunDrops = {}
    
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj.Name == "GunDrop" and obj:IsA("BasePart") then
            table.insert(GunSystem.ActiveGunDrops, obj)
        end
    end
end

local function EquipGun()
    if (player.Character and player.Character:FindFirstChild("Gun")) then
        return true
    end
    local gun = player.Backpack:FindFirstChild("Gun")
    if gun then
        gun.Parent = player.Character
        task.wait(0.1)
        return player.Character:FindFirstChild("Gun") ~= nil
    end
    return false
end

local function GetMurderer()
    local roles = ReplicatedStorage:FindFirstChild("GetPlayerData"):InvokeServer()
    for playerName, data in pairs(roles) do
        if (data.Role == "Murderer") then
            return Players:FindFirstChild(playerName)
        end
    end
end

local function ShootMurderer()
    local roles = ReplicatedStorage:FindFirstChild("GetPlayerData", true):InvokeServer()
    local murderer = nil
    for name, data in pairs(roles) do
        if (data.Role == "Murderer") then
            murderer = Players:FindFirstChild(name)
            break
        end
    end
    if (not murderer or not murderer.Character) then
        WindUI:Notify({Title = "Gun System", Content = "Murderer not found!", Icon = "x-circle", Duration = 3})
        return false
    end
    local targetRoot = murderer.Character:FindFirstChild("HumanoidRootPart")
    local localRoot = player.Character:FindFirstChild("HumanoidRootPart")
    if (targetRoot and localRoot) then
        localRoot.CFrame = targetRoot.CFrame * CFrame.new(0, 0, -4)
        task.wait(0.1)
    end
    local gun = player.Character:FindFirstChild("Gun")
    if not gun then
        WindUI:Notify({Title = "Gun System", Content = "Gun not equipped!", Icon = "x-circle", Duration = 3})
        return false
    end
    local targetPart = murderer.Character:FindFirstChild("HumanoidRootPart")
    if not targetPart then
        return false
    end
    local args = {[1] = 1, [2] = targetPart.Position, [3] = "AH2"}
    if (gun:FindFirstChild("KnifeLocal") and gun.KnifeLocal:FindFirstChild("CreateBeam")) then
        gun.KnifeLocal.CreateBeam.RemoteFunction:InvokeServer(unpack(args))
        WindUI:Notify({Title = "Gun System", Content = "Successfully shot the murderer!", Icon = "check-circle", Duration = 3})
        return true
    end
    return false
end

local function safeTeleport(cframe)
    pcall(function()
        if character and humanoidRootPart then
            humanoidRootPart.CFrame = cframe
        end
    end)
end

local function collectAllGunDrops()
    local currentPosition = humanoidRootPart.Position
    ScanForGunDrops()
    
    if #GunSystem.ActiveGunDrops == 0 then
        WindUI:Notify({Title = "Gun System", Content = "No guns available on the map", Icon = "x-circle", Duration = 3})
        return
    end
    
    for _, gunDrop in ipairs(GunSystem.ActiveGunDrops) do
        if gunDrop and gunDrop.Parent then
            safeTeleport(gunDrop.CFrame + Vector3.new(0, 3, 0))
            task.wait(0.05)
            safeTeleport(CFrame.new(currentPosition))
            task.wait(0.05)
        end
    end
    
    WindUI:Notify({Title = "Gun System", Content = "Successfully collected all guns!", Icon = "check-circle", Duration = 3})
end

local function ManualGrab()
    if GunSystem.Mode == "Grab only" then
        collectAllGunDrops()
    elseif GunSystem.Mode == "Grab & shoot murderer" then
        ScanForGunDrops()
        if (#GunSystem.ActiveGunDrops == 0) then
            WindUI:Notify({Title = "Gun System", Content = "No guns available on the map", Icon = "x-circle", Duration = 3})
            return false
        end
        
        local nearestGun = nil
        local minDistance = math.huge
        local character = player.Character
        local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")
        if humanoidRootPart then
            for _, drop in ipairs(GunSystem.ActiveGunDrops) do
                local distance = (humanoidRootPart.Position - drop.Position).Magnitude
                if (distance < minDistance) then
                    nearestGun = drop
                    minDistance = distance
                end
            end
        end
        
        if (nearestGun and player.Character) then
            local humanoidRootPart = player.Character:FindFirstChild("HumanoidRootPart")
            if humanoidRootPart then
                humanoidRootPart.CFrame = nearestGun.CFrame
                task.wait(0.3)
                local prompt = nearestGun:FindFirstChildOfClass("ProximityPrompt")
                if prompt then
                    fireproximityprompt(prompt)
                    WindUI:Notify({Title = "Gun System", Content = "Successfully grabbed the gun!", Icon = "check-circle", Duration = 3})
                    
                    task.wait(0.5)
                    if EquipGun() then
                        ShootMurderer()
                    end
                    
                    return true
                end
            end
        end
        return false
    end
end

local function ImprovedGrabOnly()
    local isTeleporting = false
    local teleportDelay = 0.5

    local function teleportLoop()
        if isTeleporting then return end
        isTeleporting = true
        
        local currentPosition = humanoidRootPart.Position
        ScanForGunDrops()
        
        if #GunSystem.ActiveGunDrops == 0 then
            isTeleporting = false
            return
        end
        
        for _, gunDrop in ipairs(GunSystem.ActiveGunDrops) do
            if gunDrop and gunDrop.Parent then
                safeTeleport(gunDrop.CFrame + Vector3.new(0, 3, 0))
                task.wait(0.05)
                safeTeleport(CFrame.new(currentPosition))
                task.wait(0.05)
            end
        end
        
        isTeleporting = false
    end

    while GunSystem.AutoGrabEnabled and GunSystem.Mode == "Grab only" do
        teleportLoop()
        task.wait(teleportDelay)
    end
end

local function AutoGrabGun()
    while GunSystem.AutoGrabEnabled do
        if GunSystem.Mode == "Grab only" then
            ImprovedGrabOnly()
        elseif GunSystem.Mode == "Grab & shoot murderer" then
            ScanForGunDrops()
            if ((#GunSystem.ActiveGunDrops > 0) and player.Character) then
                local humanoidRootPart = player.Character:FindFirstChild("HumanoidRootPart")
                if humanoidRootPart then
                    local nearestGun = nil
                    local minDistance = math.huge
                    for _, gunDrop in ipairs(GunSystem.ActiveGunDrops) do
                        local distance = (humanoidRootPart.Position - gunDrop.Position).Magnitude
                        if (distance < minDistance) then
                            nearestGun = gunDrop
                            minDistance = distance
                        end
                    end
                    if nearestGun then
                        humanoidRootPart.CFrame = nearestGun.CFrame
                        task.wait(0.3)
                        local prompt = nearestGun:FindFirstChildOfClass("ProximityPrompt")
                        if prompt then
                            fireproximityprompt(prompt)
                            
                            task.wait(0.5)
                            if EquipGun() then
                                ShootMurderer()
                            end
                            
                            task.wait(1)
                        end
                    end
                end
            end
            task.wait(GunSystem.GunDropCheckInterval)
        end
    end
end

local function monitorGunEvents()
    for _, otherPlayer in ipairs(Players:GetPlayers()) do
        if otherPlayer ~= player then
            otherPlayer.CharacterAdded:Connect(function(character)
                character.ChildAdded:Connect(function(child)
                    if child.Name == "Gun" and GunSystem.NotifyGun then
                        if not notifiedGunPickups[otherPlayer.Name] then
                            WindUI:Notify({
                                Title = "Gun System", 
                                Content = otherPlayer.Name .. " took the gun!", 
                                Icon = "alert-circle", 
                                Duration = 5
                            })
                            notifiedGunPickups[otherPlayer.Name] = true
                        end
                    end
                end)
            end)
            
            if otherPlayer.Character then
                otherPlayer.Character.ChildAdded:Connect(function(child)
                    if child.Name == "Gun" and GunSystem.NotifyGun then
                        if not notifiedGunPickups[otherPlayer.Name] then
                            WindUI:Notify({
                                Title = "Gun System", 
                                Content = otherPlayer.Name .. " took the gun!", 
                                Icon = "alert-circle", 
                                Duration = 5
                            })
                            notifiedGunPickups[otherPlayer.Name] = true
                        end
                    end
                end)
            end
        end
    end
    
    workspace.DescendantAdded:Connect(function(child)
        if child.Name == "GunDrop" and child:IsA("BasePart") and GunSystem.NotifyGun then
            if not notifiedGunSpawns[child] then
                WindUI:Notify({
                    Title = "Gun System", 
                    Content = "A gun has spawned!", 
                    Icon = "target", 
                    Duration = 5
                })
                notifiedGunSpawns[child] = true
            end
        end
    end)
end

local function resetGunNotifications()
    workspace.DescendantAdded:Connect(function(child)
        if child.Name == "GunDrop" and child:IsA("BasePart") then
            for playerName, _ in pairs(notifiedGunPickups) do
                notifiedGunPickups[playerName] = nil
            end
            notifiedGunSpawns[child] = nil
        end
    end)
end

player.CharacterAdded:Connect(function(newChar)
    character = newChar
    humanoidRootPart = newChar:WaitForChild("HumanoidRootPart")
    originalPosition = humanoidRootPart.Position
end)

Tabs.Combat:Toggle({
    Title = "Auto Grab Gun",
    Value = false,
    Callback = function(state)
        GunSystem.AutoGrabEnabled = state
        if state then
            coroutine.wrap(AutoGrabGun)()
        end
    end
})

Tabs.Combat:Button({
    Title = "Manual Grab Gun",
    Callback = function()
        ManualGrab()
    end
})

Tabs.Combat:Dropdown({
    Title = "Auto Grab Mode",
    Values = {"Grab only", "Grab & shoot murderer"},
    Value = "Grab only",
    Callback = function(value)
        GunSystem.Mode = value
    end
})

Tabs.Combat:Toggle({
    Title = "Notify Gun",
    Value = false,
    Callback = function(state)
        GunSystem.NotifyGun = state
    end
})
Tabs.Combat:Section({ Title = "Knife Combat", TextSize = 20 })
Tabs.Combat:Divider()

local killMode = "Kill Aura"
local killAuraRadius = 10
local autoKillEnabled = false
local showAuraCircle = false
local autoEquipKnife = false
local killConnection = nil
local auraConnection = nil
local anchoredPlayers = {}
local auraCircle = nil
local originalEquipState = false

local function findMurderer()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr.Backpack:FindFirstChild("Knife") or (plr.Character and plr.Character:FindFirstChild("Knife")) then
            return plr
        end
    end
    return nil
end

local function equipKnife()
    if not player.Character:FindFirstChild("Knife") then
        if player.Backpack:FindFirstChild("Knife") then
            player.Character:FindFirstChild("Humanoid"):EquipTool(player.Backpack:FindFirstChild("Knife"))
            return true
        end
        return false
    end
    return true
end

local function updateAuraCircle()
    if auraCircle and player.Character then
        local root = player.Character:FindFirstChild("HumanoidRootPart")
        if root then
            auraCircle.CFrame = root.CFrame * CFrame.Angles(0, 0, math.rad(90))
        end
    end
end

local function createAuraCircle()
    if auraCircle then
        auraCircle:Destroy()
        auraCircle = nil
    end
    
    if showAuraCircle and player.Character then
        local root = player.Character:FindFirstChild("HumanoidRootPart")
        if root then
            auraCircle = Instance.new("Part")
            auraCircle.Name = "AuraRange"
            auraCircle.Shape = Enum.PartType.Cylinder
            auraCircle.Material = Enum.Material.Neon
            auraCircle.BrickColor = BrickColor.new("Bright red")
            auraCircle.Transparency = 0.7
            auraCircle.Anchored = true
            auraCircle.CanCollide = false
            auraCircle.Size = Vector3.new(1, killAuraRadius * 2, killAuraRadius * 2)
            auraCircle.CFrame = root.CFrame * CFrame.Angles(0, 0, math.rad(90))
            auraCircle.Parent = workspace
            
            if auraConnection then
                auraConnection:Disconnect()
            end
            
            auraConnection = RunService.Heartbeat:Connect(function()
                updateAuraCircle()
            end)
        end
    else
        if auraConnection then
            auraConnection:Disconnect()
            auraConnection = nil
        end
        if auraCircle then
            auraCircle:Destroy()
            auraCircle = nil
        end
    end
end

local function unanchorPlayers()
    for _, targetPlayer in pairs(anchoredPlayers) do
        if targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
            targetPlayer.Character.HumanoidRootPart.Anchored = false
            targetPlayer.Character.HumanoidRootPart.CanCollide = true
        end
    end
    anchoredPlayers = {}
end

local function disablePlayerCollision(character)
    if character then
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end
end

local function killAura()
    local localRoot = player.Character:FindFirstChild("HumanoidRootPart")
    if not localRoot then return end
    
    local hasTargetInRange = false
    
    for _, targetPlayer in ipairs(Players:GetPlayers()) do
        if targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") and targetPlayer ~= player then
            local targetRoot = targetPlayer.Character.HumanoidRootPart
            local distance = (targetRoot.Position - localRoot.Position).Magnitude
            
            if distance <= tonumber(killAuraRadius) then
                hasTargetInRange = true
                targetRoot.Anchored = true
                targetRoot.CanCollide = false
                anchoredPlayers[targetPlayer] = targetPlayer
                targetRoot.CFrame = localRoot.CFrame + localRoot.CFrame.LookVector * 2
                disablePlayerCollision(targetPlayer.Character)
            end
        end    
    end
    
    if autoEquipKnife and hasTargetInRange then
        equipKnife()
    end
    
    local knife = player.Character:FindFirstChild("Knife")
    if (knife and knife:FindFirstChild("Stab")) then
        for i = 1, 3 do
            knife.Stab:FireServer("Down")
        end
    end
end

local function killNearby()
    local localRoot = player.Character:FindFirstChild("HumanoidRootPart")
    if not localRoot then return end
    
    local hasTargetClose = false
    
    for _, targetPlayer in ipairs(Players:GetPlayers()) do
        if targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") and targetPlayer ~= player then
            local targetRoot = targetPlayer.Character.HumanoidRootPart
            local distance = (targetRoot.Position - localRoot.Position).Magnitude
            
            if distance <= 5 then
                hasTargetClose = true
                break
            end
        end    
    end
    
    if autoEquipKnife and hasTargetClose then
        equipKnife()
    end
    
    local knife = player.Character:FindFirstChild("Knife")
    if (knife and knife:FindFirstChild("Stab")) then
        for i = 1, 5 do
            for j = 1, 3 do
                knife.Stab:FireServer("Down")
            end
            task.wait(0.1)
        end
    end
end

local function killAll()
    if autoEquipKnife then
        equipKnife()
    end
    
    local localRoot = player.Character:FindFirstChild("HumanoidRootPart")
    if not localRoot then return end
    
    for _, targetPlayer in ipairs(Players:GetPlayers()) do
        if targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") and targetPlayer ~= player then
            local targetRoot = targetPlayer.Character.HumanoidRootPart
            targetRoot.Anchored = true
            targetRoot.CanCollide = false
            anchoredPlayers[targetPlayer] = targetPlayer
            targetRoot.CFrame = localRoot.CFrame + localRoot.CFrame.LookVector * 2
            disablePlayerCollision(targetPlayer.Character)
        end    
    end
    
    local knife = player.Character:FindFirstChild("Knife")
    if (knife and knife:FindFirstChild("Stab")) then
        for i = 1, 3 do
            knife.Stab:FireServer("Down")
        end
    end
end

local function startAutoKill()
    if killConnection then return end
    
    killConnection = RunService.Heartbeat:Connect(function()
        if autoKillEnabled and findMurderer() == player then
            if killMode == "Kill Aura" then
                killAura()
            elseif killMode == "Kill Nearby" then
                killNearby()
            elseif killMode == "Kill All" then
                killAll()
            end
        end
    end)
end

local function stopAutoKill()
    if killConnection then
        killConnection:Disconnect()
        killConnection = nil
    end
    unanchorPlayers()
end

AutoEquipKnifeToggle = Tabs.Combat:Toggle({
    Title = "Auto Equip Knife",
    Value = false,
    Callback = function(state)
        autoEquipKnife = state
        originalEquipState = state
    end
})

KillModeDropdown = Tabs.Combat:Dropdown({
    Title = "Kill Mode",
    Values = {"Kill Aura", "Kill Nearby", "Kill All"},
    Value = "Kill Aura",
    Callback = function(value)
        killMode = value
        unanchorPlayers()
    end
})

KillAuraSlider = Tabs.Combat:Slider({
    Title = "Knife Kill Aura Rage",
    Desc = "Adjust kill aura radius",
    Value = { Min = 1, Max = 200, Default = 10, Step = 1 },
    Callback = function(value)
        killAuraRadius = tonumber(value)
        if auraCircle then
            auraCircle.Size = Vector3.new(1, killAuraRadius * 2, killAuraRadius * 2)
        end
    end
})

ShowAuraToggle = Tabs.Combat:Toggle({
    Title = "Show Aura Circle",
    Value = false,
    Callback = function(state)
        showAuraCircle = state
        createAuraCircle()
    end
})

AutoKillToggle = Tabs.Combat:Toggle({
    Title = "Auto Kill",
    Value = false,
    Callback = function(state)
        autoKillEnabled = state
        if state then
            startAutoKill()
        else
            stopAutoKill()
        end
    end
})
Tabs.Combat:Button({
    Title = "Kill All",
    Desc = "Teleport and kill all players",
    Icon = "target",
    Callback = function()
        if findMurderer() ~= player then return end
        
        if autoEquipKnife then
            equipKnife()
        end
        
        local localRoot = player.Character:FindFirstChild("HumanoidRootPart")
        if not localRoot then return end
        
        for _, targetPlayer in ipairs(Players:GetPlayers()) do
            if targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") and targetPlayer ~= player then
                local targetRoot = targetPlayer.Character.HumanoidRootPart
                targetRoot.Anchored = true
                targetRoot.CanCollide = false
                targetRoot.CFrame = localRoot.CFrame + localRoot.CFrame.LookVector * 2
                disablePlayerCollision(targetPlayer.Character)
            end    
        end
        
        local knife = player.Character:FindFirstChild("Knife")
        if (knife and knife:FindFirstChild("Stab")) then
            for i = 1, 3 do
                knife.Stab:FireServer("Down")
            end
        end
    end
})
task.spawn(function()
    if not player.Character then
        player.CharacterAdded:Wait()
    end
    ScanForGunDrops()
    if GunSystem.AutoGrabEnabled then
        coroutine.wrap(AutoGrabGun)()
    end
    monitorGunEvents()
    resetGunNotifications()
end)
Tabs.Visuals:Section({ Title = "Visual", TextSize = 20 })
    Tabs.Visuals:Divider()
    local cameraStretchConnection
local function setupCameraStretch()
    cameraStretchConnection = nil
    local stretchHorizontal = 0.80
    local stretchVertical = 0.80
    CameraStretchToggle = Tabs.Visuals:Toggle({
        Title = "Camera Stretch",
        Value = false,
        Callback = function(state)
            if state then
                if cameraStretchConnection then cameraStretchConnection:Disconnect() end
                cameraStretchConnection = game:GetService("RunService").RenderStepped:Connect(function()
                    local Camera = workspace.CurrentCamera
                    Camera.CFrame = Camera.CFrame * CFrame.new(0, 0, 0, stretchHorizontal, 0, 0, 0, stretchVertical, 0, 0, 0, 1)
                end)
            else
                if cameraStretchConnection then
                    cameraStretchConnection:Disconnect()
                    cameraStretchConnection = nil
                end
            end
        end
    })

    CameraStretchHorizontalInput = Tabs.Visuals:Input({
        Title = "Camera Stretch Horizontal",
        Placeholder = "0.80",
        Numeric = true,
        Value = tostring(stretchHorizontal),
        Callback = function(value)
            local num = tonumber(value)
            if num then
                stretchHorizontal = num
                if cameraStretchConnection then
                    cameraStretchConnection:Disconnect()
                    cameraStretchConnection = game:GetService("RunService").RenderStepped:Connect(function()
                        local Camera = workspace.CurrentCamera
                        Camera.CFrame = Camera.CFrame * CFrame.new(0, 0, 0, stretchHorizontal, 0, 0, 0, stretchVertical, 0, 0, 0, 1)
                    end)
                end
            end
        end
    })

    CameraStretchVerticalInput = Tabs.Visuals:Input({
        Title = "Camera Stretch Vertical",
        Placeholder = "0.80",
        Numeric = true,
        Value = tostring(stretchVertical),
        Callback = function(value)
            local num = tonumber(value)
            if num then
                stretchVertical = num
                if cameraStretchConnection then
                    cameraStretchConnection:Disconnect()
                    cameraStretchConnection = game:GetService("RunService").RenderStepped:Connect(function()
                        local Camera = workspace.CurrentCamera
                        Camera.CFrame = Camera.CFrame * CFrame.new(0, 0, 0, stretchHorizontal, 0, 0, 0, stretchVertical, 0, 0, 0, 1)
                    end)
                end
            end
        end
    })
end
	    FullBrightToggle = Tabs.Visuals:Toggle({
    Title = "Full Bright",
    Desc = "Ya Like drinking Night Vision while mining in da cave and sceard of creeper blow you up dawg?",
    Value = false,
    Callback = function(state)
        featureStates.FullBright = state
        if state then
            local Lighting = game:GetService("Lighting")
            
            featureStates.originalBrightness = Lighting.Brightness
            featureStates.originalAmbient = Lighting.Ambient
            featureStates.originalOutdoorAmbient = Lighting.OutdoorAmbient
            featureStates.originalColorShiftBottom = Lighting.ColorShift_Bottom
            featureStates.originalColorShiftTop = Lighting.ColorShift_Top
            
            local function applyFullBright()
                if Lighting.Brightness ~= 1 then
                    Lighting.Brightness = 1
                end
                if Lighting.Ambient ~= Color3.new(1, 1, 1) then
                    Lighting.Ambient = Color3.new(1, 1, 1)
                end
                if Lighting.OutdoorAmbient ~= Color3.new(1, 1, 1) then
                    Lighting.OutdoorAmbient = Color3.new(1, 1, 1)
                end
                if Lighting.ColorShift_Bottom ~= Color3.new(1, 1, 1) then
                    Lighting.ColorShift_Bottom = Color3.new(1, 1, 1)
                end
                if Lighting.ColorShift_Top ~= Color3.new(1, 1, 1) then
                    Lighting.ColorShift_Top = Color3.new(1, 1, 1)
                end
            end
            
            applyFullBright()
            
            if featureStates.fullBrightConnection then
                featureStates.fullBrightConnection:Disconnect()
            end
            
            featureStates.fullBrightConnection = RunService.Heartbeat:Connect(function()
                if featureStates.FullBright then
                    applyFullBright()
                end
            end)
            
            featureStates.fullBrightCharConnection = game.Players.LocalPlayer.CharacterAdded:Connect(function()
                task.wait(1)
                if featureStates.FullBright then
                    applyFullBright()
                end
            end)
            
        else
            if featureStates.fullBrightConnection then
                featureStates.fullBrightConnection:Disconnect()
                featureStates.fullBrightConnection = nil
            end
            
            if featureStates.fullBrightCharConnection then
                featureStates.fullBrightCharConnection:Disconnect()
                featureStates.fullBrightCharConnection = nil
            end
            
            if featureStates.originalBrightness then
                local Lighting = game:GetService("Lighting")
                Lighting.Brightness = featureStates.originalBrightness
                Lighting.Ambient = featureStates.originalAmbient
                Lighting.OutdoorAmbient = featureStates.originalOutdoorAmbient
                Lighting.ColorShift_Bottom = featureStates.originalColorShiftBottom
                Lighting.ColorShift_Top = featureStates.originalColorShiftTop
            end
        end
    end
})
local FOVSlider = Tabs.Visuals:Slider({
    Title = "Field of View",
    Value = { Min = 10, Max = 120, Default = originalFOV, Step = 1 },
    Callback = function(value)
        workspace.CurrentCamera.FieldOfView = tonumber(value)
    end
})
setupCameraStretch()
innocentEspElements = {}
murderEspElements = {}
sheriffEspElements = {}
coinEspElements = {}
gunEspElements = {}

playerEspConnection = nil
roleUpdateConnection = nil
roleData = {}
lastRoleUpdate = 0
roleUpdating = false
HighlightsConnection = nil
coinEspConnection = nil
gunEspConnection = nil

local getPlayerDataRemote = ReplicatedStorage:FindFirstChild("GetPlayerData", true)

featureStates.CoinESP = featureStates.CoinESP or {
    names = false,
    boxes = false,
    tracers = false,
    distance = false,
    boxType = "3D"
}

featureStates.GunESP = featureStates.GunESP or {
    names = false,
    boxes = false,
    tracers = false,
    distance = false,
    boxType = "3D"
}

featureStates.CoinHighlights = featureStates.CoinHighlights or false
featureStates.GunHighlights = featureStates.GunHighlights or false

local lastCoinSearch = 0
local lastGunSearch = 0
local coinCache = {}
local gunCache = {}
local cachedPlayers = {}
local lastPlayerCacheUpdate = 0

function isAnyRoleESPActive()
    local roles = {"InnocentESP", "MurderESP", "HeroSheriffESP", "CoinESP", "GunESP"}
    for _, role in ipairs(roles) do
        local states = featureStates[role]
        if states and (states.names or states.boxes or states.tracers or states.distance) then
            return true
        end
    end
    return false
end

local function checkAnyHighlights()
    return featureStates.InnocentHighlights or featureStates.MurderHighlights or featureStates.SheriffHeroHighlights or featureStates.CoinHighlights or featureStates.GunHighlights
end

function isAnyRoleNeeded()
    return isAnyRoleESPActive() or checkAnyHighlights()
end

function startRoleUpdating()
    if roleUpdating then return end
    roleUpdating = true
    updateRoles()
    roleUpdateConnection = RunService.Heartbeat:Connect(function()
        updateRoles()
    end)
end

function stopRoleUpdating()
    if roleUpdateConnection then
        roleUpdateConnection:Disconnect()
        roleUpdateConnection = nil
    end
    roleUpdating = false
    roleData = {}
end

function manageRoleUpdating()
    if isAnyRoleNeeded() then
        startRoleUpdating()
    else
        stopRoleUpdating()
    end
end

function updateRoles()
    if not getPlayerDataRemote then return end
    if tick() - lastRoleUpdate < 2 then return end
    lastRoleUpdate = tick()
    local success, roles = pcall(function()
        return getPlayerDataRemote:InvokeServer()
    end)
    if success and roles then
        roleData = {}
        for key, v in pairs(roles) do
            if v then
                roleData[key] = v
            end
        end
        refreshHighlights()
    end
end

function managePlayerESPConnection()
    local active = isAnyRoleESPActive()
    if active then
        if not playerEspConnection then
            playerEspConnection = RunService.RenderStepped:Connect(updateRoleESP)
        end
    else
        if playerEspConnection then
            playerEspConnection:Disconnect()
            playerEspConnection = nil
        end
    end
    manageRoleUpdating()
end

function manageHighlightsConnection()
    if checkAnyHighlights() then
        startHighlights()
    else
        stopHighlights()
    end
end

function manageCoinESPConnection()
    local coinActive = featureStates.CoinESP.names or featureStates.CoinESP.boxes or featureStates.CoinESP.tracers or featureStates.CoinESP.distance
    if coinActive then
        if not coinEspConnection then
            coinEspConnection = RunService.RenderStepped:Connect(updateCoinESP)
        end
    else
        if coinEspConnection then
            coinEspConnection:Disconnect()
            coinEspConnection = nil
            cleanupCoinElements()
        end
    end
end

function manageGunESPConnection()
    local gunActive = featureStates.GunESP.names or featureStates.GunESP.boxes or featureStates.GunESP.tracers or featureStates.GunESP.distance
    if gunActive then
        if not gunEspConnection then
            gunEspConnection = RunService.RenderStepped:Connect(updateGunESP)
        end
    else
        if gunEspConnection then
            gunEspConnection:Disconnect()
            gunEspConnection = nil
            cleanupGunElements()
        end
    end
end

function cleanupAllRoleElements()
    local elementTables = {innocentEspElements, murderEspElements, sheriffEspElements, coinEspElements, gunEspElements}
    for _, elemTable in ipairs(elementTables) do
        for target, esp in pairs(elemTable) do
            cleanupDrawingTable(esp)
            elemTable[target] = nil
        end
    end
end

function cleanupCoinElements()
    for target, esp in pairs(coinEspElements) do
        cleanupDrawingTable(esp)
        coinEspElements[target] = nil
    end
end

function cleanupGunElements()
    for target, esp in pairs(gunEspElements) do
        cleanupDrawingTable(esp)
        gunEspElements[target] = nil
    end
end

function getDistanceFromPlayer(targetPosition)
    if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then return 0 end
    return (targetPosition - player.Character.HumanoidRootPart.Position).Magnitude
end

function cleanupDrawingTable(drawingTable)
    for _, drawing in pairs(drawingTable) do
        if type(drawing) == "table" then
            for _, line in ipairs(drawing) do
                pcall(line.Remove, line)
            end
        else
            pcall(drawing.Remove, drawing)
        end
    end
end

function createESPObject()
    return {
        box = Drawing.new("Square"),
        tracer = Drawing.new("Line"),
        name = Drawing.new("Text"),
        distance = Drawing.new("Text"),
        boxLines = {}
    }
end

function setupESPObject(esp)
    esp.box.Thickness = 2
    esp.box.Filled = false
    esp.tracer.Thickness = 1
    esp.name.Size = 14
    esp.name.Center = true
    esp.name.Outline = true
    esp.distance.Size = 14
    esp.distance.Center = true
    esp.distance.Outline = true
end

function draw3DBox(esp, cf, pos, camera, boxColor, boxSize)
    if not cf or not camera then return end
    
    boxSize = boxSize or Vector3.new(4, 5, 3)
    local size = boxSize
    local offsets = {
        Vector3.new( size.X/2,  size.Y/2,  size.Z/2), Vector3.new( size.X/2,  size.Y/2, -size.Z/2),
        Vector3.new( size.X/2, -size.Y/2,  size.Z/2), Vector3.new( size.X/2, -size.Y/2, -size.Z/2),
        Vector3.new(-size.X/2,  size.Y/2,  size.Z/2), Vector3.new(-size.X/2,  size.Y/2, -size.Z/2),
        Vector3.new(-size.X/2, -size.Y/2,  size.Z/2), Vector3.new(-size.X/2, -size.Y/2, -size.Z/2),
    }
    
    local screenPoints = {}
    local anyPointOnScreen = false

    for i, offset in ipairs(offsets) do
        local success, vec, onScreen = pcall(function()
            local worldPos = cf * CFrame.Angles(0, math.rad(90), 0) * offset
            return camera:WorldToViewportPoint(worldPos)
        end)
        if success then
            screenPoints[i] = {pos = Vector2.new(vec.X, vec.Y), depth = vec.Z, onScreen = onScreen}
            if onScreen and vec.Z > 0 then anyPointOnScreen = true end
        end
    end

    if not esp.boxLines or #esp.boxLines == 0 then
        esp.boxLines = {}
        for i = 1, 12 do
            local line = Drawing.new("Line")
            line.Thickness = 1
            line.ZIndex = 2
            table.insert(esp.boxLines, line)
        end
    end

    local edges = {
        {1, 2}, {1, 3}, {1, 5}, {2, 4}, {2, 6},
        {3, 4}, {3, 7}, {5, 6}, {5, 7}, {4, 8}, {6, 8}, {7, 8}
    }

    local distance = (player.Character and player.Character:FindFirstChild("HumanoidRootPart") and 
        (player.Character.HumanoidRootPart.Position - pos).Magnitude) or 10
    local thickness = math.clamp(3 / (distance / 50), 1, 3)

    for i, edge in ipairs(edges) do
        local line = esp.boxLines[i]
        if line then
            local p1, p2 = screenPoints[edge[1]], screenPoints[edge[2]]
            line.Color = boxColor or Color3.fromRGB(255, 255, 255)
            line.Thickness = thickness
            line.Transparency = 1
            if anyPointOnScreen and p1 and p2 and p1.depth > 0 and p2.depth > 0 then
                line.From = p1.pos
                line.To = p2.pos
                line.Visible = true
            else
                line.Visible = false
            end
        end
    end
end

function getPlayerRole(plr)
    local playerKey = plr.Name
    return roleData[playerKey] and roleData[playerKey].Role
end

function findCoinServerParts()
    if tick() - lastCoinSearch < 3 then
        return coinCache
    end
    
    lastCoinSearch = tick()
    coinCache = {}
    
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("Part") and obj.Name == "Coin_Server" then
            table.insert(coinCache, obj)
        end
    end
    
    return coinCache
end

function findDropGunParts()
    if tick() - lastGunSearch < 3 then
        return gunCache
    end
    
    lastGunSearch = tick()
    gunCache = {}
    
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("Part") and obj.Name == "DropGun" then
            table.insert(gunCache, obj)
        end
    end
    
    return gunCache
end

function getCachedPlayers()
    if tick() - lastPlayerCacheUpdate < 1 then
        return cachedPlayers
    end
    
    lastPlayerCacheUpdate = tick()
    cachedPlayers = Players:GetPlayers()
    return cachedPlayers
end

function updateCoinESP()
    local camera = workspace.CurrentCamera
    if not camera then return end
    
    local screenBottomCenter = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y)
    local currentCoinTargets = {}
    
    local coins = findCoinServerParts()
    
    for _, coinPart in ipairs(coins) do
        if coinPart and coinPart.Parent then
            currentCoinTargets[coinPart] = true
            
            if not coinEspElements[coinPart] then
                coinEspElements[coinPart] = createESPObject()
                setupESPObject(coinEspElements[coinPart])
            end
            
            local esp = coinEspElements[coinPart]
            local vector, onScreen = camera:WorldToViewportPoint(coinPart.Position)
            
            if onScreen then
                local coinColor = Color3.fromRGB(255, 215, 0)
                local states = featureStates.CoinESP
                
                local topY = camera:WorldToViewportPoint(coinPart.Position + Vector3.new(0, 2, 0)).Y
                local bottomY = camera:WorldToViewportPoint(coinPart.Position - Vector3.new(0, 2, 0)).Y
                local size = math.max(10, (bottomY - topY) / 2)
                
                if states.boxes then
                    if states.boxType == "2D" then
                        esp.box.Visible = true
                        esp.box.Size = Vector2.new(size * 2, size * 2)
                        esp.box.Position = Vector2.new(vector.X - size, vector.Y - size)
                        esp.box.Color = coinColor
                        for _, line in ipairs(esp.boxLines) do line.Visible = false end
                    else
                        esp.box.Visible = false
                        pcall(draw3DBox, esp, coinPart.CFrame, coinPart.Position, camera, coinColor, Vector3.new(3, 3, 3))
                    end
                else
                    esp.box.Visible = false
                    for _, line in ipairs(esp.boxLines) do line.Visible = false end
                end
                
                esp.tracer.Visible = states.tracers
                if states.tracers then
                    esp.tracer.From = screenBottomCenter
                    esp.tracer.To = Vector2.new(vector.X, vector.Y)
                    esp.tracer.Color = coinColor
                end
                
                esp.name.Visible = states.names
                if states.names then
                    esp.name.Text = "Coin"
                    esp.name.Position = Vector2.new(vector.X, vector.Y - size - 15)
                    esp.name.Color = coinColor
                end
                
                esp.distance.Visible = states.distance
                if states.distance then
                    local distance = getDistanceFromPlayer(coinPart.Position)
                    esp.distance.Text = string.format("%.1f", distance)
                    esp.distance.Position = Vector2.new(vector.X, vector.Y + size + 5)
                    esp.distance.Color = coinColor
                end
            else
                esp.box.Visible = false
                esp.tracer.Visible = false
                esp.name.Visible = false
                esp.distance.Visible = false
                for _, line in ipairs(esp.boxLines) do line.Visible = false end
            end
        end
    end
    
    for target, esp in pairs(coinEspElements) do
        if not currentCoinTargets[target] then
            cleanupDrawingTable(esp)
            coinEspElements[target] = nil
        end
    end
end

function updateGunESP()
    local camera = workspace.CurrentCamera
    if not camera then return end
    
    local screenBottomCenter = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y)
    local currentGunTargets = {}
    
    local guns = findDropGunParts()
    
    for _, gunPart in ipairs(guns) do
        if gunPart and gunPart.Parent then
            currentGunTargets[gunPart] = true
            
            if not gunEspElements[gunPart] then
                gunEspElements[gunPart] = createESPObject()
                setupESPObject(gunEspElements[gunPart])
            end
            
            local esp = gunEspElements[gunPart]
            local vector, onScreen = camera:WorldToViewportPoint(gunPart.Position)
            
            if onScreen then
                local gunColor = Color3.fromRGB(255, 0, 255)
                local states = featureStates.GunESP
                
                local topY = camera:WorldToViewportPoint(gunPart.Position + Vector3.new(0, 2, 0)).Y
                local bottomY = camera:WorldToViewportPoint(gunPart.Position - Vector3.new(0, 2, 0)).Y
                local size = math.max(10, (bottomY - topY) / 2)
                
                if states.boxes then
                    if states.boxType == "2D" then
                        esp.box.Visible = true
                        esp.box.Size = Vector2.new(size * 2, size * 2)
                        esp.box.Position = Vector2.new(vector.X - size, vector.Y - size)
                        esp.box.Color = gunColor
                        for _, line in ipairs(esp.boxLines) do line.Visible = false end
                    else
                        esp.box.Visible = false
                        pcall(draw3DBox, esp, gunPart.CFrame, gunPart.Position, camera, gunColor, Vector3.new(3, 3, 3))
                    end
                else
                    esp.box.Visible = false
                    for _, line in ipairs(esp.boxLines) do line.Visible = false end
                end
                
                esp.tracer.Visible = states.tracers
                if states.tracers then
                    esp.tracer.From = screenBottomCenter
                    esp.tracer.To = Vector2.new(vector.X, vector.Y)
                    esp.tracer.Color = gunColor
                end
                
                esp.name.Visible = states.names
                if states.names then
                    esp.name.Text = "Gun"
                    esp.name.Position = Vector2.new(vector.X, vector.Y - size - 15)
                    esp.name.Color = gunColor
                end
                
                esp.distance.Visible = states.distance
                if states.distance then
                    local distance = getDistanceFromPlayer(gunPart.Position)
                    esp.distance.Text = string.format("%.1f", distance)
                    esp.distance.Position = Vector2.new(vector.X, vector.Y + size + 5)
                    esp.distance.Color = gunColor
                end
            else
                esp.box.Visible = false
                esp.tracer.Visible = false
                esp.name.Visible = false
                esp.distance.Visible = false
                for _, line in ipairs(esp.boxLines) do line.Visible = false end
            end
        end
    end
    
    for target, esp in pairs(gunEspElements) do
        if not currentGunTargets[target] then
            cleanupDrawingTable(esp)
            gunEspElements[target] = nil
        end
    end
end

function updateRoleESP()
    local camera = workspace.CurrentCamera
    if not camera then return end
    
    local screenBottomCenter = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y)
    local currentInnocentTargets = {}
    local currentMurderTargets = {}
    local currentSheriffTargets = {}

    local players = getCachedPlayers()

    for _, otherPlayer in ipairs(players) do
        if otherPlayer ~= player then
            local model = otherPlayer.Character
            if model then
                local hrp = model:FindFirstChild("HumanoidRootPart")
                local humanoid = model:FindFirstChild("Humanoid")
                if hrp and humanoid then
                    local playerRole = getPlayerRole(otherPlayer)
                    local isDead = humanoid.Health <= 0
                    local espColor, states, elements, currentTargets
                    if isDead then
                        espColor = Color3.fromRGB(255, 255, 255)
                        states = featureStates.InnocentESP
                        elements = innocentEspElements
                        currentTargets = currentInnocentTargets
                    elseif playerRole == "Murderer" then
                        espColor = Color3.fromRGB(255, 0, 0)
                        states = featureStates.MurderESP
                        elements = murderEspElements
                        currentTargets = currentMurderTargets
                    elseif playerRole == "Sheriff" then
                        espColor = Color3.fromRGB(0, 0, 255)
                        states = featureStates.HeroSheriffESP
                        elements = sheriffEspElements
                        currentTargets = currentSheriffTargets
                    elseif playerRole == "Hero" then
                        espColor = Color3.fromRGB(255, 255, 0)
                        states = featureStates.HeroSheriffESP
                        elements = sheriffEspElements
                        currentTargets = currentSheriffTargets
                    else
                        if playerRole == "Innocent" then
                            espColor = Color3.fromRGB(0, 255, 0)
                        else
                            espColor = Color3.fromRGB(255, 255, 255)
                        end
                        states = featureStates.InnocentESP
                        elements = innocentEspElements
                        currentTargets = currentInnocentTargets
                    end
                    local anyActive = states.names or states.boxes or states.tracers or states.distance
                    if anyActive then
                        currentTargets[model] = true
                        if not elements[model] then
                            elements[model] = createESPObject()
                            setupESPObject(elements[model])
                        end
                        local esp = elements[model]
                        local vector, onScreen = camera:WorldToViewportPoint(hrp.Position)
                        if onScreen then
                            local topY = camera:WorldToViewportPoint(hrp.Position + Vector3.new(0, 3, 0)).Y
                            local bottomY = camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0)).Y
                            local size = (bottomY - topY) / 2
                            local boxSize = humanoid and Vector3.new(2, humanoid.HipHeight + 5, 2) or Vector3.new(4, 5, 3)
                            if states.boxes then
                                if states.boxType == "2D" then
                                    esp.box.Visible = true
                                    esp.box.Size = Vector2.new(size * 2, size * 3)
                                    esp.box.Position = Vector2.new(vector.X - size, vector.Y - size * 1.5)
                                    esp.box.Color = espColor
                                    for _, line in ipairs(esp.boxLines) do line.Visible = false end
                                else
                                    esp.box.Visible = false
                                    pcall(draw3DBox, esp, hrp.CFrame, hrp.Position, camera, espColor, boxSize)
                                end
                            else
                                esp.box.Visible = false
                                for _, line in ipairs(esp.boxLines) do line.Visible = false end
                            end
                            esp.tracer.Visible = states.tracers
                            if states.tracers then
                                esp.tracer.From = screenBottomCenter
                                esp.tracer.To = Vector2.new(vector.X, vector.Y)
                                esp.tracer.Color = espColor
                            end
                            esp.name.Visible = states.names
                            if states.names then
                                esp.name.Text = otherPlayer.Name
                                esp.name.Position = Vector2.new(vector.X, vector.Y - size * 1.5 - 20)
                                esp.name.Color = espColor
                            end
                            esp.distance.Visible = states.distance
                            if states.distance then
                                local distance = getDistanceFromPlayer(hrp.Position)
                                esp.distance.Text = string.format("%.1f", distance)
                                esp.distance.Position = Vector2.new(vector.X, vector.Y + size * 1.5 + 5)
                                esp.distance.Color = espColor
                            end
                        else
                            esp.box.Visible = false
                            esp.tracer.Visible = false
                            esp.name.Visible = false
                            esp.distance.Visible = false
                            for _, line in ipairs(esp.boxLines) do line.Visible = false end
                        end
                    end
                end
            end
        end
    end

    for target, esp in pairs(innocentEspElements) do
        if not currentInnocentTargets[target] then
            cleanupDrawingTable(esp)
            innocentEspElements[target] = nil
        end
    end
    for target, esp in pairs(murderEspElements) do
        if not currentMurderTargets[target] then
            cleanupDrawingTable(esp)
            murderEspElements[target] = nil
        end
    end
    for target, esp in pairs(sheriffEspElements) do
        if not currentSheriffTargets[target] then
            cleanupDrawingTable(esp)
            sheriffEspElements[target] = nil
        end
    end
end

function startHighlights()
    if not HighlightsConnection then
        HighlightsConnection = RunService.Heartbeat:Connect(updateRoleHighlights)
    end
end

function stopHighlights()
    if HighlightsConnection then
        HighlightsConnection:Disconnect()
        HighlightsConnection = nil
        clearAllHighlights()
    end
end

function clearAllHighlights()
    for _, plr in pairs(getCachedPlayers()) do
        if plr.Character then
            local highlight = plr.Character:FindFirstChild("PlayerHighlight")
            if highlight then
                highlight:Destroy()
            end
        end
    end
    
    if featureStates.CoinHighlights or featureStates.GunHighlights then
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj:IsA("Part") and (obj.Name == "Coin_Server" or obj.Name == "DropGun") then
                local highlight = obj:FindFirstChild("ItemHighlight")
                if highlight then
                    highlight:Destroy()
                end
            end
        end
    end
end

function refreshHighlights()
    if not HighlightsConnection then return end
    clearAllHighlights()
end

function updateRoleHighlights()
    if not roleData then return end

    local sheriffName = nil
    for name, data in pairs(roleData) do
        if data.Role == "Sheriff" then
            sheriffName = name
            break
        end
    end
    local sheriffPlayer = sheriffName and Players:FindFirstChild(sheriffName)
    local isSheriffAlive = sheriffPlayer and IsAlive(sheriffPlayer, roleData)

    local players = getCachedPlayers()

    for _, plr in ipairs(players) do
        if plr ~= player and plr.Character then
            local model = plr.Character
            local highlight = model:FindFirstChild("PlayerHighlight")
            local data = roleData[plr.Name]
            local role = data and data.Role
            local isAlivePlayer = data and IsAlive(plr, roleData)
            local highlightEnabled = false
            if not role then
                highlightEnabled = featureStates.InnocentHighlights
            elseif role == "Murderer" then
                highlightEnabled = featureStates.MurderHighlights
            elseif role == "Sheriff" or role == "Hero" then
                highlightEnabled = featureStates.SheriffHeroHighlights
            else
                highlightEnabled = featureStates.InnocentHighlights
            end
            if highlightEnabled then
                local color
                if not data or not isAlivePlayer then
                    color = Color3.new(1,1,1)
                else
                    if role == "Murderer" then
                        color = Color3.fromRGB(225, 0, 0)
                    elseif role == "Sheriff" then
                        color = Color3.fromRGB(0, 0, 225)
                    elseif role == "Hero" and not isSheriffAlive then
                        color = Color3.fromRGB(255, 250, 0)
                    else
                        color = Color3.fromRGB(0, 225, 0)
                    end
                end
                local outlineColor = getOutlineColor(color)
                if not highlight then
                    highlight = Instance.new("Highlight")
                    highlight.Name = "PlayerHighlight"
                    highlight.Adornee = model
                    highlight.FillTransparency = 0.5
                    highlight.OutlineTransparency = 0
                    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    highlight.Parent = model
                end
                highlight.FillColor = color
                highlight.OutlineColor = outlineColor
            else
                if highlight then
                    highlight:Destroy()
                end
            end
        end
    end

    if featureStates.CoinHighlights then
        local coins = findCoinServerParts()
        for _, coinPart in ipairs(coins) do
            if coinPart and coinPart.Parent then
                local highlight = coinPart:FindFirstChild("ItemHighlight")
                if not highlight then
                    highlight = Instance.new("Highlight")
                    highlight.Name = "ItemHighlight"
                    highlight.Adornee = coinPart
                    highlight.FillTransparency = 0.5
                    highlight.OutlineTransparency = 0
                    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    highlight.Parent = coinPart
                end
                highlight.FillColor = Color3.fromRGB(255, 215, 0)
                highlight.OutlineColor = getOutlineColor(Color3.fromRGB(255, 215, 0))
            end
        end
    end

    if featureStates.GunHighlights then
        local guns = findDropGunParts()
        for _, gunPart in ipairs(guns) do
            if gunPart and gunPart.Parent then
                local highlight = gunPart:FindFirstChild("ItemHighlight")
                if not highlight then
                    highlight = Instance.new("Highlight")
                    highlight.Name = "ItemHighlight"
                    highlight.Adornee = gunPart
                    highlight.FillTransparency = 0.5
                    highlight.OutlineTransparency = 0
                    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    highlight.Parent = gunPart
                end
                highlight.FillColor = Color3.fromRGB(255, 0, 255)
                highlight.OutlineColor = getOutlineColor(Color3.fromRGB(255, 0, 255))
            end
        end
    end
end

Players.PlayerRemoving:Connect(function(plr)
    if plr.Character then
        local highlight = plr.Character:FindFirstChild("PlayerHighlight")
        if highlight then
            highlight:Destroy()
        end
    end
end)

coinEspConnection = RunService.RenderStepped:Connect(updateCoinESP)
gunEspConnection = RunService.RenderStepped:Connect(updateGunESP)

Tabs.Esp:Section({ Title = "Innocent ESP" })

InnocentNameESPToggle = Tabs.Esp:Toggle({
    Title = "Innocent Name ESP",
    Value = false,
    Callback = function(state)
        featureStates.InnocentESP.names = state
        managePlayerESPConnection()
    end
})

InnocentBoxESPToggle = Tabs.Esp:Toggle({
    Title = "Innocent Box ESP",
    Value = false,
    Callback = function(state)
        featureStates.InnocentESP.boxes = state
        managePlayerESPConnection()
    end
})

InnocentBoxTypeDropdown = Tabs.Esp:Dropdown({
    Title = "Innocent Box Type",
    Values = {"2D", "3D"},
    Value = "2D",
    Callback = function(value)
        featureStates.InnocentESP.boxType = value
    end
})

InnocentTracerToggle = Tabs.Esp:Toggle({
    Title = "Innocent Tracer",
    Value = false,
    Callback = function(state)
        featureStates.InnocentESP.tracers = state
        managePlayerESPConnection()
    end
})

InnocentDistanceESPToggle = Tabs.Esp:Toggle({
    Title = "Innocent Distance ESP",
    Value = false,
    Callback = function(state)
        featureStates.InnocentESP.distance = state
        managePlayerESPConnection()
    end
})

InnocentHighlightsToggle = Tabs.Esp:Toggle({
    Title = "Innocent Highlights",
    Value = false,
    Callback = function(state)
        featureStates.InnocentHighlights = state
        manageHighlightsConnection()
        refreshHighlights()
    end
})

Tabs.Esp:Section({ Title = "Murder ESP" })

MurderNameESPToggle = Tabs.Esp:Toggle({
    Title = "Murder Name ESP",
    Value = false,
    Callback = function(state)
        featureStates.MurderESP.names = state
        managePlayerESPConnection()
    end
})

MurderBoxESPToggle = Tabs.Esp:Toggle({
    Title = "Murder Box ESP",
    Value = false,
    Callback = function(state)
        featureStates.MurderESP.boxes = state
        managePlayerESPConnection()
    end
})

MurderBoxTypeDropdown = Tabs.Esp:Dropdown({
    Title = "Murder Box Type",
    Values = {"2D", "3D"},
    Value = "2D",
    Callback = function(value)
        featureStates.MurderESP.boxType = value
    end
})

MurderTracerToggle = Tabs.Esp:Toggle({
    Title = "Murder Tracer",
    Value = false,
    Callback = function(state)
        featureStates.MurderESP.tracers = state
        managePlayerESPConnection()
    end
})

MurderDistanceESPToggle = Tabs.Esp:Toggle({
    Title = "Murder Distance ESP",
    Value = false,
    Callback = function(state)
        featureStates.MurderESP.distance = state
        managePlayerESPConnection()
    end
})

MurderHighlightsToggle = Tabs.Esp:Toggle({
    Title = "Murder Highlights",
    Value = false,
    Callback = function(state)
        featureStates.MurderHighlights = state
        manageHighlightsConnection()
        refreshHighlights()
    end
})

Tabs.Esp:Section({ Title = "Hero/Sheriff ESP" })

HeroSheriffNameESPToggle = Tabs.Esp:Toggle({
    Title = "Hero/Sheriff Name ESP",
    Value = false,
    Callback = function(state)
        featureStates.HeroSheriffESP.names = state
        managePlayerESPConnection()
    end
})

HeroSheriffBoxESPToggle = Tabs.Esp:Toggle({
    Title = "Hero/Sheriff Box ESP",
    Value = false,
    Callback = function(state)
        featureStates.HeroSheriffESP.boxes = state
        managePlayerESPConnection()
    end
})

HeroSheriffBoxTypeDropdown = Tabs.Esp:Dropdown({
    Title = "Hero/Sheriff Box Type",
    Values = {"2D", "3D"},
    Value = "2D",
    Callback = function(value)
        featureStates.HeroSheriffESP.boxType = value
    end
})

HeroSheriffTracerToggle = Tabs.Esp:Toggle({
    Title = "Hero/Sheriff Tracer",
    Value = false,
    Callback = function(state)
        featureStates.HeroSheriffESP.tracers = state
        managePlayerESPConnection()
    end
})

HeroSheriffDistanceESPToggle = Tabs.Esp:Toggle({
    Title = "Hero/Sheriff Distance ESP",
    Value = false,
    Callback = function(state)
        featureStates.HeroSheriffESP.distance = state
        managePlayerESPConnection()
    end
})

SheriffHeroHighlightsToggle = Tabs.Esp:Toggle({
    Title = "Sheriff/Hero Highlights",
    Value = false,
    Callback = function(state)
        featureStates.SheriffHeroHighlights = state
        manageHighlightsConnection()
        refreshHighlights()
    end
})
Tabs.Esp:Section({ Title = "Gun ESP" })

GunNameESPToggle = Tabs.Esp:Toggle({
    Title = "Gun ESP",
    Value = false,
    Callback = function(state)
        featureStates.GunESP.names = state
        manageGunESPConnection()
    end
})

GunBoxESPToggle = Tabs.Esp:Toggle({
    Title = "Gun Box ESP",
    Value = false,
    Callback = function(state)
        featureStates.GunESP.boxes = state
        manageGunESPConnection()
    end
})

GunBoxTypeDropdown = Tabs.Esp:Dropdown({
    Title = "Gun Box Type",
    Values = {"2D", "3D"},
    Value = "3D",
    Callback = function(value)
        featureStates.GunESP.boxType = value
    end
})

GunTracerToggle = Tabs.Esp:Toggle({
    Title = "Gun Tracer",
    Value = false,
    Callback = function(state)
        featureStates.GunESP.tracers = state
        manageGunESPConnection()
    end
})

GunDistanceESPToggle = Tabs.Esp:Toggle({
    Title = "Gun Distance ESP",
    Value = false,
    Callback = function(state)
        featureStates.GunESP.distance = state
        manageGunESPConnection()
    end
})

GunHighlightsToggle = Tabs.Esp:Toggle({
    Title = "Gun Highlights",
    Value = false,
    Callback = function(state)
        featureStates.GunHighlights = state
        manageHighlightsConnection()
        refreshHighlights()
    end
})
Tabs.Esp:Section({ Title = "Coin ESP" })

CoinNameESPToggle = Tabs.Esp:Toggle({
    Title = "Coin ESP",
    Value = false,
    Callback = function(state)
        featureStates.CoinESP.names = state
        manageCoinESPConnection()
    end
})

CoinBoxESPToggle = Tabs.Esp:Toggle({
    Title = "Coin Box ESP",
    Value = false,
    Callback = function(state)
        featureStates.CoinESP.boxes = state
        manageCoinESPConnection()
    end
})

CoinBoxTypeDropdown = Tabs.Esp:Dropdown({
    Title = "Coin Box Type",
    Values = {"2D", "3D"},
    Value = "3D",
    Callback = function(value)
        featureStates.CoinESP.boxType = value
    end
})

CoinTracerToggle = Tabs.Esp:Toggle({
    Title = "Coin Tracer",
    Value = false,
    Callback = function(state)
        featureStates.CoinESP.tracers = state
        manageCoinESPConnection()
    end
})

CoinDistanceESPToggle = Tabs.Esp:Toggle({
    Title = "Coin Distance ESP",
    Value = false,
    Callback = function(state)
        featureStates.CoinESP.distance = state
        manageCoinESPConnection()
    end
})

CoinHighlightsToggle = Tabs.Esp:Toggle({
    Title = "Coin Highlights",
    Value = false,
    Callback = function(state)
        featureStates.CoinHighlights = state
        manageHighlightsConnection()
        refreshHighlights()
    end
})



Tabs.Teleport:Section({ Title = "Teleport", TextSize = 20 })
Tabs.Teleport:Divider()

function GetPlayerList()
    local playerList = {"Select a player"}
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= player then
            table.insert(playerList, plr.Name)
        end
    end
    return playerList
end

TeleportPlayerDropdown = Tabs.Teleport:Dropdown({
    Title = "Select Player",
    Values = GetPlayerList(),
    Value = "Select a player",
    Callback = function(value)
        selectedPlayerName = value
    end
})

function UpdatePlayerList()
    TeleportPlayerDropdown:Refresh(GetPlayerList(), "Select a player")
end

Tabs.Teleport:Button({
    Title = "Teleport to Player",
    Desc = "Teleport to the selected player",
    Icon = "user",
    Callback = function()
        if selectedPlayerName and selectedPlayerName ~= "Select a player" then
            targetPlayer = Players:FindFirstChild(selectedPlayerName)
            
            if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
                if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                    player.Character.HumanoidRootPart.CFrame = targetPlayer.Character.HumanoidRootPart.CFrame
                end
            end
        end
    end
})

Tabs.Teleport:Button({
    Title = "Teleport to Random Player",
    Desc = "Teleport to a random player in the server",
    Icon = "users",
    Callback = function()
        otherPlayers = {}
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= player and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                table.insert(otherPlayers, plr)
            end
        end
        
        if #otherPlayers > 0 then
            randomPlayer = otherPlayers[math.random(1, #otherPlayers)]
            if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                player.Character.HumanoidRootPart.CFrame = randomPlayer.Character.HumanoidRootPart.CFrame
            end
        end
    end
})

function FindMurderer()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr.Backpack:FindFirstChild("Knife") or (plr.Character and plr.Character:FindFirstChild("Knife")) then
            return plr
        end
    end
    return nil
end

function FindSheriff()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr.Backpack:FindFirstChild("Gun") or (plr.Character and plr.Character:FindFirstChild("Gun")) then
            return plr
        end
    end
    return nil
end

function FindDroppedGun()
    return workspace:FindFirstChild("DropGun")
end

function TeleportToCoin()
    local character = player.Character or player.CharacterAdded:Wait()
    local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

    local coinServer = workspace:FindFirstChild("Coin_Server")
    if not coinServer then
        return
    end

    local coins = {}
    for _, coin in ipairs(coinServer:GetChildren()) do
        if coin:IsA("BasePart") then
            table.insert(coins, coin)
        end
    end

    if #coins == 0 then
        return
    end

    local targetCoin = coins[math.random(1, #coins)]
    local targetPos = targetCoin.Position + Vector3.new(0, 5, 0)

    humanoidRootPart.CFrame = CFrame.new(targetPos)
end

function TeleportToMap()
    local character = player.Character or player.CharacterAdded:Wait()
    local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
    
    local spawnParts = {}
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and obj.Name == "Spawn" then
            table.insert(spawnParts, obj)
        end
    end
    
    if #spawnParts == 0 then
        return
    end
    
    local randomIndex = math.random(1, #spawnParts)
    local randomSpawn = spawnParts[randomIndex]
    
    humanoidRootPart.CFrame = randomSpawn.CFrame + Vector3.new(0, 5, 0)
end

function TeleportToLobby()
    local character = player.Character or player.CharacterAdded:Wait()
    local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
    
    local lobby = workspace:FindFirstChild("Lobby")
    if not lobby then
        return
    end
    
    local spawns = lobby:FindFirstChild("Spawns")
    if not spawns then
        return
    end
    
    local spawnLocations = {}
    for _, obj in pairs(spawns:GetChildren()) do
        if obj:IsA("SpawnLocation") then
            table.insert(spawnLocations, obj)
        end
    end
    
    if #spawnLocations == 0 then
        return
    end
    
    local randomIndex = math.random(1, #spawnLocations)
    local randomSpawn = spawnLocations[randomIndex]
    
    humanoidRootPart.CFrame = randomSpawn.CFrame + Vector3.new(0, 3, 0)
end
Tabs.Teleport:Button({
    Title = "Teleport to Innocent",
    Desc = "Teleport to a random innocent player",
    Icon = "user",
    Callback = function()
        murderer = FindMurderer()
        sheriff = FindSheriff()
        
        innocents = {}
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= player and plr ~= murderer and plr ~= sheriff and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                hasKnife = plr.Backpack:FindFirstChild("Knife") or (plr.Character and plr.Character:FindFirstChild("Knife"))
                hasGun = plr.Backpack:FindFirstChild("Gun") or (plr.Character and plr.Character:FindFirstChild("Gun"))
                if not hasKnife and not hasGun then
                    table.insert(innocents, plr)
                end
            end
        end
        
        if #innocents > 0 then
            randomInnocent = innocents[math.random(1, #innocents)]
            if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                player.Character.HumanoidRootPart.CFrame = randomInnocent.Character.HumanoidRootPart.CFrame
            end
        end
    end
})
Tabs.Teleport:Button({
    Title = "Teleport to Murderer",
    Icon = "user-x",
    Callback = function()
        murderer = FindMurderer()
        if murderer and murderer.Character and murderer.Character:FindFirstChild("HumanoidRootPart") then
            if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                player.Character.HumanoidRootPart.CFrame = murderer.Character.HumanoidRootPart.CFrame
            end
        end
    end
})

Tabs.Teleport:Button({
    Title = "Teleport to Sheriff",
    Icon = "user-check",
    Callback = function()
        sheriff = FindSheriff()
        if sheriff and sheriff.Character and sheriff.Character:FindFirstChild("HumanoidRootPart") then
            if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                player.Character.HumanoidRootPart.CFrame = sheriff.Character.HumanoidRootPart.CFrame
            end
        end
    end
})


Tabs.Teleport:Button({
    Title = "Teleport to Dropped Gun",
    Icon = "target",
    Callback = function()
        gun = FindDroppedGun()
        if gun then
            if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                player.Character.HumanoidRootPart.CFrame = CFrame.new(gun.Position)
            end
        end
    end
})

Tabs.Teleport:Button({
    Title = "Teleport to Coin",
    Icon = "dollar-sign",
    Callback = function()
        TeleportToCoin()
    end
})

Tabs.Teleport:Button({
    Title = "Teleport to Map",
    Icon = "map",
    Callback = function()
        TeleportToMap()
    end
})

Tabs.Teleport:Button({
    Title = "Teleport to Lobby",
    Icon = "home",
    Callback = function()
        TeleportToLobby()
    end
})

Players.PlayerAdded:Connect(function()
    UpdatePlayerList()
end)

Players.PlayerRemoving:Connect(function()
    UpdatePlayerList()
end)

player.CharacterAdded:Connect(function(newCharacter)
    character = newCharacter
    humanoid = character:WaitForChild("Humanoid", 5)
    rootPart = character:WaitForChild("HumanoidRootPart", 5)
end)

Tabs.Misc:Section({ Title = "Misc", TextSize = 40 })
Tabs.Misc:Divider()

AntiAFKConnection = nil

startAntiAFK = function()
    AntiAFKConnection = player.Idled:Connect(function()
        VirtualUser:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
        task.wait(1)
        VirtualUser:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
    end)
end

stopAntiAFK = function()
    if AntiAFKConnection then
        AntiAFKConnection:Disconnect()
        AntiAFKConnection = nil
    end
end

AntiAFKToggle = Tabs.Misc:Toggle({
    Title = "Anti AFK",
    Value = featureStates.AntiAFK,
    Callback = function(state)
        featureStates.AntiAFK = state
        if state then
            startAntiAFK()
        else
            stopAntiAFK()
        end
    end
})
Tabs.Misc:Section({ Title = "Auto Farm", TextSize = 20 })
Tabs.Misc:Divider()

local AutoFarm = {
    Enabled = false,
    Mode = "Teleport",
    TeleportDelay = 0,
    MoveSpeed = 50,
    Connection = nil,
    CoinCheckInterval = 0.5,
    CoinContainers = {
        "Factory",
        "Hospital3",
        "MilBase",
        "House2",
        "Workplace",
        "Mansion2",
        "BioLab",
        "Hotel",
        "Bank2",
        "PoliceStation",
        "ResearchFacility",
        "Lobby"
    }
}

local function findNearestCoin()
    local closestCoin = nil
    local shortestDistance = math.huge
    local character = player.Character
    local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then
        return nil
    end
    for _, containerName in ipairs(AutoFarm.CoinContainers) do
        local container = workspace:FindFirstChild(containerName)
        if container then
            local coinContainer =
                ((containerName == "Lobby") and container) or container:FindFirstChild("CoinContainer")
            if coinContainer then
                for _, coin in ipairs(coinContainer:GetChildren()) do
                    if coin:IsA("BasePart") then
                        local distance = (humanoidRootPart.Position - coin.Position).Magnitude
                        if (distance < shortestDistance) then
                            shortestDistance = distance
                            closestCoin = coin
                        end
                    end
                end
            end
        end
    end
    return closestCoin
end

local function teleportToCoin(coin)
    if (not coin or not player.Character) then
        return
    end
    local humanoidRootPart = player.Character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then
        return
    end
    humanoidRootPart.CFrame = CFrame.new(coin.Position + Vector3.new(0, 3, 0))
    task.wait(AutoFarm.TeleportDelay)
end

local function smoothMoveToCoin(coin)
    if (not coin or not player.Character) then
        return
    end
    local humanoidRootPart = player.Character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then
        return
    end
    local startTime = tick()
    local startPos = humanoidRootPart.Position
    local endPos = coin.Position + Vector3.new(0, 3, 0)
    local distance = (startPos - endPos).Magnitude
    local duration = distance / AutoFarm.MoveSpeed
    while ((tick() - startTime) < duration) and AutoFarm.Enabled do
        if (not coin or not coin.Parent) then
            break
        end
        local progress = math.min((tick() - startTime) / duration, 1)
        humanoidRootPart.CFrame = CFrame.new(startPos:Lerp(endPos, progress))
        task.wait()
    end
end

local function walkToCoin(coin)
    if (not coin or not player.Character) then
        return
    end
    local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
    if not humanoid then
        return
    end
    humanoid.WalkSpeed = 16
    humanoid:MoveTo(coin.Position + Vector3.new(0, 0, 3))
    local startTime = tick()
    while AutoFarm.Enabled and (humanoid.MoveDirection.Magnitude > 0) and ((tick() - startTime) < 10) do
        task.wait(0.5)
    end
end

local function collectCoin(coin)
    if (not coin or not player.Character) then
        return
    end
    local humanoidRootPart = player.Character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then
        return
    end
    firetouchinterest(humanoidRootPart, coin, 0)
    firetouchinterest(humanoidRootPart, coin, 1)
end

local function farmLoop()
    while AutoFarm.Enabled do
        local coin = findNearestCoin()
        if coin then
            if (AutoFarm.Mode == "Teleport") then
                teleportToCoin(coin)
            elseif (AutoFarm.Mode == "Smooth") then
                smoothMoveToCoin(coin)
            else
                walkToCoin(coin)
            end
            collectCoin(coin)
            task.wait(2)
        end
        task.wait(AutoFarm.CoinCheckInterval)
    end
end

Tabs.Misc:Toggle({
    Title = "Enable AutoFarm",
    Value = false,
    Callback = function(state)
        AutoFarm.Enabled = state
        if state then
            AutoFarm.Connection = task.spawn(farmLoop)
        else
            if AutoFarm.Connection then
                task.cancel(AutoFarm.Connection)
            end
        end
    end
})
Tabs.Misc:Dropdown({
    Title = "Movement Mode",
    Values = {"Teleport", "Smooth", "Walk"},
    Value = "Teleport",
    Callback = function(mode)
        AutoFarm.Mode = mode
    end
})

Tabs.Misc:Slider({
    Title = "Teleport Delay (sec)",
    Value = {Min = 0, Max = 1, Default = 0, Step = 0.1},
    Callback = function(value)
        AutoFarm.TeleportDelay = value
    end
})

Tabs.Misc:Slider({
    Title = "Smooth Move Speed",
    Value = {Min = 20, Max = 200, Default = 50},
    Callback = function(value)
        AutoFarm.MoveSpeed = value
    end
})

Tabs.Misc:Slider({
    Title = "Check Interval (sec)",
    Step = 0.1,
    Value = {Min = 0.1, Max = 2, Default = 0.5},
    Callback = function(value)
        AutoFarm.CoinCheckInterval = value
    end
})

Tabs.Utility:Button(
    {
        Title = "Dupe Emote All (Not working idk why)",
        Desc = "Unlock all emotes by pressing this button.",
        Callback = function()
            local player = game.Players.LocalPlayer
            local replicatedStorage = game:GetService("ReplicatedStorage")
            local playerGui = player:FindFirstChild("PlayerGui")
            if not playerGui then
                warn("PlayerGui not found")
                return
            end

            local mainGui = playerGui:FindFirstChild("MainGUI")
            if not mainGui then
                warn("MainGUI not found")
                return
            end

            local gameFrame = mainGui:FindFirstChild("Game")
            if not gameFrame then
                warn("Game frame not found")
                return
            end

            local emoteFrame = gameFrame:FindFirstChild("Emotes")
            if not emoteFrame then
                warn("Emote frame not found")
                return
            end

            local modulesFolder = replicatedStorage:FindFirstChild("Modules")
            if not modulesFolder then
                warn("Modules folder not found in ReplicatedStorage")
                return
            end

            local emoteModuleScript = modulesFolder:FindFirstChild("EmoteModule")
            if not emoteModuleScript then
                warn("EmoteModule not found")
                return
            end

            local success, emoteModule = pcall(require, emoteModuleScript)
            if not success then
                warn("Failed to require EmoteModule:", emoteModule)
                return
            end

            if emoteModule and typeof(emoteModule.GeneratePage) == "function" then
                emoteModule.GeneratePage(
                    {"headless", "zombie", "zen", "ninja", "floss", "dab", "sit"},
                    emoteFrame,
                    "PolleserHub EMOTES"
                )
                print("Emotes unlocked successfully!")
            else
                warn("GeneratePage function not found in EmoteModule")
            end
        end
    }
)

local hiddenfling = false
local movel = 0.1
local flingPower = 1e35

local function fling()
    local chr = player.Character
    if not chr then return end
    local hrp = chr:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    while hiddenfling and chr and hrp and hrp.Parent do
        local vel = hrp.Velocity
        hrp.Velocity = vel * flingPower + Vector3.new(0, flingPower, 0)
        RunService.RenderStepped:Wait()
        hrp.Velocity = vel
        RunService.Stepped:Wait()
        hrp.Velocity = vel + Vector3.new(0, movel, 0)
        movel = -movel
        RunService.Heartbeat:Wait()
    end
end

 TouchFlingToggle = Tabs.Utility:Toggle({
    Title = "Touch Fling",
    Value = false,
    Callback = function(state)
        hiddenfling = state
        if state then
            coroutine.wrap(fling)()
        end
    end
})

Tabs.Utility:Input({
    Title = "Fling Power",
    Placeholder = "Enter fling power (default: 1e35)",
    Callback = function(value)
        if value and value ~= "" then
            flingPower = tonumber(value) or 1e35
        end
    end
})
Tabs.Utility:Button({
    Title = "Fling Tool",
    Icon = "rbxassetid://3836615692",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/FilteringEnabled/FE/main/punch"))()
    end
})
local antiVoidActive = false
local originalDestroyHeight = workspace.FallenPartsDestroyHeight

local function enableAntiVoid()
    if antiVoidActive then return end
    antiVoidActive = true
    originalDestroyHeight = workspace.FallenPartsDestroyHeight
    workspace.FallenPartsDestroyHeight = -math.huge
end

local function disableAntiVoid()
    if not antiVoidActive then return end
    workspace.FallenPartsDestroyHeight = originalDestroyHeight
    antiVoidActive = false
end

Tabs.Utility:Toggle({
    Title = "Anti Void Damage",
    Value = false,
    Callback = function(state)
        if state then
            enableAntiVoid()
        else
            disableAntiVoid()
        end
    end
})
local infinitePositionEnabled = false
local savedPosition = nil
local positionConnection = nil
local positionTolerance = 0.1

local function lockPosition()
    local character = player.Character or player.CharacterAdded:Wait()
    local hrp = character:WaitForChild("HumanoidRootPart", 5)
    if not hrp then return end

    if not savedPosition then
        savedPosition = hrp.CFrame
    end

    positionConnection = RunService.Heartbeat:Connect(function()
        if hrp and hrp.Parent and savedPosition then
            if (hrp.Position - savedPosition.Position).Magnitude > positionTolerance then
                hrp.CFrame = savedPosition
                hrp.Velocity = Vector3.new(0, 0, 0)
                hrp.RotVelocity = Vector3.new(0, 0, 0)
            end
        end
    end)
end

local function unlockPosition()
    if positionConnection then
        positionConnection:Disconnect()
        positionConnection = nil
    end
    savedPosition = nil
end

InfinitePositionToggle = Tabs.Utility:Toggle({
    Title = "Infinite Position Lock",
    Desc = "Lock your position in place",
    Value = false,
    Callback = function(state)
        infinitePositionEnabled = state
        if state then
            lockPosition()
            player.CharacterAdded:Connect(function()
                if infinitePositionEnabled then
                    task.wait(0.1)
                    lockPosition()
                end
            end)
        else
            unlockPosition()
        end
    end
})
TimeChangerInput = Tabs.Utility:Input({
    Title = "Set Time (HH:MM)",
    Placeholder = "12:00",
    Callback = function(value)
        value = value:gsub("^%s*(.-)%s*$", "%1")
        
        local h_str, m_str = value:match("(%d+):(%d+)")
        if h_str and m_str then
            local h = tonumber(h_str)
            local m = tonumber(m_str)
            
            if h and m and h >= 0 and h <= 23 and m >= 0 and m <= 59 and #h_str <= 2 and #m_str <= 2 then
                local totalHours = h + (m / 60)
                game:GetService("Lighting").ClockTime = totalHours
             end
        end
    end
})
getgenv().lagSwitchEnabled = false
getgenv().lagDuration = 0.5
local lagGui = nil
local lagGuiButton = nil
local lagInputConnection = nil
local isLagActive = false
local lagSystemLoaded = false

local function makeDraggable(frame)
    frame.Active = true
    frame.Draggable = true
    
    local dragDetector = Instance.new("UIDragDetector")
    dragDetector.Parent = frame
    
    local originalBackground = frame.BackgroundColor3
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

local function loadLagSystem()
    if lagSystemLoaded then return end
    lagSystemLoaded = true
    
    if not lagInputConnection then
        lagInputConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if gameProcessed then return end
            if input.KeyCode == Enum.KeyCode.L and getgenv().lagSwitchEnabled and not isLagActive then
                isLagActive = true
                task.spawn(function()
                    local duration = getgenv().lagDuration or 0.5
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

local function checkLagState()
    local shouldLoad = getgenv().lagSwitchEnabled
    
    if shouldLoad and not lagSystemLoaded then
        loadLagSystem()
    elseif not shouldLoad and lagSystemLoaded then
        unloadLagSystem()
    end
end

local function createLagGui(yOffset)
    local lagGuiOld = playerGui:FindFirstChild("LagSwitchGui")
    if lagGuiOld then lagGuiOld:Destroy() end
    
    lagGui = Instance.new("ScreenGui")
    lagGui.Name = "LagSwitchGui"
    lagGui.IgnoreGuiInset = true
    lagGui.ResetOnSpawn = false
    lagGui.Enabled = getgenv().lagSwitchEnabled
    lagGui.Parent = playerGui

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 60, 0, 60)
    frame.Position = UDim2.new(0.5, -30, 0.12 + (yOffset or 0), 0)
    frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    frame.BackgroundTransparency = 0.35
    frame.BorderSizePixel = 0
    frame.Parent = lagGui
    makeDraggable(frame)

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = frame

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(150, 150, 150)
    stroke.Thickness = 2
    stroke.Parent = frame

    local label = Instance.new("TextLabel")
    label.Text = "Lag"
    label.Size = UDim2.new(0.9, 0, 0.5, 0)
    label.Position = UDim2.new(0.05, 0, 0, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.Font = Enum.Font.Roboto
    label.TextSize = 16
    label.TextXAlignment = Enum.TextXAlignment.Center
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.TextScaled = true
    label.Parent = frame

    lagGuiButton = Instance.new("TextButton")
    lagGuiButton.Name = "TriggerButton"
    lagGuiButton.Text = "Trigger"
    lagGuiButton.Size = UDim2.new(0.9, 0, 0.5, 0)
    lagGuiButton.Position = UDim2.new(0.05, 0, 0.5, 0)
    lagGuiButton.BackgroundColor3 = Color3.fromRGB(0, 120, 80)
    lagGuiButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    lagGuiButton.Font = Enum.Font.Roboto
    lagGuiButton.TextSize = 14
    lagGuiButton.TextXAlignment = Enum.TextXAlignment.Center
    lagGuiButton.TextYAlignment = Enum.TextYAlignment.Center
    lagGuiButton.TextScaled = true
    lagGuiButton.Parent = frame

    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 4)
    buttonCorner.Parent = lagGuiButton

    lagGuiButton.MouseButton1Click:Connect(function()
        if not isLagActive then
            isLagActive = true
            task.spawn(function()
                local start = tick()
                while tick() - start < (getgenv().lagDuration or 0.5) do
                    local a = math.random(1, 1000000) * math.random(1, 1000000)
                    a = a / math.random(1, 10000)
                end
                isLagActive = false
            end)
        end
    end)
end

LagSwitchToggle = Tabs.Utility:Toggle({
    Title = "Lag Switch",
    Icon = "zap",
    Value = false,
    Callback = function(state)
        getgenv().lagSwitchEnabled = state
        if state then
            if not lagGui then
                createLagGui(0)
            else
                lagGui.Enabled = true
            end
        else
            if lagGui then
                lagGui.Enabled = false
            end
        end
        checkLagState()
    end
})

LagDurationInput = Tabs.Utility:Input({
    Title = "Lag Duration (seconds)",
    Placeholder = "0.5",
    Value = tostring(getgenv().lagDuration),
    NumbersOnly = true,
    Callback = function(text)
        local n = tonumber(text)
        if n and n > 0 then
            getgenv().lagDuration = n
        end
    end
})

Players.PlayerRemoving:Connect(function(leavingPlayer)
    if leavingPlayer == player then
        unloadLagSystem()
        if lagGui then
            lagGui:Destroy()
        end
    end
end)

checkLagState()
GravityToggle = Tabs.Utility:Toggle({
    Title = "Custom Gravity",
    Value = false,
    Callback = function(state)
        featureStates.CustomGravity = state
        if state then
            workspace.Gravity = featureStates.GravityValue
        else
            workspace.Gravity = originalGameGravity
        end
    end
})

GravityInput = Tabs.Utility:Input({
    Title = "Gravity Value",
    Placeholder = tostring(originalGameGravity),
    Value = tostring(featureStates.GravityValue),
    Callback = function(text)
        local num = tonumber(text)
        if num then
            featureStates.GravityValue = num
            if featureStates.CustomGravity then
                workspace.Gravity = num
            end
        end
    end
})
getgenv().gravityGuiVisible = false

GravityGUIToggle = Tabs.Utility:Toggle({
    Title = "Gravity toggle shortcuts",
    Desc = "Toggle gui or keybind for quick enable gravity",
    Icon = "toggle-right",
    Value = false,
    Callback = function(state)
        getgenv().gravityGuiVisible = state
        local gravityGui = game:GetService("Players").LocalPlayer.PlayerGui:FindFirstChild("GravityGui")
        if gravityGui then
            gravityGui.Enabled = state
        end
        if not state then
            WindUI:Notify({
                Title = "Gravity GUI",
                Content = "GUI And keybind disabled.",
                Duration = 3
            })
        else
            WindUI:Notify({
                Title = "Gravity toggle shortcuts",
                Content = "GUI is enabled or Press J to toggle gravity.",
                Duration = 3
            })
        end
    end
})
featureStates.NoRender = false
featureStates.NoRenderColor = Color3.fromRGB(0, 0, 0)

NoRenderToggle = Tabs.Utility:Toggle({
    Title = "No Render",
    Desc = "Disable 3D rendering for performance",
    Value = false,
    Callback = function(state)
        featureStates.NoRender = state
        game:GetService("RunService"):Set3dRenderingEnabled(not state)
        
        if state then
            local gui = Instance.new("ScreenGui")
            gui.Name = "NoRenderBackground"
            gui.IgnoreGuiInset = true
            gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
            gui.ResetOnSpawn = false
            
            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(1, 0, 1, 0)
            frame.BackgroundColor3 = featureStates.NoRenderColor
            frame.BorderSizePixel = 0
            frame.Parent = gui
            
            gui.Parent = player.PlayerGui
        else
            local gui = player.PlayerGui:FindFirstChild("NoRenderBackground")
            if gui then
                gui:Destroy()
            end
        end
    end
})

NoRenderColorPicker = Tabs.Utility:Colorpicker({
    Title = "No Render Color",
    Desc = "Choose background color when No Render is enabled",
    Default = Color3.fromRGB(0, 0, 0),
    Transparency = 0,
    Callback = function(color)
        featureStates.NoRenderColor = color
        
        if featureStates.NoRender then
            local gui = player.PlayerGui:FindFirstChild("NoRenderBackground")
            if gui then
                local frame = gui:FindFirstChildOfClass("Frame")
                if frame then
                    frame.BackgroundColor3 = color
                end
            end
        end
    end
})
featureStates.RemoveTextures = false

RemoveTexturesButton = Tabs.Utility:Button({
    Title = "Remove Textures",
    Callback = function()
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
})
game:GetService("Players").PlayerRemoving:Connect(function(leavingPlayer)
    if leavingPlayer == player then
        game:GetService("RunService"):Set3dRenderingEnabled(true)
    end
end)
LowQualityButton = Tabs.Utility:Button({
    Title = "Low Quality",
    Desc = "Disable textures, effects, and optimize graphics",
    Callback = function()
        local ToDisable = {
            Textures = true,
            VisualEffects = true,
            Parts = true,
            Particles = true,
            Sky = true
        }

        local ToEnable = {
            FullBright = false
        }

        local Stuff = {}

        for _, v in next, game:GetDescendants() do
            if ToDisable.Parts then
                if v:IsA("Part") or v:IsA("UnionOperation") or v:IsA("BasePart") then
                    v.Material = Enum.Material.SmoothPlastic
                    table.insert(Stuff, 1, v)
                end
            end
            
            if ToDisable.Particles then
                if v:IsA("ParticleEmitter") or v:IsA("Smoke") or v:IsA("Explosion") or v:IsA("Sparkles") or v:IsA("Fire") then
                    v.Enabled = false
                    table.insert(Stuff, 1, v)
                end
            end
            
            if ToDisable.VisualEffects then
                if v:IsA("BloomEffect") or v:IsA("BlurEffect") or v:IsA("DepthOfFieldEffect") or v:IsA("SunRaysEffect") then
                    v.Enabled = false
                    table.insert(Stuff, 1, v)
                end
            end
            
            if ToDisable.Textures then
                if v:IsA("Decal") or v:IsA("Texture") then
                    v.Texture = ""
                    table.insert(Stuff, 1, v)
                end
            end
            
            if ToDisable.Sky then
                if v:IsA("Sky") then
                    v.Parent = nil
                    table.insert(Stuff, 1, v)
                end
            end
        end

        if ToEnable.FullBright then
            local Lighting = game:GetService("Lighting")
            
            Lighting.FogColor = Color3.fromRGB(255, 255, 255)
            Lighting.FogEnd = math.huge
            Lighting.FogStart = math.huge
            Lighting.Ambient = Color3.fromRGB(255, 255, 255)
            Lighting.Brightness = 5
            Lighting.ColorShift_Bottom = Color3.fromRGB(255, 255, 255)
            Lighting.ColorShift_Top = Color3.fromRGB(255, 255, 255)
            Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
            Lighting.Outlines = true
        end
    end
})
local disablePlayerCollisions = false
local collisionConnection = nil

local function disableAllPlayerCollisions()
    for _, targetPlayer in ipairs(Players:GetPlayers()) do
        if targetPlayer.Character and targetPlayer ~= player then
            for _, part in ipairs(targetPlayer.Character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end
    end
end

local function enableAllPlayerCollisions()
    for _, targetPlayer in ipairs(Players:GetPlayers()) do
        if targetPlayer.Character and targetPlayer ~= player then
            for _, part in ipairs(targetPlayer.Character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = true
                end
            end
        end
    end
end

local function startCollisionDisable()
    if collisionConnection then return end
    
    collisionConnection = RunService.Heartbeat:Connect(function()
        if disablePlayerCollisions then
            disableAllPlayerCollisions()
        end
    end)
end

local function stopCollisionDisable()
    if collisionConnection then
        collisionConnection:Disconnect()
        collisionConnection = nil
    end
    enableAllPlayerCollisions()
end

DisableCollisionsToggle = Tabs.Utility:Toggle({
    Title = "Disable Player Collisions",
    Value = false,
    Callback = function(state)
        disablePlayerCollisions = state
        if state then
            startCollisionDisable()
        else
            stopCollisionDisable()
        end
    end
})
Tabs.Settings:Section({ Title = "Configuration", TextSize = 20 })
Tabs.Settings:Divider()

ConfigNameInput = Tabs.Settings:Input({
    Title = "Config Name",
    Placeholder = "Enter config name",
    Callback = function(value)
        configFileName = value
    end
})

Tabs.Settings:Button({
    Title = "Save Configuration",
    Desc = "Save current settings to file",
    Icon = "save",
    Callback = function()
        success, error = pcall(function()
            if not isfolder("mm2") then
                makefolder("mm2")
            end
            
            fileName = configFileName and configFileName ~= "" and configFileName or "MM2"
            
            configData = {
                Theme = WindUI:GetCurrentTheme(),
                Transparency = WindUI.TransparencyValue,
                FeatureStates = featureStates
            }
            
            writefile("mm2/" .. fileName .. ".json", HttpService:JSONEncode(configData))
        end)
        
        if success then
            UpdateConfigList()
        end
    end
})

ConfigDropdown = Tabs.Settings:Dropdown({
    Title = "Load Configuration",
    Values = {"Select a config"},
    Value = "Select a config",
    Callback = function(value)
        if value ~= "Select a config" then
            success, error = pcall(function()
                if isfile("mm2/" .. value .. ".json") then
                    configData = HttpService:JSONDecode(readfile("mm2/" .. value .. ".json"))
                    
                    if configData.Theme then
                        WindUI:SetTheme(configData.Theme)
                    end
                    if configData.Transparency then
                        WindUI.TransparencyValue = configData.Transparency
                    end
                    if configData.FeatureStates then
                        for key, val in pairs(configData.FeatureStates) do
                            featureStates[key] = val
                        end
                        if InfiniteJumpToggle then
                            InfiniteJumpToggle:Set(featureStates.InfiniteJump)
                        end
                        if SpeedToggle then
                            SpeedToggle:Set(featureStates.SpeedHack)
                            if featureStates.SpeedHack and humanoid then
                                humanoid.WalkSpeed = featureStates.SpeedValue
                            elseif humanoid then
                                humanoid.WalkSpeed = 16
                            end
                        end
                        if SpeedSlider then
                            SpeedSlider:Set(featureStates.SpeedValue)
                        end
                        if NoclipToggle then
                            NoclipToggle:Set(featureStates.Noclip)
                            if featureStates.Noclip then
                                noclip()
                            else
                                clip()
                            end
                        end
                        if FlyToggle then
                            FlyToggle:Set(featureStates.Fly)
                            if featureStates.Fly then
                                startFlying()
                                flyConnection = RunService.Heartbeat:Connect(updateFly)
                            else
                                stopFlying()
                                if flyConnection then
                                    flyConnection:Disconnect()
                                    flyConnection = nil
                                end
                            end
                        end
                        if FlySpeedSlider then
                            FlySpeedSlider:Set(featureStates.FlySpeed)
                        end
                        if TPWALKToggle then
                            TPWALKToggle:Set(featureStates.TPWALK)
                            if featureStates.TPWALK then
                                startTpwalk()
                            else
                                stopTpwalk()
                            end
                        end
                        if TPWALKSlider then
                            TPWALKSlider:Set(featureStates.TpwalkValue)
                        end
                        if JumpBoostToggle then
                            JumpBoostToggle:Set(featureStates.JumpBoost)
                            if featureStates.JumpBoost then
                                startJumpBoost()
                            else
                                stopJumpBoost()
                            end
                        end
                        if JumpBoostSlider then
                            JumpBoostSlider:Set(featureStates.JumpPower)
                        end
                        if AntiAFKToggle then
                            AntiAFKToggle:Set(featureStates.AntiAFK)
                            if featureStates.AntiAFK then
                                startAntiAFK()
                            else
                                stopAntiAFK()
                            end
                        end
                        if InnocentNameESPToggle then
                            InnocentNameESPToggle:Set(featureStates.InnocentESP.names)
                        end
                        if InnocentBoxESPToggle then
                            InnocentBoxESPToggle:Set(featureStates.InnocentESP.boxes)
                        end
                        if InnocentTracerToggle then
                            InnocentTracerToggle:Set(featureStates.InnocentESP.tracers)
                        end
                        if InnocentDistanceESPToggle then
                            InnocentDistanceESPToggle:Set(featureStates.InnocentESP.distance)
                        end
                        if InnocentBoxTypeDropdown then
                            InnocentBoxTypeDropdown:Set(featureStates.InnocentESP.boxType)
                        end
                        if MurderNameESPToggle then
                            MurderNameESPToggle:Set(featureStates.MurderESP.names)
                        end
                        if MurderBoxESPToggle then
                            MurderBoxESPToggle:Set(featureStates.MurderESP.boxes)
                        end
                        if MurderTracerToggle then
                            MurderTracerToggle:Set(featureStates.MurderESP.tracers)
                        end
                        if MurderDistanceESPToggle then
                            MurderDistanceESPToggle:Set(featureStates.MurderESP.distance)
                        end
                        if MurderBoxTypeDropdown then
                            MurderBoxTypeDropdown:Set(featureStates.MurderESP.boxType)
                        end
                        if HeroSheriffNameESPToggle then
                            HeroSheriffNameESPToggle:Set(featureStates.HeroSheriffESP.names)
                        end
                        if HeroSheriffBoxESPToggle then
                            HeroSheriffBoxESPToggle:Set(featureStates.HeroSheriffESP.boxes)
                        end
                        if HeroSheriffTracerToggle then
                            HeroSheriffTracerToggle:Set(featureStates.HeroSheriffESP.tracers)
                        end
                        if HeroSheriffDistanceESPToggle then
                            HeroSheriffDistanceESPToggle:Set(featureStates.HeroSheriffESP.distance)
                        end
                        if HeroSheriffBoxTypeDropdown then
                            HeroSheriffBoxTypeDropdown:Set(featureStates.HeroSheriffESP.boxType)
                        end
                        if InnocentHighlightsToggle then
                            InnocentHighlightsToggle:Set(featureStates.InnocentHighlights)
                        end
                        if MurderHighlightsToggle then
                            MurderHighlightsToggle:Set(featureStates.MurderHighlights)
                        end
                        if SheriffHeroHighlightsToggle then
                            SheriffHeroHighlightsToggle:Set(featureStates.SheriffHeroHighlights)
                        end
                        managePlayerESPConnection()
                        manageHighlightsConnection()
                        if featureStates.Fly then
                            startFlying()
                            flyConnection = RunService.Heartbeat:Connect(updateFly)
                        else
                            stopFlying()
                            if flyConnection then
                                flyConnection:Disconnect()
                                flyConnection = nil
                            end
                        end
                        if featureStates.TPWALK then
                            startTpwalk()
                        else
                            stopTpwalk()
                        end
                        if featureStates.JumpBoost then
                            startJumpBoost()
                        else
                            stopJumpBoost()
                        end
                        if featureStates.AntiAFK then
                            startAntiAFK()
                        else
                            stopAntiAFK()
                        end
                    end
                end
            end)
        end
    end
})

Tabs.Settings:Button({
    Title = "Delete Config",
    Desc = "Delete selected configuration",
    Icon = "trash-2",
    Callback = function()
        selectedConfig = ConfigDropdown.Value
        if selectedConfig ~= "Select a config" then
            success, error = pcall(function()
                if isfile("mm2/" .. selectedConfig .. ".json") then
                    delfile("mm2/" .. selectedConfig .. ".json")
                    UpdateConfigList()
                end
            end)
        end
    end
})

function UpdateConfigList()
    configList = {"Select a config"}
    if isfolder("mm2") then
        files = listfiles("mm2")
        for i, file in ipairs(files) do
            if file:sub(-5) == ".json" then
                fileName = file:match(".*/(.*)%.json")
                if fileName then
                    table.insert(configList, fileName)
                end
            end
        end
    end
    ConfigDropdown:Refresh(configList, "Select a config")
end

Tabs.Settings:Dropdown({
    Title = "Select Theme",
    Values = {"Dark", "Light", "Blue", "Red", "Green", "Purple"},
    Value = "Dark",
    Callback = function(value)
        WindUI:SetTheme(value)
    end
})

Tabs.Settings:Slider({
    Title = "Window Transparency",
    Value = { Min = 0, Max = 1, Default = 0.2, Step = 0.1 },
    Callback = function(value)
        WindUI.TransparencyValue = value
    end
})
        Tabs.Settings:Keybind({
        Flag = "Keybind",
        Title = "Keybind",
        Desc = "Keybind to open ui",
        Value = "RightControl",
        Callback = function(RightControl)
            Window:SetToggleKey(Enum.KeyCode[RightControl])
        end
    })
UpdateConfigList()

lastConfigUpdate = 0
configUpdateCooldown = 5

RunService.Heartbeat:Connect(function()
    currentTime = tick()
    if currentTime - lastConfigUpdate >= configUpdateCooldown then
        UpdateConfigList()
        lastConfigUpdate = currentTime
    end
end)

ConfigNameInput.Callback = function(value)
    configFileName = value
    UpdateConfigList()
end
