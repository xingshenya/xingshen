
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

local T = {
    bg      = Color3.fromRGB(16, 17, 21),
    panel   = Color3.fromRGB(24, 26, 32),
    card    = Color3.fromRGB(32, 35, 42),
    cardHi  = Color3.fromRGB(42, 46, 56),
    line    = Color3.fromRGB(50, 54, 64),
    text    = Color3.fromRGB(232, 234, 240),
    sub     = Color3.fromRGB(132, 138, 152),
    accent  = Color3.fromRGB(52, 199, 123),
    accent2 = Color3.fromRGB(66, 133, 244),
    danger  = Color3.fromRGB(232, 78, 78),
    off     = Color3.fromRGB(64, 68, 80),
    purple  = Color3.fromRGB(180, 90, 240),
    gold    = Color3.fromRGB(255, 200, 60),
}

local function corner(p, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 8)
    c.Parent = p
    return c
end

local function stroke(p, col, th)
    local s = Instance.new("UIStroke")
    s.Color = col or T.line
    s.Thickness = th or 1
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = p
    return s
end

local container
pcall(function() container = gethui and gethui() end)
if not container then
    local ok, cg = pcall(function() return game:GetService("CoreGui") end)
    if ok and cg then
        local canWrite = pcall(function()
            local probe = Instance.new("Folder")
            probe.Parent = cg
            probe:Destroy()
        end)
        if canWrite then container = cg end
    end
end
if not container then
    container = LP:WaitForChild("PlayerGui")
end

local GUI = Instance.new("ScreenGui")
GUI.Name = "XS_CS"
GUI.ResetOnSpawn = false
GUI.IgnoreGuiInset = true
GUI.DisplayOrder = 999
GUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
pcall(function() GUI.Parent = container end)
if not GUI.Parent then GUI.Parent = LP:WaitForChild("PlayerGui") end
ROOT.gui = GUI

local BALL = Instance.new("TextButton")
BALL.Name = "Ball"
BALL.Size = UDim2.new(0, 52, 0, 52)
BALL.Position = UDim2.new(0, 16, 0, 150)
BALL.BackgroundColor3 = T.accent
BALL.Text = "星"
BALL.TextColor3 = Color3.fromRGB(10, 20, 15)
BALL.Font = Enum.Font.GothamBold
BALL.TextSize = 20
BALL.AutoButtonColor = false
BALL.BorderSizePixel = 0
BALL.Parent = GUI
corner(BALL, 26)
stroke(BALL, Color3.fromRGB(0, 0, 0), 2)

local PW, PH = 356, 520

local PANEL = Instance.new("Frame")
PANEL.Name = "Panel"
PANEL.Size = UDim2.new(0, PW, 0, PH)
PANEL.Position = UDim2.new(0, 10, 0, 40)
PANEL.BackgroundColor3 = T.bg
PANEL.BorderSizePixel = 0
PANEL.Active = true
PANEL.ClipsDescendants = true
PANEL.Parent = GUI
corner(PANEL, 14)
stroke(PANEL, T.line, 1)

local TOPBAR = Instance.new("Frame")
TOPBAR.Size = UDim2.new(1, 0, 0, 3)
TOPBAR.BackgroundColor3 = T.accent
TOPBAR.BorderSizePixel = 0
TOPBAR.Parent = PANEL

local grad = Instance.new("UIGradient")
grad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0.00, T.accent),
    ColorSequenceKeypoint.new(0.50, T.accent2),
    ColorSequenceKeypoint.new(1.00, T.purple),
})
grad.Parent = TOPBAR

local HEADER = Instance.new("Frame")
HEADER.Name = "Header"
HEADER.Size = UDim2.new(1, 0, 0, 46)
HEADER.Position = UDim2.new(0, 0, 0, 3)
HEADER.BackgroundTransparency = 1
HEADER.Parent = PANEL

local LOGO = Instance.new("Frame")
LOGO.Size = UDim2.new(0, 26, 0, 26)
LOGO.Position = UDim2.new(0, 14, 0, 10)
LOGO.BackgroundColor3 = T.accent
LOGO.BorderSizePixel = 0
LOGO.Parent = HEADER
corner(LOGO, 13)

local LOGOTXT = Instance.new("TextLabel")
LOGOTXT.Size = UDim2.new(1, 0, 1, 0)
LOGOTXT.BackgroundTransparency = 1
LOGOTXT.Text = "星"
LOGOTXT.TextColor3 = Color3.fromRGB(10, 20, 15)
LOGOTXT.Font = Enum.Font.GothamBold
LOGOTXT.TextSize = 15
LOGOTXT.Parent = LOGO

local TITLE = Instance.new("TextLabel")
TITLE.Size = UDim2.new(1, -100, 0, 20)
TITLE.Position = UDim2.new(0, 48, 0, 8)
TITLE.BackgroundTransparency = 1
TITLE.Text = "星神BS定制"
TITLE.TextColor3 = T.text
TITLE.TextXAlignment = Enum.TextXAlignment.Left
TITLE.Font = Enum.Font.GothamBold
TITLE.TextSize = 15
TITLE.Parent = HEADER

local SUBTITLE = Instance.new("TextLabel")
SUBTITLE.Size = UDim2.new(1, -100, 0, 16)
SUBTITLE.Position = UDim2.new(0, 48, 0, 25)
SUBTITLE.BackgroundTransparency = 1
SUBTITLE.Text = "星神美化"
SUBTITLE.TextColor3 = T.sub
SUBTITLE.TextXAlignment = Enum.TextXAlignment.Left
SUBTITLE.Font = Enum.Font.Gotham
SUBTITLE.TextSize = 10
SUBTITLE.Parent = HEADER

local MINBTN = Instance.new("TextButton")
MINBTN.Size = UDim2.new(0, 28, 0, 28)
MINBTN.Position = UDim2.new(1, -74, 0, 9)
MINBTN.BackgroundColor3 = T.card
MINBTN.Text = "—"
MINBTN.TextColor3 = T.text
MINBTN.Font = Enum.Font.GothamBold
MINBTN.TextSize = 16
MINBTN.AutoButtonColor = false
MINBTN.BorderSizePixel = 0
MINBTN.Parent = HEADER
corner(MINBTN, 7)

local CLOSEBTN = Instance.new("TextButton")
CLOSEBTN.Size = UDim2.new(0, 28, 0, 28)
CLOSEBTN.Position = UDim2.new(1, -40, 0, 9)
CLOSEBTN.BackgroundColor3 = T.danger
CLOSEBTN.Text = "×"
CLOSEBTN.TextColor3 = Color3.new(1, 1, 1)
CLOSEBTN.Font = Enum.Font.GothamBold
CLOSEBTN.TextSize = 18
CLOSEBTN.AutoButtonColor = false
CLOSEBTN.BorderSizePixel = 0
CLOSEBTN.Parent = HEADER
corner(CLOSEBTN, 7)

local TABBAR = Instance.new("Frame")
TABBAR.Size = UDim2.new(1, -24, 0, 36)
TABBAR.Position = UDim2.new(0, 12, 0, 53)
TABBAR.BackgroundColor3 = T.panel
TABBAR.BorderSizePixel = 0
TABBAR.Parent = PANEL
corner(TABBAR, 9)

local TABS = { "美化", "透视", "武器功能", "自瞄" }
local tabBtns, pages = {}, {}

local CONTENT = Instance.new("Frame")
CONTENT.Size = UDim2.new(1, -24, 1, -152)
CONTENT.Position = UDim2.new(0, 12, 0, 95)
CONTENT.BackgroundTransparency = 1
CONTENT.Parent = PANEL

local function showPage(idx)
    for i, p in pairs(pages) do p.Visible = (i == idx) end
    for i, b in pairs(tabBtns) do
        Tween:Create(b, TweenInfo.new(0.15), {
            BackgroundColor3 = (i == idx) and T.accent or T.card,
        }):Play()
        b.TextColor3 = (i == idx) and Color3.fromRGB(10, 20, 15) or T.sub
    end
end

local TABW = math.floor((PW - 24 - 8) / #TABS)
for i, nm in ipairs(TABS) do
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, TABW, 1, -8)
    b.Position = UDim2.new(0, 4 + (i - 1) * TABW, 0, 4)
    b.BackgroundColor3 = (i == 1) and T.accent or T.card
    b.Text = nm
    b.TextColor3 = (i == 1) and Color3.fromRGB(10, 20, 15) or T.sub
    b.Font = Enum.Font.GothamBold
    b.TextSize = 11
    b.AutoButtonColor = false
    b.BorderSizePixel = 0
    b.Parent = TABBAR
    corner(b, 7)
    tabBtns[i] = b
    b.MouseButton1Click:Connect(function() showPage(i) end)

    local sf = Instance.new("ScrollingFrame")
    sf.Size = UDim2.new(1, 0, 1, 0)
    sf.BackgroundTransparency = 1
    sf.BorderSizePixel = 0
    sf.ScrollBarThickness = 3
    sf.ScrollBarImageColor3 = T.accent
    sf.ScrollBarImageTransparency = 0.4
    sf.ScrollingDirection = Enum.ScrollingDirection.Y
    sf.CanvasSize = UDim2.new(0, 0, 0, 0)
    sf.AutomaticCanvasSize = Enum.AutomaticSize.Y
    sf.Visible = (i == 1)
    sf.Parent = CONTENT

    local lay = Instance.new("UIListLayout")
    lay.Padding = UDim.new(0, 6)
    lay.SortOrder = Enum.SortOrder.LayoutOrder
    lay.Parent = sf

    pages[i] = sf
end

local function mkCard(parent, h)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, -4, 0, h or 48)
    f.BackgroundColor3 = T.card
    f.BorderSizePixel = 0
    f.Parent = parent
    corner(f, 9)
    return f
end

local function mkToggle(parent, label, desc, get, set)
    local c = mkCard(parent, 50)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -70, 0, 18)
    lbl.Position = UDim2.new(0, 14, 0, 8)
    lbl.BackgroundTransparency = 1
    lbl.Text = label
    lbl.TextColor3 = T.text
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Font = Enum.Font.GothamSemibold
    lbl.TextSize = 13
    lbl.Parent = c

    local dsc = Instance.new("TextLabel")
    dsc.Size = UDim2.new(1, -70, 0, 14)
    dsc.Position = UDim2.new(0, 14, 0, 27)
    dsc.BackgroundTransparency = 1
    dsc.Text = desc or ""
    dsc.TextColor3 = T.sub
    dsc.TextXAlignment = Enum.TextXAlignment.Left
    dsc.Font = Enum.Font.Gotham
    dsc.TextSize = 10
    dsc.Parent = c

    local track = Instance.new("Frame")
    track.Size = UDim2.new(0, 44, 0, 24)
    track.Position = UDim2.new(1, -58, 0.5, -12)
    track.BackgroundColor3 = get() and T.accent or T.off
    track.BorderSizePixel = 0
    track.Parent = c
    corner(track, 12)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 18, 0, 18)
    knob.Position = get() and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9)
    knob.BackgroundColor3 = Color3.new(1, 1, 1)
    knob.BorderSizePixel = 0
    knob.Parent = track
    corner(knob, 9)

    local hit = Instance.new("TextButton")
    hit.Size = UDim2.new(1, 0, 1, 0)
    hit.BackgroundTransparency = 1
    hit.Text = ""
    hit.Parent = c

    hit.MouseButton1Click:Connect(function()
        local v = not get()
        set(v)
        Tween:Create(track, TweenInfo.new(0.18), {
            BackgroundColor3 = v and T.accent or T.off,
        }):Play()
        Tween:Create(knob, TweenInfo.new(0.18, Enum.EasingStyle.Quad), {
            Position = v and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9),
        }):Play()
    end)
end

local function mkSlider(parent, label, minV, maxV, step, get, set, fmt)
    local c = mkCard(parent, 62)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -90, 0, 18)
    lbl.Position = UDim2.new(0, 14, 0, 8)
    lbl.BackgroundTransparency = 1
    lbl.Text = label
    lbl.TextColor3 = T.text
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Font = Enum.Font.GothamSemibold
    lbl.TextSize = 13
    lbl.Parent = c

    local val = Instance.new("TextLabel")
    val.Size = UDim2.new(0, 86, 0, 18)
    val.Position = UDim2.new(1, -90, 0, 8)
    val.BackgroundTransparency = 1
    val.Text = fmt and fmt(get()) or tostring(get())
    val.TextColor3 = T.accent
    val.TextXAlignment = Enum.TextXAlignment.Right
    val.Font = Enum.Font.GothamBold
    val.TextSize = 12
    val.Parent = c

    local track = Instance.new("Frame")
    track.Size = UDim2.new(1, -28, 0, 8)
    track.Position = UDim2.new(0, 14, 0, 40)
    track.BackgroundColor3 = T.off
    track.BorderSizePixel = 0
    track.Parent = c
    corner(track, 4)

    local fill = Instance.new("Frame")
    fill.BackgroundColor3 = T.accent
    fill.BorderSizePixel = 0
    fill.Parent = track
    corner(fill, 4)

    local dot = Instance.new("Frame")
    dot.Size = UDim2.new(0, 14, 0, 14)
    dot.AnchorPoint = Vector2.new(0.5, 0.5)
    dot.BackgroundColor3 = Color3.new(1, 1, 1)
    dot.BorderSizePixel = 0
    dot.Parent = track
    corner(dot, 7)

    local function paint(v)
        local r = (maxV > minV) and math.clamp((v - minV) / (maxV - minV), 0, 1) or 0
        fill.Size = UDim2.new(r, 0, 1, 0)
        dot.Position = UDim2.new(r, 0, 0.5, 0)
        val.Text = fmt and fmt(v) or tostring(v)
    end
    paint(get())

    local hit = Instance.new("TextButton")
    hit.Size = UDim2.new(1, 0, 0, 30)
    hit.Position = UDim2.new(0, 0, 0, 28)
    hit.BackgroundTransparency = 1
    hit.Text = ""
    hit.Parent = c

    local function fromX(px)
        local x0 = track.AbsolutePosition.X
        local w = math.max(track.AbsoluteSize.X, 1)
        local r = math.clamp((px - x0) / w, 0, 1)
        local raw = minV + (maxV - minV) * r
        local v = math.floor(raw / step + 0.5) * step
        v = math.clamp(v, minV, maxV)
        v = math.floor(v / step + 0.5) * step
        set(v)
        paint(v)
    end

    hit.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.Touch
           or i.UserInputType == Enum.UserInputType.MouseButton1 then
            fromX(i.Position.X)
        end
    end)
    hit.InputChanged:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.Touch
           or i.UserInputType == Enum.UserInputType.MouseMovement then
            fromX(i.Position.X)
        end
    end)

    return function() paint(get()) end
end

local function mkButton(parent, label, cb, color)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, -4, 0, 42)
    b.BackgroundColor3 = color or T.cardHi
    b.Text = label
    b.TextColor3 = T.text
    b.Font = Enum.Font.GothamBold
    b.TextSize = 12
    b.AutoButtonColor = false
    b.BorderSizePixel = 0
    b.Parent = parent
    corner(b, 9)

    b.MouseButton1Click:Connect(function()
        local ok, msg = pcall(cb)
        if ROOT.notify then
            ROOT.notify(ok and (msg or "完成") or ("失败: " .. tostring(msg)))
        end
    end)
    return b
end

local function mkInfo(parent, text, color)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, -4, 0, 20)
    l.BackgroundTransparency = 1
    l.Text = text
    l.TextColor3 = color or T.sub
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Font = Enum.Font.Gotham
    l.TextSize = 10
    l.Parent = parent
    return l
end

local function popupPickGun(onPick)
    local cats = ROOT.getGunsByCategory()

    local bg = Instance.new("TextButton")
    bg.Size = UDim2.new(1, 0, 1, 0)
    bg.BackgroundColor3 = Color3.new(0, 0, 0)
    bg.BackgroundTransparency = 0.5
    bg.Text = ""
    bg.AutoButtonColor = false
    bg.ZIndex = 400
    bg.Parent = GUI

    local camObj = workspace.CurrentCamera
    local vp = camObj and camObj.ViewportSize or Vector2.new(1280, 720)
    local h = math.floor(vp.Y * 0.78)

    local popup = Instance.new("Frame")
    popup.Size = UDim2.new(0, 320, 0, h)
    popup.Position = UDim2.new(0.5, -160, 0.5, -h / 2)
    popup.BackgroundColor3 = T.panel
    popup.BorderSizePixel = 0
    popup.ZIndex = 500
    popup.Parent = GUI
    corner(popup, 12)
    stroke(popup, T.accent, 1)

    local ttl = Instance.new("TextLabel")
    ttl.Size = UDim2.new(1, -100, 0, 34)
    ttl.Position = UDim2.new(0, 10, 0, 4)
    ttl.BackgroundTransparency = 1
    ttl.Text = "选择武器"
    ttl.TextColor3 = T.gold
    ttl.TextXAlignment = Enum.TextXAlignment.Left
    ttl.Font = Enum.Font.GothamBold
    ttl.TextSize = 13
    ttl.ZIndex = 501
    ttl.Parent = popup

    local backBtn = Instance.new("TextButton")
    backBtn.Size = UDim2.new(0, 60, 0, 28)
    backBtn.Position = UDim2.new(1, -70, 0, 7)
    backBtn.BackgroundColor3 = T.cardHi
    backBtn.Text = "← 返回"
    backBtn.TextColor3 = T.text
    backBtn.Font = Enum.Font.GothamMedium
    backBtn.TextSize = 10
    backBtn.AutoButtonColor = false
    backBtn.BorderSizePixel = 0
    backBtn.ZIndex = 502
    backBtn.Visible = false
    backBtn.Parent = popup
    corner(backBtn, 6)

    local sf = Instance.new("ScrollingFrame")
    sf.Size = UDim2.new(1, -8, 1, -44)
    sf.Position = UDim2.new(0, 4, 0, 40)
    sf.BackgroundTransparency = 1
    sf.BorderSizePixel = 0
    sf.CanvasSize = UDim2.new(0, 0, 0, 0)
    sf.ScrollingDirection = Enum.ScrollingDirection.Y
    sf.ScrollBarThickness = 4
    sf.ScrollBarImageColor3 = T.accent
    sf.ScrollBarImageTransparency = 0.2
    sf.ZIndex = 501
    sf.Parent = popup

    local lay = Instance.new("UIListLayout")
    lay.Padding = UDim.new(0, 3)
    lay.Parent = sf

    local function closeAll()
        pcall(function() bg:Destroy() end)
        pcall(function() popup:Destroy() end)
    end
    bg.MouseButton1Click:Connect(closeAll)

    local function clearList()
        for _, c in ipairs(sf:GetChildren()) do
            if c:IsA("TextButton") or c:IsA("TextLabel") or c:IsA("Frame") then
                c:Destroy()
            end
        end
    end

    local function mkRow(text, color, onClick, isHeader)
        local rb = Instance.new("TextButton")
        rb.Size = UDim2.new(1, -4, 0, isHeader and 26 or 32)
        rb.BackgroundColor3 = isHeader and T.card or T.card
        rb.Text = text
        rb.TextColor3 = isHeader and T.gold or color or T.text
        rb.TextXAlignment = Enum.TextXAlignment.Left
        rb.Font = isHeader and Enum.Font.GothamBold or Enum.Font.GothamMedium
        rb.TextSize = isHeader and 11 or 11
        rb.AutoButtonColor = false
        rb.BorderSizePixel = 0
        rb.ZIndex = 502
        rb.Parent = sf
        corner(rb, 6)
        local pad = Instance.new("UIPadding")
        pad.PaddingLeft = UDim.new(0, 10)
        pad.Parent = rb
        if onClick then
            rb.MouseButton1Click:Connect(onClick)
        else
            rb.AutoButtonColor = false
        end
        return rb
    end

    local showItems

    local function showCats()
        clearList()
        ttl.Text = "选择武器 · 分类"
        backBtn.Visible = false
        local y = 0
        for _, c in ipairs(cats) do
            local label = c.label .. "  (" .. #c.items .. ")"
            mkRow(label, T.accent2, function()
                showItems(c)
            end)
            y = y + 35
        end
        sf.CanvasSize = UDim2.new(0, 0, 0, y + 10)
    end

    showItems = function(c)
        clearList()
        ttl.Text = c.label
        backBtn.Visible = true
        local y = 0
        for _, name in ipairs(c.items) do
            local hasCfg = CFG.SkinMap[name] ~= nil
            local prefix = hasCfg and "● " or "  "
            local col = hasCfg and T.accent or T.text
            mkRow(prefix .. name, col, function()
                closeAll()
                onPick(name)
            end)
            y = y + 35
        end
        sf.CanvasSize = UDim2.new(0, 0, 0, y + 10)
        sf.CanvasPosition = Vector2.new(0, 0)
    end

    backBtn.MouseButton1Click:Connect(showCats)
    showCats()

    local dragStart, dragCanvas
    sf.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.Touch then
            dragStart = inp.Position.Y
            dragCanvas = sf.CanvasPosition.Y
        end
    end)
    sf.InputChanged:Connect(function(inp)
        if dragStart and inp.UserInputType == Enum.UserInputType.Touch then
            local dy = dragStart - inp.Position.Y
            sf.CanvasPosition = Vector2.new(0, math.max(0, dragCanvas + dy))
        end
    end)
    sf.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.Touch then
            dragStart = nil
        end
    end)
end

local function popupPick(title, list, onPick)
    local rowH = 32

    local bg = Instance.new("TextButton")
    bg.Size = UDim2.new(1, 0, 1, 0)
    bg.BackgroundColor3 = Color3.new(0, 0, 0)
    bg.BackgroundTransparency = 0.5
    bg.Text = ""
    bg.AutoButtonColor = false
    bg.ZIndex = 400
    bg.Parent = GUI

    local camObj = workspace.CurrentCamera
    local vp = camObj and camObj.ViewportSize or Vector2.new(1280, 720)
    local h = math.floor(vp.Y * 0.75)

    local popup = Instance.new("Frame")
    popup.Size = UDim2.new(0, 310, 0, h)
    popup.Position = UDim2.new(0.5, -155, 0.5, -h / 2)
    popup.BackgroundColor3 = T.panel
    popup.BorderSizePixel = 0
    popup.ZIndex = 500
    popup.Parent = GUI
    corner(popup, 12)
    stroke(popup, T.accent, 1)

    local ttl = Instance.new("TextLabel")
    ttl.Size = UDim2.new(1, -20, 0, 34)
    ttl.Position = UDim2.new(0, 10, 0, 4)
    ttl.BackgroundTransparency = 1
    ttl.Text = title .. "  (" .. #list .. ")"
    ttl.TextColor3 = T.gold
    ttl.TextXAlignment = Enum.TextXAlignment.Left
    ttl.Font = Enum.Font.GothamBold
    ttl.TextSize = 13
    ttl.ZIndex = 501
    ttl.Parent = popup

    local sf = Instance.new("ScrollingFrame")
    sf.Size = UDim2.new(1, -8, 1, -44)
    sf.Position = UDim2.new(0, 4, 0, 40)
    sf.BackgroundTransparency = 1
    sf.BorderSizePixel = 0
    sf.CanvasSize = UDim2.new(0, 0, 0, #list * (rowH + 2) + 4)
    sf.ScrollingDirection = Enum.ScrollingDirection.Y
    sf.ScrollBarThickness = 4
    sf.ScrollBarImageColor3 = T.accent
    sf.ScrollBarImageTransparency = 0.2
    sf.ZIndex = 501
    sf.Parent = popup

    local lay2 = Instance.new("UIListLayout")
    lay2.Padding = UDim.new(0, 2)
    lay2.Parent = sf

    local function closeAll()
        pcall(function() bg:Destroy() end)
        pcall(function() popup:Destroy() end)
    end

    bg.MouseButton1Click:Connect(closeAll)

    for _, name in ipairs(list) do
        local rb = Instance.new("TextButton")
        rb.Size = UDim2.new(1, -4, 0, rowH)
        rb.BackgroundColor3 = T.card
        rb.Text = tostring(name)
        rb.TextColor3 = T.text
        rb.TextXAlignment = Enum.TextXAlignment.Left
        rb.Font = Enum.Font.GothamMedium
        rb.TextSize = 11
        rb.AutoButtonColor = false
        rb.BorderSizePixel = 0
        rb.ZIndex = 502
        rb.Parent = sf
        corner(rb, 6)
        local pad = Instance.new("UIPadding")
        pad.PaddingLeft = UDim.new(0, 10)
        pad.Parent = rb

        rb.MouseButton1Click:Connect(function()
            closeAll()
            onPick(name)
        end)
    end

    local dragStart, dragCanvas
    sf.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.Touch then
            dragStart = inp.Position.Y
            dragCanvas = sf.CanvasPosition.Y
        end
    end)
    sf.InputChanged:Connect(function(inp)
        if dragStart and (inp.UserInputType == Enum.UserInputType.Touch) then
            local dy = dragStart - inp.Position.Y
            sf.CanvasPosition = Vector2.new(0, math.max(0, dragCanvas + dy))
        end
    end)
    sf.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.Touch then
            dragStart = nil
        end
    end)
end

local toastList = {}

function ROOT.notify(msg)
    msg = tostring(msg)

    local f = Instance.new("Frame")
    f.Size = UDim2.new(0, 280, 0, 38)
    f.Position = UDim2.new(0.5, -140, 1, -70 - #toastList * 44)
    f.BackgroundColor3 = T.panel
    f.BorderSizePixel = 0
    f.ZIndex = 600
    f.Parent = GUI
    corner(f, 9)
    stroke(f, T.accent, 1)

    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, -20, 1, 0)
    l.Position = UDim2.new(0, 10, 0, 0)
    l.BackgroundTransparency = 1
    l.Text = msg
    l.TextColor3 = T.text
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Font = Enum.Font.GothamMedium
    l.TextSize = 11
    l.ZIndex = 601
    l.Parent = f

    toastList[#toastList + 1] = f

    task.delay(2.6, function()
        pcall(function()
            Tween:Create(f, TweenInfo.new(0.25), { BackgroundTransparency = 1 }):Play()
            Tween:Create(l, TweenInfo.new(0.25), { TextTransparency = 1 }):Play()
        end)
        task.wait(0.3)
        pcall(function() f:Destroy() end)
        for i, t in ipairs(toastList) do
            if t == f then table.remove(toastList, i) break end
        end
    end)
end

do
    local p = pages[1]

    mkToggle(p, "美化总开关", "关闭恢复默认",
        function() return CFG.SkinOn end,
        function(v)
            CFG.SkinOn = v
            if not v then ROOT.restoreAllSkins() end
        end)

    local editCard = mkCard(p, 72)
    local editLbl = Instance.new("TextLabel")
    editLbl.Size = UDim2.new(1, -30, 0, 18)
    editLbl.Position = UDim2.new(0, 14, 0, 6)
    editLbl.BackgroundTransparency = 1
    editLbl.Text = "正在配置"
    editLbl.TextColor3 = T.sub
    editLbl.TextXAlignment = Enum.TextXAlignment.Left
    editLbl.Font = Enum.Font.Gotham
    editLbl.TextSize = 10
    editLbl.Parent = editCard

    local editVal = Instance.new("TextLabel")
    editVal.Size = UDim2.new(1, -30, 0, 22)
    editVal.Position = UDim2.new(0, 14, 0, 22)
    editVal.BackgroundTransparency = 1
    editVal.Text = CFG.EditGun
    editVal.TextColor3 = T.gold
    editVal.TextXAlignment = Enum.TextXAlignment.Left
    editVal.Font = Enum.Font.GothamBold
    editVal.TextSize = 15
    editVal.Parent = editCard

    local pickBtn = Instance.new("TextButton")
    pickBtn.Size = UDim2.new(1, -28, 0, 26)
    pickBtn.Position = UDim2.new(0, 14, 0, 44)
    pickBtn.BackgroundColor3 = T.cardHi
    pickBtn.Text = "换一把枪 ▾"
    pickBtn.TextColor3 = T.text
    pickBtn.Font = Enum.Font.GothamMedium
    pickBtn.TextSize = 11
    pickBtn.AutoButtonColor = false
    pickBtn.BorderSizePixel = 0
    pickBtn.Parent = editCard
    corner(pickBtn, 6)

    local stateLbl = mkInfo(p, "未配置", T.sub)

    local skinBtn = mkButton(p, "选择皮肤 ▾", function()
        local list = ROOT.getSkins(CFG.EditGun)
        if #list == 0 then return "这把枪没皮肤" end
        popupPick(CFG.EditGun .. " 的皮肤", list, function(name)
            CFG.SkinMap[CFG.EditGun] = CFG.SkinMap[CFG.EditGun] or {}
            CFG.SkinMap[CFG.EditGun].skin = name
            CFG.SkinMap[CFG.EditGun].wear = CFG.SkinMap[CFG.EditGun].wear or 1
            countCfg()
            ROOT.applyAllSkins()
            stateLbl.Text = string.format("%s → %s (已配置 %d 把)",
                CFG.EditGun, name, STAT.cfgCount)
            ROOT.notify("已设置 " .. CFG.EditGun .. " → " .. name)
        end)
        return nil
    end, T.accent2)

    local wearSlider = mkSlider(p, "磨损", 1, 5, 1,
        function()
            local conf = CFG.SkinMap[CFG.EditGun]
            return conf and conf.wear or 1
        end,
        function(v)
            if CFG.SkinMap[CFG.EditGun] then
                CFG.SkinMap[CFG.EditGun].wear = v
                ROOT.applyAllSkins()
            end
        end,
        function(v)
            return ({ "崭新", "略磨", "久经", "破损", "战痕" })[v] or tostring(v)
        end)

    pickBtn.MouseButton1Click:Connect(function()
        popupPickGun(function(name)
            CFG.EditGun = name
            editVal.Text = name
            local conf = CFG.SkinMap[name]
            if conf then
                stateLbl.Text = string.format("已配置: %s · 磨损%d", conf.skin, conf.wear or 1)
            else
                stateLbl.Text = "未配置"
            end
            wearSlider()
        end)
    end)

    mkButton(p, "清空这把枪的配置", function()
        ROOT.clearGunSkin(CFG.EditGun)
        stateLbl.Text = "未配置"
        ROOT.applyAllSkins()
        return "已清空 " .. CFG.EditGun
    end, T.danger)

    mkInfo(p, "自动", T.line)

    mkButton(p, "全皮美化", function()
        ROOT.clearCaches()
        local gunN = ROOT.randomAll()
        local gloveN = math.random(1, 15)
        local gloveSets = {
            "Bumblebee", "Gridline", "Apex", "Cobra", "Hunter",
            "Dazzle", "Sakura", "Fade", "Aztec", "Comic",
            "Whiteout", "Blackout", "Tidal", "Leopard", "Snow Leopard",
        }
        CFG.GloveName = gloveSets[gloveN] or "Bumblebee"
        CFG.GloveOn = true
        CFG.SkinOn = true
        ROOT.applyAllSkins()
        return string.format("美化成功", gunN, CFG.GloveName)
    end, T.purple)

    mkToggle(p, "手套美化", "手套",
        function() return CFG.GloveOn end,
        function(v)
            CFG.GloveOn = v
            if not v then ROOT.applyAllSkins() end
        end)

    mkButton(p, "清空全部配置", function()
        CFG.SkinMap = {}
        countCfg()
        ROOT.restoreAllSkins()
        stateLbl.Text = "未配置"
        return "已清空全部"
    end, T.danger)

    mkInfo(p, "配置后切枪刷新")
    mkInfo(p, "")
end

do
    local p = pages[2]

    mkToggle(p, "高亮模型", "",
        function() return CFG.ESP end,
        function(v) CFG.ESP = v end)

    mkToggle(p, "名字", "",
        function() return CFG.ShowName end,
        function(v) CFG.ShowName = v end)

    mkToggle(p, "血量", "",
        function() return CFG.ShowHP end,
        function(v) CFG.ShowHP = v end)

    mkToggle(p, "距离", "",
        function() return CFG.ShowDist end,
        function(v) CFG.ShowDist = v end)

    mkToggle(p, "显示队友", "",
        function() return CFG.ShowTeam end,
        function(v) CFG.ShowTeam = v end)

    mkSlider(p, "最大距离", 100, 5000, 100,
        function() return CFG.MaxDist end,
        function(v) CFG.MaxDist = v end,
        function(v) return v .. "m" end)

    mkButton(p, "关闭并清理", function()
        CFG.ESP = false
        for ch in pairs(ESP.tag) do erase(ch) end
        return "已清理"
    end, T.danger)
end

do
    local p = pages[3]

    mkToggle(p, "全枪无后座", "Recoil.Scale 归零",
        function() return CFG.NoRecoil end,
        function(v)
            CFG.NoRecoil = v
            ROOT.rebuildWeapons()
            ROOT.notify(string.format("后座 %s · %d 把",
                v and "开" or "关", STAT.recoil))
        end)

    mkToggle(p, "全枪无散布", "Spread + Range 归零",
        function() return CFG.NoSpread end,
        function(v)
            CFG.NoSpread = v
            ROOT.rebuildWeapons()
            ROOT.notify(string.format("散布 %s · %d+%d",
                v and "开" or "关", STAT.spread, STAT.ranges))
        end)

    mkButton(p, "重新应用", function()
        ROOT.rebuildWeapons()
        return string.format("%d 后座 · %d 散布 · %d 范围",
            STAT.recoil, STAT.spread, STAT.ranges)
    end)

    mkButton(p, "还原", function()
        ROOT.restoreWeapons()
        return "已还原"
    end, T.danger)

    mkInfo(p, "星")
    mkInfo(p, "神")
end

do
    local p = pages[4]

    mkSlider(p, "自瞄", 0, 5, 1,
        function() return CFG.AssistLv end,
        function(v)
            CFG.AssistLv = v
            local ok = ROOT.applyAssist(v)
            local nm = ({ "关闭", "轻", "中", "强", "超强", "强强强" })[v + 1] or "?"
            ROOT.notify(ok and ("辅助瞄准: " .. nm) or "未找到配置")
        end,
        function(v)
            return ({ "关闭", "轻", "中", "强", "超强", "强强强" })[v + 1] or "?"
        end)

    mkInfo(p, "绵羊")
    mkInfo(p, "光头强")
    mkInfo(p, "超人强")

    mkButton(p, "还原自瞄", function()
        CFG.AssistLv = 0
        ROOT.applyAssist(0)
        return "已还原"
    end, T.danger)
end

showPage(1)

local STATUS = Instance.new("Frame")
STATUS.Size = UDim2.new(1, -24, 0, 34)
STATUS.Position = UDim2.new(0, 12, 1, -46)
STATUS.BackgroundColor3 = T.panel
STATUS.BorderSizePixel = 0
STATUS.Parent = PANEL
corner(STATUS, 9)

local STATLBL = Instance.new("TextLabel")
STATLBL.Size = UDim2.new(1, -16, 1, 0)
STATLBL.Position = UDim2.new(0, 10, 0, 0)
STATLBL.BackgroundTransparency = 1
STATLBL.Text = "就绪"
STATLBL.TextColor3 = T.sub
STATLBL.TextXAlignment = Enum.TextXAlignment.Left
STATLBL.Font = Enum.Font.GothamMedium
STATLBL.TextSize = 9
STATLBL.Parent = STATUS

local function makeDraggable(handle, target)
    local dragging = false
    local startPos, startInput

    handle.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.Touch
           or i.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            startInput = i.Position
            startPos = target.Position
            i.Changed:Connect(function()
                if i.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    UIS.InputChanged:Connect(function(i)
        if not dragging then return end
        if i.UserInputType == Enum.UserInputType.Touch
           or i.UserInputType == Enum.UserInputType.MouseMovement then
            local d = i.Position - startInput
            local camObj = workspace.CurrentCamera
            local vp = camObj and camObj.ViewportSize or Vector2.new(1280, 720)
            local nx = math.clamp(startPos.X.Offset + d.X, 0, vp.X - target.AbsoluteSize.X)
            local ny = math.clamp(startPos.Y.Offset + d.Y, 0, vp.Y - target.AbsoluteSize.Y)
            target.Position = UDim2.new(0, nx, 0, ny)
        end
    end)
end

makeDraggable(HEADER, PANEL)
makeDraggable(BALL, BALL)

MINBTN.MouseButton1Click:Connect(function()
    PANEL.Visible = false
    BALL.Visible = true
end)

BALL.MouseButton1Click:Connect(function()
    PANEL.Visible = true
    BALL.Visible = false
end)

local closed = false
CLOSEBTN.MouseButton1Click:Connect(function()
    if closed then return end
    closed = true
    if ROOT.destroy then ROOT.destroy() end
end)

local frames, fpsT = 0, os.clock()
local skinTick = 0

table.insert(ROOT.conns, RunService.RenderStepped:Connect(function()
    pcall(espFrame)

    skinTick = skinTick + 1
    if skinTick >= 15 then
        skinTick = 0
        pcall(ROOT.applyAllSkins)
    end

    frames = frames + 1
    local now = os.clock()
    if now - fpsT >= 1 then
        STAT.fps = math.floor(frames / (now - fpsT))
        frames = 0
        fpsT = now
        STATLBL.Text = string.format(
            "显示%d FPS%d · 后座%d 散布%d · 皮配置%d把 套中%d",
            STAT.drawn, STAT.fps, STAT.recoil, STAT.spread,
            STAT.cfgCount, STAT.skinHit)
    end
end))

ROOT.destroy = function()
    for _, c in ipairs(ROOT.conns) do
        pcall(function() c:Disconnect() end)
    end
    ROOT.conns = {}

    pcall(function() ROOT.restoreAllSkins() end)
    pcall(function() ROOT.applyAssist(0) end)
    pcall(function() ROOT.restoreWeapons() end)

    for ch in pairs(ESP.tag) do erase(ch) end
    ESP.tag = {}

    pcall(function() GUI:Destroy() end)
    _G.XS = nil
    _G.__XS_ROOT = nil
end

task.spawn(function()
    assistCfg = findAssist()
    STAT.assist = assistCfg ~= nil

    ROOT.rebuildWeapons()
    countCfg()

    if assistCfg and CFG.AssistLv > 0 then
        ROOT.applyAssist(CFG.AssistLv)
    end

    task.wait(0.3)
    if ROOT.notify then
        ROOT.notify(string.format("已加载 · 后座%d 散布%d · %d 把枪可换皮",
            STAT.recoil, STAT.spread, #ROOT.getAllGuns()))
    end
end)

return string.format(
    '{"ok":true,"place":%d,"recoil":%d,"spread":%d,"ranges":%d,"assist":%s,"guns":%d}',
    game.PlaceId, STAT.recoil, STAT.spread, STAT.ranges,
    tostring(STAT.assist), #ROOT.getAllGuns()
)
