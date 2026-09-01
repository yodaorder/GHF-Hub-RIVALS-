--[[
	GHF Hub  -  RIVALS
	ESP | Combat | Fly | FPS Booster | Crosshair | Info HUD | Links
	Toggle window: Right Shift
	WARNING: Fly is high ban risk in RIVALS (permanent bans). Off by default.
]]

-- ============== LINKS (edit these to your own) ==============
local LINKS = {
	Discord = "https://discord.gg/mZRFmmQ3R",
	YouTube = "https://www.youtube.com/@RFLYoda",
	Script = "",
	RobloxGroup = "",
}
-- ============================================================

repeat task.wait() until game:IsLoaded() and game:GetService("Players").LocalPlayer

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local UIS = game:GetService("UserInputService")
local Stats = game:GetService("Stats")

local Player = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Persistent hub state (survives live-reload)
local GHF = getgenv().GHFHub or {}
getgenv().GHFHub = GHF

local function cleanupIntro()
	if GHF.Window then
		pcall(function()
			GHF.Window:Destroy()
		end)
	end
	GHF.Window = nil
	if GHF.conns then
		for _, c in ipairs(GHF.conns) do
			pcall(function()
				c:Disconnect()
			end)
		end
		GHF.conns = {}
	end
	if GHF.drawings then
		for _, d in ipairs(GHF.drawings) do
			pcall(function()
				d:Remove()
			end)
		end
		GHF.drawings = {}
	end
	GHF.running = false
end
cleanupIntro()

local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
local hubParent = gethui() or game:GetService("CoreGui")
if WindUI.SetParent then
	pcall(function()
		WindUI:SetParent(hubParent)
	end)
end

local Window = WindUI:CreateWindow({
	Title = "GHF Hub  |  RIVALS",
	Author = Player.DisplayName .. "  (" .. Player.Name .. ")",
	Icon = "solar:home-2-bold",
	Folder = "GHFHub",
	Size = UDim2.fromOffset(600, 480),
	NewElements = true,
	ToggleKey = Enum.KeyCode.RightShift,
	HideSearchBar = true,
	IgnoreAlerts = true,
	OpenButton = {
		Title = "Open GHF Hub",
		Icon = "home",
		CornerRadius = UDim.new(0, 16),
		StrokeThickness = 2,
		Color = ColorSequence.new(Color3.fromRGB(255, 72, 48), Color3.fromRGB(251, 155, 41)),
		OnlyMobile = false,
		Enabled = true,
		Draggable = true,
	},
})

GHF.Window = Window
GHF.running = true
GHF.drawings = GHF.drawings or {}
GHF.conns = GHF.conns or {}

local function track(d)
	table.insert(GHF.drawings, d)
	return d
end

local function connect(signal, fn)
	local c = signal:Connect(fn)
	table.insert(GHF.conns, c)
	return c
end

-- Best-effort mirror of the hub's open/close state (WindUI toggles on Right Shift),
-- so the triggerbot never holds click into the open UI.
local windowOpen = false
connect(UIS.InputBegan, function(input)
	if input.KeyCode == Enum.KeyCode.RightShift then
		windowOpen = not windowOpen
	end
end)

local function setQuality(v)
	pcall(function()
		sethiddenproperty(settings(), "RenderQualityLevel", v)
	end)
end

local function getQuality()
	local ok, v = pcall(function()
		return gethiddenproperty(settings(), "RenderQualityLevel")
	end)
	return ok and v or 0
end

-- ============ Config ============
local Config = {
	ESP = {
		Enabled = false,
		Boxes = true,
		Names = true,
		Health = true,
		Tracers = false,
		Distance = false,
		MaxDistance = 500,
		Color = Color3.fromRGB(255, 80, 80),
	},
	Triggerbot = {
		Enabled = false,
		Arm = "Always",
		FireRadius = 12,
		MaxDistance = 200,
	},
	Fly = {
		Enabled = false,
		Speed = 60,
	},
	FPS = {
		Enabled = false,
		Quality = 2,
		FpsCap = 240,
		NoShadows = true,
		Uncap = true,
		saved = nil,
	},
	Crosshair = {
		Enabled = false,
		Style = "Plus",
		Size = 8,
		Gap = 4,
		Thickness = 2,
		Color = Color3.fromRGB(0, 255, 0),
	},
	HUD = {
		Enabled = false,
		Ping = true,
		Fps = true,
		Players = true,
	},
}

local function notify(title, content, duration)
	pcall(function()
		WindUI:Notify({
			Title = title,
			Content = content,
			Duration = duration or 3.5,
		})
	end)
end

-- ============ Visuals ============
local VisualsTab = Window:Tab({ Title = "Visuals", Icon = "eye" })
local EspSection = VisualsTab:Section({ Title = "ESP", Icon = "scan-eye" })

EspSection:Toggle({
	Title = "Enable ESP",
	Value = false,
	Callback = function(v) Config.ESP.Enabled = v end,
})
EspSection:Space()
EspSection:Toggle({
	Title = "Boxes",
	Value = Config.ESP.Boxes,
	Callback = function(v) Config.ESP.Boxes = v end,
})
EspSection:Space()
EspSection:Toggle({
	Title = "Names",
	Value = Config.ESP.Names,
	Callback = function(v) Config.ESP.Names = v end,
})
EspSection:Space()
EspSection:Toggle({
	Title = "Health Bar",
	Value = Config.ESP.Health,
	Callback = function(v) Config.ESP.Health = v end,
})
EspSection:Space()
EspSection:Toggle({
	Title = "Tracers",
	Value = Config.ESP.Tracers,
	Callback = function(v) Config.ESP.Tracers = v end,
})
EspSection:Space()
EspSection:Toggle({
	Title = "Distance",
	Value = Config.ESP.Distance,
	Callback = function(v) Config.ESP.Distance = v end,
})
EspSection:Space()
EspSection:Slider({
	Title = "Max Distance",
	Step = 10,
	Value = { Min = 50, Max = 1000, Default = Config.ESP.MaxDistance },
	Callback = function(v) Config.ESP.MaxDistance = v end,
})
EspSection:Space()
EspSection:Colorpicker({
	Title = "Box Color",
	Default = Config.ESP.Color,
	Callback = function(v) Config.ESP.Color = v end,
})

-- ============ Combat / Triggerbot ============
local CombatTab = Window:Tab({ Title = "Combat", Icon = "crosshair" })
local TrigSection = CombatTab:Section({ Title = "Triggerbot", Icon = "crosshair" })

TrigSection:Toggle({
	Title = "Enable Triggerbot",
	Value = false,
	Callback = function(v) Config.Triggerbot.Enabled = v end,
})
TrigSection:Space()
TrigSection:Dropdown({
	Title = "Arm Mode",
	Values = { "Always", "While Holding Fire" },
	Value = "Always",
	Callback = function(v)
		if v == "While Holding Fire" then
			Config.Triggerbot.Arm = "While Holding Fire"
		else
			Config.Triggerbot.Arm = "Always"
		end
	end,
})
TrigSection:Space()
TrigSection:Slider({
	Title = "Fire Radius (px)",
	Step = 1,
	Value = { Min = 2, Max = 40, Default = Config.Triggerbot.FireRadius },
	Callback = function(v) Config.Triggerbot.FireRadius = v end,
})
TrigSection:Space()
TrigSection:Slider({
	Title = "Max Distance (studs)",
	Step = 10,
	Value = { Min = 50, Max = 400, Default = Config.Triggerbot.MaxDistance },
	Callback = function(v) Config.Triggerbot.MaxDistance = v end,
})
TrigSection:Space()
TrigSection:Button({
	Title = "Test Fire",
	Callback = function()
		if type(isrbxactive) == "function" and isrbxactive() then
			mouse1click()
			notify("Triggerbot", "Test shot fired (left click).")
		else
			notify("Triggerbot", "Roblox window not focused!", 3)
		end
	end,
})
TrigSection:Space()
TrigSection:Paragraph({
	Title = "How it works",
	Text = "Holds left click while an enemy's upper body is inside the fire radius. Never moves your mouse. Roblox window must be focused. Right click is never touched.",
})

-- ============ Fly ============
local FlyTab = Window:Tab({ Title = "Fly", Icon = "feather" })
local FlySection = FlyTab:Section({ Title = "Flight", Icon = "feather" })

FlySection:Toggle({
	Title = "Enable Fly",
	Value = false,
	Callback = function(v) Config.Fly.Enabled = v end,
})
FlySection:Space()
FlySection:Slider({
	Title = "Speed",
	Step = 5,
	Value = { Min = 10, Max = 300, Default = Config.Fly.Speed },
	Callback = function(v) Config.Fly.Speed = v end,
})

-- ============ FPS Booster ============
local BoostTab = Window:Tab({ Title = "Boost", Icon = "gauge" })
local BoostSection = BoostTab:Section({ Title = "FPS Booster", Icon = "gauge" })

BoostSection:Toggle({
	Title = "Enable Booster",
	Value = false,
	Callback = function(v) Config.FPS.Enabled = v end,
})
BoostSection:Space()
BoostSection:Slider({
	Title = "Graphics Quality",
	Step = 1,
	Value = { Min = 1, Max = 21, Default = Config.FPS.Quality },
	Callback = function(v) Config.FPS.Quality = v end,
})
BoostSection:Space()
BoostSection:Toggle({
	Title = "Disable Shadows",
	Value = Config.FPS.NoShadows,
	Callback = function(v) Config.FPS.NoShadows = v end,
})
BoostSection:Space()
BoostSection:Toggle({
	Title = "Raise FPS Cap",
	Value = Config.FPS.Uncap,
	Callback = function(v) Config.FPS.Uncap = v end,
})
BoostSection:Space()
BoostSection:Slider({
	Title = "FPS Cap",
	Step = 10,
	Value = { Min = 30, Max = 360, Default = Config.FPS.FpsCap },
	Callback = function(v) Config.FPS.FpsCap = v end,
})
BoostSection:Space()
BoostSection:Button({
	Title = "Reset Graphics",
	Justify = "Center",
	Icon = "",
	Callback = function()
		if Config.FPS.saved then
			setQuality(Config.FPS.saved.quality)
			pcall(function() Lighting.GlobalShadows = Config.FPS.saved.shadows end)
			Config.FPS.saved = nil
		end
		if type(setfpscap) == "function" then
			pcall(function() setfpscap(240) end)
		end
		Config.FPS.Enabled = false
		notify("Graphics Reset", "Original settings restored.")
	end,
})

-- ============ Crosshair ============
local CrosshairTab = Window:Tab({ Title = "Crosshair", Icon = "circle-dot" })
local ChSection = CrosshairTab:Section({ Title = "Crosshair", Icon = "circle-dot" })

ChSection:Toggle({
	Title = "Enable Crosshair",
	Value = false,
	Callback = function(v) Config.Crosshair.Enabled = v end,
})
ChSection:Space()
ChSection:Dropdown({
	Title = "Style",
	Values = { "Plus", "Circle", "Dot" },
	Value = "Plus",
	Callback = function(v) Config.Crosshair.Style = v end,
})
ChSection:Space()
ChSection:Slider({
	Title = "Size",
	Step = 1,
	Value = { Min = 2, Max = 40, Default = Config.Crosshair.Size },
	Callback = function(v) Config.Crosshair.Size = v end,
})
ChSection:Space()
ChSection:Slider({
	Title = "Gap",
	Step = 1,
	Value = { Min = 0, Max = 20, Default = Config.Crosshair.Gap },
	Callback = function(v) Config.Crosshair.Gap = v end,
})
ChSection:Space()
ChSection:Slider({
	Title = "Thickness",
	Step = 1,
	Value = { Min = 1, Max = 5, Default = Config.Crosshair.Thickness },
	Callback = function(v) Config.Crosshair.Thickness = v end,
})
ChSection:Space()
ChSection:Colorpicker({
	Title = "Color",
	Default = Config.Crosshair.Color,
	Callback = function(v) Config.Crosshair.Color = v end,
})

-- ============ Info HUD ============
local HudTab = Window:Tab({ Title = "HUD", Icon = "info" })
local HudSection = HudTab:Section({ Title = "Info HUD", Icon = "info" })

HudSection:Toggle({
	Title = "Enable HUD",
	Value = false,
	Callback = function(v) Config.HUD.Enabled = v end,
})
HudSection:Space()
HudSection:Toggle({
	Title = "Show Ping",
	Value = Config.HUD.Ping,
	Callback = function(v) Config.HUD.Ping = v end,
})
HudSection:Space()
HudSection:Toggle({
	Title = "Show FPS",
	Value = Config.HUD.Fps,
	Callback = function(v) Config.HUD.Fps = v end,
})
HudSection:Space()
HudSection:Toggle({
	Title = "Show Players",
	Value = Config.HUD.Players,
	Callback = function(v) Config.HUD.Players = v end,
})

-- ============ Links ============
local LinksTab = Window:Tab({ Title = "Links", Icon = "link" })
local LinksSection = LinksTab:Section({ Title = "GHF Community", Icon = "link" })

LinksSection:Paragraph({
	Title = "Copy a link to your clipboard",
	Desc = "Fill the LINKS table at the top of the script (ghf-hub.luau) then click below.",
	Image = "solar:link-bold",
	ImageSize = 40,
})

for name, url in pairs(LINKS) do
	if url and url ~= "" then
		LinksSection:Button({
			Title = "Copy " .. name,
			Icon = "copy",
			Callback = function()
				setclipboard(url)
				notify(name .. " copied", url)
			end,
		})
		LinksSection:Space()
	end
end

LinksSection:Button({
	Title = "Copy Username",
	Icon = "user",
	Callback = function()
		setclipboard(Player.Name)
		notify("Username copied", Player.Name)
	end,
})
LinksSection:Space()
LinksSection:Button({
	Title = "Copy User ID",
	Icon = "hash",
	Callback = function()
		setclipboard(tostring(Player.UserId))
		notify("User ID copied", tostring(Player.UserId))
	end,
})

-- ============ Settings ============
local SettingsTab = Window:Tab({ Title = "Settings", Icon = "settings" })
local SettingsSection = SettingsTab:Section({ Title = "Settings", Icon = "settings" })

SettingsSection:Slider({
	Title = "UI Scale",
	Step = 0.05,
	Value = { Min = 0.5, Max = 1.5, Default = 1 },
	Callback = function(v)
		pcall(function()
			Window:SetUIScale(v)
		end)
	end,
})
SettingsSection:Space()
SettingsSection:Button({
	Title = "Destroy GHF Hub",
	Color = Color3.fromHex("#ff4830"),
	Icon = "shredder",
	Justify = "Center",
	Callback = function()
		cleanupIntro()
	end,
})

-- ============ Drawing helpers ============
local FONT_MONO = Drawing.Fonts.Monospace

local function projectCharacter(ch, cam)
	local hrp = ch:FindFirstChild("HumanoidRootPart")
	local head = ch:FindFirstChild("Head")
	if not hrp then return false end
	local size = hrp.Size
	local base = hrp.Position
	local top = head and head.Position or base + Vector3.new(0, size.Y / 2 + 1, 0)
	local x = size.X / 2
	local z = size.Z / 2
	local y0 = base.Y - size.Y / 2
	local corners = {
		Vector3.new(base.X - x, y0, base.Z - z),
		Vector3.new(base.X + x, y0, base.Z - z),
		Vector3.new(base.X + x, y0, base.Z + z),
		Vector3.new(base.X - x, y0, base.Z + z),
		Vector3.new(top.X - x, top.Y, top.Z - z),
		Vector3.new(top.X + x, top.Y, top.Z - z),
		Vector3.new(top.X + x, top.Y, top.Z + z),
		Vector3.new(top.X - x, top.Y, top.Z + z),
	}
	local minx, maxx, miny, maxy = 1e9, -1e9, 1e9, -1e9
	local behind = false
	for _, c in ipairs(corners) do
		local sp = cam:WorldToViewportPoint(c)
		if sp.Z < 0 then behind = true end
		minx = math.min(minx, sp.X)
		maxx = math.max(maxx, sp.X)
		miny = math.min(miny, sp.Y)
		maxy = math.max(maxy, sp.Y)
	end
	if behind then return false end
	if maxx - minx < 4 then return false end
	return true, minx, maxx, miny, maxy
end

local function makeEspSet()
	local lines = {
		track(Drawing.new("Line")),
		track(Drawing.new("Line")),
		track(Drawing.new("Line")),
		track(Drawing.new("Line")),
	}
	local tracer = track(Drawing.new("Line"))
	local name = track(Drawing.new("Text"))
	local dist = track(Drawing.new("Text"))
	local barBg = track(Drawing.new("Square"))
	local barFg = track(Drawing.new("Square"))
	name.Font = FONT_MONO
	dist.Font = FONT_MONO
	name.Size = 14
	dist.Size = 10
	name.Center = true
	dist.Center = false
	name.Outline = true
	name.OutlineColor = Color3.new(0, 0, 0)
	dist.Outline = true
	dist.OutlineColor = Color3.new(0, 0, 0)
	barBg.Filled = true
	barFg.Filled = true
	return { lines = lines, tracer = tracer, name = name, dist = dist, barBg = barBg, barFg = barFg }
end

local function hideEspSet(set)
	for _, d in ipairs(set.lines) do d.Visible = false end
	set.tracer.Visible = false
	set.name.Visible = false
	set.dist.Visible = false
	set.barBg.Visible = false
	set.barFg.Visible = false
end

-- ============ Crosshair drawing ============
local chLines = {
	track(Drawing.new("Line")),
	track(Drawing.new("Line")),
	track(Drawing.new("Line")),
	track(Drawing.new("Line")),
}
local chCircle = track(Drawing.new("Circle"))
local chDot = track(Drawing.new("Square"))

local tbLabel = track(Drawing.new("Text"))
tbLabel.Font = FONT_MONO
tbLabel.Size = 14
tbLabel.Outline = true
tbLabel.OutlineColor = Color3.new(0, 0, 0)
tbLabel.Center = true

local function renderCrosshair()
	local enabled = Config.Crosshair.Enabled
	if not enabled then
		for _, l in ipairs(chLines) do l.Visible = false end
		chCircle.Visible = false
		chDot.Visible = false
		return
	end
	local m = UIS:GetMouseLocation()
	local size = Config.Crosshair.Size
	local gap = Config.Crosshair.Gap
	local th = Config.Crosshair.Thickness
	local col = Config.Crosshair.Color
	local style = Config.Crosshair.Style

	if style == "Plus" then
		local h2 = th / 2
		local corners = {
			{ Vector2.new(m.X - gap - size, m.Y - h2), Vector2.new(m.X - gap, m.Y - h2) },
			{ Vector2.new(m.X + gap, m.Y - h2), Vector2.new(m.X + gap + size, m.Y - h2) },
			{ Vector2.new(m.X - h2, m.Y - gap - size), Vector2.new(m.X - h2, m.Y - gap) },
			{ Vector2.new(m.X - h2, m.Y + gap), Vector2.new(m.X - h2, m.Y + gap + size) },
		}
		for i, l in ipairs(chLines) do
			l.From = corners[i][1]
			l.To = corners[i][2]
			l.Color = col
			l.Thickness = th
			l.Visible = true
		end
		chCircle.Visible = false
		chDot.Visible = false
	elseif style == "Circle" then
		for _, l in ipairs(chLines) do l.Visible = false end
		chDot.Visible = false
		chCircle.Position = m
		chCircle.Radius = size
		chCircle.Color = col
		chCircle.Thickness = th
		chCircle.Filled = false
		chCircle.Visible = true
	else
		for _, l in ipairs(chLines) do l.Visible = false end
		chCircle.Visible = false
		chDot.Position = Vector2.new(m.X - size / 2, m.Y - size / 2)
		chDot.Size = Vector2.new(size, size)
		chDot.Color = col
		chDot.Filled = true
		chDot.Visible = true
	end
end

-- ============ HUD text ============
local hudTexts = {
	track(Drawing.new("Text")),
	track(Drawing.new("Text")),
	track(Drawing.new("Text")),
}
for _, t in ipairs(hudTexts) do
	t.Font = FONT_MONO
	t.Size = 14
	t.Outline = true
	t.OutlineColor = Color3.new(0, 0, 0)
	t.Position = Vector2.new(8, 8)
end
hudTexts[2].Position = Vector2.new(8, 26)
hudTexts[3].Position = Vector2.new(8, 44)

local function renderHUD(fps, ping)
	local on = Config.HUD.Enabled
	if not on then
		for _, t in ipairs(hudTexts) do t.Visible = false end
		return
	end
	local lines = {}
	if Config.HUD.Fps then lines[#lines + 1] = "FPS: " .. tostring(math.floor(fps + 0.5)) end
	if Config.HUD.Ping then lines[#lines + 1] = "Ping: " .. tostring(ping) .. " ms" end
	if Config.HUD.Players then lines[#lines + 1] = "Players: " .. tostring(#Players:GetPlayers()) end
	for i, t in ipairs(hudTexts) do
		t.Visible = i <= #lines
		if i <= #lines then t.Text = lines[i] end
	end
end

-- ============ FPS Booster ============
local function syncFPS()
	if Config.FPS.Enabled then
		if not Config.FPS.saved then
			Config.FPS.saved = {}
			Config.FPS.saved.quality = getQuality()
			pcall(function() Config.FPS.saved.shadows = Lighting.GlobalShadows end)
		end
		setQuality(Config.FPS.Quality)
		if Config.FPS.NoShadows then
			pcall(function() Lighting.GlobalShadows = false end)
		end
		if Config.FPS.Uncap and type(setfpscap) == "function" then
			pcall(function() setfpscap(Config.FPS.FpsCap) end)
		end
	elseif Config.FPS.saved then
		setQuality(Config.FPS.saved.quality)
		pcall(function() Lighting.GlobalShadows = Config.FPS.saved.shadows end)
		if Config.FPS.Uncap and type(setfpscap) == "function" then
			pcall(function() setfpscap(240) end)
		end
		Config.FPS.saved = nil
	end
end

local function fpsSignature()
	return table.concat({
		tostring(Config.FPS.Enabled),
		tostring(Config.FPS.Quality),
		tostring(Config.FPS.NoShadows),
		tostring(Config.FPS.Uncap),
		tostring(Config.FPS.FpsCap),
	}, "|")
end

local function getPing()
	local ok, v = pcall(function()
		return Stats.Network.ServerStats["Data Ping"]:GetValue()
	end)
	return ok and v or 0
end

-- ============ Main loop ============
local espSets = {}
local frameCount, lastT, fps = 0, tick(), 0
local hudPing = 0
local lastSig

connect(RunService.RenderStepped, function()
	if not GHF.running then return end

	Camera = workspace.CurrentCamera or Camera
	if not Camera then return end
	local cam = Camera
	local camPos = cam.CFrame.Position
	local center = cam.ViewportSize / 2

	frameCount += 1
	local nowT = tick()
	if nowT - lastT >= 0.5 then
		fps = frameCount / (nowT - lastT)
		frameCount = 0
		lastT = nowT
		hudPing = getPing()
	end

	local sig = fpsSignature()
	if sig ~= lastSig then
		syncFPS()
		lastSig = sig
	end

	for p, set in pairs(espSets) do
		if not Config.ESP.Enabled then
			hideEspSet(set)
		end
	end

	if Config.ESP.Enabled then
		local px, py = cam.ViewportSize.X, cam.ViewportSize.Y
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= Player then
				local ch = p.Character
				if ch then
					local hum = ch:FindFirstChildOfClass("Humanoid")
					local hrp = ch:FindFirstChild("HumanoidRootPart")
					if hum and hrp and hum.Health > 0 then
						local dist = (camPos - hrp.Position).Magnitude
						if dist <= Config.ESP.MaxDistance then
							local set = espSets[p]
							if not set then
								set = makeEspSet()
								espSets[p] = set
							end
							local ok, minx, maxx, miny, maxy = projectCharacter(ch, cam)
							if ok then
								local w = maxx - minx
								local col = Config.ESP.Color
								local tl = Vector2.new(minx, miny)
								local tr = Vector2.new(maxx, miny)
								local bl = Vector2.new(minx, maxy)
								local br = Vector2.new(maxx, maxy)
								local on = Config.ESP.Boxes
								set.lines[1].From, set.lines[1].To, set.lines[1].Color, set.lines[1].Thickness, set.lines[1].Visible = tl, tr, col, 1, on
								set.lines[2].From, set.lines[2].To, set.lines[2].Color, set.lines[2].Thickness, set.lines[2].Visible = tr, br, col, 1, on
								set.lines[3].From, set.lines[3].To, set.lines[3].Color, set.lines[3].Thickness, set.lines[3].Visible = br, bl, col, 1, on
								set.lines[4].From, set.lines[4].To, set.lines[4].Color, set.lines[4].Thickness, set.lines[4].Visible = bl, tl, col, 1, on

								if Config.ESP.Names then
									set.name.Text = p.Name
									set.name.Position = Vector2.new(minx + w / 2, miny - 16)
									set.name.Color = Color3.new(1, 1, 1)
									set.name.Visible = true
								else
									set.name.Visible = false
								end

								if Config.ESP.Health then
									local hRatio = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
									set.barBg.Position = Vector2.new(minx, miny - 5)
									set.barBg.Size = Vector2.new(w, 3)
									set.barBg.Color = Color3.new(0, 0, 0)
									set.barBg.Visible = true
									set.barFg.Position = Vector2.new(minx, miny - 5)
									set.barFg.Size = Vector2.new(w * hRatio, 3)
									set.barFg.Color = Color3.fromHSV(hRatio * 0.333, 1, 1)
									set.barFg.Visible = true
								else
									set.barBg.Visible = false
									set.barFg.Visible = false
								end

								if Config.ESP.Tracers then
									set.tracer.From = Vector2.new(px / 2, py)
									set.tracer.To = Vector2.new(minx + w / 2, maxy)
									set.tracer.Color = col
									set.tracer.Thickness = 1
									set.tracer.Visible = true
								else
									set.tracer.Visible = false
								end

								if Config.ESP.Distance then
									set.dist.Text = tostring(math.floor(dist)) .. " studs"
									set.dist.Position = Vector2.new(minx + w / 2, maxy + 2)
									set.dist.Center = true
									set.dist.Color = Color3.new(1, 1, 1)
									set.dist.Visible = true
								else
									set.dist.Visible = false
								end
							else
								hideEspSet(set)
							end
						else
							if espSets[p] then hideEspSet(espSets[p]) end
						end
					else
						if espSets[p] then hideEspSet(espSets[p]) end
					end
				else
					if espSets[p] then hideEspSet(espSets[p]) end
				end
			end
		end
	end

	if Config.Triggerbot.Enabled then
		local tb = Config.Triggerbot
		local active = type(isrbxactive) ~= "function" or isrbxactive()
		local armed = tb.Arm == "Always"
			or (tb.Arm == "While Holding Fire" and UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1))
		local fire = false
		local best
		local nearestAny
		local nCand = 0
		if armed and not windowOpen and active then
			local candidates = {}
			for _, p in ipairs(Players:GetPlayers()) do
				if p ~= Player and p.Character then
					local ch = p.Character
					local hum = ch:FindFirstChildOfClass("Humanoid")
					local hrp = ch:FindFirstChild("HumanoidRootPart")
					if hum and hrp and hum.Health > 0 then
						candidates[#candidates + 1] = ch
					end
				end
			end
			-- RIVALS firing-range dummies are NPC rigs, not Players.
			local range = workspace:FindFirstChild("ShootingRangeEntities")
			if range then
				for _, ch in ipairs(range:GetChildren()) do
					local hum = ch:FindFirstChildOfClass("Humanoid")
					local hrp = ch:FindFirstChild("HumanoidRootPart")
					if hum and hrp and hum.Health > 0 then
						candidates[#candidates + 1] = ch
					end
				end
			end
			nCand = #candidates
			for _, ch in ipairs(candidates) do
				local hrp = ch:FindFirstChild("HumanoidRootPart")
				if (camPos - hrp.Position).Magnitude <= tb.MaxDistance then
					local parts = { ch:FindFirstChild("Head"), hrp }
					for _, part in ipairs(parts) do
						if part then
							local sp = cam:WorldToViewportPoint(part.Position)
							if sp.Z > 0 then
								local dx = sp.X - center.X
								local dy = sp.Y - center.Y
								local sd = math.sqrt(dx * dx + dy * dy)
								if not nearestAny or sd < nearestAny then
									nearestAny = sd
								end
								if sd <= tb.FireRadius and (not best or sd < best) then
									best = sd
								end
							end
						end
					end
				end
			end
			fire = best ~= nil
		end
		if fire then
			mouse1press()
		else
			mouse1release()
		end

		-- Live status + diagnostics for testing remote
		GHF.tb = GHF.tb or {}
		GHF.tb.en = true
		GHF.tb.windowOpen = windowOpen
		GHF.tb.active = active
		GHF.tb.armed = armed
		GHF.tb.best = best
		GHF.tb.nearestAny = nearestAny
		GHF.tb.nCand = nCand
		GHF.tb.fire = fire
		GHF.tb.t = tick()

		local state = "T-BOT"
		if not active then
			state = state .. " | NO FOCUS"
		elseif windowOpen then
			state = state .. " | WINDOW OPEN"
		elseif not armed then
			state = state .. " | NOT ARMED"
		elseif nCand == 0 then
			state = state .. " | NO TARGETS (" .. (tb.MaxDistance) .. "s)"
		else
			state = state .. (fire and " | FIRING" or (" | nearest " .. math.floor(nearestAny or 9999) .. "px"))
		end
		tbLabel.Text = state
		tbLabel.Position = Vector2.new(center.X, cam.ViewportSize.Y - 30)
		tbLabel.Color = fire and Color3.fromRGB(80, 255, 120) or Color3.fromRGB(200, 200, 200)
		tbLabel.Visible = true
	else
		tbLabel.Visible = false
		GHF.tb = GHF.tb or {}
		GHF.tb.en = false
	end

	if Config.Fly.Enabled then
		local char = Player.Character
		if char then
			local hrp = char:FindFirstChild("HumanoidRootPart")
			local hum = char:FindFirstChildOfClass("Humanoid")
			if hrp then
				local cf = cam.CFrame
				local move = Vector3.zero
				-- face where the camera is looking
				local flat = cam.CFrame.LookVector
				flat = Vector3.new(flat.X, 0, flat.Z)
				if flat.Magnitude > 0.001 then
					flat = flat.Unit
					local target = CFrame.lookAt(hrp.Position, hrp.Position + flat)
					hrp.CFrame = target
					if hum then
						pcall(function()
							hum:ChangeState(Enum.HumanoidStateType.Flying)
						end)
					end
				end
				if UIS:IsKeyDown(Enum.KeyCode.W) then move = move - cf.LookVector end
				if UIS:IsKeyDown(Enum.KeyCode.S) then move = move + cf.LookVector end
				if UIS:IsKeyDown(Enum.KeyCode.A) then move = move - cf.RightVector end
				if UIS:IsKeyDown(Enum.KeyCode.D) then move = move + cf.RightVector end
				if UIS:IsKeyDown(Enum.KeyCode.Space) then move = move + Vector3.new(0, 1, 0) end
				if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then move = move - Vector3.new(0, 1, 0) end
				if move.Magnitude > 0 then move = move.Unit end
				local vel = move * Config.Fly.Speed
				hrp.Velocity = vel
				hrp.AssemblyLinearVelocity = vel
				if hum then
					pcall(function()
						hum:ChangeState(Enum.HumanoidStateType.Flying)
					end)
				end
			end
		end
	end

	renderCrosshair()
	renderHUD(fps, hudPing)
end)

notify("GHF Hub loaded", "Right Shift toggles the window. ESP / Triggerbot / Fly are OFF by default.", 4)
print("GHF Hub loaded. Toggle key: Right Shift")
