if script:GetAttribute("FPSCounterExecuted") then
    return
end
script:SetAttribute("FPSCounterExecuted", true)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")
local Stats = game:GetService("Stats")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

if playerGui:FindFirstChild("FPSCounter") then
    return
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "FPSCounter"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

screenGui.ScreenInsets = Enum.ScreenInsets.TopbarSafeInsets

local container = Instance.new("Frame")
container.Size = UDim2.new(0, 150, 0, 70)
container.BackgroundTransparency = 1
container.Parent = screenGui

container.AnchorPoint = Vector2.new(1, 0)
container.Position = UDim2.new(1, -12, 0, 12)

local contentFrame = Instance.new("Frame")
contentFrame.Size = UDim2.new(1, 0, 1, 0)
contentFrame.BackgroundTransparency = 1
contentFrame.Parent = container

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 3)
listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
listLayout.Parent = contentFrame

local function formatMemorySize(bytes)
    local sizes = {"B", "KB", "MB", "GB", "TB", "PB"}
    local i = 1
    while bytes >= 1024 and i < #sizes do
        bytes = bytes / 1024
        i = i + 1
    end
    return string.format("%.1f %s", bytes, sizes[i])
end

local function createStatRow()
    local rowFrame = Instance.new("Frame")
    rowFrame.Size = UDim2.new(1, 0, 0, 18)
    rowFrame.BackgroundTransparency = 1
    rowFrame.LayoutOrder = #contentFrame:GetChildren()
    
    local leftLabel = Instance.new("TextLabel")
    leftLabel.Size = UDim2.new(0.45, 0, 1, 0)
    leftLabel.Position = UDim2.new(0, 0, 0, 0)
    leftLabel.BackgroundTransparency = 1
    leftLabel.TextColor3 = Color3.new(1, 1, 1)
    leftLabel.Text = ""
    leftLabel.TextSize = 12
    leftLabel.Font = Enum.Font.Gotham
    leftLabel.TextXAlignment = Enum.TextXAlignment.Left
    leftLabel.Parent = rowFrame
    
    local leftStroke = Instance.new("UIStroke")
    leftStroke.Color = Color3.new(0, 0, 0)
    leftStroke.Thickness = 1.5
    leftStroke.Parent = leftLabel
    
    local rightLabel = Instance.new("TextLabel")
    rightLabel.Size = UDim2.new(0.45, 0, 1, 0)
    rightLabel.Position = UDim2.new(0.55, 0, 0, 0)
    rightLabel.BackgroundTransparency = 1
    rightLabel.TextColor3 = Color3.new(1, 1, 1)
    rightLabel.Text = ""
    rightLabel.TextSize = 12
    rightLabel.Font = Enum.Font.Gotham
    rightLabel.TextXAlignment = Enum.TextXAlignment.Left
    rightLabel.Parent = rowFrame
    
    local rightStroke = Instance.new("UIStroke")
    rightStroke.Color = Color3.new(0, 0, 0)
    rightStroke.Thickness = 1.5
    rightStroke.Parent = rightLabel
    
    return rowFrame, leftLabel, rightLabel
end

local statRows = {}
local statLabels = {}

for i = 1, 3 do
    local rowFrame, leftLabel, rightLabel = createStatRow()
    rowFrame.Parent = contentFrame
    statRows[i] = rowFrame
    statLabels[i * 2 - 1] = leftLabel
    statLabels[i * 2] = rightLabel
end

local frameCount = 0
local lastTime = tick()

local startTime = tick()

local function getPerformanceStats()
    local stats = Stats
    
    local cpuTimeMs = 0
    local cpuSuccess, cpuResult = pcall(function()
        local performanceStats = stats:FindFirstChild("PerformanceStats")
        if performanceStats then
            local cpuStat = performanceStats:FindFirstChild("CPU")
            if cpuStat then
                local value = cpuStat:GetValue()
                if value < 1 then
                    return value * 1000
                end
                return value
            end
        end
        
        local physicsTime = stats.Physics.SteppingUpdateTime:GetValue()
        if physicsTime then
            return physicsTime * 1000
        end
        
        return 0
    end)
    
    if cpuSuccess and cpuResult then
        cpuTimeMs = math.floor(cpuResult * 10) / 10
    end
    
    local gpuTimeMs = 0
    local gpuSuccess, gpuResult = pcall(function()
        local performanceStats = stats:FindFirstChild("PerformanceStats")
        if performanceStats then
            local gpuStat = performanceStats:FindFirstChild("GPU")
            if gpuStat then
                local value = gpuStat:GetValue()
                if value < 1 then
                    return value * 1000
                end
                return value
            end
        end
        
        local renderTime = stats.Graphics.AverageRenderTime:GetValue()
        if renderTime then
            return renderTime * 1000
        end
        
        local textureTime = stats.Graphics.TextureStreamingTaskTime:GetValue()
        if textureTime then
            return textureTime * 1000
        end
        
        return 0
    end)
    
    if gpuSuccess and gpuResult then
        gpuTimeMs = math.floor(gpuResult * 10) / 10
    end
    
    local ping = 0
    local pingSuccess, pingResult = pcall(function()
        return stats.Network.ServerStatsItem["Data Ping"]:GetValue()
    end)
    
    if pingSuccess and pingResult then
        ping = pingResult
    end
    
    local ramUsageBytes = 0
    local ramSuccess, ramResult = pcall(function()
        return stats:GetTotalMemoryUsageMb() * 1024 * 1024
    end)
    
    if not ramSuccess then
        ramSuccess, ramResult = pcall(function()
            local total = 0
            local memoryTags = {
                Enum.DeveloperMemoryTag.Internal,
                Enum.DeveloperMemoryTag.HttpCache,
                Enum.DeveloperMemoryTag.Instances,
                Enum.DeveloperMemoryTag.Signals,
                Enum.DeveloperMemoryTag.LuaHeap,
                Enum.DeveloperMemoryTag.Script,
                Enum.DeveloperMemoryTag.Graphics
            }
            
            for _, tag in ipairs(memoryTags) do
                local success, value = pcall(function()
                    return stats:GetMemoryUsageMbForTag(tag)
                end)
                if success then
                    total = total + value
                end
            end
            return total * 1024 * 1024
        end)
    end
    
    if not ramSuccess then
        ramSuccess, ramResult = pcall(function()
            return collectgarbage("count") * 1024
        end)
    end
    
    if ramSuccess and ramResult then
        ramUsageBytes = ramResult
    end
    
    return {
        CPU = cpuTimeMs,
        GPU = gpuTimeMs,
        Ping = ping,
        RAM = ramUsageBytes
    }
end

local function getColorForMilliseconds(value)
    if value < 8 then
        return Color3.new(0.2, 1, 0.2)
    elseif value < 16 then
        return Color3.new(0.6, 1, 0.2)
    elseif value < 33 then
        return Color3.new(1, 1, 0.2)
    elseif value < 50 then
        return Color3.new(1, 0.6, 0.2)
    else
        return Color3.new(1, 0.2, 0.2)
    end
end

local function getColorForPing(value)
    if value < 50 then
        return Color3.new(0.2, 1, 0.2)
    elseif value < 100 then
        return Color3.new(1, 1, 0.2)
    elseif value < 200 then
        return Color3.new(1, 0.6, 0.2)
    else
        return Color3.new(1, 0.2, 0.2)
    end
end

local function getColorForFPS(value)
    if value >= 60 then
        return Color3.new(0.2, 1, 0.2)
    elseif value >= 30 then
        return Color3.new(1, 1, 0.2)
    else
        return Color3.new(1, 0.2, 0.2)
    end
end

local function getRAMColor(ramUsageMB)
    if ramUsageMB < 200 then
        return Color3.new(0.2, 1, 0.2)
    elseif ramUsageMB < 500 then
        return Color3.new(1, 1, 0.2)
    else
        return Color3.new(1, 0.2, 0.2)
    end
end

RunService.RenderStepped:Connect(function()
    frameCount = frameCount + 1
    
    local currentTime = tick()
    local timePassed = currentTime - lastTime
    
    if timePassed >= 1 then
        local fps = math.floor(frameCount / timePassed + 0.5)
        
        local stats = getPerformanceStats()
        
        statLabels[1].Text = string.format("FPS: %d", fps)
        statLabels[1].TextColor3 = getColorForFPS(fps)
        
        statLabels[3].Text = string.format("CPU: %.1fms", stats.CPU)
        statLabels[3].TextColor3 = getColorForMilliseconds(stats.CPU)
        
        statLabels[5].Text = string.format("Ping: %dms", stats.Ping)
        statLabels[5].TextColor3 = getColorForPing(stats.Ping)
        
        local elapsedTime = currentTime - startTime
        local minutes = math.floor(elapsedTime / 60)
        local seconds = math.floor(elapsedTime % 60)
        statLabels[2].Text = string.format("Time: %02d:%02d", minutes, seconds)
        statLabels[2].TextColor3 = Color3.new(1, 1, 1)
        
        statLabels[4].Text = string.format("GPU: %.1fms", stats.GPU)
        statLabels[4].TextColor3 = getColorForMilliseconds(stats.GPU)
        
        local ramMB = stats.RAM / (1024 * 1024)
        statLabels[6].Text = string.format("RAM: %s", formatMemorySize(stats.RAM))
        statLabels[6].TextColor3 = getRAMColor(ramMB)
        
        frameCount = 0
        lastTime = currentTime
    end
end)
