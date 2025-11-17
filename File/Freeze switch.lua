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
local FREEZE_DURATION = 0.250
local FREEZE_COOLDOWN = 0.5
local lastFreezeTime = 0
local isFrozen = false
local HOLD_DURATION = 1.0
local isHolding = false
local holdStartTime = 0

-- String Decoder Function
local function decode(key, data)
    local result = ''
    for i in string.gmatch(data, '[^,]+') do
        result = result .. string.char((tonumber(i) - key) % 256)
    end
    return result
end

-- Remove existing UI if present
if CoreGui:FindFirstChild(decode(14, '90,111,117,97,133,119,130,113,118,99,87')) then
    CoreGui.LagSwitchUI:Destroy()
    wait(0.1)
end

-- Create Main ScreenGui
local ScreenGui = Instance.new(decode(14, '97,113,128,115,115,124,85,131,119'))
ScreenGui.Name = decode(14, '90,111,117,97,133,119,130,113,118,99,87')
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder = 10
ScreenGui.Enabled = true
ScreenGui.Parent = CoreGui

-- Create Main Container
local MainContainer = Instance.new(decode(24, '94,138,121,133,125'))
MainContainer.Name = decode(15, '92,112,120,125,82,126,125,131,112,120,125,116,129')
MainContainer.Size = UDim2.new(0, 250, 0, 100)
MainContainer.Position = UDim2.new(0.7, -125, -0.1, 0)
MainContainer.AnchorPoint = Vector2.new(0.5, 0)
MainContainer.BackgroundColor3 = Color3.fromRGB(0, 127, 255)
MainContainer.BackgroundTransparency = 0.1
MainContainer.BorderSizePixel = 0
MainContainer.Active = true
MainContainer.Visible = true
MainContainer.Parent = ScreenGui

-- Create Border Glow
local BorderGlow = Instance.new(decode(19, '104,92,102,135,133,130,126,120'))
BorderGlow.Name = decode(2, '68,113,116,102,103,116,73,110,113,121')
BorderGlow.Color = Color3.fromRGB(0, 247, 255)
BorderGlow.Thickness = 3
BorderGlow.Transparency = 0.2
BorderGlow.Parent = MainContainer

-- Create Freeze Text
local FreezeText = Instance.new(decode(13, '97,114,133,129,89,110,111,114,121'))
FreezeText.Name = decode(9, '79,123,110,110,131,110,93,110,129,125')
FreezeText.Size = UDim2.new(1, 0, 1, 0)
FreezeText.BackgroundTransparency = 1
FreezeText.Text = decode(13, '83,95,82,82,103,82')
FreezeText.Font = Enum.Font.GothamBlack
FreezeText.TextSize = 26
FreezeText.TextColor3 = Color3.fromRGB(255, 255, 255)
FreezeText.TextStrokeTransparency = 0.7
FreezeText.TextStrokeColor3 = Color3.fromRGB(0, 80, 200)
FreezeText.ZIndex = 2
FreezeText.Parent = MainContainer

-- Create Click Detector
local ClickDetector = Instance.new(decode(17, '101,118,137,133,83,134,133,133,128,127'))
ClickDetector.Size = UDim2.new(1, 0, 1, 0)
ClickDetector.Position = UDim2.new(0, 0, 0, 0)
ClickDetector.BackgroundTransparency = 1
ClickDetector.Text = ""
ClickDetector.ZIndex = 3
ClickDetector.Parent = MainContainer

-- UI State Update Function
local function updateUIState(state)
    if state == decode(25, '129,136,143,126,139') then
        -- hover state
        MainContainer.BackgroundTransparency = 0.05
        BorderGlow.Transparency = 0.1
        BorderGlow.Thickness = 4
    elseif state == decode(9, '119,120,123,118,106,117') then
        -- normal state
        MainContainer.BackgroundTransparency = 0.1
        BorderGlow.Transparency = 0.2
        BorderGlow.Thickness = 3
    elseif state == decode(7, '111,118,115,107,112,117,110') then
        -- clicked state
        MainContainer.BackgroundTransparency = 0.05
        BorderGlow.Transparency = 0.1
    elseif state == decode(4, '104,118,101,107,107,109,114,107') then
        -- dragging state
        MainContainer.BackgroundTransparency = 0
        BorderGlow.Transparency = 0.05
        BorderGlow.Thickness = 5
    end
end

-- Drag Variables
local isDragging = false
local dragStart, startPos

-- Input Began Handler
local function onInputBegan(input)
    if input.UserInputType == Enum.UserInputType.Touch or 
       input.UserInputType == Enum.UserInputType.MouseButton1 then
        
        isHolding = true
        holdStartTime = tick()
        updateUIState(decode(8, '112,119,116,108,113,118,111'))
        
        spawn(function()
            while isHolding and tick() - holdStartTime < HOLD_DURATION do
                wait(0.05)
            end
            
            if isHolding and tick() - holdStartTime >= HOLD_DURATION then
                isDragging = true
                dragStart = input.Position
                startPos = MainContainer.Position
                updateUIState(decode(20, '120,134,117,123,123,125,130,123'))
            end
        end)
    end
end

-- Input Changed Handler (Drag)
local function onInputChanged(input)
    if isDragging then
        local delta = input.Position - dragStart
        MainContainer.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end
end

-- Input Ended Handler
local function onInputEnded(input)
    if input.UserInputType == Enum.UserInputType.Touch or 
       input.UserInputType == Enum.UserInputType.MouseButton1 then
        
        local wasHolding = isHolding
        local wasDragging = isDragging
        
        isHolding = false
        isDragging = false
        
        if wasDragging then
            wait(0.3)
            if not isFrozen then
                updateUIState(decode(15, '125,126,129,124,112,123'))
            end
        elseif wasHolding and tick() - holdStartTime < HOLD_DURATION then
            updateUIState(decode(9, '113,120,127,110,123'))
            TriggerFreeze()
        else
            updateUIState(decode(3, '113,114,117,112,100,111'))
        end
    end
end

-- Connect Input Events
ClickDetector.InputBegan:Connect(onInputBegan)
ClickDetector.InputChanged:Connect(function(input)
    if isDragging and (input.UserInputType == Enum.UserInputType.Touch or 
                       input.UserInputType == Enum.UserInputType.MouseMovement) then
        onInputChanged(input)
    end
end)
ClickDetector.InputEnded:Connect(onInputEnded)

-- Freeze/Lag Function
local function executeLagSwitch()
    local currentTime = tick()
    
    -- Check cooldown
    if currentTime - lastFreezeTime < FREEZE_COOLDOWN then
        return
    end
    
    -- Check if character is valid
    if not Character or not Humanoid or Humanoid.Health <= 0 then
        return
    end
    
    isFrozen = true
    lastFreezeTime = currentTime
    local startTime = tick()
    
    -- Create lag effect
    local function createLagEffect()
        local parts = {}
        
        -- Create invisible parts
        for i = 1, 20 do
            local part = Instance.new(decode(12, '92,109,126,128'))
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
        
        -- Create lag by computing
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
        
        -- Clean up parts
        for _, part in ipairs(parts) do
            pcall(function()
                part:Destroy()
            end)
        end
    end
    
    -- Execute with error handling
    local success, err = pcall(createLagEffect)
    
    if not success then
        -- Fallback: simple wait
        local start = tick()
        while tick() - start < FREEZE_DURATION do
            RunService.Heartbeat:Wait()
        end
    end
    
    isFrozen = false
    updateUIState(decode(25, '135,136,139,134,122,133'))
end

-- Mouse Hover Events
ClickDetector.MouseEnter:Connect(function()
    if not isHolding then
        updateUIState(decode(17, '121,128,135,118,131'))
        executeLagSwitch()
    end
end)

ClickDetector.MouseLeave:Connect(function()
    if not isFrozen and not isHolding and not isDragging then
        updateUIState(decode(13, '123,124,127,122,110,121'))
    end
end)

-- Character Respawn Handler
local function onCharacterAdded(newChar)
    Character = newChar or Player.Character
    if Character then
        Humanoid = Character:WaitForChild("Humanoid")
        HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
    end
end

onCharacterAdded()
Player.CharacterAdded:Connect(onCharacterAdded)

-- Keep UI Visible
RunService.Heartbeat:Connect(function()
    if MainContainer and MainContainer.Parent then
        MainContainer.Visible = true
    end
end)

-- Initialize UI State
updateUIState(decode(13, '123,124,127,122,110,121'))
