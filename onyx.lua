-- Onyx Neumorphic UI Library V3.2 (7RQXY Edition)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

local Onyx = { Version = "3.2.0", Animated = true }

local Signal = {}
Signal.__index = Signal
local Connection = {}
Connection.__index = Connection

function Connection:Disconnect()
	self.Connected = false
	local i = table.find(self._sig._list, self)
	if i then table.remove(self._sig._list, i) end
end
function Signal.new() return setmetatable({ _list = {} }, Signal) end
function Signal:Connect(fn)
	local c = setmetatable({ Connected = true, _fn = fn, _sig = self }, Connection)
	table.insert(self._list, c)
	return c
end
function Signal:Fire(...)
	for _, c in table.clone(self._list) do
		if c.Connected then task.spawn(c._fn, ...) end
	end
end

local Maid = {}
Maid.__index = Maid
function Maid.new() return setmetatable({ _t = {} }, Maid) end
function Maid:Add(item)
	table.insert(self._t, item)
	return item
end
function Maid:Clean()
	local t = self._t
	self._t = {}
	for _, x in t do
		local ty = typeof(x)
		if ty == "RBXScriptConnection" then x:Disconnect()
		elseif ty == "Instance" then x:Destroy()
		elseif ty == "function" then x()
		elseif ty == "table" and x.Disconnect then x:Disconnect()
		elseif ty == "table" and x.Destroy then x:Destroy()
		end
	end
end

local function rgb(r, g, b) return Color3.fromRGB(r, g, b) end

local Theme = {
	Base = rgb(24, 26, 33),
	SurfaceTop = rgb(32, 35, 44),
	SurfaceBot = rgb(20, 22, 28),
	InsetTop = rgb(13, 14, 18),
	InsetBot = rgb(27, 30, 38),
	LightBevel = rgb(52, 57, 72),
	DarkBevel = rgb(10, 11, 15),
	ShadowDark = rgb(8, 9, 12),
	ShadowLight = rgb(42, 46, 58),
	Text = rgb(240, 244, 255),
	TextMuted = rgb(148, 156, 178),
	TextDim = rgb(98, 105, 125),
	Accent = rgb(59, 130, 246),
	AccentGlow = rgb(96, 165, 250),
	AccentDark = rgb(29, 78, 216),
	Success = rgb(16, 185, 129),
	Warning = rgb(245, 158, 11),
	Danger = rgb(239, 68, 68),
	Radius = 12,
}
Onyx.Theme = Theme

local FAMILY = "rbxasset://fonts/families/GothamSSm.json"
local Fonts = {
	Regular = Font.new(FAMILY, Enum.FontWeight.Regular),
	Medium = Font.new(FAMILY, Enum.FontWeight.Medium),
	SemiBold = Font.new(FAMILY, Enum.FontWeight.SemiBold),
	Bold = Font.new(FAMILY, Enum.FontWeight.Bold),
}
Onyx.Fonts = Fonts

local TWEEN_FAST = TweenInfo.new(0.18, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
local TWEEN_SPRING = TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

local function tween(inst, props, animate, info)
	if animate and Onyx.Animated then
		local tw = TweenService:Create(inst, info or TWEEN_FAST, props)
		tw:Play()
		return tw
	else
		for k, v in props do inst[k] = v end
	end
end

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
			inst.TextSize = 13
			inst.TextColor3 = Theme.Text
			inst.TextXAlignment = Enum.TextXAlignment.Left
			if not inst:IsA("TextBox") then inst.Text = "" end
		end
		if inst:IsA("ScrollingFrame") then
			inst.ScrollBarThickness = 2
			inst.ScrollBarImageColor3 = Theme.Accent
			inst.ScrollBarImageTransparency = 0.35
			inst.CanvasSize = UDim2.new()
			inst.AutomaticCanvasSize = Enum.AutomaticSize.Y
			inst.ScrollingDirection = Enum.ScrollingDirection.Y
		end
	end
	local parent = props.Parent
	if type(parent) == "table" then parent = parent.Content or parent.Instance end
	for k, v in props do if k ~= "Parent" then inst[k] = v end end
	if children then for _, c in children do c.Parent = inst end end
	inst.Parent = parent
	return inst
end

local function Corner(parent, r)
	return New("UICorner", { CornerRadius = typeof(r) == "UDim" and r or UDim.new(0, r or Theme.Radius), Parent = parent })
end

local function Pad(parent, a, b, c, d)
	local l, t, r, bt
	if b == nil then l, t, r, bt = a, a, a, a elseif c == nil then l, t, r, bt = a, b, a, b else l, t, r, bt = a, b, c, d end
	return New("UIPadding", { PaddingLeft = UDim.new(0, l), PaddingTop = UDim.new(0, t), PaddingRight = UDim.new(0, r), PaddingBottom = UDim.new(0, bt), Parent = parent })
end

local function List(parent, o)
	o = o or {}
	return New("UIListLayout", {
		FillDirection = o.Horizontal and Enum.FillDirection.Horizontal or Enum.FillDirection.Vertical,
		Padding = UDim.new(0, o.Gap or 0),
		SortOrder = Enum.SortOrder.LayoutOrder,
		HorizontalAlignment = o.HAlign or Enum.HorizontalAlignment.Left,
		VerticalAlignment = o.VAlign or Enum.VerticalAlignment.Top,
		Parent = parent
	})
end
Onyx.List = List

local function ApplyRaisedNeumorph(frame, radius, thickness)
	frame.BackgroundColor3 = Color3.new(1, 1, 1)
	frame.BackgroundTransparency = 0
	Corner(frame, radius or Theme.Radius)
	local surfGrad = New("UIGradient", {
		Rotation = 135,
		Color = ColorSequence.new(Theme.SurfaceTop, Theme.SurfaceBot),
		Parent = frame
	})
	local st = New("UIStroke", {
		Color = Color3.new(1, 1, 1),
		Thickness = thickness or 1.2,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = frame
	})
	local stGrad = New("UIGradient", {
		Rotation = 135,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Theme.LightBevel),
			ColorSequenceKeypoint.new(0.5, Theme.Base),
			ColorSequenceKeypoint.new(1, Theme.DarkBevel)
		}),
		Parent = st
	})
	return st, surfGrad, stGrad
end

local function ApplyInsetNeumorph(frame, radius, thickness)
	frame.BackgroundColor3 = Color3.new(1, 1, 1)
	frame.BackgroundTransparency = 0
	Corner(frame, radius or 8)
	local surfGrad = New("UIGradient", {
		Rotation = 135,
		Color = ColorSequence.new(Theme.InsetTop, Theme.InsetBot),
		Parent = frame
	})
	local st = New("UIStroke", {
		Color = Color3.new(1, 1, 1),
		Thickness = thickness or 1.2,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = frame
	})
	local stGrad = New("UIGradient", {
		Rotation = 135,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Theme.DarkBevel),
			ColorSequenceKeypoint.new(0.6, Theme.Base),
			ColorSequenceKeypoint.new(1, Theme.LightBevel)
		}),
		Parent = st
	})
	return st, surfGrad, stGrad
end

local function ApplyAccentNeumorph(frame, radius)
	frame.BackgroundColor3 = Color3.new(1, 1, 1)
	frame.BackgroundTransparency = 0
	Corner(frame, radius or 999)
	New("UIGradient", {
		Rotation = 135,
		Color = ColorSequence.new(Theme.AccentGlow, Theme.AccentDark),
		Parent = frame
	})
	local st = New("UIStroke", {
		Color = Theme.AccentGlow,
		Thickness = 1,
		Transparency = 0.25,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = frame
	})
	return st
end

local function Base(instance)
	local self = { Instance = instance, _maid = Maid.new(), Changed = Signal.new() }
	instance.Destroying:Connect(function() self._maid:Clean() end)
	function self:Destroy() instance:Destroy() end
	return self
end

local function isPointer(i)
	return i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch
end

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

local IconDefs = {
	["check"] = function(b) b.seg(.2, .52, .42, .74) b.seg(.42, .74, .82, .3) end,
	["chevron-down"] = function(b) b.seg(.22, .38, .5, .66) b.seg(.5, .66, .78, .38) end,
	["x"] = function(b) b.seg(.26, .26, .74, .74) b.seg(.74, .26, .26, .74) end,
	["minus"] = function(b) b.seg(.22, .5, .78, .5) end,
}

local function makeIcon(name, size, col, parent)
	size = size or 16
	local box = New("Frame", { Name = "Icon", Size = UDim2.fromOffset(size, size), Parent = parent })
	local cur = typeof(col) == "Color3" and col or (Theme[col] or Theme.Text)
	local t = math.max(1.2, size * 0.1) / size
	local b = {
		seg = function(ax, ay, bx, by, w)
			w = w or t
			local dx, dy = bx - ax, by - ay
			local len = math.sqrt(dx * dx + dy * dy)
			New("Frame", {
				AnchorPoint = Vector2.new(.5, .5),
				Position = UDim2.fromScale((ax + bx) / 2, (ay + by) / 2),
				Size = UDim2.fromScale(len + w, w),
				Rotation = math.deg(math.atan2(dy, dx)),
				BackgroundColor3 = cur,
				BackgroundTransparency = 0,
				Parent = box
			}, { New("UICorner", { CornerRadius = UDim.new(.5, 0) }) })
		end
	}
	if IconDefs[name] then IconDefs[name](b) end
	return { Instance = box }
end

local defaultGui
function Onyx.GetRoot(name)
	if defaultGui and defaultGui.Parent then return defaultGui end
	local guiName = name or "OnyxUI_7rqxyRoot"
	local host = (gethui and gethui()) or CoreGui
	local ok = pcall(function()
		local old = host:FindFirstChild(guiName)
		if old then old:Destroy() end
	end)
	if not ok then host = LocalPlayer:WaitForChild("PlayerGui") end
	local old = host:FindFirstChild(guiName)
	if old then old:Destroy() end

	defaultGui = New("ScreenGui", {
		Name = guiName,
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = 9999,
		Parent = host
	})
	return defaultGui
end

local layerStack = {}
local layerCounter = 0

local function openLayer(anchor, o)
	o = o or {}
	local gui = Onyx.GetRoot()
	local ov = gui:FindFirstChild("OnyxOverlay") or New("Frame", {
		Name = "OnyxOverlay",
		Size = UDim2.fromScale(1, 1),
		ZIndex = 500,
		Parent = gui
	})
	layerCounter += 2
	local z = 500 + layerCounter
	local layer = { Open = true, Overlay = ov }
	local blocker = New("TextButton", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		ZIndex = z,
		Parent = ov
	})
	local host = New("Frame", {
		AutomaticSize = Enum.AutomaticSize.XY,
		Size = UDim2.new(),
		Position = UDim2.fromOffset(-10000, -10000),
		ZIndex = z + 1,
		Parent = ov
	})
	layer.Host, layer.Blocker = host, blocker
	table.insert(layerStack, layer)

	function layer.Place()
		if not layer.Open then return end
		local cs, vs = host.AbsoluteSize, ov.AbsoluteSize
		local ap, as = anchor.AbsolutePosition - ov.AbsolutePosition, anchor.AbsoluteSize
		local x = math.clamp(ap.X, 8, math.max(8, vs.X - cs.X - 8))
		local y = math.clamp(ap.Y + as.Y + 6, 8, math.max(8, vs.Y - cs.Y - 8))
		host.Position = UDim2.fromOffset(x, y)
	end
	host:GetPropertyChangedSignal("AbsoluteSize"):Connect(layer.Place)
	task.defer(function() RunService.Heartbeat:Wait() layer.Place() end)

	function layer.Close()
		if not layer.Open then return end
		layer.Open = false
		local i = table.find(layerStack, layer)
		if i then table.remove(layerStack, i) end
		if o.OnClose then o.OnClose() end
		host:Destroy()
		blocker:Destroy()
	end
	blocker.Activated:Connect(layer.Close)
	return layer
end

function Onyx.CloseAllLayers()
	for _, layer in table.clone(layerStack) do
		layer.Close()
	end
end

local antiAfkConn
function Onyx.EnableAntiAFK(quiet)
	if antiAfkConn then return end
	local VirtualUser = game:GetService("VirtualUser")
	antiAfkConn = LocalPlayer.Idled:Connect(function()
		VirtualUser:CaptureController()
		VirtualUser:ClickButton2(Vector2.new())
		if not quiet then
			Onyx.Notify({ Title = "Anti-AFK", Text = "Idle prevented.", Duration = 2 })
		end
	end)
end

local notifContainer
function Onyx.Notify(props)
	props = props or {}
	local gui = Onyx.GetRoot()
	if not notifContainer or not notifContainer.Parent then
		notifContainer = New("Frame", {
			Name = "OnyxNotifications",
			AnchorPoint = Vector2.new(1, 1),
			Position = UDim2.new(1, -18, 1, -18),
			Size = UDim2.new(0, 300, 1, -36),
			ZIndex = 900,
			Parent = gui
		})
		List(notifContainer, { Gap = 10, HAlign = Enum.HorizontalAlignment.Right, VAlign = Enum.VerticalAlignment.Bottom })
	end

	local kindColor = Theme.AccentGlow
	if props.Type == "Success" then kindColor = Theme.Success
	elseif props.Type == "Warning" then kindColor = Theme.Warning
	elseif props.Type == "Danger" or props.Type == "Error" then kindColor = Theme.Danger end

	local holder = New("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		ClipsDescendants = true,
		Parent = notifContainer
	})
	local card = New("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Position = UDim2.fromOffset(320, 0),
		Parent = holder
	})
	ApplyRaisedNeumorph(card, 11, 1.2)
	Pad(card, 12, 10, 12, 12)
	List(card, { Gap = 5 })

	local topRow = New("Frame", { Size = UDim2.new(1, 0, 0, 16), Parent = card })
	local dot = New("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		Size = UDim2.fromOffset(6, 6),
		BackgroundColor3 = kindColor,
		BackgroundTransparency = 0,
		Parent = topRow
	})
	Corner(dot, 99)
	New("TextLabel", {
		Position = UDim2.fromOffset(12, 0),
		Size = UDim2.new(1, -12, 1, 0),
		Text = string.upper(props.Title or "NOTIFICATION"),
		FontFace = Fonts.Bold,
		TextSize = 11,
		TextColor3 = Theme.Text,
		Parent = topRow
	})

	New("TextLabel", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Text = props.Text or "",
		FontFace = Fonts.Medium,
		TextSize = 11,
		TextColor3 = Theme.TextMuted,
		TextWrapped = true,
		Parent = card
	})

	local barTrack = New("Frame", { Size = UDim2.new(1, 0, 0, 3), Parent = card })
	ApplyInsetNeumorph(barTrack, 99, 0.8)
	local barFill = New("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = kindColor,
		BackgroundTransparency = 0,
		Parent = barTrack
	})
	Corner(barFill, 99)

	local duration = props.Duration or 4
	tween(card, { Position = UDim2.fromOffset(0, 0) }, true, TWEEN_SPRING)
	tween(barFill, { Size = UDim2.fromScale(0, 1) }, true, TweenInfo.new(duration, Enum.EasingStyle.Linear))

	task.delay(duration, function()
		if not holder.Parent then return end
		tween(card, { Position = UDim2.fromOffset(330, 0) }, true, TWEEN_FAST)
		task.wait(0.2)
		if holder.Parent then holder:Destroy() end
	end)
end

local function AttachContainerMethods(target)
	function target:Telemetry(p) p = p or {} p.Parent = self.Content return Onyx.TelemetryDisplay(p) end
	function target:StatRow(p) p = p or {} p.Parent = self.Content return Onyx.StatRow(p) end
	function target:Banner(p) p = p or {} p.Parent = self.Content return Onyx.InstructionBanner(p) end
	function target:Switch(p) p = p or {} p.Parent = self.Content return Onyx.Switch(p) end
	function target:Button(p) p = p or {} p.Parent = self.Content return Onyx.Button(p) end
	function target:Slider(p) p = p or {} p.Parent = self.Content return Onyx.Slider(p) end
	function target:Select(p) p = p or {} p.Parent = self.Content return Onyx.Select(p) end
	function target:Dropdown(p) p = p or {} p.Parent = self.Content return Onyx.Select(p) end
	function target:MultiSelect(p) p = p or {} p.Parent = self.Content return Onyx.MultiSelect(p) end
	function target:ModeSelector(p) p = p or {} p.Parent = self.Content return Onyx.ModeSelector(p) end
	function target:TextInput(p) p = p or {} p.Parent = self.Content return Onyx.TextInput(p) end
	function target:NumberInput(p) p = p or {} p.Parent = self.Content return Onyx.NumberInput(p) end
	function target:Keybind(p) p = p or {} p.Parent = self.Content return Onyx.Keybind(p) end
	function target:ColorPicker(p) p = p or {} p.Parent = self.Content return Onyx.ColorPicker(p) end
	function target:LogConsole(p) p = p or {} p.Parent = self.Content return Onyx.LogConsole(p) end
	function target:Card(p) p = p or {} p.Parent = self.Content return Onyx.Card(p) end
	function target:Row(p) p = p or {} p.Parent = self.Content return Onyx.Row(p) end
	function target:Container(p) p = p or {} p.Parent = self.Content return Onyx.Container(p) end
end

function Onyx.Row(props)
	props = props or {}
	local row = New("Frame", {
		Size = props.Size or UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = props.LayoutOrder,
		Parent = props.Parent
	})
	List(row, { Horizontal = true, Gap = props.Gap or 10, VAlign = Enum.VerticalAlignment.Center })
	local self = Base(row)
	self.Content = row
	AttachContainerMethods(self)
	return self
end

function Onyx.Container(props)
	props = props or {}
	local container = New("Frame", {
		Size = props.Size or UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = props.LayoutOrder,
		Parent = props.Parent
	})
	List(container, { Gap = props.Gap or 10 })
	local self = Base(container)
	self.Content = container
	AttachContainerMethods(self)
	return self
end

function Onyx.Card(props)
	props = props or {}
	local wrapper = New("Frame", {
		Size = props.Size or UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = props.LayoutOrder,
		Parent = props.Parent
	})
	New("Frame", {
		Position = UDim2.fromOffset(-1, -1),
		Size = UDim2.new(1, 2, 1, 2),
		BackgroundColor3 = Theme.ShadowLight,
		BackgroundTransparency = 0.72,
		ZIndex = 1,
		Parent = wrapper
	}, { Corner(nil, 13) })
	New("Frame", {
		Position = UDim2.fromOffset(1, 2),
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = Theme.ShadowDark,
		BackgroundTransparency = 0.45,
		ZIndex = 1,
		Parent = wrapper
	}, { Corner(nil, 13) })

	local root = New("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		ZIndex = 2,
		Parent = wrapper
	})
	ApplyRaisedNeumorph(root, 13, 1.2)
	Pad(root, 14, 13, 14, 14)
	List(root, { Gap = 10 })

	local self = Base(wrapper)
	if props.Title then
		local header = New("Frame", { Size = UDim2.new(1, 0, 0, 18), LayoutOrder = 1, Parent = root })
		local accentBar = New("Frame", {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 0, 0.5, 0),
			Size = UDim2.fromOffset(3, 12),
			Parent = header
		})
		if props.DangerAccent then
			accentBar.BackgroundColor3 = Theme.Danger
			accentBar.BackgroundTransparency = 0
			Corner(accentBar, 99)
		else
			ApplyAccentNeumorph(accentBar, 99)
		end
		New("TextLabel", {
			Position = UDim2.fromOffset(10, 0),
			Size = UDim2.new(1, -10, 1, 0),
			Text = string.upper(props.Title),
			FontFace = Fonts.Bold,
			TextSize = 11,
			TextColor3 = props.DangerAccent and Theme.Danger or Theme.TextMuted,
			Parent = header
		})
	end
	local content = New("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 2, Parent = root })
	List(content, { Gap = 9 })
	self.Content = content
	AttachContainerMethods(self)
	return self
end

function Onyx.Window(props)
	props = props or {}
	local size = props.Size or UDim2.fromOffset(440, 620)
	local toggleKey = props.ToggleKey or Enum.KeyCode.RightControl

	local shadowHolder = New("Frame", {
		Size = size,
		Position = props.Position or UDim2.new(.5, -size.X.Offset / 2, .5, -size.Y.Offset / 2),
		Visible = props.Visible ~= false,
		Parent = props.Parent or Onyx.GetRoot()
	})
	New("Frame", {
		Position = UDim2.fromOffset(-2, -2),
		Size = UDim2.new(1, 4, 1, 4),
		BackgroundColor3 = Theme.ShadowLight,
		BackgroundTransparency = 0.78,
		ZIndex = 0,
		Parent = shadowHolder
	}, { Corner(nil, 19) })
	New("Frame", {
		Position = UDim2.fromOffset(2, 3),
		Size = UDim2.new(1, 2, 1, 2),
		BackgroundColor3 = Theme.ShadowDark,
		BackgroundTransparency = 0.35,
		ZIndex = 0,
		Parent = shadowHolder
	}, { Corner(nil, 19) })

	local win = New("Frame", { Size = UDim2.fromScale(1, 1), ClipsDescendants = true, ZIndex = 1, Parent = shadowHolder })
	ApplyRaisedNeumorph(win, 18, 1.5)

	local bar = New("Frame", { Size = UDim2.new(1, 0, 0, 52), Parent = win })
	local ledWell = New("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 16, 0.5, 0),
		Size = UDim2.fromOffset(18, 18),
		Parent = bar
	})
	ApplyInsetNeumorph(ledWell, 999, 1)
	local ledDot = New("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(8, 8),
		BackgroundColor3 = Theme.TextDim,
		BackgroundTransparency = 0,
		Parent = ledWell
	})
	Corner(ledDot, 999)
	local ledStroke = New("UIStroke", { Color = Theme.TextDim, Thickness = 1.5, Transparency = 0.4, Parent = ledDot })

	New("TextLabel", {
		Text = props.Title or "7RQXY // MASTERMIND",
		FontFace = Fonts.Bold,
		TextSize = 14,
		TextColor3 = Theme.Text,
		Position = UDim2.fromOffset(42, 8),
		Size = UDim2.new(1, -130, 0, 18),
		Parent = bar
	})
	New("TextLabel", {
		Text = props.Subtitle or "V3.2 ONYX EDITION • RCTRL TO HIDE",
		FontFace = Fonts.Medium,
		TextSize = 10,
		TextColor3 = Theme.TextDim,
		Position = UDim2.fromOffset(42, 26),
		Size = UDim2.new(1, -130, 0, 14),
		Parent = bar
	})

	local groove = New("Frame", { Position = UDim2.new(0, 16, 1, -2), Size = UDim2.new(1, -32, 0, 2), BackgroundColor3 = Theme.ShadowDark, BackgroundTransparency = 0.3, Parent = bar })
	New("Frame", { Position = UDim2.new(0, 0, 0, 1), Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = Theme.LightBevel, BackgroundTransparency = 0.5, Parent = groove })

	local btns = New("Frame", { AnchorPoint = Vector2.new(1, .5), Position = UDim2.new(1, -14, .5, 0), Size = UDim2.fromOffset(66, 28), Parent = bar })
	List(btns, { Horizontal = true, Gap = 8, HAlign = Enum.HorizontalAlignment.Right, VAlign = Enum.VerticalAlignment.Center })

	local function makeControlBtn(iconName, hoverColor)
		local b = New("TextButton", { Size = UDim2.fromOffset(28, 28), Parent = btns })
		local st = ApplyRaisedNeumorph(b, 999, 1)
		local ic = makeIcon(iconName, 13, "TextMuted", b)
		ic.Instance.AnchorPoint, ic.Instance.Position = Vector2.new(.5, .5), UDim2.fromScale(.5, .5)
		b.MouseEnter:Connect(function() tween(st, { Color = hoverColor }, true) end)
		b.MouseLeave:Connect(function() tween(st, { Color = Color3.new(1, 1, 1) }, true) end)
		return b
	end

	local tabBarWrapper = New("Frame", {
		Position = UDim2.fromOffset(16, 58),
		Size = UDim2.new(1, -32, 0, 34),
		Visible = false,
		Parent = win
	})
	ApplyInsetNeumorph(tabBarWrapper, 10, 1)
	Pad(tabBarWrapper, 4)
	local tabBarList = New("ScrollingFrame", {
		Size = UDim2.fromScale(1, 1),
		ScrollBarThickness = 0,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.X,
		ScrollingDirection = Enum.ScrollingDirection.X,
		Parent = tabBarWrapper
	})
	List(tabBarList, { Horizontal = true, Gap = 6, VAlign = Enum.VerticalAlignment.Center })

	local bodyHolder = New("Frame", {
		Position = UDim2.fromOffset(0, 54),
		Size = UDim2.new(1, 0, 1, -56),
		Parent = win
	})

	local defaultSc = New("ScrollingFrame", { Size = UDim2.fromScale(1, 1), Parent = bodyHolder })
	local defaultInner = New("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Parent = defaultSc })
	List(defaultInner, { Gap = 12 })
	Pad(defaultInner, 16, 12, 16, 18)

	local self = Base(shadowHolder)
	self.Content = defaultInner
	self._tabs = {}
	self._activeTab = nil

	function self:SetActiveLED(active)
		local col = active and Theme.Success or Theme.TextDim
		tween(ledDot, { BackgroundColor3 = col }, true)
		tween(ledStroke, { Color = col }, true)
	end

	function self:Tab(title)
		if #self._tabs == 0 then
			tabBarWrapper.Visible = true
			defaultSc.Visible = false
			bodyHolder.Position = UDim2.fromOffset(0, 96)
			bodyHolder.Size = UDim2.new(1, 0, 1, -98)
		end

		local tabBtn = New("TextButton", {
			Size = UDim2.fromOffset(math.max(74, #title * 8 + 22), 26),
			Parent = tabBarList
		})
		Corner(tabBtn, 7)

		local activeBg = New("Frame", { Size = UDim2.fromScale(1, 1), Parent = tabBtn })
		local activeSt = ApplyAccentNeumorph(activeBg, 7)
		-- Explicitly hide accent background & stroke on creation so inactive tabs stay dark
		activeBg.BackgroundTransparency = 1
		activeSt.Transparency = 1

		local tabLbl = New("TextLabel", {
			Size = UDim2.fromScale(1, 1),
			Text = string.upper(title),
			FontFace = Fonts.Bold,
			TextSize = 11,
			TextColor3 = Theme.TextMuted,
			TextXAlignment = Enum.TextXAlignment.Center,
			ZIndex = 2,
			Parent = tabBtn
		})

		local tabSc = New("ScrollingFrame", { Size = UDim2.fromScale(1, 1), Visible = false, Parent = bodyHolder })
		local tabInner = New("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Parent = tabSc })
		List(tabInner, { Gap = 12 })
		Pad(tabInner, 16, 8, 16, 18)

		local tabObj = {
			Title = title,
			Button = tabBtn,
			ActiveBg = activeBg,
			ActiveStroke = activeSt,
			Label = tabLbl,
			Scroll = tabSc,
			Content = tabInner
		}
		AttachContainerMethods(tabObj)
		table.insert(self._tabs, tabObj)

		local function selectThis(animate)
			self._activeTab = tabObj
			for _, t in ipairs(self._tabs) do
				local sel = (t == tabObj)
				t.Scroll.Visible = sel
				tween(t.ActiveBg, { BackgroundTransparency = sel and 0 or 1 }, animate)
				tween(t.ActiveStroke, { Transparency = sel and 0.25 or 1 }, animate)
				tween(t.Label, { TextColor3 = sel and rgb(255, 255, 255) or Theme.TextMuted }, animate)
			end
			Onyx.CloseAllLayers()
		end

		tabBtn.Activated:Connect(function() selectThis(true) end)
		if #self._tabs == 1 then selectThis(false) end
		return tabObj
	end

	local minimized, fullSize = false, size
	local mb = makeControlBtn("minus", Theme.AccentGlow)
	mb.Activated:Connect(function()
		minimized = not minimized
		bodyHolder.Visible = not minimized
		if #self._tabs > 0 then tabBarWrapper.Visible = not minimized end
		Onyx.CloseAllLayers()
		if minimized then fullSize = shadowHolder.Size end
		tween(shadowHolder, { Size = minimized and UDim2.new(fullSize.X.Scale, fullSize.X.Offset, 0, 52) or fullSize }, true, TWEEN_SPRING)
	end)

	local cb = makeControlBtn("x", Theme.Danger)
	cb.Activated:Connect(function()
		shadowHolder.Visible = false
		self:SetActiveLED(false)
		Onyx.CloseAllLayers()
		if props.OnClose then props.OnClose() end
	end)

	local startPos, startMouse
	drag(bar, function(input, began)
		if began then startPos, startMouse = shadowHolder.Position, Vector2.new(input.Position.X, input.Position.Y) return end
		local d = Vector2.new(input.Position.X, input.Position.Y) - startMouse
		shadowHolder.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
	end)

	if toggleKey then
		self._maid:Add(UserInputService.InputBegan:Connect(function(input, gp)
			if not gp and input.KeyCode == toggleKey and shadowHolder.Parent then
				shadowHolder.Visible = not shadowHolder.Visible
				if not shadowHolder.Visible then Onyx.CloseAllLayers() end
			end
		end))
	end

	AttachContainerMethods(self)
	return self
end

function Onyx.TelemetryDisplay(props)
	props = props or {}
	local well = New("Frame", { Size = props.Size or UDim2.new(1, 0, 0, 38), LayoutOrder = props.LayoutOrder, Parent = props.Parent })
	ApplyInsetNeumorph(well, 9, 1.2)
	Pad(well, 12, 0, 12, 0)

	local pulseDot = New("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		Size = UDim2.fromOffset(7, 7),
		BackgroundColor3 = Theme.AccentGlow,
		BackgroundTransparency = 0,
		Parent = well
	})
	Corner(pulseDot, 999)

	local lbl = New("TextLabel", {
		Position = UDim2.fromOffset(15, 0),
		Size = UDim2.new(1, -15, 1, 0),
		Text = props.Text or "Ready",
		FontFace = Fonts.Medium,
		TextSize = 11,
		TextColor3 = Theme.TextMuted,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = well
	})

	local self = Base(well)
	function self:SetStatus(text, isActive)
		lbl.Text = text
		tween(pulseDot, { BackgroundColor3 = isActive and Theme.Success or Theme.AccentGlow }, true)
	end
	return self
end

function Onyx.StatRow(props)
	props = props or {}
	local well = New("Frame", { Size = props.Size or UDim2.new(1, 0, 0, 34), LayoutOrder = props.LayoutOrder, Parent = props.Parent })
	ApplyInsetNeumorph(well, 8, 1)
	Pad(well, 12, 0, 12, 0)
	New("TextLabel", {
		Size = UDim2.new(0.6, 0, 1, 0),
		Text = props.Label or "METRIC",
		FontFace = Fonts.Medium,
		TextSize = 12,
		TextColor3 = Theme.TextMuted,
		Parent = well
	})
	local valLbl = New("TextLabel", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 0, 0, 0),
		Size = UDim2.new(0.4, 0, 1, 0),
		Text = tostring(props.Value or "0"),
		FontFace = Fonts.Bold,
		TextSize = 12,
		TextColor3 = Theme.AccentGlow,
		TextXAlignment = Enum.TextXAlignment.Right,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = well
	})
	local self = Base(well)
	function self:SetValue(v) valLbl.Text = tostring(v) end
	function self:GetValue() return valLbl.Text end
	return self
end

function Onyx.InstructionBanner(props)
	props = props or {}
	local well = New("Frame", {
		Size = props.Size or UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = props.LayoutOrder,
		Parent = props.Parent
	})
	ApplyInsetNeumorph(well, 8, 1.2)
	Pad(well, 12, 10, 12, 10)
	local lbl = New("TextLabel", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		RichText = true,
		TextWrapped = true,
		Text = props.Text or "",
		FontFace = Fonts.Bold,
		TextSize = 11,
		TextColor3 = props.Color or Theme.Warning,
		Parent = well
	})
	local self = Base(well)
	function self:SetText(t) lbl.Text = t end
	return self
end

function Onyx.Switch(props)
	props = props or {}
	local wScale = props.Width or 1
	local root = New("Frame", {
		Size = props.Size or UDim2.new(wScale, 0, 0, 28),
		LayoutOrder = props.LayoutOrder,
		Parent = props.Parent
	})
	local lbl = New("TextLabel", {
		Size = UDim2.new(1, -56, 1, 0),
		Text = props.Label or "",
		TextSize = 12,
		FontFace = Fonts.Medium,
		TextColor3 = Theme.Text,
		Parent = root
	})

	local btn = New("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.fromOffset(44, 24),
		Parent = root
	})
	local trackStroke = ApplyInsetNeumorph(btn, 999, 1.2)

	local activeGlow = New("Frame", { Size = UDim2.fromScale(1, 1), Parent = btn })
	local activeGlowStroke = ApplyAccentNeumorph(activeGlow, 999)
	activeGlow.BackgroundTransparency = 1
	activeGlowStroke.Transparency = 1

	local knob = New("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 3, 0.5, 0),
		Size = UDim2.fromOffset(18, 18),
		ZIndex = 2,
		Parent = btn
	})
	ApplyRaisedNeumorph(knob, 999, 1)

	local knobLed = New("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(5, 5),
		BackgroundColor3 = Theme.TextDim,
		BackgroundTransparency = 0,
		Parent = knob
	})
	Corner(knobLed, 999)

	local self = Base(root)
	local on = props.Value or false
	local function paint(animate)
		tween(activeGlow, { BackgroundTransparency = on and 0.15 or 1 }, animate)
		tween(activeGlowStroke, { Transparency = on and 0.25 or 1 }, animate)
		tween(knob, { Position = on and UDim2.new(1, -21, 0.5, 0) or UDim2.new(0, 3, 0.5, 0) }, animate, TWEEN_SPRING)
		tween(knobLed, { BackgroundColor3 = on and Theme.AccentGlow or Theme.TextDim }, animate)
		tween(lbl, { TextColor3 = on and Theme.Text or Theme.TextMuted }, animate)
		tween(trackStroke, { Transparency = on and 0.3 or 0 }, animate)
	end
	paint(false)

	btn.Activated:Connect(function()
		on = not on
		paint(true)
		self.Changed:Fire(on)
		if props.OnChanged then props.OnChanged(on) end
	end)

	function self:SetValue(val, fireCallback)
		on = val == true
		paint(true)
		if fireCallback then
			self.Changed:Fire(on)
			if props.OnChanged then props.OnChanged(on) end
		end
	end
	function self:GetValue() return on end
	return self
end

function Onyx.Button(props)
	props = props or {}
	local wScale = props.Width or 1
	local hPixels = props.Height or 34
	local computedSize = props.Size or UDim2.new(wScale, 0, 0, hPixels)
	if computedSize.Y.Scale > 0 and computedSize.Y.Offset == 0 then
		computedSize = UDim2.new(computedSize.X.Scale, computedSize.X.Offset, 0, hPixels)
	end

	local btn = New("TextButton", {
		Size = computedSize,
		LayoutOrder = props.LayoutOrder,
		Parent = props.Parent
	})
	local st
	if props.Accent then
		st = ApplyAccentNeumorph(btn, 9)
	else
		st = ApplyRaisedNeumorph(btn, 9, 1.2)
	end
	local lbl = New("TextLabel", {
		Size = UDim2.fromScale(1, 1),
		Text = props.Text or "BUTTON",
		FontFace = Fonts.Bold,
		TextSize = 11,
		TextColor3 = props.Accent and rgb(255, 255, 255) or Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Center,
		Parent = btn
	})
	btn.MouseEnter:Connect(function()
		if not props.Accent then tween(st, { Color = Theme.AccentGlow }, true) end
	end)
	btn.MouseLeave:Connect(function()
		if not props.Accent then tween(st, { Color = Color3.new(1, 1, 1) }, true) end
	end)
	btn.Activated:Connect(function()
		if props.OnClick then props.OnClick() end
	end)
	local self = Base(btn)
	function self:SetText(t) lbl.Text = t end
	return self
end

function Onyx.Slider(props)
	props = props or {}
	local min, max, step = props.Min or 0, props.Max or 100, props.Step or 1
	local suffix = props.Suffix or ""
	local value = math.clamp(props.Value or min, min, max)

	local root = New("Frame", { Size = props.Size or UDim2.new(1, 0, 0, 46), LayoutOrder = props.LayoutOrder, Parent = props.Parent })
	New("TextLabel", {
		Size = UDim2.new(1, -70, 0, 20),
		Text = props.Label or "",
		TextSize = 12,
		FontFace = Fonts.Medium,
		TextColor3 = Theme.Text,
		Parent = root
	})

	local badge = New("Frame", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 0, 0, 0),
		Size = UDim2.fromOffset(60, 20),
		Parent = root
	})
	ApplyInsetNeumorph(badge, 6, 1)
	local valLabel = New("TextLabel", {
		Size = UDim2.fromScale(1, 1),
		TextXAlignment = Enum.TextXAlignment.Center,
		TextSize = 11,
		FontFace = Fonts.Bold,
		TextColor3 = Theme.AccentGlow,
		Parent = badge
	})

	local holder = New("Frame", { Position = UDim2.fromOffset(0, 26), Size = UDim2.new(1, 0, 0, 18), Parent = root })
	local track = New("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		Size = UDim2.new(1, 0, 0, 8),
		Parent = holder
	})
	ApplyInsetNeumorph(track, 999, 1)

	local fill = New("Frame", { Size = UDim2.fromScale(0, 1), Parent = track })
	ApplyAccentNeumorph(fill, 999)

	local thumb = New("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromOffset(18, 18),
		Position = UDim2.new(0, 0, 0.5, 0),
		ZIndex = 3,
		Parent = holder
	})
	ApplyRaisedNeumorph(thumb, 999, 1.2)
	local thumbCore = New("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(6, 6),
		BackgroundColor3 = Theme.AccentGlow,
		BackgroundTransparency = 0,
		Parent = thumb
	})
	Corner(thumbCore, 999)

	local self = Base(root)
	local function render()
		local a = (value - min) / math.max(max - min, 0.0001)
		fill.Size = UDim2.fromScale(a, 1)
		thumb.Position = UDim2.new(a, 0, 0.5, 0)
		local fmt = (step < 1) and string.format("%.2f", value) or tostring(math.round(value))
		valLabel.Text = fmt .. suffix
	end
	local function set(v, fire)
		local snapped = min + math.round((v - min) / step) * step
		value = math.clamp(tonumber(string.format("%.4f", snapped)), min, max)
		render()
		if fire ~= false then
			self.Changed:Fire(value)
			if props.OnChanged then props.OnChanged(value) end
		end
	end

	local hit = New("TextButton", { Size = UDim2.new(1, 16, 1, 0), Position = UDim2.fromOffset(-8, 0), ZIndex = 4, Parent = holder })
	drag(hit, function(input, began)
		if began then tween(thumb, { Size = UDim2.fromOffset(21, 21) }, true, TWEEN_SPRING) end
		local a = math.clamp((input.Position.X - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
		set(min + a * (max - min), true)
	end, function()
		tween(thumb, { Size = UDim2.fromOffset(18, 18) }, true, TWEEN_SPRING)
	end)
	render()
	function self:SetValue(v, fire) set(v, fire) end
	function self:GetValue() return value end
	return self
end

-- Single-Choice Dropdown Menu
function Onyx.Select(props)
	props = props or {}
	local options = props.Options or {}
	local root = New("Frame", { Size = props.Size or UDim2.new(1, 0, 0, 56), LayoutOrder = props.LayoutOrder, Parent = props.Parent })
	New("TextLabel", {
		Size = UDim2.new(1, 0, 0, 18),
		Text = props.Label or "Dropdown",
		TextSize = 12,
		FontFace = Fonts.Medium,
		TextColor3 = Theme.Text,
		Parent = root
	})

	local trig = New("TextButton", { Position = UDim2.fromOffset(0, 22), Size = UDim2.new(1, 0, 0, 34), Parent = root })
	local st = ApplyRaisedNeumorph(trig, 9, 1.2)

	local lbl = New("TextLabel", {
		Position = UDim2.fromOffset(12, 0),
		Size = UDim2.new(1, -44, 1, 0),
		TextSize = 12,
		FontFace = Fonts.SemiBold,
		TextColor3 = Theme.AccentGlow,
		Parent = trig
	})

	local chevWell = New("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -8, 0.5, 0),
		Size = UDim2.fromOffset(20, 20),
		Parent = trig
	})
	ApplyInsetNeumorph(chevWell, 6, 1)
	local chev = makeIcon("chevron-down", 12, "TextMuted", chevWell)
	chev.Instance.AnchorPoint, chev.Instance.Position = Vector2.new(.5, .5), UDim2.fromScale(.5, .5)

	local self = Base(root)
	local value = props.Value or options[1]
	local layer
	local function paint(open)
		lbl.Text = tostring(value or "Select...")
		tween(chev.Instance, { Rotation = open and 180 or 0 }, true, TWEEN_SPRING)
		tween(st, { Color = open and Theme.AccentGlow or Color3.new(1, 1, 1) }, true)
	end
	paint(false)

	trig.Activated:Connect(function()
		if layer and layer.Open then layer.Close() return end
		layer = openLayer(trig, { OnClose = function() paint(false) end })
		paint(true)

		local dropShell = New("Frame", {
			Size = UDim2.fromOffset(trig.AbsoluteSize.X, math.min(#options * 32 + 12, 200)),
			Parent = layer.Host
		})
		ApplyRaisedNeumorph(dropShell, 10, 1.4)
		Pad(dropShell, 6)

		local mScroll = New("ScrollingFrame", { Size = UDim2.fromScale(1, 1), Parent = dropShell })
		local mList = List(mScroll, { Gap = 4 })

		for _, opt in ipairs(options) do
			local isSelected = (value == opt)
			local btn = New("TextButton", { Size = UDim2.new(1, 0, 0, 28), Parent = mScroll })
			if isSelected then
				ApplyInsetNeumorph(btn, 7, 1)
			else
				Corner(btn, 7)
			end
			local optTxt = New("TextLabel", {
				Position = UDim2.fromOffset(10, 0),
				Size = UDim2.new(1, -30, 1, 0),
				Text = tostring(opt),
				TextSize = 12,
				FontFace = isSelected and Fonts.Bold or Fonts.Medium,
				TextColor3 = isSelected and Theme.AccentGlow or Theme.TextMuted,
				Parent = btn
			})
			if isSelected then
				local chk = makeIcon("check", 13, "AccentGlow", btn)
				chk.Instance.AnchorPoint, chk.Instance.Position = Vector2.new(1, .5), UDim2.new(1, -8, .5, 0)
			end
			btn.Activated:Connect(function()
				value = opt
				layer.Close()
				paint(false)
				self.Changed:Fire(value)
				if props.OnChanged then props.OnChanged(value) end
			end)
		end
		mScroll.CanvasSize = UDim2.new(0, 0, 0, mList.AbsoluteContentSize.Y + 4)
	end)

	function self:SetValue(v, fire)
		value = v
		paint(false)
		if fire and props.OnChanged then props.OnChanged(v) end
	end
	function self:GetValue() return value end
	function self:SetOptions(newOpts) options = newOpts or {} end
	return self
end
Onyx.Dropdown = Onyx.Select

-- Multi-Choice Dropdown Menu
function Onyx.MultiSelect(props)
	props = props or {}
	local options = props.Options or {}
	local selected = {}
	for _, v in ipairs(props.Values or {}) do selected[v] = true end

	local root = New("Frame", { Size = props.Size or UDim2.new(1, 0, 0, 56), LayoutOrder = props.LayoutOrder, Parent = props.Parent })
	New("TextLabel", {
		Size = UDim2.new(1, 0, 0, 18),
		Text = props.Label or "Multi-Dropdown",
		TextSize = 12,
		FontFace = Fonts.Medium,
		TextColor3 = Theme.Text,
		Parent = root
	})

	local trig = New("TextButton", { Position = UDim2.fromOffset(0, 22), Size = UDim2.new(1, 0, 0, 34), Parent = root })
	local st = ApplyRaisedNeumorph(trig, 9, 1.2)

	local lbl = New("TextLabel", {
		Position = UDim2.fromOffset(12, 0),
		Size = UDim2.new(1, -44, 1, 0),
		TextSize = 12,
		FontFace = Fonts.SemiBold,
		TextColor3 = Theme.AccentGlow,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = trig
	})

	local chevWell = New("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -8, 0.5, 0),
		Size = UDim2.fromOffset(20, 20),
		Parent = trig
	})
	ApplyInsetNeumorph(chevWell, 6, 1)
	local chev = makeIcon("chevron-down", 12, "TextMuted", chevWell)
	chev.Instance.AnchorPoint, chev.Instance.Position = Vector2.new(.5, .5), UDim2.fromScale(.5, .5)

	local self = Base(root)
	local layer

	local function getList()
		local out = {}
		for _, opt in ipairs(options) do
			if selected[opt] then table.insert(out, opt) end
		end
		return out
	end

	local function paint(open)
		local list = getList()
		lbl.Text = (#list > 0) and table.concat(list, ", ") or "None"
		tween(chev.Instance, { Rotation = open and 180 or 0 }, true, TWEEN_SPRING)
		tween(st, { Color = open and Theme.AccentGlow or Color3.new(1, 1, 1) }, true)
	end
	paint(false)

	trig.Activated:Connect(function()
		if layer and layer.Open then layer.Close() return end
		layer = openLayer(trig, { OnClose = function() paint(false) end })
		paint(true)

		local dropShell = New("Frame", {
			Size = UDim2.fromOffset(trig.AbsoluteSize.X, math.min(#options * 32 + 12, 200)),
			Parent = layer.Host
		})
		ApplyRaisedNeumorph(dropShell, 10, 1.4)
		Pad(dropShell, 6)

		local mScroll = New("ScrollingFrame", { Size = UDim2.fromScale(1, 1), Parent = dropShell })
		local mList = List(mScroll, { Gap = 4 })

		for _, opt in ipairs(options) do
			local btn = New("TextButton", { Size = UDim2.new(1, 0, 0, 28), Parent = mScroll })
			Corner(btn, 7)

			local optTxt = New("TextLabel", {
				Position = UDim2.fromOffset(10, 0),
				Size = UDim2.new(1, -30, 1, 0),
				Text = tostring(opt),
				TextSize = 12,
				Parent = btn
			})
			local chk = makeIcon("check", 13, "AccentGlow", btn)
			chk.Instance.AnchorPoint, chk.Instance.Position = Vector2.new(1, .5), UDim2.new(1, -8, .5, 0)

			local function refreshRow()
				local isSel = selected[opt] == true
				btn.BackgroundColor3 = Theme.InsetTop
				btn.BackgroundTransparency = isSel and 0.25 or 1
				optTxt.FontFace = isSel and Fonts.Bold or Fonts.Medium
				optTxt.TextColor3 = isSel and Theme.AccentGlow or Theme.TextMuted
				chk.Instance.Visible = isSel
			end
			refreshRow()

			btn.Activated:Connect(function()
				selected[opt] = not selected[opt]
				refreshRow()
				paint(true)
				local currentList = getList()
				self.Changed:Fire(currentList)
				if props.OnChanged then props.OnChanged(currentList) end
			end)
		end
		mScroll.CanvasSize = UDim2.new(0, 0, 0, mList.AbsoluteContentSize.Y + 4)
	end)

	return self
end

function Onyx.ModeSelector(props)
	props = props or {}
	local options = props.Options or {}
	local root = New("Frame", { Size = props.Size or UDim2.new(1, 0, 0, 56), LayoutOrder = props.LayoutOrder, Parent = props.Parent })
	New("TextLabel", {
		Size = UDim2.new(1, 0, 0, 16),
		Text = props.Label or "Mode",
		FontFace = Fonts.Medium,
		TextSize = 12,
		TextColor3 = Theme.TextMuted,
		Parent = root
	})

	local row = New("Frame", { Position = UDim2.fromOffset(0, 20), Size = UDim2.new(1, 0, 0, 36), Parent = root })
	local buttons = {}
	local current = props.Value or (options[1] and (type(options[1]) == "table" and options[1].Key or options[1]))
	local count = math.max(1, #options)
	local self = Base(root)

	for i, opt in ipairs(options) do
		local key = type(opt) == "table" and opt.Key or opt
		local text = type(opt) == "table" and opt.Text or tostring(opt)
		local scaleW = 1 / count
		local btn = New("TextButton", {
			Position = UDim2.new(scaleW * (i - 1), i > 1 and 4 or 0, 0, 0),
			Size = UDim2.new(scaleW, -4, 1, 0),
			Parent = row
		})
		local baseStroke = ApplyRaisedNeumorph(btn, 9, 1.2)
		local activeBg = New("Frame", { Size = UDim2.fromScale(1, 1), Parent = btn })
		local activeStroke = ApplyAccentNeumorph(activeBg, 9)
		activeBg.BackgroundTransparency = 1
		activeStroke.Transparency = 1

		local lbl = New("TextLabel", {
			Size = UDim2.fromScale(1, 1),
			Text = text,
			FontFace = Fonts.Bold,
			TextSize = 11,
			TextXAlignment = Enum.TextXAlignment.Center,
			ZIndex = 2,
			Parent = btn
		})

		buttons[key] = { Btn = btn, ActiveBg = activeBg, ActiveStroke = activeStroke, BaseStroke = baseStroke, Label = lbl }

		btn.Activated:Connect(function()
			self:SetMode(key, true)
			self.Changed:Fire(key)
			if props.OnChanged then props.OnChanged(key) end
		end)
	end

	function self:SetMode(mode, animate)
		current = mode
		for k, v in pairs(buttons) do
			local sel = (k == mode)
			tween(v.ActiveBg, { BackgroundTransparency = sel and 0 or 1 }, animate)
			tween(v.ActiveStroke, { Transparency = sel and 0.25 or 1 }, animate)
			tween(v.Label, { TextColor3 = sel and rgb(255, 255, 255) or Theme.TextMuted }, animate)
		end
	end
	self:SetMode(current, false)
	return self
end

function Onyx.TextInput(props)
	props = props or {}
	local well = New("Frame", {
		Size = props.Size or UDim2.new(1, 0, 0, 38),
		LayoutOrder = props.LayoutOrder,
		Parent = props.Parent
	})
	local st = ApplyInsetNeumorph(well, 9, 1.2)
	Pad(well, 12, 0, 12, 0)
	local box = New("TextBox", {
		Size = UDim2.fromScale(1, 1),
		PlaceholderText = props.Placeholder or "Enter text...",
		PlaceholderColor3 = Theme.TextDim,
		Text = props.Default or "",
		FontFace = Fonts.Medium,
		TextSize = 12,
		TextColor3 = Theme.Text,
		ClearTextOnFocus = false,
		Parent = well
	})
	box.Focused:Connect(function() tween(st, { Color = Theme.AccentGlow }, true) end)
	box.FocusLost:Connect(function()
		tween(st, { Color = Color3.new(1, 1, 1) }, true)
		if props.OnChanged then props.OnChanged(box.Text) end
	end)
	local self = Base(well)
	self.Box = box
	function self:GetValue() return box.Text end
	function self:SetValue(t) box.Text = tostring(t) end
	return self
end

function Onyx.NumberInput(props)
	props = props or {}
	local min, max = props.Min or 0.01, props.Max or 9999
	local root = New("Frame", {
		Size = props.Size or UDim2.new(1, 0, 0, 34),
		LayoutOrder = props.LayoutOrder,
		Parent = props.Parent
	})
	New("TextLabel", {
		Size = UDim2.new(1, -90, 1, 0),
		Text = props.Label or "Value",
		FontFace = Fonts.Medium,
		TextSize = 12,
		TextColor3 = Theme.Text,
		Parent = root
	})

	local well = New("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.fromOffset(80, 30),
		Parent = root
	})
	local st = ApplyInsetNeumorph(well, 8, 1.2)
	Pad(well, 8, 0, 8, 0)

	local currentVal = tonumber(props.Value) or 1
	local box = New("TextBox", {
		Size = UDim2.fromScale(1, 1),
		Text = tostring(currentVal),
		PlaceholderText = tostring(currentVal),
		PlaceholderColor3 = Theme.TextDim,
		FontFace = Fonts.Bold,
		TextSize = 12,
		TextColor3 = Theme.AccentGlow,
		TextXAlignment = Enum.TextXAlignment.Center,
		ClearTextOnFocus = false,
		Parent = well
	})

	box.Focused:Connect(function() tween(st, { Color = Theme.AccentGlow }, true) end)
	box.FocusLost:Connect(function()
		tween(st, { Color = Color3.new(1, 1, 1) }, true)
		local num = tonumber(box.Text)
		if num then
			currentVal = math.clamp(num, min, max)
			box.Text = tostring(currentVal)
			if props.OnChanged then props.OnChanged(currentVal) end
		else
			box.Text = tostring(currentVal)
		end
	end)

	local self = Base(root)
	self.Box = box
	function self:GetValue() return currentVal end
	function self:SetValue(v) currentVal = tonumber(v) or currentVal box.Text = tostring(currentVal) end
	return self
end

function Onyx.Keybind(props)
	props = props or {}
	local currentKey = props.Value or Enum.KeyCode.F
	local listening = false

	local root = New("Frame", { Size = props.Size or UDim2.new(1, 0, 0, 32), LayoutOrder = props.LayoutOrder, Parent = props.Parent })
	New("TextLabel", {
		Size = UDim2.new(1, -95, 1, 0),
		Text = props.Label or "Keybind",
		FontFace = Fonts.Medium,
		TextSize = 12,
		TextColor3 = Theme.Text,
		Parent = root
	})

	local btn = New("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.fromOffset(86, 28),
		Parent = root
	})
	local st = ApplyInsetNeumorph(btn, 7, 1.2)
	local keyLbl = New("TextLabel", {
		Size = UDim2.fromScale(1, 1),
		Text = currentKey.Name,
		FontFace = Fonts.Bold,
		TextSize = 11,
		TextColor3 = Theme.AccentGlow,
		TextXAlignment = Enum.TextXAlignment.Center,
		Parent = btn
	})

	local self = Base(root)
	btn.Activated:Connect(function()
		listening = true
		keyLbl.Text = "..."
		tween(st, { Color = Theme.AccentGlow }, true)
	end)

	self._maid:Add(UserInputService.InputBegan:Connect(function(input, gp)
		if listening then
			if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode ~= Enum.KeyCode.Unknown then
				listening = false
				currentKey = input.KeyCode
				keyLbl.Text = currentKey.Name
				tween(st, { Color = Color3.new(1, 1, 1) }, true)
				self.Changed:Fire(currentKey)
				if props.OnChanged then props.OnChanged(currentKey) end
			end
		elseif not gp and input.KeyCode == currentKey then
			if props.OnPressed then props.OnPressed(currentKey) end
		end
	end))

	return self
end

function Onyx.ColorPicker(props)
	props = props or {}
	local curColor = props.Value or Theme.AccentGlow
	local h, s, v = curColor:ToHSV()

	local root = New("Frame", { Size = props.Size or UDim2.new(1, 0, 0, 32), LayoutOrder = props.LayoutOrder, Parent = props.Parent })
	New("TextLabel", {
		Size = UDim2.new(1, -60, 1, 0),
		Text = props.Label or "Color",
		FontFace = Fonts.Medium,
		TextSize = 12,
		TextColor3 = Theme.Text,
		Parent = root
	})

	local swatchBtn = New("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.fromOffset(46, 24),
		BackgroundColor3 = curColor,
		BackgroundTransparency = 0,
		Parent = root
	})
	Corner(swatchBtn, 7)
	New("UIStroke", { Color = Theme.LightBevel, Thickness = 1.2, Parent = swatchBtn })

	local self = Base(root)
	local layer

	local function updateColor()
		curColor = Color3.fromHSV(h, s, v)
		swatchBtn.BackgroundColor3 = curColor
		self.Changed:Fire(curColor)
		if props.OnChanged then props.OnChanged(curColor) end
	end

	swatchBtn.Activated:Connect(function()
		if layer and layer.Open then layer.Close() return end
		layer = openLayer(swatchBtn)

		local pop = New("Frame", {
			Size = UDim2.fromOffset(230, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			Parent = layer.Host
		})
		ApplyRaisedNeumorph(pop, 11, 1.4)
		Pad(pop, 12, 12, 12, 14)
		List(pop, { Gap = 8 })

		Onyx.Slider({
			Label = "Hue", Min = 0, Max = 1, Step = 0.01, Value = h, Parent = pop,
			OnChanged = function(val) h = val updateColor() end
		})
		Onyx.Slider({
			Label = "Saturation", Min = 0, Max = 1, Step = 0.01, Value = s, Parent = pop,
			OnChanged = function(val) s = val updateColor() end
		})
		Onyx.Slider({
			Label = "Brightness", Min = 0, Max = 1, Step = 0.01, Value = v, Parent = pop,
			OnChanged = function(val) v = val updateColor() end
		})
	end)

	return self
end

function Onyx.LogConsole(props)
	props = props or {}
	local well = New("Frame", {
		Size = props.Size or UDim2.new(1, 0, 0, props.Height or 125),
		LayoutOrder = props.LayoutOrder,
		Parent = props.Parent
	})
	ApplyInsetNeumorph(well, 9, 1.2)
	Pad(well, 10, 8, 10, 8)
	local sc = New("ScrollingFrame", { Size = UDim2.fromScale(1, 1), Parent = well })
	List(sc, { Gap = 4 })

	local self = Base(well)
	function self:Log(msg, colorHex)
		local children = sc:GetChildren()
		if #children > 40 then
			for _, item in ipairs(children) do
				if item:IsA("TextLabel") then item:Destroy() break end
			end
		end
		local ts = os.date("%H:%M:%S")
		local hex = colorHex or "#60A5FA"
		New("TextLabel", {
			Size = UDim2.new(1, -6, 0, 15),
			RichText = true,
			Text = string.format("<font color='%s'>[%s]</font> %s", hex, ts, tostring(msg)),
			FontFace = Fonts.Medium,
			TextSize = 11,
			TextColor3 = Theme.TextMuted,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Parent = sc
		})
		task.defer(function()
			sc.CanvasPosition = Vector2.new(0, sc.AbsoluteCanvasSize.Y)
		end)
	end
	function self:Success(msg) self:Log(msg, "#10B981") end
	function self:Warn(msg) self:Log(msg, "#F59E0B") end
	function self:Error(msg) self:Log(msg, "#EF4444") end
	function self:Clear()
		for _, item in ipairs(sc:GetChildren()) do
			if item:IsA("TextLabel") then item:Destroy() end
		end
	end
	return self
end

if getgenv then getgenv().Onyx = Onyx end

return Onyx
