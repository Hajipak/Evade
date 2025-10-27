-- Load WindUI
local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()

-- Localization setup (Optional, based on DaraHub structure)
local Localization = WindUI:Localization({
    Enabled = true,
    Prefix = "loc:",
    DefaultLanguage = "en",
    Translations = {
        ["en"] = {
            ["SCRIPT_TITLE"] = "Movement Hub",
            ["WELCOME"] = "Made by Zen",
            ["FEATURES"] = "Features",
            ["Player_TAB"] = "Player",
            ["AUTO_TAB"] = "Auto",
            ["VISUALS_TAB"] = "Visuals",
            ["ESP_TAB"] = "ESP",
            ["SETTINGS_TAB"] = "Settings",
        },
    }
})

-- Create Window
local Window = WindUI:CreateWindow({
    Title = "Movement Hub",
    SubTitle = "by Zen",
    Width = 500, -- Adjust width as needed
    Height = 400, -- Adjust height as needed
    Theme = "Dark", -- Default theme
    Version = "1.0.0",
    MinimizeKey = Enum.KeyCode.RightShift, -- Default key to minimize
    SaveFolder = "MovementHubConfigs", -- Folder for saving configs
})

-- Add Topbar Button for theme switching (like DaraHub)
Window:CreateTopbarButton("theme-switcher", "moon", function()
    WindUI:SetTheme(WindUI:GetCurrentTheme() == "Dark" and "Light" or "Dark")
end, 990)

-- Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Variables & States (Preserved from previous script)
local featureStates = {
    Bhop = false,
    AutoCarry = false,
    CustomGravity = false,
    AutoCrouch = false,
    GravityValue = workspace.Gravity,
    AutoCrouchMode = "Air",
    -- Bounce state is now handled by the toggle itself
    TimerDisplay = false, -- Add state for Timer Display
    BhopHold = false, -- Add state for Bhop Hold mode
}

-- Bhop Variables (Based on Evade Test.txt)
getgenv().bhopMode = getgenv().bhopMode or "Acceleration"
getgenv().bhopAccelValue = getgenv().bhopAccelValue or -0.5
getgenv().bhopHoldActive = false -- This is for holding a key to bhop, not the main toggle

-- Other Variables (Preserved from previous script)
local originalGameGravity = workspace.Gravity

-- GUI Variables
local bhopGui, bhopGuiButton
local autoCarryGui, autoCarryGuiButton
local gravityGui, gravityGuiButton
local autoCrouchGui, autoCrouchGuiButton

-- GUI Button Visibility States (getgenv for persistence)
getgenv().bhopGuiVisible = getgenv().bhopGuiVisible or false
getgenv().autoCarryGuiVisible = getgenv().autoCarryGuiVisible or false
getgenv().gravityGuiVisible = getgenv().gravityGuiVisible or false
getgenv().autoCrouchGuiVisible = getgenv().autoCrouchGuiVisible or false

-- Button Size States (getgenv for persistence)
getgenv().guiButtonSizeX = getgenv().guiButtonSizeX or 60
getgenv().guiButtonSizeY = getgenv().guiButtonSizeY or 60

-- Current Settings (Default Values)
local currentSettings = {
    AirStrafeAcceleration = "187",
    JumpCap = "1",
    Speed = "1500"
}

-- Bounce Variables (Based on DaraHub code)
local BOUNCE_HEIGHT = 0 -- Default value, will be loaded from config
local BOUNCE_EPSILON = 0.1 -- Default value, will be loaded from config
local BOUNCE_ENABLED = false -- Default value, will be loaded from config
local touchConnections = {}

-- Function to setup bounce on touch for a character (Based on DaraHub code)
local function setupBounceOnTouch(character)
    if not BOUNCE_ENABLED then return end
    if not character or not character:FindFirstChild("HumanoidRootPart") then return end
    local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

    -- Disconnect any existing connection for this character
    if touchConnections[character] then
        touchConnections[character]:Disconnect()
        touchConnections[character] = nil
    end

    local touchConnection
    touchConnection = humanoidRootPart.Touched:Connect(function(hit)
        if not BOUNCE_ENABLED or not hit or hit.Parent == character then return end

        -- Calculate Y position boundaries
        local playerBottom = humanoidRootPart.Position.Y - humanoidRootPart.Size.Y / 2
        local playerTop = humanoidRootPart.Position.Y + humanoidRootPart.Size.Y / 2
        local hitBottom = hit.Position.Y - hit.Size.Y / 2
        local hitTop = hit.Position.Y + hit.Size.Y / 2

        -- Check if hit is above the player (don't bounce)
        if hitTop <= playerBottom + BOUNCE_EPSILON then
            return
        -- Check if hit is below the player (don't bounce)
        elseif hitBottom >= playerTop - BOUNCE_EPSILON then
            return
        end

        -- Fire remote event if needed (e.g., for game interaction)
        -- local remoteEvent = ReplicatedStorage:WaitForChild("Events"):WaitForChild("Character"):WaitForChild("PassCharacterInfo")
        -- remoteEvent:FireServer({}, {2})

        if BOUNCE_HEIGHT > 0 then
            local bodyVel = Instance.new("BodyVelocity")
            bodyVel.MaxForce = Vector3.new(0, math.huge, 0) -- Infinite force on Y-axis
            bodyVel.Velocity = Vector3.new(0, BOUNCE_HEIGHT, 0)
            bodyVel.Parent = humanoidRootPart
            Debris:AddItem(bodyVel, 0.2)
        end
    end)

    touchConnections[character] = touchConnection

    -- Clean up connection when character is removed
    character.AncestryChanged:Connect(function()
        if not character.Parent then
            if touchConnections[character] then
                touchConnections[character]:Disconnect()
                touchConnections[character] = nil
            end
        end
    end)
end

-- Function to disable bounce (Based on DaraHub code)
local function disableBounce()
    for character, connection in pairs(touchConnections) do
        if connection then
            connection:Disconnect()
            touchConnections[character] = nil
        end
    end
end

-- Required Fields for Config Tables (Preserved from previous script)
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

-- Function to check if table has all required fields (Preserved from previous script)
local function hasAllFields(tbl)
    if type(tbl) ~= "table" then return false end
    for field, _ in pairs(requiredFields) do
        if rawget(tbl, field) == nil then return false end
    end
    return true
end

-- Function to find config tables (Preserved from previous script)
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

-- Function to apply values to tables (using "Not Optimized" method) (Preserved from previous script)
local function applyToTables(callback)
    local targets = getConfigTables()
    if #targets == 0 then return end
    for i, tableObj in ipairs(targets) do
        if tableObj and typeof(tableObj) == "table" then
            pcall(callback, tableObj)
        end
    end
end

-- Function to apply stored settings on startup (Preserved from previous script)
local function applyStoredSettings()
    local airStrafeVal = tonumber(currentSettings.AirStrafeAcceleration)
    local jumpCapVal = tonumber(currentSettings.JumpCap)
    local speedVal = tonumber(currentSettings.Speed)

    if airStrafeVal and tostring(airStrafeVal) ~= "187" then
        applyToTables(function(obj) obj.AirStrafeAcceleration = airStrafeVal end)
    end
    if jumpCapVal and tostring(jumpCapVal) ~= "1" then
        applyToTables(function(obj) obj.JumpCap = jumpCapVal end)
    end
    if speedVal and tostring(speedVal) ~= "1500" then
        applyToTables(function(obj) obj.Speed = speedVal end)
    end
end

-- Function to make GUI frames draggable (Preserved from previous script)
local function makeDraggable(frame)
    frame.Active = true
    frame.Draggable = true
    local dragDetector = Instance.new("UIDragDetector")
    dragDetector.Parent = frame
end

-- Bhop Feature Variables & Logic (Updated based on Evade Test.txt - Less Laggy Version)
local bhopConnection = nil
local bhopLoaded = false

-- New updateBhop function based on Evade Test.txt (runs less frequently)
local function updateBhop()
    while true do -- Loop indefinitely
        local friction = 5 -- Default friction value
        local isBhopActive = getgenv().autoJumpEnabled or getgenv().bhopHoldActive -- Check both main toggle and hold toggle

        if isBhopActive and getgenv().bhopMode == "Acceleration" then
            friction = getgenv().bhopAccelValue or -0.5 -- Use the input value when Acceleration mode is active
        end

        -- Apply friction change if main toggle is off (reset) or if mode is No Accel (reset) while active
        if not getgenv().autoJumpEnabled then
            friction = 5 -- Always reset if main toggle is off
        else
            if getgenv().bhopMode == "No Acceleration" then
                friction = 5 -- Reset friction if No Acceleration mode is active
            end
        end

        -- Iterate through tables and modify Friction
        for _, t in pairs(getgc(true)) do
            if type(t) == "table" and rawget(t, "Friction") then
                if getgenv().bhopMode == "No Acceleration" then
                    -- If No Acceleration mode, always reset friction
                    t.Friction = 5
                else
                    -- Otherwise, apply the calculated friction (either default or from accel input)
                    t.Friction = friction
                end
            end
        end

        task.wait(0.15) -- Wait for 0.15 seconds before the next cycle (less frequent than Heartbeat)
    end
end

-- Function to setup mobile jump button for Bhop Hold (Based on Evade Test.txt)
local function setupJumpButton()
    local success, err = pcall(function()
        local touchGui = player:WaitForChild("PlayerGui"):WaitForChild("TouchGui", 5)
        if not touchGui then return end
        local touchControlFrame = touchGui:WaitForChild("TouchControlFrame", 5)
        if not touchControlFrame then return end
        local jumpButton = touchControlFrame:WaitForChild("JumpButton", 5)
        if not jumpButton then return end

        jumpButton.MouseButton1Down:Connect(function()
            if featureStates.BhopHold then -- Use featureStates variable
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

-- Function to setup Bhop keybind for GUI toggle (only affects main toggle state)
local function setupBhopKeybind()
    if bhopKeyConnection then bhopKeyConnection:Disconnect() end
    bhopKeyConnection = UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
        if gameProcessedEvent then return end
        -- Use a specific key (e.g., L) to toggle bhop main state, but only if GUI toggle is enabled
        if input.KeyCode == Enum.KeyCode.L and getgenv().bhopGuiVisible then
            getgenv().autoJumpEnabled = not getgenv().autoJumpEnabled -- Toggle the main state
            featureStates.Bhop = getgenv().autoJumpEnabled -- Update feature state
            if bhopGuiButton then -- Update the GUI button if it exists
                bhopGuiButton.Text = getgenv().autoJumpEnabled and "On" or "Off"
                bhopGuiButton.BackgroundColor3 = getgenv().autoJumpEnabled and Color3.fromRGB(0, 120, 80) or Color3.fromRGB(120, 0, 0)
            end
            -- No need to explicitly load/unload as updateBhop handles it
        end
    end)
end


-- AutoCarry Feature Logic (Preserved from previous script)
local AutoCarryConnection = nil
local function startAutoCarry()
    if AutoCarryConnection then return end
    AutoCarryConnection = RunService.Heartbeat:Connect(function()
        if not featureStates.AutoCarry then return end
        local char = player.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then
            for _, other in ipairs(Players:GetPlayers()) do
                if other ~= player and other.Character and other.Character:FindFirstChild("HumanoidRootPart") then
                    local distance = (hrp.Position - other.Character.HumanoidRootPart.Position).Magnitude
                    if distance < 15 then -- Adjust range as needed
                        firetouchinterest(hrp, other.Character.HumanoidRootPart, 0)
                        task.wait(0.1)
                        firetouchinterest(hrp, other.Character.HumanoidRootPart, 1)
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


-- AutoCrouch Feature Logic (Preserved from previous script)
local previousCrouchState = false
local spamDown = true -- For "Normal" mode spam
local function fireKeybind(state, action)
    if state then
        game:GetService("VirtualUser"):CaptureController()
        game:GetService("VirtualUser"):Button1Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
    else
        game:GetService("VirtualUser"):Button1Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
    end
end

local crouchConnection = nil
local function startAutoCrouch()
    if crouchConnection then crouchConnection:Disconnect() end
    crouchConnection = RunService.Heartbeat:Connect(function()
        if not featureStates.AutoCrouch then
            if previousCrouchState then
                fireKeybind(false, "Crouch") -- Release crouch if it was active
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
        elseif mode == "Air" then
            -- Crouch only in air
            if humanoid:GetState() == Enum.HumanoidStateType.Freefall or humanoid:GetState() == Enum.HumanoidStateType.Jumping then
                if not previousCrouchState then
                    fireKeybind(true, "Crouch")
                    previousCrouchState = true
                end
            else
                if previousCrouchState then
                    fireKeybind(false, "Crouch")
                    previousCrouchState = false
                end
            end
        elseif mode == "Ground" then
            -- Crouch only on ground
             if humanoid:GetState() == Enum.HumanoidStateType.Landed or humanoid:GetState() == Enum.HumanoidStateType.Running then
                if not previousCrouchState then
                    fireKeybind(true, "Crouch")
                    previousCrouchState = true
                end
            else
                if previousCrouchState then
                    fireKeybind(false, "Crouch")
                    previousCrouchState = false
                end
            end
        end
    end)
end

local function stopAutoCrouch()
    if crouchConnection then
        crouchConnection:Disconnect()
        crouchConnection = nil
    end
    if previousCrouchState then
        fireKeybind(false, "Crouch") -- Ensure crouch is released on stop
        previousCrouchState = false
    end
end

-- --- Create GUI Button Functions (Based on DaraHub style) ---
local function createBhopGui(yOffset)
    -- Destroy old GUI if it exists
    local bhopGuiOld = playerGui:FindFirstChild("BhopGui")
    if bhopGuiOld then bhopGuiOld:Destroy() end

    bhopGui = Instance.new("ScreenGui")
    bhopGui.Name = "BhopGui"
    bhopGui.IgnoreGuiInset = true
    bhopGui.ResetOnSpawn = false
    bhopGui.Enabled = getgenv().bhopGuiVisible -- Controlled by visibility state
    bhopGui.Parent = playerGui

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, getgenv().guiButtonSizeX, 0, getgenv().guiButtonSizeY) -- Use dynamic size
    frame.Position = UDim2.new(0.5, -getgenv().guiButtonSizeX/2, 0.12 + (yOffset or 0), 0) -- Centered X
    frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    frame.BackgroundTransparency = 0.35
    frame.BorderSizePixel = 0
    frame.Parent = bhopGui

    makeDraggable(frame)

    local label = Instance.new("TextLabel")
    label.Text = "Bhop"
    label.Size = UDim2.new(0.9, 0, 0.3, 0)
    label.Position = UDim2.new(0.05, 0, 0.05, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.Font = Enum.Font.Roboto
    label.TextSize = 20
    label.TextXAlignment = Enum.TextXAlignment.Center
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.TextScaled = true
    label.Parent = frame

    bhopGuiButton = Instance.new("TextButton")
    bhopGuiButton.Name = "ToggleButton"
    bhopGuiButton.Text = getgenv().autoJumpEnabled and "On" or "Off"
    bhopGuiButton.Size = UDim2.new(0.9, 0, 0.5, 0)
    bhopGuiButton.Position = UDim2.new(0.05, 0, 0.5, 0)
    bhopGuiButton.BackgroundColor3 = getgenv().autoJumpEnabled and Color3.fromRGB(0, 120, 80) or Color3.fromRGB(120, 0, 0)
    bhopGuiButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    bhopGuiButton.Font = Enum.Font.Roboto
    bhopGuiButton.TextSize = 14
    bhopGuiButton.TextXAlignment = Enum.TextXAlignment.Center
    bhopGuiButton.TextYAlignment = Enum.TextYAlignment.Center
    bhopGuiButton.Parent = frame

    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 4)
    buttonCorner.Parent = bhopGuiButton

    bhopGuiButton.MouseButton1Click:Connect(function()
        getgenv().autoJumpEnabled = not getgenv().autoJumpEnabled
        featureStates.Bhop = getgenv().autoJumpEnabled
        bhopGuiButton.Text = getgenv().autoJumpEnabled and "On" or "Off"
        bhopGuiButton.BackgroundColor3 = getgenv().autoJumpEnabled and Color3.fromRGB(0, 120, 80) or Color3.fromRGB(120, 0, 0)
        -- No need to explicitly load/unload as updateBhop handles it
    end)

    return bhopGui, bhopGuiButton
end

local function createAutoCarryGui(yOffset)
    -- Destroy old GUI if it exists
    local autoCarryGuiOld = playerGui:FindFirstChild("AutoCarryGui")
    if autoCarryGuiOld then autoCarryGuiOld:Destroy() end

    autoCarryGui = Instance.new("ScreenGui")
    autoCarryGui.Name = "AutoCarryGui"
    autoCarryGui.IgnoreGuiInset = true
    autoCarryGui.ResetOnSpawn = false
    autoCarryGui.Enabled = getgenv().autoCarryGuiVisible -- Controlled by visibility state
    autoCarryGui.Parent = playerGui

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, getgenv().guiButtonSizeX, 0, getgenv().guiButtonSizeY) -- Use dynamic size
    frame.Position = UDim2.new(0.5, -getgenv().guiButtonSizeX/2, 0.12 + (yOffset or 0), 0) -- Centered X
    frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    frame.BackgroundTransparency = 0.35
    frame.BorderSizePixel = 0
    frame.Parent = autoCarryGui

    makeDraggable(frame)

    local label = Instance.new("TextLabel")
    label.Text = "Carry"
    label.Size = UDim2.new(0.9, 0, 0.3, 0)
    label.Position = UDim2.new(0.05, 0, 0.05, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.Font = Enum.Font.Roboto
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Center
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.TextScaled = true
    label.Parent = frame

    autoCarryGuiButton = Instance.new("TextButton")
    autoCarryGuiButton.Name = "ToggleButton"
    autoCarryGuiButton.Text = featureStates.AutoCarry and "On" or "Off"
    autoCarryGuiButton.Size = UDim2.new(0.9, 0, 0.5, 0)
    autoCarryGuiButton.Position = UDim2.new(0.05, 0, 0.5, 0)
    autoCarryGuiButton.BackgroundColor3 = featureStates.AutoCarry and Color3.fromRGB(0, 120, 80) or Color3.fromRGB(120, 0, 0)
    autoCarryGuiButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    autoCarryGuiButton.Font = Enum.Font.Roboto
    autoCarryGuiButton.TextSize = 14
    autoCarryGuiButton.TextXAlignment = Enum.TextXAlignment.Center
    autoCarryGuiButton.TextYAlignment = Enum.TextYAlignment.Center
    autoCarryGuiButton.Parent = frame

    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 4)
    buttonCorner.Parent = autoCarryGuiButton

    autoCarryGuiButton.MouseButton1Click:Connect(function()
        featureStates.AutoCarry = not featureStates.AutoCarry
        if featureStates.AutoCarry then
            startAutoCarry()
        else
            stopAutoCarry()
        end
        autoCarryGuiButton.Text = featureStates.AutoCarry and "On" or "Off"
        autoCarryGuiButton.BackgroundColor3 = featureStates.AutoCarry and Color3.fromRGB(0, 120, 80) or Color3.fromRGB(120, 0, 0)
    end)

    return autoCarryGui, autoCarryGuiButton
end

local function createGravityGui(yOffset)
    -- Destroy old GUI if it exists
    local gravityGuiOld = playerGui:FindFirstChild("GravityGui")
    if gravityGuiOld then gravityGuiOld:Destroy() end

    gravityGui = Instance.new("ScreenGui")
    gravityGui.Name = "GravityGui"
    gravityGui.IgnoreGuiInset = true
    gravityGui.ResetOnSpawn = false
    gravityGui.Enabled = getgenv().gravityGuiVisible -- Controlled by visibility state
    gravityGui.Parent = playerGui

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, getgenv().guiButtonSizeX, 0, getgenv().guiButtonSizeY) -- Use dynamic size
    frame.Position = UDim2.new(0.5, -getgenv().guiButtonSizeX/2, 0.12 + (yOffset or 0), 0) -- Centered X
    frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    frame.BackgroundTransparency = 0.35
    frame.BorderSizePixel = 0
    frame.Parent = gravityGui

    makeDraggable(frame)

    local label = Instance.new("TextLabel")
    label.Text = "Gravity"
    label.Size = UDim2.new(0.9, 0, 0.3, 0)
    label.Position = UDim2.new(0.05, 0, 0.05, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.Font = Enum.Font.Roboto
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Center
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.TextScaled = true
    label.Parent = frame

    gravityGuiButton = Instance.new("TextButton")
    gravityGuiButton.Name = "ToggleButton"
    gravityGuiButton.Text = featureStates.CustomGravity and "On" or "Off"
    gravityGuiButton.Size = UDim2.new(0.9, 0, 0.5, 0)
    gravityGuiButton.Position = UDim2.new(0.05, 0, 0.5, 0)
    gravityGuiButton.BackgroundColor3 = featureStates.CustomGravity and Color3.fromRGB(0, 120, 80) or Color3.fromRGB(120, 0, 0)
    gravityGuiButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    gravityGuiButton.Font = Enum.Font.Roboto
    gravityGuiButton.TextSize = 14
    gravityGuiButton.TextXAlignment = Enum.TextXAlignment.Center
    gravityGuiButton.TextYAlignment = Enum.TextYAlignment.Center
    gravityGuiButton.Parent = frame

    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 4)
    buttonCorner.Parent = gravityGuiButton

    gravityGuiButton.MouseButton1Click:Connect(function()
        featureStates.CustomGravity = not featureStates.CustomGravity
        if featureStates.CustomGravity then
            workspace.Gravity = featureStates.GravityValue
        else
            workspace.Gravity = originalGameGravity
        end
        gravityGuiButton.Text = featureStates.CustomGravity and "On" or "Off"
        gravityGuiButton.BackgroundColor3 = featureStates.CustomGravity and Color3.fromRGB(0, 120, 80) or Color3.fromRGB(120, 0, 0)
    end)

    return gravityGui, gravityGuiButton
end

local function createAutoCrouchGui(yOffset)
    -- Destroy old GUI if it exists
    local autoCrouchGuiOld = playerGui:FindFirstChild("AutoCrouchGui")
    if autoCrouchGuiOld then autoCrouchGuiOld:Destroy() end

    autoCrouchGui = Instance.new("ScreenGui")
    autoCrouchGui.Name = "AutoCrouchGui"
    autoCrouchGui.IgnoreGuiInset = true
    autoCrouchGui.ResetOnSpawn = false
    autoCrouchGui.Enabled = getgenv().autoCrouchGuiVisible -- Controlled by visibility state
    autoCrouchGui.Parent = playerGui

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, getgenv().guiButtonSizeX, 0, getgenv().guiButtonSizeY) -- Use dynamic size
    frame.Position = UDim2.new(0.5, -getgenv().guiButtonSizeX/2, 0.12 + (yOffset or 0), 0) -- Centered X
    frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    frame.BackgroundTransparency = 0.35
    frame.BorderSizePixel = 0
    frame.Parent = autoCrouchGui

    makeDraggable(frame)

    local label = Instance.new("TextLabel")
    label.Text = "Crouch"
    label.Size = UDim2.new(0.9, 0, 0.3, 0)
    label.Position = UDim2.new(0.05, 0, 0.05, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.Font = Enum.Font.Roboto
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Center
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.TextScaled = true
    label.Parent = frame

    autoCrouchGuiButton = Instance.new("TextButton")
    autoCrouchGuiButton.Name = "ToggleButton"
    autoCrouchGuiButton.Text = featureStates.AutoCrouch and "On" or "Off"
    autoCrouchGuiButton.Size = UDim2.new(0.9, 0, 0.5, 0)
    autoCrouchGuiButton.Position = UDim2.new(0.05, 0, 0.5, 0)
    autoCrouchGuiButton.BackgroundColor3 = featureStates.AutoCrouch and Color3.fromRGB(0, 120, 80) or Color3.fromRGB(120, 0, 0)
    autoCrouchGuiButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    autoCrouchGuiButton.Font = Enum.Font.Roboto
    autoCrouchGuiButton.TextSize = 14
    autoCrouchGuiButton.TextXAlignment = Enum.TextXAlignment.Center
    autoCrouchGuiButton.TextYAlignment = Enum.TextYAlignment.Center
    autoCrouchGuiButton.Parent = frame

    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 4)
    buttonCorner.Parent = autoCrouchGuiButton

    autoCrouchGuiButton.MouseButton1Click:Connect(function()
        featureStates.AutoCrouch = not featureStates.AutoCrouch
        if featureStates.AutoCrouch then
            startAutoCrouch()
        else
            stopAutoCrouch()
        end
        autoCrouchGuiButton.Text = featureStates.AutoCrouch and "On" or "Off"
        autoCrouchGuiButton.BackgroundColor3 = featureStates.AutoCrouch and Color3.fromRGB(0, 120, 80) or Color3.fromRGB(120, 0, 0)
    end)

    return autoCrouchGui, autoCrouchGuiButton
end


-- --- UI Creation (Using WindUI structure like DaraHub) ---
local FeatureSection = Window:Section({ Title = "Features", Opened = true })

local Tabs = {
    Player = FeatureSection:Tab({ Title = "Movement Hub", Icon = "motion" }), -- Renamed Tab
    Visuals = FeatureSection:Tab({ Title = "Visuals", Icon = "eye" }), -- New Visuals Tab
    Settings = FeatureSection:Tab({ Title = "Settings", Icon = "settings" }) -- Added Settings Tab like DaraHub
}

-- Player Tab Content (Renamed from Movement Hub)
Tabs.Player:Section({ Title = "Movement Settings", TextSize = 20 })

local StrafeInput = Tabs.Player:Input({
    Title = "Strafe Acceleration",
    Icon = "wind",
    Placeholder = "Default 187",
    Value = currentSettings.AirStrafeAcceleration,
    Callback = function(val)
        local num = tonumber(val)
        if num then
            currentSettings.AirStrafeAcceleration = tostring(num)
            applyToTables(function(obj) obj.AirStrafeAcceleration = num end)
        end
    end
})

local JumpCapInput = Tabs.Player:Input({
    Title = "Jump Cap",
    Icon = "chevrons-up",
    Placeholder = "Default 1",
    Value = currentSettings.JumpCap,
    Callback = function(val)
        local num = tonumber(val)
        if num then
            currentSettings.JumpCap = tostring(num)
            applyToTables(function(obj) obj.JumpCap = num end)
        end
    end
})

local SpeedInput = Tabs.Player:Input({
    Title = "Speed",
    Icon = "tachometer",
    Placeholder = "Default 1500",
    Value = currentSettings.Speed,
    Callback = function(val)
        local num = tonumber(val)
        if num then
            currentSettings.Speed = tostring(num)
            applyToTables(function(obj) obj.Speed = num end)
        end
    end
})

local ApplyMethodDropdown = Tabs.Player:Dropdown({
    Title = "Select Apply Method",
    Values = { "none", "Not Optimized", "Optimized" }, -- Added "none" as default
    Multi = false,
    Default = getgenv().ApplyMode or "none", -- Default to "none"
    Callback = function(value)
        getgenv().ApplyMode = value
        -- You can add logic here to change how settings are applied based on the method
        -- For now, applyToTables uses the "Not Optimized" method regardless of this setting
    end
})

Tabs.Player:Section({ Title = "Features", TextSize = 20 })

local BhopToggle = Tabs.Player:Toggle({
    Title = "Bhop",
    Value = featureStates.Bhop,
    Callback = function(state)
        featureStates.Bhop = state
        getgenv().autoJumpEnabled = state -- Link toggle state to the main bhop variable
        if bhopGuiButton then
            bhopGuiButton.Text = getgenv().autoJumpEnabled and "On" or "Off"
            bhopGuiButton.BackgroundColor3 = getgenv().autoJumpEnabled and Color3.fromRGB(0, 120, 80) or Color3.fromRGB(120, 0, 0)
        end
        -- No need to explicitly load/unload as updateBhop handles it
    end
})

local BhopGUIToggle = Tabs.Player:Toggle({
    Title = "Bhop GUI Toggle",
    Value = getgenv().bhopGuiVisible,
    Callback = function(state)
        getgenv().bhopGuiVisible = state
        if state then
            -- Create the GUI if it doesn't exist and enable it
            if not bhopGui then
                createBhopGui(0) -- Pass the initial Y offset
                setupBhopKeybind() -- Ensure keybind is active if GUI is visible
            else
                bhopGui.Enabled = state
            end
        else
            -- Just disable the GUI if the state is false
            if bhopGui then
                bhopGui.Enabled = state
            end
        end
        -- Also re-setup keybinds in case visibility changed
        setupBhopKeybind()
    end
})

-- Bhop Mode Dropdown
local BhopModeDropdown = Tabs.Player:Dropdown({
    Title = "Bhop Mode",
    Values = {"Acceleration", "No Acceleration"},
    Value = getgenv().bhopMode, -- Use the global variable
    Callback = function(value)
        getgenv().bhopMode = value -- Update the global variable
        -- The updateBhop function will handle the mode change on the next iteration
    end
})

-- Bhop Acceleration Input
local BhopAccelInput = Tabs.Player:Input({
    Title = "Bhop Accel (Negative)",
    Placeholder = "-0.5",
    Value = tostring(getgenv().bhopAccelValue), -- Use the global variable
    NumbersOnly = true, -- WindUI equivalent of Numeric
    Callback = function(input)
        local val = tonumber(input)
        if val and val < 0 then -- Ensure value is a number and negative
            getgenv().bhopAccelValue = val -- Update the global variable
        end
    end
})

-- Bhop Hold Toggle (Based on Evade Test.txt)
local BhopHoldToggle = Tabs.Player:Toggle({
    Title = "Bhop (Hold Space/Jump)",
    Value = featureStates.BhopHold,
    Callback = function(state)
        featureStates.BhopHold = state
        if not state then
            getgenv().bhopHoldActive = false -- Ensure hold state is false if toggle is turned off
        end
    end
})

local AutoCarryToggle = Tabs.Player:Toggle({
    Title = "Auto Carry",
    Value = featureStates.AutoCarry,
    Callback = function(state)
        featureStates.AutoCarry = state
        if state then
            startAutoCarry()
        else
            stopAutoCarry()
        end
        if autoCarryGuiButton then
            autoCarryGuiButton.Text = featureStates.AutoCarry and "On" or "Off"
            autoCarryGuiButton.BackgroundColor3 = featureStates.AutoCarry and Color3.fromRGB(0, 120, 80) or Color3.fromRGB(120, 0, 0)
        end
    end
})

local AutoCarryGUIToggle = Tabs.Player:Toggle({
    Title = "Auto Carry GUI Toggle",
    Value = getgenv().autoCarryGuiVisible,
    Callback = function(state)
        getgenv().autoCarryGuiVisible = state
        if state then
            -- Create the GUI if it doesn't exist and enable it
            if not autoCarryGui then
                createAutoCarryGui(0.12) -- Pass the initial Y offset
            else
                autoCarryGui.Enabled = state
            end
        else
            -- Just disable the GUI if the state is false
            if autoCarryGui then
                autoCarryGui.Enabled = state
            end
        end
    end
})

local GravityToggle = Tabs.Player:Toggle({
    Title = "Custom Gravity",
    Value = featureStates.CustomGravity,
    Callback = function(state)
        featureStates.CustomGravity = state
        if state then
            workspace.Gravity = featureStates.GravityValue
        else
            workspace.Gravity = originalGameGravity
        end
        if gravityGuiButton then
            gravityGuiButton.Text = featureStates.CustomGravity and "On" or "Off"
            gravityGuiButton.BackgroundColor3 = featureStates.CustomGravity and Color3.fromRGB(0, 120, 80) or Color3.fromRGB(120, 0, 0)
        end
    end
})

local GravityGUIToggle = Tabs.Player:Toggle({
    Title = "Gravity GUI Toggle",
    Value = getgenv().gravityGuiVisible,
    Callback = function(state)
        getgenv().gravityGuiVisible = state
        if state then
            -- Create the GUI if it doesn't exist and enable it
            if not gravityGui then
                createGravityGui(0.24) -- Pass the initial Y offset
            else
                gravityGui.Enabled = state
            end
        else
            -- Just disable the GUI if the state is false
            if gravityGui then
                gravityGui.Enabled = state
            end
        end
    end
})

local GravityInput = Tabs.Player:Input({
    Title = "Gravity Value",
    Placeholder = "Default 196.2",
    Value = tostring(featureStates.GravityValue),
    NumbersOnly = true, -- WindUI equivalent of Numeric
    Callback = function(val)
        local num = tonumber(val)
        if num then
            featureStates.GravityValue = num
            if featureStates.CustomGravity then
                workspace.Gravity = num
            end
        end
    end
})

local AutoCrouchToggle = Tabs.Player:Toggle({
    Title = "Auto Crouch",
    Value = featureStates.AutoCrouch,
    Callback = function(state)
        featureStates.AutoCrouch = state
        if state then
            startAutoCrouch()
        else
            stopAutoCrouch()
        end
        if autoCrouchGuiButton then
            autoCrouchGuiButton.Text = featureStates.AutoCrouch and "On" or "Off"
            autoCrouchGuiButton.BackgroundColor3 = featureStates.AutoCrouch and Color3.fromRGB(0, 120, 80) or Color3.fromRGB(120, 0, 0)
        end
    end
})

local AutoCrouchGUIToggle = Tabs.Player:Toggle({
    Title = "Auto Crouch GUI Toggle",
    Value = getgenv().autoCrouchGuiVisible,
    Callback = function(state)
        getgenv().autoCrouchGuiVisible = state
        if state then
            -- Create the GUI if it doesn't exist and enable it
            if not autoCrouchGui then
                createAutoCrouchGui(0.36) -- Pass the initial Y offset
            else
                autoCrouchGui.Enabled = state
            end
        else
            -- Just disable the GUI if the state is false
            if autoCrouchGui then
                autoCrouchGui.Enabled = state
            end
        end
    end
})

local AutoCrouchModeDropdown = Tabs.Player:Dropdown({
    Title = "Auto Crouch Mode",
    Values = {"Air", "Normal", "Ground"},
    Value = featureStates.AutoCrouchMode,
    Callback = function(value)
        featureStates.AutoCrouchMode = value
        -- Restart the auto crouch logic to apply the new mode
        if featureStates.AutoCrouch then
            stopAutoCrouch()
            startAutoCrouch()
        end
    end
})

-- Bounce Section and Components (Based on DaraHub structure)
Tabs.Player:Section({ Title = "Bounce Settings", TextSize = 20 })

local BounceToggle
local BounceHeightInput
local EpsilonInput

BounceToggle = Tabs.Player:Toggle({
    Title = "Enable Bounce",
    Value = BOUNCE_ENABLED, -- Use the global variable
    Callback = function(state)
        BOUNCE_ENABLED = state -- Update the global variable
        if state then
            if player.Character then
                setupBounceOnTouch(player.Character)
            end
        else
            disableBounce()
        end
        -- Enable/Disable related inputs based on toggle state
        BounceHeightInput:Set({ Enabled = state })
        EpsilonInput:Set({ Enabled = state })
    end
})

BounceHeightInput = Tabs.Player:Input({
    Title = "Bounce Height",
    Placeholder = "0",
    Value = tostring(BOUNCE_HEIGHT), -- Use the global variable
    NumbersOnly = true, -- WindUI equivalent of Numeric
    Enabled = false, -- Initially disabled, enabled by toggle
    Callback = function(value)
        local num = tonumber(value)
        if num then
            BOUNCE_HEIGHT = math.max(0, num) -- Ensure non-negative value
        end
    end
})

EpsilonInput = Tabs.Player:Input({
    Title = "Touch Detection Epsilon",
    Placeholder = "0.1",
    Value = tostring(BOUNCE_EPSILON), -- Use the global variable
    NumbersOnly = true, -- WindUI equivalent of Numeric
    Enabled = false, -- Initially disabled, enabled by toggle
    Callback = function(value)
        local num = tonumber(value)
        if num then
            BOUNCE_EPSILON = math.max(0, num) -- Ensure non-negative value
        end
    end
})


-- Visuals Tab Content
Tabs.Visuals:Section({ Title = "Visual", TextSize = 20 }) -- Section for visual settings

local TimerDisplayToggle = Tabs.Visuals:Toggle({
    Title = "Timer Display",
    Value = featureStates.TimerDisplay,
    Callback = function(state)
        featureStates.TimerDisplay = state

        local function getRoundTimer()
            local player = game:GetService("Players").LocalPlayer
            local pg = player.PlayerGui
            local shared = pg:FindFirstChild("Shared")
            local hud = shared and shared:FindFirstChild("HUD")
            local overlay = hud and hud:FindFirstChild("Overlay")
            if not overlay then return nil end -- Return nil if overlay doesn't exist
            local default = overlay and overlay:FindFirstChild("Default")
            local ro = default and default:FindFirstChild("RoundOverlay")
            local round = ro and ro:FindFirstChild("Round")
            return round and round:FindFirstChild("RoundTimer") -- Return the timer label or nil
        end

        local function setContainerVisible(visible)
            local pg = game:GetService("Players").LocalPlayer.PlayerGui
            local main = pg:FindFirstChild("MainInterface")
            if main then
                local container = main:FindFirstChild("TimerContainer") -- Find the TimerContainer
                if container then
                    container.Visible = visible -- Set its visibility
                end
            end
        end

        if state then
            -- Show the timer and container if toggle is on
            setContainerVisible(true)
            -- Optional: Continuously check if timer becomes invisible and re-show container
            -- This might be needed if the game hides the timer but the container remains visible
            -- A simple loop could be added here, but be cautious of performance.
            -- For now, just show it once when enabled.
        else
            -- Hide the container if toggle is off
            setContainerVisible(false)
        end
    end
})


-- Settings Tab Content (Like DaraHub)
Tabs.Settings:Section({ Title = "Main Settings", TextSize = 20 })

local ButtonSizeXInput = Tabs.Settings:Input({
    Title = "Button Size X",
    Placeholder = "60",
    Value = tostring(getgenv().guiButtonSizeX),
    NumbersOnly = true,
    Callback = function(input)
        local val = tonumber(input)
        if val then
            getgenv().guiButtonSizeX = math.max(20, val)
            -- Update existing GUI button sizes if they exist
            if bhopGui and bhopGui:FindFirstChild("Frame") then
                bhopGui.Frame.Size = UDim2.new(0, getgenv().guiButtonSizeX, 0, getgenv().guiButtonSizeY)
            end
            if autoCarryGui and autoCarryGui:FindFirstChild("Frame") then
                autoCarryGui.Frame.Size = UDim2.new(0, getgenv().guiButtonSizeX, 0, getgenv().guiButtonSizeY)
            end
            if gravityGui and gravityGui:FindFirstChild("Frame") then
                gravityGui.Frame.Size = UDim2.new(0, getgenv().guiButtonSizeX, 0, getgenv().guiButtonSizeY)
            end
            if autoCrouchGui and autoCrouchGui:FindFirstChild("Frame") then
                autoCrouchGui.Frame.Size = UDim2.new(0, getgenv().guiButtonSizeX, 0, getgenv().guiButtonSizeY)
            end
        end
    end
})

local ButtonSizeYInput = Tabs.Settings:Input({
    Title = "Button Size Y",
    Placeholder = "60",
    Value = tostring(getgenv().guiButtonSizeY),
    NumbersOnly = true,
    Callback = function(input)
        local val = tonumber(input)
        if val then
            getgenv().guiButtonSizeY = math.max(20, val)
            -- Update existing GUI button sizes if they exist
             if bhopGui and bhopGui:FindFirstChild("Frame") then
                bhopGui.Frame.Size = UDim2.new(0, getgenv().guiButtonSizeX, 0, getgenv().guiButtonSizeY)
            end
            if autoCarryGui and autoCarryGui:FindFirstChild("Frame") then
                autoCarryGui.Frame.Size = UDim2.new(0, getgenv().guiButtonSizeX, 0, getgenv().guiButtonSizeY)
            end
            if gravityGui and gravityGui:FindFirstChild("Frame") then
                gravityGui.Frame.Size = UDim2.new(0, getgenv().guiButtonSizeX, 0, getgenv().guiButtonSizeY)
            end
            if autoCrouchGui and autoCrouchGui:FindFirstChild("Frame") then
                autoCrouchGui.Frame.Size = UDim2.new(0, getgenv().guiButtonSizeX, 0, getgenv().guiButtonSizeY)
            end
        end
    end
})

-- --- Initialize ---
-- Apply settings found in memory or defaults
applyStoredSettings()

-- Create GUI buttons when their respective *GUI Toggle* is enabled (not just visibility state)
if getgenv().bhopGuiVisible then createBhopGui(0) setupBhopKeybind() end
if getgenv().autoCarryGuiVisible then createAutoCarryGui(0.12) end
if getgenv().gravityGuiVisible then createGravityGui(0.24) end
if getgenv().autoCrouchGuiVisible then createAutoCrouchGui(0.36) end

-- Connect character added to setup bounce and bhop keybinds if needed
player.CharacterAdded:Connect(function(char)
    if BOUNCE_ENABLED then
        setupBounceOnTouch(char)
    end
    if getgenv().bhopGuiVisible then
        setupBhopKeybind() -- Re-setup keybinds when character respawns
    end
    -- Setup mobile jump button when character respawns
    setupJumpButton()
    -- Optionally re-apply stored settings here too if needed after respawn
    -- applyStoredSettings()
end)

-- Start the new Bhop update loop
task.spawn(updateBhop)

-- --- Save/Load Logic (DaraHub Style) ---
local configFile = Window:ConfigFile("MovementHubConfig") -- Create config file handler

-- Register inputs and toggles for saving (DaraHub style)
configFile:Register("StrafeInput", StrafeInput)
configFile:Register("JumpCapInput", JumpCapInput)
configFile:Register("SpeedInput", SpeedInput)
configFile:Register("ApplyMethodDropdown", ApplyMethodDropdown)
configFile:Register("BhopToggle", BhopToggle)
configFile:Register("BhopModeDropdown", BhopModeDropdown) -- Register Bhop Mode Dropdown
configFile:Register("BhopAccelInput", BhopAccelInput) -- Register Bhop Accel Input
configFile:Register("BhopHoldToggle", BhopHoldToggle) -- Register Bhop Hold Toggle
configFile:Register("AutoCarryToggle", AutoCarryToggle)
configFile:Register("GravityToggle", GravityToggle)
configFile:Register("GravityInput", GravityInput)
configFile:Register("AutoCrouchToggle", AutoCrouchToggle)
configFile:Register("BounceToggle", BounceToggle) -- Register Bounce toggle
configFile:Register("BounceHeightInput", BounceHeightInput) -- Register Bounce height input
configFile:Register("EpsilonInput", EpsilonInput) -- Register Epsilon input
configFile:Register("TimerDisplayToggle", TimerDisplayToggle) -- Register Timer Display Toggle
configFile:Register("BhopGUIToggle", BhopGUIToggle)
configFile:Register("AutoCarryGUIToggle", AutoCarryGUIToggle)
configFile:Register("GravityGUIToggle", GravityGUIToggle)
configFile:Register("AutoCrouchGUIToggle", AutoCrouchGUIToggle)
configFile:Register("AutoCrouchModeDropdown", AutoCrouchModeDropdown)
configFile:Register("ButtonSizeXInput", ButtonSizeXInput)
configFile:Register("ButtonSizeYInput", ButtonSizeYInput)

-- Load settings after registering, then apply them
configFile:Load()
applyStoredSettings() -- Apply loaded settings to the game

-- Update global variables after loading config
-- The callbacks for BounceHeightInput and EpsilonInput already update the global vars
-- The BounceToggle callback updates BOUNCE_ENABLED and handles setup/disable
-- The BhopAccelInput callback updates bhopAccelValue
-- The BhopModeDropdown callback updates bhopMode
-- So, the initial state should be correct after Load() and applyStoredSettings()

-- If Bounce was enabled in the config, ensure it's set up
if BOUNCE_ENABLED and player.Character then
    setupBounceOnTouch(player.Character)
end

-- Apply Timer Display state after loading config
if featureStates.TimerDisplay then
    -- Trigger the callback logic to show the timer
    local currentTimerState = featureStates.TimerDisplay
    featureStates.TimerDisplay = not currentTimerState -- Temporarily flip state
    TimerDisplayToggle:Set(currentTimerState) -- Then set it back via the toggle
end

-- Execute the additional loadstring after everything else is set up
local success, err = pcall(function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/Hajipak/Evade/refs/heads/main/Script/More-loadstring.lua"))()
end)

if not success then
    warn("Error executing additional loadstring: ", err)
end

-- Add a save button if needed (optional)
-- Tabs.Settings:Button({Title = "Save Config", Callback = function() configFile:Save() end})
