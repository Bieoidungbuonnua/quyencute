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



-- Lua FPS Boost (tắt ánh sáng/hiệu ứng nặng)
-- by bạn & ChatGPT (GPT-5 Thinking mini)
-- Chạy applyBoost() để bật, restoreBoost() để hoàn tác

local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Nếu đã backup thì dùng lại, tránh ghi đè
getgenv()._FPSBoostBackup = getgenv()._FPSBoostBackup or {
	lights = {}, -- store lights enabled
	effects = {}, -- store post processing enabled
	particles = {}, -- store particle enabled states (by instance)
	decals = {}, -- store decal/transparency
	parts = {}, -- store part material/reflectance/castshadow
	applied = false,
}

local backup = getgenv()._FPSBoostBackup

local function isParticleLike(inst)
	return inst:IsA("ParticleEmitter")
		or inst:IsA("Trail")
		or inst:IsA("Fire")
		or inst:IsA("Smoke")
		or inst:IsA("Sparkles")
		or inst:IsA("Beam")
		or inst:IsA("Explosion")
end

local function isLightLike(inst)
	return inst:IsA("PointLight")
		or inst:IsA("SurfaceLight")
		or inst:IsA("SpotLight")
		-- Note: other light types uncommon on parts
end

local function isPostProcessing(inst)
	return inst:IsA("BloomEffect")
		or inst:IsA("ColorCorrectionEffect")
		or inst:IsA("SunRaysEffect")
		or inst:IsA("DepthOfFieldEffect")
		or inst:IsA("BlurEffect")
		or inst:IsA("SunRays")
end

local function applyBoost()
	if backup.applied then
		warn("FPS Boost đã được áp dụng rồi.")
		return
	end

	-- 1) Tắt post-processing trong Lighting (backup)
	for _, inst in ipairs(Lighting:GetChildren()) do
		if isPostProcessing(inst) then
			backup.effects[#backup.effects+1] = {inst, inst.Enabled}
			pcall(function() inst.Enabled = false end)
		end
	end
	-- Also attempt to disable any unnamed effects that have Enabled property
	for _, inst in ipairs(Lighting:GetChildren()) do
		if not isPostProcessing(inst) and typeof(inst) == "Instance" and inst:IsA("Instance") then
			if pcall(function() return inst.Enabled end) then
				local ok, val = pcall(function() return inst.Enabled end)
				if ok then
					backup.effects[#backup.effects+1] = {inst, inst.Enabled}
					pcall(function() inst.Enabled = false end)
				end
			end
		end
	end

	-- 2) Iterate workspace and disable particle-like effects, lights, decals, and simplify parts
	for _, inst in ipairs(Workspace:GetDescendants()) do
		-- Part simplification
		if inst:IsA("BasePart") then
			backup.parts[#backup.parts+1] = {inst, inst.Material, inst.Reflectance, inst.CastShadow}
			pcall(function()
				inst.Material = Enum.Material.Plastic
				inst.Reflectance = 0
				inst.CastShadow = false
			end)
		end

		-- Particle-like
		if isParticleLike(inst) then
			backup.particles[#backup.particles+1] = {inst, inst.Enabled}
			pcall(function() inst.Enabled = false end)
		end

		-- Lights on parts
		if isLightLike(inst) then
			backup.lights[#backup.lights+1] = {inst, inst.Enabled}
			pcall(function() inst.Enabled = false end)
		end

		-- Generic Lights (Light class)
		if inst:IsA("Light") and not isLightLike(inst) then
			backup.lights[#backup.lights+1] = {inst, inst.Enabled}
			pcall(function() inst.Enabled = false end)
		end

		-- Decals and Textures -> hide (backup transparency / decal properties)
		if inst:IsA("Decal") then
			backup.decals[#backup.decals+1] = {inst, inst.Transparency}
			pcall(function() inst.Transparency = 1 end)
		elseif inst:IsA("Texture") then
			backup.decals[#backup.decals+1] = {inst, inst.Transparency}
			pcall(function() inst.Transparency = 1 end)
		elseif inst:IsA("SpecialMesh") or inst:IsA("MeshPart") or inst:IsA("Texture") then
			-- nothing for now
		end

		-- SurfaceAppearance: try to reduce PBR heavy effects
		if inst:IsA("SurfaceAppearance") then
			-- cannot change many properties safely; try set Roughness/Metalness via properties if exist
			-- backup not implemented due to limited API surface
			pcall(function()
				if inst:FindFirstChild("RoughnessMap") then
					inst.RoughnessMap = nil
				end
			end)
		end
	end

	-- 3) Lighting global settings
	backup.lightingSettings = {
		GlobalShadows = Lighting.GlobalShadows,
		Brightness = Lighting.Brightness,
		ClockTime = Lighting.ClockTime,
		Ambient = Lighting.Ambient,
		OutdoorAmbient = Lighting.OutdoorAmbient,
		FogEnd = Lighting.FogEnd,
		FogStart = Lighting.FogStart,
	}

	pcall(function()
		Lighting.GlobalShadows = false
		Lighting.Brightness = 0
		Lighting.Ambient = Color3.fromRGB(128,128,128)
		Lighting.OutdoorAmbient = Color3.fromRGB(128,128,128)
		Lighting.FogStart = 1e6
		Lighting.FogEnd = 1e6
	end)

	-- 4) Attempt to disable decals on player characters (hat textures, face decals)
	for _, pl in ipairs(Players:GetPlayers()) do
		if pl.Character then
			for _, chInst in ipairs(pl.Character:GetDescendants()) do
				if chInst:IsA("Decal") or chInst:IsA("Texture") then
					backup.decals[#backup.decals+1] = {chInst, chInst.Transparency}
					pcall(function() chInst.Transparency = 1 end)
				end
				if chInst:IsA("ParticleEmitter") or chInst:IsA("Trail") then
					backup.particles[#backup.particles+1] = {chInst, chInst.Enabled}
					pcall(function() chInst.Enabled = false end)
				end
			end
		end
	end

	-- 5) Try to reduce terrain detail (if Terrain exists)
	if workspace:FindFirstChildOfClass("Terrain") then
		local terr = workspace:FindFirstChildOfClass("Terrain")
		-- Backup not exhaustive; we store water properties if present
		backup.terrain = {}
		pcall(function()
			backup.terrain.WaterWaveSize = terr.WaterWaveSize
			backup.terrain.WaterWaveSpeed = terr.WaterWaveSpeed
			terr.WaterWaveSize = 0
			terr.WaterWaveSpeed = 0
		end)
	end

	backup.applied = true
	print("[FPSBoost] Applied. Use restoreBoost() to revert changes.")
end

local function restoreBoost()
	if not backup.applied then
		warn("FPS Boost chưa được áp dụng hoặc không có backup.")
		return
	end

	-- restore effects
	for _, info in ipairs(backup.effects) do
		local inst, enabled = info[1], info[2]
		if inst and inst.Parent then
			pcall(function() inst.Enabled = enabled end)
		end
	end

	-- restore particles
	for _, info in ipairs(backup.particles) do
		local inst, enabled = info[1], info[2]
		if inst and inst.Parent then
			pcall(function() inst.Enabled = enabled end)
		end
	end

	-- restore lights
	for _, info in ipairs(backup.lights) do
		local inst, enabled = info[1], info[2]
		if inst and inst.Parent then
			pcall(function() inst.Enabled = enabled end)
		end
	end

	-- restore decals
	for _, info in ipairs(backup.decals) do
		local inst, transp = info[1], info[2]
		if inst and inst.Parent then
			pcall(function() inst.Transparency = transp end)
		end
	end

	-- restore parts
	for _, info in ipairs(backup.parts) do
		local inst, mat, refl, cast = info[1], info[2], info[3], info[4]
		if inst and inst.Parent then
			pcall(function()
				inst.Material = mat
				inst.Reflectance = refl
				inst.CastShadow = cast
			end)
		end
	end

	-- restore lighting settings
	if backup.lightingSettings then
		pcall(function()
			Lighting.GlobalShadows = backup.lightingSettings.GlobalShadows
			Lighting.Brightness = backup.lightingSettings.Brightness
			Lighting.ClockTime = backup.lightingSettings.ClockTime
			Lighting.Ambient = backup.lightingSettings.Ambient
			Lighting.OutdoorAmbient = backup.lightingSettings.OutdoorAmbient
			Lighting.FogStart = backup.lightingSettings.FogStart
			Lighting.FogEnd = backup.lightingSettings.FogEnd
		end)
	end

	-- restore terrain
	if backup.terrain and workspace:FindFirstChildOfClass("Terrain") then
		pcall(function()
			local terr = workspace:FindFirstChildOfClass("Terrain")
			if backup.terrain.WaterWaveSize then terr.WaterWaveSize = backup.terrain.WaterWaveSize end
			if backup.terrain.WaterWaveSpeed then terr.WaterWaveSpeed = backup.terrain.WaterWaveSpeed end
		end)
	end

	-- clear backup so can reapply fresh next time
	getgenv()._FPSBoostBackup = {
		lights = {}, effects = {}, particles = {}, decals = {}, parts = {}, applied = false
	}
	print("[FPSBoost] Restored original settings.")
end

-- Utility: quick toggle
getgenv().applyBoost = applyBoost
getgenv().restoreBoost = restoreBoost

-- Auto-apply immediately
applyBoost()

--// GUI Spam Join Job ID (Tự động bật Spam)
-- Tác giả: Đào Nguyễn Minh Triết

local player = game.Players.LocalPlayer
local gui = Instance.new("ScreenGui")
gui.Name = "JoinJobGui"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

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
jobBox.PlaceholderText = "Nhập Job ID cần spam..."
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
