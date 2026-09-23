-- 7rqxy Custom UI Library v3 | Glassmorphism | Mobile Optimized
-- Built on v2's bug fixes (safe defaults, clamped dragging, leak-free Destroy,
-- outside-click dropdowns) with a full glass restyle:
--   * Translucent panels (BackgroundTransparency) instead of solid fills
--   * Diagonal UIGradient "sheen" on every glass surface
--   * Soft accent-colored UIStroke edges instead of hard borders
--   * Two-tone accent gradient on fills (toggles/sliders/underline)
--   * Real backdrop blur: a Lighting.BlurEffect ramps up while the menu is open,
--     which is the actual mechanism games like Sol's RNG use — Roblox has no
--     way to blur *only* what's behind a single frame, so the whole 3D view
--     blurs instead. Disable with config.BackdropBlur = false if that's not
--     wanted (e.g. it will also blur any other on-screen game UI).
--   * Soft drop shadow under the main panel and floating toggle button

local Library = {}
Library.Version = "3.0.0"

local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")

local DefaultTheme = {
    Background = Color3.fromRGB(12, 12, 18),      -- base glass tint (dark)
    Panel = Color3.fromRGB(255, 255, 255),         -- glass rows tint (white, kept very transparent)
    Accent = Color3.fromRGB(150, 160, 255),
    AccentGradient = {Color3.fromRGB(155, 120, 255), Color3.fromRGB(90, 195, 255)},
    Text = Color3.fromRGB(245, 245, 250),
    SubText = Color3.fromRGB(180, 180, 200),
    SectionHeader = Color3.fromRGB(165, 165, 190),
    Success = Color3.fromRGB(120, 220, 160),
    Error = Color3.fromRGB(230, 110, 120),
    BackgroundTransparency = 0.35,
    PanelTransparency = 0.75,
    StrokeTransparency = 0.55,
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

--// Glass building blocks -----------------------------------------------

-- Soft drop shadow using a 9-sliced shadow image. Swap the asset id for your
-- own shadow texture if this one doesn't suit your theme.
local function addShadow(parent, transparency, padding)
    local shadow = Instance.new("ImageLabel")
    shadow.Name = "Shadow"
    shadow.ZIndex = 0
    shadow.BackgroundTransparency = 1
    shadow.Image = "rbxassetid://5028857084"
    shadow.ImageColor3 = Color3.new(0, 0, 0)
    shadow.ImageTransparency = transparency or 0.55
    shadow.ScaleType = Enum.ScaleType.Slice
    shadow.SliceCenter = Rect.new(23, 23, 277, 277)
    local p = padding or 24
    shadow.Size = UDim2.new(1, p * 2, 1, p * 2)
    shadow.Position = UDim2.new(0, -p, 0, -p)
    shadow.Parent = parent
    return shadow
end

local function addGlassSheen(frame, strokeTransparency, theme)
    local stroke = Instance.new("UIStroke", frame)
    stroke.Color = theme.Accent
    stroke.Thickness = 1
    stroke.Transparency = strokeTransparency or theme.StrokeTransparency

    local grad = Instance.new("UIGradient", frame)
    grad.Rotation = 75
    grad.Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.new(1, 1, 1))
    grad.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.55),
        NumberSequenceKeypoint.new(0.55, 0.92),
        NumberSequenceKeypoint.new(1, 0.75),
    })
    return stroke, grad
end

-- Creates a translucent "glass card" row: background + rounded corners + sheen.
local function newGlassPanel(parent, theme, size, position, cornerRadius)
    local f = Instance.new("Frame", parent)
    f.Size = size
    if position then f.Position = position end
    f.BackgroundColor3 = theme.Panel
    f.BackgroundTransparency = theme.PanelTransparency
    f.BorderSizePixel = 0
    Instance.new("UICorner", f).CornerRadius = UDim.new(0, cornerRadius or 10)
    local stroke = addGlassSheen(f, theme.StrokeTransparency, theme)
    return f, stroke
end

local function applyAccentGradient(frame, theme, rotation)
    local grad = Instance.new("UIGradient", frame)
    grad.Rotation = rotation or 0
    grad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, theme.AccentGradient[1]),
        ColorSequenceKeypoint.new(1, theme.AccentGradient[2]),
    })
    return grad
end

--// Window --------------------------------------------------------------

function Library:CreateWindow(config)
    config = config or {}
    local Window = {}
    local Theme = merge(DefaultTheme, config.Theme)
    local TitleText = config.Title or "7rqxy UI"
    local MenuKey = config.MenuKey or Enum.KeyCode.RightShift
    local UseBlur = config.BackdropBlur ~= false
    local BlurSize = config.BlurSize or 14

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

    -- Backdrop blur: ramps up while the menu is visible, back down when hidden
    local BlurEffect
    if UseBlur then
        BlurEffect = Instance.new("BlurEffect")
        BlurEffect.Name = "7rqxy_GlassBlur_" .. tostring(math.random(1, 999999))
        BlurEffect.Size = 0
        BlurEffect.Parent = Lighting
    end

    -- Mobile floating toggle button (glass circle)
    local ToggleBtn = Instance.new("TextButton", ScreenGui)
    ToggleBtn.ZIndex = 5
    ToggleBtn.Size = UDim2.new(0, 46, 0, 46)
    ToggleBtn.Position = UDim2.new(0.5, -23, 0, 14)
    ToggleBtn.BackgroundColor3 = Theme.Panel
    ToggleBtn.BackgroundTransparency = 0.55
    ToggleBtn.AutoButtonColor = false
    ToggleBtn.Text = "7"
    ToggleBtn.TextColor3 = Theme.Text
    ToggleBtn.Font = Enum.Font.GothamBold
    ToggleBtn.TextSize = 20
    Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(1, 0)
    addShadow(ToggleBtn, 0.65, 14)
    local ToggleStroke = Instance.new("UIStroke", ToggleBtn)
    ToggleStroke.Thickness = 1.5
    ToggleStroke.Color = Theme.Accent
    ToggleStroke.Transparency = 0.25

    local Main = Instance.new("Frame", ScreenGui)
    Main.Name = "MainFrame"
    Main.ZIndex = 2
    Main.Size = UDim2.new(0, 420, 0, 380)
    Main.Position = UDim2.new(0.5, -210, 0.5, -190)
    Main.BackgroundColor3 = Theme.Background
    Main.BackgroundTransparency = Theme.BackgroundTransparency
    Main.BorderSizePixel = 0
    Main.Visible = false
    Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 14)
    addShadow(Main, 0.55, 26)
    addGlassSheen(Main, 0.45, Theme)

    -- Sync backdrop blur with window visibility, however it gets toggled
    if BlurEffect then
        track(Main:GetPropertyChangedSignal("Visible"):Connect(function()
            tween(BlurEffect, TweenInfo.new(0.25), {Size = Main.Visible and BlurSize or 0})
        end))
    end

    local TopBar = Instance.new("Frame", Main)
    TopBar.ZIndex = 3
    TopBar.Size = UDim2.new(1, 0, 0, 38)
    TopBar.BackgroundTransparency = 1
    TopBar.BorderSizePixel = 0

    local Title = Instance.new("TextLabel", TopBar)
    Title.Size = UDim2.new(1, -15, 1, 0)
    Title.Position = UDim2.new(0, 15, 0, 0)
    Title.BackgroundTransparency = 1
    Title.Text = TitleText
    Title.TextColor3 = Theme.Text
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = 14
    Title.TextXAlignment = Enum.TextXAlignment.Left

    local Divider = Instance.new("Frame", TopBar)
    Divider.Size = UDim2.new(1, -24, 0, 1)
    Divider.Position = UDim2.new(0, 12, 1, -1)
    Divider.BackgroundColor3 = Color3.new(1, 1, 1)
    Divider.BackgroundTransparency = 0.6
    Divider.BorderSizePixel = 0
    applyAccentGradient(Divider, Theme, 0)

    -- Scrollable pill-style tab bar
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

    -- Notifications (stacked bottom-right, glass cards)
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

    --// Dragging (clamped to screen) --------------------------------------

    local function makeDraggable(handle, target)
        local dragging, dragStart, startPos = false, nil, nil
        track(handle.InputBegan:Connect(function(input)
            if isPress(input) then
                dragging = true
                dragStart = input.Position
                startPos = target.Position
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

    local tDragging, tMoved, tStart, tPos = false, false, nil, nil
    track(ToggleBtn.InputBegan:Connect(function(input)
        if isPress(input) then
            tDragging = true; tMoved = false; tStart = input.Position; tPos = ToggleBtn.Position
        end
    end))
    track(ToggleBtn.InputEnded:Connect(function(input)
        if isPress(input) then tDragging = false end
    end))
    track(UserInputService.InputChanged:Connect(function(input)
        if tDragging and isMove(input) then
            local delta = input.Position - tStart
            if delta.Magnitude > 5 then
                tMoved = true
                local screen = screenSize()
                local size = ToggleBtn.AbsoluteSize
                local newX = clamp(tPos.X.Offset + delta.X, 0, screen.X - size.X)
                local newY = clamp(tPos.Y.Offset + delta.Y, 0, screen.Y - size.Y)
                ToggleBtn.Position = UDim2.new(0, newX, 0, newY)
            end
        end
    end))
    track(ToggleBtn.MouseButton1Click:Connect(function()
        if not tMoved then Main.Visible = not Main.Visible end
    end))
    track(UserInputService.InputBegan:Connect(function(input, gp)
        if not gp and input.KeyCode == MenuKey then Main.Visible = not Main.Visible end
    end))

    local Tabs = {}
    local FirstTab = true

    function Window:CreateTab(name)
        local Tab = {}
        local selected = FirstTab

        local TabBtn = Instance.new("TextButton", TabBar)
        TabBtn.ZIndex = 3
        TabBtn.Size = UDim2.new(0, 92, 1, 0)
        TabBtn.BackgroundColor3 = Theme.Panel
        TabBtn.BackgroundTransparency = selected and 0.55 or 0.9
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
        TabStroke.Transparency = selected and 0.4 or 0.9

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

        track(TabBtn.MouseButton1Click:Connect(function()
            for _, t in pairs(Tabs) do
                t.Page.Visible = false
                tween(t.Btn, TweenInfo.new(0.15), {BackgroundTransparency = 0.9})
                tween(t.Stroke, TweenInfo.new(0.15), {Transparency = 0.9})
                t.Btn.TextColor3 = Theme.SubText
            end
            TabPage.Visible = true
            tween(TabBtn, TweenInfo.new(0.15), {BackgroundTransparency = 0.55})
            tween(TabStroke, TweenInfo.new(0.15), {Transparency = 0.4})
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
            local Row = newGlassPanel(TabPage, Theme, UDim2.new(1, 0, 0, 40))

            local L = Instance.new("TextLabel", Row)
            L.Size = UDim2.new(0.8, 0, 1, 0)
            L.Position = UDim2.new(0, 12, 0, 0)
            L.BackgroundTransparency = 1
            L.Text = opts.Name
            L.TextColor3 = Theme.Text
            L.Font = Enum.Font.Gotham
            L.TextSize = 14
            L.TextXAlignment = Enum.TextXAlignment.Left

            local Box = Instance.new("Frame", Row)
            Box.Size = UDim2.new(0, 24, 0, 24)
            Box.Position = UDim2.new(1, -36, 0.5, -12)
            Box.BackgroundColor3 = Theme.Background
            Box.BackgroundTransparency = 0.4
            Box.BorderSizePixel = 0
            Instance.new("UICorner", Box).CornerRadius = UDim.new(0, 6)
            local BoxStroke = Instance.new("UIStroke", Box)
            BoxStroke.Color = Theme.Accent
            BoxStroke.Transparency = 0.5

            local Fill = Instance.new("Frame", Box)
            Fill.Size = UDim2.new(1, -6, 1, -6)
            Fill.Position = UDim2.new(0, 3, 0, 3)
            Fill.BorderSizePixel = 0
            Instance.new("UICorner", Fill).CornerRadius = UDim.new(0, 4)
            applyAccentGradient(Fill, Theme, 45)

            local B = Instance.new("TextButton", Row)
            B.Size = UDim2.new(1, 0, 1, 0)
            B.BackgroundTransparency = 1
            B.Text = ""

            local state = opts.CurrentValue == true -- fixed: nil-safe default
            Fill.Visible = state

            local ToggleObj = {}
            function ToggleObj:Set(v, fire)
                state = v and true or false
                Fill.Visible = state
                if fire ~= false and opts.Callback then opts.Callback(state) end
            end
            function ToggleObj:Get() return state end

            track(B.MouseButton1Click:Connect(function()
                ToggleObj:Set(not state)
            end))

            return ToggleObj
        end

        function Tab:CreateSlider(opts)
            opts = opts or {}
            local minV, maxV = opts.Range[1], opts.Range[2]
            if maxV == minV then maxV = minV + 1 end -- fixed: avoid divide-by-zero

            local Row = newGlassPanel(TabPage, Theme, UDim2.new(1, 0, 0, 65))

            local L = Instance.new("TextLabel", Row)
            L.Size = UDim2.new(1, -20, 0, 25)
            L.Position = UDim2.new(0, 12, 0, 5)
            L.BackgroundTransparency = 1
            L.Text = opts.Name
            L.TextColor3 = Theme.Text
            L.Font = Enum.Font.Gotham
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
            Track.Size = UDim2.new(1, -24, 0, 8)
            Track.Position = UDim2.new(0, 12, 0, 42)
            Track.BackgroundColor3 = Theme.Background
            Track.BackgroundTransparency = 0.35
            Track.BorderSizePixel = 0
            Instance.new("UICorner", Track).CornerRadius = UDim.new(1, 0)

            local Fill = Instance.new("Frame", Track)
            Fill.BorderSizePixel = 0
            Instance.new("UICorner", Fill).CornerRadius = UDim.new(1, 0)
            applyAccentGradient(Fill, Theme, 0)

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
            local Row, RowStroke = newGlassPanel(TabPage, Theme, UDim2.new(1, 0, 0, 40))
            Row.ClipsDescendants = true

            local L = Instance.new("TextLabel", Row)
            L.Size = UDim2.new(1, -20, 0, 40)
            L.Position = UDim2.new(0, 12, 0, 0)
            L.BackgroundTransparency = 1
            L.Text = opts.Name .. " : " .. tostring(opts.CurrentOption)
            L.TextColor3 = Theme.Text
            L.Font = Enum.Font.Gotham
            L.TextSize = 14
            L.TextXAlignment = Enum.TextXAlignment.Left

            local List = Instance.new("ScrollingFrame", Row)
            List.Size = UDim2.new(1, -24, 1, -50)
            List.Position = UDim2.new(0, 12, 0, 45)
            List.BackgroundColor3 = Theme.Background
            List.BackgroundTransparency = 0.4
            List.BorderSizePixel = 0
            List.ScrollBarThickness = 4
            List.ScrollBarImageColor3 = Theme.Accent
            Instance.new("UICorner", List).CornerRadius = UDim.new(0, 6)
            Instance.new("UIListLayout", List)

            local open = false
            local outsideConn = nil
            local currentOption = opts.CurrentOption

            local B = Instance.new("TextButton", Row)
            B.Size = UDim2.new(1, 0, 0, 40)
            B.BackgroundTransparency = 1
            B.Text = ""

            local function close()
                open = false
                tween(Row, TweenInfo.new(0.2), {Size = UDim2.new(1, 0, 0, 40)})
                if outsideConn then
                    outsideConn:Disconnect()
                    outsideConn = nil
                end
            end

            local function openDrop()
                open = true
                tween(Row, TweenInfo.new(0.2), {Size = UDim2.new(1, 0, 0, 150)})
                outsideConn = UserInputService.InputBegan:Connect(function(input, gp)
                    if gp or not isPress(input) then return end
                    local ap, as = Row.AbsolutePosition, Row.AbsoluteSize
                    local pos = input.Position
                    if pos.X < ap.X or pos.X > ap.X + as.X or pos.Y < ap.Y or pos.Y > ap.Y + as.Y then
                        close()
                    end
                end)
                track(outsideConn)
            end

            function Drop:Set(option, fire)
                currentOption = option
                L.Text = opts.Name .. " : " .. tostring(option)
                if fire ~= false and opts.Callback then opts.Callback(option) end
            end

            function Drop:Get() return currentOption end

            function Drop:Refresh(options)
                for _, c in pairs(List:GetChildren()) do
                    if c:IsA("TextButton") then c:Destroy() end
                end
                local h = 0
                for _, itm in ipairs(options) do
                    local ib = Instance.new("TextButton", List)
                    ib.Size = UDim2.new(1, 0, 0, 30)
                    ib.BackgroundColor3 = Theme.Background
                    ib.BackgroundTransparency = 1
                    ib.BorderSizePixel = 0
                    ib.Text = itm
                    ib.TextColor3 = Theme.Text
                    ib.Font = Enum.Font.Gotham
                    ib.TextSize = 13
                    track(ib.MouseButton1Click:Connect(function()
                        Drop:Set(itm, true)
                        close()
                    end))
                    h = h + 30
                end
                List.CanvasSize = UDim2.new(0, 0, 0, h)
            end
            Drop:Refresh(opts.Options)

            track(B.MouseButton1Click:Connect(function()
                if open then close() else openDrop() end
            end))

            return Drop
        end

        function Tab:CreateTextbox(opts)
            opts = opts or {}
            local Row = newGlassPanel(TabPage, Theme, UDim2.new(1, 0, 0, 40))

            local Box = Instance.new("TextBox", Row)
            Box.Size = UDim2.new(1, -20, 1, -10)
            Box.Position = UDim2.new(0, 10, 0, 5)
            Box.BackgroundColor3 = Theme.Background
            Box.BackgroundTransparency = 0.45
            Box.BorderSizePixel = 0
            Box.Text = opts.Default or ""
            Box.PlaceholderText = opts.Placeholder or opts.Name or ""
            Box.TextColor3 = Theme.Text
            Box.PlaceholderColor3 = Theme.SubText
            Box.Font = Enum.Font.Gotham
            Box.TextSize = 14
            Box.ClearTextOnFocus = false
            Instance.new("UICorner", Box).CornerRadius = UDim.new(0, 6)

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

            local Row = newGlassPanel(TabPage, Theme, UDim2.new(1, 0, 0, 40))

            local L = Instance.new("TextLabel", Row)
            L.Size = UDim2.new(0.6, 0, 1, 0)
            L.Position = UDim2.new(0, 12, 0, 0)
            L.BackgroundTransparency = 1
            L.Text = opts.Name
            L.TextColor3 = Theme.Text
            L.Font = Enum.Font.Gotham
            L.TextSize = 14
            L.TextXAlignment = Enum.TextXAlignment.Left

            local B = Instance.new("TextButton", Row)
            B.Size = UDim2.new(0, 90, 0, 26)
            B.Position = UDim2.new(1, -100, 0.5, -13)
            B.BackgroundColor3 = Theme.Background
            B.BackgroundTransparency = 0.4
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

            track(B.MouseButton1Click:Connect(function()
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
            local Row = newGlassPanel(TabPage, Theme, UDim2.new(1, 0, 0, 40))

            local B = Instance.new("TextButton", Row)
            B.Size = UDim2.new(1, 0, 1, 0)
            B.BackgroundTransparency = 1
            B.Text = opts.Name
            B.TextColor3 = Theme.Text
            B.Font = Enum.Font.GothamBold
            B.TextSize = 14

            track(B.MouseButton1Click:Connect(function()
                if opts.Callback then opts.Callback() end
            end))
        end

        return Tab
    end

    -- Toast notification, e.g. Window:Notify({Title="Saved", Text="Config updated", Type="Success"})
    function Window:Notify(opts)
        opts = opts or {}
        local color = Theme.Accent
        if opts.Type == "Success" then color = Theme.Success
        elseif opts.Type == "Error" then color = Theme.Error end

        local N = Instance.new("Frame", NotifyContainer)
        N.ZIndex = 6
        N.Size = UDim2.new(1, 0, 0, 0)
        N.AutomaticSize = Enum.AutomaticSize.Y
        N.BackgroundColor3 = Theme.Background
        N.BackgroundTransparency = 0.3
        N.ClipsDescendants = true
        Instance.new("UICorner", N).CornerRadius = UDim.new(0, 8)
        addGlassSheen(N, 0.6, Theme)

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
                tween(N, TweenInfo.new(0.25), {BackgroundTransparency = 1})
                task.wait(0.25)
                N:Destroy()
            end
        end)
    end

    function Window:Destroy()
        for _, c in ipairs(Connections) do
            pcall(function() c:Disconnect() end)
        end
        if BlurEffect then
            pcall(function() BlurEffect:Destroy() end)
        end
        ScreenGui:Destroy()
    end

    return Window
end

return Library
