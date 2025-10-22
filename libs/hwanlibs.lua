-- HwanUI
local HwanUI = {}
HwanUI.__index = HwanUI

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")
local TextService = game:GetService("TextService")
local LocalPlayer = Players.LocalPlayer

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
        return LocalPlayer:FindFirstChild("PlayerGui")
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
        local info = TweenInfo.new(time, style, dir)
        TweenService:Create(inst, info, props):Play()
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

-- Clean previous
if _G.HwanHubData then
    if _G.HwanHubData.conns then
        for _, c in ipairs(_G.HwanHubData.conns) do
            pcall(function()
                if c and c.Disconnect then c:Disconnect() end
                if c and c.disconnect then c:disconnect() end
            end)
        end
    end
    if _G.HwanHubData.screenGui and _G.HwanHubData.screenGui.Parent then
        pcall(function() _G.HwanHubData.screenGui:Destroy() end)
    end
    _G.HwanHubData = nil
end

-- Defaults
local DEFAULT = {
    Width = 300,
    Height = 500,
    Title = "HWAN HUB",
    ShowToggleIcon = true,
    KeySystem = true,
    AccessKey = "hwandeptrai",
    KeyUrl = nil,
    Theme = {
        Main = Color3.fromRGB(18,18,18),
        TabBg = Color3.fromRGB(40,40,40),
        Accent = Color3.fromRGB(245,245,245),
        Text = Color3.fromRGB(235,235,235),
        InfoBg = Color3.fromRGB(10,10,10),
        InfoInner = Color3.fromRGB(18,18,18),
        Btn = Color3.fromRGB(50,50,50),
        ToggleBg = Color3.fromRGB(80,80,80),
    },
    Corner = UDim.new(0,12),
    ToggleKey = Enum.KeyCode.LeftAlt,
}

function HwanUI:CreateWindow(title, opts)
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
    if title and type(title) == "string" then cfg.Title = title end
    for k,v in pairs(opts) do
        if k == "Theme" and type(v) == "table" then
            for kk,vv in pairs(v) do cfg.Theme[kk] = vv end
        else
            cfg[k] = v
        end
    end

    local conns = {}
    local function addConn(c) if c then table.insert(conns, c) end end

    local notifQueue = {}
    local notifShowing = false

    local host = getGuiParent()
    local screenGui = new("ScreenGui")
    screenGui.Name = (cfg.Title:gsub("%s+", "") or "HwanHub") .. "_GUI"
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
    local divider0 = new("Frame", {Parent = Frame, Name = "Divider0", Size = UDim2.new(1,-16,0,2), Position = UDim2.new(0,8,0,dividerY + 8), BackgroundColor3 = cfg.Theme.TabBg, BorderSizePixel = 0})
    refs.Divider0 = divider0
    divider0.ClipsDescendants = true

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

    -- window reference early for closures
    local window = { _dropdownInstances = {}, _dropdownStates = {}, _activeTabIndex = 1, _savedState = { active = nil, dropdownSelections = {} } }

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
        if #tabList > 3 then
            tabScroll.AutomaticCanvasSize = Enum.AutomaticSize.None
            tabScroll.CanvasSize = UDim2.new(0, totalWidth, 0, 0)
        else
            tabScroll.AutomaticCanvasSize = Enum.AutomaticSize.None
            tabScroll.CanvasSize = UDim2.new(0, math.max(totalWidth, avail), 0, 0)
            tabScroll.CanvasPosition = Vector2.new(0,0)
        end
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

    local function ensureTabVisible(btn)
        pcall(function()
            local btnAbs = btn.AbsolutePosition.X
            local btnW = btn.AbsoluteSize.X
            local scrollAbs = tabScroll.AbsolutePosition.X
            local scrollW = tabScroll.AbsoluteSize.X
            local curCanvas = tabScroll.CanvasPosition.X
            local target = btnAbs - scrollAbs + curCanvas - (scrollW/2 - btnW/2)
            local maxX = math.max(tabScroll.AbsoluteCanvasSize.X - tabScroll.AbsoluteSize.X, 0)
            target = clampVal(target, 0, maxX)
            tweenCanvasTo(target, 0.28)
        end)
    end

    local preventWindowDrag = false

    local function createTab(name)
        local idx = #tabList + 1
        local btn = new("TextButton", {
            Parent = tabScroll,
            Text = name,
            Size = UDim2.new(0,96,0,32),
            BackgroundColor3 = cfg.Theme.TabBg,
            TextColor3 = darkTabText,
            Font = Enum.Font.SourceSansBold,
            TextSize = 16,
            TextXAlignment = Enum.TextXAlignment.Center,
            TextYAlignment = Enum.TextYAlignment.Center,
            AutoButtonColor = false,
            BorderSizePixel = 0
        })
        new("UICorner", {Parent = btn, CornerRadius = UDim.new(0,10)})
        btn.TextStrokeTransparency = 1

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
        local contentPad = new("UIPadding", {Parent = content, PaddingLeft = UDim.new(0,6), PaddingRight = UDim.new(0,6), PaddingTop = UDim.new(0,6)})
        table.insert(pages, content)

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
            for _, node in ipairs(pendingTextNodes) do
                pcall(function()
                    if node and node.Parent then
                        TweenService:Create(node, TweenInfo.new(0.18, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {TextTransparency = 0}):Play()
                    end
                end)
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

        -- CreateButton
        function tab:CreateButton(label, callback)
            label = label or "Button"
            local row = new("Frame", {Parent = self.Content, Size = UDim2.new(1,0,0,36), BackgroundTransparency = 1})
            local lbl = new("TextLabel", {Parent = row, Text = label, Size = UDim2.new(0.65, -8, 1, 0), Position = UDim2.new(0,8,0,0), BackgroundTransparency = 1, TextColor3 = cfg.Theme.Text, Font = Enum.Font.SourceSansBold, TextSize = 17, TextXAlignment = Enum.TextXAlignment.Left})
            local b = new("TextButton", {Parent = row, Size = UDim2.new(0.34, -8, 1, 0), Position = UDim2.new(0.66, 4, 0, 0), BackgroundColor3 = cfg.Theme.Btn, TextColor3 = cfg.Theme.Text, Text = label, Font = Enum.Font.SourceSansBold, TextSize = 17, AutoButtonColor=false, TextXAlignment = Enum.TextXAlignment.Center, TextYAlignment = Enum.TextYAlignment.Center, TextScaled = false})
            new("UICorner", {Parent = b, CornerRadius = UDim.new(0,8)})
            addConn(b.MouseEnter:Connect(function() if UserInputService.MouseEnabled then tween(b, {BackgroundColor3 = brightenColor(cfg.Theme.Btn, 0.06)}, 0.10) end end))
            addConn(b.MouseLeave:Connect(function() tween(b, {BackgroundColor3 = cfg.Theme.Btn}, 0.10) end))
            addConn(b.MouseButton1Click:Connect(function()
                if callback then pcall(callback) end
                tween(b, {BackgroundColor3 = brightenColor(cfg.Theme.Btn, 0.12)}, 0.06)
                task.wait(0.06)
                tween(b, {BackgroundColor3 = cfg.Theme.Btn}, 0.12)
            end))
            pcall(hideTextNodesIn, row)
            task.defer(function() pcall(updateContentCanvas) end)
            return b
        end

        -- CreateToggle
        function tab:CreateToggle(label, initial, callback)
            local frame = new("Frame", {Parent = self.Content, Size = UDim2.new(1,0,0,30), BackgroundTransparency = 1})
            new("TextLabel", {Parent = frame, Text = label, Size = UDim2.new(0.65, -8, 1, 0), Position = UDim2.new(0,8,0,0), BackgroundTransparency = 1, TextColor3 = cfg.Theme.Text, Font = Enum.Font.SourceSansBold, TextSize = 17, TextXAlignment = Enum.TextXAlignment.Left})
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

            local state = initial and true or false
            local function setState(s, silent)
                state = s
                if s then
                    tween(dot, {Position = UDim2.new(1, -margin, 0.5, 0), BackgroundColor3 = dotOnColor}, 0.14, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
                else
                    tween(dot, {Position = UDim2.new(0, margin, 0.5, 0), BackgroundColor3 = dotOffColor}, 0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
                end
                if callback and not silent then pcall(callback, state) end
            end

            local clickBtn = new("TextButton", {Parent = toggleBg, Size = UDim2.new(1,0,1,0), Position = UDim2.new(0,0,0,0), BackgroundTransparency = 1, AutoButtonColor = false, Text = ""})
            new("UICorner", {Parent = clickBtn, CornerRadius = UDim.new(0,12)})
            addConn(clickBtn.MouseButton1Click:Connect(function() setState(not state) end))
            setState(state, true)
            pcall(hideTextNodesIn, frame)
            task.defer(function() pcall(updateContentCanvas) end)
            return {Get = function() return state end, Set = function(v) setState((v and true) or false) end, UI = frame}
        end

        -- CreateLabel / Section
        function tab:CreateLabel(text)
            local l = new("TextLabel", {Parent = self.Content, Size = UDim2.new(1,0,0,20), Text = text, BackgroundTransparency = 1, TextColor3 = cfg.Theme.Text, Font = Enum.Font.SourceSansBold, TextSize = 17, TextXAlignment = Enum.TextXAlignment.Left})
            pcall(hideTextNodesIn, l)
            task.defer(function() pcall(updateContentCanvas) end)
            return l
        end

        function tab:CreateSection(title)
            local sec = new("Frame", {Parent = self.Content, Size = UDim2.new(1,0,0,40), BackgroundTransparency = 1})
            local bg = new("Frame", {Parent = sec, Size = UDim2.new(1,0,0,32), Position = UDim2.new(0,0,0,4), BackgroundColor3 = cfg.Theme.TabBg, BorderSizePixel = 0})
            new("UICorner", {Parent = bg, CornerRadius = UDim.new(0,8)})
            new("TextLabel", {Parent = bg, Text = title, Size = UDim2.new(1,-12,1,0), Position = UDim2.new(0,8,0,0), BackgroundTransparency = 1, Font = Enum.Font.SourceSansBold, TextSize = 17, TextColor3 = cfg.Theme.Text, TextXAlignment = Enum.TextXAlignment.Left})
            pcall(hideTextNodesIn, sec)
            task.defer(function() pcall(updateContentCanvas) end)
            return sec
        end

        -- CreateDropdown
        function tab:CreateDropdown(label, options, callback)
            options = options or {}
            local frame = new("Frame", {Parent = self.Content, Size = UDim2.new(1,0,0,36), BackgroundTransparency = 1})
            new("TextLabel", {Parent = frame, Text = label, Size = UDim2.new(0.65, -8, 1, 0), Position = UDim2.new(0,8,0,0), BackgroundTransparency = 1, TextColor3 = cfg.Theme.Text, Font = Enum.Font.SourceSansBold, TextSize = 17, TextXAlignment = Enum.TextXAlignment.Left})
            local btnWidthScale = 0.36
            local btn = new("TextButton", {Parent = frame, Size = UDim2.new(btnWidthScale, -8, 1, 0), Position = UDim2.new(1 - btnWidthScale, 4, 0, 0), BackgroundColor3 = cfg.Theme.Btn, Text = "Select", Font = Enum.Font.SourceSansBold, TextSize = 17, TextColor3 = cfg.Theme.Text, AutoButtonColor = false, TextScaled = false, TextXAlignment = Enum.TextXAlignment.Center, TextYAlignment = Enum.TextYAlignment.Center})
            new("UICorner", {Parent = btn, CornerRadius = UDim.new(0,8)})

            local panel, escConn, followConn, contentFrame
            local instance
            local uid = HttpService:GenerateGUID(false)
            local selectedIndex = nil

            local function closePanel()
                if followConn then pcall(function() followConn:Disconnect() end) end
                if escConn then pcall(function() escConn:Disconnect() end) end
                if panel and panel.Parent then
                    pcall(function()
                        local curPos = panel.Position
                        tween(panel, {Position = UDim2.new(curPos.X.Scale, curPos.X.Offset, curPos.Y.Scale, curPos.Y.Offset - 8), BackgroundTransparency = 1}, 0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
                        task.wait(0.14)
                        panel:Destroy()
                    end)
                end
                panel = nil
                escConn = nil
                followConn = nil
                if instance and window and window._dropdownStates then
                    window._dropdownStates[instance] = false
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

                task.wait(0.16)

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

                local header = new("TextLabel", {Parent = panel, Size = UDim2.new(1,-12,0,headerH-4), Position = UDim2.new(0,6,0,6), BackgroundTransparency = 1, Font = Enum.Font.SourceSansBold, TextSize = 17, Text = label or "", TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Center, TextColor3 = cfg.Theme.Text, ZIndex = 221})

                contentFrame = new("ScrollingFrame", {Parent = panel, Size = UDim2.new(1,-12,0,panelH - headerH - 10), Position = UDim2.new(0,6,0, headerH), BackgroundTransparency = 1, ScrollBarThickness = 0, CanvasSize = UDim2.new(0,0,0, #options * itemH), VerticalScrollBarInset = Enum.ScrollBarInset.Always})
                contentFrame.AutomaticCanvasSize = Enum.AutomaticSize.None
                contentFrame.CanvasPosition = Vector2.new(0,0)

                for i, opt in ipairs(options) do
                    local row = new("TextButton", {Parent = contentFrame, Size = UDim2.new(1,0,0,itemH-6), Position = UDim2.new(0,0,0, (i-1)*itemH), BackgroundColor3 = cfg.Theme.TabBg, Text = tostring(opt), Font = Enum.Font.SourceSansBold, TextSize = 17, TextColor3 = darkTabText, AutoButtonColor = false, ZIndex = 222})
                    new("UICorner", {Parent = row, CornerRadius = UDim.new(0,6)})
                    row.TextStrokeTransparency = 1

                    row.MouseEnter:Connect(function()
                        if selectedIndex == i then return end
                        tween(row, {BackgroundColor3 = brightenColor(cfg.Theme.TabBg, 0.06)}, 0.10)
                    end)
                    row.MouseLeave:Connect(function()
                        if selectedIndex == i then
                            tween(row, {BackgroundColor3 = brightenColor(cfg.Theme.TabBg, 0.12)}, 0.10)
                        else
                            tween(row, {BackgroundColor3 = cfg.Theme.TabBg}, 0.10)
                        end
                    end)

                    row.MouseButton1Click:Connect(function()
                        if selectedIndex == i then
                            selectedIndex = nil
                            row.BackgroundColor3 = cfg.Theme.TabBg
                            row.TextColor3 = darkTabText
                            if window and window._savedState and window._savedState.dropdownSelections then
                                window._savedState.dropdownSelections[uid] = nil
                            end
                            if callback then pcall(callback, nil) end
                            btn.Text = "Select"
                            return
                        end

                        for _, child in ipairs(contentFrame:GetChildren()) do
                            if child:IsA("TextButton") then
                                pcall(function() child.BackgroundColor3 = cfg.Theme.TabBg; child.TextColor3 = darkTabText end)
                            end
                        end

                        selectedIndex = i
                        row.BackgroundColor3 = brightenColor(cfg.Theme.TabBg, 0.14)
                        row.TextColor3 = Color3.fromRGB(255,255,255)
                        btn.Text = tostring(opt)
                        if window and window._savedState then
                            window._savedState.dropdownSelections[uid] = i
                        end
                        if callback then pcall(callback, opt) end
                    end)
                end

                if window and window._savedState and window._savedState.dropdownSelections and window._savedState.dropdownSelections[uid] then
                    local idx = window._savedState.dropdownSelections[uid]
                    if idx and idx >= 1 and idx <= #options then
                        local cnt = 0
                        for _, child in ipairs(contentFrame:GetChildren()) do
                            if child:IsA("TextButton") then
                                cnt = cnt + 1
                                if cnt == idx then
                                    selectedIndex = idx
                                    child.BackgroundColor3 = brightenColor(cfg.Theme.TabBg, 0.14)
                                    child.TextColor3 = Color3.fromRGB(255,255,255)
                                    btn.Text = child.Text
                                    break
                                end
                            end
                        end
                    end
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

                tween(panel, {BackgroundTransparency = 0, Position = UDim2.new(panel.Position.X.Scale, panel.Position.X.Offset, panel.Position.Y.Scale, panel.Position.Y.Offset + 8)}, 0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
                tween(header, {TextTransparency = 0}, 0.18)
                task.delay(0.06, function()
                    for _, child in ipairs(contentFrame:GetDescendants()) do
                        if child:IsA("TextLabel") or child:IsA("TextButton") or child:IsA("TextBox") then
                            pcall(function() tween(child, {TextTransparency = 0}, 0.16) end)
                        end
                    end
                end)

                followConn = Frame:GetPropertyChangedSignal("AbsolutePosition"):Connect(updatePanelPos)
                addConn(followConn)
                local visConn = Frame:GetPropertyChangedSignal("Visible"):Connect(function()
                    if not Frame.Visible then closePanel() end
                end)
                addConn(visConn)

                escConn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
                    if gameProcessed then return end
                    if input.KeyCode == Enum.KeyCode.Escape then
                        closePanel()
                    end
                end)
                addConn(escConn)

                if instance and window and window._dropdownStates then window._dropdownStates[instance] = true end
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
            
            instance = { UI = frame, Set = function(v) btn.Text = tostring(v) end, Open = showPanel, Close = closePanel, IsOpen = function() return (panel ~= nil) end, Button = btn, uid = uid }
            if window then
                window._dropdownInstances = window._dropdownInstances or {}
                table.insert(window._dropdownInstances, instance)
                window._dropdownStates = window._dropdownStates or {}
                window._dropdownStates[instance] = false
                window._savedState = window._savedState or {}
                window._savedState.dropdownSelections = window._savedState.dropdownSelections or {}
            end

            pcall(hideTextNodesIn, frame)
            task.defer(function() pcall(updateContentCanvas) end)
            return instance
        end
    
            -- CreateSlider
        function tab:CreateSlider(label, minVal, maxVal, default, callback)
            minVal = minVal or 0; maxVal = maxVal or 100; default = (default == nil) and minVal or default
            local row = new("Frame", {Parent = self.Content, Size = UDim2.new(1,0,0,36), BackgroundTransparency = 1})

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
            leftLabel.Text = ""

            local rightBoxScale = 0.30
            local rightBox = new("Frame", {Parent = row, Size = UDim2.new(rightBoxScale, -8, 0, trackHeight), Position = UDim2.new(1 - rightBoxScale, 4, 0.5, -trackHeight/2), BackgroundColor3 = cfg.Theme.TabBg, BorderSizePixel = 0})
            new("UICorner", {Parent = rightBox, CornerRadius = UDim.new(0,8)})
            local valueLabel = new("TextLabel", {Parent = rightBox, Size = UDim2.new(1, -12, 1, 0), Position = UDim2.new(0,6,0,0), BackgroundTransparency = 1, Font = leftLabel.Font, TextSize = leftLabel.TextSize, TextColor3 = cfg.Theme.Text, TextXAlignment = Enum.TextXAlignment.Center, TextYAlignment = Enum.TextYAlignment.Center})
            valueLabel.Text = tostring(default)

            local function countCharsFit(fullText, font, textSize, targetPixel)
                local lo, hi = 0, #fullText
                while lo < hi do
                    local mid = math.ceil((lo + hi + 1) / 2)
                    local ok, size = pcall(function()
                        return TextService:GetTextSize(string.sub(fullText, 1, mid), textSize, font, Vector2.new(10000, 10000)).X
                    end)
                    local w = 0
                    if ok and size then w = size end
                    if w <= targetPixel then
                        lo = mid
                    else
                        hi = mid - 1
                    end
                end
                return lo
            end

            local function makeRichText(fullText, splitIndex)
                fullText = fullText or ""
                local escFull = escapeHtml(fullText)
                local colorCovered = color3ToHex(cfg.Theme.Main or Color3.new(0,0,0))
                local colorUncovered = color3ToHex(cfg.Theme.Text or Color3.new(1,1,1))
                if splitIndex <= 0 then
                    return string.format("<font color=\"%s\">%s</font>", colorUncovered, escFull)
                elseif splitIndex >= #fullText then
                    return string.format("<font color=\"%s\">%s</font>", colorCovered, escFull)
                else
                    local left = string.sub(fullText, 1, splitIndex)
                    local right = string.sub(fullText, splitIndex + 1)
                    left = escapeHtml(left)
                    right = escapeHtml(right)
                    return string.format("<font color=\"%s\">%s</font><font color=\"%s\">%s</font>", colorCovered, left, colorUncovered, right)
                end
            end

            local range = maxVal - minVal
            local function setFromPercent(p, skipTween)
                p = clampVal(p, 0, 1)
                local value = minVal + (maxVal - minVal) * p
                local displayValue = (math.floor(value*100 + 0.5)/100)

                local textStr = tostring(label or "")

                local trackW = math.max(1, track.AbsoluteSize.X)
                local usableWidth = trackW - (textPadding * 2)
                local fillPixel = math.floor(usableWidth * p + 0.5)

                local coveredChars = 0
                if #textStr > 0 and fillPixel > 0 then
                    coveredChars = countCharsFit(textStr, leftLabel.Font, leftLabel.TextSize, fillPixel)
                else
                    coveredChars = 0
                end

                local rich = makeRichText(textStr, coveredChars)
                pcall(function() leftLabel.Text = rich end)

                local targetFill = UDim2.new(p, 0, 1, 0)
                if not skipTween then
                    tween(fill, {Size = targetFill}, 0.12, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
                else
                    fill.Size = targetFill
                end

                pcall(function() valueLabel.Text = tostring(displayValue) end)

                if callback then pcall(callback, value) end
            end

            local defaultPct = 0
            if range == 0 then defaultPct = 0 else defaultPct = (default - minVal) / range end

            task.defer(function()
                RunService.Heartbeat:Wait()
                setFromPercent(defaultPct, true)
            end)

            local dragging = false
            local inputChangedConn
            addConn(track.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = true
                    preventWindowDrag = true
                    inputChangedConn = UserInputService.InputChanged:Connect(function(inp)
                        if dragging and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
                            local absX = inp.Position.X
                            local left = track.AbsolutePosition.X
                            local width = math.max(1, track.AbsoluteSize.X)
                            local pct = (absX - left) / width
                            setFromPercent(pct, false)
                        end
                    end)
                    addConn(inputChangedConn)
                    input.Changed:Connect(function()
                        if input.UserInputState == Enum.UserInputState.End then
                            dragging = false
                            preventWindowDrag = false
                            if inputChangedConn then pcall(function() inputChangedConn:Disconnect() end) end
                        end
                    end)
                end
            end))

            addConn(track.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    local pos = UserInputService:GetMouseLocation()
                    if pos then
                        local mx = pos.X
                        local left = track.AbsolutePosition.X
                        local width = math.max(1, track.AbsoluteSize.X)
                        local pct = (mx - left) / width
                        setFromPercent(pct, false)
                    end
                end
            end))

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
                end
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
            ensureTabVisible(tab.Button)
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

    -- Attach window properties
    window.Root = screenGui
    window.Main = Frame
    window._config = cfg
    window._dropdownInstances = window._dropdownInstances or {}
    window._dropdownStates = window._dropdownStates or {}
    window._activeTabIndex = window._activeTabIndex or 1
    window._savedState = window._savedState or { active = nil, dropdowns = {}, dropdownSelections = {} }

    -- render updates (info text)
    local pingSamples = {}
    local maxPingSamples = 30
    local pingTimer = 0
    local pingInterval = 0.25
    addConn(RunService.RenderStepped:Connect(function(dt)
        if titleGrad then titleGrad.Rotation = (titleGrad.Rotation + 0.9) % 360 end
        if hwanTopGrad then hwanTopGrad.Rotation = (hwanTopGrad.Rotation + 1.6) % 360 end
        if hwanBottomGrad then hwanBottomGrad.Rotation = (hwanBottomGrad.Rotation + 1.6) % 360 end

        local timeStr = os.date("%H:%M:%S")
        local fps = 0
        if dt > 0 then fps = math.floor(1/dt + 0.5) end

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

        InfoText.Text = string.format("TIME : %s   |   FPS: %d   |   PING: %d ms (%d%%CV)", timeStr, fps, pingMs, cvPercent)
    end))

    -- Notifications
    local finalSize = UDim2.new(0, cfg.Width, 0, cfg.Height)
    local defaultNotifDuration = 1.5
    local function processNextNotification()
        if notifShowing then return end
        local item = table.remove(notifQueue, 1)
        if not item then return end
        notifShowing = true
        local text = tostring(item.text or "")
        local duration = (item.duration and tonumber(item.duration)) or defaultNotifDuration

        local innerPad = 10
        local minW, maxW = 160, 420
        local maxH = 320
        local headerFont = TitleMain.Font
        local headerSize = 16
        local bodyFont = Enum.Font.SourceSans
        local bodySize = 15

        local textSize = TextService:GetTextSize(text, bodySize, bodyFont, Vector2.new(maxW - innerPad*2, maxH))
        local desiredW = math.clamp(math.ceil(textSize.X + innerPad*2), minW, maxW)
        local bodyH = math.ceil(textSize.Y)
        local headerW = TextService:GetTextSize(cfg.Title or "", headerSize, headerFont, Vector2.new(desiredW - innerPad*2, 100)).X
        local notifWidth = math.max(desiredW, math.ceil(headerW + innerPad*2))

        local notif = new("Frame", {Parent = screenGui, Size = UDim2.new(0, notifWidth, 0, math.max(48, bodyH + headerSize + innerPad*2)), Position = UDim2.new(1, - (16 + notifWidth), 1, -96), BackgroundColor3 = cfg.Theme.InfoInner, BorderSizePixel = 0, ZIndex = 220})
        new("UICorner", {Parent = notif, CornerRadius = UDim.new(0,8)})
        local notifStroke = new("UIStroke", {Parent = notif})
        notifStroke.Thickness = 2
        notifStroke.Transparency = 0.8
        notifStroke.Color = Color3.fromRGB(255,255,255)

        local inner = new("Frame", {Parent = notif, Size = UDim2.new(1, -innerPad*2, 1, -innerPad*2), Position = UDim2.new(0, innerPad, 0, innerPad), BackgroundTransparency = 1, ZIndex = 221})
        new("UICorner", {Parent = inner, CornerRadius = UDim.new(0,6)})

        local header = new("TextLabel", {Parent = inner, Size = UDim2.new(1,0,0,headerSize), Position = UDim2.new(0,0,0,0), BackgroundTransparency = 1, Font = headerFont, TextSize = headerSize, Text = cfg.Title, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = cfg.Theme.Text, ZIndex = 222})
        header.TextTransparency = 0

        local body = new("TextLabel", {Parent = inner, Size = UDim2.new(1,0,0,bodyH), Position = UDim2.new(0,0,0,headerSize), BackgroundTransparency = 1, Font = bodyFont, TextSize = bodySize, Text = text, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, TextColor3 = cfg.Theme.Text, ZIndex = 222, TextWrapped = true})
        body.AutomaticSize = Enum.AutomaticSize.None

        -- animate in
        notif.BackgroundTransparency = 1
        header.TextTransparency = 1
        body.TextTransparency = 1
        tween(notif, {BackgroundTransparency = 0}, 0.14, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
        tween(header, {TextTransparency = 0}, 0.14, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
        tween(body, {TextTransparency = 0}, 0.14, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)

        task.delay(duration, function()
            tween(notif, {BackgroundTransparency = 1}, 0.12)
            tween(header, {TextTransparency = 1}, 0.12)
            tween(body, {TextTransparency = 1}, 0.12)
            task.wait(0.12)
            safeDestroy(notif)
            notifShowing = false
            processNextNotification()
        end)
    end

    local function showNotification(text, duration)
        table.insert(notifQueue, {text = tostring(text or ""), duration = duration})
        processNextNotification()
    end

    -- Key UI
    local function createKeyUI(onAuth)
        local kFrame = new("Frame", {Parent = screenGui, Name = "KeyPrompt", Size = UDim2.new(0, 460, 0, 140), Position = UDim2.new(0.5, -230, 0.38, -70), BackgroundColor3 = cfg.Theme.Main, BorderSizePixel = 0, ZIndex = 300, Active = true})
        new("UICorner", {Parent = kFrame, CornerRadius = UDim.new(0,10)})
        local kStroke = new("UIStroke", {Parent = kFrame})
        kStroke.Thickness = 2
        kStroke.Transparency = 0.8
        kStroke.Color = Color3.fromRGB(255,255,255)

        local titleLbl = new("TextLabel", {Parent = kFrame, Size = UDim2.new(1, -20, 0, 30), Position = UDim2.new(0,10,0,8), BackgroundTransparency = 1, Font = Enum.Font.FredokaOne, TextSize = 18, Text = cfg.Title .. " | Key System", TextColor3 = cfg.Theme.Accent, TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 305})
        local inputBox = new("TextBox", {Parent = kFrame, Size = UDim2.new(1, -40, 0, 36), Position = UDim2.new(0,20,0,48), PlaceholderText = "Enter your key here!", Font = Enum.Font.SourceSans, TextSize = 18, Text = "", ClearTextOnFocus = false, BackgroundColor3 = Color3.fromRGB(60,60,60), TextColor3 = cfg.Theme.Text, BorderSizePixel = 0, ZIndex = 305})
        new("UICorner", {Parent = inputBox, CornerRadius = UDim.new(0,6)})
        new("UIPadding", {Parent = inputBox, PaddingLeft = UDim.new(0,12), PaddingRight = UDim.new(0,10)})

        local getBtn = new("TextButton", {Parent = kFrame, Size = UDim2.new(0,120,0,36), Position = UDim2.new(0.5, -130, 0, 96), BackgroundColor3 = cfg.Theme.Btn, Font = Enum.Font.FredokaOne, TextSize = 16, Text = "Get key", TextColor3 = cfg.Theme.Text, ZIndex = 305})
        new("UICorner", {Parent = getBtn, CornerRadius = UDim.new(0,6)})
        local checkBtn = new("TextButton", {Parent = kFrame, Size = UDim2.new(0,120,0,36), Position = UDim2.new(0.5, 10, 0, 96), BackgroundColor3 = cfg.Theme.Btn, Font = Enum.Font.FredokaOne, TextSize = 16, Text = "Check Key", TextColor3 = cfg.Theme.Text, ZIndex = 305})
        new("UICorner", {Parent = checkBtn, CornerRadius = UDim.new(0,6)})
        local msg = new("TextLabel", {Parent = kFrame, Size = UDim2.new(1, -20, 0, 18), Position = UDim2.new(0,10,1, -22), BackgroundTransparency = 1, Font = Enum.Font.SourceSans, TextSize = 14, Text = "", TextColor3 = Color3.fromRGB(200,200,200), TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 305})

        local function tryKey(key)
            if key and type(key) == "string" and string.lower(key) == string.lower(cfg.AccessKey or "") then
                showNotification("Valid Key!")
                onAuth()
                safeDestroy(kFrame)
            else
                showNotification("Invalid Key!")
                pcall(function() inputBox.Text = "" end)
            end
        end

        addConn(checkBtn.MouseButton1Click:Connect(function() tryKey(inputBox.Text) end))
        addConn(getBtn.MouseButton1Click:Connect(function()
            pcall(function()
                if cfg.KeyUrl and setclipboard then
                    setclipboard(cfg.KeyUrl)
                elseif setclipboard then
                    setclipboard("https://facebook.com/hwanthichhat")
                end
            end)
            showNotification("Copied to clipboard!")
        end))
        addConn(inputBox.FocusLost:Connect(function(enter) if enter then tryKey(inputBox.Text) end end))

        makeDraggable(kFrame)
    end

    local function applyTheme(theme)
        for kk, vv in pairs(theme) do cfg.Theme[kk] = vv end
        if refs.Frame then refs.Frame.BackgroundColor3 = cfg.Theme.Main end
        if refs.Divider0 then refs.Divider0.BackgroundColor3 = cfg.Theme.TabBg end
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

    function window:CreateTab(name) return createTab(name) end
    function window:Notify(text, duration) showNotification(text, duration) end
    function window:Center() Frame.Position = UDim2.new(0, 16, 0.5, -cfg.Height/2) end
    function window:SetVisible(v) toggleVisible(v) end
    function window:SetVisibleImmediate(v) Frame.Visible = v end
    function window:SetTheme(newTheme) if type(newTheme) == "table" then applyTheme(newTheme) end end

    function window:Destroy()
        -- close dropdowns explicitly
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

        pcall(function() if screenGui and screenGui.Parent then screenGui:Destroy() end end)

        if _G.HwanHubData and _G.HwanHubData.screenGui == screenGui then
            _G.HwanHubData = nil
        end

        conns = nil
        notifQueue = nil
        notifShowing = nil
        pages = nil
        tabList = nil
    end

    _G.HwanHubData = { screenGui = screenGui, conns = conns, auth = false }

    task.spawn(function()
        if cfg.KeySystem then
            Frame.Visible = false
            HwanBtn.Visible = false
            createKeyUI(function()
                _G.HwanHubData.auth = true
                Frame.Visible = true
                HwanBtn.Visible = (cfg.ShowToggleIcon ~= false)
                tween(Frame, {Size = finalSize}, 0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
                showNotification("Welcome to " .. (cfg.Title or "Hwan Hub"))
            end)
        else
            _G.HwanHubData.auth = true
            Frame.Visible = true
            HwanBtn.Visible = (cfg.ShowToggleIcon ~= false)
            task.wait(0.06)
            tween(Frame, {Size = finalSize}, 0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
        end
    end)

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

    -- đóng tất cả dropdown trước khi đổi trạng thái
    for i,inst in ipairs(window._dropdownInstances or {}) do
        pcall(function() if inst and inst.Close then inst.Close() end end)
    end

    if visible then
        -- show
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
        -- hide
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
        local keycode = cfg.ToggleKey or Enum.KeyCode.LeftAlt
        if gameProcessed then return end
        if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == keycode then
            if cfg.KeySystem and (not (_G.HwanHubData and _G.HwanHubData.auth)) then return end
            toggleVisible()
        end
    end))

    -- Anti-AFK
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

    return window
end

return HwanUI
