if getgenv().ZenHubEvadeExecuted then
    return
end
getgenv().ZenHubEvadeExecuted = true
-- Load WindUI
local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()

-- Localization setup
local Localization = WindUI:Localization({
    Enabled = true,
    Prefix = "loc:",
    DefaultLanguage = "en",
    Translations = {
        ["en"] = {
            ["SCRIPT_TITLE"] = "Zen Hub",
            ["WELCOME"] = "Made by: Zen",
            ["FEATURES"] = "Features",
            ["Player_TAB"] = "Player",
            ["SETTINGS_TAB"] = "Settings",
            ["JUMP_HEIGHT"] = "Jump Height",
            ["FULL_BRIGHT"] = "FullBright",
            ["NO_FOG"] = "Remove Fog",
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
    SideBarWidth = 200
})
local isWindowOpen = false
local function updateWindowOpenState()
    if Window and type(Window.IsOpen) == "function" then
        local ok, val = pcall(function() return Window:IsOpen() end)
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
featureStates = featureStates or {}
if featureStates.DisableCameraShake == nil then
    featureStates.DisableCameraShake = false
end
local currentKey = Enum.KeyCode.RightControl 
local keyConnection = nil
local isListeningForInput = false
local keyInputConnection = nil

local keyBindButton = nil

local keybindFile = "keybind_config.txt"

local function getCleanKeyName(keyCode)
    local keyString = tostring(keyCode)
    return keyString:gsub("Enum%.KeyCode%.", "")
end

local function saveKeybind()
    local keyString = tostring(currentKey)
    writefile(keybindFile, keyString)
end

local function loadKeybind()
    if isfile(keybindFile) then
        local savedKey = readfile(keybindFile)
        for _, key in pairs(Enum.KeyCode:GetEnumItems()) do
            if tostring(key) == savedKey then
                currentKey = key
                return true
            end
        end
    end
    return false
end

loadKeybind()

local function updateKeybindButtonDesc()
    if not keyBindButton then return false end
    local desc = "Current Key: " .. getCleanKeyName(currentKey)
    local success = false

    local methods = {
        function()
            if type(keyBindButton.SetDesc) == "function" then
                keyBindButton:SetDesc(desc)
            else
                error("no SetDesc")
            end
        end,
        function()
            if type(keyBindButton.Set) == "function" then
                keyBindButton:Set("Desc", desc)
            else
                error("no Set")
            end
        end,
        function()
            if keyBindButton.Desc ~= nil then
                keyBindButton.Desc = desc
            else
                error("no Desc property")
            end
        end,
        function()
            if type(keyBindButton.SetDescription) == "function" then
                keyBindButton:SetDescription(desc)
            else
                error("no SetDescription")
            end
        end,
        function()
            if type(keyBindButton.SetValue) == "function" then
                keyBindButton:SetValue(desc)
            else
                error("no SetValue")
            end
        end
    }

    for _, fn in ipairs(methods) do
        local ok = pcall(fn)
        if ok then
            success = true
            break
        end
    end

    if not success then
        pcall(function()
            WindUI:Notify({
                Title = "Keybind",
                Content = desc,
                Duration = 2
            })
        end)
    end

    return success
end

local function bindKey(keyBindButtonParam)
    local targetButton = keyBindButtonParam or keyBindButton

    if isListeningForInput then 
        isListeningForInput = false
        if keyConnection then
            keyConnection:Disconnect()
            keyConnection = nil
        end
        WindUI:Notify({
            Title = "Keybind",
            Content = "Key binding cancelled",
            Duration = 2
        })
        return
    end
    
    isListeningForInput = true
    WindUI:Notify({
        Title = "Keybind",
        Content = "Press any key to bind...",
        Duration = 3
    })
    
    keyConnection = game:GetService("UserInputService").InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        if input.UserInputType == Enum.UserInputType.Keyboard then
            currentKey = input.KeyCode
            isListeningForInput = false
            if keyConnection then
                keyConnection:Disconnect()
                keyConnection = nil
            end
            
            saveKeybind()
            
            WindUI:Notify({
                Title = "Keybind",
                Content = "Key bound to: " .. getCleanKeyName(currentKey),
                Duration = 3
            })
            pcall(function()
                updateKeybindButtonDesc()
            end)
        end
    end)
end

local function handleKeyPress(input, gameProcessed)
    if gameProcessed then return end
    
    if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == currentKey then
        local success, isVisible = pcall(function()
            if Window and type(Window.IsOpen) == "function" then
                return Window:IsOpen()
            elseif Window and Window.Opened ~= nil then
                return Window.Opened
            else
                return isWindowOpen
            end
        end)
        if not success then
            isVisible = isWindowOpen
        end

        if isVisible then
            if Window and type(Window.Close) == "function" then
                pcall(function() Window:Close() end)
            else
                isWindowOpen = false
                if Window and type(Window.OnClose) == "function" then
                    pcall(function() Window:OnClose() end)
                end
            end
        else
            if Window and type(Window.Open) == "function" then
                pcall(function() Window:Open() end)
            else
                isWindowOpen = true
                if Window and type(Window.OnOpen) == "function" then
                    pcall(function() Window:OnOpen() end)
                end
            end
        end
    end
end

keyInputConnection = game:GetService("UserInputService").InputBegan:Connect(handleKeyPress)
Window:SetIconSize(48)
Window:Tag({
    Title = "v1.2.5",
    Color = Color3.fromHex("#30ff6a")
})


--[[

-- Disabled fucking beta skid
Window:Tag({
Title = "Beta",
Color = Color3.fromHex("#315dff")

]]

Window:CreateTopbarButton("theme-switcher", "moon", function()
    WindUI:SetTheme(WindUI:GetCurrentTheme() == "Dark" and "Light" or "Dark")
end, 990)

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local Debris = game:GetService("Debris")
local workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")
local VirtualUser = game:GetService("VirtualUser")
local TeleportService = game:GetService("TeleportService")
local MarketplaceService = game:GetService("MarketplaceService")
local StarterGui = game:GetService("StarterGui") -- (jika digunakan untuk chat)
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local player = LocalPlayer -- Alias
local playerGui = PlayerGui -- Alias
local mouse = LocalPlayer:GetMouse() -- (jika digunakan)
local camera = workspace.CurrentCamera
local placeId = game.PlaceId
local jobId = game.JobId

local currentSettings = {
    Speed = "1500",
    JumpCap = "1",
    AirStrafeAcceleration = "187"
}

local appliedOnce = false
local playerModelPresent = false
local gameStatsPath = workspace:WaitForChild("Game"):WaitForChild("Stats")
getgenv().ApplyMode = "Not Optimized"
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
    
    if getgenv().ApplyMode == "Optimized" then
        task.spawn(function()
            for i, tableObj in ipairs(targets) do
                if tableObj and typeof(tableObj) == "table" then
                    pcall(callback, tableObj)
                end
                
                if i % 3 == 0 then
                    task.wait()
                end
            end
        end)
    else
        for i, tableObj in ipairs(targets) do
            if tableObj and typeof(tableObj) == "table" then
                pcall(callback, tableObj)
            end
        end
    end
end

local function applyStoredSettings()
    local settings = {
        {field = "Speed", value = tonumber(currentSettings.Speed)},
        {field = "JumpCap", value = tonumber(currentSettings.JumpCap)},
        {field = "AirStrafeAcceleration", value = tonumber(currentSettings.AirStrafeAcceleration)}
    }
    
    for _, setting in ipairs(settings) do
        if setting.value and tostring(setting.value) ~= "1500" and tostring(setting.value) ~= "1" and tostring(setting.value) ~= "187" then
            applyToTables(function(obj)
                obj[setting.field] = setting.value
            end)
        end
    end
end

local function applySettingsWithDelay()
    if not playerModelPresent or appliedOnce then
        return
    end
    
    appliedOnce = true
    
    local settings = {
        {field = "Speed", value = tonumber(currentSettings.Speed), delay = math.random(1, 14)},
        {field = "JumpCap", value = tonumber(currentSettings.JumpCap), delay = math.random(1, 14)},
        {field = "AirStrafeAcceleration", value = tonumber(currentSettings.AirStrafeAcceleration), delay = math.random(1, 14)}
    }
    
    for _, setting in ipairs(settings) do
        if setting.value and tostring(setting.value) ~= "1500" and tostring(setting.value) ~= "1" and tostring(setting.value) ~= "187" then
            task.spawn(function()
                task.wait(setting.delay)
                applyToTables(function(obj)
                    obj[setting.field] = setting.value
                end)
            end)
        end
    end
end

local function isPlayerModelPresent()
    local GameFolder = workspace:FindFirstChild("Game")
    local PlayersFolder = GameFolder and GameFolder:FindFirstChild("Players")
    return PlayersFolder and PlayersFolder:FindFirstChild(player.Name) ~= nil
end
local featureStates = {
    JumpBoost = false,
    AntiAFK = false,
    FullBright = false,
    NoFog = false,
    TimerDisplay = false
}
-- Variables
local character, humanoid, rootPart
local isJumpHeld = false
local hasRevived = false
local jumpCount = 0
local MAX_JUMPS = math.huge

local AntiAFKConnection


-- Visual Variables
local originalBrightness = Lighting.Brightness
local originalFogEnd = Lighting.FogEnd
local originalOutdoorAmbient = Lighting.OutdoorAmbient
local originalAmbient = Lighting.Ambient
local originalGlobalShadows = Lighting.GlobalShadows
local originalAtmospheres = {}

for _, v in pairs(Lighting:GetDescendants()) do
    if v:IsA("Atmosphere") then
        table.insert(originalAtmospheres, v)
    end
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
local function isPlayerGrounded()
    if not character or not humanoid or not rootPart then
        return false
    end
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

local function getDistanceFromPlayer(targetPosition)
    if not character or not rootPart then return 0 end
    return (targetPosition - rootPart.Position).Magnitude
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

local function startAntiAFK()
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
local function getServerLink()
    local placeId = game.PlaceId
    local jobId = game.JobId
    return string.format("https://www.roblox.com/games/start?placeId=%d&jobId=%s", placeId, jobId)
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

    local FeatureSection = Window:Section({ Title = "loc:FEATURES", Opened = true })

    local Tabs = {
    Player = FeatureSection:Tab({ Title = "loc:Player_TAB", Icon = "user" }),
    Auto = FeatureSection:Tab({ Title = "loc:AUTO_TAB", Icon = "repeat-2" }),
    Visuals = FeatureSection:Tab({ Title = "loc:VISUALS_TAB", Icon = "camera" }),
    Utility = FeatureSection:Tab({ Title = "Utility", Icon = "wrench"}),
    Settings = FeatureSection:Tab({ Title = "loc:SETTINGS_TAB", Icon = "settings" })
    
}


-- Player Tabs
Tabs.Player:Section({ Title = "Player", TextSize = 40 })
Tabs.Player:Divider()

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local player = Players.LocalPlayer
local remoteEvent = ReplicatedStorage:WaitForChild("Events"):WaitForChild("Character"):WaitForChild("PassCharacterInfo")

local BOUNCE_HEIGHT = 0
local BOUNCE_EPSILON = 0.1
local BOUNCE_ENABLED = false
local touchConnections = {}

local function setupBounceOnTouch(character)
    if not BOUNCE_ENABLED then return end
    
    local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
    
    if touchConnections[character] then
        touchConnections[character]:Disconnect()
        touchConnections[character] = nil
    end
    
    local touchConnection
    touchConnection = humanoidRootPart.Touched:Connect(function(hit)
        local playerBottom = humanoidRootPart.Position.Y - humanoidRootPart.Size.Y / 2
        local playerTop = humanoidRootPart.Position.Y + humanoidRootPart.Size.Y / 2
        local hitBottom = hit.Position.Y - hit.Size.Y / 2
        local hitTop = hit.Position.Y + hit.Size.Y / 2
        
        if hitTop <= playerBottom + BOUNCE_EPSILON then
            return
        elseif hitBottom >= playerTop - BOUNCE_EPSILON then
            return
        end
        
        remoteEvent:FireServer({}, {2})
        
        if BOUNCE_HEIGHT > 0 then
            local bodyVel = Instance.new("BodyVelocity")
            bodyVel.MaxForce = Vector3.new(0, math.huge, 0)
            bodyVel.Velocity = Vector3.new(0, BOUNCE_HEIGHT, 0)
            bodyVel.Parent = humanoidRootPart
            Debris:AddItem(bodyVel, 0.2)
        end
    end)
    
    touchConnections[character] = touchConnection
    
    character.AncestryChanged:Connect(function()
        if not character.Parent then
            if touchConnections[character] then
                touchConnections[character]:Disconnect()
                touchConnections[character] = nil
            end
        end
    end)
end

local function disableBounce()
    for character, connection in pairs(touchConnections) do
        if connection then
            connection:Disconnect()
            touchConnections[character] = nil
        end
    end
end

if player.Character then
    setupBounceOnTouch(player.Character)
end

player.CharacterAdded:Connect(setupBounceOnTouch)

if Tabs and Tabs.Player then
    Tabs.Player:Section({ Title = "Bounce Settings", TextSize = 20 })
    
    local BounceToggle
    local BounceHeightInput
    local EpsilonInput
    
    BounceToggle = Tabs.Player:Toggle({
        Title = "Enable Bounce",
        Value = false,
        Callback = function(state)
            BOUNCE_ENABLED = state
            if state then
                if player.Character then
                    setupBounceOnTouch(player.Character)
                end
            else
                disableBounce()
            end
            BounceHeightInput:Set({ Enabled = state })
            EpsilonInput:Set({ Enabled = state })
        end
    })

    BounceHeightInput = Tabs.Player:Input({
        Title = "Bounce Height",
        Placeholder = "0",
        Value = tostring(BOUNCE_HEIGHT),
        Numeric = true,
        Enabled = false,
        Callback = function(value)
            local num = tonumber(value)
            if num then
                BOUNCE_HEIGHT = math.max(0, num)
            end
        end
    })

    EpsilonInput = Tabs.Player:Input({
        Title = "Touch Detection Epsilon",
        Placeholder = "0.1",
        Value = tostring(BOUNCE_EPSILON),
        Numeric = true,
        Enabled = false,
        Callback = function(value)
            local num = tonumber(value)
            if num then
                BOUNCE_EPSILON = math.max(0, num)
            end
        end
    })
end

local infiniteSlideEnabled = false
local slideFrictionValue = -8
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")

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

local cachedTables = nil
local plrModel = nil
local slideConnection = nil

local function getConfigTables()
    local tables = {}
    for _, obj in ipairs(getgc(true)) do
        local success, result = pcall(function()
            if hasAll(obj) then return obj end
        end)
        if success and result then
            table.insert(tables, obj)
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
        plrModel = PlayersFolder:FindFirstChild(LocalPlayer.Name)
    else
        plrModel = nil
    end
end

local function onHeartbeat()
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
            setFriction(slideFrictionValue)
        else
            setFriction(5)
        end
    else
        setFriction(5)
    end
end

local InfiniteSlideToggle = Tabs.Player:Toggle({
    Title = "Infinite Slide",
    Value = false,
    Callback = function(state)
        infiniteSlideEnabled = state
        if slideConnection then
            slideConnection:Disconnect()
            slideConnection = nil
        end
        if state then
            cachedTables = getConfigTables()
            updatePlayerModel()
            slideConnection = RunService.Heartbeat:Connect(onHeartbeat)
            LocalPlayer.CharacterAdded:Connect(function()
                task.wait(0.1)
                updatePlayerModel()
            end)
        else
            cachedTables = nil
            plrModel = nil
            setFriction(5)
        end
    end,
})

local InfiniteSlideSpeedInput = Tabs.Player:Input({
    Title = "Set Infinite Slide Speed (Negative Only)",
    Value = tostring(slideFrictionValue),
    Placeholder = "-8 (negative only)",
    Callback = function(text)
        local num = tonumber(text)
        if num and num < 0 then
            slideFrictionValue = num
        end
    end,
})

Tabs.Player:Section({ Title = "Modifications" })

local function createValidatedInput(config)
    return function(input)
        local val = tonumber(input)
        if not val then return end
        
        if config.min and val < config.min then return end
        if config.max and val > config.max then return end
        
        currentSettings[config.field] = tostring(val)
        applyToTables(function(obj)
            obj[config.field] = val
        end)
    end
end

local SpeedInput = Tabs.Player:Input({
    Title = "Set Speed",
    Icon = "speedometer",
    Placeholder = "Default 1500",
    Value = currentSettings.Speed,
    Callback = createValidatedInput({
        field = "Speed",
        min = 1450,
        max = 100008888
    })
})

local JumpCapInput = Tabs.Player:Input({
    Title = "Set Jump Cap",
    Icon = "chevrons-up",
    Placeholder = "Default 1",
    Value = currentSettings.JumpCap,
    Callback = createValidatedInput({
        field = "JumpCap",
        min = 0.1,
        max = 9999999999
    })
})

local StrafeInput = Tabs.Player:Input({
    Title = "Strafe Acceleration",
    Icon = "wind",
    Placeholder = "Default 187",
    Value = currentSettings.AirStrafeAcceleration,
    Callback = createValidatedInput({
        field = "AirStrafeAcceleration",
        min = 1,
        max = 9999999999999
    })
})

local ApplyMethodDropdown = Tabs.Player:Dropdown({
    Title = "Select Apply Method",
    Values = { "Not Optimized", "Optimized" },
    Multi = false,
    Default = getgenv().ApplyMode,
    Callback = function(value)
        getgenv().ApplyMode = value
    end
})

-- Visuals Tab
Tabs.Visuals:Section({ Title = "Visual", TextSize = 20 })
Tabs.Visuals:Divider()

local cameraStretchConnection
local function setupCameraStretch()
    cameraStretchConnection = nil
    local stretchHorizontal = 0.80
    local stretchVertical = 0.80
    local CameraStretchToggle = Tabs.Visuals:Toggle({
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

    local CameraStretchHorizontalInput = Tabs.Visuals:Input({
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

    local CameraStretchVerticalInput = Tabs.Visuals:Input({
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

setupCameraStretch()


local module_upvr = {}
module_upvr.__index = module_upvr

local currentModuleInstance = nil

function module_upvr.new()
    if currentModuleInstance then
        currentModuleInstance = nil
    end

    local player = game.Players.LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui", 5)
    local self = setmetatable({
        Player = player,
        Enabled = false,
        Visible = false,
    }, module_upvr)

    local nextbotNoise
    local success, err = pcall(function()
        local shared = playerGui:FindFirstChild("Shared")
        if shared then
            local hud = shared:FindFirstChild("HUD")
            if hud then
                nextbotNoise = hud:FindFirstChild("NextbotNoise")
            end
        end
        if not nextbotNoise then
            local hud = playerGui:FindFirstChild("HUD")
            if hud then
                nextbotNoise = hud:FindFirstChild("NextbotNoise")
            end
        end
        if not nextbotNoise then
            nextbotNoise = playerGui:FindFirstChild("NextbotNoise")
        end
    end)

    if not success or not nextbotNoise then
        warn("Failed to find NextbotNoise in PlayerGui: " .. (err or "Unknown error"))
        return self
    end

    self.originalSize = nextbotNoise.Size
    self.originalPosition = nextbotNoise.Position
    self.originalImageTransparency = nextbotNoise.ImageTransparency
    self.originalNoiseTransparency = nextbotNoise:FindFirstChild("Noise") and nextbotNoise.Noise.ImageTransparency or 0
    self.originalNoise2Transparency = nextbotNoise:FindFirstChild("Noise2") and nextbotNoise.Noise2.ImageTransparency or 0

    local transparencySuccess, transparencyErr = pcall(function()
        local inset = game:GetService("GuiService"):GetGuiInset()
        nextbotNoise.Position = UDim2.new(0.5, 0, 0, -inset.Y)
        nextbotNoise.Size = UDim2.new(0, 0, 0, 0)
        nextbotNoise.ImageTransparency = 1
        if nextbotNoise:FindFirstChild("Noise") then
            nextbotNoise.Noise.ImageTransparency = 1
        else
            warn("Noise not found in NextbotNoise")
        end
        if nextbotNoise:FindFirstChild("Noise2") then
            nextbotNoise.Noise2.ImageTransparency = 1
        else
            warn("Noise2 not found in NextbotNoise")
        end
    end)

    if not transparencySuccess then
        warn("Failed to set vignette properties: " .. transparencyErr)
    end

    self.Noise = nextbotNoise
    currentModuleInstance = self
    return self
end

function module_upvr.stop(self)
    if self.Noise then
        local success, err = pcall(function()
            self.Noise.Size = self.originalSize
            self.Noise.Position = self.originalPosition
            self.Noise.ImageTransparency = self.originalImageTransparency
            if self.Noise:FindFirstChild("Noise") then
                self.Noise.Noise.ImageTransparency = self.originalNoiseTransparency
            end
            if self.Noise:FindFirstChild("Noise2") then
                self.Noise.Noise2.ImageTransparency = self.originalNoise2Transparency
            end
        end)
        if not success then
            warn("Failed to restore vignette properties: " .. err)
        end
    end
    currentModuleInstance = nil
end

function module_upvr.Update(arg1, arg2)
    if arg1 and arg1.Noise then
        local success, err = pcall(function()
            if arg1.Noise:IsA("ImageLabel") or arg1.Noise:IsA("Frame") then
                arg1.Noise.ImageTransparency = 1
                if arg1.Noise:FindFirstChild("Noise") then
                    arg1.Noise.Noise.ImageTransparency = 1
                end
                if arg1.Noise:FindFirstChild("Noise2") then
                    arg1.Noise.Noise2.ImageTransparency = 1
                end
            end
        end)
        if not success then
            warn("Update failed to set transparencies: " .. err)
        end
    end
end



local stableCameraInstance = nil

local StableCamera = {}
StableCamera.__index = StableCamera

function StableCamera.new(maxDistance)
    local self = setmetatable({}, StableCamera)
    self.Player = Players.LocalPlayer
    self.MaxDistance = maxDistance or 50
    self._conn = RunService.RenderStepped:Connect(function(dt) self:Update(dt) end)
    return self
end

local function tryResetShake(player)
    if not player then return end
    local ok, playerScripts = pcall(function() return player:FindFirstChild("PlayerScripts") end)
    if not ok or not playerScripts then return end
    local cameraSet = playerScripts:FindFirstChild("Camera") and playerScripts.Camera:FindFirstChild("Set")
    if cameraSet and type(cameraSet.Invoke) == "function" then
        pcall(function()
            cameraSet:Invoke("CFrameOffset", "Shake", CFrame.new())
        end)
    end
end

function StableCamera:Update(dt)
    if Players and Players.LocalPlayer then
        tryResetShake(Players.LocalPlayer)
    end
end

function StableCamera:Destroy()
    if self._conn then
        self._conn:Disconnect()
        self._conn = nil
    end
end

local DisableCameraShakeToggle = Tabs.Visuals:Toggle({
    Title = "Disable Camera Shake",
    Value = false,
    Callback = function(state)
        featureStates.DisableCameraShake = state
        if state then
            if stableCameraInstance then
                stableCameraInstance:Destroy()
                stableCameraInstance = nil
            end
            stableCameraInstance = StableCamera.new(50)
            pcall(function()
                WindUI:Notify({ Title = "Camera", Content = "Camera shake disabled", Duration = 0 })
            end)
        else
            if stableCameraInstance then
                stableCameraInstance:Destroy()
                stableCameraInstance = nil
            end
            pcall(function()
                WindUI:Notify({ Title = "Camera", Content = "Camera shake enabled", Duration = 0 })
            end)
        end
    end
})

local vignetteEnabled = false

local Disablevignette = Tabs.Visuals:Toggle({
    Title = "Disable Vignette",
    Default = false,
    Callback = function(value)
        vignetteEnabled = value
        if value then
            local vignetteInstance = module_upvr.new()
            if vignetteInstance then
                vignetteConnection = game:GetService("RunService").Heartbeat:Connect(function(dt)
                    module_upvr.Update(vignetteInstance, dt)
                end)
            end
        else
            if vignetteConnection then
                vignetteConnection:Disconnect()
                vignetteConnection = nil
            end
            if currentModuleInstance then
                module_upvr.stop(currentModuleInstance)
            end
        end
    end
})

game.Players.LocalPlayer.CharacterAdded:Connect(function()
    warn("Player respawned - checking vignette disable")
    wait(1)
    
    if vignetteEnabled then
        warn("Reapplying vignette disable after respawn")
        local vignetteInstance = module_upvr.new()
        if vignetteInstance then
            if vignetteConnection then
                vignetteConnection:Disconnect()
            end
            vignetteConnection = game:GetService("RunService").Heartbeat:Connect(function(dt)
                module_upvr.Update(vignetteInstance, dt)
            end)
        end
    end
end)

	    local FullBrightToggle = Tabs.Visuals:Toggle({
        Title = "loc:FULL_BRIGHT",
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

local NoFogToggle = Tabs.Visuals:Toggle({
    Title = "loc:NO_FOG",
    Value = false,
    Callback = function(state)
        featureStates.NoFog = state
        if state then
            startNoFog()
        else
            stopNoFog()
        end
    end
})
local originalFOV = workspace.CurrentCamera.FieldOfView
local FOVSlider = Tabs.Visuals:Slider({
    Title = "Field of View",
    Desc = "Old fov has been moved to settings, will be add back in here soon",
    Value = { Min = 10, Max = 120, Default = originalFOV, Step = 1 },
    Callback = function(value)
        workspace.CurrentCamera.FieldOfView = tonumber(value)
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

-- Auto Tab
Tabs.Auto:Section({ Title = "Auto", TextSize = 40 })

    local AutoCrouchToggle = Tabs.Auto:Toggle({
    Title = "Auto Crouch",
    Icon = "arrow-down",
    Value = false,
    Callback = function(state)
        featureStates.AutoCrouch = state
        local playerGui = Players.LocalPlayer.PlayerGui
        local autoCrouchGui = playerGui:FindFirstChild("AutoCrouchGui")
        if not autoCrouchGui and state then
            createAutoCrouchGui()
        elseif autoCrouchGui then
            autoCrouchGui.Enabled = state
            local button = autoCrouchGui.Frame:FindFirstChild("ToggleButton")
            if button then
                button.Text = state and "On" or "Off"
                button.BackgroundColor3 = state and Color3.fromRGB(0, 120, 80) or Color3.fromRGB(120, 0, 0)
            end
        end
    end
})

local AutoCrouchModeDropdown = Tabs.Auto:Dropdown({
    Title = "Auto Crouch Mode",
    Values = {"Air", "Normal", "Ground"},
    Value = "Air",
    Callback = function(value)
        featureStates.AutoCrouchMode = value
    end
})
local _Players = game:GetService("Players")
local _LocalPlayer = _Players.LocalPlayer
local BhopToggle = Tabs.Auto:Toggle({
    Title = "Bhop",
    Value = false,
    Callback = function(state)
        featureStates.Bhop = state
        if not state then
            getgenv().autoJumpEnabled = false
            if jumpGui and jumpToggleBtn then
                jumpToggleBtn.Text = "Off"
                jumpToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                jumpGui.Enabled = isMobile and state
            end
        end
        if _LocalPlayer and _LocalPlayer:FindFirstChild("PlayerGui") then
            local gui = _LocalPlayer.PlayerGui:FindFirstChild("BhopGui")
            if gui then
                gui.Enabled = state
            end
        end
    end
})
featureStates.BhopHold = false

getgenv().bhopHoldActive = false

local BhopHoldToggle = Tabs.Auto:Toggle({
    Title = "Bhop (Jump button or Space)",
    Value = false,
    Callback = function(state)
        featureStates.BhopHold = state
        if not state then
            getgenv().bhopHoldActive = false
        end
    end
})

local UIS = game:GetService("UserInputService")
UIS.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.Space and featureStates.BhopHold then
        getgenv().bhopHoldActive = true
    end
end)
UIS.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.Space then
        getgenv().bhopHoldActive = false
    end
end)

local function setupJumpButton()
    local success, err = pcall(function()
        local touchGui = player:WaitForChild("PlayerGui"):WaitForChild("TouchGui", 5)
        if not touchGui then return end
        local touchControlFrame = touchGui:WaitForChild("TouchControlFrame", 5)
        if not touchControlFrame then return end
        local jumpButton = touchControlFrame:WaitForChild("JumpButton", 5)
        if not jumpButton then return end
        
        jumpButton.MouseButton1Down:Connect(function()
            if featureStates.BhopHold then
                getgenv().bhopHoldActive = true
            end
        end)
        
        jumpButton.MouseButton1Up:Connect(function()
            getgenv().bhopHoldActive = false
        end)
    end)
    if not success then
        warn("Failed to setup jump button: " .. tostring(err))
    end
end
setupJumpButton()
player.CharacterAdded:Connect(setupJumpButton)

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
            local character = LocalPlayer.Character
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
local BhopModeDropdown = Tabs.Auto:Dropdown({
    Title = "Bhop Mode",
    Values = {"Acceleration", "No Acceleration"},
    Value = "Acceleration",
    Callback = function(value)
        getgenv().bhopMode = value
    end
})
local BhopAccelInput = Tabs.Auto:Input({
    Title = "Bhop Acceleration (Negative Only)",
    Placeholder = "-0.5",
    Numeric = true,
    Callback = function(value)
        if tostring(value):sub(1,1) == "-" then
            local n = tonumber(value)
            if n then getgenv().bhopAccelValue = n end
        end
    end
})

-- Utility Tab

local TimeChangerInput = Tabs.Utility:Input({
    Title = "Set Time (HH:MM)",
    Placeholder = "12:00",
    Value = "",
    Callback = function(value)
        value = value:gsub("^%s*(.-)%s*$", "%1")
        
        local h_str, m_str = value:match("(%d+):(%d+)")
        if h_str and m_str then
            local h = tonumber(h_str)
            local m = tonumber(m_str)
            
            if h and m and h >= 0 and h <= 23 and m >= 0 and m <= 59 and #h_str <= 2 and #m_str <= 2 then
                local totalHours = h + (m / 60)
                game:GetService("Lighting").ClockTime = totalHours
                
                WindUI:Notify({
                    Title = "Time Changer",
                    Content = "Time set to " .. string.format("%02d:%02d", h, m),
                    Duration = 2
                })
            else
                WindUI:Notify({
                    Title = "Time Changer",
                    Content = "Invalid time! Hours: 00-23, Minutes: 00-59 (e.g., 09:30 or 12:00)",
                    Duration = 3
                })
            end
        else
            WindUI:Notify({
                Title = "Time Changer",
                Content = "Invalid format! Use HH:MM (e.g., 09:30)",
                Duration = 2
            })
        end
    end
})

featureStates.AutoCrouch = false
featureStates.AutoCrouchMode = "Air"

local previousCrouchState = false
local spamDown = true

local function fireKeybind(down, key)
    local ohTable = {
        ["Down"] = down,
        ["Key"] = key
    }
    local event = game:GetService("Players").LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild("Events"):WaitForChild("temporary_events"):WaitForChild("UseKeybind")
    event:Fire(ohTable)
end

local function createAutoCrouchGui()
    local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
    
    local autoCrouchGuiOld = playerGui:FindFirstChild("AutoCrouchGui")
    if autoCrouchGuiOld then autoCrouchGuiOld:Destroy() end
    
    local autoCrouchGui = Instance.new("ScreenGui")
    autoCrouchGui.Name = "AutoCrouchGui"
    autoCrouchGui.IgnoreGuiInset = true
    autoCrouchGui.ResetOnSpawn = false
    autoCrouchGui.Enabled = true
    autoCrouchGui.Parent = playerGui

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 50, 0, 50)
    frame.Position = UDim2.new(0.5, -50, 0.12, 0)
    frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    frame.BackgroundTransparency = 0.35
    frame.BorderSizePixel = 0
    frame.Parent = autoCrouchGui
    
    local dragging = false
    local dragStart = nil
    local startPos = nil

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

    game:GetService("UserInputService").InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = frame

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(150, 150, 150)
    stroke.Thickness = 2
    stroke.Parent = frame

    local label = Instance.new("TextLabel")
    label.Text = "Auto Crouch"
    label.Size = UDim2.new(0.9, 0, 0.45, 0)
    label.Position = UDim2.new(0.05, 0, 0.05, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.Font = Enum.Font.Roboto
    label.TextSize = 30
    label.TextXAlignment = Enum.TextXAlignment.Center
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.TextScaled = true
    label.Parent = frame

    local autoCrouchGuiButton = Instance.new("TextButton")
    autoCrouchGuiButton.Name = "ToggleButton"
    autoCrouchGuiButton.Text = featureStates.AutoCrouch and "On" or "Off"
    autoCrouchGuiButton.Size = UDim2.new(0.9, 0, 0.4, 0)
    autoCrouchGuiButton.Position = UDim2.new(0.05, 0, 0.5, 0)
    autoCrouchGuiButton.BackgroundColor3 = featureStates.AutoCrouch and Color3.fromRGB(0, 120, 80) or Color3.fromRGB(120, 0, 0)
    autoCrouchGuiButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    autoCrouchGuiButton.Font = Enum.Font.Roboto
    autoCrouchGuiButton.TextSize = 16
    autoCrouchGuiButton.TextXAlignment = Enum.TextXAlignment.Center
    autoCrouchGuiButton.TextYAlignment = Enum.TextYAlignment.Center
    autoCrouchGuiButton.TextScaled = true
    autoCrouchGuiButton.Parent = frame

    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 4)
    buttonCorner.Parent = autoCrouchGuiButton

    autoCrouchGuiButton.MouseButton1Click:Connect(function()
        featureStates.AutoCrouch = not featureStates.AutoCrouch
        autoCrouchGuiButton.Text = featureStates.AutoCrouch and "On" or "Off"
        autoCrouchGuiButton.BackgroundColor3 = featureStates.AutoCrouch and Color3.fromRGB(0, 120, 80) or Color3.fromRGB(120, 0, 0)
        AutoCrouchToggle:Set(featureStates.AutoCrouch)
    end)
end

local crouchConnection = RunService.Heartbeat:Connect(function()
    if not featureStates.AutoCrouch then 
        if previousCrouchState then
            fireKeybind(false, "Crouch")
            previousCrouchState = false
        end
        return 
    end

    local character = Players.LocalPlayer.Character
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

Players.LocalPlayer.CharacterAdded:Connect(function(newChar)
    previousCrouchState = false
    spamDown = true
end)

getgenv().lagSwitchEnabled = false
getgenv().lagDuration = 0.5
local lagGui = nil
local lagGuiButton = nil
local lagInputConnection = nil
local isLagActive = false

local function makeDraggable(frame)
    local dragging = false
    local dragStart = nil
    local startPos = nil
    
    local function updateInput(input)
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
    
    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    
    frame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            if dragging then
                updateInput(input)
            end
        end
    end)
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

    local corner = Instance.new("UICorner", frame)
    corner.CornerRadius = UDim.new(0, 6)

    local stroke = Instance.new("UIStroke", frame)
    stroke.Color = Color3.fromRGB(150, 150, 150)
    stroke.Thickness = 2

    local label = Instance.new("TextLabel", frame)
    label.Text = "Lag"
    label.Size = UDim2.new(0.9, 0, 0.3, 0)
    label.Position = UDim2.new(0.05, 0, 0.05, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.Font = Enum.Font.Roboto
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Center
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.TextScaled = true

    local subLabel = Instance.new("TextLabel", frame)
    subLabel.Text = "Switch"
    subLabel.Size = UDim2.new(0.9, 0, 0.3, 0)
    subLabel.Position = UDim2.new(0.05, 0, 0.3, 0)
    subLabel.BackgroundTransparency = 1
    subLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    subLabel.Font = Enum.Font.Roboto
    subLabel.TextSize = 14
    subLabel.TextXAlignment = Enum.TextXAlignment.Center
    subLabel.TextYAlignment = Enum.TextYAlignment.Center
    subLabel.TextScaled = true

    lagGuiButton = Instance.new("TextButton", frame)
    lagGuiButton.Name = "TriggerButton"
    lagGuiButton.Text = "Trigger"
    lagGuiButton.Size = UDim2.new(0.9, 0, 0.35, 0)
    lagGuiButton.Position = UDim2.new(0.05, 0, 0.6, 0)
    lagGuiButton.BackgroundColor3 = Color3.fromRGB(0, 120, 80)
    lagGuiButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    lagGuiButton.Font = Enum.Font.Roboto
    lagGuiButton.TextSize = 12
    lagGuiButton.TextXAlignment = Enum.TextXAlignment.Center
    lagGuiButton.TextYAlignment = Enum.TextYAlignment.Center
    lagGuiButton.TextScaled = true

    local buttonCorner = Instance.new("UICorner", lagGuiButton)
    buttonCorner.CornerRadius = UDim.new(0, 4)

    lagGuiButton.MouseButton1Click:Connect(function()
        task.spawn(function()
            local start = tick()
            while tick() - start < (getgenv().lagDuration or 0.5) do
                local a = math.random(1, 1000000) * math.random(1, 1000000)
                a = a / math.random(1, 10000)
            end
        end)
    end)
end

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

local LagSwitchToggle = Tabs.Utility:Toggle({
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
    end
})

local LagDurationInput = Tabs.Utility:Input({
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

    -- Settings Tab
    Tabs.Settings:Section({ Title = "Settings", TextSize = 40 })
    Tabs.Settings:Section({ Title = "Personalize", TextSize = 20 })
    Tabs.Settings:Divider()

    local themes = {}
    for themeName, _ in pairs(WindUI:GetThemes()) do
        table.insert(themes, themeName)
    end
    table.sort(themes)

    local canChangeTheme = true
    local canChangeDropdown = true

    local ThemeDropdown = Tabs.Settings:Dropdown({
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

    local TransparencySlider = Tabs.Settings:Slider({
        Title = "loc:TRANSPARENCY",
        Value = { Min = 0, Max = 1, Default = 0.2, Step = 0.1 },
        Callback = function(value)
            WindUI.TransparencyValue = tonumber(value)
            Window:ToggleTransparency(tonumber(value) > 0)
        end
    })

    local ThemeToggle = Tabs.Settings:Toggle({
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
    local MyPlayerData = {
        name = player.Name,
        level = 1,
        inventory = {}
    }

    Tabs.Settings:Section({ Title = "Configuration Manager", TextSize = 20 })
    Tabs.Settings:Section({ Title = "Save and load your settings", TextSize = 16, TextTransparency = 0.25 })
    Tabs.Settings:Divider()

    Tabs.Settings:Input({
        Title = "Config Name",
        Value = configName,
        Callback = function(value)
            configName = value or "default"
        end
    })

    local ConfigManager = Window.ConfigManager
    if ConfigManager then
        ConfigManager:Init(Window)
        
        Tabs.Settings:Button({
            Title = "loc:SAVE_CONFIG",
            Icon = "save",
            Variant = "Primary",
            Callback = function()
                configFile = ConfigManager:CreateConfig(configName)
                configFile:Register("AntiAFKToggle", AntiAFKToggle)
                configFile:Register("FullBrightToggle", FullBrightToggle)
                configFile:Register("NoFogToggle", NoFogToggle)
                configFile:Register("TimerDisplayToggle", TimerDisplayToggle)
                configFile:Register("ThemeDropdown", ThemeDropdown)
                configFile:Register("TransparencySlider", TransparencySlider)
                configFile:Register("ThemeToggle", ThemeToggle)
                configFile:Register("SpeedInput", SpeedInput)
                configFile:Register("JumpCapInput", JumpCapInput)
                configFile:Register("StrafeInput", StrafeInput)
                configFile:Register("ApplyMethodDropdown", ApplyMethodDropdown)
                configFile:Register("InfiniteSlideToggle", InfiniteSlideToggle)
                configFile:Register("InfiniteSlideSpeedInput", InfiniteSlideSpeedInput)
                configFile:Register("LagSwitchToggle", LagSwitchToggle)
                configFile:Register("LagDurationInput", LagDurationInput)
                configFile:Set("playerData", MyPlayerData)
                configFile:Set("lastSave", os.date("%Y-%m-%d %H:%M:%S"))
                configFile:Save()
            end
        })

        Tabs.Settings:Button({
            Title = "loc:LOAD_CONFIG",
            Icon = "folder",
            Callback = function()
                configFile = ConfigManager:CreateConfig(configName)
                local loadedData = configFile:Load()
                if loadedData then
                    if loadedData.playerData then
                        MyPlayerData = loadedData.playerData
                    end
                    local lastSave = loadedData.lastSave or "Unknown"
                    Tabs.Settings:Paragraph({
                        Title = "Player Data",
                        Desc = string.format("Name: %s\nLevel: %d\nInventory: %s", 
                            MyPlayerData.name, 
                            MyPlayerData.level, 
                            table.concat(MyPlayerData.inventory, ", "))
                    })
                end
            end
        })
    else
        Tabs.Settings:Paragraph({
            Title = "Config Manager Not Available",
            Desc = "This feature requires ConfigManager",
            Image = "alert-triangle",
            ImageSize = 20,
            Color = "White"
        })
    end


    Tabs.Settings:Section({ Title = "Keybind Settings", TextSize = 20 })
    Tabs.Settings:Section({ Title = "Change toggle key for GUI", TextSize = 16, TextTransparency = 0.25 })
    Tabs.Settings:Divider()

    keyBindButton = Tabs.Settings:Button({
        Title = "Keybind",
        Desc = "Current Key: " .. getCleanKeyName(currentKey),
        Icon = "key",
        Variant = "Primary",
        Callback = function()
            bindKey(keyBindButton)
        end
    })

    pcall(updateKeybindButtonDesc)
Tabs.Settings:Section({ Title = "Game Settings (In Beta)", TextSize = 35 })
Tabs.Settings:Section({ Title = "Note: This is a permanent Changes, it's can be used to pass limit value", TextSize = 15 })
Tabs.Settings:Divider()
Tabs.Settings:Section({ Title = "Visual", TextSize = 20 })
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ChangeSettingRemote = ReplicatedStorage:WaitForChild("Events"):WaitForChild("Data"):WaitForChild("ChangeSetting")
local UpdatedEvent = game:GetService("ReplicatedStorage").Modules.Client.Settings.Updated

    Window:SelectTab(1)
end



setupGui()
setupMobileJumpButton()

Window:OnClose(function()
    isWindowOpen = false
	print ("Press " .. getCleanKeyName(currentKey) .. " To Reopen")
    if ConfigManager and configFile then
        configFile:Set("playerData", MyPlayerData)
        configFile:Set("lastSave", os.date("%Y-%m-%d %H:%M:%S"))
        configFile:Save()
    end
    if not game:GetService("UserInputService").TouchEnabled then
        pcall(function()
            WindUI:Notify({
                Title = "GUI Closed",
                Content = "Press " .. getCleanKeyName(currentKey) .. " To Reopen",
                Duration = 3
            })
        end)
    end
end)
Window:OnDestroy(function()
    print("Window destroyed")
    if keyConnection then
        keyConnection:Disconnect()
    end
    if keyInputConnection then
        keyInputConnection:Disconnect()
    end
    saveKeybind()
end)

Window:OnOpen(function()
    print("Window opened")
    isWindowOpen = true
end)

Window:UnlockAll()

local roundStartedConnection
local timerConnection

local function setupAttributeConnections()
    if roundStartedConnection then roundStartedConnection:Disconnect() end
    if timerConnection then timerConnection:Disconnect() end
    
    if gameStatsPath then
        roundStartedConnection = gameStatsPath:GetAttributeChangedSignal("RoundStarted"):Connect(function()
            local roundStarted = gameStatsPath:GetAttribute("RoundStarted")
            if roundStarted == true then
                appliedOnce = false
                applyStoredSettings()
            end
        end)
        
        timerConnection = gameStatsPath:GetAttributeChangedSignal("Timer"):Connect(function()
            if isPlayerModelPresent() and not appliedOnce then
                applySettingsWithDelay()
            end
        end)
    end
end

setupAttributeConnections()

task.spawn(function()
    while true do
        task.wait(0.5)
        local currentlyPresent = isPlayerModelPresent()
        
        if currentlyPresent and not playerModelPresent then
            playerModelPresent = true
            applyStoredSettings()
        elseif not currentlyPresent and playerModelPresent then
            playerModelPresent = false
        end
    end
end)

game:GetService("UserInputService").WindowFocused:Connect(function()
    saveKeybind()
end)


do
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local playerGui = LocalPlayer:WaitForChild("PlayerGui")
getgenv().autoJumpEnabled = false
getgenv().bhopMode = "Acceleration"
getgenv().bhopAccelValue = -0.1
local uiToggledViaUI = false 
local isMobile = UserInputService.TouchEnabled 
local function makeDraggable(frame)
    local dragging, dragInput, dragStart, startPos
    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    frame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input == dragInput then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end
local function createToggleGui(name, varName, yOffset)
    local gui = playerGui:FindFirstChild(name.."Gui")
    if gui then gui:Destroy() end
    gui = Instance.new("ScreenGui", playerGui)
    gui.Name = name.."Gui"
    gui.IgnoreGuiInset = true
    gui.ResetOnSpawn = false
    gui.Enabled = isMobile

    local frame = Instance.new("Frame", gui)
    frame.Size = UDim2.new(0, 60, 0, 60)
    frame.Position = UDim2.new(0.5, -30, 0.12 + yOffset, 0)
    frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    frame.BackgroundTransparency = 0.35
    frame.BorderSizePixel = 0
    makeDraggable(frame)

    local corner = Instance.new("UICorner", frame)
    corner.CornerRadius = UDim.new(0, 6)

    local stroke = Instance.new("UIStroke", frame)
    stroke.Color = Color3.fromRGB(150, 150, 150)
    stroke.Thickness = 2

    local label = Instance.new("TextLabel", frame)
    label.Text = name
    label.Size = UDim2.new(0.9, 0, 0.4, 0)
    label.Position = UDim2.new(0.05, 0, 0.05, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.Font = Enum.Font.Roboto
    label.TextSize = 20 
    label.TextXAlignment = Enum.TextXAlignment.Center
    label.TextYAlignment = Enum.TextYAlignment.Center

    local toggleBtn = Instance.new("TextButton", frame)
    toggleBtn.Name = "ToggleButton"
    toggleBtn.Text = getgenv()[varName] and "On" or "Off"
    toggleBtn.Size = UDim2.new(0.9, 0, 0.55, 0)
    toggleBtn.Position = UDim2.new(0.05, 0, 0.4, 0)
    toggleBtn.BackgroundColor3 = getgenv()[varName] and Color3.fromRGB(0, 100, 0) or Color3.fromRGB(0, 0, 0)
    toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255) 
    toggleBtn.Font = Enum.Font.Roboto
    toggleBtn.TextSize = 20 
    toggleBtn.TextXAlignment = Enum.TextXAlignment.Center
    toggleBtn.TextYAlignment = Enum.TextYAlignment.Center

    local buttonCorner = Instance.new("UICorner", toggleBtn)
    buttonCorner.CornerRadius = UDim.new(0, 4) 

    toggleBtn.MouseButton1Click:Connect(function()
        getgenv()[varName] = not getgenv()[varName]
        uiToggledViaUI = true
        toggleBtn.Text = getgenv()[varName] and "On" or "Off"
        toggleBtn.BackgroundColor3 = getgenv()[varName] and Color3.fromRGB(0, 100, 0) or Color3.fromRGB(0, 0, 0)
        gui.Enabled = true
    end)

    return gui, toggleBtn
end

local jumpGui, jumpToggleBtn
local MainTab = {}
MainTab.Toggle = function(self, config)
    config.Title = config.Title or "Toggle"
    config.Callback = config.Callback or function() end
    config.Value = config.Value or false

    local toggle = {
        Set = function(self, value)
            config.Value = value
            config.Callback(value)
        end
    }
    config.Callback(config.Value)
    return toggle
end

MainTab.Dropdown = function(self, config)
    config.Title = config.Title or "Dropdown"
    config.Values = config.Values or {}
    config.Multi = config.Multi or false
    config.Default = config.Default or (config.Multi and {} or config.Values[1])
    config.Callback = config.Callback or function() end

    local dropdown = {
        Select = function(self, value)
            config.Callback(value)
        end
    }
    config.Callback(config.Default)
    return dropdown
end

MainTab.Input = function(self, config)
    config.Title = config.Title or "Input"
    config.Placeholder = config.Placeholder or ""
    config.Value = config.Value or ""
    config.Callback = config.Callback or function() end

    local input = {
        Set = function(self, value)
            config.Callback(value)
        end
    }
    return input
end

MainTab:Toggle({
    Title = "Bhop",
    Value = false,
    Callback = function(state)
        if not jumpGui then
            jumpGui, jumpToggleBtn = createToggleGui("Bhop", "autoJumpEnabled", 0.12)
        end
        jumpGui.Enabled = (state and uiToggledViaUI) or isMobile 
        jumpToggleBtn.Text = state and "On" or "Off"
        jumpToggleBtn.BackgroundColor3 = state and Color3.fromRGB(0, 100, 0) or Color3.fromRGB(0, 0, 0)
    end
})

MainTab:Dropdown({
    Title = "Bhop Mode",
    Values = {"Acceleration", "No Acceleration"},
    Multi = false,
    Default = "Acceleration",
    Callback = function(value)
        getgenv().bhopMode = value
    end
})

MainTab:Input({
    Title = "Bhop Acceleration (Negative Only)",
    Placeholder = "-0.5",
    Numeric = true,
    Callback = function(value)
        if tostring(value):sub(1, 1) == "-" then
            getgenv().bhopAccelValue = tonumber(value)
        end
    end
})

UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
    if gameProcessedEvent then return end
    if input.KeyCode == Enum.KeyCode.B and featureStates.Bhop then 
        getgenv().autoJumpEnabled = not getgenv().autoJumpEnabled
        uiToggledViaUI = false
        if jumpGui and jumpToggleBtn then
            jumpGui.Enabled = isMobile and getgenv().autoJumpEnabled
            jumpToggleBtn.Text = getgenv().autoJumpEnabled and "On" or "Off"
            jumpToggleBtn.BackgroundColor3 = getgenv().autoJumpEnabled and Color3.fromRGB(0, 100, 0) or Color3.fromRGB(0, 0, 0)
        end
        MainTab:Toggle({
            Title = "Bhop",
            Value = getgenv().autoJumpEnabled,
            Callback = function(state)
                if not jumpGui then
                    jumpGui, jumpToggleBtn = createToggleGui("Bhop", "autoJumpEnabled", 0.12)
                end
                getgenv().autoJumpEnabled = state
                jumpGui.Enabled = (state and uiToggledViaUI) or (isMobile and state)
                jumpToggleBtn.Text = state and "On" or "Off"
                jumpToggleBtn.BackgroundColor3 = state and Color3.fromRGB(0, 100, 0) or Color3.fromRGB(0, 0, 0)
            end
        }):Set(getgenv().autoJumpEnabled)
    end
end)
task.spawn(function()
    while true do
        local friction = 5
        if getgenv().autoJumpEnabled and getgenv().bhopMode == "Acceleration" then
            friction = getgenv().bhopAccelValue or -5
        end
        if getgenv().autoJumpEnabled == false then
            friction = 5
        end

        for _, t in pairs(getgc(true)) do
            if type(t) == "table" and rawget(t, "Friction") then
                if getgenv().bhopMode == "No Acceleration" then
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
        if getgenv().autoJumpEnabled then
            local character = LocalPlayer.Character
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
task.spawn(function()
    local Players = game:GetService("Players")
    local player = Players.LocalPlayer
    local guiPath = { "PlayerGui", "Shared", "HUD", "Mobile", "Right", "Mobile", "CrouchButton" }

    local function waitForDescendant(parent, name)
        local found = parent:FindFirstChild(name, true)
        while not found do
            parent.DescendantAdded:Wait()
            found = parent:FindFirstChild(name, true)
        end
        return found
    end

    local function connectCrouchButton()
        local gui = player:WaitForChild(guiPath[1])
        for i = 2, #guiPath do
            gui = waitForDescendant(gui, guiPath[i])
        end
        local button = gui

        local holding = false
        local validHold = false

        button.MouseButton1Down:Connect(function()
            holding = true
            validHold = true
            task.delay(0.5, function()
                if holding and validHold and getgenv().EmoteEnabled and getgenv().SelectedEmote then
                    local args = { [1] = getgenv().SelectedEmote }
                    game:GetService("ReplicatedStorage"):WaitForChild("Events", 9e9):WaitForChild("Character", 9e9):WaitForChild("Emote", 9e9):FireServer(unpack(args))
                end
            end)
        end)

        button.MouseButton1Up:Connect(function()
            holding = false
            validHold = false
        end)
    end

    while true do
        pcall(connectCrouchButton)
        task.wait(1)
    end
end)
end
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local BhopGui = LocalPlayer.PlayerGui:FindFirstChild("BhopGui")

if BhopGui then
    BhopGui.Enabled = false
end

--[[the part of loadstring prevent error]]
loadstring(game:HttpGet('https://raw.githubusercontent.com/Hajipak/Evade/refs/heads/main/Script/More-loadstring.lua'))()
