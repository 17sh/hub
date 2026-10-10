--[[ Training Hub : ออกแบบสำหรับแท็บเล็ต (Delta) ]]
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local LP = Players.LocalPlayer

local G = (getgenv and getgenv()) or _G
if G.HUBX_UNLOAD then pcall(G.HUBX_UNLOAD) end
if G.AC_STOP then pcall(G.AC_STOP) end

local alive, conns, cleanups = true, {}, {}
local function track(c) conns[#conns + 1] = c; return c end
local function onCleanup(fn) cleanups[#cleanups + 1] = fn end

-- ===== หน้าจอหลัก + แถบสถานะ =====
local gui = Instance.new("ScreenGui")
gui.Name = "HUBX"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true; gui.DisplayOrder = 2000
local mounted = false
for _, get in ipairs({
	function() return LP:WaitForChild("PlayerGui", 5) end,
	function() return gethui and gethui() end,
	function() return game:GetService("CoreGui") end,
}) do
	local okp, parent = pcall(get)
	if okp and parent then
		pcall(function() local o = parent:FindFirstChild("HUBX"); if o then o:Destroy() end end)
		if pcall(function() gui.Parent = parent end) and gui.Parent then mounted = true break end
	end
end
if not mounted then return end

local bar = Instance.new("TextLabel", gui)
bar.Size = UDim2.new(1, 0, 0, 70); bar.Position = UDim2.new(0, 0, 1, -70)
bar.BackgroundColor3 = Color3.fromRGB(168, 85, 247); bar.TextColor3 = Color3.new(1, 1, 1)
bar.TextSize = 18; bar.TextWrapped = true; bar.ZIndex = 100; bar.Text = "Training Hub กำลังโหลด..."

local failed = false
local function coreStage(name, fn)
	if failed then return end
	bar.Text = "กำลังสร้าง: " .. name
	local ok, e = pcall(fn)
	if not ok then
		failed = true
		bar.Text = "พังที่ขั้น '" .. name .. "':\n" .. tostring(e)
		print("[Hub] พังที่ " .. name .. ": " .. tostring(e))
	end
	task.wait()
end

-- ===== ธีม + ตัวช่วย UI =====
local T = {
	bg = Color3.fromRGB(15, 14, 22), side = Color3.fromRGB(21, 20, 31), card = Color3.fromRGB(29, 28, 42),
	card2 = Color3.fromRGB(44, 42, 62), text = Color3.fromRGB(240, 238, 250), sub = Color3.fromRGB(150, 146, 175),
	accent = Color3.fromRGB(168, 85, 247), good = Color3.fromRGB(74, 222, 128), bad = Color3.fromRGB(248, 113, 113),
}
local WHITE = Color3.new(1, 1, 1)
local accentFns = {}
local function onAccent(fn) accentFns[#accentFns + 1] = fn; pcall(fn, T.accent) end
local function setAccent(c) T.accent = c; for _, f in ipairs(accentFns) do pcall(f, c) end end

local function new(c, p, par)
	local o = Instance.new(c)
	for k, v in pairs(p or {}) do o[k] = v end
	if par then o.Parent = par end
	return o
end
local function corner(o, r) return new("UICorner", {CornerRadius = UDim.new(0, r or 8)}, o) end
local function pad(o, t, b, l, r)
	return new("UIPadding", {PaddingTop = UDim.new(0, t), PaddingBottom = UDim.new(0, b),
		PaddingLeft = UDim.new(0, l), PaddingRight = UDim.new(0, r)}, o)
end

local SUF = {"", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc"}
local function fmt(n)
	if type(n) ~= "number" then return "-" end
	local neg = n < 0
	n = math.abs(n)
	local i = 1
	while n >= 1000 and i < #SUF do n = n / 1000; i = i + 1 end
	local s
	if i == 1 then s = string.format("%d", math.floor(n)) else s = string.format("%.2f", n) end
	return (neg and "-" or "") .. s .. SUF[i]
end
local function tfmt(sec)
	sec = math.max(0, math.floor(sec))
	return string.format("%d:%02d:%02d", math.floor(sec / 3600), math.floor(sec % 3600 / 60), sec % 60)
end

local toastHolder
local function toast(msg, col)
	if not toastHolder then return end
	local l = new("TextLabel", {Size = UDim2.new(1, 0, 0, 40), BackgroundColor3 = T.card2, TextColor3 = T.text,
		Text = "  " .. tostring(msg), TextSize = 15, Font = Enum.Font.GothamMedium, TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left}, toastHolder)
	corner(l, 10)
	new("Frame", {Size = UDim2.new(0, 4, 1, -12), Position = UDim2.fromOffset(4, 6), BackgroundColor3 = col or T.accent}, l)
	task.delay(3.2, function() pcall(function() l:Destroy() end) end)
end

local function makeDraggable(handle, target)
	local dragging, startIn, startPos = false, nil, nil
	track(handle.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true; startIn = i.Position; startPos = target.Position
		end
	end))
	track(UIS.InputChanged:Connect(function(i)
		if dragging and (i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseMovement) then
			local d = i.Position - startIn
			target.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
		end
	end))
	track(UIS.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
	end))
end

-- ===== โครงหน้าต่างและแท็บ =====
local win, orb, pages, tabBtns, selectedTab = nil, nil, {}, {}, nil
local sideList, body

local function repaintTabs()
	for id, b in pairs(tabBtns) do
		if id == selectedTab then b.BackgroundColor3 = T.accent; b.TextColor3 = WHITE
		else b.BackgroundColor3 = T.side; b.TextColor3 = T.sub end
	end
end
local function selectTab(id)
	selectedTab = id
	for k, p in pairs(pages) do p.Visible = (k == id) end
	repaintTabs()
end
local function addTab(id, icon, name)
	local b = new("TextButton", {Size = UDim2.new(1, 0, 0, 46), BackgroundColor3 = T.side, Text = icon .. "   " .. name,
		TextColor3 = T.sub, Font = Enum.Font.GothamBold, TextSize = 15, TextXAlignment = Enum.TextXAlignment.Left,
		AutoButtonColor = false}, sideList)
	corner(b, 10); pad(b, 0, 0, 14, 0)
	local p = new("ScrollingFrame", {Size = UDim2.new(1, -16, 1, -16), Position = UDim2.fromOffset(8, 8),
		BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 5, CanvasSize = UDim2.new(), Visible = false}, body)
	local lay = new("UIListLayout", {Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder}, p)
	track(lay:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		p.CanvasSize = UDim2.new(0, 0, 0, lay.AbsoluteContentSize.Y + 16)
	end))
	tabBtns[id] = b; pages[id] = p
	b.MouseButton1Click:Connect(function() selectTab(id) end)
	return p
end

-- ===== คอมโพเนนต์ =====
local function Card(page, title, desc, rightW)
	rightW = rightW or 150
	local f = new("Frame", {Size = UDim2.new(1, -8, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = T.card}, page)
	corner(f, 12); pad(f, 10, 10, 14, 14)
	new("UIListLayout", {Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder}, f)
	local top = new("Frame", {Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1, LayoutOrder = 1}, f)
	new("TextLabel", {Size = UDim2.new(1, -rightW, 1, 0), BackgroundTransparency = 1, Text = title, TextColor3 = T.text,
		Font = Enum.Font.GothamBold, TextSize = 16, TextXAlignment = Enum.TextXAlignment.Left}, top)
	if desc and desc ~= "" then
		new("TextLabel", {Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1,
			Text = desc, TextColor3 = T.sub, Font = Enum.Font.Gotham, TextSize = 13, TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = 2}, f)
	end
	return f, top
end

local function Section(page, text)
	local l = new("TextLabel", {Size = UDim2.new(1, -8, 0, 26), BackgroundTransparency = 1, Text = text,
		Font = Enum.Font.GothamBold, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left}, page)
	onAccent(function(c) l.TextColor3 = c end)
end

local function Toggle(page, title, desc, default, cb)
	local f, top = Card(page, title, desc, 70)
	local sw = new("TextButton", {Size = UDim2.fromOffset(52, 28), Position = UDim2.new(1, -52, 0.5, -14), Text = "",
		AutoButtonColor = false}, top)
	corner(sw, 14)
	local knob = new("Frame", {Size = UDim2.fromOffset(22, 22), Position = UDim2.fromOffset(3, 3), BackgroundColor3 = WHITE}, sw)
	corner(knob, 11)
	local state = default and true or false
	local function paint(anim)
		local col = state and T.accent or T.card2
		local pos = state and UDim2.fromOffset(27, 3) or UDim2.fromOffset(3, 3)
		if anim then
			TweenService:Create(sw, TweenInfo.new(0.15), {BackgroundColor3 = col}):Play()
			TweenService:Create(knob, TweenInfo.new(0.15), {Position = pos}):Play()
		else
			sw.BackgroundColor3 = col; knob.Position = pos
		end
	end
	onAccent(function() paint(false) end)
	sw.MouseButton1Click:Connect(function() state = not state; paint(true); task.spawn(cb, state) end)
	paint(false)
	return {set = function(v) state = v and true or false; paint(true); task.spawn(cb, state) end, get = function() return state end}
end

local function Button(page, title, desc, label, cb, col)
	local f, top = Card(page, title, desc, 150)
	local b = new("TextButton", {Size = UDim2.fromOffset(130, 30), Position = UDim2.new(1, -130, 0.5, -15),
		BackgroundColor3 = col or T.accent, Text = label, TextColor3 = WHITE, Font = Enum.Font.GothamBold, TextSize = 14}, top)
	corner(b, 8)
	if not col then onAccent(function(c) b.BackgroundColor3 = c end) end
	b.MouseButton1Click:Connect(function() task.spawn(cb) end)
	return b
end

local function Button2(page, title, desc, l1, cb1, l2, cb2)
	local f, top = Card(page, title, desc, 270)
	local function mk(x, label, cb, c)
		local b = new("TextButton", {Size = UDim2.fromOffset(124, 30), Position = UDim2.new(1, x, 0.5, -15),
			BackgroundColor3 = c or T.card2, Text = label, TextColor3 = WHITE, Font = Enum.Font.GothamBold, TextSize = 14}, top)
		corner(b, 8)
		b.MouseButton1Click:Connect(function() task.spawn(cb) end)
		return b
	end
	local b1 = mk(-262, l1, cb1, T.card2)
	local b2 = mk(-130, l2, cb2, T.accent)
	onAccent(function(c) b2.BackgroundColor3 = c end)
end

local function Stat(page, title)
	local f, top = Card(page, title, nil, 290)
	local v = new("TextLabel", {Size = UDim2.new(0, 280, 1, 0), Position = UDim2.new(1, -280, 0, 0), BackgroundTransparency = 1,
		Text = "-", Font = Enum.Font.GothamBold, TextSize = 17, TextXAlignment = Enum.TextXAlignment.Right}, top)
	onAccent(function(c) v.TextColor3 = c end)
	return function(t) v.Text = tostring(t) end
end

local function Slider(page, title, desc, min, max, default, step, cb)
	local f, top = Card(page, title, desc, 120)
	local valLbl = new("TextLabel", {Size = UDim2.new(0, 110, 1, 0), Position = UDim2.new(1, -110, 0, 0), BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold, TextSize = 16, TextXAlignment = Enum.TextXAlignment.Right}, top)
	onAccent(function(c) valLbl.TextColor3 = c end)
	local row = new("Frame", {Size = UDim2.new(1, 0, 0, 32), BackgroundTransparency = 1, LayoutOrder = 3}, f)
	local value = default
	local bar2 = new("Frame", {Size = UDim2.new(1, -90, 0, 8), Position = UDim2.new(0, 45, 0.5, -4), BackgroundColor3 = T.card2}, row)
	corner(bar2, 4)
	local fill = new("Frame", {Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = T.accent}, bar2)
	corner(fill, 4)
	onAccent(function(c) fill.BackgroundColor3 = c end)
	local hit = new("TextButton", {Size = UDim2.new(1, 0, 1, 20), Position = UDim2.new(0, 0, 0, -10), BackgroundTransparency = 1,
		Text = ""}, bar2)
	local function apply(v, fire)
		v = math.clamp(math.floor(v / step + 0.5) * step, min, max)
		value = v
		valLbl.Text = (step < 1) and string.format("%.1f", v) or tostring(v)
		fill.Size = UDim2.new((v - min) / (max - min), 0, 1, 0)
		if fire then task.spawn(cb, v) end
	end
	local function mkStep(txt, x, d)
		local b = new("TextButton", {Size = UDim2.fromOffset(34, 30), Position = UDim2.new(0, x, 0, 1), BackgroundColor3 = T.card2,
			Text = txt, TextColor3 = WHITE, Font = Enum.Font.GothamBold, TextSize = 18}, row)
		corner(b, 8)
		b.MouseButton1Click:Connect(function() apply(value + d * step, true) end)
	end
	mkStep("–", 0, -1)
	local plus = new("TextButton", {Size = UDim2.fromOffset(34, 30), Position = UDim2.new(1, -34, 0, 1), BackgroundColor3 = T.card2,
		Text = "+", TextColor3 = WHITE, Font = Enum.Font.GothamBold, TextSize = 18}, row)
	corner(plus, 8)
	plus.MouseButton1Click:Connect(function() apply(value + step, true) end)
	local dragging = false
	local function fromX(x)
		local rel = math.clamp((x - bar2.AbsolutePosition.X) / math.max(1, bar2.AbsoluteSize.X), 0, 1)
		apply(min + (max - min) * rel, true)
	end
	hit.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true; page.ScrollingEnabled = false; fromX(i.Position.X)
		end
	end)
	track(UIS.InputChanged:Connect(function(i)
		if dragging and (i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseMovement) then fromX(i.Position.X) end
	end))
	track(UIS.InputEnded:Connect(function(i)
		if dragging and (i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1) then
			dragging = false; page.ScrollingEnabled = true
		end
	end))
	apply(default, false)
	return {set = function(v) apply(v, false) end}
end

local function Input(page, title, desc, default, cb)
	local f, top = Card(page, title, desc, 240)
	local box = new("TextBox", {Size = UDim2.fromOffset(220, 30), Position = UDim2.new(1, -220, 0.5, -15), BackgroundColor3 = T.card2,
		TextColor3 = T.text, PlaceholderColor3 = T.sub, Font = Enum.Font.Gotham, TextSize = 14, Text = default or "",
		ClearTextOnFocus = false}, top)
	corner(box, 8)
	box.FocusLost:Connect(function() cb(box.Text) end)
	return box
end

local function ListBox(page)
	local f = new("Frame", {Size = UDim2.new(1, -8, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1}, page)
	new("UIListLayout", {Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder}, f)
	return f
end
local function clearList(f)
	for _, c in ipairs(f:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
end
local function Row(list, text, sub, buttons)
	local r = new("Frame", {Size = UDim2.new(1, 0, 0, 52), BackgroundColor3 = T.card}, list)
	corner(r, 10)
	local w = #buttons * 76 + 8
	new("TextLabel", {Size = UDim2.new(1, -w - 14, 0, 24), Position = UDim2.fromOffset(12, 6), BackgroundTransparency = 1, Text = text,
		TextColor3 = T.text, Font = Enum.Font.GothamBold, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd}, r)
	new("TextLabel", {Size = UDim2.new(1, -w - 14, 0, 18), Position = UDim2.fromOffset(12, 28), BackgroundTransparency = 1, Text = sub or "",
		TextColor3 = T.sub, Font = Enum.Font.Gotham, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd}, r)
	local made = {}
	for i, bd in ipairs(buttons) do
		local b = new("TextButton", {Size = UDim2.fromOffset(68, 32), Position = UDim2.new(1, -(#buttons - i + 1) * 76 + 4, 0.5, -16),
			BackgroundColor3 = bd.color or T.card2, Text = bd.text, TextColor3 = WHITE, Font = Enum.Font.GothamBold, TextSize = 13}, r)
		corner(b, 8)
		b.MouseButton1Click:Connect(function() task.spawn(bd.cb, b) end)
		made[i] = b
	end
	return r, made
end

-- ===== ขั้นที่ 1: หน้าต่างหลัก =====
coreStage("หน้าต่างหลัก", function()
	toastHolder = new("Frame", {Size = UDim2.fromOffset(380, 300), Position = UDim2.new(0.5, -190, 0, 10),
		BackgroundTransparency = 1, ZIndex = 50}, gui)
	new("UIListLayout", {Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder}, toastHolder)

	win = new("Frame", {Name = "Win", Size = UDim2.new(0.66, 0, 0.82, 0), AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.53, 0), BackgroundColor3 = T.bg, ClipsDescendants = true}, gui)
	new("UISizeConstraint", {MinSize = Vector2.new(360, 260), MaxSize = Vector2.new(1500, 900)}, win)
	corner(win, 16)
	local st = new("UIStroke", {Thickness = 1.5, Transparency = 0.5}, win)
	onAccent(function(c) st.Color = c end)

	local tb = new("Frame", {Size = UDim2.new(1, 0, 0, 52), BackgroundColor3 = T.side}, win)
	new("TextLabel", {Size = UDim2.new(1, -140, 1, 0), Position = UDim2.fromOffset(18, 0), BackgroundTransparency = 1,
		Text = "⚔  Training Hub", TextColor3 = T.text, Font = Enum.Font.GothamBold, TextSize = 19,
		TextXAlignment = Enum.TextXAlignment.Left}, tb)
	local line = new("Frame", {Size = UDim2.new(1, 0, 0, 2), Position = UDim2.new(0, 0, 1, -2)}, tb)
	onAccent(function(c) line.BackgroundColor3 = c end)
	local minB = new("TextButton", {Size = UDim2.fromOffset(40, 34), Position = UDim2.new(1, -92, 0.5, -17), BackgroundColor3 = T.card2,
		Text = "–", TextColor3 = WHITE, Font = Enum.Font.GothamBold, TextSize = 20}, tb)
	corner(minB, 8)
	local closeB = new("TextButton", {Size = UDim2.fromOffset(40, 34), Position = UDim2.new(1, -48, 0.5, -17), BackgroundColor3 = T.bad,
		Text = "✕", TextColor3 = WHITE, Font = Enum.Font.GothamBold, TextSize = 16}, tb)
	corner(closeB, 8)
	makeDraggable(tb, win)

	orb = new("TextButton", {Size = UDim2.fromOffset(56, 56), Position = UDim2.new(0, 14, 0.5, -28), Text = "⚔", TextSize = 26,
		TextColor3 = WHITE, Visible = false, ZIndex = 20}, gui)
	corner(orb, 28)
	onAccent(function(c) orb.BackgroundColor3 = c end)
	makeDraggable(orb, orb)
	local orbMoved = false
	minB.MouseButton1Click:Connect(function() win.Visible = false; orb.Visible = true end)
	orb.MouseButton1Click:Connect(function() win.Visible = true; orb.Visible = false end)
	closeB.MouseButton1Click:Connect(function() if G.HUBX_UNLOAD then G.HUBX_UNLOAD() end end)

	local side = new("Frame", {Size = UDim2.new(0, 176, 1, -52), Position = UDim2.fromOffset(0, 52), BackgroundColor3 = T.side}, win)
	sideList = new("ScrollingFrame", {Size = UDim2.new(1, -16, 1, -16), Position = UDim2.fromOffset(8, 8), BackgroundTransparency = 1,
		BorderSizePixel = 0, ScrollBarThickness = 3, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y}, side)
	new("UIListLayout", {Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder}, sideList)
	body = new("Frame", {Size = UDim2.new(1, -176, 1, -52), Position = UDim2.fromOffset(176, 52), BackgroundTransparency = 1}, win)

	track(UIS.InputBegan:Connect(function(i, gp)
		if not gp and i.KeyCode == Enum.KeyCode.RightShift then
			win.Visible = not win.Visible; orb.Visible = not win.Visible
		end
	end))

	-- มุมปรับขนาดหน้าต่าง (ลากที่มุมขวาล่าง)
	local grip = new("TextButton", {Size = UDim2.fromOffset(44, 44), Position = UDim2.new(1, -44, 1, -44), BackgroundTransparency = 1,
		Text = "◢", TextSize = 26, Font = Enum.Font.GothamBold, ZIndex = 30, AutoButtonColor = false}, win)
	onAccent(function(c) grip.TextColor3 = c end)
	local rs, rIn, rSize = false, nil, nil
	local function isP(i) return i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 end
	track(grip.InputBegan:Connect(function(i)
		if isP(i) then
			local ap, as = win.AbsolutePosition, win.AbsoluteSize
			win.AnchorPoint = Vector2.new(0, 0)
			win.Position = UDim2.fromOffset(ap.X, ap.Y)
			win.Size = UDim2.fromOffset(as.X, as.Y)
			rs = true; rIn = i.Position; rSize = as
		end
	end))
	track(UIS.InputChanged:Connect(function(i)
		if rs and (i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseMovement) then
			local d = i.Position - rIn
			local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
			win.Size = UDim2.fromOffset(math.clamp(rSize.X + d.X, 360, vp.X), math.clamp(rSize.Y + d.Y, 260, vp.Y))
		end
	end))
	track(UIS.InputEnded:Connect(function(i) if isP(i) then rs = false end end))
end)

local pDash, pPlayer, pTp, pAuto, pClick, pVis, pPerf, pServer, pSet
coreStage("แท็บ", function()
	pDash = addTab("dash", "📊", "หน้าหลัก")
	pPlayer = addTab("player", "🏃", "ผู้เล่น")
	pTp = addTab("tp", "📍", "วาร์ป")
		pAuto = addTab("auto", "⚡", "ออโต้")
		pClick = addTab("click", "🖱", "คลิก+เกิดใหม่")
	pVis = addTab("vis", "👁", "มองเห็น")
	pPerf = addTab("perf", "🚀", "ลดแลค")
	pServer = addTab("server", "🌐", "เซิร์ฟเวอร์")
	pSet = addTab("set", "⚙", "ตั้งค่า")
	selectTab("dash")
end)
if failed then return end

-- ===== สถานะ/ตัวช่วยเกม =====
local S = {
	Speed = false, SpeedV = 60, Jump = false, JumpV = 120, InfJump = false, Fly = false, FlyV = 6, Up = false, Down = false,
	Noclip = false, AntiAFK = true, AutoDaily = false, AutoPrompt = false, PromptKey = "", PromptRange = 14,
	ESP = false, ESPRange = 400, BigSize = 8, PromptESP = false, PromptESPRange = 200,
	Bright = false, FOV = 70, LoopInt = 1.0, PTP = true,
	ClickOn = false, ClickInt = 0.2, RebirthOn = false, RebirthInt = 5,
}
local function char() return LP.Character end
local function hum() local c = LP.Character; return c and c:FindFirstChildOfClass("Humanoid") end
local function root() local c = LP.Character; return c and c:FindFirstChild("HumanoidRootPart") end
local function guard(name, fn)
	local ok, e = pcall(fn)
	if not ok then
		print("[Hub] " .. name .. ": " .. tostring(e))
		toast("พังที่ " .. name .. ": " .. tostring(e):sub(1, 70), T.bad)
	end
end

local function isPaid(p)
	local t = (tostring(p.ActionText) .. " " .. tostring(p.ObjectText)):lower()
	return t:find("r%$", 1) ~= nil or t:find("robux", 1, true) ~= nil
end
local function promptPos(p)
	local par = p.Parent
	if not par then return nil end
	if par:IsA("Attachment") then return par.WorldPosition end
	if par:IsA("BasePart") then return par.Position end
	if par:IsA("Model") then return par:GetPivot().Position end
	local bp = par:FindFirstAncestorWhichIsA("BasePart")
	if bp then return bp.Position end
	return nil
end
local function firePrompt(p)
	if isPaid(p) then toast("ข้ามจุดที่ต้องจ่าย Robux", T.bad) return end
	if fireproximityprompt then pcall(fireproximityprompt, p) return end
	pcall(function() p:InputHoldBegin(); task.wait(p.HoldDuration + 0.1); p:InputHoldEnd() end)
end

-- ===== ติดตามวัตถุในแมพ (พรอมต์ + มอน) =====
local promptSet, humSet = {}, {}
local function trackObj(d)
	if d:IsA("ProximityPrompt") then promptSet[d] = true
	elseif d:IsA("Humanoid") then humSet[d] = true end
end
task.spawn(function()
	local n = 0
	for _, d in ipairs(workspace:GetDescendants()) do
		trackObj(d)
		n = n + 1
		if n % 400 == 0 then task.wait() end
	end
end)
track(workspace.DescendantAdded:Connect(trackObj))
track(workspace.DescendantRemoving:Connect(function(d) promptSet[d] = nil; humSet[d] = nil end))

-- ===== แท็บหน้าหลัก =====
guard("หน้าหลัก", function()
	Section(pDash, "ค่าสถานะของคุณ (อ่านจากเซิร์ฟเวอร์ แก้ไม่ได้)")
	local sStr = Stat(pDash, "พลัง (Strength)")
	local sWin = Stat(pDash, "Wins")
	local sReb = Stat(pDash, "Rebirths")
	local sSpd = Stat(pDash, "ตัวคูณความเร็ว")
	local sBoss = Stat(pDash, "BossCoins")
	local sPlay = Stat(pDash, "เวลาเล่น")
	local sDaily = Stat(pDash, "รางวัลรายวัน")
	Section(pDash, "สถิติรอบนี้")
	local sRateS = Stat(pDash, "พลังที่เพิ่ม / นาที")
	local sRateW = Stat(pDash, "Wins ที่เพิ่ม / นาที")
	local sElapsed = Stat(pDash, "เวลาที่เปิดสคริปต์")

	local function stat(...)
		for _, n in ipairs({...}) do
			local a = LP:GetAttribute(n)
			if type(a) == "number" then return a end
			local v = LP:FindFirstChild(n, true)
			if v and v:IsA("ValueBase") and tonumber(v.Value) then return tonumber(v.Value) end
		end
		return nil
	end
	local t0 = os.clock()
	local base = {s = stat("Fuerza", "Strength"), w = stat("Wins")}
	task.spawn(function()
		while alive do
			task.wait(1)
			pcall(function()
				local str, wins = stat("Fuerza", "Strength"), stat("Wins")
				sStr(fmt(str)); sWin(fmt(wins)); sReb(fmt(stat("Rebirths")))
				sSpd(fmt(stat("SpeedMult"))); sBoss(fmt(stat("BossCoins")))
				local pt = stat("TiempoJugado")
				sPlay(pt and tfmt(pt) or "-")
				local dp = stat("DailyProximo")
				if LP:GetAttribute("DailyListo") == true then sDaily("พร้อมรับ ✓")
				elseif dp then
					local r = dp - os.time()
					sDaily(r > 0 and tfmt(r) or "พร้อมรับ ✓")
				else sDaily("-") end
				local el = os.clock() - t0
				sElapsed(tfmt(el))
				if el > 20 then
					if str and base.s then sRateS(fmt((str - base.s) / (el / 60))) end
					if wins and base.w then sRateW(fmt((wins - base.w) / (el / 60))) end
				else
					sRateS("กำลังคำนวณ..."); sRateW("กำลังคำนวณ...")
				end
			end)
		end
	end)
end)

-- ===== แท็บผู้เล่น =====
guard("ผู้เล่น", function()
	Section(pPlayer, "การเคลื่อนที่")
	Toggle(pPlayer, "ความเร็วเดิน", "ตั้งค่าความเร็วเดินเอง (เกมอาจรีเซ็ตค่ากลับ ถ้าเด้งกลับให้ปิด)", false, function(v) S.Speed = v end)
	Slider(pPlayer, "ค่าความเร็ว", "ปกติ 16", 16, 300, S.SpeedV, 2, function(v) S.SpeedV = v end)
	Toggle(pPlayer, "พลังกระโดด", nil, false, function(v) S.Jump = v end)
	Slider(pPlayer, "ค่าพลังกระโดด", "ปกติ ~50", 50, 400, S.JumpV, 5, function(v) S.JumpV = v end)
	Toggle(pPlayer, "กระโดดไม่จำกัด", "กดกระโดดกลางอากาศได้เรื่อยๆ", false, function(v) S.InfJump = v end)
	Toggle(pPlayer, "ทะลุกำแพง (Noclip)", nil, false, function(v) S.Noclip = v end)
	Toggle(pPlayer, "บิน (Fly)", "มีปุ่ม ▲ ▼ ที่ขอบขวาจอ เดินตามทิศกล้อง", false, function(v) S.Fly = v end)
	Slider(pPlayer, "ความเร็วบิน", nil, 1, 30, S.FlyV, 1, function(v) S.FlyV = v end)
	Section(pPlayer, "ป้องกัน")
	Toggle(pPlayer, "Anti-AFK", "กันถูกเตะเมื่อไม่ได้ขยับ", true, function(v) S.AntiAFK = v end)

	-- ตรรกะ
	track(RunService.Heartbeat:Connect(function()
		local h = hum()
		if not h then return end
		if S.Speed then h.WalkSpeed = S.SpeedV end
		if S.Jump then h.UseJumpPower = true; h.JumpPower = S.JumpV end
	end))
	track(UIS.JumpRequest:Connect(function()
		if S.InfJump then local h = hum(); if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end end
	end))
	track(RunService.Stepped:Connect(function()
		if S.Noclip then
			local c = char()
			if c then for _, p in ipairs(c:GetChildren()) do if p:IsA("BasePart") then p.CanCollide = false end end end
		end
	end))
	local VU = game:GetService("VirtualUser")
	track(LP.Idled:Connect(function()
		if S.AntiAFK then pcall(function() VU:CaptureController(); VU:ClickButton2(Vector2.new()) end) end
	end))

	local flyPad = new("Frame", {Size = UDim2.fromOffset(70, 150), Position = UDim2.new(1, -90, 0.5, -75), BackgroundTransparency = 1,
		Visible = false}, gui)
	local function padBtn(t, y, key)
		local b = new("TextButton", {Size = UDim2.fromOffset(70, 70), Position = UDim2.fromOffset(0, y), BackgroundColor3 = T.card,
			BackgroundTransparency = 0.15, Text = t, TextColor3 = WHITE, TextSize = 28, Font = Enum.Font.GothamBold}, flyPad)
		corner(b, 14)
		local function press(i) return i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 end
		b.InputBegan:Connect(function(i) if press(i) then S[key] = true end end)
		b.InputEnded:Connect(function(i) if press(i) then S[key] = false end end)
	end
	padBtn("▲", 0, "Up"); padBtn("▼", 80, "Down")

	local bv, bg
	local function stopFly()
		if bv then bv:Destroy(); bv = nil end
		if bg then bg:Destroy(); bg = nil end
		local h = hum(); if h then h.PlatformStand = false end
	end
	onCleanup(function() stopFly(); flyPad:Destroy() end)
	track(RunService.RenderStepped:Connect(function()
		flyPad.Visible = S.Fly
		local r, h = root(), hum()
		if not (S.Fly and r and h) then if bv or bg then stopFly() end return end
		if not bv or bv.Parent ~= r then
			if bv then bv:Destroy() end
			if bg then bg:Destroy() end
			bv = new("BodyVelocity", {MaxForce = Vector3.new(1e9, 1e9, 1e9)}, r)
			bg = new("BodyGyro", {MaxTorque = Vector3.new(1e9, 1e9, 1e9), P = 9e4}, r)
		end
		local cam = workspace.CurrentCamera
		h.PlatformStand = true
		bg.CFrame = cam.CFrame
		local vel, d = Vector3.new(), h.MoveDirection
		if d.Magnitude > 0 then
			local l, rt = cam.CFrame.LookVector, cam.CFrame.RightVector
			local fl, fr = Vector3.new(l.X, 0, l.Z), Vector3.new(rt.X, 0, rt.Z)
			local f = (fl.Magnitude > 0) and d:Dot(fl.Unit) or 0
			local s = (fr.Magnitude > 0) and d:Dot(fr.Unit) or 0
			vel = l * f + rt * s
		end
		if S.Up or UIS:IsKeyDown(Enum.KeyCode.Space) then vel = vel + Vector3.new(0, 1, 0) end
		if S.Down or UIS:IsKeyDown(Enum.KeyCode.LeftShift) then vel = vel - Vector3.new(0, 1, 0) end
		bv.Velocity = vel * S.FlyV * 10
	end))
end)

-- ===== แท็บวาร์ป =====
local function tpTo(pos)
	local r = root()
	if r and pos then r.CFrame = CFrame.new(pos + Vector3.new(0, 4, 0)); return true end
	return false
end
guard("วาร์ป", function()
	Section(pTp, "ตำแหน่งที่บันทึก")
	local saved = {}
	for i = 1, 3 do
		Button2(pTp, "ตำแหน่ง " .. i, nil, "บันทึก", function()
			local r = root()
			if r then saved[i] = r.Position; toast("บันทึกตำแหน่ง " .. i .. " แล้ว", T.good) end
		end, "วาร์ปไป", function()
			if saved[i] then tpTo(saved[i]) else toast("ยังไม่ได้บันทึกตำแหน่ง " .. i, T.bad) end
		end)
	end
	Section(pTp, "จุดโต้ตอบในแมพ (ร้านค้า ปุ่มกด NPC)")
	Toggle(pTp, "กดแล้ววาร์ปกลับตำแหน่งเดิม", "ปุ่ม 'กด' จะพาไปที่จุดนั้น กด แล้วกลับมาให้เอง", true, function(v) S.PTP = v end)
	local filterText = ""
	Input(pTp, "กรองชื่อ", "พิมพ์คำ เช่น Boss, Buy, Equip แล้วกดรีเฟรช", "", function(t) filterText = t:lower() end)
	local list = ListBox(pTp)
	local function refresh()
		clearList(list)
		local items = {}
		for p in pairs(promptSet) do
			if p.Parent then
				local text = tostring(p.ActionText) .. " · " .. tostring(p.ObjectText)
				local par = p.Parent and p.Parent.Name or "?"
				if filterText == "" or (text .. " " .. par):lower():find(filterText, 1, true) then
					items[#items + 1] = {p = p, text = text, par = par, paid = isPaid(p)}
				end
			end
		end
		table.sort(items, function(a, b) return a.text < b.text end)
		local seen, shown = {}, 0
		for _, it in ipairs(items) do
			local key = it.text .. "|" .. it.par
			if not seen[key] and shown < 80 then
				seen[key] = true; shown = shown + 1
				if it.paid then
					Row(list, "💰 " .. it.text, "ต้องจ่าย Robux — ปิดการกดไว้เพื่อความปลอดภัย", {})
				else
					Row(list, it.text, "บน: " .. it.par, {
						{text = "วาร์ป", cb = function()
							local pos = promptPos(it.p)
							if not tpTo(pos) then toast("ไปที่จุดนี้ไม่ได้", T.bad) end
						end},
						{text = "กด", color = T.accent, cb = function()
							local r = root()
							local back = r and r.CFrame
							local pos = promptPos(it.p)
							if S.PTP and pos then tpTo(pos); task.wait(0.35) end
							firePrompt(it.p)
							task.wait(0.35)
							if S.PTP and back and root() then root().CFrame = back end
						end},
					})
				end
			end
		end
		toast("พบจุดโต้ตอบ " .. shown .. " แบบ", T.good)
	end
	Button(pTp, "รีเฟรชรายการ", "สแกนจุดโต้ตอบในแมพใหม่", "รีเฟรช", refresh)
end)

-- ===== แท็บออโต้ =====
local recs, recOrder, recLoop, recRunning = {}, {}, {}, {}
local recOn, hooked, hookOk = false, false, false
local function ser(v, d)
	d = d or 0
	local t = typeof(v)
	if t == "string" then return '"' .. v:sub(1, 30) .. '"' end
	if t == "number" or t == "boolean" or t == "nil" then return tostring(v) end
	if t == "Instance" then return "<" .. v.Name .. ">" end
	if t == "Vector3" then return string.format("V3(%.0f,%.0f,%.0f)", v.X, v.Y, v.Z) end
	if t == "table" then
		if d >= 1 then return "{..}" end
		local p, n = {}, 0
		for k, x in pairs(v) do
			n = n + 1
			if n > 4 then p[#p + 1] = ".." break end
			p[#p + 1] = tostring(k) .. "=" .. ser(x, d + 1)
		end
		return "{" .. table.concat(p, ",") .. "}"
	end
	return t
end
local function blocked(name)
	local l = name:lower()
	for _, w in ipairs({"robux", "admin", "purchase", "buy", "gamepass", "product", "pay"}) do
		if l:find(w, 1, true) then return true end
	end
	return false
end
local function fireRec(rec)
	if blocked(rec.name) then return end
	pcall(function()
		if rec.m == "InvokeServer" then rec.remote:InvokeServer(table.unpack(rec.args, 1, rec.args.n))
		else rec.remote:FireServer(table.unpack(rec.args, 1, rec.args.n)) end
	end)
end
local function findRec(suffix)
	for _, sig in ipairs(recOrder) do
		local r = recs[sig]
		if r.name:sub(-#suffix) == suffix then return r end
	end
	return nil
end
local function startLoop(sig)
	if recRunning[sig] then return end
	recRunning[sig] = true
	task.spawn(function()
		while alive and recLoop[sig] do
			local r = recs[sig]
			if r then fireRec(r) end
			task.wait(math.max(0.3, S.LoopInt))
		end
		recRunning[sig] = nil
	end)
end
local learnOn, learnData = false, nil
local function installHook()
	if hooked then return end
	hooked = true
	local cc = checkcaller or function() return false end
	hookOk = pcall(function()
		local old
		old = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
			if recOn or learnOn then
				local m = getnamecallmethod()
				if (m == "FireServer" or m == "InvokeServer") and not cc() then
					local pk = table.pack(...)
					pcall(function()
						if typeof(self) ~= "Instance" then return end
						if not (self:IsA("RemoteEvent") or self:IsA("RemoteFunction") or self:IsA("UnreliableRemoteEvent")) then return end
						local name = self:GetFullName()
						if learnOn and learnData then
							local lsig = name .. "|" .. tostring(pk.n)
							local lr = learnData.counts[lsig]
							if not lr then
								lr = {remote = self, m = m, args = pk, name = name, n = 0}
								learnData.counts[lsig] = lr
								learnData.order[#learnData.order + 1] = lsig
							end
							lr.n = lr.n + 1
						end
						if recOn then
							local parts = {}
							for i = 1, math.min(pk.n, 5) do parts[i] = ser(pk[i]) end
							local sig = name .. "|" .. table.concat(parts, ",")
							local r = recs[sig]
							if not r then
								if #recOrder >= 70 then return end
								r = {remote = self, m = m, args = pk, name = name, sig = sig, argText = table.concat(parts, ", "), n = 0}
								recs[sig] = r
								recOrder[#recOrder + 1] = sig
							end
							r.n = r.n + 1
						end
					end)
				end
			end
			return old(self, ...)
		end))
	end)
end
onCleanup(function() recOn = false; learnOn = false end)

guard("ออโต้", function()
	Section(pAuto, "ออโต้พื้นฐาน")
	Toggle(pAuto, "ออโต้รับรางวัลรายวัน", "เมื่อรางวัลพร้อม จะส่งคำสั่ง Daily_Reclamar ให้ (ถ้ามีบันทึกคำสั่งไว้จะใช้ค่านั้น)", false, function(v) S.AutoDaily = v end)
	Toggle(pAuto, "กดจุดโต้ตอบใกล้ตัวอัตโนมัติ", "กดเฉพาะจุดที่ชื่อมีคำที่กรอก ข้ามจุดที่ต้องจ่าย Robux เสมอ", false, function(v) S.AutoPrompt = v end)
	Input(pAuto, "คำที่ต้องการกด", "เช่น Claim, Open, Equip (เว้นว่าง = ไม่กดอะไร)", "", function(t) S.PromptKey = t:lower() end)
	Slider(pAuto, "ระยะกดจุด", "หน่วย studs", 5, 40, S.PromptRange, 1, function(v) S.PromptRange = v end)

	task.spawn(function()
		while alive do
			task.wait(5)
			if S.AutoDaily and LP:GetAttribute("DailyListo") == true then
				local rm = RS:FindFirstChild("Remotes")
				local rem = rm and rm:FindFirstChild("Daily_Reclamar")
				if rem and rem:IsA("RemoteEvent") then
					local rec = findRec("Daily_Reclamar")
					pcall(function()
						if rec then rem:FireServer(table.unpack(rec.args, 1, rec.args.n)) else rem:FireServer() end
					end)
					toast("ส่งคำสั่งรับรางวัลรายวันแล้ว", T.good)
					task.wait(60)
				end
			end
		end
	end)
	task.spawn(function()
		while alive do
			task.wait(1)
			if S.AutoPrompt and S.PromptKey ~= "" and fireproximityprompt then
				local r = root()
				if r then
					for p in pairs(promptSet) do
						if p.Parent and p.Enabled and not isPaid(p) then
							local t = (tostring(p.ActionText) .. " " .. tostring(p.ObjectText)):lower()
							if t:find(S.PromptKey, 1, true) then
								local pos = promptPos(p)
								if pos and (pos - r.Position).Magnitude <= S.PromptRange then pcall(fireproximityprompt, p) end
							end
						end
					end
				end
			end
		end
	end)

	Section(pAuto, "เครื่องบันทึกคำสั่งเกม → รันซ้ำอัตโนมัติ")
	Toggle(pAuto, "บันทึกคำสั่งที่เกมส่ง", "เปิด แล้วเล่นในเกมปกติ (คลิกฝึก กด Rebirth รับของ) ระบบจะจำคำสั่งไว้ แล้วกดรีเฟรชด้านล่าง", false, function(v)
		if v then
			installHook()
			if not hookOk then toast("Executor นี้ไม่รองรับการดักคำสั่ง", T.bad); recOn = false return end
		end
		recOn = v
	end)
	Slider(pAuto, "ช่วงเวลาวนซ้ำ", "วินาที (ต่ำสุด 0.3) ตั้งให้ใกล้เคียงคนเล่นจริงเพื่อลดความเสี่ยง", 0.3, 10, S.LoopInt, 0.1, function(v) S.LoopInt = v end)
	local list = ListBox(pAuto)
	local function refresh()
		clearList(list)
		if #recOrder == 0 then toast("ยังไม่มีคำสั่งที่บันทึก", T.bad) return end
		for _, sig in ipairs(recOrder) do
			local rec = recs[sig]
			local short = rec.name:match("([^%.]+%.[^%.]+)$") or rec.name
			local nm = "[" .. rec.m:sub(1, 1) .. "] " .. short .. "  x" .. rec.n
			if blocked(rec.name) then
				Row(list, nm, "ปิดการรันซ้ำ (เกี่ยวกับการจ่ายเงิน/แอดมิน)", {})
			else
				Row(list, nm, rec.argText, {
					{text = "รัน", cb = function() fireRec(rec); toast("ส่งคำสั่งแล้ว", T.good) end},
					{text = recLoop[sig] and "วน ●" or "วน", color = recLoop[sig] and T.accent or T.card2, cb = function(b)
						recLoop[sig] = not recLoop[sig]
						b.Text = recLoop[sig] and "วน ●" or "วน"
						b.BackgroundColor3 = recLoop[sig] and T.accent or T.card2
						if recLoop[sig] then startLoop(sig) end
					end},
				})
			end
		end
	end
	Button(pAuto, "รีเฟรชรายการคำสั่ง", "แสดงคำสั่งที่บันทึกได้ (ทำซ้ำกดรีเฟรชหลังเล่นเพิ่ม)", "รีเฟรช", refresh)
	Button(pAuto, "หยุดวนซ้ำทั้งหมด", nil, "หยุด", function()
		for sig in pairs(recLoop) do recLoop[sig] = false end
		refresh()
		toast("หยุดการวนซ้ำทั้งหมดแล้ว", T.good)
	end, T.bad)
	onCleanup(function() for sig in pairs(recLoop) do recLoop[sig] = false end end)
end)

-- ===== แท็บคลิก + เกิดใหม่อัตโนมัติ =====
guard("คลิก", function()
	local VIM
	pcall(function() VIM = game:GetService("VirtualInputManager") end)
	local clickModes = {"แตะ (สัมผัส)", "แตะ (เมาส์)", "เครื่องมือ", "คำสั่งเกม"}
	local mode, point, picking = 4, nil, false
	local slots = {click = {cands = {}, ci = 0}, rebirth = {cands = {}, ci = 0}}
	local function shortName(n) return n:match("([^%.]+%.[^%.]+)$") or n end

	local marker = new("Frame", {Size = UDim2.fromOffset(26, 26), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 0.35,
		Visible = false, Active = false, ZIndex = 50}, gui)
	corner(marker, 13)
	onAccent(function(c) marker.BackgroundColor3 = c end)

	local function pos()
		if point then return point.X, point.Y end
		local cam = workspace.CurrentCamera
		local vs = cam and cam.ViewportSize or Vector2.new(800, 400)
		return vs.X * 0.5, vs.Y * 0.5
	end
	local function doClick()
		if mode == 1 then
			if not VIM then return end
			local x, y = pos()
			pcall(function() VIM:SendTouchEvent(9, 0, x, y) end)
			task.wait(0.02)
			pcall(function() VIM:SendTouchEvent(9, 2, x, y) end)
		elseif mode == 2 then
			if not VIM then return end
			local x, y = pos()
			pcall(function() VIM:SendMouseButtonEvent(x, y, 0, true, game, 0) end)
			task.wait(0.02)
			pcall(function() VIM:SendMouseButtonEvent(x, y, 0, false, game, 0) end)
		elseif mode == 3 then
			pcall(function()
				local c = LP.Character
				local t = c and c:FindFirstChildOfClass("Tool")
				if t then t:Activate() end
			end)
		else
			local s = slots.click
			local r = s.cands[s.ci]
			if r then fireRec(r) end
		end
	end

	-- เรียนรู้คำสั่งจากเกม (ใช้ตัวดักเดียวกับแท็บออโต้)
	local function learn(slot, secs, setTxt, sorter)
		if learnOn then return end
		installHook()
		if not hookOk then toast("Executor นี้ดักคำสั่งเกมไม่ได้", T.bad) return end
		learnData = {counts = {}, order = {}}
		learnOn = true
		for s = secs, 1, -1 do
			setTxt("กำลังเรียนรู้... อีก " .. s .. " วิ")
			task.wait(1)
			if not alive then return end
		end
		learnOn = false
		local list = {}
		for _, sig in ipairs(learnData.order) do
			local r = learnData.counts[sig]
			if not blocked(r.name) then list[#list + 1] = r end
		end
		learnData = nil
		table.sort(list, sorter)
		slots[slot].cands = list
		slots[slot].ci = (#list > 0) and 1 or 0
		if #list == 0 then setTxt("ไม่พบคำสั่ง ลองใหม่") else
			local r = list[1]
			setTxt("1/" .. #list .. ": " .. shortName(r.name) .. " x" .. r.n)
		end
	end
	local function nextCand(slot, setTxt)
		local s = slots[slot]
		if #s.cands == 0 then toast("ยังไม่มีคำสั่งที่เรียนรู้", T.bad) return end
		s.ci = s.ci % #s.cands + 1
		local r = s.cands[s.ci]
		setTxt(s.ci .. "/" .. #s.cands .. ": " .. shortName(r.name) .. " x" .. r.n)
	end

	-- ---------- ออโต้คลิก ----------
	Section(pClick, "ออโต้คลิก")
	local clickTog
	clickTog = Toggle(pClick, "ออโต้คลิก", "โหมด 'คำสั่งเกม' ส่งคำสั่งตรงไปเซิร์ฟเวอร์ ใช้ได้ผลที่สุด (ต้องกดเรียนรู้ก่อน 1 ครั้ง)", false, function(v)
		S.ClickOn = v
		if v and mode == 4 and slots.click.ci == 0 then toast("ยังไม่มีคำสั่ง กดเรียนรู้คำสั่งคลิกก่อน", T.bad) end
		if v and (mode == 1 or mode == 2) and not VIM then toast("Executor นี้ไม่มี VirtualInputManager ลองโหมดอื่น", T.bad) end
	end)
	Slider(pClick, "ช่วงเวลาคลิก", "วินาทีต่อครั้ง (ต่ำสุด 0.1)", 0.1, 3, S.ClickInt, 0.1, function(v) S.ClickInt = v end)
	local modeBtn
	modeBtn = Button(pClick, "โหมดคลิก", "แตะ = จิ้มจอตรงจุดที่ตั้ง · เครื่องมือ = ใช้ของในมือ · คำสั่งเกม = ส่งคำสั่งตรงถึงเซิร์ฟเวอร์", clickModes[mode], function()
		mode = mode % #clickModes + 1
		modeBtn.Text = clickModes[mode]
		marker.Visible = (point ~= nil) and (mode == 1 or mode == 2)
	end)
	Button(pClick, "ตั้งจุดแตะ", "ใช้กับโหมดแตะ กดปุ่มแล้วแตะตำแหน่งบนจอนอกหน้าต่างนี้ (ไม่ตั้ง = แตะกลางจอ)", "ตั้งจุด", function()
		picking = true
		toast("แตะที่จุดบนจอที่ต้องการให้กด (นอกหน้าต่าง)", T.accent)
	end)
	local sClickCmd = Stat(pClick, "คำสั่งคลิกที่ใช้")
	sClickCmd("ยังไม่ได้เรียนรู้")
	Button(pClick, "เรียนรู้คำสั่งคลิก", "กดแล้วแตะเล่นในเกมตามปกติ 6 วินาที ระบบจะจำคำสั่งที่ถี่ที่สุด", "เรียนรู้ (6 วิ)", function()
		learn("click", 6, sClickCmd, function(a, b) return a.n > b.n end)
	end)
	Button(pClick, "คำสั่งถัดไป", "สลับไปคำสั่งอื่นที่จับได้ ถ้าตัวแรกไม่ได้ผล", "ถัดไป", function() nextCand("click", sClickCmd) end)

	-- ---------- ออโต้เกิดใหม่ ----------
	Section(pClick, "ออโต้เกิดใหม่")
	local rebTog
	rebTog = Toggle(pClick, "ออโต้เกิดใหม่", "ส่งคำสั่งเกิดใหม่ซ้ำตามช่วงเวลา เซิร์ฟเวอร์ตรวจเงื่อนไขเอง ถ้าเลเวลยังไม่เต็มจะไม่เกิดอะไร (ต้องเรียนรู้ก่อน 1 ครั้ง)", false, function(v)
		if v and slots.rebirth.ci == 0 then
			toast("ยังไม่มีคำสั่งเกิดใหม่ กดเรียนรู้ก่อน", T.bad)
			rebTog.set(false)
			return
		end
		S.RebirthOn = v
	end)
	Slider(pClick, "ช่วงเวลาลองเกิดใหม่", "วินาที ตั้งไว้ 5-10 วิ กำลังดี", 2, 120, S.RebirthInt, 1, function(v) S.RebirthInt = v end)
	local sRebCmd = Stat(pClick, "คำสั่งเกิดใหม่ที่ใช้")
	sRebCmd("ยังไม่ได้เรียนรู้")
	local function rebSorter(a, b)
		local function score(r)
			local l = r.name:lower()
			if l:find("rebirth", 1, true) or l:find("renac", 1, true) or l:find("reborn", 1, true) or l:find("prestige", 1, true) then return 0 end
			return 1
		end
		local sa, sb = score(a), score(b)
		if sa ~= sb then return sa < sb end
		return a.n < b.n
	end
	Button(pClick, "เรียนรู้คำสั่งเกิดใหม่", "กดปุ่มนี้ แล้วกดเกิดใหม่ในเกมเอง 1 ครั้งภายใน 10 วินาที (กดยืนยันในหน้าต่างเกิดใหม่ด้วย) ห้ามกดอย่างอื่นระหว่างนั้น", "เรียนรู้ (10 วิ)", function()
		S.RebirthOn = false
		rebTog.set(false)
		learn("rebirth", 10, sRebCmd, rebSorter)
	end)
	Button(pClick, "คำสั่งถัดไป (เกิดใหม่)", "ถ้าจับได้หลายคำสั่ง ให้สลับดู ตัวที่ชื่อมีคำว่า Rebirth จะอยู่ก่อน", "ถัดไป", function() nextCand("rebirth", sRebCmd) end)
	Button(pClick, "ทดสอบส่ง 1 ครั้ง", "ส่งคำสั่งเกิดใหม่ตอนนี้ทันที ถ้าเลเวลเต็มจะเกิดใหม่จริง", "ส่ง", function()
		local s = slots.rebirth
		local r = s.cands[s.ci]
		if r then fireRec(r); toast("ส่งคำสั่งเกิดใหม่แล้ว", T.good) else toast("ยังไม่ได้เรียนรู้คำสั่ง", T.bad) end
	end, T.card2)

	-- ---------- ลูปทำงาน ----------
	task.spawn(function()
		while alive do
			task.wait(math.max(0.1, S.ClickInt))
			if S.ClickOn and not learnOn then pcall(doClick) end
		end
	end)
	task.spawn(function()
		while alive do
			task.wait(math.max(1, S.RebirthInt))
			if S.RebirthOn and not learnOn then
				local s = slots.rebirth
				local r = s.cands[s.ci]
				if r then fireRec(r) end
			end
		end
	end)

	-- เลือกจุดแตะ
	local function isPress(i) return i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 end
	track(UIS.InputBegan:Connect(function(i)
		if not picking or not isPress(i) then return end
		local p = Vector2.new(i.Position.X, i.Position.Y)
		for _, o in ipairs({win, orb}) do
			if o and o.Visible then
				local fp, fs = o.AbsolutePosition, o.AbsoluteSize
				if p.X >= fp.X and p.X <= fp.X + fs.X and p.Y >= fp.Y and p.Y <= fp.Y + fs.Y then return end
			end
		end
		picking = false
		point = p
		marker.Position = UDim2.fromOffset(p.X, p.Y)
		marker.Visible = (mode == 1 or mode == 2)
		toast("ตั้งจุดแตะแล้ว (วงกลมสี)", T.good)
	end))

	onCleanup(function() S.ClickOn = false; S.RebirthOn = false; learnOn = false end)
end)


-- ===== แท็บมองเห็น =====
guard("มองเห็น", function()
	local espFolder = new("Folder", {Name = "ESP"}, gui)
	local entries, pEntries = {}, {}
	onCleanup(function() espFolder:Destroy() end)
	Section(pVis, "ESP มอนสเตอร์")
	Toggle(pVis, "กรอบมอน", "เขียว=เล็ก เหลือง=กลาง แดง=ใหญ่ พร้อมชื่อและระยะ", false, function(v) S.ESP = v end)
	Slider(pVis, "ระยะ ESP", nil, 50, 1500, S.ESPRange, 50, function(v) S.ESPRange = v end)
	Slider(pVis, "ขนาดที่ถือว่าใหญ่", "ยิ่งต่ำยิ่งมีตัวแดงเยอะ", 3, 40, S.BigSize, 1, function(v) S.BigSize = v end)
	Section(pVis, "ESP จุดโต้ตอบ")
	Toggle(pVis, "ป้ายชื่อจุดโต้ตอบ", "แสดงชื่อจุดกดทะลุกำแพง ช่วยหาร้านค้า", false, function(v) S.PromptESP = v end)
	Slider(pVis, "ระยะป้ายจุดโต้ตอบ", nil, 50, 600, S.PromptESPRange, 50, function(v) S.PromptESPRange = v end)
	Section(pVis, "ภาพ")
	local orig = nil
	Toggle(pVis, "สว่างเต็มที่ (Fullbright)", "ปิดหมอก เพิ่มความสว่าง", false, function(v)
		if v and not orig then
			orig = {B = Lighting.Brightness, C = Lighting.ClockTime, F = Lighting.FogEnd, S = Lighting.GlobalShadows}
		end
		S.Bright = v
		if not v and orig then
			Lighting.Brightness = orig.B; Lighting.ClockTime = orig.C; Lighting.FogEnd = orig.F; Lighting.GlobalShadows = orig.S
		end
	end)
	Slider(pVis, "มุมมองกล้อง (FOV)", "ปกติ 70", 40, 120, S.FOV, 1, function(v)
		S.FOV = v
		local cam = workspace.CurrentCamera
		if cam then cam.FieldOfView = v end
	end)

	local function sizeColor(s)
		if s >= S.BigSize then return Color3.fromRGB(255, 70, 70) end
		if s >= S.BigSize / 2 then return Color3.fromRGB(255, 215, 60) end
		return Color3.fromRGB(70, 255, 110)
	end
	local function rm(tbl, k)
		local e = tbl[k]
		if e then e.a:Destroy(); e.t:Destroy(); tbl[k] = nil end
	end
	task.spawn(function()
		while alive do
			task.wait(0.4)
			local r, c = root(), char()
			if S.Bright then
				Lighting.Brightness = 2; Lighting.ClockTime = 14; Lighting.FogEnd = 1e9; Lighting.GlobalShadows = false
			end
			-- มอน
			for h, e in pairs(entries) do
				if not S.ESP or not h.Parent or h.Health <= 0 or not humSet[h] then rm(entries, h) end
			end
			if S.ESP and r then
				for h in pairs(humSet) do
					local m = h.Parent
					if m and m ~= c and h.Health > 0 and not Players:GetPlayerFromCharacter(m) then
						local p = m:FindFirstChild("HumanoidRootPart") or m.PrimaryPart
						if p then
							local dist = (p.Position - r.Position).Magnitude
							if dist <= S.ESPRange then
								local e = entries[h]
								if not e then
									local cf, size = m:GetBoundingBox()
									local a = new("BoxHandleAdornment", {Adornee = p, AlwaysOnTop = true, ZIndex = 5, Transparency = 0.65,
										Size = size, CFrame = p.CFrame:ToObjectSpace(cf)}, espFolder)
									local t = new("BillboardGui", {Adornee = p, AlwaysOnTop = true, Size = UDim2.fromOffset(150, 22),
										StudsOffset = Vector3.new(0, size.Y / 2 + 1.5, 0)}, espFolder)
									local l = new("TextLabel", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, TextStrokeTransparency = 0.3,
										Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = WHITE}, t)
									e = {a = a, t = t, l = l, size = math.max(size.X, size.Y, size.Z)}
									entries[h] = e
								end
								local col = sizeColor(e.size)
								e.a.Color3 = col; e.l.TextColor3 = col
								e.l.Text = m.Name .. " [" .. math.floor(dist) .. "m]"
							else
								rm(entries, h)
							end
						end
					end
				end
			end
			-- จุดโต้ตอบ
			for p, e in pairs(pEntries) do
				if not S.PromptESP or not p.Parent or not promptSet[p] then rm(pEntries, p) end
			end
			if S.PromptESP and r then
				local made = 0
				for p in pairs(promptSet) do
					if p.Parent then
						local pos = promptPos(p)
						if pos and (pos - r.Position).Magnitude <= S.PromptESPRange then
							if not pEntries[p] and made < 6 then
								local adornee = p.Parent
								if adornee:IsA("BasePart") or adornee:IsA("Attachment") then
									local t = new("BillboardGui", {Adornee = adornee, AlwaysOnTop = true, Size = UDim2.fromOffset(180, 22),
										StudsOffset = Vector3.new(0, 2.5, 0)}, espFolder)
									local paid = isPaid(p)
									new("TextLabel", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, TextStrokeTransparency = 0.3,
										Font = Enum.Font.GothamBold, TextSize = 12,
										TextColor3 = paid and Color3.fromRGB(255, 120, 120) or Color3.fromRGB(120, 200, 255),
										Text = (paid and "💰 " or "◆ ") .. tostring(p.ActionText) .. " · " .. tostring(p.ObjectText)}, t)
									pEntries[p] = {a = t, t = t}
									made = made + 1
								end
							end
						else
							rm(pEntries, p)
						end
					end
				end
			end
		end
	end)
end)

-- ===== แท็บลดแลค =====
guard("ลดแลค", function()
	Section(pPerf, "ช่วยให้แท็บเล็ตลื่นขึ้น")
	local fxOn = false
	local function killFx(d)
		if d:IsA("ParticleEmitter") or d:IsA("Trail") or d:IsA("Beam") or d:IsA("Smoke") or d:IsA("Fire") or d:IsA("Sparkles") then
			pcall(function() d.Enabled = false end)
		end
	end
	Toggle(pPerf, "ปิดเอฟเฟกต์ (พาร์ติเคิล เทรล บีม)", "ลดภาระกราฟิกเยอะมาก เกมนี้มีเอฟเฟกต์เยอะ (ปิดแล้วเปิดคืนไม่ได้จนกว่าจะรีจอยน์)", false, function(v)
		fxOn = v
		if v then
			task.spawn(function()
				local n = 0
				for _, d in ipairs(workspace:GetDescendants()) do
					killFx(d); n = n + 1
					if n % 300 == 0 then task.wait() end
				end
				toast("ปิดเอฟเฟกต์แล้ว", T.good)
			end)
		end
	end)
	track(workspace.DescendantAdded:Connect(function(d) if fxOn then killFx(d) end end))
	Toggle(pPerf, "ปิดเงา", nil, false, function(v) pcall(function() Lighting.GlobalShadows = not v end) end)
	Toggle(pPerf, "ลดคุณภาพกราฟิกต่ำสุด", nil, false, function(v)
		pcall(function() settings().Rendering.QualityLevel = v and Enum.QualityLevel.Level01 or Enum.QualityLevel.Automatic end)
	end)

	Section(pPerf, "ซ่อนสัตว์เลี้ยง/ออร่าของคนอื่น")
	local attrs = {"_CfgPetsAjenos", "Ajuste_petsAjenos", "_CfgAurasAjenas", "Ajuste_aurasAjenas"}
	local origAttr = {}
	Toggle(pPerf, "ซ่อนสัตว์และออร่าของผู้เล่นอื่น", "ใช้ตัวเลือกที่เกมมีอยู่แล้ว (ตั้งฝั่งเครื่อง) ช่วยลดแลคในเซิร์ฟที่คนเยอะ", false, function(v)
		for _, n in ipairs(attrs) do
			if v then
				if origAttr[n] == nil then origAttr[n] = LP:GetAttribute(n) end
				pcall(function() LP:SetAttribute(n, false) end)
			else
				if origAttr[n] ~= nil then pcall(function() LP:SetAttribute(n, origAttr[n]) end) end
			end
		end
	end)

	Section(pPerf, "ประหยัดแบตตอนปล่อยฟาร์ม")
	local r3d = false
	Toggle(pPerf, "ปิดการแสดงผล 3D", "หน้าจอจะดำ แต่ UI ของสคริปต์ยังใช้ได้ ตัวละครยังเล่นต่อ ประหยัดแบตและความร้อนมาก", false, function(v)
		r3d = v
		pcall(function() RunService:Set3dRenderingEnabled(not v) end)
	end)
	onCleanup(function() if r3d then pcall(function() RunService:Set3dRenderingEnabled(true) end) end end)
	if setfpscap then
		Slider(pPerf, "จำกัด FPS", "ต่ำลง = เย็นลง ประหยัดแบต (0 = ไม่จำกัด ปรับที่ 30-60)", 0, 120, 0, 10, function(v) pcall(setfpscap, v) end)
	end
end)

-- ===== แท็บเซิร์ฟเวอร์ =====
guard("เซิร์ฟเวอร์", function()
	Section(pServer, "ข้อมูลเซิร์ฟเวอร์")
	local sFps = Stat(pServer, "FPS")
	local sPing = Stat(pServer, "Ping")
	local sPlayers = Stat(pServer, "ผู้เล่นในเซิร์ฟ")
	local sJob = Stat(pServer, "รหัสเซิร์ฟ")
	local frames, acc = 0, 0
	track(RunService.RenderStepped:Connect(function(dt) frames = frames + 1; acc = acc + dt end))
	task.spawn(function()
		while alive do
			task.wait(0.5)
			if acc > 0 then sFps(string.format("%d", math.floor(frames / acc + 0.5))); frames = 0; acc = 0 end
			pcall(function()
				local item = game:GetService("Stats").Network.ServerStatsItem["Data Ping"]
				sPing(math.floor(item:GetValue()) .. " ms")
			end)
			sPlayers(#Players:GetPlayers() .. " / " .. Players.MaxPlayers)
			sJob(game.JobId ~= "" and game.JobId:sub(1, 8) .. "..." or "-")
		end
	end)
	Section(pServer, "ย้ายเซิร์ฟ")
	Button(pServer, "รีจอยน์", "เข้าเซิร์ฟเดิมใหม่ (รีเซ็ตเอฟเฟกต์ที่ปิดไว้)", "รีจอยน์", function()
		toast("กำลังรีจอยน์...", T.accent)
		pcall(function() TeleportService:Teleport(game.PlaceId, LP) end)
	end)
	Button(pServer, "ย้ายเซิร์ฟ (คนน้อย)", "หาเซิร์ฟสาธารณะที่คนน้อยแล้วย้ายไป", "ย้าย", function()
		toast("กำลังหาเซิร์ฟ...", T.accent)
		local ok, res = pcall(function()
			local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
			return HttpService:JSONDecode(game:HttpGet(url))
		end)
		if not ok or not res or not res.data then toast("ดึงรายชื่อเซิร์ฟไม่ได้", T.bad) return end
		for _, s in ipairs(res.data) do
			if s.id ~= game.JobId and s.playing and s.maxPlayers and s.playing < s.maxPlayers - 1 then
				pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, s.id, LP) end)
				return
			end
		end
		toast("ไม่พบเซิร์ฟที่ว่าง", T.bad)
	end)
end)

-- ===== แท็บตั้งค่า =====
local function unload()
	if not alive then return end
	alive = false
	for _, f in ipairs(cleanups) do pcall(f) end
	for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
	pcall(function() gui:Destroy() end)
	G.HUBX_UNLOAD = nil
end
G.HUBX_UNLOAD = unload

guard("ตั้งค่า", function()
	Section(pSet, "หน้าตา")
	Slider(pSet, "ความกว้างหน้าต่าง", "ปรับตามสัดส่วนจอ หรือลากมุม ◢ ที่ขวาล่างของหน้าต่างได้เลย", 30, 100, 66, 1, function(v)
		local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
		win.Size = UDim2.fromOffset(vp.X * v / 100, win.AbsoluteSize.Y)
	end)
	Slider(pSet, "ความสูงหน้าต่าง", nil, 30, 100, 82, 1, function(v)
		local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
		win.Size = UDim2.fromOffset(win.AbsoluteSize.X, vp.Y * v / 100)
	end)
	local f, top = Card(pSet, "สีธีม", "เลือกสีหลักของหน้าต่าง", 10)
	local sw = new("Frame", {Size = UDim2.new(1, 0, 0, 36), BackgroundTransparency = 1, LayoutOrder = 3}, f)
	new("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 10)}, sw)
	for _, c in ipairs({
		Color3.fromRGB(168, 85, 247), Color3.fromRGB(236, 72, 153), Color3.fromRGB(59, 130, 246),
		Color3.fromRGB(34, 197, 94), Color3.fromRGB(249, 115, 22), Color3.fromRGB(239, 68, 68),
	}) do
		local b = new("TextButton", {Size = UDim2.fromOffset(36, 36), BackgroundColor3 = c, Text = ""}, sw)
		corner(b, 18)
		b.MouseButton1Click:Connect(function() setAccent(c) end)
	end
	Section(pSet, "ระบบ")
	Button(pSet, "ซ่อนหน้าต่าง", "ย่อเป็นปุ่ม ⚔ ลอยบนจอ (แตะเพื่อเปิด ลากย้ายได้) บนคีย์บอร์ดใช้ RightShift", "ซ่อน", function()
		win.Visible = false; orb.Visible = true
	end)
	Button(pSet, "ปิดสคริปต์ทั้งหมด", "หยุดทุกฟังก์ชัน ลบ UI และคืนค่าที่ปรับไว้", "ปิดสคริปต์", unload, T.bad)
	Section(pSet, "ข้อควรรู้")
	Card(pSet, "ความปลอดภัย", "ฟังก์ชันที่ต้องจ่าย Robux ถูกข้ามเสมอ ค่าสถานะ (พลัง Wins ฯลฯ) อยู่ที่เซิร์ฟเวอร์ แก้ไม่ได้ ออโต้ที่ส่งคำสั่งถี่เกินคนเล่นจริงเสี่ยงถูกตรวจพบ ควรตั้งช่วงเวลาไม่ต่ำกว่า 1 วินาที")
end)

bar.Text = "Training Hub พร้อมแล้ว! (ลากมุม ◢ ขวาล่างเพื่อปรับขนาดหน้าต่าง)"
task.delay(5, function() pcall(function() bar:Destroy() end) end)
toast("Training Hub พร้อมใช้งาน", T.good)
