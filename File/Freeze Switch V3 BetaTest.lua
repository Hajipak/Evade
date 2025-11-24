-- Cyber Freeze Switch Script (Mobile & PC Support)
-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")

-- Player Variables
local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

-- Configuration
local FREEZE_DURATION = 1
local FREEZE_COOLDOWN = 0.5
local lastFreezeTime = 0
local isFrozen = false
local HOLD_DURATION = 1.0
local isHolding = false
local holdStartTime = 0
local buttonSize = 200
local dragEnabled = true

-- Deteksi platform
local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

-- Remove existing UI if present
if CoreGui:FindFirstChild("CyberFreezeUI") then
    CoreGui.CyberFreezeUI:Destroy()
    wait(0.1)
end

-- Create Main ScreenGui
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "CyberFreezeUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder = 10
ScreenGui.Enabled = true
ScreenGui.Parent = CoreGui

-- Create Settings Frame
local SettingsFrame = Instance.new("Frame")
SettingsFrame.Name = "SettingsFrame"
SettingsFrame.Size = UDim2.new(0, 400, 0, 350)
SettingsFrame.Position = UDim2.new(0.5, -200, 0.5, -175)
SettingsFrame.BackgroundColor3 = Color3.fromRGB(10, 30, 45)
SettingsFrame.BorderSizePixel = 2
SettingsFrame.BorderColor3 = Color3.fromRGB(0, 255, 255)
SettingsFrame.Visible = false
SettingsFrame.Parent = ScreenGui

-- Create Glow Frame for Settings
local SettingsGlowFrame = Instance.new("Frame")
SettingsGlowFrame.Name = "GlowFrame"
SettingsGlowFrame.Size = UDim2.new(1, 10, 1, 10)
SettingsGlowFrame.Position = UDim2.new(0, -5, 0, -5)
SettingsGlowFrame.BackgroundTransparency = 1
SettingsGlowFrame.ZIndex = 0
SettingsGlowFrame.Parent = SettingsFrame

-- Create glow bars for settings
local function createGlowBar(name, size, position, anchorPoint)
    local bar = Instance.new("Frame")
    bar.Name = name
    bar.Size = size
    bar.Position = position
    bar.AnchorPoint = anchorPoint or Vector2.new(0, 0)
    bar.BackgroundColor3 = Color3.fromRGB(0, 255, 255)
    bar.BorderSizePixel = 0
    bar.ZIndex = 0
    bar.Parent = SettingsGlowFrame
    
    local gradient = Instance.new("UIGradient")
    gradient.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(0.5, 0),
        NumberSequenceKeypoint.new(1, 1)
    })
    gradient.Parent = bar
    
    return bar, gradient
end

local topBar = createGlowBar("TopBar", UDim2.new(0.3, 0, 0, 3), UDim2.new(0, 0, 0, 0))
local rightBar = createGlowBar("RightBar", UDim2.new(0, 3, 0.3, 0), UDim2.new(1, 0, 0, 0))
local bottomBar = createGlowBar("BottomBar", UDim2.new(0.3, 0, 0, 3), UDim2.new(1, 0, 1, 0), Vector2.new(1, 1))
local leftBar = createGlowBar("LeftBar", UDim2.new(0, 3, 0.3, 0), UDim2.new(0, 0, 1, 0), Vector2.new(0, 1))

-- Animate settings glow
local function animateSettingsGlow()
    spawn(function()
        while wait() do
            local speed = 2
            TweenService:Create(topBar, TweenInfo.new(speed, Enum.EasingStyle.Linear), {Position = UDim2.new(0.7, 0, 0, 0)}):Play()
            wait(speed + 0.5)
            topBar.Position = UDim2.new(0, 0, 0, 0)
            
            TweenService:Create(rightBar, TweenInfo.new(speed, Enum.EasingStyle.Linear), {Position = UDim2.new(1, 0, 0.7, 0)}):Play()
            wait(speed + 0.5)
            rightBar.Position = UDim2.new(1, 0, 0, 0)
            
            TweenService:Create(bottomBar, TweenInfo.new(speed, Enum.EasingStyle.Linear), {Position = UDim2.new(0.3, 0, 1, 0)}):Play()
            wait(speed + 0.5)
            bottomBar.Position = UDim2.new(1, 0, 1, 0)
            
            TweenService:Create(leftBar, TweenInfo.new(speed, Enum.EasingStyle.Linear), {Position = UDim2.new(0, 0, 0.3, 0)}):Play()
            wait(speed + 0.5)
            leftBar.Position = UDim2.new(0, 0, 1, 0)
        end
    end)
end

animateSettingsGlow()

-- Settings Title
local SettingsTitle = Instance.new("TextLabel")
SettingsTitle.Size = UDim2.new(1, 0, 0, 50)
SettingsTitle.Position = UDim2.new(0, 0, 0, 0)
SettingsTitle.BackgroundColor3 = Color3.fromRGB(0, 20, 35)
SettingsTitle.BorderSizePixel = 0
SettingsTitle.Text = "CYBER FREEZE"
SettingsTitle.TextColor3 = Color3.fromRGB(0, 255, 255)
SettingsTitle.TextSize = 24
SettingsTitle.Font = Enum.Font.GothamBold
SettingsTitle.Parent = SettingsFrame

-- Settings Label
local SettingsLabel = Instance.new("TextLabel")
SettingsLabel.Size = UDim2.new(1, -20, 0, 30)
SettingsLabel.Position = UDim2.new(0, 10, 0, 60)
SettingsLabel.BackgroundTransparency = 1
SettingsLabel.Text = "SETTINGS"
SettingsLabel.TextColor3 = Color3.fromRGB(0, 255, 255)
SettingsLabel.TextSize = 18
SettingsLabel.Font = Enum.Font.GothamBold
SettingsLabel.TextXAlignment = Enum.TextXAlignment.Left
SettingsLabel.Parent = SettingsFrame

-- Duration Label
local DurationLabel = Instance.new("TextLabel")
DurationLabel.Size = UDim2.new(1, -20, 0, 25)
DurationLabel.Position = UDim2.new(0, 10, 0, 100)
DurationLabel.BackgroundTransparency = 1
DurationLabel.Text = "Freeze Duration (0.1 - 100s):"
DurationLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
DurationLabel.TextSize = 14
DurationLabel.Font = Enum.Font.Gotham
DurationLabel.TextXAlignment = Enum.TextXAlignment.Left
DurationLabel.Parent = SettingsFrame

-- Duration Box
local DurationBox = Instance.new("TextBox")
DurationBox.Size = UDim2.new(0, 150, 0, 35)
DurationBox.Position = UDim2.new(0.5, -75, 0, 130)
DurationBox.BackgroundColor3 = Color3.fromRGB(20, 40, 60)
DurationBox.BorderSizePixel = 1
DurationBox.BorderColor3 = Color3.fromRGB(0, 200, 200)
DurationBox.Text = tostring(FREEZE_DURATION)
DurationBox.TextColor3 = Color3.fromRGB(255, 255, 255)
DurationBox.TextSize = 16
DurationBox.Font = Enum.Font.Gotham
DurationBox.Parent = SettingsFrame

-- Button Size Label
local SizeLabel = Instance.new("TextLabel")
SizeLabel.Size = UDim2.new(1, -20, 0, 25)
SizeLabel.Position = UDim2.new(0, 10, 0, 175)
SizeLabel.BackgroundTransparency = 1
SizeLabel.Text = "Button Size (100-500px):"
SizeLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
SizeLabel.TextSize = 14
SizeLabel.Font = Enum.Font.Gotham
SizeLabel.TextXAlignment = Enum.TextXAlignment.Left
SizeLabel.Parent = SettingsFrame

-- Size Box
local SizeBox = Instance.new("TextBox")
SizeBox.Size = UDim2.new(0, 150, 0, 35)
SizeBox.Position = UDim2.new(0.5, -75, 0, 205)
SizeBox.BackgroundColor3 = Color3.fromRGB(20, 40, 60)
SizeBox.BorderSizePixel = 1
SizeBox.BorderColor3 = Color3.fromRGB(0, 200, 200)
SizeBox.Text = tostring(buttonSize)
SizeBox.TextColor3 = Color3.fromRGB(255, 255, 255)
SizeBox.TextSize = 16
SizeBox.Font = Enum.Font.Gotham
SizeBox.Parent = SettingsFrame

-- Drag Label
local DragLabel = Instance.new("TextLabel")
DragLabel.Size = UDim2.new(0.5, -15, 0, 25)
DragLabel.Position = UDim2.new(0, 10, 0, 250)
DragLabel.BackgroundTransparency = 1
DragLabel.Text = "Drag GUI:"
DragLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
DragLabel.TextSize = 14
DragLabel.Font = Enum.Font.Gotham
DragLabel.TextXAlignment = Enum.TextXAlignment.Left
DragLabel.Parent = SettingsFrame

-- Drag Toggle Frame
local DragToggleFrame = Instance.new("Frame")
DragToggleFrame.Size = UDim2.new(0, 80, 0, 30)
DragToggleFrame.Position = UDim2.new(0.5, 10, 0, 247)
DragToggleFrame.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
DragToggleFrame.BorderSizePixel = 1
DragToggleFrame.BorderColor3 = Color3.fromRGB(0, 200, 200)
DragToggleFrame.Parent = SettingsFrame

local DragCorner = Instance.new("UICorner")
DragCorner.CornerRadius = UDim.new(0, 15)
DragCorner.Parent = DragToggleFrame

local DragToggleButton = Instance.new("TextButton")
DragToggleButton.Size = UDim2.new(1, 0, 1, 0)
DragToggleButton.BackgroundTransparency = 1
DragToggleButton.Text = "ON"
DragToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
DragToggleButton.TextSize = 14
DragToggleButton.Font = Enum.Font.GothamBold
DragToggleButton.Parent = DragToggleFrame

-- Apply Button
local ApplyButton = Instance.new("TextButton")
ApplyButton.Size = UDim2.new(0, 150, 0, 40)
ApplyButton.Position = UDim2.new(0.5, -75, 1, -50)
ApplyButton.BackgroundColor3 = Color3.fromRGB(0, 150, 200)
ApplyButton.BorderSizePixel = 0
ApplyButton.Text = "APPLY"
ApplyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ApplyButton.TextSize = 18
ApplyButton.Font = Enum.Font.GothamBold
ApplyButton.Parent = SettingsFrame

-- Close Button
local CloseButton = Instance.new("TextButton")
CloseButton.Size = UDim2.new(0, 30, 0, 30)
CloseButton.Position = UDim2.new(1, -40, 0, 10)
CloseButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
CloseButton.BorderSizePixel = 0
CloseButton.Text = "X"
CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseButton.TextSize = 18
CloseButton.Font = Enum.Font.GothamBold
CloseButton.Parent = SettingsFrame

-- Settings Button
local SettingsButton = Instance.new("TextButton")
SettingsButton.Size = UDim2.new(0, 60, 0, 60)
SettingsButton.Position = UDim2.new(1, -70, 0, 10)
SettingsButton.BackgroundColor3 = Color3.fromRGB(0, 150, 200)
SettingsButton.BorderSizePixel = 2
SettingsButton.BorderColor3 = Color3.fromRGB(0, 255, 255)
SettingsButton.Text = "⚙️"
SettingsButton.TextColor3 = Color3.fromRGB(255, 255, 255)
SettingsButton.TextSize = 30
SettingsButton.Font = Enum.Font.GothamBold
SettingsButton.Parent = ScreenGui

local SettingsCorner = Instance.new("UICorner")
SettingsCorner.CornerRadius = UDim.new(0, 10)
SettingsCorner.Parent = SettingsButton

-- Main Freeze Container
local MainContainer = Instance.new("Frame")
MainContainer.Name = "FreezeContainer"
MainContainer.Size = UDim2.new(0, 250, 0, 100)
MainContainer.Position = UDim2.new(0, 50, 1, -150)
MainContainer.BackgroundColor3 = Color3.fromRGB(0, 127, 255)
MainContainer.BackgroundTransparency = 0.1
MainContainer.BorderSizePixel = 0
MainContainer.Active = true
MainContainer.Parent = ScreenGui

-- Border Glow for Freeze Container
local BorderGlow = Instance.new("UIStroke")
BorderGlow.Color = Color3.fromRGB(0, 247, 255)
BorderGlow.Thickness = 3
BorderGlow.Transparency = 0.2
BorderGlow.Parent = MainContainer

-- Create Glow Frame for Freeze Button
local GlowFrame = Instance.new("Frame")
GlowFrame.Name = "GlowFrame"
GlowFrame.Size = UDim2.new(1, 10, 1, 10)
GlowFrame.Position = UDim2.new(0, -5, 0, -5)
GlowFrame.BackgroundTransparency = 1
GlowFrame.ZIndex = 0
GlowFrame.Parent = MainContainer

-- Create animated glow bars around freeze button
local freezeTopBar = createGlowBar("TopBar", UDim2.new(0.3, 0, 0, 3), UDim2.new(0, 0, 0, 0))
freezeTopBar.Parent = GlowFrame
local freezeRightBar = createGlowBar("RightBar", UDim2.new(0, 3, 0.3, 0), UDim2.new(1, 0, 0, 0))
freezeRightBar.Parent = GlowFrame
local freezeBottomBar = createGlowBar("BottomBar", UDim2.new(0.3, 0, 0, 3), UDim2.new(1, 0, 1, 0), Vector2.new(1, 1))
freezeBottomBar.Parent = GlowFrame
local freezeLeftBar = createGlowBar("LeftBar", UDim2.new(0, 3, 0.3, 0), UDim2.new(0, 0, 1, 0), Vector2.new(0, 1))
freezeLeftBar.Parent = GlowFrame

-- Animate freeze button glow
local function animateFreezeGlow()
    spawn(function()
        while wait() do
            local speed = 1.5
            TweenService:Create(freezeTopBar, TweenInfo.new(speed, Enum.EasingStyle.Linear), {Position = UDim2.new(0.7, 0, 0, 0)}):Play()
            wait(speed + 0.3)
            freezeTopBar.Position = UDim2.new(0, 0, 0, 0)
            
            TweenService:Create(freezeRightBar, TweenInfo.new(speed, Enum.EasingStyle.Linear), {Position = UDim2.new(1, 0, 0.7, 0)}):Play()
            wait(speed + 0.3)
            freezeRightBar.Position = UDim2.new(1, 0, 0, 0)
            
            TweenService:Create(freezeBottomBar, TweenInfo.new(speed, Enum.EasingStyle.Linear), {Position = UDim2.new(0.3, 0, 1, 0)}):Play()
            wait(speed + 0.3)
            freezeBottomBar.Position = UDim2.new(1, 0, 1, 0)
            
            TweenService:Create(freezeLeftBar, TweenInfo.new(speed, Enum.EasingStyle.Linear), {Position = UDim2.new(0, 0, 0.3, 0)}):Play()
            wait(speed + 0.3)
            freezeLeftBar.Position = UDim2.new(0, 0, 1, 0)
        end
    end)
end

animateFreezeGlow()

-- Freeze Text
local FreezeText = Instance.new("TextLabel")
FreezeText.Size = UDim2.new(1, 0, 1, 0)
FreezeText.BackgroundTransparency = 1
FreezeText.Text = "FREEZE"
FreezeText.Font = Enum.Font.GothamBlack
FreezeText.TextSize = 26
FreezeText.TextColor3 = Color3.fromRGB(255, 255, 255)
FreezeText.TextStrokeTransparency = 0.7
FreezeText.TextStrokeColor3 = Color3.fromRGB(0, 80, 200)
FreezeText.ZIndex = 2
FreezeText.Parent = MainContainer

-- Click Detector
local ClickDetector = Instance.new("TextButton")
ClickDetector.Size = UDim2.new(1, 0, 1, 0)
ClickDetector.BackgroundTransparency = 1
ClickDetector.Text = ""
ClickDetector.ZIndex = 3
ClickDetector.Parent = MainContainer

-- Freeze Function
local function executeLagSwitch()
    local currentTime = tick()
    
    if currentTime - lastFreezeTime < FREEZE_COOLDOWN then
        return
    end
    
    if not Character or not Humanoid or Humanoid.Health <= 0 then
        return
    end
    
    isFrozen = true
    lastFreezeTime = currentTime
    MainContainer.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
    BorderGlow.Color = Color3.fromRGB(255, 0, 0)
    
    local startTime = tick()
    local parts = {}
    
    for i = 1, 20 do
        local part = Instance.new("Part")
        part.Anchored = true
        part.CanCollide = false
        part.Transparency = 1
        part.Size = Vector3.new(1, 1, 1)
        part.Position = HumanoidRootPart.Position + Vector3.new(
            math.random(-15, 15),
            math.random(-8, 8),
            math.random(-15, 15)
        )
        part.Parent = workspace
        table.insert(parts, part)
    end
    
    local elapsedTime = 0
    while elapsedTime < FREEZE_DURATION do
        for j = 1, 200 do
            local calc = math.sin(j) * math.cos(j)
        end
        elapsedTime = tick() - startTime
        
        if elapsedTime > FREEZE_DURATION * 0.6 then
            RunService.Heartbeat:Wait()
        end
    end
    
    for _, part in ipairs(parts) do
        pcall(function()
            part:Destroy()
        end)
    end
    
    isFrozen = false
    MainContainer.BackgroundColor3 = Color3.fromRGB(0, 127, 255)
    BorderGlow.Color = Color3.fromRGB(0, 247, 255)
end

-- UI State
local function updateUIState(state)
    if state == "hover" then
        MainContainer.BackgroundTransparency = 0.05
        BorderGlow.Transparency = 0.1
        BorderGlow.Thickness = 4
    elseif state == "normal" then
        MainContainer.BackgroundTransparency = 0.1
        BorderGlow.Transparency = 0.2
        BorderGlow.Thickness = 3
    elseif state == "clicked" then
        MainContainer.BackgroundTransparency = 0.05
        BorderGlow.Transparency = 0.1
    elseif state == "dragging" then
        MainContainer.BackgroundTransparency = 0
        BorderGlow.Transparency = 0.05
        BorderGlow.Thickness = 5
    end
end

-- Drag System
local isDragging = false
local dragStart, startPos

ClickDetector.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or 
       input.UserInputType == Enum.UserInputType.MouseButton1 then
        isHolding = true
        holdStartTime = tick()
        updateUIState("clicked")
        
        spawn(function()
            while isHolding and tick() - holdStartTime < HOLD_DURATION do
                wait(0.05)
            end
            
            if isHolding and tick() - holdStartTime >= HOLD_DURATION and dragEnabled then
                isDragging = true
                dragStart = input.Position
                startPos = MainContainer.Position
                updateUIState("dragging")
            end
        end)
    end
end)

ClickDetector.InputChanged:Connect(function(input)
    if isDragging and dragEnabled and (input.UserInputType == Enum.UserInputType.Touch or 
                       input.UserInputType == Enum.UserInputType.MouseMovement) then
        local delta = input.Position - dragStart
        MainContainer.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end
end)

ClickDetector.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or 
       input.UserInputType == Enum.UserInputType.MouseButton1 then
        local wasHolding = isHolding
        local wasDragging = isDragging
        
        isHolding = false
        isDragging = false
        
        if wasDragging then
            wait(0.3)
            if not isFrozen then
                updateUIState("normal")
            end
        elseif wasHolding and tick() - holdStartTime < HOLD_DURATION then
            updateUIState("hover")
            executeLagSwitch()
        else
            updateUIState("normal")
        end
    end
end)

ClickDetector.MouseEnter:Connect(function()
    if not isHolding then
        updateUIState("hover")
    end
end)

ClickDetector.MouseLeave:Connect(function()
    if not isFrozen and not isHolding and not isDragging then
        updateUIState("normal")
    end
end)

-- Settings Events
SettingsButton.MouseButton1Click:Connect(function()
    SettingsFrame.Visible = not SettingsFrame.Visible
end)

ApplyButton.MouseButton1Click:Connect(function()
    local newDuration = tonumber(DurationBox.Text)
    local newSize = tonumber(SizeBox.Text)
    
    if newDuration and newDuration >= 0.1 and newDuration <= 100 then
        FREEZE_DURATION = newDuration
    else
        DurationBox.Text = tostring(FREEZE_DURATION)
    end
    
    if newSize and newSize >= 100 and newSize <= 500 then
        buttonSize = newSize
        MainContainer.Size = UDim2.new(0, buttonSize, 0, buttonSize / 2.5)
    else
        SizeBox.Text = tostring(buttonSize)
    end
    
    SettingsFrame.Visible = false
end)

CloseButton.MouseButton1Click:Connect(function()
    SettingsFrame.Visible = false
end)

DragToggleButton.MouseButton1Click:Connect(function()
    dragEnabled = not dragEnabled
    
    if dragEnabled then
        DragToggleButton.Text = "ON"
        DragToggleFrame.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
    else
        DragToggleButton.Text = "OFF"
        DragToggleFrame.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
    end
end)

-- Settings Drag
local settingsDragging = false
local settingsDragStart, settingsStartPos

SettingsFrame.InputBegan:Connect(function(input)
    if (input.UserInputType == Enum.UserInputType.Touch or 
        input.UserInputType == Enum.UserInputType.MouseButton1) and dragEnabled then
        settingsDragging = true
        settingsDragStart = input.Position
        settingsStartPos = SettingsFrame.Position
    end
end)

SettingsFrame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or 
       input.UserInputType == Enum.UserInputType.Touch then
        if settingsDragging and dragEnabled then
            local delta = input.Position - settingsDragStart
            SettingsFrame.Position = UDim2.new(
                settingsStartPos.X.Scale,
                settingsStartPos.X.Offset + delta.X,
                settingsStartPos.Y.Scale,
                settingsStartPos.Y.Offset + delta.Y
            )
        end
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or 
       input.UserInputType == Enum.UserInputType.MouseButton1 then
        settingsDragging = false
    end
end)

-- Keyboard shortcut (PC only)
if not isMobile then
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if not gameProcessed and input.KeyCode == Enum.KeyCode.F then
            SettingsFrame.Visible = not SettingsFrame.Visible
        end
    end)
end

-- Character Respawn
Player.CharacterAdded:Connect(function(newChar)
    Character = newChar
    Humanoid = Character:WaitForChild("Humanoid")
    HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
end)

-- Keep UI Visible
RunService.Heartbeat:Connect(function()
    if MainContainer and MainContainer.Parent then
        MainContainer.Visible = true
    end
end)

-- Initialize
updateUIState("normal")

if isMobile then
    print("✅ Cyber Freeze loaded for MOBILE!")
else
    print("✅ Cyber Freeze loaded for PC! Press F to open settings")
end
