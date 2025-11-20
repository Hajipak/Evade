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
    InnocentESP = {names = false, boxes = false, tracers = false, distance = false, boxType = "2D", color = Color3.fromRGB(0, 255, 0), deadColor = Color3.fromRGB(255, 255, 255)},
    MurderESP = {names = false, boxes = false, tracers = false, distance = false, boxType = "2D", color = Color3.fromRGB(255, 0, 0)},
    HeroSheriffESP = {names = false, boxes = false, tracers = false, distance = false, boxType = "2D", sheriffColor = Color3.fromRGB(0, 0, 255), heroColor = Color3.fromRGB(255, 255, 0)},
    InnocentHighlights = false,
    MurderHighlights = false,
    SheriffHeroHighlights = false,
    CoinESP = {names = false, boxes = false, tracers = false, distance = false, boxType = "3D", color = Color3.fromRGB(255, 215, 0)},
    GunESP = {names = false, boxes = false, tracers = false, distance = false, boxType = "3D", color = Color3.fromRGB(255, 0, 255)},
    CoinHighlights = false,
    GunHighlights = false
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
                local coinColor = featureStates.CoinESP.color
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
                local gunColor = featureStates.GunESP.color
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
                        espColor = featureStates.InnocentESP.deadColor
                        states = featureStates.InnocentESP
                        elements = innocentEspElements
                        currentTargets = currentInnocentTargets
                    elseif playerRole == "Murderer" then
                        espColor = featureStates.MurderESP.color
                        states = featureStates.MurderESP
                        elements = murderEspElements
                        currentTargets = currentMurderTargets
                    elseif playerRole == "Sheriff" then
                        espColor = featureStates.HeroSheriffESP.sheriffColor
                        states = featureStates.HeroSheriffESP
                        elements = sheriffEspElements
                        currentTargets = currentSheriffTargets
                    elseif playerRole == "Hero" then
                        espColor = featureStates.HeroSheriffESP.heroColor
                        states = featureStates.HeroSheriffESP
                        elements = sheriffEspElements
                        currentTargets = currentSheriffTargets
                    else
                        if playerRole == "Innocent" then
                            espColor = featureStates.InnocentESP.color
                        else
                            espColor = Color3.new(1,1,1)
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
                    color = featureStates.InnocentESP.deadColor
                else
                    if role == "Murderer" then
                        color = featureStates.MurderESP.color
                    elseif role == "Sheriff" then
                        color = featureStates.HeroSheriffESP.sheriffColor
                    elseif role == "Hero" and not isSheriffAlive then
                        color = featureStates.HeroSheriffESP.heroColor
                    else
                        color = featureStates.InnocentESP.color
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
                highlight.FillColor = featureStates.CoinESP.color
                highlight.OutlineColor = getOutlineColor(featureStates.CoinESP.color)
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
                highlight.FillColor = featureStates.GunESP.color
                highlight.OutlineColor = getOutlineColor(featureStates.GunESP.color)
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

Tabs.Esp:Colorpicker({
    Title = "Innocent Color",
    Desc = "Innocent ESP Color",
    Default = Color3.fromRGB(0, 255, 0),
    Transparency = 0,
    Locked = false,
    Callback = function(color) 
        featureStates.InnocentESP.color = color
    end
})

Tabs.Esp:Colorpicker({
    Title = "Dead Player Color",
    Desc = "Dead Player ESP Color",
    Default = Color3.fromRGB(255, 255, 255),
    Transparency = 0,
    Locked = false,
    Callback = function(color) 
        featureStates.InnocentESP.deadColor = color
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

Tabs.Esp:Colorpicker({
    Title = "Murder Color",
    Desc = "Murder ESP Color",
    Default = Color3.fromRGB(255, 0, 0),
    Transparency = 0,
    Locked = false,
    Callback = function(color) 
        featureStates.MurderESP.color = color
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

Tabs.Esp:Colorpicker({
    Title = "Sheriff Color",
    Desc = "Sheriff ESP Color",
    Default = Color3.fromRGB(0, 0, 255),
    Transparency = 0,
    Locked = false,
    Callback = function(color) 
        featureStates.HeroSheriffESP.sheriffColor = color
    end
})

Tabs.Esp:Colorpicker({
    Title = "Hero Color",
    Desc = "Hero ESP Color",
    Default = Color3.fromRGB(255, 255, 0),
    Transparency = 0,
    Locked = false,
    Callback = function(color) 
        featureStates.HeroSheriffESP.heroColor = color
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

Tabs.Esp:Colorpicker({
    Title = "Gun Color",
    Desc = "Gun ESP Color",
    Default = Color3.fromRGB(255, 0, 255),
    Transparency = 0,
    Locked = false,
    Callback = function(color) 
        featureStates.GunESP.color = color
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

Tabs.Esp:Colorpicker({
    Title = "Coin Color",
    Desc = "Coin ESP Color",
    Default = Color3.fromRGB(255, 215, 0),
    Transparency = 0,
    Locked = false,
    Callback = function(color) 
        featureStates.CoinESP.color = color
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
Tabs.Utility:Button(
    {
        Title = "Dupe Emote All",
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
