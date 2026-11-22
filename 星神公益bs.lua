
_G.__LUMEN_BOOTED = true

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local TextService = game:GetService("TextService")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

for _, c in ipairs(playerGui:GetChildren()) do
    if c.Name == "LumenUI" then
        pcall(function() c:Destroy() end)
    end
end

local Theme = {
    WHITE=Color3.fromRGB(255,255,255), PRIMARY=Color3.fromRGB(37,99,235),
    PRIMARY_DK=Color3.fromRGB(29,78,216), BORDER=Color3.fromRGB(229,231,235),
    TEXT=Color3.fromRGB(31,41,55), TEXT_MUTED=Color3.fromRGB(156,163,175),
    HOVER_BG=Color3.fromRGB(239,246,255), HOVER_SOFT=Color3.fromRGB(248,251,255),
    PANEL_SOFT=Color3.fromRGB(249,250,252), TRACK=Color3.fromRGB(229,231,235),
    DISABLED_BG=Color3.fromRGB(249,250,251), DISABLED_FG=Color3.fromRGB(209,213,219),
    SHADOW=Color3.fromRGB(15,23,42),
}
local FONT_REG = Enum.Font.Gotham
local FONT_MED = Enum.Font.GothamMedium
local EASE         = TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local EASE_FAST    = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local EASE_BACK    = TweenInfo.new(0.32, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local EASE_IN      = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
local EASE_NONE    = TweenInfo.new(0, Enum.EasingStyle.Linear)
local EASE_SOFT    = TweenInfo.new(0.32, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local EASE_ELASTIC = TweenInfo.new(0.45, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out)
local EASE_SINE    = TweenInfo.new(0.28, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)

local function tw(o,i,p) local t=TweenService:Create(o,i,p); t:Play(); return t end
local function corner(p,r) local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,r or 8); c.Parent=p; return c end
local function stroke(p,c,t) local s=Instance.new("UIStroke"); s.Color=c or Theme.BORDER; s.Thickness=t or 1; s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border; s.Parent=p; return s end

local function pulse(obj, peakScale, peakTime)
    peakScale = peakScale or 1.04; peakTime = peakTime or 0.1
    local origSize = obj.Size
    local peakSize = UDim2.new(origSize.X.Scale, origSize.X.Offset * peakScale, origSize.Y.Scale, origSize.Y.Offset * peakScale)
    local t1 = TweenService:Create(obj, TweenInfo.new(peakTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = peakSize })
    t1.Completed:Connect(function()
        if obj and obj.Parent then TweenService:Create(obj, EASE_ELASTIC, { Size = origSize }):Play() end
    end)
    t1:Play()
end

local function ripple(parent, cx, cy, color)
    color = color or Theme.PRIMARY
    local ring = Instance.new("Frame")
    ring.AnchorPoint = Vector2.new(0.5, 0.5); ring.Position = UDim2.new(0, cx, 0, cy)
    ring.Size = UDim2.new(0, 4, 0, 4); ring.BackgroundTransparency = 1
    ring.BorderSizePixel = 0; ring.ZIndex = 100; ring.Parent = parent
    corner(ring, 4)
    local s = stroke(ring, color, 2); s.Transparency = 0.2
    local t = TweenService:Create(ring, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = UDim2.new(0, 80, 0, 80) })
    TweenService:Create(s, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Transparency = 1 }):Play()
    t.Completed:Connect(function() pcall(function() ring:Destroy() end) end); t:Play()
end

local function shine(obj)
    local s = Instance.new("Frame")
    s.BackgroundColor3 = Color3.fromRGB(255,255,255); s.BackgroundTransparency = 0.75
    s.BorderSizePixel = 0; s.Size = UDim2.new(0, 24, 1, 0); s.Position = UDim2.new(0, -30, 0, 0)
    s.ZIndex = 20; s.Parent = obj
    local g = Instance.new("UIGradient", s)
    g.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0,1), NumberSequenceKeypoint.new(0.5,0), NumberSequenceKeypoint.new(1,1) })
    local t = TweenService:Create(s, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Position = UDim2.new(1, 30, 0, 0) })
    t.Completed:Connect(function() pcall(function() s:Destroy() end) end); t:Play()
end

local uiGui = Instance.new("ScreenGui")
uiGui.Name="LumenUI"; uiGui.ResetOnSpawn=false; uiGui.IgnoreGuiInset=true
uiGui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling; uiGui.DisplayOrder=100
uiGui.Parent=playerGui

local listLayer = Instance.new("Frame")
listLayer.BackgroundTransparency=1; listLayer.Size=UDim2.new(1,0,1,0)
listLayer.ZIndex=90; listLayer.Parent=uiGui
local activeDropdownClose = nil
local interceptLayer = Instance.new("TextButton")
interceptLayer.BackgroundTransparency=1; interceptLayer.Text=""
interceptLayer.AutoButtonColor=false; interceptLayer.Size=UDim2.new(1,0,1,0)
interceptLayer.Visible=false; interceptLayer.ZIndex=89
interceptLayer.Parent=listLayer
interceptLayer.MouseButton1Click:Connect(function()
    if activeDropdownClose then activeDropdownClose() end
end)

local function resolveParent(cfg) return (cfg and cfg.parent) or uiGui end

local tooltipGui = Instance.new("Frame")
tooltipGui.Name = "TooltipLayer"; tooltipGui.BackgroundTransparency = 1
tooltipGui.Size = UDim2.new(1,0,1,0); tooltipGui.ZIndex = 260; tooltipGui.Parent = uiGui
local activeTooltip = nil
local function hideTooltip()
    if activeTooltip then
        local box = activeTooltip; activeTooltip = nil
        tw(box, EASE_IN, { BackgroundTransparency = 1 })
        for _, c in ipairs(box:GetDescendants()) do
            if c:IsA("TextLabel") then tw(c, EASE_IN, { TextTransparency = 1 })
            elseif c:IsA("UIStroke") then tw(c, EASE_IN, { Transparency = 1 }) end
        end
        task.delay(0.2, function() pcall(function() box:Destroy() end) end)
    end
end
local function showTooltip(target, text, x, y)
    hideTooltip()
    local box = Instance.new("Frame")
    box.BackgroundColor3 = Theme.WHITE; box.BorderSizePixel = 0
    box.Position = UDim2.new(0, x, 0, y - 4); box.Size = UDim2.new(0, 220, 0, 0)
    box.AutomaticSize = Enum.AutomaticSize.Y; box.BackgroundTransparency = 1
    box.ZIndex = 261; box.Parent = tooltipGui; corner(box, 8)
    local st = stroke(box, Theme.BORDER, 1); st.Transparency = 1
    local pad = Instance.new("UIPadding", box)
    pad.PaddingTop = UDim.new(0,8); pad.PaddingBottom = UDim.new(0,8)
    pad.PaddingLeft = UDim.new(0,10); pad.PaddingRight = UDim.new(0,10)
    local lbl = Instance.new("TextLabel", box)
    lbl.BackgroundTransparency = 1; lbl.Text = text
    lbl.TextColor3 = Theme.TEXT; lbl.TextSize = 11; lbl.Font = FONT_REG
    lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.TextYAlignment = Enum.TextYAlignment.Top
    lbl.TextWrapped = true; lbl.Size = UDim2.new(1, 0, 0, 0); lbl.AutomaticSize = Enum.AutomaticSize.Y
    lbl.ZIndex = 262; lbl.TextTransparency = 1
    activeTooltip = box
    tw(box, EASE_SOFT, { BackgroundTransparency = 0, Position = UDim2.new(0, x, 0, y) })
    tw(st, EASE, { Transparency = 0 }); tw(lbl, EASE, { TextTransparency = 0 })
end

local toastContainer = Instance.new("Frame")
toastContainer.AnchorPoint = Vector2.new(1, 1); toastContainer.Position = UDim2.new(1, -20, 1, -20)
toastContainer.Size = UDim2.new(0, 0, 0, 0); toastContainer.BackgroundTransparency = 1
toastContainer.ZIndex = 250; toastContainer.Parent = uiGui
local TOAST_W = 300; local TOAST_H = 82; local TOAST_GAP = 10
local toastList = {}
local TOAST_STYLE = {
    success = { symbol = "√", color = Color3.fromRGB(34,197,94), c2 = Color3.fromRGB(22,163,74) },
    error   = { symbol = "X", color = Color3.fromRGB(239,68,68), c2 = Color3.fromRGB(220,38,38) },
    warning = { symbol = "!", color = Color3.fromRGB(245,158,11), c2 = Color3.fromRGB(217,119,6) },
    info    = { symbol = "i", color = Color3.fromRGB(59,130,246), c2 = Color3.fromRGB(37,99,235) },
}
local function isImageId(s) return type(s)=="string" and (s:match("^rbxassetid://") or s:match("^rbxasset://")) end
local function relayoutToasts(animate)
    for i, t in ipairs(toastList) do
        local targetPos = UDim2.new(1, 0, 1, -((i-1) * (TOAST_H + TOAST_GAP)))
        if animate then tw(t.frame, TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Position = targetPos })
        else t.frame.Position = targetPos end
    end
end
local function closeToast(t)
    if t.closing then return end
    t.closing = true
    for i, item in ipairs(toastList) do if item == t then table.remove(toastList, i); break end end
    tw(t.frame, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Position = UDim2.new(1, TOAST_W + 60, 1, t.frame.Position.Y.Offset) })
    tw(t.frame, TweenInfo.new(0.22), { BackgroundTransparency = 1 })
    if t.stroke then tw(t.stroke, TweenInfo.new(0.22), { Transparency = 1 }) end
    task.delay(0.26, function() relayoutToasts(true) end)
    task.delay(0.28, function() pcall(function() t.frame:Destroy() end) end)
end
local function createToast(cfg)
    local style = TOAST_STYLE[cfg.type or "info"] or TOAST_STYLE.info
    local duration = cfg.duration or 3
    local iconParam = cfg.icon
    local iconIsImage = isImageId(iconParam)
    local iconSymbol = iconParam or style.symbol
    local card = Instance.new("Frame")
    card.AnchorPoint = Vector2.new(1, 1); card.Position = UDim2.new(1, TOAST_W + 60, 1, 0)
    card.Size = UDim2.new(0, TOAST_W, 0, TOAST_H); card.BackgroundColor3 = Color3.fromRGB(255,255,255)
    card.BorderSizePixel = 0; card.ZIndex = 251; card.Parent = toastContainer; corner(card, 12)
    local cardStroke = stroke(card, Color3.fromRGB(229,231,235), 1)
    local iconCircle = Instance.new("Frame")
    iconCircle.AnchorPoint = Vector2.new(0,0); iconCircle.Position = UDim2.new(0, 16, 0, 16)
    iconCircle.Size = UDim2.new(0, 32, 0, 32); iconCircle.BackgroundColor3 = style.color
    iconCircle.BorderSizePixel = 0; iconCircle.ZIndex = 252; iconCircle.Parent = card; corner(iconCircle, 16)
    local circleGrad = Instance.new("UIGradient", iconCircle)
    circleGrad.Rotation = 45
    circleGrad.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, style.color), ColorSequenceKeypoint.new(1, style.c2) })
    iconCircle.Size = UDim2.new(0, 0, 0, 0)
    tw(iconCircle, TweenInfo.new(0.42, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out), { Size = UDim2.new(0, 32, 0, 32) })
    if iconIsImage then
        local img = Instance.new("ImageLabel")
        img.BackgroundTransparency = 1; img.Image = iconSymbol; img.ImageColor3 = Color3.fromRGB(255,255,255)
        img.Size = UDim2.new(0,16,0,16); img.Position = UDim2.new(0.5,-8,0.5,-8); img.ZIndex = 253; img.Parent = iconCircle
    else
        local iconText = Instance.new("TextLabel")
        iconText.BackgroundTransparency = 1; iconText.Text = iconSymbol
        iconText.TextColor3 = Color3.fromRGB(255,255,255); iconText.Font = Enum.Font.GothamBold
        iconText.TextSize = 18; iconText.ZIndex = 253; iconText.Size = UDim2.new(1,0,1,0); iconText.Parent = iconCircle
    end
    local titleLbl = Instance.new("TextLabel")
    titleLbl.BackgroundTransparency = 1; titleLbl.Text = cfg.title or "通知"
    titleLbl.TextColor3 = Color3.fromRGB(31,41,55); titleLbl.Font = Enum.Font.GothamBold
    titleLbl.TextSize = 12; titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.TextTruncate = Enum.TextTruncate.AtEnd
    titleLbl.Position = UDim2.new(0, 58, 0, 14); titleLbl.Size = UDim2.new(1, -94, 0, 16)
    titleLbl.ZIndex = 252; titleLbl.Parent = card
    local msgLbl = Instance.new("TextLabel")
    msgLbl.BackgroundTransparency = 1; msgLbl.Text = cfg.message or ""
    msgLbl.TextColor3 = Color3.fromRGB(156,163,175); msgLbl.Font = Enum.Font.Gotham
    msgLbl.TextSize = 10; msgLbl.TextXAlignment = Enum.TextXAlignment.Left
    msgLbl.TextWrapped = true; msgLbl.TextTruncate = Enum.TextTruncate.AtEnd
    msgLbl.Position = UDim2.new(0, 58, 0, 34); msgLbl.Size = UDim2.new(1, -74, 0, 30)
    msgLbl.ZIndex = 252; msgLbl.Parent = card
    local closeBtn = Instance.new("TextButton")
    closeBtn.AnchorPoint = Vector2.new(1, 0); closeBtn.Position = UDim2.new(1, -8, 0, 8)
    closeBtn.Size = UDim2.new(0, 22, 0, 22); closeBtn.Text = "x"
    closeBtn.TextColor3 = Color3.fromRGB(180,185,195); closeBtn.TextSize = 14
    closeBtn.Font = Enum.Font.GothamBold; closeBtn.BackgroundColor3 = Color3.fromRGB(255,255,255)
    closeBtn.BackgroundTransparency = 1; closeBtn.BorderSizePixel = 0; closeBtn.AutoButtonColor = false
    closeBtn.ZIndex = 253; closeBtn.Parent = card; corner(closeBtn, 6)
    closeBtn.MouseEnter:Connect(function()
        closeBtn.BackgroundTransparency = 0
        tw(closeBtn, EASE_FAST, { BackgroundColor3 = Color3.fromRGB(239,246,255), TextColor3 = Color3.fromRGB(29,78,216) })
    end)
    closeBtn.MouseLeave:Connect(function()
        tw(closeBtn, EASE, { TextColor3 = Color3.fromRGB(180,185,195) })
        task.delay(0.22, function() if closeBtn and closeBtn.Parent then closeBtn.BackgroundTransparency = 1 end end)
    end)
    local progressBg = Instance.new("Frame")
    progressBg.AnchorPoint = Vector2.new(0, 1); progressBg.Position = UDim2.new(0, 8, 1, -6)
    progressBg.Size = UDim2.new(1, -16, 0, 3); progressBg.BackgroundColor3 = Color3.fromRGB(229,231,235)
    progressBg.BorderSizePixel = 0; progressBg.ZIndex = 252; progressBg.Parent = card; corner(progressBg, 3)
    local progress = Instance.new("Frame")
    progress.AnchorPoint = Vector2.new(0, 0); progress.Position = UDim2.new(0, 0, 0, 0)
    progress.Size = UDim2.new(1, 0, 1, 0); progress.BackgroundColor3 = style.color
    progress.BorderSizePixel = 0; progress.ZIndex = 253; progress.Parent = progressBg; corner(progress, 3)
    local progGrad = Instance.new("UIGradient", progress)
    progGrad.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, style.color), ColorSequenceKeypoint.new(1, style.c2) })
    local entry = { frame = card, stroke = cardStroke, closing = false }
    table.insert(toastList, 1, entry); relayoutToasts(true)
    tw(progress, TweenInfo.new(duration, Enum.EasingStyle.Linear), { Size = UDim2.new(0, 0, 1, 0) })
    closeBtn.MouseButton1Click:Connect(function() closeToast(entry) end)
    task.delay(duration, function() if not entry.closing then closeToast(entry) end end)
end

local favorites = {}
local favoriteModeEnabled = false
local function toggleFavorite(id) favorites[id] = not favorites[id]; return favorites[id] end

local BADGE_COLORS = {
    green  = { bg = Color3.fromRGB(76,175,80),  fg = Color3.fromRGB(255,255,255) },
    blue   = { bg = Color3.fromRGB(37,99,235),  fg = Color3.fromRGB(255,255,255) },
    red    = { bg = Color3.fromRGB(239,68,68),  fg = Color3.fromRGB(255,255,255) },
    yellow = { bg = Color3.fromRGB(255,215,0),  fg = Color3.fromRGB(0,0,0) },
    purple = { bg = Color3.fromRGB(168,85,247), fg = Color3.fromRGB(255,255,255) },
    cyan   = { bg = Color3.fromRGB(20,184,166), fg = Color3.fromRGB(255,255,255) },
}
local badgeCount = 0
local MAX_BADGES = 30
local function resolveBadgeSpec(c, customFg)
    if type(c) == "table" then return { bg = c, fg = customFg or Color3.fromRGB(255,255,255) } end
    local s = BADGE_COLORS[c or "blue"] or BADGE_COLORS.blue
    return { bg = s.bg, fg = customFg or s.fg }
end
local function createBadge(parent, cfg)
    if badgeCount >= MAX_BADGES then warn("[LUMEN] 标签框最多 " .. MAX_BADGES .. " 个"); return nil end
    badgeCount = badgeCount + 1
    local h = cfg.h or 26
    local padding = cfg.padding or 12
    local fontSize = cfg.textSize or 10
    local font = cfg.font or FONT_MED
    local spec = resolveBadgeSpec(cfg.color, cfg.textColor)
    local textStr = cfg.text or ""
    local measured = TextService:GetTextSize(textStr, fontSize, font, Vector2.new(10000, h))
    local targetW = math.ceil(measured.X) + padding * 2
    local badge = Instance.new("Frame")
    badge.BackgroundColor3 = spec.bg; badge.BorderSizePixel = 0
    badge.AnchorPoint = cfg.anchor or Vector2.new(0, 0)
    badge.Position = UDim2.new(0, cfg.x or 0, 0, cfg.y or 0)
    badge.Size = UDim2.new(0, targetW, 0, h)
    badge.ZIndex = cfg.zIndex or 30; badge.Parent = parent
    corner(badge, cfg.radius or 6)
    local shadow = Instance.new("Frame")
    shadow.BackgroundColor3 = Color3.fromRGB(0,0,0); shadow.BackgroundTransparency = 0.92
    shadow.BorderSizePixel = 0; shadow.Position = UDim2.new(0, 0, 0, 2)
    shadow.Size = UDim2.new(1, 0, 1, 0); shadow.ZIndex = badge.ZIndex - 1
    corner(shadow, cfg.radius or 6); shadow.Parent = badge
    local lbl = Instance.new("TextLabel")
    lbl.BackgroundTransparency = 1; lbl.Text = textStr
    lbl.TextColor3 = spec.fg; lbl.Font = font; lbl.TextSize = fontSize
    lbl.TextXAlignment = Enum.TextXAlignment.Center; lbl.TextYAlignment = Enum.TextYAlignment.Center
    lbl.Size = UDim2.new(1, 0, 1, 0); lbl.ZIndex = badge.ZIndex + 1; lbl.Parent = badge
    badge.Size = UDim2.new(0, 0, 0, h); lbl.TextTransparency = 1; badge.BackgroundTransparency = 1
    tw(badge, EASE_BACK, { Size = UDim2.new(0, targetW, 0, h), BackgroundTransparency = 0 })
    tw(lbl, EASE, { TextTransparency = 0 })
    return {
        frame = badge, label = lbl,
        setText = function(newText)
            newText = newText or ""
            local m = TextService:GetTextSize(newText, fontSize, font, Vector2.new(10000, h))
            local w = math.ceil(m.X) + padding * 2
            lbl.Text = newText
            tw(badge, EASE, { Size = UDim2.new(0, w, 0, h) })
        end,
        setColor = function(c, customFg)
            local s = resolveBadgeSpec(c, customFg)
            tw(badge, EASE, { BackgroundColor3 = s.bg }); tw(lbl, EASE, { TextColor3 = s.fg })
        end,
        destroy = function()
            badgeCount = math.max(0, badgeCount - 1)
            tw(badge, EASE_IN, { Size = UDim2.new(0, 0, 0, h), BackgroundTransparency = 1 })
            tw(lbl, EASE_IN, { TextTransparency = 1 })
            task.delay(0.24, function() pcall(function() badge:Destroy() end) end)
        end,
    }
end

local function createLabel(parent, cfg)
    local lbl = Instance.new("TextLabel")
    lbl.BackgroundTransparency=1; lbl.Text=cfg.text or ""
    lbl.TextColor3=cfg.color or Theme.TEXT; lbl.TextSize=cfg.textSize or 12
    lbl.Font=cfg.font or FONT_REG
    lbl.TextXAlignment=cfg.align or Enum.TextXAlignment.Left
    lbl.TextYAlignment=cfg.vAlign or Enum.TextYAlignment.Center
    lbl.TextWrapped=cfg.wrapped or false
    lbl.TextTruncate=Enum.TextTruncate.AtEnd
    lbl.Position=UDim2.new(0,cfg.x or 0,0,cfg.y or 0)
    lbl.Size=UDim2.new(0,cfg.w or 100,0,cfg.h or 20)
    lbl.ZIndex=cfg.zIndex or 5; lbl.Parent=parent
    return lbl
end

local allStars = {}
local function createStar(parent, id, x, y)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 20, 0, 20); btn.Position = UDim2.new(0, x, 0, y)
    btn.Text = favorites[id] and "*" or "o"
    btn.TextColor3 = favorites[id] and Color3.fromRGB(245,158,11) or Color3.fromRGB(200,200,200)
    btn.TextSize = 16; btn.Font = Enum.Font.GothamBold; btn.BackgroundTransparency = 1
    btn.BorderSizePixel = 0; btn.AutoButtonColor = false; btn.Visible = favoriteModeEnabled
    btn.ZIndex = 8; btn.Parent = parent; table.insert(allStars, btn)
    btn.MouseEnter:Connect(function()
        tw(btn, EASE_FAST, { TextColor3 = Color3.fromRGB(245,158,11) })
        tw(btn, EASE_SINE, { Size = UDim2.new(0, 22, 0, 22) })
    end)
    btn.MouseLeave:Connect(function()
        tw(btn, EASE, { TextColor3 = favorites[id] and Color3.fromRGB(245,158,11) or Color3.fromRGB(200,200,200) })
        tw(btn, EASE, { Size = UDim2.new(0, 20, 0, 20) })
    end)
    btn.MouseButton1Click:Connect(function()
        local v = toggleFavorite(id)
        btn.Text = v and "*" or "o"
        tw(btn, EASE_FAST, { TextColor3 = v and Color3.fromRGB(245,158,11) or Color3.fromRGB(200,200,200) })
        pulse(btn, 1.25, 0.1)
    end)
    return btn
end
local function setFavoriteMode(v)
    favoriteModeEnabled = v
    for _, btn in ipairs(allStars) do
        if btn and btn.Parent then
            btn.Visible = v
            if v then btn.TextTransparency = 1; tw(btn, EASE, { TextTransparency = 0 }) end
        end
    end
end

local function createPanel(parent, cfg)
    cfg = cfg or {}
    local W, H = cfg.w or 460, cfg.h or 340
    local RADIUS = cfg.radius or 12
    local Z = cfg.zIndex or 4
    local hasTitle = cfg.title ~= nil
    local TITLE_H = hasTitle and (cfg.titleHeight or 34) or 0
    local tabConfig = cfg.tabs
    local hasTabs = type(tabConfig)=="table" and #tabConfig>0
    local SIDEBAR_W = hasTabs and (cfg.sidebarWidth or 100) or 0
    local showPlayer = cfg.showPlayer ~= false
    local minimizable = cfg.minimizable ~= false

    local useCenter = cfg.center == true
    if cfg.x == nil and cfg.y == nil then useCenter = true end
    local vp = Vector2.new(1920, 1080)
    if workspace.CurrentCamera then
        local v = workspace.CurrentCamera.ViewportSize
        if v and v.X > 0 and v.Y > 0 then vp = v end
    end
    local X, Y
    if useCenter then X = math.floor((vp.X - W) / 2); Y = math.floor((vp.Y - H) / 2)
    else X = cfg.x or 0; Y = cfg.y or 0 end

    local shadow = nil
    if cfg.shadow ~= false then
        shadow = Instance.new("Frame")
        shadow.BackgroundColor3=Theme.SHADOW; shadow.BackgroundTransparency=0.95
        shadow.BorderSizePixel=0
        shadow.Position=UDim2.new(0,X-2,0,Y+2)
        shadow.Size=UDim2.new(0,W+4,0,H+4)
        shadow.ZIndex=Z-1; corner(shadow,RADIUS+2); shadow.Parent=parent
    end

    local panel = Instance.new("Frame")
    panel.BackgroundColor3=cfg.bgColor or Theme.WHITE; panel.BorderSizePixel=0
    panel.AnchorPoint=Vector2.new(0, 0)
    panel.Position=UDim2.new(0,X,0,Y)
    panel.Size=UDim2.new(0,W,0,H)
    panel.ZIndex=Z; panel.ClipsDescendants=true
    corner(panel,RADIUS)
    local panelStroke = stroke(panel,cfg.borderColor or Theme.BORDER,1)
    panel.Parent=parent

    panel.Size = UDim2.new(0, W * 0.9, 0, H * 0.9)
    tw(panel, TweenInfo.new(0.42, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Size = UDim2.new(0, W, 0, H) })

    local function syncShadow()
        if not shadow then return end
        shadow.Position=UDim2.new(0,panel.Position.X.Offset-2,0,panel.Position.Y.Offset+2)
        shadow.Size=UDim2.new(0,panel.Size.X.Offset+4,0,panel.Size.Y.Offset+4)
    end
    panel:GetPropertyChangedSignal("Position"):Connect(syncShadow)
    panel:GetPropertyChangedSignal("Size"):Connect(syncShadow)

    local titleBar, titleLine, titleLabel
    if hasTitle then
        titleBar = Instance.new("Frame")
        titleBar.BackgroundColor3=cfg.titleBgColor or (cfg.bgColor or Theme.WHITE)
        titleBar.BorderSizePixel=0
        titleBar.Position=UDim2.new(0,0,0,0)
        titleBar.Size=UDim2.new(1,0,0,TITLE_H)
        titleBar.ZIndex=Z+4; corner(titleBar,RADIUS); titleBar.Parent=panel
        titleLabel = createLabel(titleBar,{text=cfg.title,x=16,y=0,w=W-100,h=TITLE_H,
            textSize=cfg.titleSize or 13,color=cfg.titleColor or Theme.TEXT,
            font=FONT_MED,zIndex=Z+5})
        titleLine = Instance.new("Frame")
        titleLine.BackgroundColor3=cfg.borderColor or Theme.BORDER
        titleLine.BorderSizePixel=0; titleLine.AnchorPoint=Vector2.new(0,1)
        titleLine.Position=UDim2.new(0,0,1,0); titleLine.Size=UDim2.new(1,0,0,1)
        titleLine.ZIndex=Z+5; titleLine.Parent=titleBar
    end

    local ICON=24; local ICON_PAD=8; local ICON_GAP=4
    local titleIconButtons = {}
    local function iconBtn(symbol, orderFromRight, onClick)
        local b = Instance.new("TextButton")
        b.BackgroundColor3=Theme.WHITE; b.BackgroundTransparency=1
        b.BorderSizePixel=0; b.Text=symbol
        b.TextColor3=Theme.TEXT_MUTED; b.TextSize=16
        b.Font=FONT_MED; b.AutoButtonColor=false
        b.AnchorPoint=Vector2.new(1,0.5)
        b.Position=UDim2.new(1,-(ICON_PAD+(orderFromRight-1)*(ICON+ICON_GAP)),0,(hasTitle and TITLE_H or 20)/2)
        b.Size=UDim2.new(0,ICON,0,ICON); b.ZIndex=Z+6
        corner(b,6); b.Parent=titleBar or panel
        table.insert(titleIconButtons, b)
        b.MouseEnter:Connect(function()
            b.BackgroundTransparency=0
            tw(b,EASE_FAST,{BackgroundColor3=Theme.HOVER_BG,TextColor3=Theme.PRIMARY_DK})
            tw(b,EASE_SINE,{Size=UDim2.new(0,26,0,26)})
        end)
        b.MouseLeave:Connect(function()
            tw(b,EASE,{TextColor3=Theme.TEXT_MUTED})
            tw(b,EASE,{Size=UDim2.new(0,ICON,0,ICON)})
            task.delay(0.22,function() if b then b.BackgroundTransparency=1 end end)
        end)
        b.MouseButton1Click:Connect(function() ripple(b, ICON/2, ICON/2, Theme.PRIMARY); onClick() end)
        return b
    end
    if cfg.onClose then iconBtn("x",1,function() cfg.onClose() end) end

    local minimized=false
    local sidebar, pageContainer, playerBar, navScroll
    local pages, tabButtons, tabHl, tabHlBar = {}, {}, nil, nil
    local groupStates = {}
    local currentTab = 1
    local hiddenTitleNodes = {}

    local function collectAndHide(node, list)
        if node:IsA("GuiObject") then
            local st = { node = node, bg = node.BackgroundTransparency, text = nil, img = nil }
            if node:IsA("TextLabel") or node:IsA("TextButton") or node:IsA("TextBox") then
                st.text = node.TextTransparency
            end
            if node:IsA("ImageLabel") or node:IsA("ImageButton") then
                st.img = node.ImageTransparency
            end
            list[#list + 1] = st
            tw(node, EASE_FAST, { BackgroundTransparency = 1 })
            if st.text ~= nil then tw(node, EASE_FAST, { TextTransparency = 1 }) end
            if st.img ~= nil then tw(node, EASE_FAST, { ImageTransparency = 1 }) end
        elseif node:IsA("UIStroke") then
            list[#list + 1] = { stroke = node, transparency = node.Transparency }
            tw(node, EASE_FAST, { Transparency = 1 })
        end
        for _, c in ipairs(node:GetChildren()) do collectAndHide(c, list) end
    end

    local function restoreHidden(list)
        for _, s in ipairs(list) do
            if s.stroke then
                if s.stroke.Parent then tw(s.stroke, EASE, { Transparency = s.transparency }) end
            elseif s.node and s.node.Parent then
                local props = { BackgroundTransparency = s.bg }
                if s.text ~= nil then props.TextTransparency = s.text end
                if s.img ~= nil then props.ImageTransparency = s.img end
                tw(s.node, EASE, props)
            end
        end
    end

    local function toggleMinimize()
        if not minimized then
            minimized = true
            if body then tw(body, EASE_FAST, { GroupTransparency = 1 }) end

            hiddenTitleNodes = {}
            if titleBar then
                for _, child in ipairs(titleBar:GetChildren()) do
                    if child ~= titleLabel and child ~= titleLine
                       and not (child:IsA("TextButton") and table.find(titleIconButtons, child)) then
                        collectAndHide(child, hiddenTitleNodes)
                    end
                end
            end
            if playerBar then playerBar.Visible = false end

            tw(panel, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Size = UDim2.new(0, panel.Size.X.Offset, 0, TITLE_H),
            })

            task.delay(0.24, function()
                if not panel or not panel.Parent then return end
                local titleW = 100
                if titleLabel then
                    local ok, m = pcall(function()
                        return TextService:GetTextSize(titleLabel.Text, titleLabel.TextSize, titleLabel.Font, Vector2.new(10000, TITLE_H))
                    end)
                    if ok and m then titleW = math.ceil(m.X) end
                end
                local btnZoneW = ICON_PAD + 2 * ICON + ICON_GAP + 4
                local minW = 16 + titleW + 16 + btnZoneW + 8
                minW = math.min(W, math.max(minW, 170))
                if titleLabel then
                    titleLabel.Size = UDim2.new(0, minW - btnZoneW - 16, 0, TITLE_H)
                end
                tw(panel, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    Size = UDim2.new(0, minW, 0, TITLE_H),
                })
            end)
            if titleLine then tw(titleLine, EASE, { BackgroundTransparency = 1 }) end
        else
            minimized = false
            tw(panel, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Size = UDim2.new(0, W, 0, TITLE_H),
            })
            task.delay(0.24, function()
                if not panel or not panel.Parent then return end
                tw(panel, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    Size = UDim2.new(0, W, 0, H),
                })
            end)
            restoreHidden(hiddenTitleNodes)
            hiddenTitleNodes = {}
            if titleLabel then
                titleLabel.Size = UDim2.new(0, W - 100, 0, TITLE_H)
            end
            if titleLine then tw(titleLine, EASE, { BackgroundTransparency = 0 }) end
            if body then tw(body, EASE, { GroupTransparency = 0 }) end
            if playerBar then playerBar.Visible = true end
        end
        if cfg.onMinimize then cfg.onMinimize(minimized) end
    end
    if hasTitle and minimizable then iconBtn("-",2,toggleMinimize) end

    if cfg.draggable ~= false then
        local dragHit = Instance.new("TextButton")
        dragHit.BackgroundTransparency=1; dragHit.Text=""; dragHit.AutoButtonColor=false
        dragHit.Position=UDim2.new(0,0,0,0)
        dragHit.Size=UDim2.new(1,0,0,hasTitle and TITLE_H or 20)
        dragHit.ZIndex=Z+5; dragHit.Parent=titleBar or panel
        local dragging=false; local dragStart, startPos
        dragHit.InputBegan:Connect(function(input)
            if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
                dragging=true; dragStart=input.Position; startPos=panel.Position
                if activeDropdownClose then activeDropdownClose(); activeDropdownClose=nil end
            end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if not dragging then return end
            if input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch then
                local dx=input.Position.X-dragStart.X; local dy=input.Position.Y-dragStart.Y
                local vp2=workspace.CurrentCamera.ViewportSize
                if vp2.X<=0 or vp2.Y<=0 then return end
                local nx=math.clamp(startPos.X.Offset+dx, -panel.Size.X.Offset+40, vp2.X-40)
                local ny=math.clamp(startPos.Y.Offset+dy, 0, vp2.Y-20)
                panel.Position=UDim2.new(0,nx,0,ny)
            end
        end)
        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then dragging=false end
        end)
    end

    local function selectTab(index, animate)
        if index<1 or index>#pages then return end
        if currentTab==index and animate~=false then return end
        local prev=pages[currentTab]; local nxt=pages[index]; currentTab=index
        if tabButtons[index] and tabHl then
            local btn=tabButtons[index]
            tw(tabHl, animate and EASE or EASE_NONE, {
                Position=UDim2.new(0,8,0,btn.Position.Y.Offset),
                Size=UDim2.new(0,SIDEBAR_W-16,0,btn.Size.Y.Offset),
            })
            if tabHlBar then
                tabHlBar.Size = UDim2.new(0, 3, 0, 6)
                task.delay(0.15, function()
                    if tabHlBar and tabHlBar.Parent then tw(tabHlBar, EASE_BACK, { Size = UDim2.new(0, 3, 0, 14) }) end
                end)
            end
            if navScroll then tw(navScroll, EASE, { CanvasPosition = Vector2.new(0, math.max(btn.Position.Y.Offset - 100, 0)) }) end
        end
        for i,b in ipairs(tabButtons) do
            local t = (i==index) and Theme.PRIMARY_DK or Theme.TEXT_MUTED
            tw(b, animate and EASE or EASE_NONE, {TextColor3=t})
        end
        if animate==false then
            for i,p in ipairs(pages) do
                p.Visible=(i==index); p.GroupTransparency=(i==index) and 0 or 1; p.Position=UDim2.new(0,0,0,0)
            end
            return
        end
        if prev and prev~=nxt then
            local closing=prev
            tw(closing, EASE, {GroupTransparency=1, Position=UDim2.new(0,-12,0,0)})
            task.delay(0.22,function()
                if closing~=pages[currentTab] then closing.Visible=false; closing.Position=UDim2.new(0,0,0,0) end
            end)
        end
        if nxt then
            nxt.Position=UDim2.new(0,14,0,0); nxt.GroupTransparency=1; nxt.Visible=true
            tw(nxt, EASE_BACK, {GroupTransparency=0, Position=UDim2.new(0,0,0,0)})
        end
    end

    if showPlayer then
        local PB_H=42; local PB_PAD=10
        playerBar = Instance.new("Frame")
        playerBar.BackgroundColor3=Theme.WHITE; playerBar.BorderSizePixel=0
        playerBar.AnchorPoint=Vector2.new(0,1)
        playerBar.Position=UDim2.new(0,PB_PAD,1,-PB_PAD)
        playerBar.Size=UDim2.new(0,SIDEBAR_W>0 and (SIDEBAR_W-PB_PAD*2) or 180,0,PB_H)
        playerBar.ZIndex=Z+6; corner(playerBar,8); playerBar.Parent=panel
        local avatarSize=30
        local avatar=Instance.new("ImageLabel")
        avatar.BackgroundColor3=Theme.HOVER_BG; avatar.BorderSizePixel=0
        avatar.AnchorPoint=Vector2.new(0,0.5); avatar.Position=UDim2.new(0,6,0.5,0)
        avatar.Size=UDim2.new(0,avatarSize,0,avatarSize); avatar.ZIndex=Z+7
        avatar.Image="rbxthumb://type=AvatarHeadShot&id="..player.UserId.."&w=60&h=60"
        corner(avatar,avatarSize/2); avatar.Parent=playerBar
        local ring = Instance.new("Frame")
        ring.BackgroundTransparency = 1; ring.BorderSizePixel = 0
        ring.AnchorPoint = Vector2.new(0.5,0.5); ring.Position = UDim2.new(0, 6 + avatarSize/2, 0.5, 0)
        ring.Size = UDim2.new(0, avatarSize, 0, avatarSize); ring.ZIndex = Z+6; ring.Parent = playerBar
        corner(ring, avatarSize/2)
        local rs = stroke(ring, Theme.PRIMARY, 1.5); rs.Transparency = 0.6
        task.spawn(function()
            while ring.Parent do
                ring.Size = UDim2.new(0, avatarSize, 0, avatarSize); rs.Transparency = 0.6
                tw(ring, TweenInfo.new(1.4, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), { Size = UDim2.new(0, avatarSize + 8, 0, avatarSize + 8) })
                tw(rs, TweenInfo.new(1.4, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), { Transparency = 1 })
                task.wait(1.4)
            end
        end)
        local nameText=Instance.new("TextLabel")
        nameText.BackgroundTransparency=1; nameText.Text=player.DisplayName
        nameText.TextColor3=Theme.TEXT; nameText.TextSize=11; nameText.Font=FONT_MED
        nameText.TextXAlignment=Enum.TextXAlignment.Left; nameText.TextTruncate=Enum.TextTruncate.AtEnd
        nameText.Position=UDim2.new(0,avatarSize+12,0,6); nameText.Size=UDim2.new(1,-(avatarSize+16),0,14)
        nameText.ZIndex=Z+7; nameText.Parent=playerBar
        local userText=Instance.new("TextLabel")
        userText.BackgroundTransparency=1; userText.Text="@"..player.Name
        userText.TextColor3=Theme.TEXT_MUTED; userText.TextSize=10; userText.Font=FONT_REG
        userText.TextXAlignment=Enum.TextXAlignment.Left; userText.TextTruncate=Enum.TextTruncate.AtEnd
        userText.Position=UDim2.new(0,avatarSize+12,0,21); userText.Size=UDim2.new(1,-(avatarSize+16),0,14)
        userText.ZIndex=Z+7; userText.Parent=playerBar
    end

    if hasTabs then
        sidebar=Instance.new("Frame")
        sidebar.BackgroundColor3=cfg.bgColor or Theme.WHITE; sidebar.BorderSizePixel=0
        sidebar.Position=UDim2.new(0,0,0,TITLE_H); sidebar.Size=UDim2.new(0,SIDEBAR_W,1,-TITLE_H)
        sidebar.ZIndex=Z+3; corner(sidebar,RADIUS); sidebar.Parent=panel
        local sideLine=Instance.new("Frame")
        sideLine.BackgroundColor3=cfg.borderColor or Theme.BORDER; sideLine.BorderSizePixel=0
        sideLine.AnchorPoint=Vector2.new(1,0); sideLine.Position=UDim2.new(1,0,0,0)
        sideLine.Size=UDim2.new(0,1,1,0); sideLine.ZIndex=Z+4; sideLine.Parent=sidebar

        local ITEM_H=cfg.tabHeight or 32
        local ITEM_PAD_X=8; local ITEM_START_Y=10
        local ITEM_W=SIDEBAR_W-ITEM_PAD_X*2
        local GROUP_H = 26

        navScroll = Instance.new("ScrollingFrame")
        navScroll.Size = UDim2.new(1, 0, 1, -(showPlayer and 60 or 0))
        navScroll.BackgroundTransparency = 1; navScroll.BorderSizePixel = 0
        navScroll.ScrollBarThickness = 3; navScroll.ScrollBarImageColor3 = Color3.fromRGB(180,180,180)
        navScroll.CanvasSize = UDim2.new(0, 0, 0, 0); navScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
        navScroll.ZIndex = Z + 4; navScroll.Parent = sidebar

        tabHl=Instance.new("Frame")
        tabHl.BackgroundColor3=Theme.HOVER_BG; tabHl.BorderSizePixel=0
        tabHl.Position=UDim2.new(0,ITEM_PAD_X,0,ITEM_START_Y)
        tabHl.Size=UDim2.new(0,ITEM_W,0,ITEM_H)
        tabHl.ZIndex=Z+3; corner(tabHl,8); tabHl.Parent=navScroll
        tabHlBar=Instance.new("Frame")
        tabHlBar.BackgroundColor3=Theme.PRIMARY; tabHlBar.BorderSizePixel=0
        tabHlBar.AnchorPoint=Vector2.new(0,0.5); tabHlBar.Position=UDim2.new(0,0,0.5,0)
        tabHlBar.Size=UDim2.new(0,3,0,14); tabHlBar.ZIndex=Z+4
        corner(tabHlBar,2); tabHlBar.Parent=tabHl

        local flatList = {}
        for _, entry in ipairs(tabConfig) do
            if type(entry) == "string" then
                table.insert(flatList, { kind="tab", name=entry, group=nil })
            else
                local gname = entry.name
                local expanded = entry.expanded ~= false
                groupStates[gname] = { expanded = expanded }
                table.insert(flatList, { kind="group", name=gname, expanded=expanded })
                for _, sub in ipairs(entry.items or {}) do
                    table.insert(flatList, { kind="tab", name=sub, group=gname })
                end
            end
        end

        local relayoutMenu

        local tabIndexCounter = 0
        for i, item in ipairs(flatList) do
            if item.kind == "group" then
                local gBtn = Instance.new("TextButton")
                gBtn.BackgroundTransparency = 1; gBtn.BorderSizePixel = 0
                gBtn.Text = ""; gBtn.AutoButtonColor = false
                gBtn.Size = UDim2.new(0, ITEM_W, 0, GROUP_H)
                gBtn.Position = UDim2.new(0, ITEM_PAD_X, 0, ITEM_START_Y)
                gBtn.ZIndex = Z+5; gBtn.Parent = navScroll
                local arrow = Instance.new("TextLabel")
                arrow.BackgroundTransparency = 1; arrow.Text = item.expanded and "v" or ">"
                arrow.TextColor3 = Theme.TEXT_MUTED; arrow.TextSize = 12
                arrow.Font = Enum.Font.GothamBold; arrow.TextXAlignment = Enum.TextXAlignment.Center
                arrow.Position = UDim2.new(0, 4, 0, 0); arrow.Size = UDim2.new(0, 18, 1, 0)
                arrow.ZIndex = Z+6; arrow.Parent = gBtn
                local glbl = Instance.new("TextLabel")
                glbl.BackgroundTransparency = 1; glbl.Text = item.name
                glbl.TextColor3 = Theme.TEXT_MUTED; glbl.TextSize = 10
                glbl.Font = FONT_MED; glbl.TextXAlignment = Enum.TextXAlignment.Left
                glbl.Position = UDim2.new(0, 26, 0, 0); glbl.Size = UDim2.new(1, -32, 1, 0)
                glbl.ZIndex = Z+6; glbl.Parent = gBtn
                item.arrow = arrow; item.button = gBtn; item.label = glbl

                gBtn.MouseButton1Click:Connect(function()
                    local state = groupStates[item.name]
                    if not state then return end
                    state.expanded = not state.expanded
                    item.expanded = state.expanded
                    tw(arrow, EASE_SINE, { TextColor3 = state.expanded and Theme.PRIMARY or Theme.TEXT_MUTED })
                    arrow.Text = state.expanded and "v" or ">"
                    if relayoutMenu then relayoutMenu(true) end
                end)
                gBtn.MouseEnter:Connect(function()
                    tw(glbl, EASE_FAST, { TextColor3 = Theme.PRIMARY })
                    tw(arrow, EASE_FAST, { TextColor3 = Theme.PRIMARY })
                end)
                gBtn.MouseLeave:Connect(function()
                    local st = groupStates[item.name]
                    local ec = (st and st.expanded) and Theme.PRIMARY or Theme.TEXT_MUTED
                    tw(glbl, EASE, { TextColor3 = Theme.TEXT_MUTED })
                    tw(arrow, EASE, { TextColor3 = ec })
                end)
            else
                tabIndexCounter = tabIndexCounter + 1
                local tabIdx = tabIndexCounter
                local tabName = item.name
                local btn=Instance.new("TextButton")
                btn.BackgroundColor3=Theme.WHITE; btn.BackgroundTransparency=1
                btn.BorderSizePixel=0; btn.Text=tabName
                btn.TextColor3=(tabIdx==1) and Theme.PRIMARY_DK or Theme.TEXT_MUTED
                btn.TextSize=cfg.tabSize or 11; btn.Font=FONT_MED
                btn.AutoButtonColor=false; btn.TextXAlignment=Enum.TextXAlignment.Left
                btn.Size=UDim2.new(0,ITEM_W,0,ITEM_H)
                btn.Position=UDim2.new(0,ITEM_PAD_X,0,ITEM_START_Y)
                btn.ZIndex=Z+5; corner(btn,8); btn.Parent=navScroll
                local pad=Instance.new("UIPadding")
                pad.PaddingLeft=UDim.new(0, item.group and 24 or 14); pad.Parent=btn
                local capture=tabIdx
                btn.MouseEnter:Connect(function()
                    if currentTab~=capture then
                        btn.BackgroundTransparency=0; btn.BackgroundColor3=Theme.HOVER_SOFT
                        tw(btn,EASE_FAST,{TextColor3=Theme.PRIMARY})
                    end
                end)
                btn.MouseLeave:Connect(function()
                    if currentTab~=capture then
                        tw(btn,EASE,{TextColor3=Theme.TEXT_MUTED})
                        task.delay(0.22,function() if currentTab~=capture and btn then btn.BackgroundTransparency=1 end end)
                    end
                end)
                btn.MouseButton1Click:Connect(function() btn.BackgroundTransparency=1; selectTab(capture) end)
                tabButtons[tabIdx]=btn
                item.button = btn
                item.tabIdx = tabIdx
            end
        end

        relayoutMenu = function(animate)
            local y = ITEM_START_Y
            for _, item in ipairs(flatList) do
                if item.kind == "group" then
                    item.targetY = y
                    y = y + GROUP_H + 2
                    if item.button then
                        item.button.Visible = true
                        if animate then tw(item.button, EASE, { Position = UDim2.new(0, ITEM_PAD_X, 0, item.targetY) })
                        else item.button.Position = UDim2.new(0, ITEM_PAD_X, 0, item.targetY) end
                    end
                else
                    local shouldShow = true
                    if item.group then
                        local gs = groupStates[item.group]
                        if gs and not gs.expanded then shouldShow = false end
                    end
                    item.targetY = y
                    if shouldShow then y = y + ITEM_H + 4 end
                    local btn = item.button
                    if btn then
                        local wasVisible = btn.Visible
                        if shouldShow then
                            if not wasVisible then
                                btn.Position = UDim2.new(0, ITEM_PAD_X, 0, item.targetY)
                                btn.Visible = true
                                btn.TextTransparency = 1
                                if animate then tw(btn, EASE, { TextTransparency = 0 })
                                else btn.TextTransparency = 0 end
                            else
                                if animate then
                                    tw(btn, EASE, { Position = UDim2.new(0, ITEM_PAD_X, 0, item.targetY), TextTransparency = 0 })
                                else
                                    btn.Position = UDim2.new(0, ITEM_PAD_X, 0, item.targetY)
                                    btn.TextTransparency = 0
                                end
                            end
                        else
                            if wasVisible then
                                if animate then
                                    tw(btn, EASE_IN, { TextTransparency = 1 })
                                    task.delay(0.18, function()
                                        if btn and btn.Parent then
                                            local gs = item.group and groupStates[item.group]
                                            if not (gs and gs.expanded) then
                                                btn.Visible = false
                                                btn.TextTransparency = 0
                                            end
                                        end
                                    end)
                                else
                                    btn.Visible = false
                                    btn.TextTransparency = 0
                                end
                            else
                                btn.Visible = false
                            end
                        end
                    end
                end
            end
            navScroll.CanvasSize = UDim2.new(0, 0, 0, y + 10)
        end
        relayoutMenu(false)

        pageContainer=Instance.new("Frame")
        pageContainer.BackgroundTransparency=1
        pageContainer.Position=UDim2.new(0,SIDEBAR_W,0,TITLE_H)
        pageContainer.Size=UDim2.new(1,-SIDEBAR_W,1,-TITLE_H)
        pageContainer.ZIndex=Z+3; pageContainer.ClipsDescendants=true; pageContainer.Parent=panel
        for i=1,#tabButtons do
            local p=Instance.new("CanvasGroup")
            p.BackgroundTransparency=1; p.Position=UDim2.new(0,0,0,0)
            p.Size=UDim2.new(1,0,1,0)
            p.GroupTransparency=(i==1) and 0 or 1
            p.Visible=(i==1); p.ZIndex=Z+3
            p.Parent=pageContainer; pages[i]=p
        end
        task.defer(function() task.wait(0.05); selectTab(1,false) end)
    end

    local body
    if hasTabs then body=pageContainer
    else
        body=Instance.new("Frame")
        body.Name="BodyHolder"; body.BackgroundTransparency=1
        body.Position=UDim2.new(0,0,0,TITLE_H); body.Size=UDim2.new(1,0,1,-TITLE_H)
        body.ZIndex=Z+1; body.Parent=panel
    end

    local ownedExternals = {}
    if shadow then table.insert(ownedExternals, shadow) end

    return {
        frame=panel, body=body, titleBar=titleBar, sidebar=sidebar,
        playerBar=playerBar, tabs=pages, selectTab=selectTab,
        panelStroke=panelStroke,
        getCurrentTab=function() return currentTab end,
        toggleMinimize=toggleMinimize,
        setPosition=function(nx,ny) panel.Position=UDim2.new(0,nx,0,ny) end,
        setSize=function(nw,nh) panel.Size=UDim2.new(0,nw,0,nh) end,
        destroy=function()
            tw(panel, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.In),
                { Size = UDim2.new(0, panel.Size.X.Offset * 0.85, 0, panel.Size.Y.Offset * 0.85),
                  Position = UDim2.new(0, panel.Position.X.Offset + panel.Size.X.Offset * 0.075,
                                       0, panel.Position.Y.Offset + panel.Size.Y.Offset * 0.075) })
            tw(panel, TweenInfo.new(0.22), { BackgroundTransparency = 1 })
            task.delay(0.28, function()
                if activeDropdownClose then pcall(activeDropdownClose); activeDropdownClose = nil end
                for _, ext in ipairs(ownedExternals) do pcall(function() if ext and ext.Parent then ext:Destroy() end end) end
                pcall(function() if panel then panel:Destroy() end end)
            end)
        end,
    }
end

local function createButton(parent, cfg)
    local isCard = cfg.layout == "card"
    local W = cfg.w or 120; local H = cfg.h or (isCard and 42 or 34)
    local X = cfg.x or 0; local Y = cfg.y or 0
    local btn = Instance.new("TextButton")
    local customBg = cfg.bgColor; local customTx = cfg.textColor; local customBd = cfg.borderColor
    btn.BackgroundColor3 = customBg or Theme.WHITE; btn.BorderSizePixel = 0
    btn.Text = isCard and "" or (cfg.text or "Button")
    btn.TextColor3 = customTx or Theme.PRIMARY; btn.TextSize = cfg.textSize or 12
    btn.Font = FONT_MED; btn.AutoButtonColor = false
    btn.Position = UDim2.new(0, X, 0, Y); btn.Size = UDim2.new(0, W, 0, H)
    btn.ZIndex = cfg.zIndex or 5; corner(btn, cfg.radius or 6)
    local st = stroke(btn, customBd or Theme.PRIMARY, 1); btn.Parent = parent
    local enabled = cfg.enabled ~= false
    local baseBg = customBg or Theme.WHITE
    local baseTx = customTx or Theme.PRIMARY
    local baseBd = customBd or Theme.PRIMARY
    local iconLabel, titleLabel
    if isCard then
        titleLabel = createLabel(btn, { text = cfg.text or "", x = cfg.paddingLeft or 14, y = 0, w = W - 46, h = H, textSize = cfg.textSize or 12, color = customTx or Theme.TEXT, font = FONT_MED, align = Enum.TextXAlignment.Left, zIndex = 6 })
        iconLabel = createLabel(btn, { text = cfg.icon or ">", x = W - 30, y = 0, w = 20, h = H, textSize = cfg.iconSize or 16, color = cfg.iconColor or Theme.PRIMARY, font = FONT_MED, align = Enum.TextXAlignment.Center, zIndex = 6 })
    end
    if not enabled then
        btn.BackgroundColor3 = Theme.DISABLED_BG
        if not isCard then btn.TextColor3 = Theme.DISABLED_FG end
        st.Color = Theme.BORDER
    end
    if cfg.favoriteId then createStar(btn, cfg.favoriteId, W - 24, 2) end
    if cfg.tooltip then
        btn.MouseEnter:Connect(function()
            local mp = UserInputService:GetMouseLocation()
            showTooltip(btn, cfg.tooltip, mp.X + 12, mp.Y + 12)
        end)
        btn.MouseLeave:Connect(function() hideTooltip() end)
    end
    btn.MouseEnter:Connect(function()
        if not enabled then return end
        tw(btn, EASE_FAST, { BackgroundColor3 = Theme.HOVER_BG, TextColor3 = Theme.PRIMARY_DK, Position = UDim2.new(0, X, 0, Y - 2) })
        tw(st, EASE_FAST, { Color = Theme.PRIMARY_DK })
        if iconLabel then
            tw(iconLabel, EASE_FAST, { TextColor3 = Theme.PRIMARY_DK })
            tw(iconLabel, EASE_SINE, { Position = UDim2.new(0, W - 26, 0, 0) })
        end
    end)
    btn.MouseLeave:Connect(function()
        if not enabled then return end
        tw(btn, EASE_BACK, { BackgroundColor3 = baseBg, TextColor3 = baseTx, Position = UDim2.new(0, X, 0, Y) })
        tw(st, EASE, { Color = baseBd })
        if iconLabel then
            tw(iconLabel, EASE, { TextColor3 = baseTx })
            tw(iconLabel, EASE_SINE, { Position = UDim2.new(0, W - 30, 0, 0) })
        end
    end)
    btn.MouseButton1Down:Connect(function()
        if not enabled then return end
        local mx = UserInputService:GetMouseLocation()
        local btnPos = btn.AbsolutePosition
        ripple(btn, mx.X - btnPos.X, mx.Y - btnPos.Y, Theme.PRIMARY)
        tw(btn, EASE_FAST, { BackgroundColor3 = Theme.PRIMARY_DK, TextColor3 = Color3.fromRGB(255,255,255), Position = UDim2.new(0, X, 0, Y) })
        local t1 = TweenService:Create(btn, EASE_FAST, { Size = UDim2.new(0, W * 0.96, 0, H * 0.94) })
        t1.Completed:Connect(function() TweenService:Create(btn, EASE_BACK, { Size = UDim2.new(0, W, 0, H) }):Play() end)
        t1:Play()
    end)
    btn.MouseButton1Up:Connect(function()
        if not enabled then return end
        if btn:IsMouseOver() then
            tw(btn, EASE, { BackgroundColor3 = Theme.HOVER_BG, TextColor3 = Theme.PRIMARY_DK, Position = UDim2.new(0, X, 0, Y - 2) })
        else
            tw(btn, EASE_BACK, { BackgroundColor3 = baseBg, TextColor3 = baseTx, Position = UDim2.new(0, X, 0, Y) })
        end
    end)
    if cfg.onClick and enabled then
        btn.MouseButton1Click:Connect(function() shine(btn); cfg.onClick(btn) end)
    end
    return btn
end

local function createToggle(parent, cfg)
    local W, H = cfg.w or 36, cfg.h or 20
    local container = Instance.new("Frame")
    container.BackgroundTransparency=1
    container.Position=UDim2.new(0,cfg.x or 0,0,cfg.y or 0)
    container.Size=UDim2.new(0,W,0,H); container.ZIndex=cfg.zIndex or 5; container.Parent=parent
    local track=Instance.new("Frame")
    track.BackgroundColor3=Theme.TRACK; track.BorderSizePixel=0
    track.Size=UDim2.new(1,0,1,0); corner(track,H/2); track.ZIndex=5; track.Parent=container
    local knobSize=H-4
    local knob=Instance.new("Frame")
    knob.BackgroundColor3=Color3.fromRGB(255,255,255); knob.BorderSizePixel=0
    knob.Size=UDim2.new(0,knobSize,0,knobSize); knob.Position=UDim2.new(0,2,0,2)
    corner(knob,knobSize/2); knob.ZIndex=6; knob.Parent=container
    local ks = Instance.new("Frame")
    ks.BackgroundColor3 = Color3.fromRGB(0,0,0); ks.BackgroundTransparency = 0.85
    ks.BorderSizePixel = 0; ks.Size = UDim2.new(1, 0, 1, 0); ks.Position = UDim2.new(0, 0, 0, 1)
    corner(ks, knobSize/2); ks.ZIndex = 5; ks.Parent = knob
    local state=cfg.value or false; local onChange=cfg.onChange
    local onC = cfg.onColor or Theme.PRIMARY
    local offC = cfg.offColor or Theme.TRACK
    local function apply(animate,elastic)
        local info=animate and (elastic and EASE_ELASTIC or EASE) or EASE_NONE
        tw(track,animate and EASE or EASE_NONE,{BackgroundColor3=state and onC or offC})
        tw(knob,info,{Position=UDim2.new(0,state and (W-knobSize-2) or 2,0,2)})
    end
    apply(false,false)
    local click=Instance.new("TextButton")
    click.BackgroundTransparency=1; click.Text=""; click.AutoButtonColor=false
    click.Size=UDim2.new(1,0,1,0); click.ZIndex=7; click.Parent=container
    click.MouseEnter:Connect(function()
        if not state then tw(track, EASE_FAST, { BackgroundColor3 = Color3.fromRGB(210,214,220) }) end
    end)
    click.MouseLeave:Connect(function()
        if not state then tw(track, EASE, { BackgroundColor3 = offC }) end
    end)
    click.MouseButton1Click:Connect(function()
        state=not state
        tw(container, EASE_FAST, { Size = UDim2.new(0, W - 2, 0, H - 2) })
        task.delay(0.12, function() tw(container, EASE_BACK, { Size = UDim2.new(0, W, 0, H) }) end)
        apply(true,true)
        if onChange then onChange(state) end
    end)
    return {container=container,getValue=function() return state end}
end

local function createSlider(parent, cfg)
    local W = cfg.w or 220; local H = cfg.h or 26
    local minV, maxV = cfg.min or 0, cfg.max or 100
    local value = cfg.value or minV; local step = cfg.step or 0
    local onChange = cfg.onChange; local showValue = cfg.showValue ~= false
    local decimals = cfg.decimals or 0; local valueW = cfg.valueWidth or 46; local gap = 8
    local container = Instance.new("Frame")
    container.BackgroundTransparency=1
    container.Position=UDim2.new(0,cfg.x or 0,0,cfg.y or 0)
    container.Size=UDim2.new(0,W,0,H); container.ZIndex=cfg.zIndex or 5; container.Parent=parent
    local sliderW = showValue and math.max(W-valueW-gap, 40) or W
    local function formatValue(v) if decimals>0 then return string.format("%."..decimals.."f",v) end return tostring(math.floor(v+0.5)) end
    local trackH=4
    local track=Instance.new("Frame")
    track.BackgroundColor3=Theme.TRACK; track.BorderSizePixel=0
    track.AnchorPoint=Vector2.new(0,0.5); track.Position=UDim2.new(0,0,0.5,0)
    track.Size=UDim2.new(0,sliderW,0,trackH); corner(track,trackH/2); track.ZIndex=5; track.Parent=container
    local primaryColor = cfg.color or Theme.PRIMARY
    local fill=Instance.new("Frame")
    fill.BackgroundColor3=primaryColor; fill.BorderSizePixel=0
    fill.Size=UDim2.new(0,0,1,0); corner(fill,trackH/2); fill.ZIndex=6; fill.Parent=track
    local fillGrad = Instance.new("UIGradient", fill)
    fillGrad.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, primaryColor), ColorSequenceKeypoint.new(1, primaryColor:Lerp(Color3.fromRGB(255,255,255), 0.25)) })
    local knobSize=14
    local knob=Instance.new("Frame")
    knob.BackgroundColor3=primaryColor; knob.BorderSizePixel=0
    knob.AnchorPoint=Vector2.new(0.5,0.5); knob.Position=UDim2.new(0,0,0.5,0)
    knob.Size=UDim2.new(0,knobSize,0,knobSize); corner(knob,knobSize/2); knob.ZIndex=7; knob.Parent=container
    local ksh = Instance.new("Frame")
    ksh.BackgroundColor3 = Color3.fromRGB(0,0,0); ksh.BackgroundTransparency = 0.85
    ksh.BorderSizePixel = 0; ksh.Size = UDim2.new(1, 2, 1, 2); ksh.Position = UDim2.new(0, -1, 0, 1)
    corner(ksh, knobSize/2); ksh.ZIndex = 6; ksh.Parent = knob
    local valueBtn, valueInput
    if showValue then
        valueBtn = Instance.new("TextButton")
        valueBtn.BackgroundColor3=Theme.WHITE; valueBtn.BackgroundTransparency=1
        valueBtn.BorderSizePixel=0; valueBtn.Text=formatValue(value)
        valueBtn.TextColor3=Theme.PRIMARY_DK; valueBtn.TextSize=12; valueBtn.Font=FONT_MED
        valueBtn.AutoButtonColor=false; valueBtn.Position=UDim2.new(0,sliderW+gap,0,0)
        valueBtn.Size=UDim2.new(0,valueW,1,0); valueBtn.ZIndex=6; corner(valueBtn,5); valueBtn.Parent=container
        valueInput = Instance.new("TextBox")
        valueInput.BackgroundColor3=Theme.WHITE; valueInput.BorderSizePixel=0
        valueInput.Text=formatValue(value); valueInput.TextColor3=Theme.TEXT
        valueInput.TextSize=12; valueInput.Font=FONT_MED; valueInput.ClearTextOnFocus=false
        valueInput.TextXAlignment=Enum.TextXAlignment.Center; valueInput.TextYAlignment=Enum.TextYAlignment.Center
        valueInput.Position=UDim2.new(0,sliderW+gap,0,0); valueInput.Size=UDim2.new(0,valueW,1,0)
        valueInput.Visible=false; valueInput.ZIndex=8; corner(valueInput,5); stroke(valueInput,Theme.PRIMARY,1.5)
        valueInput.Parent=container
        valueBtn.MouseEnter:Connect(function()
            valueBtn.BackgroundTransparency=0
            tw(valueBtn,EASE_FAST,{BackgroundColor3=Theme.HOVER_BG}); pulse(valueBtn, 1.08, 0.1)
        end)
        valueBtn.MouseLeave:Connect(function()
            tw(valueBtn,EASE,{BackgroundColor3=Theme.WHITE})
            task.delay(0.22,function() if valueBtn and valueBtn.Parent and valueInput and not valueInput.Visible then valueBtn.BackgroundTransparency=1 end end)
        end)
        valueBtn.MouseButton1Click:Connect(function()
            valueBtn.Visible=false; valueInput.Text=formatValue(value); valueInput.Visible=true; valueInput:CaptureFocus()
        end)
        valueInput.FocusLost:Connect(function()
            local n = tonumber(valueInput.Text)
            if n then
                n = math.clamp(n,minV,maxV)
                if step and step>0 then n = math.floor((n-minV)/step+0.5)*step+minV; n = math.clamp(n,minV,maxV) end
                value = n
                local r = (maxV==minV) and 0 or (value-minV)/(maxV-minV)
                local trackW = track.AbsoluteSize.X
                if trackW>0 then
                    tw(fill,EASE_FAST,{Size=UDim2.new(r,0,1,0)})
                    tw(knob,EASE_ELASTIC,{Position=UDim2.new(0,r*trackW,0.5,0)})
                end
                valueBtn.Text = formatValue(value)
                if onChange then onChange(value) end
            end
            valueInput.Visible=false; valueBtn.Visible=true
        end)
    end
    local function ratio() if maxV==minV then return 0 end return math.clamp((value-minV)/(maxV-minV),0,1) end
    local function applyVisual(animate, elastic)
        local r=ratio(); local trackW=track.AbsoluteSize.X
        if trackW<=0 then return end
        tw(fill,animate and EASE_FAST or EASE_NONE,{Size=UDim2.new(r,0,1,0)})
        if elastic then tw(knob, EASE_ELASTIC, {Position=UDim2.new(0,r*trackW,0.5,0)})
        else tw(knob,animate and EASE_FAST or EASE_NONE,{Position=UDim2.new(0,r*trackW,0.5,0)}) end
    end
    local function setValue(v, silent)
        v=math.clamp(v,minV,maxV)
        if step and step>0 then v=math.floor((v-minV)/step+0.5)*step+minV; v=math.clamp(v,minV,maxV) end
        local changed=v~=value; value=v
        applyVisual(true, false)
        if valueBtn then
            valueBtn.Text = formatValue(value)
            if changed then
                tw(valueBtn, EASE_SINE, { TextColor3 = Theme.PRIMARY })
                task.delay(0.15, function() if valueBtn and valueBtn.Parent then tw(valueBtn, EASE, { TextColor3 = Theme.PRIMARY_DK }) end end)
            end
        end
        if changed and not silent and onChange then onChange(value) end
    end
    local dragging=false
    local function fromAbsX(absX)
        local sx=track.AbsolutePosition.X; local w=track.AbsoluteSize.X
        if w<=0 then return end
        local r=math.clamp((absX-sx)/w,0,1)
        setValue(minV+r*(maxV-minV))
    end
    local hit=Instance.new("TextButton")
    hit.BackgroundTransparency=1; hit.Text=""; hit.AutoButtonColor=false
    hit.Position=UDim2.new(0,0,0,0); hit.Size=UDim2.new(0,sliderW,1,0); hit.ZIndex=7; hit.Parent=container
    hit.MouseEnter:Connect(function() if dragging then return end tw(knob,EASE_SINE,{Size=UDim2.new(0,knobSize+4,0,knobSize+4)}) end)
    hit.MouseLeave:Connect(function() if dragging then return end tw(knob,EASE,{Size=UDim2.new(0,knobSize,0,knobSize)}) end)
    hit.InputBegan:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
            dragging=true
            tw(knob,EASE_SINE,{Size=UDim2.new(0,knobSize+6,0,knobSize+6)})
            fromAbsX(input.Position.X)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch) then fromAbsX(input.Position.X) end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
            if dragging then dragging=false; tw(knob,EASE_ELASTIC,{Size=UDim2.new(0,knobSize,0,knobSize)}) end
        end
    end)
    task.defer(function() task.wait(0.05); applyVisual(false, false) end)
    return {container=container,getValue=function() return value end,setValue=setValue}
end

local function createTextBox(parent, cfg)
    local W, H = cfg.w or 220, cfg.h or 28
    local X, Y = cfg.x or 0, cfg.y or 0
    local container = Instance.new("Frame")
    container.BackgroundColor3=cfg.bgColor or Theme.WHITE; container.BorderSizePixel=0
    container.Position=UDim2.new(0,X,0,Y); container.Size=UDim2.new(0,W,0,H)
    container.ZIndex=cfg.zIndex or 5; corner(container,cfg.radius or 6)
    local st=stroke(container,cfg.borderColor or Theme.BORDER,1); container.Parent=parent
    local tb=Instance.new("TextBox")
    tb.BackgroundTransparency=1; tb.Text=cfg.text or ""
    tb.PlaceholderText=cfg.placeholder or ""; tb.PlaceholderColor3=cfg.placeholderColor or Theme.TEXT_MUTED
    tb.TextColor3=cfg.textColor or Theme.TEXT; tb.TextSize=cfg.textSize or 12; tb.Font=FONT_REG
    tb.ClearTextOnFocus=false; tb.TextXAlignment=cfg.align or Enum.TextXAlignment.Left
    tb.TextYAlignment=Enum.TextYAlignment.Center; tb.Position=UDim2.new(0,10,0,0); tb.Size=UDim2.new(1,-20,1,0)
    tb.ZIndex=6; tb.Parent=container
    tb.Focused:Connect(function()
        tw(st,EASE_FAST,{Color=Theme.PRIMARY,Thickness=1.5})
        tw(container, EASE_SINE, { Size = UDim2.new(0, W + 2, 0, H + 2), Position = UDim2.new(0, X - 1, 0, Y - 1) })
    end)
    tb.FocusLost:Connect(function()
        tw(st,EASE,{Color=cfg.borderColor or Theme.BORDER,Thickness=1})
        tw(container, EASE_BACK, { Size = UDim2.new(0, W, 0, H), Position = UDim2.new(0, X, 0, Y) })
        if cfg.onChange then cfg.onChange(tb.Text) end
    end)
    return tb
end

local function createCheckbox(parent, cfg)
    local W, H = cfg.w or 200, cfg.h or 20; local boxSize = cfg.boxSize or 16
    local container=Instance.new("Frame")
    container.BackgroundTransparency=1
    container.Position=UDim2.new(0,cfg.x or 0,0,cfg.y or 0)
    container.Size=UDim2.new(0,W,0,H); container.ZIndex=cfg.zIndex or 5; container.Parent=parent
    local box=Instance.new("Frame")
    box.BackgroundColor3=Theme.WHITE; box.BorderSizePixel=0
    box.AnchorPoint=Vector2.new(0,0.5); box.Position=UDim2.new(0,0,0.5,0)
    box.Size=UDim2.new(0,boxSize,0,boxSize); box.ZIndex=5; corner(box,4)
    local boxStroke=stroke(box,Theme.BORDER,1.5); box.Parent=container
    local mark=Instance.new("Frame")
    mark.BackgroundColor3=Color3.fromRGB(255,255,255); mark.BorderSizePixel=0
    mark.AnchorPoint=Vector2.new(0.5,0.5); mark.Position=UDim2.new(0.5,0,0.5,0)
    mark.Size=UDim2.new(0,0,0,0); mark.ZIndex=6; corner(mark,2)
    mark.BackgroundTransparency=1; mark.Parent=box
    createLabel(container,{text=cfg.label or "",x=boxSize+8,y=0,w=W-boxSize-8,h=H,textSize=cfg.textSize or 12,color=Theme.TEXT,zIndex=6})
    local state=cfg.value or false; local onChange=cfg.onChange
    local ck = cfg.color or Theme.PRIMARY
    local function apply(animate)
        if state then
            tw(box,animate and EASE or EASE_NONE,{BackgroundColor3=ck})
            tw(boxStroke,animate and EASE or EASE_NONE,{Color=ck})
            mark.Size = UDim2.new(0, 0, 0, 0); mark.BackgroundTransparency = 1
            local t = TweenService:Create(mark, EASE_FAST, { Size = UDim2.new(0, 9, 0, 9), BackgroundTransparency = 0 })
            t.Completed:Connect(function() if mark and mark.Parent then tw(mark, EASE_ELASTIC, { Size = UDim2.new(0, 6, 0, 6) }) end end)
            t:Play()
        else
            tw(box,animate and EASE or EASE_NONE,{BackgroundColor3=Theme.WHITE})
            tw(boxStroke,animate and EASE or EASE_NONE,{Color=Theme.BORDER})
            tw(mark,animate and EASE_IN or EASE_NONE,{Size=UDim2.new(0,0,0,0),BackgroundTransparency=1})
        end
    end
    apply(false)
    local click=Instance.new("TextButton")
    click.BackgroundTransparency=1; click.Text=""; click.AutoButtonColor=false
    click.Size=UDim2.new(1,0,1,0); click.ZIndex=8; click.Parent=container
    click.MouseButton1Click:Connect(function() state=not state; apply(true); pulse(box, 1.2, 0.1); if onChange then onChange(state) end end)
    return {container=container,getValue=function() return state end}
end

local function createColorPicker(parent, cfg)
    local palette = cfg.palette or {
        Color3.fromRGB(37,99,235), Color3.fromRGB(220,38,38), Color3.fromRGB(16,185,129), Color3.fromRGB(245,158,11),
        Color3.fromRGB(139,92,246), Color3.fromRGB(20,184,166), Color3.fromRGB(236,72,153), Color3.fromRGB(31,41,55),
    }
    local names = cfg.names or {"lan","hong","lv","cheng","zi","qing","mei","hei"}
    local size=cfg.size or 32; local gap=cfg.gap or 10; local cols=cfg.cols or 8
    local rows=math.ceil(#palette/cols); local W=cols*size+(cols-1)*gap; local H=rows*size+(rows-1)*gap
    local container=Instance.new("Frame")
    container.BackgroundTransparency=1
    container.Position=UDim2.new(0,cfg.x or 0,0,cfg.y or 0)
    container.Size=UDim2.new(0,W,0,H); container.ZIndex=cfg.zIndex or 5; container.Parent=parent
    local selectedIndex=cfg.value or 1; local onChange=cfg.onChange
    local swatches={}; local strokes={}
    local function refresh(animate)
        for i,sw in ipairs(swatches) do
            local so=strokes[i]
            if i==selectedIndex then
                tw(sw,animate and EASE_FAST or EASE_NONE,{Size=UDim2.new(0,size+4,0,size+4)})
                tw(so,animate and EASE_FAST or EASE_NONE,{Thickness=3,Color=Theme.PRIMARY,Transparency=0})
            else
                tw(sw,animate and EASE or EASE_NONE,{Size=UDim2.new(0,size,0,size)})
                tw(so,animate and EASE or EASE_NONE,{Thickness=1,Color=Theme.BORDER,Transparency=0.5})
            end
        end
    end
    for i,col in ipairs(palette) do
        local c=(i-1)%cols; local r=math.floor((i-1)/cols)
        local sw=Instance.new("TextButton")
        sw.BackgroundColor3=col; sw.BorderSizePixel=0; sw.Text=""; sw.AutoButtonColor=false
        sw.AnchorPoint=Vector2.new(0.5,0.5)
        sw.Position=UDim2.new(0,c*(size+gap)+size/2,0,r*(size+gap)+size/2)
        sw.Size=UDim2.new(0,size,0,size); sw.ZIndex=5; corner(sw,6)
        local s=stroke(sw,Theme.BORDER,1); sw.Parent=container
        local capture=i
        sw.MouseButton1Click:Connect(function()
            selectedIndex=capture; refresh(true); pulse(sw, 1.25, 0.1)
            if onChange then onChange(palette[capture],capture,names[capture]) end
        end)
        swatches[i]=sw; strokes[i]=s
    end
    refresh(false)
    return {container=container,getValue=function() return palette[selectedIndex],selectedIndex end}
end

local function createDescriptionBox(parent, cfg)
    local W=cfg.w or 300; local padX=cfg.padX or 14; local padY=cfg.padY or 12
    local box=Instance.new("Frame")
    box.BackgroundColor3=cfg.bgColor or Theme.PANEL_SOFT; box.BorderSizePixel=0
    box.Position=UDim2.new(0,cfg.x or 0,0,cfg.y or 0)
    box.Size=UDim2.new(0,W,0,0); box.AutomaticSize=Enum.AutomaticSize.Y
    box.ZIndex=cfg.zIndex or 5; corner(box,8)
    stroke(box,cfg.borderColor or Theme.BORDER,1); box.Parent=parent
    local layout=Instance.new("UIListLayout")
    layout.FillDirection=Enum.FillDirection.Vertical; layout.SortOrder=Enum.SortOrder.LayoutOrder
    layout.Padding=UDim.new(0,6); layout.Parent=box
    local pad=Instance.new("UIPadding")
    pad.PaddingTop=UDim.new(0,padY); pad.PaddingBottom=UDim.new(0,padY)
    pad.PaddingLeft=UDim.new(0,padX); pad.PaddingRight=UDim.new(0,padX); pad.Parent=box
    if cfg.title then
        local title = Instance.new("TextLabel")
        title.BackgroundTransparency=1; title.Text=cfg.title
        title.TextColor3=cfg.titleColor or Theme.TEXT; title.TextSize=cfg.titleSize or 12
        title.Font=FONT_MED; title.TextXAlignment=Enum.TextXAlignment.Left
        title.TextYAlignment=Enum.TextYAlignment.Top; title.LayoutOrder=1
        title.Size=UDim2.new(1,0,0,18); title.ZIndex=6; title.Parent=box
    end
    local body=Instance.new("TextLabel")
    body.BackgroundTransparency=1; body.Text=cfg.text or ""
    body.TextColor3=cfg.textColor or Theme.TEXT; body.TextSize=cfg.textSize or 11
    body.Font=FONT_REG; body.TextXAlignment=Enum.TextXAlignment.Left
    body.TextYAlignment=Enum.TextYAlignment.Top; body.TextWrapped=true
    body.LayoutOrder=2; body.Size=UDim2.new(1,0,0,0); body.AutomaticSize=Enum.AutomaticSize.Y
    body.ZIndex=6; body.Parent=box
    return box
end

local function createDropdownBase(parent, cfg, multi)
    local W=cfg.w or 200; local H=cfg.h or 30
    local items=cfg.items or {}
    local ITEM_H=cfg.itemHeight or 24; local LIST_GAP=18; local LIST_PAD=4
    local container=Instance.new("Frame")
    container.BackgroundTransparency=1
    container.Position=UDim2.new(0,cfg.x or 0,0,cfg.y or 0)
    container.Size=UDim2.new(0,W,0,H); container.ZIndex=cfg.zIndex or 5; container.Parent=parent
    local btn=Instance.new("TextButton")
    btn.BackgroundColor3=Theme.WHITE; btn.BorderSizePixel=0; btn.Text=""
    btn.AutoButtonColor=false; btn.Size=UDim2.new(1,0,1,0); btn.ZIndex=5; corner(btn,6)
    local btnStroke=stroke(btn,Theme.BORDER,1); btn.Parent=container
    local valueLabel=Instance.new("TextLabel")
    valueLabel.BackgroundTransparency=1; valueLabel.Text=""
    valueLabel.TextColor3=Theme.TEXT; valueLabel.TextSize=11; valueLabel.Font=FONT_REG
    valueLabel.TextXAlignment=Enum.TextXAlignment.Left; valueLabel.TextTruncate=Enum.TextTruncate.AtEnd
    valueLabel.Position=UDim2.new(0,10,0,0); valueLabel.Size=UDim2.new(1,-32,1,0); valueLabel.ZIndex=6; valueLabel.Parent=btn
    local arrow=Instance.new("TextLabel")
    arrow.BackgroundTransparency=1; arrow.Text="v"; arrow.TextColor3=Theme.TEXT_MUTED
    arrow.TextSize=12; arrow.Font=FONT_MED; arrow.TextXAlignment=Enum.TextXAlignment.Center
    arrow.AnchorPoint=Vector2.new(1,0.5); arrow.Position=UDim2.new(1,-8,0.5,0)
    arrow.Size=UDim2.new(0,16,0,16); arrow.ZIndex=6; arrow.Parent=btn
    local list=Instance.new("Frame")
    list.BackgroundColor3=Theme.WHITE; list.BorderSizePixel=0
    list.Size=UDim2.new(0,W,0,0); list.BackgroundTransparency=1
    list.Visible=false; list.ClipsDescendants=true; list.ZIndex=91; corner(list,6)
    local listStroke=stroke(list,Theme.BORDER,1); listStroke.Transparency=1; list.Parent=listLayer
    local innerPad=Instance.new("UIPadding")
    innerPad.PaddingTop=UDim.new(0,LIST_PAD); innerPad.PaddingBottom=UDim.new(0,LIST_PAD); innerPad.Parent=list
    local state
    if multi then state={}; if type(cfg.value)=="table" then for k,v in pairs(cfg.value) do state[k]=v end end
    else state=cfg.value; if state==nil or state=="" then state=items[1] or "" end end
    local onChange=cfg.onChange
    local itemMarks={}; local itemRows={}; local isOpen=false
    local function isSelected(i) if multi then return state[i]==true else return state==items[i] end end
    local function refreshLabel()
        if multi then
            local count=0; for _,v in pairs(state) do if v then count=count+1 end end
            if count==0 then valueLabel.Text=cfg.placeholder or "qing xuan ze"; valueLabel.TextColor3=Theme.TEXT_MUTED
            else valueLabel.Text="yi xuan "..count.." xiang"; valueLabel.TextColor3=Theme.TEXT end
        else
            if state==nil or state=="" then valueLabel.Text=cfg.placeholder or "qing xuan ze"; valueLabel.TextColor3=Theme.TEXT_MUTED
            else valueLabel.Text=tostring(state); valueLabel.TextColor3=Theme.TEXT end
        end
    end
    local function refreshMarks()
        for i,mbox in ipairs(itemMarks) do
            local inner=mbox:FindFirstChild("InnerMark")
            if isSelected(i) then
                tw(mbox,EASE_FAST,{BackgroundColor3=Theme.PRIMARY})
                if inner then
                    inner.Size = UDim2.new(0, 0, 0, 0)
                    local t = TweenService:Create(inner, EASE_FAST, { Size = UDim2.new(0, 7, 0, 7), BackgroundTransparency = 0 })
                    t.Completed:Connect(function() if inner and inner.Parent then tw(inner, EASE_ELASTIC, { Size = UDim2.new(0, 5, 0, 5) }) end end)
                    t:Play()
                end
            else
                tw(mbox,EASE,{BackgroundColor3=Theme.WHITE})
                if inner then tw(inner,EASE,{Size=UDim2.new(0,0,0,0),BackgroundTransparency=1}) end
            end
        end
    end
    local function closeList()
        if not isOpen then return end
        isOpen=false; interceptLayer.Visible=false
        if activeDropdownClose==closeList then activeDropdownClose=nil end
        tw(list,TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Size=UDim2.new(0,list.Size.X.Offset,0,0), BackgroundTransparency=1})
        tw(listStroke,EASE_IN,{Transparency=1}); tw(arrow,EASE_BACK,{Text="v"}); tw(btnStroke,EASE,{Color=Theme.BORDER})
        task.delay(0.24,function() if not isOpen then list.Visible=false end end)
    end
    local function openList()
        if activeDropdownClose and activeDropdownClose~=closeList then activeDropdownClose() end
        local btnPos=btn.AbsolutePosition; local btnSize=btn.AbsoluteSize
        local listH=#items*ITEM_H+LIST_PAD*2; local listW=btnSize.X
        list.Position=UDim2.new(0,btnPos.X,0,btnPos.Y+btnSize.Y+LIST_GAP)
        list.Size=UDim2.new(0,listW,0,0); list.Visible=true; isOpen=true; interceptLayer.Visible=true
        tw(list,TweenInfo.new(0.28,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Size=UDim2.new(0,listW,0,listH)})
        tw(list,EASE_FAST,{BackgroundTransparency=0}); tw(listStroke,EASE_FAST,{Transparency=0})
        for i,row in ipairs(itemRows) do
            row.Position=UDim2.new(0,-14,0,(i-1)*ITEM_H); row.BackgroundTransparency = 1
            task.delay(0.03*(i-1),function()
                if not isOpen then return end
                tw(row,EASE_BACK,{Position=UDim2.new(0,0,0,(i-1)*ITEM_H)})
            end)
        end
        tw(arrow,EASE_FAST,{Text="^"}); tw(btnStroke,EASE_FAST,{Color=Theme.PRIMARY})
        activeDropdownClose=closeList
    end
    for i,item in ipairs(items) do
        local row=Instance.new("TextButton")
        row.BackgroundColor3=Theme.WHITE; row.BackgroundTransparency=1
        row.BorderSizePixel=0; row.Text=""; row.AutoButtonColor=false
        row.Position=UDim2.new(0,0,0,(i-1)*ITEM_H); row.Size=UDim2.new(1,0,0,ITEM_H)
        row.ZIndex=92; corner(row,5); row.Parent=list
        createLabel(row,{text=item,x=10,y=0,w=W-42,h=ITEM_H,textSize=11,color=Theme.TEXT,zIndex=93})
        local mbox=Instance.new("Frame")
        mbox.BackgroundColor3=Theme.WHITE; mbox.BorderSizePixel=0
        mbox.AnchorPoint=Vector2.new(1,0.5); mbox.Position=UDim2.new(1,-8,0.5,0)
        mbox.Size=UDim2.new(0,12,0,12); mbox.ZIndex=93; corner(mbox,3); stroke(mbox,Theme.BORDER,1); mbox.Parent=row
        local inner=Instance.new("Frame")
        inner.Name="InnerMark"; inner.BackgroundColor3=Color3.fromRGB(255,255,255); inner.BorderSizePixel=0
        inner.AnchorPoint=Vector2.new(0.5,0.5); inner.Position=UDim2.new(0.5,0,0.5,0)
        inner.Size=UDim2.new(0,0,0,0); inner.ZIndex=94; corner(inner,1); inner.BackgroundTransparency=1; inner.Parent=mbox
        row.MouseEnter:Connect(function() row.BackgroundTransparency=0; tw(row,EASE_FAST,{BackgroundColor3=Theme.HOVER_SOFT}) end)
        row.MouseLeave:Connect(function() tw(row,EASE,{BackgroundTransparency=1}) end)
        row.MouseButton1Click:Connect(function()
            if multi then
                state[i]=not state[i]; refreshMarks(); refreshLabel()
                if onChange then
                    local picked={}
                    for k,v in pairs(state) do if v then picked[#picked+1]=items[k] end end
                    onChange(picked)
                end
            else
                state=items[i]; refreshLabel(); refreshMarks(); closeList()
                if onChange then onChange(state) end
            end
        end)
        itemMarks[i]=mbox; itemRows[i]=row
    end
    refreshLabel()
    task.defer(function() task.wait(0.05); refreshMarks() end)
    btn.MouseButton1Click:Connect(function() if isOpen then closeList() else openList() end end)
    btn.MouseEnter:Connect(function() if not isOpen then tw(btnStroke,EASE_FAST,{Color=Theme.PRIMARY}) end end)
    btn.MouseLeave:Connect(function() if not isOpen then tw(btnStroke,EASE,{Color=Theme.BORDER}) end end)
    return {container=container,getValue=function() return state end,
        setValue=function(v) state=v; refreshLabel(); refreshMarks() end,
        closeList=closeList}
end

local function staggerChildren(parent, delayPerItem)
    local children = {}
    for _, child in ipairs(parent:GetChildren()) do
        if child:IsA("Frame") or child:IsA("TextButton") then table.insert(children, child) end
    end
    table.sort(children, function(a, b) return a.Position.Y.Offset < b.Position.Y.Offset end)
    for i, c in ipairs(children) do
        local targetY = c.Position.Y.Offset
        c.Position = UDim2.new(0, c.Position.X.Offset, 0, targetY - 10)
        local trans0 = c.BackgroundTransparency
        c.BackgroundTransparency = 1
        task.delay((i - 1) * (delayPerItem or 0.04), function()
            tw(c, TweenInfo.new(0.32, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Position = UDim2.new(0, c.Position.X.Offset, 0, targetY) })
            tw(c, EASE, { BackgroundTransparency = trans0 })
        end)
    end
end

local ui = {}
ui.Theme = Theme
ui.ScreenGui = uiGui
ui.Ease = { NORMAL=EASE, FAST=EASE_FAST, BACK=EASE_BACK, IN=EASE_IN, SOFT=EASE_SOFT, ELASTIC=EASE_ELASTIC }

function ui.createPanel(cfg) cfg=cfg or {}; return createPanel(resolveParent(cfg), cfg) end
function ui.createLabel(cfg) cfg=cfg or {}; return createLabel(resolveParent(cfg), cfg) end
function ui.createButton(cfg) cfg=cfg or {}; return createButton(resolveParent(cfg), cfg) end
function ui.createToggle(cfg) cfg=cfg or {}; return createToggle(resolveParent(cfg), cfg) end
function ui.createSlider(cfg) cfg=cfg or {}; return createSlider(resolveParent(cfg), cfg) end
function ui.createTextBox(cfg) cfg=cfg or {}; return createTextBox(resolveParent(cfg), cfg) end
function ui.createCheckbox(cfg) cfg=cfg or {}; return createCheckbox(resolveParent(cfg), cfg) end
function ui.createColorPicker(cfg) cfg=cfg or {}; return createColorPicker(resolveParent(cfg), cfg) end
function ui.createDescriptionBox(cfg) cfg=cfg or {}; return createDescriptionBox(resolveParent(cfg), cfg) end
function ui.createDropdown(cfg) cfg=cfg or {}; return createDropdownBase(resolveParent(cfg), cfg, false) end
function ui.createMultiDropdown(cfg) cfg=cfg or {}; return createDropdownBase(resolveParent(cfg), cfg, true) end
function ui.createBadge(cfg) cfg=cfg or {}; return createBadge(resolveParent(cfg), cfg) end
function ui.notify(cfg) createToast(cfg or {}) end
function ui.showTooltip(target, text, x, y) showTooltip(target, text, x, y) end
function ui.hideTooltip() hideTooltip() end
function ui.getFavorites() return favorites end
function ui.toggleFavorite(id) return toggleFavorite(id) end
function ui.stagger(parent, delay) staggerChildren(parent, delay) end
function ui.setFavoriteMode(v) setFavoriteMode(v) end
function ui.destroy() uiGui:Destroy() end

_G.ui = ui

do
    local names = { "__XS_ROOT", "__XS3", "__XS2", "__XS2_GUI",
                    "__XS_GUI", "__XS_BALLGUI" }
    for _, k in ipairs(names) do
        local o = _G[k]
        if type(o) == "table" and type(o.destroy) == "function" then
            pcall(function() o.destroy() end)
        elseif typeof(o) == "Instance" then
            pcall(function() o:Destroy() end)
        end
        _G[k] = nil
    end
    local old = _G.XS
    if type(old) == "table" and type(old.destroy) == "function" then
        pcall(function() old.destroy() end)
    end
end

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS        = game:GetService("UserInputService")
local Tween      = game:GetService("TweenService")
local RS         = game:GetService("ReplicatedStorage")
local WS         = game:GetService("Workspace")
local LP         = Players.LocalPlayer

local CFG = {
    SkinOn     = true,

    GloveOn    = true,
    GloveName  = "Fade",

    EditGun    = "AK-47",

    SkinMap    = {},

    ESP        = true,
    ShowName   = true,
    ShowHP     = true,
    ShowDist   = true,
    MaxDist    = 1500,
    ShowTeam   = false,
    EspColor   = Color3.fromRGB(0, 255, 130),

    NoRecoil   = true,
    NoSpread   = true,

    AssistLv   = 1,
}

local STAT = {
    drawn    = 0,
    chars    = 0,
    fps      = 0,
    recoil   = 0,
    spread   = 0,
    ranges   = 0,
    assist   = false,
    skinHit  = 0,
    skinGun  = "-",
    cfgCount = 0,
}

local ROOT = {
    Cfg   = CFG,
    Stats = STAT,
    conns = {},
    orig  = {},
    skinOrig = {},
}
_G.XS        = ROOT
_G.__XS_ROOT = ROOT

local function unlock(t)
    if type(t) ~= "table" then return end
    pcall(function() setreadonly(t, false) end)
end

local function isTeammate(plr)
    if not plr or plr == LP then return false end
    local mt, ht = LP.Team, plr.Team
    if mt and ht then return mt == ht end
    local mc, hc = LP.TeamColor, plr.TeamColor
    if not mc or not hc then return false end
    local mn = tostring(mc.Name)
    local hn = tostring(hc.Name)
    if mn == "White" or mn == "Neutral" or mn == "Black" then return false end
    if hn == "White" or hn == "Neutral" or hn == "Black" then return false end
    return mn == hn
end

local function charHP(ch)
    if not ch then return nil end
    local hp = ch:GetAttribute("Health")
    if type(hp) ~= "number" then return nil end
    local mhp = ch:GetAttribute("MaxHealth")
    if type(mhp) ~= "number" or mhp <= 0 then mhp = 100 end
    return hp, mhp
end

local function charDead(ch)
    return ch and ch:GetAttribute("Dead") == true
end

local SKINS = nil
do
    local ok, m = pcall(require, RS.Database.Components.Libraries.Skins)
    if ok and type(m) == "table" then SKINS = m end
end
ROOT.skins = SKINS

local skinCache = {}

function ROOT.getSkins(gun)
    if skinCache[gun] then return skinCache[gun] end
    if not SKINS then return {} end
    local ok, list = pcall(SKINS.GetAllSkinsForWeapon, gun)
    if not ok or type(list) ~= "table" then return {} end
    local names = {}
    for _, sk in ipairs(list) do
        if type(sk) == "table" and sk.skin then
            names[#names + 1] = tostring(sk.skin)
        end
    end
    table.sort(names)
    skinCache[gun] = names
    return names
end

function ROOT.getAllGuns()
    local W = RS.Database.Custom.Weapons
    local list = {}
    if W then
        for _, ms in ipairs(W:GetChildren()) do
            if ms:IsA("ModuleScript") then list[#list + 1] = ms.Name end
        end
    end
    table.sort(list)
    return list
end

local CAT_ORDER = { "Rifle", "SMG", "Heavy", "Pistol", "Melee", "Grenade", "Glove", "C4", "Other" }
local CAT_LABEL = {
    Rifle   = "步枪 / 狙击",
    SMG     = "冲锋枪",
    Heavy   = "机枪 / 霰弹",
    Pistol  = "手枪",
    Melee   = "刀类",
    Grenade = "投掷物",
    Glove   = "手套",
    C4      = "C4",
    Other   = "其他",
}

local catCache = nil

function ROOT.getGunsByCategory()
    if catCache then return catCache end
    local W = RS.Database.Custom.Weapons
    local buckets = {}
    if W then
        for _, ms in ipairs(W:GetChildren()) do
            if ms:IsA("ModuleScript") then
                local ok, M = pcall(require, ms)
                local cat = "Other"
                if ok and type(M) == "table" and type(M.Type) == "string"
                   and M.Type ~= "Equipment" and M.Type ~= "Miscellaneous" then
                    cat = M.Type
                elseif ok and type(M) == "table" then
                    if M.Class == "Melee" then cat = "Melee"
                    elseif M.Class == "Grenade" then cat = "Grenade"
                    elseif M.Class == "Glove" then cat = "Glove"
                    elseif M.Class == "C4" then cat = "C4"
                    else cat = "Other" end
                end
                if not buckets[cat] then buckets[cat] = {} end
                buckets[cat][#buckets[cat] + 1] = ms.Name
            end
        end
    end

    local result = {}
    for _, cat in ipairs(CAT_ORDER) do
        local items = buckets[cat]
        if items and #items > 0 then
            table.sort(items)
            result[#result + 1] = {
                cat = cat,
                label = CAT_LABEL[cat] or cat,
                items = items,
            }
        end
    end
    catCache = result
    return result
end

local cmCache = {}

function ROOT.getColorMapMap(gun, skin, wear)
    wear = wear or 1
    local key = gun .. "|" .. skin .. "|" .. tostring(wear)
    if cmCache[key] then return cmCache[key] end
    if not SKINS then return nil end

    local ok, model = pcall(SKINS.GetCharacterModel, gun, skin, wear - 1)
    if not ok or typeof(model) ~= "Instance" then
        ok, model = pcall(SKINS.GetCharacterModel, gun, skin, 0)
        if not ok or typeof(model) ~= "Instance" then return nil end
    end

    local okC, clone = pcall(function() return model:Clone() end)
    if not okC or not clone then return nil end

    local okP = pcall(function() clone.Parent = WS end)
    if not okP then
        pcall(function() clone:Destroy() end)
        return nil
    end
    task.wait(0.03)

    local map = {}
    for _, d in ipairs(clone:GetDescendants()) do
        if d:IsA("SurfaceAppearance") then
            local pn = d.Parent and d.Parent.Name or ""
            local okR, cm = pcall(function() return d.ColorMap end)
            if okR and cm and cm ~= "" then
                map[pn] = cm
            end
        end
    end
    pcall(function() clone:Destroy() end)

    if next(map) == nil then return nil end
    cmCache[key] = map
    return map
end

function ROOT.getColorMap(gun, skin, wear)
    local m = ROOT.getColorMapMap(gun, skin, wear)
    if not m then return nil end
    for _, v in pairs(m) do return v end
    return nil
end

local function countCfg()
    local n = 0
    for _ in pairs(CFG.SkinMap) do n = n + 1 end
    STAT.cfgCount = n
    return n
end

local KNIFE_NAMES = {
    ["T Knife"] = true, ["CT Knife"] = true, ["Karambit"] = true,
    ["Flip Knife"] = true, ["Gut Knife"] = true, ["M9 Bayonet"] = true,
    ["Butterfly Knife"] = true, ["Stiletto Knife"] = true,
    ["Skeleton Knife"] = true, ["LightSaber"] = true,
}

local function hasSA(model)
    for _, d in ipairs(model:GetDescendants()) do
        if d:IsA("SurfaceAppearance") then return true end
    end
    return false
end

local function findWeaponModels()
    local cam = WS.CurrentCamera
    local list = {}
    if not cam then return list end

    local myChar = LP.Character
    local seen = {}

    local function check(c)
        if not c or not c:IsA("Model") then return end
        if c == myChar or seen[c] then return end
        if c:FindFirstChild("Weapon") then
            seen[c] = true
            list[#list + 1] = c
            return
        end
        if KNIFE_NAMES[c.Name] and hasSA(c) then
            seen[c] = true
            list[#list + 1] = c
        end
    end

    for _, c in ipairs(cam:GetChildren()) do check(c) end

    local stash = cam:FindFirstChild("ViewmodelStash")
    if stash then
        for _, c in ipairs(stash:GetChildren()) do check(c) end
    end

    return list
end

local SKIP_PARTS = { Sleeve = true, sleeve = true,
                     ["Left Arm"] = true, ["Right Arm"] = true,
                     Arm = true, arm = true }

local function isGlovePart(pn)
    if not pn then return false end
    return pn:find("Glove") ~= nil or pn:find("glove") ~= nil
end

local function isSkinPart(pn)
    if not pn then return false end
    if SKIP_PARTS[pn] then return false end
    if pn:find("Sleeve") or pn:find("sleeve") then return false end
    if isGlovePart(pn) then return false end
    return true
end

local function applySkinToModel(model)
    if not model then return 0 end
    local gun = model.Name
    local conf = CFG.SkinMap[gun]
    if not conf or not conf.skin then return 0 end

    local map = ROOT.getColorMapMap(gun, conf.skin, conf.wear or 1)
    if not map then return 0 end

    local freq = {}
    local mainCm, mainN = nil, 0
    for _, cm in pairs(map) do
        freq[cm] = (freq[cm] or 0) + 1
        if freq[cm] > mainN then
            mainN = freq[cm]
            mainCm = cm
        end
    end
    local uniqN = 0
    for _ in pairs(freq) do uniqN = uniqN + 1 end

    local singleMode = (uniqN == 1)

    local n = 0
    for _, d in ipairs(model:GetDescendants()) do
        if d:IsA("SurfaceAppearance") then
            local pn = d.Parent and d.Parent.Name or ""
            if isSkinPart(pn) then
                local cm = map[pn]

                if not cm and singleMode then
                    cm = mainCm
                end

                if cm then
                    local key = gun .. "|" .. pn
                    if ROOT.skinOrig[key] == nil then
                        local okr, oldCm = pcall(function() return d.ColorMap end)
                        local okn, oldNm = pcall(function() return d.NormalMap end)
                        ROOT.skinOrig[key] = {
                            cm = okr and oldCm or nil,
                            nm = okn and oldNm or nil,
                        }
                    end
                    local okw = pcall(function()
                        if d.ColorMap ~= cm then
                            d.ColorMap = cm
                        end
                    end)
                    if okw then n = n + 1 end
                end
            end
        end
    end

    local miss = {}
    for _, d in ipairs(model:GetDescendants()) do
        if d:IsA("SurfaceAppearance") then
            local pn = d.Parent and d.Parent.Name or ""
            if isSkinPart(pn) and not map[pn] then
                miss[#miss + 1] = pn
            end
        end
    end
    ROOT.lastMiss = miss

    return n
end

function ROOT.applyAllSkins()
    if not SKINS then return end
    local models = findWeaponModels()
    local totalHit = 0
    local lastName = "-"

    local gloveCm = nil
    if CFG.GloveOn and CFG.GloveName then
        local gm = ROOT.getColorMapMap("Driver Gloves", CFG.GloveName, 1)
        if not gm then
            gm = ROOT.getColorMapMap("Hand Wraps", CFG.GloveName, 1)
        end
        if not gm then
            gm = ROOT.getColorMapMap("Operator Gloves", CFG.GloveName, 1)
        end
        if not gm then
            gm = ROOT.getColorMapMap("Sports Gloves", CFG.GloveName, 1)
        end
        if gm then
            for _, v in pairs(gm) do gloveCm = v break end
        end
    end

    for _, model in ipairs(models) do
        if CFG.SkinOn then
            local conf = CFG.SkinMap[model.Name]
            if conf and conf.skin then
                local h = applySkinToModel(model)
                if h > 0 then
                    totalHit = totalHit + h
                    lastName = model.Name
                end
            end
        end

        if gloveCm then
            for _, d in ipairs(model:GetDescendants()) do
                if d:IsA("SurfaceAppearance") then
                    local pn = d.Parent and d.Parent.Name or ""
                    if isGlovePart(pn) then
                        local key = "GLOVE|" .. tostring(model) .. "|" .. pn
                        if ROOT.skinOrig[key] == nil then
                            local okr, oldCm = pcall(function() return d.ColorMap end)
                            local okn, oldNm = pcall(function() return d.NormalMap end)
                            ROOT.skinOrig[key] = {
                                cm = okr and oldCm or nil,
                                nm = okn and oldNm or nil,
                            }
                        end
                        pcall(function()
                            if d.ColorMap ~= gloveCm then
                                d.ColorMap = gloveCm
                            end
                        end)
                        totalHit = totalHit + 1
                    end
                end
            end
        end
    end

    STAT.skinHit = totalHit
    STAT.skinGun = lastName
end

function ROOT.restoreAllSkins()
    for _, model in ipairs(findWeaponModels()) do
        for _, d in ipairs(model:GetDescendants()) do
            if d:IsA("SurfaceAppearance") then
                local key = model.Name .. "|" .. tostring(d.Parent and d.Parent.Name)
                local b = ROOT.skinOrig[key]
                if b and b.cm then
                    pcall(function()
                        d.ColorMap = b.cm
                        if b.nm then d.NormalMap = b.nm end
                    end)
                end
            end
        end
    end
    ROOT.skinOrig = {}
end

function ROOT.setGunSkin(gun, skin, wear)
    if not gun or not skin then return false end
    CFG.SkinMap[gun] = { skin = skin, wear = wear or 1 }
    countCfg()
    return true
end

function ROOT.clearGunSkin(gun)
    CFG.SkinMap[gun] = nil
    countCfg()
end

function ROOT.randomAll()
    local guns = ROOT.getAllGuns()
    local n = 0
    for _, gun in ipairs(guns) do
        local list = ROOT.getSkins(gun)
        local usable = {}
        for _, s in ipairs(list) do
            if s ~= "Stock" then
                usable[#usable + 1] = s
            end
        end
        if #usable > 0 then
            local old = CFG.SkinMap[gun]
            local pick
            if #usable == 1 then
                pick = usable[1]
            else
                repeat
                    pick = usable[math.random(1, #usable)]
                until not old or pick ~= old.skin
            end
            local wear = math.random(1, 5)
            CFG.SkinMap[gun] = { skin = pick, wear = wear }
            n = n + 1
        end
    end
    countCfg()
    return n
end

function ROOT.clearCaches()
    cmCache = {}
    ROOT.skinOrig = {}
end

local GLOVE_LIST = {
    "CT Glove", "T Glove", "Driver Gloves",
    "Hand Wraps", "Operator Gloves", "Sports Gloves",
}

local GLOVE_FALLBACK = {
    ["Driver Gloves"]   = { "Bumblebee", "Gridline", "Argyle", "Cardinal",
                            "Apex", "Dynasty", "Gator", "Midnight Weave",
                            "Tartan", "Tuxedo", "Cobra", "Snow Leopard",
                            "Nomad", "Leopard", "Cardinal Weave" },
    ["Hand Wraps"]      = { "Comic", "Crime Scene", "Bandage", "Camouflage",
                            "Checkers", "Carpet", "Taped", "ChocolateChip",
                            "Jawbreaker", "Aztec", "Cobra", "Meander",
                            "Hunter", "Meadow", "Snakeskin" },
    ["Operator Gloves"] = { "Bumblebee", "Gridline", "Whiteout", "Black Widow",
                            "Apex", "Doodle", "Amber Fade", "Reinforced",
                            "Emerald Widow", "Agent", "Fade", "Hotline",
                            "Hunter", "Hellwire", "Smoke" },
    ["Sports Gloves"]   = { "Bumblebee", "Sakura", "Dune", "Blackout",
                            "Tidal", "Racer", "The Ambassador", "Labyrinth",
                            "Freshmint", "Malibu", "Imperial", "Hunter" },
}

function ROOT.getGloveSkins(name)
    local list = ROOT.getSkins(name)
    if #list > 0 then return list end
    return GLOVE_FALLBACK[name] or {}
end

function ROOT.randomGloves()
    local n = 0
    local used = {}
    for _, name in ipairs(GLOVE_LIST) do
        local list = ROOT.getGloveSkins(name)
        if #list > 0 then
            local pick = list[math.random(1, #list)]
            used[name] = pick
            n = n + 1
        end
    end
    CFG.GloveMap = used
    return n
end

function ROOT.setAllSame(skinName, wear)
    local guns = ROOT.getAllGuns()
    local n = 0
    for _, gun in ipairs(guns) do
        local list = ROOT.getSkins(gun)
        for _, s in ipairs(list) do
            if s == skinName then
                CFG.SkinMap[gun] = { skin = skinName, wear = wear or 1 }
                n = n + 1
                break
            end
        end
    end
    countCfg()
    return n
end

function ROOT.exportCfg()
    local parts = {}
    for gun, conf in pairs(CFG.SkinMap) do
        parts[#parts + 1] = string.format("%s=%s|%d", gun, conf.skin, conf.wear or 1)
    end
    table.sort(parts)
    return table.concat(parts, ";")
end

function ROOT.importCfg(str)
    if type(str) ~= "string" or str == "" then return 0 end
    local n = 0
    for item in str:gmatch("[^;]+") do
        local gun, skin, wear = item:match("^(.-)=(.+)|(%d+)$")
        if gun and skin then
            CFG.SkinMap[gun] = { skin = skin, wear = tonumber(wear) or 1 }
            n = n + 1
        end
    end
    countCfg()
    return n
end

local WEAPONS = nil
pcall(function() WEAPONS = RS.Database.Custom.Weapons end)

function ROOT.applyWeapons()
    if not WEAPONS then return end
    local rcN, spN, nrN = 0, 0, 0

    for _, ms in ipairs(WEAPONS:GetChildren()) do
        if ms:IsA("ModuleScript") then
            local ok, W = pcall(require, ms)
            if ok and type(W) == "table" then

                if CFG.NoRecoil then
                    local rc = W.Recoil
                    if type(rc) == "table" then
                        unlock(rc)
                        if type(rc.Scale) == "number" then
                            local key = ms.Name .. "|Recoil.Scale"
                            if ROOT.orig[key] == nil then
                                ROOT.orig[key] = rc.Scale
                            end
                            if pcall(function() rc.Scale = 0 end) then
                                rcN = rcN + 1
                            end
                        end
                    end
                end

                if CFG.NoSpread then
                    local sp = W.Spread
                    if type(sp) == "table" then
                        unlock(sp)
                        for k, v in pairs(sp) do
                            if type(v) == "number" then
                                local key = ms.Name .. "|Spread." .. tostring(k)
                                if ROOT.orig[key] == nil then
                                    ROOT.orig[key] = v
                                end
                                if pcall(function() sp[k] = 0 end) then
                                    spN = spN + 1
                                end
                            elseif typeof(v) == "NumberRange" then
                                local key = ms.Name .. "|NR|" .. tostring(k)
                                if ROOT.orig[key] == nil then
                                    ROOT.orig[key] = v
                                end
                                if pcall(function()
                                    sp[k] = NumberRange.new(0, 0)
                                end) then
                                    nrN = nrN + 1
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    STAT.recoil, STAT.spread, STAT.ranges = rcN, spN, nrN
end

function ROOT.restoreWeapons()
    if not WEAPONS then return end
    for _, ms in ipairs(WEAPONS:GetChildren()) do
        if ms:IsA("ModuleScript") then
            local ok, W = pcall(require, ms)
            if ok and type(W) == "table" then
                for key, v in pairs(ROOT.orig) do
                    local gname, path = key:match("^([^|]+)|(.+)$")
                    if gname == ms.Name then
                        if path:sub(1, 3) == "NR|" then
                            local k = path:sub(4)
                            if type(W.Spread) == "table" then
                                unlock(W.Spread)
                                pcall(function() W.Spread[k] = v end)
                            end
                        else
                            local sub, k = path:match("^(%w+)%.(.+)$")
                            if sub and k and type(W[sub]) == "table" then
                                unlock(W[sub])
                                pcall(function() W[sub][k] = v end)
                            end
                        end
                        ROOT.orig[key] = nil
                    end
                end
            end
        end
    end
    STAT.recoil, STAT.spread, STAT.ranges = 0, 0, 0
end

function ROOT.rebuildWeapons()
    ROOT.restoreWeapons()
    ROOT.applyWeapons()
end

local ASSIST_ORIG = {
    Magnetism = {
        MaxDistance = 125,
        PullStrength = 0.11344640137963143,
        MaxAngleHorizontal = 0.20943951023931956,
        MaxAngleVertical = 0.10471975511965978,
        StopThreshold = 0.008726646259971648,
    },
    VerticalMagnetism = {
        MaxDistance = 125,
        PullStrength = 0.11344640137963143,
        MaxAngleHorizontal = 0.20943951023931956,
        MaxAngleVertical = 0.10471975511965978,
        StopThreshold = 0.008726646259971648,
    },
    Friction = {
        BubbleRadius = 2.4,
        MaxSensitivity = 1,
        MinSensitivity = 0.5,
    },
    RecoilAssist = {
        ReductionAmount = 0.5,
        HorizontalReductionAmount = 0.85,
    },
    TargetSelection = {
        MaxAngle = 0.5235987755982988,
        MaxDistance = 125,
    },
}

local ASSIST_LV = {
    [1] = { dist = 250,  pull = 0.2269, angH = 0.4189, angV = 0.2094,
            stop = 0.0087, bubble = 4.8,  tAng = 1.0472, tDist = 250,
            red = 0.85, horiz = 1.0 },
    [2] = { dist = 500,  pull = 0.4538, angH = 0.8378, angV = 0.4189,
            stop = 0.0043, bubble = 9.6,  tAng = 2.0944, tDist = 500,
            red = 1.00, horiz = 1.0 },
    [3] = { dist = 1000, pull = 0.9075, angH = 1.6755, angV = 0.8378,
            stop = 0.0010, bubble = 19.2, tAng = 4.1888, tDist = 1000,
            red = 1.00, horiz = 1.0 },
    [4] = { dist = 5000, pull = 3.0000, angH = 3.0400, angV = 1.5533,
            stop = 0.0001, bubble = 96.0, tAng = 6.2600, tDist = 5000,
            red = 1.00, horiz = 1.0 },
    [5] = { dist = 10000, pull = 8.0000, angH = 3.1400, angV = 1.5700,
            stop = 0.00001, bubble = 300.0, tAng = 6.2831, tDist = 10000,
            red = 1.00, horiz = 1.0 },
}

local assistCfg = nil

local function findAssist()
    local ok, M = pcall(require, RS.Controllers.AimAssistController)
    if not ok or type(M) ~= "table" then return nil end
    for _, fn in pairs(M) do
        if type(fn) == "function" then
            local ok2, ups = pcall(debug.getupvalues, fn)
            if ok2 and ups then
                for _, u in ipairs(ups) do
                    if type(u) == "table" and u.Magnetism ~= nil then
                        return u
                    end
                end
            end
        end
    end
    return nil
end

function ROOT.applyAssist(lv)
    if not assistCfg then
        assistCfg = findAssist()
        STAT.assist = assistCfg ~= nil
    end
    if not assistCfg then return false end

    for group, fields in pairs(ASSIST_ORIG) do
        local t = assistCfg[group]
        if type(t) == "table" then
            unlock(t)
            for k, v in pairs(fields) do
                pcall(function() t[k] = v end)
            end
        end
    end

    if lv <= 0 then return true end

    local L = ASSIST_LV[lv]
    if not L then return false end

    for _, gname in ipairs({ "Magnetism", "VerticalMagnetism" }) do
        local g = assistCfg[gname]
        if type(g) == "table" then
            unlock(g)
            pcall(function()
                g.Enabled = true
                g.MaxDistance = L.dist
                g.PullStrength = L.pull
                g.MaxAngleHorizontal = L.angH
                g.MaxAngleVertical = L.angV
                g.StopThreshold = L.stop
            end)
        end
    end

    local fr = assistCfg.Friction
    if type(fr) == "table" then
        unlock(fr)
        pcall(function()
            fr.Enabled = true
            fr.BubbleRadius = L.bubble
            fr.MaxSensitivity = 1
            fr.MinSensitivity = 0.5
        end)
    end

    local ts = assistCfg.TargetSelection
    if type(ts) == "table" then
        unlock(ts)
        pcall(function()
            ts.MaxAngle = L.tAng
            ts.MaxDistance = L.tDist
        end)
    end

    local ra = assistCfg.RecoilAssist
    if type(ra) == "table" then
        unlock(ra)
        pcall(function()
            ra.Enabled = true
            ra.ReductionAmount = L.red
            ra.HorizontalReductionAmount = L.horiz
        end)
    end

    return true
end

local ESP = { tag = {} }

local function mkTag(ch)
    local bb = Instance.new("BillboardGui")
    bb.Name = "XS_TAG"
    bb.Size = UDim2.new(0, 170, 0, 56)
    bb.StudsOffsetWorldSpace = Vector3.new(0, 3.2, 0)
    bb.AlwaysOnTop = true
    bb.LightInfluence = 0
    bb.MaxDistance = CFG.MaxDist
    bb.Parent = ch

    local function mkLine(y, h, size, color)
        local l = Instance.new("TextLabel")
        l.Size = UDim2.new(1, 0, 0, h)
        l.Position = UDim2.new(0, 0, 0, y)
        l.BackgroundTransparency = 1
        l.Font = Enum.Font.GothamBold
        l.TextSize = size
        l.TextColor3 = color
        l.TextStrokeTransparency = 0.2
        l.TextStrokeColor3 = Color3.new(0, 0, 0)
        l.Parent = bb
        return l
    end

    return {
        bb   = bb,
        name = mkLine(0, 18, 14, Color3.new(1, 1, 1)),
        hp   = mkLine(18, 16, 12, Color3.fromRGB(0, 255, 120)),
        dist = mkLine(34, 14, 11, Color3.fromRGB(200, 200, 200)),
    }
end

local function killTag(t)
    if t and t.bb then pcall(function() t.bb:Destroy() end) end
end

local function ensureHL(ch)
    local hl = ch:FindFirstChild("XS_HL")
    if not hl then
        hl = Instance.new("Highlight")
        hl.Name = "XS_HL"
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        hl.Adornee = ch
        hl.Parent = ch
    end
    hl.FillColor = CFG.EspColor
    hl.OutlineColor = CFG.EspColor
    hl.FillTransparency = 0.45
    hl.OutlineTransparency = 0
    hl.Enabled = true
end

local function dropHL(ch)
    local hl = ch:FindFirstChild("XS_HL")
    if hl then pcall(function() hl:Destroy() end) end
end

local function erase(ch)
    if not ch then return end
    local t = ESP.tag[ch]
    if t then killTag(t); ESP.tag[ch] = nil end
    dropHL(ch)
end

local function collectChars()
    local list, seen = {}, {}
    local folder = WS:FindFirstChild("Characters")
    if folder then
        for _, ch in ipairs(folder:GetChildren()) do
            if ch:IsA("Model") and not seen[ch] then
                seen[ch] = true
                list[#list + 1] = ch
            end
        end
    end
    for _, ch in ipairs(WS:GetChildren()) do
        if ch:IsA("Model") and not seen[ch]
           and ch:GetAttribute("Health") ~= nil then
            seen[ch] = true
            list[#list + 1] = ch
        end
    end
    return list
end

local function espFrame()
    local all = collectChars()
    STAT.chars = #all

    local myChar = LP.Character
    local myRoot = myChar and (myChar:FindFirstChild("HumanoidRootPart")
                               or myChar.PrimaryPart)
    local myPos = myRoot and myRoot.Position

    local alive = {}
    for _, ch in ipairs(all) do alive[ch] = true end

    for ch in pairs(ESP.tag) do
        if not alive[ch] then erase(ch) end
    end

    if not CFG.ESP then
        for ch in pairs(ESP.tag) do erase(ch) end
        STAT.drawn = 0
        return
    end

    local drawn = 0

    for ch in pairs(alive) do
        local skip = false
        if ch == myChar then skip = true end
        if not skip and charDead(ch) then skip = true end

        if not skip and not CFG.ShowTeam then
            local plr = Players:GetPlayerFromCharacter(ch)
            if plr and isTeammate(plr) then skip = true end
        end

        local dist = 0
        if not skip and myPos then
            local hrp = ch:FindFirstChild("HumanoidRootPart") or ch.PrimaryPart
            if hrp then
                dist = (hrp.Position - myPos).Magnitude
                if dist > CFG.MaxDist then skip = true end
            end
        end

        if skip then
            erase(ch)
        else
            drawn = drawn + 1
            ensureHL(ch)

            local t = ESP.tag[ch]
            if not t then
                t = mkTag(ch)
                ESP.tag[ch] = t
            end
            t.bb.MaxDistance = CFG.MaxDist
            t.bb.Enabled = true

            local plr = Players:GetPlayerFromCharacter(ch)

            t.name.Visible = CFG.ShowName
            if CFG.ShowName then
                local nm = plr and plr.DisplayName or ch.Name
                local cn = ch:GetAttribute("CharacterName")
                if type(cn) == "string" and cn ~= "" then
                    nm = nm .. " [" .. cn .. "]"
                end
                t.name.Text = nm
            end

            local hp, mhp = charHP(ch)
            if CFG.ShowHP and hp then
                local r = math.clamp(hp / mhp, 0, 1)
                t.hp.Visible = true
                t.hp.Text = string.format("%d / %d", math.floor(hp), math.floor(mhp))
                if r > 0.5 then
                    t.hp.TextColor3 = Color3.fromRGB(0, 255, 120)
                elseif r > 0.25 then
                    t.hp.TextColor3 = Color3.fromRGB(255, 200, 0)
                else
                    t.hp.TextColor3 = Color3.fromRGB(255, 70, 70)
                end
            else
                t.hp.Visible = false
            end

            t.dist.Visible = CFG.ShowDist
            if CFG.ShowDist then
                t.dist.Text = string.format("%dm", math.floor(dist))
            end
        end
    end

    STAT.drawn = drawn
end

local FOV = { On = false, Val = 110 }
local fovConn = nil

local function fovTick()
    if not FOV.On then return end
    local cam = WS.CurrentCamera
    if cam and cam.FieldOfView ~= FOV.Val then
        cam.FieldOfView = FOV.Val
    end
end

local function fovStart()
    if fovConn then return end
    fovConn = RunService.RenderStepped:Connect(function()
        pcall(fovTick)
    end)
end

local function fovStop()
    if fovConn then
        pcall(function() fovConn:Disconnect() end)
        fovConn = nil
    end
end

local SM = { Wpn = nil, Stam = nil, LastFire = 0, Ammo = false, Auto = false }

local function smFindEquipped()
    local best = nil
    pcall(function()
        local n = 0
        for _, o in ipairs(getgc(true)) do
            n = n + 1
            if n > 180000 then break end
            if type(o) == "table" then
                local props = rawget(o, "Properties")
                if type(props) == "table"
                   and type(rawget(o, "Rounds")) == "number"
                   and rawget(o, "IsEquipped") == true then
                    best = o
                end
            end
        end
    end)
    return best
end

local function smFindStam()
    local ch = LP.Character
    if not ch then return nil end
    local hrp = ch:FindFirstChild("HumanoidRootPart") or ch.PrimaryPart
    if not hrp then return nil end
    local myPos = hrp.Position
    local best, bestD = nil, 1e9
    pcall(function()
        local n = 0
        for _, o in ipairs(getgc(true)) do
            n = n + 1
            if n > 180000 then break end
            if type(o) == "table" then
                local nxt = rawget(o, "Next")
                if type(nxt) == "table" then
                    local pos = rawget(nxt, "Position")
                    if typeof(pos) == "Vector3" and type(rawget(nxt, "Stamina")) == "number" then
                        local d = (pos - myPos).Magnitude
                        if d < bestD then bestD = d; best = o end
                    end
                end
            end
        end
    end)
    if best and bestD < 10 then return best end
    return nil
end

local function smTick()
    local now = os.clock()

    local st = SM.Stam
    if st then
        local inner = st.inner
        if inner then
            pcall(function() inner.Stamina = 100 end)
        else
            SM.Stam = nil
        end
    end

    local w = SM.Wpn
    if not w then return end

    if rawget(w, "IsEquipped") ~= true then
        SM.Wpn = nil
        return
    end

    if SM.Auto then
        local props = rawget(w, "Properties")
        if type(props) == "table" and rawget(props, "Automatic") == false
           and rawget(w, "IsFireHeld") == true
           and now - SM.LastFire >= 0.05 then
            local rounds = rawget(w, "Rounds")
            if type(rounds) == "number" and rounds > 0 then
                SM.LastFire = now
                if rawget(w, "IsShooting") == true then
                    pcall(function() w.IsShooting = false end)
                end
                pcall(function() w:shoot("Primary") end)
            end
        end
    end

    if SM.Ammo then
        local p2 = rawget(w, "Properties")
        if type(p2) == "table" then
            local maxR = rawget(p2, "Rounds")
            local maxC = rawget(p2, "Capacity")
            if type(maxR) == "number" and rawget(w, "Rounds") ~= maxR then
                pcall(function() w.Rounds = maxR end)
            end
            if type(maxC) == "number" and rawget(w, "Capacity") ~= maxC then
                pcall(function() w.Capacity = maxC end)
            end
        end
    end
end

local smConn = nil
local function smHeartbeat()
    if smConn then return end
    smConn = RunService.Heartbeat:Connect(function()
        pcall(smTick)
    end)
end

local function smEnsure()
    if not SM.Wpn then SM.Wpn = smFindEquipped() end
    if not SM.Stam then SM.Stam = smFindStam() end
end

local HS = { On = false, Recs = {}, LockPos = nil, Recon = 0, Drift = 0 }

local function hsCollectRecs()
    local list = {}
    local ok, R = pcall(require, RS.MovementV2.Client.Reconciler)
    if ok and type(R) == "table" then
        local idx = rawget(R, "__index")
        pcall(function()
            for _, o in ipairs(getgc(true)) do
                if type(o) == "table" and (getmetatable(o) == idx or getmetatable(o) == R) then
                    list[#list + 1] = o
                end
            end
        end)
    end
    if #list == 0 then
        pcall(function()
            for _, o in ipairs(getgc(true)) do
                if type(o) == "table" and type(rawget(o, "_lastSequence")) == "number" and rawget(o, "_ring") ~= nil then
                    list[#list + 1] = o
                end
            end
        end)
    end
    return list
end

local function hsStart()
    HS.Recs = hsCollectRecs()
    if #HS.Recs == 0 then return false end
    local ch = LP.Character
    local hrp = ch and (ch:FindFirstChild("HumanoidRootPart") or ch.PrimaryPart)
    HS.LockPos = (hrp and hrp.Position) or Vector3.new(0, 0, 0)
    HS.On = true
    HS.Recon = 0
    task.spawn(function()
        while HS.On do
            pcall(function()
                for _, r in ipairs(HS.Recs) do
                    r._lastSequence = 4294967295
                end
                HS.Recon = HS.Recon + 1
            end)
            task.wait(0.02)
        end
    end)
    return true
end

local function hsStop()
    HS.On = false
    task.delay(0.05, function()
        pcall(function()
            for _, r in ipairs(HS.Recs) do
                r._lastSequence = 0
            end
        end)
    end)
end

local hsConn = nil
local function hsHeartbeat()
    if hsConn then return end
    hsConn = RunService.Heartbeat:Connect(function()
        if not HS.On then return end
        pcall(function()
            local ch = LP.Character
            local hrp = ch and (ch:FindFirstChild("HumanoidRootPart") or ch.PrimaryPart)
            if hrp and HS.LockPos then
                HS.Drift = (hrp.Position - HS.LockPos).Magnitude
            end
        end)
    end)
end

local UIPanel = ui.createPanel({
	title = "星神BS",
	w = 430, h = 350,
	tabs = { "美化", "透视", "武器", "自瞄", "辅助" },
	sidebarWidth = 76, tabHeight = 30, titleSize = 12,
	showPlayer = false,
	onClose = function() if ROOT.destroy then pcall(ROOT.destroy) end end,
})

local pages = UIPanel.tabs

local function makeScroller(page)
	local sf = Instance.new("ScrollingFrame")
	sf.BackgroundTransparency = 1
	sf.BorderSizePixel = 0
	sf.Position = UDim2.new(0, 0, 0, 0)
	sf.Size = UDim2.new(1, 0, 1, 0)
	sf.CanvasSize = UDim2.new(0, 0, 0, 0)
	sf.ScrollingDirection = Enum.ScrollingDirection.Y
	sf.ScrollBarThickness = 4
	sf.ScrollBarImageColor3 = ui.Theme.PRIMARY
	sf.ScrollBarImageTransparency = 0.35
	sf.ScrollingEnabled = false
	sf.ElasticBehavior = Enum.ElasticBehavior.Never
	sf.ClipsDescendants = true
	sf.ZIndex = 5
	sf.Parent = page

	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, 6)
	pad.PaddingLeft = UDim.new(0, 4)
	pad.PaddingRight = UDim.new(0, 8)
	pad.Parent = sf

	local dragTouch, startY, startCanvas, moved = nil, 0, 0, false

	local function beginDrag(input)
		dragTouch = input
		startY = input.Position.Y
		startCanvas = sf.CanvasPosition.Y
		moved = false
	end

	local function moveDrag(input)
		if not dragTouch then return end
		local dy = startY - input.Position.Y
		if math.abs(dy) > 6 then moved = true end
		if moved then
			local maxY = math.max(0, sf.AbsoluteCanvasSize.Y - sf.AbsoluteSize.Y)
			sf.CanvasPosition = Vector2.new(0, math.clamp(startCanvas + dy, 0, maxY))
		end
	end

	local function endDrag()
		if dragTouch then
			dragTouch = nil
			moved = false
		end
	end

	sf.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch then
			beginDrag(input)
		end
	end)
	sf.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch then
			moveDrag(input)
		end
	end)
	sf.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch then
			endDrag()
		end
	end)

	local function recalc()
		local maxY = 0
		for _, c in ipairs(sf:GetChildren()) do
			if c:IsA("GuiObject") then
				local bottom = c.Position.Y.Offset + c.Size.Y.Offset
				if bottom > maxY then maxY = bottom end
			end
		end
		sf.CanvasSize = UDim2.new(0, 0, 0, maxY + 16)
	end

	sf.ChildAdded:Connect(function() task.defer(recalc) end)
	task.defer(function() task.wait(0.15); recalc(); task.wait(0.4); recalc() end)

	return sf
end

local function layout(page)
	local host = makeScroller(page)
	local y = 2
	local L = {}

	L.title = function(text)
		ui.createLabel({ parent = host, text = text, x = 6, y = y, w = 280, h = 15,
			textSize = 10, color = ui.Theme.TEXT_MUTED })
		y = y + 20
		return L
	end

	L.toggle = function(text, init, onChange, desc)
		ui.createLabel({ parent = host, text = text, x = 8, y = y + (desc and 2 or 5), w = 250, h = 15,
			textSize = 11, color = ui.Theme.TEXT })
		if desc then
			ui.createLabel({ parent = host, text = desc, x = 8, y = y + 19, w = 250, h = 12,
				textSize = 9, color = ui.Theme.TEXT_MUTED })
		end
		ui.createToggle({ parent = host, x = 276, y = y + (desc and 9 or 5), w = 40, h = 20,
			value = init, onChange = onChange })
		y = y + (desc and 40 or 30)
		return L
	end

	L.slider = function(text, minV, maxV, step, init, onChange)
		ui.createLabel({ parent = host, text = text, x = 8, y = y, w = 240, h = 15,
			textSize = 11, color = ui.Theme.TEXT })
		local s = ui.createSlider({ parent = host, x = 8, y = y + 16, w = 306, h = 22,
			min = minV, max = maxV, step = step, value = init, onChange = onChange })
		y = y + 46
		return s
	end

	L.button = function(text, onClick)
		ui.createButton({ parent = host, text = text, x = 6, y = y, w = 310, h = 30,
			onClick = function() pcall(onClick) end })
		y = y + 36
		return L
	end

	L.info = function(text)
		ui.createLabel({ parent = host, text = text, x = 8, y = y, w = 310, h = 13,
			textSize = 9, color = ui.Theme.TEXT_MUTED })
		y = y + 15
		return L
	end

	L.gap = function(h) y = y + (h or 8); return L end
	return L
end

local function say(msg)
	pcall(function()
		ui.notify({ title = "星神", message = tostring(msg), type = "info" })
	end)
end

do
	local LG = layout(pages[1])
	LG.title("皮肤")
	LG.toggle("美化总开关", CFG.SkinOn, function(v)
		CFG.SkinOn = v
		if not v then pcall(ROOT.restoreAllSkins) end
		say("美化总开关: " .. (v and "开" or "关"))
	end, "关闭恢复默认")
	LG.toggle("手套美化", CFG.GloveOn, function(v)
		CFG.GloveOn = v
		if not v then pcall(ROOT.applyAllSkins) end
		say("手套美化: " .. (v and "开" or "关"))
	end, "当前 " .. tostring(CFG.GloveName))
	LG.gap(4)
	LG.title("一键")
	LG.button("全皮美化", function()
		ROOT.clearCaches()
		local gunN = ROOT.randomAll()
		local sets = { "Bumblebee", "Gridline", "Apex", "Cobra", "Hunter",
			"Dazzle", "Sakura", "Fade", "Aztec", "Comic",
			"Whiteout", "Blackout", "Tidal", "Leopard", "Snow Leopard" }
		CFG.GloveName = sets[math.random(1, #sets)] or "Bumblebee"
		CFG.GloveOn = true
		CFG.SkinOn = true
		ROOT.applyAllSkins()
		say("美化完成 " .. gunN .. " 把 手套 " .. CFG.GloveName)
	end)
	LG.button("清空全部配置", function()
		CFG.SkinMap = {}
		ROOT.clearCaches()
		ROOT.restoreAllSkins()
		say("已清空")
	end)
end

do
	local LG = layout(pages[2])
	LG.title("人物透视")
	LG.toggle("高亮模型", CFG.ESP, function(v)
		CFG.ESP = v
		say("高亮: " .. (v and "开" or "关"))
	end)
	LG.toggle("名字", CFG.ShowName, function(v) CFG.ShowName = v end)
	LG.toggle("血量", CFG.ShowHP, function(v) CFG.ShowHP = v end)
	LG.toggle("距离", CFG.ShowDist, function(v) CFG.ShowDist = v end)
	LG.toggle("队友", CFG.ShowTeam, function(v) CFG.ShowTeam = v end)
	LG.gap(4)
	LG.slider("最大距离", 100, 5000, 100, CFG.MaxDist, function(v) CFG.MaxDist = v end)
	LG.button("清理全部标记", function()
		CFG.ESP = false
		for ch in pairs(ESP.tag) do erase(ch) end
		say("已清理")
	end)
end

do
	local LG = layout(pages[3])
	LG.title("武器参数")
	LG.toggle("无后座", CFG.NoRecoil, function(v)
		CFG.NoRecoil = v
		ROOT.rebuildWeapons()
		say(string.format("后座 %s %d把", v and "开" or "关", STAT.recoil))
	end, "Recoil.Scale 归零")
	LG.toggle("无散布", CFG.NoSpread, function(v)
		CFG.NoSpread = v
		ROOT.rebuildWeapons()
		say(string.format("散布 %s %d+%d", v and "开" or "关", STAT.spread, STAT.ranges))
	end, "Spread+Range 归零")
	LG.button("重新应用", function()
		ROOT.rebuildWeapons()
		say(string.format("%d后座 %d散布 %d范围", STAT.recoil, STAT.spread, STAT.ranges))
	end)
	LG.gap(4)
	LG.title("射击")
	LG.toggle("单发改自动", SM.Auto, function(v)
		SM.Auto = v
		if v then
			smHeartbeat()
			smEnsure()
			if not SM.Wpn then say("未找到武器，进游戏自动重试") end
		end
		say("单发改自动: " .. (v and "开" or "关"))
	end, "半自动按住连发")
	LG.toggle("锁子弹", SM.Ammo, function(v)
		SM.Ammo = v
		if v then
			smHeartbeat()
			smEnsure()
		end
		say("锁子弹: " .. (v and "开" or "关"))
	end, "弹夹保持满")
	LG.button("重抓武器", function()
		SM.Wpn = smFindEquipped()
		SM.Stam = smFindStam()
		say(SM.Wpn and "已抓取" or "未找到，请手持武器")
	end)
	LG.button("还原参数", function()
		ROOT.restoreWeapons()
		say("已还原")
	end)
end

do
	local LG = layout(pages[4])
	local LVNAME = { "关闭", "轻", "中", "强", "超强", "强强强" }
	LG.title("辅助瞄准")
	LG.slider("等级", 0, 5, 1, CFG.AssistLv, function(v)
		CFG.AssistLv = v
		local ok = ROOT.applyAssist(v)
		say(ok and ("自瞄 " .. (LVNAME[v + 1] or "?")) or "未找到自瞄配置")
	end)
	LG.info("0关 1轻 2中 3强 4超强 5满")
	LG.gap(4)
	LG.button("还原自瞄", function()
		CFG.AssistLv = 0
		ROOT.applyAssist(0)
		say("已还原")
	end)
	LG.gap(4)
	LG.info("配置状态 " .. (STAT.assist and "已找到" or "未找到"))
end

do
	local LG = layout(pages[5])
	LG.title("广角")
	LG.toggle("启用FOV", FOV.On, function(v)
		FOV.On = v
		if v then
			fovStart()
		else
			fovStop()
			local cam = WS.CurrentCamera
			if cam then cam.FieldOfView = 70 end
		end
		say("FOV: " .. (v and "开" or "关"))
	end, "默认70 广角110")
	LG.slider("角度", 70, 130, 5, FOV.Val, function(v)
		FOV.Val = v
		if FOV.On then fovTick() end
	end)
	LG.gap(4)
	LG.info("回溯用左侧悬浮球")
end

local skinTick = 0

table.insert(ROOT.conns, RunService.RenderStepped:Connect(function()
	pcall(espFrame)
	skinTick = skinTick + 1
	if skinTick >= 15 then
		skinTick = 0
		pcall(ROOT.applyAllSkins)
	end
end))

local HSB_GUI = Instance.new("ScreenGui")
HSB_GUI.Name = "XS_HSB"
HSB_GUI.ResetOnSpawn = false
HSB_GUI.IgnoreGuiInset = true
HSB_GUI.DisplayOrder = 998
local hsContainer = nil
pcall(function() hsContainer = gethui and gethui() end)
if not hsContainer then
	local ok, cg = pcall(function() return game:GetService("CoreGui") end)
	if ok and cg then
		local can = pcall(function()
			local p = Instance.new("Folder")
			p.Parent = cg
			p:Destroy()
		end)
		if can then hsContainer = cg end
	end
end
if not hsContainer then hsContainer = LP:WaitForChild("PlayerGui") end
pcall(function() HSB_GUI.Parent = hsContainer end)
if not HSB_GUI.Parent then HSB_GUI.Parent = LP:WaitForChild("PlayerGui") end

local HSB = Instance.new("TextButton")
HSB.Size = UDim2.new(0, 52, 0, 34)
HSB.Position = UDim2.new(0, 16, 0, 200)
HSB.BackgroundColor3 = Color3.fromRGB(60, 64, 76)
HSB.Text = "回溯"
HSB.TextColor3 = Color3.fromRGB(240, 240, 245)
HSB.Font = Enum.Font.GothamBold
HSB.TextSize = 12
HSB.BorderSizePixel = 0
HSB.AutoButtonColor = false
HSB.Parent = HSB_GUI
Instance.new("UICorner", HSB).CornerRadius = UDim.new(0, 8)
local hsStroke = Instance.new("UIStroke", HSB)
hsStroke.Color = Color3.fromRGB(28, 28, 34)
hsStroke.Thickness = 2

local hsDot = Instance.new("Frame")
hsDot.Size = UDim2.new(0, 6, 0, 6)
hsDot.Position = UDim2.new(1, -8, 0, 1)
hsDot.BackgroundColor3 = Color3.fromRGB(120, 120, 130)
hsDot.BorderSizePixel = 0
hsDot.Parent = HSB
Instance.new("UICorner", hsDot).CornerRadius = UDim.new(0, 3)

local hsbDragging, hsbDragStart, hsbStartPos = false, nil, nil
local hsbMaxDist, hsbTapStart, hsbHoldTask = 0, 0, nil
local HSB_LOCKED = false

local function hsbToggle()
	if HS.On then
		hsStop()
		HSB.BackgroundColor3 = Color3.fromRGB(60, 64, 76)
		hsDot.BackgroundColor3 = Color3.fromRGB(120, 120, 130)
	else
		if hsStart() then
			HSB.BackgroundColor3 = Color3.fromRGB(52, 199, 123)
			hsDot.BackgroundColor3 = Color3.fromRGB(20, 90, 55)
		else
			HSB.BackgroundColor3 = Color3.fromRGB(120, 72, 72)
			hsDot.BackgroundColor3 = Color3.fromRGB(150, 90, 90)
		end
	end
end

HSB.InputBegan:Connect(function(i)
	if i.UserInputType ~= Enum.UserInputType.Touch
		and i.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
	hsbTapStart = os.clock()
	hsbMaxDist = 0
	if not HSB_LOCKED then
		hsbDragging = true
		hsbDragStart = i.Position
		hsbStartPos = HSB.Position
	end
	if hsbHoldTask then pcall(function() task.cancel(hsbHoldTask) end) end
	hsbHoldTask = task.delay(0.75, function()
		hsbHoldTask = nil
		HSB_LOCKED = not HSB_LOCKED
		hsbDragging = false
		if HSB_LOCKED then
			hsStroke.Color = Color3.fromRGB(255, 200, 60)
			hsStroke.Thickness = 3
		else
			hsStroke.Color = Color3.fromRGB(28, 28, 34)
			hsStroke.Thickness = 2
		end
	end)
	i.Changed:Connect(function()
		if i.UserInputState == Enum.UserInputState.End then
			hsbDragging = false
			if hsbHoldTask then
				pcall(function() task.cancel(hsbHoldTask) end)
				hsbHoldTask = nil
				if hsbMaxDist < 10 and (os.clock() - hsbTapStart) < 0.6 then
					hsbToggle()
				end
			end
		end
	end)
end)

UserInputService.InputChanged:Connect(function(i)
	if not hsbDragging then return end
	if i.UserInputType == Enum.UserInputType.Touch
		or i.UserInputType == Enum.UserInputType.MouseMovement then
		local d = i.Position - hsbDragStart
		local dist = math.sqrt(d.X * d.X + d.Y * d.Y)
		if dist > hsbMaxDist then hsbMaxDist = dist end
		local cam = WS.CurrentCamera
		local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
		HSB.Position = UDim2.new(0,
			math.clamp(hsbStartPos.X.Offset + d.X, 0, vp.X - 52), 0,
			math.clamp(hsbStartPos.Y.Offset + d.Y, 0, vp.Y - 34))
	end
end)

local hsDriftConn = RunService.Heartbeat:Connect(function()
	if not HS.On then return end
	pcall(function()
		local ch = LP.Character
		local hrp = ch and (ch:FindFirstChild("HumanoidRootPart") or ch.PrimaryPart)
		if hrp and HS.LockPos then
			HS.Drift = (hrp.Position - HS.LockPos).Magnitude
			local r = math.clamp(HS.Drift / 80, 0, 1)
			hsDot.BackgroundColor3 = Color3.new(0.3 + r * 0.7, 0.9 - r * 0.7, 0.4)
		end
	end)
end)

task.spawn(function()
	assistCfg = findAssist()
	STAT.assist = assistCfg ~= nil
	ROOT.rebuildWeapons()
	countCfg()
	if assistCfg and CFG.AssistLv > 0 then
		ROOT.applyAssist(CFG.AssistLv)
	end
	task.wait(0.3)
	say(string.format("已加载 后座%d 散布%d %d把可换皮",
		STAT.recoil, STAT.spread, #ROOT.getAllGuns()))
end)

if SM.Auto or SM.Ammo then smHeartbeat() end

ROOT.destroy = function()
	pcall(fovStop)
	if smConn then pcall(function() smConn:Disconnect() end); smConn = nil end
	if hsConn then pcall(function() hsConn:Disconnect() end); hsConn = nil end
	if hsDriftConn then pcall(function() hsDriftConn:Disconnect() end); hsDriftConn = nil end
	pcall(hsStop)

	for _, c in ipairs(ROOT.conns) do
		pcall(function() c:Disconnect() end)
	end
	ROOT.conns = {}

	pcall(function() ROOT.restoreAllSkins() end)
	pcall(function() ROOT.applyAssist(0) end)
	pcall(function() ROOT.restoreWeapons() end)

	for ch in pairs(ESP.tag) do erase(ch) end
	ESP.tag = {}

	pcall(function() HSB_GUI:Destroy() end)
	pcall(function() UIPanel.destroy() end)
	pcall(function() ui.destroy() end)

	_G.XS = nil
	_G.__XS_ROOT = nil
end
