--企鹅群1075566796
--站在前人肩膀上

local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
if not WindUI then return end

WindUI:AddTheme({
    Name = "星神",
    Accent = "#80C0FF",
    Outline = "#6090C0",
    Text = "#FFFFFF",
    Placeholder = "#D0E0FF",
})

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local autoAttack = false
local useSkills = false
local autoAim = false
local autoSwitch = true          
local playerESP = false
local speedEnabled = false
local speedValue = 16
local selectedTarget = nil
local selectedDisplayName = ""
local teleportTarget = ""
local attackConn = nil
local aimConn = nil
local skillConn = nil
local speedConn = nil
local espConn = nil
local allPlayers = {}
local espObjects = {}

local skillThread = nil
local skillToken = 0            
local lastAimPoint = nil         
local lastAimTime = 0
local suppressUntil = 0          
local fps = 0
local targetDropdown = nil       

local function refreshPlayers()
    allPlayers = {}
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            table.insert(allPlayers, plr.DisplayName)
        end
    end
    if #allPlayers == 0 then
        table.insert(allPlayers, "无其他玩家")
    end
end

local function findPlayerByDisplayName(displayName)
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.DisplayName == displayName then
            return plr
        end
    end
    return nil
end

local function getCamera()
    return workspace.CurrentCamera
end

local function isValidNumber(n)
    return typeof(n) == "number" and n == n and n ~= math.huge and n ~= -math.huge
end

local function isValidPos(p)
    return typeof(p) == "Vector3"
        and isValidNumber(p.X) and isValidNumber(p.Y) and isValidNumber(p.Z)
end


local function getTargetPart(plr)
    local char = plr and plr.Character
    if not char then return nil end
    local head = char:FindFirstChild("Head")
    if head and head:IsA("BasePart") then return head end
    local root = char:FindFirstChild("HumanoidRootPart")
    if root and root:IsA("BasePart") then return root end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum and hum.RootPart and hum.RootPart:IsA("BasePart") then return hum.RootPart end
    for _, d in ipairs(char:GetDescendants()) do
        if d:IsA("BasePart") then return d end
    end
    return nil
end


local function getTargetPosition(plr, allowCache)
    local part = getTargetPart(plr)
    if part then
        local p = part.Position
        if isValidPos(p) then
            lastAimPoint = p
            lastAimTime = os.clock()
            return p
        end
    end
    if allowCache and lastAimPoint and (os.clock() - lastAimTime) < 5 then
        return lastAimPoint
    end
    return nil
end

local function isAlivePlayer(plr)
    if not plr or not plr.Parent or plr == LocalPlayer then return false end
    local char = plr.Character
    if not char then return false end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum and hum.Health <= 0 then return false end
    return getTargetPart(plr) ~= nil
end

local function findNearestAlivePlayer()
    local myChar = LocalPlayer.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    local myPos = myRoot and myRoot.Position
    local best, bestDist = nil, math.huge
    for _, plr in ipairs(Players:GetPlayers()) do
        if isAlivePlayer(plr) then
            local part = getTargetPart(plr)
            if part then
                local d = 0
                if isValidPos(myPos) then
                    d = (myPos - part.Position).Magnitude
                end
                if d < bestDist then
                    bestDist = d
                    best = plr
                end
            end
        end
    end
    return best
end


local function currentTarget()
    local plr = selectedTarget
    if not plr or not plr.Parent then
        plr = findPlayerByDisplayName(selectedDisplayName)
        selectedTarget = plr
    end
    if not plr or not plr.Parent then return nil end

    if (plr.Character == nil or getTargetPart(plr) == nil) and autoSwitch then
        local n = findNearestAlivePlayer()
        if n then
            plr = n
            selectedTarget = n
            selectedDisplayName = n.DisplayName
            lastAimPoint = nil
            if targetDropdown then
                pcall(function() targetDropdown:SetValue(n.DisplayName) end)
            end
        end
    end
    return plr
end

local function fireLeftClick()
    local char = LocalPlayer.Character
    if not char then return end
    local event = char:FindFirstChild("Communicate")
    if event then
        pcall(function()
            event:FireServer({
                Goal = "LeftClick",
                Mobile = true
            })
        end)
    end
end

local function pressKey(keyCode)
    pcall(function()
        local vim = game:GetService("VirtualInputManager")
        vim:SendKeyEvent(true, keyCode, false, game)
        task.wait(0.05)
        vim:SendKeyEvent(false, keyCode, false, game)
    end)
end

local function clearESP()
    for _, obj in pairs(espObjects) do
        pcall(function() obj:Destroy() end)
    end
    espObjects = {}
end

local function cleanupESPSlot(plr)
    local entry = espObjects[plr]
    if not entry then return end
    pcall(function() entry.Highlight:Destroy() end)
    pcall(function() entry.Billboard:Destroy() end)
    espObjects[plr] = nil
end

local function updateESP()
    if not playerESP then
        clearESP()
        return
    end
    for _, plr in pairs(Players:GetPlayers()) do
        local entry = espObjects[plr]
        local char = plr.Character
        local head = char and char:FindFirstChild("Head")
        
        local valid = entry and entry.Highlight and entry.Highlight.Parent == char

        if plr == LocalPlayer or not char or not head or not valid then
            cleanupESPSlot(plr)
        end

        if plr ~= LocalPlayer and char and head and not espObjects[plr] then
            local highlight = Instance.new("Highlight")
            highlight.FillColor = Color3.fromRGB(0, 100, 255)
            highlight.FillTransparency = 0.5
            highlight.OutlineColor = Color3.fromRGB(0, 100, 255)
            highlight.OutlineTransparency = 0.2
            highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            highlight.Parent = char

            local bg = Instance.new("BillboardGui")
            bg.Size = UDim2.new(0, 200, 0, 40)
            bg.AlwaysOnTop = true
            bg.MaxDistance = math.huge
            bg.Parent = head

            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1, 0, 1, 0)
            label.BackgroundTransparency = 1
            label.Text = plr.DisplayName
            label.TextColor3 = Color3.fromRGB(0, 150, 255)
            label.Font = Enum.Font.GothamBold
            label.TextSize = 14
            label.TextStrokeTransparency = 0.5
            label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
            label.Parent = bg

            espObjects[plr] = {Highlight = highlight, Billboard = bg}
        end
    end
end

local function startAttackLoop()
    if attackConn then attackConn:Disconnect() end
    attackConn = RunService.Heartbeat:Connect(function()
        if not autoAttack then return end
        pcall(function()
            local target = currentTarget()
            if not target then return end

            local myChar = LocalPlayer.Character
            local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
            if not myRoot then return end

            local pos = getTargetPosition(target, true)
            if not pos then return end

            local targetChar = target.Character
            local targetRoot = targetChar and targetChar:FindFirstChild("HumanoidRootPart")
            local look = Vector3.new(0, 0, -1)
            if targetRoot and isValidPos(targetRoot.CFrame.Position) then
                local lv = targetRoot.CFrame.LookVector
                if lv.Magnitude > 0.1 then look = lv end
            end

            local behindPos = pos - look * 3
            if (behindPos - pos).Magnitude > 0.05 then
                local newCF = CFrame.lookAt(behindPos, pos)
                if isValidPos(newCF.Position) then
                    myRoot.CFrame = newCF
                    myRoot.AssemblyLinearVelocity = Vector3.zero
                end
            end

            local cam = getCamera()
            if cam then
                local camPos = cam.CFrame.Position
                if isValidPos(camPos) and (pos - camPos).Magnitude > 0.1 then
                    cam.CFrame = CFrame.lookAt(camPos, pos)
                end
            end

            fireLeftClick()
            fireLeftClick()
        end)
    end)
end

local function startAimLoop()
    if aimConn then aimConn:Disconnect() end
    aimConn = RunService.RenderStepped:Connect(function()
        if not autoAim then return end
        pcall(function()
            local target = currentTarget()
            if not target then return end

            local pos = getTargetPosition(target, true)
            if not pos then return end

            local cam = getCamera()
            if not cam then return end
            local camPos = cam.CFrame.Position
            if not isValidPos(camPos) then return end
            if (pos - camPos).Magnitude < 0.1 then return end
            cam.CFrame = CFrame.lookAt(camPos, pos)
        end)
    end)
end

local function stopSkillLoop()
    skillToken = skillToken + 1
    skillThread = nil
end

local function startSkillLoop()
    stopSkillLoop()
    local myToken = skillToken
    skillThread = task.spawn(function()
        while useSkills and skillToken == myToken do
            pressKey(Enum.KeyCode.One)
            if not useSkills or skillToken ~= myToken then break end
            task.wait(0.5)
            pressKey(Enum.KeyCode.Two)
            if not useSkills or skillToken ~= myToken then break end
            task.wait(0.5)
            pressKey(Enum.KeyCode.Three)
            if not useSkills or skillToken ~= myToken then break end
            task.wait(0.5)
            pressKey(Enum.KeyCode.Four)
            if not useSkills or skillToken ~= myToken then break end
            task.wait(9)
        end
    end)
end

local function startSpeedLoop()
    if speedConn then speedConn:Disconnect() end
    speedConn = RunService.Heartbeat:Connect(function()
        if not speedEnabled then return end
        local myChar = LocalPlayer.Character
        if myChar then
            local humanoid = myChar:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid.WalkSpeed = speedValue
            end
        end
    end)
end

local function pickupTrashCan()
    local myChar = LocalPlayer.Character
    if not myChar then return end
    local myRoot = myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end
    local originalPos = myRoot.CFrame
    local myPos = myRoot.Position
    local nearest = nil
    local nearestDist = math.huge
    
    for _, obj in pairs(workspace:GetDescendants()) do
        local name = obj.Name:lower()
        if name:find("trash can") or name:find("trashcan") then
            local root = obj:IsA("Model") and (obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")) or (obj:IsA("BasePart") and obj)
            if root and root.Position then
                local d = (myPos - root.Position).Magnitude
                if d < nearestDist then
                    nearestDist = d
                    nearest = root
                end
            end
        end
    end
    
    if not nearest then
        WindUI:Notify({Title = "未找到", Content = "附近没有垃圾桶", Duration = 2})
        return
    end
    
    myRoot.CFrame = CFrame.new(nearest.Position + Vector3.new(0, 2, 0))
    task.wait(0.4)
    for i = 1, 3 do
        fireLeftClick()
        task.wait(0.15)
    end
    task.wait(0.3)
    myRoot.CFrame = originalPos
    WindUI:Notify({Title = "拾取完成", Content = "已回到原地", Duration = 2})
end

local function teleportToPlayer()
    if teleportTarget == "" or teleportTarget == "无其他玩家" then
        WindUI:Notify({Title = "提示", Content = "请选择玩家", Duration = 2})
        return
    end
    local plr = findPlayerByDisplayName(teleportTarget)
    if plr and plr.Character then
        local myChar = LocalPlayer.Character
        if myChar then
            local myRoot = myChar:FindFirstChild("HumanoidRootPart")
            local targetRoot = plr.Character:FindFirstChild("HumanoidRootPart")
            if myRoot and targetRoot then
                myRoot.CFrame = targetRoot.CFrame * CFrame.new(0, 0, 3)
                WindUI:Notify({Title = "传送成功", Content = "已传送到 " .. plr.DisplayName, Duration = 2})
            end
        end
    end
end

refreshPlayers()
selectedDisplayName = allPlayers[1] or "无其他玩家"
teleportTarget = allPlayers[1] or "无其他玩家"
selectedTarget = findPlayerByDisplayName(selectedDisplayName)

local Window = WindUI:CreateWindow({
    Title = "最强战场",
    Icon = "solar:moon-bold",
    Size = UDim2.fromOffset(600, 350),
    ToggleKey = Enum.KeyCode.RightShift,
    Theme = "星神",
    Transparent = true,
    ScrollBarEnabled = true,
})

Window:Tab({Title = "公告", Icon = "solar:info-circle-bold"}):Paragraph({
    Title = "最强战场",
    Desc = "我想偷个懒"
})

local MainTab = Window:Tab({Title = "主要功能", Icon = "solar:star-bold"})

targetDropdown = MainTab:Dropdown({
    Title = "选择目标",
    Values = allPlayers,
    Value = selectedDisplayName,
    Callback = function(v)
        if os.clock() < suppressUntil then return end
        selectedDisplayName = v
        selectedTarget = findPlayerByDisplayName(v)
        lastAimPoint = nil
    end
})

MainTab:Toggle({
    Title = "自动打人",
    Desc = "对面移动时可能打不中",
    Value = false,
    Callback = function(v)
        autoAttack = v
        if v then
            selectedTarget = findPlayerByDisplayName(selectedDisplayName)
            startAttackLoop()
        end
    end
})

MainTab:Toggle({
    Title = "自瞄玩家",
    Value = false,
    Callback = function(v)
        autoAim = v
        if v then
            selectedTarget = findPlayerByDisplayName(selectedDisplayName)
            startAimLoop()
        end
    end
})

MainTab:Toggle({
    Title = "击倒后自动换目标",
    Desc = "目标被击倒/角色消失时自动锁定最近活人",
    Value = true,
    Callback = function(v)
        autoSwitch = v
    end
})

MainTab:Toggle({
    Title = "自动放技能(不建议开)",
    Value = false,
    Callback = function(v)
        useSkills = v
        if v then
            startSkillLoop()
        else
            stopSkillLoop()
        end
    end
})

MainTab:Button({
    Title = "拾取垃圾桶(可能bug)",
    Callback = function()
        pickupTrashCan()
    end
})

local PlayerTab = Window:Tab({Title = "玩家功能", Icon = "solar:user-bold"})

PlayerTab:Toggle({
    Title = "调整移速",
    Value = false,
    Callback = function(v)
        speedEnabled = v
        if v then startSpeedLoop() end
    end
})

PlayerTab:Slider({
    Title = "速度值 (16-200)",
    Value = {Min = 16, Max = 200, Default = 16},
    Step = 1,
    Callback = function(v)
        speedValue = v
    end
})

PlayerTab:Toggle({
    Title = "透视所有玩家",
    Value = false,
    Callback = function(v)
        playerESP = v
        if not v then clearESP() end
    end
})

PlayerTab:Divider()

local tpDropdown = PlayerTab:Dropdown({
    Title = "选择传送玩家",
    Values = allPlayers,
    Value = teleportTarget,
    Callback = function(v)
        if os.clock() < suppressUntil then return end
        teleportTarget = v
    end
})

PlayerTab:Button({
    Title = "传送玩家",
    Callback = function()
        teleportToPlayer()
    end
})

local fpsConn = RunService.RenderStepped:Connect(function(dt)
    if dt and dt > 0 then
        fps = fps * 0.9 + (1 / dt) * 0.1
    end
end)

task.spawn(function()
    while true do
        refreshPlayers()
        
        suppressUntil = os.clock() + 0.25
        pcall(function()
            targetDropdown:SetValues(allPlayers)
            tpDropdown:SetValues(allPlayers)
        end)
        updateESP()
        task.wait(1)
    end
end)

local SettingsTab = Window:Tab({Title = "设置", Icon = "solar:settings-bold"})
local statusPara = SettingsTab:Paragraph({Title = "功能状态", Desc = "加载中..."})

task.spawn(function()
    while true do
        local status = ""
        status = status .. "自动打人: " .. (autoAttack and "yes" or "no") .. "\n"
        status = status .. "自瞄玩家: " .. (autoAim and "yes" or "no") .. "\n"
        status = status .. "自动放技能: " .. (useSkills and "yes" or "no") .. "\n"
        status = status .. "调整移速: " .. (speedEnabled and "yes" or "no") .. "\n"
        status = status .. "透视玩家: " .. (playerESP and "yes" or "no") .. "\n"
        status = status .. "击倒换目标: " .. (autoSwitch and "yes" or "no") .. "\n"
        status = status .. "当前目标: " .. (selectedTarget and selectedTarget.DisplayName or "无") .. "\n"
        status = status .. "帧率: " .. math.floor(fps) .. " FPS"
        statusPara:SetDesc(status)
        task.wait(1)
    end
end)

SettingsTab:Button({
    Title = "关闭面板",
    Callback = function()
        Window:Close()
    end
})

Window:OnClose(function()
    autoAttack = false
    autoAim = false
    speedEnabled = false
    playerESP = false
    stopSkillLoop()
    useSkills = false
    clearESP()
    if attackConn then attackConn:Disconnect() end
    if aimConn then aimConn:Disconnect() end
    if speedConn then speedConn:Disconnect() end
    if fpsConn then fpsConn:Disconnect() end
end)

WindUI:Notify({
    Title = "星神公益最强战场",
    Content = "加载完成",
    Duration = 3
})
