--[[
    自动攻击 - 锁定目标 + 强制无敌版
    作者：星神
--]]

local function safeLoad(url)
    local success, result = pcall(function()
        return loadstring(game:HttpGet(url))()
    end)
    if not success then
        warn("加载失败: " .. url)
        return nil
    end
    return result
end

local Library = safeLoad("https://raw.githubusercontent.com/kongbaNB/ui/refs/heads/main/黑曜石主库.ui")
local ThemeManager = safeLoad("https://raw.githubusercontent.com/kongbaNB/ui/refs/heads/main/主题管理.ui")
local SaveManager = safeLoad("https://raw.githubusercontent.com/kongbaNB/ui/refs/heads/main/配置管理.ui")

if not Library then
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "错误", Text = "UI 库加载失败", Duration = 5,
    })
    return
end

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

local RequestAttack = ReplicatedStorage
    :WaitForChild("Packages")
    :WaitForChild("Knit")
    :WaitForChild("Services")
    :WaitForChild("MonsterService")
    :WaitForChild("RF")
    :WaitForChild("RequestAttack")

--// ==================== UI ====================
local Window = Library:CreateWindow({
    Title = "自动攻击",
    Footer = "星神 制作",
    Icon = 131153193945220,
    NotifySide = "Right",
    ShowCustomCursor = true,
})

Library:Notify({ Title = "自动攻击", Description = "锁定目标版已加载", Time = 5 })

local Tabs = {
    Main = Window:AddTab("主要", "sword"),
    GodMode = Window:AddTab("无敌", "shield"),
    Settings = Window:AddTab("设置", "settings"),
}

if ThemeManager then
    ThemeManager:SetLibrary(Library)
    ThemeManager:SetFolder("AutoAttackTheme")
    ThemeManager:ApplyToTab(Tabs.Settings)
end

if SaveManager then
    SaveManager:SetLibrary(Library)
    SaveManager:SetFolder("AutoAttackConfig")
    SaveManager:BuildConfigSection(Tabs.Settings)
end

--// ==================== 配置 ====================
local Settings = {
    Enabled = false,
    MaxDistance = 5000,
    Interval = 0.01,
    GodMode = false,
    ShowDebug = false,
}

local State = {
    Total = 0,
    Target = "无",
    Conn = nil,
    GodConn = nil,
}

--// ==================== 实时获取（不缓存） ====================
local function GetCharacter()
    return player.Character
end

local function GetRootPart()
    local char = GetCharacter()
    if not char then return nil end
    return char:FindFirstChild("HumanoidRootPart")
end

local function GetHumanoid()
    local char = GetCharacter()
    if not char then return nil end
    return char:FindFirstChildOfClass("Humanoid")
end

--// ==================== 扫描怪物 ====================
local function GetMonsters()
    local root = GetRootPart()
    if not root then return {} end
    local pos = root.Position

    local list = {}
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and obj ~= GetCharacter() and not Players:GetPlayerFromCharacter(obj) then
            local hum = obj:FindFirstChildOfClass("Humanoid")
            local part = obj:FindFirstChild("HumanoidRootPart")
            if hum and part and hum.Health > 0 then
                local d = (part.Position - pos).Magnitude
                if d <= Settings.MaxDistance then
                    table.insert(list, { Model = obj, Part = part, Name = obj.Name, Dist = d })
                end
            end
        end
    end
    table.sort(list, function(a, b) return a.Dist < b.Dist end)
    return list
end

--// ==================== 攻击逻辑（锁定最近目标） ====================
local CurrentTarget = nil

local function AttackOnce()
    if not Settings.Enabled then return end
    
    local root = GetRootPart()
    if not root then return end
    
    -- 检查当前锁定目标是否仍然有效
    if CurrentTarget then
        local model = CurrentTarget.Model
        if model and model.Parent then
            local hum = model:FindFirstChildOfClass("Humanoid")
            local part = model:FindFirstChild("HumanoidRootPart")
            if hum and hum.Health > 0 and part then
                local dist = (part.Position - root.Position).Magnitude
                if dist <= Settings.MaxDistance then
                    -- 仍然有效，继续攻击这个目标
                    pcall(function()
                        RequestAttack:InvokeServer(part.CFrame)
                    end)
                    State.Total = State.Total + 1
                    State.Target = CurrentTarget.Name .. " (" .. string.format("%.1f", dist) .. ")"
                    return
                end
            end
        end
        -- 无效了，清空
        CurrentTarget = nil
    end
    
    -- 找新的最近目标
    local mobs = GetMonsters()
    if #mobs > 0 then
        CurrentTarget = mobs[1]
        pcall(function()
            RequestAttack:InvokeServer(CurrentTarget.Part.CFrame)
        end)
        State.Total = State.Total + 1
        State.Target = CurrentTarget.Name .. " (" .. string.format("%.1f", CurrentTarget.Dist) .. ")"
    else
        State.Target = "无"
    end
end

--// ==================== 无敌模式（强制满血） ====================
local function SetupGodMode()
    -- 1. Hook TakeDamage（如果支持）
    local function HookTD(hum)
        if not hum then return end
        local old = hum.TakeDamage
        if old and typeof(old) == "function" then
            hum.TakeDamage = function(self, amt, ...)
                if Settings.GodMode then
                    if Settings.ShowDebug then
                        Library:Notify("拦截伤害: " .. tostring(amt), 1)
                    end
                    return 0
                end
                return old(self, amt, ...)
            end
        end
    end
    
    -- 2. 心跳强制满血（最可靠，不依赖 Hook）
    if State.GodConn then State.GodConn:Disconnect() end
    State.GodConn = RunService.Heartbeat:Connect(function()
        if not Settings.GodMode then return end
        local hum = GetHumanoid()
        if hum and hum.MaxHealth and hum.MaxHealth > 0 then
            if hum.Health < hum.MaxHealth then
                hum.Health = hum.MaxHealth
            end
        end
    end)
    
    -- 初始 Hook
    local hum = GetHumanoid()
    if hum then HookTD(hum) end
    
    -- 重生 Hook
    player.CharacterAdded:Connect(function(c)
        task.wait(0.5)
        local nh = c:FindFirstChildOfClass("Humanoid")
        if nh then HookTD(nh) end
    end)
end

--// ==================== UI 组件 ====================

local AttackGroup = Tabs.Main:AddLeftGroupbox("攻击控制")

AttackGroup:AddToggle("AutoAttack", {
    Text = "自动攻击",
    Default = false,
    Tooltip = "锁定最近目标持续攻击，死了自动切下一个",
}):OnChanged(function(v)
    Settings.Enabled = v
    if v then
        State.Conn = RunService.Heartbeat:Connect(AttackOnce)
        Library:Notify("自动攻击已开启 | 锁定最近目标", 3)
    else
        if State.Conn then State.Conn:Disconnect() State.Conn = nil end
        CurrentTarget = nil
        State.Target = "无"
        Library:Notify("自动攻击已关闭", 3)
    end
end)

AttackGroup:AddSlider("RangeSlider", {
    Text = "攻击范围",
    Default = 5000,
    Min = 100,
    Max = 10000,
    Rounding = 0,
    Suffix = " studs",
}):OnChanged(function(v)
    Settings.MaxDistance = v
end)

AttackGroup:AddSlider("IntervalSlider", {
    Text = "攻击间隔",
    Default = 0.01,
    Min = 0.01,
    Max = 1,
    Rounding = 2,
    Suffix = "s",
}):OnChanged(function(v)
    Settings.Interval = v
end)

AttackGroup:AddButton("手动攻击最近", function()
    CurrentTarget = nil
    AttackOnce()
    Library:Notify("已攻击: " .. State.Target, 2)
end)

AttackGroup:AddButton("切换目标", function()
    CurrentTarget = nil
    AttackOnce()
    Library:Notify("已切换至: " .. State.Target, 2)
end)

-- 状态
local StatusGroup = Tabs.Main:AddRightGroupbox("状态")

local TargetLabel = StatusGroup:AddLabel("当前目标: 无")
local CountLabel = StatusGroup:AddLabel("攻击次数: 0")
local MonsterCountLabel = StatusGroup:AddLabel("周围怪物: 0")

task.spawn(function()
    while true do
        task.wait(0.3)
        local mobs = GetMonsters()
        MonsterCountLabel:SetText("周围怪物: " .. #mobs)
        TargetLabel:SetText("当前目标: " .. State.Target)
        CountLabel:SetText("攻击次数: " .. State.Total)
    end
end)

-- 无敌标签
local GodGroup = Tabs.GodMode:AddLeftGroupbox("怪物无敌")

GodGroup:AddToggle("GodModeToggle", {
    Text = "怪物攻击无伤害",
    Default = false,
    Tooltip = "每帧强制满血，不依赖 Hook",
}):OnChanged(function(v)
    Settings.GodMode = v
    Library:Notify(v and "无敌已开启（强制满血）" or "无敌已关闭", 3)
end)

GodGroup:AddLabel("原理：Heartbeat 每帧强制 Health = MaxHealth")
GodGroup:AddLabel("不依赖 metatable Hook，最稳定")

GodGroup:AddButton("测试无敌", function()
    local hum = GetHumanoid()
    if hum then
        local before = hum.Health
        hum:TakeDamage(999)
        task.wait(0.2)
        local after = hum.Health
        Library:Notify(string.format("血量: %.1f -> %.1f %s", before, after, after >= before and "✓有效" or "✗失效"), 3)
    else
        Library:Notify("未找到 Humanoid", 3)
    end
end)

-- 设置标签
local MiscGroup = Tabs.Settings:AddLeftGroupbox("其他设置")

MiscGroup:AddToggle("ShowDebug", {
    Text = "显示调试信息",
    Default = false,
}):OnChanged(function(v)
    Settings.ShowDebug = v
end)

MiscGroup:AddButton("重置攻击计数", function()
    State.Total = 0
    Library:Notify("已重置", 2)
end)

--// ==================== 重生处理 ====================
player.CharacterAdded:Connect(function(c)
    task.wait(1)
    if Settings.Enabled then
        if State.Conn then State.Conn:Disconnect() end
        CurrentTarget = nil
        State.Conn = RunService.Heartbeat:Connect(function()
            task.wait(Settings.Interval)
            AttackOnce()
        end)
    end
end)

player.CharacterRemoving:Connect(function()
    if State.Conn then
        State.Conn:Disconnect()
        State.Conn = nil
    end
    CurrentTarget = nil
end)

--// ==================== 初始化 ====================
SetupGodMode()

Library:Notify("脚本已就绪", 5)
Library:Notify("锁定最近目标，死亡自动切换", 5)
Library:Notify("无敌采用强制满血，稳定可靠", 5)
