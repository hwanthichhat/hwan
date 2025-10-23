-- Hwan (Hwan UI library) - Updated (dropdown persistence, slider improvements, hover animations, smoother FPS, multiple select)
-- Note: Replace your existing hwanlibs.lua with this content.

local Hwan = {}
Hwan.__index = Hwan

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")
local TextService = game:GetService("TextService")
local LocalPlayer = Players.LocalPlayer

-- Predefined themes
local THEMES = {
    Dark = {
        Main = Color3.fromRGB(18,18,18),
        TabBg = Color3.fromRGB(40,40,40),
        Accent = Color3.fromRGB(245,245,245),
        Text = Color3.fromRGB(235,235,235),
        InfoBg = Color3.fromRGB(10,10,10),
        InfoInner = Color3.fromRGB(18,18,18),
        Btn = Color3.fromRGB(50,50,50),
        ToggleBg = Color3.fromRGB(80,80,80),
    }
}

-- Helpers
local function getGuiParent()
    if type(gethui) == "function" then
        local ok, g = pcall(gethui)
        if ok and g then return g end
    end
    if type(get_hidden_gui) == "function" then
        local ok, g = pcall(get_hidden_gui)
        if ok and g then return g end
    end
    if LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui") then
        return LocalPlayer.PlayerGui
    end
    return game:GetService("CoreGui")
end

local function protectGui(g)
    if syn and syn.protect_gui then pcall(syn.protect_gui, g) end
    if protect_gui then pcall(protect_gui, g) end
end

local function new(class, props)
    local inst = Instance.new(class)
    if props then
        if type(props) == "table" then
            for k,v in pairs(props) do pcall(function() inst[k] = v end) end
        else
            pcall(function() inst.Parent = props end)
        end
    end
    return inst
end

local function safeDestroy(obj)
    pcall(function() if obj and obj.Parent then obj:Destroy() end end)
end

local function tween(inst, props, time, style, dir)
    time = time or 0.18
    style = style or Enum.EasingStyle.Quad
    dir = dir or Enum.EasingDirection.Out
    pcall(function()
        if not inst or not inst.Parent then return end
        TweenService:Create(inst, TweenInfo.new(time, style, dir), props):Play()
    end)
end

local function clampVal(v,a,b) if v < a then return a end if v > b then return b end return v end
local function brightenColor(c, amt)
    amt = amt or 0.06
    return Color3.new(clampVal(c.R + amt, 0, 1), clampVal(c.G + amt, 0, 1), clampVal(c.B + amt, 0, 1))
end
local function darkenColor(c, amt)
    amt = amt or 0.08
    return Color3.new(clampVal(c.R - amt, 0, 1), clampVal(c.G - amt, 0, 1), clampVal(c.B - amt, 0, 1))
end

local function color3ToHex(c)
    local r = math.floor(c.R * 255 + 0.5)
    local g = math.floor(c.G * 255 + 0.5)
    local b = math.floor(c.B * 255 + 0.5)
    return string.format("#%02X%02X%02X", r, g, b)
end

local function escapeHtml(s)
    if not s then return "" end
    return tostring(s):gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;")
end

-- Defaults
local DEFAULT = {
    Width = 300,
    Height = 400, -- requested default
    Title = "HWAN HUB",
    ShowToggleIcon = true,
    KeySystem = true,
    KeySettings = nil,
    Theme = "Dark",
    Corner = UDim.new(0,12),
    ToggleKey = Enum.KeyCode.LeftAlt,
    ConfigurationSaving = { Enabled = false, FolderName = nil, FileName = nil },
}

-- File helpers
local function writeFileSafe(path, data)
    if writefile then
        pcall(writefile, path, data)
    end
end
local function readFileSafe(path)
    if isfile then
        local ok, res = pcall(readfile, path)
        if ok then return res end
    end
    return nil
end

-- Hover bounce helper (small zoom + bounce)
local hoverConfig = {
    scale = 1.035,
    timeEnter = 0.12,
    timeLeave = 0.12,
    easing = Enum.EasingStyle.Back
}
local function addHoverBounce(inst)
    if not inst or not inst:IsA("GuiObject") then return end
    if inst:GetAttribute("hw_hover_added") then return end
    inst:SetAttribute("hw_hover_added", true)
    local origSize = inst.Size
    local origPos = inst.Position
    local function scaledSize(s)
        local sx = s.X.Scale or 0
        local so = s.X.Offset or 0
        local sy = s.Y.Scale or 0
        local yo = s.Y.Offset or 0
        -- only scale offsets slightly; keep scale factors
        local nso = so * hoverConfig.scale
        local nyo = yo * hoverConfig.scale
        return UDim2.new(sx, nso, sy, nyo)
    end
    local function scaledPos(s, o)
        -- shift position so scaled element centers roughly same
        local dx = ( (o.X.Offset * (hoverConfig.scale - 1)) / 2 )
        local dy = ( (o.Y.Offset * (hoverConfig.scale - 1)) / 2 )
        local xScale = s.X.Scale or 0
        local yScale = s.Y.Scale or 0
        local xOff = (s.X.Offset or 0) - dx
        local yOff = (s.Y.Offset or 0) - dy
        return UDim2.new(xScale, xOff, yScale, yOff)
    end

    local entering = false
    local leaveTween, enterTween

    inst.MouseEnter:Connect(function()
        if not inst or not inst.Parent then return end
        if entering then return end
        entering = true
        pcall(function()
            if enterTween then pcall(function() enterTween:Cancel() end) end
            enterTween = TweenService:Create(inst, TweenInfo.new(hoverConfig.timeEnter, hoverConfig.easing, Enum.EasingDirection.Out), {Size = scaledSize(origSize), Position = scaledPos(origSize, origPos)})
            enterTween:Play()
        end)
    end)
    inst.MouseLeave:Connect(function()
        if not inst or not inst.Parent then return end
        entering = false
        pcall(function()
            if enterTween then pcall(function() enterTween:Cancel() end) end
            leaveTween = TweenService:Create(inst, TweenInfo.new(hoverConfig.timeLeave, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {Size = origSize, Position = origPos})
            leaveTween:Play()
        end)
    end)
end

-- Create window
function Hwan:CreateWindow(opts)
    opts = opts or {}
    local cfg = {}
    for k,v in pairs(DEFAULT) do
        if type(v) == "table" then
            cfg[k] = {}
            for kk,vv in pairs(v) do cfg[k][kk] = vv end
        else
            cfg[k] = v
        end
    end

    if type(opts) == "string" then
        cfg.Title = opts
    elseif type(opts) == "table" then
        if opts.Name then cfg.Title = opts.Name end
        for k,v in pairs(opts) do
            if k == "Theme" and type(v) == "table" then
                -- handled below
            elseif k == "Theme" and type(v) == "string" then
            else
                cfg[k] = v
            end
        end
    end

    if type(opts) == "table" and opts.Theme then
        if type(opts.Theme) == "string" then
            cfg.Theme = opts.Theme
        elseif type(opts.Theme) == "table" then
            cfg.Theme = opts.Theme
        end
    end

    if type(cfg.Theme) == "string" then
        local tname = cfg.Theme
        if THEMES[tname] then
            cfg.Theme = {}
            for kk,vv in pairs(THEMES[tname]) do cfg.Theme[kk] = vv end
        else
            cfg.Theme = {}
            for kk,vv in pairs(THEMES.Dark) do cfg.Theme[kk] = vv end
        end
    elseif type(cfg.Theme) == "table" then
        local merged = {}
        for kk,vv in pairs(THEMES.Dark) do merged[kk] = vv end
        for kk,vv in pairs(cfg.Theme) do merged[kk] = vv end
        cfg.Theme = merged
    else
        cfg.Theme = {}
        for kk,vv in pairs(THEMES.Dark) do cfg.Theme[kk] = vv end
    end

    cfg.KeySettings = cfg.KeySettings or {}
    if type(opts) == "table" and opts.KeySettings ~= nil then
        cfg.KeySystem = true
    end
    if cfg.AccessKey and (cfg.KeySettings.Key == nil or #cfg.KeySettings.Key == 0) then
        cfg.KeySettings.Key = cfg.KeySettings.Key or {}
        table.insert(cfg.KeySettings.Key, tostring(cfg.AccessKey))
    end
    if cfg.KeyUrl and (not cfg.KeySettings.KeyUrl) then
        cfg.KeySettings.KeyUrl = cfg.KeySettings.KeyUrl or cfg.KeyUrl
    end
    cfg.KeySettings.Title = cfg.KeySettings.Title or (cfg.Title .. " | Key System")
    cfg.KeySettings.FileName = cfg.KeySettings.FileName or (cfg.Title .. "_key.txt")
    cfg.KeySettings.SaveKey = (cfg.KeySettings.SaveKey == true)
    cfg.KeySettings.GrabKeyFromSite = (cfg.KeySettings.GrabKeyFromSite == true)
    cfg.KeySettings.Key = cfg.KeySettings.Key or {}

    local conns = {}
    local function addConn(c) if c then table.insert(conns, c) end end

    local host = getGuiParent()
    local screenGui = new("ScreenGui")
    screenGui.Name = (cfg.Title:gsub("%s+", "") or "Hwan") .. "_GUI"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = host
    protectGui(screenGui)

    local refs = {}

    local Frame = new("Frame", {
        Parent = screenGui,
        Name = "Main",
        Size = UDim2.new(0, cfg.Width, 0, 0),
        Position = UDim2.new(0, 16, 0.5, -cfg.Height/2),
        BackgroundColor3 = cfg.Theme.Main,
        BorderSizePixel = 0,
        Active = true
    })
    refs.Frame = Frame
    new("UICorner", {Parent = Frame, CornerRadius = cfg.Corner})
    local frameStroke = new("UIStroke", {Parent = Frame})
    frameStroke.Thickness = 2
    frameStroke.Transparency = 0.8
    frameStroke.Color = Color3.fromRGB(255,255,255)

    local TitleFrame = new("Frame", {Parent = Frame, Size = UDim2.new(1, -16, 0, 100), Position = UDim2.new(0,8,0,8), BackgroundTransparency = 1})
    local TitleMain = new("TextLabel", {
        Parent = TitleFrame,
        Size = UDim2.new(1,0,0,54),
        Position = UDim2.new(0,0,0,4),
        BackgroundTransparency = 1,
        Text = string.upper(cfg.Title),
        Font = Enum.Font.LuckiestGuy,
        TextSize = 44,
        TextYAlignment = Enum.TextYAlignment.Center,
        TextXAlignment = Enum.TextXAlignment.Center,
        TextStrokeTransparency = 0,
        TextStrokeColor3 = Color3.fromRGB(0,0,0),
        TextTransparency = 0,
        TextColor3 = cfg.Theme.Accent,
        ZIndex = 70,
        ClipsDescendants = false
    })
    refs.TitleMain = TitleMain
    local titleGrad = new("UIGradient", {Parent = TitleMain})
    titleGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255,255,255)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(120,120,120)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(0,0,0)),
    })
    titleGrad.Rotation = 0

    local TabsFrame = new("Frame", {Parent = TitleFrame, Size = UDim2.new(1,0,0,36), Position = UDim2.new(0,0,0,56), BackgroundTransparency = 1})
    local TabsHolder = new("Frame", {Parent = TabsFrame, Size = UDim2.new(1, 0, 1, 0), Position = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 1})
    new("UICorner", {Parent = TabsHolder, CornerRadius = UDim.new(0,8)})

    local dividerY = 100
    local MainDivider = new("Frame", {
        Parent = Frame,
        Name = "MainDivider",
        Size = UDim2.new(1, -16, 0, 2),
        Position = UDim2.new(0, 8, 0, dividerY + 8),
        BackgroundColor3 = cfg.Theme.TabBg,
        BorderSizePixel = 0
    })
    refs.MainDivider = MainDivider
    MainDivider.ClipsDescendants = true

    local dividerGrad = new("UIGradient", { Parent = MainDivider })
    dividerGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255,255,255)),
        ColorSequenceKeypoint.new(1.00, Color3.fromRGB(200,200,200)),
    })
    dividerGrad.Rotation = 0

    local dividerColorTimer = 0
    local dividerColorFreq = 0.6
    local dividerColorMin = Color3.fromRGB(200,200,200)
    local dividerColorMax = Color3.fromRGB(255,255,255)
    local divColorConn = RunService.Heartbeat:Connect(function(dt)
        pcall(function()
            dividerColorTimer = dividerColorTimer + dt
            local t = (math.sin(dividerColorTimer * (2 * math.pi * dividerColorFreq)) + 1) / 2
            local r = dividerColorMin:Lerp(dividerColorMax, t)
            dividerGrad.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, r), ColorSequenceKeypoint.new(1, r) })
        end)
    end)
    addConn(divColorConn)

    local InfoBar = new("Frame", {Parent = screenGui, Name = "InfoBar", Size = UDim2.new(0, 360, 0, 36), Position = UDim2.new(1, -376, 0, 16), BackgroundColor3 = cfg.Theme.InfoBg, BorderSizePixel = 0, ZIndex = 50})
    refs.InfoBar = InfoBar
    new("UICorner", {Parent = InfoBar, CornerRadius = UDim.new(0,8)})
    InfoBar.BackgroundTransparency = 0.06
    local InfoBarStroke = new("UIStroke", {Parent = InfoBar})
    InfoBarStroke.Thickness = 2
    InfoBarStroke.Transparency = 0.8
    InfoBarStroke.Color = Color3.fromRGB(255,255,255)

    local InfoInner = new("Frame", {Parent = InfoBar, Size = UDim2.new(1, -8, 1, -8), Position = UDim2.new(0,4,0,4), BackgroundColor3 = cfg.Theme.InfoInner, BorderSizePixel = 0, ZIndex = 51})
    new("UICorner", {Parent = InfoInner, CornerRadius = UDim.new(0,6)})
    local InfoText = new("TextLabel", {Parent = InfoInner, Size = UDim2.new(1,-4,1,0), Position = UDim2.new(0,2,0,0), BackgroundTransparency = 1, Font = Enum.Font.SourceSansBold, TextSize = 18, TextXAlignment = Enum.TextXAlignment.Center, TextYAlignment = Enum.TextYAlignment.Center, TextColor3 = cfg.Theme.Text, Text = "TIME: 00:00:00 | FPS: 0 | PING: 0 ms (0%CV)", ZIndex = 52})
    refs.InfoText = InfoText

    local HwanBtn = new("Frame", {Parent = screenGui, Name = "HwanBtn", Size = UDim2.new(0,56,0,56), Position = UDim2.new(0, 90, 0, 64), BackgroundColor3 = cfg.Theme.InfoInner, BorderSizePixel = 0, ZIndex = 1000, Active = true, Visible = (cfg.ShowToggleIcon ~= false)})
    refs.HwanBtn = HwanBtn
    new("UICorner", {Parent = HwanBtn, CornerRadius = UDim.new(0,10)})
    local HwanBtnStroke = new("UIStroke", {Parent = HwanBtn})
    HwanBtnStroke.Thickness = 2
    HwanBtnStroke.Transparency = 0.8
    HwanBtnStroke.Color = Color3.fromRGB(255,255,255)

    local HwanInner = new("Frame", {Parent = HwanBtn, Size = UDim2.new(1,-8,1,-8), Position = UDim2.new(0,4,0,4), BackgroundColor3 = cfg.Theme.InfoInner, BorderSizePixel = 0, ZIndex = 1001})
    new("UICorner", {Parent = HwanInner, CornerRadius = UDim.new(0,8)})
    refs.HwanInner = HwanInner

    local HwanTop = new("TextLabel", {Parent = HwanInner, Size = UDim2.new(1,0,0,18), Position = UDim2.new(0,0,0,6), BackgroundTransparency = 1, Font = Enum.Font.LuckiestGuy, Text = string.sub(cfg.Title,1,4):upper(), TextXAlignment = Enum.TextXAlignment.Center, TextYAlignment = Enum.TextYAlignment.Center, TextStrokeTransparency = 0, TextStrokeColor3 = Color3.fromRGB(255,255,255), TextColor3 = Color3.fromRGB(0,0,0), ZIndex = 1002, TextSize = 14})
    local HwanBottom = new("TextLabel", {Parent = HwanInner, Size = UDim2.new(1,0,0,20), Position = UDim2.new(0,0,0,26), BackgroundTransparency = 1, Font = Enum.Font.LuckiestGuy, Text = "HUB", TextXAlignment = Enum.TextXAlignment.Center, TextYAlignment = Enum.TextYAlignment.Center, TextStrokeTransparency = 0, TextStrokeColor3 = Color3.fromRGB(255,255,255), TextColor3 = Color3.fromRGB(0,0,0), ZIndex = 1002, TextSize = 16})
    local hwanTopGrad = new("UIGradient", {Parent = HwanTop}) hwanTopGrad.Rotation = 0
    local hwanBottomGrad = new("UIGradient", {Parent = HwanBottom}) hwanBottomGrad.Rotation = 0
    hwanTopGrad.Color = titleGrad.Color
    hwanBottomGrad.Color = titleGrad.Color

    local contentYStart = dividerY + 6
    local contentArea = new("Frame", {Parent = Frame, Size = UDim2.new(1,0,1, -contentYStart), Position = UDim2.new(0,0,0,contentYStart), BackgroundTransparency = 1})
    new("UIPadding", {Parent = contentArea, PaddingLeft = UDim.new(0,8), PaddingRight = UDim.new(0,8), PaddingTop = UDim.new(0,4), PaddingBottom = UDim.new(0,12)})
    refs.ContentArea = contentArea

    local window = { _dropdownInstances = {}, _dropdownStates = {}, _activeTabIndex = 1, _savedState = { active = nil, dropdownSelections = {} } }
    window._config = cfg
    window.Root = screenGui
    window.Main = Frame
    window.Flags = {}

    local pages = {}
    local tabList = {}
    local darkTabText = darkenColor(cfg.Theme.Text, 0.18)

    local tabScroll = new("ScrollingFrame", {Parent = TabsHolder, Size = UDim2.new(1,0,1,0), Position = UDim2.new(0,0,0,0), BackgroundTransparency = 1, ScrollBarThickness = 0, ScrollBarImageTransparency = 1, CanvasSize = UDim2.new(0,0,0,0), AutomaticCanvasSize = Enum.AutomaticSize.X, HorizontalScrollBarInset = Enum.ScrollBarInset.Always})
    new("UIListLayout", {Parent = tabScroll, FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0,8), SortOrder = Enum.SortOrder.LayoutOrder}).HorizontalAlignment = Enum.HorizontalAlignment.Left

    local function clampCanvas()
        pcall(function()
            local maxX = math.max(tabScroll.AbsoluteCanvasSize.X - tabScroll.AbsoluteSize.X, 0)
            local cur = tabScroll.CanvasPosition.X
            if cur < 0 then tabScroll.CanvasPosition = Vector2.new(0,0) end
            if cur > maxX then tabScroll.CanvasPosition = Vector2.new(maxX,0) end
        end)
    end

    local function tweenCanvasTo(targetX, duration)
        duration = duration or 0.28
        local startX = tabScroll.CanvasPosition.X
        local elapsed = 0
        local conn
        conn = RunService.RenderStepped:Connect(function(dt)
            elapsed = math.min(elapsed + dt, duration)
            local alpha = (duration == 0 and 1) or (elapsed / duration)
            alpha = 1 - (1 - alpha) * (1 - alpha)
            local newX = startX + (targetX - startX) * alpha
            tabScroll.CanvasPosition = Vector2.new(math.floor(newX + 0.5), 0)
            if elapsed >= duration then
                if conn then conn:Disconnect() end
            end
        end)
        addConn(conn)
    end

    local function updateTabsLayout()
        local count = #tabList
        local avail = math.max(tabScroll.AbsoluteSize.X, cfg.Width)
        if count == 0 then return end
        local fixedSlots = 4
        local padding = 8
        local totalPaddingFor4 = padding * (fixedSlots + 1)
        local slotWidth = math.floor((avail - totalPaddingFor4) / fixedSlots)
        slotWidth = clampVal(slotWidth, 64, 160)
        for _, t in ipairs(tabList) do
            if t and t.Button then
                t.Button.Size = UDim2.new(0, slotWidth, 0, 32)
            end
        end
        local totalWidth = padding * (#tabList + 1) + #tabList * slotWidth
        tabScroll.AutomaticCanvasSize = Enum.AutomaticSize.None
        tabScroll.CanvasSize = UDim2.new(0, math.max(totalWidth, avail), 0, 0)
        if #tabList <= 3 then tabScroll.CanvasPosition = Vector2.new(0,0) end
        clampCanvas()
    end

    addConn(tabScroll:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() updateTabsLayout() end))
    addConn(tabScroll:GetPropertyChangedSignal("AbsoluteCanvasSize"):Connect(function() clampCanvas() end))
    task.defer(function() pcall(updateTabsLayout) end)

    do
        local dragging = false
        local dragStart = Vector2.new()
        local startCanvasX = 0
        local conn1 = tabScroll.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                dragStart = input.Position
                startCanvasX = tabScroll.CanvasPosition.X
                local endedConn
                endedConn = input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragging = false
                        if endedConn then endedConn:Disconnect() end
                    end
                end)
                addConn(endedConn)
            end
        end)
        addConn(conn1)
        local conn2 = UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                local delta = input.Position - dragStart
                local maxX = math.max(tabScroll.AbsoluteCanvasSize.X - tabScroll.AbsoluteSize.X, 0)
                local newX = clampVal(startCanvasX - delta.X, 0, maxX)
                tabScroll.CanvasPosition = Vector2.new(newX, 0)
            end
        end)
        addConn(conn2)
    end

    local preventWindowDrag = false

    local function registerFlag(name, meta)
        if not name or name == "" then return end
        window.Flags[name] = meta or {}
    end

    local function createTab(name)
        local idx = #tabList + 1
        local btn = new("TextButton", {
            Parent = tabScroll,
            Text = name,
            Size = UDim2.new(0,96,0,32),
            BackgroundColor3 = cfg.Theme.TabBg,
            TextColor3 = darkenColor(cfg.Theme.Text, 0.18),
            Font = Enum.Font.SourceSansBold,
            TextSize = 16,
            TextXAlignment = Enum.TextXAlignment.Center,
            TextYAlignment = Enum.TextYAlignment.Center,
            AutoButtonColor = false,
            BorderSizePixel = 0
        })
        new("UICorner", {Parent = btn, CornerRadius = UDim.new(0,10)})
        btn.TextStrokeTransparency = 1
        addHoverBounce(btn)

        local content = new("ScrollingFrame", {
            Parent = contentArea,
            Size = UDim2.new(1,0,1,0),
            Position = UDim2.new(0,0,0,6),
            BackgroundTransparency = 1,
            ScrollBarThickness = 0,
            ScrollBarImageTransparency = 1,
            CanvasSize = UDim2.new(0,0,0,0),
            AutomaticCanvasSize = Enum.AutomaticSize.None,
            VerticalScrollBarInset = Enum.ScrollBarInset.Always,
        })
        content.Visible = false

        local contentLayout = new("UIListLayout", {Parent = content, FillDirection = Enum.FillDirection.Vertical, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0,10)})
        new("UIPadding", {Parent = content, PaddingLeft = UDim.new(0,6), PaddingRight = UDim.new(0,6), PaddingTop = UDim.new(0,6)})

        local pendingTextNodes = {}
        local function hideTextNodesIn(obj)
            for _, d in ipairs(obj:GetDescendants()) do
                if d:IsA("TextLabel") or d:IsA("TextButton") or d:IsA("TextBox") then
                    local cur = 0
                    pcall(function() cur = d.TextTransparency end)
                    if d.SetAttribute then d:SetAttribute("hw_orig_text_transparency", cur) end
                    d.TextTransparency = 1
                    table.insert(pendingTextNodes, d)
                end
            end
        end

        local function revealPendingText()
            if #pendingTextNodes == 0 then return end
            for i = #pendingTextNodes, 1, -1 do
                local node = pendingTextNodes[i]
                if node and node.Parent then
                    pcall(function()
                        TweenService:Create(node, TweenInfo.new(0.18, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {TextTransparency = 0}):Play()
                    end)
                end
                pendingTextNodes[i] = nil
            end
            pendingTextNodes = {}
        end

        local function updateContentCanvas()
            local h = contentLayout.AbsoluteContentSize.Y + 6
            content.CanvasSize = UDim2.new(0, 0, 0, h)
        end

        local function waitForLayoutStability()
            local maxFrames = 45
            local stableNeeded = 2
            local stable = 0
            local prev = -1
            for i = 1, maxFrames do
                local frameHeight = (Frame and Frame.AbsoluteSize and Frame.AbsoluteSize.Y) or 0
                local layoutH = contentLayout.AbsoluteContentSize.Y or 0
                if layoutH > 0 and frameHeight > 8 then
                    if layoutH == prev then
                        stable = stable + 1
                    else
                        stable = 0
                    end
                    prev = layoutH
                else
                    prev = layoutH
                    stable = 0
                end
                if layoutH > 0 and stable >= stableNeeded then
                    break
                end
                RunService.Heartbeat:Wait()
            end
            pcall(updateContentCanvas)
            pcall(revealPendingText)
        end

        addConn(contentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() pcall(updateContentCanvas) end))

        local tab = {Name = name, Button = btn, Content = content, Index = idx, _showed = function() return content.Visible end, _waiter = waitForLayoutStability, _reveal = revealPendingText}

        addConn(btn.MouseEnter:Connect(function() if UserInputService.MouseEnabled then tween(btn, {BackgroundColor3 = brightenColor(cfg.Theme.TabBg, 0.06)}, 0.12) end end))
        addConn(btn.MouseLeave:Connect(function() if btn ~= nil then
            if btn.TextColor3 ~= Color3.fromRGB(255,255,255) then
                tween(btn, {BackgroundColor3 = cfg.Theme.TabBg}, 0.12)
            else
                tween(btn, {BackgroundColor3 = brightenColor(cfg.Theme.TabBg, 0.08)}, 0.12)
            end
        end end))

        function tab:CreateButton(opts)
            opts = opts or {}
            local name = opts.Name or "Button"
            local cb = opts.Callback
            local row = new("Frame", {Parent = content, Size = UDim2.new(1,0,0,36), BackgroundTransparency = 1})
            local lbl = new("TextLabel", {
                Parent = row,
                Text = name,
                Size = UDim2.new(0.65, -8, 1, 0),
                Position = UDim2.new(0,8,0,0),
                BackgroundTransparency = 1,
                TextColor3 = cfg.Theme.Text,
                Font = Enum.Font.SourceSansBold,
                TextSize = 17,
                TextXAlignment = Enum.TextXAlignment.Left
            })
            local b = new("TextButton", {
                Parent = row,
                Size = UDim2.new(0.34, -8, 1, 0),
                Position = UDim2.new(0.66, 4, 0, 0),
                BackgroundColor3 = cfg.Theme.Btn,
                TextColor3 = cfg.Theme.Text,
                Text = "Button",
                Font = Enum.Font.SourceSansBold,
                TextSize = 17,
                AutoButtonColor = false,
                TextXAlignment = Enum.TextXAlignment.Center,
                TextYAlignment = Enum.TextYAlignment.Center,
                TextScaled = false
            })
            new("UICorner", {Parent = b, CornerRadius = UDim.new(0,8)})
            addHoverBounce(b)
            addHoverBounce(lbl)
            addConn(b.MouseButton1Click:Connect(function()
                if cb then pcall(cb) end
                tween(b, {BackgroundColor3 = brightenColor(cfg.Theme.Btn, 0.12)}, 0.06)
                task.wait(0.06)
                tween(b, {BackgroundColor3 = cfg.Theme.Btn}, 0.12)
            end))
            pcall(hideTextNodesIn, row)
            task.defer(function() pcall(updateContentCanvas) end)
            return b
        end

        function tab:CreateToggle(opts)
            opts = opts or {}
            local name = opts.Name or ""
            local flag = opts.Flag
            local current = opts.CurrentValue or opts.Current or false
            local cb = opts.Callback

            local frame = new("Frame", {Parent = content, Size = UDim2.new(1,0,0,30), BackgroundTransparency = 1})
            new("TextLabel", {Parent = frame, Text = name, Size = UDim2.new(0.65, -8, 1, 0), Position = UDim2.new(0,8,0,0), BackgroundTransparency = 1, TextColor3 = cfg.Theme.Text, Font = Enum.Font.SourceSansBold, TextSize = 17, TextXAlignment = Enum.TextXAlignment.Left})
            local toggleWidth = 54
            local toggleHeight = 24
            local pad = 6
            local toggleBg = new("Frame", {Parent = frame, Size = UDim2.new(0, toggleWidth,0, toggleHeight), Position = UDim2.new(1, - (toggleWidth + pad), 0.5, -toggleHeight/2), BackgroundColor3 = cfg.Theme.ToggleBg, BorderSizePixel = 0})
            new("UICorner", {Parent = toggleBg, CornerRadius = UDim.new(0,12)})
            local dotOffColor = darkenColor(Color3.fromRGB(200,200,200), 0.16)
            local dotOnColor  = brightenColor(cfg.Theme.Accent, 0.0)
            local dotSize = 18
            local margin = math.floor(dotSize/2) + 4
            local dot = new("Frame", {Parent = toggleBg, Size = UDim2.new(0, dotSize,0, dotSize), BackgroundColor3 = dotOffColor})
            new("UICorner", {Parent = dot, CornerRadius = UDim.new(1,0)})
            dot.AnchorPoint = Vector2.new(0.5,0.5)
            dot.Position = UDim2.new(0, margin, 0.5, 0)

            local state = current and true or false
            local function setState(s, silent)
                state = s
                if s then
                    tween(dot, {Position = UDim2.new(1, -margin, 0.5, 0), BackgroundColor3 = dotOnColor}, 0.14, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
                else
                    tween(dot, {Position = UDim2.new(0, margin, 0.5, 0), BackgroundColor3 = dotOffColor}, 0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
                end
                if cb and not silent then pcall(cb, state) end
            end

            local clickBtn = new("TextButton", {Parent = toggleBg, Size = UDim2.new(1,0,1,0), Position = UDim2.new(0,0,0,0), BackgroundTransparency = 1, AutoButtonColor = false, Text = ""})
            new("UICorner", {Parent = clickBtn, CornerRadius = UDim.new(0,12)})
            addConn(clickBtn.MouseButton1Click:Connect(function() setState(not state) end))
            setState(state, true)
            pcall(hideTextNodesIn, frame)
            task.defer(function() pcall(updateContentCanvas) end)

            if flag and type(flag) == "string" then
                registerFlag(flag, { Type = "Toggle", Get = function() return state end, Set = function(v) setState((v and true) or false, true) end, UI = frame })
            end

            return { UI = frame, Get = function() return state end, Set = function(v) setState((v and true) or false) end, Flag = flag }
        end

        function tab:CreateLabel(text)
            local l = new("TextLabel", {Parent = content, Size = UDim2.new(1,0,0,20), Text = text or "", BackgroundTransparency = 1, TextColor3 = cfg.Theme.Text, Font = Enum.Font.SourceSansBold, TextSize = 17, TextXAlignment = Enum.TextXAlignment.Left})
            pcall(hideTextNodesIn, l)
            task.defer(function() pcall(updateContentCanvas) end)
            return l
        end

        function tab:CreateSection(title)
            local sec = new("Frame", {Parent = content, Size = UDim2.new(1,0,0,40), BackgroundTransparency = 1})
            local bg = new("Frame", {Parent = sec, Size = UDim2.new(1,0,0,32), Position = UDim2.new(0,0,0,4), BackgroundColor3 = cfg.Theme.TabBg, BorderSizePixel = 0})
            new("UICorner", {Parent = bg, CornerRadius = UDim.new(0,8)})
            new("TextLabel", {Parent = bg, Text = title, Size = UDim2.new(1,-12,1,0), Position = UDim2.new(0,8,0,0), BackgroundTransparency = 1, Font = Enum.Font.SourceSansBold, TextSize = 17, TextColor3 = cfg.Theme.Text, TextXAlignment = Enum.TextXAlignment.Left})
            pcall(hideTextNodesIn, sec)
            task.defer(function() pcall(updateContentCanvas) end)
            return sec
        end

        function tab:CreateDropdown(opts)
            opts = opts or {}
            local name = opts.Name or ""
            local options = opts.Options or opts.Choices or {}
            local multiple = opts.MultipleOptions or false
            local callback = opts.Callback
            local flag = opts.Flag

            local frame = new("Frame", {Parent = content, Size = UDim2.new(1,0,0,36), BackgroundTransparency = 1})
            new("TextLabel", {Parent = frame, Text = name, Size = UDim2.new(0.65, -8, 1, 0), Position = UDim2.new(0,8,0,0), BackgroundTransparency = 1, TextColor3 = cfg.Theme.Text, Font = Enum.Font.SourceSansBold, TextSize = 17, TextXAlignment = Enum.TextXAlignment.Left})
            local btnWidthScale = 0.36
            local btn = new("TextButton", {Parent = frame, Size = UDim2.new(btnWidthScale, -8, 1, 0), Position = UDim2.new(1 - btnWidthScale, 4, 0, 0), BackgroundColor3 = cfg.Theme.Btn, Text = "Select", Font = Enum.Font.SourceSansBold, TextSize = 17, TextColor3 = cfg.Theme.Text, AutoButtonColor = false, TextScaled = false, TextXAlignment = Enum.TextXAlignment.Center, TextYAlignment = Enum.TextYAlignment.Center})
            new("UICorner", {Parent = btn, CornerRadius = UDim.new(0,8)})
            addHoverBounce(btn)

            local panel, escConn, followConn, contentFrame
            local instance
            local uid = HttpService:GenerateGUID(false)
            local selectedIndex = nil
            local selectedIndices = {} -- for multiple selections
            local cachedSelectedValues = nil

            -- restore if saved
            if window and window._savedState and window._savedState.dropdownSelections and window._savedState.dropdownSelections[uid] then
                local saved = window._savedState.dropdownSelections[uid]
                if type(saved) == "number" then selectedIndex = saved; selectedIndices = { [saved] = true }
                elseif type(saved) == "table" then selectedIndices = {}; for _,i in ipairs(saved) do selectedIndices[i] = true end end
            end

            local function closePanel()
                if followConn then pcall(function() followConn:Disconnect() end) end
                followConn = nil
                if escConn then pcall(function() escConn:Disconnect() end) end
                escConn = nil
                if panel and panel.Parent then
                    pcall(function()
                        -- Immediately hide children to avoid "flash" when closing
                        for _, child in ipairs(panel:GetDescendants()) do
                            if child:IsA("TextLabel") or child:IsA("TextButton") or child:IsA("TextBox") then
                                pcall(function() child.TextTransparency = 1 end)
                            end
                            if child:IsA("Frame") or child:IsA("ImageLabel") or child:IsA("ImageButton") then
                                pcall(function() if child.BackgroundTransparency ~= nil then child.BackgroundTransparency = 1 end end)
                            end
                        end
                        -- fade panel background quickly
                        tween(panel, {BackgroundTransparency = 1}, 0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
                        task.wait(0.12)
                        panel:Destroy()
                    end)
                end
                panel = nil
                if instance and window and window._dropdownStates then
                    window._dropdownStates[uid] = false
                end
            end

            local function updatePanelPos()
                if not panel or not panel.Parent then return end
                pcall(function()
                    local absX = Frame.AbsolutePosition.X
                    local absY = Frame.AbsolutePosition.Y
                    local screenSize = Workspace.CurrentCamera and Workspace.CurrentCamera.ViewportSize or Vector2.new(1920,1080)
                    local maxVisible = 6
                    local itemH = 36
                    local headerH = 30
                    local panelH = math.min(headerH + #options*itemH + 8, headerH + maxVisible*itemH + 8)
                    local panelW = 260
                    local x = absX + Frame.AbsoluteSize.X + 8
                    local y = absY + (Frame.AbsoluteSize.Y/2) - (panelH/2)
                    x = math.clamp(x, 8, screenSize.X - panelW - 8)
                    y = math.clamp(y, 8, screenSize.Y - panelH - 8)
                    panel.Position = UDim2.new(0, x, 0, y)
                end)
            end

            local function showPanel()
                if panel and panel.Parent then
                    closePanel()
                    return
                end

                if window and window._dropdownInstances then
                    for _, other in ipairs(window._dropdownInstances) do
                        if other ~= instance and other.IsOpen and other.IsOpen() then
                            pcall(function() other.Close() end)
                        end
                    end
                end

                task.wait(0.12)

                local maxVisible = 6
                local itemH = 36
                local headerH = 30
                local panelH = math.min(headerH + #options*itemH + 8, headerH + maxVisible*itemH + 8)
                panel = new("Frame", {Parent = screenGui, Size = UDim2.new(0,260,0, panelH), BackgroundColor3 = cfg.Theme.Main, ZIndex = 220, BackgroundTransparency = 1})
                new("UICorner", {Parent = panel, CornerRadius = UDim.new(0,8)})
                local panelStroke = new("UIStroke", {Parent = panel})
                panelStroke.Thickness = 2
                panelStroke.Transparency = 0.8
                panelStroke.Color = Color3.fromRGB(255,255,255)

                local header = new("TextLabel", {Parent = panel, Size = UDim2.new(1,-12,0,headerH-4), Position = UDim2.new(0,6,0,6), BackgroundTransparency = 1, Font = Enum.Font.SourceSansBold, TextSize = 17, Text = name or "", TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Center, TextColor3 = cfg.Theme.Text, ZIndex = 221})

                contentFrame = new("ScrollingFrame", {Parent = panel, Size = UDim2.new(1,-12,0,panelH - headerH - 10), Position = UDim2.new(0,6,0, headerH), BackgroundTransparency = 1, ScrollBarThickness = 0, CanvasSize = UDim2.new(0,0,0, #options * itemH), VerticalScrollBarInset = Enum.ScrollBarInset.Always})
                contentFrame.AutomaticCanvasSize = Enum.AutomaticSize.None
                contentFrame.CanvasPosition = Vector2.new(0,0)

                -- build rows and restore selected state
                for i, opt in ipairs(options) do
                    local row = new("TextButton", {Parent = contentFrame, Size = UDim2.new(1,0,0,itemH-6), Position = UDim2.new(0,0,0, (i-1)*itemH), BackgroundColor3 = cfg.Theme.TabBg, Text = tostring(opt), Font = Enum.Font.SourceSansBold, TextSize = 17, TextColor3 = cfg.Theme.Text, AutoButtonColor = false, ZIndex = 222})
                    new("UICorner", {Parent = row, CornerRadius = UDim.new(0,6)})
                    row.TextStrokeTransparency = 1
                    addHoverBounce(row)

                    -- apply saved selection highlight if exists
                    if multiple then
                        if selectedIndices[i] then
                            row.BackgroundColor3 = brightenColor(cfg.Theme.TabBg, 0.14)
                            row.TextColor3 = Color3.fromRGB(255,255,255)
                        end
                    else
                        if selectedIndex == i then
                            row.BackgroundColor3 = brightenColor(cfg.Theme.TabBg, 0.14)
                            row.TextColor3 = Color3.fromRGB(255,255,255)
                        end
                    end

                    row.MouseEnter:Connect(function()
                        pcall(function()
                            if multiple then
                                if not selectedIndices[i] then tween(row, {BackgroundColor3 = brightenColor(cfg.Theme.TabBg, 0.06)}, 0.10) end
                            else
                                if selectedIndex ~= i then tween(row, {BackgroundColor3 = brightenColor(cfg.Theme.TabBg, 0.06)}, 0.10) end
                            end
                        end)
                    end)
                    row.MouseLeave:Connect(function()
                        pcall(function()
                            if multiple then
                                if selectedIndices[i] then
                                    tween(row, {BackgroundColor3 = brightenColor(cfg.Theme.TabBg, 0.12)}, 0.10)
                                else
                                    tween(row, {BackgroundColor3 = cfg.Theme.TabBg}, 0.10)
                                end
                            else
                                if selectedIndex == i then
                                    tween(row, {BackgroundColor3 = brightenColor(cfg.Theme.TabBg, 0.12)}, 0.10)
                                else
                                    tween(row, {BackgroundColor3 = cfg.Theme.TabBg}, 0.10)
                                end
                            end
                        end)
                    end)

                    row.MouseButton1Click:Connect(function()
                        if multiple then
                            -- toggle selection
                            if selectedIndices[i] then
                                selectedIndices[i] = nil
                                row.BackgroundColor3 = cfg.Theme.TabBg
                                row.TextColor3 = cfg.Theme.Text
                            else
                                selectedIndices[i] = true
                                row.BackgroundColor3 = brightenColor(cfg.Theme.TabBg, 0.14)
                                row.TextColor3 = Color3.fromRGB(255,255,255)
                            end
                            -- update saved state
                            local selList = {}
                            for k,_ in pairs(selectedIndices) do table.insert(selList, k) end
                            window._savedState.dropdownSelections[uid] = selList
                            -- set btn text
                            local vals = {}
                            for k,_ in pairs(selectedIndices) do table.insert(vals, tostring(options[k])) end
                            if #vals == 0 then btn.Text = "Select" else btn.Text = tostring(#vals) .. " selected" end
                            if callback then
                                local out = {}
                                for k,_ in pairs(selectedIndices) do table.insert(out, options[k]) end
                                pcall(callback, out)
                            end
                            if flag and window.Flags[flag] and window.Flags[flag].Set then window.Flags[flag].Set(selectedIndices) end
                        else
                            if selectedIndex == i then
                                selectedIndex = nil
                                row.BackgroundColor3 = cfg.Theme.TabBg
                                row.TextColor3 = cfg.Theme.Text
                                window._savedState.dropdownSelections[uid] = nil
                                if callback then pcall(callback, nil) end
                                btn.Text = "Select"
                                if flag and window.Flags[flag] and window.Flags[flag].Set then window.Flags[flag].Set(nil) end
                                return
                            end
                            -- clear others
                            for _, child in ipairs(contentFrame:GetChildren()) do
                                if child:IsA("TextButton") then
                                    pcall(function() child.BackgroundColor3 = cfg.Theme.TabBg; child.TextColor3 = cfg.Theme.Text end)
                                end
                            end
                            selectedIndex = i
                            row.BackgroundColor3 = brightenColor(cfg.Theme.TabBg, 0.14)
                            row.TextColor3 = Color3.fromRGB(255,255,255)
                            btn.Text = tostring(opt)
                            window._savedState.dropdownSelections[uid] = i
                            if callback then pcall(callback, opt) end
                            if flag and window.Flags[flag] and window.Flags[flag].Set then window.Flags[flag].Set(opt) end
                        end
                    end)
                end

                updatePanelPos()
                pcall(function()
                    local curPos = panel.Position
                    panel.Position = UDim2.new(curPos.X.Scale, curPos.X.Offset, curPos.Y.Scale, curPos.Y.Offset - 8)
                end)

                panel.BackgroundTransparency = 1
                header.TextTransparency = 1
                for _, child in ipairs(contentFrame:GetDescendants()) do
                    if child:IsA("TextLabel") or child:IsA("TextButton") or child:IsA("TextBox") then
                        pcall(function() child.TextTransparency = 1 end)
                    end
                end

                -- animate open with text fade-in
                tween(panel, {BackgroundTransparency = 0}, 0.18)
                tween(panel, {Position = UDim2.new(panel.Position.X.Scale, panel.Position.X.Offset, panel.Position.Y.Scale, panel.Position.Y.Offset + 8)}, 0.18)
                task.delay(0.06, function()
                    pcall(function()
                        for _, child in ipairs(panel:GetDescendants()) do
                            if child:IsA("TextLabel") or child:IsA("TextButton") or child:IsA("TextBox") then
                                TweenService:Create(child, TweenInfo.new(0.18, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {TextTransparency = 0}):Play()
                            end
                        end
                    end)
                end)

                -- follow viewport/ camera changes
                if not followConn then
                    followConn = RunService.Heartbeat:Connect(function()
                        pcall(updatePanelPos)
                    end)
                end
            end

            local opening = false
            local openConn = btn.MouseButton1Click:Connect(function()
                if opening then return end
                opening = true
                pcall(showPanel)
                task.wait(0.02)
                opening = false
            end)
            addConn(openConn)

            instance = { UI = frame, Set = function(v)
                if type(v) == "table" then
                    -- if table, join to string
                    if #v == 0 then btn.Text = "Select"
                    else btn.Text = tostring(#v) .. " selected" end
                else
                    btn.Text = tostring(v)
                end
            end, Open = showPanel, Close = closePanel, IsOpen = function() return (panel ~= nil) end, Button = btn, uid = uid, Flag = flag }

            if flag and type(flag) == "string" then
                registerFlag(flag, { Type = "Dropdown", Get = function() return btn.Text end, Set = function(v) btn.Text = tostring(v) end, UI = frame })
            end

            if window then
                window._dropdownInstances = window._dropdownInstances or {}
                table.insert(window._dropdownInstances, instance)
                window._dropdownStates = window._dropdownStates or {}
                window._dropdownStates[uid] = false
                window._savedState = window._savedState or {}
                window._savedState.dropdownSelections = window._savedState.dropdownSelections or {}
            end

            pcall(hideTextNodesIn, frame)
            task.defer(function() pcall(updateContentCanvas) end)
            return instance
        end

        function tab:CreateKeybind(opts)
            opts = opts or {}
            local label = opts.Name or "Keybind"
            local defaultKey = opts.Default or opts.CurrentValue or opts.Key
            local cb = opts.Callback
            local flag = opts.Flag

            local row = new("Frame", {Parent = content, Size = UDim2.new(1,0,0,36), BackgroundTransparency = 1})
            new("TextLabel", {Parent = row, Text = label, Size = UDim2.new(0.65, -8, 1, 0), Position = UDim2.new(0,8,0,0), BackgroundTransparency = 1, TextColor3 = cfg.Theme.Text, Font = Enum.Font.SourceSansBold, TextSize = 17, TextXAlignment = Enum.TextXAlignment.Left})
            local btn = new("TextButton", {Parent = row, Size = UDim2.new(0.34, -8, 1, 0), Position = UDim2.new(0.66, 4, 0, 0), BackgroundColor3 = cfg.Theme.Btn, TextColor3 = cfg.Theme.Text, Text = "", Font = Enum.Font.SourceSansBold, TextSize = 17, AutoButtonColor=false, TextXAlignment = Enum.TextXAlignment.Center, TextYAlignment = Enum.TextYAlignment.Center})
            new("UICorner", {Parent = btn, CornerRadius = UDim.new(0,8)})
            addHoverBounce(btn)

            local function displayForKey(k)
                if not k then
                    btn.Text = "..."
                    return
                end
                if typeof(k) == "EnumItem" and k.EnumType == Enum.KeyCode then
                    btn.Text = k.Name
                elseif type(k) == "string" then
                    btn.Text = k
                else
                    local ok, s = pcall(function() return tostring(k) end)
                    btn.Text = (ok and s) and s or "..."
                end
            end

            local boundKey = nil
            if defaultKey then
                if typeof(defaultKey) == "EnumItem" and defaultKey.EnumType == Enum.KeyCode then
                    boundKey = defaultKey
                elseif type(defaultKey) == "string" then
                    boundKey = defaultKey
                end
            end
            displayForKey(boundKey)

            local listening = false
            local inputConn

            local function stopListening()
                if inputConn then
                    pcall(function() inputConn:Disconnect() end)
                    inputConn = nil
                end
                listening = false
                tween(btn, {BackgroundColor3 = cfg.Theme.Btn}, 0.08)
                displayForKey(boundKey)
            end

            local function startListening()
                if listening then return end
                listening = true
                btn.Text = "..."
                tween(btn, {BackgroundColor3 = brightenColor(cfg.Theme.Btn, 0.12)}, 0.06)

                -- Only keyboard input accepted; ignore mouse and other types (fix requested)
                inputConn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
                    if gameProcessed then return end
                    if input.UserInputType ~= Enum.UserInputType.Keyboard then
                        -- ignore non-keyboard
                        return
                    end
                    if input.KeyCode == Enum.KeyCode.Escape then
                        -- cancel listening but do not clear binding
                        stopListening()
                        return
                    end

                    -- accept only keyboard keys
                    boundKey = input.KeyCode
                    pcall(cb, boundKey)
                    stopListening()
                    return
                end)
            end

            addConn(btn.MouseButton1Click:Connect(function()
                if not listening then startListening() else stopListening() end
            end))

            -- Right-click clears binding (explicit)
            addConn(btn.MouseButton2Click:Connect(function()
                boundKey = nil
                displayForKey(boundKey)
                pcall(cb, nil)
            end))

            if flag and type(flag) == "string" then
                registerFlag(flag, { Type = "Keybind", Get = function() return boundKey end, Set = function(v) boundKey = v; displayForKey(boundKey) end, UI = row })
            end

            pcall(hideTextNodesIn, row)
            task.defer(function() pcall(updateContentCanvas) end)
            return { UI = row, Set = function(v) if v == nil then boundKey = nil elseif typeof(v) == "EnumItem" and v.EnumType == Enum.KeyCode then boundKey = v elseif type(v) == "string" then boundKey = v else boundKey = v end displayForKey(boundKey) end, Get = function() return boundKey end, Flag = flag }
        end

        function tab:CreateSlider(opts)
            opts = opts or {}
            local label = opts.Name or ""
            local minVal = tonumber((opts.Range and opts.Range[1]) or opts.Min) or opts.MinVal or 0
            local maxVal = tonumber((opts.Range and opts.Range[2]) or opts.Max) or opts.MaxVal or 100
            local default = (opts.CurrentValue ~= nil) and opts.CurrentValue or (opts.Default or minVal)
            local cb = opts.Callback
            local flag = opts.Flag

            minVal = minVal or 0; maxVal = maxVal or 100; default = default or minVal
            local row = new("Frame", {Parent = content, Size = UDim2.new(1,0,0,36), BackgroundTransparency = 1})

            local leftArea = new("Frame", {Parent = row, Size = UDim2.new(0.65, -8, 1, 0), Position = UDim2.new(0,8,0,0), BackgroundTransparency = 1})
            local trackHeight = 28
            local track = new("Frame", {Parent = leftArea, Size = UDim2.new(1,0,0,trackHeight), Position = UDim2.new(0,0,0,4), BackgroundColor3 = cfg.Theme.TabBg, BorderSizePixel = 0})
            local cornerRadius = 6
            new("UICorner", {Parent = track, CornerRadius = UDim.new(0, cornerRadius)})
            track.ClipsDescendants = true

            local fill = new("Frame", {Parent = track, Size = UDim2.new(0,0,1,0), Position = UDim2.new(0,0,0,0), BackgroundColor3 = Color3.new(1,1,1), BorderSizePixel = 0, ZIndex = 1})
            new("UICorner", {Parent = fill, CornerRadius = UDim.new(0, cornerRadius)})

            local textPadding = 8
            local leftLabel = new("TextLabel", {
                Parent = track,
                Size = UDim2.new(1, -textPadding*2, 1, 0),
                Position = UDim2.new(0, textPadding, 0, 0),
                BackgroundTransparency = 1,
                Font = Enum.Font.SourceSansBold,
                TextSize = 17,
                TextColor3 = cfg.Theme.Text,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Center,
                ZIndex = 3,
                RichText = true,
            })
            leftLabel.Text = label

            local rightBoxScale = 0.30
            local rightBox = new("Frame", {Parent = row, Size = UDim2.new(rightBoxScale, -8, 0, trackHeight), Position = UDim2.new(1 - rightBoxScale, 4, 0.5, -trackHeight/2), BackgroundColor3 = cfg.Theme.TabBg, BorderSizePixel = 0})
            new("UICorner", {Parent = rightBox, CornerRadius = UDim.new(0,8)})
            local valueLabel = new("TextLabel", {Parent = rightBox, Size = UDim2.new(1, -12, 1, 0), Position = UDim2.new(0,6,0,0), BackgroundTransparency = 1, Font = leftLabel.Font, TextSize = leftLabel.TextSize, TextColor3 = cfg.Theme.Text, TextXAlignment = Enum.TextXAlignment.Center, TextYAlignment = Enum.TextYAlignment.Center})
            valueLabel.Text = tostring(default)

            -- cache text width so dragging is cheaper
            local cachedTextWidth = 0
            local function computeCachedTextWidth()
                local ok, ts = pcall(function() return TextService:GetTextSize(tostring(leftLabel.Text or ""), leftLabel.TextSize, leftLabel.Font, Vector2.new(9999,9999)) end)
                if ok and ts then cachedTextWidth = ts.X else cachedTextWidth = 0 end
            end
            computeCachedTextWidth()
            leftLabel:GetPropertyChangedSignal("Text"):Connect(function() computeCachedTextWidth() end)
            track:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() end)

            local function updateLeftLabelTextColor()
                pcall(function()
                    if not leftLabel or not leftLabel.Parent or not track or track.AbsoluteSize.X <= 0 then return end
                    local leftPad = textPadding
                    local fillWidth = fill.AbsoluteSize.X or (fill.Size.X.Scale * math.max(1, track.AbsoluteSize.X))
                    if fillWidth >= (leftPad + cachedTextWidth) then
                        pcall(function() leftLabel.TextColor3 = cfg.Theme.Main end)
                    else
                        pcall(function() leftLabel.TextColor3 = cfg.Theme.Text end)
                    end
                end)
            end

            local function setFromPercent(p, skipTween)
                p = clampVal(p, 0, 1)
                local value = minVal + (maxVal - minVal) * p
                local displayValue = (math.floor(value*100 + 0.5)/100)
                if not skipTween then tween(fill, {Size = UDim2.new(p,0,1,0)}, 0.12) else fill.Size = UDim2.new(p,0,1,0) end
                pcall(function() valueLabel.Text = tostring(displayValue) end)
                if cb then pcall(cb, value) end
                if flag and window.Flags[flag] and window.Flags[flag].Set then pcall(window.Flags[flag].Set, value) end
                -- update left label color shortly after layout (deferred)
                task.defer(function() RunService.Heartbeat:Wait(); updateLeftLabelTextColor() end)
            end

            local defaultPct = 0
            local range = maxVal - minVal
            if range == 0 then defaultPct = 0 else defaultPct = (default - minVal) / range end
            task.defer(function() RunService.Heartbeat:Wait(); setFromPercent(defaultPct, true) end)

            local dragging = false
            local inputChangedConn

            local function onInputBegan(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = true
                    preventWindowDrag = true

                    local pos = nil
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        pos = UserInputService:GetMouseLocation()
                    else
                        pos = input.Position
                    end
                    if pos then
                        local absX = pos.X
                        local left = track.AbsolutePosition.X
                        local width = math.max(1, track.AbsoluteSize.X)
                        local pct = (absX - left) / width
                        setFromPercent(pct, false)
                    end

                    inputChangedConn = UserInputService.InputChanged:Connect(function(inp)
                        if dragging and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
                            local absX = inp.Position.X
                            local left = track.AbsolutePosition.X
                            local width = math.max(1, track.AbsoluteSize.X)
                            local pct = (absX - left) / width
                            setFromPercent(pct, false)
                        end
                    end)

                    local endedConn
                    endedConn = input.Changed:Connect(function()
                        if input.UserInputState == Enum.UserInputState.End then
                            dragging = false
                            preventWindowDrag = false
                            if inputChangedConn then pcall(function() inputChangedConn:Disconnect() end) inputChangedConn = nil end
                            if endedConn then pcall(function() endedConn:Disconnect() end) end
                        end
                    end)
                end
            end

            addConn(track.InputBegan:Connect(onInputBegan))

            if flag and type(flag) == "string" then
                registerFlag(flag, { Type = "Slider", Get = function()
                    local curPct = fill.Size.X.Scale
                    return minVal + (maxVal - minVal) * curPct
                end, Set = function(v)
                    local r = maxVal - minVal
                    if r == 0 then setFromPercent(0, true) else setFromPercent((v - minVal) / r, false) end
                end, UI = row })
            end

            pcall(hideTextNodesIn, row)
            task.defer(function() pcall(updateContentCanvas) end)

            return {
                UI = row,
                Set = function(v)
                    local r = maxVal - minVal
                    if r == 0 then setFromPercent(0, false) else setFromPercent((v - minVal) / r, false) end
                end,
                Get = function()
                    local curPct = fill.Size.X.Scale
                    return minVal + (maxVal - minVal) * curPct
                end,
                Flag = flag
            }
        end

        table.insert(tabList, tab)
        updateTabsLayout()

        addConn(btn.MouseButton1Click:Connect(function()
            for _, t in ipairs(tabList) do
                if t and t.Content then
                    t.Content.Visible = false
                end
                if t and t.Button then
                    tween(t.Button, {BackgroundColor3 = cfg.Theme.TabBg}, 0.14)
                    t.Button.TextColor3 = darkTabText
                end
            end

            tab.Content.Visible = true
            tab.Content.Position = UDim2.new(0,0,0,6)
            tab.Content.CanvasPosition = Vector2.new(0,0)
            pcall(function() tab:_waiter() end)
            tween(tab.Content, {Position = UDim2.new(0,0,0,0)}, 0.36, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

            tween(tab.Button, {BackgroundColor3 = brightenColor(cfg.Theme.TabBg, 0.14)}, 0.14)
            tab.Button.TextColor3 = Color3.fromRGB(255,255,255)
            pcall(function() if window then window._activeTabIndex = idx; window._savedState.active = idx end end)
        end))

        if #tabList == 1 then
            tab.Content.Visible = true
            task.spawn(function() pcall(tab._waiter) end)
            tab.Content.Position = UDim2.new(0,0,0,0)
            tween(tab.Button, {BackgroundColor3 = brightenColor(cfg.Theme.TabBg, 0.14)}, 0.12)
            tab.Button.TextColor3 = Color3.fromRGB(255,255,255)
            pcall(function() if window then window._activeTabIndex = 1; window._savedState.active = 1 end end)
        end

        return tab
    end

    local function makeDraggable(gui, handle)
        handle = handle or gui
        pcall(function() handle.Active = true end)
        local dragging, dragInput, dragStart, startPos
        local c1 = handle.InputBegan:Connect(function(input)
            if preventWindowDrag then return end
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                dragStart = input.Position
                startPos = gui.Position
                local endedConn
                endedConn = input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragging = false
                        if endedConn then pcall(function() endedConn:Disconnect() end) end
                    end
                end)
                addConn(endedConn)
            end
        end)
        addConn(c1)
        local c2 = handle.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                dragInput = input
            end
        end)
        addConn(c2)
        local c3 = UserInputService.InputChanged:Connect(function(input)
            if dragging and input == dragInput then
                local delta = input.Position - dragStart
                gui.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            end
        end)
        addConn(c3)
    end

    makeDraggable(Frame)
    makeDraggable(InfoBar)
    makeDraggable(HwanBtn)

    window._dropdownInstances = window._dropdownInstances or {}
    window._dropdownStates = window._dropdownStates or {}
    window._activeTabIndex = window._activeTabIndex or 1
    window._savedState = window._savedState or { active = nil, dropdowns = {}, dropdownSelections = {} }

    local pingSamples = {}
    local maxPingSamples = 30
    local pingTimer = 0
    local pingInterval = 0.25

    -- FPS smoothing
    local fpsDisplay = 60

    local renderConn = RunService.RenderStepped:Connect(function(dt)
        pcall(function()
            if titleGrad and titleGrad.Parent then titleGrad.Rotation = (titleGrad.Rotation + 0.9) % 360 end
            if hwanTopGrad and hwanTopGrad.Parent then hwanTopGrad.Rotation = (hwanTopGrad.Rotation + 1.6) % 360 end
            if hwanBottomGrad and hwanBottomGrad.Parent then hwanBottomGrad.Rotation = (hwanBottomGrad.Rotation + 1.6) % 360 end
        end)

        -- Info updates (time, fps, ping) - smoothed fps
        pcall(function()
            if not refs.InfoText then return end
            local timeStr = os.date("%H:%M:%S")
            local instantFps = 0
            if dt > 0 then instantFps = 1/dt end
            -- lerp display towards instant
            fpsDisplay = fpsDisplay + (instantFps - fpsDisplay) * 0.12
            local fps = math.floor(fpsDisplay + 0.5)

            pingTimer = pingTimer + dt
            local pingMs = 0
            if pingTimer >= pingInterval then
                pingTimer = pingTimer - pingInterval
                local ok, pingValue = pcall(function() return game:GetService("Stats").Network.ServerStatsItem["Data Ping"] end)
                if ok and pingValue and typeof(pingValue.GetValueString) == "function" then
                    local ok2, str = pcall(function() return pingValue:GetValueString() end)
                    if ok2 and str then pingMs = tonumber(str:match("%d+")) or 0 end
                end
                table.insert(pingSamples, pingMs)
                if #pingSamples > maxPingSamples then table.remove(pingSamples, 1) end
            else
                if #pingSamples > 0 then pingMs = pingSamples[#pingSamples] end
            end

            local mean, std = 0, 0
            if #pingSamples > 0 then
                local sum = 0
                for _, v in ipairs(pingSamples) do sum = sum + v end
                mean = sum / #pingSamples
                local sqsum = 0
                for _, v in ipairs(pingSamples) do sqsum = sqsum + (v - mean) * (v - mean) end
                std = math.sqrt(sqsum / #pingSamples)
            end
            local cvPercent = 0
            if mean > 0 then cvPercent = math.floor((std / mean) * 100 + 0.5) end

            if refs.InfoText then
                refs.InfoText.Text = string.format("TIME : %s   |   FPS: %d   |   PING: %d ms (%d%%CV)", timeStr, fps, pingMs, cvPercent)
            end
        end)
    end)
    addConn(renderConn)

    -- Notifications (stack up to 5)
    local notifQueue = {}
    local activeNotifs = {}
    local maxActiveNotifs = 5
    local notifGap = 8
    local defaultNotifDuration = 1.5

    local function repositionNotifs()
        for i, entry in ipairs(activeNotifs) do
            local notif = entry.frame
            local h = entry.height or notif.AbsoluteSize.Y
            local targetY = -96 - (i-1) * (h + notifGap)
            pcall(function()
                if notif and notif.Parent then
                    tween(notif, {Position = UDim2.new(1, -(16 + entry.width), 1, targetY)}, 0.18, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
                end
            end)
        end
    end

    local function removeActiveNotif(index)
        local entry = table.remove(activeNotifs, index)
        if entry and entry.frame then
            pcall(function() safeDestroy(entry.frame) end)
        end
        repositionNotifs()
        if #notifQueue > 0 then
            local nextItem = table.remove(notifQueue, 1)
            if nextItem then
                -- display queued
                task.spawn(function()
                    task.wait(0.02)
                    local innerPad = 12
                    local minW, maxW = 160, 520
                    local maxH = 400
                    local headerFont = TitleMain.Font
                    local headerSize = 18
                    local bodyFont = Enum.Font.SourceSans
                    local bodySize = 16

                    local text = nextItem.text or ""
                    local duration = nextItem.duration or defaultNotifDuration

                    local textSize = TextService:GetTextSize(tostring(text), bodySize, bodyFont, Vector2.new(maxW - innerPad*2, maxH))
                    local desiredW = math.clamp(math.ceil(textSize.X + innerPad*2), minW, maxW)
                    local bodyH = math.ceil(textSize.Y)
                    local headerW = TextService:GetTextSize(cfg.Title or "", headerSize, headerFont, Vector2.new(desiredW - innerPad*2, 100)).X
                    local notifWidth = math.max(desiredW, math.ceil(headerW + innerPad*2))
                    local notifHeight = math.max(48, bodyH + headerSize + innerPad*2)

                    local yOffset = -96 - (#activeNotifs) * (notifHeight + notifGap)

                    local nframe = new("Frame", {Parent = screenGui, Size = UDim2.new(0, notifWidth, 0, notifHeight), Position = UDim2.new(1, -(16 + notifWidth), 1, yOffset), BackgroundColor3 = cfg.Theme.InfoInner, BorderSizePixel = 0, ZIndex = 220})
                    new("UICorner", {Parent = nframe, CornerRadius = UDim.new(0,8)})
                    local notifStroke = new("UIStroke", {Parent = nframe})
                    notifStroke.Thickness = 2
                    notifStroke.Transparency = 0.8
                    notifStroke.Color = Color3.fromRGB(255,255,255)

                    local inner = new("Frame", {Parent = nframe, Size = UDim2.new(1, -innerPad*2, 1, -innerPad*2), Position = UDim2.new(0, innerPad, 0, innerPad), BackgroundTransparency = 1, ZIndex = 221})
                    new("UICorner", {Parent = inner, CornerRadius = UDim.new(0,6)})

                    local header = new("TextLabel", {Parent = inner, Size = UDim2.new(1,0,0,headerSize), Position = UDim2.new(0,0,0,0), BackgroundTransparency = 1, Font = headerFont, TextSize = headerSize, Text = cfg.Title, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = cfg.Theme.Text, ZIndex = 222})
                    header.TextTransparency = 0

                    local body = new("TextLabel", {Parent = inner, Size = UDim2.new(1,0,0,bodyH), Position = UDim2.new(0,0,0,headerSize), BackgroundTransparency = 1, Font = bodyFont, TextSize = bodySize, Text = tostring(text), TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, TextColor3 = cfg.Theme.Text, ZIndex = 222, TextWrapped = true})
                    body.AutomaticSize = Enum.AutomaticSize.None
                    body.TextTransparency = 0

                    nframe.BackgroundTransparency = 1
                    tween(nframe, {BackgroundTransparency = 0}, 0.14, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)

                    table.insert(activeNotifs, { frame = nframe, width = notifWidth, height = notifHeight })
                    repositionNotifs()

                    task.delay(duration, function()
                        for i, e in ipairs(activeNotifs) do
                            if e.frame == nframe then
                                tween(nframe, {BackgroundTransparency = 1}, 0.12)
                                task.wait(0.12)
                                removeActiveNotif(i)
                                break
                            end
                        end
                    end)
                end)
            end
        end
    end

    local function showNotification(text, duration)
        text = tostring(text or "")
        duration = tonumber(duration) or defaultNotifDuration
        if #activeNotifs < maxActiveNotifs then
            local innerPad = 12
            local minW, maxW = 160, 520
            local maxH = 400
            local headerFont = TitleMain.Font
            local headerSize = 18
            local bodyFont = Enum.Font.SourceSans
            local bodySize = 16

            local textSize = TextService:GetTextSize(text, bodySize, bodyFont, Vector2.new(maxW - innerPad*2, maxH))
            local desiredW = math.clamp(math.ceil(textSize.X + innerPad*2), minW, maxW)
            local bodyH = math.ceil(textSize.Y)
            local headerW = TextService:GetTextSize(cfg.Title or "", headerSize, headerFont, Vector2.new(desiredW - innerPad*2, 100)).X
            local notifWidth = math.max(desiredW, math.ceil(headerW + innerPad*2))
            local notifHeight = math.max(48, bodyH + headerSize + innerPad*2)

            local yOffset = -96 - (#activeNotifs) * (notifHeight + notifGap)

            local nframe = new("Frame", {Parent = screenGui, Size = UDim2.new(0, notifWidth, 0, notifHeight), Position = UDim2.new(1, -(16 + notifWidth), 1, yOffset), BackgroundColor3 = cfg.Theme.InfoInner, BorderSizePixel = 0, ZIndex = 220})
            new("UICorner", {Parent = nframe, CornerRadius = UDim.new(0,8)})
            local notifStroke = new("UIStroke", {Parent = nframe})
            notifStroke.Thickness = 2
            notifStroke.Transparency = 0.8
            notifStroke.Color = Color3.fromRGB(255,255,255)

            local inner = new("Frame", {Parent = nframe, Size = UDim2.new(1, -innerPad*2, 1, -innerPad*2), Position = UDim2.new(0, innerPad, 0, innerPad), BackgroundTransparency = 1, ZIndex = 221})
            new("UICorner", {Parent = inner, CornerRadius = UDim.new(0,6)})

            local header = new("TextLabel", {Parent = inner, Size = UDim2.new(1,0,0,headerSize), Position = UDim2.new(0,0,0,0), BackgroundTransparency = 1, Font = headerFont, TextSize = headerSize, Text = cfg.Title, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = cfg.Theme.Text, ZIndex = 222})
            header.TextTransparency = 0

            local body = new("TextLabel", {Parent = inner, Size = UDim2.new(1,0,0,bodyH), Position = UDim2.new(0,0,0,headerSize), BackgroundTransparency = 1, Font = bodyFont, TextSize = bodySize, Text = text, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, TextColor3 = cfg.Theme.Text, ZIndex = 222, TextWrapped = true})
            body.AutomaticSize = Enum.AutomaticSize.None
            body.TextTransparency = 0

            nframe.BackgroundTransparency = 1
            tween(nframe, {BackgroundTransparency = 0}, 0.14, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)

            table.insert(activeNotifs, { frame = nframe, width = notifWidth, height = notifHeight })
            repositionNotifs()

            task.delay(duration, function()
                for i, e in ipairs(activeNotifs) do
                    if e.frame == nframe then
                        tween(nframe, {BackgroundTransparency = 1}, 0.12)
                        task.wait(0.12)
                        removeActiveNotif(i)
                        break
                    end
                end
            end)
        else
            table.insert(notifQueue, { text = text, duration = duration })
        end
    end

    local finalSize = UDim2.new(0, cfg.Width, 0, cfg.Height)

    -- Config saving/loading
    local function configFileName()
        local cfgs = cfg.ConfigurationSaving or {}
        local fname = cfgs.FileName or cfg.Title or "HwanConfig"
        if cfgs.FolderName and cfgs.FolderName ~= "" then
            return (cfgs.FolderName .. "/" .. fname .. ".json")
        end
        return (fname .. ".json")
    end

    local function saveConfig()
        if not cfg.ConfigurationSaving or not cfg.ConfigurationSaving.Enabled then return end
        local out = {}
        for flagName, meta in pairs(window.Flags) do
            local ok, val = pcall(function()
                if type(meta.Get) == "function" then
                    return meta.Get()
                end
                return meta.Value
            end)
            if ok and val ~= nil then
                if typeof(val) == "EnumItem" and val.EnumType == Enum.KeyCode then
                    out[flagName] = { __enum = "KeyCode", name = val.Name }
                elseif typeof(val) == "Color3" then
                    out[flagName] = { __color = color3ToHex(val) }
                else
                    out[flagName] = val
                end
            end
        end
        local ok, encoded = pcall(function() return HttpService:JSONEncode(out) end)
        if ok and encoded then
            writeFileSafe(configFileName(), encoded)
        end
    end

    local function loadConfig()
        if not cfg.ConfigurationSaving or not cfg.ConfigurationSaving.Enabled then return end
        local s = readFileSafe(configFileName())
        if not s then return end
        local ok, decoded = pcall(function() return HttpService:JSONDecode(s) end)
        if not ok or type(decoded) ~= "table" then return end
        for flagName, val in pairs(decoded) do
            local meta = window.Flags[flagName]
            if meta and type(meta.Set) == "function" then
                if type(val) == "table" and val.__enum == "KeyCode" and val.name then
                    local enumVal = Enum.KeyCode:FindFirstChild(val.name) or Enum.KeyCode[val.name]
                    pcall(meta.Set, enumVal)
                elseif type(val) == "table" and val.__color and type(val.__color) == "string" then
                    local hex = val.__color:gsub("#","")
                    if #hex == 6 then
                        local r = tonumber(hex:sub(1,2),16)/255
                        local g = tonumber(hex:sub(3,4),16)/255
                        local b = tonumber(hex:sub(5,6),16)/255
                        pcall(meta.Set, Color3.new(r,g,b))
                    end
                else
                    pcall(meta.Set, val)
                end
            end
        end
    end

    -- Key UI
    local function createKeyUI(onAuth)
        local ks = cfg.KeySettings or {}
        ks.Title = ks.Title or (cfg.Title .. " | Key System")
        ks.FileName = ks.FileName or (cfg.Title .. "_key.txt")
        ks.SaveKey = (ks.SaveKey == true)
        ks.GrabKeyFromSite = (ks.GrabKeyFromSite == true)
        ks.Key = ks.Key or {}

        local allowed = {}
        local function addAllowed(k)
            if not k then return end
            k = tostring(k):gsub("^%s*(.-)%s*$","%1")
            if k ~= "" then allowed[k] = true end
        end

        local function fetchKeysFromUrl(url)
            if not url or type(url) ~= "string" then return end
            local ok, res = pcall(function() return game:HttpGet(url) end)
            if not ok or not res then return end
            for line in res:gmatch("[^\r\n]+") do
                local t = line:gsub("^%s*(.-)%s*$","%1")
                if t ~= "" then allowed[t] = true end
            end
        end

        for _, v in ipairs(ks.Key) do
            if type(v) == "string" and v:match("^https?://") then
                if ks.GrabKeyFromSite then
                    pcall(fetchKeysFromUrl, v)
                else
                    addAllowed(v)
                end
            else
                addAllowed(v)
            end
        end
        if ks.KeyUrl and type(ks.KeyUrl) == "string" then
            if ks.GrabKeyFromSite then pcall(fetchKeysFromUrl, ks.KeyUrl) else addAllowed(ks.KeyUrl) end
        end

        local savedKey = nil
        if ks.SaveKey then
            local raw = readFileSafe(ks.FileName)
            if raw then
                savedKey = tostring(raw):gsub("^%s*(.-)%s*$","%1")
                if savedKey ~= "" and allowed[savedKey] then
                    showNotification("Valid saved key found. Access granted.")
                    onAuth()
                    return
                end
            end
        end

        local kFrame = new("Frame", {Parent = screenGui, Name = "KeyPrompt", Size = UDim2.new(0, 520, 0, 160), Position = UDim2.new(0.5, -260, 0.38, -80), BackgroundColor3 = cfg.Theme.Main, BorderSizePixel = 0, ZIndex = 300, Active = true})
        new("UICorner", {Parent = kFrame, CornerRadius = UDim.new(0,10)})
        local kStroke = new("UIStroke", {Parent = kFrame})
        kStroke.Thickness = 2
        kStroke.Transparency = 0.8
        kStroke.Color = Color3.fromRGB(255,255,255)

        local titleLbl = new("TextLabel", {Parent = kFrame, Size = UDim2.new(1, -20, 0, 30), Position = UDim2.new(0,10,0,8), BackgroundTransparency = 1, Font = Enum.Font.FredokaOne, TextSize = 18, Text = ks.Title, TextColor3 = cfg.Theme.Accent, TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 305})
        local inputBox = new("TextBox", {Parent = kFrame, Size = UDim2.new(1, -40, 0, 40), Position = UDim2.new(0,20,0,48), PlaceholderText = "Enter your key here!", Font = Enum.Font.SourceSans, TextSize = 18, Text = "", ClearTextOnFocus = false, BackgroundColor3 = Color3.fromRGB(60,60,60), TextColor3 = cfg.Theme.Text, BorderSizePixel = 0, ZIndex = 305})
        new("UICorner", {Parent = inputBox, CornerRadius = UDim.new(0,6)})
        new("UIPadding", {Parent = inputBox, PaddingLeft = UDim.new(0,12), PaddingRight = UDim.new(0,10)})

        local getBtn = new("TextButton", {Parent = kFrame, Size = UDim2.new(0,140,0,36), Position = UDim2.new(0.5, -170, 0, 100), BackgroundColor3 = cfg.Theme.Btn, Font = Enum.Font.FredokaOne, TextSize = 16, Text = "Get key", TextColor3 = cfg.Theme.Text, ZIndex = 305})
        new("UICorner", {Parent = getBtn, CornerRadius = UDim.new(0,6)})
        local checkBtn = new("TextButton", {Parent = kFrame, Size = UDim2.new(0,140,0,36), Position = UDim2.new(0.5, -10, 0, 100), BackgroundColor3 = cfg.Theme.Btn, Font = Enum.Font.FredokaOne, TextSize = 16, Text = "Check Key", TextColor3 = cfg.Theme.Text, ZIndex = 305})
        new("UICorner", {Parent = checkBtn, CornerRadius = UDim.new(0,6)})
        local msg = new("TextLabel", {Parent = kFrame, Size = UDim2.new(1, -20, 0, 18), Position = UDim2.new(0,10,1, -22), BackgroundTransparency = 1, Font = Enum.Font.SourceSans, TextSize = 14, Text = "", TextColor3 = Color3.fromRGB(200,200,200), TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 305})

        local function setMsg(s, color)
            pcall(function()
                msg.Text = tostring(s or "")
                if color then msg.TextColor3 = color end
            end)
        end

        local function tryKey(key)
            if not key then setMsg("No key provided."); showNotification("Invalid Key!"); return false end
            key = tostring(key):gsub("^%s*(.-)%s*$","%1")
            if next(allowed) == nil and ks.GrabKeyFromSite then
                for _, v in ipairs(ks.Key or {}) do
                    if type(v) == "string" and v:match("^https?://") then pcall(fetchKeysFromUrl, v) end
                end
                if ks.KeyUrl and ks.KeyUrl:match("^https?://") then pcall(fetchKeysFromUrl, ks.KeyUrl) end
            end

            if allowed[key] then
                if ks.SaveKey then
                    pcall(function() writeFileSafe(ks.FileName, key) end)
                end
                showNotification("Valid Key! Access granted.")
                onAuth()
                safeDestroy(kFrame)
                return true
            end

            if next(allowed) == nil and #ks.Key == 1 and ks.Key[1] == key then
                if ks.SaveKey then pcall(function() writeFileSafe(ks.FileName, key) end) end
                showNotification("Valid Key! Access granted.")
                onAuth()
                safeDestroy(kFrame)
                return true
            end

            setMsg("Invalid key. Make sure you entered correct key.", Color3.fromRGB(220,80,80))
            showNotification("Invalid Key!")
            pcall(function() inputBox.Text = "" end)
            return false
        end

        addConn(checkBtn.MouseButton1Click:Connect(function() tryKey(inputBox.Text) end))
        addConn(inputBox.FocusLost:Connect(function(enter) if enter then tryKey(inputBox.Text) end end))

        addConn(getBtn.MouseButton1Click:Connect(function()
            local copied = false
            if ks.KeyUrl and type(ks.KeyUrl) == "string" and setclipboard then pcall(setclipboard, ks.KeyUrl); copied = true end
            if not copied then
                for _, v in ipairs(ks.Key) do
                    if type(v) == "string" and v:match("^https?://") and setclipboard then pcall(setclipboard, v); copied = true; break end
                end
            end
            if not copied and setclipboard then pcall(setclipboard, "No key URL provided.") end
            showNotification(copied and "Copied to clipboard!" or "No URL to copy.")
        end))

        makeDraggable(kFrame)

        if savedKey and savedKey ~= "" then
            setMsg("Found saved key. Verifying...")
            task.defer(function()
                task.wait(0.05)
                if tryKey(savedKey) then return end
                setMsg("", Color3.fromRGB(200,200,200))
            end)
        end
    end

    -- capture original UI properties for show/hide animations
    local _origUI = {}
    local function captureOriginalProperties()
        for _, d in ipairs(Frame:GetDescendants()) do
            pcall(function()
                if _origUI[d] == nil then
                    local txt = nil
                    if d:IsA("TextLabel") or d:IsA("TextButton") or d:IsA("TextBox") then
                        txt = (d.TextTransparency ~= nil) and d.TextTransparency or nil
                    end

                    local bg = nil
                    if d:IsA("Frame") or d:IsA("ImageLabel") or d:IsA("ImageButton") or d:IsA("TextLabel") or d:IsA("TextButton") or d:IsA("TextBox") then
                        bg = (d.BackgroundTransparency ~= nil) and d.BackgroundTransparency or nil
                    end

                    local stroke = nil
                    if d:IsA("UIStroke") then
                        stroke = d.Transparency
                    end

                    local img = nil
                    if d:IsA("ImageLabel") or d:IsA("ImageButton") then
                        img = (d.ImageTransparency ~= nil) and d.ImageTransparency or nil
                    end

                    _origUI[d] = {
                        TextTransparency = txt,
                        BackgroundTransparency = bg,
                        StrokeTransparency = stroke,
                        ImageTransparency = img,
                    }
                else
                    if d.GetAttribute then
                        local a = d:GetAttribute("hw_orig_text_transparency")
                        if a ~= nil then _origUI[d].TextTransparency = a end
                        local ab = d:GetAttribute("hw_orig_bg_transparency")
                        if ab ~= nil then _origUI[d].BackgroundTransparency = ab end
                        local ai = d:GetAttribute("hw_orig_image_transparency")
                        if ai ~= nil then _origUI[d].ImageTransparency = ai end
                    end
                end
            end)
        end
    end

    local function tweenToTransparency(inst, props, dur)
        pcall(function()
            if not inst or not inst.Parent then return end
            if (not dur) or dur <= 0 then
                for k,v in pairs(props) do
                    pcall(function() inst[k] = v end)
                end
                return
            end
            TweenService:Create(inst, TweenInfo.new(dur, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), props):Play()
        end)
    end

    local function setAllTransparency(target, dur)
        for d, vals in pairs(_origUI) do
            if d and d.Parent then
                pcall(function()
                    if vals.TextTransparency ~= nil and (d.TextTransparency ~= nil) then tweenToTransparency(d, {TextTransparency = target}, dur) end
                    if vals.BackgroundTransparency ~= nil and (d.BackgroundTransparency ~= nil) then tweenToTransparency(d, {BackgroundTransparency = target}, dur) end
                    if vals.StrokeTransparency ~= nil and d:IsA("UIStroke") then tweenToTransparency(d, {Transparency = target}, dur) end
                    if vals.ImageTransparency ~= nil and (d.ImageTransparency ~= nil) then tweenToTransparency(d, {ImageTransparency = target}, dur) end
                end)
            else
                _origUI[d] = nil
            end
        end
    end

    captureOriginalProperties()

    local animCounter = 0
    local visible = true
    local function toggleVisible(newV)
        animCounter = animCounter + 1
        local token = animCounter

        visible = newV == nil and not visible or newV
        local animDur = 0.28
        local fadeDur = 0.12

        for i,inst in ipairs(window._dropdownInstances or {}) do
            pcall(function() if inst and inst.Close then inst.Close() end end)
        end

        if visible then
            Frame.ClipsDescendants = true
            Frame.Visible = true
            Frame.Size = UDim2.new(0, cfg.Width, 0, 0)

            captureOriginalProperties()
            setAllTransparency(1, 0)

            tween(Frame, {Size = UDim2.new(0, cfg.Width, 0, cfg.Height)}, animDur, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

            pcall(function()
                tween(HwanInner, {Size = UDim2.new(1,-6,1,-6)}, 0.12)
                task.wait(0.12)
                tween(HwanInner, {Size = UDim2.new(1,-8,1,-8)}, 0.12)
            end)

            task.delay(animDur * 0.9, function()
                if token ~= animCounter then return end
                for d, vals in pairs(_origUI) do
                    if token ~= animCounter then break end
                    if d and d.Parent then
                        pcall(function()
                            if vals.TextTransparency ~= nil and (d.TextTransparency ~= nil) then tweenToTransparency(d, {TextTransparency = vals.TextTransparency}, 0.18) end
                            if vals.BackgroundTransparency ~= nil and (d.BackgroundTransparency ~= nil) then tweenToTransparency(d, {BackgroundTransparency = vals.BackgroundTransparency}, 0.18) end
                            if vals.StrokeTransparency ~= nil and d:IsA("UIStroke") then tweenToTransparency(d, {Transparency = vals.StrokeTransparency}, 0.18) end
                            if vals.ImageTransparency ~= nil and (d.ImageTransparency ~= nil) then tweenToTransparency(d, {ImageTransparency = vals.ImageTransparency}, 0.18) end
                        end)
                    else
                        _origUI[d] = nil
                    end
                end
                task.delay(0.18 + 0.02, function()
                    if token ~= animCounter then return end
                    pcall(function() Frame.ClipsDescendants = false end)
                end)
            end)
        else
            captureOriginalProperties()
            setAllTransparency(1, fadeDur)

            for i,inst in ipairs(window._dropdownInstances or {}) do
                pcall(function() if inst and inst.Close then inst.Close() end end)
            end

            Frame.ClipsDescendants = true
            task.delay(fadeDur + 0.02, function()
                if token ~= animCounter then return end
                tween(Frame, {Size = UDim2.new(0, cfg.Width, 0, 0)}, animDur, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
                pcall(function()
                    tween(HwanInner, {Size = UDim2.new(1,-6,1,-6)}, 0.12)
                    task.wait(0.12)
                    tween(HwanInner, {Size = UDim2.new(1,-8,1,-8)}, 0.12)
                end)
                task.delay(animDur + 0.02, function()
                    if token ~= animCounter then return end
                    pcall(function() Frame.Visible = false; Frame.ClipsDescendants = false end)
                end)
            end)
        end
    end

    addConn(HwanBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            toggleVisible()
        end
    end))

    addConn(UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
        local keycode = cfg.ToggleKey or Enum.KeyCode.LeftAlt
        local okToggle = false
        if typeof(keycode) == "EnumItem" and keycode.EnumType == Enum.KeyCode then
            if input.KeyCode == keycode then okToggle = true end
        elseif type(keycode) == "string" then
            if tostring(input.KeyCode.Name) == keycode then okToggle = true end
        end
        if okToggle then
            if cfg.KeySystem and (not (_G.Hwan and _G.Hwan.auth)) then return end
            toggleVisible()
        end
    end))

    function window:SetToggleKey(k)
        if typeof(k) == "EnumItem" and k.EnumType == Enum.KeyCode then
            cfg.ToggleKey = k
        elseif type(k) == "string" and #k > 0 then
            cfg.ToggleKey = k
        end
    end

    pcall(function()
        local vu = game:GetService("VirtualUser")
        if LocalPlayer and LocalPlayer.Idled then
            local afkConn = LocalPlayer.Idled:Connect(function()
                pcall(function()
                    vu:CaptureController()
                    vu:Button2Down(Vector2.new(0,0), workspace.CurrentCamera and workspace.CurrentCamera.CFrame or CFrame.new())
                    task.wait(1)
                    vu:Button2Up(Vector2.new(0,0), workspace.CurrentCamera and workspace.CurrentCamera.CFrame or CFrame.new())
                end)
            end)
            addConn(afkConn)
        end
    end)

    -- expose API
    function window:CreateTab(name) return createTab(name) end
    function window:Notify(tblOrText)
        if type(tblOrText) == "table" then
            showNotification(tblOrText.Content or tblOrText.Message or tblOrText.Text or "", tblOrText.Duration)
        else
            showNotification(tblOrText, nil)
        end
    end
    function window:SetTheme(newTheme)
        if type(newTheme) == "string" then
            if THEMES[newTheme] then
                for kk,vv in pairs(THEMES[newTheme]) do cfg.Theme[kk] = vv end
            end
        elseif type(newTheme) == "table" then
            for kk,vv in pairs(newTheme) do cfg.Theme[kk] = vv end
        end
        if refs.Frame then refs.Frame.BackgroundColor3 = cfg.Theme.Main end
        if refs.MainDivider then refs.MainDivider.BackgroundColor3 = cfg.Theme.TabBg end
        if refs.InfoBar then refs.InfoBar.BackgroundColor3 = cfg.Theme.InfoBg end
        if refs.InfoText then refs.InfoText.TextColor3 = cfg.Theme.Text end
        if refs.HwanBtn then refs.HwanBtn.BackgroundColor3 = cfg.Theme.InfoInner end
        if refs.HwanInner then refs.HwanInner.BackgroundColor3 = cfg.Theme.InfoInner end
        if refs.TitleMain then refs.TitleMain.TextColor3 = cfg.Theme.Accent end
        for _, t in ipairs(tabList) do
            if t.Button then t.Button.BackgroundColor3 = cfg.Theme.TabBg; t.Button.TextColor3 = darkenColor(cfg.Theme.Text, 0.18) end
            if t.Content then
                for _, child in ipairs(t.Content:GetDescendants()) do
                    if child:IsA("TextLabel") or child:IsA("TextButton") or child:IsA("TextBox") then
                        pcall(function() child.TextColor3 = cfg.Theme.Text end)
                    end
                end
            end
        end
    end
    function window:GetFlag(name) return window.Flags[name] end
    function window:SetFlag(name, val) if window.Flags[name] and window.Flags[name].Set then window.Flags[name].Set(val) else window.Flags[name] = { Value = val } end end
    function window:SaveConfiguration() saveConfig() end
    function window:LoadConfiguration() loadConfig() end

    local oldDestroy
    oldDestroy = function()
        for _, inst in ipairs(window._dropdownInstances or {}) do
            pcall(function() if inst and inst.Close then inst.Close() end end)
        end
        for i = #conns, 1, -1 do
            local c = conns[i]
            pcall(function()
                if c and c.Disconnect then c:Disconnect()
                elseif c and c.disconnect then c:disconnect()
                end
            end)
            conns[i] = nil
        end

        for i = #activeNotifs, 1, -1 do
            local e = activeNotifs[i]
            if e and e.frame then safeDestroy(e.frame) end
            activeNotifs[i] = nil
        end
        notifQueue = nil

        pcall(function() if screenGui and screenGui.Parent then screenGui:Destroy() end end)

        if _G.Hwan and _G.Hwan.screenGui == screenGui then
            _G.Hwan = nil
        end

        conns = nil
        notifQueue = nil
        notifShowing = nil
        pcall(saveConfig)
    end

    function window:Destroy()
        oldDestroy()
    end

    _G.Hwan = { screenGui = screenGui, conns = conns, auth = false }

    task.spawn(function()
        if cfg.KeySystem then
            Frame.Visible = false
            HwanBtn.Visible = false
            createKeyUI(function()
                _G.Hwan.auth = true
                Frame.Visible = true
                HwanBtn.Visible = (cfg.ShowToggleIcon ~= false)
                tween(Frame, {Size = finalSize}, 0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
                showNotification("Welcome to " .. (cfg.Title or "Hwan Hub"))
            end)
        else
            _G.Hwan.auth = true
            Frame.Visible = true
            HwanBtn.Visible = (cfg.ShowToggleIcon ~= false)
            task.wait(0.06)
            tween(Frame, {Size = finalSize}, 0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
        end
    end)

    task.defer(function()
        pcall(loadConfig)
    end)

    return window
end

return Hwan
