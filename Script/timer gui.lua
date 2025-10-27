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

    MainInterface.Name = "MainInterface"
    MainInterface.Parent = PlayerGui
    MainInterface.ResetOnSpawn = false
    MainInterface.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    MainInterface.Enabled = true

    TimerContainer.Name = "TimerContainer"
    TimerContainer.Parent = MainInterface
    TimerContainer.AnchorPoint = Vector2.new(0.5, 0)
    TimerContainer.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    TimerContainer.BackgroundTransparency = 1.000
    TimerContainer.BorderColor3 = Color3.fromRGB(27, 42, 53)
    TimerContainer.Position = UDim2.new(0.5, 0, 0, 0)
    TimerContainer.Size = UDim2.new(1, 0, 1, 0)
    TimerContainer.Visible = true

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
    BorderOutline.Color = Color3.fromRGB(0, 0, 0)
    BorderOutline.Transparency = 0.8

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

    return CountdownText, StatusText, MainInterface, TimerContainer
end

local TimerLabel, StatusLabel, MainInterface, TimerContainer = CreateTimerGUI()

local statsFolder = workspace:WaitForChild("Game"):WaitForChild("Stats")

local timerConnection

local function formatTime(seconds)
    if not seconds then return "0:00" end
    
    seconds = math.floor(tonumber(seconds) or 0)
    local minutes = math.floor(seconds / 60)
    local remainingSeconds = seconds % 60
    
    return string.format("%d:%02d", minutes, remainingSeconds)
end

local function setupTimerConnection()
    if timerConnection then
        timerConnection:Disconnect()
    end
    
    if statsFolder then
        timerConnection = statsFolder:GetAttributeChangedSignal("Timer"):Connect(function()
            local timerValue = statsFolder:GetAttribute("Timer")
            local roundStarted = statsFolder:GetAttribute("RoundStarted")
            
            TimerLabel.Text = formatTime(timerValue)
            
            TimerLabel.TextColor3 = timerValue and timerValue <= 5 and Color3.fromRGB(215, 100, 100) or Color3.fromRGB(165, 194, 255)
            
            StatusLabel.Text = roundStarted and "ROUND ACTIVE" or "INTERMISSION"
        end)
        
        local initialTimer = statsFolder:GetAttribute("Timer")
        local initialRoundStarted = statsFolder:GetAttribute("RoundStarted")
        
        TimerLabel.Text = formatTime(initialTimer)
        TimerLabel.TextColor3 = initialTimer and initialTimer <= 5 and Color3.fromRGB(215, 100, 100) or Color3.fromRGB(165, 194, 255)
        StatusLabel.Text = initialRoundStarted and "ROUND ACTIVE" or "INTERMISSION"
    end
end

setupTimerConnection()

local folderAddedConnection
folderAddedConnection = workspace.ChildAdded:Connect(function(child)
    if child.Name == "Game" then
        local gameFolder = child:WaitForChild("Stats")
        statsFolder = gameFolder
        setupTimerConnection()
    end
end)

local function cleanupTimer()
    if timerConnection then
        timerConnection:Disconnect()
        timerConnection = nil
    end
    if folderAddedConnection then
        folderAddedConnection:Disconnect()
        folderAddedConnection = nil
    end
end

local roundTimer = PlayerGui:WaitForChild("Menu"):WaitForChild("IntermissionTimer"):WaitForChild("RoundTimer")
local hudOverlay = PlayerGui:WaitForChild("Shared"):WaitForChild("HUD"):WaitForChild("Overlay"):WaitForChild("Default"):WaitForChild("RoundOverlay"):WaitForChild("Round"):WaitForChild("RoundTimer")

task.spawn(function()
    while true do
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

local function updateUIVisibility()
    local intermissionAbout = roundTimer:GetAttribute("About")
    local roundTimerAbout = hudOverlay:GetAttribute("About")
    local isIntermissionTimerVisible = roundTimer:IsDescendantOf(PlayerGui) and roundTimer.Visible
    local isHudOverlayVisible = hudOverlay:IsDescendantOf(PlayerGui) and hudOverlay.Visible
    local toggleState = VisualsTab and VisualsTab:GetValue("Game Timer Display") or true

    TimerContainer.Visible = toggleState and not (
        intermissionAbout == "INTERMISSION" or 
        roundTimerAbout == "INTERMISSION" or 
        isIntermissionTimerVisible or 
        isHudOverlayVisible
    )
end

roundTimer:GetAttributeChangedSignal("About"):Connect(updateUIVisibility)
hudOverlay:GetAttributeChangedSignal("About"):Connect(updateUIVisibility)

local function connectVisibilityListener(instance)
    if instance then
        instance:GetPropertyChangedSignal("Visible"):Connect(updateUIVisibility)
        instance.AncestryChanged:Connect(updateUIVisibility)
    end
end

connectVisibilityListener(roundTimer)
connectVisibilityListener(hudOverlay)
