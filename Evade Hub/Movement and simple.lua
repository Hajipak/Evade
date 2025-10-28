-- Evade Tester - Minimal Edition
-- Fitur: Strafe Acceleration, Jump Cap, Speed, ApplyMode, Bhop, Bounce, FullBright, Timer Display
-- + Pengaturan ukuran GUI (Width & Height) di tab Settings
-- + Load external script (Hajipak) diletakkan di akhir seperti Evade Test asli

if getgenv().EvadeMinimalExecuted then return end
getgenv().EvadeMinimalExecuted = true

-- Load WindUI
local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer

-- Default Settings
local settings = {
    Speed = "1500",
    JumpCap = "1",
    AirStrafeAcceleration = "187",
    ApplyMode = "Not Optimized",
    BhopEnabled = false,
    BounceEnabled = false,
    FullBright = false,
    TimerDisplay = false,
    GUIWidth = "200",
    GUIHeight = "30"
}

-- Config System
local HttpService = game:GetService("HttpService")
local configFile = "evade_minimal_config.txt"

local function saveSettings()
    pcall(function()
        writefile(configFile, HttpService:JSONEncode(settings))
    end)
end

local function loadSettings()
    if isfile and isfile(configFile) then
        local data = HttpService:JSONDecode(readfile(configFile))
        for k,v in pairs(data) do settings[k] = v end
    end
end

loadSettings()

-- WindUI Setup
WindUI.TransparencyValue = 0.2
WindUI:SetTheme("Dark")
local Window = WindUI:CreateWindow({
    Title = "Movement Hub Test",
    Icon = "rocket",
    Author = "Made by Zen",
    Size = UDim2.fromOffset(580, 420),
    Theme = "Dark",
    SideBarWidth = 200
})

Window:Tag({ Title = "v1.0", Color = Color3.fromHex("#30ff6a") })

-- Helper
local function pxToUDim2(w,h)
    return UDim2.fromOffset(tonumber(w) or 200, tonumber(h) or 30)
end

-- Config Table Finder
local requiredFields = {
    Friction = true, AirStrafeAcceleration = true, JumpHeight = true,
    RunDeaccel = true, JumpSpeedMultiplier = true, JumpCap = true,
    SprintCap = true, WalkSpeedMultiplier = true, BhopEnabled = true,
    Speed = true, AirAcceleration = true, RunAccel = true, SprintAcceleration = true
}

local function hasAllFields(tbl)
    if type(tbl) ~= "table" then return false end
    for field,_ in pairs(requiredFields) do
        if rawget(tbl, field) == nil then return false end
    end
    return true
end

local function getConfigTables()
    local list = {}
    for _,obj in ipairs(getgc(true)) do
        if type(obj) == "table" and hasAllFields(obj) then
            table.insert(list, obj)
        end
    end
    return list
end

local function applyToTables(func)
    local t = getConfigTables()
    if #t == 0 then return end
    for _,tbl in ipairs(t) do
        pcall(func, tbl)
    end
end

local function refreshAppliedSettings()
    applyToTables(function(t)
        t.Speed = tonumber(settings.Speed)
        t.JumpCap = tonumber(settings.JumpCap)
        t.AirStrafeAcceleration = tonumber(settings.AirStrafeAcceleration)
    end)
end

-- FullBright Logic
local original = {
    Brightness = Lighting.Brightness,
    FogEnd = Lighting.FogEnd,
    GlobalShadows = Lighting.GlobalShadows,
    Ambient = Lighting.Ambient,
    OutdoorAmbient = Lighting.OutdoorAmbient
}

local function setFullBright(on)
    if on then
        Lighting.Brightness = 2
        Lighting.FogEnd = 1e6
        Lighting.GlobalShadows = false
        Lighting.Ambient = Color3.new(1,1,1)
        Lighting.OutdoorAmbient = Color3.new(1,1,1)
    else
        for k,v in pairs(original) do Lighting[k] = v end
    end
end

-- Timer Display
local gui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
gui.Name = "EvadeTimer"
gui.ResetOnSpawn = false
local timer = Instance.new("TextLabel", gui)
timer.Size = UDim2.fromOffset(180,24)
timer.Position = UDim2.new(0.5,-90,0,10)
timer.BackgroundTransparency = 0.5
timer.BackgroundColor3 = Color3.fromRGB(30,30,30)
timer.TextColor3 = Color3.new(1,1,1)
timer.Font = Enum.Font.SourceSansBold
timer.TextSize = 14
timer.Visible = false

local startTime = tick()
local function updateTimer()
    if not settings.TimerDisplay then
        timer.Visible = false
        return
    end
    timer.Visible = true
    local e = math.floor(tick() - startTime)
    local h = math.floor(e / 3600)
    local m = math.floor((e % 3600) / 60)
    local s = e % 60
    timer.Text = string.format("Timer: %02d:%02d:%02d", h, m, s)
end

-- GUI untuk Bhop & Bounce
local function createGui(name, y)
    local sg = Instance.new("ScreenGui", player.PlayerGui)
    sg.Name = name.."Gui"
    local btn = Instance.new("TextButton", sg)
    btn.Size = pxToUDim2(settings.GUIWidth, settings.GUIHeight)
    btn.Position = UDim2.new(0,10,0,y)
    btn.BackgroundColor3 = Color3.fromRGB(45,45,45)
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Font = Enum.Font.SourceSans
    btn.TextSize = 16
    btn.Text = name..": OFF"

    btn.MouseButton1Click:Connect(function()
        if name == "Bhop" then
            settings.BhopEnabled = not settings.BhopEnabled
            btn.Text = name..": "..(settings.BhopEnabled and "ON" or "OFF")
        else
            settings.BounceEnabled = not settings.BounceEnabled
            btn.Text = name..": "..(settings.BounceEnabled and "ON" or "OFF")
        end
        saveSettings()
    end)
    return btn
end

local bhopBtn = createGui("Bhop", 50)
local bounceBtn = createGui("Bounce", 90)

-- Logic untuk Movement
local function isGrounded()
    local char = player.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    return workspace:Raycast(hrp.Position, Vector3.new(0,-3,0)) ~= nil
end

local bhopHolding = false
UserInputService.InputBegan:Connect(function(i,g)
    if g then return end
    if i.KeyCode == Enum.KeyCode.Space then bhopHolding = true end
end)
UserInputService.InputEnded:Connect(function(i,g)
    if g then return end
    if i.KeyCode == Enum.KeyCode.Space then bhopHolding = false end
end)

RunService.Heartbeat:Connect(function()
    refreshAppliedSettings()
    if settings.FullBright then setFullBright(true) end
    if settings.TimerDisplay then updateTimer() end

    local char = player.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then
        if settings.BhopEnabled and bhopHolding and hum.FloorMaterial ~= Enum.Material.Air then
            hum.Jump = true
        end
        if settings.BounceEnabled and not isGrounded() then
            hum.Jump = true
        end
    end
end)

-- Tabs
local Move = Window:CreateTab("Movement")
local Visual = Window:CreateTab("Visuals")
local Setting = Window:CreateTab("Settings")

-- Movement Tab
Move:CreateInput({Title="Speed", Text=settings.Speed}).OnChanged:Connect(function(v)
    settings.Speed=v saveSettings() refreshAppliedSettings()
end)
Move:CreateInput({Title="Jump Cap", Text=settings.JumpCap}).OnChanged:Connect(function(v)
    settings.JumpCap=v saveSettings() refreshAppliedSettings()
end)
Move:CreateInput({Title="Strafe Acceleration", Text=settings.AirStrafeAcceleration}).OnChanged:Connect(function(v)
    settings.AirStrafeAcceleration=v saveSettings() refreshAppliedSettings()
end)
Move:CreateDropdown({
    Title="ApplyMode",
    Options={"Not Optimized","Optimized"},
    Default=settings.ApplyMode
}).OnChanged:Connect(function(o)
    settings.ApplyMode=o saveSettings()
end)
Move:CreateToggle({Title="Bhop", Enabled=settings.BhopEnabled}).OnChanged:Connect(function(v)
    settings.BhopEnabled=v saveSettings()
    bhopBtn.Text="Bhop: "..(v and "ON" or "OFF")
end)
Move:CreateToggle({Title="Bounce", Enabled=settings.BounceEnabled}).OnChanged:Connect(function(v)
    settings.BounceEnabled=v saveSettings()
    bounceBtn.Text="Bounce: "..(v and "ON" or "OFF")
end)

-- Visual Tab
Visual:CreateToggle({Title="FullBright", Enabled=settings.FullBright}).OnChanged:Connect(function(v)
    settings.FullBright=v saveSettings() setFullBright(v)
end)
Visual:CreateToggle({Title="Timer Display", Enabled=settings.TimerDisplay}).OnChanged:Connect(function(v)
    settings.TimerDisplay=v saveSettings() timer.Visible=v
end)

-- Settings Tab
Setting:CreateInput({Title="GUI Width", Text=settings.GUIWidth}).OnChanged:Connect(function(v)
    settings.GUIWidth=v saveSettings()
    bhopBtn.Size = pxToUDim2(settings.GUIWidth, settings.GUIHeight)
    bounceBtn.Size = pxToUDim2(settings.GUIWidth, settings.GUIHeight)
end)
Setting:CreateInput({Title="GUI Height", Text=settings.GUIHeight}).OnChanged:Connect(function(v)
    settings.GUIHeight=v saveSettings()
    bhopBtn.Size = pxToUDim2(settings.GUIWidth, settings.GUIHeight)
    bounceBtn.Size = pxToUDim2(settings.GUIWidth, settings.GUIHeight)
end)
Setting:CreateButton({Title="Save Settings"}, function()
    saveSettings()
    WindUI:Notify({Title="Config", Content="Settings saved.", Duration=2})
end)
Setting:CreateButton({Title="Load Settings"}, function()
    loadSettings()
    WindUI:Notify({Title="Config", Content="Settings loaded.", Duration=2})
end)

-- ⬇️ Tambahan eksternal dari Hajipak (posisi sama seperti Evade Test)
loadstring(game:HttpGet("https://raw.githubusercontent.com/Hajipak/Evade/refs/heads/main/Script/More-loadstring.lua"))()

-- Notifikasi akhir
WindUI:Notify({Title="Evade Minimal", Content="Loaded minimal features + Hajipak script", Duration=3})
