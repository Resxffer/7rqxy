-- 7rqxy Custom UI Library v4.0.0 | Solid Black & Ash | Native Mobile Taps

local Library = {}
Library.Version = "4.0.0"

local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local DefaultTheme = {
    Background = Color3.fromRGB(15, 15, 18),           -- Solid Dark Base
    Panel = Color3.fromRGB(25, 25, 30),                -- Solid Ash Cards
    Accent = Color3.fromRGB(160, 165, 170),            -- Ash Silver 
    Text = Color3.fromRGB(245, 245, 245),
    SubText = Color3.fromRGB(150, 150, 150),
    SectionHeader = Color3.fromRGB(160, 165, 170),
    Success = Color3.fromRGB(120, 220, 160),
    Error = Color3.fromRGB(230, 110, 120),
    CornerRadius = 8,       -- sharper corners for solid look
    RowCornerRadius = 6,    
}
Library.Theme = DefaultTheme

--// Helpers -----------------------------------------------------------

local function merge(base, override)
    local out = {}
    for k, v in pairs(base) do out[k] = v end
    if override then
        for k, v in pairs(override) do out[k] = v end
    end
    return out
end

local function clamp(v, lo, hi)
    if v < lo then return lo elseif v > hi then return hi else return v end
end

local function tween(obj, info, props)
    local t = TweenService:Create(obj, info, props)
    t:Play()
    return t
end

local function easeInfo(duration, style, direction)
    return TweenInfo.new(duration or 0.2, style or Enum.EasingStyle.Quint, direction or Enum.EasingDirection.Out)
end

local function isPress(input)
    return input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch
end

local function isMove(input)
    return input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch
end

local function screenSize()
    local cam = Workspace.CurrentCamera
    return cam and cam.ViewportSize or Vector2.new(1280, 720)
end

--// Solid building blocks -----------------------------------------------

local function addShadow(parent, padding)
    local shadow = Instance.new("ImageLabel")
    shadow.Name = "Shadow"
    shadow.ZIndex = math.max((parent.ZIndex or 1) - 1, 0)
    shadow.BackgroundTransparency = 1
    shadow.Image = "rbxassetid://5028857084"
    shadow.ImageColor3 = Color3.new(0, 0, 0)
    shadow.ImageTransparency = 0.5 -- Solid shadow
    shadow.ScaleType = Enum.ScaleType.Slice
    shadow.SliceCenter = Rect.new(23, 23, 277, 277)
    local p = padding or 24
    shadow.Size = UDim2.new(1, p * 2, 1, p * 2)
    shadow.Position = UDim2.new(0, -p, 0, -p)
    shadow.Parent = parent
    return shadow
end

local function newPanel(parent, theme, size, position, cornerRadius)
    local f = Instance.new("Frame", parent)
    f.Size = size
    if position then f.Position = position end
    f.BackgroundColor3 = theme.Panel
    f.BorderSizePixel = 0
    Instance.new("UICorner", f).CornerRadius = UDim.new(0, cornerRadius or theme.RowCornerRadius)
    
    local stroke = Instance.new("UIStroke", f)
    stroke.Color = theme.Accent
    stroke.Thickness = 1
    stroke.Transparency = 0.5
    return f, stroke
end

--// Window --------------------------------------------------------------

function Library:CreateWindow(config)
    config = config or {}
    local Window = {}
    local Theme = merge(DefaultTheme, config.Theme)
    local TitleText = config.Title or "7rqxy UI"
    local MenuKey = config.MenuKey or Enum.KeyCode.RightShift
    local WindowSize = UDim2.new(0, 420, 0, 380)

    local Connections = {}
    local function track(conn)
        table.insert(Connections, conn)
        return conn
    end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "7rqxy_Library"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.IgnoreGuiInset = true
    ScreenGui.DisplayOrder = 9999
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
    pcall(function() ScreenGui.Parent = CoreGui end)
    if not ScreenGui.Parent then
        ScreenGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
    end

    local ToggleBtn = Instance.new("TextButton", ScreenGui)
    ToggleBtn.ZIndex = 5
    ToggleBtn.Size = UDim2.new(0, 46, 0, 46)
    ToggleBtn.Position = UDim2.new(0.5, -23, 0, 14)
    ToggleBtn.BackgroundColor3 = Theme.Panel
    ToggleBtn.AutoButtonColor = false
    ToggleBtn.Text = "7"
    ToggleBtn.TextColor3 = Theme.Text
    ToggleBtn.Font = Enum.Font.GothamBold
    ToggleBtn.TextSize = 20
    Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(1, 0)
    addShadow(ToggleBtn, 14)
    local ToggleStroke = Instance.new("UIStroke", ToggleBtn)
    ToggleStroke.Thickness = 1.5
    ToggleStroke.Color = Theme.Accent
    ToggleStroke.Transparency = 0

    local Main = Instance.new("Frame", ScreenGui)
    Main.Name = "MainFrame"
    Main.ZIndex = 2
    Main.Size = WindowSize
    Main.Position = UDim2.new(0.5, -WindowSize.X.Offset / 2, 0.5, -WindowSize.Y.Offset / 2)
    Main.BackgroundColor3 = Theme.Background
    Main.BorderSizePixel = 0
    Main.Visible = false
    Instance.new("UICorner", Main).CornerRadius = UDim.new(0, Theme.CornerRadius)
    addShadow(Main, 30)
    
    local MainStroke = Instance.new("UIStroke", Main)
    MainStroke.Color = Theme.Accent
    MainStroke.Thickness = 1
    MainStroke.Transparency = 0.3

    local MainScale = Instance.new("UIScale", Main)
    MainScale.Scale = 1

    local isOpen = false
    local function setOpen(state)
        if state == isOpen then return end
        isOpen = state
        if state then
            Main.Visible = true
            MainScale.Scale = 0.94
            tween(MainScale, easeInfo(0.22), {Scale = 1})
        else
            tween(MainScale, easeInfo(0.16, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {Scale = 0.94})
            task.delay(0.16, function()
                if not isOpen then Main.Visible = false end
            end)
        end
    end

    local TopBar = Instance.new("Frame", Main)
    TopBar.ZIndex = 3
    TopBar.Size = UDim2.new(1, 0, 0, 38)
    TopBar.BackgroundTransparency = 1
    TopBar.BorderSizePixel = 0

    local Title = Instance.new("TextLabel", TopBar)
    Title.Size = UDim2.new(1, -15, 1, 0)
    Title.Position = UDim2.new(0, 16, 0, 0)
    Title.BackgroundTransparency = 1
    Title.Text = TitleText
    Title.TextColor3 = Theme.Text
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = 14
    Title.TextXAlignment = Enum.TextXAlignment.Left

    local Divider = Instance.new("Frame", TopBar)
    Divider.Size = UDim2.new(1, -24, 0, 1)
    Divider.Position = UDim2.new(0, 12, 1, -1)
    Divider.BackgroundColor3 = Theme.Accent
    Divider.BackgroundTransparency = 0.5
    Divider.BorderSizePixel = 0

    local TabBar = Instance.new("ScrollingFrame", Main)
    TabBar.ZIndex = 3
    TabBar.Size = UDim2.new(1, -20, 0, 32)
    TabBar.Position = UDim2.new(0, 10, 0, 44)
    TabBar.BackgroundTransparency = 1
    TabBar.BorderSizePixel = 0
    TabBar.ScrollBarThickness = 2
    TabBar.ScrollBarImageColor3 = Theme.Accent
    TabBar.ScrollingDirection = Enum.ScrollingDirection.X
    TabBar.CanvasSize = UDim2.new(0, 0, 0, 0)
    TabBar.AutomaticCanvasSize = Enum.AutomaticSize.X
    local TabListLayout = Instance.new("UIListLayout", TabBar)
    TabListLayout.FillDirection = Enum.FillDirection.Horizontal
    TabListLayout.Padding = UDim.new(0, 6)
    TabListLayout.SortOrder = Enum.SortOrder.LayoutOrder

    local TabContainer = Instance.new("Frame", Main)
    TabContainer.ZIndex = 3
    TabContainer.Size = UDim2.new(1, 0, 1, -92)
    TabContainer.Position = UDim2.new(0, 0, 0, 92)
    TabContainer.BackgroundTransparency = 1

    local NotifyContainer = Instance.new("Frame", ScreenGui)
    NotifyContainer.ZIndex = 6
    NotifyContainer.Size = UDim2.new(0, 260, 1, -20)
    NotifyContainer.Position = UDim2.new(1, -280, 0, 10)
    NotifyContainer.BackgroundTransparency = 1
    local NotifyLayout = Instance.new("UIListLayout", NotifyContainer)
    NotifyLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
    NotifyLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    NotifyLayout.Padding = UDim.new(0, 8)
    NotifyLayout.SortOrder = Enum.SortOrder.LayoutOrder

    local function makeDraggable(handle, target)
        local dragging, dragStart, startPos = false, nil, nil
        track(handle.InputBegan:Connect(function(input)
            if isPress(input) then
                dragging = true; dragStart = input.Position; startPos = target.Position
            end
        end))
        track(handle.InputEnded:Connect(function(input)
            if isPress(input) then dragging = false end
        end))
        track(UserInputService.InputChanged:Connect(function(input)
            if dragging and isMove(input) then
                local delta = input.Position - dragStart
                local screen = screenSize()
                local size = target.AbsoluteSize
                local xScale, yScale = startPos.X.Scale, startPos.Y.Scale
                local newX = clamp(startPos.X.Offset + delta.X, -screen.X * xScale, screen.X * (1 - xScale) - size.X)
                local newY = clamp(startPos.Y.Offset + delta.Y, -screen.Y * yScale, screen.Y * (1 - yScale) - size.Y)
                target.Position = UDim2.new(xScale, newX, yScale, newY)
            end
        end))
    end

    makeDraggable(TopBar, Main)

    -- Toggle Button Drag Logic
    local tDragging, tMoved, tStart, tPos = false, false, nil, nil
    track(ToggleBtn.InputBegan:Connect(function(input)
        if isPress(input) then
            tDragging = true; tMoved = false; tStart = input.Position; tPos = ToggleBtn.Position
        end
    end))
    track(UserInputService.InputChanged:Connect(function(input)
        if tDragging and isMove(input) then
            local delta = input.Position - tStart
            if delta.Magnitude > 10 then 
                tMoved = true
                local screen = screenSize()
                local size = ToggleBtn.AbsoluteSize
                local newX = clamp(tPos.X.Offset + delta.X, 0, screen.X - size.X)
                local newY = clamp(tPos.Y.Offset + delta.Y, 0, screen.Y - size.Y)
                ToggleBtn.Position = UDim2.new(0, newX, 0, newY)
            end
        end
    end))
    track(ToggleBtn.InputEnded:Connect(function(input)
        if isPress(input) then tDragging = false end
    end))
    
    -- Native tap support to fix mobile miss-clicks
    track(ToggleBtn.Activated:Connect(function()
        if not tMoved then setOpen(not isOpen) end
    end))
    
    track(UserInputService.InputBegan:Connect(function(input, gp)
        if not gp and input.KeyCode == MenuKey then setOpen(not isOpen) end
    end))

    local Tabs = {}
    local FirstTab = true
    local ActiveDropdownClose = nil

    function Window:CreateTab(name)
        local Tab = {}
        local selected = FirstTab

        local TabBtn = Instance.new("TextButton", TabBar)
        TabBtn.ZIndex = 3
        TabBtn.Size = UDim2.new(0, 92, 1, 0)
        TabBtn.BackgroundColor3 = Theme.Panel
        TabBtn.BackgroundTransparency = selected and 0 or 0.6
        TabBtn.BorderSizePixel = 0
        TabBtn.AutoButtonColor = false
        TabBtn.Text = name
        TabBtn.TextColor3 = selected and Theme.Text or Theme.SubText
        TabBtn.Font = Enum.Font.GothamMedium
        TabBtn.TextSize = 13
        Instance.new("UICorner", TabBtn).CornerRadius = UDim.new(1, 0)
        local TabStroke = Instance.new("UIStroke", TabBtn)
        TabStroke.Thickness = 1
        TabStroke.Color = Theme.Accent
        TabStroke.Transparency = selected and 0 or 0.6

        local TabPage = Instance.new("ScrollingFrame", TabContainer)
        TabPage.ZIndex = 3
        TabPage.Size = UDim2.new(1, -20, 1, -10)
        TabPage.Position = UDim2.new(0, 10, 0, 5)
        TabPage.BackgroundTransparency = 1
        TabPage.BorderSizePixel = 0
        TabPage.ScrollBarThickness = 4
        TabPage.ScrollBarImageColor3 = Theme.Accent
        TabPage.AutomaticCanvasSize = Enum.AutomaticSize.Y
        TabPage.CanvasSize = UDim2.new(0, 0, 0, 0)
        TabPage.Visible = selected

        local Layout = Instance.new("UIListLayout", TabPage)
        Layout.Padding = UDim.new(0, 8)
        Layout.SortOrder = Enum.SortOrder.LayoutOrder

        local entry = {Btn = TabBtn, Page = TabPage, Stroke = TabStroke}
        table.insert(Tabs, entry)
        FirstTab = false

        -- Native tap for tabs
        track(TabBtn.Activated:Connect(function()
            for _, t in pairs(Tabs) do
                t.Page.Visible = false
                tween(t.Btn, easeInfo(0.15), {BackgroundTransparency = 0.6})
                tween(t.Stroke, easeInfo(0.15), {Transparency = 0.6})
                t.Btn.TextColor3 = Theme.SubText
            end
            TabPage.Visible = true
            tween(TabBtn, easeInfo(0.15), {BackgroundTransparency = 0})
            tween(TabStroke, easeInfo(0.15), {Transparency = 0})
            TabBtn.TextColor3 = Theme.Text
        end))

        function Tab:CreateHeader(text)
            local H = Instance.new("Frame", TabPage)
            H.Size = UDim2.new(1, 0, 0, 25)
            H.BackgroundTransparency = 1
            local L = Instance.new("TextLabel", H)
            L.Size = UDim2.new(1, 0, 1, 0)
            L.Position = UDim2.new(0, 5, 0, 5)
            L.BackgroundTransparency = 1
            L.Text = text
            L.TextColor3 = Theme.SectionHeader
            L.Font = Enum.Font.GothamBold
            L.TextSize = 13
            L.TextXAlignment = Enum.TextXAlignment.Left
        end

        function Tab:CreateLabel(text)
            local Row = Instance.new("Frame", TabPage)
            Row.Size = UDim2.new(1, 0, 0, 22)
            Row.BackgroundTransparency = 1
            local L = Instance.new("TextLabel", Row)
            L.Size = UDim2.new(1, -10, 1, 0)
            L.Position = UDim2.new(0, 5, 0, 0)
            L.BackgroundTransparency = 1
            L.Text = text
            L.TextColor3 = Theme.SubText
            L.Font = Enum.Font.Gotham
            L.TextSize = 13
            L.TextXAlignment = Enum.TextXAlignment.Left
            L.TextWrapped = true

            local LabelObj = {}
            function LabelObj:Set(t) L.Text = t end
            return LabelObj
        end

        function Tab:CreateToggle(opts)
            opts = opts or {}
            local Row = newPanel(TabPage, Theme, UDim2.new(1, 0, 0, 42))

            local L = Instance.new("TextLabel", Row)
            L.Size = UDim2.new(1, -70, 1, 0)
            L.Position = UDim2.new(0, 14, 0, 0)
            L.BackgroundTransparency = 1
            L.Text = opts.Name
            L.TextColor3 = Theme.Text
            L.Font = Enum.Font.GothamMedium
            L.TextSize = 14
            L.TextXAlignment = Enum.TextXAlignment.Left

            local Track = Instance.new("Frame", Row)
            Track.Size = UDim2.new(0, 42, 0, 22)
            Track.Position = UDim2.new(1, -56, 0.5, -11)
            Track.BackgroundColor3 = Theme.Background
            Track.BorderSizePixel = 0
            Instance.new("UICorner", Track).CornerRadius = UDim.new(1, 0)
            local TrackStroke = Instance.new("UIStroke", Track)
            TrackStroke.Color = Theme.Accent
            TrackStroke.Transparency = 0.5
            TrackStroke.Thickness = 1

            local Fill = Instance.new("Frame", Track)
            Fill.Size = UDim2.new(1, 0, 1, 0)
            Fill.BackgroundColor3 = Theme.Accent
            Fill.BorderSizePixel = 0
            Instance.new("UICorner", Fill).CornerRadius = UDim.new(1, 0)

            local Knob = Instance.new("Frame", Track)
            Knob.ZIndex = 2
            Knob.Size = UDim2.new(0, 16, 0, 16)
            Knob.Position = UDim2.new(0, 3, 0.5, -8)
            Knob.BackgroundColor3 = Theme.Text
            Knob.BorderSizePixel = 0
            Instance.new("UICorner", Knob).CornerRadius = UDim.new(1, 0)
            addShadow(Knob, 6)

            local B = Instance.new("TextButton", Row)
            B.Size = UDim2.new(1, 0, 1, 0)
            B.BackgroundTransparency = 1
            B.Text = ""

            local state = opts.CurrentValue == true

            local function render(instant)
                local knobPos = state and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
                local fillTrans = state and 0 or 1
                if instant then
                    Knob.Position = knobPos
                    Fill.BackgroundTransparency = fillTrans
                else
                    tween(Knob, easeInfo(0.18), {Position = knobPos})
                    tween(Fill, easeInfo(0.18), {BackgroundTransparency = fillTrans})
                end
            end
            render(true)

            local ToggleObj = {}
            function ToggleObj:Set(v, fire)
                state = v and true or false
                render(false)
                if fire ~= false and opts.Callback then opts.Callback(state) end
            end
            function ToggleObj:Get() return state end

            -- Native tap for toggle
            track(B.Activated:Connect(function()
                ToggleObj:Set(not state)
            end))

            return ToggleObj
        end

        function Tab:CreateSlider(opts)
            opts = opts or {}
            local minV, maxV = opts.Range[1], opts.Range[2]
            if maxV == minV then maxV = minV + 1 end 

            local Row = newPanel(TabPage, Theme, UDim2.new(1, 0, 0, 65))

            local L = Instance.new("TextLabel", Row)
            L.Size = UDim2.new(1, -20, 0, 25)
            L.Position = UDim2.new(0, 12, 0, 5)
            L.BackgroundTransparency = 1
            L.Text = opts.Name
            L.TextColor3 = Theme.Text
            L.Font = Enum.Font.GothamMedium
            L.TextSize = 14
            L.TextXAlignment = Enum.TextXAlignment.Left

            local ValText = Instance.new("TextLabel", Row)
            ValText.Size = UDim2.new(0, 50, 0, 25)
            ValText.Position = UDim2.new(1, -60, 0, 5)
            ValText.BackgroundTransparency = 1
            ValText.TextColor3 = Theme.Accent
            ValText.Font = Enum.Font.GothamBold
            ValText.TextSize = 14
            ValText.TextXAlignment = Enum.TextXAlignment.Right

            local Track = Instance.new("Frame", Row)
            Track.Size = UDim2.new(1, -24, 0, 6)
            Track.Position = UDim2.new(0, 12, 0, 43)
            Track.BackgroundColor3 = Theme.Background
            Track.BorderSizePixel = 0
            Instance.new("UICorner", Track).CornerRadius = UDim.new(1, 0)

            local Fill = Instance.new("Frame", Track)
            Fill.BackgroundColor3 = Theme.Accent
            Fill.BorderSizePixel = 0
            Instance.new("UICorner", Fill).CornerRadius = UDim.new(1, 0)

            local Thumb = Instance.new("Frame", Track)
            Thumb.ZIndex = 2
            Thumb.AnchorPoint = Vector2.new(0.5, 0.5)
            Thumb.Size = UDim2.new(0, 14, 0, 14)
            Thumb.BackgroundColor3 = Theme.Text
            Thumb.BorderSizePixel = 0
            Instance.new("UICorner", Thumb).CornerRadius = UDim.new(1, 0)
            addShadow(Thumb, 6)

            local value = clamp(opts.CurrentValue or minV, minV, maxV)
            local SliderObj = {}

            local function setValue(v, fire)
                v = clamp(v, minV, maxV)
                if opts.Increment then
                    v = clamp(math.floor(v / opts.Increment + 0.5) * opts.Increment, minV, maxV)
                end
                value = v
                local p = (value - minV) / (maxV - minV)
                Fill.Size = UDim2.new(p, 0, 1, 0)
                Thumb.Position = UDim2.new(p, 0, 0.5, 0)
                ValText.Text = tostring(value)
                if fire ~= false and opts.Callback then opts.Callback(value) end
            end
            setValue(value, false)

            function SliderObj:Set(v) setValue(v, true) end
            function SliderObj:Get() return value end

            local dragging = false
            local function updateFromInput(input)
                local p = clamp((input.Position.X - Track.AbsolutePosition.X) / Track.AbsoluteSize.X, 0, 1)
                setValue(minV + (maxV - minV) * p, true)
            end

            track(Track.InputBegan:Connect(function(input)
                if isPress(input) then
                    dragging = true
                    updateFromInput(input)
                end
            end))
            track(UserInputService.InputEnded:Connect(function(input)
                if isPress(input) then dragging = false end
            end))
            track(UserInputService.InputChanged:Connect(function(input)
                if dragging and isMove(input) then updateFromInput(input) end
            end))

            return SliderObj
        end

        function Tab:CreateDropdown(opts)
            opts = opts or {}
            local Drop = {}
            local optionHeight = 30
            local maxVisible = 5
            local rowHeight = 42
            local topGap, bottomPad = 4, 8
            local listHeight = math.min(math.max(#opts.Options, 1), maxVisible) * optionHeight + 8

            local Row = newPanel(TabPage, Theme, UDim2.new(1, 0, 0, rowHeight))
            Row.ClipsDescendants = true

            local L = Instance.new("TextLabel", Row)
            L.Size = UDim2.new(1, -50, 0, rowHeight)
            L.Position = UDim2.new(0, 14, 0, 0)
            L.BackgroundTransparency = 1
            L.Text = opts.Name .. " : " .. tostring(opts.CurrentOption)
            L.TextColor3 = Theme.Text
            L.Font = Enum.Font.GothamMedium
            L.TextSize = 14
            L.TextXAlignment = Enum.TextXAlignment.Left
            L.TextTruncate = Enum.TextTruncate.AtEnd

            local Chevron = Instance.new("TextLabel", Row)
            Chevron.Size = UDim2.new(0, 24, 0, 24)
            Chevron.Position = UDim2.new(1, -34, 0, 9)
            Chevron.BackgroundTransparency = 1
            Chevron.Text = "v"
            Chevron.TextColor3 = Theme.Accent
            Chevron.Font = Enum.Font.GothamBold
            Chevron.TextSize = 16

            local ListHolder = Instance.new("Frame", Row)
            ListHolder.Size = UDim2.new(1, -24, 0, listHeight)
            ListHolder.Position = UDim2.new(0, 12, 0, rowHeight + topGap)
            ListHolder.BackgroundColor3 = Theme.Background
            ListHolder.BorderSizePixel = 0
            Instance.new("UICorner", ListHolder).CornerRadius = UDim.new(0, 6)
            local ListStroke = Instance.new("UIStroke", ListHolder)
            ListStroke.Color = Theme.Accent
            ListStroke.Transparency = 0.5

            local List = Instance.new("ScrollingFrame", ListHolder)
            List.Size = UDim2.new(1, 0, 1, 0)
            List.BackgroundTransparency = 1
            List.BorderSizePixel = 0
            List.ScrollBarThickness = 3
            List.ScrollBarImageColor3 = Theme.Accent
            Instance.new("UIListLayout", List).SortOrder = Enum.SortOrder.LayoutOrder
            local ListPad = Instance.new("UIPadding", List)
            ListPad.PaddingTop = UDim.new(0, 4)
            ListPad.PaddingBottom = UDim.new(0, 4)

            local B = Instance.new("TextButton", Row)
            B.Size = UDim2.new(1, 0, 0, rowHeight)
            B.BackgroundTransparency = 1
            B.Text = ""

            local open = false
            local outsideConn = nil
            local currentOption = opts.CurrentOption

            local function closedSize() return UDim2.new(1, 0, 0, rowHeight) end
            local function openSize() return UDim2.new(1, 0, 0, rowHeight + topGap + listHeight + bottomPad) end

            local close, openDrop 

            close = function()
                if not open then return end
                open = false
                tween(Row, easeInfo(0.2), {Size = closedSize()})
                tween(Chevron, easeInfo(0.2), {Rotation = 0})
                if outsideConn then outsideConn:Disconnect(); outsideConn = nil end
                if ActiveDropdownClose == close then ActiveDropdownClose = nil end
            end

            openDrop = function()
                if open then return end
                if ActiveDropdownClose then ActiveDropdownClose() end
                ActiveDropdownClose = close

                open = true
                tween(Row, easeInfo(0.22), {Size = openSize()})
                tween(Chevron, easeInfo(0.2), {Rotation = 180})
                
                task.delay(0.1, function()
                    if not open then return end
                    outsideConn = UserInputService.InputBegan:Connect(function(input, gp)
                        if gp or not isPress(input) then return end
                        local ap = Row.AbsolutePosition
                        local currentTargetHeight = rowHeight + topGap + listHeight + bottomPad
                        local pos = input.Position
                        if pos.X < ap.X or pos.X > ap.X + Row.AbsoluteSize.X or pos.Y < ap.Y or pos.Y > ap.Y + currentTargetHeight then
                            close()
                        end
                    end)
                    track(outsideConn)
                end)

                task.defer(function()
                    local rowTop = Row.AbsolutePosition.Y - TabPage.AbsolutePosition.Y + TabPage.CanvasPosition.Y
                    local rowBottom = rowTop + rowHeight + topGap + listHeight + bottomPad
                    local viewTop = TabPage.CanvasPosition.Y
                    local viewBottom = viewTop + TabPage.AbsoluteSize.Y
                    if rowBottom > viewBottom then
                        tween(TabPage, easeInfo(0.25), {CanvasPosition = Vector2.new(0, TabPage.CanvasPosition.Y + (rowBottom - viewBottom) + 10)})
                    elseif rowTop < viewTop then
                        tween(TabPage, easeInfo(0.25), {CanvasPosition = Vector2.new(0, math.max(0, rowTop - 10))})
                    end
                end)
            end

            function Drop:Set(option, fire)
                currentOption = option
                L.Text = opts.Name .. " : " .. tostring(option)
                for _, c in ipairs(List:GetChildren()) do
                    if c:IsA("TextButton") then
                        local sel = c.Text == tostring(option)
                        tween(c, easeInfo(0.15), {BackgroundTransparency = sel and 0.7 or 1})
                        c.TextColor3 = sel and Theme.Accent or Theme.Text
                    end
                end
                if fire ~= false and opts.Callback then opts.Callback(option) end
            end

            function Drop:Get() return currentOption end

            function Drop:Refresh(options)
                for _, c in ipairs(List:GetChildren()) do
                    if c:IsA("TextButton") then c:Destroy() end
                end
                listHeight = math.min(math.max(#options, 1), maxVisible) * optionHeight + 8
                ListHolder.Size = UDim2.new(1, -24, 0, listHeight)
                if open then Row.Size = openSize() end

                for _, itm in ipairs(options) do
                    local selected = tostring(itm) == tostring(currentOption)
                    local ib = Instance.new("TextButton", List)
                    ib.Size = UDim2.new(1, -8, 0, optionHeight - 2)
                    ib.Position = UDim2.new(0, 4, 0, 0)
                    ib.BackgroundColor3 = Theme.Accent
                    ib.BackgroundTransparency = selected and 0.7 or 1
                    ib.BorderSizePixel = 0
                    ib.Text = tostring(itm)
                    ib.TextColor3 = selected and Theme.Accent or Theme.Text
                    ib.Font = Enum.Font.Gotham
                    ib.TextSize = 13
                    Instance.new("UICorner", ib).CornerRadius = UDim.new(0, 4)

                    track(ib.MouseEnter:Connect(function()
                        if tostring(itm) ~= tostring(currentOption) then
                            tween(ib, easeInfo(0.12), {BackgroundTransparency = 0.88})
                        end
                    end))
                    track(ib.MouseLeave:Connect(function()
                        if tostring(itm) ~= tostring(currentOption) then
                            tween(ib, easeInfo(0.12), {BackgroundTransparency = 1})
                        end
                    end))
                    
                    -- Native tap for dropdown items
                    track(ib.Activated:Connect(function()
                        Drop:Set(itm, true)
                        close()
                    end))
                end
                List.CanvasSize = UDim2.new(0, 0, 0, #options * optionHeight + 8)
            end
            Drop:Refresh(opts.Options)

            track(B.Activated:Connect(function()
                if open then close() else openDrop() end
            end))

            return Drop
        end

        function Tab:CreateTextbox(opts)
            opts = opts or {}
            local Row = newPanel(TabPage, Theme, UDim2.new(1, 0, 0, 42))

            local Box = Instance.new("TextBox", Row)
            Box.Size = UDim2.new(1, -22, 1, -12)
            Box.Position = UDim2.new(0, 11, 0, 6)
            Box.BackgroundColor3 = Theme.Background
            Box.BorderSizePixel = 0
            Box.Text = opts.Default or ""
            Box.PlaceholderText = opts.Placeholder or opts.Name or ""
            Box.TextColor3 = Theme.Text
            Box.PlaceholderColor3 = Theme.SubText
            Box.Font = Enum.Font.Gotham
            Box.TextSize = 14
            Box.ClearTextOnFocus = false
            Instance.new("UICorner", Box).CornerRadius = UDim.new(0, 6)
            local BoxStroke = Instance.new("UIStroke", Box)
            BoxStroke.Color = Theme.Accent
            BoxStroke.Transparency = 0.5

            local TextboxObj = {}
            function TextboxObj:Set(t) Box.Text = t end
            function TextboxObj:Get() return Box.Text end

            track(Box.FocusLost:Connect(function(enterPressed)
                if opts.Callback then opts.Callback(Box.Text, enterPressed) end
            end))

            return TextboxObj
        end

        function Tab:CreateKeybind(opts)
            opts = opts or {}
            local currentKey = opts.CurrentKey or Enum.KeyCode.Unknown
            local listening = false

            local Row = newPanel(TabPage, Theme, UDim2.new(1, 0, 0, 42))

            local L = Instance.new("TextLabel", Row)
            L.Size = UDim2.new(0.6, 0, 1, 0)
            L.Position = UDim2.new(0, 14, 0, 0)
            L.BackgroundTransparency = 1
            L.Text = opts.Name
            L.TextColor3 = Theme.Text
            L.Font = Enum.Font.GothamMedium
            L.TextSize = 14
            L.TextXAlignment = Enum.TextXAlignment.Left

            local B = Instance.new("TextButton", Row)
            B.Size = UDim2.new(0, 90, 0, 26)
            B.Position = UDim2.new(1, -100, 0.5, -13)
            B.BackgroundColor3 = Theme.Background
            B.BorderSizePixel = 0
            B.Text = currentKey.Name
            B.TextColor3 = Theme.Accent
            B.Font = Enum.Font.GothamBold
            B.TextSize = 13
            Instance.new("UICorner", B).CornerRadius = UDim.new(0, 6)
            local BStroke = Instance.new("UIStroke", B)
            BStroke.Color = Theme.Accent
            BStroke.Transparency = 0.5

            local KeybindObj = {}
            function KeybindObj:Get() return currentKey end
            function KeybindObj:Set(key)
                currentKey = key
                B.Text = key.Name
            end

            track(B.Activated:Connect(function()
                listening = true
                B.Text = "..."
            end))

            track(UserInputService.InputBegan:Connect(function(input, gp)
                if not listening then return end
                if input.UserInputType == Enum.UserInputType.Keyboard then
                    currentKey = input.KeyCode
                    B.Text = currentKey.Name
                    listening = false
                    if opts.Callback then opts.Callback(currentKey) end
                end
            end))

            return KeybindObj
        end

        function Tab:CreateButton(opts)
            opts = opts or {}
            local Row = newPanel(TabPage, Theme, UDim2.new(1, 0, 0, 42))

            local B = Instance.new("TextButton", Row)
            B.Size = UDim2.new(1, 0, 1, 0)
            B.BackgroundTransparency = 1
            B.Text = opts.Name
            B.TextColor3 = Theme.Text
            B.Font = Enum.Font.GothamBold
            B.TextSize = 14

            track(B.Activated:Connect(function()
                if opts.Callback then opts.Callback() end
            end))
        end

        return Tab
    end

    function Window:Notify(opts)
        opts = opts or {}
        local color = Theme.Accent
        if opts.Type == "Success" then color = Theme.Success
        elseif opts.Type == "Error" then color = Theme.Error end

        local N = Instance.new("Frame", NotifyContainer)
        N.ZIndex = 6
        N.Size = UDim2.new(1, 0, 0, 0)
        N.AutomaticSize = Enum.AutomaticSize.Y
        N.BackgroundColor3 = Theme.Panel
        N.BorderSizePixel = 0
        N.ClipsDescendants = true
        Instance.new("UICorner", N).CornerRadius = UDim.new(0, 8)
        local stroke = Instance.new("UIStroke", N)
        stroke.Color = Theme.Accent
        stroke.Transparency = 0.5

        local AccentBar = Instance.new("Frame", N)
        AccentBar.Size = UDim2.new(0, 3, 1, 0)
        AccentBar.BackgroundColor3 = color
        AccentBar.BorderSizePixel = 0
        Instance.new("UICorner", AccentBar).CornerRadius = UDim.new(1, 0)

        local Pad = Instance.new("UIPadding", N)
        Pad.PaddingTop = UDim.new(0, 8)
        Pad.PaddingBottom = UDim.new(0, 8)
        Pad.PaddingLeft = UDim.new(0, 14)
        Pad.PaddingRight = UDim.new(0, 10)

        local T = Instance.new("TextLabel", N)
        T.Size = UDim2.new(1, 0, 0, 16)
        T.BackgroundTransparency = 1
        T.Text = opts.Title or "Notification"
        T.TextColor3 = color
        T.Font = Enum.Font.GothamBold
        T.TextSize = 13
        T.TextXAlignment = Enum.TextXAlignment.Left

        local Msg = Instance.new("TextLabel", N)
        Msg.Size = UDim2.new(1, 0, 0, 0)
        Msg.AutomaticSize = Enum.AutomaticSize.Y
        Msg.Position = UDim2.new(0, 0, 0, 18)
        Msg.BackgroundTransparency = 1
        Msg.Text = opts.Text or ""
        Msg.TextColor3 = Theme.Text
        Msg.Font = Enum.Font.Gotham
        Msg.TextSize = 13
        Msg.TextWrapped = true
        Msg.TextXAlignment = Enum.TextXAlignment.Left

        task.delay(opts.Duration or 4, function()
            if N and N.Parent then
                tween(N, easeInfo(0.25), {BackgroundTransparency = 1})
                task.wait(0.25)
                N:Destroy()
            end
        end)
    end

    function Window:Destroy()
        for _, c in ipairs(Connections) do
            pcall(function() c:Disconnect() end)
        end
        ScreenGui:Destroy()
    end

    return Window
end

return Library
