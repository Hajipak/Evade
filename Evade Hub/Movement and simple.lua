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

-- Create Tabs
local Tabs = {}
Tabs.Main = Window:CreateTab({Title = "Main"})
Tabs.Settings = Window:CreateTab({Title = "Settings"})

-- Global variables
getgenv().bhopEnabled = false
getgenv().bhopMode = "Acceleration"
getgenv().bhopAccelValue = -0.1

getgenv().autoCrouchEnabled = false
getgenv().autoCrouchMode = "normal"

getgenv().bounceEnabled = false
getgenv().bounceHeight = 50
getgenv().touchEpsilon = 0.1

getgenv().strafeAcceleration = 187
getgenv().jumpCap = 1
getgenv().speed = 1500

-- GUI sizes
local guiSizes = {
    bhop = {width = 60, height = 60},
    autocrouch = {width = 60, height = 60},
    bounce = {width = 60, height = 60}
}

-- Draggable function
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
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

-- Create toggle GUI
local function createToggleGui(name, varName, yOffset)
    local gui = playerGui:FindFirstChild(name.."Gui")
    if gui then gui:Destroy() end
    gui = Instance.new("ScreenGui", playerGui)
    gui.Name = name.."Gui"
    gui.IgnoreGuiInset = true
    gui.ResetOnSpawn = false
    gui.Enabled = getgenv()[varName] and isMobile

    local frame = Instance.new("Frame", gui)
    frame.Size = UDim2.new(0, guiSizes[name:lower()].width, 0, guiSizes[name:lower()].height)
    frame.Position = UDim2.new(0.5, -guiSizes[name:lower()].width/2, 0.12 + yOffset, 0)
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

-- === MAIN TAB: Bhop ===
Tabs.Main:Section({Title = "Bhop Settings"})

local bhopGui, bhopToggleBtn, bhopFrame
Tabs.Main:Toggle({
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

Tabs.Main:Dropdown({
    Title = "Bhop Mode",
    Values = {"Acceleration", "No Acceleration"},
    Callback = function(value)
        getgenv().bhopMode = value
    end
})

Tabs.Main:Input({
    Title = "Bhop Acceleration (Negative Only)",
    Placeholder = "-0.1",
    Callback = function(value)
        if value:sub(1,1) == "-" then
            getgenv().bhopAccelValue = tonumber(value)
        end
    end
})

-- === MAIN TAB: Auto Crouch ===
Tabs.Main:Section({Title = "Auto Crouch Settings"})

local autoCrouchGui, autoCrouchToggleBtn, autoCrouchFrame
Tabs.Main:Toggle({
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

Tabs.Main:Dropdown({
    Title = "Auto Crouch Mode",
    Values = {"air", "normal", "ground"},
    Callback = function(value)
        getgenv().autoCrouchMode = value
    end
})

-- === MAIN TAB: Bounce ===
Tabs.Main:Section({Title = "Bounce Settings"})

local bounceGui, bounceToggleBtn, bounceFrame
Tabs.Main:Toggle({
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

Tabs.Main:Input({
    Title = "Bounce Height",
    Placeholder = "50",
    Callback = function(value)
        getgenv().bounceHeight = tonumber(value) or 50
    end
})

Tabs.Main:Input({
    Title = "Touch Epsilon",
    Placeholder = "0.1",
    Callback = function(value)
        getgenv().touchEpsilon = tonumber(value) or 0.1
    end
})

-- === MAIN TAB: Other Settings ===
Tabs.Main:Section({Title = "Other Movement Settings"})

Tabs.Main:Input({
    Title = "Strafe Acceleration",
    Placeholder = "187",
    Callback = function(value)
        getgenv().strafeAcceleration = tonumber(value) or 187
    end
})

Tabs.Main:Input({
    Title = "Jump Cap",
    Placeholder = "1",
    Callback = function(value)
        getgenv().jumpCap = tonumber(value) or 1
    end
})

Tabs.Main:Input({
    Title = "Speed",
    Placeholder = "1500",
    Callback = function(value)
        getgenv().speed = tonumber(value) or 1500
    end
})

-- === SETTINGS TAB: GUI Size Controls ===
Tabs.Settings:Section({Title = "GUI Size Settings"})

Tabs.Settings:Section({Title = "Bhop GUI"})
Tabs.Settings:Input({
    Title = "Width",
    Placeholder = "60",
    Callback = function(value)
        guiSizes.bhop.width = tonumber(value) or 60
        if bhopFrame then bhopFrame.Size = UDim2.new(0, guiSizes.bhop.width, 0, guiSizes.bhop.height) end
    end
})
Tabs.Settings:Input({
    Title = "Height",
    Placeholder = "60",
    Callback = function(value)
        guiSizes.bhop.height = tonumber(value) or 60
        if bhopFrame then bhopFrame.Size = UDim2.new(0, guiSizes.bhop.width, 0, guiSizes.bhop.height) end
    end
})

Tabs.Settings:Section({Title = "Auto Crouch GUI"})
Tabs.Settings:Input({
    Title = "Width",
    Placeholder = "60",
    Callback = function(value)
        guiSizes.autocrouch.width = tonumber(value) or 60
        if autoCrouchFrame then autoCrouchFrame.Size = UDim2.new(0, guiSizes.autocrouch.width, 0, guiSizes.autocrouch.height) end
    end
})
Tabs.Settings:Input({
    Title = "Height",
    Placeholder = "60",
    Callback = function(value)
        guiSizes.autocrouch.height = tonumber(value) or 60
        if autoCrouchFrame then autoCrouchFrame.Size = UDim2.new(0, guiSizes.autocrouch.width, 0, guiSizes.autocrouch.height) end
    end
})

Tabs.Settings:Section({Title = "Bounce GUI"})
Tabs.Settings:Input({
    Title = "Width",
    Placeholder = "60",
    Callback = function(value)
        guiSizes.bounce.width = tonumber(value) or 60
        if bounceFrame then bounceFrame.Size = UDim2.new(0, guiSizes.bounce.width, 0, guiSizes.bounce.height) end
    end
})
Tabs.Settings:Input({
    Title = "Height",
    Placeholder = "60",
    Callback = function(value)
        guiSizes.bounce.height = tonumber(value) or 60
        if bounceFrame then bounceFrame.Size = UDim2.new(0, guiSizes.bounce.width, 0, guiSizes.bounce.height) end
    end
})

-- === Bhop Logic (No task.spawn loop) ===
UserInputService.JumpRequest:Connect(function()
    if getgenv().bhopEnabled then
        local character = player.Character
        local humanoid = character and character:FindFirstChild("Humanoid")
        if humanoid and humanoid:GetState() ~= Enum.HumanoidStateType.Jumping and humanoid:GetState() ~= Enum.HumanoidStateType.Freefall then
            humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end)

RunService.Heartbeat:Connect(function()
    if getgenv().bhopEnabled and getgenv().bhopMode == "Acceleration" then
        for _, t in pairs(getgc(true)) do
            if type(t) == "table" and rawget(t, "Friction") then
                t.Friction = getgenv().bhopAccelValue
            end
        end
    end
end)

-- === Auto Crouch Logic (No loop) ===
RunService.Heartbeat:Connect(function()
    if getgenv().autoCrouchEnabled then
        local character = player.Character
        local humanoid = character and character:FindFirstChild("Humanoid")
        if humanoid then
            local state = humanoid:GetState()
            local inAir = state == Enum.HumanoidStateType.Freefall
            local onGround = state == Enum.HumanoidStateType.Landed
            local shouldCrouch = (getgenv().autoCrouchMode == "normal") or
                                (getgenv().autoCrouchMode == "air" and inAir) or
                                (getgenv().autoCrouchMode == "ground" and onGround)
            if shouldCrouch then
                humanoid:ChangeState(Enum.HumanoidStateType.Crouching)
            end
        end
    end
end)

-- === Bounce Logic (No loop) ===
RunService.Heartbeat:Connect(function()
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
end)

-- === Apply Other Settings (No loop) ===
RunService.Heartbeat:Connect(function()
    for _, t in pairs(getgc(true)) do
        if type(t) == "table" then
            if rawget(t, "AirStrafeAcceleration") then t.AirStrafeAcceleration = getgenv().strafeAcceleration end
            if rawget(t, "JumpCap") then t.JumpCap = getgenv().jumpCap end
            if rawget(t, "Speed") then t.Speed = getgenv().speed end
        end
    end
end)

-- Open Main tab by default
Window:SelectTab(1)
