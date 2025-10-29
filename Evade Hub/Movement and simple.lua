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
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local LocalPlayer = Players.LocalPlayer

-- Player and Character References
local player = LocalPlayer
local character
local humanoid
local humanoidRootPart

-- Configuration and States (simplified for this script)
getgenv().autoJumpEnabled = false
getgenv().autoCrouchEnabled = false
getgenv().bounceEnabled = false -- For the new toggle-specific version
getgenv().bounceEnabledTabOnly = false -- For the tab-only version
getgenv().bhopMode = "Acceleration"
getgenv().bhopAccelValue = -5
getgenv().autoCrouchMode = "normal" -- Options: "air", "normal", "ground"
getgenv().crouchConnection = nil
getgenv().touchConnections = {}
getgenv().BOUNCE_HEIGHT = 0
getgenv().BOUNCE_EPSILON = 0.1
local featureStates = {
    StrafeAcceleration = 5,
    JumpCap = 1,
    Speed = 1500,
    Bhop = false,
    AutoCrouch = false,
    Bounce = false,
    BounceTabOnly = false -- State for tab-only version
}

-- Toggle GUI Creation Function (from Evade structure)
local function createToggleGui(title, varName, initialXScale, initialYScale)
    initialXScale = initialXScale or 0.1
    initialYScale = initialYScale or 0.1

    local playerGui = LocalPlayer:WaitForChild("PlayerGui", 5)
    if not playerGui then return end

    local gui = Instance.new("ScreenGui")
    gui.Name = title .. "Gui"
    gui.ResetOnSpawn = false
    gui.Parent = playerGui

    local frame = Instance.new("Frame", gui)
    frame.Name = "MainFrame"
    frame.Size = UDim2.new(initialXScale, 0, initialYScale, 0)
    frame.Position = UDim2.new(initialXScale, 0, 0.5, 0) -- Example position
    frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    frame.BorderSizePixel = 2
    frame.BorderColor3 = Color3.fromRGB(0, 0, 0)
    frame.Active = true
    frame.Draggable = true

    local titleText = Instance.new("TextLabel", frame)
    titleText.Name = "Title"
    titleText.Size = UDim2.new(1, 0, 0.3, 0)
    titleText.Position = UDim2.new(0, 0, 0, 0)
    titleText.BackgroundTransparency = 1
    titleText.Text = title
    titleText.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleText.Font = Enum.Font.Roboto
    titleText.TextSize = 14
    titleText.TextXAlignment = Enum.TextXAlignment.Center
    titleText.TextYAlignment = Enum.TextYAlignment.Center

    local toggleBtn = Instance.new("TextButton", frame)
    toggleBtn.Name = "ToggleButton"
    toggleBtn.Size = UDim2.new(0.9, 0, 0.55, 0)
    toggleBtn.Position = UDim2.new(0.05, 0, 0.35, 0)
    toggleBtn.BackgroundColor3 = getgenv()[varName] and Color3.fromRGB(0, 100, 0) or Color3.fromRGB(0, 0, 0)
    toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggleBtn.Font = Enum.Font.Roboto
    toggleBtn.TextSize = 20
    toggleBtn.TextXAlignment = Enum.TextXAlignment.Center
    toggleBtn.TextYAlignment = Enum.TextYAlignment.Center
    toggleBtn.Text = getgenv()[varName] and "On" or "Off"

    local buttonCorner = Instance.new("UICorner", toggleBtn)
    buttonCorner.CornerRadius = UDim.new(0, 4)

    local uiToggledViaUI = false

    toggleBtn.MouseButton1Click:Connect(function()
        getgenv()[varName] = not getgenv()[varName]
        uiToggledViaUI = true
        toggleBtn.Text = getgenv()[varName] and "On" or "Off"
        toggleBtn.BackgroundColor3 = getgenv()[varName] and Color3.fromRGB(0, 100, 0) or Color3.fromRGB(0, 0, 0)
        gui.Enabled = true -- Ensure GUI stays visible when toggled via UI

        -- Update featureStates
        if varName == "autoJumpEnabled" then
            featureStates.Bhop = getgenv()[varName]
        elseif varName == "autoCrouchEnabled" then
            featureStates.AutoCrouch = getgenv()[varName]
        elseif varName == "bounceEnabled" then
            featureStates.Bounce = getgenv()[varName]
        end
    end)

    return gui, toggleBtn
end

-- --- Movement Hub UI Setup ---
local function setupMovementHub()
    if not Tabs or not Tabs.Auto or not Tabs.Player then
        warn("Tabs.Auto or Tabs.Player not found. Cannot setup Movement Hub.")
        return
    end

local Tabs = {
    Main = FeatureSection:Tab({ Title = "Main", Icon = "layout-grid" }),
    Player = FeatureSection:Tab({ Title = "Player", Icon = "user" }),
    Auto = FeatureSection:Tab({ Title = "Auto", Icon = "repeat-2" }),
    Visuals = FeatureSection:Tab({ Title = "Visuals", Icon = "camera" }),
    ESP = FeatureSection:Tab({ Title = "ESP", Icon = "eye" }),
    Utility = FeatureSection:Tab({ Title = "Utility", Icon = "wrench" }),
    Teleport = FeatureSection:Tab({ Title = "Teleport", Icon = "navigation" }),
    Settings = FeatureSection:Tab({ Title = "Settings", Icon = "settings" })
}

    -- Settings for GUI Toggle Sizes
    local bhopToggleXSize = 0.1
    local bhopToggleYSize = 0.1
    local autoCrouchToggleXSize = 0.1
    local autoCrouchToggleYSize = 0.1
    local bounceUIGuiToggleXSize = 0.1
    local bounceUIGuiToggleYSize = 0.1

    -- Main Movement Section
    Tabs.Auto:Section({ Title = "Movement Hub", TextSize = 40 })

    -- Strafe Acceleration Input
    local StrafeInput = Tabs.Auto:Input({
        Title = "Strafe Acceleration",
        Icon = "wind", -- Menggunakan ikon jika tersedia
        Placeholder = "Default 5",
        Value = tostring(featureStates.StrafeAcceleration),
        Numeric = true, -- Pastikan hanya angka yang bisa dimasukkan
        Callback = function(value)
            local num = tonumber(value)
            if num then
                featureStates.StrafeAcceleration = num
                -- Jika ada fungsi atau variabel lain yang perlu diupdate, lakukan di sini
            end
        end
    }):Set(tostring(featureStates.StrafeAcceleration)) -- Set nilai awal

    -- Jump Cap Input
    local JumpCapInput = Tabs.Auto:Input({
        Title = "Jump Cap",
        Icon = "chevrons-up", -- Menggunakan ikon jika tersedia
        Placeholder = "Default 1",
        Value = tostring(featureStates.JumpCap),
        Numeric = true,
        Callback = function(value)
            local num = tonumber(value)
            if num and num > 0 then -- Pastikan nilai positif
                featureStates.JumpCap = num
                -- Jika ada fungsi atau variabel lain yang perlu diupdate, lakukan di sini
            end
        end
    }):Set(tostring(featureStates.JumpCap))

    -- Speed Input
    local SpeedInput = Tabs.Auto:Input({
        Title = "Speed",
        Icon = "speedometer", -- Menggunakan ikon jika tersedia
        Placeholder = "Default 1500",
        Value = tostring(featureStates.Speed),
        Numeric = true,
        Callback = function(value)
            local num = tonumber(value)
            if num and num >= 10 then -- Pastikan nilai minimal 10
                featureStates.Speed = num
                -- Jika ada fungsi atau variabel lain yang perlu diupdate, lakukan di sini
            end
        end
    }):Set(tostring(featureStates.Speed))

    -- Bhop Setup
    local bhopGui, bhopToggleBtn = createToggleGui("Bhop", "autoJumpEnabled", bhopToggleXSize, bhopToggleYSize)
    local bhopToggle = Tabs.Auto:Toggle({
        Title = "Bhop (UI Toggle)",
        Value = getgenv().autoJumpEnabled,
        Callback = function(state)
            getgenv().autoJumpEnabled = state
            if bhopGui and bhopToggleBtn then
                bhopGui.Enabled = (state and uiToggledViaUI) -- Show UI if toggled on via UI or mobile
                bhopToggleBtn.Text = state and "On" or "Off"
                bhopToggleBtn.BackgroundColor3 = state and Color3.fromRGB(0, 100, 0) or Color3.fromRGB(0, 0, 0)
            end
            featureStates.Bhop = state
            if state then
                -- Assuming Bhop activation logic is handled elsewhere (e.g., in RunService.Heartbeat)
            else
                -- Assuming Bhop deactivation logic is handled elsewhere
            end
        end
    })
    bhopToggle:Set(getgenv().autoJumpEnabled)

    -- Bhop Mode Dropdown
    Tabs.Auto:Dropdown({
        Title = "Bhop Mode",
        Values = {"Acceleration", "No Acceleration"},
        Multi = false,
        Default = "Acceleration",
        Callback = function(value)
            getgenv().bhopMode = value
        end
    })

    -- Bhop Acceleration Input
    Tabs.Auto:Input({
        Title = "Bhop Acceleration (Negative Only)",
        Placeholder = "-0.5",
        Numeric = true,
        Callback = function(value)
            if tostring(value):sub(1, 1) == "-" then
                local n = tonumber(value)
                if n then getgenv().bhopAccelValue = n end
            end
        end
    })

    -- Auto Crouch Setup
    local autoCrouchGui, autoCrouchToggleBtn = createToggleGui("Auto Crouch", "autoCrouchEnabled", autoCrouchToggleXSize, autoCrouchToggleYSize)
    local autoCrouchToggle = Tabs.Auto:Toggle({
        Title = "Auto Crouch (UI Toggle)",
        Value = getgenv().autoCrouchEnabled,
        Callback = function(state)
            getgenv().autoCrouchEnabled = state
            if autoCrouchGui and autoCrouchToggleBtn then
                autoCrouchGui.Enabled = (state and uiToggledViaUI)
                autoCrouchToggleBtn.Text = state and "On" or "Off"
                autoCrouchToggleBtn.BackgroundColor3 = state and Color3.fromRGB(0, 100, 0) or Color3.fromRGB(0, 0, 0)
            end
            featureStates.AutoCrouch = state
            if state then
                startAutoCrouch()
            else
                stopAutoCrouch()
            end
        end
    })
    autoCrouchToggle:Set(getgenv().autoCrouchEnabled)

    -- Auto Crouch Mode Dropdown
    Tabs.Auto:Dropdown({
        Title = "Auto Crouch Mode",
        Values = {"Air", "Normal", "Ground"},
        Multi = false,
        Default = "Normal",
        Callback = function(value)
            getgenv().autoCrouchMode = value:lower()
        end
    })

    -- Bounce Setup (Version with Toggle UI)
    local bounceUIGui, bounceUIGuiToggleBtn = createToggleGui("Bounce (UI)", "bounceEnabled", bounceUIGuiToggleXSize, bounceUIGuiToggleYSize)
    local bounceUIGuiToggle = Tabs.Player:Toggle({
        Title = "Bounce (UI Toggle)",
        Value = getgenv().bounceEnabled,
        Callback = function(state)
            getgenv().bounceEnabled = state
            if bounceUIGui and bounceUIGuiToggleBtn then
                bounceUIGui.Enabled = (state and uiToggledViaUI)
                bounceUIGuiToggleBtn.Text = state and "On" or "Off"
                bounceUIGuiToggleBtn.BackgroundColor3 = state and Color3.fromRGB(0, 100, 0) or Color3.fromRGB(0, 0, 0)
            end
            featureStates.Bounce = state
            if state then
                if player.Character then
                    setupBounceOnTouch(player.Character)
                end
            else
                disableBounce()
            end
        end
    })
    bounceUIGuiToggle:Set(getgenv().bounceEnabled)

    -- Bounce Height Input (for UI Toggle version)
    Tabs.Player:Input({
        Title = "Bounce Height (UI Toggle)",
        Placeholder = "0",
        Value = tostring(getgenv().BOUNCE_HEIGHT),
        Numeric = true,
        Enabled = getgenv().bounceEnabled,
        Callback = function(value)
            local num = tonumber(value)
            if num then
                getgenv().BOUNCE_HEIGHT = math.max(0, num)
            end
        end
    }):Set(tostring(getgenv().BOUNCE_HEIGHT))

    -- Touch Epsilon Input (for UI Toggle version)
    Tabs.Player:Input({
        Title = "Touch Epsilon (UI Toggle)",
        Placeholder = "0.1",
        Value = tostring(getgenv().BOUNCE_EPSILON),
        Numeric = true,
        Enabled = getgenv().bounceEnabled,
        Callback = function(value)
            local num = tonumber(value)
            if num then
                getgenv().BOUNCE_EPSILON = math.max(0, num)
            end
        end
    }):Set(tostring(getgenv().BOUNCE_EPSILON))

    -- Bounce Setup (Version with Tab Toggle Only)
    local bounceTabOnlyToggle = Tabs.Player:Toggle({
        Title = "Bounce (Tab Only)",
        Value = featureStates.BounceTabOnly,
        Callback = function(state)
            getgenv().bounceEnabledTabOnly = state -- Sync global var
            featureStates.BounceTabOnly = state
            if state then
                if player.Character then
                    setupBounceOnTouchTabOnly(player.Character) -- Use different setup function if needed, or same one
                end
            else
                disableBounceTabOnly() -- Use different disable function if needed, or same one
            end
            -- Update inputs based on toggle state
            bounceHeightTabInput:Set({ Enabled = state })
            epsilonTabInput:Set({ Enabled = state })
        end
    })
    bounceTabOnlyToggle:Set(featureStates.BounceTabOnly) -- Set initial state

    -- Bounce Height Input (for Tab Only version)
    local bounceHeightTabInput = Tabs.Player:Input({
        Title = "Bounce Height (Tab Only)",
        Placeholder = "0",
        Value = tostring(getgenv().BOUNCE_HEIGHT),
        Numeric = true,
        Enabled = featureStates.BounceTabOnly, -- Enabled based on toggle state
        Callback = function(value)
            local num = tonumber(value)
            if num then
                getgenv().BOUNCE_HEIGHT = math.max(0, num)
            end
        end
    }):Set(tostring(getgenv().BOUNCE_HEIGHT))

    -- Touch Epsilon Input (for Tab Only version)
    local epsilonTabInput = Tabs.Player:Input({
        Title = "Touch Epsilon (Tab Only)",
        Placeholder = "0.1",
        Value = tostring(getgenv().BOUNCE_EPSILON),
        Numeric = true,
        Enabled = featureStates.BounceTabOnly, -- Enabled based on toggle state
        Callback = function(value)
            local num = tonumber(value)
            if num then
                getgenv().BOUNCE_EPSILON = math.max(0, num)
            end
        end
    }):Set(tostring(getgenv().BOUNCE_EPSILON))


    -- Settings for Toggle UI Sizes
    Tabs.Settings:Section({ Title = "Movement Toggle UI Settings", TextSize = 20 })
    Tabs.Settings:Slider({
        Title = "Bhop Toggle Width",
        Value = { Min = 0.05, Max = 0.3, Default = bhopToggleXSize, Step = 0.01 },
        Callback = function(value)
            bhopToggleXSize = value
            if bhopGui and bhopGui:FindFirstChild("MainFrame") then
                bhopGui.MainFrame.Size = UDim2.new(value, 0, bhopToggleYSize, 0)
            end
        end
    })
    Tabs.Settings:Slider({
        Title = "Bhop Toggle Height",
        Value = { Min = 0.05, Max = 0.3, Default = bhopToggleYSize, Step = 0.01 },
        Callback = function(value)
            bhopToggleYSize = value
            if bhopGui and bhopGui:FindFirstChild("MainFrame") then
                bhopGui.MainFrame.Size = UDim2.new(bhopToggleXSize, 0, value, 0)
            end
        end
    })
    Tabs.Settings:Slider({
        Title = "Auto Crouch Toggle Width",
        Value = { Min = 0.05, Max = 0.3, Default = autoCrouchToggleXSize, Step = 0.01 },
        Callback = function(value)
            autoCrouchToggleXSize = value
            if autoCrouchGui and autoCrouchGui:FindFirstChild("MainFrame") then
                autoCrouchGui.MainFrame.Size = UDim2.new(value, 0, autoCrouchToggleYSize, 0)
            end
        end
    })
    Tabs.Settings:Slider({
        Title = "Auto Crouch Toggle Height",
        Value = { Min = 0.05, Max = 0.3, Default = autoCrouchToggleYSize, Step = 0.01 },
        Callback = function(value)
            autoCrouchToggleYSize = value
            if autoCrouchGui and autoCrouchGui:FindFirstChild("MainFrame") then
                autoCrouchGui.MainFrame.Size = UDim2.new(autoCrouchToggleXSize, 0, value, 0)
            end
        end
    })
    Tabs.Settings:Slider({
        Title = "Bounce (UI) Toggle Width",
        Value = { Min = 0.05, Max = 0.3, Default = bounceUIGuiToggleXSize, Step = 0.01 },
        Callback = function(value)
            bounceUIGuiToggleXSize = value
            if bounceUIGui and bounceUIGui:FindFirstChild("MainFrame") then
                bounceUIGui.MainFrame.Size = UDim2.new(value, 0, bounceUIGuiToggleYSize, 0)
            end
        end
    })
    Tabs.Settings:Slider({
        Title = "Bounce (UI) Toggle Height",
        Value = { Min = 0.05, Max = 0.3, Default = bounceUIGuiToggleYSize, Step = 0.01 },
        Callback = function(value)
            bounceUIGuiToggleYSize = value
            if bounceUIGui and bounceUIGui:FindFirstChild("MainFrame") then
                bounceUIGui.MainFrame.Size = UDim2.new(bounceUIGuiToggleXSize, 0, value, 0)
            end
        end
    })

end

-- --- Bhop Functionality ---
local function setFriction(value)
    if character and character:FindFirstChild("HumanoidRootPart") then
        character.HumanoidRootPart.CustomPhysicalProperties = PhysicalProperties.new(
            value, -- Custom friction
            0.3, -- Custom elasticity
            0.5, -- Custom density
            0.1, -- Custom friction weight
            0.1  -- Custom elasticity weight
        )
    end
end

RunService.Heartbeat:Connect(function()
    if getgenv().autoJumpEnabled then
        local friction = 5
        if getgenv().bhopMode == "Acceleration" then
            friction = getgenv().bhopAccelValue or -5
        end
        setFriction(friction)
    else
        setFriction(5) -- Default friction
    end
end)

-- --- Auto Crouch Functionality ---
local function startAutoCrouch()
    if getgenv().crouchConnection then getgenv().crouchConnection:Disconnect() end
    getgenv().crouchConnection = RunService.Heartbeat:Connect(function()
        if not character or not humanoid then return end
        if not humanoidRootPart then return end

        local currentState = humanoid:GetState()
        local isCrouching = currentState == Enum.HumanoidStateType.Climbing or
                           currentState == Enum.HumanoidStateType.Crouching or
                           humanoid.Sit

        if not isCrouching then
            if getgenv().autoCrouchMode == "air" then
                if currentState ~= Enum.HumanoidStateType.Freefall then return end
            elseif getgenv().autoCrouchMode == "ground" then
                if currentState ~= Enum.HumanoidStateType.Landed and
                   currentState ~= Enum.HumanoidStateType.Running and
                   currentState ~= Enum.HumanoidStateType.RunningNoPhysics then
                    return
                end
            end
            humanoid:ChangeState(Enum.HumanoidStateType.Crouching)
        end
    end)
end

local function stopAutoCrouch()
    if getgenv().crouchConnection then
        getgenv().crouchConnection:Disconnect()
        getgenv().crouchConnection = nil
    end
    -- Optionally, uncrouch the player when stopped
    if character and humanoid then
        humanoid:ChangeState(Enum.HumanoidStateType.Running)
    end
end

-- --- Bounce Functionality (for both UI and Tab versions) ---
-- Note: The core logic can be shared, the difference is in the toggle control.
local function bouncePlayer()
    if character and humanoidRootPart then
        local newVelocity = humanoidRootPart.Velocity
        humanoidRootPart.Velocity = Vector3.new(newVelocity.X, math.abs(newVelocity.Y) + getgenv().BOUNCE_HEIGHT, newVelocity.Z)
    end
end

local function onTouched(hit)
    -- Check either global variable depending on which version is active
    if not (getgenv().bounceEnabled or getgenv().bounceEnabledTabOnly) then return end
    local magnitude = humanoidRootPart.Velocity.Magnitude
    if magnitude > getgenv().BOUNCE_EPSILON then -- Use epsilon for sensitivity
        bouncePlayer()
    end
end

-- Shared setup and disable functions (assuming logic is the same)
local function setupBounceOnTouch(char)
    if not (getgenv().bounceEnabled or getgenv().bounceEnabledTabOnly) then return end -- Check either active version
    if getgenv().touchConnections[char] then
        getgenv().touchConnections[char]:Disconnect()
    end
    local humanoidRootPart = char:WaitForChild("HumanoidRootPart")
    local connection = humanoidRootPart.Touched:Connect(onTouched)
    getgenv().touchConnections[char] = connection
end

local function setupBounceOnTouchTabOnly(char)
    -- For the tab-only version, we can reuse the same setup if the logic is identical
    setupBounceOnTouch(char)
end

local function disableBounce()
    -- Disable for the UI toggle version
    for char, connection in pairs(getgenv().touchConnections) do
        if connection then
            connection:Disconnect()
            getgenv().touchConnections[char] = nil
        end
    end
end

local function disableBounceTabOnly()
    -- Disable for the tab-only version - can reuse if logic is identical
    disableBounce()
end

player.CharacterAdded:Connect(function(char)
    -- Setup for the currently active version (or both if they can run simultaneously, though unlikely)
    if getgenv().bounceEnabled then
        setupBounceOnTouch(char)
    end
    if getgenv().bounceEnabledTabOnly then
        setupBounceOnTouchTabOnly(char)
    end
end)

-- Initialize Player Character for Bounce if already exists
if player.Character then
    if getgenv().bounceEnabled then
        setupBounceOnTouch(player.Character)
    end
    if getgenv().bounceEnabledTabOnly then
        setupBounceOnTouchTabOnly(player.Character)
    end
end

-- --- Initialize UI ---
setupMovementHub()
