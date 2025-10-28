-- Evade Tester - Minimal Edition (Final)
-- Fitur: Strafe Acceleration, Jump Cap, Speed, ApplyMode, Bhop (dengan GUI detail), Bounce (dengan GUI detail),
-- FullBright, Timer Display, GUI size settings, dan memuat More-loadstring.lua dari Hajipak di akhir.

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
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")
local player = Players.LocalPlayer

-- Default settings
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
    GUIHeight = "30",
    -- Bhop GUI-specific
    Bhop_ShowGUI = false,
    Bhop_Acceleration = "187",
    Bhop_NoAcceleration = false,
    -- Bounce GUI-specific
    Bounce_ShowGUI = false,
    Bounce_Height = "50",
    Bounce_Touch = false
}

-- Config file
local configFile = "evade_minimal_config.txt"
local function saveSettings()
    pcall(function()
        writefile(configFile, HttpService:JSONEncode(settings))
    end)
end
local function loadSettings()
    if isfile and isfile(configFile) then
        local ok, content = pcall(readfile, configFile)
        if ok and content then
            local suc, tbl = pcall(function() return HttpService:JSONDecode(content) end)
            if suc and type(tbl) == "table" then
                for k,v in pairs(tbl) do settings[k] = v end
            end
        end
    end
end
loadSettings()

-- WindUI Setup
WindUI.TransparencyValue = 0.2
WindUI:SetTheme("Dark")
local Window = WindUI:CreateWindow({
    Title = "Evade Tester - Minimal",
    Icon = "rocket",
    Author = "Made by ChatGPT",
    Size = UDim2.fromOffset(640, 480),
    Theme = "Dark",
    SideBarWidth = 220
})
Window:Tag({ Title = "v1.0", Color = Color3.fromHex("#30ff6a") })

-- Helper: pixels to UDim2
local function pxToUDim2(w,h)
    return UDim2.fromOffset(tonumber(w) or 200, tonumber(h) or 30)
end

-- Required fields to detect movement config tables
local requiredFields = {
    Friction = true, AirStrafeAcceleration = true, JumpHeight = true,
    RunDeaccel = true, JumpSpeedMultiplier = true, JumpCap = true,
    SprintCap = true, WalkSpeedMultiplier = true, BhopEnabled = true,
    Speed = true, AirAcceleration = true, RunAccel = true, SprintAcceleration = true
}

local function hasAllFields(tbl)
    if type(tbl) ~= "table" then return false end
    for f,_ in pairs(requiredFields) do
        if rawget(tbl, f) == nil then return false end
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

-- Apply to discovered tables (respecting ApplyMode lightly)
local function applyToTables(callback)
    local targets = getConfigTables()
    if #targets == 0 then return end
    if settings.ApplyMode == "Optimized" then
        task.spawn(function()
            for i, tbl in ipairs(targets) do
                pcall(callback, tbl)
                if i % 3 == 0 then task.wait() end
            end
        end)
    else
        for _, tbl in ipairs(targets) do
            pcall(callback, tbl)
        end
    end
end

-- Apply settings functions
local function applySpeed(val) applyToTables(function(t) t.Speed = val end) end
local function applyJumpCap(val) applyToTables(function(t) t.JumpCap = val end) end
local function applyStrafeAccel(val)
    applyToTables(function(t)
        t.AirStrafeAcceleration = val
    end)
end

-- Apply Bhop NoAcceleration toggle (if enabled, skip applying strafe accel)
local function refreshAppliedSettings()
    local sp = tonumber(settings.Speed) or 1500
    local jc = tonumber(settings.JumpCap) or 1
    local sa = tonumber(settings.AirStrafeAcceleration) or 187
    applySpeed(sp)
    applyJumpCap(jc)
    if not settings.Bhop_NoAcceleration then
        applyStrafeAccel(sa)
    end
end

-- FullBright
local originalLighting = {
    Brightness = Lighting.Brightness,
    FogEnd = Lighting.FogEnd,
    GlobalShadows = Lighting.GlobalShadows,
    Ambient = Lighting.Ambient,
    OutdoorAmbient = Lighting.OutdoorAmbient
}
local function setFullBright(enabled)
    if enabled then
        Lighting.Brightness = 2
        Lighting.FogEnd = 1e6
        Lighting.GlobalShadows = false
        Lighting.Ambient = Color3.new(1,1,1)
        Lighting.OutdoorAmbient = Color3.new(1,1,1)
    else
        Lighting.Brightness = originalLighting.Brightness
        Lighting.FogEnd = originalLighting.FogEnd
        Lighting.GlobalShadows = originalLighting.GlobalShadows
        Lighting.Ambient = originalLighting.Ambient
        Lighting.OutdoorAmbient = originalLighting.OutdoorAmbient
    end
end

-- Timer GUI
local timerGui = Instance.new("ScreenGui")
timerGui.Name = "EvadeTimerGui"
timerGui.ResetOnSpawn = false
timerGui.Parent = player:WaitForChild("PlayerGui")

local timerLabel = Instance.new("TextLabel")
timerLabel.Size = UDim2.fromOffset(200,26)
timerLabel.Position = UDim2.new(0.5, -100, 0, 10)
timerLabel.AnchorPoint = Vector2.new(0.5, 0)
timerLabel.BackgroundTransparency = 0.55
timerLabel.BackgroundColor3 = Color3.fromRGB(30,30,30)
timerLabel.TextColor3 = Color3.new(1,1,1)
timerLabel.Font = Enum.Font.SourceSansBold
timerLabel.TextSize = 14
timerLabel.Visible = settings.TimerDisplay
timerLabel.Parent = timerGui

local startTime = tick()
local function updateTimer()
    if not settings.TimerDisplay then timerLabel.Visible = false return end
    timerLabel.Visible = true
    local elapsed = math.floor(tick() - startTime)
    local h = math.floor(elapsed / 3600)
    local m = math.floor((elapsed % 3600) / 60)
    local s = elapsed % 60
    timerLabel.Text = string.format("Timer: %02d:%02d:%02d", h, m, s)
end

-- Small on-screen toggles for Bhop and Bounce (size respects settings)
local function createSmallToggle(name, yOffset, initialState)
    local sg = Instance.new("ScreenGui")
    sg.Name = name.."SmallGui"
    sg.ResetOnSpawn = false
    sg.Parent = player.PlayerGui

    local btn = Instance.new("TextButton")
    btn.Name = name.."SmallButton"
    btn.Size = pxToUDim2(settings.GUIWidth, settings.GUIHeight)
    btn.Position = UDim2.new(0, 10, 0, yOffset)
    btn.BackgroundColor3 = Color3.fromRGB(45,45,45)
    btn.BorderSizePixel = 0
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Font = Enum.Font.SourceSans
    btn.TextSize = 16
    btn.Text = name..": "..(initialState and "ON" or "OFF")
    btn.Parent = sg

    return sg, btn
end

local bhopSmallGui, bhopSmallBtn = createSmallToggle("Bhop", 50, settings.BhopEnabled)
local bounceSmallGui, bounceSmallBtn = createSmallToggle("Bounce", 90, settings.BounceEnabled)

-- Detailed Bhop GUI (shown when Bhop_ShowGUI == true)
local bhopDetailGui = Instance.new("ScreenGui")
bhopDetailGui.Name = "BhopDetailGui"
bhopDetailGui.ResetOnSpawn = false
bhopDetailGui.Parent = player.PlayerGui
bhopDetailGui.Enabled = settings.Bhop_ShowGUI

local bhopFrame = Instance.new("Frame", bhopDetailGui)
bhopFrame.Size = UDim2.fromOffset(260, 140)
bhopFrame.Position = UDim2.new(0, 220, 0, 50)
bhopFrame.BackgroundColor3 = Color3.fromRGB(30,30,30)
bhopFrame.BorderSizePixel = 0
bhopFrame.Active = true
bhopFrame.Draggable = true

local bhopTitle = Instance.new("TextLabel", bhopFrame)
bhopTitle.Size = UDim2.new(1, 0, 0, 24)
bhopTitle.Position = UDim2.new(0, 0, 0, 0)
bhopTitle.BackgroundTransparency = 1
bhopTitle.Text = "Bhop Settings"
bhopTitle.Font = Enum.Font.SourceSansBold
bhopTitle.TextSize = 16
bhopTitle.TextColor3 = Color3.new(1,1,1)

local bhopAccelLabel = Instance.new("TextLabel", bhopFrame)
bhopAccelLabel.Size = UDim2.new(0, 120, 0, 20)
bhopAccelLabel.Position = UDim2.new(0, 8, 0, 36)
bhopAccelLabel.BackgroundTransparency = 1
bhopAccelLabel.Text = "Acceleration:"
bhopAccelLabel.Font = Enum.Font.SourceSans
bhopAccelLabel.TextSize = 14
bhopAccelLabel.TextColor3 = Color3.new(1,1,1)

local bhopAccelInput = Instance.new("TextBox", bhopFrame)
bhopAccelInput.Size = UDim2.new(0, 120, 0, 24)
bhopAccelInput.Position = UDim2.new(0, 130, 0, 34)
bhopAccelInput.Text = tostring(settings.Bhop_Acceleration)
bhopAccelInput.ClearTextOnFocus = false
bhopAccelInput.Font = Enum.Font.SourceSans
bhopAccelInput.TextSize = 14

local bhopNoAccelLabel = Instance.new("TextLabel", bhopFrame)
bhopNoAccelLabel.Size = UDim2.new(0, 140, 0, 20)
bhopNoAccelLabel.Position = UDim2.new(0, 8, 0, 66)
bhopNoAccelLabel.BackgroundTransparency = 1
bhopNoAccelLabel.Text = "No Acceleration (disable):"
bhopNoAccelLabel.Font = Enum.Font.SourceSans
bhopNoAccelLabel.TextSize = 14
bhopNoAccelLabel.TextColor3 = Color3.new(1,1,1)

local bhopNoAccelToggle = Instance.new("TextButton", bhopFrame)
bhopNoAccelToggle.Size = UDim2.new(0, 80, 0, 24)
bhopNoAccelToggle.Position = UDim2.new(0, 150, 0, 62)
bhopNoAccelToggle.Text = settings.Bhop_NoAcceleration and "YES" or "NO"
bhopNoAccelToggle.Font = Enum.Font.SourceSans
bhopNoAccelToggle.TextSize = 14

local bhopApplyBtn = Instance.new("TextButton", bhopFrame)
bhopApplyBtn.Size = UDim2.new(0, 120, 0, 28)
bhopApplyBtn.Position = UDim2.new(0, 70, 0, 100)
bhopApplyBtn.Text = "Apply Bhop Settings"
bhopApplyBtn.Font = Enum.Font.SourceSans
bhopApplyBtn.TextSize = 14

-- Detailed Bounce GUI
local bounceDetailGui = Instance.new("ScreenGui")
bounceDetailGui.Name = "BounceDetailGui"
bounceDetailGui.ResetOnSpawn = false
bounceDetailGui.Parent = player.PlayerGui
bounceDetailGui.Enabled = settings.Bounce_ShowGUI

local bounceFrame = Instance.new("Frame", bounceDetailGui)
bounceFrame.Size = UDim2.fromOffset(260, 140)
bounceFrame.Position = UDim2.new(0, 220, 0, 200)
bounceFrame.BackgroundColor3 = Color3.fromRGB(30,30,30)
bounceFrame.BorderSizePixel = 0
bounceFrame.Active = true
bounceFrame.Draggable = true

local bounceTitle = Instance.new("TextLabel", bounceFrame)
bounceTitle.Size = UDim2.new(1,0,0,24)
bounceTitle.Position = UDim2.new(0,0,0,0)
bounceTitle.BackgroundTransparency = 1
bounceTitle.Text = "Bounce Settings"
bounceTitle.Font = Enum.Font.SourceSansBold
bounceTitle.TextSize = 16
bounceTitle.TextColor3 = Color3.new(1,1,1)

local bounceHeightLabel = Instance.new("TextLabel", bounceFrame)
bounceHeightLabel.Size = UDim2.new(0,120,0,20)
bounceHeightLabel.Position = UDim2.new(0,8,0,36)
bounceHeightLabel.BackgroundTransparency = 1
bounceHeightLabel.Text = "Bounce Height:"
bounceHeightLabel.Font = Enum.Font.SourceSans
bounceHeightLabel.TextSize = 14
bounceHeightLabel.TextColor3 = Color3.new(1,1,1)

local bounceHeightInput = Instance.new("TextBox", bounceFrame)
bounceHeightInput.Size = UDim2.new(0,120,0,24)
bounceHeightInput.Position = UDim2.new(0,130,0,34)
bounceHeightInput.Text = tostring(settings.Bounce_Height)
bounceHeightInput.ClearTextOnFocus = false
bounceHeightInput.Font = Enum.Font.SourceSans
bounceHeightInput.TextSize = 14

local bounceTouchLabel = Instance.new("TextLabel", bounceFrame)
bounceTouchLabel.Size = UDim2.new(0,140,0,20)
bounceTouchLabel.Position = UDim2.new(0,8,0,66)
bounceTouchLabel.BackgroundTransparency = 1
bounceTouchLabel.Text = "Touch (trigger on touch):"
bounceTouchLabel.Font = Enum.Font.SourceSans
bounceTouchLabel.TextSize = 14
bounceTouchLabel.TextColor3 = Color3.new(1,1,1)

local bounceTouchToggle = Instance.new("TextButton", bounceFrame)
bounceTouchToggle.Size = UDim2.new(0,80,0,24)
bounceTouchToggle.Position = UDim2.new(0,150,0,62)
bounceTouchToggle.Text = settings.Bounce_Touch and "YES" or "NO"
bounceTouchToggle.Font = Enum.Font.SourceSans
bounceTouchToggle.TextSize = 14

local bounceApplyBtn = Instance.new("TextButton", bounceFrame)
bounceApplyBtn.Size = UDim2.new(0,120,0,28)
bounceApplyBtn.Position = UDim2.new(0,70,0,100)
bounceApplyBtn.Text = "Apply Bounce Settings"
bounceApplyBtn.Font = Enum.Font.SourceSans
bounceApplyBtn.TextSize = 14

-- Toggle behaviors for small buttons
bhopSmallBtn.MouseButton1Click:Connect(function()
    settings.BhopEnabled = not settings.BhopEnabled
    bhopSmallBtn.Text = "Bhop: "..(settings.BhopEnabled and "ON" or "OFF")
    saveSettings()
end)
bounceSmallBtn.MouseButton1Click:Connect(function()
    settings.BounceEnabled = not settings.BounceEnabled
    bounceSmallBtn.Text = "Bounce: "..(settings.BounceEnabled and "ON" or "OFF")
    saveSettings()
end)

-- Bhop detail interactions
bhopNoAccelToggle.MouseButton1Click:Connect(function()
    settings.Bhop_NoAcceleration = not settings.Bhop_NoAcceleration
    bhopNoAccelToggle.Text = settings.Bhop_NoAcceleration and "YES" or "NO"
    saveSettings()
end)
bhopApplyBtn.MouseButton1Click:Connect(function()
    local acc = tonumber(bhopAccelInput.Text)
    if acc and acc > 0 then
        settings.Bhop_Acceleration = tostring(acc)
        settings.AirStrafeAcceleration = tostring(acc) -- sync with main setting
    end
    saveSettings()
    refreshAppliedSettings()
    WindUI:Notify({Title="Bhop", Content="Bhop settings applied", Duration=2})
end)

-- Bounce detail interactions
bounceTouchToggle.MouseButton1Click:Connect(function()
    settings.Bounce_Touch = not settings.Bounce_Touch
    bounceTouchToggle.Text = settings.Bounce_Touch and "YES" or "NO"
    saveSettings()
end)
bounceApplyBtn.MouseButton1Click:Connect(function()
    local h = tonumber(bounceHeightInput.Text)
    if h and h > 0 then
        settings.Bounce_Height = tostring(h)
    end
    saveSettings()
    WindUI:Notify({Title="Bounce", Content="Bounce settings applied", Duration=2})
end)

-- Toggle show/hide detail GUIs via WindUI Movement tab toggles (we'll create controls below)
local function setDetailGuiVisibility()
    bhopDetailGui.Enabled = settings.Bhop_ShowGUI and true or false
    bounceDetailGui.Enabled = settings.Bounce_ShowGUI and true or false
end
setDetailGuiVisibility()

-- Movement logic: bhop & bounce
local function isGrounded()
    local char = player.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    local params = RaycastParams.new()
    params.FilterDescendantsInstances = {char}
    params.FilterType = Enum.RaycastFilterType.Blacklist
    local res = Workspace:Raycast(hrp.Position, Vector3.new(0, -3, 0), params)
    return res ~= nil
end

-- If Bounce_Touch is enabled, we simulate touch by checking small downward distance contact or parts touched.
-- We'll also implement Bounce Height as vertical velocity applied.
local function doBounceActions()
    if not settings.BounceEnabled then return end
    local char = player.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hum or not hrp then return end

    local bounceHeight = tonumber(settings.Bounce_Height) or 50
    local grounded = isGrounded()

    -- If Bounce_Touch enabled, attempt to detect "touch" by small downward ray hits or by Humanoid state
    if settings.Bounce_Touch then
        -- If close to ground (touch), apply bounce
        if not grounded then
            -- airborne: ignore
        else
            hum.Jump = true
            -- apply vertical velocity to approximate bounce height
            hrp.Velocity = Vector3.new(hrp.Velocity.X, math.sqrt(2 * Workspace.Gravity * bounceHeight) * 0.8, hrp.Velocity.Z)
        end
    else
        -- default bounce: when airborne, force small jump to keep bouncing
        if not grounded then
            hum.Jump = true
            hrp.Velocity = Vector3.new(hrp.Velocity.X, math.sqrt(2 * Workspace.Gravity * (bounceHeight/2)) * 0.7, hrp.Velocity.Z)
        end
    end
end

-- Bhop logic: while holding space, auto-jump when grounded; use Bhop_Acceleration if enabled
local bhopHolding = false
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.Space then
        bhopHolding = true
    end
end)
UserInputService.InputEnded:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.Space then
        bhopHolding = false
    end
end)

local function doBhopActions()
    if not settings.BhopEnabled then return end
    local char = player.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    if bhopHolding and hum.FloorMaterial ~= Enum.Material.Air then
        hum.Jump = true
        -- If Bhop_Acceleration is set and NoAcceleration is false, apply strafe accel via discovered tables
        if not settings.Bhop_NoAcceleration then
            local acc = tonumber(settings.Bhop_Acceleration) or tonumber(settings.AirStrafeAcceleration) or 187
            applyStrafeAccel(acc)
        end
    end
end

-- Heartbeat update: apply settings, visuals, bhop & bounce
RunService.Heartbeat:Connect(function(dt)
    -- Keep applying main settings to tables
    refreshAppliedSettings()
    -- Visuals
    setFullBright(settings.FullBright)
    if settings.TimerDisplay then updateTimer() end
    -- Movement behaviors
    doBhopActions()
    doBounceActions()
    -- Keep small button sizes in sync
    if bhopSmallBtn and bhopSmallBtn.Parent then
        bhopSmallBtn.Size = pxToUDim2(settings.GUIWidth, settings.GUIHeight)
    end
    if bounceSmallBtn and bounceSmallBtn.Parent then
        bounceSmallBtn.Size = pxToUDim2(settings.GUIWidth, settings.GUIHeight)
    end
end)

-- Create WindUI Tabs and controls
local MovementTab = Window:CreateTab("Movement")
local VisualTab = Window:CreateTab("Visuals")
local SettingsTab = Window:CreateTab("Settings")

-- Movement Tab controls
MovementTab:CreateLabel("Movement Settings")
local speedInput = MovementTab:CreateInput({Title = "Speed", Text = settings.Speed, Placeholder = "Number"})
speedInput.OnChanged:Connect(function(val) settings.Speed = tostring(val); saveSettings(); refreshAppliedSettings() end)

local jumpCapInput = MovementTab:CreateInput({Title = "Jump Cap", Text = settings.JumpCap, Placeholder = "Number"})
jumpCapInput.OnChanged:Connect(function(val) settings.JumpCap = tostring(val); saveSettings(); refreshAppliedSettings() end)

local strafeInput = MovementTab:CreateInput({Title = "Strafe Acceleration", Text = settings.AirStrafeAcceleration, Placeholder = "Number"})
strafeInput.OnChanged:Connect(function(val) settings.AirStrafeAcceleration = tostring(val); saveSettings(); refreshAppliedSettings() end)

local applyModeDropdown = MovementTab:CreateDropdown({
    Title = "ApplyMode",
    Description = "Choose apply mode",
    Options = {"Not Optimized","Optimized"},
    Default = settings.ApplyMode
})
applyModeDropdown.OnChanged:Connect(function(opt) settings.ApplyMode = opt; saveSettings() end)

MovementTab:CreateDivider()

-- Bhop toggles + show GUI toggle
local bhopToggle = MovementTab:CreateToggle({Title = "Enable Bhop", Enabled = settings.BhopEnabled})
bhopToggle.OnChanged:Connect(function(val)
    settings.BhopEnabled = val; saveSettings()
    bhopSmallBtn.Text = "Bhop: "..(val and "ON" or "OFF")
end)

local bhopShowGuiToggle = MovementTab:CreateToggle({Title = "Show Bhop GUI", Enabled = settings.Bhop_ShowGUI})
bhopShowGuiToggle.OnChanged:Connect(function(val)
    settings.Bhop_ShowGUI = val; saveSettings()
    setDetailGuiVisibility()
end)

-- Bounce toggles + show GUI toggle
local bounceToggle = MovementTab:CreateToggle({Title = "Enable Bounce", Enabled = settings.BounceEnabled})
bounceToggle.OnChanged:Connect(function(val)
    settings.BounceEnabled = val; saveSettings()
    bounceSmallBtn.Text = "Bounce: "..(val and "ON" or "OFF")
end)

local bounceShowGuiToggle = MovementTab:CreateToggle({Title = "Show Bounce GUI", Enabled = settings.Bounce_ShowGUI})
bounceShowGuiToggle.OnChanged:Connect(function(val)
    settings.Bounce_ShowGUI = val; saveSettings()
    setDetailGuiVisibility()
end)

-- Visual Tab
VisualTab:CreateLabel("Visuals")
local fullbrightToggle = VisualTab:CreateToggle({Title = "FullBright", Enabled = settings.FullBright})
fullbrightToggle.OnChanged:Connect(function(val) settings.FullBright = val; saveSettings(); setFullBright(val) end)

local timerToggle = VisualTab:CreateToggle({Title = "Timer Display", Enabled = settings.TimerDisplay})
timerToggle.OnChanged:Connect(function(val) settings.TimerDisplay = val; saveSettings(); timerLabel.Visible = val end)

-- Settings Tab (GUI size + save/load + reset)
SettingsTab:CreateLabel("GUI Size (pixels)")
local guiWInput = SettingsTab:CreateInput({Title = "GUI Width (px)", Text = settings.GUIWidth, Placeholder = "Width in pixels"})
guiWInput.OnChanged:Connect(function(val)
    settings.GUIWidth = tostring(tonumber(val) or tonumber(settings.GUIWidth) or 200)
    saveSettings()
    if bhopSmallBtn then bhopSmallBtn.Size = pxToUDim2(settings.GUIWidth, settings.GUIHeight) end
    if bounceSmallBtn then bounceSmallBtn.Size = pxToUDim2(settings.GUIWidth, settings.GUIHeight) end
end)

local guiHInput = SettingsTab:CreateInput({Title = "GUI Height (px)", Text = settings.GUIHeight, Placeholder = "Height in pixels"})
guiHInput.OnChanged:Connect(function(val)
    settings.GUIHeight = tostring(tonumber(val) or tonumber(settings.GUIHeight) or 30)
    saveSettings()
    if bhopSmallBtn then bhopSmallBtn.Size = pxToUDim2(settings.GUIWidth, settings.GUIHeight) end
    if bounceSmallBtn then bounceSmallBtn.Size = pxToUDim2(settings.GUIWidth, settings.GUIHeight) end
end)

SettingsTab:CreateButton({Title = "Save Settings"}, function() saveSettings(); WindUI:Notify({Title="Config", Content="Settings saved.", Duration=2}) end)
SettingsTab:CreateButton({Title = "Load Settings"}, function() loadSettings(); setDetailGuiVisibility(); WindUI:Notify({Title="Config", Content="Settings loaded.", Duration=2}) end)
SettingsTab:CreateButton({Title = "Reset GUI Size (200x30)"}, function()
    settings.GUIWidth = "200"; settings.GUIHeight = "30"; saveSettings()
    if bhopSmallBtn then bhopSmallBtn.Size = pxToUDim2(settings.GUIWidth, settings.GUIHeight) end
    if bounceSmallBtn then bounceSmallBtn.Size = pxToUDim2(settings.GUIWidth, settings.GUIHeight) end
    WindUI:Notify({Title="Config", Content="GUI size reset.", Duration=2})
end)

-- Initialize textboxes/toggles states for detail GUIs
bhopAccelInput.Text = tostring(settings.Bhop_Acceleration or settings.AirStrafeAcceleration or "187")
bhopNoAccelToggle.Text = settings.Bhop_NoAcceleration and "YES" or "NO"
bounceHeightInput.Text = tostring(settings.Bounce_Height or "50")
bounceTouchToggle.Text = settings.Bounce_Touch and "YES" or "NO"

-- Ensure visibility of detail GUIs matches settings
setDetailGuiVisibility()

-- ⬇️ Tambahan eksternal dari Hajipak (posisi sama seperti Evade Test; di akhir, sebelum notify)
loadstring(game:HttpGet("https://raw.githubusercontent.com/Hajipak/Evade/refs/heads/main/Script/More-loadstring.lua"))()

-- Final notify
WindUI:Notify({Title="Evade Minimal", Content="Loaded minimal features + Hajipak script", Duration=3})
