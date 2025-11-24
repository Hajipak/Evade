-- Cyber Freeze Switch Script (Mobile & PC Support)
-- Script untuk freeze game dengan durasi yang bisa diatur

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Deteksi platform
local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

-- Variabel untuk freeze
local freezeEnabled = false
local freezeDuration = 1
local buttonSize = 200
local freezeConnection = nil
local dragEnabled = true

-- Buat ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CyberFreezeGui"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

-- Frame utama untuk settings
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 400, 0, 350)
mainFrame.Position = UDim2.new(0.5, -200, 0.5, -175)
mainFrame.BackgroundColor3 = Color3.fromRGB(10, 30, 45)
mainFrame.BorderSizePixel = 2
mainFrame.BorderColor3 = Color3.fromRGB(0, 255, 255)
mainFrame.Visible = false
mainFrame.Parent = screenGui

-- Animasi cahaya biru mengelilingi frame
local glowFrame = Instance.new("Frame")
glowFrame.Name = "GlowFrame"
glowFrame.Size = UDim2.new(1, 10, 1, 10)
glowFrame.Position = UDim2.new(0, -5, 0, -5)
glowFrame.BackgroundTransparency = 1
glowFrame.ZIndex = 0
glowFrame.Parent = mainFrame

-- Buat 4 glow bar untuk efek cahaya mengelilingi
local function createGlowBar(name, size, position, anchorPoint)
    local bar = Instance.new("Frame")
    bar.Name = name
    bar.Size = size
    bar.Position = position
    bar.AnchorPoint = anchorPoint or Vector2.new(0, 0)
    bar.BackgroundColor3 = Color3.fromRGB(0, 255, 255)
    bar.BorderSizePixel = 0
    bar.ZIndex = 0
    bar.Parent = glowFrame
    
    local gradient = Instance.new("UIGradient")
    gradient.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(0.5, 0),
        NumberSequenceKeypoint.new(1, 1)
    })
    gradient.Parent = bar
    
    return bar, gradient
end

-- Buat 4 bar untuk efek cahaya
local topBar, topGradient = createGlowBar("TopBar", UDim2.new(0.3, 0, 0, 3), UDim2.new(0, 0, 0, 0))
local rightBar, rightGradient = createGlowBar("RightBar", UDim2.new(0, 3, 0.3, 0), UDim2.new(1, 0, 0, 0))
local bottomBar, bottomGradient = createGlowBar("BottomBar", UDim2.new(0.3, 0, 0, 3), UDim2.new(1, 0, 1, 0), Vector2.new(1, 1))
local leftBar, leftGradient = createGlowBar("LeftBar", UDim2.new(0, 3, 0.3, 0), UDim2.new(0, 0, 1, 0), Vector2.new(0, 1))

-- Fungsi animasi cahaya mengelilingi
local function animateGlow()
    local animationSpeed = 2
    
    spawn(function()
        while wait() do
            -- Top bar bergerak dari kiri ke kanan
            local topTween = TweenService:Create(topBar, TweenInfo.new(animationSpeed, Enum.EasingStyle.Linear), {
                Position = UDim2.new(0.7, 0, 0, 0)
            })
            topTween:Play()
            topTween.Completed:Wait()
            topBar.Position = UDim2.new(0, 0, 0, 0)
            
            wait(0.5)
            
            -- Right bar bergerak dari atas ke bawah
            local rightTween = TweenService:Create(rightBar, TweenInfo.new(animationSpeed, Enum.EasingStyle.Linear), {
                Position = UDim2.new(1, 0, 0.7, 0)
            })
            rightTween:Play()
            rightTween.Completed:Wait()
            rightBar.Position = UDim2.new(1, 0, 0, 0)
            
            wait(0.5)
            
            -- Bottom bar bergerak dari kanan ke kiri
            local bottomTween = TweenService:Create(bottomBar, TweenInfo.new(animationSpeed, Enum.EasingStyle.Linear), {
                Position = UDim2.new(0.3, 0, 1, 0)
            })
            bottomTween:Play()
            bottomTween.Completed:Wait()
            bottomBar.Position = UDim2.new(1, 0, 1, 0)
            
            wait(0.5)
            
            -- Left bar bergerak dari bawah ke atas
            local leftTween = TweenService:Create(leftBar, TweenInfo.new(animationSpeed, Enum.EasingStyle.Linear), {
                Position = UDim2.new(0, 0, 0.3, 0)
            })
            leftTween:Play()
            leftTween.Completed:Wait()
            leftBar.Position = UDim2.new(0, 0, 1, 0)
            
            wait(0.5)
        end
    end)
end

-- Mulai animasi cahaya
animateGlow()

-- Title
local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "Title"
titleLabel.Size = UDim2.new(1, 0, 0, 50)
titleLabel.Position = UDim2.new(0, 0, 0, 0)
titleLabel.BackgroundColor3 = Color3.fromRGB(0, 20, 35)
titleLabel.BorderSizePixel = 0
titleLabel.Text = "CYBER FREEZE"
titleLabel.TextColor3 = Color3.fromRGB(0, 255, 255)
titleLabel.TextSize = 24
titleLabel.Font = Enum.Font.GothamBold
titleLabel.Parent = mainFrame

-- Settings Label
local settingsLabel = Instance.new("TextLabel")
settingsLabel.Size = UDim2.new(1, -20, 0, 30)
settingsLabel.Position = UDim2.new(0, 10, 0, 60)
settingsLabel.BackgroundTransparency = 1
settingsLabel.Text = "SETTINGS"
settingsLabel.TextColor3 = Color3.fromRGB(0, 255, 255)
settingsLabel.TextSize = 18
settingsLabel.Font = Enum.Font.GothamBold
settingsLabel.TextXAlignment = Enum.TextXAlignment.Left
settingsLabel.Parent = mainFrame

-- Freeze Duration Label
local durationLabel = Instance.new("TextLabel")
durationLabel.Size = UDim2.new(1, -20, 0, 25)
durationLabel.Position = UDim2.new(0, 10, 0, 100)
durationLabel.BackgroundTransparency = 1
durationLabel.Text = "Freeze Duration (0.1 - 100s):"
durationLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
durationLabel.TextSize = 14
durationLabel.Font = Enum.Font.Gotham
durationLabel.TextXAlignment = Enum.TextXAlignment.Left
durationLabel.Parent = mainFrame

-- Duration TextBox
local durationBox = Instance.new("TextBox")
durationBox.Size = UDim2.new(0, 150, 0, 35)
durationBox.Position = UDim2.new(0.5, -75, 0, 130)
durationBox.BackgroundColor3 = Color3.fromRGB(20, 40, 60)
durationBox.BorderSizePixel = 1
durationBox.BorderColor3 = Color3.fromRGB(0, 200, 200)
durationBox.Text = tostring(freezeDuration)
durationBox.TextColor3 = Color3.fromRGB(255, 255, 255)
durationBox.TextSize = 16
durationBox.Font = Enum.Font.Gotham
durationBox.Parent = mainFrame

-- Button Size Label
local sizeLabel = Instance.new("TextLabel")
sizeLabel.Size = UDim2.new(1, -20, 0, 25)
sizeLabel.Position = UDim2.new(0, 10, 0, 175)
sizeLabel.BackgroundTransparency = 1
sizeLabel.Text = "Button Size (100-500px):"
sizeLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
sizeLabel.TextSize = 14
sizeLabel.Font = Enum.Font.Gotham
sizeLabel.TextXAlignment = Enum.TextXAlignment.Left
sizeLabel.Parent = mainFrame

-- Size TextBox
local sizeBox = Instance.new("TextBox")
sizeBox.Size = UDim2.new(0, 150, 0, 35)
sizeBox.Position = UDim2.new(0.5, -75, 0, 205)
sizeBox.BackgroundColor3 = Color3.fromRGB(20, 40, 60)
sizeBox.BorderSizePixel = 1
sizeBox.BorderColor3 = Color3.fromRGB(0, 200, 200)
sizeBox.Text = tostring(buttonSize)
sizeBox.TextColor3 = Color3.fromRGB(255, 255, 255)
sizeBox.TextSize = 16
sizeBox.Font = Enum.Font.Gotham
sizeBox.Parent = mainFrame

-- Drag GUI Label
local dragLabel = Instance.new("TextLabel")
dragLabel.Size = UDim2.new(0.5, -15, 0, 25)
dragLabel.Position = UDim2.new(0, 10, 0, 250)
dragLabel.BackgroundTransparency = 1
dragLabel.Text = "Drag GUI:"
dragLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
dragLabel.TextSize = 14
dragLabel.Font = Enum.Font.Gotham
dragLabel.TextXAlignment = Enum.TextXAlignment.Left
dragLabel.Parent = mainFrame

-- Drag Toggle Frame
local dragToggleFrame = Instance.new("Frame")
dragToggleFrame.Size = UDim2.new(0, 80, 0, 30)
dragToggleFrame.Position = UDim2.new(0.5, 10, 0, 247)
dragToggleFrame.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
dragToggleFrame.BorderSizePixel = 1
dragToggleFrame.BorderColor3 = Color3.fromRGB(0, 200, 200)
dragToggleFrame.Parent = mainFrame

local dragToggleCorner = Instance.new("UICorner")
dragToggleCorner.CornerRadius = UDim.new(0, 15)
dragToggleCorner.Parent = dragToggleFrame

-- Drag Toggle Button
local dragToggleButton = Instance.new("TextButton")
dragToggleButton.Size = UDim2.new(1, 0, 1, 0)
dragToggleButton.Position = UDim2.new(0, 0, 0, 0)
dragToggleButton.BackgroundTransparency = 1
dragToggleButton.Text = "ON"
dragToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
dragToggleButton.TextSize = 14
dragToggleButton.Font = Enum.Font.GothamBold
dragToggleButton.Parent = dragToggleFrame

-- Apply Button
local applyButton = Instance.new("TextButton")
applyButton.Size = UDim2.new(0, 150, 0, 40)
applyButton.Position = UDim2.new(0.5, -75, 1, -50)
applyButton.BackgroundColor3 = Color3.fromRGB(0, 150, 200)
applyButton.BorderSizePixel = 0
applyButton.Text = "APPLY"
applyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
applyButton.TextSize = 18
applyButton.Font = Enum.Font.GothamBold
applyButton.Parent = mainFrame

-- Close Button
local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.new(0, 30, 0, 30)
closeButton.Position = UDim2.new(1, -40, 0, 10)
closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeButton.BorderSizePixel = 0
closeButton.Text = "X"
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.TextSize = 18
closeButton.Font = Enum.Font.GothamBold
closeButton.Parent = mainFrame

-- Settings Button (untuk mobile & PC)
local settingsButton = Instance.new("TextButton")
settingsButton.Name = "SettingsButton"
settingsButton.Size = UDim2.new(0, 60, 0, 60)
settingsButton.Position = UDim2.new(1, -70, 0, 10)
settingsButton.BackgroundColor3 = Color3.fromRGB(0, 150, 200)
settingsButton.BorderSizePixel = 2
settingsButton.BorderColor3 = Color3.fromRGB(0, 255, 255)
settingsButton.Text = "⚙️"
settingsButton.TextColor3 = Color3.fromRGB(255, 255, 255)
settingsButton.TextSize = 30
settingsButton.Font = Enum.Font.GothamBold
settingsButton.Parent = screenGui

local settingsCorner = Instance.new("UICorner")
settingsCorner.CornerRadius = UDim.new(0, 10)
settingsCorner.Parent = settingsButton

-- Freeze Button (tombol aktual untuk freeze)
local freezeButton = Instance.new("TextButton")
freezeButton.Name = "FreezeButton"
freezeButton.Size = UDim2.new(0, buttonSize, 0, buttonSize)
freezeButton.Position = UDim2.new(0, 50, 1, -buttonSize - 50)
freezeButton.BackgroundColor3 = Color3.fromRGB(0, 200, 200)
freezeButton.BorderSizePixel = 3
freezeButton.BorderColor3 = Color3.fromRGB(0, 255, 255)
freezeButton.Text = "❄️"
freezeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
freezeButton.TextSize = 50
freezeButton.Font = Enum.Font.GothamBold
freezeButton.Visible = true
freezeButton.Parent = screenGui

-- UICorner untuk button
local corner1 = Instance.new("UICorner")
corner1.CornerRadius = UDim.new(1, 0)
corner1.Parent = freezeButton

-- Fungsi freeze game
local function freezeGame()
    if freezeEnabled then return end
    
    freezeEnabled = true
    freezeButton.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
    
    -- Freeze dengan menghentikan rendering dan physics
    local startTime = tick()
    
    freezeConnection = RunService.Heartbeat:Connect(function()
        local elapsed = tick() - startTime
        if elapsed >= freezeDuration then
            if freezeConnection then
                freezeConnection:Disconnect()
                freezeConnection = nil
            end
            freezeEnabled = false
            freezeButton.BackgroundColor3 = Color3.fromRGB(0, 200, 200)
        else
            -- Freeze rendering dengan wait yang sangat singkat
            wait(9e9) -- Ini akan membuat game freeze
        end
    end)
    
    -- Timer untuk unfreeze otomatis
    task.delay(freezeDuration, function()
        if freezeConnection then
            freezeConnection:Disconnect()
            freezeConnection = nil
        end
        freezeEnabled = false
        freezeButton.BackgroundColor3 = Color3.fromRGB(0, 200, 200)
    end)
end

-- Toggle Drag Function
dragToggleButton.MouseButton1Click:Connect(function()
    dragEnabled = not dragEnabled
    
    if dragEnabled then
        dragToggleButton.Text = "ON"
        dragToggleFrame.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
    else
        dragToggleButton.Text = "OFF"
        dragToggleFrame.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
    end
end)

-- Settings Button Click (Toggle)
settingsButton.MouseButton1Click:Connect(function()
    mainFrame.Visible = not mainFrame.Visible
end)

-- Event handlers
applyButton.MouseButton1Click:Connect(function()
    local newDuration = tonumber(durationBox.Text)
    local newSize = tonumber(sizeBox.Text)
    
    if newDuration and newDuration >= 0.1 and newDuration <= 100 then
        freezeDuration = newDuration
    else
        durationBox.Text = tostring(freezeDuration)
    end
    
    if newSize and newSize >= 100 and newSize <= 500 then
        buttonSize = newSize
        freezeButton.Size = UDim2.new(0, buttonSize, 0, buttonSize)
        freezeButton.TextSize = buttonSize / 4
    else
        sizeBox.Text = tostring(buttonSize)
    end
    
    mainFrame.Visible = false
end)

closeButton.MouseButton1Click:Connect(function()
    mainFrame.Visible = false
end)

freezeButton.MouseButton1Click:Connect(function()
    freezeGame()
end)

-- Toggle settings dengan tombol keyboard (untuk PC)
if not isMobile then
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if not gameProcessed and input.KeyCode == Enum.KeyCode.F then
            mainFrame.Visible = not mainFrame.Visible
        end
    end)
end

-- Drag functionality untuk mainFrame (Support Mobile & PC)
local dragging = false
local dragInput = nil
local dragStart = nil
local startPos = nil

local function updateInput(input)
    if dragging and dragEnabled then
        local delta = input.Position - dragStart
        mainFrame.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end
end

-- Support untuk Mouse (PC)
mainFrame.InputBegan:Connect(function(input)
    if (input.UserInputType == Enum.UserInputType.MouseButton1 or 
        input.UserInputType == Enum.UserInputType.Touch) and dragEnabled then
        dragging = true
        dragStart = input.Position
        startPos = mainFrame.Position
        
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

mainFrame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or 
       input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

-- Update position saat drag
UserInputService.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or 
       input.UserInputType == Enum.UserInputType.Touch then
        if dragging and dragEnabled then
            updateInput(input)
        end
    end
end)

-- Touch End untuk mobile
UserInputService.TouchEnded:Connect(function(input, gameProcessed)
    if input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

-- Notifikasi platform
if isMobile then
    print("✅ Cyber Freeze Script loaded for MOBILE!")
    print("📱 Tap the gear (⚙️) button to open settings")
else
    print("✅ Cyber Freeze Script loaded for PC!")
    print("⌨️ Press 'F' or click gear (⚙️) to toggle settings")
end

print("❄️ Click the freeze button to freeze the game")
