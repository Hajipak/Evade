-- Movement Hub Evade Lite.lua
-- WindUI-based movement tool (trimmed UI, full logic from Evade Test)
if getgenv().MovementHubEvadeLiteExecuted then return end
getgenv().MovementHubEvadeLiteExecuted = true

-- Load WindUI
local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()

-- Localization
local Localization = WindUI:Localization({
    Enabled = true,
    Prefix = "loc:",
    DefaultLanguage = "en",
    Translations = {
        ["en"] = {
            ["SCRIPT_TITLE"] = "Movement Hub - Evade Lite",
            ["WELCOME"] = "Made by: Zen",
            ["PLAYER_TAB"] = "Player",
            ["AUTO_TAB"] = "Auto",
            ["SETTINGS_TAB"] = "Settings",
            ["STRAFE_ACC"] = "Strafe Acceleration",
            ["JUMP_CAP"] = "Jump Cap",
            ["SPEED"] = "Speed",
            ["BHOP"] = "Bhop",
            ["AUTO_CROUCH"] = "Auto Crouch",
            ["BOUNCE"] = "Bounce",
            ["SIZE_BUTTON"] = "Size Button"
        }
    }
})

-- WindUI window
WindUI.TransparencyValue = 0.2
WindUI:SetTheme("Dark")
local Window = WindUI:CreateWindow({
    Title = "loc:SCRIPT_TITLE",
    Icon = "rocket",
    Author = "loc:WELCOME",
    Folder = "MovementHub",
    Size = UDim2.fromOffset(580, 490),
    Theme = "Dark",
    HidePanelBackground = false,
    Acrylic = false,
    HideSearchBar = false,
    SideBarWidth = 200
})

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local player = Players.LocalPlayer
local character, humanoid, rootPart

-- Helper functions
local function hasMovementFields(tbl)
    if type(tbl) ~= "table" then return false end
    local needed = {"Friction","AirStrafeAcceleration","JumpHeight","RunDeaccel","JumpSpeedMultiplier","JumpCap","SprintCap","WalkSpeedMultiplier","BhopEnabled","Speed","AirAcceleration","RunAccel","SprintAcceleration"}
    for _, k in ipairs(needed) do
        if rawget(tbl, k) == nil then return false end
    end
    return true
end

local function getConfigTables()
    local tables = {}
    for _, obj in ipairs(getgc(true)) do
        local ok, res = pcall(function()
            if hasMovementFields(obj) then return obj end
        end)
        if ok and res then table.insert(tables, res) end
    end
    return tables
end

local function applyToTables(fn)
    for _, t in ipairs(getConfigTables()) do
        pcall(fn, t)
    end
end

-- Settings
local currentSettings = {
    Speed = "1500",
    JumpCap = "1",
    AirStrafeAcceleration = "187"
}

local function createValidatedInput(config)
    return function(input)
        local val = tonumber(input)
        if not val then return end
        currentSettings[config.field] = tostring(val)
        applyToTables(function(obj)
            obj[config.field] = val
        end)
    end
end

-- States
local featureStates = { Bhop=false, AutoCrouch=false, Bounce=false }

-- On-screen GUI toggle creator
local function createToggleGui(name, stateRef)
    local gui = Instance.new("ScreenGui")
    gui.Name = name .. "Gui"
    gui.IgnoreGuiInset = true
    gui.ResetOnSpawn = false
    gui.Parent = player:WaitForChild("PlayerGui")

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 130, 0, 40)
    frame.Position = UDim2.new(0.8, 0, 0.03, 0)
    frame.BackgroundTransparency = 0.4
    frame.BackgroundColor3 = Color3.fromRGB(25,25,25)
    frame.Parent = gui

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -50, 1, 0)
    label.Position = UDim2.new(0, 8, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = name
    label.Font = Enum.Font.SourceSansBold
    label.TextSize = 14
    label.TextColor3 = Color3.fromRGB(255,255,255)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 40, 0, 24)
    btn.Position = UDim2.new(1, -46, 0.5, -12)
    btn.Text = featureStates[stateRef] and "On" or "Off"
    btn.BackgroundColor3 = featureStates[stateRef] and Color3.fromRGB(0,170,60) or Color3.fromRGB(170,0,0)
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 14
    btn.Parent = frame

    btn.MouseButton1Click:Connect(function()
        featureStates[stateRef] = not featureStates[stateRef]
        btn.Text = featureStates[stateRef] and "On" or "Off"
        btn.BackgroundColor3 = featureStates[stateRef] and Color3.fromRGB(0,170,60) or Color3.fromRGB(170,0,0)
    end)

    gui.Enabled = false
    return gui
end

-- Tabs
local Tabs = {}
Tabs.Player = Window:CreateTab({ Title = "loc:PLAYER_TAB" })
Tabs.Auto = Window:CreateTab({ Title = "loc:AUTO_TAB" })
Tabs.Settings = Window:CreateTab({ Title = "loc:SETTINGS_TAB" })

-- Player inputs
Tabs.Player:Section({ Title = "Movement" })
Tabs.Player:Input({ Title="loc:SPEED", Value=currentSettings.Speed, Callback=createValidatedInput({field="Speed"}) })
Tabs.Player:Input({ Title="loc:JUMP_CAP", Value=currentSettings.JumpCap, Callback=createValidatedInput({field="JumpCap"}) })
Tabs.Player:Input({ Title="loc:STRAFE_ACC", Value=currentSettings.AirStrafeAcceleration, Callback=createValidatedInput({field="AirStrafeAcceleration"}) })

-- Auto tab
Tabs.Auto:Section({ Title = "Automation" })
Tabs.Auto:Toggle({ Title="loc:BHOP", Value=false, Callback=function(state) featureStates.Bhop = state end })
Tabs.Auto:Toggle({ Title="loc:AUTO_CROUCH", Value=false, Callback=function(state) featureStates.AutoCrouch = state end })
Tabs.Auto:Toggle({ Title="loc:BOUNCE", Value=false, Callback=function(state) featureStates.Bounce = state end })

-- Logic loops
task.spawn(function()
    while task.wait(0.15) do
        if featureStates.Bhop then
            for _, t in pairs(getgc(true)) do
                if type(t)=="table" and rawget(t,"Friction") then
                    pcall(function() t.Friction = -0.5 end)
                end
            end
        end
    end
end)

task.spawn(function()
    while task.wait() do
        if featureStates.Bhop then
            local char = player.Character
            if char and char:FindFirstChild("Humanoid") then
                local hum = char.Humanoid
                if hum:GetState() ~= Enum.HumanoidStateType.Jumping and hum:GetState() ~= Enum.HumanoidStateType.Freefall then
                    hum:ChangeState(Enum.HumanoidStateType.Jumping)
                end
            end
        end
    end
end)

task.spawn(function()
    while RunService.Heartbeat:Wait() do
        if featureStates.AutoCrouch then
            local char = player.Character
            if char and char:FindFirstChild("Humanoid") then
                local hum = char.Humanoid
                if hum.FloorMaterial == Enum.Material.Air then
                    hum.WalkSpeed = hum.WalkSpeed * 0.6
                end
            end
        end
    end
end)

-- Settings tab: Size button
Tabs.Settings:Section({ Title = "Window" })
Tabs.Settings:Button({
    Title = "loc:SIZE_BUTTON",
    Callback = function()
        Window:SetSize(UDim2.fromOffset(700,600))
    end
})

print("[Movement Hub Evade Lite] Loaded successfully.")
