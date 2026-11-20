
if _G.__XS_ALL then
    pcall(function() _G.__XS_ALL.unload() end)
end
pcall(function()
    local pg = game:GetService("Players").LocalPlayer:FindFirstChild("PlayerGui")
    if pg then
        local old = pg:FindFirstChild("XS_Menu")
        if old then old:Destroy() end
    end
end)
pcall(function()
    local cg = game:GetService("CoreGui")
    for _, ch in ipairs(cg:GetChildren()) do
        if ch.Name == "XS_Menu" then ch:Destroy() end
    end
end)

local RS        = game:GetService("ReplicatedStorage")
local Players   = game:GetService("Players")
local RunSvc    = game:GetService("RunService")
local UIS       = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Tween     = game:GetService("TweenService")
local LP        = Players.LocalPlayer


local CFG = {
    -- ESP
    esp           = true,
    espBox        = true,
    espName       = true,
    espHealth     = true,
    espDist       = true,
    espFilterFake = true,
    espMaxDist    = 1500,

    -- 魔法子弹
    magic         = true,
    magicMode     = "any",     -- player / npc / any

    -- 自瞄
    aimbot        = false,
    aimPart       = "Head",
    aimSmooth     = 1.0,       
    aimFOV        = 300,
    aimVisible    = false,

    -- 准心圆圈
    circleOnly    = true,
    circleRadius  = 200,
    showCircle    = true,

    -- 枪械
    gunNoSpread   = true,
    gunNoRecoil   = false,
    gunRapid      = false,
    gunRapidMul   = 3,
    gunInfAmmo    = false,
    gunForceAuto  = false,

    -- 自动开火
    autoFire      = false,
    autoFireRate  = 0.08,

    -- 其它
    headYOffset   = 0.2,
}

local STAT = {
    redirected = 0,
    aimTarget  = "-",
    inCircle   = 0,
    players    = 0,
    npcs       = 0,
    drawn      = 0,
    shots      = 0,
    t0         = os.clock(),
}


local function myPos()
    local c = LP.Character
    if c then
        local h = c:FindFirstChild("HumanoidRootPart")
        if h then return h.Position end
    end
end

local function realPlayerOf(model)
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Character == model then return p end
    end
end

local function isDummy(model)
    if model.Name:find("^Fake_") then return true end
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Name == model.Name and p.Character ~= model then return true end
    end
    return false
end

-- ═══════════════════ ① ESP ═══════════════════
local ESP = { draws = {}, conn = nil, lastGC = 0 }
local ESP_KEYS = { "box", "name", "dist", "hpBG", "hpBar", "hpTxt" }

local function mkDraw()
    if not Drawing then return nil end
    local d = {}
    local ok = pcall(function()
        d.box   = Drawing.new("Square")
        d.name  = Drawing.new("Text")
        d.dist  = Drawing.new("Text")
        d.hpBG  = Drawing.new("Square")
        d.hpBar = Drawing.new("Square")
        d.hpTxt = Drawing.new("Text")
    end)
    if not ok then
        for _, o in pairs(d) do pcall(function() o:Remove() end) end
        return nil
    end

    d.box.Thickness = 1
    d.box.Filled    = false
    d.box.Visible   = false

    d.name.Size     = 13
    d.name.Center   = true
    d.name.Outline  = true
    d.name.OutlineColor = Color3.new(0, 0, 0)
    d.name.Color    = Color3.fromRGB(255, 255, 255)
    d.name.TextBounds = Vector2.new(180, 13)
    d.name.Visible  = false

    d.dist.Size     = 11
    d.dist.Center   = true
    d.dist.Outline  = true
    d.dist.OutlineColor = Color3.new(0, 0, 0)
    d.dist.Color    = Color3.fromRGB(210, 210, 210)
    d.dist.TextBounds = Vector2.new(70, 11)
    d.dist.Visible  = false

    d.hpBG.Filled   = true
    d.hpBG.Color    = Color3.new(0, 0, 0)
    d.hpBG.Visible  = false

    d.hpBar.Filled  = true
    d.hpBar.Visible = false

    d.hpTxt.Size    = 10
    d.hpTxt.Center  = true
    d.hpTxt.Outline = true
    d.hpTxt.OutlineColor = Color3.new(0, 0, 0)
    d.hpTxt.Color   = Color3.new(1, 1, 1)
    d.hpTxt.TextBounds = Vector2.new(36, 10)
    d.hpTxt.Visible = false

    return d
end

local function hideDraw(d)
    if not d then return end
    for _, k in ipairs(ESP_KEYS) do
        local o = d[k]
        if o then pcall(function() o.Visible = false end) end
    end
end

local function killDraw(d)
    if not d then return end
    for _, k in ipairs(ESP_KEYS) do
        local o = d[k]
        if o then
            pcall(function() o.Visible = false end)
            pcall(function() o:Remove() end)
        end
    end
end


local function projectBox(cam, head, hrp, hum)
    local headTop = head.Position + Vector3.new(0, head.Size.Y * 0.5, 0)
    local hip = 2.0
    pcall(function()
        if hum and hum.HipHeight and hum.HipHeight > 0 then hip = hum.HipHeight end
    end)
    local foot = hrp.Position - Vector3.new(0, hip, 0)

    local hs, hOn = cam:WorldToViewportPoint(headTop)
    local fs, fOn = cam:WorldToViewportPoint(foot)
    if not hOn or not fOn then return nil end
    if hs.Z <= 0 or fs.Z <= 0 then return nil end

    local h = math.abs(fs.Y - hs.Y)
    if h < 6 then h = 6 end

    local vp = cam.ViewportSize
    if hs.X < -vp.X * 0.5 or hs.X > vp.X * 1.5 then return nil end
    if hs.Y < -vp.Y * 0.5 or fs.Y > vp.Y * 1.5 then return nil end

    local w = h * 0.45
    return { x = hs.X - w / 2, y = hs.Y, w = w, h = h, cx = hs.X }
end

ESP.conn = RunSvc.RenderStepped:Connect(function()
    for _, d in pairs(ESP.draws) do hideDraw(d) end

    if not CFG.esp then STAT.drawn = 0 return end

    local cam = Workspace.CurrentCamera
    if not cam then return end

    local mp = myPos()
    if not mp then return end

    local now = os.clock()
    if now - ESP.lastGC > 5 then
        ESP.lastGC = now
        for p, d in pairs(ESP.draws) do
            if not p.Parent or not p.Character then
                killDraw(d)
                ESP.draws[p] = nil
            end
        end
    end

    local drawn = 0
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP then
            local skip = CFG.espFilterFake and p.Name:find("^Fake_")
            local ch = p.Character
            if not skip and ch then
                local head = ch:FindFirstChild("Head")
                local hrp  = ch:FindFirstChild("HumanoidRootPart")
                local hum  = ch:FindFirstChildOfClass("Humanoid")
                if head and hrp and hum and hum.Health > 0 then
                    local dist = (hrp.Position - mp).Magnitude
                    if dist <= CFG.espMaxDist then
                        local b = projectBox(cam, head, hrp, hum)
                        if b then
                            local d = ESP.draws[p]
                            if not d then
                                d = mkDraw()
                                ESP.draws[p] = d
                            end
                            if d then
                                drawn = drawn + 1
                                if d.box and CFG.espBox then
                                    d.box.Size     = Vector2.new(b.w, b.h)
                                    d.box.Position = Vector2.new(b.x, b.y)
                                    d.box.Color    = Color3.fromRGB(0, 255, 140)
                                    d.box.Visible  = true
                                end
                                if d.name and CFG.espName then
                                    d.name.Text     = p.Name
                                    d.name.Position = Vector2.new(b.cx, b.y - 14)
                                    d.name.Visible  = true
                                end
                                if d.dist and CFG.espDist then
                                    d.dist.Text     = string.format("%dm", math.floor(dist))
                                    d.dist.Position = Vector2.new(b.cx, b.y + b.h + 1)
                                    d.dist.Visible  = true
                                end
                                if d.hpBG and d.hpBar and CFG.espHealth then
                                    local ratio = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
                                    local bh = b.h * ratio
                                    local bx = b.x - 5
                                    d.hpBG.Size     = Vector2.new(2, b.h)
                                    d.hpBG.Position = Vector2.new(bx, b.y)
                                    d.hpBG.Visible  = true
                                    d.hpBar.Size     = Vector2.new(2, bh)
                                    d.hpBar.Position = Vector2.new(bx, b.y + b.h - bh)
                                    d.hpBar.Color    = Color3.fromRGB(255, 60, 60):Lerp(Color3.fromRGB(0, 255, 0), ratio)
                                    d.hpBar.Visible  = true
                                    if d.hpTxt and b.h > 20 then
                                        d.hpTxt.Text     = tostring(math.floor(hum.Health))
                                        d.hpTxt.Position = Vector2.new(bx - 13, b.y + b.h / 2 - 5)
                                        d.hpTxt.Visible  = true
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    STAT.drawn = drawn
end)


local scanCache = { at = 0, list = {} }

local function scanAll()
    local now = os.clock()
    if now - scanCache.at < 0.15 then return scanCache.list end
    scanCache.at = now

    local list = {}
    local roots = {
        workspace,
        workspace:FindFirstChild("Gizmos"),
        workspace:FindFirstChild("Mobs"),
    }

    local function walk(node, d)
        if not node or d > 3 or #list >= 250 then return end
        for _, ch in ipairs(node:GetChildren()) do
            if #list >= 250 then return end
            if ch:IsA("Model") then
                local hum = ch:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health > 0 then
                    local head = ch:FindFirstChild("Head")
                    local hrp = ch:FindFirstChild("HumanoidRootPart")
                    if head and hrp then
                        list[#list+1] = { model = ch, hum = hum, head = head, hrp = hrp, name = ch.Name }
                    end
                end
            end
            pcall(walk, ch, d + 1)
        end
    end

    for _, r in ipairs(roots) do
        if r then pcall(walk, r, 0) end
    end

    scanCache.list = list
    return list
end

--
local circleDraw = nil
if Drawing then
    pcall(function()
        circleDraw = Drawing.new("Circle")
        circleDraw.Thickness = 1.5
        circleDraw.Color = Color3.fromRGB(0, 255, 140)
        circleDraw.NumSides = 64
        circleDraw.Transparency = 0.65
        circleDraw.Filled = false
        circleDraw.Visible = false
    end)
end

local function toScreen(pos, cam)
    local sp, on = cam:WorldToViewportPoint(pos)
    if not on or sp.Z <= 0 then return nil end
    return sp
end

local function isInCircle(sp, cam)
    if not sp then return false end
    local vp = cam.ViewportSize
    local dx = sp.X - vp.X * 0.5
    local dy = sp.Y - vp.Y * 0.5
    return math.sqrt(dx*dx + dy*dy) <= CFG.circleRadius
end

local targetCache = { at = 0, target = nil }

local function pickTarget()
    local now = os.clock()
    if (now - targetCache.at) < 0.1 then return targetCache.target end
    targetCache.at = now

    local mp = myPos()
    if not mp then targetCache.target = nil return nil end

    local cam = Workspace.CurrentCamera
    if not cam then targetCache.target = nil return nil end

    local best, bestD = nil, math.huge
    local nP, nN, nIn = 0, 0, 0

    -- 玩家
    if CFG.magicMode == "player" or CFG.magicMode == "any" then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LP and p.Character then
                local ch = p.Character
                local head = ch:FindFirstChild("Head")
                local hrp  = ch:FindFirstChild("HumanoidRootPart")
                local hum  = ch:FindFirstChildOfClass("Humanoid")
                if head and hrp and hum and hum.Health > 0 then
                    if not (CFG.espFilterFake and p.Name:find("^Fake_")) then
                        local d = (hrp.Position - mp).Magnitude
                        local sp = toScreen(head.Position, cam)
                        local inC = isInCircle(sp, cam)
                        if inC then nIn = nIn + 1 end
                        if inC or not CFG.circleOnly then
                            nP = nP + 1
                            if d < bestD then
                                bestD = d
                                best = { pos = head.Position + Vector3.new(0, CFG.headYOffset, 0),
                                         name = p.Name, kind = "player", model = ch,
                                         inCircle = inC, dist = d }
                            end
                        end
                    end
                end
            end
        end
    end

    -- NPC
    if CFG.magicMode == "npc" or CFG.magicMode == "any" then
        for _, e in ipairs(scanAll()) do
            local skip = false
            if CFG.espFilterFake and isDummy(e.model) then skip = true end
            if realPlayerOf(e.model) then skip = true end
            if not skip then
                local d = (e.hrp.Position - mp).Magnitude
                local sp = toScreen(e.head.Position, cam)
                local inC = isInCircle(sp, cam)
                if inC then nIn = nIn + 1 end
                if inC or not CFG.circleOnly then
                    nN = nN + 1
                    if d < bestD then
                        bestD = d
                        best = { pos = e.head.Position + Vector3.new(0, CFG.headYOffset, 0),
                                 name = e.name, kind = "npc", model = e.model,
                                 inCircle = inC, dist = d }
                    end
                end
            end
        end
    end

    STAT.players = nP
    STAT.npcs = nN
    STAT.inCircle = nIn
    targetCache.target = best
    return best
end

-- 圆圈渲染
local circleConn = RunSvc.RenderStepped:Connect(function()
    local cam = Workspace.CurrentCamera
    if not cam or not circleDraw then return end
    if CFG.showCircle then
        local vp = cam.ViewportSize
        circleDraw.Position = Vector2.new(vp.X * 0.5, vp.Y * 0.5)
        circleDraw.Radius = CFG.circleRadius
        if (STAT.inCircle or 0) > 0 then
            circleDraw.Color = Color3.fromRGB(255, 80, 80)
        else
            circleDraw.Color = Color3.fromRGB(0, 255, 140)
        end
        circleDraw.Visible = true
    else
        circleDraw.Visible = false
    end
end)

-- ═══════════════════ ④ 魔法子弹 ═══════════════════
local PU = RS.Shared.Wanted.Modules.ProjectileUtil
local pu = require(PU)

local origTraj = pu.GetProjectileTrajectory
if type(origTraj) == "function" then
    pu.GetProjectileTrajectory = newcclosure(function(fromCF, toCF, speed, gunData, ...)
        if CFG.magic then
            local t = pickTarget()
            if t and (t.inCircle or not CFG.circleOnly) then
                local origin = t.pos
                local dir = toCF.Position - fromCF.Position
                if dir.Magnitude < 0.001 then dir = fromCF.LookVector end
                local u = dir.Unit
                local nf = CFrame.lookAt(origin, origin + u * 10)
                local nt = CFrame.lookAt(origin + u * 0.5, origin)
                STAT.redirected = STAT.redirected + 1
                return origTraj(nf, nt, speed, gunData, ...)
            end
        end
        return origTraj(fromCF, toCF, speed, gunData, ...)
    end)
end


local AIM_PRI = Enum.RenderPriority.Camera.Value + 1

local function aimStep()
    if not CFG.aimbot then STAT.aimTarget = "-" return end
    local cam = Workspace.CurrentCamera
    if not cam then return end

    local t = pickTarget()
    if not t then STAT.aimTarget = "-" return end

    local sp = toScreen(t.pos, cam)
    if not sp then STAT.aimTarget = "-" return end

    local vp = cam.ViewportSize
    local dx = sp.X - vp.X * 0.5
    local dy = sp.Y - vp.Y * 0.5
    if math.sqrt(dx*dx + dy*dy) > CFG.aimFOV then
        STAT.aimTarget = "-"
        return
    end

    local aimPos = t.pos
    if t.model then
        pcall(function()
            local part = t.model:FindFirstChild(CFG.aimPart)
            if part and part:IsA("BasePart") then aimPos = part.Position end
        end)
    end

    if CFG.aimVisible then
        local rp = RaycastParams.new()
        rp.FilterType = Enum.RaycastFilterType.Exclude
        rp.FilterDescendantsInstances = { LP.Character, t.model }
        local hit = Workspace:Raycast(cam.CFrame.Position, aimPos - cam.CFrame.Position, rp)
        if hit then STAT.aimTarget = "-" return end
    end

    local want = CFrame.lookAt(cam.CFrame.Position, aimPos)
    if CFG.aimSmooth >= 0.99 then
        cam.CFrame = want
    else
        cam.CFrame = cam.CFrame:Lerp(want, math.clamp(CFG.aimSmooth, 0.05, 1))
    end
    STAT.aimTarget = t.name
end

local function bindAim()
    pcall(function() RunSvc:BindToRenderStep("XS_AIM", AIM_PRI, aimStep) end)
end
local function unbindAim()
    pcall(function() RunSvc:UnbindFromRenderStep("XS_AIM") end)
end
bindAim()

-- ═══════════════════ ⑥ 枪械增强 ═══════════════════
local GUNS = { list = {}, backup = {} }

do
    local Guns = RS.Shared.Wanted.Indicies.Objects.Guns
    if Guns then
        for _, cat in ipairs(Guns:GetChildren()) do
            if cat:IsA("Folder") then
                for _, g in ipairs(cat:GetChildren()) do
                    if g:IsA("ModuleScript") then
                        local ok, m = pcall(require, g)
                        if ok and type(m) == "table" and m.fireDebounce then
                            GUNS.list[#GUNS.list+1] = { name = g.Name, mod = m }
                        end
                    end
                end
            end
        end
    end
end


local function safeSet(t, key, val)
    if type(t) ~= "table" then return false end
    local wasRO = false
    if isreadonly then
        local ok, r = pcall(isreadonly, t)
        if ok then wasRO = r end
    end
    if wasRO and setreadonly then pcall(setreadonly, t, false) end
    local ok = pcall(function() t[key] = val end)
    if not ok and rawset then ok = pcall(rawset, t, key, val) end
    if wasRO and setreadonly then pcall(setreadonly, t, true) end
    return ok
end


for i, e in ipairs(GUNS.list) do
    local m = e.mod
    GUNS.backup[i] = {
        fireDebounce = m.fireDebounce,
        fireMode     = m.fireMode,
        spreadAngle  = m.aim and m.aim.spreadAngle,
        rSpread      = m.recoil and m.recoil.spread,
        rSway        = m.recoil and m.recoil.sway,
        rClimb       = m.recoil and m.recoil.climb,
        rKickBack    = m.recoil and m.recoil.kickBack,
        rKickHoriz   = m.recoil and m.recoil.kickHoriz,
        rFirstKick   = m.recoil and m.recoil.firstShotKick,
        magSize      = m.ammoData and m.ammoData.magSize,
        totalAmmo    = m.ammoData and m.ammoData.totalAmmo,
    }
end

local function applyGuns()
    for i, e in ipairs(GUNS.list) do
        local m, b = e.mod, GUNS.backup[i]

        
        if CFG.gunRapid then
            safeSet(m, "fireDebounce", b.fireDebounce / math.max(CFG.gunRapidMul, 1))
        else
            safeSet(m, "fireDebounce", b.fireDebounce)
        end

        
        if CFG.gunForceAuto then
            if m.fireMode == "semi" then safeSet(m, "fireMode", "auto") end
        else
            if b.fireMode and m.fireMode ~= b.fireMode then
                safeSet(m, "fireMode", b.fireMode)
            end
        end

        
        if m.aim then
            if CFG.gunNoSpread then
                if b.spreadAngle and b.spreadAngle > 0.0005 then
                    safeSet(m.aim, "spreadAngle", 0.0005)
                end
            else
                safeSet(m.aim, "spreadAngle", b.spreadAngle)
            end
        end
        if m.recoil then
            if CFG.gunNoSpread then
                if b.rSpread and b.rSpread > 0.0005 then safeSet(m.recoil, "spread", 0.0005) end
                if b.rSway and b.rSway > 0.0005 then safeSet(m.recoil, "sway", 0.0005) end
            else
                safeSet(m.recoil, "spread", b.rSpread)
                safeSet(m.recoil, "sway", b.rSway)
            end
            if CFG.gunNoRecoil then
                safeSet(m.recoil, "climb", 0)
                safeSet(m.recoil, "kickBack", 0)
                safeSet(m.recoil, "kickHoriz", 0)
                safeSet(m.recoil, "firstShotKick", 0)
            else
                safeSet(m.recoil, "climb", b.rClimb)
                safeSet(m.recoil, "kickBack", b.rKickBack)
                safeSet(m.recoil, "kickHoriz", b.rKickHoriz)
                safeSet(m.recoil, "firstShotKick", b.rFirstKick)
            end
        end

        
        if m.ammoData then
            if CFG.gunInfAmmo then
                safeSet(m.ammoData, "magSize", 999)
                safeSet(m.ammoData, "totalAmmo", 99999)
            else
                safeSet(m.ammoData, "magSize", b.magSize)
                safeSet(m.ammoData, "totalAmmo", b.totalAmmo)
            end
        end
    end
end

applyGuns()


local ammoBackup = {}
local function refreshRuntimeAmmo()
    if not CFG.gunInfAmmo or not getgc then return end
    for _, obj in ipairs(getgc(true)) do
        if type(obj) == "table" then
            local a = rawget(obj, "ammo")
            local t = rawget(obj, "totalAmmo")
            if type(a) == "number" and type(t) == "number" then
                if not ammoBackup[obj] then
                    ammoBackup[obj] = { a = a, t = t }
                end
                if a < 999 then
                    pcall(function() obj.ammo = 999 end)
                    if rawset then pcall(rawset, obj, "ammo", 999) end
                end
                if t < 99999 then
                    pcall(function() obj.totalAmmo = 99999 end)
                    if rawset then pcall(rawset, obj, "totalAmmo", 99999) end
                end
            end
        end
    end
end

local function restoreRuntimeAmmo()
    for obj, b in pairs(ammoBackup) do
        pcall(function() obj.ammo = b.a end)
        pcall(function() obj.totalAmmo = b.t end)
        if rawset then
            pcall(rawset, obj, "ammo", b.a)
            pcall(rawset, obj, "totalAmmo", b.t)
        end
    end
    ammoBackup = {}
end

local lastAmmoScan = 0
local ammoConn = RunSvc.Heartbeat:Connect(function()
    if not CFG.gunInfAmmo then return end
    local now = os.clock()
    if now - lastAmmoScan < 0.3 then return end
    lastAmmoScan = now
    pcall(refreshRuntimeAmmo)
end)

-- ═══════════════════ ⑦ 自动开火 ═══════════════════
local lastShot = 0
local function doClick()
    local ok = pcall(function()
        if mouse1click then
            mouse1click()
        elseif mouse1press and mouse1release then
            mouse1press()
            task.wait(0.008)
            mouse1release()
        else
            local VIM = game:GetService("VirtualInputManager")
            if VIM then
                VIM:SendMouseButtonEvent(0, 0, 0, true, game, 0)
                VIM:SendMouseButtonEvent(0, 0, 0, false, game, 0)
            end
        end
    end)
    return ok
end

local autoConn = RunSvc.Heartbeat:Connect(function()
    if not CFG.autoFire then return end
    local now = os.clock()
    if now - lastShot < CFG.autoFireRate then return end

    local t = pickTarget()
    if not t then return end
    if CFG.circleOnly and not t.inCircle then return end

    if doClick() then
        STAT.shots = STAT.shots + 1
        lastShot = now
    end
end)


local GUI = Instance.new("ScreenGui")
GUI.Name = "XS_Menu"
GUI.ResetOnSpawn = false
GUI.IgnoreGuiInset = true
GUI.DisplayOrder = 999
GUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
pcall(function() GUI.Parent = game:GetService("CoreGui") end)
if not GUI.Parent then GUI.Parent = LP:WaitForChild("PlayerGui") end

-- 主容器
local MAIN = Instance.new("Frame")
MAIN.Name = "Main"
MAIN.BackgroundColor3 = Color3.fromRGB(24, 26, 32)
MAIN.BorderSizePixel = 0
MAIN.Position = UDim2.new(0, 20, 0, 80)
MAIN.Size = UDim2.new(0, 250, 0, 340)
MAIN.Visible = true
MAIN.Parent = GUI

local MAIN_CORNER = Instance.new("UICorner")
MAIN_CORNER.CornerRadius = UDim.new(0, 8)
MAIN_CORNER.Parent = MAIN

local MAIN_STROKE = Instance.new("UIStroke")
MAIN_STROKE.Color = Color3.fromRGB(60, 130, 255)
MAIN_STROKE.Thickness = 1
MAIN_STROKE.Parent = MAIN

-- 标题栏
local TITLE = Instance.new("Frame")
TITLE.Name = "TitleBar"
TITLE.BackgroundColor3 = Color3.fromRGB(32, 36, 46)
TITLE.BorderSizePixel = 0
TITLE.Size = UDim2.new(1, 0, 0, 34)
TITLE.Parent = MAIN
local TITLE_CORNER = Instance.new("UICorner")
TITLE_CORNER.CornerRadius = UDim.new(0, 8)
TITLE_CORNER.Parent = TITLE
-- 
local TITLE_FIX = Instance.new("Frame")
TITLE_FIX.BackgroundColor3 = Color3.fromRGB(32, 36, 46)
TITLE_FIX.BorderSizePixel = 0
TITLE_FIX.Position = UDim2.new(0, 0, 1, -8)
TITLE_FIX.Size = UDim2.new(1, 0, 0, 8)
TITLE_FIX.Parent = TITLE

local TITLE_LBL = Instance.new("TextLabel")
TITLE_LBL.BackgroundTransparency = 1
TITLE_LBL.Text = "星神 · 通缉"
TITLE_LBL.TextColor3 = Color3.fromRGB(120, 180, 255)
TITLE_LBL.TextSize = 14
TITLE_LBL.Font = Enum.Font.GothamBold
TITLE_LBL.TextXAlignment = Enum.TextXAlignment.Left
TITLE_LBL.Position = UDim2.new(0, 12, 0, 0)
TITLE_LBL.Size = UDim2.new(1, -70, 1, 0)
TITLE_LBL.Parent = TITLE

-- 折叠按钮
local MIN_BTN = Instance.new("TextButton")
MIN_BTN.BackgroundColor3 = Color3.fromRGB(50, 56, 70)
MIN_BTN.BorderSizePixel = 0
MIN_BTN.Text = "−"
MIN_BTN.TextColor3 = Color3.fromRGB(200, 210, 230)
MIN_BTN.TextSize = 16
MIN_BTN.Font = Enum.Font.GothamBold
MIN_BTN.Position = UDim2.new(1, -56, 0, 7)
MIN_BTN.Size = UDim2.new(0, 20, 0, 20)
MIN_BTN.Parent = TITLE
local MB_C = Instance.new("UICorner")
MB_C.CornerRadius = UDim.new(0, 4)
MB_C.Parent = MIN_BTN

-- 关闭按钮
local CLOSE_BTN = Instance.new("TextButton")
CLOSE_BTN.BackgroundColor3 = Color3.fromRGB(180, 60, 70)
CLOSE_BTN.BorderSizePixel = 0
CLOSE_BTN.Text = "×"
CLOSE_BTN.TextColor3 = Color3.fromRGB(255, 255, 255)
CLOSE_BTN.TextSize = 16
CLOSE_BTN.Font = Enum.Font.GothamBold
CLOSE_BTN.Position = UDim2.new(1, -30, 0, 7)
CLOSE_BTN.Size = UDim2.new(0, 20, 0, 20)
CLOSE_BTN.Parent = TITLE
local CB_C = Instance.new("UICorner")
CB_C.CornerRadius = UDim.new(0, 4)
CB_C.Parent = CLOSE_BTN

-- 标签按钮（四个）
local TAB_BAR = Instance.new("Frame")
TAB_BAR.BackgroundTransparency = 1
TAB_BAR.Position = UDim2.new(0, 4, 0, 38)
TAB_BAR.Size = UDim2.new(1, -8, 0, 26)
TAB_BAR.Parent = MAIN

local TABS = {}
local TAB_NAMES = { "透视", "魔法", "武器", "操作" }
for i, nm in ipairs(TAB_NAMES) do
    local b = Instance.new("TextButton")
    b.BackgroundColor3 = Color3.fromRGB(36, 40, 50)
    b.BorderSizePixel = 0
    b.Text = nm
    b.TextColor3 = Color3.fromRGB(160, 170, 190)
    b.TextSize = 11
    b.Font = Enum.Font.GothamMedium
    b.Position = UDim2.new(0, (i-1) * 60, 0, 0)
    b.Size = UDim2.new(0, 58, 0, 26)
    b.Parent = TAB_BAR
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 5)
    c.Parent = b
    TABS[i] = b
end

-- 内容滚动区
local SCROLL = Instance.new("ScrollingFrame")
SCROLL.BackgroundTransparency = 1
SCROLL.BorderSizePixel = 0
SCROLL.Position = UDim2.new(0, 4, 0, 70)
SCROLL.Size = UDim2.new(1, -8, 1, -76)
SCROLL.CanvasSize = UDim2.new(0, 0, 0, 0)
SCROLL.ScrollBarThickness = 4
SCROLL.ScrollBarImageColor3 = Color3.fromRGB(60, 130, 255)
SCROLL.ScrollingDirection = Enum.ScrollingDirection.Y
SCROLL.Parent = MAIN

-- 每页容器
local PAGES = {}
for i = 1, 4 do
    local p = Instance.new("Frame")
    p.BackgroundTransparency = 1
    p.Size = UDim2.new(1, 0, 1, 0)
    p.Visible = (i == 1)
    p.Parent = SCROLL
    PAGES[i] = p
end

-- ─── UI 构造工具 ───
local Y = { 0, 0, 0, 0 }

local function addRow(pageIdx, h)
    local y = Y[pageIdx]
    Y[pageIdx] = Y[pageIdx] + (h or 26)
    return y
end

local function addLabel(pageIdx, text, size, color)
    local y = addRow(pageIdx, 18)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.Text = text
    l.TextColor3 = color or Color3.fromRGB(120, 180, 255)
    l.TextSize = size or 11
    l.Font = Enum.Font.GothamBold
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Position = UDim2.new(0, 6, 0, y)
    l.Size = UDim2.new(1, -12, 0, 18)
    l.Parent = PAGES[pageIdx]
    return l
end

local function addToggle(pageIdx, text, getter, setter)
    local y = addRow(pageIdx, 26)
    local lbl = Instance.new("TextLabel")
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = Color3.fromRGB(210, 218, 232)
    lbl.TextSize = 11
    lbl.Font = Enum.Font.Gotham
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Position = UDim2.new(0, 8, 0, y)
    lbl.Size = UDim2.new(1, -60, 0, 26)
    lbl.Parent = PAGES[pageIdx]

    local btn = Instance.new("TextButton")
    btn.BackgroundColor3 = getter() and Color3.fromRGB(60, 130, 255) or Color3.fromRGB(50, 54, 64)
    btn.BorderSizePixel = 0
    btn.Text = ""
    btn.Position = UDim2.new(1, -46, 0, y + 5)
    btn.Size = UDim2.new(0, 36, 0, 18)
    btn.Parent = PAGES[pageIdx]
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(1, 0)
    c.Parent = btn

    local knob = Instance.new("Frame")
    knob.BackgroundColor3 = Color3.new(1, 1, 1)
    knob.BorderSizePixel = 0
    knob.Size = UDim2.new(0, 14, 0, 14)
    knob.Position = getter() and UDim2.new(1, -16, 0, 2) or UDim2.new(0, 2, 0, 2)
    knob.Parent = btn
    local kc = Instance.new("UICorner")
    kc.CornerRadius = UDim.new(1, 0)
    kc.Parent = knob

    btn.MouseButton1Click:Connect(function()
        local now = not getter()
        setter(now)
        Tween:Create(btn, TweenInfo.new(0.15), {
            BackgroundColor3 = now and Color3.fromRGB(60, 130, 255) or Color3.fromRGB(50, 54, 64)
        }):Play()
        Tween:Create(knob, TweenInfo.new(0.15), {
            Position = now and UDim2.new(1, -16, 0, 2) or UDim2.new(0, 2, 0, 2)
        }):Play()
    end)
    return btn
end

local function addSlider(pageIdx, text, minV, maxV, getter, setter, decimals)
    decimals = decimals or 0
    local y1 = addRow(pageIdx, 17)
    local lbl = Instance.new("TextLabel")
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = Color3.fromRGB(190, 200, 218)
    lbl.TextSize = 10
    lbl.Font = Enum.Font.Gotham
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Position = UDim2.new(0, 8, 0, y1)
    lbl.Size = UDim2.new(1, -70, 0, 17)
    lbl.Parent = PAGES[pageIdx]

    local valLbl = Instance.new("TextLabel")
    valLbl.BackgroundTransparency = 1
    valLbl.Text = string.format("%." .. decimals .. "f", getter())
    valLbl.TextColor3 = Color3.fromRGB(120, 180, 255)
    valLbl.TextSize = 10
    valLbl.Font = Enum.Font.GothamBold
    valLbl.TextXAlignment = Enum.TextXAlignment.Right
    valLbl.Position = UDim2.new(1, -56, 0, y1)
    valLbl.Size = UDim2.new(0, 50, 0, 17)
    valLbl.Parent = PAGES[pageIdx]

    local y2 = addRow(pageIdx, 24)

    local track = Instance.new("Frame")
    track.BackgroundColor3 = Color3.fromRGB(50, 54, 64)
    track.BorderSizePixel = 0
    track.Position = UDim2.new(0, 8, 0, y2 + 8)
    track.Size = UDim2.new(1, -16, 0, 4)
    track.Parent = PAGES[pageIdx]
    local tc = Instance.new("UICorner")
    tc.CornerRadius = UDim.new(1, 0)
    tc.Parent = track

    local fill = Instance.new("Frame")
    fill.BackgroundColor3 = Color3.fromRGB(60, 130, 255)
    fill.BorderSizePixel = 0
    fill.Size = UDim2.new((getter() - minV) / (maxV - minV), 0, 1, 0)
    fill.Parent = track
    local fc = Instance.new("UICorner")
    fc.CornerRadius = UDim.new(1, 0)
    fc.Parent = fill

    local hit = Instance.new("TextButton")
    hit.BackgroundTransparency = 1
    hit.Text = ""
    hit.Position = UDim2.new(0, 0, 0, y2)
    hit.Size = UDim2.new(1, 0, 0, 24)
    hit.Parent = PAGES[pageIdx]

    local dragging = false

    local function updateFromX(absX)
        local trackAbs = track.AbsolutePosition.X
        local trackW = track.AbsoluteSize.X
        local ratio = math.clamp((absX - trackAbs) / trackW, 0, 1)
        local v = minV + ratio * (maxV - minV)
        if decimals == 0 then v = math.floor(v + 0.5) end
        setter(v)
        fill.Size = UDim2.new(ratio, 0, 1, 0)
        valLbl.Text = string.format("%." .. decimals .. "f", v)
    end

    hit.MouseButton1Down:Connect(function()
        dragging = true
        updateFromX(UIS:GetMouseLocation().X)
    end)
    hit.MouseMoved:Connect(function()
        if dragging then updateFromX(UIS:GetMouseLocation().X) end
    end)
    UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
           or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    -- 触屏支持
    hit.TouchLongPress:Connect(function()
        dragging = true
    end)

    return track
end

local function addButton(pageIdx, text, onClick)
    local y = addRow(pageIdx, 32)
    local b = Instance.new("TextButton")
    b.BackgroundColor3 = Color3.fromRGB(42, 48, 60)
    b.BorderSizePixel = 0
    b.Text = text
    b.TextColor3 = Color3.fromRGB(200, 215, 240)
    b.TextSize = 11
    b.Font = Enum.Font.GothamMedium
    b.Position = UDim2.new(0, 8, 0, y + 2)
    b.Size = UDim2.new(1, -16, 0, 28)
    b.Parent = PAGES[pageIdx]
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 5)
    c.Parent = b
    b.MouseEnter:Connect(function()
        Tween:Create(b, TweenInfo.new(0.12), { BackgroundColor3 = Color3.fromRGB(56, 66, 84) }):Play()
    end)
    b.MouseLeave:Connect(function()
        Tween:Create(b, TweenInfo.new(0.12), { BackgroundColor3 = Color3.fromRGB(42, 48, 60) }):Play()
    end)
    b.MouseButton1Click:Connect(onClick)
    return b
end

-- 三连按钮（目标类型）
local function addTriple(pageIdx, label, opts, getter, setter)
    local y = addRow(pageIdx, 28)
    local lbl = Instance.new("TextLabel")
    lbl.BackgroundTransparency = 1
    lbl.Text = label
    lbl.TextColor3 = Color3.fromRGB(190, 200, 218)
    lbl.TextSize = 10
    lbl.Font = Enum.Font.Gotham
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Position = UDim2.new(0, 8, 0, y)
    lbl.Size = UDim2.new(0, 46, 0, 28)
    lbl.Parent = PAGES[pageIdx]

    local btns = {}
    for i, o in ipairs(opts) do
        local b = Instance.new("TextButton")
        local cur = getter()
        local on = (cur == o.v)
        b.BackgroundColor3 = on and Color3.fromRGB(60, 130, 255) or Color3.fromRGB(42, 48, 60)
        b.BorderSizePixel = 0
        b.Text = o.t
        b.TextColor3 = on and Color3.new(1,1,1) or Color3.fromRGB(180, 190, 210)
        b.TextSize = 10
        b.Font = Enum.Font.GothamMedium
        b.Position = UDim2.new(0, 56 + (i-1) * 60, 0, y + 3)
        b.Size = UDim2.new(0, 56, 0, 22)
        b.Parent = PAGES[pageIdx]
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, 4)
        c.Parent = b
        btns[i] = b
        b.MouseButton1Click:Connect(function()
            setter(o.v)
            for j, bb in ipairs(btns) do
                local isOn = (opts[j].v == o.v)
                bb.BackgroundColor3 = isOn and Color3.fromRGB(60, 130, 255) or Color3.fromRGB(42, 48, 60)
                bb.TextColor3 = isOn and Color3.new(1,1,1) or Color3.fromRGB(180, 190, 210)
            end
        end)
    end
end

-- ═══════════════════ 填内容 ═══════════════════

-- ── 页 1：透视 ──
addLabel(1, "透视 ESP")
addToggle(1, "总开关",    function() return CFG.esp end,           function(v) CFG.esp = v end)
addToggle(1, "方框",      function() return CFG.espBox end,        function(v) CFG.espBox = v end)
addToggle(1, "名字",      function() return CFG.espName end,       function(v) CFG.espName = v end)
addToggle(1, "血量",      function() return CFG.espHealth end,     function(v) CFG.espHealth = v end)
addToggle(1, "距离",      function() return CFG.espDist end,       function(v) CFG.espDist = v end)
addToggle(1, "过检测",  function() return CFG.espFilterFake end, function(v) CFG.espFilterFake = v end)
addSlider(1, "最远距离", 100, 5000, function() return CFG.espMaxDist end, function(v) CFG.espMaxDist = v end, 0)

-- ── 页 2：魔法 ──
addLabel(2, "魔法子弹")
addToggle(2, "魔法子弹",      function() return CFG.magic end,      function(v) CFG.magic = v end)
addToggle(2, "只打圈内",      function() return CFG.circleOnly end, function(v) CFG.circleOnly = v end)
addToggle(2, "显示圆圈",      function() return CFG.showCircle end, function(v) CFG.showCircle = v end)
addSlider(2, "圆圈大小", 30, 600, function() return CFG.circleRadius end, function(v) CFG.circleRadius = v end, 0)
addTriple(2, "目标", {
    { t = "玩家", v = "player" },
    { t = "NPC",  v = "npc" },
    { t = "全部", v = "any" },
}, function() return CFG.magicMode end, function(v) CFG.magicMode = v end)

addLabel(2, "自瞄")
addToggle(2, " 瞄头",   function() return CFG.aimbot end,     function(v) CFG.aimbot = v end)
addSlider(2, "自瞄范围", 30, 800, function() return CFG.aimFOV end, function(v) CFG.aimFOV = v end, 0)
addSlider(2, "平滑", 0.05, 1.0, function() return CFG.aimSmooth end, function(v) CFG.aimSmooth = v end, 2)
addToggle(2, "漏打",   function() return CFG.aimVisible end, function(v) CFG.aimVisible = v end)

-- ── 页 3：武器 ──
addLabel(3, "枪械增强")
addToggle(3, "无扩散",     function() return CFG.gunNoSpread end,  function(v) CFG.gunNoSpread = v; applyGuns() end)
addToggle(3, "无后坐力",   function() return CFG.gunNoRecoil end,  function(v) CFG.gunNoRecoil = v; applyGuns() end)
addToggle(3, "射速开",   function() return CFG.gunRapid end,     function(v) CFG.gunRapid = v; applyGuns() end)
addSlider(3, "射速倍数", 1, 10, function() return CFG.gunRapidMul end, function(v) CFG.gunRapidMul = v; applyGuns() end, 1)

addLabel(3, "弹药")
addToggle(3, "无限弹药（仅供娱乐）",     function() return CFG.gunInfAmmo end, function(v)
    CFG.gunInfAmmo = v
    applyGuns()
    if v then pcall(refreshRuntimeAmmo) else pcall(restoreRuntimeAmmo) end
end)
addToggle(3, "单发改全自动", function() return CFG.gunForceAuto end, function(v)
    CFG.gunForceAuto = v
    applyGuns()
end)

addLabel(3, "自动开火")
addToggle(3, "自动开火",   function() return CFG.autoFire end,     function(v) CFG.autoFire = v end)
addSlider(3, "开火间隔", 0.03, 1.0, function() return CFG.autoFireRate end, function(v) CFG.autoFireRate = v end, 2)

-- ── 页 4：操作 ──
addLabel(4, "状态")
local STAT_LBL = Instance.new("TextLabel")
STAT_LBL.BackgroundTransparency = 1
STAT_LBL.Text = "..."
STAT_LBL.TextColor3 = Color3.fromRGB(180, 195, 220)
STAT_LBL.TextSize = 10
STAT_LBL.Font = Enum.Font.Code
STAT_LBL.TextXAlignment = Enum.TextXAlignment.Left
STAT_LBL.TextYAlignment = Enum.TextYAlignment.Top
STAT_LBL.TextWrapped = true
STAT_LBL.Position = UDim2.new(0, 8, 0, Y[4])
STAT_LBL.Size = UDim2.new(1, -16, 0, 110)
STAT_LBL.Parent = PAGES[4]
Y[4] = Y[4] + 116

addLabel(4, "快捷操作")
addButton(4, "扫描目标", function()
    local mp = myPos()
    if not mp then return end
    local list = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and p.Character then
            local hrp = p.Character:FindFirstChild("HumanoidRootPart")
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            if hrp and hum and hum.Health > 0 then
                local d = (hrp.Position - mp).Magnitude
                list[#list+1] = string.format("%s %dm", p.Name, math.floor(d))
            end
        end
    end
    table.sort(list)
    STAT_LBL.Text = "玩家 " .. #list .. ":\n" .. table.concat(list, "\n")
end)
addButton(4, "关闭 ESP", function() CFG.esp = false end)
addButton(4, "关闭魔法", function() CFG.magic = false; CFG.aimbot = false end)
addButton(4, "全部关闭", function()
    CFG.esp = false
    CFG.magic = false
    CFG.aimbot = false
    CFG.autoFire = false
    CFG.gunInfAmmo = false
    CFG.gunForceAuto = false
    CFG.gunNoSpread = false
    CFG.gunNoRecoil = false
    CFG.gunRapid = false
    applyGuns()
    restoreRuntimeAmmo()
end)
addButton(4, "重载脚本", function()
    if _G.__XS_ALL then _G.__XS_ALL.unload() end
end)

-- 每页设置 CanvasSize
for i = 1, 4 do
    local total = Y[i] + 10
    PAGES[i].Size = UDim2.new(1, 0, 0, total)
end

-- 标签切换
local curTab = 1
local function selectTab(idx)
    curTab = idx
    for i = 1, 4 do
        PAGES[i].Visible = (i == idx)
        TABS[i].BackgroundColor3 = (i == idx) and Color3.fromRGB(60, 130, 255) or Color3.fromRGB(36, 40, 50)
        TABS[i].TextColor3 = (i == idx) and Color3.new(1,1,1) or Color3.fromRGB(160, 170, 190)
    end
    -- 更新滚动区 CanvasSize
    SCROLL.CanvasSize = UDim2.new(0, 0, 0, Y[idx] + 40)
    SCROLL.CanvasPosition = Vector2.new(0, 0)
end
for i, b in ipairs(TABS) do
    b.MouseButton1Click:Connect(function() selectTab(i) end)
end
selectTab(1)

-- 折叠
local collapsed = false
local fullSize = UDim2.new(0, 250, 0, 340)
MIN_BTN.MouseButton1Click:Connect(function()
    collapsed = not collapsed
    if collapsed then
        MAIN.Size = UDim2.new(0, 250, 0, 34)
        MIN_BTN.Text = "+"
    else
        MAIN.Size = fullSize
        MIN_BTN.Text = "−"
    end
end)

-- 关闭
CLOSE_BTN.MouseButton1Click:Connect(function()
    GUI.Enabled = false
end)

-- 拖动（只有标题栏能拖）
local dragging, dragStart, startPos
TITLE.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
       or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = MAIN.Position
    end
end)
UIS.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
       or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        MAIN.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X,
                                  startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)
UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
       or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

-- 状态刷新
local statConn = RunSvc.Heartbeat:Connect(function()
    if curTab ~= 4 or not STAT_LBL then return end
    local lines = {
        string.format("运行 %ds", math.floor(os.clock() - STAT.t0)),
        string.format("ESP 绘制 %d", STAT.drawn),
        string.format("弹道改写 %d", STAT.redirected),
        string.format("自瞄锁定 %s", tostring(STAT.aimTarget)),
        string.format("圈内 %d / 玩家 %d / NPC %d",
            STAT.inCircle or 0, STAT.players or 0, STAT.npcs or 0),
        string.format("自动开火 %d", STAT.shots),
    }
    STAT_LBL.Text = table.concat(lines, "\n")
end)

-- ═══════════════════ ⑨ 卸载 ═══════════════════
local function unload()
    pcall(function() ESP.conn:Disconnect() end)
    pcall(function() circleConn:Disconnect() end)
    pcall(function() ammoConn:Disconnect() end)
    pcall(function() autoConn:Disconnect() end)
    pcall(function() statConn:Disconnect() end)
    unbindAim()

    for _, d in pairs(ESP.draws) do killDraw(d) end
    ESP.draws = {}

    if circleDraw then
        pcall(function() circleDraw.Visible = false end)
        pcall(function() circleDraw:Remove() end)
    end

    pcall(function() GUI:Destroy() end)

    -- 还原枪械
    for i, e in ipairs(GUNS.list) do
        local m, b = e.mod, GUNS.backup[i]
        safeSet(m, "fireDebounce", b.fireDebounce)
        if b.fireMode then safeSet(m, "fireMode", b.fireMode) end
        if m.aim then safeSet(m.aim, "spreadAngle", b.spreadAngle) end
        if m.recoil then
            safeSet(m.recoil, "spread", b.rSpread)
            safeSet(m.recoil, "sway", b.rSway)
            safeSet(m.recoil, "climb", b.rClimb)
            safeSet(m.recoil, "kickBack", b.rKickBack)
            safeSet(m.recoil, "kickHoriz", b.rKickHoriz)
            safeSet(m.recoil, "firstShotKick", b.rFirstKick)
        end
        if m.ammoData then
            safeSet(m.ammoData, "magSize", b.magSize)
            safeSet(m.ammoData, "totalAmmo", b.totalAmmo)
        end
    end
    restoreRuntimeAmmo()

    _G.__XS_ALL = nil
end

_G.__XS_ALL = {
    cfg = CFG,
    stat = STAT,
    unload = unload,
    gui = GUI,
    show = function() GUI.Enabled = true end,
    hide = function() GUI.Enabled = false end,
}

return {
    ok = true,
    guns = #GUNS.list,
    features = "ESP / 魔法子弹 / 自瞄 / 准心圆圈 / 枪械增强 / 自动开火",
    unload = "_G.__XS_ALL.unload()",
}
