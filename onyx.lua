--!nonstrict
--[[
	╔═══════════════════════════════════════════════════════════════════╗
	║  ONYX UI  –  dark, shadcn-style component kit for Roblox (Luau)   ║
	╚═══════════════════════════════════════════════════════════════════╝

	Single file, zero dependencies. Use as a ModuleScript (require) or paste
	into a loadstring-able script.

	local Onyx = require(path.to.Onyx)
	local gui  = Onyx.CreateGui({ Name = "MyApp" })
	local win  = Onyx.Window({ Title = "Hello", Parent = gui })
	Onyx.Button({ Text = "Click me", Parent = win.Content, OnClick = function() print("hi") end })

	Every component:  Onyx.Component({ ...props, Parent = instance | component })
	returns a table with .Instance (root GuiObject), :Destroy(), and usually
	.Changed (signal) plus getters / setters.   See Demo.client.lua for all of them.

	COMPONENTS
	  Layout   : CreateGui, Window, Card, Stack, ScrollArea, Divider, Spacer
	  Text     : Text (h1 h2 h3 title body label muted small tiny code)
	  Actions  : Button (default secondary outline ghost destructive soft-danger link),
	             ButtonGroup, MediaControls, Badge
	  Inputs   : Input, Textarea, NumberInput, OTP, Checkbox, RadioGroup, Switch,
	             Slider, Select, Keybind, ColorPicker, Rating, Calendar
	  Display  : Alert, Avatar, UserChip, Progress, ProgressRing, Spinner, Table,
	             Breadcrumb, Pagination, Stepper, Carousel, Tabs, Segmented, Accordion
	  Overlays : Dialog, Confirm, Popover, Menu, Tooltip, Toast (Notify)
	  System   : SetTheme, RegisterTheme, RegisterIcon, Icon, Signal
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")

local Onyx = {}
Onyx.Version = "1.0.0"
Onyx.Animated = true

--==================================================================--
--  Signal / Maid
--==================================================================--
local Signal = {}
Signal.__index = Signal
local Connection = {}
Connection.__index = Connection

function Connection:Disconnect()
	self.Connected = false
	local i = table.find(self._sig._list, self)
	if i then table.remove(self._sig._list, i) end
end

function Signal.new()
	return setmetatable({ _list = {} }, Signal)
end
function Signal:Connect(fn)
	local c = setmetatable({ Connected = true, _fn = fn, _sig = self }, Connection)
	table.insert(self._list, c)
	return c
end
function Signal:Once(fn)
	local c
	c = self:Connect(function(...)
		c:Disconnect()
		fn(...)
	end)
	return c
end
function Signal:Wait()
	local co = coroutine.running()
	self:Once(function(...) task.spawn(co, ...) end)
	return coroutine.yield()
end
function Signal:Fire(...)
	for _, c in table.clone(self._list) do
		if c.Connected then task.spawn(c._fn, ...) end
	end
end
function Signal:DisconnectAll()
	for _, c in table.clone(self._list) do c.Connected = false end
	self._list = {}
end
Onyx.Signal = Signal

local Maid = {}
Maid.__index = Maid
function Maid.new() return setmetatable({ _t = {} }, Maid) end
function Maid:Give(x)
	table.insert(self._t, x)
	return x
end
function Maid:Clean()
	local t = self._t
	self._t = {}
	for _, x in t do
		local ty = typeof(x)
		if ty == "RBXScriptConnection" then x:Disconnect()
		elseif ty == "Instance" then x:Destroy()
		elseif ty == "function" then x()
		elseif ty == "table" then
			if x.Disconnect then x:Disconnect() elseif x.Destroy then x:Destroy() end
		end
	end
end

--==================================================================--
--  Theme
--==================================================================--
local function rgb(r, g, b) return Color3.fromRGB(r, g, b) end

local Themes = {
	Dark = {
		Name = "Dark",
		Background = rgb(9, 9, 11), Surface = rgb(17, 17, 20), SurfaceAlt = rgb(24, 24, 28),
		Elevated = rgb(30, 30, 35), Border = rgb(39, 39, 46), BorderStrong = rgb(63, 63, 72),
		Hover = rgb(34, 34, 40), Track = rgb(45, 45, 53),
		Text = rgb(250, 250, 250), TextMuted = rgb(161, 161, 170), TextDim = rgb(113, 113, 122),
		Primary = rgb(244, 244, 245), PrimaryHover = rgb(212, 212, 216), PrimaryText = rgb(9, 9, 11),
		Secondary = rgb(39, 39, 46), SecondaryHover = rgb(52, 52, 60), SecondaryText = rgb(250, 250, 250),
		Accent = rgb(59, 130, 246), AccentHover = rgb(37, 99, 235), AccentText = rgb(255, 255, 255), AccentSoft = rgb(23, 37, 84),
		Success = rgb(34, 197, 94), SuccessSoft = rgb(10, 46, 26),
		Warning = rgb(245, 158, 11), WarningSoft = rgb(54, 36, 8),
		Danger = rgb(239, 68, 68), DangerHover = rgb(220, 38, 38), DangerSoft = rgb(60, 16, 18),
		Info = rgb(59, 130, 246), InfoSoft = rgb(23, 37, 84),
		Scrim = rgb(0, 0, 0), Radius = 8,
	},
	Light = {
		Name = "Light",
		Background = rgb(255, 255, 255), Surface = rgb(250, 250, 250), SurfaceAlt = rgb(244, 244, 245),
		Elevated = rgb(255, 255, 255), Border = rgb(228, 228, 231), BorderStrong = rgb(212, 212, 216),
		Hover = rgb(244, 244, 245), Track = rgb(228, 228, 231),
		Text = rgb(9, 9, 11), TextMuted = rgb(113, 113, 122), TextDim = rgb(161, 161, 170),
		Primary = rgb(24, 24, 27), PrimaryHover = rgb(63, 63, 70), PrimaryText = rgb(250, 250, 250),
		Secondary = rgb(244, 244, 245), SecondaryHover = rgb(228, 228, 231), SecondaryText = rgb(24, 24, 27),
		Accent = rgb(37, 99, 235), AccentHover = rgb(29, 78, 216), AccentText = rgb(255, 255, 255), AccentSoft = rgb(219, 234, 254),
		Success = rgb(22, 163, 74), SuccessSoft = rgb(220, 252, 231),
		Warning = rgb(217, 119, 6), WarningSoft = rgb(254, 243, 199),
		Danger = rgb(220, 38, 38), DangerHover = rgb(185, 28, 28), DangerSoft = rgb(254, 226, 226),
		Info = rgb(37, 99, 235), InfoSoft = rgb(219, 234, 254),
		Scrim = rgb(0, 0, 0), Radius = 8,
	},
}
local Theme = {}
for k, v in Themes.Dark do Theme[k] = v end
Onyx.Theme = Theme
Onyx.Themes = Themes

local renderers = {}
local function reactive(inst, paint)
	renderers[inst] = paint
	inst.Destroying:Connect(function() renderers[inst] = nil end)
	paint(false)
end

function Onyx.SetTheme(theme)
	if type(theme) == "string" then theme = Themes[theme] end
	assert(type(theme) == "table", "Onyx.SetTheme: unknown theme")
	for k, v in theme do Theme[k] = v end
	for _, paint in table.clone(renderers) do pcall(paint, false) end
end
function Onyx.RegisterTheme(name, overrides, base)
	local t = table.clone(Themes[base or "Dark"])
	for k, v in overrides do t[k] = v end
	t.Name = name
	Themes[name] = t
	return t
end

local function color(c)
	if typeof(c) == "Color3" then return c end
	return Theme[c] or Theme.Text
end

--==================================================================--
--  Instance helpers
--==================================================================--
local FAMILY = "rbxasset://fonts/families/GothamSSm.json"
local Fonts = {
	Regular = Font.new(FAMILY, Enum.FontWeight.Regular),
	Medium = Font.new(FAMILY, Enum.FontWeight.Medium),
	SemiBold = Font.new(FAMILY, Enum.FontWeight.SemiBold),
	Bold = Font.new(FAMILY, Enum.FontWeight.Bold),
	Code = Font.fromEnum(Enum.Font.Code),
}
Onyx.Fonts = Fonts

local function New(class, props, children)
	local inst = Instance.new(class)
	props = props or {}
	if inst:IsA("GuiObject") then
		inst.BorderSizePixel = 0
		if props.BackgroundColor3 == nil and props.BackgroundTransparency == nil then
			inst.BackgroundTransparency = 1
		end
		if inst:IsA("GuiButton") then inst.AutoButtonColor = false end
		if inst:IsA("TextLabel") or inst:IsA("TextButton") or inst:IsA("TextBox") then
			inst.FontFace = Fonts.Regular
			inst.TextSize = 14
			inst.TextColor3 = Theme.Text
			inst.TextXAlignment = Enum.TextXAlignment.Left
			if not inst:IsA("TextBox") then inst.Text = "" end
		end
		if inst:IsA("ScrollingFrame") then
			inst.ScrollBarThickness = 3
			inst.ScrollBarImageColor3 = Theme.BorderStrong
			inst.CanvasSize = UDim2.new()
			inst.AutomaticCanvasSize = Enum.AutomaticSize.Y
			inst.ScrollingDirection = Enum.ScrollingDirection.Y
		end
	end
	local parent = props.Parent
	if type(parent) == "table" then parent = parent.Content or parent.Instance end
	for k, v in props do
		if k ~= "Parent" then inst[k] = v end
	end
	if children then
		for _, c in children do c.Parent = inst end
	end
	inst.Parent = parent
	return inst
end

local function Corner(parent, r)
	return New("UICorner", { CornerRadius = typeof(r) == "UDim" and r or UDim.new(0, r or Theme.Radius), Parent = parent })
end
local function Stroke(parent, col, thickness)
	return New("UIStroke", {
		Color = col or Theme.Border, Thickness = thickness or 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = parent,
	})
end
local function Pad(parent, a, b, c, d)
	local l, t, r, bt
	if b == nil then l, t, r, bt = a, a, a, a
	elseif c == nil then l, t, r, bt = a, b, a, b
	else l, t, r, bt = a, b, c, d end
	return New("UIPadding", {
		PaddingLeft = UDim.new(0, l), PaddingTop = UDim.new(0, t),
		PaddingRight = UDim.new(0, r), PaddingBottom = UDim.new(0, bt), Parent = parent,
	})
end
local function List(parent, o)
	o = o or {}
	return New("UIListLayout", {
		FillDirection = o.Horizontal and Enum.FillDirection.Horizontal or Enum.FillDirection.Vertical,
		Padding = UDim.new(0, o.Gap or 0),
		SortOrder = Enum.SortOrder.LayoutOrder,
		HorizontalAlignment = o.HAlign or Enum.HorizontalAlignment.Left,
		VerticalAlignment = o.VAlign or Enum.VerticalAlignment.Top,
		Wraps = o.Wraps or false,
		Parent = parent,
	})
end

local TWEEN = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local function tween(inst, props, animate, info)
	if animate and Onyx.Animated then
		TweenService:Create(inst, info or TWEEN, props):Play()
	else
		for k, v in props do inst[k] = v end
	end
end

local function Base(instance)
	local self = { Instance = instance, _maid = Maid.new(), Changed = Signal.new() }
	instance.Destroying:Connect(function() self._maid:Clean() end)
	function self:Destroy() instance:Destroy() end
	function self:SetVisible(v) instance.Visible = v end
	function self:Show() instance.Visible = true end
	function self:Hide() instance.Visible = false end
	return self
end

local function isPointer(i)
	return i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch
end

-- Press-and-drag helper. onUpdate(input, began)
local function drag(target, onUpdate, onDone)
	target.InputBegan:Connect(function(input)
		if not isPointer(input) then return end
		onUpdate(input, true)
		local c1, c2
		c1 = UserInputService.InputChanged:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.MouseMovement or i == input then onUpdate(i, false) end
		end)
		c2 = input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				c1:Disconnect()
				c2:Disconnect()
				if onDone then onDone() end
			end
		end)
	end)
end

-- pointer position in pixels relative to the top-left of `gui`
local function pointerLocal(input, gui)
	local layer = gui:FindFirstAncestorWhichIsA("ScreenGui")
	local inset = Vector2.zero
	if layer and layer.IgnoreGuiInset then inset = GuiService:GetGuiInset() end
	local p = Vector2.new(input.Position.X, input.Position.Y) + inset
	return p - gui.AbsolutePosition
end

local function utf8sub(s, n)
	local len = utf8.len(s)
	if len and len > n then return s:sub(1, utf8.offset(s, n + 1) - 1) end
	return s
end
local function commas(n)
	local s = tostring(math.floor(n))
	local formatted = s:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	return (formatted:gsub("^,", ""))
end

--==================================================================--
--  Icons  (drawn from UI primitives so they are crisp & theme-aware)
--==================================================================--
local IconDefs, CustomIcons = {}, {}
local function def(name, fn) IconDefs[name] = fn end

def("check", function(b) b.seg(.2, .52, .42, .74) b.seg(.42, .74, .82, .3) end)
def("x", function(b) b.seg(.25, .25, .75, .75) b.seg(.75, .25, .25, .75) end)
def("plus", function(b) b.seg(.2, .5, .8, .5) b.seg(.5, .2, .5, .8) end)
def("minus", function(b) b.seg(.2, .5, .8, .5) end)
def("dash", function(b) b.seg(.2, .5, .8, .5) end)
def("chevron-down", function(b) b.seg(.22, .38, .5, .66) b.seg(.5, .66, .78, .38) end)
def("chevron-up", function(b) b.seg(.22, .62, .5, .34) b.seg(.5, .34, .78, .62) end)
def("chevron-right", function(b) b.seg(.38, .22, .66, .5) b.seg(.66, .5, .38, .78) end)
def("chevron-left", function(b) b.seg(.62, .22, .34, .5) b.seg(.34, .5, .62, .78) end)
def("chevrons-up-down", function(b)
	b.seg(.3, .4, .5, .2) b.seg(.5, .2, .7, .4) b.seg(.3, .6, .5, .8) b.seg(.5, .8, .7, .6)
end)
def("search", function(b) b.ring(.45, .45, .58) b.seg(.68, .68, .86, .86) end)
def("star", function(b) b.glyph("★", .95) end)
def("star-outline", function(b) b.glyph("☆", .95) end)
def("heart", function(b) b.glyph("♥", .95) end)
def("heart-outline", function(b) b.glyph("♡", .95) end)
def("trash", function(b)
	b.seg(.16, .26, .84, .26)
	b.seg(.38, .26, .38, .14) b.seg(.38, .14, .62, .14) b.seg(.62, .14, .62, .26)
	b.rect(.24, .32, .52, .56, .12)
	b.seg(.42, .46, .42, .74) b.seg(.58, .46, .58, .74)
end)
def("user", function(b)
	b.clip()
	b.ring(.5, .3, .32)
	b.ring(.5, .98, .72)
end)
def("file", function(b) b.rect(.2, .1, .6, .8, .12) b.seg(.34, .42, .66, .42) b.seg(.34, .62, .66, .62) end)
def("image", function(b)
	b.rect(.1, .18, .8, .64, .12) b.ring(.34, .4, .14, true)
	b.seg(.16, .72, .42, .5) b.seg(.42, .5, .62, .68) b.seg(.62, .68, .84, .54)
end)
def("bookmark", function(b) b.rect(.27, .1, .46, .8, .1) b.seg(.5, .72, .5, .72) end)
def("settings", function(b)
	b.ring(.5, .5, .5)
	b.ring(.5, .5, .16)
	for k = 0, 7 do
		local a = k * math.pi / 4
		b.seg(.5 + .31 * math.cos(a), .5 + .31 * math.sin(a), .5 + .42 * math.cos(a), .5 + .42 * math.sin(a), b.t * 1.7)
	end
end)
def("home", function(b) b.seg(.12, .5, .5, .16) b.seg(.5, .16, .88, .5) b.rect(.25, .48, .5, .38, .06) end)
def("archive", function(b) b.rect(.1, .16, .8, .22, .1) b.rect(.17, .38, .66, .46, .08) b.seg(.4, .56, .6, .56) end)
def("info", function(b) b.ring(.5, .5, .86) b.seg(.5, .46, .5, .7) b.ring(.5, .3, .1, true) end)
def("alert", function(b) b.ring(.5, .5, .86) b.seg(.5, .28, .5, .55) b.ring(.5, .71, .1, true) end)
def("circle-check", function(b) b.ring(.5, .5, .86) b.seg(.32, .52, .45, .65) b.seg(.45, .65, .7, .37) end)
def("circle-x", function(b) b.ring(.5, .5, .86) b.seg(.36, .36, .64, .64) b.seg(.64, .36, .36, .64) end)
def("bell", function(b) b.rect(.24, .14, .52, .56, .45) b.seg(.15, .72, .85, .72) b.ring(.5, .86, .1, true) end)
def("calendar", function(b)
	b.rect(.12, .2, .76, .68, .1) b.seg(.12, .42, .88, .42) b.seg(.32, .1, .32, .28) b.seg(.68, .1, .68, .28)
end)
def("mail", function(b) b.rect(.1, .22, .8, .56, .1) b.seg(.12, .3, .5, .58) b.seg(.5, .58, .88, .3) end)
def("lock", function(b) b.rect(.2, .45, .6, .42, .1) b.rect(.3, .12, .4, .6, .5) end)
def("credit-card", function(b) b.rect(.08, .22, .84, .56, .1) b.seg(.08, .42, .92, .42) b.seg(.22, .64, .4, .64) end)
def("dot", function(b) b.ring(.5, .5, .32, true) end)
def("menu", function(b) b.seg(.18, .3, .82, .3) b.seg(.18, .5, .82, .5) b.seg(.18, .7, .82, .7) end)
def("play", function(b)
	for i = 0, 14 do
		local y = .16 + (.68 * i / 14)
		local w = .52 * (1 - math.abs(y - .5) / .36)
		b.seg(.3, y, .3 + math.max(w, 0), y, .075)
	end
end)
def("pause", function(b) b.rect(.26, .2, .17, .6, .1, true) b.rect(.57, .2, .17, .6, .1, true) end)
def("stop", function(b) b.rect(.24, .24, .52, .52, .12, true) end)
def("github", function(b) b.ring(.5, .5, .86) b.glyph("G", .55) end)
def("google", function(b) b.glyph("G", .95) end)
def("apple", function(b) b.ring(.5, .5, .86) b.glyph("A", .55) end)

local function makeIcon(name, size, col, parent)
	size = size or 16
	local custom = CustomIcons[name]
	local asset = custom and custom.Image
	if not asset and type(name) == "number" then asset = "rbxassetid://" .. name end
	if not asset and type(name) == "string" and name:find("^rbxasset") then asset = name end

	local box = New("Frame", {
		Name = "Icon", Size = UDim2.fromOffset(size, size), Parent = parent,
		ClipsDescendants = false,
	})
	local parts = {}
	local cur = color(col or "Text")
	local obj = { Instance = box }

	local function add(inst, prop)
		table.insert(parts, { inst, prop })
		inst[prop] = cur
	end

	if asset then
		local img = New("ImageLabel", { Size = UDim2.fromScale(1, 1), Image = asset, Parent = box })
		if custom and custom.RectOffset then img.ImageRectOffset = custom.RectOffset img.ImageRectSize = custom.RectSize end
		add(img, "ImageColor3")
	else
		local th = math.max(1, size * 0.09)
		local t = th / size
		local b = { t = t }
		function b.clip() box.ClipsDescendants = true end
		function b.seg(ax, ay, bx, by, w)
			w = w or t
			local dx, dy = bx - ax, by - ay
			local len = math.sqrt(dx * dx + dy * dy)
			local f = New("Frame", {
				AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromScale((ax + bx) / 2, (ay + by) / 2),
				Size = UDim2.fromScale(len + w, w), Rotation = math.deg(math.atan2(dy, dx)),
				BackgroundTransparency = 0, Parent = box,
			}, { New("UICorner", { CornerRadius = UDim.new(.5, 0) }) })
			add(f, "BackgroundColor3")
		end
		function b.rect(x, y, w, h, r, filled)
			local ins = filled and 0 or t
			local f = New("Frame", {
				Position = UDim2.fromScale(x + ins / 2, y + ins / 2), Size = UDim2.fromScale(w - ins, h - ins),
				BackgroundTransparency = filled and 0 or 1, Parent = box,
			})
			New("UICorner", { CornerRadius = UDim.new(r or 0, 0), Parent = f })
			if filled then add(f, "BackgroundColor3")
			else add(New("UIStroke", { Thickness = th, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = f }), "Color") end
		end
		function b.ring(cx, cy, d, filled) b.rect(cx - d / 2, cy - d / 2, d, d, .5, filled) end
		function b.glyph(txt, s)
			local l = New("TextLabel", {
				Size = UDim2.fromScale(1, 1), Text = txt, TextSize = math.floor(size * s),
				FontFace = Fonts.Bold, TextXAlignment = Enum.TextXAlignment.Center, Parent = box,
			})
			add(l, "TextColor3")
		end
		local fn = IconDefs[name] or IconDefs.dot
		fn(b)
	end

	function obj:SetColor(c)
		cur = color(c)
		for _, p in parts do p[1][p[2]] = cur end
	end
	return obj
end

function Onyx.Icon(name, size, col, parent) return makeIcon(name, size, col, parent) end
function Onyx.RegisterIcon(name, image, rectOffset, rectSize)
	if type(image) == "number" then image = "rbxassetid://" .. image end
	CustomIcons[name] = { Image = image, RectOffset = rectOffset, RectSize = rectSize }
end

--==================================================================--
--  Roots, overlays, layers
--==================================================================--
local defaultGui

local function defaultParent()
	local ok, hui = pcall(function()
		local env = getfenv()
		return env.gethui and env.gethui()
	end)
	if ok and hui then return hui end
	local lp = Players.LocalPlayer
	if lp then return lp:WaitForChild("PlayerGui") end
	return game:GetService("CoreGui")
end

function Onyx.CreateGui(props)
	props = props or {}
	local gui = Instance.new("ScreenGui")
	gui.Name = props.Name or "Onyx"
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.IgnoreGuiInset = props.IgnoreGuiInset ~= false
	gui.DisplayOrder = props.DisplayOrder or 100
	gui.Parent = props.Parent or defaultParent()
	defaultGui = defaultGui or gui
	return gui
end
function Onyx.SetRoot(gui) defaultGui = gui end
function Onyx.GetRoot()
	if not defaultGui or not defaultGui.Parent then defaultGui = Onyx.CreateGui({ Name = "OnyxRoot" }) end
	return defaultGui
end

local function getOverlay(anchor)
	local gui = anchor and anchor:FindFirstAncestorWhichIsA("LayerCollector") or Onyx.GetRoot()
	local ov = gui:FindFirstChild("OnyxOverlay")
	if not ov then
		ov = New("Frame", { Name = "OnyxOverlay", Size = UDim2.fromScale(1, 1), ZIndex = 100, Parent = gui })
	end
	return ov, gui
end

local layerCounter = 0
local layerStack = {}
local escConn

local function openLayer(anchor, o)
	o = o or {}
	local ov = getOverlay(anchor)
	layerCounter += 2
	local z = 100 + layerCounter
	local layer = { Open = true, Overlay = ov }
	local blocker = New("TextButton", {
		Name = "Blocker", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Theme.Scrim,
		BackgroundTransparency = 1, ZIndex = z, Parent = ov,
	})
	local host = New("Frame", {
		Name = "Layer", AutomaticSize = Enum.AutomaticSize.XY, Size = UDim2.new(),
		Position = UDim2.fromOffset(-10000, -10000), ZIndex = z + 1, Parent = ov,
	})
	layer.Host, layer.Blocker = host, blocker
	if o.Dim then tween(blocker, { BackgroundTransparency = 0.45 }, true, TweenInfo.new(0.2)) end

	local side, align, off = o.Side or "bottom", o.Align or "start", o.Offset or 6
	function layer.Place()
		if not layer.Open then return end
		local cs, vs = host.AbsoluteSize, ov.AbsoluteSize
		local x, y
		if o.Center then
			x, y = (vs.X - cs.X) / 2, (vs.Y - cs.Y) / 2
		elseif o.At then
			x, y = o.At.X - ov.AbsolutePosition.X, o.At.Y - ov.AbsolutePosition.Y
		else
			local ap, as = anchor.AbsolutePosition - ov.AbsolutePosition, anchor.AbsoluteSize
			if side == "bottom" or side == "top" then
				y = side == "bottom" and ap.Y + as.Y + off or ap.Y - cs.Y - off
				if side == "bottom" and y + cs.Y > vs.Y - 8 and ap.Y - cs.Y - off > 8 then y = ap.Y - cs.Y - off end
				if align == "start" then x = ap.X elseif align == "end" then x = ap.X + as.X - cs.X else x = ap.X + (as.X - cs.X) / 2 end
			else
				x = side == "right" and ap.X + as.X + off or ap.X - cs.X - off
				if align == "start" then y = ap.Y elseif align == "end" then y = ap.Y + as.Y - cs.Y else y = ap.Y + (as.Y - cs.Y) / 2 end
			end
		end
		x = math.clamp(x, 8, math.max(8, vs.X - cs.X - 8))
		y = math.clamp(y, 8, math.max(8, vs.Y - cs.Y - 8))
		host.Position = UDim2.fromOffset(x, y)
	end
	if o.Center then host.AnchorPoint = Vector2.zero end
	if o.MatchWidth and anchor then host.Size = UDim2.fromOffset(anchor.AbsoluteSize.X, 0) end
	host:GetPropertyChangedSignal("AbsoluteSize"):Connect(layer.Place)
	task.defer(function()
		RunService.Heartbeat:Wait()
		layer.Place()
	end)

	function layer.Close()
		if not layer.Open then return end
		layer.Open = false
		local i = table.find(layerStack, layer)
		if i then table.remove(layerStack, i) end
		if o.OnClose then o.OnClose() end
		for _, c in host:GetChildren() do
			if c:IsA("GuiObject") then c.Parent = nil end
		end
		host:Destroy()
		blocker:Destroy()
	end
	blocker.Activated:Connect(function()
		if o.Dismiss ~= false then layer.Close() end
	end)
	layer.Dismissable = o.Dismiss ~= false
	table.insert(layerStack, layer)
	if not escConn then
		escConn = UserInputService.InputBegan:Connect(function(input, gp)
			if input.KeyCode == Enum.KeyCode.Escape then
				local top = layerStack[#layerStack]
				if top and top.Dismissable then top.Close() end
			end
		end)
	end
	return layer
end

--==================================================================--
--  Layout primitives
--==================================================================--
local Align = {
	left = Enum.HorizontalAlignment.Left, center = Enum.HorizontalAlignment.Center, right = Enum.HorizontalAlignment.Right,
}
local VAlign = { top = Enum.VerticalAlignment.Top, center = Enum.VerticalAlignment.Center, bottom = Enum.VerticalAlignment.Bottom }

-- Stack: auto-sized vertical/horizontal layout container
function Onyx.Stack(props)
	props = props or {}
	local fit = props.Fit or (props.Horizontal and "Y" or "Y")
	local f = New("Frame", {
		Name = props.Name or "Stack", LayoutOrder = props.LayoutOrder,
		Size = props.Size or UDim2.new(props.Width and 0 or 1, props.Width or 0, 0, props.Height or 0),
		AutomaticSize = Enum.AutomaticSize[fit], Parent = props.Parent,
	})
	List(f, {
		Horizontal = props.Horizontal, Gap = props.Gap or 8, Wraps = props.Wrap,
		HAlign = Align[props.Align or "left"], VAlign = VAlign[props.VAlign or "top"],
	})
	if props.Padding then
		if type(props.Padding) == "table" then Pad(f, table.unpack(props.Padding)) else Pad(f, props.Padding) end
	end
	local self = Base(f)
	self.Content = f
	return self
end

function Onyx.Spacer(props)
	props = props or {}
	return Base(New("Frame", { Name = "Spacer", Size = UDim2.fromOffset(props.Width or 1, props.Height or 8), LayoutOrder = props.LayoutOrder, Parent = props.Parent }))
end

function Onyx.Divider(props)
	props = props or {}
	if props.Vertical then
		local f = New("Frame", { Name = "Divider", Size = UDim2.new(0, 1, 1, 0), BackgroundColor3 = Theme.Border, BackgroundTransparency = 0, LayoutOrder = props.LayoutOrder, Parent = props.Parent })
		reactive(f, function() f.BackgroundColor3 = Theme.Border end)
		return Base(f)
	end
	local root = New("Frame", { Name = "Divider", Size = UDim2.new(1, 0, 0, props.Text and 16 or 1), LayoutOrder = props.LayoutOrder, Parent = props.Parent })
	local l1 = New("Frame", { AnchorPoint = Vector2.new(0, .5), Position = UDim2.fromScale(0, .5), Size = UDim2.new(1, 0, 0, 1), BackgroundTransparency = 0, Parent = root })
	local lbl
	if props.Text then
		lbl = New("TextLabel", {
			AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromScale(.5, .5), AutomaticSize = Enum.AutomaticSize.XY,
			Text = props.Text, TextSize = 12, BackgroundTransparency = 0, Parent = root,
		})
		Pad(lbl, 8, 0)
	end
	reactive(root, function()
		l1.BackgroundColor3 = Theme.Border
		if lbl then lbl.TextColor3 = Theme.TextMuted lbl.BackgroundColor3 = props.Background and color(props.Background) or Theme.Surface end
	end)
	return Base(root)
end

-- Text
local TextStyles = {
	h1 = { "Bold", 28, "Text" }, h2 = { "Bold", 22, "Text" }, h3 = { "SemiBold", 18, "Text" },
	title = { "SemiBold", 15, "Text" }, body = { "Regular", 14, "Text" }, label = { "Medium", 13, "Text" },
	muted = { "Regular", 13, "TextMuted" }, small = { "Regular", 12, "TextMuted" }, tiny = { "Regular", 11, "TextDim" },
	code = { "Code", 12, "Text" },
}
function Onyx.Text(props)
	props = props or {}
	local s = TextStyles[props.Variant or "body"] or TextStyles.body
	local wrap = props.Wrap
	local l = New("TextLabel", {
		Name = props.Name or "Text", Text = props.Text or "", FontFace = Fonts[props.Bold and "Bold" or s[1]], TextSize = props.Size or s[2],
		AutomaticSize = wrap and Enum.AutomaticSize.Y or Enum.AutomaticSize.XY,
		Size = wrap and UDim2.new(1, 0, 0, 0) or UDim2.new(),
		TextWrapped = wrap or false, RichText = props.RichText or false, LayoutOrder = props.LayoutOrder,
		TextXAlignment = Enum.TextXAlignment[props.TextAlign or "Left"], Parent = props.Parent,
	})
	reactive(l, function() l.TextColor3 = color(props.Color or s[3]) end)
	local self = Base(l)
	function self:SetText(t) l.Text = t end
	function self:GetText() return l.Text end
	return self
end
Onyx.Label = Onyx.Text

-- Optional label / hint wrapper used by inputs. Returns (root, body, setHint)
local function Field(props, parent)
	if not (props.Label or props.Description) then
		local body = New("Frame", {
			Size = props.Width and UDim2.fromOffset(props.Width, 0) or UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = props.LayoutOrder, Parent = parent,
		})
		return body, body, function() end
	end
	local root = New("Frame", {
		Size = props.Width and UDim2.fromOffset(props.Width, 0) or UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = props.LayoutOrder, Parent = parent,
	})
	List(root, { Gap = 6 })
	if props.Label then Onyx.Text({ Text = props.Label, Variant = "label", Parent = root }).Instance.LayoutOrder = 1 end
	local body = New("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 2, Parent = root })
	local hint = Onyx.Text({ Text = props.Description or "", Variant = "small", Wrap = true, Parent = root })
	hint.Instance.LayoutOrder = 3
	hint.Instance.Visible = props.Description ~= nil
	local function setHint(text, isError)
		hint.Instance.Visible = text ~= nil and text ~= ""
		hint:SetText(text or "")
		hint.Instance.TextColor3 = isError and Theme.Danger or Theme.TextMuted
	end
	return root, body, setHint
end

--==================================================================--
--  Button / Badge
--==================================================================--
local ButtonVariants = {
	default = { bg = "Primary", hover = "PrimaryHover", fg = "PrimaryText" },
	secondary = { bg = "Secondary", hover = "SecondaryHover", fg = "SecondaryText" },
	outline = { hover = "Hover", fg = "Text", stroke = "Border", bg = "Surface", alwaysBg = true },
	ghost = { hover = "Hover", fg = "Text" },
	destructive = { bg = "Danger", hover = "DangerHover", fg = "AccentText" },
	["soft-danger"] = { bg = "DangerSoft", hover = "DangerSoft", fg = "Danger", stroke = "Danger" },
	["soft-success"] = { bg = "SuccessSoft", hover = "SuccessSoft", fg = "Success", stroke = "Success" },
	accent = { bg = "Accent", hover = "AccentHover", fg = "AccentText" },
	link = { fg = "Accent", hover = "Hover" },
}
local ButtonSizes = { sm = { h = 28, text = 12, pad = 10 }, md = { h = 34, text = 13, pad = 14 }, lg = { h = 42, text = 14, pad = 18 } }

function Onyx.Button(props)
	props = props or {}
	local v = ButtonVariants[props.Variant or "default"] or ButtonVariants.default
	local sz = ButtonSizes[props.Size or "md"] or ButtonSizes.md
	local iconOnly = props.Icon and not props.Text
	local btn = New("TextButton", {
		Name = props.Name or "Button", BackgroundTransparency = 0, LayoutOrder = props.LayoutOrder, Parent = props.Parent,
	})
	if props.FullWidth then btn.Size = UDim2.new(1, 0, 0, sz.h)
	elseif props.Width then btn.Size = UDim2.fromOffset(props.Width, sz.h)
	elseif iconOnly then btn.Size = UDim2.fromOffset(sz.h, sz.h)
	else btn.Size = UDim2.fromOffset(0, sz.h) btn.AutomaticSize = Enum.AutomaticSize.X end
	Corner(btn, props.Round and 999 or 6)
	local stroke = Stroke(btn)
	if not iconOnly then Pad(btn, sz.pad, 0) end
	List(btn, { Horizontal = true, Gap = 8, HAlign = Enum.HorizontalAlignment.Center, VAlign = Enum.VerticalAlignment.Center })

	local self = Base(btn)
	self.Clicked = self.Changed
	local hover, pressed = false, false
	local disabled, loading = props.Disabled or false, false
	local iconL, iconR, spinner, label
	local iconSize = props.IconSize or (sz.text + 3)
	if props.Icon then iconL = makeIcon(props.Icon, iconSize, v.fg, btn) iconL.Instance.LayoutOrder = 1 end
	if props.Text then
		label = New("TextLabel", {
			Text = props.Text, FontFace = Fonts.Medium, TextSize = sz.text, AutomaticSize = Enum.AutomaticSize.XY,
			TextXAlignment = Enum.TextXAlignment.Center, LayoutOrder = 2, Parent = btn,
		})
	end
	if props.IconRight then iconR = makeIcon(props.IconRight, iconSize, v.fg, btn) iconR.Instance.LayoutOrder = 3 end

	local function paint(animate)
		local bg, bgT = Theme.Hover, 1
		if v.bg then bg, bgT = Theme[v.bg], 0 end
		if hover and not disabled and v.hover then bg, bgT = Theme[v.hover], 0 end
		if pressed and not disabled and bgT == 0 then bg = bg:Lerp(Color3.new(0, 0, 0), .12) end
		if disabled and bgT == 0 then bgT = .5 end
		tween(btn, { BackgroundColor3 = bg, BackgroundTransparency = bgT }, animate)
		tween(stroke, { Color = Theme[v.stroke or "Border"], Transparency = v.stroke and (disabled and .6 or 0) or 1 }, animate)
		local fg = Theme[v.fg]
		if label then label.TextColor3 = fg label.TextTransparency = disabled and .5 or 0 end
		if iconL then iconL:SetColor(fg) end
		if iconR then iconR:SetColor(fg) end
	end
	reactive(btn, paint)

	btn.MouseEnter:Connect(function() hover = true paint(true) end)
	btn.MouseLeave:Connect(function() hover, pressed = false, false paint(true) end)
	btn.MouseButton1Down:Connect(function() pressed = true paint(true) end)
	btn.MouseButton1Up:Connect(function() pressed = false paint(true) end)
	btn.Activated:Connect(function()
		if disabled or loading then return end
		self.Changed:Fire()
		if props.OnClick then props.OnClick() end
	end)

	function self:SetText(t) if label then label.Text = t end end
	function self:SetDisabled(d) disabled = d paint(true) end
	function self:SetLoading(l)
		loading = l
		if l and not spinner then
			spinner = Onyx.Spinner({ Size = iconSize, Color = v.fg, Parent = btn })
			spinner.Instance.LayoutOrder = 0
		elseif not l and spinner then spinner:Destroy() spinner = nil end
		if iconL then iconL.Instance.Visible = not l end
	end
	function self:SetIcon(n)
		if iconL then iconL.Instance:Destroy() end
		iconL = makeIcon(n, iconSize, v.fg, btn) iconL.Instance.LayoutOrder = 1
	end
	if props.Tooltip then Onyx.Tooltip(btn, props.Tooltip) end
	return self
end

function Onyx.ButtonGroup(props)
	local root = New("Frame", {
		Name = "ButtonGroup", AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 34),
		BackgroundTransparency = 0, LayoutOrder = props.LayoutOrder, Parent = props.Parent,
	})
	Corner(root, 6)
	local st = Stroke(root)
	List(root, { Horizontal = true })
	reactive(root, function() root.BackgroundColor3 = Theme.Surface st.Color = Theme.Border end)
	local self = Base(root)
	self.Buttons = {}
	for i, b in props.Buttons or {} do
		if i > 1 then Onyx.Divider({ Vertical = true, Parent = root }).Instance.LayoutOrder = i * 2 - 1 end
		b.Variant = b.Variant or "ghost"
		b.Parent = root
		b.LayoutOrder = i * 2
		self.Buttons[i] = Onyx.Button(b)
	end
	return self
end

function Onyx.MediaControls(props)
	props = props or {}
	local playing = props.Playing or false
	local group
	local function build()
		if group then group:Destroy() end
		group = Onyx.ButtonGroup({ Parent = props.Parent, Buttons = {
			{ Icon = "chevron-left", OnClick = props.OnPrev },
			{ Icon = playing and "pause" or "play", OnClick = function()
				playing = not playing
				if playing and props.OnPlay then props.OnPlay() elseif not playing and props.OnPause then props.OnPause() end
				build()
			end },
			{ Icon = "stop", OnClick = function() playing = false if props.OnStop then props.OnStop() end build() end },
			{ Icon = "chevron-right", OnClick = props.OnNext },
		} })
	end
	build()
	local self = { Instance = nil }
	setmetatable(self, { __index = function(_, k) if k == "Instance" then return group.Instance end end })
	function self:Destroy() group:Destroy() end
	return self
end

local BadgeVariants = {
	default = { "SurfaceAlt", "Text", "BorderStrong" }, secondary = { "Secondary", "SecondaryText", "Secondary" },
	outline = { nil, "Text", "Border" }, primary = { "Primary", "PrimaryText", "Primary" },
	success = { "SuccessSoft", "Success", "Success" }, warning = { "WarningSoft", "Warning", "Warning" },
	danger = { "DangerSoft", "Danger", "Danger" }, info = { "InfoSoft", "Info", "Info" },
}
function Onyx.Badge(props)
	local v = BadgeVariants[props.Variant or "default"] or BadgeVariants.default
	local f = New("Frame", {
		Name = "Badge", AutomaticSize = Enum.AutomaticSize.X, Size = props.Width and UDim2.fromOffset(props.Width, props.Height or 24) or UDim2.fromOffset(0, props.Height or 22),
		BackgroundTransparency = 0, LayoutOrder = props.LayoutOrder, Parent = props.Parent,
	})
	if props.Width then f.AutomaticSize = Enum.AutomaticSize.None end
	Corner(f, props.Square and 6 or 999)
	local st = Stroke(f)
	Pad(f, 10, 0)
	List(f, { Horizontal = true, Gap = 5, HAlign = Enum.HorizontalAlignment.Center, VAlign = Enum.VerticalAlignment.Center })
	local lbl = New("TextLabel", { Text = props.Text or "", FontFace = Fonts.Medium, TextSize = 12, AutomaticSize = Enum.AutomaticSize.XY, TextXAlignment = Enum.TextXAlignment.Center, LayoutOrder = 2, Parent = f })
	local ic = props.Icon and makeIcon(props.Icon, 12, v[2], f)
	if ic then ic.Instance.LayoutOrder = 1 end
	reactive(f, function()
		f.BackgroundColor3 = v[1] and Theme[v[1]] or Theme.Background
		f.BackgroundTransparency = v[1] and 0 or 1
		st.Color = Theme[v[3]]
		lbl.TextColor3 = Theme[v[2]]
		if ic then ic:SetColor(v[2]) end
	end)
	local self = Base(f)
	function self:SetText(t) lbl.Text = t end
	return self
end

--==================================================================--
--  Spinner / Progress / ProgressRing
--==================================================================--
function Onyx.Spinner(props)
	props = props or {}
	local size = props.Size or 24
	local root = New("Frame", { Name = "Spinner", Size = UDim2.fromOffset(size, size), LayoutOrder = props.LayoutOrder, Parent = props.Parent })
	local n, d = 8, size * 0.2
	local r = size / 2 - d / 2
	local dots = {}
	for i = 1, n do
		local a = (i - 1) / n * math.pi * 2 - math.pi / 2
		dots[i] = New("Frame", {
			AnchorPoint = Vector2.new(.5, .5), Position = UDim2.new(.5, math.cos(a) * r, .5, math.sin(a) * r),
			Size = UDim2.fromOffset(d, d), BackgroundTransparency = 0, Parent = root,
		}, { New("UICorner", { CornerRadius = UDim.new(1, 0) }) })
	end
	local col = props.Color or "Text"
	reactive(root, function() for _, dot in dots do dot.BackgroundColor3 = color(col) end end)
	local self = Base(root)
	self._maid:Give(RunService.Heartbeat:Connect(function()
		local t = os.clock() * 1.2
		for i, dot in dots do
			local ph = (t - (i - 1) / n) % 1
			dot.BackgroundTransparency = ph * 0.85
			local s = d * (1 - 0.5 * ph)
			dot.Size = UDim2.fromOffset(s, s)
		end
	end))
	return self
end

function Onyx.Progress(props)
	props = props or {}
	local max, value = props.Max or 100, props.Value or 0
	local h = props.Height or 8
	local root = New("Frame", { Name = "Progress", Size = UDim2.new(1, 0, 0, math.max(h, 16)), LayoutOrder = props.LayoutOrder, Parent = props.Parent })
	local labelW = props.ShowValue and 44 or 0
	local track = New("Frame", {
		AnchorPoint = Vector2.new(0, .5), Position = UDim2.fromScale(0, .5), Size = UDim2.new(1, -labelW, 0, h),
		BackgroundTransparency = 0, ClipsDescendants = true, Parent = root,
	})
	Corner(track, 999)
	local fill = New("Frame", { Size = UDim2.fromScale(0, 1), BackgroundTransparency = 0, Parent = track })
	Corner(fill, 999)
	local lbl
	if props.ShowValue then
		lbl = New("TextLabel", {
			AnchorPoint = Vector2.new(1, .5), Position = UDim2.fromScale(1, .5), Size = UDim2.fromOffset(40, 16),
			TextXAlignment = Enum.TextXAlignment.Right, TextSize = 12, FontFace = Fonts.Medium, Parent = root,
		})
	end
	reactive(root, function()
		track.BackgroundColor3 = Theme.Track
		fill.BackgroundColor3 = color(props.Color or "Accent")
		if lbl then lbl.TextColor3 = Theme.TextMuted end
	end)
	local self = Base(root)
	function self:SetValue(v, animate)
		value = math.clamp(v, 0, max)
		tween(fill, { Size = UDim2.fromScale(value / max, 1) }, animate ~= false, TweenInfo.new(.3, Enum.EasingStyle.Quad))
		if lbl then lbl.Text = math.floor(value / max * 100 + .5) .. "%" end
		self.Changed:Fire(value)
	end
	function self:GetValue() return value end
	self:SetValue(value, false)
	return self
end

function Onyx.ProgressRing(props)
	props = props or {}
	local S, T = props.Size or 56, props.Thickness or 5
	local max, value = props.Max or 100, props.Value or 0
	local inner = S - 2 * T
	local root = New("Frame", { Name = "ProgressRing", Size = UDim2.fromOffset(S, S), LayoutOrder = props.LayoutOrder, Parent = props.Parent })
	local track = New("Frame", { Size = UDim2.fromOffset(inner, inner), Position = UDim2.fromOffset(T, T), Parent = root })
	Corner(track, 999)
	local trackStroke = Stroke(track, Theme.Track, T)
	local strokes, grads = {}, {}
	local seq = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(.5, 0),
		NumberSequenceKeypoint.new(.501, 1), NumberSequenceKeypoint.new(1, 1),
	})
	for _, right in { true, false } do
		local holder = New("Frame", {
			Size = UDim2.fromOffset(S / 2, S), Position = right and UDim2.fromOffset(S / 2, 0) or UDim2.new(),
			ClipsDescendants = true, Parent = root,
		})
		local c = New("Frame", {
			Size = UDim2.fromOffset(inner, inner),
			Position = right and UDim2.fromOffset(T - S / 2, T) or UDim2.fromOffset(T, T), Parent = holder,
		})
		Corner(c, 999)
		local st = Stroke(c, Theme.Accent, T)
		local g = New("UIGradient", { Transparency = seq, Rotation = right and 0 or 180, Parent = st })
		table.insert(strokes, st)
		grads[right and "R" or "L"] = g
	end
	local lbl
	if props.ShowValue ~= false then
		lbl = New("TextLabel", {
			Size = UDim2.fromScale(1, 1), TextXAlignment = Enum.TextXAlignment.Center,
			FontFace = Fonts.SemiBold, TextSize = math.max(10, math.floor(S * .24)), Parent = root,
		})
	end
	reactive(root, function()
		trackStroke.Color = Theme.Track
		for _, st in strokes do st.Color = color(props.Color or "Accent") end
		if lbl then lbl.TextColor3 = Theme.Text end
	end)
	local self = Base(root)
	function self:SetValue(v)
		value = math.clamp(v, 0, max)
		local ang = value / max * 360
		grads.R.Rotation = math.clamp(ang, 0, 180)
		grads.L.Rotation = math.clamp(ang, 180, 360)
		if lbl then lbl.Text = math.floor(value / max * 100 + .5) .. "%" end
		self.Changed:Fire(value)
	end
	function self:GetValue() return value end
	self:SetValue(value)
	return self
end

--==================================================================--
--  Text inputs
--==================================================================--
function Onyx.Input(props)
	props = props or {}
	local root, body, setHint = Field(props, props.Parent)
	local h = props.Height or 34
	local box = New("Frame", { Name = "Input", Size = UDim2.new(1, 0, 0, h), BackgroundTransparency = 0, Parent = body })
	Corner(box, 6)
	local st = Stroke(box)
	Pad(box, 10, 0)
	List(box, { Horizontal = true, Gap = 8, VAlign = Enum.VerticalAlignment.Center })
	local icon = props.Icon and makeIcon(props.Icon, 15, "TextDim", box)
	if icon then icon.Instance.LayoutOrder = 1 end
	local tb = New("TextBox", {
		Name = "Box", Size = UDim2.new(1, icon and -23 or 0, 1, 0), LayoutOrder = 2,
		PlaceholderText = props.Placeholder or "", Text = "", ClearTextOnFocus = false,
		TextSize = 13, TextTruncate = Enum.TextTruncate.AtEnd, TextEditable = not props.Disabled, Parent = box,
	})
	local self = Base(root)
	self.Box = tb
	local real = props.Text or ""
	local MASK = "•"
	local busy, focused, errored = false, false, false
	local function masked() return string.rep(MASK, utf8.len(real) or #real) end
	local function show() busy = true tb.Text = props.Password and masked() or real busy = false end
	show()

	local function paint(animate)
		tween(box, { BackgroundColor3 = Theme.SurfaceAlt }, animate)
		tween(st, { Color = errored and Theme.Danger or (focused and Theme.Accent or Theme.Border) }, animate)
		tb.TextColor3 = props.Disabled and Theme.TextDim or Theme.Text
		tb.PlaceholderColor3 = Theme.TextDim
		if icon then icon:SetColor(focused and "Text" or "TextDim") end
	end
	reactive(box, paint)

	local function process()
		if busy then return end
		local t = tb.Text
		if props.Password then
			if t == masked() then return end
			local old = {}
			for _, cp in utf8.codes(real) do table.insert(old, utf8.char(cp)) end
			local new, bullets, hasNew = {}, 0, false
			for _, cp in utf8.codes(t) do
				if utf8.char(cp) == MASK then bullets += 1 else hasNew = true end
			end
			if hasNew then
				local idx = 1
				for _, cp in utf8.codes(t) do
					local ch = utf8.char(cp)
					if ch == MASK then table.insert(new, old[idx] or "") idx += 1 else table.insert(new, ch) end
				end
			else
				local removed = #old - bullets
				local k = bullets
				local c = tb.CursorPosition
				if c and c > 0 then
					local ok, n = pcall(utf8.len, t, 1, c - 1)
					if ok and n and n <= bullets then k = n end
				end
				for i = 1, k do table.insert(new, old[i]) end
				for i = k + removed + 1, #old do table.insert(new, old[i]) end
			end
			real = table.concat(new)
		else
			real = t
		end
		if props.Numeric then real = real:gsub("[^%d%.%-]", "") end
		if props.MaxLength then real = utf8sub(real, props.MaxLength) end
		local c = tb.CursorPosition
		show()
		if props.Password and c and c > 0 then
			pcall(function()
				local ok, n = pcall(utf8.len, tb.Text, 1, 1)
				tb.CursorPosition = #tb.Text + 1
			end)
		end
		self.Changed:Fire(real)
		if props.OnChanged then props.OnChanged(real) end
	end
	tb:GetPropertyChangedSignal("Text"):Connect(process)
	tb.Focused:Connect(function() focused = true paint(true) end)
	tb.FocusLost:Connect(function(enter)
		focused = false paint(true)
		if props.OnSubmit and enter then props.OnSubmit(real) end
		if props.OnBlur then props.OnBlur(real) end
	end)

	function self:GetValue() return real end
	function self:SetValue(v) real = tostring(v) show() self.Changed:Fire(real) end
	function self:SetError(msg) errored = msg ~= nil setHint(msg, true) paint(true) end
	function self:Focus() tb:CaptureFocus() end
	return self
end

function Onyx.Textarea(props)
	props = props or {}
	local root, body, setHint = Field(props, props.Parent)
	local box = New("Frame", { Name = "Textarea", Size = UDim2.new(1, 0, 0, props.Height or 100), BackgroundTransparency = 0, Parent = body })
	Corner(box, 6)
	local st = Stroke(box)
	Pad(box, 10, 8)
	local tb = New("TextBox", {
		Size = UDim2.fromScale(1, 1), MultiLine = true, TextWrapped = true, ClearTextOnFocus = false,
		TextYAlignment = Enum.TextYAlignment.Top, TextSize = 13, PlaceholderText = props.Placeholder or "",
		Text = props.Text or "", Parent = box,
	})
	local count
	if props.MaxLength and props.ShowCount ~= false then
		local row = New("Frame", { Size = UDim2.new(1, 0, 0, 16), AutomaticSize = Enum.AutomaticSize.None, Parent = body })
		box.Parent = nil
		local holder = New("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Parent = body })
		List(holder, { Gap = 6 })
		box.Parent = holder
		row.Parent = holder
		local ic = makeIcon("info", 13, "TextDim", row)
		ic.Instance.Position = UDim2.fromOffset(0, 1)
		count = New("TextLabel", { Position = UDim2.fromOffset(19, 0), Size = UDim2.new(1, -19, 1, 0), TextSize = 12, Parent = row })
	end
	reactive(box, function()
		box.BackgroundColor3 = Theme.SurfaceAlt
		st.Color = Theme.Border
		tb.TextColor3 = Theme.Text
		tb.PlaceholderColor3 = Theme.TextDim
		if count then count.TextColor3 = Theme.TextMuted end
	end)
	local self = Base(root)
	local function refresh()
		if props.MaxLength then
			local t = utf8sub(tb.Text, props.MaxLength)
			if t ~= tb.Text then tb.Text = t return end
			if count then count.Text = string.format("%d characters max (%d/%d)", props.MaxLength, utf8.len(t) or #t, props.MaxLength) end
		end
		self.Changed:Fire(tb.Text)
		if props.OnChanged then props.OnChanged(tb.Text) end
	end
	tb:GetPropertyChangedSignal("Text"):Connect(refresh)
	tb.Focused:Connect(function() tween(st, { Color = Theme.Accent }, true) end)
	tb.FocusLost:Connect(function() tween(st, { Color = Theme.Border }, true) end)
	refresh()
	function self:GetValue() return tb.Text end
	function self:SetValue(v) tb.Text = v end
	return self
end

function Onyx.NumberInput(props)
	props = props or {}
	local min, max, step = props.Min or -math.huge, props.Max or math.huge, props.Step or 1
	local value = math.clamp(props.Value or 0, min, max)
	local root, body = Field(props, props.Parent)
	local box = New("Frame", { Name = "NumberInput", Size = UDim2.new(1, 0, 0, 34), BackgroundTransparency = 0, Parent = body })
	Corner(box, 6)
	local st = Stroke(box)
	List(box, { Horizontal = true })
	local minus = Onyx.Button({ Icon = "minus", Variant = "ghost", Parent = box, LayoutOrder = 1 })
	local tb = New("TextBox", {
		Size = UDim2.new(1, -68, 1, 0), TextXAlignment = Enum.TextXAlignment.Center, FontFace = Fonts.Medium,
		ClearTextOnFocus = false, TextSize = 13, LayoutOrder = 2, Parent = box,
	})
	local plus = Onyx.Button({ Icon = "plus", Variant = "ghost", Parent = box, LayoutOrder = 3 })
	reactive(box, function() box.BackgroundColor3 = Theme.SurfaceAlt st.Color = Theme.Border tb.TextColor3 = Theme.Text end)
	local self = Base(root)
	local function set(v, silent)
		v = math.clamp(tonumber(string.format("%.8g", v)) or value, min, max)
		local changed = v ~= value
		value = v
		tb.Text = tostring(v)
		if changed and not silent then
			self.Changed:Fire(v)
			if props.OnChanged then props.OnChanged(v) end
		end
	end
	set(value, true)
	minus.Changed:Connect(function() set(value - step) end)
	plus.Changed:Connect(function() set(value + step) end)
	tb.FocusLost:Connect(function() set(tonumber(tb.Text) or value) end)
	function self:GetValue() return value end
	function self:SetValue(v) set(v) end
	return self
end

function Onyx.OTP(props)
	props = props or {}
	local len = props.Length or 6
	local numeric = props.Numeric ~= false
	local root = New("Frame", { Name = "OTP", AutomaticSize = Enum.AutomaticSize.XY, LayoutOrder = props.LayoutOrder, Parent = props.Parent })
	List(root, { Horizontal = true, Gap = props.Gap or 8 })
	local holder = New("Frame", { Size = UDim2.fromOffset(1, 1), ClipsDescendants = true, Parent = root })
	local tb = New("TextBox", { Size = UDim2.fromOffset(60, 20), Position = UDim2.fromOffset(-200, -200), Text = "", ClearTextOnFocus = false, Parent = holder })
	local cells = {}
	for i = 1, len do
		local c = New("TextButton", { Size = UDim2.fromOffset(36, 42), BackgroundTransparency = 0, LayoutOrder = i, Parent = root })
		Corner(c, 6)
		local st = Stroke(c)
		local t = New("TextLabel", { Size = UDim2.fromScale(1, 1), TextXAlignment = Enum.TextXAlignment.Center, FontFace = Fonts.SemiBold, TextSize = 17, Parent = c })
		c.Activated:Connect(function() tb:CaptureFocus() end)
		cells[i] = { c, st, t }
	end
	local self = Base(root)
	local focused = false
	local function paint(animate)
		local txt = tb.Text
		for i, cell in cells do
			local active = focused and (i == math.min(#txt + 1, len))
			cell[1].BackgroundColor3 = Theme.SurfaceAlt
			tween(cell[2], { Color = active and Theme.Accent or Theme.Border }, animate)
			cell[3].Text = txt:sub(i, i)
			cell[3].TextColor3 = Theme.Text
		end
	end
	reactive(root, paint)
	tb:GetPropertyChangedSignal("Text"):Connect(function()
		local t = tb.Text
		if numeric then t = t:gsub("%D", "") end
		t = t:sub(1, len)
		if t ~= tb.Text then tb.Text = t return end
		paint(true)
		self.Changed:Fire(t)
		if props.OnChanged then props.OnChanged(t) end
		if #t == len and props.OnComplete then props.OnComplete(t) end
	end)
	tb.Focused:Connect(function() focused = true paint(true) end)
	tb.FocusLost:Connect(function() focused = false paint(true) end)
	function self:GetValue() return tb.Text end
	function self:SetValue(v) tb.Text = v end
	function self:Focus() tb:CaptureFocus() end
	return self
end

--==================================================================--
--  Checkbox / Radio / Switch
--==================================================================--
-- shared "choice" control: kind = "checkbox" | "radio"
local function Choice(kind, props)
	local card = props.Card
	local round = kind == "radio" or props.Shape == "round"
	local root = New("TextButton", {
		Name = kind == "radio" and "Radio" or "Checkbox", BackgroundTransparency = card and 0 or 1, LayoutOrder = props.LayoutOrder,
		Size = card and UDim2.new(1, 0, 0, 0) or UDim2.new(), AutomaticSize = card and Enum.AutomaticSize.Y or Enum.AutomaticSize.XY,
		Parent = props.Parent,
	})
	local cardStroke
	if card then Corner(root, 8) cardStroke = Stroke(root) Pad(root, 12) end
	List(root, { Horizontal = true, Gap = 10 })
	local box = New("Frame", { Size = UDim2.fromOffset(18, 18), BackgroundTransparency = 0, LayoutOrder = 1, Parent = root })
	Corner(box, round and 999 or 5)
	local boxStroke = Stroke(box)
	local mark
	if kind == "radio" then
		mark = New("Frame", {
			AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromScale(.5, .5), Size = UDim2.fromOffset(6, 6),
			BackgroundTransparency = 0, Parent = box,
		}, { New("UICorner", { CornerRadius = UDim.new(1, 0) }) })
	else
		mark = makeIcon("check", 12, "PrimaryText", box)
		mark.Instance.AnchorPoint = Vector2.new(.5, .5)
		mark.Instance.Position = UDim2.fromScale(.5, .5)
	end
	local lbl, desc
	if props.Label or props.Description then
		local txt = New("Frame", {
			LayoutOrder = 2, AutomaticSize = card and Enum.AutomaticSize.Y or Enum.AutomaticSize.XY,
			Size = card and UDim2.new(1, -28, 0, 0) or UDim2.new(), Parent = root,
		})
		List(txt, { Gap = 2 })
		if props.Label then lbl = New("TextLabel", { Text = props.Label, FontFace = Fonts.Medium, TextSize = 13, AutomaticSize = Enum.AutomaticSize.XY, LayoutOrder = 1, Parent = txt }) end
		if props.Description then
			desc = New("TextLabel", {
				Text = props.Description, TextSize = 12, TextWrapped = card or false, LayoutOrder = 2,
				AutomaticSize = card and Enum.AutomaticSize.Y or Enum.AutomaticSize.XY, Size = card and UDim2.new(1, 0, 0, 0) or UDim2.new(), Parent = txt,
			})
		end
		if lbl then lbl.Position = UDim2.fromOffset(0, 0) end
	end
	local self = Base(root)
	local checked, hover, disabled = props.Checked or props.Value or false, false, props.Disabled or false
	local function paint(animate)
		local on = checked
		tween(box, { BackgroundColor3 = on and Theme.Primary or Theme.SurfaceAlt }, animate)
		tween(boxStroke, { Color = on and Theme.Primary or (hover and Theme.TextDim or Theme.BorderStrong) }, animate)
		if kind == "radio" then mark.BackgroundColor3 = Theme.PrimaryText mark.Visible = on
		else mark.Instance.Visible = on mark:SetColor("PrimaryText") end
		if cardStroke then
			tween(cardStroke, { Color = on and Theme.Accent or (hover and Theme.BorderStrong or Theme.Border) }, animate)
			tween(root, { BackgroundColor3 = on and Theme.AccentSoft or Theme.Surface }, animate)
			if on and Theme.Name == "Dark" then tween(root, { BackgroundColor3 = Theme.Surface }, animate) end
		end
		if lbl then lbl.TextColor3 = disabled and Theme.TextDim or Theme.Text end
		if desc then desc.TextColor3 = Theme.TextMuted end
	end
	reactive(root, paint)
	root.MouseEnter:Connect(function() hover = true paint(true) end)
	root.MouseLeave:Connect(function() hover = false paint(true) end)
	root.Activated:Connect(function()
		if disabled then return end
		if props.OnToggle then props.OnToggle(self) end
	end)
	function self:SetChecked(v, silent)
		if v == checked then return end
		checked = v
		paint(true)
		if not silent then self.Changed:Fire(v) end
	end
	function self:GetChecked() return checked end
	function self:SetDisabled(d) disabled = d root.Interactable = not d paint(true) end
	return self
end

function Onyx.Checkbox(props)
	props = props or {}
	local userToggle = props.OnChanged
	local self
	local p = table.clone(props)
	p.OnToggle = function(c) c:SetChecked(not c:GetChecked()) end
	self = Choice("checkbox", p)
	self.Changed:Connect(function(v) if userToggle then userToggle(v) end end)
	self.GetValue = self.GetChecked
	return self
end

function Onyx.RadioGroup(props)
	props = props or {}
	local root = New("Frame", {
		Name = "RadioGroup", Size = UDim2.new(props.Horizontal and 1 or 1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = props.LayoutOrder, Parent = props.Parent,
	})
	List(root, { Horizontal = props.Horizontal, Wraps = props.Horizontal, Gap = props.Gap or (props.Card and 8 or 12) })
	local self = Base(root)
	local items, value = {}, props.Value
	local function select(v)
		if v == value then return end
		value = v
		for val, ch in items do ch:SetChecked(val == value, true) end
		self.Changed:Fire(value)
		if props.OnChanged then props.OnChanged(value) end
	end
	for i, opt in props.Options or {} do
		if type(opt) ~= "table" then opt = { Value = opt, Label = tostring(opt) } end
		local val = opt.Value
		items[val] = Choice("radio", {
			Label = opt.Label or tostring(val), Description = opt.Description, Card = props.Card, Disabled = opt.Disabled,
			Checked = val == value, LayoutOrder = i, Parent = root,
			OnToggle = function() select(val) end,
		})
	end
	function self:GetValue() return value end
	function self:SetValue(v) select(v) end
	return self
end

function Onyx.Switch(props)
	props = props or {}
	local root = New("TextButton", {
		Name = "Switch", AutomaticSize = Enum.AutomaticSize.XY, Size = UDim2.new(), LayoutOrder = props.LayoutOrder, Parent = props.Parent,
	})
	List(root, { Horizontal = true, Gap = 10, VAlign = Enum.VerticalAlignment.Center })
	local track = New("Frame", { Size = UDim2.fromOffset(36, 20), BackgroundTransparency = 0, LayoutOrder = 1, Parent = root })
	Corner(track, 999)
	local knob = New("Frame", {
		AnchorPoint = Vector2.new(0, .5), Position = UDim2.new(0, 2, .5, 0), Size = UDim2.fromOffset(16, 16),
		BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0, Parent = track,
	})
	Corner(knob, 999)
	local lbl = props.Label and New("TextLabel", { Text = props.Label, FontFace = Fonts.Medium, TextSize = 13, AutomaticSize = Enum.AutomaticSize.XY, LayoutOrder = 2, Parent = root })
	local self = Base(root)
	local on, disabled = props.Value or false, props.Disabled or false
	local function paint(animate)
		tween(track, { BackgroundColor3 = on and Theme.Accent or Theme.Track }, animate)
		tween(knob, { Position = on and UDim2.new(1, -18, .5, 0) or UDim2.new(0, 2, .5, 0) }, animate)
		if lbl then lbl.TextColor3 = disabled and Theme.TextDim or Theme.Text end
	end
	reactive(root, paint)
	root.Activated:Connect(function()
		if disabled then return end
		on = not on paint(true)
		self.Changed:Fire(on)
		if props.OnChanged then props.OnChanged(on) end
	end)
	function self:GetValue() return on end
	function self:SetValue(v) on = v paint(true) self.Changed:Fire(on) end
	function self:SetDisabled(d) disabled = d paint(true) end
	return self
end

--==================================================================--
--  Slider
--==================================================================--
function Onyx.Slider(props)
	props = props or {}
	local min, max, step = props.Min or 0, props.Max or 100, props.Step or 1
	local value = math.clamp(props.Value or min, min, max)
	local root, body = Field(props, props.Parent)
	local holder = New("Frame", { Name = "Slider", Size = UDim2.new(1, 0, 0, props.Marks and 44 or 28), Parent = body })
	local track = New("Frame", {
		AnchorPoint = Vector2.new(0, .5), Position = UDim2.new(0, 0, 0, 14), Size = UDim2.new(1, 0, 0, 6),
		BackgroundTransparency = 0, Parent = holder,
	})
	Corner(track, 999)
	local fill = New("Frame", { Size = UDim2.fromScale(0, 1), BackgroundTransparency = 0, Parent = track })
	Corner(fill, 999)
	local thumb = New("Frame", {
		AnchorPoint = Vector2.new(.5, .5), Size = UDim2.fromOffset(16, 16), Position = UDim2.new(0, 0, 0, 14),
		BackgroundTransparency = 0, ZIndex = 3, Parent = holder,
	})
	Corner(thumb, 999)
	local thumbStroke = Stroke(thumb, Theme.Accent, 2)
	local bubble = New("TextLabel", {
		AnchorPoint = Vector2.new(.5, 1), Position = UDim2.new(.5, 0, 0, -6), AutomaticSize = Enum.AutomaticSize.XY,
		BackgroundTransparency = 0, TextSize = 11, FontFace = Fonts.Medium, TextXAlignment = Enum.TextXAlignment.Center,
		Visible = false, Parent = thumb,
	})
	Corner(bubble, 4)
	Pad(bubble, 6, 3)
	local marks = {}
	if props.Marks then
		for i = 0, props.Marks do
			local a = i / props.Marks
			local tick = New("Frame", { AnchorPoint = Vector2.new(.5, 0), Position = UDim2.new(a, 0, 0, 22), Size = UDim2.fromOffset(1, 4), BackgroundTransparency = 0, Parent = holder })
			local tl = New("TextLabel", {
				AnchorPoint = Vector2.new(.5, 0), Position = UDim2.new(a, 0, 0, 28), Size = UDim2.fromOffset(30, 12),
				Text = tostring(tonumber(string.format("%.4g", min + a * (max - min)))), TextSize = 10,
				TextXAlignment = Enum.TextXAlignment.Center, Parent = holder,
			})
			table.insert(marks, { tick, tl })
		end
	end
	local self = Base(root)
	local dragging, hover = false, false
	local function paint(animate)
		track.BackgroundColor3 = Theme.Track
		fill.BackgroundColor3 = Theme.Accent
		thumb.BackgroundColor3 = Theme.Background
		bubble.BackgroundColor3 = Theme.Elevated
		bubble.TextColor3 = Theme.Text
		tween(thumbStroke, { Color = (dragging or hover) and Theme.AccentHover or Theme.Accent }, animate)
		bubble.Visible = dragging or hover
		for _, m in marks do m[1].BackgroundColor3 = Theme.BorderStrong m[2].TextColor3 = Theme.TextDim end
	end
	reactive(holder, paint)
	local function render()
		local a = (value - min) / (max - min)
		fill.Size = UDim2.fromScale(a, 1)
		thumb.Position = UDim2.new(a, 0, 0, 14)
		bubble.Text = tostring(value) .. (props.Suffix or "")
	end
	local function set(v, silent)
		v = math.clamp(math.floor((v - min) / step + .5) * step + min, min, max)
		v = tonumber(string.format("%.8g", v))
		if v == value then return end
		value = v
		render()
		if not silent then
			self.Changed:Fire(v)
			if props.OnChanged then props.OnChanged(v) end
		end
	end
	local hit = New("TextButton", { Size = UDim2.new(1, 16, 1, 0), Position = UDim2.fromOffset(-8, 0), ZIndex = 4, Parent = holder })
	drag(hit, function(input, began)
		if began then dragging = true paint(true) end
		local a = math.clamp((input.Position.X - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
		set(min + a * (max - min))
	end, function() dragging = false paint(true) end)
	hit.MouseEnter:Connect(function() hover = true paint(true) end)
	hit.MouseLeave:Connect(function() hover = false paint(true) end)
	render()
	function self:GetValue() return value end
	function self:SetValue(v) set(v) end
	return self
end

--==================================================================--
--  Menu (list / command palette / nav) and Select
--==================================================================--
function Onyx.Menu(props)
	props = props or {}
	local root = New("Frame", {
		Name = "Menu", Size = props.Width and UDim2.fromOffset(props.Width, 0) or UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 0, LayoutOrder = props.LayoutOrder, Parent = props.Parent,
	})
	Corner(root, 8)
	local st = Stroke(root)
	Pad(root, 4)
	List(root, { Gap = 2 })
	local self = Base(root)
	local style = props.Style or "list" -- "list" (check on selected) | "nav" (highlight selected)
	local multi = props.Multi
	local selected = {}
	if multi then for _, v in props.Values or {} do selected[v] = true end
	elseif props.Value ~= nil then selected[props.Value] = true end
	local items = props.Items or {}
	local query = ""
	local rows = {}
	local sepLines = {}

	if props.Search then
		local sf = New("Frame", { Size = UDim2.new(1, 0, 0, 34), LayoutOrder = 0, Parent = root })
		local ic = makeIcon("search", 15, "TextDim", sf)
		ic.Instance.AnchorPoint = Vector2.new(0, .5) ic.Instance.Position = UDim2.new(0, 8, .5, 0)
		self.SearchBox = New("TextBox", {
			Position = UDim2.fromOffset(30, 0), Size = UDim2.new(1, -38, 1, 0), PlaceholderText = props.SearchPlaceholder or "Search...",
			ClearTextOnFocus = false, TextSize = 13, Parent = sf,
		})
		local line = New("Frame", { Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0, 0, 1, 0), BackgroundTransparency = 0, Parent = sf })
		reactive(sf, function()
			self.SearchBox.TextColor3 = Theme.Text self.SearchBox.PlaceholderColor3 = Theme.TextDim line.BackgroundColor3 = Theme.Border
		end)
		local sp = New("Frame", { Size = UDim2.new(1, 0, 0, 2), LayoutOrder = 1, Parent = root })
	end

	local scroll = New("ScrollingFrame", { Size = UDim2.new(1, 0, 0, 0), LayoutOrder = 2, ScrollBarThickness = props.MaxHeight and 3 or 0, Parent = root })
	local list = List(scroll, { Gap = 2 })
	list:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		scroll.Size = UDim2.new(1, 0, 0, math.min(list.AbsoluteContentSize.Y, props.MaxHeight or 10000))
	end)
	reactive(root, function() root.BackgroundColor3 = props.Background and color(props.Background) or Theme.Surface st.Color = Theme.Border end)

	local function isSel(item) return selected[item.Value] == true end
	local function pick(item)
		if item.Disabled then return end
		if multi then selected[item.Value] = not selected[item.Value] or nil
		else selected = { [item.Value] = true } end
		for _, r in rows do r.paint(true) end
		local val = item.Value
		if multi then val = {} for k in selected do table.insert(val, k) end end
		self.Changed:Fire(val, item)
		if item.OnSelect then item.OnSelect(item) end
		if props.OnSelect then props.OnSelect(val, item) end
	end

	local function render()
		for _, c in scroll:GetChildren() do if not c:IsA("UIListLayout") then c:Destroy() end end
		rows = {}
		local q = query:lower()
		local shown = 0
		for i, item in items do
			if item.Separator then
				if q == "" then
					local s = New("Frame", { Size = UDim2.new(1, 0, 0, 9), LayoutOrder = i, Parent = scroll })
					local l = New("Frame", { AnchorPoint = Vector2.new(0, .5), Position = UDim2.fromScale(0, .5), Size = UDim2.new(1, 0, 0, 1), BackgroundTransparency = 0, Parent = s })
					reactive(l, function() l.BackgroundColor3 = Theme.Border end)
				end
			elseif item.Header then
				if q == "" then
					local h = New("TextLabel", { Text = item.Header, TextSize = 12, FontFace = Fonts.Medium, Size = UDim2.new(1, 0, 0, 26), LayoutOrder = i, Parent = scroll })
					Pad(h, 8, 0)
					reactive(h, function() h.TextColor3 = Theme.TextDim end)
				end
			elseif q == "" or (item.Text or ""):lower():find(q, 1, true) then
				shown += 1
				item.Value = item.Value == nil and item.Text or item.Value
				local row = New("TextButton", { Size = UDim2.new(1, 0, 0, props.RowHeight or 32), BackgroundTransparency = 0, LayoutOrder = i, Parent = scroll })
				Corner(row, 6)
				local rst = Stroke(row)
				local off = 8
				local ic
				if item.Icon then
					ic = makeIcon(item.Icon, 15, "TextMuted", row)
					ic.Instance.AnchorPoint = Vector2.new(0, .5) ic.Instance.Position = UDim2.new(0, 8, .5, 0)
					off = 31
				end
				local lbl = New("TextLabel", {
					Text = item.Text or "", TextSize = 13, FontFace = Fonts.Medium, Position = UDim2.fromOffset(off, 0),
					Size = UDim2.new(1, -off - 30, 1, 0), TextTruncate = Enum.TextTruncate.AtEnd, Parent = row,
				})
				local right
				if item.Shortcut then
					right = New("TextLabel", { Text = item.Shortcut, TextSize = 11, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -8, 0, 0), Size = UDim2.new(0, 40, 1, 0), TextXAlignment = Enum.TextXAlignment.Right, Parent = row })
				end
				local chk
				if style == "list" then
					chk = makeIcon("check", 14, "Text", row)
					chk.Instance.AnchorPoint = Vector2.new(1, .5) chk.Instance.Position = UDim2.new(1, -8, .5, 0)
				end
				local hover = false
				local r = {}
				function r.paint(animate)
					local on = isSel(item)
					local navOn = style == "nav" and on
					tween(row, { BackgroundColor3 = navOn and Theme.SurfaceAlt or Theme.Hover, BackgroundTransparency = (navOn or (hover and not item.Disabled)) and 0 or 1 }, animate)
					tween(rst, { Transparency = navOn and 0 or 1, Color = Theme.BorderStrong }, animate)
					local fg = item.Danger and Theme.Danger or (item.Disabled and Theme.TextDim or ((style == "nav" and not on and not hover) and Theme.TextMuted or Theme.Text))
					lbl.TextColor3 = fg
					if ic then ic:SetColor(item.Danger and "Danger" or (navOn and "Text" or "TextMuted")) end
					if right then right.TextColor3 = Theme.TextDim end
					if chk then chk.Instance.Visible = on chk:SetColor("Text") end
				end
				row.MouseEnter:Connect(function() hover = true r.paint(true) end)
				row.MouseLeave:Connect(function() hover = false r.paint(true) end)
				row.Activated:Connect(function() pick(item) end)
				r.paint(false)
				table.insert(rows, r)
			end
		end
		if shown == 0 and q ~= "" then
			local e = New("TextLabel", { Text = props.EmptyText or "No results found.", TextSize = 13, Size = UDim2.new(1, 0, 0, 40), TextXAlignment = Enum.TextXAlignment.Center, Parent = scroll })
			reactive(e, function() e.TextColor3 = Theme.TextMuted end)
		end
	end
	if self.SearchBox then
		self.SearchBox:GetPropertyChangedSignal("Text"):Connect(function() query = self.SearchBox.Text render() end)
	end
	render()

	function self:SetItems(new) items = new render() end
	function self:SetValue(v)
		selected = {}
		if multi then for _, x in v do selected[x] = true end else selected[v] = true end
		for _, r in rows do r.paint(true) end
	end
	function self:GetValue()
		if multi then local t = {} for k in selected do table.insert(t, k) end return t end
		return next(selected)
	end
	return self
end

function Onyx.Select(props)
	props = props or {}
	local root, body = Field(props, props.Parent)
	local opts = {}
	for _, o in props.Options or {} do
		if type(o) ~= "table" then o = { Value = o, Text = tostring(o) } end
		o.Text = o.Text or o.Label or tostring(o.Value)
		table.insert(opts, o)
	end
	local trig = New("TextButton", {
		Name = "Select", Size = props.Width and UDim2.fromOffset(props.Width, 34) or UDim2.new(1, 0, 0, 34),
		BackgroundTransparency = 0, Parent = body,
	})
	Corner(trig, 6)
	local st = Stroke(trig)
	local padL = 12
	local ic = props.Icon and makeIcon(props.Icon, 15, "TextMuted", trig)
	if ic then ic.Instance.AnchorPoint = Vector2.new(0, .5) ic.Instance.Position = UDim2.new(0, 11, .5, 0) padL = 34 end
	local lbl = New("TextLabel", { Position = UDim2.fromOffset(padL, 0), Size = UDim2.new(1, -padL - 30, 1, 0), TextSize = 13, FontFace = Fonts.Medium, TextTruncate = Enum.TextTruncate.AtEnd, Parent = trig })
	local chev = makeIcon(props.Multi and "chevrons-up-down" or "chevron-down", 14, "TextDim", trig)
	chev.Instance.AnchorPoint = Vector2.new(1, .5) chev.Instance.Position = UDim2.new(1, -10, .5, 0)
	local self = Base(root)
	local value = props.Value
	local values = props.Values or {}
	local layer
	local function labelText()
		if props.Multi then
			if #values == 0 then return nil end
			if #values <= 2 then
				local t = {}
				for _, v in values do for _, o in opts do if o.Value == v then table.insert(t, o.Text) end end end
				return table.concat(t, ", ")
			end
			return #values .. " selected"
		end
		for _, o in opts do if o.Value == value then return o.Text end end
	end
	local open = false
	local function paint(animate)
		local txt = labelText()
		lbl.Text = txt or props.Placeholder or "Select..."
		lbl.TextColor3 = txt and Theme.Text or Theme.TextMuted
		trig.BackgroundColor3 = Theme.SurfaceAlt
		tween(st, { Color = open and Theme.Accent or Theme.Border }, animate)
	end
	reactive(trig, paint)
	trig.Activated:Connect(function()
		if layer and layer.Open then layer.Close() return end
		layer = openLayer(trig, { OnClose = function() open = false paint(true) end })
		open = true paint(true)
		local m = Onyx.Menu({
			Items = opts, Value = value, Values = values, Multi = props.Multi, Search = props.Searchable,
			Width = math.max(trig.AbsoluteSize.X, props.MenuWidth or 0), MaxHeight = 240, Background = "Elevated", Parent = layer.Host,
		})
		m.Changed:Connect(function(v)
			if props.Multi then values = v else value = v layer.Close() end
			paint(true)
			self.Changed:Fire(v)
			if props.OnChanged then props.OnChanged(v) end
		end)
		if m.SearchBox then m.SearchBox:CaptureFocus() end
	end)
	function self:GetValue() return props.Multi and values or value end
	function self:SetValue(v) if props.Multi then values = v else value = v end paint(true) end
	return self
end

--==================================================================--
--  Overlays: Popover / Dialog / Toast / Tooltip
--==================================================================--
local function resolveInstance(x)
	if type(x) == "table" then return x.Instance end
	return x
end

function Onyx.Popover(props)
	props = props or {}
	local content = New("Frame", {
		Name = "Popover", Size = UDim2.fromOffset(props.Width or 240, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 0,
	})
	Corner(content, 8)
	local st = Stroke(content)
	Pad(content, props.Padding or 12)
	List(content, { Gap = props.Gap or 8 })
	reactive(content, function() content.BackgroundColor3 = Theme.Elevated st.Color = Theme.Border end)
	local self = Base(content)
	self.Content = content
	local anchor = resolveInstance(props.Anchor)
	local layer
	function self:IsOpen() return layer ~= nil and layer.Open end
	function self:Open(at)
		if self:IsOpen() then return end
		layer = openLayer(anchor, {
			Side = props.Side, Align = props.Align, Offset = props.Offset, At = at, Dismiss = props.Dismissable,
			OnClose = function() content.Parent = nil self.Changed:Fire(false) end,
		})
		content.Parent = layer.Host
		self.Changed:Fire(true)
	end
	function self:Close() if layer then layer.Close() end end
	function self:Toggle() if self:IsOpen() then self:Close() else self:Open() end end
	if anchor and props.Toggle ~= false and anchor:IsA("GuiButton") then
		anchor.Activated:Connect(function() self:Toggle() end)
	end
	return self
end

function Onyx.Dialog(props)
	props = props or {}
	local card = New("Frame", {
		Name = "Dialog", Size = UDim2.fromOffset(props.Width or 340, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 0,
	})
	Corner(card, 12)
	local st = Stroke(card)
	Pad(card, 20)
	List(card, { Gap = 14 })
	reactive(card, function() card.BackgroundColor3 = Theme.Surface st.Color = Theme.Border end)
	local self = Base(card)
	if props.Title or props.Description then
		local head = Onyx.Stack({ Gap = 4, Parent = card })
		head.Instance.LayoutOrder = 1
		if props.Title then Onyx.Text({ Text = props.Title, Variant = "title", Wrap = true, Parent = head }) end
		if props.Description then Onyx.Text({ Text = props.Description, Variant = "muted", Wrap = true, Parent = head }) end
	end
	local content = Onyx.Stack({ Gap = 10, Parent = card })
	content.Instance.LayoutOrder = 2
	self.Content = content.Instance
	local layer
	function self:Close() if layer then layer.Close() end end
	function self:IsOpen() return layer ~= nil and layer.Open end
	if props.ConfirmText ~= false or props.CancelText ~= false then
		local foot = New("Frame", { Size = UDim2.new(1, 0, 0, 34), LayoutOrder = 3, Parent = card })
		List(foot, { Horizontal = true, Gap = 8, HAlign = Enum.HorizontalAlignment.Right })
		if props.CancelText ~= false then
			Onyx.Button({ Text = props.CancelText or "Cancel", Variant = "outline", LayoutOrder = 1, Parent = foot, OnClick = function()
				self:Close() if props.OnCancel then props.OnCancel() end
			end })
		end
		if props.ConfirmText ~= false then
			Onyx.Button({ Text = props.ConfirmText or "Confirm", Variant = props.Danger and "destructive" or "default", LayoutOrder = 2, Parent = foot, OnClick = function()
				if props.OnConfirm then props.OnConfirm() end
				self:Close()
			end })
		end
	end
	function self:Open()
		if self:IsOpen() then return end
		layer = openLayer(resolveInstance(props.Anchor), {
			Center = true, Dim = true, Dismiss = props.Dismissable ~= false,
			OnClose = function() card.Parent = nil self.Changed:Fire(false) end,
		})
		card.Parent = layer.Host
		self.Changed:Fire(true)
	end
	if props.Trigger then
		local t = resolveInstance(props.Trigger)
		t.Activated:Connect(function() self:Open() end)
	end
	return self
end
function Onyx.Confirm(props)
	local d = Onyx.Dialog(props)
	d:Open()
	return d
end

local toastCounter = 0
local ToastIcons = { info = { "info", "Info" }, success = { "circle-check", "Success" }, warning = { "alert", "Warning" }, danger = { "circle-x", "Danger" }, default = { "info", "Text" } }
function Onyx.Toast(props)
	props = props or {}
	local ov = getOverlay(resolveInstance(props.Anchor))
	local host = ov:FindFirstChild("OnyxToasts")
	if not host then
		host = New("Frame", {
			Name = "OnyxToasts", AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -16, 1, -16),
			Size = UDim2.fromOffset(330, 0), AutomaticSize = Enum.AutomaticSize.Y, ZIndex = 2000, Parent = ov,
		})
		List(host, { Gap = 8, HAlign = Enum.HorizontalAlignment.Right, VAlign = Enum.VerticalAlignment.Bottom })
	end
	toastCounter += 1
	local wrap = New("Frame", { Name = "Toast", Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, ClipsDescendants = true, LayoutOrder = toastCounter, Parent = host })
	Pad(wrap, 2)
	local card = New("Frame", {
		Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Position = UDim2.new(1, 40, 0, 0), BackgroundTransparency = 0, Parent = wrap,
	})
	Corner(card, 10)
	local st = Stroke(card)
	Pad(card, 14)
	List(card, { Horizontal = true, Gap = 10 })
	local ico = ToastIcons[props.Variant or "default"] or ToastIcons.default
	local ic = makeIcon(ico[1], 18, ico[2], card)
	ic.Instance.LayoutOrder = 1
	local col = New("Frame", { Size = UDim2.new(1, -52, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 2, Parent = card })
	List(col, { Gap = 3 })
	Onyx.Text({ Text = props.Title or "Notification", Variant = "label", Wrap = true, Parent = col }).Instance.LayoutOrder = 1
	if props.Description then Onyx.Text({ Text = props.Description, Variant = "small", Wrap = true, Parent = col }).Instance.LayoutOrder = 2 end
	if props.Action then
		local sp = New("Frame", { Size = UDim2.fromOffset(1, 6), LayoutOrder = 3, Parent = col })
		local ab = Onyx.Button({ Text = props.Action.Text or "Undo", Variant = "outline", Size = "sm", Parent = col, OnClick = function()
			if props.Action.OnClick then props.Action.OnClick() end
		end })
		ab.Instance.LayoutOrder = 4
	end
	local closeBtn = Onyx.Button({ Icon = "x", Variant = "ghost", Size = "sm", Width = 24, Parent = card })
	closeBtn.Instance.Size = UDim2.fromOffset(24, 24)
	closeBtn.Instance.LayoutOrder = 3
	reactive(card, function() card.BackgroundColor3 = Theme.Elevated st.Color = Theme.Border end)
	local self = Base(wrap)
	local gone = false
	function self:Dismiss()
		if gone then return end
		gone = true
		tween(card, { Position = UDim2.new(1, 40, 0, 0) }, true, TweenInfo.new(.2))
		task.delay(.22, function() wrap:Destroy() end)
	end
	closeBtn.Changed:Connect(function() self:Dismiss() end)
	tween(card, { Position = UDim2.new(0, 0, 0, 0) }, true, TweenInfo.new(.25, Enum.EasingStyle.Quint))
	local dur = props.Duration or 4
	if dur > 0 then task.delay(dur, function() self:Dismiss() end) end
	return self
end
Onyx.Notify = Onyx.Toast

function Onyx.Tooltip(target, text, o)
	o = o or {}
	target = resolveInstance(target)
	local tip
	local token = 0
	local function hide() token += 1 if tip then tip:Destroy() tip = nil end end
	target.MouseEnter:Connect(function()
		token += 1
		local my = token
		task.delay(o.Delay or .35, function()
			if token ~= my or tip then return end
			local ov = getOverlay(target)
			tip = New("TextLabel", {
				Text = text, TextSize = 12, FontFace = Fonts.Medium, AutomaticSize = Enum.AutomaticSize.XY, BackgroundColor3 = Theme.Primary,
				BackgroundTransparency = 0, TextColor3 = Theme.PrimaryText, ZIndex = 3000, Position = UDim2.fromOffset(-5000, -5000), Parent = ov,
			})
			Corner(tip, 6)
			Pad(tip, 8, 5)
			RunService.Heartbeat:Wait()
			if not tip then return end
			local ap, as, cs = target.AbsolutePosition - ov.AbsolutePosition, target.AbsoluteSize, tip.AbsoluteSize
			local y = ap.Y - cs.Y - 6
			if y < 4 then y = ap.Y + as.Y + 6 end
			tip.Position = UDim2.fromOffset(math.max(4, ap.X + (as.X - cs.X) / 2), y)
		end)
	end)
	target.MouseLeave:Connect(hide)
	target.Destroying:Connect(hide)
end

--==================================================================--
--  Card / Alert / ScrollArea / Window
--==================================================================--
function Onyx.Card(props)
	props = props or {}
	local root = New("Frame", {
		Name = "Card", Size = props.Width and UDim2.fromOffset(props.Width, 0) or UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 0, LayoutOrder = props.LayoutOrder, Parent = props.Parent,
	})
	Corner(root, props.Radius or 10)
	local st = Stroke(root)
	Pad(root, props.Padding or 16)
	List(root, { Gap = props.Gap or 12 })
	reactive(root, function() root.BackgroundColor3 = Theme[props.Background or "Surface"] st.Color = Theme.Border end)
	local self = Base(root)
	if props.Title or props.Description then
		local head = Onyx.Stack({ Gap = 4, Parent = root })
		head.Instance.LayoutOrder = 1
		if props.Title then Onyx.Text({ Text = props.Title, Variant = props.TitleVariant or "title", Wrap = true, Parent = head }) end
		if props.Description then Onyx.Text({ Text = props.Description, Variant = "muted", Wrap = true, Parent = head }) end
	end
	local content = Onyx.Stack({ Gap = props.ContentGap or 10, Parent = root })
	content.Instance.LayoutOrder = 2
	self.Content = content.Instance
	function self:AddFooter(horizontal)
		local f = Onyx.Stack({ Horizontal = horizontal ~= false, Gap = 8, Parent = root })
		f.Instance.LayoutOrder = 3
		return f
	end
	return self
end

function Onyx.Alert(props)
	props = props or {}
	local variant = props.Variant or "default"
	local map = { default = { "info", "Text" }, info = { "info", "Info" }, success = { "circle-check", "Success" }, warning = { "alert", "Warning" }, danger = { "circle-x", "Danger" } }
	local m = map[variant] or map.default
	local root = New("Frame", {
		Name = "Alert", Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 0,
		LayoutOrder = props.LayoutOrder, Parent = props.Parent,
	})
	Corner(root, 8)
	local st = Stroke(root)
	Pad(root, 12, 11)
	List(root, { Horizontal = true, Gap = 10, VAlign = Enum.VerticalAlignment.Center })
	local ic = makeIcon(props.Icon or m[1], 18, m[2], root)
	ic.Instance.LayoutOrder = 1
	local dismissW = props.Dismissible and 32 or 0
	local col = New("Frame", { Size = UDim2.new(1, -28 - dismissW, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 2, Parent = root })
	List(col, { Gap = 2 })
	if props.Title then Onyx.Text({ Text = props.Title, Variant = "label", Wrap = true, Parent = col }).Instance.LayoutOrder = 1 end
	if props.Description then Onyx.Text({ Text = props.Description, Variant = "small", Wrap = true, Parent = col }).Instance.LayoutOrder = 2 end
	local self = Base(root)
	if props.Dismissible then
		local b = Onyx.Button({ Icon = "x", Variant = "ghost", Size = "sm", Parent = root })
		b.Instance.Size = UDim2.fromOffset(24, 24) b.Instance.LayoutOrder = 3
		b.Changed:Connect(function()
			if props.OnDismiss then props.OnDismiss() end
			root:Destroy()
		end)
	end
	reactive(root, function()
		root.BackgroundColor3 = Theme.Surface
		st.Color = variant == "default" and Theme.Border or Theme[m[2]]
	end)
	return self
end

function Onyx.ScrollArea(props)
	props = props or {}
	local h = props.Horizontal
	local sc = New("ScrollingFrame", {
		Name = "ScrollArea", Size = props.Size or UDim2.new(1, 0, 0, props.Height or 200), LayoutOrder = props.LayoutOrder,
		AutomaticCanvasSize = h and Enum.AutomaticSize.X or Enum.AutomaticSize.Y,
		ScrollingDirection = h and Enum.ScrollingDirection.X or Enum.ScrollingDirection.Y, Parent = props.Parent,
	})
	local inner = New("Frame", {
		Name = "Content", Size = h and UDim2.new(0, 0, 1, 0) or UDim2.new(1, 0, 0, 0),
		AutomaticSize = h and Enum.AutomaticSize.X or Enum.AutomaticSize.Y, Parent = sc,
	})
	List(inner, { Horizontal = h, Gap = props.Gap or 10 })
	if props.Padding then Pad(inner, props.Padding) end
	reactive(sc, function() sc.ScrollBarImageColor3 = Theme.BorderStrong end)
	local self = Base(sc)
	self.Content = inner
	return self
end

function Onyx.Window(props)
	props = props or {}
	local size = props.Size or UDim2.fromOffset(640, 440)
	local win = New("Frame", {
		Name = "Window", Size = size, BackgroundTransparency = 0,
		Position = props.Position or UDim2.new(.5, -size.X.Offset / 2, .5, -size.Y.Offset / 2), Parent = props.Parent,
	})
	Corner(win, 12)
	local st = Stroke(win)
	local bar = New("Frame", { Name = "TitleBar", Size = UDim2.new(1, 0, 0, 46), Parent = win })
	local title = New("TextLabel", {
		Text = props.Title or "Window", FontFace = Fonts.SemiBold, TextSize = 14, Position = UDim2.fromOffset(16, 0),
		Size = UDim2.new(1, -110, 1, 0), TextTruncate = Enum.TextTruncate.AtEnd, Parent = bar,
	})
	local line = New("Frame", { Position = UDim2.new(0, 0, 1, 0), Size = UDim2.new(1, 0, 0, 1), BackgroundTransparency = 0, Parent = bar })
	local btns = New("Frame", { AnchorPoint = Vector2.new(1, .5), Position = UDim2.new(1, -8, .5, 0), Size = UDim2.fromOffset(64, 28), Parent = bar })
	List(btns, { Horizontal = true, Gap = 4, HAlign = Enum.HorizontalAlignment.Right })
	local area = Onyx.ScrollArea({ Size = UDim2.new(1, 0, 1, -47), Padding = props.Padding or 16, Gap = props.Gap or 12, Parent = win })
	area.Instance.Position = UDim2.fromOffset(0, 47)
	local self = Base(win)
	self.Content = area.Content
	self.TitleLabel = title
	local minimized = false
	local fullSize = size
	if props.Minimizable ~= false then
		local mb = Onyx.Button({ Icon = "minus", Variant = "ghost", Size = "sm", Parent = btns, LayoutOrder = 1 })
		mb.Instance.Size = UDim2.fromOffset(28, 28)
		mb.Changed:Connect(function()
			minimized = not minimized
			area.Instance.Visible = not minimized
			if minimized then fullSize = win.Size end
			win.Size = minimized and UDim2.new(fullSize.X.Scale, fullSize.X.Offset, 0, 46) or fullSize
		end)
	end
	if props.Closable ~= false then
		local cb = Onyx.Button({ Icon = "x", Variant = "ghost", Size = "sm", Parent = btns, LayoutOrder = 2 })
		cb.Instance.Size = UDim2.fromOffset(28, 28)
		cb.Changed:Connect(function()
			self:Close()
		end)
	end
	function self:Close() win.Visible = false if props.OnClose then props.OnClose() end end
	function self:Toggle() win.Visible = not win.Visible end
	function self:SetTitle(t) title.Text = t end
	reactive(win, function()
		win.BackgroundColor3 = Theme.Surface st.Color = Theme.Border title.TextColor3 = Theme.Text line.BackgroundColor3 = Theme.Border
	end)
	if props.Draggable ~= false then
		local startPos, startMouse
		drag(bar, function(input, began)
			if began then startPos, startMouse = win.Position, Vector2.new(input.Position.X, input.Position.Y) return end
			local d = Vector2.new(input.Position.X, input.Position.Y) - startMouse
			win.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
		end)
	end
	if props.Resizable then
		local grip = New("TextButton", { AnchorPoint = Vector2.new(1, 1), Position = UDim2.fromScale(1, 1), Size = UDim2.fromOffset(18, 18), ZIndex = 5, Parent = win })
		local g = makeIcon("chevron-right", 10, "TextDim", grip)
		g.Instance.Rotation = 45 g.Instance.Position = UDim2.fromOffset(4, 4)
		local s0, m0
		local minS = props.MinSize or Vector2.new(320, 200)
		drag(grip, function(input, began)
			if began then s0, m0 = win.AbsoluteSize, Vector2.new(input.Position.X, input.Position.Y) return end
			local d = Vector2.new(input.Position.X, input.Position.Y) - m0
			win.Size = UDim2.fromOffset(math.max(minS.X, s0.X + d.X), math.max(minS.Y, s0.Y + d.Y))
			fullSize = win.Size
		end)
	end
	if props.ToggleKey then
		self._maid:Give(UserInputService.InputBegan:Connect(function(input, gp)
			if not gp and input.KeyCode == props.ToggleKey then self:Toggle() end
		end))
	end
	return self
end
