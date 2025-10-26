
if getgenv().DaraHubEvadeExecuted then
    return
end
getgenv().DaraHubEvadeExecuted = true

-- UI_MODE: "shim" (only WindUI-compat shim),
-- "fluent" (only Fluent-built UI mirror),
-- "both" (keep shim for compatibility and also build Fluent mirror)
local UI_MODE = "both" -- user requested both; change to "shim" or "fluent" if desired

-- Load Fluent (for Fluent mirror) and provide a WindUI-compatible shim
local successFluent, Fluent = pcall(function()
    return loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
end)
if not successFluent then
    Fluent = nil
end

-- WindUI compatibility shim (keeps variable names and API used by original script)
local WindUI = {}
WindUI._fluent = Fluent
WindUI._callbacks = { theme = {} }

-- minimal localization wrapper to accept original Localization(...) usage
function WindUI:Localization(tbl)
    local obj = { _tbl = tbl }
    function obj:Get(key)
        if not key then return key end
        if type(key) ~= "string" then return key end
        if tostring(key):sub(1,4) == "loc:" then
            local k = tostring(key):sub(5)
            local lang = (tbl.DefaultLanguage or "en")
            local t = tbl.Translations and tbl.Translations[lang]
            if t and t[k] then return t[k] end
            if tbl.Translations and tbl.Translations["en"] and tbl.Translations["en"][k] then
                return tbl.Translations["en"][k]
            end
            return k
        end
        return key
    end
    return obj
end

-- Theme helpers
local currentTheme = "Dark"
function WindUI:SetTheme(theme)
    currentTheme = theme or currentTheme
    if Fluent and Fluent.SetTheme then
        pcall(function() Fluent:SetTheme(currentTheme) end)
    end
    for _,cb in pairs(WindUI._callbacks.theme) do
        pcall(cb, currentTheme)
    end
end
function WindUI:GetCurrentTheme()
    return currentTheme
end
function WindUI:OnThemeChange(cb)
    if type(cb) == "function" then
        table.insert(WindUI._callbacks.theme, cb)
    end
end

-- Notify shim (maps to Fluent.Notify if available)
function WindUI:Notify(opts)
    local title = opts.Title or opts.TitleText or "Notification"
    local content = opts.Content or opts.Text or ""
    local duration = opts.Duration or 3
    pcall(function()
        if Fluent and Fluent.Notify then
            Fluent:Notify({ Title = title, Content = content, Duration = duration })
        else
            -- fallback: print
            print(("[Notify] %s: %s"):format(title, content))
        end
    end)
end

local function makeId(title)
    if not title then return "id" .. tostring(math.random(1,1e9)) end
    local id = tostring(title):gsub("%s+", ""):gsub("%W","")
    return id .. "_" .. tostring(math.random(1000,9999))
end

local WindUIOptions = {}
WindUI.Options = WindUIOptions

-- CreateWindow: returns a Window-like object with Section(...) and other helpers
function WindUI:CreateWindow(opts)
    local wopts = {
        Title = opts and (opts.Title or opts.TitleText) or "Zen Hub",
        SubTitle = opts and (opts.SubTitle or opts.SubTitleText) or "Fluent Shim",
        TabWidth = (opts and opts.TabWidth) or 160,
        Size = opts and opts.Size or UDim2.fromOffset(580, 490),
        Acrylic = opts and (opts.Acrylic == nil and false or opts.Acrylic),
        Theme = (opts and opts.Theme) or currentTheme,
        MinimizeKey = (opts and opts.MinimizeKey) or Enum.KeyCode.RightControl
    }
    local FWindow = nil
    if Fluent then
        local ok, wnd = pcall(function() return Fluent:CreateWindow(wopts) end)
        if ok then FWindow = wnd end
    end

    local Window = {}
    Window._fluentWindow = FWindow
    Window._tabs = {}

    function Window:SetIconSize(s) end
    function Window:Open() if FWindow and FWindow.Open then pcall(function() FWindow:Open() end) end end
    function Window:Close() if FWindow and FWindow.Close then pcall(function() FWindow:Close() end) end end
    function Window:IsOpen()
        if FWindow and FWindow.IsOpen then
            local ok, val = pcall(function() return FWindow:IsOpen() end)
            return ok and val or false
        end
        return false
    end
    function Window:OnOpen(cb) Window._onopen = cb end
    function Window:OnClose(cb) Window._onclose = cb end
    function Window:Tag(t) end
    function Window:CreateTopbarButton(id, icon, cb)
        if FWindow and FWindow.TopbarButton then
            pcall(function() FWindow:TopbarButton(id, {Icon = icon or "moon", Callback = cb}) end)
        end
    end
    function Window:Dialog(tab) if FWindow and FWindow.Dialog then pcall(function() FWindow:Dialog(tab) end) end end

    function Window:Section(sectionOpts)
        local Section = {}
        function Section:Tab(tabOpts)
            tabOpts = tabOpts or {}
            local title = tabOpts.Title or tabOpts.TitleText or "Tab"
            local ftab = nil
            if FWindow and FWindow.AddTab then
                pcall(function() ftab = FWindow:AddTab({ Title = title, Icon = tabOpts.Icon or "" }) end)
            end
            local Tab = {}
            Tab._fluentTab = ftab
            Tab._controls = {}
            function Tab:Section(opts)
                opts = opts or {}
                if ftab and ftab.AddLabel then
                    pcall(function() ftab:AddLabel({ Title = opts.Title or opts.TitleText or "", Description = opts.Desc or opts.Description or "" }) end)
                end
            end
            function Tab:Divider() if ftab and ftab.AddDivider then pcall(function() ftab:AddDivider() end) end end

            local function createControl(kind, conf)
                local id = conf._id or makeId(conf.Title or conf.title or kind)
                conf.Default = conf.Default or conf.Value or conf.DefaultValue
                WindUIOptions[id] = { Value = conf.Default, _meta = conf }
                local created = nil
                if ftab then
                    pcall(function()
                        if kind == "Toggle" and ftab.AddToggle then
                            created = ftab:AddToggle(id, { Title = conf.Title or id, Description = conf.Desc or "", Default = conf.Default or false })
                        elseif kind == "Slider" and ftab.AddSlider then
                            created = ftab:AddSlider(id, {
                                Title = conf.Title or id,
                                Description = conf.Desc or "",
                                Default = conf.Default or 0,
                                Min = conf.Min or (conf.Value and conf.Value.Min) or 0,
                                Max = conf.Max or (conf.Value and conf.Value.Max) or 100,
                                Rounding = conf.Rounding or (conf.Step or 1),
                                Callback = conf.Callback
                            })
                        elseif kind == "Dropdown" and ftab.AddDropdown then
                            created = ftab:AddDropdown(id, {
                                Title = conf.Title or id,
                                Values = conf.Values or conf.Choices or {},
                                Default = conf.DefaultIndex or 1,
                                Multi = conf.Multi or false
                            })
                        elseif kind == "Input" and ftab.AddInput then
                            created = ftab:AddInput(id, {
                                Title = conf.Title or id,
                                Placeholder = conf.Placeholder or conf.Desc or "",
                                Default = conf.Default or ""
                            })
                        elseif kind == "Button" and ftab.AddButton then
                            created = ftab:AddButton({
                                Title = conf.Title or id,
                                Description = conf.Desc or conf.Description or "",
                                Callback = conf.Callback or function() end
                            })
                        else
                            if ftab.AddLabel then
                                created = ftab:AddLabel({ Title = conf.Title or id, Description = conf.Description or "" })
                            end
                        end
                    end)
                end
                local wrapper = {}
                wrapper._id = id
                wrapper._kind = kind
                wrapper._fluentObj = created
                function wrapper:Set(key, value)
                    if type(key) == "table" and key.Enabled ~= nil then
                        if created and created.SetValue then created:SetValue(key.Enabled); WindUIOptions[id].Value = key.Enabled end
                        return
                    end
                    if key == true or key == false then
                        if created and created.SetValue then created:SetValue(key); WindUIOptions[id].Value = key end
                        return
                    end
                    if type(key) == "string" and value ~= nil then
                        if key == "Value" and created and created.SetValue then
                            created:SetValue(value); WindUIOptions[id].Value = value
                        else
                            WindUIOptions[id][key] = value
                        end
                        return
                    end
                    if created and created.SetValue then created:SetValue(key); WindUIOptions[id].Value = key end
                end
                function wrapper:Get() return WindUIOptions[id] and WindUIOptions[id].Value or nil end
                function wrapper:OnChanged(cb)
                    if created and created.OnChanged then
                        created:OnChanged(function(v) WindUIOptions[id].Value = v; pcall(cb, v) end)
                    else
                        wrapper._onchanged = cb
                    end
                end
                Tab._controls[id] = wrapper
                return wrapper
            end

            function Tab:Toggle(conf) return createControl("Toggle", conf) end
            function Tab:Slider(conf) return createControl("Slider", conf) end
            function Tab:Dropdown(conf) return createControl("Dropdown", conf) end
            function Tab:Input(conf) return createControl("Input", conf) end
            function Tab:Button(conf) return createControl("Button", conf) end
            function Tab:Tag(conf) return createControl("Tag", conf) end
            function Tab:Label(opts)
                if ftab and ftab.AddLabel then pcall(function() ftab:AddLabel({ Title = (opts and opts.Title) or opts or "", Description = (opts and opts.Desc) or "" }) end) end
            end

            Window._tabs[title] = Tab
            return Tab
        end
        return Section
    end

    function Window:SelectTab(idx) if FWindow and FWindow.SelectTab then pcall(function() FWindow:SelectTab(idx) end) end end
    Window.Fluent = FWindow
    return Window
end

_G.WindUI = WindUI

-- Build the main Window and Tabs expected by the rest of the script
local Window = WindUI:CreateWindow({
    Title = "Zen Hub",
    SubTitle = "Made by: Pnsdg And Yomka",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 490),
    Acrylic = false,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.RightControl
})

local FeatureSection = Window:Section({ Title = "loc:FEATURES", Opened = true })
local Tabs = {
    Main = FeatureSection:Tab({ Title = "Main", Icon = "layout-grid" }),
    Player = FeatureSection:Tab({ Title = "loc:Player_TAB", Icon = "user" }),
    Auto = FeatureSection:Tab({ Title = "loc:AUTO_TAB", Icon = "repeat-2" }),
    Visuals = FeatureSection:Tab({ Title = "loc:VISUALS_TAB", Icon = "camera" }),
    ESP = FeatureSection:Tab({ Title = "loc:ESP_TAB", Icon = "eye" }),
    Utility = FeatureSection:Tab({ Title = "Utility", Icon = "wrench"}),
    Teleport = FeatureSection:Tab({ Title = "Teleport", Icon = "navigation" }),
    Settings = FeatureSection:Tab({ Title = "loc:SETTINGS_TAB", Icon = "settings" })
}
WindUI.Window = Window
WindUI.Tabs = Tabs
WindUI:SetTheme("Dark")

-- If UI_MODE wants a Fluent mirror, build it after original script populates WindUI.Options
if UI_MODE ~= "shim" and Fluent then
    task.spawn(function()
        wait(0.8) -- allow original script to create WindUI options
        local ok, err = pcall(function()
            -- Build a Fluent mirror window
            local mirror = Fluent:CreateWindow({
                Title = "Zen Hub (Fluent Mirror)",
                SubTitle = "Mirror of WindUI options",
                Size = UDim2.fromOffset(700, 520),
                Theme = "Dark"
            })
            local tab = mirror:AddTab({ Title = "Mirror", Icon = "eye" })
            -- iterate options and create controls based on value type
            for id, info in pairs(WindUI.Options) do
                local meta = info._meta or {}
                local v = info.Value
                local display = meta.Title or id
                if type(v) == "boolean" then
                    tab:AddToggle(id, { Title = display, Description = meta.Description or meta.Desc or "" , Default = v }):OnChanged(function(val)
                        WindUI.Options[id].Value = val
                    end)
                elseif type(v) == "number" then
                    local minv = (meta.Min or 0)
                    local maxv = (meta.Max or (v*2) or 100)
                    tab:AddSlider(id, { Title = display, Description = meta.Description or "", Default = v, Min = minv, Max = maxv, Rounding = meta.Step or 1 })
                elseif type(v) == "string" then
                    -- if meta.Values present, create dropdown
                    if meta.Values and type(meta.Values) == "table" and #meta.Values > 0 then
                        tab:AddDropdown(id, { Title = display, Values = meta.Values, Default = 1 })
                    else
                        tab:AddInput(id, { Title = display, Default = v or "" })
                    end
                else
                    tab:AddLabel({ Title = display, Description = tostring(v) })
                end
            end
            mirror:SelectTab(1)
        end)
        if not ok then
            warn("Zen Hub: fluent mirror build failed:", err)
        end
    end)
end


local FeatureSection = Window:Section({ Title = "loc:FEATURES", Opened = true })

    local Tabs = {
    Main = FeatureSection:Tab({ Title = "Main", Icon = "layout-grid" }),
    Player = FeatureSection:Tab({ Title = "loc:Player_TAB", Icon = "user" }),
    Auto = FeatureSection:Tab({ Title = "loc:AUTO_TAB", Icon = "repeat-2" }),
    Visuals = FeatureSection:Tab({ Title = "loc:VISUALS_TAB", Icon = "camera" }),
    ESP = FeatureSection:Tab({ Title = "loc:ESP_TAB", Icon = "eye" }),
    Utility = FeatureSection:Tab({ Title = "Utility", Icon = "wrench"}),
    Teleport = FeatureSection:Tab({ Title = "Teleport", Icon = "navigation" }),
    Settings = FeatureSection:Tab({ Title = "loc:SETTINGS_TAB", Icon = "settings" })
    
}


-- Main Tab
Tabs.Main:Section({ Title = "Server Info", TextSize = 20 })
Tabs.Main:Divider()

local placeName = "Unknown"
local success, productInfo = pcall(function()
    return MarketplaceService:GetProductInfo(placeId)
end)
if success and productInfo then
    placeName = productInfo.Name
end

Tabs.Main:Paragraph({
    Title = "Game Mode",
    Desc = placeName
})

Tabs.Main:Button({
    Title = "Copy Server Link",
    Desc = "Copy the current server's join link",
    Icon = "link",
    Callback = function()
        local serverLink = getServerLink()
        pcall(function()
            setclipboard(serverLink)
        end)
        WindUI:Notify({
                Icon = "link",
                Title = "Link Copied",
                Content = "The server invite link has been copied to your clipborad",
                Duration = 3
        })
    end
})

local numPlayers = #Players:GetPlayers()
local maxPlayers = Players.MaxPlayers

Tabs.Main:Paragraph({
    Title = "Current Players",
    Desc = numPlayers .. " / " .. maxPlayers
})

Tabs.Main:Paragraph({
    Title = "Server ID",
    Desc = jobId
})

Tabs.Main:Paragraph({
    Title = "Place ID",
    Desc = tostring(placeId)
})

Tabs.Main:Section({ Title = "Server Tools", TextSize = 20 })
Tabs.Main:Divider()

Tabs.Main:Button({
    Title = "Rejoin",
    Desc = "Rejoin the current server",
    Icon = "refresh-cw",
    Callback = function()
        rejoinServer()
    end
})

Tabs.Main:Button({
    Title = "Server Hop",
    Desc = "Hop to a random server",
    Icon = "shuffle",
    Callback = function()
        serverHop()
    end
})

Tabs.Main:Button({
    Title = "Hop to Small Server",
    Desc = "Hop to the smallest available server",
    Icon = "minimize",
    Callback = function()
        hopToSmallServer()
    end
})

Tabs.Main:Button({
       Title = "Advanced Server Hop",
       Desc = "Finding a Server inside your game",
       Icon = "server",
       Callback = function()
           local success, result = pcall(function()
               local script = loadstring(game:HttpGet("https://raw.githubusercontent.com/Pnsdgsa/Script-kids/refs/heads/main/Advanced%20Server%20Hop.lua"))()
           end)
           if not success then
               WindUI:Notify({
                   Title = "Error",
                   Content = "Oopsie Daisy Some thing wrong happening with the Github Repository link, Unfortunately this script no longer exsit: " .. tostring(result),
                   Duration = 4
               })
           else
               WindUI:Notify({
                   Title = "Success",
                   Content = "Script Is Loaded",
                   Duration = 3
               })
           end
       end
   })
   Tabs.Main:Section({ Title = "Misc", TextSize = 20 })
   Tabs.Main:Divider()
   Tabs.Main:Button({
    Title = "Show/Hide Reload button",
    Desc = "This button allow you to use front view mode without keyboard or any tool in vip server",
    Icon = "switch-camera",
    Callback = function()
        if reloadVisible then
            if reloadButton then
                reloadButton.Visible = false
                reloadButton.Active = false
            end
            reloadVisible = false
        else
            reloadButton = game:GetService("Players").LocalPlayer.PlayerGui.Shared.HUD.Mobile.Right.Mobile.ReloadButton
            local originalParent = reloadButton.Parent
            reloadButton.Parent = nil
            wait()
            reloadButton.Parent = originalParent
            reloadButton.Visible = true
            reloadButton.Active = true
            reloadVisible = true
        end
    end
})
       local AntiAFKToggle = Tabs.Main:Toggle({
        Title = "loc:ANTI_AFK",
        Value = false,
        Callback = function(state)
            featureStates.AntiAFK = state
            if state then
                startAntiAFK()
            else
                stopAntiAFK()
            end
        end
    })
   -- Player Tabs
   Tabs.Player:Section({ Title = "Player", TextSize = 40 })
    Tabs.Player:Divider()

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local player = Players.LocalPlayer
local remoteEvent = ReplicatedStorage:WaitForChild("Events"):WaitForChild("Character"):WaitForChild("PassCharacterInfo")

local BOUNCE_HEIGHT = 0
local BOUNCE_EPSILON = 0.1
local BOUNCE_ENABLED = false
local touchConnections = {}

local function setupBounceOnTouch(character)
    if not BOUNCE_ENABLED then return end
    
    local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
    
    if touchConnections[character] then
        touchConnections[character]:Disconnect()
        touchConnections[character] = nil
    end
    
    local touchConnection
    touchConnection = humanoidRootPart.Touched:Connect(function(hit)
        local playerBottom = humanoidRootPart.Position.Y - humanoidRootPart.Size.Y / 2
        local playerTop = humanoidRootPart.Position.Y + humanoidRootPart.Size.Y / 2
        local hitBottom = hit.Position.Y - hit.Size.Y / 2
        local hitTop = hit.Position.Y + hit.Size.Y / 2
        
        if hitTop <= playerBottom + BOUNCE_EPSILON then
            return
        elseif hitBottom >= playerTop - BOUNCE_EPSILON then
            return
        end
        
        remoteEvent:FireServer({}, {2})
        
        if BOUNCE_HEIGHT > 0 then
            local bodyVel = Instance.new("BodyVelocity")
            bodyVel.MaxForce = Vector3.new(0, math.huge, 0)
            bodyVel.Velocity = Vector3.new(0, BOUNCE_HEIGHT, 0)
            bodyVel.Parent = humanoidRootPart
            Debris:AddItem(bodyVel, 0.2)
        end
    end)
    
    touchConnections[character] = touchConnection
    
    character.AncestryChanged:Connect(function()
        if not character.Parent then
            if touchConnections[character] then
                touchConnections[character]:Disconnect()
                touchConnections[character] = nil
            end
        end
    end)
end

local function disableBounce()
    for character, connection in pairs(touchConnections) do
        if connection then
            connection:Disconnect()
            touchConnections[character] = nil
        end
    end
end

if player.Character then
    setupBounceOnTouch(player.Character)
end

player.CharacterAdded:Connect(setupBounceOnTouch)

if Tabs and Tabs.Player then
    Tabs.Player:Section({ Title = "Bounce Settings", TextSize = 20 })
    
    local BounceToggle
    local BounceHeightInput
    local EpsilonInput
    
    BounceToggle = Tabs.Player:Toggle({
        Title = "Enable Bounce",
        Value = false,
        Callback = function(state)
            BOUNCE_ENABLED = state
            if state then
                if player.Character then
                    setupBounceOnTouch(player.Character)
                end
            else
                disableBounce()
            end
            BounceHeightInput:Set({ Enabled = state })
            EpsilonInput:Set({ Enabled = state })
        end
    })

    BounceHeightInput = Tabs.Player:Input({
        Title = "Bounce Height",
        Placeholder = "0",
        Value = tostring(BOUNCE_HEIGHT),
        Numeric = true,
        Enabled = false,
        Callback = function(value)
            local num = tonumber(value)
            if num then
                BOUNCE_HEIGHT = math.max(0, num)
            end
        end
    })

    EpsilonInput = Tabs.Player:Input({
        Title = "Touch Detection Epsilon",
        Placeholder = "0.1",
        Value = tostring(BOUNCE_EPSILON),
        Numeric = true,
        Enabled = false,
        Callback = function(value)
            local num = tonumber(value)
            if num then
                BOUNCE_EPSILON = math.max(0, num)
            end
        end
    })
end
    local InfiniteJumpToggle = Tabs.Player:Toggle({
        Title = "loc:INFINITE_JUMP",
        Value = false,
        Callback = function(state)
            featureStates.InfiniteJump = state
        end
    })

    local JumpMethodDropdown = Tabs.Player:Dropdown({
        Title = "loc:JUMP_METHOD",
        Values = {"Hold", "Spam"},
        Value = "Hold",
        Callback = function(value)
            featureStates.JumpMethod = value
        end
    })

local infiniteSlideEnabled = false
local slideFrictionValue = -8
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")

local keys = {
    "Friction", "AirStrafeAcceleration", "JumpHeight", "RunDeaccel",
    "JumpSpeedMultiplier", "JumpCap", "SprintCap", "WalkSpeedMultiplier",
    "BhopEnabled", "Speed", "AirAcceleration", "RunAccel", "SprintAcceleration"
}

local function hasAll(tbl)
    if type(tbl) ~= "table" then return false end
    for _, k in ipairs(keys) do
        if rawget(tbl, k) == nil then return false end
    end
    return true
end

local cachedTables = nil
local plrModel = nil
local slideConnection = nil

local function getConfigTables()
    local tables = {}
    for _, obj in ipairs(getgc(true)) do
        local success, result = pcall(function()
            if hasAll(obj) then return obj end
        end)
        if success and result then
            table.insert(tables, obj)
        end
    end
    return tables
end

local function setFriction(value)
    if not cachedTables then return end
    for _, t in ipairs(cachedTables) do
        pcall(function()
            t.Friction = value
        end)
    end
end

local function updatePlayerModel()
    local GameFolder = workspace:FindFirstChild("Game")
    local PlayersFolder = GameFolder and GameFolder:FindFirstChild("Players")
    if PlayersFolder then
        plrModel = PlayersFolder:FindFirstChild(LocalPlayer.Name)
    else
        plrModel = nil
    end
end

local function onHeartbeat()
    if not plrModel then
        setFriction(5)
        return
    end
    local success, currentState = pcall(function()
        return plrModel:GetAttribute("State")
    end)
    if success and currentState then
        if currentState == "Slide" then
            pcall(function()
                plrModel:SetAttribute("State", "EmotingSlide")
            end)
        elseif currentState == "EmotingSlide" then
            setFriction(slideFrictionValue)
        else
            setFriction(5)
        end
    else
        setFriction(5)
    end
end

local InfiniteSlideToggle = Tabs.Player:Toggle({
    Title = "Infinite Slide",
    Value = false,
    Callback = function(state)
        infiniteSlideEnabled = state
        if slideConnection then
            slideConnection:Disconnect()
            slideConnection = nil
        end
        if state then
            cachedTables = getConfigTables()
            updatePlayerModel()
            slideConnection = RunService.Heartbeat:Connect(onHeartbeat)
            LocalPlayer.CharacterAdded:Connect(function()
                task.wait(0.1)
                updatePlayerModel()
            end)
        else
            cachedTables = nil
            plrModel = nil
            setFriction(5)
        end
    end,
})

local InfiniteSlideSpeedInput = Tabs.Player:Input({
    Title = "Set Infinite Slide Speed (Negative Only)",
    Value = tostring(slideFrictionValue),
    Placeholder = "-8 (negative only)",
    Callback = function(text)
        local num = tonumber(text)
        if num and num < 0 then
            slideFrictionValue = num
        end
    end,
})
    local FlyToggle = Tabs.Player:Toggle({
        Title = "loc:FLY",
        Value = false,
        Callback = function(state)
            featureStates.Fly = state
            if state then
                startFlying()
            else
                stopFlying()
            end
        end
    })
local noclipConnections = {}
local noclipEnabled = false

local function setNoCollision()
    for _, object in pairs(workspace:GetDescendants()) do
        if object:IsA("BasePart") and not object:IsDescendantOf(player.Character) then
            object.CanCollide = false
        end
    end
end

local function restoreCollisions()
    for _, object in pairs(workspace:GetDescendants()) do
        if object:IsA("BasePart") and not object:IsDescendantOf(player.Character) then
            object.CanCollide = true
        end
    end
end

local function checkPlayerPosition()
    if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then return end
    local humanoidRootPart = player.Character.HumanoidRootPart
    local rayOrigin = humanoidRootPart.Position
    local rayDistance = math.clamp(10, 1, 50)  
    local rayDirection = Vector3.new(0, -rayDistance, 0)
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {player.Character}
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    local raycastResult = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
    if raycastResult and raycastResult.Instance:IsA("BasePart") then
        raycastResult.Instance.CanCollide = true
    end
    for _, object in pairs(workspace:GetDescendants()) do
        if object:IsA("BasePart") and object ~= (raycastResult and raycastResult.Instance) and not object:IsDescendantOf(player.Character) then
            object.CanCollide = false
        end
    end
end

local function onCharacterAdded(newCharacter)
    character = newCharacter
    humanoidRootPart = newCharacter:WaitForChild("HumanoidRootPart")
    if noclipEnabled then
        setNoCollision()
    end
end

    local FlySpeedSlider = Tabs.Player:Slider({
        Title = "loc:FLY_SPEED",
        Value = { Min = 1, Max = 200, Default = 5, Step = 1 },
                Desc = "Adjust fly speed",
        Callback = function(value)
            featureStates.FlySpeed = value
        end
    })
local NoclipToggle = Tabs.Player:Toggle({
    Title = "Noclip",
    Desc = "Note: This feature Can make you fall to the void non-stop so be careful what you're doing when toggles this on",
    Icon = "ghost",
    Callback = function(state)
        noclipEnabled = state
        if state then
            character = player.Character
            humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")
            if character then
                setNoCollision()
            end
            noclipConnections.characterAdded = player.CharacterAdded:Connect(onCharacterAdded)
            noclipConnections.descendantAdded = workspace.DescendantAdded:Connect(function(descendant)
                if noclipEnabled and descendant:IsA("BasePart") and not descendant:IsDescendantOf(player.Character) then
                    descendant.CanCollide = false
                end
            end)
            noclipConnections.heartbeat = RunService.Heartbeat:Connect(checkPlayerPosition)
        else
            for _, conn in pairs(noclipConnections) do
                if conn then conn:Disconnect() end
            end
            noclipConnections = {}
            restoreCollisions()
        end
    end
})
    local TPWALKToggle = Tabs.Player:Toggle({
        Title = "loc:TPWALK",
        Value = false,
        Callback = function(state)
            featureStates.TPWALK = state
            if state then
                startTpwalk()
            else
                stopTpwalk()
            end
        end
    })

    local TPWALKSlider = Tabs.Player:Slider({
        Title = "loc:TPWALK_VALUE",
         Desc = "Adjust TPWALK speed",
        Value = { Min = 1, Max = 200, Default = 1, Step = 1 },
        Callback = function(value)
            featureStates.TpwalkValue = value
        end
    })

    local JumpBoostToggle = Tabs.Player:Toggle({
        Title = "loc:JUMP_HEIGHT",
        Value = false,
        Callback = function(state)
            featureStates.JumpBoost = state
            if state then
                startJumpBoost()
            else
                stopJumpBoost()
            end
        end
    })

    local JumpBoostSlider = Tabs.Player:Slider({
        Title = "loc:JUMP_POWER",
        Desc = "Adjust jump height",
        Value = { Min = 1, Max = 200, Default = 5, Step = 1 },
        Callback = function(value)
            featureStates.JumpPower = value
            if featureStates.JumpBoost then
                if humanoid then
                    humanoid.JumpPower = featureStates.JumpPower
                end
            end
        end
    })

Tabs.Player:Section({ Title = "Modifications" })

local function createValidatedInput(config)
    return function(input)
        local val = tonumber(input)
        if not val then return end
        
        if config.min and val < config.min then return end
        if config.max and val > config.max then return end
        
        currentSettings[config.field] = tostring(val)
        applyToTables(function(obj)
            obj[config.field] = val
        end)
    end
end

local SpeedInput = Tabs.Player:Input({
    Title = "Set Speed",
    Icon = "speedometer",
    Placeholder = "Default 1500",
    Value = currentSettings.Speed,
    Callback = createValidatedInput({
        field = "Speed",
        min = 1450,
        max = 100008888
    })
})

local JumpCapInput = Tabs.Player:Input({
    Title = "Set Jump Cap",
    Icon = "chevrons-up",
    Placeholder = "Default 1",
    Value = currentSettings.JumpCap,
    Callback = createValidatedInput({
        field = "JumpCap",
        min = 0.1,
        max = 5088888
    })
})

local StrafeInput = Tabs.Player:Input({
    Title = "Strafe Acceleration",
    Icon = "wind",
    Placeholder = "Default 187",
    Value = currentSettings.AirStrafeAcceleration,
    Callback = createValidatedInput({
        field = "AirStrafeAcceleration",
        min = 1,
        max = 1000888888
    })
})

local ApplyMethodDropdown = Tabs.Player:Dropdown({
    Title = "Select Apply Method",
    Values = { "Not Optimized", "Optimized" },
    Multi = false,
    Default = getgenv().ApplyMode,
    Callback = function(value)
        getgenv().ApplyMode = value
    end
})
    -- Visuals Tab
    Tabs.Visuals:Section({ Title = "Visual", TextSize = 20 })
    Tabs.Visuals:Divider()
    local cameraStretchConnection
local function setupCameraStretch()
    cameraStretchConnection = nil
    local stretchHorizontal = 0.80
    local stretchVertical = 0.80
    local CameraStretchToggle = Tabs.Visuals:Toggle({
        Title = "Camera Stretch",
        Value = false,
        Callback = function(state)
            if state then
                if cameraStretchConnection then cameraStretchConnection:Disconnect() end
                cameraStretchConnection = game:GetService("RunService").RenderStepped:Connect(function()
                    local Camera = workspace.CurrentCamera
                    Camera.CFrame = Camera.CFrame * CFrame.new(0, 0, 0, stretchHorizontal, 0, 0, 0, stretchVertical, 0, 0, 0, 1)
                end)
            else
                if cameraStretchConnection then
                    cameraStretchConnection:Disconnect()
                    cameraStretchConnection = nil
                end
            end
        end
    })

    local CameraStretchHorizontalInput = Tabs.Visuals:Input({
        Title = "Camera Stretch Horizontal",
        Placeholder = "0.80",
        Numeric = true,
        Value = tostring(stretchHorizontal),
        Callback = function(value)
            local num = tonumber(value)
            if num then
                stretchHorizontal = num
                if cameraStretchConnection then
                    cameraStretchConnection:Disconnect()
                    cameraStretchConnection = game:GetService("RunService").RenderStepped:Connect(function()
                        local Camera = workspace.CurrentCamera
                        Camera.CFrame = Camera.CFrame * CFrame.new(0, 0, 0, stretchHorizontal, 0, 0, 0, stretchVertical, 0, 0, 0, 1)
                    end)
                end
            end
        end
    })

    local CameraStretchVerticalInput = Tabs.Visuals:Input({
        Title = "Camera Stretch Vertical",
        Placeholder = "0.80",
        Numeric = true,
        Value = tostring(stretchVertical),
        Callback = function(value)
            local num = tonumber(value)
            if num then
                stretchVertical = num
                if cameraStretchConnection then
                    cameraStretchConnection:Disconnect()
                    cameraStretchConnection = game:GetService("RunService").RenderStepped:Connect(function()
                        local Camera = workspace.CurrentCamera
                        Camera.CFrame = Camera.CFrame * CFrame.new(0, 0, 0, stretchHorizontal, 0, 0, 0, stretchVertical, 0, 0, 0, 1)
                    end)
                end
            end
        end
    })
end

setupCameraStretch()


local module_upvr = {}
module_upvr.__index = module_upvr

local currentModuleInstance = nil

function module_upvr.new()
    if currentModuleInstance then
        currentModuleInstance = nil
    end

    local player = game.Players.LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui", 5)
    local self = setmetatable({
        Player = player,
        Enabled = false,
        Visible = false,
    }, module_upvr)

    local nextbotNoise
    local success, err = pcall(function()
        local shared = playerGui:FindFirstChild("Shared")
        if shared then
            local hud = shared:FindFirstChild("HUD")
            if hud then
                nextbotNoise = hud:FindFirstChild("NextbotNoise")
            end
        end
        if not nextbotNoise then
            local hud = playerGui:FindFirstChild("HUD")
            if hud then
                nextbotNoise = hud:FindFirstChild("NextbotNoise")
            end
        end
        if not nextbotNoise then
            nextbotNoise = playerGui:FindFirstChild("NextbotNoise")
        end
    end)

    if not success or not nextbotNoise then
        warn("Failed to find NextbotNoise in PlayerGui: " .. (err or "Unknown error"))
        return self
    end

    self.originalSize = nextbotNoise.Size
    self.originalPosition = nextbotNoise.Position
    self.originalImageTransparency = nextbotNoise.ImageTransparency
    self.originalNoiseTransparency = nextbotNoise:FindFirstChild("Noise") and nextbotNoise.Noise.ImageTransparency or 0
    self.originalNoise2Transparency = nextbotNoise:FindFirstChild("Noise2") and nextbotNoise.Noise2.ImageTransparency or 0

    local transparencySuccess, transparencyErr = pcall(function()
        local inset = game:GetService("GuiService"):GetGuiInset()
        nextbotNoise.Position = UDim2.new(0.5, 0, 0, -inset.Y)
        nextbotNoise.Size = UDim2.new(0, 0, 0, 0)
        nextbotNoise.ImageTransparency = 1
        if nextbotNoise:FindFirstChild("Noise") then
            nextbotNoise.Noise.ImageTransparency = 1
        else
            warn("Noise not found in NextbotNoise")
        end
        if nextbotNoise:FindFirstChild("Noise2") then
            nextbotNoise.Noise2.ImageTransparency = 1
        else
            warn("Noise2 not found in NextbotNoise")
        end
    end)

    if not transparencySuccess then
        warn("Failed to set vignette properties: " .. transparencyErr)
    end

    self.Noise = nextbotNoise
    currentModuleInstance = self
    return self
end

function module_upvr.stop(self)
    if self.Noise then
        local success, err = pcall(function()
            self.Noise.Size = self.originalSize
            self.Noise.Position = self.originalPosition
            self.Noise.ImageTransparency = self.originalImageTransparency
            if self.Noise:FindFirstChild("Noise") then
                self.Noise.Noise.ImageTransparency = self.originalNoiseTransparency
            end
            if self.Noise:FindFirstChild("Noise2") then
                self.Noise.Noise2.ImageTransparency = self.originalNoise2Transparency
            end
        end)
        if not success then
            warn("Failed to restore vignette properties: " .. err)
        end
    end
    currentModuleInstance = nil
end

function module_upvr.Update(arg1, arg2)
    if arg1 and arg1.Noise then
        local success, err = pcall(function()
            if arg1.Noise:IsA("ImageLabel") or arg1.Noise:IsA("Frame") then
                arg1.Noise.ImageTransparency = 1
                if arg1.Noise:FindFirstChild("Noise") then
                    arg1.Noise.Noise.ImageTransparency = 1
                end
                if arg1.Noise:FindFirstChild("Noise2") then
                    arg1.Noise.Noise2.ImageTransparency = 1
                end
            end
        end)
        if not success then
            warn("Update failed to set transparencies: " .. err)
        end
    end
end



local stableCameraInstance = nil

local StableCamera = {}
StableCamera.__index = StableCamera

function StableCamera.new(maxDistance)
    local self = setmetatable({}, StableCamera)
    self.Player = Players.LocalPlayer
    self.MaxDistance = maxDistance or 50
    self._conn = RunService.RenderStepped:Connect(function(dt) self:Update(dt) end)
    return self
end

local function tryResetShake(player)
    if not player then return end
    local ok, playerScripts = pcall(function() return player:FindFirstChild("PlayerScripts") end)
    if not ok or not playerScripts then return end
    local cameraSet = playerScripts:FindFirstChild("Camera") and playerScripts.Camera:FindFirstChild("Set")
    if cameraSet and type(cameraSet.Invoke) == "function" then
        pcall(function()
            cameraSet:Invoke("CFrameOffset", "Shake", CFrame.new())
        end)
    end
end

function StableCamera:Update(dt)
    if Players and Players.LocalPlayer then
        tryResetShake(Players.LocalPlayer)
    end
end

function StableCamera:Destroy()
    if self._conn then
        self._conn:Disconnect()
        self._conn = nil
    end
end

local DisableCameraShakeToggle = Tabs.Visuals:Toggle({
    Title = "Disable Camera Shake",
    Value = false,
    Callback = function(state)
        featureStates.DisableCameraShake = state
        if state then
            if stableCameraInstance then
                stableCameraInstance:Destroy()
                stableCameraInstance = nil
            end
            stableCameraInstance = StableCamera.new(50)
            pcall(function()
                WindUI:Notify({ Title = "Camera", Content = "Camera shake disabled", Duration = 0 })
            end)
        else
            if stableCameraInstance then
                stableCameraInstance:Destroy()
                stableCameraInstance = nil
            end
            pcall(function()
                WindUI:Notify({ Title = "Camera", Content = "Camera shake enabled", Duration = 0 })
            end)
        end
    end
})

local vignetteEnabled = false

local Disablevignette = Tabs.Visuals:Toggle({
    Title = "Disable Vignette",
    Default = false,
    Callback = function(value)
        vignetteEnabled = value
        if value then
            local vignetteInstance = module_upvr.new()
            if vignetteInstance then
                vignetteConnection = game:GetService("RunService").Heartbeat:Connect(function(dt)
                    module_upvr.Update(vignetteInstance, dt)
                end)
            end
        else
            if vignetteConnection then
                vignetteConnection:Disconnect()
                vignetteConnection = nil
            end
            if currentModuleInstance then
                module_upvr.stop(currentModuleInstance)
            end
        end
    end
})

game.Players.LocalPlayer.CharacterAdded:Connect(function()
    warn("Player respawned - checking vignette disable")
    wait(1)
    
    if vignetteEnabled then
        warn("Reapplying vignette disable after respawn")
        local vignetteInstance = module_upvr.new()
        if vignetteInstance then
            if vignetteConnection then
                vignetteConnection:Disconnect()
            end
            vignetteConnection = game:GetService("RunService").Heartbeat:Connect(function(dt)
                module_upvr.Update(vignetteInstance, dt)
            end)
        end
    end
end)

	    local FullBrightToggle = Tabs.Visuals:Toggle({
        Title = "loc:FULL_BRIGHT",
        Value = false,
        Callback = function(state)
            featureStates.FullBright = state
            if state then
                startFullBright()
            else
                stopFullBright()
            end
        end
    })

local NoFogToggle = Tabs.Visuals:Toggle({
    Title = "loc:NO_FOG",
    Value = false,
    Callback = function(state)
        featureStates.NoFog = state
        if state then
            startNoFog()
        else
            stopNoFog()
        end
    end
})
local originalFOV = workspace.CurrentCamera.FieldOfView
local FOVSlider = Tabs.Visuals:Slider({
    Title = "Field of View",
    Desc = "Old fov has been moved to settings, will be add back in here soon",
    Value = { Min = 10, Max = 120, Default = originalFOV, Step = 1 },
    Callback = function(value)
        workspace.CurrentCamera.FieldOfView = tonumber(value)
    end
})
local TimerDisplayToggle = Tabs.Visuals:Toggle({
    Title = "Timer Display",
    Value = false,
    Callback = function(state)
        featureStates.TimerDisplay = state
        if state then
            pcall(function()
                local Players = game:GetService("Players")
                local LocalPlayer = Players.LocalPlayer
                local PlayerGui = LocalPlayer.PlayerGui
                local MainInterface = PlayerGui:WaitForChild("MainInterface")
                local TimerContainer = MainInterface:WaitForChild("TimerContainer")
                TimerContainer.Visible = true
            end)
            
            task.spawn(function()
                while featureStates.TimerDisplay do
                    local success, result = pcall(function()
                        local Players = game:GetService("Players")
                        local player = Players.LocalPlayer
                        
                        if not player then
                            return false
                        end
                        
                        local playerGui = player:FindFirstChild("PlayerGui")
                        if not playerGui then
                            return false
                        end
                        
                        local shared = playerGui:WaitForChild("Shared", 1)
                        if not shared then
                            return false
                        end
                        
                        local hud = shared:WaitForChild("HUD", 1)
                        if not hud then
                            return false
                        end
                        
                        local overlay = hud:WaitForChild("Overlay", 1)
                        if not overlay then
                            return false
                        end
                        
                        local default = overlay:WaitForChild("Default", 1)
                        if not default then
                            return false
                        end
                        
                        local roundOverlay = default:WaitForChild("RoundOverlay", 1)
                        if not roundOverlay then
                            return false
                        end
                        
                        local round = roundOverlay:WaitForChild("Round", 1)
                        if not round then
                            return false
                        end
                        
                        local roundTimer = round:WaitForChild("RoundTimer", 1)
                        if not roundTimer then
                            return false
                        end
                        
                        roundTimer.Visible = false
                        return true
                    end)
                    
                    if not success or not result then
                        task.wait(0)
                    else
                        task.wait(0)
                    end
                end
            end)
        else
            pcall(function()
                local Players = game:GetService("Players")
                local LocalPlayer = Players.LocalPlayer
                local PlayerGui = LocalPlayer.PlayerGui
                local MainInterface = PlayerGui:WaitForChild("MainInterface")
                local TimerContainer = MainInterface:WaitForChild("TimerContainer")
                TimerContainer.Visible = false
            end)
        end
    end
})

    -- ESP Tab
    Tabs.ESP:Section({ Title = "ESP", TextSize = 40 })
    Tabs.ESP:Divider()
    Tabs.ESP:Section({ Title = "Player ESP" })
    local PlayerNameESPToggle = Tabs.ESP:Toggle({
        Title = "loc:PLAYER_NAME_ESP",
        Value = false,
        Callback = function(state)
            featureStates.PlayerESP.names = state
            if state or featureStates.PlayerESP.boxes or featureStates.PlayerESP.tracers or featureStates.PlayerESP.distance then
                startPlayerESP()
            else
                stopPlayerESP()
            end
        end
    })

    local PlayerBoxESPToggle = Tabs.ESP:Toggle({
        Title = "loc:PLAYER_BOX_ESP",
        Value = false,
        Callback = function(state)
            featureStates.PlayerESP.boxes = state
            if state or featureStates.PlayerESP.tracers or featureStates.PlayerESP.names or featureStates.PlayerESP.distance then
                startPlayerESP()
            else
                stopPlayerESP()
            end
        end
    })

    local PlayerBoxTypeDropdown = Tabs.ESP:Dropdown({
        Title = "Player Box Type",
        Values = {"2D", "3D"},
        Value = "2D",
        Callback = function(value)
            featureStates.PlayerESP.boxType = value
        end
    })

    local PlayerRainbowBoxesToggle = Tabs.ESP:Toggle({
        Title = "loc:PLAYER_RAINBOW_BOXES",
        Value = false,
        Callback = function(state)
            featureStates.PlayerESP.rainbowBoxes = state
            if featureStates.PlayerESP.boxes then
                stopPlayerESP()
                startPlayerESP()
            end
        end
    })

    local PlayerTracerToggle = Tabs.ESP:Toggle({
        Title = "loc:PLAYER_TRACER",
        Value = false,
        Callback = function(state)
            featureStates.PlayerESP.tracers = state
            if state or featureStates.PlayerESP.boxes or featureStates.PlayerESP.names or featureStates.PlayerESP.distance then
                startPlayerESP()
            else
                stopPlayerESP()
            end
        end
    })
    local PlayerRainbowTracersToggle = Tabs.ESP:Toggle({
        Title = "loc:PLAYER_RAINBOW_TRACERS",
        Value = false,
        Callback = function(state)
            featureStates.PlayerESP.rainbowTracers = state
            if featureStates.PlayerESP.tracers then
                stopPlayerESP()
                startPlayerESP()
            end
        end
    })

    local PlayerDistanceESPToggle = Tabs.ESP:Toggle({
        Title = "loc:PLAYER_DISTANCE_ESP",
        Value = false,
        Callback = function(state)
            featureStates.PlayerESP.distance = state
            if state or featureStates.PlayerESP.boxes or featureStates.PlayerESP.tracers or featureStates.PlayerESP.names then
                startPlayerESP()
            else
                stopPlayerESP()
            end
        end
    })

    Tabs.ESP:Section({ Title = "Nextbot Name ESP" })

local NextbotESPToggle = Tabs.ESP:Toggle({
    Title = "loc:NEXTBOT_NAME_ESP",
    Value = false,
    Callback = function(state)
        featureStates.NextbotESP.names = state
        if state then
            startNextbotNameESP()
            setupNextbotDetection()
        else
            stopNextbotNameESP()
        end
    end
})

local NextbotBoxESPToggle = Tabs.ESP:Toggle({
    Title = "Nextbot Box ESP",
    Value = false,
    Callback = function(state)
        featureStates.NextbotESP.boxes = state
        if state or featureStates.NextbotESP.names or featureStates.NextbotESP.tracers or featureStates.NextbotESP.distance then
            startNextbotNameESP()
        else
            stopNextbotNameESP()
        end
    end
})

local NextbotBoxTypeDropdown = Tabs.ESP:Dropdown({
    Title = "Nextbot Box Type",
    Values = {"2D", "3D"},
    Value = "2D",
    Callback = function(value)
        featureStates.NextbotESP.boxType = value
    end
})
local NextbotRainbowBoxesToggle = Tabs.ESP:Toggle({
    Title = "Nextbot Rainbow Boxes",
    Value = false,
    Callback = function(state)
        featureStates.NextbotESP.rainbowBoxes = state
        if featureStates.NextbotESP.boxes then
            stopNextbotNameESP()
            startNextbotNameESP()
        end
    end
})
local NextbotTracerToggle = Tabs.ESP:Toggle({
    Title = "Nextbot Tracer",
    Value = false,
    Callback = function(state)
        featureStates.NextbotESP.tracers = state
        if state or featureStates.NextbotESP.names or featureStates.NextbotESP.boxes or featureStates.NextbotESP.distance then
            startNextbotNameESP()
        else
            stopNextbotNameESP()
        end
    end
})
local NextbotRainbowTracersToggle = Tabs.ESP:Toggle({
    Title = "Nextbot Rainbow Tracers",
    Value = false,
    Callback = function(state)
        featureStates.NextbotESP.rainbowTracers = state
        if featureStates.NextbotESP.tracers then
            stopNextbotNameESP()
            startNextbotNameESP()
        end
    end
})
local NextbotDistanceESPToggle = Tabs.ESP:Toggle({
    Title = "Nextbot Distance ESP",
    Value = false,
    Callback = function(state)
        featureStates.NextbotESP.distance = state
        if state or featureStates.NextbotESP.names or featureStates.NextbotESP.boxes or featureStates.NextbotESP.tracers then
            startNextbotNameESP()
        else
            stopNextbotNameESP()
        end
    end
})


    Tabs.ESP:Section({ Title = "Downed Player ESP" })

    local DownedBoxESPToggle = Tabs.ESP:Toggle({
        Title = "loc:DOWNED_BOX_ESP",
        Value = false,
        Callback = function(state)
            featureStates.DownedBoxESP = state
            if state or featureStates.DownedTracer then
                if downedTracerConnection then stopDownedTracer() end
                startDownedTracer()
            else
                stopDownedTracer()
            end
        end
    })

    local DownedBoxTypeDropdown = Tabs.ESP:Dropdown({
        Title = "Downed Box Type",
        Values = {"2D", "3D"},
        Value = "2D",
        Callback = function(value)
            featureStates.DownedBoxType = value
        end
    })

    local DownedTracerToggle = Tabs.ESP:Toggle({
        Title = "loc:DOWNED_TRACER",
        Value = false,
        Callback = function(state)
            featureStates.DownedTracer = state
            if state or featureStates.DownedBoxESP then
                if downedTracerConnection then stopDownedTracer() end
                startDownedTracer()
            else
                stopDownedTracer()
            end
        end
    })

    local DownedNameESPToggle = Tabs.ESP:Toggle({
        Title = "loc:DOWNED_NAME_ESP",
        Value = false,
        Callback = function(state)
            featureStates.DownedNameESP = state
            if state then
                startDownedNameESP()
            else
                stopDownedNameESP()
            end
        end
    })

    local DownedDistanceESPToggle = Tabs.ESP:Toggle({
        Title = "loc:DOWNED_DISTANCE_ESP",
        Value = false,
        Callback = function(state)
            featureStates.DownedDistanceESP = state
            if featureStates.DownedNameESP then
                stopDownedNameESP()
                startDownedNameESP()
            end
        end
    })
Tabs.ESP:Section({ Title = "Ticket ESP" })
local TicketEspToggle = Tabs.ESP:Toggle({
    Title = "Ticket ESP",
    Value = false,
    Callback = function(state)
        if getgenv().ticketEspConnections then
            for _, connection in ipairs(getgenv().ticketEspConnections) do
                connection:Disconnect()
            end
            getgenv().ticketEspConnections = nil
        end
        if getgenv().ticketEspLabels then
            for _, label in pairs(getgenv().ticketEspLabels) do
                label:Remove()
            end
            getgenv().ticketEspLabels = nil
        end

        if state then
            local espConnections = {}
            local espLabels = {}
            local tickets = workspace:FindFirstChild("Game") and workspace.Game:FindFirstChild("Effects") and workspace.Game.Effects:FindFirstChild("Tickets")

            local function updateEsp()
                if not tickets then return end
                
                for ticket, label in pairs(espLabels) do
                    if not ticket.Parent or not ticket:FindFirstChild("HumanoidRootPart") then
                        label:Remove()
                        espLabels[ticket] = nil
                    end
                end
                
                for _, ticket in ipairs(tickets:GetChildren()) do
                    if ticket:FindFirstChild("HumanoidRootPart") and not espLabels[ticket] then
                        local label = Drawing.new("Text")
                        label.Visible = false
                        label.Text = "Ticket"
                        label.Color = Color3.fromRGB(0, 0, 255) 
                        label.Size = 20
                        label.Center = true
                        label.Outline = true
                        espLabels[ticket] = label
                    end
                end
                
                local camera = workspace.CurrentCamera
                if not camera then return end
                for ticket, label in pairs(espLabels) do
                    local ticketPart = ticket:FindFirstChild("HumanoidRootPart")
                    if ticketPart then
                        local screenPos, onScreen = camera:WorldToViewportPoint(ticketPart.Position)
                        label.Visible = onScreen
                        if onScreen then
                            label.Position = Vector2.new(screenPos.X, screenPos.Y - 30)
                        end
                    end
                end
            end
            
            updateEsp()
            
            table.insert(espConnections, RunService.RenderStepped:Connect(updateEsp))
            if tickets then
                table.insert(espConnections, tickets.ChildAdded:Connect(updateEsp))
                table.insert(espConnections, tickets.ChildRemoved:Connect(updateEsp))
            end
            
            getgenv().ticketEspConnections = espConnections
            getgenv().ticketEspLabels = espLabels
        end
    end
})

local TicketTracerEspToggle = Tabs.ESP:Toggle({
    Title = "Ticket Tracer ESP",
    Value = false,
    Callback = function(state)
        if getgenv().ticketTracerConnections then
            for _, connection in ipairs(getgenv().ticketTracerConnections) do
                connection:Disconnect()
            end
            getgenv().ticketTracerConnections = nil
        end
        if getgenv().ticketTracerDrawings then
            for _, drawings in pairs(getgenv().ticketTracerDrawings) do
                for _, drawing in ipairs(drawings) do
                    drawing:Remove()
                end
            end
            getgenv().ticketTracerDrawings = nil
        end

        if state then
            local tracerConnections = {}
            local tracerDrawings = {}
            local tickets = workspace:FindFirstChild("Game") and workspace.Game:FindFirstChild("Effects") and workspace.Game.Effects:FindFirstChild("Tickets")

            local function updateTracerEsp()
                if not tickets then return end
                
                for ticket, drawings in pairs(tracerDrawings) do
                    if not ticket.Parent or not ticket:FindFirstChild("HumanoidRootPart") then
                        for _, drawing in ipairs(drawings) do
                            drawing:Remove()
                        end
                        tracerDrawings[ticket] = nil
                    end
                end
                
                for _, ticket in ipairs(tickets:GetChildren()) do
                    if ticket:FindFirstChild("HumanoidRootPart") and not tracerDrawings[ticket] then
                        local tracer = Drawing.new("Line")
                        tracer.Visible = false
                        tracer.Color = Color3.fromRGB(0, 0, 255)
                        tracer.Thickness = 2
                        tracer.Transparency = 1
                        tracerDrawings[ticket] = {tracer}
                    end
                end
                
                local camera = workspace.CurrentCamera
                if not camera then return end
                local screenBottomCenter = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y)
                for ticket, drawings in pairs(tracerDrawings) do
                    local ticketPart = ticket:FindFirstChild("HumanoidRootPart")
                    if ticketPart then
                        local screenPos, onScreen = camera:WorldToViewportPoint(ticketPart.Position)
                        drawings[1].Visible = onScreen
                        if onScreen then
                            drawings[1].From = screenBottomCenter
                            drawings[1].To = Vector2.new(screenPos.X, screenPos.Y)
                        end
                    end
                end
            end
            
            updateTracerEsp()
            
            table.insert(tracerConnections, RunService.RenderStepped:Connect(updateTracerEsp))
            if tickets then
                table.insert(tracerConnections, tickets.ChildAdded:Connect(updateTracerEsp))
                table.insert(tracerConnections, tickets.ChildRemoved:Connect(updateTracerEsp))
            end
            
            getgenv().ticketTracerConnections = tracerConnections
            getgenv().ticketTracerDrawings = tracerDrawings
        end
    end
})

local TicketDistanceEspToggle = Tabs.ESP:Toggle({
    Title = "Ticket Distance ESP",
    Value = false,
    Callback = function(state)
        if getgenv().ticketDistanceConnections then
            for _, connection in ipairs(getgenv().ticketDistanceConnections) do
                connection:Disconnect()
            end
            getgenv().ticketDistanceConnections = nil
        end
        if getgenv().ticketDistanceLabels then
            for _, label in pairs(getgenv().ticketDistanceLabels) do
                label:Remove()
            end
            getgenv().ticketDistanceLabels = nil
        end

        if state then
            local distanceConnections = {}
            local distanceLabels = {}
            local tickets = workspace:FindFirstChild("Game") and workspace.Game:FindFirstChild("Effects") and workspace.Game.Effects:FindFirstChild("Tickets")

            local function updateDistanceEsp()
                if not tickets then return end
                
                for ticket, label in pairs(distanceLabels) do
                    if not ticket.Parent or not ticket:FindFirstChild("HumanoidRootPart") then
                        label:Remove()
                        distanceLabels[ticket] = nil
                    end
                end
                
                for _, ticket in ipairs(tickets:GetChildren()) do
                    if ticket:FindFirstChild("HumanoidRootPart") and not distanceLabels[ticket] then
                        local distanceLabel = Drawing.new("Text")
                        distanceLabel.Visible = false
                        distanceLabel.Text = "0m"
                        distanceLabel.Color = Color3.fromRGB(0, 0, 255)
                        distanceLabel.Size = 16
                        distanceLabel.Center = true
                        distanceLabel.Outline = true
                        distanceLabels[ticket] = distanceLabel
                    end
                end
                
                local character = player.Character
                local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")
                local camera = workspace.CurrentCamera
                if not camera or not humanoidRootPart then return end
                for ticket, label in pairs(distanceLabels) do
                    local ticketPart = ticket:FindFirstChild("HumanoidRootPart")
                    if ticketPart then
                        local screenPos, onScreen = camera:WorldToViewportPoint(ticketPart.Position)
                        label.Visible = onScreen
                        if onScreen then
                            local distance = (ticketPart.Position - humanoidRootPart.Position).Magnitude
                            label.Text = string.format("%.1fm", distance)
                            label.Position = Vector2.new(screenPos.X, screenPos.Y + 20)
                        end
                    end
                end
            end
            
            updateDistanceEsp()
            
            table.insert(distanceConnections, RunService.RenderStepped:Connect(updateDistanceEsp))
            if tickets then
                table.insert(distanceConnections, tickets.ChildAdded:Connect(updateDistanceEsp))
                table.insert(distanceConnections, tickets.ChildRemoved:Connect(updateDistanceEsp))
            end
            
            getgenv().ticketDistanceConnections = distanceConnections
            getgenv().ticketDistanceLabels = distanceLabels
        end
    end
})

local HighlightsTicketEspToggle = Tabs.ESP:Toggle({
    Title = "Highlights Ticket ESP",
    Value = false,
    Callback = function(state)
        if getgenv().ticketHighlightConnections then
            for _, connection in ipairs(getgenv().ticketHighlightConnections) do
                connection:Disconnect()
            end
            getgenv().ticketHighlightConnections = nil
        end
        if getgenv().ticketHighlights then
            for _, highlight in pairs(getgenv().ticketHighlights) do
                highlight:Destroy()
            end
            getgenv().ticketHighlights = nil
        end

        if state then
            local highlightConnections = {}
            local highlights = {}
            local tickets = workspace:FindFirstChild("Game") and workspace.Game:FindFirstChild("Effects") and workspace.Game.Effects:FindFirstChild("Tickets")

            local function updateHighlights()
                if not tickets then return end
                
                for ticket, highlight in pairs(highlights) do
                    if not ticket.Parent or not ticket:FindFirstChild("HumanoidRootPart") then
                        highlight:Destroy()
                        highlights[ticket] = nil
                    end
                end
                
                for _, ticket in ipairs(tickets:GetChildren()) do
                    if ticket:FindFirstChild("HumanoidRootPart") and not highlights[ticket] then
                        local highlight = Instance.new("Highlight")
                        highlight.Adornee = ticket
                        highlight.FillColor = Color3.fromRGB(0, 0, 255)
                        highlight.OutlineColor = Color3.fromRGB(0, 0, 255)
                        highlight.FillTransparency = 0.5
                        highlight.OutlineTransparency = 0
                        highlight.Parent = ticket
                        highlights[ticket] = highlight
                    end
                end
            end
            
            updateHighlights()
            
            table.insert(highlightConnections, RunService.RenderStepped:Connect(updateHighlights))
            if tickets then
                table.insert(highlightConnections, tickets.ChildAdded:Connect(updateHighlights))
                table.insert(highlightConnections, tickets.ChildRemoved:Connect(updateHighlights))
            end
            
            getgenv().ticketHighlightConnections = highlightConnections
            getgenv().ticketHighlights = highlights
        end
    end
})
    -- Auto Tab
    Tabs.Auto:Section({ Title = "Auto", TextSize = 40 })
    local AutoCrouchToggle = Tabs.Auto:Toggle({
    Title = "Auto Crouch",
    Icon = "arrow-down",
    Value = false,
    Callback = function(state)
        featureStates.AutoCrouch = state
        local playerGui = Players.LocalPlayer.PlayerGui
        local autoCrouchGui = playerGui:FindFirstChild("AutoCrouchGui")
        if not autoCrouchGui and state then
            createAutoCrouchGui()
        elseif autoCrouchGui then
            autoCrouchGui.Enabled = state
            local button = autoCrouchGui.Frame:FindFirstChild("ToggleButton")
            if button then
                button.Text = state and "On" or "Off"
                button.BackgroundColor3 = state and Color3.fromRGB(0, 120, 80) or Color3.fromRGB(120, 0, 0)
            end
        end
    end
})

local AutoCrouchModeDropdown = Tabs.Auto:Dropdown({
    Title = "Auto Crouch Mode",
    Values = {"Air", "Normal", "Ground"},
    Value = "Air",
    Callback = function(value)
        featureStates.AutoCrouchMode = value
    end
})
local _Players = game:GetService("Players")
local _LocalPlayer = _Players.LocalPlayer
local BhopToggle = Tabs.Auto:Toggle({
    Title = "Bhop",
    Value = false,
    Callback = function(state)
        featureStates.Bhop = state
        if not state then
            getgenv().autoJumpEnabled = false
            if jumpGui and jumpToggleBtn then
                jumpToggleBtn.Text = "Off"
                jumpToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                jumpGui.Enabled = isMobile and state
            end
        end
        if _LocalPlayer and _LocalPlayer:FindFirstChild("PlayerGui") then
            local gui = _LocalPlayer.PlayerGui:FindFirstChild("BhopGui")
            if gui then
                gui.Enabled = state
            end
        end
    end
})
featureStates.BhopHold = false

getgenv().bhopHoldActive = false

local BhopHoldToggle = Tabs.Auto:Toggle({
    Title = "Bhop (Jump button or Space)",
    Value = false,
    Callback = function(state)
        featureStates.BhopHold = state
        if not state then
            getgenv().bhopHoldActive = false
        end
    end
})

local UIS = game:GetService("UserInputService")
UIS.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.Space and featureStates.BhopHold then
        getgenv().bhopHoldActive = true
    end
end)
UIS.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.Space then
        getgenv().bhopHoldActive = false
    end
end)

local function setupJumpButton()
    local success, err = pcall(function()
        local touchGui = player:WaitForChild("PlayerGui"):WaitForChild("TouchGui", 5)
        if not touchGui then return end
        local touchControlFrame = touchGui:WaitForChild("TouchControlFrame", 5)
        if not touchControlFrame then return end
        local jumpButton = touchControlFrame:WaitForChild("JumpButton", 5)
        if not jumpButton then return end
        
        jumpButton.MouseButton1Down:Connect(function()
            if featureStates.BhopHold then
                getgenv().bhopHoldActive = true
            end
        end)
        
        jumpButton.MouseButton1Up:Connect(function()
            getgenv().bhopHoldActive = false
        end)
    end)
    if not success then
        warn("Failed to setup jump button: " .. tostring(err))
    end
end
setupJumpButton()
player.CharacterAdded:Connect(setupJumpButton)

task.spawn(function()
    while true do
        local friction = 5
        local isBhopActive = getgenv().autoJumpEnabled or getgenv().bhopHoldActive
        if isBhopActive and getgenv().bhopMode == "Acceleration" then
            friction = getgenv().bhopAccelValue or -0.5
        end
        for _, t in pairs(getgc(true)) do
            if type(t) == "table" and rawget(t, "Friction") then
                if getgenv().bhopMode == "No Acceleration" then
                else
                    t.Friction = friction
                end
            end
        end
        task.wait(0.15)
    end
end)

task.spawn(function()
    while true do
        local isBhopActive = getgenv().autoJumpEnabled or getgenv().bhopHoldActive
        if isBhopActive then
            local character = LocalPlayer.Character
            if character and character:FindFirstChild("Humanoid") then
                local humanoid = character.Humanoid
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
local BhopModeDropdown = Tabs.Auto:Dropdown({
    Title = "Bhop Mode",
    Values = {"Acceleration", "No Acceleration"},
    Value = "Acceleration",
    Callback = function(value)
        getgenv().bhopMode = value
    end
})
local BhopAccelInput = Tabs.Auto:Input({
    Title = "Bhop Acceleration (Negative Only)",
    Placeholder = "-0.5",
    Numeric = true,
    Callback = function(value)
        if tostring(value):sub(1,1) == "-" then
            local n = tonumber(value)
            if n then getgenv().bhopAccelValue = n end
        end
    end
})
local AutoEmoteToggle = Tabs.Auto:Toggle({
    Title = "Auto Emote (Hold Crouch Button)",
    Value = false,
    Callback = function(state)
        getgenv().EmoteEnabled = state
    end
})
local EmoteDropdown = Tabs.Auto:Dropdown({
    Title = "Select Emote",
    Values = emoteList,
    Multi = false,
    Callback = function(option)
        getgenv().SelectedEmote = option
    end
})

    local AutoCarryToggle = Tabs.Auto:Toggle({
        Title = "loc:AUTO_CARRY",
        Value = false,
        Callback = function(state)
            featureStates.AutoCarry = state
            if state then
                startAutoCarry()
            else
                stopAutoCarry()
            end
        end
    })

getgenv().autoCarryGuiVisible = false


local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local playerGui = LocalPlayer:WaitForChild("PlayerGui", 5)

local function makeDraggable(frame)
    local dragging = false
    local dragStart = nil
    local startPos = nil

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

local function createAutoCarryGui(yOffset)
    local autoCarryGuiOld = playerGui:FindFirstChild("AutoCarryGui")
    if autoCarryGuiOld then
        autoCarryGuiOld:Destroy()
    end
    
    local autoCarryGui = Instance.new("ScreenGui")
    autoCarryGui.Name = "AutoCarryGui"
    autoCarryGui.IgnoreGuiInset = true
    autoCarryGui.ResetOnSpawn = false
    autoCarryGui.Enabled = getgenv().autoCarryGuiVisible
    autoCarryGui.Parent = playerGui

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 60, 0, 60)
    frame.Position = UDim2.new(0.5, -30, 0.12 + (yOffset or 0), 0)
    frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    frame.BackgroundTransparency = 0.35
    frame.BorderSizePixel = 0
    frame.Parent = autoCarryGui
    makeDraggable(frame)

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = frame

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(150, 150, 150)
    stroke.Thickness = 2
    stroke.Parent = frame

    local label = Instance.new("TextLabel")
    label.Text = "Auto"
    label.Size = UDim2.new(0.9, 0, 0.3, 0)
    label.Position = UDim2.new(0.05, 0, 0.05, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.Font = Enum.Font.Roboto
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Center
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.TextScaled = true
    label.Parent = frame

    local subLabel = Instance.new("TextLabel")
    subLabel.Text = "Carry"
    subLabel.Size = UDim2.new(0.9, 0, 0.3, 0)
    subLabel.Position = UDim2.new(0.05, 0, 0.3, 0)
    subLabel.BackgroundTransparency = 1
    subLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    subLabel.Font = Enum.Font.Roboto
    subLabel.TextSize = 14
    subLabel.TextXAlignment = Enum.TextXAlignment.Center
    subLabel.TextYAlignment = Enum.TextYAlignment.Center
    subLabel.TextScaled = true
    subLabel.Parent = frame

    local autoCarryGuiButton = Instance.new("TextButton")
    autoCarryGuiButton.Name = "ToggleButton"
    autoCarryGuiButton.Text = featureStates.AutoCarry and "On" or "Off"
    autoCarryGuiButton.Size = UDim2.new(0.9, 0, 0.35, 0)
    autoCarryGuiButton.Position = UDim2.new(0.05, 0, 0.6, 0)
    autoCarryGuiButton.BackgroundColor3 = featureStates.AutoCarry and Color3.fromRGB(0, 120, 80) or Color3.fromRGB(120, 0, 0)
    autoCarryGuiButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    autoCarryGuiButton.Font = Enum.Font.Roboto
    autoCarryGuiButton.TextSize = 12
    autoCarryGuiButton.TextXAlignment = Enum.TextXAlignment.Center
    autoCarryGuiButton.TextYAlignment = Enum.TextYAlignment.Center
    autoCarryGuiButton.TextScaled = true
    autoCarryGuiButton.Parent = frame

    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 4)
    buttonCorner.Parent = autoCarryGuiButton

    autoCarryGuiButton.MouseButton1Click:Connect(function()
        featureStates.AutoCarry = not featureStates.AutoCarry
        if featureStates.AutoCarry then
            startAutoCarry()
        else
            stopAutoCarry()
        end
        autoCarryGuiButton.Text = featureStates.AutoCarry and "On" or "Off"
        autoCarryGuiButton.BackgroundColor3 = featureStates.AutoCarry and Color3.fromRGB(0, 120, 80) or Color3.fromRGB(120, 0, 0)
    end)
end

local autoCarryInputConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.X and getgenv().autoCarryGuiVisible then
        featureStates.AutoCarry = not featureStates.AutoCarry
        if featureStates.AutoCarry then
            startAutoCarry()
        else
            stopAutoCarry()
        end
        local autoCarryGui = playerGui:FindFirstChild("AutoCarryGui")
        if autoCarryGui and autoCarryGui.Enabled then
            local button = autoCarryGui.Frame:FindFirstChild("ToggleButton")
            if button then
                button.Text = featureStates.AutoCarry and "On" or "Off"
                button.BackgroundColor3 = featureStates.AutoCarry and Color3.fromRGB(0, 120, 80) or Color3.fromRGB(120, 0, 0)
            end
        end
        WindUI:Notify({
            Title = "Auto Carry",
            Content = "Auto Carry " .. (featureStates.AutoCarry and "enabled" or "disabled"),
            Duration = 2
        })
    end
end)

local function toggleAutoCarryGUI(state)
    getgenv().autoCarryGuiVisible = state
    local autoCarryGui = playerGui:FindFirstChild("AutoCarryGui")
    if autoCarryGui then
        autoCarryGui.Enabled = state
    end
    if state then
        WindUI:Notify({
            Title = "Auto Carry GUI",
            Content = "GUI is enabled. Press X to toggle auto carry.",
            Duration = 3
        })
    else
        WindUI:Notify({
            Title = "Auto Carry GUI",
            Content = "GUI and keybind disabled.",
            Duration = 3
        })
    end
end

local AutoCarryKeybindToggle = Tabs.Auto:Toggle({
    Title = "Auto carry keybind/button",
    Desc = "Toggle gui or keybind for quick enable auto carry",
    Icon = "toggle-right",
    Value = false,
    Callback = function(state)
        toggleAutoCarryGUI(state)
    end
})

createAutoCarryGui(0)
local FastReviveToggle = Tabs.Auto:Toggle({
    Title = "Fast Revive",
    Value = false,
    Callback = function(state)
        featureStates.FastRevive = state
        if state then
            startAutoRevive()
        else
            stopAutoRevive()
        end
    end
})

local FastReviveMethodDropdown = Tabs.Auto:Dropdown({
    Title = "Fast Revive Method",
    Values = {"Auto", "Interact"},
    Value = "Interact",
    Callback = function(value)
        featureStates.FastReviveMethod = value
        
        stopAutoRevive()
        if featureStates.FastReviveMethod == "Interact" then
            featureStates.interactHookActive = false
        end
        
        if featureStates.FastRevive then
            startAutoRevive()
        end
    end
})
    local AutoVoteDropdown = Tabs.Auto:Dropdown({
        Title = "loc:AUTO_VOTE_MAP",
        Values = {"Map 1", "Map 2", "Map 3", "Map 4"},
        Value = "Map 1",
        Callback = function(value)
            if value == "Map 1" then
                featureStates.SelectedMap = 1
            elseif value == "Map 2" then
                featureStates.SelectedMap = 2
            elseif value == "Map 3" then
                featureStates.SelectedMap = 3
            elseif value == "Map 4" then
                featureStates.SelectedMap = 4
            end
        end
    })

    local AutoVoteToggle = Tabs.Auto:Toggle({
        Title = "loc:AUTO_VOTE",
        Value = false,
        Callback = function(state)
            featureStates.AutoVote = state
            if state then
                startAutoVote()
            else
                stopAutoVote()
            end
        end
    })
local AutoVoteModeToggle = Tabs.Auto:Toggle({
    Title = "Auto Vote Game Mode",
    Value = false,
    Callback = function(state)
        if state then
            local voteConnection
            voteConnection = RunService.Heartbeat:Connect(function()
                local voteEvent = ReplicatedStorage:WaitForChild("Events"):WaitForChild("Player"):WaitForChild("Vote")
                if voteEvent then
                    if featureStates.SelectedVoteMode == 1 then
                        voteEvent:FireServer(1, true)
                    elseif featureStates.SelectedVoteMode == 2 then
                        voteEvent:FireServer(2, true)
                    elseif featureStates.SelectedVoteMode == 3 then
                        voteEvent:FireServer(3, true)
                    elseif featureStates.SelectedVoteMode == 4 then
                        voteEvent:FireServer(4, true)
                    end
                end
            end)
            
            getgenv().AutoVoteModeConnection = voteConnection
        else
            if getgenv().AutoVoteModeConnection then
                getgenv().AutoVoteModeConnection:Disconnect()
                getgenv().AutoVoteModeConnection = nil
            end
        end
    end
})

local AutoVoteModeDropdown = Tabs.Auto:Dropdown({
    Title = "Vote Mode",
    Values = {"Mode 1", "Mode 2", "Mode 3", "Mode 4"},
    Value = "Mode 1",
    Callback = function(value)
        if value == "Mode 1" then
            featureStates.SelectedVoteMode = 1
        elseif value == "Mode 2" then
            featureStates.SelectedVoteMode = 2
        elseif value == "Mode 3" then
            featureStates.SelectedVoteMode = 3
        elseif value == "Mode 4" then
            featureStates.SelectedVoteMode = 4
        end
    end
})
    local AutoSelfReviveToggle = Tabs.Auto:Toggle({
        Title = "loc:AUTO_SELF_REVIVE",
        Value = false,
        Callback = function(state)
            featureStates.AutoSelfRevive = state
            if state then
                startAutoSelfRevive()
            else
                stopAutoSelfRevive()
            end
        end
    })

    Tabs.Auto:Button({
        Title = "loc:MANUAL_REVIVE",
        Desc = "Manually revive yourself",
        Icon = "heart",
        Callback = function()
            manualRevive()
        end
    })

    local AutoWinToggle = Tabs.Auto:Toggle({
        Title = "loc:AUTO_WIN",
        Value = false,
        Callback = function(state)
            featureStates.AutoWin = state
            if state then
                startAutoWin()
            else
                stopAutoWin()
            end
        end
    })
    local AutoWhistleToggle = Tabs.Auto:Toggle({
    Title = "Auto Whistle",
    Value = false,
    Callback = function(state)
        featureStates.AutoWhistle = state
        if state then
            startAutoWhistle()
        else
            stopAutoWhistle()
        end
    end
})

    local AutoMoneyFarmToggle = Tabs.Auto:Toggle({
        Title = "loc:AUTO_MONEY_FARM",
        Value = false,
        Callback = function(state)
            featureStates.AutoMoneyFarm = state
            getgenv().moneyfarm = state
            if state then
                startAutoMoneyFarm()
                featureStates.FastRevive = true
                featureStates.AutoSelfRevive = true
                featureStates.FastReviveMethod = "Auto"
                pcall(function()
                    if FastReviveMethodDropdown and FastReviveMethodDropdown.Select then
                        FastReviveMethodDropdown:Select("Auto")
                    elseif FastReviveMethodDropdown and FastReviveMethodDropdown.Set then
                        FastReviveMethodDropdown:Set("Value", "Auto")
                    end
                end)
                FastReviveToggle:Set(true)
                AutoSelfReviveToggle:Set(true)
                startAutoRevive()
            else
                stopAutoMoneyFarm()
            end
        end
    })
local AutoTicketFarmToggle = Tabs.Auto:Toggle({
    Title = "Auto ticket farm",
    Value = false,
    Callback = function(state)
        getgenv().ticketfarm = state
        local AutoTicketFarmConnection
        local yOffset = 15
        local currentTicket = nil
        local ticketProcessedTime = 0

        if state then
            local securityPart = workspace:FindFirstChild("SecurityPart")
            if not securityPart then
                securityPart = Instance.new("Part")
                securityPart.Name = "SecurityPart"
                securityPart.Size = Vector3.new(10, 1, 10)
                securityPart.Position = Vector3.new(0, 500, 0)
                securityPart.Anchored = true
                securityPart.CanCollide = true
                securityPart.Transparency = 1
                securityPart.Parent = workspace
            end

            AutoTicketFarmConnection = game:GetService("RunService").Heartbeat:Connect(function()
                if not getgenv().ticketfarm then
                    if AutoTicketFarmConnection then
                        AutoTicketFarmConnection:Disconnect()
                        AutoTicketFarmConnection = nil
                    end
                    return
                end

                local character = player.Character
                local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")
                local tickets = workspace:FindFirstChild("Game") and workspace.Game:FindFirstChild("Effects") and workspace.Game.Effects:FindFirstChild("Tickets")
                local playersInGame = workspace:FindFirstChild("Game") and workspace.Game:FindFirstChild("Players")

                if character and humanoidRootPart then
                    if character:GetAttribute("Downed") then
                        ReplicatedStorage.Events.Player.ChangePlayerMode:FireServer(true)
                        humanoidRootPart.CFrame = securityPart.CFrame + Vector3.new(0, 3, 0)
                        return
                    end

                    if getgenv().moneyfarm and playersInGame then
                        local downedPlayerFound = false
                        for _, v in pairs(playersInGame:GetChildren()) do
                            if v:IsA("Model") and v:GetAttribute("Downed") then
                                local downedRootPart = v:FindFirstChild("HumanoidRootPart")
                                if downedRootPart then
                                    humanoidRootPart.CFrame = downedRootPart.CFrame + Vector3.new(0, 3, 0)
                                    ReplicatedStorage.Events.Character.Interact:FireServer("Revive", true, v)
                                    downedPlayerFound = true
                                    currentTicket = nil 
                                    break
                                end
                            end
                        end
                        if downedPlayerFound then
                            return
                        end
                    end

                    if tickets then
                        local activeTickets = tickets:GetChildren()
                        if #activeTickets > 0 then
                            if not currentTicket or not currentTicket.Parent then
                                currentTicket = activeTickets[1]
                                ticketProcessedTime = tick()
                            end

                            if currentTicket and currentTicket.Parent then
                                local ticketPart = currentTicket:FindFirstChild("HumanoidRootPart")
                                if ticketPart then
                                    local targetPosition = ticketPart.Position + Vector3.new(0, yOffset, 0)
                                    humanoidRootPart.CFrame = CFrame.new(targetPosition)
                                    
                                    if tick() - ticketProcessedTime > 0.1 then
                                        humanoidRootPart.CFrame = ticketPart.CFrame
                                    end
                                else
                                    currentTicket = nil
                                end
                            else
                                humanoidRootPart.CFrame = securityPart.CFrame + Vector3.new(0, 3, 0)
                                currentTicket = nil
                            end
                        else
                            humanoidRootPart.CFrame = securityPart.CFrame + Vector3.new(0, 3, 0)
                            currentTicket = nil
                        end
                    else
                        humanoidRootPart.CFrame = securityPart.CFrame + Vector3.new(0, 3, 0)
                        currentTicket = nil
                    end
                end
            end)
        else
            if AutoTicketFarmConnection then
                AutoTicketFarmConnection:Disconnect()
                AutoTicketFarmConnection = nil
            end
            currentTicket = nil
            local character = player.Character or player.CharacterAdded:Wait()
            local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
            local securityPart = workspace:FindFirstChild("SecurityPart")
            if humanoidRootPart and securityPart then
                humanoidRootPart.CFrame = securityPart.CFrame + Vector3.new(0, 3, 0)
            end
        end
    end
})
-- Utility Tab

local FreeCamToggle = Tabs.Utility:Toggle({
    Title = "Free Cam UI",
    Desc = "Note: Sometimes it's may be glitchy so don't use it too often, I can't really fix it",
    Icon = "camera",
    Value = false,
    Callback = function(state)
        controlFrame.Visible = state and isMobile
        if state and isMobile then
         print ("")
        elseif state and not isMobile then
            WindUI:Notify({
                Title = "Free Cam",
                Content = "Use Ctrl+P to toggle Free Cam.",
                Duration = 3
            })
            if not isFreecamEnabled then
                deactivateFreecam()
            end
        else
            if isFreecamEnabled then
                deactivateFreecam()
            end
        end
    end
})
local FreeCamSpeedSlider = Tabs.Utility:Slider({
    Title = "Free Cam Speed",
    Desc = "Adjust movement speed in Free Cam",
    Value = { Min = 1, Max = 500, Default = 50, Step = 1 },
    Callback = function(value)
        FREECAM_SPEED = value
    end
})

local TimeChangerInput = Tabs.Utility:Input({
    Title = "Set Time (HH:MM)",
    Placeholder = "12:00",
    Value = "",
    Callback = function(value)
        value = value:gsub("^%s*(.-)%s*$", "%1")
        
        local h_str, m_str = value:match("(%d+):(%d+)")
        if h_str and m_str then
            local h = tonumber(h_str)
            local m = tonumber(m_str)
            
            if h and m and h >= 0 and h <= 23 and m >= 0 and m <= 59 and #h_str <= 2 and #m_str <= 2 then
                local totalHours = h + (m / 60)
                game:GetService("Lighting").ClockTime = totalHours
                
                WindUI:Notify({
                    Title = "Time Changer",
                    Content = "Time set to " .. string.format("%02d:%02d", h, m),
                    Duration = 2
                })
            else
                WindUI:Notify({
                    Title = "Time Changer",
                    Content = "Invalid time! Hours: 00-23, Minutes: 00-59 (e.g., 09:30 or 12:00)",
                    Duration = 3
                })
            end
        else
            WindUI:Notify({
                Title = "Time Changer",
                Content = "Invalid format! Use HH:MM (e.g., 09:30)",
                Duration = 2
            })
        end
    end
})

featureStates.AutoCrouch = false
featureStates.AutoCrouchMode = "Air"

local previousCrouchState = false
local spamDown = true

local function fireKeybind(down, key)
    local ohTable = {
        ["Down"] = down,
        ["Key"] = key
    }
    local event = game:GetService("Players").LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild("Events"):WaitForChild("temporary_events"):WaitForChild("UseKeybind")
    event:Fire(ohTable)
end

local function createAutoCrouchGui()
    local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
    
    local autoCrouchGuiOld = playerGui:FindFirstChild("AutoCrouchGui")
    if autoCrouchGuiOld then autoCrouchGuiOld:Destroy() end
    
    local autoCrouchGui = Instance.new("ScreenGui")
    autoCrouchGui.Name = "AutoCrouchGui"
    autoCrouchGui.IgnoreGuiInset = true
    autoCrouchGui.ResetOnSpawn = false
    autoCrouchGui.Enabled = true
    autoCrouchGui.Parent = playerGui

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 50, 0, 50)
    frame.Position = UDim2.new(0.5, -50, 0.12, 0)
    frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    frame.BackgroundTransparency = 0.35
    frame.BorderSizePixel = 0
    frame.Parent = autoCrouchGui
    
    local dragging = false
    local dragStart = nil
    local startPos = nil

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

    game:GetService("UserInputService").InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = frame

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(150, 150, 150)
    stroke.Thickness = 2
    stroke.Parent = frame

    local label = Instance.new("TextLabel")
    label.Text = "Auto Crouch"
    label.Size = UDim2.new(0.9, 0, 0.45, 0)
    label.Position = UDim2.new(0.05, 0, 0.05, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.Font = Enum.Font.Roboto
    label.TextSize = 30
    label.TextXAlignment = Enum.TextXAlignment.Center
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.TextScaled = true
    label.Parent = frame

    local autoCrouchGuiButton = Instance.new("TextButton")
    autoCrouchGuiButton.Name = "ToggleButton"
    autoCrouchGuiButton.Text = featureStates.AutoCrouch and "On" or "Off"
    autoCrouchGuiButton.Size = UDim2.new(0.9, 0, 0.4, 0)
    autoCrouchGuiButton.Position = UDim2.new(0.05, 0, 0.5, 0)
    autoCrouchGuiButton.BackgroundColor3 = featureStates.AutoCrouch and Color3.fromRGB(0, 120, 80) or Color3.fromRGB(120, 0, 0)
    autoCrouchGuiButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    autoCrouchGuiButton.Font = Enum.Font.Roboto
    autoCrouchGuiButton.TextSize = 16
    autoCrouchGuiButton.TextXAlignment = Enum.TextXAlignment.Center
    autoCrouchGuiButton.TextYAlignment = Enum.TextYAlignment.Center
    autoCrouchGuiButton.TextScaled = true
    autoCrouchGuiButton.Parent = frame

    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 4)
    buttonCorner.Parent = autoCrouchGuiButton

    autoCrouchGuiButton.MouseButton1Click:Connect(function()
        featureStates.AutoCrouch = not featureStates.AutoCrouch
        autoCrouchGuiButton.Text = featureStates.AutoCrouch and "On" or "Off"
        autoCrouchGuiButton.BackgroundColor3 = featureStates.AutoCrouch and Color3.fromRGB(0, 120, 80) or Color3.fromRGB(120, 0, 0)
        AutoCrouchToggle:Set(featureStates.AutoCrouch)
    end)
end

local crouchConnection = RunService.Heartbeat:Connect(function()
    if not featureStates.AutoCrouch then 
        if previousCrouchState then
            fireKeybind(false, "Crouch")
            previousCrouchState = false
        end
        return 
    end

    local character = Players.LocalPlayer.Character
    if not character or not character:FindFirstChild("Humanoid") then return end

    local humanoid = character.Humanoid
    local mode = featureStates.AutoCrouchMode

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

Players.LocalPlayer.CharacterAdded:Connect(function(newChar)
    previousCrouchState = false
    spamDown = true
end)
player.CharacterAdded:Connect(function()
    hasRevived = false
    if featureStates.AutoSelfRevive then
        task.wait(1)
        startAutoSelfRevive()
    end
end)
getgenv().lagSwitchEnabled = false
getgenv().lagDuration = 0.5
local lagGui = nil
local lagGuiButton = nil
local lagInputConnection = nil
local isLagActive = false

local function makeDraggable(frame)
    local dragging = false
    local dragStart = nil
    local startPos = nil
    
    local function updateInput(input)
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
    
    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
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
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            if dragging then
                updateInput(input)
            end
        end
    end)
end

local function createLagGui(yOffset)
    local lagGuiOld = playerGui:FindFirstChild("LagSwitchGui")
    if lagGuiOld then lagGuiOld:Destroy() end
    lagGui = Instance.new("ScreenGui")
    lagGui.Name = "LagSwitchGui"
    lagGui.IgnoreGuiInset = true
    lagGui.ResetOnSpawn = false
    lagGui.Enabled = getgenv().lagSwitchEnabled
    lagGui.Parent = playerGui

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 60, 0, 60)
    frame.Position = UDim2.new(0.5, -30, 0.12 + (yOffset or 0), 0)
    frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    frame.BackgroundTransparency = 0.35
    frame.BorderSizePixel = 0
    frame.Parent = lagGui
    makeDraggable(frame)

    local corner = Instance.new("UICorner", frame)
    corner.CornerRadius = UDim.new(0, 6)

    local stroke = Instance.new("UIStroke", frame)
    stroke.Color = Color3.fromRGB(150, 150, 150)
    stroke.Thickness = 2

    local label = Instance.new("TextLabel", frame)
    label.Text = "Lag"
    label.Size = UDim2.new(0.9, 0, 0.3, 0)
    label.Position = UDim2.new(0.05, 0, 0.05, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.Font = Enum.Font.Roboto
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Center
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.TextScaled = true

    local subLabel = Instance.new("TextLabel", frame)
    subLabel.Text = "Switch"
    subLabel.Size = UDim2.new(0.9, 0, 0.3, 0)
    subLabel.Position = UDim2.new(0.05, 0, 0.3, 0)
    subLabel.BackgroundTransparency = 1
    subLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    subLabel.Font = Enum.Font.Roboto
    subLabel.TextSize = 14
    subLabel.TextXAlignment = Enum.TextXAlignment.Center
    subLabel.TextYAlignment = Enum.TextYAlignment.Center
    subLabel.TextScaled = true

    lagGuiButton = Instance.new("TextButton", frame)
    lagGuiButton.Name = "TriggerButton"
    lagGuiButton.Text = "Trigger"
    lagGuiButton.Size = UDim2.new(0.9, 0, 0.35, 0)
    lagGuiButton.Position = UDim2.new(0.05, 0, 0.6, 0)
    lagGuiButton.BackgroundColor3 = Color3.fromRGB(0, 120, 80)
    lagGuiButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    lagGuiButton.Font = Enum.Font.Roboto
    lagGuiButton.TextSize = 12
    lagGuiButton.TextXAlignment = Enum.TextXAlignment.Center
    lagGuiButton.TextYAlignment = Enum.TextYAlignment.Center
    lagGuiButton.TextScaled = true

    local buttonCorner = Instance.new("UICorner", lagGuiButton)
    buttonCorner.CornerRadius = UDim.new(0, 4)

    lagGuiButton.MouseButton1Click:Connect(function()
        task.spawn(function()
            local start = tick()
            while tick() - start < (getgenv().lagDuration or 0.5) do
                local a = math.random(1, 1000000) * math.random(1, 1000000)
                a = a / math.random(1, 10000)
            end
        end)
    end)
end

if not lagInputConnection then
    lagInputConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.KeyCode == Enum.KeyCode.L and getgenv().lagSwitchEnabled and not isLagActive then
            isLagActive = true
            task.spawn(function()
                local duration = getgenv().lagDuration or 0.5
                local start = tick()
                while tick() - start < duration do
                    local a = math.random(1, 1000000) * math.random(1, 1000000)
                    a = a / math.random(1, 10000)
                end
                isLagActive = false
            end)
        end
    end)
end

local LagSwitchToggle = Tabs.Utility:Toggle({
    Title = "Lag Switch",
    Icon = "zap",
    Value = false,
    Callback = function(state)
        getgenv().lagSwitchEnabled = state
        if state then
            if not lagGui then
                createLagGui(0)
            else
                lagGui.Enabled = true
            end
        else
            if lagGui then
                lagGui.Enabled = false
            end
        end
    end
})

local LagDurationInput = Tabs.Utility:Input({
    Title = "Lag Duration (seconds)",
    Placeholder = "0.5",
    Value = tostring(getgenv().lagDuration),
    NumbersOnly = true,
    Callback = function(text)
        local n = tonumber(text)
        if n and n > 0 then
            getgenv().lagDuration = n
        end
    end
})

local GravityToggle = Tabs.Utility:Toggle({
    Title = "Custom Gravity",
    Value = false,
    Callback = function(state)
        featureStates.CustomGravity = state
        if state then
            workspace.Gravity = featureStates.GravityValue
        else
            workspace.Gravity = originalGameGravity
        end
    end
})

local GravityInput = Tabs.Utility:Input({
    Title = "Gravity Value",
    Placeholder = tostring(originalGameGravity),
    Value = tostring(featureStates.GravityValue),
    Callback = function(text)
        local num = tonumber(text)
        if num then
            featureStates.GravityValue = num
            if featureStates.CustomGravity then
                workspace.Gravity = num
            end
        end
    end
})
getgenv().gravityGuiVisible = false

local GravityGUIToggle = Tabs.Utility:Toggle({
    Title = "Gravity toggle shortcuts",
    Desc = "Toggle gui or keybind for quick enable gravity",
    Icon = "toggle-right",
    Value = false,
    Callback = function(state)
        getgenv().gravityGuiVisible = state
        local gravityGui = game:GetService("Players").LocalPlayer.PlayerGui:FindFirstChild("GravityGui")
        if gravityGui then
            gravityGui.Enabled = state
        end
        if not state then
            WindUI:Notify({
                Title = "Gravity GUI",
                Content = "GUI And keybind disabled.",
                Duration = 3
            })
        else
            WindUI:Notify({
                Title = "Gravity toggle shortcuts",
                Content = "GUI is enabled or Press J to toggle gravity.",
                Duration = 3
            })
        end
    end
})

-- teleports tab
Tabs.Teleport:Section({ Title = "Teleports", TextSize = 20 })
Tabs.Teleport:Divider()

Tabs.Teleport:Button({
    Title = "Teleport to Spawn",
    Desc = "Teleport to a random spawn location",
    Icon = "home",
    Callback = function()
        local spawnsFolder = workspace:FindFirstChild("Game") and workspace.Game:FindFirstChild("Map") and workspace.Game.Map:FindFirstChild("Parts") and workspace.Game.Map.Parts:FindFirstChild("Spawns")
        
        if spawnsFolder then
            local spawnLocations = spawnsFolder:GetChildren()
            if #spawnLocations > 0 then
                local randomSpawn = spawnLocations[math.random(1, #spawnLocations)]
                local character = player.Character
                local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")
                
                if humanoidRootPart then
                    humanoidRootPart.CFrame = randomSpawn.CFrame + Vector3.new(0, 3, 0)
                end
            end
        end
    end
})

Tabs.Teleport:Button({
    Title = "Teleport to Random Player",
    Desc = "Teleport to a random online player",
    Icon = "users",
    Callback = function()
        local players = Players:GetPlayers()
        local validPlayers = {}
        
        for _, plr in ipairs(players) do
            if plr ~= player and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                table.insert(validPlayers, plr)
            end
        end
        
        if #validPlayers > 0 then
            local randomPlayer = validPlayers[math.random(1, #validPlayers)]
            local character = player.Character
            local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")
            
            if humanoidRootPart then
                humanoidRootPart.CFrame = randomPlayer.Character.HumanoidRootPart.CFrame + Vector3.new(0, 3, 0)
            end
        end
    end
})

Tabs.Teleport:Button({
    Title = "Teleport to Downed Player",
    Desc = "Teleport to a random downed player",
    Icon = "heart",
    Callback = function()
        local playersFolder = workspace:FindFirstChild("Game") and workspace.Game:FindFirstChild("Players")
        local downedPlayers = {}
        
        if playersFolder then
            for _, model in ipairs(playersFolder:GetChildren()) do
                if model:IsA("Model") and model:GetAttribute("Downed") == true and model.Name ~= player.Name then
                    local hrp = model:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        table.insert(downedPlayers, model)
                    end
                end
            end
        end
        
        if #downedPlayers > 0 then
            local randomDowned = downedPlayers[math.random(1, #downedPlayers)]
            local character = player.Character
            local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")
            
            if humanoidRootPart then
                humanoidRootPart.CFrame = randomDowned.HumanoidRootPart.CFrame + Vector3.new(0, 3, 0)
            end
        end
    end
})

-- Player Dropdown for Teleport
local playerList = {}
local PlayerDropdown = Tabs.Teleport:Dropdown({
    Title = "Select Player",
    Values = {"No players found"},
    Value = "No players found",
    Callback = function(selectedPlayer)
    end
})

local function updatePlayerList()
    playerList = {}
    local players = Players:GetPlayers()
    local playerNames = {}
    
    for _, plr in ipairs(players) do
        if plr ~= player then
            table.insert(playerList, plr)
            table.insert(playerNames, plr.Name)
        end
    end
    
    if #playerNames == 0 then
        playerNames = {"No players found"}
    end
    
    PlayerDropdown:Refresh(playerNames, true)
end

updatePlayerList()
Players.PlayerAdded:Connect(updatePlayerList)
Players.PlayerRemoving:Connect(updatePlayerList)

Tabs.Teleport:Button({
    Title = "Teleport to Selected Player",
    Desc = "Teleport to the player selected in dropdown",
    Icon = "user",
    Callback = function()
        local selectedPlayerName = PlayerDropdown.Value
        if selectedPlayerName ~= "No players found" then
            for _, plr in ipairs(playerList) do
                if plr.Name == selectedPlayerName and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                    local character = player.Character
                    local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")
                    
                    if humanoidRootPart then
                        humanoidRootPart.CFrame = plr.Character.HumanoidRootPart.CFrame + Vector3.new(0, 3, 0)
                    end
                    break
                end
            end
        end
    end
})

Tabs.Teleport:Button({
    Title = "Teleport to Ticket",
    Desc = "Teleport to a random ticket",
    Icon = "ticket",
    Callback = function()
        local tickets = workspace:FindFirstChild("Game") and workspace.Game:FindFirstChild("Effects") and workspace.Game.Effects:FindFirstChild("Tickets")
        
        if tickets then
            local ticketList = tickets:GetChildren()
            if #ticketList > 0 then
                local randomTicket = ticketList[math.random(1, #ticketList)]
                local ticketPart = randomTicket:FindFirstChild("HumanoidRootPart")
                
                if ticketPart then
                    local character = player.Character
                    local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")
                    
                    if humanoidRootPart then
                        humanoidRootPart.CFrame = ticketPart.CFrame + Vector3.new(0, 3, 0)
                    end
                end
            end
        end
    end
})

Tabs.Teleport:Button({
    Title = "Teleport to Nextbot",
    Desc = "Teleport to a random nextbot",
    Icon = "ghost",
    Callback = function()
        local nextbots = {}
        
        local playersFolder = workspace:FindFirstChild("Game") and workspace.Game:FindFirstChild("Players")
        if playersFolder then
            for _, model in ipairs(playersFolder:GetChildren()) do
                if model:IsA("Model") and isNextbotModel(model) then
                    local hrp = model:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        table.insert(nextbots, model)
                    end
                end
            end
        end
        
        local npcsFolder = workspace:FindFirstChild("NPCs")
        if npcsFolder then
            for _, model in ipairs(npcsFolder:GetChildren()) do
                if model:IsA("Model") and isNextbotModel(model) then
                    local hrp = model:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        table.insert(nextbots, model)
                    end
                end
            end
        end
        
        if #nextbots > 0 then
            local randomNextbot = nextbots[math.random(1, #nextbots)]
            local character = player.Character
            local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")
            
            if humanoidRootPart then
                humanoidRootPart.CFrame = randomNextbot.HumanoidRootPart.CFrame + Vector3.new(0, 10, 0)
            end
        end
    end
})

Tabs.Teleport:Button({
    Title = "Teleport to SecurityPart",
    Desc = "Teleport to the safe SecurityPart location",
    Icon = "shield",
    Callback = function()
        local securityPart = workspace:FindFirstChild("SecurityPart")
        
        if securityPart then
            local character = player.Character
            local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")
            
            if humanoidRootPart then
                humanoidRootPart.CFrame = securityPart.CFrame + Vector3.new(0, 3, 0)
            end
        end
    end
})

    -- Settings Tab
    Tabs.Settings:Section({ Title = "Settings", TextSize = 40 })
    Tabs.Settings:Section({ Title = "Personalize", TextSize = 20 })
    Tabs.Settings:Divider()

    local themes = {}
    for themeName, _ in pairs(WindUI:GetThemes()) do
        table.insert(themes, themeName)
    end
    table.sort(themes)

    local canChangeTheme = true
    local canChangeDropdown = true

    local ThemeDropdown = Tabs.Settings:Dropdown({
        Title = "loc:THEME_SELECT",
        Values = themes,
        SearchBarEnabled = true,
        MenuWidth = 280,
        Value = "Dark",
        Callback = function(theme)
            if canChangeDropdown then
                canChangeTheme = false
                WindUI:SetTheme(theme)
                canChangeTheme = true
            end
        end
    })

    local TransparencySlider = Tabs.Settings:Slider({
        Title = "loc:TRANSPARENCY",
        Value = { Min = 0, Max = 1, Default = 0.2, Step = 0.1 },
        Callback = function(value)
            WindUI.TransparencyValue = tonumber(value)
            Window:ToggleTransparency(tonumber(value) > 0)
        end
    })

    local ThemeToggle = Tabs.Settings:Toggle({
        Title = "Enable Dark Mode",
        Desc = "Use dark color scheme",
        Value = true,
        Callback = function(state)
            if canChangeTheme then
                local newTheme = state and "Dark" or "Light"
                WindUI:SetTheme(newTheme)
                if canChangeDropdown then
                    ThemeDropdown:Select(newTheme)
                end
            end
        end
    })

    WindUI:OnThemeChange(function(theme)
        canChangeTheme = false
        ThemeToggle:Set(theme == "Dark")
        canChangeTheme = true
    end)

    -- Configuration Manager
    local configName = "default"
    local configFile = nil
    local MyPlayerData = {
        name = player.Name,
        level = 1,
        inventory = {}
    }

    Tabs.Settings:Section({ Title = "Configuration Manager", TextSize = 20 })
    Tabs.Settings:Section({ Title = "Save and load your settings", TextSize = 16, TextTransparency = 0.25 })
    Tabs.Settings:Divider()

    Tabs.Settings:Input({
        Title = "Config Name",
        Value = configName,
        Callback = function(value)
            configName = value or "default"
        end
    })

    local ConfigManager = Window.ConfigManager
    if ConfigManager then
        ConfigManager:Init(Window)
        
        Tabs.Settings:Button({
            Title = "loc:SAVE_CONFIG",
            Icon = "save",
            Variant = "Primary",
            Callback = function()
                configFile = ConfigManager:CreateConfig(configName)
                configFile:Register("InfiniteJumpToggle", InfiniteJumpToggle)
                configFile:Register("AutoTicketFarmToggle", AutoTicketFarmToggle)
                configFile:Register("TicketEspToggle", TicketEspToggle)
                configFile:Register("TicketBoxEspToggle", TicketBoxEspToggle)
                configFile:Register("EspTypeDropdown", EspTypeDropdown)
                configFile:Register("TicketTracerEspToggle", TicketTracerEspToggle)
                configFile:Register("TicketDistanceEspToggle", TicketDistanceEspToggle)
                configFile:Register("HighlightsTicketEspToggle", HighlightsTicketEspToggle)
                configFile:Register("FreeCamSpeedSlider", FreeCamSpeedSlider)
                configFile:Register("JumpMethodDropdown", JumpMethodDropdown)
                configFile:Register("FlyToggle", FlyToggle)
                configFile:Register("FlySpeedSlider", FlySpeedSlider)
                configFile:Register("ZoomSlider", ZoomSlider)
                configFile:Register("TPWALKToggle", TPWALKToggle)
                configFile:Register("TPWALKSlider", TPWALKSlider)
                configFile:Register("JumpBoostToggle", JumpBoostToggle)
                configFile:Register("JumpBoostSlider", JumpBoostSlider)
                configFile:Register("AntiAFKToggle", AntiAFKToggle)
                configFile:Register("FullBrightToggle", FullBrightToggle)
                configFile:Register("PlayerBoxESPToggle", PlayerBoxESPToggle)
                configFile:Register("PlayerBoxTypeDropdown", PlayerBoxTypeDropdown)
                configFile:Register("PlayerTracerToggle", PlayerTracerToggle)
                configFile:Register("PlayerNameESPToggle", PlayerNameESPToggle)
                configFile:Register("PlayerDistanceESPToggle", PlayerDistanceESPToggle)
                configFile:Register("PlayerRainbowBoxesToggle", PlayerRainbowBoxesToggle)
                configFile:Register("PlayerRainbowTracersToggle", PlayerRainbowTracersToggle)
                configFile:Register("NextbotESPToggle", NextbotESPToggle)
                configFile:Register("NextbotBoxESPToggle", NextbotBoxESPToggle)
                configFile:Register("NextbotBoxTypeDropdown", NextbotBoxTypeDropdown)
                configFile:Register("NextbotTracerToggle", NextbotTracerToggle)
                configFile:Register("NextbotDistanceESPToggle", NextbotDistanceESPToggle)
                configFile:Register("NextbotRainbowBoxesToggle", NextbotRainbowBoxesToggle)
                configFile:Register("NextbotRainbowTracersToggle", NextbotRainbowTracersToggle)
                configFile:Register("DownedBoxESPToggle", DownedBoxESPToggle)
                configFile:Register("DownedBoxTypeDropdown", DownedBoxTypeDropdown)
                configFile:Register("EmoteDropdown", EmoteDropdown)
configFile:Register("AutoEmoteToggle", AutoEmoteToggle)
 configFile:Register("NoFogToggle", NoFogToggle)
                configFile:Register("DownedTracerToggle", DownedTracerToggle)
                configFile:Register("DownedNameESPToggle", DownedNameESPToggle)
                configFile:Register("DownedDistanceESPToggle", DownedDistanceESPToggle)
                configFile:Register("AutoCarryToggle", AutoCarryToggle)
                configFile:Register("AutoReviveToggle", FastReviveToggle)
                configFile:Register("FastReviveToggle", FastReviveToggle)
                configFile:Register("AutoVoteDropdown", AutoVoteDropdown)
                configFile:Register("AutoVoteToggle", AutoVoteToggle)
                configFile:Register("AutoSelfReviveToggle", AutoSelfReviveToggle)
                configFile:Register("AutoWinToggle", AutoWinToggle)
                configFile:Register("TimerDisplayToggle", TimerDisplayToggle)
                configFile:Register("AutoMoneyFarmToggle", AutoMoneyFarmToggle)
                configFile:Register("ThemeDropdown", ThemeDropdown)
                configFile:Register("TransparencySlider", TransparencySlider)
                configFile:Register("ThemeToggle", ThemeToggle)
                configFile:Register("SpeedInput", SpeedInput)
                configFile:Register("AutoWhistleToggle", AutoWhistleToggle)
                configFile:Register("JumpCapInput", JumpCapInput)
                configFile:Register("StrafeInput", StrafeInput)
                configFile:Register("ApplyMethodDropdown", ApplyMethodDropdown)
                configFile:Register("InfiniteSlideToggle", InfiniteSlideToggle)
                configFile:Register("GravityToggle", GravityToggle)
                configFile:Register("GravityInput", GravityInput)
                configFile:Register("InfiniteSlideSpeedInput", InfiniteSlideSpeedInput)
                configFile:Register("LagSwitchToggle", LagSwitchToggle)
                configFile:Register("LagDurationInput", LagDurationInput)
                configFile:Set("playerData", MyPlayerData)
                configFile:Set("lastSave", os.date("%Y-%m-%d %H:%M:%S"))
                configFile:Save()
            end
        })

        Tabs.Settings:Button({
            Title = "loc:LOAD_CONFIG",
            Icon = "folder",
            Callback = function()
                configFile = ConfigManager:CreateConfig(configName)
                local loadedData = configFile:Load()
                if loadedData then
                    if loadedData.playerData then
                        MyPlayerData = loadedData.playerData
                    end
                    local lastSave = loadedData.lastSave or "Unknown"
                    Tabs.Settings:Paragraph({
                        Title = "Player Data",
                        Desc = string.format("Name: %s\nLevel: %d\nInventory: %s", 
                            MyPlayerData.name, 
                            MyPlayerData.level, 
                            table.concat(MyPlayerData.inventory, ", "))
                    })
                end
            end
        })
    else
        Tabs.Settings:Paragraph({
            Title = "Config Manager Not Available",
            Desc = "This feature requires ConfigManager",
            Image = "alert-triangle",
            ImageSize = 20,
            Color = "White"
        })
    end


    Tabs.Settings:Section({ Title = "Keybind Settings", TextSize = 20 })
    Tabs.Settings:Section({ Title = "Change toggle key for GUI", TextSize = 16, TextTransparency = 0.25 })
    Tabs.Settings:Divider()

    keyBindButton = Tabs.Settings:Button({
        Title = "Keybind",
        Desc = "Current Key: " .. getCleanKeyName(currentKey),
        Icon = "key",
        Variant = "Primary",
        Callback = function()
            bindKey(keyBindButton)
        end
    })

    pcall(updateKeybindButtonDesc)
Tabs.Settings:Section({ Title = "Game Settings (In Beta)", TextSize = 35 })
Tabs.Settings:Section({ Title = "Note: This is a permanent Changes, it's can be used to pass limit value", TextSize = 15 })
Tabs.Settings:Divider()
Tabs.Settings:Section({ Title = "Visual", TextSize = 20 })
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ChangeSettingRemote = ReplicatedStorage:WaitForChild("Events"):WaitForChild("Data"):WaitForChild("ChangeSetting")
local UpdatedEvent = game:GetService("ReplicatedStorage").Modules.Client.Settings.Updated

local UpdatedEvent = game:GetService("ReplicatedStorage").Modules.Client.Settings.Updated
local ChangeSettingRemote = game:GetService("ReplicatedStorage").Events.Data.ChangeSetting

local MapShadowToggle = Tabs.Settings:Toggle({
    Title = "Map Shadow",
    Callback = function(state)
        ChangeSettingRemote:InvokeServer(6, state)
        UpdatedEvent:Fire(6, state)
    end
})

local LowGraphicToggle = Tabs.Settings:Toggle({
    Title = "Low graphic",
    Callback = function(state)
        ChangeSettingRemote:InvokeServer(5, state)
        UpdatedEvent:Fire(5, state)
    end
})
local RagdollToggle = Tabs.Settings:Toggle({
    Title = "Ragdoll",
    Callback = function(state)
        ChangeSettingRemote:InvokeServer(10, state)
        UpdatedEvent:Fire(10, state)
    end
})
local MusicVolumeInput = Tabs.Settings:Input({
    Title = "Music volume",
    Placeholder = "0.5",
    NumbersOnly = true,
    Callback = function(value)
        local num = tonumber(value)
        if num then
            ChangeSettingRemote:InvokeServer(7, num)
            UpdatedEvent:Fire(7, num)
        end
    end
})
local NextbotVolumeInput = Tabs.Settings:Input({
    Title = "Nextbot volume",
    Placeholder = "100",
    NumbersOnly = true,
    Callback = function(value)
        local num = tonumber(value)
        if num then
            ChangeSettingRemote:InvokeServer(9, num)
            UpdatedEvent:Fire(9, num)
        end
    end
})

local BoomBoxVolumeInput = Tabs.Settings:Input({
    Title = "Boom box volume",
    Placeholder = "100",
    NumbersOnly = true,
    Callback = function(value)
        local num = tonumber(value)
        if num then
            ChangeSettingRemote:InvokeServer(4, num)
            UpdatedEvent:Fire(4, num)
        end
    end
})

local EmoteVolumeInput = Tabs.Settings:Input({
    Title = "Emote volume",
    Placeholder = "100",
    NumbersOnly = true,
    Callback = function(value)
        local num = tonumber(value)
        if num then
            ChangeSettingRemote:InvokeServer(8, num)
            UpdatedEvent:Fire(8, num)
        end
    end
})

local NextbotVignetteToggle = Tabs.Settings:Toggle({
    Title = "Nextbot vignette",
    Callback = function(state)
        ChangeSettingRemote:InvokeServer(12, state)
        UpdatedEvent:Fire(12, state)
    end
})

local R15EnabledToggle = Tabs.Settings:Toggle({
    Title = "R15 enabled",
    Callback = function(state)
        ChangeSettingRemote:InvokeServer(15, state)
        UpdatedEvent:Fire(15, state)
    end
})

local AnimatedTagToggle = Tabs.Settings:Toggle({
    Title = "Animated tag",
    Callback = function(state)
        ChangeSettingRemote:InvokeServer(18, state)
        UpdatedEvent:Fire(18, state)
    end
})
Tabs.Settings:Section({ Title = "Game", TextSize = 20 })
local CanBeCarriedToggle = Tabs.Settings:Toggle({
    Title = "Can be carried",
    Callback = function(state)
        ChangeSettingRemote:InvokeServer(1, state)
        UpdatedEvent:Fire(1, state)
    end
})

local FovInput = Tabs.Settings:Input({
    Title = "Fov",
    Placeholder = "100",
    NumbersOnly = true,
    Callback = function(value)
        local num = tonumber(value)
        if num then
            ChangeSettingRemote:InvokeServer(2, num)
            UpdatedEvent:Fire(2, num)
        end
    end
})

local PovScrollToggle = Tabs.Settings:Toggle({
    Title = "Pov scroll",
    Callback = function(state)
        ChangeSettingRemote:InvokeServer(13, state)
        UpdatedEvent:Fire(13, state)
    end
})

local SprintViewmodelToggle = Tabs.Settings:Toggle({
    Title = "Sprint viewmodel",
    Callback = function(state)
        ChangeSettingRemote:InvokeServer(11, state)
        UpdatedEvent:Fire(11, state)
    end
})

local ViewbobToggle = Tabs.Settings:Toggle({
    Title = "Viewbob",
    Callback = function(state)
        ChangeSettingRemote:InvokeServer(3, state)
        UpdatedEvent:Fire(3, state)
    end
})

local VoicchatVolumeInput = Tabs.Settings:Input({
    Title = "Voicchat volume",
    Placeholder = "100",
    NumbersOnly = true,
    Callback = function(value)
        local num = tonumber(value)
        if num then
            ChangeSettingRemote:InvokeServer(14, num)
            UpdatedEvent:Fire(14, num)
        end
    end
})

    Window:SelectTab(1)
end



setupGui()
setupMobileJumpButton()

Window:OnClose(function()
    isWindowOpen = false
	print ("Press " .. getCleanKeyName(currentKey) .. " To Reopen")
    if ConfigManager and configFile then
        configFile:Set("playerData", MyPlayerData)
        configFile:Set("lastSave", os.date("%Y-%m-%d %H:%M:%S"))
        configFile:Save()
    end
    if not game:GetService("UserInputService").TouchEnabled then
        pcall(function()
            WindUI:Notify({
                Title = "GUI Closed",
                Content = "Press " .. getCleanKeyName(currentKey) .. " To Reopen",
                Duration = 3
            })
        end)
    end
end)
Window:OnDestroy(function()
    print("Window destroyed")
    if keyConnection then
        keyConnection:Disconnect()
    end
    if keyInputConnection then
        keyInputConnection:Disconnect()
    end
    saveKeybind()
end)

Window:OnOpen(function()
    print("Window opened")
    isWindowOpen = true
end)

Window:UnlockAll()

local roundStartedConnection
local timerConnection

local function setupAttributeConnections()
    if roundStartedConnection then roundStartedConnection:Disconnect() end
    if timerConnection then timerConnection:Disconnect() end
    
    if gameStatsPath then
        roundStartedConnection = gameStatsPath:GetAttributeChangedSignal("RoundStarted"):Connect(function()
            local roundStarted = gameStatsPath:GetAttribute("RoundStarted")
            if roundStarted == true then
                appliedOnce = false
                applyStoredSettings()
            end
        end)
        
        timerConnection = gameStatsPath:GetAttributeChangedSignal("Timer"):Connect(function()
            if isPlayerModelPresent() and not appliedOnce then
                applySettingsWithDelay()
            end
        end)
    end
end

setupAttributeConnections()

task.spawn(function()
    while true do
        task.wait(0.5)
        local currentlyPresent = isPlayerModelPresent()
        
        if currentlyPresent and not playerModelPresent then
            playerModelPresent = true
            applyStoredSettings()
        elseif not currentlyPresent and playerModelPresent then
            playerModelPresent = false
        end
    end
end)

game:GetService("UserInputService").WindowFocused:Connect(function()
    saveKeybind()
end)


do
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local playerGui = LocalPlayer:WaitForChild("PlayerGui")
getgenv().autoJumpEnabled = false
getgenv().bhopMode = "Acceleration"
getgenv().bhopAccelValue = -0.1
local uiToggledViaUI = false 
local isMobile = UserInputService.TouchEnabled 
local function makeDraggable(frame)
    local dragging, dragInput, dragStart, startPos
    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    frame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input == dragInput then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end
local function createToggleGui(name, varName, yOffset)
    local gui = playerGui:FindFirstChild(name.."Gui")
    if gui then gui:Destroy() end
    gui = Instance.new("ScreenGui", playerGui)
    gui.Name = name.."Gui"
    gui.IgnoreGuiInset = true
    gui.ResetOnSpawn = false
    gui.Enabled = isMobile

    local frame = Instance.new("Frame", gui)
    frame.Size = UDim2.new(0, 60, 0, 60)
    frame.Position = UDim2.new(0.5, -30, 0.12 + yOffset, 0)
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
        uiToggledViaUI = true
        toggleBtn.Text = getgenv()[varName] and "On" or "Off"
        toggleBtn.BackgroundColor3 = getgenv()[varName] and Color3.fromRGB(0, 100, 0) or Color3.fromRGB(0, 0, 0)
        gui.Enabled = true
    end)

    return gui, toggleBtn
end

local jumpGui, jumpToggleBtn
local MainTab = {}
MainTab.Toggle = function(self, config)
    config.Title = config.Title or "Toggle"
    config.Callback = config.Callback or function() end
    config.Value = config.Value or false

    local toggle = {
        Set = function(self, value)
            config.Value = value
            config.Callback(value)
        end
    }
    config.Callback(config.Value)
    return toggle
end

MainTab.Dropdown = function(self, config)
    config.Title = config.Title or "Dropdown"
    config.Values = config.Values or {}
    config.Multi = config.Multi or false
    config.Default = config.Default or (config.Multi and {} or config.Values[1])
    config.Callback = config.Callback or function() end

    local dropdown = {
        Select = function(self, value)
            config.Callback(value)
        end
    }
    config.Callback(config.Default)
    return dropdown
end

MainTab.Input = function(self, config)
    config.Title = config.Title or "Input"
    config.Placeholder = config.Placeholder or ""
    config.Value = config.Value or ""
    config.Callback = config.Callback or function() end

    local input = {
        Set = function(self, value)
            config.Callback(value)
        end
    }
    return input
end

MainTab:Toggle({
    Title = "Bhop",
    Value = false,
    Callback = function(state)
        if not jumpGui then
            jumpGui, jumpToggleBtn = createToggleGui("Bhop", "autoJumpEnabled", 0.12)
        end
        jumpGui.Enabled = (state and uiToggledViaUI) or isMobile 
        jumpToggleBtn.Text = state and "On" or "Off"
        jumpToggleBtn.BackgroundColor3 = state and Color3.fromRGB(0, 100, 0) or Color3.fromRGB(0, 0, 0)
    end
})

MainTab:Dropdown({
    Title = "Bhop Mode",
    Values = {"Acceleration", "No Acceleration"},
    Multi = false,
    Default = "Acceleration",
    Callback = function(value)
        getgenv().bhopMode = value
    end
})

MainTab:Input({
    Title = "Bhop Acceleration (Negative Only)",
    Placeholder = "-0.5",
    Numeric = true,
    Callback = function(value)
        if tostring(value):sub(1, 1) == "-" then
            getgenv().bhopAccelValue = tonumber(value)
        end
    end
})

UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
    if gameProcessedEvent then return end
    if input.KeyCode == Enum.KeyCode.B and featureStates.Bhop then 
        getgenv().autoJumpEnabled = not getgenv().autoJumpEnabled
        uiToggledViaUI = false
        if jumpGui and jumpToggleBtn then
            jumpGui.Enabled = isMobile and getgenv().autoJumpEnabled
            jumpToggleBtn.Text = getgenv().autoJumpEnabled and "On" or "Off"
            jumpToggleBtn.BackgroundColor3 = getgenv().autoJumpEnabled and Color3.fromRGB(0, 100, 0) or Color3.fromRGB(0, 0, 0)
        end
        MainTab:Toggle({
            Title = "Bhop",
            Value = getgenv().autoJumpEnabled,
            Callback = function(state)
                if not jumpGui then
                    jumpGui, jumpToggleBtn = createToggleGui("Bhop", "autoJumpEnabled", 0.12)
                end
                getgenv().autoJumpEnabled = state
                jumpGui.Enabled = (state and uiToggledViaUI) or (isMobile and state)
                jumpToggleBtn.Text = state and "On" or "Off"
                jumpToggleBtn.BackgroundColor3 = state and Color3.fromRGB(0, 100, 0) or Color3.fromRGB(0, 0, 0)
            end
        }):Set(getgenv().autoJumpEnabled)
    end
end)
task.spawn(function()
    while true do
        local friction = 5
        if getgenv().autoJumpEnabled and getgenv().bhopMode == "Acceleration" then
            friction = getgenv().bhopAccelValue or -5
        end
        if getgenv().autoJumpEnabled == false then
            friction = 5
        end

        for _, t in pairs(getgc(true)) do
            if type(t) == "table" and rawget(t, "Friction") then
                if getgenv().bhopMode == "No Acceleration" then
                else
                    t.Friction = friction
                end
            end
        end
        task.wait(0.15)
    end
end)

task.spawn(function()
    while true do
        if getgenv().autoJumpEnabled then
            local character = LocalPlayer.Character
            if character and character:FindFirstChild("Humanoid") then
                local humanoid = character.Humanoid
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
    local Players = game:GetService("Players")
    local player = Players.LocalPlayer
    local guiPath = { "PlayerGui", "Shared", "HUD", "Mobile", "Right", "Mobile", "CrouchButton" }

    local function waitForDescendant(parent, name)
        local found = parent:FindFirstChild(name, true)
        while not found do
            parent.DescendantAdded:Wait()
            found = parent:FindFirstChild(name, true)
        end
        return found
    end

    local function connectCrouchButton()
        local gui = player:WaitForChild(guiPath[1])
        for i = 2, #guiPath do
            gui = waitForDescendant(gui, guiPath[i])
        end
        local button = gui

        local holding = false
        local validHold = false

        button.MouseButton1Down:Connect(function()
            holding = true
            validHold = true
            task.delay(0.5, function()
                if holding and validHold and getgenv().EmoteEnabled and getgenv().SelectedEmote then
                    local args = { [1] = getgenv().SelectedEmote }
                    game:GetService("ReplicatedStorage"):WaitForChild("Events", 9e9):WaitForChild("Character", 9e9):WaitForChild("Emote", 9e9):FireServer(unpack(args))
                end
            end)
        end)

        button.MouseButton1Up:Connect(function()
            holding = false
            validHold = false
        end)
    end

    while true do
        pcall(connectCrouchButton)
        task.wait(1)
    end
end)
end
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local BhopGui = LocalPlayer.PlayerGui:FindFirstChild("BhopGui")

if BhopGui then
    BhopGui.Enabled = false
end
if not featureStates then
    featureStates = {
        CustomGravity = false,
        GravityValue = workspace.Gravity
    }
end
local originalGameGravity = workspace.Gravity
local playerGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui", 5)

local function makeDraggable(frame)
    local dragging = false
    local dragStart = nil
    local startPos = nil

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

    game:GetService("UserInputService").InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

local function createGravityGui(yOffset)
    local gravityGuiOld = playerGui:FindFirstChild("GravityGui")
    if gravityGuiOld then gravityGuiOld:Destroy() end
    
    local gravityGui = Instance.new("ScreenGui")
    gravityGui.Name = "GravityGui"
    gravityGui.IgnoreGuiInset = true
    gravityGui.ResetOnSpawn = false
    gravityGui.Enabled = getgenv().gravityGuiVisible
    gravityGui.Parent = playerGui

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 60, 0, 60)
    frame.Position = UDim2.new(0.5, -30, 0.12 + (yOffset or 0), 0)
    frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    frame.BackgroundTransparency = 0.35
    frame.BorderSizePixel = 0
    frame.Parent = gravityGui
    makeDraggable(frame)

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = frame

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(150, 150, 150)
    stroke.Thickness = 2
    stroke.Parent = frame

    local label = Instance.new("TextLabel")
    label.Text = "Gravity"
    label.Size = UDim2.new(0.9, 0, 0.3, 0)
    label.Position = UDim2.new(0.05, 0, 0.05, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.Font = Enum.Font.Roboto
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Center
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.TextScaled = true
    label.Parent = frame

    local subLabel = Instance.new("TextLabel")
    subLabel.Text = "Toggle"
    subLabel.Size = UDim2.new(0.9, 0, 0.3, 0)
    subLabel.Position = UDim2.new(0.05, 0, 0.3, 0)
    subLabel.BackgroundTransparency = 1
    subLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    subLabel.Font = Enum.Font.Roboto
    subLabel.TextSize = 14
    subLabel.TextXAlignment = Enum.TextXAlignment.Center
    subLabel.TextYAlignment = Enum.TextYAlignment.Center
    subLabel.TextScaled = true
    subLabel.Parent = frame

    local gravityGuiButton = Instance.new("TextButton")
    gravityGuiButton.Name = "ToggleButton"
    gravityGuiButton.Text = featureStates.CustomGravity and "On" or "Off"
    gravityGuiButton.Size = UDim2.new(0.9, 0, 0.35, 0)
    gravityGuiButton.Position = UDim2.new(0.05, 0, 0.6, 0)
    gravityGuiButton.BackgroundColor3 = featureStates.CustomGravity and Color3.fromRGB(0, 120, 80) or Color3.fromRGB(120, 0, 0)
    gravityGuiButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    gravityGuiButton.Font = Enum.Font.Roboto
    gravityGuiButton.TextSize = 12
    gravityGuiButton.TextXAlignment = Enum.TextXAlignment.Center
    gravityGuiButton.TextYAlignment = Enum.TextYAlignment.Center
    gravityGuiButton.TextScaled = true
    gravityGuiButton.Parent = frame

    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 4)
    buttonCorner.Parent = gravityGuiButton

    gravityGuiButton.MouseButton1Click:Connect(function()
        featureStates.CustomGravity = not featureStates.CustomGravity
        if featureStates.CustomGravity then
            workspace.Gravity = featureStates.GravityValue
        else
            workspace.Gravity = originalGameGravity
        end
        gravityGuiButton.Text = featureStates.CustomGravity and "On" or "Off"
        gravityGuiButton.BackgroundColor3 = featureStates.CustomGravity and Color3.fromRGB(0, 120, 80) or Color3.fromRGB(120, 0, 0)
    end)
end
createGravityGui()
game:GetService("UserInputService").InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.J and getgenv().gravityGuiVisible then
        featureStates.CustomGravity = not featureStates.CustomGravity
        if featureStates.CustomGravity then
            workspace.Gravity = featureStates.GravityValue
        else
            workspace.Gravity = originalGameGravity
        end
        local gravityGui = playerGui:FindFirstChild("GravityGui")
        if gravityGui then
            local button = gravityGui.Frame:FindFirstChild("ToggleButton")
            if button then
                button.Text = featureStates.CustomGravity and "On" or "Off"
                button.BackgroundColor3 = featureStates.CustomGravity and Color3.fromRGB(0, 120, 80) or Color3.fromRGB(120, 0, 0)
            end
        end
        WindUI:Notify({
            Title = "Gravity",
            Content = "Custom Gravity " .. (featureStates.CustomGravity and "enabled" or "disabled"),
            Duration = 2
        })
    end
end)
if featureStates.CustomGravity then
    workspace.Gravity = featureStates.GravityValue
else
    workspace.Gravity = originalGameGravity
end
local downedConnection = nil

local function setupDownedListener(character)
    if downedConnection then
        downedConnection:Disconnect()
        downedConnection = nil
    end
    
    if character then
        downedConnection = character:GetAttributeChangedSignal("Downed"):Connect(function()
            if character:GetAttribute("Downed") == true then
                deactivateFreecam()
            end
        end)
        
        if character:GetAttribute("Downed") == true then
            deactivateFreecam()
        end
    end
end

player.CharacterAdded:Connect(function(character)
    setupDownedListener(character)
end)

if player.Character then
    setupDownedListener(player.Character)
end

--[[the part of loadstring prevent error]]
loadstring(game:HttpGet('https://raw.githubusercontent.com/Pnsdgsa/Script-kids/refs/heads/main/Scripthub/Darahub/evade/More-Loadstrings.lua'))()

                local securityPart = Instance.new("Part")
                securityPart.Name = "SecurityPart"
                securityPart.Size = Vector3.new(10, 1, 10)
                securityPart.Position = Vector3.new(0, 500, 0)
                securityPart.Anchored = true
                securityPart.CanCollide = true
                securityPart.Parent = workspace
                rootPart.CFrame = securityPart.CFrame + Vector3.new(0, 3, 0)
