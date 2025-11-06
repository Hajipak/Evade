local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")

local function createPopup()
    local settingsFile = "darahub/serverfindertipspopup_settings.txt"
    
    local function fileExists(path)
        local success, _ = pcall(function()
            readfile(path)
        end)
        return success
    end
    
    local function loadSettings()
        if fileExists(settingsFile) then
            local content = readfile(settingsFile)
            return content == "true"
        end
        return false
    end
    
    local function saveSettings(neverShowAgain)
        local content = neverShowAgain and "true" or "false"
        writefile(settingsFile, content)
    end
    
    if loadSettings() then
        return
    end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "ImportantTipsPopup"
    screenGui.Parent = CoreGui
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
    screenGui.DisplayOrder = 999999
    screenGui.ResetOnSpawn = false

    local UIScale = Instance.new("UIScale")
    UIScale.Name = "UIScale_Popup"
    UIScale.Parent = screenGui
    local screenSize = GuiService:GetScreenResolution()
    if screenSize then
        local baseResolution = 1920
        UIScale.Scale = math.min(1.5, screenSize.X / baseResolution)
    end

    local backgroundFrame = Instance.new("TextButton")
    backgroundFrame.Size = UDim2.new(1, 0, 1, 0)
    backgroundFrame.Position = UDim2.new(0, 0, 0, 0)
    backgroundFrame.BackgroundColor3 = Color3.new(0, 0, 0)
    backgroundFrame.BackgroundTransparency = 0.3
    backgroundFrame.Text = ""
    backgroundFrame.AutoButtonColor = false
    backgroundFrame.Parent = screenGui

    local popupFrame = Instance.new("Frame")
    popupFrame.Size = UDim2.new(0, 560, 0, 490)
    popupFrame.Position = UDim2.new(0.5, -280, 0.5, -245)
    popupFrame.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1)
    popupFrame.BorderSizePixel = 0
    popupFrame.Parent = screenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = popupFrame

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.new(0.3, 0.3, 0.3)
    stroke.Thickness = 3
    stroke.Parent = popupFrame

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, 0, 0, 70)
    titleLabel.Position = UDim2.new(0, 0, 0, 0)
    titleLabel.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
    titleLabel.BorderSizePixel = 0
    titleLabel.Text = "Important tips, read this before use"
    titleLabel.TextColor3 = Color3.new(1, 1, 1)
    titleLabel.TextScaled = true
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.Parent = popupFrame

    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 8)
    titleCorner.Parent = titleLabel

    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Size = UDim2.new(1, -28, 1, -238)
    scrollFrame.Position = UDim2.new(0, 14, 0, 84)
    scrollFrame.BackgroundTransparency = 1
    scrollFrame.BorderSizePixel = 0
    scrollFrame.ScrollBarThickness = 8
    scrollFrame.Parent = popupFrame

    local contentLabel = Instance.new("TextLabel")
    contentLabel.Size = UDim2.new(1, 0, 0, 0)
    contentLabel.AutomaticSize = Enum.AutomaticSize.Y
    contentLabel.BackgroundTransparency = 1
    contentLabel.Text = "In order to make all features work please use good executor and disable verify teleport other wise some feature will not work.\n\nsometimes this script may search duplicated server list, refresh the server to solve the problem, this bug will be patching soon.\n\nWait 10s to able to click okay"
    contentLabel.TextColor3 = Color3.new(1, 1, 1)
    contentLabel.TextSize = 20
    contentLabel.TextWrapped = true
    contentLabel.Font = Enum.Font.Gotham
    contentLabel.TextXAlignment = Enum.TextXAlignment.Left
    contentLabel.TextYAlignment = Enum.TextYAlignment.Top
    contentLabel.Parent = scrollFrame

    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, contentLabel.TextBounds.Y)

    local checkboxFrame = Instance.new("Frame")
    checkboxFrame.Size = UDim2.new(1, -28, 0, 42)
    checkboxFrame.Position = UDim2.new(0, 14, 1, -154)
    checkboxFrame.BackgroundTransparency = 1
    checkboxFrame.Parent = popupFrame

    local checkboxButton = Instance.new("TextButton")
    checkboxButton.Size = UDim2.new(0, 28, 0, 28)
    checkboxButton.Position = UDim2.new(0, 0, 0, 7)
    checkboxButton.BackgroundColor3 = Color3.new(0.3, 0.3, 0.3)
    checkboxButton.BorderSizePixel = 0
    checkboxButton.Text = ""
    checkboxButton.TextColor3 = Color3.new(1, 1, 1)
    checkboxButton.TextSize = 20
    checkboxButton.Font = Enum.Font.GothamBold
    checkboxButton.AutoButtonColor = true
    checkboxButton.Parent = checkboxFrame

    local checkboxCorner = Instance.new("UICorner")
    checkboxCorner.CornerRadius = UDim.new(0, 4)
    checkboxCorner.Parent = checkboxButton

    local checkboxStroke = Instance.new("UIStroke")
    checkboxStroke.Color = Color3.new(0.5, 0.5, 0.5)
    checkboxStroke.Thickness = 1
    checkboxStroke.Parent = checkboxButton

    local checkboxLabel = Instance.new("TextLabel")
    checkboxLabel.Size = UDim2.new(1, -30, 1, 0)
    checkboxLabel.Position = UDim2.new(0, 35, 0, 0)
    checkboxLabel.BackgroundTransparency = 1
    checkboxLabel.Text = "Never show this message again"
    checkboxLabel.TextColor3 = Color3.new(1, 1, 1)
    checkboxLabel.TextSize = 17
    checkboxLabel.TextXAlignment = Enum.TextXAlignment.Left
    checkboxLabel.Font = Enum.Font.Gotham
    checkboxLabel.Parent = checkboxFrame

    local neverShowAgain = false

    checkboxButton.MouseButton1Click:Connect(function()
        neverShowAgain = not neverShowAgain
        
        if neverShowAgain then
            checkboxButton.Text = "✓"
            checkboxButton.BackgroundColor3 = Color3.new(0.2, 0.6, 1)
        else
            checkboxButton.Text = ""
            checkboxButton.BackgroundColor3 = Color3.new(0.3, 0.3, 0.3)
        end
    end)

    local okButton = Instance.new("TextButton")
    okButton.Size = UDim2.new(0, 168, 0, 56)
    okButton.Position = UDim2.new(0.5, -84, 1, -84)
    okButton.BackgroundColor3 = Color3.new(0.3, 0.3, 0.3)
    okButton.BorderSizePixel = 0
    okButton.Text = "Please wait 10s..."
    okButton.TextColor3 = Color3.new(0.5, 0.5, 0.5)
    okButton.TextSize = 20
    okButton.Font = Enum.Font.Gotham
    okButton.AutoButtonColor = false
    okButton.Parent = popupFrame

    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 8)
    buttonCorner.Parent = okButton

    local countdown = 10
    local countdownConnection
    local startTime = os.time()

    local function formatTime(seconds)
        return string.format("%ds", math.ceil(seconds))
    end

    local function updateButtonText()
        okButton.Text = "Please wait " .. formatTime(countdown) .. "..."
    end

    local function enableButton()
        if countdownConnection then
            countdownConnection:Disconnect()
        end
        okButton.Text = "OK"
        okButton.BackgroundColor3 = Color3.new(0.2, 0.6, 1)
        okButton.TextColor3 = Color3.new(1, 1, 1)
        okButton.AutoButtonColor = true
    end

    local function closePopup()
        okButton.AutoButtonColor = false
        
        if neverShowAgain then
            saveSettings(true)
        end

        local clickTween = TweenService:Create(okButton, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundColor3 = Color3.new(0.1, 0.4, 0.8),
            Size = UDim2.new(0, 154, 0, 53)
        })
        clickTween:Play()
        
        clickTween.Completed:Wait()
        
        local returnTween = TweenService:Create(okButton, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, 168, 0, 56)
        })
        returnTween:Play()
        
        returnTween.Completed:Wait()
        
        local closeTween = TweenService:Create(popupFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
            Size = UDim2.new(0, 0, 0, 0),
            Position = UDim2.new(0.5, 0, 0.5, 0),
            BackgroundTransparency = 1
        })
        
        local backgroundTween = TweenService:Create(backgroundFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundTransparency = 1
        })
        
        closeTween:Play()
        backgroundTween:Play()
        
        closeTween.Completed:Connect(function()
            screenGui:Destroy()
        end)
    end

    countdownConnection = RunService.Heartbeat:Connect(function()
        local elapsed = os.time() - startTime
        countdown = math.max(0, 10 - elapsed)
        
        if countdown <= 0 then
            enableButton()
        else
            updateButtonText()
        end
    end)

    okButton.MouseButton1Click:Connect(function()
        if countdown <= 0 then
            closePopup()
        end
    end)

    backgroundFrame.MouseButton1Click:Connect(function()
    end)

    popupFrame.Size = UDim2.new(0, 0, 0, 0)
    popupFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    popupFrame.BackgroundTransparency = 1
    backgroundFrame.BackgroundTransparency = 1
    
    local bgTween = TweenService:Create(backgroundFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        BackgroundTransparency = 0.3
    })
    bgTween:Play()
    
    local popupTween = TweenService:Create(popupFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 560, 0, 490),
        Position = UDim2.new(0.5, -280, 0.5, -245),
        BackgroundTransparency = 0
    })
    popupTween:Play()
end

createPopup()

local S_T = game:GetService("TeleportService")
local S_H = game:GetService("HttpService")
local Players = game:GetService("Players")
local GuiService = game:GetService("GuiService")
local StarterGui = game:GetService("StarterGui")
local AS = game:GetService("AssetService")
local MarketplaceService = game:GetService("MarketplaceService")

local AllIDs = {}
local foundAnything = ""
local actualHour = os.date("!*t").hour
local Deleted = false
local serverList = {}
local guiVisible = true
local sortOption = "Low to High"
local showNonMaxServers = false

local File = pcall(function()
    AllIDs = S_H:JSONDecode(readfile("server-hop-temp.json"))
end)
if not File then
    table.insert(AllIDs, actualHour)
    pcall(function()
        writefile("server-hop-temp.json", S_H:JSONEncode(AllIDs))
    end)
end

local function findServers(placeId)
    local servers = {}
    local cursor = ""
    local maxRetries = 3
    retryDelay = 1

    if not tonumber(placeId) or placeId <= 0 then
        return servers, "Invalid Place ID"
    end

    repeat
        local url = 'https://games.roblox.com/v1/games/' .. placeId .. '/servers/Public?sortOrder=Asc&limit=100'
        if cursor ~= "" then
            url = url .. '&cursor=' .. cursor
        end
        local success, Site
        for attempt = 1, maxRetries do
            success, Site = pcall(function()
                return S_H:JSONDecode(game:HttpGet(url))
            end)
            if success and Site and Site.data then
                break
            end
            wait(retryDelay * attempt)
        end
        if success and Site and Site.data then
            for _, server in pairs(Site.data) do
                table.insert(servers, {
                    id = server.id,
                    playing = server.playing,
                    maxPlayers = server.maxPlayers
                })
            end
            cursor = Site.nextPageCursor or ""
        else
            return servers, "Failed to fetch servers: API error"
        end
        wait(0.5)
    until cursor == "" or cursor == "null" or cursor == nil
    return servers, nil
end

local function getGameInfo(placeId, maxLabel)
    local maxRetries = 3
    local retryDelay = 1
    local servers, err
    for attempt = 1, maxRetries do
        servers, err = findServers(placeId)
        if not err and #servers > 0 then
            maxLabel.Text = "Max Players: " .. servers[1].maxPlayers
            return
        end
        if attempt < maxRetries then
            wait(retryDelay * attempt)
        end
    end
    maxLabel.Text = "Max Players: ?"
end

local function TPReturner(placeId, desiredPlayerCount)
    if not tonumber(placeId) or placeId <= 0 then
        return false, "Invalid Place ID"
    end
    if not tonumber(desiredPlayerCount) or desiredPlayerCount < 0 then
        return false, "Invalid player count"
    end

    local Site
    local maxRetries = 3
    local retryDelay = 1

    for attempt = 1, maxRetries do
        local success, result = pcall(function()
            if foundAnything == "" then
                return S_H:JSONDecode(game:HttpGet('https://games.roblox.com/v1/games/' .. placeId .. '/servers/Public?sortOrder=Asc&limit=100'))
            else
                return S_H:JSONDecode(game:HttpGet('https://games.roblox.com/v1/games/' .. placeId .. '/servers/Public?sortOrder=Asc&limit=100&cursor=' .. foundAnything))
            end
        end)
        if success then
            Site = result
            break
        end
        wait(retryDelay * attempt)
    end

    if not Site or not Site.data then
        return false, "Failed to fetch servers: API error"
    end

    local ID = ""
    if Site.nextPageCursor and Site.nextPageCursor ~= "null" and Site.nextPageCursor ~= nil then
        foundAnything = Site.nextPageCursor
    end
    local num = 0
    for _, v in pairs(Site.data) do
        local Possible = true
        ID = tostring(v.id)
        if tonumber(v.playing) == tonumber(desiredPlayerCount) then
            for _, Existing in pairs(AllIDs) do
                if num ~= 0 then
                    if ID == tostring(Existing) then
                        Possible = false
                    end
                else
                    if tonumber(actualHour) ~= tonumber(Existing) then
                        local delFile = pcall(function()
                            delfile("server-hop-temp.json")
                            AllIDs = {}
                            table.insert(AllIDs, actualHour)
                        end)
                    end
                end
                num = num + 1
            end
            if Possible then
                table.insert(AllIDs, ID)
                local success, err = pcall(function()
                    writefile("server-hop-temp.json", S_H:JSONEncode(AllIDs))
                    S_T:TeleportToPlaceInstance(placeId, ID, Players.LocalPlayer)
                end)
                if success then
                    return true, nil
                else
                    return false, "Teleport failed: " .. tostring(err)
                end
            end
        end
    end
    return false, "No server found with " .. desiredPlayerCount .. " players"
end

local function joinServerById(placeId, serverId)
    if not tonumber(placeId) or placeId <= 0 then
        return false, "Invalid Place ID"
    end
    if not serverId or serverId == "" then
        return false, "Invalid Server ID"
    end

    local success, err = pcall(function()
        table.insert(AllIDs, serverId)
        writefile("server-hop-temp.json", S_H:JSONEncode(AllIDs))
        S_T:TeleportToPlaceInstance(placeId, serverId, Players.LocalPlayer)
    end)
    if success then
        return true, nil
    else
        return false, "Teleport failed: " .. tostring(err)
    end
end

local function createGUI()
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "ServerHopGUI"
    ScreenGui.Parent = game:GetService("CoreGui")
    ScreenGui.ResetOnSpawn = false
    ScreenGui.DisplayOrder = 99

    local UIScale = Instance.new("UIScale")
    UIScale.Name = "UIScale_ScreenGui"
    UIScale.Parent = ScreenGui
    local screenSize = GuiService:GetScreenResolution()
    if screenSize then
        local baseResolution = 1920
        UIScale.Scale = math.min(1.5, screenSize.X / baseResolution)
    end

    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, 950, 0, 630)
    MainFrame.Position = UDim2.new(0.5, -475, 0.5, -315)
    MainFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    MainFrame.BorderSizePixel = 0
    MainFrame.Parent = ScreenGui

    local UICornerMain = Instance.new("UICorner")
    UICornerMain.Name = "UICorner_MainFrame"
    UICornerMain.CornerRadius = UDim.new(0, 12)
    UICornerMain.Parent = MainFrame

    local CloseButton = Instance.new("TextButton")
    CloseButton.Name = "CloseButton"
    CloseButton.Size = UDim2.new(0, 40, 0, 40)
    CloseButton.Position = UDim2.new(1, -50, 0, 10)
    CloseButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    CloseButton.TextSize = 20
    CloseButton.Font = Enum.Font.SourceSansBold
    CloseButton.Text = "X"
    CloseButton.TextScaled = true
    CloseButton.TextWrapped = true
    CloseButton.Parent = MainFrame

    local UICornerCloseButton = Instance.new("UICorner")
    UICornerCloseButton.Name = "UICorner_CloseButton"
    UICornerCloseButton.CornerRadius = UDim.new(0, 8)
    UICornerCloseButton.Parent = CloseButton

    local GameListTitle = Instance.new("TextLabel")
    GameListTitle.Name = "GameListTitle"
    GameListTitle.Size = UDim2.new(0, 320, 0, 30)
    GameListTitle.Position = UDim2.new(0, 20, 0, 10)
    GameListTitle.BackgroundTransparency = 1
    GameListTitle.Text = "GAME LIST"
    GameListTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    GameListTitle.TextSize = 18
    GameListTitle.Font = Enum.Font.SourceSansBold
    GameListTitle.TextScaled = true
    GameListTitle.TextWrapped = true
    GameListTitle.TextXAlignment = Enum.TextXAlignment.Center
    GameListTitle.Parent = MainFrame
    GameListTitle.Visible = true

    local HopTitle = Instance.new("TextLabel")
    HopTitle.Name = "HopTitle"
    HopTitle.Size = UDim2.new(0, 250, 0, 30)
    HopTitle.Position = UDim2.new(0, 350, 0, 10)
    HopTitle.BackgroundTransparency = 1
    HopTitle.Text = "Advanced Server Hop"
    HopTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    HopTitle.TextSize = 18
    HopTitle.Font = Enum.Font.SourceSansBold
    HopTitle.TextScaled = true
    HopTitle.TextWrapped = true
    HopTitle.TextXAlignment = Enum.TextXAlignment.Center
    HopTitle.Parent = MainFrame

    local AdvancedControlsFrame = Instance.new("Frame")
    AdvancedControlsFrame.Name = "AdvancedControlsFrame"
    AdvancedControlsFrame.Size = UDim2.new(0, 260, 0, 450)
    AdvancedControlsFrame.Position = UDim2.new(0, 340, 0, 50)
    AdvancedControlsFrame.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    AdvancedControlsFrame.BorderSizePixel = 0
    AdvancedControlsFrame.Parent = MainFrame

    local UICornerAdvancedControls = Instance.new("UICorner")
    UICornerAdvancedControls.Name = "UICorner_AdvancedControlsFrame"
    UICornerAdvancedControls.CornerRadius = UDim.new(0, 8)
    UICornerAdvancedControls.Parent = AdvancedControlsFrame

    local ServersListTitle = Instance.new("TextLabel")
    ServersListTitle.Name = "ServersListTitle"
    ServersListTitle.Size = UDim2.new(0, 320, 0, 30)
    ServersListTitle.Position = UDim2.new(0, 610, 0, 10)
    ServersListTitle.BackgroundTransparency = 1
    ServersListTitle.Text = "Servers List"
    ServersListTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    ServersListTitle.TextSize = 18
    ServersListTitle.Font = Enum.Font.SourceSansBold
    ServersListTitle.TextScaled = true
    ServersListTitle.TextWrapped = true
    ServersListTitle.TextTruncate = Enum.TextTruncate.AtEnd
    ServersListTitle.TextXAlignment = Enum.TextXAlignment.Center
    ServersListTitle.Parent = MainFrame

    local GamesScrollingFrame = Instance.new("ScrollingFrame")
    GamesScrollingFrame.Name = "GamesScrollingFrame"
    GamesScrollingFrame.Size = UDim2.new(0, 320, 0, 530)
    GamesScrollingFrame.Position = UDim2.new(0, 20, 0, 50)
    GamesScrollingFrame.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    GamesScrollingFrame.BorderSizePixel = 0
    GamesScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    GamesScrollingFrame.ScrollBarThickness = 10
    GamesScrollingFrame.ClipsDescendants = true
    GamesScrollingFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    GamesScrollingFrame.ScrollingDirection = Enum.ScrollingDirection.Y
    GamesScrollingFrame.Parent = MainFrame
    GamesScrollingFrame.Visible = true

    local UICornerGamesScroll = Instance.new("UICorner")
    UICornerGamesScroll.Name = "UICorner_GamesScrollingFrame"
    UICornerGamesScroll.CornerRadius = UDim.new(0, 8)
    UICornerGamesScroll.Parent = GamesScrollingFrame

    local GamesUIListLayout = Instance.new("UIListLayout")
    GamesUIListLayout.Name = "UIListLayout_GamesScrollingFrame"
    GamesUIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    GamesUIListLayout.Padding = UDim.new(0, 8)
    GamesUIListLayout.Parent = GamesScrollingFrame

    local SortDropdown = Instance.new("TextButton")
    SortDropdown.Name = "SortDropdown"
    SortDropdown.Size = UDim2.new(0, 250, 0, 40)
    SortDropdown.Position = UDim2.new(0, 5, 0, 10)
    SortDropdown.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    SortDropdown.TextColor3 = Color3.fromRGB(255, 255, 255)
    SortDropdown.TextSize = 18
    SortDropdown.Font = Enum.Font.SourceSans
    SortDropdown.Text = "Sort: " .. sortOption
    SortDropdown.TextScaled = true
    SortDropdown.TextWrapped = true
    SortDropdown.Parent = AdvancedControlsFrame

    local UICornerSortDropdown = Instance.new("UICorner")
    UICornerSortDropdown.Name = "UICorner_SortDropdown"
    UICornerSortDropdown.CornerRadius = UDim.new(0, 8)
    UICornerSortDropdown.Parent = SortDropdown

    local CheckboxFrame = Instance.new("Frame")
    CheckboxFrame.Name = "CheckboxFrame"
    CheckboxFrame.Size = UDim2.new(0, 250, 0, 40)
    CheckboxFrame.Position = UDim2.new(0, 5, 0, 60)
    CheckboxFrame.BackgroundTransparency = 1
    CheckboxFrame.Parent = AdvancedControlsFrame

    local Checkbox = Instance.new("TextButton")
    Checkbox.Name = "Checkbox"
    Checkbox.Size = UDim2.new(0, 30, 0, 30)
    Checkbox.Position = UDim2.new(0, 0, 0, 5)
    Checkbox.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    Checkbox.TextColor3 = Color3.fromRGB(255, 255, 255)
    Checkbox.TextSize = 18
    Checkbox.Font = Enum.Font.SourceSansBold
    Checkbox.Text = showNonMaxServers and "✓" or ""
    Checkbox.TextScaled = true
    Checkbox.TextWrapped = true
    Checkbox.Parent = CheckboxFrame

    local UICornerCheckbox = Instance.new("UICorner")
    UICornerCheckbox.Name = "UICorner_Checkbox"
    UICornerCheckbox.CornerRadius = UDim.new(0, 8)
    UICornerCheckbox.Parent = Checkbox

    local CheckboxLabel = Instance.new("TextLabel")
    CheckboxLabel.Name = "CheckboxLabel"
    CheckboxLabel.Size = UDim2.new(0, 200, 0, 30)
    CheckboxLabel.Position = UDim2.new(0, 40, 0, 5)
    CheckboxLabel.BackgroundTransparency = 1
    CheckboxLabel.Text = "Show only non-full servers"
    CheckboxLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    CheckboxLabel.TextSize = 16
    CheckboxLabel.Font = Enum.Font.SourceSans
    CheckboxLabel.TextScaled = true
    CheckboxLabel.TextWrapped = true
    CheckboxLabel.TextXAlignment = Enum.TextXAlignment.Left
    CheckboxLabel.Parent = CheckboxFrame

    local GameNameLabel = Instance.new("TextLabel")
    GameNameLabel.Name = "GameNameLabel"
    GameNameLabel.Size = UDim2.new(0, 250, 0, 30)
    GameNameLabel.Position = UDim2.new(0, 5, 0, 105)
    GameNameLabel.BackgroundTransparency = 1
    GameNameLabel.Text = "Game: Unknown"
    GameNameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    GameNameLabel.TextSize = 16
    GameNameLabel.Font = Enum.Font.SourceSansBold
    GameNameLabel.TextScaled = true
    GameNameLabel.TextWrapped = true
    GameNameLabel.TextXAlignment = Enum.TextXAlignment.Left
    GameNameLabel.Parent = AdvancedControlsFrame

    local PlaceIdInput = Instance.new("TextBox")
    PlaceIdInput.Name = "PlaceIdInput"
    PlaceIdInput.Size = UDim2.new(0, 250, 0, 40)
    PlaceIdInput.Position = UDim2.new(0, 5, 0, 140)
    PlaceIdInput.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    PlaceIdInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    PlaceIdInput.TextSize = 18
    PlaceIdInput.Font = Enum.Font.SourceSans
    PlaceIdInput.PlaceholderText = "Enter Place ID"
    PlaceIdInput.Text = ""
    PlaceIdInput.ClipsDescendants = true
    PlaceIdInput.TextScaled = true
    PlaceIdInput.TextWrapped = true
    PlaceIdInput.ClearTextOnFocus = false
    PlaceIdInput.Parent = AdvancedControlsFrame

    local UICornerPlaceIdInput = Instance.new("UICorner")
    UICornerPlaceIdInput.Name = "UICorner_PlaceIdInput"
    UICornerPlaceIdInput.CornerRadius = UDim.new(0, 8)
    UICornerPlaceIdInput.Parent = PlaceIdInput

    local PlayerCountInput = Instance.new("TextBox")
    PlayerCountInput.Name = "PlayerCountInput"
    PlayerCountInput.Size = UDim2.new(0, 250, 0, 40)
    PlayerCountInput.Position = UDim2.new(0, 5, 0, 190)
    PlayerCountInput.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    PlayerCountInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    PlayerCountInput.TextSize = 18
    PlayerCountInput.Font = Enum.Font.SourceSans
    PlayerCountInput.PlaceholderText = "Enter player count to hop"
    PlayerCountInput.Text = ""
    PlayerCountInput.ClipsDescendants = true
    PlayerCountInput.TextScaled = true
    PlayerCountInput.TextWrapped = true
    PlayerCountInput.ClearTextOnFocus = false
    PlayerCountInput.Parent = AdvancedControlsFrame

    local UICornerPlayerCountInput = Instance.new("UICorner")
    UICornerPlayerCountInput.Name = "UICorner_PlayerCountInput"
    UICornerPlayerCountInput.CornerRadius = UDim.new(0, 8)
    UICornerPlayerCountInput.Parent = PlayerCountInput

    local ServerIdInput = Instance.new("TextBox")
    ServerIdInput.Name = "ServerIdInput"
    ServerIdInput.Size = UDim2.new(0, 250, 0, 40)
    ServerIdInput.Position = UDim2.new(0, 5, 0, 240)
    ServerIdInput.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    ServerIdInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    ServerIdInput.TextSize = 18
    ServerIdInput.Font = Enum.Font.SourceSans
    ServerIdInput.PlaceholderText = "Enter Server ID or Link"
    ServerIdInput.Text = ""
    ServerIdInput.ClearTextOnFocus = false
    ServerIdInput.ClipsDescendants = true
    ServerIdInput.TextScaled = true
    ServerIdInput.TextWrapped = true
    ServerIdInput.Parent = AdvancedControlsFrame

    local UICornerServerIdInput = Instance.new("UICorner")
    UICornerServerIdInput.Name = "UICorner_ServerIdInput"
    UICornerServerIdInput.CornerRadius = UDim.new(0, 8)
    UICornerServerIdInput.Parent = ServerIdInput

    local SearchInput = Instance.new("TextBox")
    SearchInput.Name = "SearchInput"
    SearchInput.Size = UDim2.new(0, 250, 0, 40)
    SearchInput.Position = UDim2.new(0, 5, 0, 290)
    SearchInput.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    SearchInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    SearchInput.TextSize = 18
    SearchInput.Font = Enum.Font.SourceSans
    SearchInput.PlaceholderText = "Search by player count"
    SearchInput.Text = ""
    SearchInput.ClipsDescendants = true
    SearchInput.TextScaled = true
    SearchInput.ClearTextOnFocus = false
    SearchInput.TextWrapped = true
    SearchInput.Parent = AdvancedControlsFrame

    local UICornerSearchInput = Instance.new("UICorner")
    UICornerSearchInput.Name = "UICorner_SearchInput"
    UICornerSearchInput.CornerRadius = UDim.new(0, 8)
    UICornerSearchInput.Parent = SearchInput

    local HopButton = Instance.new("TextButton")
    HopButton.Name = "HopButton"
    HopButton.Size = UDim2.new(0, 120, 0, 40)
    HopButton.Position = UDim2.new(0, 5, 0, 340)
    HopButton.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
    HopButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    HopButton.TextSize = 18
    HopButton.Font = Enum.Font.SourceSansBold
    HopButton.Text = "Hop"
    HopButton.TextScaled = true
    HopButton.TextWrapped = true
    HopButton.Parent = AdvancedControlsFrame

    local UICornerHopButton = Instance.new("UICorner")
    UICornerHopButton.Name = "UICorner_HopButton"
    UICornerHopButton.CornerRadius = UDim.new(0, 8)
    UICornerHopButton.Parent = HopButton

    local JoinServerButton = Instance.new("TextButton")
    JoinServerButton.Name = "JoinServerButton"
    JoinServerButton.Size = UDim2.new(0, 120, 0, 40)
    JoinServerButton.Position = UDim2.new(0, 135, 0, 340)
    JoinServerButton.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
    JoinServerButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    JoinServerButton.TextSize = 18
    JoinServerButton.Font = Enum.Font.SourceSansBold
    JoinServerButton.Text = "Join Server"
    JoinServerButton.TextScaled = true
    JoinServerButton.TextWrapped = true
    JoinServerButton.Parent = AdvancedControlsFrame

    local UICornerJoinServerButton = Instance.new("UICorner")
    UICornerJoinServerButton.Name = "UICorner_JoinServerButton"
    UICornerJoinServerButton.CornerRadius = UDim.new(0, 8)
    UICornerJoinServerButton.Parent = JoinServerButton

    local RefreshButton = Instance.new("TextButton")
    RefreshButton.Name = "RefreshButton"
    RefreshButton.Size = UDim2.new(0, 120, 0, 40)
    RefreshButton.Position = UDim2.new(0, 5, 0, 390)
    RefreshButton.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
    RefreshButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    RefreshButton.TextSize = 18
    RefreshButton.Font = Enum.Font.SourceSansBold
    RefreshButton.Text = "Refresh"
    RefreshButton.TextScaled = true
    RefreshButton.TextWrapped = true
    RefreshButton.Parent = AdvancedControlsFrame

    local UICornerRefreshButton = Instance.new("UICorner")
    UICornerRefreshButton.Name = "UICorner_RefreshButton"
    UICornerRefreshButton.CornerRadius = UDim.new(0, 8)
    UICornerRefreshButton.Parent = RefreshButton

    local Status = Instance.new("TextLabel")
    Status.Name = "Status"
    Status.Size = UDim2.new(0, 910, 0, 30)
    Status.Position = UDim2.new(0, 20, 0, 590)
    Status.BackgroundTransparency = 1
    Status.Text = ""
    Status.TextColor3 = Color3.fromRGB(255, 255, 255)
    Status.TextSize = 16
    Status.Font = Enum.Font.SourceSans
    Status.TextScaled = true
    Status.TextWrapped = true
    Status.Parent = MainFrame

    local ScrollingFrame = Instance.new("ScrollingFrame")
    ScrollingFrame.Name = "ServersScrollingFrame"
    ScrollingFrame.Size = UDim2.new(0, 320, 0, 530)
    ScrollingFrame.Position = UDim2.new(0, 610, 0, 50)
    ScrollingFrame.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    ScrollingFrame.BorderSizePixel = 0
    ScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    ScrollingFrame.ScrollBarThickness = 10
    ScrollingFrame.ClipsDescendants = true
    ScrollingFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    ScrollingFrame.ScrollingDirection = Enum.ScrollingDirection.Y
    ScrollingFrame.Parent = MainFrame

    local UICornerScroll = Instance.new("UICorner")
    UICornerScroll.Name = "UICorner_ServersScrollingFrame"
    UICornerScroll.CornerRadius = UDim.new(0, 8)
    UICornerScroll.Parent = ScrollingFrame

    local UIListLayout = Instance.new("UIListLayout")
    UIListLayout.Name = "UIListLayout_ServersScrollingFrame"
    UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    UIListLayout.Padding = UDim.new(0, 8)
    UIListLayout.Parent = ScrollingFrame

    local function fetchGames()
        for _, child in pairs(GamesScrollingFrame:GetChildren()) do
            if child:IsA("Frame") then
                child:Destroy()
            end
        end

        local places = {}
        local success, pages = pcall(function()
            return AS:GetGamePlacesAsync()
        end)
        if success then
            repeat
                local currentPage = pages:GetCurrentPage()
                for _, placeInfo in ipairs(currentPage) do
                    table.insert(places, placeInfo)
                end
            until pages.IsFinished
        end

        local currentPlace = nil
        local otherPlaces = {}
        local totalPlaces = #places

        for _, placeInfo in ipairs(places) do
            if placeInfo.PlaceId == game.PlaceId then
                currentPlace = placeInfo
            else
                table.insert(otherPlaces, placeInfo)
            end
        end

        table.sort(otherPlaces, function(a, b)
            return a.Name < b.Name
        end)

        local layoutOrder = 0

        if totalPlaces > 1 then
            GamesScrollingFrame.Visible = true
            GameListTitle.Visible = true

            if currentPlace then
                local HeaderFrame = Instance.new("Frame")
                HeaderFrame.Name = "HeaderFrame_CurrentPlace"
                HeaderFrame.Size = UDim2.new(1, -10, 0, 170)
                HeaderFrame.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
                HeaderFrame.LayoutOrder = layoutOrder
                HeaderFrame.Parent = GamesScrollingFrame

                local UICornerHeader = Instance.new("UICorner")
                UICornerHeader.Name = "UICorner_HeaderFrame_CurrentPlace"
                UICornerHeader.CornerRadius = UDim.new(0, 8)
                UICornerHeader.Parent = HeaderFrame

                local UIStrokeHeader = Instance.new("UIStroke")
                UIStrokeHeader.Name = "UIStroke_HeaderFrame_CurrentPlace"
                UIStrokeHeader.Color = Color3.fromRGB(0, 90, 160)
                UIStrokeHeader.Thickness = 1
                UIStrokeHeader.Transparency = 0.5
                UIStrokeHeader.Parent = HeaderFrame

                local HeaderLabel = Instance.new("TextLabel")
                HeaderLabel.Name = "HeaderLabel_CurrentPlace"
                HeaderLabel.Size = UDim2.new(1, -20, 0, 30)
                HeaderLabel.Position = UDim2.new(0, 10, 0, 5)
                HeaderLabel.BackgroundTransparency = 1
                HeaderLabel.Text = "You're currently in"
                HeaderLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                HeaderLabel.TextSize = 28
                HeaderLabel.Font = Enum.Font.SourceSansBold
                HeaderLabel.TextXAlignment = Enum.TextXAlignment.Center
                HeaderLabel.TextYAlignment = Enum.TextYAlignment.Center
                HeaderLabel.Parent = HeaderFrame

                local GameFrame = Instance.new("Frame")
                GameFrame.Name = "GameFrame_CurrentPlace"
                GameFrame.Size = UDim2.new(1, -20, 0, 130)
                GameFrame.Position = UDim2.new(0, 10, 0, 35)
                GameFrame.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
                GameFrame.Parent = HeaderFrame

                local UICornerGame = Instance.new("UICorner")
                UICornerGame.Name = "UICorner_GameFrame_CurrentPlace"
                UICornerGame.CornerRadius = UDim.new(0, 8)
                UICornerGame.Parent = GameFrame

                local UIStrokeGame = Instance.new("UIStroke")
                UIStrokeGame.Name = "UIStroke_GameFrame_CurrentPlace"
                UIStrokeGame.Color = Color3.fromRGB(60, 60, 60)
                UIStrokeGame.Thickness = 1
                UIStrokeGame.Transparency = 0.3
                UIStrokeGame.Parent = GameFrame

                local NameLabel = Instance.new("TextLabel")
                NameLabel.Name = "NameLabel_CurrentPlace"
                NameLabel.Size = UDim2.new(1, -20, 0, 50)
                NameLabel.Position = UDim2.new(0, 10, 0, 5)
                NameLabel.BackgroundTransparency = 1
                NameLabel.Text = currentPlace.Name
                NameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                NameLabel.TextSize = 18
                NameLabel.Font = Enum.Font.SourceSansBold
                NameLabel.TextScaled = true
                NameLabel.TextWrapped = true
                NameLabel.TextXAlignment = Enum.TextXAlignment.Left
                NameLabel.TextTruncate = Enum.TextTruncate.AtEnd
                NameLabel.Parent = GameFrame

                local InfoFrame = Instance.new("Frame")
                InfoFrame.Name = "InfoFrame_CurrentPlace"
                InfoFrame.Size = UDim2.new(1, -20, 0, 30)
                InfoFrame.Position = UDim2.new(0, 10, 0, 55)
                InfoFrame.BackgroundTransparency = 1
                InfoFrame.Parent = GameFrame

                local InfoLayout = Instance.new("UIListLayout")
                InfoLayout.Name = "UIListLayout_InfoFrame_CurrentPlace"
                InfoLayout.FillDirection = Enum.FillDirection.Horizontal
                InfoLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
                InfoLayout.VerticalAlignment = Enum.VerticalAlignment.Center
                InfoLayout.Padding = UDim.new(0, 20)
                InfoLayout.Parent = InfoFrame

                local IDLabel = Instance.new("TextLabel")
                IDLabel.Name = "IDLabel_CurrentPlace"
                IDLabel.Size = UDim2.new(0, 120, 1, 0)
                IDLabel.BackgroundTransparency = 1
                IDLabel.Text = "ID: " .. currentPlace.PlaceId
                IDLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
                IDLabel.TextSize = 14
                IDLabel.Font = Enum.Font.SourceSans
                IDLabel.TextScaled = true
                IDLabel.TextWrapped = true
                IDLabel.TextXAlignment = Enum.TextXAlignment.Left
                IDLabel.Parent = InfoFrame

                local maxPlayers = "Loading..."

                local MaxLabel = Instance.new("TextLabel")
                MaxLabel.Name = "MaxLabel_CurrentPlace"
                MaxLabel.Size = UDim2.new(0, 150, 1, 0)
                MaxLabel.BackgroundTransparency = 1
                MaxLabel.Text = "Max Players: " .. maxPlayers
                MaxLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
                MaxLabel.TextSize = 14
                MaxLabel.Font = Enum.Font.SourceSans
                MaxLabel.TextScaled = true
                MaxLabel.TextWrapped = true
                MaxLabel.TextXAlignment = Enum.TextXAlignment.Left
                MaxLabel.Parent = InfoFrame

                local ButtonsFrame = Instance.new("Frame")
                ButtonsFrame.Name = "ButtonsFrame_CurrentPlace"
                ButtonsFrame.Size = UDim2.new(1, -20, 0, 40)
                ButtonsFrame.Position = UDim2.new(0, 10, 0, 85)
                ButtonsFrame.BackgroundTransparency = 1
                ButtonsFrame.Parent = GameFrame

                local ButtonsLayout = Instance.new("UIListLayout")
                ButtonsLayout.Name = "UIListLayout_ButtonsFrame_CurrentPlace"
                ButtonsLayout.FillDirection = Enum.FillDirection.Horizontal
                ButtonsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
                ButtonsLayout.VerticalAlignment = Enum.VerticalAlignment.Center
                ButtonsLayout.Padding = UDim.new(0, 5)
                ButtonsLayout.Parent = ButtonsFrame

                local JoinButton = Instance.new("TextButton")
                JoinButton.Name = "JoinButton_CurrentPlace"
                JoinButton.Size = UDim2.new(0, 80, 1, 0)
                JoinButton.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
                JoinButton.TextColor3 = Color3.fromRGB(255, 255, 255)
                JoinButton.TextSize = 12
                JoinButton.Font = Enum.Font.SourceSansBold
                JoinButton.Text = "Join"
                JoinButton.TextScaled = true
                JoinButton.TextWrapped = true
                JoinButton.Parent = ButtonsFrame

                local UICornerJoin = Instance.new("UICorner")
                UICornerJoin.Name = "UICorner_JoinButton_CurrentPlace"
                UICornerJoin.CornerRadius = UDim.new(0, 6)
                UICornerJoin.Parent = JoinButton

                JoinButton.MouseButton1Click:Connect(function()
                    if not guiVisible then return end
                    S_T:Teleport(currentPlace.PlaceId, Players.LocalPlayer)
                end)

                local FindServersButton = Instance.new("TextButton")
                FindServersButton.Name = "FindServersButton_CurrentPlace"
                FindServersButton.Size = UDim2.new(0, 90, 1, 0)
                FindServersButton.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
                FindServersButton.TextColor3 = Color3.fromRGB(255, 255, 255)
                FindServersButton.TextSize = 12
                FindServersButton.Font = Enum.Font.SourceSansBold
                FindServersButton.Text = "Find Servers"
                FindServersButton.TextScaled = true
                FindServersButton.TextWrapped = true
                FindServersButton.Parent = ButtonsFrame

                local UICornerFind = Instance.new("UICorner")
                UICornerFind.Name = "UICorner_FindServersButton_CurrentPlace"
                UICornerFind.CornerRadius = UDim.new(0, 6)
                UICornerFind.Parent = FindServersButton

                FindServersButton.MouseButton1Click:Connect(function()
                    if not guiVisible then return end
                    PlaceIdInput.Text = tostring(currentPlace.PlaceId)
                    local filterCount = tonumber(SearchInput.Text)
                    updateServerList(filterCount)
                    Status.Text = "Switched to servers for " .. currentPlace.Name
                end)

                local CopyButton = Instance.new("TextButton")
                CopyButton.Name = "CopyButton_CurrentPlace"
                CopyButton.Size = UDim2.new(0, 80, 1, 0)
                CopyButton.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
                CopyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
                CopyButton.TextSize = 12
                CopyButton.Font = Enum.Font.SourceSansBold
                CopyButton.Text = "Copy ID"
                CopyButton.TextScaled = true
                CopyButton.TextWrapped = true
                CopyButton.Parent = ButtonsFrame

                local UICornerCopy = Instance.new("UICorner")
                UICornerCopy.Name = "UICorner_CopyButton_CurrentPlace"
                UICornerCopy.CornerRadius = UDim.new(0, 6)
                UICornerCopy.Parent = CopyButton

                CopyButton.MouseButton1Click:Connect(function()
                    if not guiVisible then return end
                    pcall(function()
                        setclipboard(tostring(currentPlace.PlaceId))
                        StarterGui:SetCore("SendNotification", {
                            Title = "Copied",
                            Text = "Place ID copied to clipboard!",
                            Duration = 3
                        })
                    end)
                    Status.Text = "Copied Place ID for " .. currentPlace.Name
                end)

                task.spawn(function()
                    getGameInfo(currentPlace.PlaceId, MaxLabel)
                end)

                layoutOrder = layoutOrder + 1
            end

            for _, placeInfo in ipairs(otherPlaces) do
                local maxPlayers = "Loading..."

                local RowFrame = Instance.new("Frame")
                local sanitizedName = placeInfo.Name:gsub("%W", "")
                RowFrame.Name = "RowFrame_" .. sanitizedName
                RowFrame.Size = UDim2.new(1, -10, 0, 150)
                RowFrame.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
                RowFrame.LayoutOrder = layoutOrder
                RowFrame.Parent = GamesScrollingFrame
                RowFrame.ClipsDescendants = true

                local UICornerRow = Instance.new("UICorner")
                UICornerRow.Name = "UICorner_RowFrame_" .. sanitizedName
                UICornerRow.CornerRadius = UDim.new(0, 8)
                UICornerRow.Parent = RowFrame

                local NameLabel = Instance.new("TextLabel")
                NameLabel.Name = "NameLabel_" .. sanitizedName
                NameLabel.Size = UDim2.new(1, 0, 0, 50)
                NameLabel.Position = UDim2.new(0, 0, 0, 10)
                NameLabel.BackgroundTransparency = 1
                NameLabel.Text = placeInfo.Name
                NameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                NameLabel.TextSize = 18
                NameLabel.Font = Enum.Font.SourceSansBold
                NameLabel.TextScaled = true
                NameLabel.TextWrapped = true
                NameLabel.TextXAlignment = Enum.TextXAlignment.Left
                NameLabel.TextTruncate = Enum.TextTruncate.AtEnd
                NameLabel.Parent = RowFrame

                local InfoFrame = Instance.new("Frame")
                InfoFrame.Name = "InfoFrame_" .. sanitizedName
                InfoFrame.Size = UDim2.new(1, 0, 0, 30)
                InfoFrame.Position = UDim2.new(0, 0, 0, 60)
                InfoFrame.BackgroundTransparency = 1
                InfoFrame.Parent = RowFrame

                local InfoLayout = Instance.new("UIListLayout")
                InfoLayout.Name = "UIListLayout_InfoFrame_" .. sanitizedName
                InfoLayout.FillDirection = Enum.FillDirection.Horizontal
                InfoLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
                InfoLayout.VerticalAlignment = Enum.VerticalAlignment.Center
                InfoLayout.Padding = UDim.new(0, 20)
                InfoLayout.Parent = InfoFrame

                local IDLabel = Instance.new("TextLabel")
                IDLabel.Name = "IDLabel_" .. sanitizedName
                IDLabel.Size = UDim2.new(0, 120, 1, 0)
                IDLabel.BackgroundTransparency = 1
                IDLabel.Text = "ID: " .. placeInfo.PlaceId
                IDLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
                IDLabel.TextSize = 14
                IDLabel.Font = Enum.Font.SourceSans
                IDLabel.TextScaled = true
                IDLabel.TextWrapped = true
                IDLabel.TextXAlignment = Enum.TextXAlignment.Left
                IDLabel.Parent = InfoFrame

                local MaxLabel = Instance.new("TextLabel")
                MaxLabel.Name = "MaxLabel_" .. sanitizedName
                MaxLabel.Size = UDim2.new(0, 150, 1, 0)
                MaxLabel.BackgroundTransparency = 1
                MaxLabel.Text = "Max Players: " .. maxPlayers
                MaxLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
                MaxLabel.TextSize = 14
                MaxLabel.Font = Enum.Font.SourceSans
                MaxLabel.TextScaled = true
                MaxLabel.TextWrapped = true
                MaxLabel.TextXAlignment = Enum.TextXAlignment.Left
                MaxLabel.Parent = InfoFrame

                local ButtonsFrame = Instance.new("Frame")
                ButtonsFrame.Name = "ButtonsFrame_" .. sanitizedName
                ButtonsFrame.Size = UDim2.new(1, 0, 0, 40)
                ButtonsFrame.Position = UDim2.new(0, 0, 0, 100)
                ButtonsFrame.BackgroundTransparency = 1
                ButtonsFrame.Parent = RowFrame

                local ButtonsLayout = Instance.new("UIListLayout")
                ButtonsLayout.Name = "UIListLayout_ButtonsFrame_" .. sanitizedName
                ButtonsLayout.FillDirection = Enum.FillDirection.Horizontal
                ButtonsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
                ButtonsLayout.VerticalAlignment = Enum.VerticalAlignment.Center
                ButtonsLayout.Padding = UDim.new(0, 5)
                ButtonsLayout.Parent = ButtonsFrame

                local JoinButton = Instance.new("TextButton")
                JoinButton.Name = "JoinButton_" .. sanitizedName
                JoinButton.Size = UDim2.new(0, 80, 1, 0)
                JoinButton.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
                JoinButton.TextColor3 = Color3.fromRGB(255, 255, 255)
                JoinButton.TextSize = 12
                JoinButton.Font = Enum.Font.SourceSansBold
                JoinButton.Text = "Join"
                JoinButton.TextScaled = true
                JoinButton.TextWrapped = true
                JoinButton.Parent = ButtonsFrame

                local UICornerJoin = Instance.new("UICorner")
                UICornerJoin.Name = "UICorner_JoinButton_" .. sanitizedName
                UICornerJoin.CornerRadius = UDim.new(0, 6)
                UICornerJoin.Parent = JoinButton

                JoinButton.MouseButton1Click:Connect(function()
                    if not guiVisible then return end
                    S_T:Teleport(placeInfo.PlaceId, Players.LocalPlayer)
                end)

                local FindServersButton = Instance.new("TextButton")
                FindServersButton.Name = "FindServersButton_" .. sanitizedName
                FindServersButton.Size = UDim2.new(0, 90, 1, 0)
                FindServersButton.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
                FindServersButton.TextColor3 = Color3.fromRGB(255, 255, 255)
                FindServersButton.TextSize = 12
                FindServersButton.Font = Enum.Font.SourceSansBold
                FindServersButton.Text = "Find Servers"
                FindServersButton.TextScaled = true
                FindServersButton.TextWrapped = true
                FindServersButton.Parent = ButtonsFrame

                local UICornerFind = Instance.new("UICorner")
                UICornerFind.Name = "UICorner_FindServersButton_" .. sanitizedName
                UICornerFind.CornerRadius = UDim.new(0, 6)
                UICornerFind.Parent = FindServersButton

                FindServersButton.MouseButton1Click:Connect(function()
                    if not guiVisible then return end
                    PlaceIdInput.Text = tostring(placeInfo.PlaceId)
                    local filterCount = tonumber(SearchInput.Text)
                    updateServerList(filterCount)
                    Status.Text = "Switched to servers for " .. placeInfo.Name
                end)

                local CopyButton = Instance.new("TextButton")
                CopyButton.Name = "CopyButton_" .. sanitizedName
                CopyButton.Size = UDim2.new(0, 80, 1, 0)
                CopyButton.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
                CopyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
                CopyButton.TextSize = 12
                CopyButton.Font = Enum.Font.SourceSansBold
                CopyButton.Text = "Copy ID"
                CopyButton.TextScaled = true
                CopyButton.TextWrapped = true
                CopyButton.Parent = ButtonsFrame

                local UICornerCopy = Instance.new("UICorner")
                UICornerCopy.Name = "UICorner_CopyButton_" .. sanitizedName
                UICornerCopy.CornerRadius = UDim.new(0, 6)
                UICornerCopy.Parent = CopyButton

                CopyButton.MouseButton1Click:Connect(function()
                    if not guiVisible then return end
                    pcall(function()
                        setclipboard(tostring(placeInfo.PlaceId))
                        StarterGui:SetCore("SendNotification", {
                            Title = "Copied",
                            Text = "Place ID copied to clipboard!",
                            Duration = 3
                        })
                    end)
                    Status.Text = "Copied Place ID for " .. placeInfo.Name
                end)

                task.spawn(function()
                    getGameInfo(placeInfo.PlaceId, MaxLabel)
                end)

                layoutOrder = layoutOrder + 1
            end
        else
            GamesScrollingFrame.Visible = false
            GameListTitle.Visible = false
            PlaceIdInput.Text = tostring(game.PlaceId)

            HopTitle.Position = UDim2.new(0, 20, 0, 10)
            AdvancedControlsFrame.Position = UDim2.new(0, 10, 0, 50)
            ServersListTitle.Position = UDim2.new(0, 280, 0, 10)
            ScrollingFrame.Position = UDim2.new(0, 280, 0, 50)
            Status.Size = UDim2.new(0, 580, 0, 30)
            Status.Position = UDim2.new(0, 10, 0, 590)
            MainFrame.Size = UDim2.new(0, 610, 0, 630)
            MainFrame.Position = UDim2.new(0.5, -305, 0.5, -315)
        end
    end

    local function updateServerList(filterPlayerCount)
        for _, child in pairs(ScrollingFrame:GetChildren()) do
            if child:IsA("Frame") then
                child:Destroy()
            end
        end

        ScrollingFrame.CanvasPosition = Vector2.new(0, 0)

        local placeId = tonumber(PlaceIdInput.Text) or game.PlaceId
        local gameName = "Unknown Game"
        pcall(function()
            local info = MarketplaceService:GetProductInfo(placeId)
            gameName = info.Name or "Unknown Game"
        end)
        GameNameLabel.Text = "Game: " .. gameName

        local showCurrent = placeId == game.PlaceId
        local layoutOrder = 0

        local currentServerPlaying = "?"
        local currentServerId = game.JobId
        local currentMaxPlayers = "?"

        if showCurrent then
            local servers, err = findServers(placeId)
            if not err then
                for _, server in pairs(servers) do
                    if server.id == game.JobId then
                        currentServerPlaying = server.playing .. "/" .. server.maxPlayers
                        currentMaxPlayers = server.maxPlayers
                        break
                    end
                end
            end

            local HeaderFrame = Instance.new("Frame")
            HeaderFrame.Name = "CurrentServerHeader"
            HeaderFrame.Size = UDim2.new(1, -10, 0, 180)
            HeaderFrame.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
            HeaderFrame.LayoutOrder = layoutOrder
            HeaderFrame.Parent = ScrollingFrame

            local UICornerHeader = Instance.new("UICorner")
            UICornerHeader.Name = "UICorner_CurrentServerHeader"
            UICornerHeader.CornerRadius = UDim.new(0, 8)
            UICornerHeader.Parent = HeaderFrame

            local UIStrokeHeader = Instance.new("UIStroke")
            UIStrokeHeader.Name = "UIStroke_CurrentServerHeader"
            UIStrokeHeader.Color = Color3.fromRGB(0, 90, 160)
            UIStrokeHeader.Thickness = 1
            UIStrokeHeader.Transparency = 0.5
            UIStrokeHeader.Parent = HeaderFrame

            local HeaderLabel = Instance.new("TextLabel")
            HeaderLabel.Name = "HeaderLabel_CurrentServer"
            HeaderLabel.Size = UDim2.new(1, -20, 0, 30)
            HeaderLabel.Position = UDim2.new(0, 10, 0, 5)
            HeaderLabel.BackgroundTransparency = 1
            HeaderLabel.Text = "You're currently in this server"
            HeaderLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            HeaderLabel.TextSize = 28
            HeaderLabel.Font = Enum.Font.SourceSansBold
            HeaderLabel.TextXAlignment = Enum.TextXAlignment.Center
            HeaderLabel.TextYAlignment = Enum.TextYAlignment.Center
            HeaderLabel.Parent = HeaderFrame

            local ServerFrame = Instance.new("Frame")
            ServerFrame.Name = "CurrentServerFrame"
            ServerFrame.Size = UDim2.new(1, -20, 0, 140)
            ServerFrame.Position = UDim2.new(0, 10, 0, 35)
            ServerFrame.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
            ServerFrame.Parent = HeaderFrame

            local UICornerServer = Instance.new("UICorner")
            UICornerServer.Name = "UICorner_CurrentServerFrame"
            UICornerServer.CornerRadius = UDim.new(0, 8)
            UICornerServer.Parent = ServerFrame

            local UIStrokeServer = Instance.new("UIStroke")
            UIStrokeServer.Name = "UIStroke_CurrentServerFrame"
            UIStrokeServer.Color = Color3.fromRGB(60, 60, 60)
            UIStrokeServer.Thickness = 1
            UIStrokeServer.Transparency = 0.3
            UIStrokeServer.Parent = ServerFrame

            local PlayersLabel = Instance.new("TextLabel")
            PlayersLabel.Name = "PlayersLabel_CurrentServer"
            PlayersLabel.Size = UDim2.new(1, 0, 0, 30)
            PlayersLabel.Position = UDim2.new(0, 0, 0, 10)
            PlayersLabel.BackgroundTransparency = 1
            PlayersLabel.Text = currentServerPlaying .. " players"
            PlayersLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            PlayersLabel.TextSize = 18
            PlayersLabel.Font = Enum.Font.SourceSansBold
            PlayersLabel.TextScaled = true
            PlayersLabel.TextWrapped = true
            PlayersLabel.TextXAlignment = Enum.TextXAlignment.Left
            PlayersLabel.Parent = ServerFrame

            local IdLabel = Instance.new("TextLabel")
            IdLabel.Name = "IdLabel_CurrentServer"
            IdLabel.Size = UDim2.new(1, 0, 0, 60)
            IdLabel.Position = UDim2.new(0, 0, 0, 40)
            IdLabel.BackgroundTransparency = 1
            IdLabel.Text = "Server ID: " .. currentServerId
            IdLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
            IdLabel.TextSize = 16
            IdLabel.Font = Enum.Font.SourceSans
            IdLabel.TextScaled = true
            IdLabel.TextWrapped = true
            IdLabel.TextXAlignment = Enum.TextXAlignment.Left
            IdLabel.Parent = ServerFrame

            local ButtonsFrame = Instance.new("Frame")
            ButtonsFrame.Name = "ButtonsFrame_CurrentServer"
            ButtonsFrame.Size = UDim2.new(1, 0, 0, 35)
            ButtonsFrame.Position = UDim2.new(0, 0, 0, 100)
            ButtonsFrame.BackgroundTransparency = 1
            ButtonsFrame.Parent = ServerFrame

            local ButtonsLayout = Instance.new("UIListLayout")
            ButtonsLayout.Name = "UIListLayout_ButtonsFrame_CurrentServer"
            ButtonsLayout.FillDirection = Enum.FillDirection.Horizontal
            ButtonsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
            ButtonsLayout.VerticalAlignment = Enum.VerticalAlignment.Center
            ButtonsLayout.Padding = UDim.new(0, 5)
            ButtonsLayout.Parent = ButtonsFrame

            local RejoinButton = Instance.new("TextButton")
            RejoinButton.Name = "RejoinButton_CurrentServer"
            RejoinButton.Size = UDim2.new(0, 140, 1, 0)
            RejoinButton.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
            RejoinButton.TextColor3 = Color3.fromRGB(255, 255, 255)
            RejoinButton.TextSize = 14
            RejoinButton.Font = Enum.Font.SourceSansBold
            RejoinButton.Text = "Rejoin"
            RejoinButton.TextScaled = true
            RejoinButton.TextWrapped = true
            RejoinButton.Parent = ButtonsFrame

            local UICornerRejoin = Instance.new("UICorner")
            UICornerRejoin.Name = "UICorner_RejoinButton_CurrentServer"
            UICornerRejoin.CornerRadius = UDim.new(0, 6)
            UICornerRejoin.Parent = RejoinButton

            RejoinButton.MouseButton1Click:Connect(function()
                if not guiVisible then return end
                Status.Text = "Rejoining current server..."
                local success, err = pcall(function()
                    S_T:TeleportToPlaceInstance(placeId, game.JobId, Players.LocalPlayer)
                end)
                if not success then
                    Status.Text = "Rejoin failed: " .. tostring(err)
                end
            end)

            local CopyButton = Instance.new("TextButton")
            CopyButton.Name = "CopyButton_CurrentServer"
            CopyButton.Size = UDim2.new(0, 140, 1, 0)
            CopyButton.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
            CopyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
            CopyButton.TextSize = 14
            CopyButton.Font = Enum.Font.SourceSansBold
            CopyButton.Text = "Copy Server Link"
            CopyButton.TextScaled = true
            CopyButton.TextWrapped = true
            CopyButton.Parent = ButtonsFrame

            local UICornerCopy = Instance.new("UICorner")
            UICornerCopy.Name = "UICorner_CopyButton_CurrentServer"
            UICornerCopy.CornerRadius = UDim.new(0, 6)
            UICornerCopy.Parent = CopyButton

            CopyButton.MouseButton1Click:Connect(function()
                if not guiVisible then return end
                local serverLink = "https://www.roblox.com/games/start?placeId=" .. placeId .. "&jobId=" .. game.JobId
                pcall(function()
                    setclipboard(serverLink)
                    StarterGui:SetCore("SendNotification", {
                        Title = "Server Link Copied",
                        Text = "Current server link copied to clipboard!",
                        Duration = 3
                    })
                end)
                Status.Text = "Current server link copied!"
            end)

            layoutOrder = 1
        end

        local servers, err = findServers(placeId)
        if err then
            Status.Text = err
            return
        end
        serverList = servers

        local filteredServers = {}
        if filterPlayerCount and filterPlayerCount >= 0 then
            for _, server in pairs(serverList) do
                if showCurrent and server.id == game.JobId then
                else
                    if server.playing == filterPlayerCount then
                        table.insert(filteredServers, server)
                    end
                end
            end
        else
            for _, server in pairs(serverList) do
                if showCurrent and server.id == game.JobId then
                else
                    table.insert(filteredServers, server)
                end
            end
        end

        if showNonMaxServers then
            local nonFullServers = {}
            for _, server in pairs(filteredServers) do
                if server.playing < server.maxPlayers then
                    table.insert(nonFullServers, server)
                end
            end
            filteredServers = nonFullServers
        end

        table.sort(filteredServers, function(a, b)
            if sortOption == "Low to High" then
                return a.playing < b.playing
            else
                return a.playing > b.playing
            end
        end)

        for i, server in pairs(filteredServers) do
            local ServerFrame = Instance.new("Frame")
            ServerFrame.Name = "ServerFrame_" .. i
            ServerFrame.Size = UDim2.new(1, -10, 0, 140)
            ServerFrame.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
            ServerFrame.BorderSizePixel = 0
            ServerFrame.LayoutOrder = layoutOrder + i - 1
            ServerFrame.Parent = ScrollingFrame

            local UICornerServer = Instance.new("UICorner")
            UICornerServer.Name = "UICorner_ServerFrame_" .. i
            UICornerServer.CornerRadius = UDim.new(0, 8)
            UICornerServer.Parent = ServerFrame

            local PlayersLabel = Instance.new("TextLabel")
            PlayersLabel.Name = "PlayersLabel_Server_" .. i
            PlayersLabel.Size = UDim2.new(1, 0, 0, 30)
            PlayersLabel.Position = UDim2.new(0, 0, 0, 10)
            PlayersLabel.BackgroundTransparency = 1
            PlayersLabel.Text = server.playing .. "/" .. server.maxPlayers .. " players"
            PlayersLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            PlayersLabel.TextSize = 18
            PlayersLabel.Font = Enum.Font.SourceSansBold
            PlayersLabel.TextScaled = true
            PlayersLabel.TextWrapped = true
            PlayersLabel.Parent = ServerFrame

            local IdLabel = Instance.new("TextLabel")
            IdLabel.Name = "IdLabel_Server_" .. i
            IdLabel.Size = UDim2.new(1, 0, 0, 60)
            IdLabel.Position = UDim2.new(0, 0, 0, 40)
            IdLabel.BackgroundTransparency = 1
            IdLabel.Text = "Server ID: " .. server.id
            IdLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
            IdLabel.TextSize = 16
            IdLabel.Font = Enum.Font.SourceSans
            IdLabel.TextScaled = true
            IdLabel.TextWrapped = true
            IdLabel.Parent = ServerFrame

            local JoinButton = Instance.new("TextButton")
            JoinButton.Name = "JoinButton_Server_" .. i
            JoinButton.Size = UDim2.new(0.65, -5, 0, 35)
            JoinButton.Position = UDim2.new(0, 5, 0, 100)
            JoinButton.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
            JoinButton.TextColor3 = Color3.fromRGB(255, 255, 255)
            JoinButton.TextSize = 16
            JoinButton.Font = Enum.Font.SourceSansBold
            JoinButton.Text = "Join"
            JoinButton.TextScaled = true
            JoinButton.TextWrapped = true
            JoinButton.Parent = ServerFrame

            local UICornerJoinButton = Instance.new("UICorner")
            UICornerJoinButton.Name = "UICorner_JoinButton_Server_" .. i
            UICornerJoinButton.CornerRadius = UDim.new(0, 8)
            UICornerJoinButton.Parent = JoinButton

            local CopyButton = Instance.new("TextButton")
            CopyButton.Name = "CopyButton_Server_" .. i
            CopyButton.Size = UDim2.new(0.3, -10, 0, 35)
            CopyButton.Position = UDim2.new(0.7, 0, 0, 100)
            CopyButton.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
            CopyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
            CopyButton.TextSize = 16
            CopyButton.Font = Enum.Font.SourceSans
            CopyButton.Text = "Copy Link"
            CopyButton.TextScaled = true
            CopyButton.TextWrapped = true
            CopyButton.Parent = ServerFrame

            local UICornerCopyButton = Instance.new("UICorner")
            UICornerCopyButton.Name = "UICorner_CopyButton_Server_" .. i
            UICornerCopyButton.CornerRadius = UDim.new(0, 8)
            UICornerCopyButton.Parent = CopyButton

            local placeId = tonumber(PlaceIdInput.Text) or game.PlaceId
            JoinButton.MouseButton1Click:Connect(function()
                if not guiVisible then return end
                Status.Text = "Joining server with " .. server.playing .. " players..."
                local success, err = pcall(function()
                    table.insert(AllIDs, server.id)
                    writefile("server-hop-temp.json", S_H:JSONEncode(AllIDs))
                    S_T:TeleportToPlaceInstance(placeId, server.id, Players.LocalPlayer)
                end)
                if not success then
                    if placeId ~= game.PlaceId then
                        Status.Text = "Please disable verify teleport"
                    else
                        Status.Text = "Teleport failed: " .. tostring(err)
                    end
                end
            end)

            CopyButton.MouseButton1Click:Connect(function()
                if not guiVisible then return end
                local serverLink = "https://www.roblox.com/games/start?placeId=" .. placeId .. "&jobId=" .. server.id
                pcall(function()
                    setclipboard(serverLink)
                    StarterGui:SetCore("SendNotification", {
                        Title = "Server Link Copied",
                        Text = "Copied server link to clipboard!",
                        Duration = 3
                    })
                end)
                Status.Text = "Server link copied!"
            end)
        end

        local serverCountText = showCurrent and #filteredServers + 1 or #filteredServers
        Status.Text = "Found " .. serverCountText .. " servers for Place ID: " .. placeId
    end

    local function restrictInput(textbox, maxLength, numbersOnly)
        textbox:GetPropertyChangedSignal("Text"):Connect(function()
            local text = textbox.Text
            if numbersOnly then
                text = text:gsub("%D", "")
            end
            if #text > maxLength then
                text = text:sub(1, maxLength)
            end
            if text ~= textbox.Text then
                textbox.Text = text
                textbox.CursorPosition = #text + 1
            end
        end)
    end

    restrictInput(PlaceIdInput, 20, true)
    restrictInput(PlayerCountInput, 3, true)
    restrictInput(ServerIdInput, 200, false)
    restrictInput(SearchInput, 3, true)

    CloseButton.MouseButton1Click:Connect(function()
        local function deleteServerHopGUI()
            local CoreGui = game:GetService("CoreGui")
            local serverHopGUI = CoreGui:WaitForChild("ServerHopGUI")

            if serverHopGUI then
                serverHopGUI:Destroy()
            end
        end

        deleteServerHopGUI()
    end)

    SortDropdown.MouseButton1Click:Connect(function()
        if not guiVisible then return end
        sortOption = sortOption == "Low to High" and "High to Low" or "Low to High"
        SortDropdown.Text = "Sort: " .. sortOption
        updateServerList(tonumber(SearchInput.Text))
    end)

    Checkbox.MouseButton1Click:Connect(function()
        if not guiVisible then return end
        showNonMaxServers = not showNonMaxServers
        Checkbox.Text = showNonMaxServers and "✓" or ""
        updateServerList(tonumber(SearchInput.Text))
    end)

    HopButton.MouseButton1Click:Connect(function()
        if not guiVisible then return end
        local playerCount = tonumber(PlayerCountInput.Text)
        local placeId = tonumber(PlaceIdInput.Text) or game.PlaceId
        if not playerCount or playerCount < 0 or PlayerCountInput.Text == "" then
            -- Use game TP method if player count is blank or invalid
            Status.Text = "Teleporting to Place ID: " .. placeId .. " (random server)..."
            local success, err = pcall(function()
                S_T:Teleport(placeId, Players.LocalPlayer)
            end)
            if not success then
                if placeId ~= game.PlaceId then
                    Status.Text = "Please disable verify teleport"
                else
                    Status.Text = "Teleport failed: " .. tostring(err)
                end
            end
        else
            Status.Text = "Searching for server with " .. playerCount .. " players in Place ID: " .. placeId .. "..."
            local startTime = os.time()
            local success, err
            repeat
                success, err = TPReturner(placeId, playerCount)
                if not success then
                    wait(1)
                    foundAnything = ""
                end
            until success or (os.time() - startTime >= 120)
            if not success then
                -- If no server found after timeout, fallback to game TP method
                Status.Text = "No server found with " .. playerCount .. " players. Teleporting to random server..."
                local fallbackSuccess, fallbackErr = pcall(function()
                    S_T:Teleport(placeId, Players.LocalPlayer)
                end)
                if not fallbackSuccess then
                    if placeId ~= game.PlaceId then
                        Status.Text = "Please disable verify teleport"
                    else
                        Status.Text = fallbackErr or "Teleport failed: " .. tostring(fallbackErr)
                    end
                end
            end
        end
    end)

    JoinServerButton.MouseButton1Click:Connect(function()
        if not guiVisible then return end
        local serverInput = ServerIdInput.Text:match("^%s*(.-)%s*$")
        if serverInput == "" then
            Status.Text = "Please enter a valid server ID or link"
            return
        end
        local extractedId
        local finalPlaceId = tonumber(PlaceIdInput.Text) or game.PlaceId
        if serverInput:find("://") then
            extractedId = serverInput:match("jobId=([^&]+)")
            if not extractedId then
                Status.Text = "Invalid server link. Could not extract jobId."
                return
            end
            local linkPlaceId = serverInput:match("placeId=([^&]+)")
            if linkPlaceId then
                finalPlaceId = tonumber(linkPlaceId) or finalPlaceId
            end
        else
            extractedId = serverInput
        end
        Status.Text = "Attempting to join server ID: " .. extractedId .. "..."
        local success, err = joinServerById(finalPlaceId, extractedId)
        if not success then
            if finalPlaceId ~= game.PlaceId then
                Status.Text = "Please disable verify teleport"
            else
                Status.Text = err or "Failed to join server ID: " .. extractedId
            end
        end
    end)

    RefreshButton.MouseButton1Click:Connect(function()
        if not guiVisible then return end
        Status.Text = "Refreshing server list..."
        updateServerList(tonumber(SearchInput.Text))
    end)

    SearchInput:GetPropertyChangedSignal("Text"):Connect(function()
        if not guiVisible then return end
        local filterCount = tonumber(SearchInput.Text)
        updateServerList(filterCount)
    end)

    PlaceIdInput:GetPropertyChangedSignal("Text"):Connect(function()
        if not guiVisible then return end
        local filterCount = tonumber(SearchInput.Text)
        updateServerList(filterCount)
    end)

    fetchGames()

    updateServerList()
end

createGUI()

local module = {}
function module:Teleport(placeId, playerCount)
    local startTime = os.time()
    local success, err
    repeat
        success, err = TPReturner(placeId, playerCount)
        if not success then
            wait(1)
            foundAnything = ""
        end
    until success or (os.time() - startTime >= 120)
    if not success then
        -- Fallback to game TP if no server found
        local fallbackSuccess, fallbackErr = pcall(function()
            S_T:Teleport(placeId, Players.LocalPlayer)
        end)
        if fallbackSuccess then
            return true, nil
        else
            return false, fallbackErr
        end
    end
    return success, err
end
function module:GetServers(placeId)
    local servers, err = findServers(placeId)
    return servers, err
end
function module:JoinServerById(placeId, serverId)
    return joinServerById(placeId, serverId)
end
