-- 清理旧 UI（更彻底）
pcall(function()
    local coreGui = game:GetService("CoreGui")
    local old = coreGui:FindFirstChild("WindUI")
    if old then
        old:Destroy()
    end
    -- 有些 WindUI 版本用不同名字
    for _, v in ipairs(coreGui:GetChildren()) do
        if v:IsA("ScreenGui") and (v.Name:find("Wind") or v.Name:find("wind")) then
            v:Destroy()
        end
    end
end)

task.wait(0.1)

-- 加载 WindUI（带备用源）
local WindUI = nil
local loadSources = {
    "https://github.com/Footagesus/WindUI/releases/latest/download/main.lua",
    "https://raw.githubusercontent.com/Footagesus/WindUI/refs/heads/main/main.lua", -- 备用
}

for i, url in ipairs(loadSources) do
    local success, result = pcall(function()
        return loadstring(game:HttpGet(url, true))()
    end)
    if success and result and type(result.CreateWindow) == "function" then
        WindUI = result
        break
    else
        warn("WindUI 加载尝试 " .. i .. " 失败: " .. tostring(result))
    end
    task.wait(0.2)
end

if not WindUI then
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "加载失败",
        Text = "WindUI 库无法加载，请检查网络或更换注入器",
        Duration = 5
    })
    warn("WindUI 加载失败，脚本已终止")
    return
end

-- 创建主窗口（修复 KeySystem 配置，避免阻塞）
local Window
local ok, err = pcall(function()
    Window = WindUI:CreateWindow({
        Title = "VIP 脚本",
        Icon = "rbxassetid://129260712070622",
        IconThemed = true,
        Author = "VIP 功能",
        Folder = "云中心",
        Size = UDim2.fromOffset(580, 460),
        Transparent = true,
        Theme = "Dark",
        User = { Enabled = true, Callback = function() print("已点击") end, Anonymous = true },
        SideBarWidth = 200,
        ScrollBarEnabled = true,
        -- 密钥系统：如果不需要可以整段删掉，需要的话确保 URL 有效
        KeySystem = {
            Key = { "1234", "5678" },
            Note = "示例密钥系统。\n\n密钥是 '1234' 或 '5678'",
            URL = "https://github.com/Footagesus/WindUI", -- 改为有效链接
            SaveKey = true,
        },
    })
end)

if not ok or not Window then
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "窗口创建失败",
        Text = tostring(err),
        Duration = 5
    })
    warn("CreateWindow 失败: " .. tostring(err))
    return
end

-- 以下代码保持不变（你的标签页和功能代码）...
local Tabs = {}
Tabs.GeneralTab = Window:Section({ Title = "VIP 功能", Opened = true }):Tab({ Title = "通用", Icon = "star", ShowTabTitle = true })
Tabs.WeirdBatTab = Window:Section({ Title = "VIP 功能", Opened = true }):Tab({ Title = "古怪的球棒", Icon = "star", ShowTabTitle = true })
Tabs.NukeTab = Window:Section({ Title = "VIP 功能", Opened = true }):Tab({ Title = "合成核弹", Icon = "star", ShowTabTitle = true })
Tabs.AssassinTab = Window:Section({ Title = "VIP 功能", Opened = true }):Tab({ Title = "沉默的刺客", Icon = "star", ShowTabTitle = true })

local toggleRefs = {}

-- ====== 透视 ======
local espEnabled = false
local espConnections = {}
local espObjects = {}

local function createESP(player)
    if not player.Character then return end
    local character = player.Character
    local highlight = Instance.new("Highlight")
    highlight.FillColor = Color3.fromRGB(255, 105, 180)
    highlight.FillTransparency = 0.5
    highlight.OutlineColor = Color3.fromRGB(0, 255, 255)
    highlight.OutlineTransparency = 0
    highlight.Adornee = character
    highlight.Parent = character
    table.insert(espObjects, highlight)

    local head = character:FindFirstChild("Head")
    if head then
        pcall(function() head:FindFirstChild("ESP_NameTag"):Destroy() end)
        local billboard = Instance.new("BillboardGui")
        billboard.Name = "ESP_NameTag"
        billboard.Size = UDim2.new(0, 200, 0, 40)
        billboard.StudsOffset = Vector3.new(0, 2.8, 0)
        billboard.AlwaysOnTop = true
        billboard.Parent = head

        local textLabel = Instance.new("TextLabel")
        textLabel.Size = UDim2.new(1, 0, 1, 0)
        textLabel.BackgroundTransparency = 1
        textLabel.Text = player.Name
        textLabel.TextColor3 = Color3.fromRGB(255, 105, 180)
        textLabel.TextSize = 10
        textLabel.TextTransparency = 0.4
        textLabel.Font = Enum.Font.GothamBold
        textLabel.TextStrokeTransparency = 0.4
        textLabel.TextStrokeColor3 = Color3.fromRGB(255, 105, 180)
        textLabel.Parent = billboard
        table.insert(espObjects, billboard)
    end
end

local function toggleESP(state)
    espEnabled = state
    if state then
        for _, conn in ipairs(espConnections) do
            if conn then conn:Disconnect() end
        end
        espConnections = {}
        for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
            if player ~= game:GetService("Players").LocalPlayer then
                if player.Character then
                    createESP(player)
                end
                player.CharacterAdded:Connect(function(char)
                    if espEnabled and player ~= game:GetService("Players").LocalPlayer then
                        task.wait(0.1)
                        createESP(player)
                    end
                end)
            end
        end
        espConnections[1] = game:GetService("Players").PlayerAdded:Connect(function(player)
            if espEnabled and player ~= game:GetService("Players").LocalPlayer then
                player.CharacterAdded:Connect(function()
                    if espEnabled and player ~= game:GetService("Players").LocalPlayer then
                        task.wait(0.1)
                        createESP(player)
                    end
                end)
            end
        end)
    else
        for _, obj in ipairs(espObjects) do
            if obj and obj.Parent then obj:Destroy() end
        end
        espObjects = {}
        for _, conn in ipairs(espConnections) do
            if conn then conn:Disconnect() end
        end
        espConnections = {}
    end
end

toggleRefs.esp = Tabs.GeneralTab:Toggle({ Title = "透视", Value = false, Callback = function(state) toggleESP(state) end })

-- ====== 加速 ======
local speedEnabled = false
local originalWalkSpeed = 16
local speedValue = 50

toggleRefs.speed = Tabs.GeneralTab:Toggle({
    Title = "加速", Value = false,
    Callback = function(state)
        speedEnabled = state
        local player = game:GetService("Players").LocalPlayer
        if not player.Character then return end
        local humanoid = player.Character:FindFirstChild("Humanoid")
        if humanoid then
            if state then
                originalWalkSpeed = humanoid.WalkSpeed
                humanoid.WalkSpeed = speedValue
            else
                humanoid.WalkSpeed = originalWalkSpeed
            end
        end
    end
})

Tabs.GeneralTab:Slider({
    Title = "速度调节", Value = { Min = 16, Max = 2000, Default = 50 },
    Callback = function(value)
        speedValue = value
        if speedEnabled then
            local player = game:GetService("Players").LocalPlayer
            if player.Character then
                local humanoid = player.Character:FindFirstChild("Humanoid")
                if humanoid then humanoid.WalkSpeed = value end
            end
        end
    end
})

Tabs.GeneralTab:Button({
    Title = "恢复初始速度",
    Callback = function()
        local player = game:GetService("Players").LocalPlayer
        if not player.Character then return end
        local humanoid = player.Character:FindFirstChild("Humanoid")
        if humanoid then humanoid.WalkSpeed = 16; speedEnabled = false end
    end
})

-- ====== 高跳 ======
local jumpEnabled = false
local originalJumpPower = 50
local jumpValue = 100

toggleRefs.jump = Tabs.GeneralTab:Toggle({
    Title = "高跳", Value = false,
    Callback = function(state)
        jumpEnabled = state
        local player = game:GetService("Players").LocalPlayer
        if not player.Character then return end
        local humanoid = player.Character:FindFirstChild("Humanoid")
        if humanoid then
            if state then
                originalJumpPower = humanoid.JumpPower
                humanoid.JumpPower = jumpValue
            else
                humanoid.JumpPower = originalJumpPower
            end
        end
    end
})

Tabs.GeneralTab:Slider({
    Title = "跳跃高度调节", Value = { Min = 50, Max = 2000, Default = 100 },
    Callback = function(value)
        jumpValue = value
        if jumpEnabled then
            local player = game:GetService("Players").LocalPlayer
            if player.Character then
                local humanoid = player.Character:FindFirstChild("Humanoid")
                if humanoid then humanoid.JumpPower = value end
            end
        end
    end
})

Tabs.GeneralTab:Button({
    Title = "恢复初始跳跃",
    Callback = function()
        local player = game:GetService("Players").LocalPlayer
        if not player.Character then return end
        local humanoid = player.Character:FindFirstChild("Humanoid")
        if humanoid then humanoid.JumpPower = 50; jumpEnabled = false end
    end
})

-- ====== 马可波罗（旋转） ======
local runService = game:GetService("RunService")
local spinEnabled = false
local spinConnection = nil
local spinSpeed = 100

toggleRefs.spin = Tabs.GeneralTab:Toggle({
    Title = "马可波罗", Desc = "baby，你晕了吗", Value = false,
    Callback = function(state)
        spinEnabled = state
        if state then
            spinConnection = runService.RenderStepped:Connect(function(deltaTime)
                if not spinEnabled then return end
                local player = game:GetService("Players").LocalPlayer
                local char = player.Character
                if char then
                    local humanoid = char:FindFirstChildOfClass("Humanoid")
                    local root = char:FindFirstChild("HumanoidRootPart")
                    if humanoid and root then
                        humanoid.AutoRotate = false
                        root.CFrame = CFrame.new(root.Position) * (root.CFrame - root.Position) * CFrame.Angles(0, math.rad(spinSpeed) * deltaTime, 0)
                    end
                end
            end)
        else
            if spinConnection then spinConnection:Disconnect(); spinConnection = nil end
            local player = game:GetService("Players").LocalPlayer
            if player.Character then
                local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
                if humanoid then humanoid.AutoRotate = true end
            end
        end
    end
})

Tabs.GeneralTab:Slider({
    Title = "旋转速度", Desc = "度/秒", Value = { Min = 10, Max = 10000, Default = 100 },
    Callback = function(value) spinSpeed = value end
})

-- ====== 夜视功能 ======
local lighting = game:GetService("Lighting")
local nightVisionEnabled = false
local nightVisionThread = nil
local originalAmbient = lighting.Ambient
local originalOutdoorAmbient = lighting.OutdoorAmbient
local originalFogEnd = lighting.FogEnd
local originalBrightness = lighting.Brightness

toggleRefs.nightVision = Tabs.GeneralTab:Toggle({
    Title = "夜视",
    Desc = "提亮画面，看清黑暗区域",
    Value = false,
    Callback = function(state)
        nightVisionEnabled = state
        if state then
            nightVisionThread = task.spawn(function()
                while nightVisionEnabled do
                    lighting.Ambient = Color3.fromRGB(200, 200, 200)
                    lighting.OutdoorAmbient = Color3.fromRGB(200, 200, 200)
                    lighting.FogEnd = 10000
                    lighting.Brightness = 3
                    task.wait(0.5)
                end
            end)
        else
            if nightVisionThread then
                task.cancel(nightVisionThread)
                nightVisionThread = nil
            end
            lighting.Ambient = originalAmbient
            lighting.OutdoorAmbient = originalOutdoorAmbient
            lighting.FogEnd = originalFogEnd
            lighting.Brightness = originalBrightness
        end
    end
})

-- ====== 死亡/重生后自动恢复加速和高跳 ======
game:GetService("Players").LocalPlayer.CharacterAdded:Connect(function(char)
    local function applyStats()
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            if speedEnabled then
                hum.WalkSpeed = speedValue
            end
            if jumpEnabled then
                hum.JumpPower = jumpValue
            end
            return true
        end
        return false
    end
    if not applyStats() then
        for i = 1, 10 do
            task.wait(0.1)
            if applyStats() then break end
        end
    end
end)

-- ==============================================
-- 折叠区域1：标记点与循环传送
-- ==============================================
local MarkSection = Tabs.GeneralTab:Section({ Title = "标记点与循环传送", Opened = false })
local markObjects = {}
local markPositions = { [1] = Vector3.zero, [2] = Vector3.zero, [3] = Vector3.zero }

local function removeMark(index)
    if markObjects[index] then
        if markObjects[index].Part then markObjects[index].Part:Destroy() end
        markObjects[index] = nil
    end
end

local function setMark(index)
    local player = game:GetService("Players").LocalPlayer
    local char = player.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        local pos = char.HumanoidRootPart.Position
        removeMark(index)
        local part = Instance.new("Part")
        part.Anchored = true; part.CanCollide = false; part.Size = Vector3.new(0.2, 0.2, 0.2); part.Transparency = 1; part.Position = pos; part.Parent = workspace
        local billboard = Instance.new("BillboardGui")
        billboard.Adornee = part; billboard.Size = UDim2.new(0, 200, 0, 40); billboard.StudsOffset = Vector3.new(0, 2, 0); billboard.AlwaysOnTop = true; billboard.Parent = part
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, 0, 1, 0); label.BackgroundTransparency = 1; label.Text = "标记点" .. index; label.TextColor3 = Color3.fromRGB(255, 255, 0); label.TextSize = 18; label.Font = Enum.Font.GothamBold; label.TextStrokeTransparency = 0; label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0); label.Parent = billboard
        markObjects[index] = { Part = part }; markPositions[index] = pos
        WindUI:Notify({ Title = "标记点" .. index, Content = "已设置标记", Duration = 1.5 })
    end
end

MarkSection:Button({ Title = "标记点1", Desc = "在当前坐标设置标记点1", Callback = function() setMark(1) end })
MarkSection:Button({ Title = "清除标记点1", Desc = "移除标记点1", Callback = function() removeMark(1); markPositions[1] = Vector3.zero; WindUI:Notify({ Title = "已清除", Content = "标记点1已移除", Duration = 1 }) end })
MarkSection:Button({ Title = "标记点2", Desc = "在当前坐标设置标记点2", Callback = function() setMark(2) end })
MarkSection:Button({ Title = "清除标记点2", Desc = "移除标记点2", Callback = function() removeMark(2); markPositions[2] = Vector3.zero; WindUI:Notify({ Title = "已清除", Content = "标记点2已移除", Duration = 1 }) end })
MarkSection:Button({ Title = "标记点3", Desc = "在当前坐标设置标记点3", Callback = function() setMark(3) end })
MarkSection:Button({ Title = "清除标记点3", Desc = "移除标记点3", Callback = function() removeMark(3); markPositions[3] = Vector3.zero; WindUI:Notify({ Title = "已清除", Content = "标记点3已移除", Duration = 1 }) end })

local loopTeleportEnabled = false
local loopTeleportThread = nil
toggleRefs.loopTeleport = MarkSection:Toggle({
    Title = "循环传送", Desc = "按1→2→3→1顺序循环传送", Value = false,
    Callback = function(state)
        loopTeleportEnabled = state
        if state then
            loopTeleportThread = task.spawn(function()
                while loopTeleportEnabled do
                    for i = 1, 3 do
                        if not loopTeleportEnabled then break end
                        local pos = markPositions[i]
                        if pos ~= Vector3.zero then
                            local player = game:GetService("Players").LocalPlayer
                            local char = player.Character
                            if char and char:FindFirstChild("HumanoidRootPart") then
                                char.HumanoidRootPart.CFrame = CFrame.new(pos)
                            end
                            task.wait(0.05)
                        end
                    end
                    task.wait(0.05)
                end
            end)
        else if loopTeleportThread then task.cancel(loopTeleportThread); loopTeleportThread = nil end end
    end
})

-- ==============================================
-- 折叠区域2：坐标传送
-- ==============================================
local TeleSection = Tabs.GeneralTab:Section({ Title = "坐标传送", Opened = false })
TeleSection:Button({
    Title = "复制当前坐标", Desc = "将当前位置复制到剪贴板",
    Callback = function()
        local player = game:GetService("Players").LocalPlayer
        local char = player.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            local pos = char.HumanoidRootPart.Position
            local str = string.format("%d,%d,%d", math.round(pos.X), math.round(pos.Y), math.round(pos.Z))
            if setclipboard then setclipboard(str) else game:GetService("StarterGui"):SetCore("SendNotification", { Title = "坐标已复制", Text = str, Duration = 2 }) end
            WindUI:Notify({ Title = "复制成功", Content = str, Duration = 1.5 })
        end
    end
})
local inputCoord = "0,0,0"
TeleSection:Input({ Title = "目标坐标", Desc = "格式：X,Y,Z", Default = "0,0,0", Callback = function(text) inputCoord = text end })
TeleSection:Button({
    Title = "传送", Desc = "传送到输入的坐标",
    Callback = function()
        local x,y,z = inputCoord:match("([^,]+),([^,]+),([^,]+)")
        if x and y and z then
            local player = game:GetService("Players").LocalPlayer
            local char = player.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                char.HumanoidRootPart.CFrame = CFrame.new(tonumber(x) or 0, tonumber(y) or 0, tonumber(z) or 0)
                WindUI:Notify({ Title = "传送成功", Content = inputCoord, Duration = 1 })
            end
        else WindUI:Notify({ Title = "格式错误", Content = "请使用 X,Y,Z 格式", Duration = 2 }) end
    end
})

-- ====== 一键关闭所有功能 ======
Tabs.GeneralTab:Button({
    Title = "一键关闭所有功能", Desc = "关闭所有VIP功能并恢复默认值",
    Callback = function()
        for name, toggle in pairs(toggleRefs) do pcall(function() toggle:SetValue(false) end) end
        toggleESP(false)
        if chainKillThread then task.cancel(chainKillThread); chainKillThread = nil end
        if shotbatKillThread then task.cancel(shotbatKillThread); shotbatKillThread = nil end
        if tripbatKillThread then task.cancel(tripbatKillThread); tripbatKillThread = nil end
        if gubbyThread then task.cancel(gubbyThread); gubbyThread = nil end
        if poisonKillThread then task.cancel(poisonKillThread); poisonKillThread = nil end
        if attractThread then task.cancel(attractThread); attractThread = nil end
        if aquaKillThread then task.cancel(aquaKillThread); aquaKillThread = nil end
        if electroKillThread then task.cancel(electroKillThread); electroKillThread = nil end
        if antiFallThread then task.cancel(antiFallThread); antiFallThread = nil end
        if spinConnection then spinConnection:Disconnect(); spinConnection = nil end
        if loopTeleportThread then task.cancel(loopTeleportThread); loopTeleportThread = nil end
        if nightVisionThread then task.cancel(nightVisionThread); nightVisionThread = nil end
        if autoMergeThread then task.cancel(autoMergeThread); autoMergeThread = nil end
        if assassinThread then task.cancel(assassinThread); assassinThread = nil end
        if autoAttackThread then task.cancel(autoAttackThread); autoAttackThread = nil end
        if gachaThread then task.cancel(gachaThread); gachaThread = nil end
        lighting.Ambient = originalAmbient; lighting.OutdoorAmbient = originalOutdoorAmbient; lighting.FogEnd = originalFogEnd; lighting.Brightness = originalBrightness
        local player = game:GetService("Players").LocalPlayer
        if player.Character then
            local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
            if humanoid then humanoid.AutoRotate = true; humanoid.WalkSpeed = 16; humanoid.JumpPower = 50 end
        end
        speedEnabled = false; jumpEnabled = false
        WindUI:Notify({ Title = "已关闭", Content = "所有功能已关闭", Duration = 3 })
    end
})

-- ====== 古怪的球棒选项卡 ======
local chainKillEnabled = false; local chainKillThread = nil
toggleRefs.chainKill = Tabs.WeirdBatTab:Toggle({
    Title = "秒杀", Desc = "牢大肘击", Value = false,
    Callback = function(state)
        chainKillEnabled = state
        if state then
            chainKillThread = task.spawn(function()
                while chainKillEnabled do
                    local player = game:GetService("Players").LocalPlayer
                    local char = player.Character
                    if char then
                        local tool = char:FindFirstChildOfClass("Tool") or player.Backpack:FindFirstChildOfClass("Tool")
                        if tool then
                            game:GetService("ReplicatedStorage"):WaitForChild("BatRemotes"):WaitForChild("Chainlinker"):FireServer(tool)
                        end
                    end
                    task.wait(0.01)
                end
            end)
        else if chainKillThread then task.cancel(chainKillThread); chainKillThread = nil end end
    end
})

local shotbatKillEnabled = false; local shotbatKillThread = nil
toggleRefs.shotbatKill = Tabs.WeirdBatTab:Toggle({
    Title = "射到精尽(射门棒)", Desc = "开启后疯狂射精", Value = false,
    Callback = function(state)
        shotbatKillEnabled = state
        if state then
            shotbatKillThread = task.spawn(function()
                while shotbatKillEnabled do
                    local player = game:GetService("Players").LocalPlayer
                    local char = player.Character
                    if char then
                        local tool = char:FindFirstChild("Shotbat") or player.Backpack:FindFirstChild("Shotbat")
                        if tool then
                            game:GetService("ReplicatedStorage"):WaitForChild("BatRemotes"):WaitForChild("Shotbat"):WaitForChild("Blast"):FireServer(tool)
                        end
                    end
                    task.wait(0.01)
                end
            end)
        else if shotbatKillThread then task.cancel(shotbatKillThread); shotbatKillThread = nil end end
    end
})

local tripbatKillEnabled = false; local tripbatKillThread = nil
toggleRefs.tripbatKill = Tabs.WeirdBatTab:Toggle({
    Title = "玉面手雷王(子空间跳跃棒)", Desc = "开启后化身玉面手雷王", Value = false,
    Callback = function(state)
        tripbatKillEnabled = state
        if state then
            tripbatKillThread = task.spawn(function()
                while tripbatKillEnabled do
                    local player = game:GetService("Players").LocalPlayer
                    local char = player.Character
                    if char then
                        local tool = char:FindFirstChild("Subspace Tripbat") or player.Backpack:FindFirstChild("Subspace Tripbat")
                        if tool then
                            game:GetService("ReplicatedStorage"):WaitForChild("BatRemotes"):WaitForChild("Subspace Tripbat"):WaitForChild("Tripmine Throw"):FireServer(tool)
                        end
                    end
                    task.wait(0.01)
                end
            end)
        else if tripbatKillThread then task.cancel(tripbatKillThread); tripbatKillThread = nil end end
    end
})

local gubbyEnabled = false; local gubbyThread = nil
toggleRefs.gubby = Tabs.WeirdBatTab:Toggle({
    Title = "上吧皮卡丘(古比球棒)", Desc = "方向跟随键盘/摇杆移动方向", Value = false,
    Callback = function(state)
        gubbyEnabled = state
        if state then
            gubbyThread = task.spawn(function()
                while gubbyEnabled do
                    local player = game:GetService("Players").LocalPlayer
                    local char = player.Character
                    if char then
                        local tool = char:FindFirstChild("Gubby Bat") or player.Backpack:FindFirstChild("Gubby Bat")
                        if tool then
                            local humanoid = char:FindFirstChildOfClass("Humanoid"); local rootPart = char:FindFirstChild("HumanoidRootPart")
                            if humanoid and rootPart then
                                local moveDir = humanoid.MoveDirection
                                if moveDir.Magnitude > 0 then rootPart.CFrame = CFrame.new(rootPart.Position, rootPart.Position + moveDir) end
                            end
                            game:GetService("ReplicatedStorage"):WaitForChild("BatRemotes"):WaitForChild("Gubby Bat"):WaitForChild("Gubby Dash"):FireServer(tool)
                        end
                    end
                    task.wait(0.01)
                end
            end)
        else if gubbyThread then task.cancel(gubbyThread); gubbyThread = nil end end
    end
})

local poisonKillEnabled = false; local poisonKillThread = nil
toggleRefs.poisonKill = Tabs.WeirdBatTab:Toggle({
    Title = "绝命毒师(毒液棒)", Desc = "疯狂释放毒气云", Value = false,
    Callback = function(state)
        poisonKillEnabled = state
        if state then
            poisonKillThread = task.spawn(function()
                while poisonKillEnabled do
                    local player = game:GetService("Players").LocalPlayer
                    local char = player.Character
                    if char then
                        local tool = char:FindFirstChild("Poison Bat") or player.Backpack:FindFirstChild("Poison Bat")
                        if tool then
                            game:GetService("ReplicatedStorage"):WaitForChild("BatRemotes"):WaitForChild("Poison Bat"):WaitForChild("Poison Cloud"):FireServer(tool)
                        end
                    end
                    task.wait(0.01)
                end
            end)
        else if poisonKillThread then task.cancel(poisonKillThread); poisonKillThread = nil end end
    end
})

local attractEnabled = false; local attractThread = nil
toggleRefs.attract = Tabs.WeirdBatTab:Toggle({
    Title = "吸人", Desc = "自动传送到最近的存活玩家，无目标时回到安全点", Value = false,
    Callback = function(state)
        attractEnabled = state
        if state then
            attractThread = task.spawn(function()
                while attractEnabled do
                    local player = game:GetService("Players").LocalPlayer
                    local myChar = player.Character
                    if myChar and myChar:FindFirstChild("HumanoidRootPart") then
                        local myPos = myChar.HumanoidRootPart.Position
                        local closestPlayer = nil; local closestDist = math.huge
                        for _, p in ipairs(game:GetService("Players"):GetPlayers()) do
                            if p ~= player and p.Character then
                                local char = p.Character; local enemyRoot = char:FindFirstChild("HumanoidRootPart")
                                local humanoid = char:FindFirstChildOfClass("Humanoid"); local forceField = char:FindFirstChildOfClass("ForceField")
                                if enemyRoot and humanoid and humanoid.Health > 0 and not forceField then
                                    local dist = (enemyRoot.Position - myPos).Magnitude
                                    if dist < closestDist then closestDist = dist; closestPlayer = p end
                                end
                            end
                        end
                        if closestPlayer and closestPlayer.Character and closestPlayer.Character:FindFirstChild("HumanoidRootPart") then
                            myChar.HumanoidRootPart.CFrame = closestPlayer.Character.HumanoidRootPart.CFrame
                        else
                            myChar.HumanoidRootPart.CFrame = CFrame.new(78, 179, -3)
                        end
                    end
                    task.wait(0.1)
                end
            end)
        else if attractThread then task.cancel(attractThread); attractThread = nil end end
    end
})

local aquaKillEnabled = false; local aquaKillThread = nil
toggleRefs.aquaKill = Tabs.WeirdBatTab:Toggle({
    Title = "推推乐（aqua球棒）", Desc = "疯狂释放海浪技能（间隔0.1秒）", Value = false,
    Callback = function(state)
        aquaKillEnabled = state
        if state then
            aquaKillThread = task.spawn(function()
                while aquaKillEnabled do
                    local player = game:GetService("Players").LocalPlayer
                    local char = player.Character
                    if char then
                        local tool = char:FindFirstChild("Aqua Bat") or player.Backpack:FindFirstChild("Aqua Bat")
                        if tool then
                            game:GetService("ReplicatedStorage"):WaitForChild("BatRemotes"):WaitForChild("Aqua Bat"):WaitForChild("Aqua Power"):FireServer(tool)
                        end
                    end
                    task.wait(0.1)
                end
            end)
        else if aquaKillThread then task.cancel(aquaKillThread); aquaKillThread = nil end end
    end
})

local electroKillEnabled = false; local electroKillThread = nil
toggleRefs.electroKill = Tabs.WeirdBatTab:Toggle({
    Title = "五雷轰顶(咖喱棒)", Desc = "疯狂释放雷电技能（自动瞄准敌人，无目标时保持上一位置）", Value = false,
    Callback = function(state)
        electroKillEnabled = state
        if state then
            electroKillThread = task.spawn(function()
                local lastTargetPos = nil
                local function getDefaultTarget()
                    local player = game:GetService("Players").LocalPlayer
                    local char = player.Character
                    if char and char:FindFirstChild("HumanoidRootPart") then return char.HumanoidRootPart.Position + char.HumanoidRootPart.CFrame.LookVector * 10 end
                    return Vector3.new(78, 179, -3)
                end
                lastTargetPos = getDefaultTarget()
                while electroKillEnabled do
                    local player = game:GetService("Players").LocalPlayer; local char = player.Character
                    if char then
                        local tool = char:FindFirstChild("Electro Bat") or player.Backpack:FindFirstChild("Electro Bat")
                        if tool then
                            local root = char:FindFirstChild("HumanoidRootPart"); local myPos = root and root.Position
                            if myPos then
                                local closestDist = 1000; local newTarget = nil
                                for _, p in ipairs(game:GetService("Players"):GetPlayers()) do
                                    if p ~= player and p.Character then
                                        local enemyRoot = p.Character:FindFirstChild("HumanoidRootPart")
                                        local enemyHumanoid = p.Character:FindFirstChildOfClass("Humanoid")
                                        local forceField = p.Character:FindFirstChildOfClass("ForceField")
                                        if enemyRoot and enemyHumanoid and enemyHumanoid.Health > 0 and not forceField then
                                            local dist = (enemyRoot.Position - myPos).Magnitude
                                            if dist < closestDist then closestDist = dist; newTarget = enemyRoot.Position end
                                        end
                                    end
                                end
                                if newTarget then lastTargetPos = newTarget end
                            end
                            game:GetService("ReplicatedStorage"):WaitForChild("BatRemotes"):WaitForChild("Electro Bat"):WaitForChild("Electrify"):FireServer(tool, lastTargetPos)
                        end
                    end
                    task.wait(0.01)
                end
            end)
        else if electroKillThread then task.cancel(electroKillThread); electroKillThread = nil end end
    end
})

local antiFallEnabled = false; local antiFallThread = nil
toggleRefs.antiFall = Tabs.WeirdBatTab:Toggle({
    Title = "防坠落", Desc = "高度低于5时自动传送到安全点", Value = false,
    Callback = function(state)
        antiFallEnabled = state
        if state then
            antiFallThread = task.spawn(function()
                while antiFallEnabled do
                    local player = game:GetService("Players").LocalPlayer; local char = player.Character
                    if char and char:FindFirstChild("HumanoidRootPart") then
                        if char.HumanoidRootPart.Position.Y < 5 then char.HumanoidRootPart.CFrame = CFrame.new(78, 179, -3) end
                    end
                    task.wait(0.1)
                end
            end)
        else if antiFallThread then task.cancel(antiFallThread); antiFallThread = nil end end
    end
})

Tabs.WeirdBatTab:Button({
    Title = "无限提升(力量棒)", Desc = "发送100次力量提升包",
    Callback = function()
        task.spawn(function()
            for i = 1, 100 do
                local player = game:GetService("Players").LocalPlayer; local char = player.Character
                if char then
                    local tool = char:FindFirstChild("Power Bat") or player.Backpack:FindFirstChild("Power Bat")
                    if tool then
                        game:GetService("ReplicatedStorage"):WaitForChild("BatRemotes"):WaitForChild("Power Bat"):WaitForChild("Power Up"):FireServer(tool)
                    end
                end
                task.wait(0.01)
            end
        end)
    end
})

-- ====== 合成核弹选项卡 ======
local autoMergeEnabled = false; local autoMergeThread = nil
toggleRefs.autoMerge = Tabs.NukeTab:Toggle({
    Title = "自动合成", Desc = "检测200米内同名核弹 ≥2 → 拾取并立即合成", Value = false,
    Callback = function(state)
        autoMergeEnabled = state
        if state then
            autoMergeThread = task.spawn(function()
                while autoMergeEnabled do
                    local player = game:GetService("Players").LocalPlayer; local char = player.Character
                    if char and char:FindFirstChild("HumanoidRootPart") then
                        local root = char.HumanoidRootPart; local bases = workspace:FindFirstChild("Bases")
                        if bases then
                            local nameMap = {}
                            for _, base in ipairs(bases:GetChildren()) do
                                local nukesFolder = base:FindFirstChild("Nukes")
                                if nukesFolder then
                                    for _, nuke in ipairs(nukesFolder:GetChildren()) do
                                        if (nuke:IsA("BasePart") or nuke:IsA("Model")) and nuke:GetAttribute("OwnerUserId") == player.UserId then
                                            if nuke:GetAttribute("State") == "floor" or nuke:GetAttribute("State") == "based" then
                                                local dist = (nuke:GetPivot().Position - root.Position).Magnitude
                                                if dist <= 200 then
                                                    local name = nuke.Name
                                                    if not nameMap[name] then nameMap[name] = {} end
                                                    table.insert(nameMap[name], {nuke = nuke, dist = dist})
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                            for _, list in pairs(nameMap) do
                                if #list >= 2 then
                                    table.sort(list, function(a,b) return a.dist < b.dist end)
                                    local target = list[1].nuke
                                    pcall(function() game.ReplicatedStorage:WaitForChild("NukeRemotes"):WaitForChild("PickUp"):FireServer(target) end)
                                    task.wait(0.05)
                                    pcall(function() game.ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Remotes"):WaitForChild("Networking"):WaitForChild("RE/Merge/MergeRequest"):FireServer(Instance.new("Model")) end)
                                    break
                                end
                            end
                        end
                    end
                    task.wait(0.1)
                end
            end)
        else if autoMergeThread then task.cancel(autoMergeThread); autoMergeThread = nil end end
    end
})

-- ====== 沉默的刺客选项卡 ======
local assassinEnabled = false; local assassinThread = nil
toggleRefs.assassin = Tabs.AssassinTab:Toggle({
    Title = "强制显示模型", Desc = "强制显示所有敌人的角色模型", Value = false,
    Callback = function(state)
        assassinEnabled = state
        if state then
            assassinThread = task.spawn(function()
                while assassinEnabled do
                    for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
                        if player ~= game:GetService("Players").LocalPlayer and player.Character then
                            for _, part in ipairs(player.Character:GetDescendants()) do
                                if part:IsA("BasePart") then part.Transparency = 0 end
                            end
                        end
                    end
                    task.wait(0.1)
                end
            end)
        else if assassinThread then task.cancel(assassinThread); assassinThread = nil end end
    end
})

local autoAttackEnabled = false; local autoAttackThread = nil
toggleRefs.autoAttack = Tabs.AssassinTab:Toggle({
    Title = "自动秒杀全图", Desc = "全图自动挥刀击杀（范围9990米，间隔0.01秒）", Value = false,
    Callback = function(state)
        autoAttackEnabled = state
        if state then
            autoAttackThread = task.spawn(function()
                while autoAttackEnabled do
                    local player = game:GetService("Players").LocalPlayer; local char = player.Character
                    if char then
                        local tool = char:FindFirstChild("Gaia") or player.Backpack:FindFirstChild("Gaia")
                        if tool then
                            local root = char:FindFirstChild("HumanoidRootPart")
                            if root then
                                local myPos = root.Position; local closestEnemy = nil; local closestDist = 9990
                                for _, p in ipairs(game:GetService("Players"):GetPlayers()) do
                                    if p ~= player and p.Character then
                                        local enemyRoot = p.Character:FindFirstChild("HumanoidRootPart")
                                        local enemyHum = p.Character:FindFirstChildOfClass("Humanoid")
                                        local forceField = p.Character:FindFirstChildOfClass("ForceField")
                                        if enemyRoot and enemyHum and enemyHum.Health > 0 and not forceField then
                                            local dist = (enemyRoot.Position - myPos).Magnitude
                                            if dist < closestDist then closestDist = dist; closestEnemy = { model = p.Character, root = enemyRoot, dist = dist } end
                                        end
                                    end
                                end
                                if closestEnemy then
                                    local direction = (closestEnemy.root.Position - myPos).Unit
                                    local args = {
                                        "AttemptWeaponHit",
                                        {
                                            attackCycleData = { lungeMult = 1, slowMult = 0.2, attackTime = 0.65, knockbackMult = 1, slowTime = 1.5 },
                                            knockback = 50, shouldLock = true, shouldLunge = true, hitboxOffset = Vector3.new(0,0,-1.5), isCritical = false, shouldSlow = true,
                                            attackCooldown = 0.1, damage = 100, lungeKnockback = 55, cycleIndex = 2, slowMult = 0.2, hitboxSize = Vector3.new(9,14,8),
                                            weaponDefinition = {
                                                attackCycle = {
                                                    ["1"] = { knockbackMul = 1, slowMult = 0.2, attackTime = 0.65, lungeMul = 1, slowTime = 1.5 },
                                                    ["2"] = { lungeMult = 1, slowMult = 0.2, attackTime = 0.65, knockbackMult = 1, slowTime = 1.5 },
                                                    ["3"] = { lungeMult = 0.75, slowMult = 0.2, attackTime = 0.7166666666666667, knockbackMult = 1.5, slowTime = 1.5 },
                                                    ["4"] = { lungeMult = 2.25, attackTime = 0.9833333333333333, slowMult = 0.2, hitboxOffsetAdd = Vector3.new(0,0,-1.5), hitboxSizeAdd = Vector3.new(0,0,3), knockbackMult = 2.25, slowTime = 1.5 }
                                                },
                                                attackOrder = { "1", "2", "3", "4" }
                                            },
                                            tool = tool, slowTime = 1.5
                                        },
                                        { { knockback = 50, isClosestEnemy = true, origin = closestEnemy.root.Position, enemyModel = closestEnemy.model, distance = closestEnemy.dist, direction = direction } }
                                    }
                                    pcall(function() game.ReplicatedStorage:WaitForChild("Events"):WaitForChild("GameRemoteFunction"):InvokeServer(unpack(args)) end)
                                end
                            end
                        end
                    end
                    task.wait(0.01)
                end
            end)
        else if autoAttackThread then task.cancel(autoAttackThread); autoAttackThread = nil end end
    end
})

-- 自动开箱(神圣) – 直接发包，不检测余额
local gachaEnabled = false; local gachaThread = nil
toggleRefs.gacha = Tabs.AssassinTab:Toggle({
    Title = "自动开箱(神圣)", Desc = "每0.5秒发送一次神圣开箱", Value = false,
    Callback = function(state)
        gachaEnabled = state
        if state then
            gachaThread = task.spawn(function()
                while gachaEnabled do
                    pcall(function()
                        local remote = game.ReplicatedStorage:FindFirstChild("Events")
                        if remote then remote = remote:FindFirstChild("GameRemoteFunction") end
                        if remote then remote:InvokeServer("AttemptRollGachaChest", "Divine") end
                    end)
                    task.wait(0.5)
                end
            end)
        else
            if gachaThread then task.cancel(gachaThread); gachaThread = nil end
        end
    end
})

Window:OnClose(function()
    lighting.Ambient = originalAmbient; lighting.OutdoorAmbient = originalOutdoorAmbient; lighting.FogEnd = originalFogEnd; lighting.Brightness = originalBrightness
    local player = game:GetService("Players").LocalPlayer
    if player.Character then
        local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then humanoid.AutoRotate = true end
    end
    print("界面已关闭。")
end)

Window:SelectTab(1)

-- 加载成功提示
WindUI:Notify({ Title = "VIP 脚本", Content = "加载成功！", Duration = 2 })
