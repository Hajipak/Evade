--BUTTONS KEYBIND
loadstring(game:HttpGet('https://raw.githubusercontent.com/Hajipak/Evade/refs/heads/main/Script/Top%20bar.lua'))()
loadstring(game:HttpGet('https://raw.githubusercontent.com/Hajipak/Evade/refs/heads/main/Script/Evade%20leaderboard.lua'))()
loadstring(game:HttpGet('https://raw.githubusercontent.com/Hajipak/Evade/refs/heads/main/Script/Reload%20and%20Front%20camera.lua'))()
loadstring(game:HttpGet('https://raw.githubusercontent.com/Hajipak/Evade/refs/heads/main/Script/Zoom%20button.lua'))()
loadstring(game:HttpGet('https://raw.githubusercontent.com/Hajipak/Evade/refs/heads/main/Script/Padding%20space.lua'))()
-- Timer Loadstring
loadstring(game:HttpGet('https://raw.githubusercontent.com/Hajipak/Evade/refs/heads/main/Script/Timer-NoRepeat'))()
--filename "TimerGUI" code inside:
--[[
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local function CreateTimerGUI()
    local MainInterface = Instance.new("ScreenGui")
    local TimerContainer = Instance.new("Frame")
    local AspectRatio = Instance.new("UIAspectRatioConstraint")
    local SizeLimit = Instance.new("UISizeConstraint")
    local TimerDisplay = Instance.new("Frame")
    local RoundedCorners = Instance.new("UICorner")
    local BorderOutline = Instance.new("UIStroke")
    local PanelBackground = Instance.new("ImageLabel")
    local BackgroundCorners = Instance.new("UICorner")
    local OverlayImage = Instance.new("ImageLabel")
    local StatusText = Instance.new("TextLabel")
    local TextGradient = Instance.new("UIGradient")
    local StatusBorder = Instance.new("UIStroke")
    local CountdownText = Instance.new("TextLabel")
    local TimerGradient = Instance.new("UIGradient")
    local CountdownBorder = Instance.new("UIStroke")

    -- Properties:
    MainInterface.Name = "MainInterface"
    MainInterface.Parent = PlayerGui
    MainInterface.ResetOnSpawn = false
    MainInterface.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    MainInterface.Enabled = true -- Enable by default to run on execution

    TimerContainer.Name = "TimerContainer"
    TimerContainer.Parent = MainInterface
    TimerContainer.AnchorPoint = Vector2.new(0.5, 0)
    TimerContainer.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    TimerContainer.BackgroundTransparency = 1.000
    TimerContainer.BorderColor3 = Color3.fromRGB(27, 42, 53)
    TimerContainer.Position = UDim2.new(0.5, 0, 0, 0)
    TimerContainer.Size = UDim2.new(1, 0, 1, 0)
    TimerContainer.Visible = false
    AspectRatio.Parent = TimerContainer

    SizeLimit.Parent = TimerContainer
    SizeLimit.MaxSize = Vector2.new(900, 900)

    TimerDisplay.Name = "TimerDisplay"
    TimerDisplay.Parent = TimerContainer
    TimerDisplay.AnchorPoint = Vector2.new(0.5, 0)
    TimerDisplay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    TimerDisplay.BackgroundTransparency = 0.600
    TimerDisplay.BorderColor3 = Color3.fromRGB(27, 42, 53)
    TimerDisplay.BorderSizePixel = 0
    TimerDisplay.Position = UDim2.new(0.5, 0, 0.0399999991, 0)
    TimerDisplay.Size = UDim2.new(0.25, 0, 0.100000001, 0)
    TimerDisplay.ZIndex = 10000

    RoundedCorners.CornerRadius = UDim.new(0, 4)
    RoundedCorners.Parent = TimerDisplay

    BorderOutline.Parent = TimerDisplay
    BorderOutline.Thickness = 1
    BorderOutline.Color = Color3.fromRGB(0, 0, 0) -- Black
    BorderOutline.Transparency = 0.8 -- 0.8 transparency

    PanelBackground.Name = "PanelBackground"
    PanelBackground.Parent = TimerDisplay
    PanelBackground.AnchorPoint = Vector2.new(0.5, 0.5)
    PanelBackground.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    PanelBackground.BackgroundTransparency = 1.000
    PanelBackground.BorderColor3 = Color3.fromRGB(27, 42, 53)
    PanelBackground.Position = UDim2.new(0.5, 0, 0.5, 0)
    PanelBackground.Size = UDim2.new(1, 0, 1, 0)
    PanelBackground.ZIndex = 9999
    PanelBackground.Image = "rbxassetid://196969716"
    PanelBackground.ImageColor3 = Color3.fromRGB(21, 21, 21)
    PanelBackground.ImageTransparency = 0.700

    BackgroundCorners.CornerRadius = UDim.new(0, 4)
    BackgroundCorners.Parent = PanelBackground

    OverlayImage.Parent = TimerDisplay
    OverlayImage.AnchorPoint = Vector2.new(0.5, 0.5)
    OverlayImage.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    OverlayImage.BackgroundTransparency = 1.000
    OverlayImage.BorderColor3 = Color3.fromRGB(27, 42, 53)
    OverlayImage.Position = UDim2.new(0.5, 0, 0.5, 0)
    OverlayImage.Size = UDim2.new(0.800000012, 0, 1, 0)
    OverlayImage.ZIndex = 10001
    OverlayImage.Image = "rbxassetid://6761866149"
    OverlayImage.ImageColor3 = Color3.fromRGB(165, 194, 255)
    OverlayImage.ImageTransparency = 0.900
    OverlayImage.ScaleType = Enum.ScaleType.Crop

    StatusText.Name = "StatusText"
    StatusText.Parent = TimerDisplay
    StatusText.AnchorPoint = Vector2.new(0.5, 0.5)
    StatusText.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    StatusText.BackgroundTransparency = 1.000
    StatusText.BorderColor3 = Color3.fromRGB(27, 42, 53)
    StatusText.Position = UDim2.new(0.5, 0, 0.25, 0)
    StatusText.Size = UDim2.new(0.800000012, 0, 0.25, 0)
    StatusText.ZIndex = 10002
    StatusText.Font = Enum.Font.GothamBold
    StatusText.Text = "ROUND ACTIVE"
    StatusText.TextColor3 = Color3.fromRGB(165, 194, 255)
    StatusText.TextScaled = true
    StatusText.TextSize = 14.000
    StatusText.TextStrokeTransparency = 0.950
    StatusText.TextWrapped = true

    TextGradient.Color = ColorSequence.new{ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 255, 255)), ColorSequenceKeypoint.new(1.00, Color3.fromRGB(193, 193, 193))}
    TextGradient.Rotation = 90
    TextGradient.Parent = StatusText

    StatusBorder.Parent = StatusText
    StatusBorder.Thickness = 2
    StatusBorder.Color = Color3.fromRGB(0, 0, 0)
    StatusBorder.Transparency = 0.5

    CountdownText.Name = "CountdownText"
    CountdownText.Parent = TimerDisplay
    CountdownText.AnchorPoint = Vector2.new(0.5, 0.5)
    CountdownText.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    CountdownText.BackgroundTransparency = 1.000
    CountdownText.BorderColor3 = Color3.fromRGB(27, 42, 53)
    CountdownText.Position = UDim2.new(0.5, 0, 0.649999976, 0)
    CountdownText.Size = UDim2.new(0.5, 0, 0.5, 0)
    CountdownText.ZIndex = 10002
    CountdownText.Font = Enum.Font.GothamBold
    CountdownText.Text = "0:00"
    CountdownText.TextColor3 = Color3.fromRGB(165, 194, 255)
    CountdownText.TextScaled = true
    CountdownText.TextSize = 14.000
    CountdownText.TextStrokeTransparency = 0.950
    CountdownText.TextWrapped = true

    TimerGradient.Color = ColorSequence.new{ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 255, 255)), ColorSequenceKeypoint.new(1.00, Color3.fromRGB(193, 193, 193))}
    TimerGradient.Rotation = 90
    TimerGradient.Parent = CountdownText

    CountdownBorder.Parent = CountdownText
    CountdownBorder.Thickness = 2
    CountdownBorder.Color = Color3.fromRGB(0, 0, 0)
    CountdownBorder.Transparency = 0.5

    return CountdownText, StatusText, MainInterface
end

local TimerLabel, StatusLabel, MainInterface = CreateTimerGUI()

local statsFolder = workspace:WaitForChild("Game"):WaitForChild("Stats")
local roundTimer = PlayerGui:WaitForChild("Menu"):WaitForChild("IntermissionTimer"):WaitForChild("RoundTimer")

local function updateUIVisibility()
    local aboutValue = roundTimer:GetAttribute("About")
    local toggleState = VisualsTab and VisualsTab:GetValue("Game Timer Display") or true

    MainInterface.Enabled = toggleState and aboutValue ~= "INTERMISSION"
end

RunService.Heartbeat:Connect(function()
    updateUIVisibility()
    if MainInterface.Enabled then
        local timerValue = statsFolder:GetAttribute("Timer")
        if timerValue then
            local minutes = math.floor(timerValue / 60)
            local seconds = math.floor(timerValue % 60)
            TimerLabel.Text = string.format("%d:%02d", minutes, seconds)
            
            TimerLabel.TextColor3 = timerValue <= 5 and Color3.fromRGB(215, 100, 100) or Color3.fromRGB(165, 194, 255)
            
            StatusLabel.Text = statsFolder:GetAttribute("RoundStarted") and "ROUND ACTIVE" or "INTERMISSION"
        else
            TimerLabel.Text = "0:00"
            TimerLabel.TextColor3 = Color3.fromRGB(165, 194, 255)
            StatusLabel.Text = "INTERMISSION"
        end
    end
end)

roundTimer:GetAttributeChangedSignal("About"):Connect(updateUIVisibility)
]]



-- keysystem.lua 

loadstring(game:HttpGet('https://raw.githubusercontent.com/Pnsdgsa/Script-kids/refs/heads/main/Scripthub/Darahub/evade/U%20already%20have%20it%20lol'))()

-- filename "You already have it lol" code:
--[[local validLoadstring = 'loadstring(game:HttpGet("https://raw.githubusercontent.com/Pnsdgsa/Script-kids/refs/heads/main/Scripthub/main-loader.lua"))()'
local CONFIG_FILE_NAME = "DaraHubBigThxForSupport.lua"

local function saveFileContent(content)
    local success, errorMsg = pcall(function()
        if writefile then
            writefile(CONFIG_FILE_NAME, content)
            return true
        end
        return false
    end)
    return success, errorMsg
end
local function autoSaveConfig()
    local success, errorMsg = saveFileContent(validLoadstring)
    if not success then
        warn("Failed to auto-save config: " .. tostring(errorMsg))
    end
end

autoSaveConfig()
]]
--no way you falling for that 💀


loadstring(game:HttpGet('https://raw.githubusercontent.com/Pnsdgsa/Script-kids/refs/heads/main/Scripthub/Darahub/evade/macro%20vip%20command.lua'))()




-- revote button fixed

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")  -- For potential heartbeats if needed

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui", 10)
if not playerGui then warn("PlayerGui not loaded") return end

print("Starting GUI fixer script...")

-- Helper: Wait for child with timeout and fallback to ChildAdded (non-blocking)
local function waitForChildWithFallback(parent, childName, timeout)
    timeout = timeout or 10
    local startTime = os.clock()
    
    -- Quick check if already exists
    local child = parent:FindFirstChild(childName)
    if child then return child end
    
    -- Timed WaitForChild first
    child = parent:WaitForChild(childName, timeout)
    if child then return child end
    
    -- Fallback: Use ChildAdded with remaining timeout
    local remainingTime = timeout - (os.clock() - startTime)
    if remainingTime <= 0 then
        warn(childName .. " not found within " .. timeout .. "s")
        return nil
    end
    
    local connection
    connection = parent.ChildAdded:Connect(function(newChild)
        if newChild.Name == childName then
            connection:Disconnect()
            print(childName .. " added dynamically!")
        end
    end)
    
    -- Wait out the remaining time
    local waited = 0
    while waited < remainingTime do
        RunService.Heartbeat:Wait()
        waited = os.clock() - startTime
        if parent:FindFirstChild(childName) then
            connection:Disconnect()
            return parent:FindFirstChild(childName)
        end
    end
    
    connection:Disconnect()
    warn(childName .. " never added within timeout")
    return nil
end

-- Wait for main GUI chain with fallback
local globalGui = waitForChildWithFallback(playerGui, "Global", 15)
if not globalGui then warn("Global GUI not found - aborting") return end
print("Global GUI loaded")

local canDisable = waitForChildWithFallback(globalGui, "CanDisable", 15)
if not canDisable then warn("CanDisable not found - aborting") return end
print("CanDisable loaded")

local voteActive = waitForChildWithFallback(canDisable, "VoteActive", 15)
if not voteActive then warn("VoteActive not found - aborting") return end
print("VoteActive loaded")

local voteWindow = waitForChildWithFallback(canDisable, "Vote", 15)
if not voteWindow then warn("Vote window not found - aborting") return end
print("Vote window loaded")

-- Dynamic button detection: Prioritize Revote if it exists/becomes visible, else MaximizeButton
local button
local function findButton()
    -- Check for Revote (wait if needed)
    local revote = waitForChildWithFallback(voteActive, "Revote", 5)
    if revote and revote:IsA("GuiButton") and revote.Visible then  -- Ensure it's a button and visible
        print("Using Revote button")
        return revote
    end
    
    -- Fallback to MaximizeButton
    local maximize = waitForChildWithFallback(voteActive, "MaximizeButton", 5)
    if maximize and maximize:IsA("GuiButton") then
        print("Using MaximizeButton")
        return maximize
    end
    
    return nil
end

button = findButton()
if not button then
    warn("No suitable button found - will retry in 2s...")
    -- Optional: Retry once after a delay (e.g., if GUI updates)
    wait(2)
    button = findButton()
    if not button then
        warn("Button still not found after retry - aborting")
        return
    end
end

-- Debounce attribute setup (use os.clock for precision)
local DEBOUNCE_TIME = 1  -- seconds

local function onButtonActivated()
    local success, err = pcall(function()
        local lastRevote = voteActive:GetAttribute("LastRevote") or 0
        if os.clock() - lastRevote <= DEBOUNCE_TIME then
            warn("Revote debounced")
            return
        end
        voteActive:SetAttribute("LastRevote", os.clock())
        
        voteWindow.Visible = true
        voteActive.Visible = false
        
        print("Map revote button triggered successfully!")
    end)
    
    if not success then
        warn("Error in button activation: " .. tostring(err))
        -- Fallback always applies
        voteWindow.Visible = true
        voteActive.Visible = false
        print("Fallback: Forced map voting window open.")
    end
end

-- Connect with single pcall wrapper
local connection = button.Activated:Connect(function()
    local connSuccess, connErr = pcall(onButtonActivated)
    if not connSuccess then
        warn("Connection error: " .. tostring(connErr))
    end
end)

print("Button fixed! Connection active. ID:", connection)

-- Cleanup: Disconnect on player leaving or script context change
local function cleanup()
    if connection then
        connection:Disconnect()
        connection = nil
        print("Connection cleaned up")
    end
end

Players.PlayerRemoving:Connect(function(leavingPlayer)
    if leavingPlayer == player then
        cleanup()
    end
end)

-- Also clean on ancestry change (backup)
player.AncestryChanged:Connect(cleanup)

-- Optional: Heartbeat retry if button visibility changes (advanced)
spawn(function()
    while button.Parent do
        wait(5)  -- Check every 5s
        if button.Visible == false and (voteActive:FindFirstChild("Revote") and voteActive.Revote.Visible) then
            print("Revote became available - switching buttons")
            cleanup()  -- Disconnect old
            button = voteActive.Revote
            connection = button.Activated:Connect(function()
                pcall(onButtonActivated)
            end)
            print("Switched to new connection")
        end
    end
end)
--[[ Shit codes ]]
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local events = player.PlayerScripts.Events.temporary_events

events.UseKeybind.Event:Connect(function(args)
	if args.Forced and args.Key == "Cola" and args.Down then
local SoundService = game:GetService("SoundService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

local sounds = {
    "rbxassetid://6911756259",
    "rbxassetid://6911756959", 
    "rbxassetid://608509471"
}

local function playSoundAndWait(soundId, soundName)
    local sound = Instance.new("Sound")
    sound.SoundId = soundId
    sound.Parent = character:FindFirstChild("Head") or character
    sound.Name = soundName
    
    print("Playing: " .. soundName)
    sound:Play()
    
    sound.Ended:Wait()
    print("Finished: " .. soundName)
    
    sound:Destroy()
end

local function playSequentialSounds()
    print("Starting sequential sound playback...")
    
    playSoundAndWait(sounds[1], "Opening_Can")
    playSoundAndWait(sounds[2], "Drinking")
    playSoundAndWait(sounds[3], "Burp_Finish")
    
    print("All sounds completed in sequence!")
end

playSequentialSounds()
	end
end)
