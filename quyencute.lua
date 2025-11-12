--// CONFIG (sử dụng getgenv để dùng chung giữa các script)
getgenv().Config = getgenv().Config or {
	FPS = 240, -- Giới hạn FPS
	AutoSetCap = true, -- Tự động gọi setfpscap()
}

--// Áp dụng cấu hình FPS
if getgenv().Config.AutoSetCap and setfpscap then
	pcall(function()
		setfpscap(getgenv().Config.FPS)
		print("⚙️ FPS Cap set to:", getgenv().Config.FPS)
	end)
end


--// Real FPS Display (Auto-scale, accurate & clear)
--// by Đào Nguyễn Minh Triết & GPT-5

-- Xóa FPS cũ nếu có
if game.CoreGui:FindFirstChild("FPS_Display") then
	game.CoreGui.FPS_Display:Destroy()
end

-- Tạo GUI
local fpsGui = Instance.new("ScreenGui")
fpsGui.Name = "FPS_Display"
fpsGui.ResetOnSpawn = false
fpsGui.IgnoreGuiInset = true
fpsGui.Parent = game:GetService("CoreGui")

-- Label hiển thị FPS (auto-scale)
local fpsLabel = Instance.new("TextLabel")
fpsLabel.AnchorPoint = Vector2.new(1, 0)
fpsLabel.Position = UDim2.new(1, -20, 0, 20) -- Góc phải trên
fpsLabel.Size = UDim2.new(0.1, 0, 0.05, 0) -- Tự co giãn theo kích thước Roblox
fpsLabel.BackgroundTransparency = 1
fpsLabel.Text = "FPS: 0"
fpsLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
fpsLabel.TextStrokeTransparency = 0
fpsLabel.TextScaled = true
fpsLabel.Font = Enum.Font.GothamBlack
fpsLabel.ZIndex = 999999
fpsLabel.Parent = fpsGui

-- Biến tính FPS
local fps = 0
local frames = 0
local lastTime = tick()

-- Hàm cập nhật kích thước khi Roblox thay đổi độ phân giải
local function updateSize()
	local viewportSize = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1920, 1080)
	local screenScale = math.clamp(viewportSize.Y / 1080, 0.6, 2)
	fpsLabel.Size = UDim2.new(0, 200 * screenScale, 0, 60 * screenScale)
	fpsLabel.TextScaled = true
end

-- Cập nhật size khi camera hoặc resolution thay đổi
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(updateSize)
if workspace.CurrentCamera then
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateSize)
end
updateSize()

-- Tính FPS thật
game:GetService("RunService").RenderStepped:Connect(function()
	frames += 1
	local now = tick()
	if now - lastTime >= 0.2 then -- cập nhật mỗi 0.2s
		fps = math.floor(frames / (now - lastTime))
		lastTime = now
		frames = 0

		-- Đổi màu
		if fps > 5 then
			fpsLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
		else
			fpsLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
		end

		fpsLabel.Text = "FPS: " .. fps
	end
end)
