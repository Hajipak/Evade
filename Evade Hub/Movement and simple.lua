-- Evade Test (Trimmed Final)
-- Features: Bhop, Auto Crouch, Bounce, Strafe Acceleration, Jump Cap, Speed, Timer Display, FullBright
-- On-screen GUI buttons for: Auto Crouch, Bhop, Bounce (draggable)
-- Tab Auto includes toggles to Show/Hide Bhop & Bounce on-screen buttons
-- Tab Auto includes GUI Settings: ButtonWidth, ButtonHeight (default 50x50)

if getgenv().EvadeTrimFinalLoaded then return end
getgenv().EvadeTrimFinalLoaded = true

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- === Configuration defaults ===
local config = {
    Speed = 1500,
    JumpCap = 1,
    AirStrafeAcceleration = 187,
    ApplyMode = "Not Optimized",
    -- GUI on-screen default
    ButtonWidth = 50,
    ButtonHeight = 50,
    ShowBhopButton = false,
    ShowBounceButton = false
}

-- Feature states
local state = {
    Bhop = false,
    BhopMode = "Acceleration", -- "Acceleration","No Acceleration","Hold"
    BhopAccelValue = -0.5,
    AutoCrouch = false,
    AutoCrouchMode = "Air", -- "Air","Normal","Ground"
    Bounce = false,
    BounceHeight = 0,
    BounceEpsilon = 0.1,
    FullBright = false,
    TimerDisplay = false
}

-- Preserve original lighting to restore
local originalLighting = {
    Brightness = Lighting.Brightness,
    FogEnd = Lighting.FogEnd,
    Ambient = Lighting.Ambient,
    OutdoorAmbient = Lighting.OutdoorAmbient,
    GlobalShadows = Lighting.GlobalShadows
}

-- ===== Helpers to find config tables in game's memory =====
local requiredFields = {
    Friction = true,
    AirStrafeAcceleration = true,
    JumpHeight = true,
    RunDeaccel = true,
    JumpSpeedMultiplier = true,
    JumpCap = true,
    SprintCap = true,
    WalkSpeedMultiplier = true,
    BhopEnabled = true,
    Speed = true,
    AirAcceleration = true,
    RunAccel = true,
    SprintAcceleration = true
}

local function hasAllFields(tbl)
    if type(tbl) ~= "table" then return false end
    for field, _ in pairs(requiredFields) do
        if rawget(tbl, field) == nil then return false end
    end
    return true
end

local function getConfigTables()
    local tables = {}
    for _, obj in ipairs(getgc(true)) do
        local ok, res = pcall(function()
            if hasAllFields(obj) then return obj end
        end)
        if ok and res then table.insert(tables, res) end
    end
    return tables
end

local function applyToTables(callback)
    local targets = getConfigTables()
    if #targets == 0 then return end
    if config.ApplyMode == "Optimized" then
        task.spawn(function()
            for i, tableObj in ipairs(targets) do
                pcall(callback, tableObj)
                if i % 3 == 0 then task.wait() end
            end
        end)
    else
        for _, tableObj in ipairs(targets) do
            pcall(callback, tableObj)
        end
    end
end

local function applySettingField(field, value)
    applyToTables(function(obj)
        pcall(function()
            obj[field] = value
        end)
    end)
end

-- initial application
applySettingField("Speed", config.Speed)
applySettingField("JumpCap", config.JumpCap)
applySettingField("AirStrafeAcceleration", config.AirStrafeAcceleration)

-- ===== FullBright =====
local function setFullbright(on)
    if on then
        Lighting.Brightness = 3
        Lighting.FogEnd = 100000
        Lighting.Ambient = Color3.fromRGB(255,255,255)
        Lighting.OutdoorAmbient = Color3.fromRGB(255,255,255)
        Lighting.GlobalShadows = false
    else
        Lighting.Brightness = originalLighting.Brightness
        Lighting.FogEnd = originalLighting.FogEnd
        Lighting.Ambient = originalLighting.Ambient
        Lighting.OutdoorAmbient = originalLighting.OutdoorAmbient
        Lighting.GlobalShadows = originalLighting.GlobalShadows
    end
end

-- ===== Timer display (simple) =====
local timerGui = nil
local function createTimerGui()
    if timerGui and timerGui.Parent then return end
    if timerGui then timerGui:Destroy() end
    timerGui = Instance.new("ScreenGui")
    timerGui.Name = "EvadeTimerGui"
    timerGui.IgnoreGuiInset = true
    timerGui.ResetOnSpawn = false
    timerGui.Parent = playerGui

    local frame = Instance.new("Frame", timerGui)
    frame.Name = "TimerFrame"
    frame.Size = UDim2.new(0,180,0,36)
    frame.Position = UDim2.new(0.5,-90,0.02,0)
    frame.BackgroundTransparency = 0.35
    frame.BackgroundColor3 = Color3.fromRGB(0,0,0)
    frame.BorderSizePixel = 0

    local label = Instance.new("TextLabel", frame)
    label.Name = "TimerLabel"
    label.Size = UDim2.new(1,-8,1,-8)
    label.Position = UDim2.new(0,4,0,4)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(255,255,255)
    label.Font = Enum.Font.SourceSansBold
    label.TextSize = 18
    label.Text = "Timer: N/A"
end

local function destroyTimerGui()
    if timerGui then
        timerGui:Destroy()
        timerGui = nil
    end
end

-- Optional: bind to a "Game Stats" object if present
local function tryBindTimer(statsObj)
    if not statsObj then return end
    pcall(function()
        if statsObj:GetAttribute("Timer") ~= nil then
            if state.TimerDisplay then createTimerGui() end
            statsObj:GetAttributeChangedSignal("Timer"):Connect(function()
                if state.TimerDisplay and timerGui then
                    local lbl = timerGui:FindFirstChild("TimerFrame") and timerGui.TimerFrame:FindFirstChild("TimerLabel")
                    if lbl then lbl.Text = "Timer: "..tostring(statsObj:GetAttribute("Timer")) end
                end
            end)
        end
    end)
end

-- try to find workspace.Game.Stats or similar without error
pcall(function()
    local g = workspace:FindFirstChild("Game") or workspace
    local stats = g:FindFirstChild("Stats")
    tryBindTimer(stats)
end)

-- ===== Bounce (touch-based) =====
local Debris = game:GetService("Debris")
local remoteEvent = nil
pcall(function() remoteEvent = ReplicatedStorage:WaitForChild("Events"):WaitForChild("Character"):WaitForChild("PassCharacterInfo") end)

local touchConnections = {}
local function setupBounceOnTouch(character)
    if not state.Bounce then return end
    if not character then return end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    if touchConnections[character] then
        touchConnections[character]:Disconnect()
        touchConnections[character] = nil
    end

    local conn = hrp.Touched:Connect(function(hit)
        if not state.Bounce then return end
        local hitSize = (hit and hit.Size) or Vector3.new(0,0,0)
        local hitTop = hit.Position.Y + hitSize.Y/2
        local playerBottom = hrp.Position.Y - hrp.Size.Y/2
        if hitTop <= playerBottom + state.BounceEpsilon then return end
        if remoteEvent then
            pcall(function() remoteEvent:FireServer({}, {2}) end)
        end
        if state.BounceHeight and state.BounceHeight > 0 then
            local bv = Instance.new("BodyVelocity")
            bv.MaxForce = Vector3.new(0, math.huge, 0)
            bv.Velocity = Vector3.new(0, state.BounceHeight, 0)
            bv.Parent = hrp
            Debris:AddItem(bv, 0.2)
        end
    end)
    touchConnections[character] = conn

    character.AncestryChanged:Connect(function()
        if not character.Parent and touchConnections[character] then
            touchConnections[character]:Disconnect()
            touchConnections[character] = nil
        end
    end)
end

local function disableAllBounce()
    for c, conn in pairs(touchConnections) do
        if conn then conn:Disconnect() end
    end
    touchConnections = {}
end

player.CharacterAdded:Connect(function(ch)
    task.wait(0.5)
    if state.Bounce then setupBounceOnTouch(ch) end
end)
if player.Character and state.Bounce then setupBounceOnTouch(player.Character) end

-- ===== Bhop (friction tweak + auto-jump) =====
getgenv().autoJumpEnabled = false
getgenv().bhopHoldActive = false

UserInputService.InputBegan:Connect(function(inp, gpe)
    if gpe then return end
    if inp.KeyCode == Enum.KeyCode.Space and state.BhopMode == "Hold" and state.Bhop then
        getgenv().bhopHoldActive = true
    end
end)
UserInputService.InputEnded:Connect(function(inp)
    if inp.KeyCode == Enum.KeyCode.Space then
        getgenv().bhopHoldActive = false
    end
end)

-- toggle Bhop via on-screen button or menu; support 'B' hotkey to toggle active bhop
UserInputService.InputBegan:Connect(function(inp, gpe)
    if gpe then return end
    if inp.KeyCode == Enum.KeyCode.B and state.Bhop then
        getgenv().autoJumpEnabled = not getgenv().autoJumpEnabled
    end
end)

-- friction application loop
task.spawn(function()
    while task.wait(0.15) do
        local friction = 5
        local isBhopActive = getgenv().autoJumpEnabled or getgenv().bhopHoldActive
        if isBhopActive and state.BhopMode == "Acceleration" then
            friction = state.BhopAccelValue or -0.5
        end
        for _, t in pairs(getgc(true)) do
            if type(t) == "table" and rawget(t, "Friction") then
                if state.BhopMode ~= "No Acceleration" then
                    pcall(function() t.Friction = friction end)
                end
            end
        end
    end
end)

-- auto-jump coroutine
task.spawn(function()
    while task.wait() do
        local active = getgenv().autoJumpEnabled or getgenv().bhopHoldActive
        if active and state.Bhop then
            local character = player.Character
            if character and character:FindFirstChild("Humanoid") then
                local humanoid = character.Humanoid
                if humanoid:GetState() ~= Enum.HumanoidStateType.Jumping and humanoid:GetState() ~= Enum.HumanoidStateType.Freefall then
                    humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                end
            end
            if state.BhopMode == "No Acceleration" then task.wait(0.05) else task.wait() end
        else
            task.wait(0.05)
        end
    end
end)

-- ===== Auto Crouch (fires keybind event) =====
local function fireKeybind(down, key)
    -- safe-fire to any in PlayerScripts temporary events if present
    pcall(function()
        local ps = player:FindFirstChild("PlayerScripts")
        if ps then
            local events = ps:FindFirstChild("Events") or ps:FindFirstChild("Temporary_Events") or ps:FindFirstChild("temporary_events")
            if events then
                local use = events:FindFirstChild("UseKeybind") or events:FindFirstChild("use_keybind") or events:FindFirstChild("Use_Keybind")
                if use and use.Fire then
                    use:Fire({ Down = down, Key = key })
                end
            end
        end
    end)
end

local previousCrouchState = false
local spamDown = true

RunService.Heartbeat:Connect(function()
    if not state.AutoCrouch then
        if previousCrouchState then
            fireKeybind(false, "Crouch")
            previousCrouchState = false
        end
        return
    end

    local char = player.Character
    if not char or not char:FindFirstChild("Humanoid") then return end
    local humanoid = char.Humanoid
    local mode = state.AutoCrouchMode

    if mode == "Normal" then
        fireKeybind(spamDown, "Crouch")
        spamDown = not spamDown
    else
        local isAir = (humanoid.FloorMaterial == Enum.Material.Air) and (humanoid:GetState() ~= Enum.HumanoidStateType.Seated)
        local shouldCrouch = (mode == "Air" and isAir) or (mode == "Ground" and not isAir)
        if shouldCrouch ~= previousCrouchState then
            fireKeybind(shouldCrouch, "Crouch")
            previousCrouchState = shouldCrouch
        end
    end
end)

-- ===== On-screen small draggable button utility =====
local function makeDraggable(frame)
    local dragging, dragInput, dragStart, startPos = false, nil, nil, nil

    local function update(input)
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end

    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    frame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)

    game:GetService("UserInputService").InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            update(input)
        end
    end)
end

-- create or destroy small button
local smallButtons = {
    AutoCrouch = nil,
    Bhop = nil,
    Bounce = nil
}

local function createSmallButton(name, pos, getStateFunc, toggleFunc)
    -- remove if exists
    if smallButtons[name] and smallButtons[name].Parent then smallButtons[name]:Destroy() end
    local sg = Instance.new("ScreenGui", playerGui)
    sg.Name = "EvadeSmallButton_"..name
    sg.ResetOnSpawn = false
    sg.IgnoreGuiInset = true

    local frame = Instance.new("Frame", sg)
    frame.Name = name.."Frame"
    frame.Size = UDim2.new(0, config.ButtonWidth, 0, config.ButtonHeight)
    frame.Position = pos
    frame.BackgroundTransparency = 0.25
    frame.BackgroundColor3 = Color3.fromRGB(0,0,0)
    frame.BorderSizePixel = 0

    local label = Instance.new("TextLabel", frame)
    label.Size = UDim2.new(1,0,0.55,0)
    label.Position = UDim2.new(0,0,0,0)
    label.BackgroundTransparency = 1
    label.Text = name
    label.Font = Enum.Font.SourceSansBold
    label.TextSize = 14
    label.TextColor3 = Color3.fromRGB(255,255,255)

    local btn = Instance.new("TextButton", frame)
    btn.Name = name.."Btn"
    btn.Size = UDim2.new(0.9,0,0.35,0)
    btn.Position = UDim2.new(0.05,0,0.55,0)
    btn.Text = getStateFunc() and "On" or "Off"
    btn.AutoButtonColor = true

    local function refreshAppearance()
        btn.Text = getStateFunc() and "On" or "Off"
        if getStateFunc() then
            btn.BackgroundColor3 = Color3.fromRGB(0,150,80)
        else
            btn.BackgroundColor3 = Color3.fromRGB(150,0,0)
        end
    end

    btn.MouseButton1Click:Connect(function()
        toggleFunc()
        refreshAppearance()
    end)

    -- make it draggable
    makeDraggable(frame)

    smallButtons[name] = sg
    refreshAppearance()
    return sg
end

local function destroySmallButton(name)
    if smallButtons[name] and smallButtons[name].Parent then
        smallButtons[name]:Destroy()
        smallButtons[name] = nil
    end
end

-- create Auto Crouch button by default
createSmallButton("AutoCrouch", UDim2.new(0.5, -config.ButtonWidth - 8, 0.12, 0),
    function() return state.AutoCrouch end,
    function() state.AutoCrouch = not state.AutoCrouch end
)

-- create Bhop and Bounce buttons only when config toggles are true
local function refreshOnScreenButtons()
    -- positions: left Bhop, center AutoCrouch, right Bounce
    local leftPos = UDim2.new(0.5, -config.ButtonWidth*2 - 16, 0.12, 0)
    local centerPos = UDim2.new(0.5, -config.ButtonWidth/2, 0.12, 0)
    local rightPos = UDim2.new(0.5, config.ButtonWidth + 16, 0.12, 0)

    -- Auto Crouch (ensure updated size)
    if smallButtons.AutoCrouch and smallButtons.AutoCrouch.Parent then
        smallButtons.AutoCrouch.AutoCrouchFrame.Size = UDim2.new(0, config.ButtonWidth, 0, config.ButtonHeight)
        smallButtons.AutoCrouch.AutoCrouchFrame.Position = centerPos
    end

    if config.ShowBhopButton then
        if not smallButtons.Bhop then
            createSmallButton("Bhop", leftPos,
                function() return state.Bhop end,
                function() state.Bhop = not state.Bhop; if not state.Bhop then getgenv().autoJumpEnabled = false; getgenv().bhopHoldActive = false end end
            )
        else
            smallButtons.Bhop.BhopFrame.Size = UDim2.new(0, config.ButtonWidth, 0, config.ButtonHeight)
            smallButtons.Bhop.BhopFrame.Position = leftPos
        end
    else
        destroySmallButton("Bhop")
    end

    if config.ShowBounceButton then
        if not smallButtons.Bounce then
            createSmallButton("Bounce", rightPos,
                function() return state.Bounce end,
                function() state.Bounce = not state.Bounce; if state.Bounce and player.Character then setupBounceOnTouch(player.Character) else disableAllBounce() end end
            )
        else
            smallButtons.Bounce.BounceFrame.Size = UDim2.new(0, config.ButtonWidth, 0, config.ButtonHeight)
            smallButtons.Bounce.BounceFrame.Position = rightPos
        end
    else
        destroySmallButton("Bounce")
    end
end

-- initial call to set up based on defaults
refreshOnScreenButtons()

-- ===== Minimal WindUI integration (if available) =====
local WindUI = nil
local success, lib = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()
end)
if success and lib then WindUI = lib end

local Window = nil
if WindUI then
    Window = WindUI:CreateWindow({
        Title = "Evade Trim Final",
        Icon = "rocket",
        Author = "Trim",
        Folder = "EvadeTrimFinal",
        Size = UDim2.fromOffset(520,360),
        Theme = "Dark"
    })
    local Tabs = {}
    Tabs.Player = Window:CreateTab("Player")
    Tabs.Auto = Window:CreateTab("Auto")
    Tabs.Visuals = Window:CreateTab("Visuals")

    -- Player: movement settings
    Tabs.Player:Section({ Title = "Movement" })
    Tabs.Player:Input({
        Title = "Set Speed",
        Placeholder = "1500",
        Value = tostring(config.Speed),
        Callback = function(val)
            local n = tonumber(val) if not n then return end
            config.Speed = n
            applySettingField("Speed", n)
        end
    })
    Tabs.Player:Input({
        Title = "Set Jump Cap",
        Placeholder = "1",
        Value = tostring(config.JumpCap),
        Callback = function(val)
            local n = tonumber(val) if not n then return end
            config.JumpCap = n
            applySettingField("JumpCap", n)
        end
    })
    Tabs.Player:Input({
        Title = "Strafe Acceleration",
        Placeholder = "187",
        Value = tostring(config.AirStrafeAcceleration),
        Callback = function(val)
            local n = tonumber(val) if not n then return end
            config.AirStrafeAcceleration = n
            applySettingField("AirStrafeAcceleration", n)
        end
    })
    Tabs.Player:Dropdown({
        Title = "Select Apply Mode",
        Values = { "Not Optimized", "Optimized" },
        Default = config.ApplyMode,
        Callback = function(v) config.ApplyMode = v end
    })

    -- Auto: toggles + GUI settings
    Tabs.Auto:Section({ Title = "Automatic Features" })
    Tabs.Auto:Toggle({
        Title = "Bhop (Menu Toggle)",
        Value = state.Bhop,
        Callback = function(v) state.Bhop = v; if not v then getgenv().autoJumpEnabled = false; getgenv().bhopHoldActive = false end end
    })
    Tabs.Auto:Dropdown({
        Title = "Bhop Mode",
        Values = { "Acceleration", "No Acceleration", "Hold" },
        Value = state.BhopMode,
        Callback = function(v) state.BhopMode = v end
    })
    Tabs.Auto:Input({
        Title = "Bhop Acceleration (neg)",
        Placeholder = "-0.5",
        Value = tostring(state.BhopAccelValue),
        Callback = function(v) local n = tonumber(v) if n then state.BhopAccelValue = n end end
    })

    Tabs.Auto:Toggle({
        Title = "Auto Crouch",
        Value = state.AutoCrouch,
        Callback = function(v) state.AutoCrouch = v end
    })
    Tabs.Auto:Dropdown({
        Title = "Auto Crouch Mode",
        Values = { "Air", "Normal", "Ground" },
        Value = state.AutoCrouchMode,
        Callback = function(v) state.AutoCrouchMode = v end
    })

    Tabs.Auto:Section({ Title = "On-screen Buttons" })
    Tabs.Auto:Toggle({
        Title = "Show Bhop Button",
        Value = config.ShowBhopButton,
        Callback = function(v) config.ShowBhopButton = v refreshOnScreenButtons() end
    })
    Tabs.Auto:Toggle({
        Title = "Show Bounce Button",
        Value = config.ShowBounceButton,
        Callback = function(v) config.ShowBounceButton = v refreshOnScreenButtons() end
    })

    Tabs.Auto:Section({ Title = "GUI Settings" })
    Tabs.Auto:Input({
        Title = "Button Width (px)",
        Placeholder = "50",
        Value = tostring(config.ButtonWidth),
        Callback = function(v)
            local n = tonumber(v); if not n then return end
            config.ButtonWidth = math.clamp(n, 20, 300)
            refreshOnScreenButtons()
        end
    })
    Tabs.Auto:Input({
        Title = "Button Height (px)",
        Placeholder = "50",
        Value = tostring(config.ButtonHeight),
        Callback = function(v)
            local n = tonumber(v); if not n then return end
            config.ButtonHeight = math.clamp(n, 20, 300)
            refreshOnScreenButtons()
        end
    })

    -- Bounce settings in Player tab
    Tabs.Player:Section({ Title = "Bounce" })
    Tabs.Player:Toggle({
        Title = "Enable Bounce",
        Value = state.Bounce,
        Callback = function(v) state.Bounce = v if v and player.Character then setupBounceOnTouch(player.Character) else disableAllBounce() end end
    })
    Tabs.Player:Input({
        Title = "Bounce Height",
        Placeholder = "0",
        Value = tostring(state.BounceHeight),
        Callback = function(v) local n = tonumber(v); if n then state.BounceHeight = n end end
    })
    Tabs.Player:Input({
        Title = "Bounce Epsilon",
        Placeholder = "0.1",
        Value = tostring(state.BounceEpsilon),
        Callback = function(v) local n = tonumber(v); if n then state.BounceEpsilon = n end end
    })

    -- Visuals
    Tabs.Visuals:Section({ Title = "Visuals" })
    Tabs.Visuals:Toggle({
        Title = "FullBright",
        Value = state.FullBright,
        Callback = function(v) state.FullBright = v setFullbright(v) end
    })
    Tabs.Visuals:Toggle({
        Title = "Timer Display",
        Value = state.TimerDisplay,
        Callback = function(v) state.TimerDisplay = v if v then createTimerGui() else destroyTimerGui() end end
    })

    Window:Open()
end

-- If WindUI missing, create very basic menu fallback (not fancy) for critical toggles
if not WindUI then
    -- create a tiny settings GUI to toggle show buttons and sizes
    local sg = Instance.new("ScreenGui", playerGui)
    sg.Name = "EvadeTrimFallbackMenu"
    sg.ResetOnSpawn = false
    sg.IgnoreGuiInset = true

    local frame = Instance.new("Frame", sg)
    frame.Size = UDim2.new(0,260,0,200)
    frame.Position = UDim2.new(0.02,0,0.02,0)
    frame.BackgroundTransparency = 0.4
    frame.BackgroundColor3 = Color3.fromRGB(0,0,0)
    frame.BorderSizePixel = 0

    local function addLabel(text, y)
        local lbl = Instance.new("TextLabel", frame)
        lbl.Size = UDim2.new(1,-12,0,20)
        lbl.Position = UDim2.new(0,6,0, y)
        lbl.BackgroundTransparency = 1
        lbl.Text = text
        lbl.TextColor3 = Color3.new(1,1,1)
        lbl.Font = Enum.Font.SourceSans
        lbl.TextSize = 14
        return lbl
    end

    addLabel("Evade Trim Fallback Menu", 6)
    addLabel("Use WindUI for full features", 26)

    -- simple buttons for ShowBhopButton and ShowBounceButton
    local bhopBtn = Instance.new("TextButton", frame)
    bhopBtn.Size = UDim2.new(0.48, -6, 0, 30)
    bhopBtn.Position = UDim2.new(0,6,0,60)
    bhopBtn.Text = config.ShowBhopButton and "Hide Bhop Btn" or "Show Bhop Btn"
    bhopBtn.MouseButton1Click:Connect(function()
        config.ShowBhopButton = not config.ShowBhopButton
        bhopBtn.Text = config.ShowBhopButton and "Hide Bhop Btn" or "Show Bhop Btn"
        refreshOnScreenButtons()
    end)

    local bounceBtn = Instance.new("TextButton", frame)
    bounceBtn.Size = UDim2.new(0.48, -6, 0, 30)
    bounceBtn.Position = UDim2.new(0.5, 6, 0, 60)
    bounceBtn.Text = config.ShowBounceButton and "Hide Bounce Btn" or "Show Bounce Btn"
    bounceBtn.MouseButton1Click:Connect(function()
        config.ShowBounceButton = not config.ShowBounceButton
        bounceBtn.Text = config.ShowBounceButton and "Hide Bounce Btn" or "Show Bounce Btn"
        refreshOnScreenButtons()
    end)

    -- size inputs (rudimentary)
    local wInput = Instance.new("TextBox", frame)
    wInput.Size = UDim2.new(0.48, -6, 0, 24)
    wInput.Position = UDim2.new(0,6,0,100)
    wInput.Text = tostring(config.ButtonWidth)
    wInput.FocusLost:Connect(function(enter)
        local n = tonumber(wInput.Text)
        if n then config.ButtonWidth = math.clamp(n,20,300); refreshOnScreenButtons() end
    end)
    local hInput = Instance.new("TextBox", frame)
    hInput.Size = UDim2.new(0.48, -6, 0, 24)
    hInput.Position = UDim2.new(0.5,6,0,100)
    hInput.Text = tostring(config.ButtonHeight)
    hInput.FocusLost:Connect(function(enter)
        local n = tonumber(hInput.Text)
        if n then config.ButtonHeight = math.clamp(n,20,300); refreshOnScreenButtons() end
    end)
end

-- Cleanup on unload
game:BindToClose(function()
    disableAllBounce()
    destroyTimerGui()
    setFullbright(false)
end)

-- End of script
--[[the part of loadstring prevent error]]
loadstring(game:HttpGet('https://raw.githubusercontent.com/Hajipak/Evade/refs/heads/main/Script/More-loadstring.lua'))()
