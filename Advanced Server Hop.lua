-- Services
local S_T = game:GetService("TeleportService")
local S_H = game:GetService("HttpService")
local Players = game:GetService("Players")
local GuiService = game:GetService("GuiService")
local StarterGui = game:GetService("StarterGui")

-- Variables
local AllIDs = {}
local foundAnything = ""
local actualHour = os.date("!*t").hour
local Deleted = false
local serverList = {}
local guiVisible = true
local sortOption = "Low to High" -- Default sort option
local showNonMaxServers = false -- Default checkbox state

-- File handling for server IDs
local File = pcall(function()
    AllIDs = S_H:JSONDecode(readfile("server-hop-temp.json"))
end)
if not File then
    table.insert(AllIDs, actualHour)
    pcall(function()
        writefile("server-hop-temp.json", S_H:JSONEncode(AllIDs))
    end)
end

-- Server finder function
local function findServers(placeId)
    local servers = {}
    local cursor = ""
    local maxRetries = 3
    local retryDelay = 1

    -- Validate Place ID
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
            wait(retryDelay * attempt) -- Exponential backoff
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
        wait(0.5) -- Rate limit
    until cursor == "" or cursor == "null" or cursor == nil
    return servers, nil
end

-- Server hopping function
local function TPReturner(placeId, desiredPlayerCount)
    -- Validate inputs
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
        wait(retryDelay * attempt) -- Exponential backoff
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

-- Function to join specific server by ID
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

-- GUI Creation
local function createGUI()
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "ServerHopGUI"
    ScreenGui.Parent = game:GetService("CoreGui")
    ScreenGui.ResetOnSpawn = false
    ScreenGui.DisplayOrder = 999999999

    -- Add UIScale for DPI scaling
    local UIScale = Instance.new("UIScale")
    UIScale.Parent = ScreenGui
    local screenSize = GuiService:GetScreenResolution()
    if screenSize then
        local baseResolution = 1920
        UIScale.Scale = math.min(1.5, screenSize.X / baseResolution)
    end

    -- Single Main Frame
    local MainFrame = Instance.new("Frame")
    MainFrame.Size = UDim2.new(0, 650, 0, 600) -- Increased height to 600
    MainFrame.Position = UDim2.new(0.5, -325, 0.5, -300) -- Adjusted to center vertically
    MainFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    MainFrame.BorderSizePixel = 0
    MainFrame.Parent = ScreenGui

    local UICornerMain = Instance.new("UICorner")
    UICornerMain.CornerRadius = UDim.new(0, 12)
    UICornerMain.Parent = MainFrame

    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(0, 300, 0, 40)
    Title.Position = UDim2.new(0, 20, 0, 10)
    Title.BackgroundTransparency = 1
    Title.Text = "Server Hop"
    Title.Name = "ServerHop"
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.TextSize = 24
    Title.Font = Enum.Font.SourceSansBold
    Title.TextScaled = true
    Title.TextWrapped = true
    Title.Parent = MainFrame

    local CloseButton = Instance.new("TextButton")
    CloseButton.Size = UDim2.new(0, 40, 0, 40)
    CloseButton.Position = UDim2.new(1, -50, 0, 10)
    CloseButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    CloseButton.TextSize = 20
    CloseButton.Font = Enum.Font.SourceSansBold
    CloseButton.Text = "X"
    CloseButton.Name = "CloseButton"
    CloseButton.TextScaled = true
    CloseButton.TextWrapped = true
    CloseButton.Parent = MainFrame

    local UICornerCloseButton = Instance.new("UICorner")
    UICornerCloseButton.CornerRadius = UDim.new(0, 8)
    UICornerCloseButton.Parent = CloseButton

    -- Left Side: Inputs and Buttons
    -- Sort Dropdown
    local SortDropdown = Instance.new("TextButton")
    SortDropdown.Size = UDim2.new(0, 250, 0, 40)
    SortDropdown.Position = UDim2.new(0, 20, 0, 60)
    SortDropdown.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    SortDropdown.TextColor3 = Color3.fromRGB(255, 255, 255)
    SortDropdown.TextSize = 18
    SortDropdown.Name = "ServerSortButton"
    SortDropdown.Font = Enum.Font.SourceSans
    SortDropdown.Text = "Sort: " .. sortOption
    SortDropdown.TextScaled = true
    SortDropdown.TextWrapped = true
    SortDropdown.Parent = MainFrame

    local UICornerSortDropdown = Instance.new("UICorner")
    UICornerSortDropdown.CornerRadius = UDim.new(0, 8)
    UICornerSortDropdown.Parent = SortDropdown

    -- Checkbox
    local CheckboxFrame = Instance.new("Frame")
    CheckboxFrame.Size = UDim2.new(0, 250, 0, 40)
    CheckboxFrame.Position = UDim2.new(0, 20, 0, 110) -- Below SortDropdown
    CheckboxFrame.BackgroundTransparency = 1
    CheckboxFrame.Parent = MainFrame
    CheckboxFrame.Name = "CheckboxFrame"

    local Checkbox = Instance.new("TextButton")
    Checkbox.Size = UDim2.new(0, 30, 0, 30)
    Checkbox.Position = UDim2.new(0, 0, 0, 5)
    Checkbox.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    Checkbox.TextColor3 = Color3.fromRGB(255, 255, 255)
    Checkbox.TextSize = 18
    Checkbox.Font = Enum.Font.SourceSansBold
    Checkbox.Text = showNonMaxServers and "âœ“" or ""
    Checkbox.TextScaled = true
    Checkbox.TextWrapped = true
    Checkbox.Parent = CheckboxFrame
    Checkbox.Name = "CheckBox"

    local UICornerCheckbox = Instance.new("UICorner")
    UICornerCheckbox.CornerRadius = UDim.new(0, 8)
    UICornerCheckbox.Parent = Checkbox

    local CheckboxLabel = Instance.new("TextLabel")
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
    CheckboxLabel.Name = "CheckBoxLable"

    -- PlaceIdInput
    local PlaceIdInput = Instance.new("TextBox")
    PlaceIdInput.Size = UDim2.new(0, 250, 0, 40)
    PlaceIdInput.Position = UDim2.new(0, 20, 0, 160) -- 110 + 40 + 10
    PlaceIdInput.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    PlaceIdInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    PlaceIdInput.TextSize = 18
    PlaceIdInput.Font = Enum.Font.SourceSans
    PlaceIdInput.PlaceholderText = "Enter Place ID"
    PlaceIdInput.Text = ""
    PlaceIdInput.ClipsDescendants = true
    PlaceIdInput.TextScaled = true
    PlaceIdInput.TextWrapped = true
    PlaceIdInput.Parent = MainFrame
    PlaceIdInput.Name = "PlaceIDInput"

    local UICornerPlaceIdInput = Instance.new("UICorner")
    UICornerPlaceIdInput.CornerRadius = UDim.new(0, 8)
    UICornerPlaceIdInput.Parent = PlaceIdInput

    -- PlayerCountInput
    local PlayerCountInput = Instance.new("TextBox")
    PlayerCountInput.Size = UDim2.new(0, 250, 0, 40)
    PlayerCountInput.Position = UDim2.new(0, 20, 0, 210) -- 160 + 40 + 10
    PlayerCountInput.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    PlayerCountInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    PlayerCountInput.TextSize = 18
    PlayerCountInput.Font = Enum.Font.SourceSans
    PlayerCountInput.PlaceholderText = "Enter player count to hop"
    PlayerCountInput.Text = ""
    PlayerCountInput.ClipsDescendants = true
    PlayerCountInput.TextScaled = true
    PlayerCountInput.TextWrapped = true
    PlayerCountInput.Parent = MainFrame
    PlayerCountInput.Name = "PlayerCountInput"

    local UICornerPlayerCountInput = Instance.new("UICorner")
    UICornerPlayerCountInput.CornerRadius = UDim.new(0, 8)
    UICornerPlayerCountInput.Parent = PlayerCountInput

    -- ServerIdInput
    local ServerIdInput = Instance.new("TextBox")
    ServerIdInput.Size = UDim2.new(0, 250, 0, 40)
    ServerIdInput.Position = UDim2.new(0, 20, 0, 260) -- 210 + 40 + 10
    ServerIdInput.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    ServerIdInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    ServerIdInput.TextSize = 18
    ServerIdInput.Font = Enum.Font.SourceSans
    ServerIdInput.PlaceholderText = "Enter Server ID or Link"
    ServerIdInput.Text = ""
    ServerIdInput.ClipsDescendants = true
    ServerIdInput.TextScaled = true
    ServerIdInput.TextWrapped = true
    ServerIdInput.Parent = MainFrame
    ServerIdInput.Name = "ServerIDInput"

    local UICornerServerIdInput = Instance.new("UICorner")
    UICornerServerIdInput.CornerRadius = UDim.new(0, 8)
    UICornerServerIdInput.Parent = ServerIdInput

    -- SearchInput
    local SearchInput = Instance.new("TextBox")
    SearchInput.Size = UDim2.new(0, 250, 0, 40)
    SearchInput.Position = UDim2.new(0, 20, 0, 310) -- 260 + 40 + 10
    SearchInput.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    SearchInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    SearchInput.TextSize = 18
    SearchInput.Font = Enum.Font.SourceSans
    SearchInput.PlaceholderText = "Search by player count"
    SearchInput.Text = ""
    SearchInput.ClipsDescendants = true
    SearchInput.TextScaled = true
    SearchInput.TextWrapped = true
    SearchInput.Parent = MainFrame
    SearchInput.Name = "SearchInput"

    local UICornerSearchInput = Instance.new("UICorner")
    UICornerSearchInput.CornerRadius = UDim.new(0, 8)
    UICornerSearchInput.Parent = SearchInput

    -- HopButton
    local HopButton = Instance.new("TextButton")
    HopButton.Size = UDim2.new(0, 120, 0, 40)
    HopButton.Position = UDim2.new(0, 20, 0, 360) -- 310 + 40 + 10
    HopButton.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
    HopButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    HopButton.TextSize = 18
    HopButton.Font = Enum.Font.SourceSansBold
    HopButton.Text = "Hop"
    HopButton.TextScaled = true
    HopButton.TextWrapped = true
    HopButton.Parent = MainFrame
    HopButton.Name = "HopButton"

    local UICornerHopButton = Instance.new("UICorner")
    UICornerHopButton.CornerRadius = UDim.new(0, 8)
    UICornerHopButton.Parent = HopButton

    -- JoinServerButton
    local JoinServerButton = Instance.new("TextButton")
    JoinServerButton.Size = UDim2.new(0, 120, 0, 40)
    JoinServerButton.Position = UDim2.new(0, 150, 0, 360) -- Same y as HopButton
    JoinServerButton.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
    JoinServerButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    JoinServerButton.TextSize = 18
    JoinServerButton.Font = Enum.Font.SourceSansBold
    JoinServerButton.Text = "Join Server"
    JoinServerButton.TextScaled = true
    JoinServerButton.TextWrapped = true
    JoinServerButton.Parent = MainFrame
    JoinServerButton.Name = "JoinServerButton"

    local UICornerJoinServerButton = Instance.new("UICorner")
    UICornerJoinServerButton.CornerRadius = UDim.new(0, 8)
    UICornerJoinServerButton.Parent = JoinServerButton

    -- RefreshButton
    local RefreshButton = Instance.new("TextButton")
    RefreshButton.Size = UDim2.new(0, 120, 0, 40)
    RefreshButton.Position = UDim2.new(0, 20, 0, 410) -- 360 + 40 + 10
    RefreshButton.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
    RefreshButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    RefreshButton.TextSize = 18
    RefreshButton.Font = Enum.Font.SourceSansBold
    RefreshButton.Text = "Refresh"
    RefreshButton.TextScaled = true
    RefreshButton.TextWrapped = true
    RefreshButton.Parent = MainFrame
    RefreshButton.Name = "RefreshButton"

    local UICornerRefreshButton = Instance.new("UICorner")
    UICornerRefreshButton.CornerRadius = UDim.new(0, 8)
    UICornerRefreshButton.Parent = RefreshButton

    -- Status Label
    local Status = Instance.new("TextLabel")
    Status.Size = UDim2.new(0, 615, 0, 30)
    Status.Position = UDim2.new(0, 20, 0,527) -- 410 + 40 + 10
    Status.BackgroundTransparency = 1
    Status.Text = ""
    Status.TextColor3 = Color3.fromRGB(255, 255, 255)
    Status.TextSize = 16
    Status.Font = Enum.Font.SourceSans
    Status.TextScaled = true
    Status.TextWrapped = true
    Status.Parent = MainFrame
    Status.Name = "Status"

    -- Right Side: Server List
    local ServerListTitle = Instance.new("TextLabel")
    ServerListTitle.Size = UDim2.new(0, 350, 0, 40)
    ServerListTitle.Position = UDim2.new(0, 280, 0, 10)
    ServerListTitle.BackgroundTransparency = 1
    ServerListTitle.Text = "Server List"
    ServerListTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    ServerListTitle.TextSize = 24
    ServerListTitle.Font = Enum.Font.SourceSansBold
    ServerListTitle.TextScaled = true
    ServerListTitle.TextWrapped = true
    ServerListTitle.Parent = MainFrame
    ServerListTitle.Name = "ServerListTitel"

    local ScrollingFrame = Instance.new("ScrollingFrame")
    ScrollingFrame.Size = UDim2.new(0, 350, 0, 450) -- Increased height to match left side
    ScrollingFrame.Position = UDim2.new(0, 280, 0, 60)
    ScrollingFrame.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    ScrollingFrame.BorderSizePixel = 0
    ScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    ScrollingFrame.ScrollBarThickness = 10
    ScrollingFrame.ClipsDescendants = true
    ScrollingFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    ScrollingFrame.ScrollingDirection = Enum.ScrollingDirection.Y
    ScrollingFrame.Parent = MainFrame

    local UICornerScroll = Instance.new("UICorner")
    UICornerScroll.CornerRadius = UDim.new(0, 8)
    UICornerScroll.Parent = ScrollingFrame

    local UIListLayout = Instance.new("UIListLayout")
    UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    UIListLayout.Padding = UDim.new(0, 8)
    UIListLayout.Parent = ScrollingFrame

    -- Function to update server list UI
    local function updateServerList(filterPlayerCount)
        -- Clear existing server frames
        for _, child in pairs(ScrollingFrame:GetChildren()) do
            if child:IsA("Frame") then
                child:Destroy()
            end
        end

        -- Reset scroll position to top
        ScrollingFrame.CanvasPosition = Vector2.new(0, 0)

        -- Fetch servers
        local placeId = tonumber(PlaceIdInput.Text) or game.PlaceId
        local servers, err = findServers(placeId)
        if err then
            Status.Text = err
            return
        end
        serverList = servers

        -- Filter servers by player count if specified
        local filteredServers = serverList
        if filterPlayerCount and filterPlayerCount >= 0 then
            filteredServers = {}
            for _, server in pairs(serverList) do
                if server.playing == filterPlayerCount then
                    table.insert(filteredServers, server)
                end
            end
        end

        -- Filter out full servers if checkbox is checked
        if showNonMaxServers then
            local nonFullServers = {}
            for _, server in pairs(filteredServers) do
                if server.playing < server.maxPlayers then
                    table.insert(nonFullServers, server)
                end
            end
            filteredServers = nonFullServers
        end

        -- Sort servers based on dropdown selection
        table.sort(filteredServers, function(a, b)
            if sortOption == "Low to High" then
                return a.playing < b.playing
            else
                return a.playing > b.playing
            end
        end)

        -- Create UI for each server
        for i, server in pairs(filteredServers) do
            local ServerFrame = Instance.new("Frame")
            ServerFrame.Size = UDim2.new(1, -10, 0, 140)
            ServerFrame.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
            ServerFrame.BorderSizePixel = 0
            ServerFrame.LayoutOrder = i
            ServerFrame.Parent = ScrollingFrame

            local UICornerServer = Instance.new("UICorner")
            UICornerServer.CornerRadius = UDim.new(0, 8)
            UICornerServer.Parent = ServerFrame

            local PlayersLabel = Instance.new("TextLabel")
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
            UICornerJoinButton.CornerRadius = UDim.new(0, 8)
            UICornerJoinButton.Parent = JoinButton

            local CopyButton = Instance.new("TextButton")
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
            UICornerCopyButton.CornerRadius = UDim.new(0, 8)
            UICornerCopyButton.Parent = CopyButton

            JoinButton.MouseButton1Click:Connect(function()
                if not guiVisible then return end
                Status.Text = "Joining server with " .. server.playing .. " players..."
                local success, err = pcall(function()
                    table.insert(AllIDs, server.id)
                    writefile("server-hop-temp.json", S_H:JSONEncode(AllIDs))
                    S_T:TeleportToPlaceInstance(placeId, server.id, Players.LocalPlayer)
                end)
                if not success then
                    Status.Text = "Teleport failed: " .. tostring(err)
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

        Status.Text = "Found " .. #filteredServers .. " servers for Place ID: " .. placeId
    end

    -- Input validation for textboxes
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

    -- Apply input restrictions
    restrictInput(PlaceIdInput, 20, true)
    restrictInput(PlayerCountInput, 3, true)
    restrictInput(ServerIdInput, 200, false)
    restrictInput(SearchInput, 3, true)

    -- Close button functionality
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

    -- Dropdown functionality
    SortDropdown.MouseButton1Click:Connect(function()
        if not guiVisible then return end
        sortOption = sortOption == "Low to High" and "High to Low" or "Low to High"
        SortDropdown.Text = "Sort: " .. sortOption
        updateServerList(tonumber(SearchInput.Text))
    end)

    -- Checkbox functionality
    Checkbox.MouseButton1Click:Connect(function()
        if not guiVisible then return end
        showNonMaxServers = not showNonMaxServers
        Checkbox.Text = showNonMaxServers and "âœ“" or ""
        updateServerList(tonumber(SearchInput.Text))
    end)

    -- Button functionality
    HopButton.MouseButton1Click:Connect(function()
        if not guiVisible then return end
        local playerCount = tonumber(PlayerCountInput.Text)
        local placeId = tonumber(PlaceIdInput.Text) or game.PlaceId
        if playerCount and playerCount >= 0 then
            Status.Text = "Searching for server with " .. playerCount .. " players in Place ID: " .. placeId .. "..."
            local success, err
            local attempts = 0
            local maxAttempts = 5
            while not success and attempts < maxAttempts do
                success, err = TPReturner(placeId, playerCount)
                if not success then
                    wait(1)
                    foundAnything = ""
                end
                attempts = attempts + 1
            end
            if not success then
                Status.Text = err or "No server found with " .. playerCount .. " players in Place ID: " .. placeId
            end
        else
            Status.Text = "Please enter a valid player count"
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
            Status.Text = err or "Failed to join server ID: " .. extractedId
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

    -- Initial server list population
    updateServerList()
end

-- Initialize GUI
createGUI()

-- Module for external use
local module = {}
function module:Teleport(placeId, playerCount)
    local success, err
    local attempts = 0
    local maxAttempts = 5
    while not success and attempts < maxAttempts do
        success, err = TPReturner(placeId, playerCount)
        if not success then
            wait(1)
            foundAnything = ""
        end
        attempts = attempts + 1
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

return module
