local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local ReplicatedStorage= game:GetService("ReplicatedStorage")
local HttpService      = game:GetService("HttpService")

local Player   = Players.LocalPlayer
local PlayerGui= Player:WaitForChild("PlayerGui")
local CoreGui = game:GetService("CoreGui")

local function getDpiScale()
	local gui   = Instance.new("ScreenGui", PlayerGui)
	local frame = Instance.new("Frame", gui)
	frame.Size  = UDim2.new(0,100,0,100)
	task.wait()
	local scale = frame.AbsoluteSize.X / 100
	gui:Destroy()
	return math.clamp(math.round(scale*10)/10,1,3)
end
local DPI = getDpiScale()

local FILLED = "●"
local OPEN   = "○"

local function safeReadFile(path)
	if not readfile then return nil end
	local success, content = pcall(readfile, path)
	return success and content or nil
end

local function safeWriteFile(path, data)
	if not writefile then return false end
	local success, err = pcall(writefile, path, data)
	return success
end

local CONFIG_DIR = "DaraHub"
local CONFIG_FILE = CONFIG_DIR .. "/EvadeMacroVipCMD.json"

if isfolder and not isfolder(CONFIG_DIR) then makefolder(CONFIG_DIR) end

local Presets = {}
local function serializeMacro(macro)
	local ser = table.clone(macro)
	ser.keybind = macro.keybind.Name
	return ser
end
local function deserializeMacro(ser)
	local macro = table.clone(ser)
	macro.keybind = ser.keybind and Enum.KeyCode[ser.keybind] or Enum.KeyCode.F
	return macro
end
local function loadPresets()
	local data = safeReadFile(CONFIG_FILE)
	if data then
		local success, decoded = pcall(HttpService.JSONDecode, HttpService, data)
		if success and typeof(decoded) == "table" then
			Presets = {}
			for name, arr in pairs(decoded) do
				Presets[name] = {}
				for i, ser in ipairs(arr) do
					Presets[name][i] = deserializeMacro(ser)
				end
			end
		end
	end
end
local function savePresets()
	local toSave = {}
	for name, macros in pairs(Presets) do
		toSave[name] = {}
		for i, macro in ipairs(macros) do
			toSave[name][i] = serializeMacro(macro)
		end
	end
	local json = HttpService:JSONEncode(toSave)
	safeWriteFile(CONFIG_FILE, json)
end
loadPresets()

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MacroManagerGUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Enabled = false 
ScreenGui.Parent = CoreGui

local Main = Instance.new("Frame")
Main.Name = "MainFrame"
Main.Size = UDim2.new(0,380*DPI,0,480*DPI)
Main.Position = UDim2.new(0.5,0,0.5,0)
Main.AnchorPoint = Vector2.new(0.5,0.5)
Main.BackgroundColor3 = Color3.fromRGB(25,25,35)
Main.ClipsDescendants = true
Main.Parent = ScreenGui
Instance.new("UICorner",Main).CornerRadius = UDim.new(0,12)

local TitleBar = Instance.new("Frame")
TitleBar.Name = "TitleBar"
TitleBar.Size = UDim2.new(1,0,0,36*DPI)
TitleBar.BackgroundColor3 = Color3.fromRGB(30,30,45)
TitleBar.Parent = Main

local Title = Instance.new("TextLabel")
Title.Name = "TitleLabel"
Title.Size = UDim2.new(1,-84,1,0)
Title.Position = UDim2.new(0,8,0,0)
Title.BackgroundTransparency = 1
Title.Text = "Macro Manager"
Title.TextColor3 = Color3.new(1,1,1)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 16*DPI
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TitleBar

local ConfigBtn = Instance.new("TextButton")
ConfigBtn.Name = "ConfigButton"
ConfigBtn.Size = UDim2.new(0,28,0,28)
ConfigBtn.Position = UDim2.new(1,-68,0,4)
ConfigBtn.BackgroundColor3 = Color3.fromRGB(100,150,255)
ConfigBtn.Text = "🗂️"
ConfigBtn.TextColor3 = Color3.new(1,1,1)
ConfigBtn.Font = Enum.Font.GothamBold
ConfigBtn.TextSize = 16*DPI
ConfigBtn.Parent = TitleBar
Instance.new("UICorner",ConfigBtn).CornerRadius = UDim.new(0,6)

local Close = Instance.new("TextButton")
Close.Name = "CloseButton"
Close.Size = UDim2.new(0,28,0,28)
Close.Position = UDim2.new(1,-32,0,4)
Close.BackgroundColor3 = Color3.fromRGB(255,50,50)
Close.Text = "X"
Close.TextColor3 = Color3.new(1,1,1)
Close.Font = Enum.Font.GothamBold
Close.TextSize = 14*DPI
Close.Parent = TitleBar
Instance.new("UICorner",Close).CornerRadius = UDim.new(0,6)
Close.MouseButton1Click:Connect(function()
	ScreenGui.Enabled = false
end)

local Scroll = Instance.new("ScrollingFrame")
Scroll.Name = "MacroScroll"
Scroll.Size = UDim2.new(1,-16,1,-88)
Scroll.Position = UDim2.new(0,8,0,44)
Scroll.BackgroundTransparency = 1
Scroll.ScrollBarThickness = 5
Scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
Scroll.Parent = Main

local Layout = Instance.new("UIListLayout",Scroll)
Layout.Name = "MacroListLayout"
Layout.Padding = UDim.new(0,6)

local NoMacrosLabel = Instance.new("TextLabel")
NoMacrosLabel.Name = "NoMacrosLabel"
NoMacrosLabel.Size = UDim2.new(1,-32,1,-100)
NoMacrosLabel.Position = UDim2.new(0,16,0,50)
NoMacrosLabel.BackgroundTransparency = 1
NoMacrosLabel.Text = "No VIP Command macros available"
NoMacrosLabel.TextColor3 = Color3.fromRGB(150,150,150)
NoMacrosLabel.Font = Enum.Font.Gotham
NoMacrosLabel.TextSize = 16*DPI
NoMacrosLabel.TextWrapped = true
NoMacrosLabel.Visible = true
NoMacrosLabel.Parent = Main

local CreateBtn = Instance.new("TextButton")
CreateBtn.Name = "CreateButton"
CreateBtn.Size = UDim2.new(1,-16,0,36)
CreateBtn.Position = UDim2.new(0,8,1,-44)
CreateBtn.BackgroundColor3 = Color3.fromRGB(0,170,255)
CreateBtn.Text = "+ New Macro"
CreateBtn.TextColor3 = Color3.new(1,1,1)
CreateBtn.Font = Enum.Font.GothamBold
CreateBtn.TextSize = 15*DPI
CreateBtn.Parent = Main
Instance.new("UICorner",CreateBtn).CornerRadius = UDim.new(0,8)

local DelayUnits = {"Ms","Sec","Minute","Hour","Day","Week","Year"}
local function toMs(v,u)
	local m = {Ms=1,Sec=1000,Minute=60000,Hour=3600000,Day=86400000,Week=604800000,Year=31536000000}
	return (v or 0) * (m[u] or 1)
end

local TimeUnits = {"Ms","Second","Minute","Hour","Day","Week","Month","Year"}
local function toSeconds(v,u)
	local m = {Ms=0.001,Second=1,Minute=60,Hour=3600,Day=86400,Week=604800,Month=2629800,Year=31557600}
	return (v or 0) * (m[u] or 1)
end

local function formatTimeRemaining(seconds)
	if seconds <= 0 then return "Done" end
	local years = math.floor(seconds/31557600); seconds %= 31557600
	local months= math.floor(seconds/2629800); seconds %= 2629800
	local weeks = math.floor(seconds/604800); seconds %= 604800
	local days  = math.floor(seconds/86400); seconds %= 86400
	local hours = math.floor(seconds/3600); seconds %= 3600
	local mins  = math.floor(seconds/60); seconds %= 60
	local parts = {}
	if years>0  then table.insert(parts,years.."y") end
	if months>0 then table.insert(parts,months.."mo") end
	if weeks>0  then table.insert(parts,weeks.."w") end
	if days>0   then table.insert(parts,days.."d") end
	if hours>0  then table.insert(parts,hours.."h") end
	if mins>0   then table.insert(parts,mins.."m") end
	if seconds > 0 and (#parts > 0 and seconds >= 1 or #parts == 0) then
		local sec_str = seconds < 1 and string.format("%.1fs", seconds) or math.floor(seconds) .. "s"
		table.insert(parts, sec_str)
	end
	return table.concat(parts," ")
end

local Macros = {}

local function updateNoMacrosLabel()
	NoMacrosLabel.Visible = #Macros == 0
end
local function updateCanvas()
	task.defer(function()
		Scroll.CanvasSize = UDim2.new(0,0,0,Layout.AbsoluteContentSize.Y+10)
	end)
end

local ConfirmPopup
local function showDeleteConfirm(data,idx,entryFrame)
	if ConfirmPopup then ConfirmPopup:Destroy() end
	ConfirmPopup = Instance.new("Frame")
	ConfirmPopup.Name = "DeleteConfirmPopup"
	ConfirmPopup.Size = UDim2.new(0,260*DPI,0,130*DPI)
	ConfirmPopup.Position = UDim2.new(0.5,0,0.5,0)
	ConfirmPopup.AnchorPoint = Vector2.new(0.5,0.5)
	ConfirmPopup.BackgroundColor3 = Color3.fromRGB(30,30,40)
	ConfirmPopup.ZIndex = 20
	ConfirmPopup.Parent = ScreenGui
	Instance.new("UICorner",ConfirmPopup).CornerRadius = UDim.new(0,12)

	local msg = Instance.new("TextLabel")
	msg.Text = "Delete this macro?"
	msg.Size = UDim2.new(1,-20,0,50)
	msg.Position = UDim2.new(0,10,0,10)
	msg.BackgroundTransparency = 1
	msg.TextColor3 = Color3.new(1,1,1)
	msg.Font = Enum.Font.GothamBold
	msg.TextSize = 15*DPI
	msg.ZIndex = 21
	msg.Parent = ConfirmPopup

	local yes = Instance.new("TextButton")
	yes.Size = UDim2.new(0.45,0,0,32)
	yes.Position = UDim2.new(0.05,0,1,-40)
	yes.BackgroundColor3 = Color3.fromRGB(255,50,50)
	yes.Text = "Yes"
	yes.TextColor3 = Color3.new(1,1,1)
	yes.Font = Enum.Font.GothamBold
	yes.TextSize = 13*DPI
	yes.ZIndex = 21
	yes.Parent = ConfirmPopup
	Instance.new("UICorner",yes).CornerRadius = UDim.new(0,8)

	local no = Instance.new("TextButton")
	no.Size = UDim2.new(0.45,0,0,32)
	no.Position = UDim2.new(0.5,0,1,-40)
	no.BackgroundColor3 = Color3.fromRGB(100,100,100)
	no.Text = "No"
	no.TextColor3 = Color3.new(1,1,1)
	no.Font = Enum.Font.GothamBold
	no.TextSize = 13*DPI
	no.ZIndex = 21
	no.Parent = ConfirmPopup
	Instance.new("UICorner",no).CornerRadius = UDim.new(0,8)

	no.MouseButton1Click:Connect(function()
		ConfirmPopup:Destroy(); ConfirmPopup=nil
	end)

	yes.MouseButton1Click:Connect(function()
		if data.running and data.stopMacro then data.stopMacro() end
		if data.connections then
			for _,c in ipairs(data.connections) do if c.Connected then pcall(c.Disconnect,c) end end
		end
		entryFrame:Destroy()
		table.remove(Macros,idx)
		updateNoMacrosLabel()
		updateCanvas()
		ConfirmPopup:Destroy(); ConfirmPopup=nil
	end)
end

local function makeEntry(data,idx)
	local f = Instance.new("Frame")
	f.Name = "MacroEntry_" .. idx
	f.Size = UDim2.new(1,0,0,135)
	f.BackgroundColor3 = Color3.fromRGB(35,35,50)
	f.ZIndex = 2
	f.Parent = Scroll
	Instance.new("UICorner",f).CornerRadius = UDim.new(0,8)

	local name = Instance.new("TextLabel")
	name.Name = "MacroNameLabel"
	name.Size = UDim2.new(0.6,0,0,22)
	name.Position = UDim2.new(0,8,0,4)
	name.BackgroundTransparency = 1
	name.Text = data.name~="" and data.name or ("Macro "..idx)
	name.TextColor3 = Color3.new(1,1,1)
	name.Font = Enum.Font.GothamBold
	name.TextSize = 13*DPI
	name.TextXAlignment = Enum.TextXAlignment.Left
	name.ZIndex = 3
	name.Parent = f

	local cmd = Instance.new("TextLabel")
	cmd.Name = "CommandLabel"
	cmd.Size = UDim2.new(1,-16,0,18)
	cmd.Position = UDim2.new(0,8,0,26)
	cmd.BackgroundTransparency = 1
	cmd.Text = data.command
	cmd.TextColor3 = Color3.fromRGB(180,180,180)
	cmd.Font = Enum.Font.Gotham
	cmd.TextSize = 11*DPI
	cmd.TextXAlignment = Enum.TextXAlignment.Left
	cmd.ZIndex = 3
	cmd.Parent = f

	local info = Instance.new("TextLabel")
	info.Name = "InfoLabel"
	info.Size = UDim2.new(1,-16,0,20)
	info.Position = UDim2.new(0,8,0,44)
	info.BackgroundTransparency = 1
	info.Text = string.format("Delay: %d %s | Key: %s",data.delayValue,data.delayUnit,(data.keybind and data.keybind.Name) or "F")
	info.TextColor3 = Color3.fromRGB(120,200,255)
	info.Font = Enum.Font.Gotham
	info.TextSize = 10*DPI
	info.TextXAlignment = Enum.TextXAlignment.Left
	info.ZIndex = 3
	info.Parent = f

	local repeatLabel = Instance.new("TextLabel")
	repeatLabel.Name = "RepeatLabel"
	repeatLabel.Size = UDim2.new(1,-16,0,18)
	repeatLabel.Position = UDim2.new(0,8,0,66)
	repeatLabel.BackgroundTransparency = 1
	repeatLabel.Text = data.stopMode=="indefinitely" and "Run indefinitely"
	                  or data.stopMode=="time" and "Amount of time"
	                  or "Number of cycles"
	repeatLabel.TextColor3 = Color3.fromRGB(255,200,100)
	repeatLabel.Font = Enum.Font.Gotham
	repeatLabel.TextSize = 11*DPI
	repeatLabel.TextXAlignment = Enum.TextXAlignment.Left
	repeatLabel.ZIndex = 3
	repeatLabel.Parent = f

	local countdown = Instance.new("TextLabel")
	countdown.Name = "CountdownLabel"
	countdown.Size = UDim2.new(1,-16,0,18)
	countdown.Position = UDim2.new(0,8,0,84)
	countdown.BackgroundTransparency = 1
	countdown.Text = "Ready"
	countdown.TextColor3 = Color3.fromRGB(255,200,100)
	countdown.Font = Enum.Font.GothamBold
	countdown.TextSize = 12*DPI
	countdown.TextXAlignment = Enum.TextXAlignment.Left
	countdown.ZIndex = 3
	countdown.Parent = f

	local status = Instance.new("TextLabel")
	status.Name = "StatusLabel"
	status.Size = UDim2.new(0,70,0,18)
	status.Position = UDim2.new(1,-78,0,4)
	status.BackgroundTransparency = 1
	status.Text = "OFF"
	status.TextColor3 = Color3.fromRGB(255,100,100)
	status.Font = Enum.Font.GothamBold
	status.TextSize = 11*DPI
	status.ZIndex = 3
	status.Parent = f

	local function btn(txt,col,x,name)
		local b = Instance.new("TextButton")
		b.Name = name.."Button"
		b.Size = UDim2.new(0,52,0,22)
		b.Position = UDim2.new(0,x,1,-31)
		b.BackgroundColor3 = col
		b.Text = txt
		b.TextColor3 = Color3.new(1,1,1)
		b.Font = Enum.Font.GothamBold
		b.TextSize = 11*DPI
		b.ZIndex = 4
		b.Parent = f
		Instance.new("UICorner",b).CornerRadius = UDim.new(0,6)
		return b
	end
	local startBtn = btn("START",Color3.fromRGB(0,200,0),8,"Start")
	local editBtn  = btn("Edit",Color3.fromRGB(255,170,0),68,"Edit")
	local dupBtn   = btn("Dup",Color3.fromRGB(0,170,255),128,"Duplicate")
	local delBtn   = btn("Del",Color3.fromRGB(255,50,50),188,"Delete")

	local running = false
	local conn, countdownConn, keyConn
	data.connections = {}
	local startTime, cycleCount, maxCycles

	local function updateCountdown()
		if countdownConn and countdownConn.Connected then countdownConn:Disconnect() end

		if data.stopMode == "indefinitely" then
			countdown.Visible = false
			return
		else
			countdown.Visible = true
		end

		if not running then
			countdown.Text = "Ready"
			countdown.TextColor3 = Color3.fromRGB(255,200,100)
			return
		end

		countdownConn = RunService.Heartbeat:Connect(function()
			if not running then
				countdown.Text = "Ready"
				countdown.TextColor3 = Color3.fromRGB(255,200,100)
				if countdownConn.Connected then countdownConn:Disconnect() end
				return
			end

			local elapsed = tick() - startTime
			local delaySec = toMs(data.delayValue,data.delayUnit)/1000
			local nextInSec = delaySec - (elapsed % delaySec)

			if data.stopMode == "time" then
				local remaining = math.max(0, data.stopTime - elapsed)
				countdown.Text = formatTimeRemaining(remaining)
				countdown.TextColor3 = remaining<=0 and Color3.fromRGB(255,100,100) or Color3.fromRGB(100,255,100)

			elseif data.stopMode == "cycles" then
				local left = math.max(0, (maxCycles or 0) - cycleCount)
				countdown.Text = left.." cycle"..(left==1 and "" or "s").." left | "..formatTimeRemaining(nextInSec)
				countdown.TextColor3 = Color3.fromRGB(100,255,100)

			else
				countdown.Text = formatTimeRemaining(nextInSec)
				countdown.TextColor3 = Color3.fromRGB(100,255,100)
			end
		end)
		table.insert(data.connections,countdownConn)
	end

	local function stopMacro()
		if conn and conn.Connected then conn:Disconnect(); conn=nil end
		if countdownConn and countdownConn.Connected then countdownConn:Disconnect(); countdownConn=nil end
		if keyConn and keyConn.Connected then keyConn:Disconnect(); keyConn=nil end
		running = false
		startBtn.Text = "START"
		startBtn.BackgroundColor3 = Color3.fromRGB(0,200,0)
		status.Text = "OFF"
		status.TextColor3 = Color3.fromRGB(255,100,100)
		countdown.Text = "Ready"
		countdown.TextColor3 = Color3.fromRGB(255,200,100)
		data.connections = {}
		updateCountdown()
	end
	data.stopMacro = stopMacro

	local function startMacro()
		if running then return end
		running = true
		startBtn.Text = "STOP"
		startBtn.BackgroundColor3 = Color3.fromRGB(255,50,50)
		status.Text = "ON"
		status.TextColor3 = Color3.fromRGB(0,255,0)

		startTime = tick()
		cycleCount = 0
		maxCycles = (data.stopMode=="cycles") and data.stopCycles or nil
		local delaySec = toMs(data.delayValue,data.delayUnit)/1000
		local nextRun = 0

		if conn and conn.Connected then conn:Disconnect() end
		conn = RunService.Heartbeat:Connect(function()
			if not running then return end
			local now = tick()

			if data.stopMode=="time" and (now-startTime >= data.stopTime) then stopMacro(); return end
			if data.stopMode=="cycles" and cycleCount >= maxCycles then stopMacro(); return end

			if now >= nextRun then
				pcall(function()
					ReplicatedStorage.Events.Admin.VIPCommand:InvokeServer(data.command)
				end)
				cycleCount += 1
				nextRun = now + delaySec
			end
		end)
		table.insert(data.connections,conn)
		updateCountdown()
	end

	startBtn.MouseButton1Click:Connect(function()
		if running then stopMacro() else startMacro() end
	end)

	local function connectKeybind()
		if keyConn and keyConn.Connected then keyConn:Disconnect() end
		keyConn = UserInputService.InputBegan:Connect(function(inp,gp)
			if gp or inp.KeyCode ~= data.keybind then return end
			if running then stopMacro() else startMacro() end
		end)
		table.insert(data.connections,keyConn)
	end
	connectKeybind()
	data.connectKeybind = connectKeybind

	dupBtn.MouseButton1Click:Connect(function()
		local copy = table.clone(data)
		copy.name = (copy.name~="" and copy.name or "Macro").." (Copy)"
		table.insert(Macros,copy)
		makeEntry(copy,#Macros)
		updateNoMacrosLabel()
		updateCanvas()
	end)

	delBtn.MouseButton1Click:Connect(function() showDeleteConfirm(data,idx,f) end)
	editBtn.MouseButton1Click:Connect(function() CmdEditMacro(data,idx,f) end)

	data.running = running
	data.entryFrame = f
	data.startBtn   = startBtn
	data.status     = status
	data.countdown  = countdown
	data.repeatLabel= repeatLabel
	data.updateCountdown = updateCountdown

	updateCountdown()
	updateNoMacrosLabel()
	updateCanvas()
	return f
end

local Popup, activeDropdown, overlay
local function closeAllDropdowns()
	if activeDropdown then activeDropdown.Visible = false; activeDropdown = nil end
	if overlay then overlay:Destroy(); overlay = nil end
end
local function createOverlay()
	if overlay then overlay:Destroy() end
	overlay = Instance.new("TextButton")
	overlay.Size = UDim2.new(1,0,1,0)
	overlay.BackgroundTransparency = 0.7
	overlay.BackgroundColor3 = Color3.new(0,0,0)
	overlay.Text = ""
	overlay.ZIndex = 14
	overlay.Parent = Popup
	overlay.MouseButton1Click:Connect(closeAllDropdowns)
end
local function makeDropdown(btn,list,options,default,cb)
	btn.Text = default
	list.Visible = false
	list.ZIndex = 15
	for i,opt in ipairs(options) do
		local o = Instance.new("TextButton")
		o.Size = UDim2.new(1,0,0,28)
		o.Position = UDim2.new(0,0,0,(i-1)*28)
		o.BackgroundColor3 = Color3.fromRGB(50,50,70)
		o.Text = opt
		o.TextColor3 = Color3.new(1,1,1)
		o.Font = Enum.Font.Gotham
		o.TextSize = 13*DPI
		o.ZIndex = 16
		o.Parent = list
		Instance.new("UICorner",o).CornerRadius = UDim.new(0,6)
		o.MouseButton1Click:Connect(function()
			btn.Text = opt
			cb(opt)
			closeAllDropdowns()
		end)
	end
	btn.ZIndex = 11
	btn.MouseButton1Click:Connect(function()
		if activeDropdown == list then
			closeAllDropdowns()
		else
			closeAllDropdowns()
			list.Visible = true
			activeDropdown = list
			createOverlay()
		end
	end)
end

function CmdEditMacro(editData, oldIdx, oldFrame)
	if Popup then Popup:Destroy() end
	local isEdit = editData ~= nil
	local data = isEdit and table.clone(editData) or {
		name="",command="",delayValue=1,delayUnit="Ms",
		keybind=Enum.KeyCode.F,stopMode="indefinitely",
		stopTime=5,stopTimeUnit="Second",stopCycles=10
	}

	Popup = Instance.new("Frame")
	Popup.Name = "EditMacroPopup"
	Popup.Size = UDim2.new(0,360*DPI,0,460*DPI)
	Popup.Position = UDim2.new(0.5,0,0.5,0)
	Popup.AnchorPoint = Vector2.new(0.5,0.5)
	Popup.BackgroundColor3 = Color3.fromRGB(30,30,40)
	Popup.ZIndex = 10
	Popup.Parent = ScreenGui
	Instance.new("UICorner",Popup).CornerRadius = UDim.new(0,12)

	local pTitle = Instance.new("TextLabel")
	pTitle.Size = UDim2.new(1,0,0,36)
	pTitle.BackgroundColor3 = Color3.fromRGB(35,35,55)
	pTitle.Text = isEdit and "Edit Macro" or "New Macro"
	pTitle.TextColor3 = Color3.new(1,1,1)
	pTitle.Font = Enum.Font.GothamBold
	pTitle.TextSize = 16*DPI
	pTitle.ZIndex = 11
	pTitle.Parent = Popup
	Instance.new("UICorner",pTitle).CornerRadius = UDim.new(0,12)

	local nameBox = Instance.new("TextBox")
	nameBox.Size = UDim2.new(1,-16,0,32)
	nameBox.Position = UDim2.new(0,8,0,44)
	nameBox.PlaceholderText = "Enter Name"
	nameBox.Text = data.name
	nameBox.BackgroundColor3 = Color3.fromRGB(40,40,55)
	nameBox.TextColor3 = Color3.new(1,1,1)
	nameBox.Font = Enum.Font.Gotham
	nameBox.TextSize = 13*DPI
	nameBox.ClearTextOnFocus = false
	nameBox.ZIndex = 11
	nameBox.Parent = Popup
	Instance.new("UICorner",nameBox)

	local cmdBox = Instance.new("TextBox")
	cmdBox.Size = UDim2.new(1,-16,0,32)
	cmdBox.Position = UDim2.new(0,8,0,82)
	cmdBox.PlaceholderText = "Enter command here, use ''!'' To execute a command"
	cmdBox.Text = data.command
	cmdBox.BackgroundColor3 = Color3.fromRGB(40,40,55)
	cmdBox.TextColor3 = Color3.new(1,1,1)
	cmdBox.Font = Enum.Font.Gotham
	cmdBox.TextSize = 13*DPI
	cmdBox.ClearTextOnFocus = false
	cmdBox.ZIndex = 11
	cmdBox.Parent = Popup
	Instance.new("UICorner",cmdBox)

	local delayVal = Instance.new("TextBox")
	delayVal.Size = UDim2.new(0,90,0,32)
	delayVal.Position = UDim2.new(0,8,0,120)
	delayVal.PlaceholderText = "Delay"
	delayVal.Text = tostring(data.delayValue or 1)
	delayVal.BackgroundColor3 = Color3.fromRGB(40,40,55)
	delayVal.TextColor3 = Color3.new(1,1,1)
	delayVal.Font = Enum.Font.Gotham
	delayVal.TextSize = 13*DPI
	delayVal.ClearTextOnFocus = false
	delayVal.ZIndex = 11
	delayVal.Parent = Popup
	Instance.new("UICorner",delayVal)

	local delayDrop = Instance.new("TextButton")
	delayDrop.Size = UDim2.new(0,90,0,32)
	delayDrop.Position = UDim2.new(0,106,0,120)
	delayDrop.BackgroundColor3 = Color3.fromRGB(50,50,70)
	delayDrop.TextColor3 = Color3.new(1,1,1)
	delayDrop.Font = Enum.Font.GothamBold
	delayDrop.TextSize = 13*DPI
	delayDrop.Text = data.delayUnit or "Ms"
	delayDrop.ZIndex = 11
	delayDrop.Parent = Popup
	Instance.new("UICorner",delayDrop)

	local dropList = Instance.new("Frame")
	dropList.Size = UDim2.new(0,90,0,196)
	dropList.Position = UDim2.new(0,106,0,152)
	dropList.BackgroundColor3 = Color3.fromRGB(40,40,55)
	dropList.Visible = false
	dropList.ZIndex = 15
	dropList.Parent = Popup
	Instance.new("UICorner",dropList)
	makeDropdown(delayDrop,dropList,DelayUnits,data.delayUnit or "Ms",function(u) data.delayUnit=u end)

	local keyBtn = Instance.new("TextButton")
	keyBtn.Size = UDim2.new(1,-16,0,32)
	keyBtn.Position = UDim2.new(0,8,0,162)
	keyBtn.Text = "Key: "..(data.keybind and data.keybind.Name or "F")
	keyBtn.BackgroundColor3 = Color3.fromRGB(40,40,55)
	keyBtn.TextColor3 = Color3.new(1,1,1)
	keyBtn.Font = Enum.Font.Gotham
	keyBtn.TextSize = 13*DPI
	keyBtn.ZIndex = 11
	keyBtn.Parent = Popup
	Instance.new("UICorner",keyBtn)

	local waiting = false
	keyBtn.MouseButton1Click:Connect(function()
		if waiting then return end
		waiting = true
		keyBtn.Text = "Press any key..."
		local c; c = UserInputService.InputBegan:Connect(function(inp)
			if inp.KeyCode ~= Enum.KeyCode.Unknown then
				data.keybind = inp.KeyCode
				keyBtn.Text = "Key: "..inp.KeyCode.Name
				waiting = false
				c:Disconnect()
			end
		end)
	end)

	local stopAfterLabel = Instance.new("TextLabel")
	stopAfterLabel.Size = UDim2.new(1,-16,0,24)
	stopAfterLabel.Position = UDim2.new(0,8,0,196)
	stopAfterLabel.BackgroundTransparency = 1
	stopAfterLabel.Text = "Stop after"
	stopAfterLabel.TextColor3 = Color3.fromRGB(200,200,200)
	stopAfterLabel.Font = Enum.Font.GothamBold
	stopAfterLabel.TextSize = 14*DPI
	stopAfterLabel.TextXAlignment = Enum.TextXAlignment.Left
	stopAfterLabel.ZIndex = 11
	stopAfterLabel.Parent = Popup

	local radioRows = {}
	local function updateRadios()
		for _,row in ipairs(radioRows) do
			local radio = row:FindFirstChild("RadioBtn")
			local bg    = row:FindFirstChild("CircleBg")
			local mode  = row:FindFirstChild("Mode")
			if radio and bg and mode then
				local sel = mode.Value == data.stopMode
				radio.Text = sel and FILLED or OPEN
				bg.BackgroundColor3 = sel and Color3.fromRGB(0,200,0) or Color3.fromRGB(70,70,70)
			end
		end
	end
	local function makeRadio(y,txt,mode)
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1,-16,0,32)
		row.Position = UDim2.new(0,8,0,y)
		row.BackgroundTransparency = 1
		row.ZIndex = 11
		row.Parent = Popup

		local bg = Instance.new("Frame")
		bg.Name = "CircleBg"
		bg.Size = UDim2.new(0,28,0,28)
		bg.Position = UDim2.new(0,0,0,2)
		bg.BackgroundColor3 = data.stopMode==mode and Color3.fromRGB(0,200,0) or Color3.fromRGB(70,70,70)
		bg.ZIndex = 11
		bg.Parent = row
		Instance.new("UICorner",bg).CornerRadius = UDim.new(0,14)

		local radio = Instance.new("TextButton")
		radio.Name = "RadioBtn"
		radio.Size = UDim2.new(0,28,0,28)
		radio.Position = UDim2.new(0,0,0,2)
		radio.BackgroundTransparency = 1
		radio.Text = data.stopMode==mode and FILLED or OPEN
		radio.TextColor3 = Color3.new(1,1,1)
		radio.Font = Enum.Font.Code
		radio.TextSize = 22*DPI
		radio.ZIndex = 12
		radio.Parent = row

		local lbl = Instance.new("TextLabel")
		lbl.Size = UDim2.new(1,-36,1,0)
		lbl.Position = UDim2.new(0,36,0,0)
		lbl.BackgroundTransparency = 1
		lbl.Text = txt
		lbl.TextColor3 = Color3.new(1,1,1)
		lbl.Font = Enum.Font.Gotham
		lbl.TextSize = 13*DPI
		lbl.TextXAlignment = Enum.TextXAlignment.Left
		lbl.ZIndex = 11
		lbl.Parent = row

		radio.MouseButton1Click:Connect(function()
			data.stopMode = mode
			updateRadios()
		end)

		local modeVal = Instance.new("StringValue")
		modeVal.Name = "Mode"
		modeVal.Value = mode
		modeVal.Parent = row
		table.insert(radioRows,row)
		return row
	end

	local timeRow  = makeRadio(220,"Amount of time","time")
	local cycleRow = makeRadio(256,"Number of cycles","cycles")
	makeRadio(292,"Run indefinitely","indefinitely")

	local timeInput = Instance.new("TextBox")
	timeInput.Size = UDim2.new(0,70,0,28)
	timeInput.Position = UDim2.new(0,130,0,2)
	timeInput.BackgroundColor3 = Color3.fromRGB(40,40,55)
	timeInput.TextColor3 = Color3.new(1,1,1)
	timeInput.Font = Enum.Font.Gotham
	timeInput.TextSize = 13*DPI
	if data.stopMode=="time" and data.stopTime then
		local unit = data.stopTimeUnit or "Second"
		local val = data.stopTime / toSeconds(1,unit)
		timeInput.Text = tostring(math.floor(val+0.5))
	else
		timeInput.Text = "5"
		timeInput.PlaceholderText = "Time value"
	end
	timeInput.ClearTextOnFocus = false
	timeInput.ZIndex = 11
	timeInput.Parent = timeRow
	Instance.new("UICorner",timeInput)

	local timeDrop = Instance.new("TextButton")
	timeDrop.Size = UDim2.new(0,70,0,28)
	timeDrop.Position = UDim2.new(0,208,0,2)
	timeDrop.BackgroundColor3 = Color3.fromRGB(50,50,70)
	timeDrop.TextColor3 = Color3.new(1,1,1)
	timeDrop.Font = Enum.Font.GothamBold
	timeDrop.TextSize = 13*DPI
	timeDrop.Text = data.stopTimeUnit or "Second"
	timeDrop.ZIndex = 11
	timeDrop.Parent = timeRow
	Instance.new("UICorner",timeDrop)

	local tList = Instance.new("Frame")
	tList.Size = UDim2.new(0,70,0,224)
	tList.Position = UDim2.new(0,208,0,30)
	tList.BackgroundColor3 = Color3.fromRGB(40,40,55)
	tList.Visible = false
	tList.ZIndex = 15
	tList.Parent = timeRow
	Instance.new("UICorner",tList)
	makeDropdown(timeDrop,tList,TimeUnits,data.stopTimeUnit or "Second",function(u) data.stopTimeUnit=u end)

	local cycleInput = Instance.new("TextBox")
	cycleInput.Size = UDim2.new(0,100,0,28)
	cycleInput.Position = UDim2.new(0,150,0,2)
	cycleInput.BackgroundColor3 = Color3.fromRGB(40,40,55)
	cycleInput.TextColor3 = Color3.new(1,1,1)
	cycleInput.Font = Enum.Font.Gotham
	cycleInput.TextSize = 13*DPI
	cycleInput.Text = tostring(data.stopCycles or 10)
	cycleInput.ClearTextOnFocus = false
	cycleInput.ZIndex = 11
	cycleInput.Parent = cycleRow
	Instance.new("UICorner",cycleInput)

	local save = Instance.new("TextButton")
	save.Size = UDim2.new(0.5,-12,0,36)
	save.Position = UDim2.new(0,8,1,-44)
	save.BackgroundColor3 = Color3.fromRGB(0,200,0)
	save.Text = isEdit and "Update" or "Create"
	save.TextColor3 = Color3.new(1,1,1)
	save.Font = Enum.Font.GothamBold
	save.TextSize = 15*DPI
	save.ZIndex = 11
	save.Parent = Popup
	Instance.new("UICorner",save)

	local cancel = Instance.new("TextButton")
	cancel.Size = UDim2.new(0.5,-12,0,36)
	cancel.Position = UDim2.new(0.5,4,1,-44)
	cancel.BackgroundColor3 = Color3.fromRGB(150,150,150)
	cancel.Text = "Cancel"
	cancel.TextColor3 = Color3.new(1,1,1)
	cancel.Font = Enum.Font.GothamBold
	cancel.TextSize = 15*DPI
	cancel.ZIndex = 11
	cancel.Parent = Popup
	Instance.new("UICorner",cancel)

	cancel.MouseButton1Click:Connect(function()
		closeAllDropdowns()
		Popup:Destroy(); Popup=nil
	end)

	local function updateSaveBtn()
		local hasCmd = cmdBox.Text:match("^%s*(.-)%s*$") ~= ""
		save.BackgroundColor3 = hasCmd and Color3.fromRGB(0,200,0) or Color3.fromRGB(100,100,100)
		save.TextColor3 = hasCmd and Color3.new(1,1,1) or Color3.fromRGB(180,180,180)
	end
	cmdBox:GetPropertyChangedSignal("Text"):Connect(updateSaveBtn)
	updateSaveBtn()

	save.MouseButton1Click:Connect(function()
		local cmd = cmdBox.Text:match("^%s*(.-)%s*$")
		if cmd == "" then return end
		local name = nameBox.Text ~= "" and nameBox.Text or "Macro"
		local dVal = tonumber(delayVal.Text) or 1

		local newData = {
			name = name,
			command = cmd,
			delayValue = dVal,
			delayUnit = delayDrop.Text,
			keybind = data.keybind,
			stopMode = data.stopMode,
			stopTime = nil,
			stopTimeUnit = nil,
			stopCycles = nil,
		}
		if data.stopMode == "time" then
			local val = tonumber(timeInput.Text) or 5
			local unit = timeDrop.Text
			newData.stopTime = toSeconds(val,unit)
			newData.stopTimeUnit = unit
		elseif data.stopMode == "cycles" then
			newData.stopCycles = tonumber(cycleInput.Text) or 10
		end

		if isEdit then
			if editData.running and editData.stopMacro then editData.stopMacro() end
			if editData.connections then
				for _,c in ipairs(editData.connections) do if c.Connected then pcall(c.Disconnect,c) end end
			end
			oldFrame:Destroy()
			table.remove(Macros,oldIdx)
		end

		table.insert(Macros,newData)
		makeEntry(newData,#Macros)
		updateNoMacrosLabel()
		updateCanvas()
		closeAllDropdowns()
		Popup:Destroy(); Popup=nil
	end)

	updateRadios()

	local cam = workspace.CurrentCamera
	local scale = math.min(1, cam.ViewportSize.X*0.7/(360*DPI), cam.ViewportSize.Y*0.7/(460*DPI))
	Instance.new("UIScale",Popup).Scale = scale
end

local ConfigPopup
local ConfigScroll
local PresetConfirmPopup
local SaveAsPopup
local selectedPresetRow = nil

local function highlightPresetRow(row, selected)
	if selected then
		row.BackgroundColor3 = Color3.fromRGB(0, 120, 255)
	else
		row.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
	end
end

local function showPresetDeleteConfirm(presetName, row)
	if PresetConfirmPopup then PresetConfirmPopup:Destroy() end
	PresetConfirmPopup = Instance.new("Frame")
	PresetConfirmPopup.Name = "PresetDeleteConfirm"
	PresetConfirmPopup.Size = UDim2.new(0,260*DPI,0,130*DPI)
	PresetConfirmPopup.Position = UDim2.new(0.5,0,0.5,0)
	PresetConfirmPopup.AnchorPoint = Vector2.new(0.5,0.5)
	PresetConfirmPopup.BackgroundColor3 = Color3.fromRGB(30,30,40)
	PresetConfirmPopup.ZIndex = 40
	PresetConfirmPopup.Parent = ScreenGui
	Instance.new("UICorner",PresetConfirmPopup).CornerRadius = UDim.new(0,12)

	local msg = Instance.new("TextLabel")
	msg.Text = "Delete preset '" .. presetName .. "'?"
	msg.Size = UDim2.new(1,-20,0,50)
	msg.Position = UDim2.new(0,10,0,10)
	msg.BackgroundTransparency = 1
	msg.TextColor3 = Color3.new(1,1,1)
	msg.Font = Enum.Font.GothamBold
	msg.TextSize = 15*DPI
	msg.TextWrapped = true
	msg.ZIndex = 41
	msg.Parent = PresetConfirmPopup

	local yes = Instance.new("TextButton")
	yes.Size = UDim2.new(0.45,0,0,32)
	yes.Position = UDim2.new(0.05,0,1,-40)
	yes.BackgroundColor3 = Color3.fromRGB(255,50,50)
	yes.Text = "Yes"
	yes.TextColor3 = Color3.new(1,1,1)
	yes.Font = Enum.Font.GothamBold
	yes.TextSize = 13*DPI
	yes.ZIndex = 41
	yes.Parent = PresetConfirmPopup
	Instance.new("UICorner",yes).CornerRadius = UDim.new(0,8)

	local no = Instance.new("TextButton")
	no.Size = UDim2.new(0.45,0,0,32)
	no.Position = UDim2.new(0.5,0,1,-40)
	no.BackgroundColor3 = Color3.fromRGB(100,100,100)
	no.Text = "No"
	no.TextColor3 = Color3.new(1,1,1)
	no.Font = Enum.Font.GothamBold
	no.TextSize = 13*DPI
	no.ZIndex = 41
	no.Parent = PresetConfirmPopup
	Instance.new("UICorner",no).CornerRadius = UDim.new(0,8)

	no.MouseButton1Click:Connect(function()
		PresetConfirmPopup:Destroy(); PresetConfirmPopup=nil
	end)

	yes.MouseButton1Click:Connect(function()
		Presets[presetName] = nil
		savePresets()
		row:Destroy()
		PresetConfirmPopup:Destroy(); PresetConfirmPopup=nil
	end)
end

local function showPresetLoadConfirm(presetName, presetData)
	if PresetConfirmPopup then PresetConfirmPopup:Destroy() end
	PresetConfirmPopup = Instance.new("Frame")
	PresetConfirmPopup.Name = "PresetLoadConfirm"
	PresetConfirmPopup.Size = UDim2.new(0,260*DPI,0,130*DPI)
	PresetConfirmPopup.Position = UDim2.new(0.5,0,0.5,0)
	PresetConfirmPopup.AnchorPoint = Vector2.new(0.5,0.5)
	PresetConfirmPopup.BackgroundColor3 = Color3.fromRGB(30,30,40)
	PresetConfirmPopup.ZIndex = 40
	PresetConfirmPopup.Parent = ScreenGui
	Instance.new("UICorner",PresetConfirmPopup).CornerRadius = UDim.new(0,12)

	local msg = Instance.new("TextLabel")
	msg.Text = "Loading '" .. presetName .. "' will replace current macros. Continue?"
	msg.Size = UDim2.new(1,-20,0,50)
	msg.Position = UDim2.new(0,10,0,10)
	msg.BackgroundTransparency = 1
	msg.TextColor3 = Color3.new(1,1,1)
	msg.Font = Enum.Font.GothamBold
	msg.TextSize = 15*DPI
	msg.TextWrapped = true
	msg.ZIndex = 41
	msg.Parent = PresetConfirmPopup

	local yes = Instance.new("TextButton")
	yes.Size = UDim2.new(0.45,0,0,32)
	yes.Position = UDim2.new(0.05,0,1,-40)
	yes.BackgroundColor3 = Color3.fromRGB(0,170,255)
	yes.Text = "Yes"
	yes.TextColor3 = Color3.new(1,1,1)
	yes.Font = Enum.Font.GothamBold
	yes.TextSize = 13*DPI
	yes.ZIndex = 41
	yes.Parent = PresetConfirmPopup
	Instance.new("UICorner",yes).CornerRadius = UDim.new(0,8)

	local no = Instance.new("TextButton")
	no.Size = UDim2.new(0.45,0,0,32)
	no.Position = UDim2.new(0.5,0,1,-40)
	no.BackgroundColor3 = Color3.fromRGB(100,100,100)
	no.Text = "No"
	no.TextColor3 = Color3.new(1,1,1)
	no.Font = Enum.Font.GothamBold
	no.TextSize = 13*DPI
	no.ZIndex = 41
	no.Parent = PresetConfirmPopup
	Instance.new("UICorner",no).CornerRadius = UDim.new(0,8)

	no.MouseButton1Click:Connect(function()
		PresetConfirmPopup:Destroy(); PresetConfirmPopup=nil
	end)

	yes.MouseButton1Click:Connect(function()
		Macros = table.clone(presetData)
		for _,c in ipairs(Scroll:GetChildren()) do
			if c:IsA("Frame") and c.Name:match("^MacroEntry_") then c:Destroy() end
		end
		for i,m in ipairs(Macros) do makeEntry(m,i) end
		updateNoMacrosLabel()
		updateCanvas()
		ConfigPopup:Destroy(); ConfigPopup = nil
		PresetConfirmPopup:Destroy(); PresetConfirmPopup=nil
	end)
end

local function showPresetSaveConflict(presetName, input, saveBtn, defaultName)
	if PresetConfirmPopup then PresetConfirmPopup:Destroy() end
	PresetConfirmPopup = Instance.new("Frame")
	PresetConfirmPopup.Name = "PresetSaveConflict"
	PresetConfirmPopup.Size = UDim2.new(0,280*DPI,0,150*DPI)
	PresetConfirmPopup.Position = UDim2.new(0.5,0,0.5,0)
	PresetConfirmPopup.AnchorPoint = Vector2.new(0.5,0.5)
	PresetConfirmPopup.BackgroundColor3 = Color3.fromRGB(30,30,40)
	PresetConfirmPopup.ZIndex = 50
	PresetConfirmPopup.Parent = ScreenGui
	Instance.new("UICorner",PresetConfirmPopup).CornerRadius = UDim.new(0,12)

	local msg = Instance.new("TextLabel")
	msg.Text = "Preset '" .. presetName .. "' already exists."
	msg.Size = UDim2.new(1,-20,0,40)
	msg.Position = UDim2.new(0,10,0,10)
	msg.BackgroundTransparency = 1
	msg.TextColor3 = Color3.new(1,1,1)
	msg.Font = Enum.Font.GothamBold
	msg.TextSize = 15*DPI
	msg.TextWrapped = true
	msg.ZIndex = 51
	msg.Parent = PresetConfirmPopup

	local replace = Instance.new("TextButton")
	replace.Size = UDim2.new(0.3,0,0,32)
	replace.Position = UDim2.new(0.05,0,1,-40)
	replace.BackgroundColor3 = Color3.fromRGB(255,170,0)
	replace.Text = "Replace"
	replace.TextColor3 = Color3.new(1,1,1)
	replace.Font = Enum.Font.GothamBold
	replace.TextSize = 13*DPI
	replace.ZIndex = 51
	replace.Parent = PresetConfirmPopup
	Instance.new("UICorner",replace).CornerRadius = UDim.new(0,8)

	local rename = Instance.new("TextButton")
	rename.Size = UDim2.new(0.35,0,0,32)
	rename.Position = UDim2.new(0.36,0,1,-40)
	rename.BackgroundColor3 = Color3.fromRGB(0,170,255)
	rename.Text = "Rename"
	rename.TextColor3 = Color3.new(1,1,1)
	rename.Font = Enum.Font.GothamBold
	rename.TextSize = 13*DPI
	rename.ZIndex = 51
	rename.Parent = PresetConfirmPopup
	Instance.new("UICorner",rename).CornerRadius = UDim.new(0,8)

	local cancel = Instance.new("TextButton")
	cancel.Size = UDim2.new(0.3,0,0,32)
	cancel.Position = UDim2.new(0.72,0,1,-40)
	cancel.BackgroundColor3 = Color3.fromRGB(100,100,100)
	cancel.Text = "Cancel"
	cancel.TextColor3 = Color3.new(1,1,1)
	cancel.Font = Enum.Font.GothamBold
	cancel.TextSize = 13*DPI
	cancel.ZIndex = 51
	cancel.Parent = PresetConfirmPopup
	Instance.new("UICorner",cancel).CornerRadius = UDim.new(0,8)

	cancel.MouseButton1Click:Connect(function()
		input:Destroy()
		saveBtn:Destroy()
		PresetConfirmPopup:Destroy(); PresetConfirmPopup=nil
	end)

	local function performSave(finalName)
		Presets[finalName] = table.clone(Macros)
		savePresets()
		input:Destroy()
		saveBtn:Destroy()
		PresetConfirmPopup:Destroy(); PresetConfirmPopup=nil
		openConfigPopup()
	end

	replace.MouseButton1Click:Connect(function()
		performSave(presetName)
	end)

	rename.MouseButton1Click:Connect(function()
		local newName = presetName
		local i = 1
		while Presets[newName] do
			newName = presetName .. " (" .. i .. ")"
			i += 1
		end
		performSave(newName)
	end)
end

local function showSaveAsPopup()
	if SaveAsPopup then SaveAsPopup:Destroy() end
	if ConfigPopup then ConfigPopup:Destroy() end

	selectedPresetRow = nil

	local defaultName = "Preset " .. os.date("%H-%M-%S")

	SaveAsPopup = Instance.new("Frame")
	SaveAsPopup.Name = "SaveAsPopup"
	SaveAsPopup.Size = UDim2.new(0,360*DPI,0,400*DPI)
	SaveAsPopup.Position = UDim2.new(0.5,0,0.5,0)
	SaveAsPopup.AnchorPoint = Vector2.new(0.5,0.5)
	SaveAsPopup.BackgroundColor3 = Color3.fromRGB(30,30,40)
	SaveAsPopup.ZIndex = 30
	SaveAsPopup.Parent = ScreenGui
	Instance.new("UICorner",SaveAsPopup).CornerRadius = UDim.new(0,12)

	local pTitle = Instance.new("TextLabel")
	pTitle.Size = UDim2.new(1,0,0,36)
	pTitle.BackgroundColor3 = Color3.fromRGB(35,35,55)
	pTitle.Text = "Save As"
	pTitle.TextColor3 = Color3.new(1,1,1)
	pTitle.Font = Enum.Font.GothamBold
	pTitle.TextSize = 16*DPI
	pTitle.ZIndex = 31
	pTitle.Parent = SaveAsPopup
	Instance.new("UICorner",pTitle).CornerRadius = UDim.new(0,12)

	local existingScroll = Instance.new("ScrollingFrame")
	existingScroll.Name = "ExistingPresetsScroll"
	existingScroll.Size = UDim2.new(1,-16,0,200)
	existingScroll.Position = UDim2.new(0,8,0,44)
	existingScroll.BackgroundTransparency = 1
	existingScroll.ScrollBarThickness = 5
	existingScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	existingScroll.ZIndex = 31
	existingScroll.Parent = SaveAsPopup

	local existingLayout = Instance.new("UIListLayout", existingScroll)
	existingLayout.Padding = UDim.new(0,6)

	local input

	for presetName, _ in pairs(Presets) do
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1,0,0,30)
		row.BackgroundColor3 = Color3.fromRGB(40,40,55)
		row.ZIndex = 32
		row.Parent = existingScroll
		Instance.new("UICorner",row).CornerRadius = UDim.new(0,6)

		local label = Instance.new("TextButton")
		label.Text = presetName
		label.Size = UDim2.new(1,-16,1,0)
		label.Position = UDim2.new(0,8,0,0)
		label.BackgroundTransparency = 1
		label.TextColor3 = Color3.new(1,1,1)
		label.Font = Enum.Font.Gotham
		label.TextSize = 13*DPI
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.ZIndex = 33
		label.Parent = row

		label.MouseButton1Click:Connect(function()
			if selectedPresetRow then
				highlightPresetRow(selectedPresetRow, false)
			end
			selectedPresetRow = row
			highlightPresetRow(row, true)
			input.Text = presetName
		end)
	end

	local inputLabel = Instance.new("TextLabel")
	inputLabel.Text = "Enter preset name"
	inputLabel.Size = UDim2.new(1,-16,0,24)
	inputLabel.Position = UDim2.new(0,8,0,260)
	inputLabel.BackgroundTransparency = 1
	inputLabel.TextColor3 = Color3.fromRGB(200,200,200)
	inputLabel.Font = Enum.Font.Gotham
	inputLabel.TextSize = 14*DPI
	inputLabel.ZIndex = 31
	inputLabel.Parent = SaveAsPopup

	input = Instance.new("TextBox")
	input.Text = ""
	input.ClearTextOnFocus = false
	input.PlaceholderText = defaultName
	input.Size = UDim2.new(1,-16,0,32)
	input.Position = UDim2.new(0,8,0,284)
	input.BackgroundColor3 = Color3.fromRGB(50,50,70)
	input.TextColor3 = Color3.new(1,1,1)
	input.Font = Enum.Font.Gotham
	input.TextSize = 13*DPI
	input.ZIndex = 31
	input.Parent = SaveAsPopup
	Instance.new("UICorner",input).CornerRadius = UDim.new(0,8)

	local saveBtn = Instance.new("TextButton")
	saveBtn.Size = UDim2.new(0.5,-12,0,36)
	saveBtn.Position = UDim2.new(0,8,1,-44)
	saveBtn.BackgroundColor3 = Color3.fromRGB(0,200,0)
	saveBtn.Text = "Save"
	saveBtn.TextColor3 = Color3.new(1,1,1)
	saveBtn.Font = Enum.Font.GothamBold
	saveBtn.TextSize = 15*DPI
	saveBtn.ZIndex = 31
	saveBtn.Parent = SaveAsPopup
	Instance.new("UICorner",saveBtn).CornerRadius = UDim.new(0,8)

	local cancelBtn = Instance.new("TextButton")
	cancelBtn.Size = UDim2.new(0.5,-12,0,36)
	cancelBtn.Position = UDim2.new(0.5,4,1,-44)
	cancelBtn.BackgroundColor3 = Color3.fromRGB(150,150,150)
	cancelBtn.Text = "Cancel"
	cancelBtn.TextColor3 = Color3.new(1,1,1)
	cancelBtn.Font = Enum.Font.GothamBold
	cancelBtn.TextSize = 15*DPI
	cancelBtn.ZIndex = 31
	cancelBtn.Parent = SaveAsPopup
	Instance.new("UICorner",cancelBtn).CornerRadius = UDim.new(0,8)

	cancelBtn.MouseButton1Click:Connect(function()
		SaveAsPopup:Destroy(); SaveAsPopup = nil
		openConfigPopup()
	end)

	saveBtn.MouseButton1Click:Connect(function()
		local presetName = input.Text:match("^%s*(.-)%s*$")
		if presetName == "" then presetName = defaultName end
		if Presets[presetName] then
			showPresetSaveConflict(presetName, input, saveBtn, defaultName)
		else
			Presets[presetName] = table.clone(Macros)
			savePresets()
			SaveAsPopup:Destroy(); SaveAsPopup = nil
			openConfigPopup()
		end
	end)

	local cam = workspace.CurrentCamera
	local scale = math.min(1, cam.ViewportSize.X*0.7/(360*DPI), cam.ViewportSize.Y*0.7/(400*DPI))
	Instance.new("UIScale",SaveAsPopup).Scale = scale
end

local function openConfigPopup()
	if ConfigPopup then ConfigPopup:Destroy() end

	ConfigPopup = Instance.new("Frame")
	ConfigPopup.Size = UDim2.new(0,360*DPI,0,400*DPI)
	ConfigPopup.Position = UDim2.new(0.5,0,0.5,0)
	ConfigPopup.AnchorPoint = Vector2.new(0.5,0.5)
	ConfigPopup.BackgroundColor3 = Color3.fromRGB(30,30,40)
	ConfigPopup.ZIndex = 30
	ConfigPopup.Parent = ScreenGui
	Instance.new("UICorner",ConfigPopup).CornerRadius = UDim.new(0,12)

	local pTitle = Instance.new("TextLabel")
	pTitle.Size = UDim2.new(1,0,0,36)
	pTitle.BackgroundColor3 = Color3.fromRGB(35,35,55)
	pTitle.Text = "Macro Presets"
	pTitle.TextColor3 = Color3.new(1,1,1)
	pTitle.Font = Enum.Font.GothamBold
	pTitle.TextSize = 16*DPI
	pTitle.ZIndex = 31
	pTitle.Parent = ConfigPopup
	Instance.new("UICorner",pTitle).CornerRadius = UDim.new(0,12)

	ConfigScroll = Instance.new("ScrollingFrame")
	ConfigScroll.Size = UDim2.new(1,-16,1,-88)
	ConfigScroll.Position = UDim2.new(0,8,0,44)
	ConfigScroll.BackgroundTransparency = 1
	ConfigScroll.ScrollBarThickness = 5
	ConfigScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	ConfigScroll.ZIndex = 31
	ConfigScroll.Parent = ConfigPopup

	local cfgLayout = Instance.new("UIListLayout", ConfigScroll)
	cfgLayout.Padding = UDim.new(0,6)

	local saveAsBtn = Instance.new("TextButton")
	saveAsBtn.Size = UDim2.new(0.5,-12,0,36)
	saveAsBtn.Position = UDim2.new(0,8,1,-44)
	saveAsBtn.BackgroundColor3 = Color3.fromRGB(0,170,255)
	saveAsBtn.Text = "Save As"
	saveAsBtn.TextColor3 = Color3.new(1,1,1)
	saveAsBtn.Font = Enum.Font.GothamBold
	saveAsBtn.TextSize = 15*DPI
	saveAsBtn.ZIndex = 31
	saveAsBtn.Parent = ConfigPopup
	Instance.new("UICorner",saveAsBtn).CornerRadius = UDim.new(0,8)

	local closeCfgBtn = Instance.new("TextButton")
	closeCfgBtn.Size = UDim2.new(0.5,-12,0,36)
	closeCfgBtn.Position = UDim2.new(0.5,4,1,-44)
	closeCfgBtn.BackgroundColor3 = Color3.fromRGB(150,150,150)
	closeCfgBtn.Text = "Close"
	closeCfgBtn.TextColor3 = Color3.new(1,1,1)
	closeCfgBtn.Font = Enum.Font.GothamBold
	closeCfgBtn.TextSize = 15*DPI
	closeCfgBtn.ZIndex = 31
	closeCfgBtn.Parent = ConfigPopup
	Instance.new("UICorner",closeCfgBtn).CornerRadius = UDim.new(0,8)

	closeCfgBtn.MouseButton1Click:Connect(function()
		ConfigPopup:Destroy(); ConfigPopup = nil
	end)

	saveAsBtn.MouseButton1Click:Connect(function()
		showSaveAsPopup()
	end)

	for presetName, presetData in pairs(Presets) do
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1,0,0,40)
		row.BackgroundColor3 = Color3.fromRGB(40,40,55)
		row.ZIndex = 32
		row.Parent = ConfigScroll
		Instance.new("UICorner",row).CornerRadius = UDim.new(0,8)

		local label = Instance.new("TextLabel")
		label.Text = presetName
		label.Size = UDim2.new(0.6,0,1,0)
		label.Position = UDim2.new(0,8,0,0)
		label.BackgroundTransparency = 1
		label.TextColor3 = Color3.new(1,1,1)
		label.Font = Enum.Font.Gotham
		label.TextSize = 13*DPI
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.ZIndex = 33
		label.Parent = row

		local loadBtn = Instance.new("TextButton")
		loadBtn.Size = UDim2.new(0,60,0,28)
		loadBtn.Position = UDim2.new(1,-130,0,6)
		loadBtn.BackgroundColor3 = Color3.fromRGB(0,200,0)
		loadBtn.Text = "Load"
		loadBtn.TextColor3 = Color3.new(1,1,1)
		loadBtn.Font = Enum.Font.GothamBold
		loadBtn.TextSize = 12*DPI
		loadBtn.ZIndex = 33
		loadBtn.Parent = row
		Instance.new("UICorner",loadBtn).CornerRadius = UDim.new(0,6)

		local delBtn = Instance.new("TextButton")
		delBtn.Size = UDim2.new(0,60,0,28)
		delBtn.Position = UDim2.new(1,-65,0,6)
		delBtn.BackgroundColor3 = Color3.fromRGB(255,50,50)
		delBtn.Text = "Delete"
		delBtn.TextColor3 = Color3.new(1,1,1)
		delBtn.Font = Enum.Font.GothamBold
		delBtn.TextSize = 12*DPI
		delBtn.ZIndex = 33
		delBtn.Parent = row
		Instance.new("UICorner",delBtn).CornerRadius = UDim.new(0,6)

		loadBtn.MouseButton1Click:Connect(function()
			showPresetLoadConfirm(presetName, presetData)
		end)

		delBtn.MouseButton1Click:Connect(function()
			showPresetDeleteConfirm(presetName, row)
		end)
	end

	local cam = workspace.CurrentCamera
	local scale = math.min(1, cam.ViewportSize.X*0.7/(360*DPI), cam.ViewportSize.Y*0.7/(400*DPI))
	Instance.new("UIScale",ConfigPopup).Scale = scale
end

ConfigBtn.MouseButton1Click:Connect(openConfigPopup)

CreateBtn.MouseButton1Click:Connect(function() CmdEditMacro() end)

updateNoMacrosLabel()
updateCanvas()

local cam = workspace.CurrentCamera
local scale = math.min(1, cam.ViewportSize.X*0.7/(380*DPI), cam.ViewportSize.Y*0.7/(480*DPI))
local uiScale = Instance.new("UIScale",Main)
uiScale.Scale = scale
