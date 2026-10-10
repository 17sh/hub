-- Auto Click v2 (หลายโหมด สลับลองจนได้ผล)
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local LP = Players.LocalPlayer
local G = (getgenv and getgenv()) or _G
if G.AC_STOP then pcall(G.AC_STOP) end

local VIM
pcall(function() VIM = game:GetService("VirtualInputManager") end)

local alive, on = true, false
local ladder = {0.1, 0.15, 0.2, 0.3, 0.5, 0.75, 1, 1.5, 2, 3}
local li = 3
local mode = 1
local modes = {"แตะ (สัมผัส)", "แตะ (เมาส์)", "เครื่องมือ", "คำสั่งเกม"}
local point = nil
local picking, learning = false, false
local cands, ci = {}, 0
local counts, order = {}, {}
local hooked, hookOk = false, false
local conns = {}

local gui = Instance.new("ScreenGui")
gui.Name = "AUTOCLICK"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true; gui.DisplayOrder = 2500
local mounted = false
for _, get in ipairs({
	function() return LP:WaitForChild("PlayerGui", 5) end,
	function() return gethui and gethui() end,
	function() return game:GetService("CoreGui") end,
}) do
	local ok, p = pcall(get)
	if ok and p then
		pcall(function() local o = p:FindFirstChild("AUTOCLICK"); if o then o:Destroy() end end)
		if pcall(function() gui.Parent = p end) and gui.Parent then mounted = true break end
	end
end
if not mounted then return end

local function round(o, r) Instance.new("UICorner", o).CornerRadius = UDim.new(0, r) end
local function btn(par, text, x, y, w, h, col)
	local b = Instance.new("TextButton", par)
	b.Size = UDim2.fromOffset(w, h); b.Position = UDim2.fromOffset(x, y)
	b.BackgroundColor3 = col or Color3.fromRGB(44, 42, 62); b.TextColor3 = Color3.new(1, 1, 1)
	b.Font = Enum.Font.GothamBold; b.TextSize = 14; b.Text = text; b.TextWrapped = true
	round(b, 8)
	return b
end

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.fromOffset(200, 268); frame.Position = UDim2.new(0, 14, 0.5, -60)
frame.BackgroundColor3 = Color3.fromRGB(21, 20, 31); frame.BorderSizePixel = 0
round(frame, 12)

local drag = Instance.new("TextLabel", frame)
drag.Size = UDim2.new(1, -34, 0, 24); drag.BackgroundTransparency = 1
drag.Text = "  ลากย้าย"; drag.TextXAlignment = Enum.TextXAlignment.Left
drag.TextColor3 = Color3.fromRGB(150, 146, 175); drag.TextSize = 13; drag.Font = Enum.Font.GothamBold

local closeB = btn(frame, "✕", 170, 2, 26, 22, Color3.fromRGB(248, 113, 113))
local main = btn(frame, "", 8, 28, 184, 40)
main.TextSize = 16
local slow = btn(frame, "ช้า", 8, 74, 50, 32)
local fast = btn(frame, "เร็ว", 142, 74, 50, 32)
local lbl = Instance.new("TextLabel", frame)
lbl.Size = UDim2.fromOffset(80, 32); lbl.Position = UDim2.fromOffset(60, 74); lbl.BackgroundTransparency = 1
lbl.TextColor3 = Color3.new(1, 1, 1); lbl.TextSize = 13; lbl.Font = Enum.Font.GothamBold
local modeB = btn(frame, "", 8, 112, 184, 32)
local act = btn(frame, "", 8, 150, 184, 32)
local nextB = btn(frame, "คำสั่งถัดไป", 8, 188, 184, 32)
local statusL = Instance.new("TextLabel", frame)
statusL.Size = UDim2.fromOffset(184, 40); statusL.Position = UDim2.fromOffset(8, 224)
statusL.BackgroundTransparency = 1; statusL.TextColor3 = Color3.fromRGB(150, 146, 175)
statusL.TextSize = 12; statusL.Font = Enum.Font.Gotham; statusL.TextWrapped = true
statusL.TextXAlignment = Enum.TextXAlignment.Left; statusL.TextYAlignment = Enum.TextYAlignment.Top

local marker = Instance.new("Frame", gui)
marker.Size = UDim2.fromOffset(26, 26); marker.AnchorPoint = Vector2.new(0.5, 0.5)
marker.BackgroundColor3 = Color3.fromRGB(168, 85, 247); marker.BackgroundTransparency = 0.35
marker.Visible = false; marker.Active = false; marker.ZIndex = 50
round(marker, 13)

local function setStatus(t) statusL.Text = tostring(t) end
local function short(n) return n:match("([^%.]+%.[^%.]+)$") or n end
local function showCand()
	local r = cands[ci]
	if r then setStatus("คำสั่ง " .. ci .. "/" .. #cands .. ": " .. short(r.name) .. " x" .. r.n) end
end

local function paint()
	main.Text = on and "ออโต้คลิก: เปิด" or "ออโต้คลิก: ปิด"
	main.BackgroundColor3 = on and Color3.fromRGB(168, 85, 247) or Color3.fromRGB(44, 42, 62)
	lbl.Text = "ทุก " .. tostring(ladder[li]) .. " วิ"
	modeB.Text = "โหมด " .. mode .. ": " .. modes[mode]
	if mode == 1 or mode == 2 then act.Text = "ตั้งจุดแตะ"
	elseif mode == 3 then act.Text = "ใช้เครื่องมือในมือ"
	else act.Text = "เรียนรู้คำสั่ง (6 วิ)" end
	nextB.Visible = (mode == 4)
	marker.Visible = (point ~= nil) and (mode == 1 or mode == 2)
end

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
		local r = cands[ci]
		if r then
			pcall(function()
				if r.m == "InvokeServer" then r.remote:InvokeServer(table.unpack(r.args, 1, r.args.n))
				else r.remote:FireServer(table.unpack(r.args, 1, r.args.n)) end
			end)
		end
	end
end

local function blocked(n)
	local l = n:lower()
	for _, w in ipairs({"robux", "admin", "purchase", "buy", "gamepass", "product", "pay"}) do
		if l:find(w, 1, true) then return true end
	end
	return false
end

local function installHook()
	if hooked then return end
	hooked = true
	local cc = checkcaller or function() return false end
	hookOk = pcall(function()
		local old
		old = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
			if learning then
				local m = getnamecallmethod()
				if (m == "FireServer" or m == "InvokeServer") and not cc() then
					local pk = table.pack(...)
					pcall(function()
						if typeof(self) ~= "Instance" then return end
						if not (self:IsA("RemoteEvent") or self:IsA("RemoteFunction") or self:IsA("UnreliableRemoteEvent")) then return end
						local name = self:GetFullName()
						local sig = name .. "|" .. tostring(pk.n)
						local r = counts[sig]
						if not r then
							r = {remote = self, m = m, args = pk, name = name, n = 0}
							counts[sig] = r
							order[#order + 1] = sig
						end
						r.n = r.n + 1
					end)
				end
			end
			return old(self, ...)
		end))
	end)
end

local function startLearn()
	if learning then return end
	installHook()
	if not hookOk then setStatus("Executor นี้ดักคำสั่งเกมไม่ได้ ใช้โหมด 1-3 แทน"); return end
	counts, order = {}, {}
	learning = true
	for s = 6, 1, -1 do
		setStatus("กำลังเรียนรู้... แตะเล่นในเกมตามปกติ อีก " .. s .. " วิ")
		task.wait(1)
		if not alive then return end
	end
	learning = false
	local list = {}
	for _, sig in ipairs(order) do
		local r = counts[sig]
		if not blocked(r.name) then list[#list + 1] = r end
	end
	table.sort(list, function(a, b) return a.n > b.n end)
	cands = list
	ci = (#list > 0) and 1 or 0
	if ci == 0 then setStatus("ไม่พบคำสั่ง ลองแตะเล่นให้ถี่ขึ้นแล้วเรียนรู้ใหม่") else showCand() end
end

main.MouseButton1Click:Connect(function()
	on = not on
	paint()
	if on and mode == 4 and ci == 0 then setStatus("ยังไม่มีคำสั่ง กด เรียนรู้คำสั่ง ก่อน") end
	if on and (mode == 1 or mode == 2) and not VIM then setStatus("Executor นี้ไม่มี VirtualInputManager ลองโหมด 3 หรือ 4") end
end)
slow.MouseButton1Click:Connect(function() li = math.min(#ladder, li + 1); paint() end)
fast.MouseButton1Click:Connect(function() li = math.max(1, li - 1); paint() end)
modeB.MouseButton1Click:Connect(function()
	mode = mode % #modes + 1
	paint()
	if mode == 1 or mode == 2 then setStatus(point and "จะแตะที่จุดที่ตั้งไว้" or "ยังไม่ได้ตั้งจุดแตะ (จะแตะกลางจอ)")
	elseif mode == 3 then setStatus("สั่งใช้เครื่องมือที่ถืออยู่ซ้ำๆ")
	else setStatus(ci > 0 and "ใช้คำสั่งที่เรียนรู้ไว้" or "กด เรียนรู้คำสั่ง แล้วแตะเล่นในเกม") end
end)
act.MouseButton1Click:Connect(function()
	if mode == 1 or mode == 2 then
		picking = true
		setStatus("แตะที่จุดบนจอที่ต้องการให้กด (นอกกล่องนี้)")
	elseif mode == 3 then
		setStatus("โหมดนี้ไม่ต้องตั้งค่า ถืออาวุธไว้แล้วกดเปิด")
	else
		startLearn()
	end
end)
nextB.MouseButton1Click:Connect(function()
	if #cands > 0 then ci = ci % #cands + 1; showCand() end
end)

local function isPress(i) return i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 end
conns[#conns + 1] = UIS.InputBegan:Connect(function(i)
	if not picking or not isPress(i) then return end
	local p = Vector2.new(i.Position.X, i.Position.Y)
	local fp, fs = frame.AbsolutePosition, frame.AbsoluteSize
	if p.X >= fp.X and p.X <= fp.X + fs.X and p.Y >= fp.Y and p.Y <= fp.Y + fs.Y then return end
	picking = false
	point = p
	marker.Position = UDim2.fromOffset(p.X, p.Y)
	paint()
	setStatus("ตั้งจุดแตะแล้ว (วงม่วง)")
end)

local dragging, startIn, startPos = false, nil, nil
conns[#conns + 1] = drag.InputBegan:Connect(function(i)
	if isPress(i) then dragging = true; startIn = i.Position; startPos = frame.Position end
end)
conns[#conns + 1] = UIS.InputChanged:Connect(function(i)
	if dragging and (i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseMovement) then
		local d = i.Position - startIn
		frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
	end
end)
conns[#conns + 1] = UIS.InputEnded:Connect(function(i) if isPress(i) then dragging = false end end)

task.spawn(function()
	while alive do
		task.wait(ladder[li])
		if on and not learning then pcall(doClick) end
	end
end)

local function stop()
	alive = false; on = false; learning = false
	for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
	pcall(function() gui:Destroy() end)
	G.AC_STOP = nil
end
G.AC_STOP = stop
closeB.MouseButton1Click:Connect(stop)

paint()
setStatus("ลองเปิดแล้วดูว่าได้ของไหม ถ้าไม่ได้ กดเปลี่ยนโหมด")
