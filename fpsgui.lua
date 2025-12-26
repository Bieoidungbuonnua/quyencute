--// CONFIG dùng chung
getgenv().Config = getgenv().Config or {
	FPS = 240, -- Giới hạn FPS
	AutoSetCap = true, -- Tự động gọi setfpscap()
}

--// Set FPS Cap nếu có
if getgenv().Config.AutoSetCap and setfpscap then
	pcall(function()
		setfpscap(getgenv().Config.FPS)
		print("⚙️ FPS Cap set to:", getgenv().Config.FPS)
	end)
end


--// GUI Spam Join Job ID (Tự động bật Spam)
-- Tác giả: Đào Nguyễn Minh Triết
local StarterGui = game:GetService("StarterGui")

pcall(function()
    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
end)

local player = game.Players.LocalPlayer
local gui = Instance.new("ScreenGui")
gui.Name = "JoinJobGui"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")
-- Name UI
repeat task.wait() until game:IsLoaded()

local Players = game:GetService("Players")
local plr = Players.LocalPlayer

-- Xoá UI cũ nếu có
if game.CoreGui:FindFirstChild("PlayerNameUI") then
    game.CoreGui.PlayerNameUI:Destroy()
end

-- ScreenGui
local gui = Instance.new("ScreenGui")
gui.Name = "PlayerNameUI"
gui.ResetOnSpawn = false
gui.Parent = game.CoreGui

-- TextLabel
local nameLabel = Instance.new("TextLabel")
nameLabel.Parent = gui
nameLabel.Size = UDim2.new(0, 260, 0, 40)
nameLabel.Position = UDim2.new(1, -270, 1, -50) -- góc dưới phải

nameLabel.BackgroundTransparency = 1
nameLabel.Text = plr.Name
nameLabel.TextColor3 = Color3.fromRGB(255, 215, 0) -- vàng (gold)
nameLabel.TextSize = 22
nameLabel.Font = Enum.Font.GothamBold
nameLabel.TextXAlignment = Enum.TextXAlignment.Right
nameLabel.TextYAlignment = Enum.TextYAlignment.Center

-- Khung chính
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 260, 0, 120)
mainFrame.Position = UDim2.new(0.5, -130, 0, 25)
mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
mainFrame.BackgroundTransparency = 0.1
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = gui

-- Tiêu đề
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 28)
title.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
title.Text = "🔥SCRIPT JOIN BY TRIET"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.SourceSansBold
title.TextSize = 20
title.Parent = mainFrame

-- Ô nhập Job ID
local jobBox = Instance.new("TextBox")
jobBox.Size = UDim2.new(0.9, 0, 0, 35)
jobBox.Position = UDim2.new(0.05, 0, 0.38, 0)
jobBox.PlaceholderText = "Điền Job iD..."
jobBox.Text = ""
jobBox.ClearTextOnFocus = true
jobBox.TextScaled = true
jobBox.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
jobBox.TextColor3 = Color3.fromRGB(255, 255, 255)
jobBox.Font = Enum.Font.SourceSans
jobBox.Parent = mainFrame

-- Nút Spam Join
local spamBtn = Instance.new("TextButton")
spamBtn.Size = UDim2.new(0.43, 0, 0, 26)
spamBtn.Position = UDim2.new(0.05, 0, 0.8, 0)
spamBtn.Text = "🔥 Spam Join (ON)"
spamBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
spamBtn.TextColor3 = Color3.new(1, 1, 1)
spamBtn.Font = Enum.Font.SourceSansBold
spamBtn.TextScaled = true
spamBtn.Parent = mainFrame

-- Nút Đóng
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0.43, 0, 0, 26)
closeBtn.Position = UDim2.new(0.52, 0, 0.8, 0)
closeBtn.Text = "❌ CLOSE"
closeBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
closeBtn.TextColor3 = Color3.new(1, 1, 1)
closeBtn.Font = Enum.Font.SourceSansBold
closeBtn.TextScaled = true
closeBtn.Parent = mainFrame

-- Hàm Join Job
local function joinJob(jobId)
	if jobId and jobId ~= "" then
		print("Đang join JobID:", jobId)
		game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, jobId, player)
	else
		warn("⚠️ Chưa nhập Job ID!")
	end
end

-- Khi nhấn Enter thì join luôn
jobBox.FocusLost:Connect(function(enterPressed)
	if enterPressed then
		joinJob(jobBox.Text)
	end
end)

-- Spam Join bật mặc định
local spamming = true
task.spawn(function()
	while spamming do
		joinJob(jobBox.Text)
		task.wait(3)
	end
end)

-- Nút bật/tắt Spam Join
spamBtn.MouseButton1Click:Connect(function()
	spamming = not spamming
	if spamming then
		spamBtn.Text = "🔥 Spam Join (ON)"
		spamBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
		task.spawn(function()
			while spamming do
				joinJob(jobBox.Text)
				task.wait(3)
			end
		end)
	else
		spamBtn.Text = "🔥 Spam Join (OFF)"
		spamBtn.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
	end
end)

-- Nút Đóng
closeBtn.MouseButton1Click:Connect(function()
	gui:Destroy()
end)



--// GUI góc phải: Copy Job ID + Hop Server Blox Fruits
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local player = Players.LocalPlayer

local old = player:FindFirstChild("PlayerGui"):FindFirstChild("JobGUI")
if old then old:Destroy() end

local gui2 = Instance.new("ScreenGui")
gui2.Name = "JobGUI"
gui2.ResetOnSpawn = false
gui2.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 180, 0, 120)
frame.Position = UDim2.new(1, -190, 0, 10)
frame.BackgroundColor3 = Color3.fromRGB(25,25,25)
frame.BackgroundTransparency = 0.3
frame.BorderSizePixel = 0
frame.Parent = gui2

Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)

local copyButton = Instance.new("TextButton")
copyButton.Size = UDim2.new(1, -20, 0, 45)
copyButton.Position = UDim2.new(0, 10, 0, 10)
copyButton.BackgroundColor3 = Color3.fromRGB(50,150,255)
copyButton.Text = "📋 Copy Job ID"
copyButton.TextColor3 = Color3.new(1,1,1)
copyButton.Font = Enum.Font.SourceSansBold
copyButton.TextSize = 20
copyButton.Parent = frame
Instance.new("UICorner", copyButton).CornerRadius = UDim.new(0,8)

local hopButton = Instance.new("TextButton")
hopButton.Size = UDim2.new(1, -20, 0, 45)
hopButton.Position = UDim2.new(0, 10, 0, 65)
hopButton.BackgroundColor3 = Color3.fromRGB(0,200,100)
hopButton.Text = "🌎 Hop Server"
hopButton.TextColor3 = Color3.new(1,1,1)
hopButton.Font = Enum.Font.SourceSansBold
hopButton.TextSize = 20
hopButton.Parent = frame
Instance.new("UICorner", hopButton).CornerRadius = UDim.new(0,8)
-- Nút Reset Character
local resetButton = Instance.new("TextButton")
resetButton.Size = UDim2.new(1, -20, 0, 45)
resetButton.Position = UDim2.new(0, 10, 0, 120) -- nằm dưới nút Hop Server
resetButton.BackgroundColor3 = Color3.fromRGB(255, 120, 50)
resetButton.Text = "🔁 Reset Character"
resetButton.TextColor3 = Color3.new(1, 1, 1)
resetButton.Font = Enum.Font.SourceSansBold
resetButton.TextSize = 20
resetButton.Parent = frame
Instance.new("UICorner", resetButton).CornerRadius = UDim.new(0, 8)

resetButton.MouseButton1Click:Connect(function()
	resetButton.Text = "⏳ Resetting..."
	task.wait(1)
	pcall(function()
		game:GetService("Players").LocalPlayer.Character:BreakJoints()
	end)
	resetButton.Text = "🔁 Reset Character"
end)


copyButton.MouseButton1Click:Connect(function()
	setclipboard(game.JobId)
	copyButton.Text = "✅ Đã copy!"
	task.wait(1.5)
	copyButton.Text = "📋 Copy Job ID"
end)

hopButton.MouseButton1Click:Connect(function()
	hopButton.Text = "🔄 Đang HOP..."
	pcall(function()
		local placeId = 2753915549
		local foundServer = nil
		local cursor = ""
		repeat
			local url = ("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100%s"):format(
				placeId, cursor ~= "" and "&cursor=" .. cursor or ""
			)
			local data = game:GetService("HttpService"):JSONDecode(game:HttpGet(url))
			for _, v in ipairs(data.data) do
				if v.playing < v.maxPlayers and v.id ~= game.JobId then
					foundServer = v.id
					break
				end
			end
			cursor = data.nextPageCursor or ""
		until foundServer or cursor == ""
		if foundServer then
			hopButton.Text = "🌍 Đang HOP..."
			TeleportService:TeleportToPlaceInstance(placeId, foundServer, player)
		else
			hopButton.Text = "⚠️ Không có server trống!"
			task.wait(2)
			hopButton.Text = "🌎 Hop Server"
		end
	end)
end)
--// Real FPS Display (Auto-scale, accurate & clear)
--// by Đào Nguyễn Minh Triết & GPT-5
if game.CoreGui:FindFirstChild("FPS_Display") then
	game.CoreGui.FPS_Display:Destroy()
end

local fpsGui = Instance.new("ScreenGui")
fpsGui.Name = "FPS_Display"
fpsGui.ResetOnSpawn = false
fpsGui.IgnoreGuiInset = true
fpsGui.Parent = game:GetService("CoreGui")

local fpsLabel = Instance.new("TextLabel")
fpsLabel.AnchorPoint = Vector2.new(1, 0)
fpsLabel.Position = UDim2.new(1, -20, 0, 20)
fpsLabel.Size = UDim2.new(0.1, 0, 0.05, 0)
fpsLabel.BackgroundTransparency = 1
fpsLabel.Text = "FPS: 0"
fpsLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
fpsLabel.TextStrokeTransparency = 0
fpsLabel.TextScaled = true
fpsLabel.Font = Enum.Font.GothamBlack
fpsLabel.ZIndex = 999999
fpsLabel.Parent = fpsGui

local fps, frames, lastTime = 0, 0, tick()
local function updateSize()
	local viewportSize = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1920, 1080)
	local scale = math.clamp(viewportSize.Y / 1080, 0.6, 2)
	fpsLabel.Size = UDim2.new(0, 200 * scale, 0, 60 * scale)
	fpsLabel.TextScaled = true
end

workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(updateSize)
if workspace.CurrentCamera then
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateSize)
end
updateSize()

game:GetService("RunService").RenderStepped:Connect(function()
	frames += 1
	local now = tick()
	if now - lastTime >= 0.2 then
		fps = math.floor(frames / (now - lastTime))
		lastTime, frames = now, 0
		fpsLabel.TextColor3 = fps > 5 and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
		fpsLabel.Text = "FPS: " .. fps
	end
end)

--// Gui Check Player Blox Fruit (mượt & luôn hiện)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- Xóa GUI cũ nếu có
local oldGui = LocalPlayer:FindFirstChild("PlayerGui"):FindFirstChild("PlayerCheckGui")
if oldGui then oldGui:Destroy() end

-- Tạo ScreenGui mới
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "PlayerCheckGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- Tạo Label hiển thị số player
local PlayerLabel = Instance.new("TextLabel")
PlayerLabel.Size = UDim2.new(0, 150, 0, 40)
PlayerLabel.Position = UDim2.new(0, 10, 0, 50) -- ⬅⬅⬅ GIẢM CAO XUỐNG DƯỚI
PlayerLabel.BackgroundColor3 = Color3.fromRGB(128, 0, 128)
PlayerLabel.BackgroundTransparency = 0.3
PlayerLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
PlayerLabel.Font = Enum.Font.SourceSansBold
PlayerLabel.TextScaled = true
PlayerLabel.Text = "Loading..."
PlayerLabel.Parent = ScreenGui

-- Update số player realtime mỗi frame
RunService.Heartbeat:Connect(function()
    if PlayerLabel then
        local count = #Players:GetPlayers()
        PlayerLabel.Text = count.."/12"
    end
end)


--// HIỂN THỊ PLACE ID Ở GIỮA MÀN HÌNH
-- by GPT-5 (theo yêu cầu của Đào Nguyễn Minh Triết)

local currentPlaceId = game.PlaceId

-- Tạo GUI hiển thị Place ID ở giữa phía trên
local infoGui = Instance.new("ScreenGui")
infoGui.Name = "PlaceInfoGui"
infoGui.ResetOnSpawn = false
infoGui.IgnoreGuiInset = true
infoGui.Parent = game:GetService("CoreGui")

local infoLabel = Instance.new("TextLabel")
infoLabel.AnchorPoint = Vector2.new(0.5, 0)
infoLabel.Position = UDim2.new(0.5, 0, 0, 20) -- Giữa phía trên màn hình
infoLabel.Size = UDim2.new(0, 500, 0, 50)
infoLabel.BackgroundTransparency = 1
infoLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
infoLabel.TextStrokeTransparency = 0.2
infoLabel.Font = Enum.Font.GothamBold
infoLabel.TextScaled = true
infoLabel.ZIndex = 999999
infoLabel.Text = "🆔 Place ID: " .. tostring(currentPlaceId)
infoLabel.Parent = infoGui

-- Tự động điều chỉnh kích thước theo độ phân giải màn hình
local function autoScale()
	local viewport = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1920, 1080)
	local scale = math.clamp(viewport.Y / 1080, 0.8, 2)
	infoLabel.Size = UDim2.new(0, 350 * scale, 0, 50 * scale)
	infoLabel.TextScaled = true
end

workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(autoScale)
if workspace.CurrentCamera then
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(autoScale)
end
autoScale()

