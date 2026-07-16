--[[
    怪物自动攻击脚本 - 最终修复版
    修复：实时扫描 + 死亡自动跳过 + 复活自动切换 + 多文件夹优先扫描
    注意：RequestAttack 只有 CFrame 参数，无法修改伤害数值
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
local character = player.Character or player.CharacterAdded:Wait()

local RequestAttack = ReplicatedStorage
    :WaitForChild("Packages")
    :WaitForChild("Knit")
    :WaitForChild("Services")
    :WaitForChild("MonsterService")
    :WaitForChild("RF")
    :WaitForChild("RequestAttack")

--// ==================== UI ====================
local Window = Library:CreateWindow({
    Title = "自动攻击 - 修复版",
    Footer = "星神",
    Icon = 131153193945220,
    NotifySide = "Right",
    ShowCustomCursor = true,
})

Library:Notify({ Title = "自动攻击", Description = "修复版已加载\n解决目标锁定问题", Time = 5 })

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
    AttackInterval = 0.01,
    MonsterFilter = "",
    GodMode = false,
    ShowDebug = true,
}

local State = {
    TotalAttacks = 0,
    CurrentTargetName = "无",
    Connection = nil,
}

--// ==================== 核心：实时怪物检测（不缓存任何属性） ====================

local function GetRootPart()
    if not character then return nil end
    return character:FindFirstChild("HumanoidRootPart")
end

local function GetLiveMonsters()
    local rootPart = GetRootPart()
    if not rootPart then return {} end
    local playerPos = rootPart.Position

    -- 优先扫描常见怪物文件夹（比全 Workspace 快且准）
    local allModels = {}
    local folderNames = { "Mobs", "Enemies", "Monsters", "NPCs", "Creatures", "Entities", "Hostiles", "SpawnedMobs", "MonsterSpawns", "MobFolder" }
    
    for _, name in ipairs(folderNames) do
        local f = Workspace:FindFirstChild(name)
        if f then
            for _, child in pairs(f:GetChildren()) do
                if child:IsA("Model") and child ~= character and not Players:GetPlayerFromCharacter(child) then
                    table.insert(allModels, child)
                end
            end
        end
    end

    -- 如果没找到专用文件夹， fallback 扫描 Workspace
    if #allModels == 0 then
        for _, obj in pairs(Workspace:GetDescendants()) do
            if obj:IsA("Model") and obj ~= character and not Players:GetPlayerFromCharacter(obj) then
                table.insert(allModels, obj)
            end
        end
    end

    local valid = {}
    for _, model in ipairs(allModels) do
        -- 关键：每次都要重新查找 Humanoid 和 RootPart，绝不缓存
        if not model.Parent then continue end

        local hum = model:FindFirstChildOfClass("Humanoid")
        local mobRoot = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("Torso") or model:FindFirstChild("UpperTorso")

        -- 必须活着（Health > 0），且根部件存在
        if hum and hum.Health > 0 and mobRoot and mobRoot.Parent then
            if Settings.MonsterFilter == "" or model.Name:lower():find(Settings.MonsterFilter:lower()) then
                local dist = (mobRoot.Position - playerPos).Magnitude
                if dist <= Settings.MaxDistance then
                    table.insert(valid, {
                        Model = model,      -- 只存模型引用，不存任何属性
                        Name = model.Name,
                        Distance = dist,
                    })
                end
            end
        end
    end

    table.sort(valid, function(a, b) return a.Distance < b.Distance end)
    return valid
end

--// ==================== 攻击逻辑（实时读坐标，绝不缓存） ====================

local function AttackMonster(model)
    -- 再次检查模型是否还存在
    if not model or not model.Parent then return false, "模型已销毁" end

    -- 实时重新查找部件（防止怪物复活后部件换新）
    local root = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("Torso") or model:FindFirstChild("UpperTorso")
    local hum = model:FindFirstChildOfClass("Humanoid")

    if not root then return false, "找不到根部件" end
    if not hum then return false, "找不到 Humanoid" end
    if hum.Health <= 0 then return false, "目标已死亡" end

    -- 实时坐标！不是缓存的
    local cf = root.CFrame

    local success, result = pcall(function()
        return RequestAttack:InvokeServer(cf)
    end)

    if success then
        State.TotalAttacks = State.TotalAttacks + 1
        State.CurrentTargetName = model.Name
        return true, result
    else
        return false, tostring(result)
    end
end

-- 主循环：每次重新扫描全部怪物，实时攻击
local function AttackLoop()
    if not Settings.Enabled then return end

    local monsters = GetLiveMonsters()
    if #monsters == 0 then
        State.CurrentTargetName = "无"
        return
    end

    -- 遍历所有活着的怪，每个都实时读取坐标
    for _, entry in ipairs(monsters) do
        if not Settings.Enabled then break end

        -- 攻击前再查一次血量（防止循环过程中怪死了）
        local hum = entry.Model:FindFirstChildOfClass("Humanoid")
        if hum and hum.Health > 0 then
            local ok, err = AttackMonster(entry.Model)
            if not ok and Settings.ShowDebug then
                -- Library:Notify("跳过: " .. err, 1)
            end
        end

        if Settings.AttackInterval > 0 then
            task.wait(Settings.AttackInterval)
        end
    end
end

--// ==================== 无敌模式 ====================

local function SetupGodMode()
    local function HookHumanoid(hum)
        if not hum or hum:GetAttribute("PenetrateHooked") then return end
        hum:SetAttribute("PenetrateHooked", true)

        local oldTakeDamage = hum.TakeDamage
        hum.TakeDamage = function(self, amount, ...)
            if Settings.GodMode then
                if Settings.ShowDebug then
                    Library:Notify("拦截伤害: " .. tostring(amount), 1)
                end
                return 0
            end
            return oldTakeDamage(self, amount, ...)
        end

        local mt = getrawmetatable(hum)
        if mt and mt.__newindex then
            local oldNewIndex = mt.__newindex
            make_writeable(mt)
            mt.__newindex = function(t, k, v)
                if k == "Health" and typeof(v) == "number" and Settings.GodMode then
                    local current = hum.Health
                    if v < current then
                        return oldNewIndex(t, k, current)
                    end
                end
                return oldNewIndex(t, k, v)
            end
            make_readonly(mt)
        end
    end

    local hum = character:FindFirstChildOfClass("Humanoid")
    if hum then HookHumanoid(hum) end

    player.CharacterAdded:Connect(function(newChar)
        character = newChar
        task.wait(0.5)
        local newHum = newChar:FindFirstChildOfClass("Humanoid")
        if newHum then HookHumanoid(newHum) end
    end)
end

--// ==================== UI 组件 ====================

local AttackGroup = Tabs.Main:AddLeftGroupbox("攻击控制")

AttackGroup:AddToggle("AutoAttack", {
    Text = "自动攻击",
    Default = false,
    Tooltip = "开启后实时扫描并攻击所有活着的怪物",
}):OnChanged(function(Value)
    Settings.Enabled = Value
    if Value then
        Library:Notify("自动攻击已开启 | 实时扫描模式", 3)
        State.Connection = RunService.Heartbeat:Connect(AttackLoop)
    else
        Library:Notify("自动攻击已关闭", 3)
        if State.Connection then
            State.Connection:Disconnect()
            State.Connection = nil
        end
        State.CurrentTargetName = "无"
    end
end)

AttackGroup:AddSlider("RangeSlider", {
    Text = "攻击范围",
    Default = 5000,
    Min = 100,
    Max = 10000,
    Rounding = 0,
    Suffix = " studs",
}):OnChanged(function(Value)
    Settings.MaxDistance = Value
end)

AttackGroup:AddSlider("IntervalSlider", {
    Text = "攻击间隔",
    Default = 0.01,
    Min = 0.01,
    Max = 1,
    Rounding = 2,
    Suffix = "s",
}):OnChanged(function(Value)
    Settings.AttackInterval = Value
end)

AttackGroup:AddInput("FilterInput", {
    Text = "怪物名称过滤",
    Default = "",
    Numeric = false,
    Finished = true,
}):OnChanged(function(Value)
    Settings.MonsterFilter = Value
end)

AttackGroup:AddButton("手动攻击全部（测试）", function()
    local monsters = GetLiveMonsters()
    Library:Notify("发现 " .. #monsters .. " 个活着的怪物", 3)
    for _, entry in ipairs(monsters) do
        AttackMonster(entry.Model)
    end
end)

-- 状态
local StatusGroup = Tabs.Main:AddRightGroupbox("状态")

local TargetLabel = StatusGroup:AddLabel("当前目标: 无")
local CountLabel = StatusGroup:AddLabel("攻击次数: 0")
local MonsterCountLabel = StatusGroup:AddLabel("周围怪物: 0")

task.spawn(function()
    while true do
        task.wait(0.3)
        local monsters = GetLiveMonsters()
        MonsterCountLabel:SetText("周围怪物: " .. #monsters)
        TargetLabel:SetText("当前目标: " .. State.CurrentTargetName)
        CountLabel:SetText("攻击次数: " .. State.TotalAttacks)
    end
end)

-- 无敌
local GodGroup = Tabs.GodMode:AddLeftGroupbox("怪物无敌")

GodGroup:AddToggle("GodModeToggle", {
    Text = "怪物攻击无伤害",
    Default = false,
    Tooltip = "开启后怪物打你零伤害",
}):OnChanged(function(Value)
    Settings.GodMode = Value
    Library:Notify(Value and "无敌已开启" or "无敌已关闭", 3)
end)

GodGroup:AddButton("测试无敌", function()
    local hum = character:FindFirstChildOfClass("Humanoid")
    if hum then
        local before = hum.Health
        hum:TakeDamage(999)
        task.wait(0.1)
        Library:Notify("血量: " .. before .. " -> " .. hum.Health, 3)
    end
end)

-- 设置
local MiscGroup = Tabs.Settings:AddLeftGroupbox("其他")

MiscGroup:AddToggle("ShowDebug", {
    Text = "显示调试信息",
    Default = true,
}):OnChanged(function(Value)
    Settings.ShowDebug = Value
end)

MiscGroup:AddButton("重置计数", function()
    State.TotalAttacks = 0
    Library:Notify("已重置", 2)
end)

--// ==================== 初始化 ====================
SetupGodMode()

player.CharacterAdded:Connect(function(newChar)
    character = newChar
    if Settings.Enabled then
        if State.Connection then State.Connection:Disconnect() end
        task.wait(1)
        State.Connection = RunService.Heartbeat:Connect(AttackLoop)
    end
end)

player.CharacterRemoving:Connect(function()
    if State.Connection then
        State.Connection:Disconnect()
        State.Connection = nil
    end
end)

Library:Notify("修复版已就绪", 5)
Library:Notify("每次循环重新扫描，死亡自动跳过", 5)
