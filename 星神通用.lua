pcall(function()
    local cg = game:GetService("CoreGui")
    local old = cg:FindFirstChild("WindUI")
    if old then old:Destroy() end
    for _, v in ipairs(cg:GetChildren()) do
        if v:IsA("ScreenGui") and (v.Name:find("Wind") or v.Name:find("wind")) then
            pcall(function() v:Destroy() end)
        end
    end
end)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local StarterGui = game:GetService("StarterGui")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

repeat task.wait() until LocalPlayer:FindFirstChild("PlayerGui")

local WindUI
local CACHE_FILE = "WindUI_Cache_v2.lua"

pcall(function()
    if readfile and isfile and isfile(CACHE_FILE) then
        local src = readfile(CACHE_FILE)
        if src and #src > 1000 then
            WindUI = loadstring(src)()
        end
    end
end)

if type(WindUI) ~= "table" or type(WindUI.CreateWindow) ~= "function" then
    WindUI = nil
end

if not WindUI then
    local sources = {
        "https://raw.githubusercontent.com/Footagesus/WindUI/main/main.lua",
        "https://github.com/Footagesus/WindUI/releases/latest/download/main.lua",
        "https://raw.githubusercontent.com/Footagesus/WindUI/refs/heads/main/main.lua",
    }
    local loaded = false
    for idx, url in ipairs(sources) do
        local ok, result = pcall(function()
            local src = game:HttpGet(url, true)
            if src and #src > 1000 then
                pcall(function() if writefile then writefile(CACHE_FILE, src) end end)
            end
            return loadstring(src)()
        end)
        if ok and result and result.CreateWindow then
            WindUI = result
            loaded = true
            break
        end
    end
    if not loaded then
        StarterGui:SetCore("SendNotification", {Title = "加载失败", Text = "WindUI 库无法加载", Duration = 5})
        return
    end
end

-- 精简创建参数（移除 User, Folder, SideBarWidth 等可能导致失败的项）
local Window = WindUI:CreateWindow({
    Title = "VIP 脚本",
    Icon = "rbxassetid://6031066502",
    IconThemed = true,
    Author = "VIP 功能",
    Size = UDim2.fromOffset(580, 460),
    Transparent = true,
    Theme = "Dark",
})
if not Window then
    StarterGui:SetCore("SendNotification", {Title = "窗口创建失败", Text = "请重试", Duration = 5})
    return
end

pcall(function()
    local gui = Window.Gui or Window.Window or Window.MainGui
    if gui then
        local btn = gui:FindFirstChild("Minimize", true) or gui:FindFirstChild("MinimizeButton", true)
        if btn then btn.Visible = false end
    end
end)

local Tabs = {}
local toggleRefs = {}
local sliderRefs = {}

local MainSection = Window:Section({ Title = "VIP 功能", Opened = true })
Tabs.GeneralTab = MainSection:Tab({ Title = "通用", Icon = "star", ShowTabTitle = true })
Tabs.WeirdBatTab = MainSection:Tab({ Title = "古怪的球棒", Icon = "star", ShowTabTitle = true })
Tabs.NukeTab = MainSection:Tab({ Title = "合成核弹", Icon = "star", ShowTabTitle = true })
Tabs.AssassinTab = MainSection:Tab({ Title = "沉默的刺客", Icon = "star", ShowTabTitle = true })

-- ================== 功能函数定义 ==================
local speedEnabled = false
local originalWalkSpeed = 16
local speedValue = 50

local function toggleSpeed(state)
    speedEnabled = state
    local char = LocalPlayer.Character
    if not char then return end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if humanoid then
        if state then originalWalkSpeed = humanoid.WalkSpeed; humanoid.WalkSpeed = speedValue
        else humanoid.WalkSpeed = originalWalkSpeed end
    end
end

local jumpEnabled = false
local originalJumpPower = 50
local jumpValue = 100

local function toggleJump(state)
    jumpEnabled = state
    local char = LocalPlayer.Character
    if not char then return end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if humanoid then
        if state then originalJumpPower = humanoid.JumpPower; humanoid.JumpPower = jumpValue
        else humanoid.JumpPower = originalJumpPower end
    end
end

local spinEnabled = false
local spinConnection = nil
local spinSpeed = 100

local function toggleSpin(state)
    spinEnabled = state
    if state then
        spinConnection = RunService.RenderStepped:Connect(function(deltaTime)
            if not spinEnabled then return end
            local char = LocalPlayer.Character
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
        local char = LocalPlayer.Character
        if char then
            local humanoid = char:FindFirstChildOfClass("Humanoid")
            if humanoid then humanoid.AutoRotate = true end
        end
    end
end

local nightVisionEnabled = false
local nightVisionThread = nil
local originalAmbient = Lighting.Ambient
local originalOutdoorAmbient = Lighting.OutdoorAmbient
local originalFogEnd = Lighting.FogEnd
local originalBrightness = Lighting.Brightness

local function toggleNightVision(state)
    nightVisionEnabled = state
    if state then
        nightVisionThread = task.spawn(function()
            while nightVisionEnabled do
                Lighting.Ambient = Color3.fromRGB(200, 200, 200)
                Lighting.OutdoorAmbient = Color3.fromRGB(200, 200, 200)
                Lighting.FogEnd = 10000
                Lighting.Brightness = 3
                task.wait(0.5)
            end
        end)
    else
        if nightVisionThread then task.cancel(nightVisionThread); nightVisionThread = nil end
        Lighting.Ambient = originalAmbient
        Lighting.OutdoorAmbient = originalOutdoorAmbient
        Lighting.FogEnd = originalFogEnd
        Lighting.Brightness = originalBrightness
    end
end

local attractEnabled = false
local attractThread = nil

local function toggleAttract(state)
    attractEnabled = state
    if state then
        attractThread = task.spawn(function()
            while attractEnabled do
                local myChar = LocalPlayer.Character
                if myChar and myChar:FindFirstChild("HumanoidRootPart") then
                    local myPos = myChar.HumanoidRootPart.Position
                    local closest = nil
                    local minDist = math.huge
                    for _, p in ipairs(Players:GetPlayers()) do
                        if p ~= LocalPlayer and p.Character then
                            local enemyRoot = p.Character:FindFirstChild("HumanoidRootPart")
                            local hum = p.Character:FindFirstChildOfClass("Humanoid")
                            local ff = p.Character:FindFirstChildOfClass("ForceField")
                            if enemyRoot and hum and hum.Health > 0 and not ff then
                                local dist = (enemyRoot.Position - myPos).Magnitude
                                if dist < minDist then minDist = dist; closest = enemyRoot end
                            end
                        end
                    end
                    if closest then
                        myChar.HumanoidRootPart.CFrame = closest.CFrame
                    else
                        myChar.HumanoidRootPart.CFrame = CFrame.new(78,179,-3)
                    end
                end
                task.wait(0.1)
            end
        end)
    else
        if attractThread then task.cancel(attractThread); attractThread = nil end
    end
end

local markObjects = {}
local markPositions = { [1] = Vector3.zero, [2] = Vector3.zero, [3] = Vector3.zero }
local loopTeleportEnabled = false
local loopTeleportThread = nil

local function removeMark(index)
    if markObjects[index] then
        if markObjects[index].Part then markObjects[index].Part:Destroy() end
        markObjects[index] = nil
    end
end

local function setMark(index)
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        local pos = char.HumanoidRootPart.Position
        removeMark(index)
        local part = Instance.new("Part")
        part.Anchored = true
        part.CanCollide = false
        part.Size = Vector3.new(0.2, 0.2, 0.2)
        part.Transparency = 1
        part.Position = pos
        part.Parent = Workspace
        local bill = Instance.new("BillboardGui")
        bill.Adornee = part
        bill.Size = UDim2.new(0, 200, 0, 40)
        bill.StudsOffset = Vector3.new(0,2,0)
        bill.AlwaysOnTop = true
        bill.Parent = part
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1,0,1,0)
        label.BackgroundTransparency = 1
        label.Text = "标记点"..index
        label.TextColor3 = Color3.fromRGB(255,255,0)
        label.TextSize = 18
        label.Font = Enum.Font.GothamBold
        label.TextStrokeTransparency = 0
        label.TextStrokeColor3 = Color3.fromRGB(0,0,0)
        label.Parent = bill
        markObjects[index] = { Part = part }
        markPositions[index] = pos
        WindUI:Notify({ Title = "标记点"..index, Content = "已设置", Duration = 1.5 })
    end
end

local function toggleLoopTeleport(state)
    loopTeleportEnabled = state
    if state then
        loopTeleportThread = task.spawn(function()
            while loopTeleportEnabled do
                for i = 1, 3 do
                    if not loopTeleportEnabled then break end
                    local pos = markPositions[i]
                    if pos ~= Vector3.zero then
                        local char = LocalPlayer.Character
                        if char and char:FindFirstChild("HumanoidRootPart") then
                            char.HumanoidRootPart.CFrame = CFrame.new(pos)
                        end
                        task.wait(0.05)
                    end
                end
                task.wait(0.05)
            end
        end)
    else
        if loopTeleportThread then task.cancel(loopTeleportThread); loopTeleportThread = nil end
    end
end

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
        for _, conn in ipairs(espConnections) do if conn then conn:Disconnect() end end
        espConnections = {}
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                if player.Character then createESP(player) end
                local conn = player.CharacterAdded:Connect(function()
                    if espEnabled and player ~= LocalPlayer then
                        task.wait(0.1)
                        createESP(player)
                    end
                end)
                table.insert(espConnections, conn)
            end
        end
        local conn = Players.PlayerAdded:Connect(function(player)
            if espEnabled and player ~= LocalPlayer then
                local charConn = player.CharacterAdded:Connect(function()
                    if espEnabled and player ~= LocalPlayer then
                        task.wait(0.1)
                        createESP(player)
                    end
                end)
                table.insert(espConnections, charConn)
            end
        end)
        table.insert(espConnections, conn)
    else
        for _, obj in ipairs(espObjects) do if obj and obj.Parent then obj:Destroy() end end
        espObjects = {}
        for _, conn in ipairs(espConnections) do if conn then conn:Disconnect() end end
        espConnections = {}
    end
end

local freeCamEnabled = false
local fixedCamEnabled = false
local freeCamRenderConn = nil
local fixedCamRenderConn = nil
local freeCamSpeed = 50

local function disableFreeCamInternal()
    freeCamEnabled = false
    if freeCamRenderConn then freeCamRenderConn:Disconnect(); freeCamRenderConn = nil end
end

local function disableFixedCamInternal()
    fixedCamEnabled = false
    if fixedCamRenderConn then fixedCamRenderConn:Disconnect(); fixedCamRenderConn = nil end
end

local function restoreDefaultCamera()
    disableFreeCamInternal()
    disableFixedCamInternal()
    Camera.CameraType = Enum.CameraType.Custom
    Camera.CameraSubject = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
end

local function enableFreeCam()
    if fixedCamEnabled then
        disableFixedCamInternal()
        if toggleRefs.fixedCam then pcall(function() toggleRefs.fixedCam:SetValue(false) end) end
    end
    if freeCamRenderConn then freeCamRenderConn:Disconnect() end
    freeCamEnabled = true
    Camera.CameraType = Enum.CameraType.Scriptable
    Camera.CameraSubject = nil
    freeCamRenderConn = RunService.RenderStepped:Connect(function(dt)
        if not freeCamEnabled then
            freeCamRenderConn:Disconnect()
            freeCamRenderConn = nil
            return
        end
        local moveDir = Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + Camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - Camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - Camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + Camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.E) then moveDir = moveDir + Vector3.new(0, 1, 0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.Q) then moveDir = moveDir + Vector3.new(0, -1, 0) end
        if moveDir.Magnitude > 0 then
            Camera.CFrame = Camera.CFrame + moveDir.Unit * freeCamSpeed * dt
        end
        if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
            local delta = UserInputService:GetMouseDelta()
            local sensitivity = 0.3
            Camera.CFrame = Camera.CFrame * CFrame.Angles(0, math.rad(-delta.X * sensitivity), 0) * CFrame.Angles(math.rad(-delta.Y * sensitivity), 0, 0)
        end
    end)
end

local function disableFreeCam()
    disableFreeCamInternal()
    if not fixedCamEnabled then restoreDefaultCamera() end
end

local function enableFixedCam()
    if freeCamEnabled then
        disableFreeCamInternal()
        if toggleRefs.freeCam then pcall(function() toggleRefs.freeCam:SetValue(false) end) end
    end
    if fixedCamRenderConn then fixedCamRenderConn:Disconnect() end
    fixedCamEnabled = true
    local fixedCFrame = Camera.CFrame
    Camera.CameraType = Enum.CameraType.Scriptable
    Camera.CameraSubject = nil
    Camera.CFrame = fixedCFrame
    fixedCamRenderConn = RunService.RenderStepped:Connect(function()
        if not fixedCamEnabled then
            fixedCamRenderConn:Disconnect()
            fixedCamRenderConn = nil
            return
        end
        pcall(function()
            Camera.CameraType = Enum.CameraType.Scriptable
            Camera.CameraSubject = nil
            Camera.CFrame = fixedCFrame
        end)
    end)
end

local function disableFixedCam()
    disableFixedCamInternal()
    if not freeCamEnabled then restoreDefaultCamera() end
end

local autoAttackEnabled = false
local autoAttackThread = nil

local function setAutoAttack(state)
    autoAttackEnabled = state
    if state then
        autoAttackThread = task.spawn(function()
            while autoAttackEnabled do
                local char = LocalPlayer.Character
                if char then
                    local tool = char:FindFirstChild("Gaia") or LocalPlayer.Backpack:FindFirstChild("Gaia")
                    if tool then
                        local root = char:FindFirstChild("HumanoidRootPart")
                        if root then
                            local myPos = root.Position
                            local closestEnemy = nil
                            local closestDist = 9990
                            for _, p in ipairs(Players:GetPlayers()) do
                                if p ~= LocalPlayer and p.Character then
                                    local enemyRoot = p.Character:FindFirstChild("HumanoidRootPart")
                                    local hum = p.Character:FindFirstChildOfClass("Humanoid")
                                    local ff = p.Character:FindFirstChildOfClass("ForceField")
                                    if enemyRoot and hum and hum.Health > 0 and not ff then
                                        local dist = (enemyRoot.Position - myPos).Magnitude
                                        if dist < closestDist then
                                            closestDist = dist
                                            closestEnemy = { model = p.Character, root = enemyRoot, dist = dist }
                                        end
                                    end
                                end
                            end
                            if closestEnemy then
                                local dir = (closestEnemy.root.Position - myPos).Unit
                                local args = {
                                    "AttemptWeaponHit",
                                    {
                                        attackCycleData = { lungeMult = 1, slowMult = 0.2, attackTime = 0.65, knockbackMult = 1, slowTime = 1.5 },
                                        knockback = 50, shouldLock = true, shouldLunge = true,
                                        hitboxOffset = Vector3.new(0,0,-1.5), isCritical = false, shouldSlow = true,
                                        attackCooldown = 0.1, damage = 100, lungeKnockback = 55, cycleIndex = 2, slowMult = 0.2,
                                        hitboxSize = Vector3.new(9,14,8),
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
                                    { { knockback = 50, isClosestEnemy = true, origin = closestEnemy.root.Position, enemyModel = closestEnemy.model, distance = closestEnemy.dist, direction = dir } }
                                }
                                pcall(function()
                                    ReplicatedStorage:WaitForChild("Events"):WaitForChild("GameRemoteFunction"):InvokeServer(unpack(args))
                                end)
                            end
                        end
                    end
                end
                task.wait(0.01)
            end
        end)
    else
        if autoAttackThread then task.cancel(autoAttackThread); autoAttackThread = nil end
    end
end

local function safeServerTime()
    local ok, t = pcall(function() return workspace:GetServerTimeNow() end)
    return (ok and type(t) == "number") and t or tick()
end

local function safeFireServer(pathList)
    pcall(function()
        local current = ReplicatedStorage
        for _, name in ipairs(pathList) do
            current = current:FindFirstChild(name)
            if not current then return end
        end
        if current:IsA("RemoteEvent") then current:FireServer()
        elseif current:IsA("RemoteFunction") then current:InvokeServer() end
    end)
end

local UNIT_SUFFIXES = {
    k = 1e3, m = 1e6, b = 1e9, t = 1e12,
    q = 1e15, Q = 1e18, s = 1e21, S = 1e24,
    o = 1e27, n = 1e30, d = 1e33,
    U = 1e36, D = 1e39, T = 1e42,
    qd = 1e45, Qd = 1e48, sd = 1e51,
    Sd = 1e54, od = 1e57, nd = 1e60,
    v = 1e63, V = 1e66, c = 1e69, C = 1e72,
}

local function parseNumberWithSuffix(text)
    local clean = text:gsub("%s+", ""):lower()
    local numStr, suffix = clean:match("^(%-?%d+%.?%d*)(%a*)$")
    if not numStr then return nil end
    local value = tonumber(numStr)
    if not value then return nil end
    if suffix and suffix ~= "" then
        local mult = UNIT_SUFFIXES[suffix] or 1
        value = value * mult
    end
    return value
end

local function getNukeLevel(obj)
    for _, child in ipairs(obj:GetDescendants()) do
        if child:IsA("TextLabel") and child.Text then
            local num = parseNumberWithSuffix(child.Text)
            if num then return math.floor(num + 0.5) end
        end
    end
    return nil
end

local function isNukeReady(nuke)
    if not (nuke:IsA("BasePart") or nuke:IsA("Model")) then return false end
    local state = nuke:GetAttribute("State")
    if state ~= "based" and state ~= "floor" then return false end
    local dropTime = nuke:GetAttribute("DropTime")
    if dropTime and safeServerTime() - dropTime < 0.5 then return false end
    return true
end

local function getMergeablePair()
    local groups = {}
    local bases = Workspace:FindFirstChild("Bases")
    if not bases then return nil, nil end
    for _, base in ipairs(bases:GetChildren()) do
        local nukesFolder = base:FindFirstChild("Nukes")
        if nukesFolder then
            for _, nuke in ipairs(nukesFolder:GetChildren()) do
                if nuke:GetAttribute("OwnerUserId") == LocalPlayer.UserId and isNukeReady(nuke) then
                    local level = getNukeLevel(nuke)
                    if level then
                        if not groups[level] then groups[level] = {} end
                        table.insert(groups[level], nuke)
                    end
                end
            end
        end
    end
    for level, nukes in pairs(groups) do
        if #nukes >= 2 then return nukes[1], nukes[2] end
    end
    return nil, nil
end

local autoMergeEnabled = false
local autoMergeThread = nil

local function setAutoMerge(state)
    autoMergeEnabled = state
    if state then
        autoMergeThread = task.spawn(function()
            while autoMergeEnabled do
                local success, err = pcall(function()
                    local char = LocalPlayer.Character
                    if not char then return end
                    local root = char:FindFirstChild("HumanoidRootPart")
                    if not root then return end
                    local nukeA, nukeB = getMergeablePair()
                    if not nukeA or not nukeB then task.wait(0.5) return end
                    if char:FindFirstChildOfClass("Tool") then
                        pcall(function()
                            ReplicatedStorage:WaitForChild("NukeRemotes"):WaitForChild("Drop"):FireServer(root.CFrame)
                        end)
                        task.wait(0.3)
                    end
                    root.CFrame = CFrame.new(nukeA:GetPivot().Position + Vector3.new(0, 2.5, 0))
                    task.wait(0.15)
                    pcall(function() ReplicatedStorage:WaitForChild("NukeRemotes"):WaitForChild("PickUp"):FireServer(nukeA) end)
                    task.wait(0.35)
                    root.CFrame = CFrame.new(nukeB:GetPivot().Position + Vector3.new(0, 2.5, 0))
                    task.wait(0.15)
                    pcall(function()
                        ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Remotes"):WaitForChild("Networking"):WaitForChild("RE/Merge/MergeRequest"):FireServer(nukeB)
                    end)
                    task.wait(0.5)
                    if root and root.Parent then
                        pcall(function() ReplicatedStorage:WaitForChild("NukeRemotes"):WaitForChild("Drop"):FireServer(root.CFrame) end)
                        task.wait(0.2)
                    end
                    if root and root.Parent then
                        local cur = root.Position
                        root.CFrame = CFrame.new(cur.X, 50, cur.Z)
                    end
                    task.wait(0.3)
                end)
                if not success then warn("[自动合成] 错误: " .. tostring(err)) end
                task.wait(0.2)
            end
        end)
    else
        if autoMergeThread then task.cancel(autoMergeThread); autoMergeThread = nil end
    end
end

local autoShieldEnabled = false
local autoShieldThread = nil
local shieldCooldownUntil = safeServerTime() - 1
local cooldownConnected = false

local function connectCooldownEvent()
    if cooldownConnected then return end
    pcall(function()
        local nukeRemotes = ReplicatedStorage:FindFirstChild("NukeRemotes")
        if nukeRemotes then
            local cd = nukeRemotes:FindFirstChild("NukeCooldown")
            if cd and cd:IsA("RemoteEvent") then
                cd.OnClientEvent:Connect(function(t)
                    if type(t) == "number" then shieldCooldownUntil = t end
                end)
                cooldownConnected = true
            end
        end
    end)
end

local function setAutoShield(state)
    autoShieldEnabled = state
    if state then
        connectCooldownEvent()
        autoShieldThread = task.spawn(function()
            while autoShieldEnabled do
                local now = safeServerTime()
                if now >= shieldCooldownUntil then
                    safeFireServer({"NukeRemotes", "RequestLockBase"})
                    task.wait(8)
                else
                    task.wait(math.max(0, shieldCooldownUntil - now + 0.2))
                end
            end
        end)
    else
        if autoShieldThread then task.cancel(autoShieldThread); autoShieldThread = nil end
    end
end

local function tryPurchaseUpgrade(upgradeType)
    pcall(function()
        ReplicatedStorage:WaitForChild("NukeRemotes"):WaitForChild("PurchaseUpgrade"):FireServer(upgradeType)
    end)
end

local autoUpgradeAllEnabled = false
local autoUpgradeAllThread = nil

local function setAutoUpgradeAll(state)
    autoUpgradeAllEnabled = state
    if state then
        autoUpgradeAllThread = task.spawn(function()
            while autoUpgradeAllEnabled do
                tryPurchaseUpgrade("TIER") task.wait(0.2)
                tryPurchaseUpgrade("MAX") task.wait(0.2)
                tryPurchaseUpgrade("LOCKBASE") task.wait(30)
            end
        end)
    else
        if autoUpgradeAllThread then task.cancel(autoUpgradeAllThread); autoUpgradeAllThread = nil end
    end
end

local assassinEnabled = false
local assassinThread = nil

local function setAssassin(state)
    assassinEnabled = state
    if state then
        assassinThread = task.spawn(function()
            while assassinEnabled do
                for _, p in ipairs(Players:GetPlayers()) do
                    if p ~= LocalPlayer and p.Character then
                        for _, part in ipairs(p.Character:GetDescendants()) do
                            if part:IsA("BasePart") then part.Transparency = 0 end
                        end
                    end
                end
                task.wait(0.1)
            end
        end)
    else
        if assassinThread then task.cancel(assassinThread); assassinThread = nil end
    end
end

local gachaEnabled = false
local gachaThread = nil

local function setGacha(state)
    gachaEnabled = state
    if state then
        gachaThread = task.spawn(function()
            while gachaEnabled do
                pcall(function()
                    local remote = ReplicatedStorage:FindFirstChild("Events")
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

-- ================== UI 构建 ==================
toggleRefs.esp = Tabs.GeneralTab:Toggle({ Title = "透视", Value = false, Callback = function(state) toggleESP(state) end })

toggleRefs.speed = Tabs.GeneralTab:Toggle({ Title = "加速", Value = false, Callback = toggleSpeed })
sliderRefs.speed = Tabs.GeneralTab:Slider({
    Title = "速度调节", Value = { Min = 16, Max = 2000, Default = 50 },
    Callback = function(value)
        speedValue = value
        if speedEnabled then
            local char = LocalPlayer.Character
            if char then
                local humanoid = char:FindFirstChildOfClass("Humanoid")
                if humanoid then humanoid.WalkSpeed = value end
            end
        end
    end
})
Tabs.GeneralTab:Button({
    Title = "恢复初始速度",
    Callback = function()
        local char = LocalPlayer.Character
        if not char then return end
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        if humanoid then humanoid.WalkSpeed = 16; speedEnabled = false end
    end
})

toggleRefs.jump = Tabs.GeneralTab:Toggle({ Title = "高跳", Value = false, Callback = toggleJump })
sliderRefs.jump = Tabs.GeneralTab:Slider({
    Title = "跳跃高度调节", Value = { Min = 50, Max = 2000, Default = 100 },
    Callback = function(value)
        jumpValue = value
        if jumpEnabled then
            local char = LocalPlayer.Character
            if char then
                local humanoid = char:FindFirstChildOfClass("Humanoid")
                if humanoid then humanoid.JumpPower = value end
            end
        end
    end
})
Tabs.GeneralTab:Button({
    Title = "恢复初始跳跃",
    Callback = function()
        local char = LocalPlayer.Character
        if not char then return end
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        if humanoid then humanoid.JumpPower = 50; jumpEnabled = false end
    end
})

toggleRefs.spin = Tabs.GeneralTab:Toggle({ Title = "马可波罗", Desc = "baby，你晕了吗", Value = false, Callback = toggleSpin })
sliderRefs.spin = Tabs.GeneralTab:Slider({
    Title = "旋转速度", Desc = "度/秒", Value = { Min = 10, Max = 10000, Default = 100 },
    Callback = function(value) spinSpeed = value end
})

toggleRefs.nightVision = Tabs.GeneralTab:Toggle({ Title = "夜视", Desc = "提亮画面，看清黑暗区域", Value = false, Callback = toggleNightVision })
toggleRefs.attract = Tabs.GeneralTab:Toggle({ Title = "吸人", Desc = "自动传送到最近的玩家附近", Value = false, Callback = toggleAttract })

local CameraSection = Tabs.GeneralTab:Section({ Title = "视角相机", Opened = false })
toggleRefs.freeCam = CameraSection:Toggle({
    Title = "自由移动相机视角", Desc = "WASD移动，QE升降，右键旋转视角", Value = false,
    Callback = function(state)
        if state then enableFreeCam() else disableFreeCam() end
    end
})
sliderRefs.freeCam = CameraSection:Slider({
    Title = "自由视角速度", Value = { Min = 10, Max = 200, Default = 50 },
    Callback = function(value) freeCamSpeed = value end
})
toggleRefs.fixedCam = CameraSection:Toggle({
    Title = "固定相机视角", Desc = "将相机固定在当前位置不动", Value = false,
    Callback = function(state)
        if state then enableFixedCam() else disableFixedCam() end
    end
})

local MarkSection = Tabs.GeneralTab:Section({ Title = "标记点与循环传送", Opened = false })
MarkSection:Button({ Title = "标记点1", Callback = function() setMark(1) end })
MarkSection:Button({ Title = "清除标记点1", Callback = function() removeMark(1); markPositions[1] = Vector3.zero end })
MarkSection:Button({ Title = "标记点2", Callback = function() setMark(2) end })
MarkSection:Button({ Title = "清除标记点2", Callback = function() removeMark(2); markPositions[2] = Vector3.zero end })
MarkSection:Button({ Title = "标记点3", Callback = function() setMark(3) end })
MarkSection:Button({ Title = "清除标记点3", Callback = function() removeMark(3); markPositions[3] = Vector3.zero end })
toggleRefs.loopTeleport = MarkSection:Toggle({ Title = "循环传送", Value = false, Callback = toggleLoopTeleport })

local TeleSection = Tabs.GeneralTab:Section({ Title = "坐标传送", Opened = false })
TeleSection:Button({
    Title = "复制当前坐标", Callback = function()
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            local pos = char.HumanoidRootPart.Position
            local str = string.format("%d,%d,%d", math.round(pos.X), math.round(pos.Y), math.round(pos.Z))
            if setclipboard then setclipboard(str) else
                StarterGui:SetCore("SendNotification",{Title="坐标已复制",Text=str,Duration=2})
            end
            WindUI:Notify({Title="复制成功",Content=str,Duration=1.5})
        end
    end
})
local inputCoord = "0,0,0"
TeleSection:Input({ Title = "目标坐标", Default = "0,0,0", Callback = function(t) inputCoord = t end })
TeleSection:Button({
    Title = "传送", Callback = function()
        local x,y,z = inputCoord:match("([^,]+),([^,]+),([^,]+)")
        if x and y and z then
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                char.HumanoidRootPart.CFrame = CFrame.new(tonumber(x) or 0, tonumber(y) or 0, tonumber(z) or 0)
                WindUI:Notify({Title="传送成功",Content=inputCoord,Duration=1})
            end
        else
            WindUI:Notify({Title="格式错误",Content="请使用 X,Y,Z 格式",Duration=2})
        end
    end
})

Tabs.GeneralTab:Button({
    Title = "一键关闭所有功能",
    Callback = function()
        for _, t in pairs(toggleRefs) do pcall(function() t:SetValue(false) end) end
        toggleESP(false)
        if spinConnection then spinConnection:Disconnect(); spinConnection = nil end
        restoreDefaultCamera()
        Lighting.Ambient = originalAmbient
        Lighting.OutdoorAmbient = originalOutdoorAmbient
        Lighting.FogEnd = originalFogEnd
        Lighting.Brightness = originalBrightness
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hum.AutoRotate = true; hum.WalkSpeed = 16; hum.JumpPower = 50 end
        end
        speedEnabled = false; jumpEnabled = false
        WindUI:Notify({ Title = "已关闭", Content = "所有功能已关闭", Duration = 3 })
    end
})

-- 古怪的球棒
local chainKillEnabled = false
local chainKillThread = nil
toggleRefs.chainKill = Tabs.WeirdBatTab:Toggle({
    Title = "秒杀", Value = false,
    Callback = function(s)
        chainKillEnabled = s
        if s then
            chainKillThread = task.spawn(function()
                while chainKillEnabled do
                    local char = LocalPlayer.Character
                    if char then
                        local tool = char:FindFirstChildOfClass("Tool") or LocalPlayer.Backpack:FindFirstChildOfClass("Tool")
                        if tool then
                            ReplicatedStorage:WaitForChild("BatRemotes"):WaitForChild("Chainlinker"):FireServer(tool)
                        end
                    end
                    task.wait(0.01)
                end
            end)
        else if chainKillThread then task.cancel(chainKillThread); chainKillThread = nil end end
    end
})

local shotbatKillEnabled = false
local shotbatKillThread = nil
toggleRefs.shotbatKill = Tabs.WeirdBatTab:Toggle({
    Title = "射到精尽(射门棒)", Value = false,
    Callback = function(s)
        shotbatKillEnabled = s
        if s then
            shotbatKillThread = task.spawn(function()
                while shotbatKillEnabled do
                    local char = LocalPlayer.Character
                    if char then
                        local tool = char:FindFirstChild("Shotbat") or LocalPlayer.Backpack:FindFirstChild("Shotbat")
                        if tool then
                            ReplicatedStorage:WaitForChild("BatRemotes"):WaitForChild("Shotbat"):WaitForChild("Blast"):FireServer(tool)
                        end
                    end
                    task.wait(0.01)
                end
            end)
        else if shotbatKillThread then task.cancel(shotbatKillThread); shotbatKillThread = nil end end
    end
})

local tripbatKillEnabled = false
local tripbatKillThread = nil
toggleRefs.tripbatKill = Tabs.WeirdBatTab:Toggle({
    Title = "玉面手雷王(子空间跳跃棒)", Value = false,
    Callback = function(s)
        tripbatKillEnabled = s
        if s then
            tripbatKillThread = task.spawn(function()
                while tripbatKillEnabled do
                    local char = LocalPlayer.Character
                    if char then
                        local tool = char:FindFirstChild("Subspace Tripbat") or LocalPlayer.Backpack:FindFirstChild("Subspace Tripbat")
                        if tool then
                            ReplicatedStorage:WaitForChild("BatRemotes"):WaitForChild("Subspace Tripbat"):WaitForChild("Tripmine Throw"):FireServer(tool)
                        end
                    end
                    task.wait(0.01)
                end
            end)
        else if tripbatKillThread then task.cancel(tripbatKillThread); tripbatKillThread = nil end end
    end
})

local gubbyEnabled = false
local gubbyThread = nil
toggleRefs.gubby = Tabs.WeirdBatTab:Toggle({
    Title = "上吧皮卡丘(古比球棒)", Value = false,
    Callback = function(s)
        gubbyEnabled = s
        if s then
            gubbyThread = task.spawn(function()
                while gubbyEnabled do
                    local char = LocalPlayer.Character
                    if char then
                        local tool = char:FindFirstChild("Gubby Bat") or LocalPlayer.Backpack:FindFirstChild("Gubby Bat")
                        if tool then
                            local hum = char:FindFirstChildOfClass("Humanoid")
                            local root = char:FindFirstChild("HumanoidRootPart")
                            if hum and root then
                                local dir = hum.MoveDirection
                                if dir.Magnitude > 0 then root.CFrame = CFrame.new(root.Position, root.Position + dir) end
                            end
                            ReplicatedStorage:WaitForChild("BatRemotes"):WaitForChild("Gubby Bat"):WaitForChild("Gubby Dash"):FireServer(tool)
                        end
                    end
                    task.wait(0.01)
                end
            end)
        else if gubbyThread then task.cancel(gubbyThread); gubbyThread = nil end end
    end
})

local poisonKillEnabled = false
local poisonKillThread = nil
toggleRefs.poisonKill = Tabs.WeirdBatTab:Toggle({
    Title = "绝命毒师(毒液棒)", Value = false,
    Callback = function(s)
        poisonKillEnabled = s
        if s then
            poisonKillThread = task.spawn(function()
                while poisonKillEnabled do
                    local char = LocalPlayer.Character
                    if char then
                        local tool = char:FindFirstChild("Poison Bat") or LocalPlayer.Backpack:FindFirstChild("Poison Bat")
                        if tool then
                            ReplicatedStorage:WaitForChild("BatRemotes"):WaitForChild("Poison Bat"):WaitForChild("Poison Cloud"):FireServer(tool)
                        end
                    end
                    task.wait(0.01)
                end
            end)
        else if poisonKillThread then task.cancel(poisonKillThread); poisonKillThread = nil end end
    end
})

local aquaKillEnabled = false
local aquaKillThread = nil
toggleRefs.aquaKill = Tabs.WeirdBatTab:Toggle({
    Title = "推推乐（aqua球棒）", Value = false,
    Callback = function(s)
        aquaKillEnabled = s
        if s then
            aquaKillThread = task.spawn(function()
                while aquaKillEnabled do
                    local char = LocalPlayer.Character
                    if char then
                        local tool = char:FindFirstChild("Aqua Bat") or LocalPlayer.Backpack:FindFirstChild("Aqua Bat")
                        if tool then
                            ReplicatedStorage:WaitForChild("BatRemotes"):WaitForChild("Aqua Bat"):WaitForChild("Aqua Power"):FireServer(tool)
                        end
                    end
                    task.wait(0.1)
                end
            end)
        else if aquaKillThread then task.cancel(aquaKillThread); aquaKillThread = nil end end
    end
})

local electroKillEnabled = false
local electroKillThread = nil
toggleRefs.electroKill = Tabs.WeirdBatTab:Toggle({
    Title = "五雷轰顶(咖喱棒)", Value = false,
    Callback = function(s)
        electroKillEnabled = s
        if s then
            electroKillThread = task.spawn(function()
                local lastTarget = nil
                local function defaultTarget()
                    local char = LocalPlayer.Character
                    if char and char:FindFirstChild("HumanoidRootPart") then
                        return char.HumanoidRootPart.Position + char.HumanoidRootPart.CFrame.LookVector * 10
                    end
                    return Vector3.new(78,179,-3)
                end
                lastTarget = defaultTarget()
                while electroKillEnabled do
                    local char = LocalPlayer.Character
                    if char then
                        local tool = char:FindFirstChild("Electro Bat") or LocalPlayer.Backpack:FindFirstChild("Electro Bat")
                        if tool then
                            local root = char:FindFirstChild("HumanoidRootPart")
                            if root then
                                local myPos = root.Position
                                local closestDist = 1000
                                local newTarget = nil
                                for _, p in ipairs(Players:GetPlayers()) do
                                    if p ~= LocalPlayer and p.Character then
                                        local enemyRoot = p.Character:FindFirstChild("HumanoidRootPart")
                                        local hum = p.Character:FindFirstChildOfClass("Humanoid")
                                        local ff = p.Character:FindFirstChildOfClass("ForceField")
                                        if enemyRoot and hum and hum.Health > 0 and not ff then
                                            local dist = (enemyRoot.Position - myPos).Magnitude
                                            if dist < closestDist then closestDist = dist; newTarget = enemyRoot.Position end
                                        end
                                    end
                                end
                                if newTarget then lastTarget = newTarget end
                            end
                            ReplicatedStorage:WaitForChild("BatRemotes"):WaitForChild("Electro Bat"):WaitForChild("Electrify"):FireServer(tool, lastTarget)
                        end
                    end
                    task.wait(0.01)
                end
            end)
        else if electroKillThread then task.cancel(electroKillThread); electroKillThread = nil end end
    end
})

local antiFallEnabled = false
local antiFallThread = nil
toggleRefs.antiFall = Tabs.WeirdBatTab:Toggle({
    Title = "防坠落", Value = false,
    Callback = function(s)
        antiFallEnabled = s
        if s then
            antiFallThread = task.spawn(function()
                while antiFallEnabled do
                    local char = LocalPlayer.Character
                    if char and char:FindFirstChild("HumanoidRootPart") then
                        if char.HumanoidRootPart.Position.Y < 5 then
                            char.HumanoidRootPart.CFrame = CFrame.new(78,179,-3)
                        end
                    end
                    task.wait(0.1)
                end
            end)
        else if antiFallThread then task.cancel(antiFallThread); antiFallThread = nil end end
    end
})

Tabs.WeirdBatTab:Button({
    Title = "无限提升(力量棒)",
    Callback = function()
        task.spawn(function()
            for i=1,100 do
                local char = LocalPlayer.Character
                if char then
                    local tool = char:FindFirstChild("Power Bat") or LocalPlayer.Backpack:FindFirstChild("Power Bat")
                    if tool then
                        ReplicatedStorage:WaitForChild("BatRemotes"):WaitForChild("Power Bat"):WaitForChild("Power Up"):FireServer(tool)
                    end
                end
                task.wait(0.01)
            end
        end)
    end
})

toggleRefs.autoMerge = Tabs.NukeTab:Toggle({ Title = "自动合成", Desc = "同等级合成后立即丢弃，并传送到Y=50高空", Value = false, Callback = setAutoMerge })
toggleRefs.autoShield = Tabs.NukeTab:Toggle({ Title = "自动防护罩", Desc = "冷却结束自动开罩", Value = false, Callback = setAutoShield })
toggleRefs.autoUpgradeAll = Tabs.NukeTab:Toggle({ Title = "自动升级（全部）", Desc = "每30秒购买全部升级", Value = false, Callback = setAutoUpgradeAll })

toggleRefs.assassin = Tabs.AssassinTab:Toggle({ Title = "强制显示模型", Value = false, Callback = setAssassin })
toggleRefs.autoAttack = Tabs.AssassinTab:Toggle({ Title = "自动秒杀全图", Desc = "全图自动挥刀击杀", Value = false, Callback = setAutoAttack })
toggleRefs.gacha = Tabs.AssassinTab:Toggle({ Title = "自动开箱(神圣)", Value = false, Callback = setGacha })

Window:OnClose(function()
    Lighting.Ambient = originalAmbient
    Lighting.OutdoorAmbient = originalOutdoorAmbient
    Lighting.FogEnd = originalFogEnd
    Lighting.Brightness = originalBrightness
    restoreDefaultCamera()
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.AutoRotate = true end
    end
end)

Window:SelectTab(1)

LocalPlayer.CharacterAdded:Connect(function(char)
    local function applyStats()
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            if speedEnabled then hum.WalkSpeed = speedValue end
            if jumpEnabled then hum.JumpPower = jumpValue end
            return true
        end
        return false
    end
    if not applyStats() then
        for i = 1, 10 do task.wait(0.1); if applyStats() then break end end
    end
    if not freeCamEnabled and not fixedCamEnabled then
        Camera.CameraType = Enum.CameraType.Custom
        Camera.CameraSubject = char:FindFirstChildOfClass("Humanoid")
    end
end)

-- 快捷键
local shiftBoostEnabled = false
local shiftOriginalSpeed = 16

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
        if not speedEnabled then
            shiftBoostEnabled = true
            local char = LocalPlayer.Character
            if char then
                local humanoid = char:FindFirstChildOfClass("Humanoid")
                if humanoid then
                    shiftOriginalSpeed = humanoid.WalkSpeed
                    humanoid.WalkSpeed = speedValue
                end
            end
        end
        return
    end
    local key = input.KeyCode
    local handled = false
    local notifyTitle = "快捷键"
    local notifyContent = ""
    if key == Enum.KeyCode.F1 then
        local newState = not espEnabled
        espEnabled = newState
        toggleESP(newState)
        pcall(function() toggleRefs.esp:SetValue(newState) end)
        notifyContent = "透视: " .. (newState and "开启" or "关闭")
        handled = true
    elseif key == Enum.KeyCode.F2 then
        local newState = not speedEnabled
        speedEnabled = newState
        toggleSpeed(newState)
        pcall(function() toggleRefs.speed:SetValue(newState) end)
        notifyContent = "加速: " .. (newState and "开启" or "关闭")
        handled = true
    elseif key == Enum.KeyCode.F3 then
        local newState = not jumpEnabled
        jumpEnabled = newState
        toggleJump(newState)
        pcall(function() toggleRefs.jump:SetValue(newState) end)
        notifyContent = "高跳: " .. (newState and "开启" or "关闭")
        handled = true
    elseif key == Enum.KeyCode.F4 then
        local newState = not attractEnabled
        attractEnabled = newState
        toggleAttract(newState)
        pcall(function() toggleRefs.attract:SetValue(newState) end)
        notifyContent = "吸人: " .. (newState and "开启" or "关闭")
        handled = true
    elseif key == Enum.KeyCode.F5 then
        local newState = not nightVisionEnabled
        nightVisionEnabled = newState
        toggleNightVision(newState)
        pcall(function() toggleRefs.nightVision:SetValue(newState) end)
        notifyContent = "夜视: " .. (newState and "开启" or "关闭")
        handled = true
    elseif key == Enum.KeyCode.F6 then
        if not freeCamEnabled then
            enableFreeCam()
            pcall(function() toggleRefs.freeCam:SetValue(true) end)
            notifyContent = "自由相机: 开启"
        else
            disableFreeCam()
            pcall(function() toggleRefs.freeCam:SetValue(false) end)
            notifyContent = "自由相机: 关闭"
        end
        handled = true
    elseif key == Enum.KeyCode.F7 then
        if not fixedCamEnabled then
            enableFixedCam()
            pcall(function() toggleRefs.fixedCam:SetValue(true) end)
            notifyContent = "固定相机: 开启"
        else
            disableFixedCam()
            pcall(function() toggleRefs.fixedCam:SetValue(false) end)
            notifyContent = "固定相机: 关闭"
        end
        handled = true
    elseif key == Enum.KeyCode.F8 then
        local newState = not loopTeleportEnabled
        loopTeleportEnabled = newState
        toggleLoopTeleport(newState)
        pcall(function() toggleRefs.loopTeleport:SetValue(newState) end)
        notifyContent = "循环传送: " .. (newState and "开启" or "关闭")
        handled = true
    elseif key == Enum.KeyCode.F9 then
        for _, t in pairs(toggleRefs) do pcall(function() t:SetValue(false) end) end
        toggleESP(false)
        if spinConnection then spinConnection:Disconnect(); spinConnection = nil end
        restoreDefaultCamera()
        Lighting.Ambient = originalAmbient
        Lighting.OutdoorAmbient = originalOutdoorAmbient
        Lighting.FogEnd = originalFogEnd
        Lighting.Brightness = originalBrightness
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hum.AutoRotate = true; hum.WalkSpeed = 16; hum.JumpPower = 50 end
        end
        speedEnabled = false; jumpEnabled = false
        notifyContent = "一键关闭所有功能"
        handled = true
    elseif key == Enum.KeyCode.F10 then
        local newState = not autoAttackEnabled
        autoAttackEnabled = newState
        setAutoAttack(newState)
        pcall(function() toggleRefs.autoAttack:SetValue(newState) end)
        notifyContent = "自动秒杀全图: " .. (newState and "开启" or "关闭")
        handled = true
    elseif key == Enum.KeyCode.F11 then
        local newState = not autoMergeEnabled
        autoMergeEnabled = newState
        setAutoMerge(newState)
        pcall(function() toggleRefs.autoMerge:SetValue(newState) end)
        notifyContent = "自动合成: " .. (newState and "开启" or "关闭")
        handled = true
    elseif key == Enum.KeyCode.F12 then
        local newState = not autoShieldEnabled
        autoShieldEnabled = newState
        setAutoShield(newState)
        pcall(function() toggleRefs.autoShield:SetValue(newState) end)
        notifyContent = "自动防护罩: " .. (newState and "开启" or "关闭")
        handled = true
    elseif key == Enum.KeyCode.One then
        local pos = markPositions[1]
        if pos ~= Vector3.zero then
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                char.HumanoidRootPart.CFrame = CFrame.new(pos)
                notifyContent = "传送到标记点1"
                handled = true
            end
        else notifyContent = "标记点1未设置"; handled = true end
    elseif key == Enum.KeyCode.Two then
        local pos = markPositions[2]
        if pos ~= Vector3.zero then
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                char.HumanoidRootPart.CFrame = CFrame.new(pos)
                notifyContent = "传送到标记点2"
                handled = true
            end
        else notifyContent = "标记点2未设置"; handled = true end
    elseif key == Enum.KeyCode.Three then
        local pos = markPositions[3]
        if pos ~= Vector3.zero then
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                char.HumanoidRootPart.CFrame = CFrame.new(pos)
                notifyContent = "传送到标记点3"
                handled = true
            end
        else notifyContent = "标记点3未设置"; handled = true end
    end
    if handled then
        pcall(function() WindUI:Notify({ Title = notifyTitle, Content = notifyContent, Duration = 1.5 }) end)
    end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
    if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
        if shiftBoostEnabled then
            shiftBoostEnabled = false
            local char = LocalPlayer.Character
            if char then
                local humanoid = char:FindFirstChildOfClass("Humanoid")
                if humanoid then humanoid.WalkSpeed = shiftOriginalSpeed end
            end
        end
    end
end)

UserInputService.InputChanged:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType == Enum.UserInputType.MouseWheel then
        local delta = input.Position.Z
        if delta ~= 0 then
            speedValue = math.clamp(speedValue + delta * 10, 16, 2000)
            if speedEnabled then
                local char = LocalPlayer.Character
                if char then
                    local humanoid = char:FindFirstChildOfClass("Humanoid")
                    if humanoid then humanoid.WalkSpeed = speedValue end
                end
            end
            pcall(function()
                if sliderRefs.speed and sliderRefs.speed.SetValue then
                    sliderRefs.speed:SetValue(speedValue)
                end
            end)
        end
    end
end)

pcall(function()
    local gui = Window.Gui or Window.Window or Window.MainGui
    if gui then
        local keybindLabel = Instance.new("TextLabel")
        keybindLabel.Name = "KeybindHint"
        keybindLabel.Size = UDim2.new(0, 260, 0, 220)
        keybindLabel.Position = UDim2.new(1, -270, 0, 10)
        keybindLabel.BackgroundTransparency = 0.3
        keybindLabel.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
        keybindLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        keybindLabel.TextSize = 11
        keybindLabel.Font = Enum.Font.GothamBold
        keybindLabel.TextXAlignment = Enum.TextXAlignment.Left
        keybindLabel.TextYAlignment = Enum.TextYAlignment.Top
        keybindLabel.Text = [[电脑端快捷键:
F1 透视 | F2 加速 | F3 高跳
F4 吸人 | F5 夜视 | F6 自由相机
F7 固定相机 | F8 循环传送
F9 一键关闭 | F10 自动秒杀
F11 自动合成 | F12 自动防护罩
1/2/3 标记点传送
Shift 临时加速 | 滚轮 调速]]
        keybindLabel.Parent = gui
    end
end)

WindUI:Notify({ Title = "VIP 脚本", Content = "加载成功！电脑端快捷键已启用", Duration = 3 })
