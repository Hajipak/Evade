if getgenv().ZenHubEvadeExecuted then
    return
end
getgenv().ZenHubEvadeExecuted = true

-- Load WindUI
local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()

-- Set WindUI properties
WindUI.TransparencyValue = 0.2
WindUI:SetTheme("Dark")

-- Create WindUI window
local Window = WindUI:CreateWindow({
    Title = "Zen Hub",
    Icon = "rocket",
    Author = "Made by: Zen",
    Folder = "GameHackUI",
    Size = UDim2.fromOffset(580, 490),
    Theme = "Dark",
    HidePanelBackground = false,
    Acrylic = false,
    HideSearchBar = false,
    SideBarWidth = 200
})

-- Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local isMobile = UserInputService.TouchEnabled

-- Tabs
local Tabs = {}
Tabs.Player = Window:CreateTab({Title = "Player"})
Tabs.Settings = Window:CreateTab({Title = "Settings"})

-- Global variables for features
getgenv().bhopEnabled = false
getgenv().bhopMode = "Acceleration"
getgenv().bhopAccelValue = -0.1

getgenv().autoCrouchEnabled = false
getgenv().autoCrouchMode = "normal"  -- air, normal, ground

getgenv().bounceEnabled = false
getgenv().bounceHeight = 50
getgenv().touchEpsilon = 0.1

getgenv().strafeAcceleration = 187
getgenv().jumpCap = 1
getgenv().speed = 1500

-- GUI sizes (default)
local guiSizes = {
    bhop = {width = 60, height = 60},
    autoCrouch = {width = 60, height = 60},
    bounce = {width = 60, height = 60}
}

-- Function to make frames draggable
local function makeDraggable(frame)
    local dragging = false
    local dragStart, startPos
    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
        end
    end)
    frame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            if dragging then
                local delta = input.Position - dragStart
                frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            end
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

-- Function to create toggle GUI
local function createToggleGui(name, varName, yOffset)
    local gui = playerGui:FindFirstChild(name .. "Gui")
    if gui then gui:Destroy() end
    gui = Instance.new("ScreenGui", playerGui)
    gui.Name = name .. "Gui"
    gui.IgnoreGuiInset = true
    gui.ResetOnSpawn = false
    gui.Enabled = getgenv()[varName] and isMobile

    local frame = Instance.new("Frame", gui)
    frame.Size = UDim2.new(0, guiSizes[name:lower()].width, 0, guiSizes[name:lower()].height)
    frame.Position = UDim2.new(0.5, -guiSizes[name:lower()].width / 2, 0.12 + yOffset, 0)
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
        toggleBtn.Text = getgenv()[varName] and "On" or "Off"
        toggleBtn.BackgroundColor3 = getgenv()[varName] and Color3.fromRGB(0, 100, 0) or Color3.fromRGB(0, 0, 0)
        gui.Enabled = true
    end)

    return gui, toggleBtn, frame
end

-- Bhop GUI and Logic
local bhopGui, bhopToggleBtn, bhopFrame
Tabs.Player:Toggle({
    Title = "Bhop",
    Callback = function(state)
        getgenv().bhopEnabled = state
        if not bhopGui then
            bhopGui, bhopToggleBtn, bhopFrame = createToggleGui("Bhop", "bhopEnabled", 0.12)
        end
        bhopGui.Enabled = state and isMobile
        bhopToggleBtn.Text = state and "On" or "Off"
        bhopToggleBtn.BackgroundColor3 = state and Color3.fromRGB(0, 100, 0) or Color3.fromRGB(0, 0, 0)
    end
})

Tabs.Player:Dropdown({
    Title = "Bhop Mode",
    Values = {"Acceleration", "No Acceleration"},
    Callback = function(value)
        getgenv().bhopMode = value
    end
})

Tabs.Player:Input({
    Title = "Bhop Acceleration (Negative Only)",
    Placeholder = "-0.1",
    Callback = function(value)
        if value:sub(1,1) == "-" then
            getgenv().bhopAccelValue = tonumber(value)
        end
    end
})

-- Bhop Loop
task.spawn(function()
    while true do
        if getgenv().bhopEnabled then
            local character = player.Character
            local humanoid = character and character:FindFirstChild("Humanoid")
            if humanoid then
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
    while true do
        local friction = 5
        if getgenv().bhopEnabled and getgenv().bhopMode == "Acceleration" then
            friction = getgenv().bhopAccelValue or -0.1
        end
        for _, t in pairs(getgc(true)) do
            if type(t) == "table" and rawget(t, "Friction") then
                t.Friction = friction
            end
        end
        task.wait(0.15)
    end
end)

-- Auto Crouch GUI and Logic
local autoCrouchGui, autoCrouchToggleBtn, autoCrouchFrame
Tabs.Player:Toggle({
    Title = "Auto Crouch",
    Callback = function(state)
        getgenv().autoCrouchEnabled = state
        if not autoCrouchGui then
            autoCrouchGui, autoCrouchToggleBtn, autoCrouchFrame = createToggleGui("AutoCrouch", "autoCrouchEnabled", 0.24)
        end
        autoCrouchGui.Enabled = state and isMobile
        autoCrouchToggleBtn.Text = state and "On" or "Off"
        autoCrouchToggleBtn.BackgroundColor3 = state and Color3.fromRGB(0, 100, 0) or Color3.fromRGB(0, 0, 0)
    end
})

Tabs.Player:Dropdown({
    Title = "Auto Crouch Mode",
    Values = {"air", "normal", "ground"},
    Callback = function(value)
        getgenv().autoCrouchMode = value
    end
})

-- Auto Crouch Loop
task.spawn(function()
    while true do
        if getgenv().autoCrouchEnabled then
            local character = player.Character
            local humanoid = character and character:FindFirstChild("Humanoid")
            if humanoid then
                local inAir = humanoid:GetState() == Enum.HumanoidStateType.Freefall
                local onGround = humanoid:GetState() == Enum.HumanoidStateType.Landed
                if (getgenv().autoCrouchMode == "normal") or
                   (getgenv().autoCrouchMode == "air" and inAir) or
                   (getgenv().autoCrouchMode == "ground" and onGround) then
                    humanoid:ChangeState(Enum.HumanoidStateType.Crouching)
                end
            end
        end
        task.wait(0.1)
    end
end)

-- Bounce GUI and Logic
local bounceGui, bounceToggleBtn, bounceFrame
Tabs.Player:Toggle({
    Title = "Bounce",
    Callback = function(state)
        getgenv().bounceEnabled = state
        if not bounceGui then
            bounceGui, bounceToggleBtn, bounceFrame = createToggleGui("Bounce", "bounceEnabled", 0.36)
        end
        bounceGui.Enabled = state and isMobile
        bounceToggleBtn.Text = state and "On" or "Off"
        bounceToggleBtn.BackgroundColor3 = state and Color3.fromRGB(0, 100, 0) or Color3.fromRGB(0, 0, 0)
    end
})

Tabs.Player:Input({
    Title = "Bounce Height",
    Placeholder = "50",
    Callback = function(value)
        getgenv().bounceHeight = tonumber(value) or 50
    end
})

Tabs.Player:Input({
    Title = "Touch Epsilon",
    Placeholder = "0.1",
    Callback = function(value)
        getgenv().touchEpsilon = tonumber(value) or 0.1
    end
})

-- Bounce Loop
task.spawn(function()
    while true do
        if getgenv().bounceEnabled then
            local character = player.Character
            local rootPart = character and character:FindFirstChild("HumanoidRootPart")
            if rootPart then
                local ray = Ray.new(rootPart.Position, Vector3.new(0, -1, 0) * (rootPart.Size.Y / 2 + getgenv().touchEpsilon))
                local hit = workspace:FindPartOnRay(ray, character)
                if hit then
                    rootPart.Velocity = Vector3.new(rootPart.Velocity.X, getgenv().bounceHeight, rootPart.Velocity.Z)
                end
            end
        end
        task.wait(0.05)
    end
end)

-- Strafe Acceleration, Jump Cap, Speed
Tabs.Player:Input({
    Title = "Strafe Acceleration",
    Placeholder = "187",
    Callback = function(value)
        getgenv().strafeAcceleration = tonumber(value) or 187
    end
})

Tabs.Player:Input({
    Title = "Jump Cap",
    Placeholder = "1",
    Callback = function(value)
        getgenv().jumpCap = tonumber(value) or 1
    end
})

Tabs.Player:Input({
    Title = "Speed",
    Placeholder = "1500",
    Callback = function(value)
        getgenv().speed = tonumber(value) or 1500
    end
})

-- Apply settings to config tables
local function applySettings()
    for _, t in pairs(getgc(true)) do
        if type(t) == "table" then
            if rawget(t, "AirStrafeAcceleration") then t.AirStrafeAcceleration = getgenv().strafeAcceleration end
            if rawget(t, "JumpCap") then t.JumpCap = getgenv().jumpCap end
            if rawget(t, "Speed") then t.Speed = getgenv().speed end
        end
    end
end

RunService.Heartbeat:Connect(applySettings)

-- Settings for GUI sizes
Tabs.Settings:Section({ Title = "GUI Size Settings" })

Tabs.Settings:Input({
    Title = "Bhop GUI Width",
    Placeholder = "60",
    Callback = function(value)
        guiSizes.bhop.width = tonumber(value) or 60
        if bhopFrame then bhopFrame.Size = UDim2.new(0, guiSizes.bhop.width, 0, guiSizes.bhop.height) end
    end
})

Tabs.Settings:Input({
    Title = "Bhop GUI Height",
    Placeholder = "60",
    Callback = function(value)
        guiSizes.bhop.height = tonumber(value) or 60
        if bhopFrame then bhopFrame.Size = UDim2.new(0, guiSizes.bhop.width, 0, guiSizes.bhop.height) end
    end
})

Tabs.Settings:Input({
    Title = "Auto Crouch GUI Width",
    Placeholder = "60",
    Callback = function(value)
        guiSizes.autoCrouch.width = tonumber(value) or 60
        if autoCrouchFrame then autoCrouchFrame.Size = UDim2.new(0, guiSizes.autoCrouch.width, 0, guiSizes.autoCrouch.height) end
    end
})

Tabs.Settings:Input({
    Title = "Auto Crouch GUI Height",
    Placeholder = "60",
    Callback = function(value)
        guiSizes.autoCrouch.height = tonumber(value) or 60
        if autoCrouchFrame then autoCrouchFrame.Size = UDim2.new(0, guiSizes.autoCrouch.width, 0, guiSizes.autoCrouch.height) end
    end
})

Tabs.Settings:Input({
    Title = "Bounce GUI Width",
    Placeholder = "60",
    Callback = function(value)
        guiSizes.bounce.width = tonumber(value) or 60
        if bounceFrame then bounceFrame.Size = UDim2.new(0, guiSizes.bounce.width, 0, guiSizes.bounce.height) end
    end
})

Tabs.Settings:Input({
    Title = "Bounce GUI Height",
    Placeholder = "60",
    Callback = function(value)
        guiSizes.bounce.height = tonumber(value) or 60
        if bounceFrame then bounceFrame.Size = UDim2.new(0, guiSizes.bounce.width, 0, guiSizes.bounce.height) end
    end
})

Window:SelectTab(1)
