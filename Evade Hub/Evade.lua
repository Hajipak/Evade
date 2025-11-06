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

-- Localization setup
local Localization = WindUI:Localization({
    Enabled = true,
    Prefix = "loc:",
    DefaultLanguage = "en",
    Translations = {
        ["en"] = {
            ["SCRIPT_TITLE"] = "Zen Hub",
            ["WELCOME"] = "Made by: Pnsdg And Yomka",
            ["FEATURES"] = "Features",
            ["Player_TAB"] = "Player",
            ["AUTO_TAB"] = "Auto",
            ["VISUALS_TAB"] = "Visuals",
            ["ESP_TAB"] = "ESP",
            ["SETTINGS_TAB"] = "Settings",
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
            ["PLAYER_NAME_ESP"] = "Player Name ESP",
            ["PLAYER_BOX_ESP"] = "Player Box ESP",
            ["PLAYER_TRACER"] = "Player Tracer",
            ["PLAYER_DISTANCE_ESP"] = "Player Distance ESP",
            ["PLAYER_RAINBOW_BOXES"] = "Player Rainbow Boxes",
            ["PLAYER_RAINBOW_TRACERS"] = "Player Rainbow Tracers",
            ["NEXTBOT_ESP"] = "Nextbot ESP",
            ["NEXTBOT_NAME_ESP"] = "Nextbot Name ESP",
            ["DOWNED_BOX_ESP"] = "Downed Player Box ESP",
            ["DOWNED_TRACER"] = "Downed Player Tracer",
            ["DOWNED_NAME_ESP"] = "Downed Player Name ESP",
            ["DOWNED_DISTANCE_ESP"] = "Downed Player Distance ESP",
            ["AUTO_CARRY"] = "Auto Carry",
            ["AUTO_REVIVE"] = "Auto Revive",
            ["AUTO_VOTE"] = "Auto Vote",
            ["AUTO_VOTE_MAP"] = "Auto Vote Map",
            ["AUTO_SELF_REVIVE"] = "Auto Self Revive",
            ["MANUAL_REVIVE"] = "Manual Revive",
            ["AUTO_WIN"] = "Auto Win",
            ["AUTO_MONEY_FARM"] = "Auto Money Farm",
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

-- Create WindUI window (Initially Hidden - This is GUI v1)
local Window = WindUI:CreateWindow({
    Title = "loc:SCRIPT_TITLE",
    Icon = "rbxassetid://137330250139083",
    Author = "loc:WELCOME",
    Folder = "GameHackUI",
    Size = UDim2.fromOffset(580, 490),
    Theme = "Dark",
    HidePanelBackground = false,
    Acrylic = false,
    HideSearchBar = false,
    SideBarWidth = 200
})
Window:Toggle(false) -- Make sure it's hidden initially

-- Variables for feature states
local featureStates = featureStates or {}
featureStates.ShowGUIv1 = false -- Toggle for main GUI (v1) visibility
featureStates.ShowGUIv2 = false -- Toggle for second GUI (v2) visibility
featureStates.BhopGuiVisible = false -- Toggle for Bhop GUI visibility (for keybind and mobile button)
featureStates.AutoCrouch = false
featureStates.BounceEnabled = false
featureStates.LagSwitchEnabled = false
featureStates.LagDuration = 0.5
featureStates.FullBright = false
featureStates.NoFog = false
featureStates.TimerDisplay = false
featureStates.BounceHeight = 0
featureStates.BounceEpsilon = 0.1

-- Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local workspace = game:GetService("Workspace")
local originalGameGravity = workspace.Gravity
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Global variables for GUI sizes
local guiV1SizeX = 580
local guiV1SizeY = 490
local guiV2SizeX = 60
local guiV2SizeY = 60

-- Function to make a frame draggable
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

-- =========================
-- === GUI v2: Button Panel ===
-- =========================

-- Function to create the second GUI (Bhop, Bounce, Auto Crouch buttons) - This is GUI v2
local function createGUIv2(yOffset)
    local guiName = "GUIv2"
    local guiOld = playerGui:FindFirstChild(guiName)
    if guiOld then guiOld:Destroy() end
    local gui = Instance.new("ScreenGui")
    gui.Name = guiName
    gui.IgnoreGuiInset = true
    gui.ResetOnSpawn = false
    gui.Enabled = featureStates.ShowGUIv2
    gui.Parent = playerGui
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, guiV2SizeX, 0, guiV2SizeY)
    frame.Position = UDim2.new(0.5, -guiV2SizeX/2, 0.12 + (yOffset or 0), 0)
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

    -- Bhop Button
    local bhopLabel = Instance.new("TextLabel")
    bhopLabel.Text = "Bhop"
    bhopLabel.Size = UDim2.new(0.9, 0, 0.3, 0)
    bhopLabel.Position = UDim2.new(0.05, 0, 0.05, 0)
    bhopLabel.BackgroundTransparency = 1
    bhopLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    bhopLabel.Font = Enum.Font.Roboto
    bhopLabel.TextSize = 14
    bhopLabel.TextXAlignment = Enum.TextXAlignment.Center
    bhopLabel.TextYAlignment = Enum.TextYAlignment.Center
    bhopLabel.TextScaled = true
    bhopLabel.Parent = frame

    local bhopToggleBtn = Instance.new("TextButton")
    bhopToggleBtn.Name = "BhopToggleButton"
    bhopToggleBtn.Text = getgenv().autoJumpEnabled and "On" or "Off"
    bhopToggleBtn.Size = UDim2.new(0.9, 0, 0.3, 0)
    bhopToggleBtn.Position = UDim2.new(0.05, 0, 0.35, 0)
    bhopToggleBtn.BackgroundColor3 = getgenv().autoJumpEnabled and Color3.fromRGB(0, 120, 80) or Color3.fromRGB(120, 0, 0)
    bhopToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    bhopToggleBtn.Font = Enum.Font.Roboto
    bhopToggleBtn.TextSize = 12
    bhopToggleBtn.TextXAlignment = Enum.TextXAlignment.Center
    bhopToggleBtn.TextYAlignment = Enum.TextYAlignment.Center
    bhopToggleBtn.TextScaled = true
    bhopToggleBtn.Parent = frame
    local bhopButtonCorner = Instance.new("UICorner")
    bhopButtonCorner.CornerRadius = UDim.new(0, 4)
    bhopButtonCorner.Parent = bhopToggleBtn
    bhopToggleBtn.MouseButton1Click:Connect(function()
        getgenv().autoJumpEnabled = not getgenv().autoJumpEnabled
        featureStates.Bhop = getgenv().autoJumpEnabled
        bhopToggleBtn.Text = getgenv().autoJumpEnabled and "On" or "Off"
        bhopToggleBtn.BackgroundColor3 = getgenv().autoJumpEnabled and Color3.fromRGB(0, 120, 80) or Color3.fromRGB(120, 0, 0)
        checkBhopState()
    end)

    -- Bounce Button
    local bounceLabel = Instance.new("TextLabel")
    bounceLabel.Text = "Bounce"
    bounceLabel.Size = UDim2.new(0.9, 0, 0.3, 0)
    bounceLabel.Position = UDim2.new(0.05, 0, 0.65, 0)
    bounceLabel.BackgroundTransparency = 1
    bounceLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    bounceLabel.Font = Enum.Font.Roboto
    bounceLabel.TextSize = 14
    bounceLabel.TextXAlignment = Enum.TextXAlignment.Center
    bounceLabel.TextYAlignment = Enum.TextYAlignment.Center
    bounceLabel.TextScaled = true
    bounceLabel.Parent = frame

    local bounceToggleBtn = Instance.new("TextButton")
    bounceToggleBtn.Name = "BounceToggleButton"
    bounceToggleBtn.Text = featureStates.BounceEnabled and "On" or "Off"
    bounceToggleBtn.Size = UDim2.new(0.9, 0, 0.3, 0)
    bounceToggleBtn.Position = UDim2.new(0.05, 0, 0.95, 0)
    bounceToggleBtn.BackgroundColor3 = featureStates.BounceEnabled and Color3.fromRGB(0, 120, 80) or Color3.fromRGB(120, 0, 0)
    bounceToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    bounceToggleBtn.Font = Enum.Font.Roboto
    bounceToggleBtn.TextSize = 12
    bounceToggleBtn.TextXAlignment = Enum.TextXAlignment.Center
    bounceToggleBtn.TextYAlignment = Enum.TextYAlignment.Center
    bounceToggleBtn.TextScaled = true
    bounceToggleBtn.Parent = frame
    local bounceButtonCorner = Instance.new("UICorner")
    bounceButtonCorner.CornerRadius = UDim.new(0, 4)
    bounceButtonCorner.Parent = bounceToggleBtn
    bounceToggleBtn.MouseButton1Click:Connect(function()
        featureStates.BounceEnabled = not featureStates.BounceEnabled
        if featureStates.BounceEnabled then
            enableBounce()
        else
            disableBounce()
        end
        bounceToggleBtn.Text = featureStates.BounceEnabled and "On" or "Off"
        bounceToggleBtn.BackgroundColor3 = featureStates.BounceEnabled and Color3.fromRGB(0, 120, 80) or Color3.fromRGB(120, 0, 0)
    end)

    -- Auto Crouch Button
    local autoCrouchLabel = Instance.new("TextLabel")
    autoCrouchLabel.Text = "Auto Crouch"
    autoCrouchLabel.Size = UDim2.new(0.9, 0, 0.3, 0)
    autoCrouchLabel.Position = UDim2.new(0.05, 0, 1.25, 0)
    autoCrouchLabel.BackgroundTransparency = 1
    autoCrouchLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    autoCrouchLabel.Font = Enum.Font.Roboto
    autoCrouchLabel.TextSize = 14
    autoCrouchLabel.TextXAlignment = Enum.TextXAlignment.Center
    autoCrouchLabel.TextYAlignment = Enum.TextYAlignment.Center
    autoCrouchLabel.TextScaled = true
    autoCrouchLabel.Parent = frame

    local autoCrouchToggleBtn = Instance.new("TextButton")
    autoCrouchToggleBtn.Name = "AutoCrouchToggleButton"
    autoCrouchToggleBtn.Text = featureStates.AutoCrouch and "On" or "Off"
    autoCrouchToggleBtn.Size = UDim2.new(0.9, 0, 0.3, 0)
    autoCrouchToggleBtn.Position = UDim2.new(0.05, 0, 1.55, 0)
    autoCrouchToggleBtn.BackgroundColor3 = featureStates.AutoCrouch and Color3.fromRGB(0, 120, 80) or Color3.fromRGB(120, 0, 0)
    autoCrouchToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    autoCrouchToggleBtn.Font = Enum.Font.Roboto
    autoCrouchToggleBtn.TextSize = 12
    autoCrouchToggleBtn.TextXAlignment = Enum.TextXAlignment.Center
    autoCrouchToggleBtn.TextYAlignment = Enum.TextYAlignment.Center
    autoCrouchToggleBtn.TextScaled = true
    autoCrouchToggleBtn.Parent = frame
    local autoCrouchButtonCorner = Instance.new("UICorner")
    autoCrouchButtonCorner.CornerRadius = UDim.new(0, 4)
    autoCrouchButtonCorner.Parent = autoCrouchToggleBtn
    autoCrouchToggleBtn.MouseButton1Click:Connect(function()
        featureStates.AutoCrouch = not featureStates.AutoCrouch
        autoCrouchToggleBtn.Text = featureStates.AutoCrouch and "On" or "Off"
        autoCrouchToggleBtn.BackgroundColor3 = featureStates.AutoCrouch and Color3.fromRGB(0, 120, 80) or Color3.fromRGB(120, 0, 0)
    end)

    return gui, bhopToggleBtn, bounceToggleBtn, autoCrouchToggleBtn
end

-- =========================
-- === Feature Functions ===
-- =========================

-- Function to enable/disable bounce
local touchConnections = {}
local function setupBounceOnTouch(character)
    if not featureStates.BounceEnabled then return end
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
        if hitTop <= playerBottom + featureStates.BounceEpsilon then
            return
        elseif hitBottom >= playerTop - featureStates.BounceEpsilon then
            return
        end
        local remoteEvent = ReplicatedStorage:WaitForChild("Events"):WaitForChild("Character"):WaitForChild("PassCharacterInfo")
        remoteEvent:FireServer({}, {2})
        if featureStates.BounceHeight > 0 then
            local bodyVel = Instance.new("BodyVelocity")
            bodyVel.MaxForce = Vector3.new(0, math.huge, 0)
            bodyVel.Velocity = Vector3.new(0, featureStates.BounceHeight, 0)
            bodyVel.Parent = humanoidRootPart
            game:GetService("Debris"):AddItem(bodyVel, 0.2)
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

local function enableBounce()
    if player.Character then
        setupBounceOnTouch(player.Character)
    end
end

-- Function to handle auto crouch
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

local function setupAutoCrouchListeners()
    if crouchConnection then crouchConnection:Disconnect() end
    crouchConnection = RunService.Heartbeat:Connect(function()
        if not featureStates.AutoCrouch then return end
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
end

-- Function to handle lag switch
local isLagActive = false
local lagSystemLoaded = false
local lagGui = nil
local lagGuiButton = nil

local function loadLagSystem()
    if lagSystemLoaded then return end
    lagSystemLoaded = true
    if not lagInputConnection then
        lagInputConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if gameProcessed then return end
            if input.KeyCode == Enum.KeyCode.L and featureStates.LagSwitchEnabled and not isLagActive then
                isLagActive = true
                task.spawn(function()
                    local duration = featureStates.LagDuration or 0.5
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
    local shouldLoad = featureStates.LagSwitchEnabled
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
    lagGui.Enabled = featureStates.LagSwitchEnabled
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
                while tick() - start < (featureStates.LagDuration or 0.5) do
                    local a = math.random(1, 1000000) * math.random(1, 1000000)
                    a = a / math.random(1, 10000)
                end
                isLagActive = false
            end)
        end
    end)
end

-- Initialize variables for Bhop
getgenv().bhopMode = "Acceleration"
getgenv().bhopAccelValue = -0.5
getgenv().bhopHoldActive = false
getgenv().autoJumpEnabled = false
getgenv().jumpCooldown = 0.7
local bhopConnection = nil
local bhopLoaded = false
local bhopKeyConnection = nil
local characterConnection = nil
local frictionTables = {}
local Character = nil
local Humanoid = nil
local HumanoidRootPart = nil
local LastJump = 0
local GROUND_CHECK_DISTANCE = 3.5
local MAX_SLOPE_ANGLE = 45
local AIR_RANGE = 0.1

local function findFrictionTables()
    frictionTables = {}
    for _, t in pairs(getgc(true)) do
        if t.obj and type(t.obj) == "table" and rawget(t.obj, "Friction") then
            table.insert(frictionTables, {obj = t.obj, original = t.original})
        end
    end
end

local function setFriction(value)
    for _, e in ipairs(frictionTables) do
        if e.obj and type(e.obj) == "table" and rawget(e.obj, "Friction") then
            e.obj.Friction = value
        end
    end
end

local function resetBhopFriction()
    for _, e in ipairs(frictionTables) do
        if e.obj and type(e.obj) == "table" and rawget(e.obj, "Friction") then
            e.obj.Friction = e.original
        end
    end
    frictionTables = {}
end

local function applyBhopFriction()
    if getgenv().bhopMode == "Acceleration" then
        findFrictionTables()
        if #frictionTables > 0 then
            setFriction(getgenv().bhopAccelValue or -0.5)
        end
    else
        resetBhopFriction()
    end
end

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
    if not bhopLoaded then return end
    local character = player.Character
    local humanoid = character and character:FindFirstChild("Humanoid")
    if not character or not humanoid then
        return
    end
    local isBhopActive = getgenv().autoJumpEnabled or getgenv().bhopHoldActive
    if isBhopActive then
        local now = tick()
        if IsOnGround() and (now - LastJump) > getgenv().jumpCooldown then
            humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            LastJump = now
        end
    end
end

local function loadBhop()
    if bhopLoaded then return end
    bhopLoaded = true
    if bhopConnection then
        bhopConnection:Disconnect()
    end
    bhopConnection = RunService.Heartbeat:Connect(updateBhop)
    applyBhopFriction()
end

local function unloadBhop()
    if not bhopLoaded then return end
    bhopLoaded = false
    if bhopConnection then
        bhopConnection:Disconnect()
        bhopConnection = nil
    end
    getgenv().bhopHoldActive = false
    resetBhopFriction()
end

local function checkBhopState()
    local shouldLoad = getgenv().autoJumpEnabled or getgenv().bhopHoldActive
    if shouldLoad then
        loadBhop()
    else
        unloadBhop()
    end
end

local function reapplyBhopOnRespawn()
    if getgenv().autoJumpEnabled or getgenv().bhopHoldActive then
        wait(0.5)
        applyBhopFriction()
        checkBhopState()
    end
end

local function setupBhopKeybind()
    if bhopKeyConnection then
        bhopKeyConnection:Disconnect()
    end
    bhopKeyConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.KeyCode == Enum.KeyCode.B and featureStates.BhopGuiVisible then
            getgenv().autoJumpEnabled = not getgenv().autoJumpEnabled
            featureStates.Bhop = getgenv().autoJumpEnabled
            if BhopToggle then
                BhopToggle:Set(getgenv().autoJumpEnabled)
            end
            if jumpToggleBtn then
                jumpToggleBtn.Text = getgenv().autoJumpEnabled and "On" or "Off"
                jumpToggleBtn.BackgroundColor3 = getgenv().autoJumpEnabled and Color3.fromRGB(0, 120, 80) or Color3.fromRGB(120, 0, 0)
            end
            checkBhopState()
        end
    end)
end

local function setupJumpButton()
    local success, err = pcall(function()
        local touchGui = player:WaitForChild("PlayerGui", 5):WaitForChild("TouchGui", 5)
        if not touchGui then return end
        local touchControlFrame = touchGui:WaitForChild("TouchControlFrame", 5)
        if not touchControlFrame then return end
        local jumpButton = touchControlFrame:WaitForChild("JumpButton", 5)
        if not jumpButton then return end
        jumpButton.MouseButton1Down:Connect(function()
            if featureStates.BhopHold then
                getgenv().bhopHoldActive = true
                checkBhopState()
            end
        end)
        jumpButton.MouseButton1Up:Connect(function()
            getgenv().bhopHoldActive = false
            checkBhopState()
        end)
    end)
end

-- Setup initial state
if player.Character then
    setupBounceOnTouch(player.Character)
    setupJumpButton()
    reapplyBhopOnRespawn()
end
player.CharacterAdded:Connect(setupBounceOnTouch)
player.CharacterAdded:Connect(function(character)
    Character = character
    Humanoid = character:WaitForChild("Humanoid")
    HumanoidRootPart = character:WaitForChild("HumanoidRootPart")
    setupJumpButton()
    reapplyBhopOnRespawn()
end)

-- Setup listeners for auto crouch
setupAutoCrouchListeners()

-- Setup listeners for lag switch
checkLagState()

-- Create GUI v2
local guiV2, bhopToggleBtn, bounceToggleBtn, autoCrouchToggleBtn = createGUIv2(0)

-- =========================
-- === GUI v1: Main Window ===
-- =========================

-- Create the main GUI (v1) - Will be shown/hidden via toggle
local function setupGUIv1()
    local FeatureSection = Window:Section({ Title = "loc:FEATURES", Opened = true })
    local Tabs = {
        Player = FeatureSection:Tab({ Title = "loc:Player_TAB", Icon = "user" }),
        Visuals = FeatureSection:Tab({ Title = "loc:VISUALS_TAB", Icon = "camera" }),
        Settings = FeatureSection:Tab({ Title = "loc:SETTINGS_TAB", Icon = "settings" })
    }

    -- Player Tab
    Tabs.Player:Section({ Title = "Player", TextSize = 40 })
    Tabs.Player:Divider()

    -- Speed Input
    local SpeedInput = Tabs.Player:Input({
        Title = "Set Speed",
        Icon = "speedometer",
        Placeholder = "Default 1500",
        Value = currentSettings.Speed,
        Callback = function(input)
            local val = tonumber(input)
            if not val then return end
            currentSettings.Speed = tostring(val)
            applyToTables(function(obj)
                obj.Speed = val
            end)
        end
    })

    -- Jump Cap Input
    local JumpCapInput = Tabs.Player:Input({
        Title = "Set Jump Cap",
        Icon = "chevrons-up",
        Placeholder = "Default 1",
        Value = currentSettings.JumpCap,
        Callback = function(input)
            local val = tonumber(input)
            if not val then return end
            currentSettings.JumpCap = tostring(val)
            applyToTables(function(obj)
                obj.JumpCap = val
            end)
        end
    })

    -- Strafe Acceleration Input
    local StrafeInput = Tabs.Player:Input({
        Title = "Strafe Acceleration",
        Icon = "wind",
        Placeholder = "Default 187",
        Value = currentSettings.AirStrafeAcceleration,
        Callback = function(input)
            local val = tonumber(input)
            if not val then return end
            currentSettings.AirStrafeAcceleration = tostring(val)
            applyToTables(function(obj)
                obj.AirStrafeAcceleration = val
            end)
        end
    })

    -- Apply Method Dropdown (default empty)
    local ApplyMethodDropdown = Tabs.Player:Dropdown({
        Title = "Select Apply Method",
        Values = { "Not Optimized", "Optimized" },
        Multi = false,
        Default = "",
        Callback = function(value)
            getgenv().ApplyMode = value
        end
    })

    -- Bhop Toggle
    local BhopToggle = Tabs.Player:Toggle({
        Title = "Bhop",
        Value = false,
        Callback = function(state)
            featureStates.Bhop = state
            getgenv().autoJumpEnabled = state
            if bhopToggleBtn then
                bhopToggleBtn.Text = state and "On" or "Off"
                bhopToggleBtn.BackgroundColor3 = state and Color3.fromRGB(0, 120, 80) or Color3.fromRGB(120, 0, 0)
            end
            checkBhopState()
        end
    })

    -- Bhop Hold Toggle
    local BhopHoldToggle = Tabs.Player:Toggle({
        Title = "Bhop (Hold Space/Jump)",
        Value = false,
        Callback = function(state)
            featureStates.BhopHold = state
            if not state then
                getgenv().bhopHoldActive = false
                checkBhopState()
            end
        end
    })

    -- Bhop Shortcut Toggle
    local BhopShortcutToggle = Tabs.Player:Toggle({
        Title = "Bhop Shortcut",
        Desc = "Show Bhop GUI For quick Toggle or press B to Toggle Bhop (Auto jump)",
        Value = false,
        Callback = function(state)
            featureStates.BhopGuiVisible = state
            if guiV2 then
                guiV2.Enabled = state
            end
            setupBhopKeybind()
        end
    })

    -- Bhop Mode Dropdown
    local BhopModeDropdown = Tabs.Player:Dropdown({
        Title = "Bhop Mode",
        Values = {"Acceleration", "No Acceleration"},
        Value = "Acceleration",
        Callback = function(value)
            getgenv().bhopMode = value
            checkBhopState()
        end
    })

    -- Bhop Acceleration Input
    local BhopAccelInput = Tabs.Player:Input({
        Title = "Bhop Acceleration (Negative Only)",
        Placeholder = "-0.5",
        Numeric = true,
        Callback = function(value)
            if tostring(value):sub(1, 1) == "-" then
                local n = tonumber(value)
                if n then
                    getgenv().bhopAccelValue = n
                    if getgenv().autoJumpEnabled or getgenv().bhopHoldActive then
                        applyBhopFriction()
                    end
                end
            end
        end
    })

    -- Jump Cooldown Input
    local JumpCooldownInput = Tabs.Player:Input({
        Title = "Jump Cooldown (Seconds)",
        Placeholder = "0.7",
        Numeric = true,
        Callback = function(value)
            local n = tonumber(value)
            if n and n > 0 then
                getgenv().jumpCooldown = n
            end
        end
    })

    -- Auto Crouch Toggle
    local AutoCrouchToggle = Tabs.Player:Toggle({
        Title = "Auto Crouch",
        Desc = "Press C to toggle if you on keyboard",
        Value = false,
        Callback = function(state)
            featureStates.AutoCrouch = state
            if autoCrouchToggleBtn then
                autoCrouchToggleBtn.Text = state and "On" or "Off"
                autoCrouchToggleBtn.BackgroundColor3 = state and Color3.fromRGB(0, 120, 80) or Color3.fromRGB(120, 0, 0)
            end
        end
    })

    -- Auto Crouch Mode Dropdown
    local AutoCrouchModeDropdown = Tabs.Player:Dropdown({
        Title = "Auto Crouch Mode",
        Values = {"Air", "Normal", "Ground"},
        Value = "Air",
        Callback = function(value)
            featureStates.AutoCrouchMode = value
        end
    })

    -- Bounce Toggle
    local BounceToggle = Tabs.Player:Toggle({
        Title = "Enable Bounce",
        Value = false,
        Callback = function(state)
            featureStates.BounceEnabled = state
            if state then
                enableBounce()
            else
                disableBounce()
            end
            if bounceToggleBtn then
                bounceToggleBtn.Text = state and "On" or "Off"
                bounceToggleBtn.BackgroundColor3 = state and Color3.fromRGB(0, 120, 80) or Color3.fromRGB(120, 0, 0)
            end
        end
    })

    -- Bounce Height Input
    local BounceHeightInput = Tabs.Player:Input({
        Title = "Bounce Height",
        Placeholder = "0",
        Value = tostring(featureStates.BounceHeight),
        Numeric = true,
        Callback = function(value)
            local num = tonumber(value)
            if num then
                featureStates.BounceHeight = math.max(0, num)
            end
        end
    })

    -- Touch Detection Epsilon Input
    local EpsilonInput = Tabs.Player:Input({
        Title = "Touch Detection Epsilon",
        Placeholder = "0.1",
        Value = tostring(featureStates.BounceEpsilon),
        Numeric = true,
        Callback = function(value)
            local num = tonumber(value)
            if num then
                featureStates.BounceEpsilon = math.max(0, num)
            end
        end
    })

    -- Visuals Tab
    Tabs.Visuals:Section({ Title = "Visual", TextSize = 20 })
    Tabs.Visuals:Divider()

    -- Full Bright Toggle
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

    -- No Fog Toggle
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

    -- Timer Display Toggle
    local TimerDisplayToggle = Tabs.Visuals:Toggle({
        Title = "Timer Display",
        Value = false,
        Callback = function(state)
            featureStates.TimerDisplay = state
            local function getRoundTimer()
                local player = game:GetService("Players").LocalPlayer
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
                local pg = game:GetService("Players").LocalPlayer.PlayerGui
                local main = pg:FindFirstChild("MainInterface")
                if main then
                    local container = main:FindFirstChild("TimerContainer")
                    if container then
                        container.Visible = visible
                    end
                end
            end
            if state then
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
    })

    -- Settings Tab
    Tabs.Settings:Section({ Title = "Settings", TextSize = 40 })
    Tabs.Settings:Section({ Title = "Personalize", TextSize = 20 })
    Tabs.Settings:Divider()

    -- Show GUI v1 Toggle
    local ShowGUIv1Toggle = Tabs.Settings:Toggle({
        Title = "Show Main GUI (v1)",
        Value = featureStates.ShowGUIv1,
        Callback = function(state)
            featureStates.ShowGUIv1 = state
            Window:Toggle(state)
            if state then
                Window:Open()
            else
                Window:Close()
            end
        end
    })

    -- Show GUI v2 Toggle
    local ShowGUIv2Toggle = Tabs.Settings:Toggle({
        Title = "Show Button Panel (v2)",
        Value = featureStates.ShowGUIv2,
        Callback = function(state)
            featureStates.ShowGUIv2 = state
            if guiV2 then
                guiV2.Enabled = state
            end
        end
    })

    -- Main GUI v1 Size Inputs
    local GuiV1SizeXInput = Tabs.Settings:Input({
        Title = "Main GUI Width (X)",
        Placeholder = tostring(guiV1SizeX),
        Value = tostring(guiV1SizeX),
        NumbersOnly = true,
        Callback = function(value)
            local num = tonumber(value)
            if num and num > 0 then
                guiV1SizeX = num
                Window.Size = UDim2.fromOffset(guiV1SizeX, guiV1SizeY)
            end
        end
    })

    local GuiV1SizeYInput = Tabs.Settings:Input({
        Title = "Main GUI Height (Y)",
        Placeholder = tostring(guiV1SizeY),
        Value = tostring(guiV1SizeY),
        NumbersOnly = true,
        Callback = function(value)
            local num = tonumber(value)
            if num and num > 0 then
                guiV1SizeY = num
                Window.Size = UDim2.fromOffset(guiV1SizeX, guiV1SizeY)
            end
        end
    })

    -- Button Panel GUI v2 Size Inputs
    local GuiV2SizeXInput = Tabs.Settings:Input({
        Title = "Button Panel Width (X)",
        Placeholder = tostring(guiV2SizeX),
        Value = tostring(guiV2SizeX),
        NumbersOnly = true,
        Callback = function(value)
            local num = tonumber(value)
            if num and num > 0 then
                guiV2SizeX = num
                if guiV2 then
                    guiV2.Frame.Size = UDim2.new(0, guiV2SizeX, 0, guiV2SizeY)
                end
            end
        end
    })

    local GuiV2SizeYInput = Tabs.Settings:Input({
        Title = "Button Panel Height (Y)",
        Placeholder = tostring(guiV2SizeY),
        Value = tostring(guiV2SizeY),
        NumbersOnly = true,
        Callback = function(value)
            local num = tonumber(value)
            if num and num > 0 then
                guiV2SizeY = num
                if guiV2 then
                    guiV2.Frame.Size = UDim2.new(0, guiV2SizeX, 0, guiV2SizeY)
                end
            end
        end
    })

    -- Utility Buttons
    Tabs.Settings:Section({ Title = "Utility", TextSize = 20 })
    Tabs.Settings:Divider()

    local ClearInvisWallButton = Tabs.Settings:Button({
        Title = "Clear Invis Walls",
        Callback = function()
            local invisPartsFolder = workspace:FindFirstChild("Game") and workspace.Game:FindFirstChild("Map") and workspace.Game.Map:FindFirstChild("InvisParts")
            if invisPartsFolder then
                for _, obj in ipairs(invisPartsFolder:GetDescendants()) do
                    if obj:IsA("BasePart") then
                        obj.CanCollide = false
                    end
                end
            end
        end
    })

    local LowGraphicsButton = Tabs.Settings:Button({
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

    local RemoveTextureButton = Tabs.Settings:Button({
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

    -- Lag Switch Toggle
    local LagSwitchToggle = Tabs.Settings:Toggle({
        Title = "Lag Switch",
        Icon = "zap",
        Value = false,
        Callback = function(state)
            featureStates.LagSwitchEnabled = state
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

    -- Lag Duration Input
    local LagDurationInput = Tabs.Settings:Input({
        Title = "Lag Duration (seconds)",
        Placeholder = "0.5",
        Value = tostring(featureStates.LagDuration),
        NumbersOnly = true,
        Callback = function(text)
            local n = tonumber(text)
            if n and n > 0 then
                featureStates.LagDuration = n
            end
        end
    })

    Window:SelectTab(1)
end

setupGUIv1()

-- Handle GUI v1 visibility changes
Window:OnClose(function()
    featureStates.ShowGUIv1 = false
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

Window:OnOpen(function()
    print("Window opened")
    featureStates.ShowGUIv1 = true
end)

-- Ensure GUI size updates are applied
game:GetService("UserInputService").WindowFocused:Connect(function()
    saveKeybind()
end)

-- Initialize variables for config management
local ConfigManager = Window.ConfigManager
local configFile = nil
local MyPlayerData = {
    name = player.Name,
    level = 1,
    inventory = {}
}

-- Save configuration
if ConfigManager then
    ConfigManager:Init(Window)
    Tabs.Settings:Button({
        Title = "Save Configuration",
        Icon = "save",
        Variant = "Primary",
        Callback = function()
            configFile = ConfigManager:CreateConfig("default")
            configFile:Register("SpeedInput", SpeedInput)
            configFile:Register("JumpCapInput", JumpCapInput)
            configFile:Register("StrafeInput", StrafeInput)
            configFile:Register("ApplyMethodDropdown", ApplyMethodDropdown)
            configFile:Register("BhopToggle", BhopToggle)
            configFile:Register("BhopHoldToggle", BhopHoldToggle)
            configFile:Register("BhopShortcutToggle", BhopShortcutToggle)
            configFile:Register("BhopModeDropdown", BhopModeDropdown)
            configFile:Register("BhopAccelInput", BhopAccelInput)
            configFile:Register("JumpCooldownInput", JumpCooldownInput)
            configFile:Register("AutoCrouchToggle", AutoCrouchToggle)
            configFile:Register("AutoCrouchModeDropdown", AutoCrouchModeDropdown)
            configFile:Register("BounceToggle", BounceToggle)
            configFile:Register("BounceHeightInput", BounceHeightInput)
            configFile:Register("EpsilonInput", EpsilonInput)
            configFile:Register("FullBrightToggle", FullBrightToggle)
            configFile:Register("NoFogToggle", NoFogToggle)
            configFile:Register("TimerDisplayToggle", TimerDisplayToggle)
            configFile:Register("ShowGUIv1Toggle", ShowGUIv1Toggle)
            configFile:Register("ShowGUIv2Toggle", ShowGUIv2Toggle)
            configFile:Register("GuiV1SizeXInput", GuiV1SizeXInput)
            configFile:Register("GuiV1SizeYInput", GuiV1SizeYInput)
            configFile:Register("GuiV2SizeXInput", GuiV2SizeXInput)
            configFile:Register("GuiV2SizeYInput", GuiV2SizeYInput)
            configFile:Register("ClearInvisWallButton", ClearInvisWallButton)
            configFile:Register("LowGraphicsButton", LowGraphicsButton)
            configFile:Register("RemoveTextureButton", RemoveTextureButton)
            configFile:Register("LagSwitchToggle", LagSwitchToggle)
            configFile:Register("LagDurationInput", LagDurationInput)
            configFile:Set("playerData", MyPlayerData)
            configFile:Set("lastSave", os.date("%Y-%m-%d %H:%M:%S"))
            configFile:Save()
        end
    })
    Tabs.Settings:Button({
        Title = "Load Configuration",
        Icon = "folder",
        Callback = function()
            configFile = ConfigManager:CreateConfig("default")
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

-- Cleanup on player leave
Players.PlayerRemoving:Connect(function(leavingPlayer)
    if leavingPlayer == player then
        if bhopConnection then
            bhopConnection:Disconnect()
        end
        if bhopKeyConnection then
            bhopKeyConnection:Disconnect()
        end
        if characterConnection then
            characterConnection:Disconnect()
        end
        if lagInputConnection then
            lagInputConnection:Disconnect()
        end
        if crouchConnection then
            crouchConnection:Disconnect()
        end
        disableBounce()
        unloadBhop()
        unloadLagSystem()
        if guiV2 then
            guiV2:Destroy()
        end
        if lagGui then
            lagGui:Destroy()
        end
    end
end)

-- Helper functions for compatibility
local function getCleanKeyName(keyCode)
    return keyCode.Name
end

local function saveKeybind()
    -- Placeholder for saving keybind if needed
end

local function getgenv()
    return _G
end

-- Initialize global variables
currentSettings = currentSettings or {
    Speed = "1500",
    JumpCap = "1",
    AirStrafeAcceleration = "187"
}

-- Function to apply settings to tables
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

-- Apply stored settings
local appliedOnce = false
local playerModelPresent = false
local function isPlayerModelPresent()
    local GameFolder = workspace:FindFirstChild("Game")
    local PlayersFolder = GameFolder and GameFolder:FindFirstChild("Players")
    return PlayersFolder and PlayersFolder:FindFirstChild(player.Name) ~= nil
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

-- Functions for visual features
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

-- Ensure the SecurityPart exists
if not workspace:FindFirstChild("SecurityPart") then
    local SecurityPart = Instance.new("Part")
    SecurityPart.Name = "SecurityPart"
    SecurityPart.Size = Vector3.new(10, 1, 10)
    SecurityPart.Position = Vector3.new(0, 500, 0)
    SecurityPart.Anchored = true
    SecurityPart.CanCollide = true
    SecurityPart.Parent = workspace
end

-- Final setup
setupMobileJumpButton()
Window:UnlockAll()

-- Notify user that script is ready
print("Evade Test Script Loaded Successfully!")
