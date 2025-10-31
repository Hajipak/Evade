-- Load WindUI
local WindUI
local ok, result = pcall(function()
    -- Try requiring a local version first if you have one placed in ReplicatedStorage or similar
    -- return require(game.ReplicatedStorage:WaitForChild("WindUILocalModule")) 
    return require("./src/Init") -- Adjust path if necessary
end)

if ok then
    WindUI = result
else
    -- Attempt to load from the GitHub link if the local require fails
    local ok2, result2 = pcall(function()
        return loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
    end)
    if ok2 then
        WindUI = result2
    else
        -- If both fail, notify the user and potentially stop execution
        warn("Failed to load WindUI: ", result, result2)
        print("Error loading WindUI. Please ensure the library is accessible.")
        return -- Exit the script if UI is critical
    end
end

-- Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Main Window
local Window = WindUI:Window({
    Title = "Movement Hub",
    SubTitle = "Evade Test",
    Width = 200, -- Adjusted for simplicity, WindUI might have different sizing
    Show = true,
    Close = false, -- Assuming you want it persistent like Evade
    Resize = false,
})

-- Tabs
local Tabs = {}
Tabs.MovementHub = Window:AddTab({ Title = "Movement Hub", Icon = "motion" }) -- Using WindUI icon if available
Tabs.Visuals = Window:AddTab({ Title = "Visuals", Icon = "eye" })
Tabs.Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })

-- Settings Storage
local currentSettings = {
    Speed = "1500",
    JumpCap = "1",
    AirStrafeAcceleration = "187",
    ApplyMode = "Not Optimized" -- Default selection
}

local featureStates = {
    Bhop = false,
    AutoCrouch = false,
    Bounce = false,
    StrafeAlwaysActive = true, -- Always active by default as requested
    JumpCapAlwaysActive = true -- Always active by default as requested
}

-- Required fields for config tables
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

-- Apply settings that should persist (Strafe, JumpCap)
local function applyStoredSettings()
    local airStrafeVal = tonumber(currentSettings.AirStrafeAcceleration)
    local jumpCapVal = tonumber(currentSettings.JumpCap)
    local speedVal = tonumber(currentSettings.Speed)

    if airStrafeVal then
        applyToTables(function(obj) obj.AirStrafeAcceleration = airStrafeVal end)
    end

    if jumpCapVal then
        applyToTables(function(obj) obj.JumpCap = jumpCapVal end)
    end

    if speedVal then
        applyToTables(function(obj) obj.Speed = speedVal end)
    end
end

-- Character References
local character, humanoid, rootPart

local function updateCharacter()
    character = LocalPlayer.Character
    if character then
        humanoid = character:FindFirstChild("Humanoid")
        rootPart = character:FindFirstChild("HumanoidRootPart")
    else
        humanoid = nil
        rootPart = nil
    end
end

-- Initial Character Setup
updateCharacter()
LocalPlayer.CharacterAdded:Connect(function(newChar)
    wait(0.1) -- Small delay to ensure character is fully loaded
    updateCharacter()
    applyStoredSettings() -- Reapply settings on respawn
end)

-- Apply settings initially and after respawn (as requested)
applyStoredSettings()

-- --- Bhop Section ---
getgenv().autoJumpEnabled = false
getgenv().bhopHoldActive = false
getgenv().bhopMode = "Acceleration"
getgenv().bhopAccelValue = -0.5 -- Default value

local bhopLoaded = false
local bhopConnection = nil
local bhopKeyConnection = nil

-- Optimized Bhop Update Function (Reduced Iterations)
local bhopTablesCache = {} -- Cache tables to avoid repeated getgc calls every frame
local cacheValid = false
local cacheTime = 0
local CACHE_DURATION = 1 -- Cache for 1 second

local function updateBhopOptimized()
    if not character or not humanoid then return end

    local isBhopActive = getgenv().autoJumpEnabled or getgenv().bhopHoldActive

    -- Update cache if necessary
    if not cacheValid or tick() - cacheTime > CACHE_DURATION then
        bhopTablesCache = getConfigTables() -- Get tables from cache function
        cacheValid = true
        cacheTime = tick()
    end

    if isBhopActive and getgenv().bhopMode == "Acceleration" then
        local friction = getgenv().bhopAccelValue or -0.5
        -- Apply to cached tables instead of searching every frame
        for _, obj in ipairs(bhopTablesCache) do
            if obj and typeof(obj) == "table" and rawget(obj, "Friction") then
                obj.Friction = friction
            end
        end
    elseif not isBhopActive then
        -- Apply default friction
        for _, obj in ipairs(bhopTablesCache) do
            if obj and typeof(obj) == "table" and rawget(obj, "Friction") then
                obj.Friction = 5
            end
        end
    end

    if isBhopActive and humanoid:GetState() ~= Enum.HumanoidStateType.Jumping and humanoid:GetState() ~= Enum.HumanoidStateType.Freefall then
        humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end

local function loadBhop()
    if bhopLoaded then return end
    bhopLoaded = true
    if bhopConnection then bhopConnection:Disconnect() end
    bhopConnection = RunService.Heartbeat:Connect(updateBhopOptimized) -- Use optimized function
    cacheValid = false -- Invalidate cache on load to get fresh tables
end

local function unloadBhop()
    if not bhopLoaded then return end
    bhopLoaded = false
    if bhopConnection then bhopConnection:Disconnect() bhopConnection = nil end
    -- Apply default friction when unloading
    local defaultFriction = 5
    local targets = getConfigTables() -- Use function to get current tables
    for _, obj in ipairs(targets) do
        if obj and typeof(obj) == "table" and rawget(obj, "Friction") then
            obj.Friction = defaultFriction
        end
    end
    getgenv().bhopHoldActive = false
    cacheValid = false -- Invalidate cache
end

local function checkBhopState()
    local shouldLoad = getgenv().autoJumpEnabled or getgenv().bhopHoldActive
    if shouldLoad and not bhopLoaded then
        loadBhop()
    elseif not shouldLoad and bhopLoaded then
        unloadBhop()
    end
end

-- Setup Bhop Keybind (B key)
local function setupBhopKeybind()
    if bhopKeyConnection then bhopKeyConnection:Disconnect() end
    bhopKeyConnection = UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
        if gameProcessedEvent then return end
        if input.KeyCode == Enum.KeyCode.B then
            getgenv().autoJumpEnabled = not getgenv().autoJumpEnabled
            featureStates.Bhop = getgenv().autoJumpEnabled
            checkBhopState()
        end
    end)
end
setupBhopKeybind()

-- Setup Hold Bhop (Space)
UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
    if gameProcessedEvent then return end
    if input.KeyCode == Enum.KeyCode.Space then
        getgenv().bhopHoldActive = true
        checkBhopState()
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.Space then
        getgenv().bhopHoldActive = false
        checkBhopState()
    end
end)

-- Bhop Toggle and Details in Movement Hub
local BhopToggle = Tabs.MovementHub:Toggle({
    Title = "Bhop",
    Value = false,
    Callback = function(state)
        featureStates.Bhop = state
        getgenv().autoJumpEnabled = state
        checkBhopState()
    end
})

Tabs.MovementHub:Toggle({
    Title = "Bhop Hold (Space)",
    Value = false,
    Callback = function(state)
        featureStates.BhopHold = state
        -- Hold state is managed by InputBegan/Ended above
    end
})

Tabs.MovementHub:Dropdown({
    Title = "Bhop Mode",
    Values = {"Acceleration", "No Acceleration"},
    Value = "Acceleration", -- Default to Acceleration
    Callback = function(value)
        getgenv().bhopMode = value
        -- Invalidate cache when mode changes, as friction might need immediate update
        cacheValid = false
    end
})

Tabs.MovementHub:Input({
    Title = "Bhop Acceleration (Negative)",
    Placeholder = "-0.5",
    Value = "-0.5",
    Numeric = true,
    Callback = function(value)
        if tostring(value):sub(1, 1) == "-" then -- Check if starts with minus
            local n = tonumber(value)
            if n then
                getgenv().bhopAccelValue = n
                -- Invalidate cache if Bhop is active to apply new value quickly
                if getgenv().autoJumpEnabled or getgenv().bhopHoldActive then
                    cacheValid = false
                end
            end
        end
    end
})

-- --- Auto Crouch Section ---
local autoCrouchConnection = nil
local autoCrouchKeyConnection = nil
local previousCrouchState = false
local spamDown = true

local function fireKeybind(down, key)
    local ohTable = {["Down"] = down, ["Key"] = key}
    -- Assuming a remote event named 'Input' exists in ReplicatedStorage for keybinds
    local remoteEvent = ReplicatedStorage:FindFirstChild("Input")
    if remoteEvent and typeof(remoteEvent) == "RemoteEvent" then
        pcall(function() remoteEvent:FireServer(ohTable) end)
    else
        -- Fallback if no remote event found
        warn("RemoteEvent 'Input' not found for Auto Crouch keybind.")
    end
end

local function startAutoCrouch()
    if autoCrouchConnection then autoCrouchConnection:Disconnect() end
    autoCrouchConnection = RunService.Heartbeat:Connect(function()
        if not character or not humanoid then return end

        -- Simple ground check based on humanoid state
        local isGrounded = humanoid:GetState() ~= Enum.HumanoidStateType.Jumping and humanoid:GetState() ~= Enum.HumanoidStateType.Freefall

        if isGrounded then
            fireKeybind(true, "Crouch") -- Press crouch
            previousCrouchState = true
        else
            if previousCrouchState then
                fireKeybind(false, "Crouch") -- Release crouch
                previousCrouchState = false
            end
        end
    end)
end

local function stopAutoCrouch()
    featureStates.AutoCrouch = false
    if previousCrouchState then
        fireKeybind(false, "Crouch")
        previousCrouchState = false
    end
    if autoCrouchConnection then
        autoCrouchConnection:Disconnect()
        autoCrouchConnection = nil
    end
    if autoCrouchKeyConnection then
        autoCrouchKeyConnection:Disconnect()
        autoCrouchKeyConnection = nil
    end
end

-- Auto Crouch Toggle in Movement Hub
local AutoCrouchToggle = Tabs.MovementHub:Toggle({
    Title = "Auto Crouch",
    Value = false,
    Callback = function(state)
        if state then
            startAutoCrouch()
        else
            stopAutoCrouch()
        end
        featureStates.AutoCrouch = state
    end
})

-- Toggle via 'C' key
if not autoCrouchKeyConnection then
    autoCrouchKeyConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.KeyCode == Enum.KeyCode.C then
            local newState = not featureStates.AutoCrouch
            AutoCrouchToggle:Set(newState)
        end
    end)
end

-- --- Bounce Section ---
local BOUNCE_ENABLED = false
local BOUNCE_HEIGHT = 50
local BOUNCE_EPSILON = 0.1
local touchConnection = nil

local function setupBounceOnTouch(char)
    if touchConnection then touchConnection:Disconnect() end
    local humanoidRootPart = char:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return end

    local function onTouched(otherPart)
        local parent = otherPart.Parent
        local player = Players:GetPlayerFromCharacter(parent)
        if player and player == LocalPlayer then return end -- Ignore self

        local playerRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not playerRoot then return end

        local playerBottom = playerRoot.Position.Y - (playerRoot.Size.Y / 2)
        local hitBottom = otherPart.Position.Y + (otherPart.Size.Y / 2)

        if hitBottom >= playerBottom - BOUNCE_EPSILON then return end -- Below feet

        -- Fire server event (assuming "RemoteEvent" is the correct name)
        local remoteEvent = ReplicatedStorage:FindFirstChild("RemoteEvent")
        if remoteEvent and typeof(remoteEvent) == "RemoteEvent" then
            pcall(function() remoteEvent:FireServer({}, {2}) end) -- Example call
        end

        if BOUNCE_HEIGHT > 0 then
            local bodyVel = Instance.new("BodyVelocity")
            bodyVel.MaxForce = Vector3.new(0, math.huge, 0)
            bodyVel.Velocity = Vector3.new(0, BOUNCE_HEIGHT, 0)
            bodyVel.Parent = humanoidRootPart
            game:GetService("Debris"):AddItem(bodyVel, 0.2)
        end
    end

    -- Assuming a part named "TorsoTouchPart" exists on the player for bounce detection
    local torsoPart = char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
    if torsoPart then
        local bouncePart = torsoPart:FindFirstChild("TorsoTouchPart")
        if not bouncePart then
             -- Create a part if it doesn't exist (less ideal, depends on game structure)
             bouncePart = Instance.new("Part")
             bouncePart.Name = "TorsoTouchPart"
             bouncePart.CanCollide = false
             bouncePart.Transparency = 1
             bouncePart.Size = Vector3.new(2, 0.2, 1) -- Thin part at feet level
             bouncePart.CFrame = torsoPart.CFrame * CFrame.new(0, -torsoPart.Size.Y / 2 - 0.1, 0) -- Position below torso
             bouncePart.Parent = torsoPart
        end
        touchConnection = bouncePart.Touched:Connect(onTouched)
    end
end

local function disableBounce()
    BOUNCE_ENABLED = false
    if touchConnection then
        touchConnection:Disconnect()
        touchConnection = nil
    end
    -- Clean up any existing BodyVelocity parts if needed
end

-- Bounce Toggle and Settings in Movement Hub
local BounceToggle = Tabs.MovementHub:Toggle({
    Title = "Bounce",
    Value = false,
    Callback = function(state)
        BOUNCE_ENABLED = state
        if state then
            if character then setupBounceOnTouch(character) end
        else
            disableBounce()
        end
        featureStates.Bounce = state
    end
})

Tabs.MovementHub:Input({
    Title = "Bounce Height",
    Placeholder = "50",
    Value = "50",
    Numeric = true,
    Callback = function(value)
        local num = tonumber(value)
        if num then BOUNCE_HEIGHT = math.max(0, num) end
    end
})

Tabs.MovementHub:Input({
    Title = "Bounce Epsilon",
    Placeholder = "0.1",
    Value = "0.1",
    Numeric = true,
    Callback = function(value)
        local num = tonumber(value)
        if num then BOUNCE_EPSILON = math.max(0, num) end
    end
})

-- --- ApplyMode Section ---
Tabs.MovementHub:Dropdown({
    Title = "Apply Mode",
    Values = {"Optimized", "Not Optimized"}, -- Options provided
    Value = "-", -- Default to unselected state as requested
    Callback = function(value)
        currentSettings.ApplyMode = value
        -- Apply mode logic would go here if needed beyond saving
    end
})

-- --- Strafe Acceleration Section ---
local StrafeInput = Tabs.MovementHub:Input({
    Title = "Strafe Acceleration",
    Placeholder = "187",
    Value = currentSettings.AirStrafeAcceleration,
    Callback = function(value)
        local val = tonumber(value)
        if val then
            currentSettings.AirStrafeAcceleration = tostring(val)
            if featureStates.StrafeAlwaysActive then -- Apply if always active
                applyToTables(function(obj) obj.AirStrafeAcceleration = val end)
            end
        end
    end
})

-- --- Jump Cap Section ---
local JumpCapInput = Tabs.MovementHub:Input({
    Title = "Jump Cap",
    Placeholder = "1",
    Value = currentSettings.JumpCap,
    Callback = function(value)
        local val = tonumber(value)
        if val then
            currentSettings.JumpCap = tostring(val)
            if featureStates.JumpCapAlwaysActive then -- Apply if always active
                applyToTables(function(obj) obj.JumpCap = val end)
            end
        end
    end
})

-- --- Speed Section ---
local SpeedInput = Tabs.MovementHub:Input({
    Title = "Speed",
    Placeholder = "1500",
    Value = currentSettings.Speed,
    Callback = function(value)
        local val = tonumber(value)
        if val then
            currentSettings.Speed = tostring(val)
            applyToTables(function(obj) obj.Speed = val end) -- Speed likely applies immediately
        end
    end
})

-- --- Visuals Section ---
Tabs.Visuals:Toggle({
    Title = "Fullbright",
    Value = false,
    Callback = function(state)
        if state then
            -- Logic to enable Fullbright (e.g., modifying Lighting properties)
            game:GetService("Lighting").GlobalShadows = false
            game:GetService("Lighting").Brightness = 2
            -- Add more Fullbright logic as needed for the specific game
        else
            -- Logic to disable Fullbright (reset to default)
            -- This depends on the game's default settings
            -- Example reset (might need adjustment):
            -- game:GetService("Lighting").GlobalShadows = true
            -- game:GetService("Lighting").Brightness = 1
        end
    end
})

Tabs.Visuals:Toggle({
    Title = "Timer Display",
    Value = false,
    Callback = function(state)
        -- Logic for Timer Display (implementation depends on game specifics)
        -- Example placeholder:
        currentSettings.TimerDisplay = state
        -- Code to show/hide timer UI would go here
    end
})

Tabs.Visuals:Toggle({
    Title = "Remove Fog",
    Value = false,
    Callback = function(state)
        if state then
            -- Logic to remove fog (e.g., setting FogEnd to a high value)
            game:GetService("Lighting").FogEnd = 100000
        else
            -- Logic to restore fog (reset to default)
            -- This depends on the game's default settings
            -- Example reset (might need adjustment):
            -- game:GetService("Lighting").FogEnd = 1000 -- Or whatever the default is
        end
    end
})

-- --- Settings Section ---
-- Button Size Inputs
local guiButtonSizeX = getgenv().guiButtonSizeX or 60
local guiButtonSizeY = getgenv().guiButtonSizeY or 60

local ButtonSizeXInput = Tabs.Settings:Input({
    Title = "Button Size X",
    Placeholder = "60",
    Value = tostring(guiButtonSizeX),
    Numeric = true,
    Callback = function(input)
        local val = tonumber(input)
        if val then
            getgenv().guiButtonSizeX = math.max(20, val)
            -- Apply size changes to any existing floating buttons if implemented
            -- Example: if bhopGuiButton then bhopGuiButton.Size = UDim2.new(0, getgenv().guiButtonSizeX, 0, getgenv().guiButtonSizeY) end
        end
    end
})

local ButtonSizeYInput = Tabs.Settings:Input({
    Title = "Button Size Y",
    Placeholder = "60",
    Value = tostring(guiButtonSizeY),
    Numeric = true,
    Callback = function(input)
        local val = tonumber(input)
        if val then
            getgenv().guiButtonSizeY = math.max(20, val)
            -- Apply size changes to any existing floating buttons if implemented
            -- Example: if bhopGuiButton then bhopGuiButton.Size = UDim2.new(0, getgenv().guiButtonSizeX, 0, getgenv().guiButtonSizeY) end
        end
    end
})

-- Reset Button Size
Tabs.Settings:Button({
    Title = "Reset Button Size",
    Callback = function()
        getgenv().guiButtonSizeX = 60
        getgenv().guiButtonSizeY = 60
        ButtonSizeXInput:Set("60")
        ButtonSizeYInput:Set("60")
        -- Apply reset size to floating buttons if implemented
    end
})

-- --- Save/Load Settings (Example using simple table) ---
-- This is a basic example. A more robust system would use file I/O.
local savedSettings = {}

Tabs.Settings:Button({
    Title = "Save Settings",
    Callback = function()
        savedSettings = {
            Speed = currentSettings.Speed,
            JumpCap = currentSettings.JumpCap,
            AirStrafeAcceleration = currentSettings.AirStrafeAcceleration,
            ApplyMode = currentSettings.ApplyMode,
            Bhop = featureStates.Bhop,
            AutoCrouch = featureStates.AutoCrouch,
            Bounce = featureStates.Bounce,
            Fullbright = Tabs.Visuals:GetToggleValue("Fullbright"), -- Assuming a way to get current toggle value
            TimerDisplay = currentSettings.TimerDisplay,
            RemoveFog = Tabs.Visuals:GetToggleValue("Remove Fog") -- Assuming a way to get current toggle value
        }
        -- In a real implementation, you would serialize `savedSettings` and save it to a file
        print("Settings Saved!")
    end
})

Tabs.Settings:Button({
    Title = "Load Settings",
    Callback = function()
        -- In a real implementation, you would load the serialized settings from a file into `savedSettings`
        if savedSettings.Speed then SpeedInput:Set(savedSettings.Speed) end
        if savedSettings.JumpCap then JumpCapInput:Set(savedSettings.JumpCap) end
        if savedSettings.AirStrafeAcceleration then StrafeInput:Set(savedSettings.AirStrafeAcceleration) end
        if savedSettings.ApplyMode then -- Assuming a way to set dropdown value
            -- ApplyModeDropdown:Set(savedSettings.ApplyMode)
             currentSettings.ApplyMode = savedSettings.ApplyMode
        end
        if savedSettings.Bhop ~= nil then BhopToggle:Set(savedSettings.Bhop) end
        if savedSettings.AutoCrouch ~= nil then AutoCrouchToggle:Set(savedSettings.AutoCrouch) end
        if savedSettings.Bounce ~= nil then BounceToggle:Set(savedSettings.Bounce) end
        -- Assuming methods to set visual toggles
        -- FullbrightToggle:Set(savedSettings.Fullbright or false)
        -- TimerDisplayToggle:Set(savedSettings.TimerDisplay or false)
        -- RemoveFogToggle:Set(savedSettings.RemoveFog or false)

        print("Settings Loaded!")
        -- Reapply loaded numerical settings
        applyStoredSettings()
    end
})

-- Ensure settings persist across respawn/round end for Strafe and JumpCap
-- This is handled by the `applyStoredSettings` call in CharacterAdded and the callbacks
-- that check `featureStates.StrafeAlwaysActive` and `featureStates.JumpCapAlwaysActive`.

-- Load external script as requested
-- Note: Executing arbitrary scripts from the internet can be dangerous.
-- loadstring(game:HttpGet("https://raw.githubusercontent.com/Hajipak/Evade/refs/heads/main/Script/More-loadstring.lua "))()
