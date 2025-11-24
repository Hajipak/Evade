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
local buttonSize = 250
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

-- Main Freeze Container
local MainContainer = Instance.new("Frame")
MainContainer.Name = "FreezeContainer"
MainContainer.Size = UDim2.new(0, 250, 0, 100)
MainContainer.Position = UDim2.new(0.05, 0, 0.4, 0)
MainContainer.BackgroundColor3 = Color3.fromRGB(5, 40, 60)
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

-- Create animated glow bars
local function createGlowBar(name, size, position, anchorPoint)
    local bar = Instance.new("Frame")
    bar.Name = name
    bar.Size = size
    bar.Position = position
    bar.AnchorPoint = anchorPoint or Vector2.new(0, 0)
    bar.BackgroundColor3 = Color3.fromRGB(0, 255, 255)
    bar.BorderSizePixel = 0
    bar.ZIndex = 0
    bar.Parent = GlowFrame
    
    local gradient = Instance.new("UIGradient")
    gradient.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(0.5, 0),
        NumberSequenceKeypoint.new(1, 1)
    })
    gradient.Parent = bar
    
    return bar
end

local freezeTopBar = createGlowBar("TopBar", UDim2.new(0.3, 0, 0, 3), UDim2.new(0, 0, 0, 0))
local freezeRightBar = createGlowBar("RightBar", UDim2.new(0, 3, 0.3, 0), UDim2.new(1, 0, 0, 0))
local freezeBottomBar = createGlowBar("BottomBar", UDim2.new(0.3, 0, 0, 3), UDim2.new(1, 0, 1, 0), Vector2.new(1, 1))
local freezeLeftBar = createGlowBar("LeftBar", UDim2.new(0, 3, 0.3, 0), UDim2.new(0, 0, 1, 0), Vector2.new(0, 1))

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
FreezeText.Text = "CYBER FREEZE"
FreezeText.Font = Enum.Font.GothamBlack
FreezeText.TextSize = 22
FreezeText.TextColor3 = Color3.fromRGB(0, 255, 255)
FreezeText.TextStrokeTransparency = 0.5
FreezeText.TextStrokeColor3 = Color3.fromRGB(0, 150, 255)
FreezeText.ZIndex = 2
FreezeText.Parent = MainContainer

-- System Ready Label
local SystemLabel = Instance.new("TextLabel")
SystemLabel.Size = UDim2.new(1, 0, 0.4, 0)
SystemLabel.Position = UDim2.new(0, 0, 0.6, 0)
SystemLabel.BackgroundTransparency = 1
SystemLabel.Text = "SYSTEM READY"
SystemLabel.Font = Enum.Font.Gotham
SystemLabel.TextSize = 12
SystemLabel.TextColor3 = Color3.fromRGB(100, 200, 255)
SystemLabel.TextStrokeTransparency = 0.8
SystemLabel.ZIndex = 2
SystemLabel.Parent = MainContainer

-- Settings Icon Button (like in photo)
local SettingsIcon = Instance.new("ImageButton")
SettingsIcon.Name = "SettingsIcon"
SettingsIcon.Size = UDim2.new(0, 30, 0, 30)
SettingsIcon.Position = UDim2.new(1, -40, 0, 10)
SettingsIcon.BackgroundColor3 = Color3.fromRGB(0, 100, 150)
SettingsIcon.BackgroundTransparency = 0.3
SettingsIcon.BorderSizePixel = 1
SettingsIcon.BorderColor3 = Color3.fromRGB(0, 255, 255)
SettingsIcon.Image = ""
SettingsIcon.ZIndex = 3
SettingsIcon.Parent = MainContainer

local SettingsIconCorner = Instance.new("UICorner")
SettingsIconCorner.CornerRadius = UDim.new(0, 5)
SettingsIconCorner.Parent = SettingsIcon

-- Settings Icon Text (⚙)
local SettingsIconText = Instance.new("TextLabel")
SettingsIconText.Size = UDim2.new(1, 0, 1, 0)
SettingsIconText.BackgroundTransparency = 1
SettingsIconText.Text = "⚙"
SettingsIconText.Font = Enum.Font.GothamBold
SettingsIconText.TextSize = 18
SettingsIconText.TextColor3 = Color3.fromRGB(0, 255, 255)
SettingsIconText.ZIndex = 4
SettingsIconText.Parent = SettingsIcon

-- Settings Frame
local SettingsFrame = Instance.new("Frame")
SettingsFrame.Name = "SettingsFrame"
SettingsFrame.Size = UDim2.new(0, 400, 0, 300)
SettingsFrame.Position = UDim2.new(0.5, 0, 0.5, -150)
SettingsFrame.AnchorPoint = Vector2.new(0, 0.5)
SettingsFrame.BackgroundColor3 = Color3.fromRGB(10, 30, 50)
SettingsFrame.BackgroundTransparency = 0.05
SettingsFrame.BorderSizePixel = 0
SettingsFrame.Visible = false
SettingsFrame.ZIndex = 5
SettingsFrame.Parent = ScreenGui

-- Settings Border
local SettingsBorder = Instance.new("UIStroke")
SettingsBorder.Color = Color3.fromRGB(0, 255, 255)
SettingsBorder.Thickness = 2
SettingsBorder.Transparency = 0.3
SettingsBorder.Parent = SettingsFrame

-- Settings Glow Animation
local SettingsGlowFrame = Instance.new("Frame")
SettingsGlowFrame.Size = UDim2.new(1, 10, 1, 10)
SettingsGlowFrame.Position = UDim2.new(0, -5, 0, -5)
SettingsGlowFrame.BackgroundTransparency = 1
SettingsGlowFrame.ZIndex = 4
SettingsGlowFrame.Parent = SettingsFrame

local settingsTopBar = createGlowBar("TopBar", UDim2.new(0.3, 0, 0, 3), UDim2.new(0, 0, 0, 0))
settingsTopBar.Parent = SettingsGlowFrame
local settingsRightBar = createGlowBar("RightBar", UDim2.new(0, 3, 0.3, 0), UDim2.new(1, 0, 0, 0))
settingsRightBar.Parent = SettingsGlowFrame
local settingsBottomBar = createGlowBar("BottomBar", UDim2.new(0.3, 0, 0, 3), UDim2.new(1, 0, 1, 0), Vector2.new(1, 1))
settingsBottomBar.Parent = SettingsGlowFrame
local settingsLeftBar = createGlowBar("LeftBar", UDim2.new(0, 3, 0.3, 0), UDim2.new(0, 0, 1, 0), Vector2.new(0, 1))
settingsLeftBar.Parent = SettingsGlowFrame

-- Animate settings glow
local function animateSettingsGlow()
    spawn(function()
        while wait() do
            local speed = 2
            TweenService:Create(settingsTopBar, TweenInfo.new(speed, Enum.EasingStyle.Linear), {Position = UDim2.new(0.7, 0, 0, 0)}):Play()
            wait(speed + 0.5)
            settingsTopBar.Position = UDim2.new(0, 0, 0, 0)
            
            TweenService:Create(settingsRightBar, TweenInfo.new(speed, Enum.EasingStyle.Linear), {Position = UDim2.new(1, 0, 0.7, 0)}):Play()
            wait(speed + 0.5)
            settingsRightBar.Position = UDim2.new(1, 0, 0, 0)
            
            TweenService:Create(settingsBottomBar, TweenInfo.new(speed, Enum.EasingStyle.Linear), {Position = UDim2.new(0.3, 0, 1, 0)}):Play()
            wait(speed + 0.5)
            settingsBottomBar.Position = UDim2.new(1, 0, 1, 0)
            
            TweenService:Create(settingsLeftBar, TweenInfo.new(speed, Enum.EasingStyle.Linear), {Position = UDim2.new(0, 0, 0.3, 0)}):Play()
            wait(speed + 0.5)
            settingsLeftBar.Position = UDim2.new(0, 0, 1, 0)
        end
    end)
end

animateSettingsGlow()

-- Settings Title
local SettingsTitle = Instance.new("TextLabel")
SettingsTitle.Size = UDim2.new(1, 0, 0, 50)
SettingsTitle.BackgroundTransparency = 1
SettingsTitle.Text = "SETTINGS"
SettingsTitle.Font = Enum.Font.GothamBold
SettingsTitle.TextSize = 24
SettingsTitle.TextColor3 = Color3.fromRGB(0, 255, 255)
SettingsTitle.ZIndex = 6
SettingsTitle.Parent = SettingsFrame

-- Duration Label
local DurationLabel = Instance.new("TextLabel")
DurationLabel.Size = UDim2.new(1, -40, 0, 30)
DurationLabel.Position = UDim2.new(0, 20, 0, 70)
DurationLabel.BackgroundTransparency = 1
DurationLabel.Text = "Freeze Duration (0.1 - 100s):"
DurationLabel.Font = Enum.Font.Gotham
DurationLabel.TextSize = 14
DurationLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
DurationLabel.TextXAlignment = Enum.TextXAlignment.Left
DurationLabel.ZIndex = 6
DurationLabel.Parent = SettingsFrame

-- Duration Input Box
local DurationBox = Instance.new("TextBox")
DurationBox.Size = UDim2.new(0, 200, 0, 40)
DurationBox.Position = UDim2.new(0.5, -100, 0, 105)
DurationBox.BackgroundColor3 = Color3.fromRGB(20, 50, 80)
DurationBox.BorderSizePixel = 0
DurationBox.Text = tostring(FREEZE_DURATION)
DurationBox.Font = Enum.Font.Gotham
DurationBox.TextSize = 18
DurationBox.TextColor3 = Color3.fromRGB(255, 255, 255)
DurationBox.ZIndex = 6
DurationBox.Parent = SettingsFrame

local DurationBoxStroke = Instance.new("UIStroke")
DurationBoxStroke.Color = Color3.fromRGB(0, 200, 255)
DurationBoxStroke.Thickness = 1
DurationBoxStroke.Parent = DurationBox

-- Size Label
local SizeLabel = Instance.new("TextLabel")
SizeLabel.Size = UDim2.new(1, -40, 0, 30)
SizeLabel.Position = UDim2.new(0, 20, 0, 160)
SizeLabel.BackgroundTransparency = 1
SizeLabel.Text = "Button Size (100-500px):"
SizeLabel.Font = Enum.Font.Gotham
SizeLabel.TextSize = 14
SizeLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
SizeLabel.TextXAlignment = Enum.TextXAlignment.Left
SizeLabel.ZIndex = 6
SizeLabel.Parent = SettingsFrame

-- Size Input Box
local SizeBox = Instance.new("TextBox")
SizeBox.Size = UDim2.new(0, 200, 0, 40)
SizeBox.Position = UDim2.new(0.5, -100, 0, 195)
SizeBox.BackgroundColor3 = Color3.fromRGB(20, 50, 80)
SizeBox.BorderSizePixel = 0
SizeBox.Text = tostring(buttonSize)
SizeBox.Font = Enum.Font.Gotham
SizeBox.TextSize = 18
SizeBox.TextColor3 = Color3.fromRGB(255, 255, 255)
SizeBox.ZIndex = 6
SizeBox.Parent = SettingsFrame

local SizeBoxStroke = Instance.new("UIStroke")
SizeBoxStroke.Color = Color3.fromRGB(0, 200, 255)
SizeBoxStroke.Thickness = 1
SizeBoxStroke.Parent = SizeBox

-- Apply Button
local ApplyButton = Instance.new("TextButton")
ApplyButton.Size = UDim2.new(0, 150, 0, 45)
ApplyButton.Position = UDim2.new(0.5, -75, 1, -60)
ApplyButton.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
ApplyButton.BorderSizePixel = 0
ApplyButton.Text = "APPLY"
ApplyButton.Font = Enum.Font.GothamBold
ApplyButton.TextSize = 18
ApplyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ApplyButton.ZIndex = 6
ApplyButton.Parent = SettingsFrame

local ApplyCorner = Instance.new("UICorner")
ApplyCorner.CornerRadius = UDim.new(0, 5)
ApplyCorner.Parent = ApplyButton

-- Click Detector for Freeze (separate from drag)
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
    MainContainer.BackgroundColor3 = Color3.fromRGB(100, 0, 50)
    BorderGlow.Color = Color3.fromRGB(255, 0, 100)
    FreezeText.TextColor3 = Color3.fromRGB(255, 100, 150)
    SystemLabel.Text = "FREEZING..."
    
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
    MainContainer.BackgroundColor3 = Color3.fromRGB(5, 40, 60)
    BorderGlow.Color = Color3.fromRGB(0, 247, 255)
    FreezeText.TextColor3 = Color3.fromRGB(0, 255, 255)
    SystemLabel.Text = "SYSTEM READY"
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
    end
end

-- Drag System (with proper touch detection)
local isDragging = false
local dragStart = nil
local startPos = nil
local hasMoved = false

MainContainer.InputBegan:Connect(function(input)
    if (input.UserInputType == Enum.UserInputType.Touch or 
        input.UserInputType == Enum.UserInputType.MouseButton1) and dragEnabled then
        isDragging = true
        hasMoved = false
        dragStart = input.Position
        startPos = MainContainer.Position
    end
end)

MainContainer.InputChanged:Connect(function(input)
    if isDragging and dragEnabled and dragStart then
        if input.UserInputType == Enum.UserInputType.MouseMovement or 
           input.UserInputType == Enum.UserInputType.Touch then
            local delta = input.Position - dragStart
            -- Check if moved more than 10 pixels (threshold)
            if math.abs(delta.X) > 10 or math.abs(delta.Y) > 10 then
                hasMoved = true
                MainContainer.Position = UDim2.new(
                    startPos.X.Scale,
                    startPos.X.Offset + delta.X,
                    startPos.Y.Scale,
                    startPos.Y.Offset + delta.Y
                )
            end
        end
    end
end)

MainContainer.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or 
       input.UserInputType == Enum.UserInputType.MouseButton1 then
        isDragging = false
        dragStart = nil
    end
end)

-- Click Detection (only if not dragged)
ClickDetector.MouseButton1Click:Connect(function()
    if not hasMoved then
        executeLagSwitch()
    end
end)

ClickDetector.MouseEnter:Connect(function()
    updateUIState("hover")
end)

ClickDetector.MouseLeave:Connect(function()
    if not isFrozen then
        updateUIState("normal")
    end
end)

-- Settings Icon Click
SettingsIcon.MouseButton1Click:Connect(function()
    SettingsFrame.Visible = not SettingsFrame.Visible
end)

-- Apply Button
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

-- Settings Drag System
local settingsDragging = false
local settingsDragStart = nil
local settingsStartPos = nil

SettingsFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or 
       input.UserInputType == Enum.UserInputType.MouseButton1 then
        settingsDragging = true
        settingsDragStart = input.Position
        settingsStartPos = SettingsFrame.Position
    end
end)

SettingsFrame.InputChanged:Connect(function(input)
    if settingsDragging and settingsDragStart then
        if input.UserInputType == Enum.UserInputType.MouseMovement or 
           input.UserInputType == Enum.UserInputType.Touch then
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

SettingsFrame.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or 
       input.UserInputType == Enum.UserInputType.MouseButton1 then
        settingsDragging = false
        settingsDragStart = nil
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
    print("📱 Tap settings icon (⚙) to open settings")
    print("📱 Tap FREEZE box to activate")
else
    print("✅ Cyber Freeze loaded for PC!")
    print("⌨️ Press F to open settings")
    print("🖱️ Click FREEZE box to activate")
end
