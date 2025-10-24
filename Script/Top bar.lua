local player = game.Players.LocalPlayer
local guiService = game:GetService("GuiService")
local starterGui = game:GetService("StarterGui")

local playerGui = player:WaitForChild("PlayerGui")
if playerGui:FindFirstChild("CustomTopGui") then
    return
end

starterGui:SetCore("TopbarEnabled", false)

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CustomTopGui"
screenGui.IgnoreGuiInset = false
screenGui.ScreenInsets = Enum.ScreenInsets.TopbarSafeInsets
screenGui.DisplayOrder = 100
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local frame = Instance.new("Frame")
frame.Parent = screenGui
frame.BackgroundTransparency = 1
frame.BorderSizePixel = 0
frame.Position = UDim2.new(0, 0, 0, 0)
frame.Size = UDim2.new(1, 0, 1, -2)

local scrollingFrame = Instance.new("ScrollingFrame")
scrollingFrame.Name = "Right"
scrollingFrame.Parent = frame
scrollingFrame.BackgroundTransparency = 1
scrollingFrame.BorderSizePixel = 0
scrollingFrame.Position = UDim2.new(0, 12, 0, 0)
scrollingFrame.Size = UDim2.new(1, -24, 1, 0)
scrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
scrollingFrame.AutomaticCanvasSize = Enum.AutomaticSize.X
scrollingFrame.ScrollBarThickness = 0
scrollingFrame.ScrollingDirection = Enum.ScrollingDirection.X
scrollingFrame.ScrollingEnabled = false

local uiListLayout = Instance.new("UIListLayout")
uiListLayout.Parent = scrollingFrame
uiListLayout.Padding = UDim.new(0, 12)
uiListLayout.SortOrder = Enum.SortOrder.LayoutOrder
uiListLayout.FillDirection = Enum.FillDirection.Horizontal
uiListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
uiListLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
