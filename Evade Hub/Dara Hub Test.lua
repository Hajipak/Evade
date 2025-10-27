-- Movement Hub (Dara Hub style, full)
-- Single Tab: "Movement Hub"
-- Sections: Movement Settings, Physics, Automation, Settings (with utility buttons)
-- Features: Speed, Strafe Acceleration, Jump Cap, ApplyMode, Gravity, Auto Crouch, Bhop, AutoCarry
-- Extra Buttons in Settings: Apply Settings, Reset to Default, Rejoin Server, Respawn Character, Fly Toggle
-- No prints/logs. Defensive pcall usage.

-- WindUI loader (pcall safe)
local ok, WindUI = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()
end)
if not ok or not WindUI then return end

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local Workspace = game:GetService("Workspace")
local TeleportService = game:GetService("TeleportService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Player / Character refs
local LocalPlayer = Players.LocalPlayer
local character, humanoid, rootPart
local function updateCharacterRefs()
    character = LocalPlayer.Character
    if character then
        humanoid = character:FindFirstChildOfClass("Humanoid")
        rootPart = character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Torso") or character:FindFirstChild("UpperTorso")
    else
        humanoid = nil
        rootPart = nil
    end
end
updateCharacterRefs()
LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(0.05)
    updateCharacterRefs()
end)
LocalPlayer.CharacterRemoving:Connect(function() character = nil humanoid = nil rootPart = nil end)

-- Config and defaults
local configFileName = "movement_hub_config.txt"
local defaultSettings = {
    Speed = 1500,
    AirStrafeAcceleration = 187,
    JumpCap = 1,
    ApplyMode = "Not Optimized", -- or "Optimized"
    Gravity = Workspace.Gravity or 196.2,
    AutoCrouch = false,
    Bhop = false,
    AutoCarry = false,
    FlySpeed = 100
}
local currentSettings = {}
for k,v in pairs(defaultSettings) do currentSettings[k] = v end

-- Save / Load config
local function saveConfig()
    pcall(function()
        writefile(configFileName, HttpService:JSONEncode(currentSettings))
    end)
end

local function loadConfig()
    if not isfile(configFileName) then return end
    local ok, content = pcall(function() return readfile(configFileName) end)
    if not ok or not content then return end
    local suc, decoded = pcall(function() return HttpService:JSONDecode(content) end)
    if suc and type(decoded) == "table" then
        for k,v in pairs(decoded) do currentSettings[k] = v end
    end
end

-- Helpers: find in-memory config tables (getgc) & apply
local function getConfigTables()
    local out = {}
    local success, gc = pcall(function() return getgc(true) end)
    if not success or type(gc) ~= "table" then return out end
    for _, obj in ipairs(gc) do
        local ok, cond = pcall(function()
            return type(obj) == "table" and rawget(obj, "Speed") ~= nil and rawget(obj, "JumpCap") ~= nil
        end)
        if ok and cond then
            table.insert(out, obj)
        end
    end
    return out
end

local function applyToTables(callback)
    local targets = getConfigTables()
    if #targets == 0 then return end
    if currentSettings.ApplyMode == "Optimized" then
        task.spawn(function()
            for i,tbl in ipairs(targets) do
                pcall(callback, tbl)
                if i % 3 == 0 then task.wait() end
            end
        end)
    else
        for i,tbl in ipairs(targets) do
            pcall(callback, tbl)
        end
    end
end

-- Mappings (fallback to humanoid)
local function mapSpeedToWalkSpeed(spd)
    local num = tonumber(spd) or defaultSettings.Speed
    local mapped = num / 100
    if mapped < 8 then mapped = 8 end
    if mapped > 500 then mapped = 500 end
    return mapped
end
local function mapJumpCapToJumpPower(jc)
    local cap = tonumber(jc) or defaultSettings.JumpCap
    local power = 50 + (cap - 1) * 10
    if power < 50 then power = 50 end
    if power > 500 then power = 500 end
    return power
end

-- Apply all movement settings
local function applyMovementSettings()
    -- apply to found tables
    applyToTables(function(tbl)
        if currentSettings.Speed ~= nil then tbl.Speed = tonumber(currentSettings.Speed) or tbl.Speed end
        if currentSettings.JumpCap ~= nil then tbl.JumpCap = tonumber(currentSettings.JumpCap) or tbl.JumpCap end
        if currentSettings.AirStrafeAcceleration ~= nil then tbl.AirStrafeAcceleration = tonumber(currentSettings.AirStrafeAcceleration) or tbl.AirStrafeAcceleration end
    end)
    -- gravity
    pcall(function() Workspace.Gravity = tonumber(currentSettings.Gravity) or Workspace.Gravity end)
    -- humanoid fallback
    if humanoid then
        pcall(function()
            humanoid.WalkSpeed = mapSpeedToWalkSpeed(currentSettings.Speed)
            if rawget(humanoid, "JumpPower") ~= nil then
                humanoid.JumpPower = mapJumpCapToJumpPower(currentSettings.JumpCap)
            elseif rawget(humanoid, "JumpHeight") ~= nil then
                humanoid.JumpHeight = mapJumpCapToJumpPower(currentSettings.JumpCap) / 10
            end
        end)
    end
end

-- Init
loadConfig()
applyMovementSettings()

-- JumpCap logic (multi-jump)
local jumpCount = 0
local lastGrounded = true
local function isGrounded()
    if not rootPart then return true end
    local params = RaycastParams.new()
    params.FilterDescendantsInstances = {character}
    params.FilterType = Enum.RaycastFilterType.Blacklist
    local res = Workspace:Raycast(rootPart.Position, Vector3.new(0, -3, 0), params)
    return res ~= nil
end

UserInputService.JumpRequest:Connect(function()
    if not humanoid then return end
    local grounded = isGrounded()
    if grounded then jumpCount = 0 end
    local maxJumps = math.max(1, tonumber(currentSettings.JumpCap) or 1)
    if jumpCount < maxJumps then
        jumpCount = jumpCount + 1
        pcall(function()
            humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            if not grounded and rootPart then
                rootPart.Velocity = Vector3.new(rootPart.Velocity.X, mapJumpCapToJumpPower(currentSettings.JumpCap) * 0.7, rootPart.Velocity.Z)
            end
        end)
    end
end)

RunService.Heartbeat:Connect(function()
    if humanoid then
        local grounded = isGrounded()
        if grounded and not lastGrounded then
            jumpCount = 0
        end
        lastGrounded = grounded
    end
end)

-- Bhop handling (space hold)
local bhopHold = false
UserInputService.InputBegan:Connect(function(inp, gp)
    if gp then return end
    if inp.UserInputType == Enum.UserInputType.Keyboard and inp.KeyCode == Enum.KeyCode.Space then
        bhopHold = true
    end
end)
UserInputService.InputEnded:Connect(function(inp, gp)
    if gp then return end
    if inp.UserInputType == Enum.UserInputType.Keyboard and inp.KeyCode == Enum.KeyCode.Space then
        bhopHold = false
    end
end)

-- Air strafe: apply lateral acceleration when airborne
local function applyAirStrafe(dt)
    if not rootPart or not humanoid then return end
    if isGrounded() then return end
    local moveDir = humanoid.MoveDirection
    if moveDir.Magnitude <= 0 then return end
    local accel = tonumber(currentSettings.AirStrafeAcceleration) or defaultSettings.AirStrafeAcceleration
    local cam = workspace.CurrentCamera
    if not cam then return end
    local desired = (cam.CFrame:VectorToWorldSpace(moveDir)).Unit
    if desired.Magnitude == 0 then return end
    local add = desired * (accel * dt * 0.6)
    rootPart.Velocity = Vector3.new(rootPart.Velocity.X + add.X, rootPart.Velocity.Y, rootPart.Velocity.Z + add.Z)
end

-- AutoCrouch logic (simulate by HipHeight & WalkSpeed)
local crouched = false
local originalHipHeight = nil
local function setCrouch(state)
    if not humanoid then return end
    if originalHipHeight == nil and humanoid then originalHipHeight = humanoid.HipHeight end
    if state and not crouched then
        crouched = true
        pcall(function()
            humanoid.HipHeight = (originalHipHeight or 2) * 0.6
            humanoid.WalkSpeed = (humanoid.WalkSpeed or 16) * 0.6
        end)
    elseif not state and crouched then
        crouched = false
        pcall(function()
            humanoid.HipHeight = originalHipHeight or humanoid.HipHeight
            humanoid.WalkSpeed = mapSpeedToWalkSpeed(currentSettings.Speed)
        end)
    end
end

-- AutoCarry (best-effort) - tries ReplicatedStorage.Events.Character.Interact
local interactEvent = nil
pcall(function()
    if ReplicatedStorage:FindFirstChild("Events") and ReplicatedStorage.Events:FindFirstChild("Character") and ReplicatedStorage.Events.Character:FindFirstChild("Interact") then
        interactEvent = ReplicatedStorage.Events.Character.Interact
    end
end)

local function findNearestCarryTarget(range)
    range = range or 6
    local nearest, nd = nil, math.huge
    if Workspace:FindFirstChild("Game") and Workspace.Game:FindFirstChild("Players") then
        for _, m in ipairs(Workspace.Game.Players:GetChildren()) do
            if m:IsA("Model") and m ~= character and m:FindFirstChild("HumanoidRootPart") then
                local hrp = m.HumanoidRootPart
                local dist = (hrp.Position - (rootPart and rootPart.Position or Vector3.new())).Magnitude
                if dist < nd and dist <= range then nearest, nd = m, dist end
            end
        end
    end
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and obj:FindFirstChild("HumanoidRootPart") then
            local hrp = obj.HumanoidRootPart
            local dist = (hrp.Position - (rootPart and rootPart.Position or Vector3.new())).Magnitude
            if dist < nd and dist <= range then nearest, nd = obj, dist end
        end
    end
    return nearest
end

local autoCarryRunning = false
local function autoCarryLoop()
    if autoCarryRunning then return end
    autoCarryRunning = true
    while currentSettings.AutoCarry do
        if rootPart and interactEvent then
            local tgt = findNearestCarryTarget(6)
            if tgt then
                pcall(function()
                    interactEvent:FireServer(tgt)
                end)
            end
        end
        task.wait(0.6)
    end
    autoCarryRunning = false
end

-- Fly (basic noclip + velocity controlled)
local flyEnabled = false
local flyConnection = nil
local flySpeed = tonumber(currentSettings.FlySpeed) or defaultSettings.FlySpeed
local function enableFly()
    if flyEnabled then return end
    flyEnabled = true
    if humanoid then
        pcall(function() humanoid.PlatformStand = true end)
    end
    flyConnection = RunService.RenderStepped:Connect(function(dt)
        if not rootPart or not flyEnabled then return end
        local cam = workspace.CurrentCamera
        if not cam then return end
        local forward = (UserInputService:IsKeyDown(Enum.KeyCode.W) and 1 or 0) - (UserInputService:IsKeyDown(Enum.KeyCode.S) and 1 or 0)
        local right = (UserInputService:IsKeyDown(Enum.KeyCode.D) and 1 or 0) - (UserInputService:IsKeyDown(Enum.KeyCode.A) and 1 or 0)
        local up = (UserInputService:IsKeyDown(Enum.KeyCode.Space) and 1 or 0) - (UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) and 1 or 0)
        local move = Vector3.new(right, up, forward)
        if move.Magnitude > 0 then
            local worldMove = (cam.CFrame:VectorToWorldSpace(move)).Unit
            rootPart.Velocity = worldMove * (tonumber(currentSettings.FlySpeed) or flySpeed)
        else
            rootPart.Velocity = Vector3.new(0,0,0)
        end
        if rootPart then
            pcall(function() rootPart.CanCollide = false end)
        end
    end)
end
local function disableFly()
    if not flyEnabled then return end
    flyEnabled = false
    if flyConnection then
        pcall(function() flyConnection:Disconnect() end)
        flyConnection = nil
    end
    if humanoid then
        pcall(function() humanoid.PlatformStand = false end)
    end
    if rootPart then
        pcall(function() rootPart.CanCollide = true end)
    end
end

-- Heartbeat tasks: bhop, air strafe, auto crouch
RunService.Heartbeat:Connect(function(dt)
    if not character then updateCharacterRefs() end
    if currentSettings.Bhop and bhopHold and humanoid then
        if isGrounded() then
            pcall(function() humanoid:ChangeState(Enum.HumanoidStateType.Jumping) end)
        end
    end
    if tonumber(currentSettings.AirStrafeAcceleration) and tonumber(currentSettings.AirStrafeAcceleration) > 0 then
        applyAirStrafe(dt)
    end
    if currentSettings.AutoCrouch and humanoid then
        local mapped = mapSpeedToWalkSpeed(currentSettings.Speed)
        local curSpeed = (humanoid.MoveDirection).Magnitude * (humanoid.WalkSpeed or 16)
        if curSpeed >= mapped * 1.2 then
            setCrouch(true)
        else
            setCrouch(false)
        end
    else
        if not currentSettings.AutoCrouch then
            setCrouch(false)
        end
    end
end)

-- AutoCarry monitor
task.spawn(function()
    while true do
        if currentSettings.AutoCarry and not autoCarryRunning then
            task.spawn(autoCarryLoop)
        end
        task.wait(1)
    end
end)

-- Reapply debounce + autosave
local reapplyDebounce = false
local function scheduleReapply()
    if reapplyDebounce then return end
    reapplyDebounce = true
    task.spawn(function()
        task.wait(0.1)
        applyMovementSettings()
        saveConfig()
        reapplyDebounce = false
    end)
end

-- WindUI window & UI (Dara Hub style)
WindUI.TransparencyValue = 0.2
WindUI:SetTheme("Dark")
local Window = WindUI:CreateWindow({
    Title = "Movement Hub",
    Icon = "rbxassetid://137330250139083",
    Author = "Dara Hub - Movement",
    Folder = "GameHackUI",
    Size = UDim2.fromOffset(640, 480),
    Theme = "Dark",
    HidePanelBackground = false,
    Acrylic = false,
    HideSearchBar = false,
    SideBarWidth = 200
})
Window:SetIconSize(48)
Window:Tag({Title = "v1.0", Color = Color3.fromHex("#30ff6a")})

local Tab = Window:CreateTab("Movement Hub")

-- Movement Settings Section (use textboxes like Dara Hub)
local MovementSection = Tab:CreateSection("Movement Settings")

-- Speed input
local speedBox = MovementSection:CreateTextbox({
    Text = "Speed",
    Default = tostring(currentSettings.Speed),
    Placeholder = "1500"
})
speedBox:OnChanged(function(val)
    local n = tonumber(val)
    if n then currentSettings.Speed = n end
    scheduleReapply()
end)

-- Strafe Accel input
local strafeBox = MovementSection:CreateTextbox({
    Text = "Strafe Acceleration",
    Default = tostring(currentSettings.AirStrafeAcceleration),
    Placeholder = "187"
})
strafeBox:OnChanged(function(val)
    local n = tonumber(val)
    if n then currentSettings.AirStrafeAcceleration = n end
    scheduleReapply()
end)

-- Jump Cap input
local jumpCapBox = MovementSection:CreateTextbox({
    Text = "Jump Cap",
    Default = tostring(currentSettings.JumpCap),
    Placeholder = "1"
})
jumpCapBox:OnChanged(function(val)
    local n = tonumber(val)
    if n then
        currentSettings.JumpCap = n
    end
    scheduleReapply()
end)

local applyModeDrop = MovementSection:CreateDropdown({
    Text = "ApplyMode",
    Options = {"Not Optimized", "Optimized"},
    Default = currentSettings.ApplyMode
})
applyModeDrop:OnChanged(function(choice)
    currentSettings.ApplyMode = choice
    scheduleReapply()
end)

-- Physics Section
local PhysicsSection = Tab:CreateSection("Physics")

local gravityBox = PhysicsSection:CreateTextbox({
    Text = "Gravity",
    Default = tostring(currentSettings.Gravity),
    Placeholder = tostring(defaultSettings.Gravity)
})
gravityBox:OnChanged(function(val)
    local n = tonumber(val)
    if n then currentSettings.Gravity = n end
    scheduleReapply()
end)

local autoCrouchToggle = PhysicsSection:CreateToggle({
    Text = "Auto Crouch",
    Default = currentSettings.AutoCrouch
})
autoCrouchToggle:OnChanged(function(state)
    currentSettings.AutoCrouch = state
    scheduleReapply()
end)

-- Automation Section
local AutomationSection = Tab:CreateSection("Automation")

local bhopToggle = AutomationSection:CreateToggle({
    Text = "Bhop",
    Default = currentSettings.Bhop
})
bhopToggle:OnChanged(function(state)
    currentSettings.Bhop = state
    scheduleReapply()
end)

local autoCarryToggle = AutomationSection:CreateToggle({
    Text = "AutoCarry",
    Default = currentSettings.AutoCarry
})
autoCarryToggle:OnChanged(function(state)
    currentSettings.AutoCarry = state
    if state and not autoCarryRunning then
        task.spawn(autoCarryLoop)
    end
    scheduleReapply()
end)

-- Settings Section (contains all buttons as requested)
local SettingsSection = Tab:CreateSection("Settings")

local applyBtn = SettingsSection:CreateButton({Text = "Apply Settings"})
applyBtn:OnClick(function()
    applyMovementSettings()
    saveConfig()
end)

local resetBtn = SettingsSection:CreateButton({Text = "Reset to Default"})
resetBtn:OnClick(function()
    for k,v in pairs(defaultSettings) do currentSettings[k] = v end
    -- refresh UI
    pcall(function()
        if speedBox.SetValue then speedBox:SetValue(tostring(currentSettings.Speed)) end
        if strafeBox.SetValue then strafeBox:SetValue(tostring(currentSettings.AirStrafeAcceleration)) end
        if jumpCapBox.SetValue then jumpCapBox:SetValue(tostring(currentSettings.JumpCap)) end
        if gravityBox.SetValue then gravityBox:SetValue(tostring(currentSettings.Gravity)) end
        if applyModeDrop.SetValue then applyModeDrop:SetValue(currentSettings.ApplyMode) end
        if autoCrouchToggle.SetValue then autoCrouchToggle:SetValue(currentSettings.AutoCrouch) end
        if bhopToggle.SetValue then bhopToggle:SetValue(currentSettings.Bhop) end
        if autoCarryToggle.SetValue then autoCarryToggle:SetValue(currentSettings.AutoCarry) end
    end)
    applyMovementSettings()
    saveConfig()
end)

local rejoinBtn = SettingsSection:CreateButton({Text = "Rejoin Server"})
rejoinBtn:OnClick(function()
    pcall(function()
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
    end)
end)

local respawnBtn = SettingsSection:CreateButton({Text = "Respawn Character"})
respawnBtn:OnClick(function()
    pcall(function()
        if humanoid then humanoid.Health = 0 end
    end)
end)

local flyToggle = SettingsSection:CreateToggle({Text = "Fly (basic)", Default = false})
flyToggle:OnChanged(function(state)
    if state then
        enableFly()
    else
        disableFly()
    end
end)

-- Extra: Fly speed input in Settings
local flySpeedBox = SettingsSection:CreateTextbox({
    Text = "Fly Speed",
    Default = tostring(currentSettings.FlySpeed),
    Placeholder = tostring(defaultSettings.FlySpeed)
})
flySpeedBox:OnChanged(function(val)
    local n = tonumber(val)
    if n then currentSettings.FlySpeed = n end
    scheduleReapply()
end)

-- Load/Save Buttons (redundant but present)
local saveBtn = SettingsSection:CreateButton({Text = "Save Configuration"})
saveBtn:OnClick(function() saveConfig() end)

local loadBtn = SettingsSection:CreateButton({Text = "Load Configuration"})
loadBtn:OnClick(function()
    loadConfig()
    pcall(function()
        if speedBox.SetValue then speedBox:SetValue(tostring(currentSettings.Speed)) end
        if strafeBox.SetValue then strafeBox:SetValue(tostring(currentSettings.AirStrafeAcceleration)) end
        if jumpCapBox.SetValue then jumpCapBox:SetValue(tostring(currentSettings.JumpCap)) end
        if gravityBox.SetValue then gravityBox:SetValue(tostring(currentSettings.Gravity)) end
        if applyModeDrop.SetValue then applyModeDrop:SetValue(currentSettings.ApplyMode) end
        if autoCrouchToggle.SetValue then autoCrouchToggle:SetValue(currentSettings.AutoCrouch) end
        if bhopToggle.SetValue then bhopToggle:SetValue(currentSettings.Bhop) end
        if autoCarryToggle.SetValue then autoCarryToggle:SetValue(currentSettings.AutoCarry) end
        if flySpeedBox.SetValue then flySpeedBox:SetValue(tostring(currentSettings.FlySpeed)) end
    end)
    applyMovementSettings()
end)

-- Initialize UI values to current settings
pcall(function() if speedBox.SetValue then speedBox:SetValue(tostring(currentSettings.Speed)) end end)
pcall(function() if strafeBox.SetValue then strafeBox:SetValue(tostring(currentSettings.AirStrafeAcceleration)) end end)
pcall(function() if jumpCapBox.SetValue then jumpCapBox:SetValue(tostring(currentSettings.JumpCap)) end end)
pcall(function() if gravityBox.SetValue then gravityBox:SetValue(tostring(currentSettings.Gravity)) end end)
pcall(function() if applyModeDrop.SetValue then applyModeDrop:SetValue(currentSettings.ApplyMode) end end)
pcall(function() if autoCrouchToggle.SetValue then autoCrouchToggle:SetValue(currentSettings.AutoCrouch) end end)
pcall(function() if bhopToggle.SetValue then bhopToggle:SetValue(currentSettings.Bhop) end end)
pcall(function() if autoCarryToggle.SetValue then autoCarryToggle:SetValue(currentSettings.AutoCarry) end end)
pcall(function() if flyToggle.SetValue then flyToggle:SetValue(flyEnabled) end end)
pcall(function() if flySpeedBox.SetValue then flySpeedBox:SetValue(tostring(currentSettings.FlySpeed)) end end)

-- End of Movement Hub (Dara Hub style)
