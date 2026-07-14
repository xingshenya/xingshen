-- ===== 全图爆闪穿墙版（主球1000，附着相机） =====
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Events = ReplicatedStorage:WaitForChild("Events")
local RemoteEvents = Events:WaitForChild("RemoteEvents")
local slideEvent = RemoteEvents:WaitForChild("ReplicateSlidingEffect")

local isActive = false
local isScriptAlive = true
local ball = nil
local subBalls = {}
local loopConnection = nil
local broadcastConnection = nil
local uiInstance = nil
local buttonRef = nil

-- 参数（主球尺寸固定1000）
local scale = 1000
local maxScale = 1000
local growthSpeed = 0          -- 不增长，固定1000
local flashInterval = 0.01

local function createSubBall(root, offset)
    local b = Instance.new("Part")
    b.Name = "SubFlashBall"
    b.Size = Vector3.new(200, 200, 200)
    b.Shape = Enum.PartType.Ball
    b.Anchored = true
    b.CanCollide = false
    b.CastShadow = false
    b.Material = Enum.Material.Neon
    b.Color = Color3.fromRGB(255, 200, 80)
    b.Transparency = 0.2
    b.CFrame = root.CFrame + offset
    b.Parent = workspace

    local light = Instance.new("PointLight")
    light.Parent = b
    light.Color = b.Color
    light.Range = 5000
    light.Brightness = 2
    table.insert(subBalls, b)
    return b
end

local function createBall(char)
    if not char then return false end
    local root = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Head")
    if not root then return false end

    -- 清理旧对象
    if ball and ball.Parent then ball:Destroy() end
    for _, sb in ipairs(subBalls) do
        if sb and sb.Parent then sb:Destroy() end
    end
    subBalls = {}

    -- 主光球（附着在相机上，永远在屏幕最前）
    local camera = workspace.CurrentCamera
    ball = Instance.new("Part")
    ball.Name = "MainFlashBall"
    ball.Size = Vector3.new(scale, scale, scale)
    ball.Shape = Enum.PartType.Ball
    ball.Anchored = true
    ball.CanCollide = false
    ball.CastShadow = false
    ball.Material = Enum.Material.Neon
    ball.Color = Color3.fromRGB(255, 200, 80)
    ball.Transparency = 0.1
    ball.CFrame = camera.CFrame * CFrame.new(0, 0, -100)  -- 放在相机前方100单位
    ball.Parent = workspace

    local light = Instance.new("PointLight")
    light.Parent = ball
    light.Color = ball.Color
    light.Range = 5000
    light.Brightness = 2

    -- 子光球（分布在角色周围，穿墙覆盖）
    local offsets = {
        Vector3.new(300, 0, 0),
        Vector3.new(-300, 0, 0),
        Vector3.new(0, 0, 300),
        Vector3.new(0, 0, -300),
        Vector3.new(0, 200, 0),
        Vector3.new(0, -200, 0)
    }
    for _, off in ipairs(offsets) do
        createSubBall(root, off)
    end

    return true
end

local function updateBall()
    if not ball or not ball.Parent then return end

    -- 主球始终跟随相机（穿墙）
    local camera = workspace.CurrentCamera
    if camera then
        ball.CFrame = camera.CFrame * CFrame.new(0, 0, -100)
    end

    -- 主球闪烁
    local light = ball:FindFirstChildOfClass("PointLight")
    if light then
        local now = tick()
        local cycle = now % (flashInterval * 2)
        if cycle < flashInterval then
            light.Brightness = 200
            ball.Transparency = 0.05
            ball.Color = Color3.fromRGB(255, 255, 230)
            light.Color = ball.Color
        else
            light.Brightness = 0
            ball.Transparency = 0.9
            ball.Color = Color3.fromRGB(255, 150, 50)
            light.Color = ball.Color
        end
        light.Range = 5000
    end

    -- 主球尺寸固定1000（不加脉动，保持稳定）
    ball.Size = Vector3.new(scale, scale, scale)

    -- 更新子光球（围绕角色旋转，始终覆盖周围）
    local char = player.Character
    local root
    if char then
        root = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Head")
    end
    for i, sb in ipairs(subBalls) do
        if sb and sb.Parent and root then
            local angle = tick() * 0.3 + i * math.pi / 3
            local radius = 150 + math.sin(tick() * 0.2 + i) * 50
            local pos = root.Position + Vector3.new(
                math.cos(angle) * radius,
                math.sin(angle * 0.5) * 60 + 20,
                math.sin(angle) * radius
            )
            sb.CFrame = CFrame.new(pos)
            sb.Size = Vector3.new(300, 300, 300)

            -- 子球同步闪烁
            local sl = sb:FindFirstChildOfClass("PointLight")
            if sl then
                local now = tick()
                local cycle = now % (flashInterval * 2)
                if cycle < flashInterval then
                    sl.Brightness = 200
                    sb.Transparency = 0.05
                    sb.Color = Color3.fromRGB(255, 255, 230)
                    sl.Color = sb.Color
                else
                    sl.Brightness = 0
                    sb.Transparency = 0.9
                    sb.Color = Color3.fromRGB(255, 150, 50)
                    sl.Color = sb.Color
                end
                sl.Range = 5000
            end
        end
    end
end

local function removeBall()
    if ball then
        ball:Destroy()
        ball = nil
    end
    for _, sb in ipairs(subBalls) do
        if sb and sb.Parent then sb:Destroy() end
    end
    subBalls = {}
end

local function broadcastSlide(state)
    if not isScriptAlive then return end
    local char = player.Character
    if not char then return end
    local rootPart = char:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end
    slideEvent:FireServer(state)
end

local function startEffect()
    if not isScriptAlive or isActive then return end
    isActive = true

    local char = player.Character
    if not char then
        warn("[光球] 角色不存在")
        return
    end

    if not createBall(char) then
        isActive = false
        return
    end

    broadcastSlide(true)

    loopConnection = RunService.RenderStepped:Connect(function()
        if isActive and isScriptAlive then updateBall() end
    end)

    broadcastConnection = RunService.Heartbeat:Connect(function()
        if isActive and isScriptAlive then broadcastSlide(true) end
    end)

    if buttonRef then
        buttonRef.Text = "关闭"
        buttonRef.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    end
    print("[全图爆闪] 已开启（主球1000，穿墙，子球覆盖全图）")
end

local function stopEffect()
    if not isActive then return end
    isActive = false
    removeBall()
    broadcastSlide(false)
    if loopConnection then
        loopConnection:Disconnect()
        loopConnection = nil
    end
    if broadcastConnection then
        broadcastConnection:Disconnect()
        broadcastConnection = nil
    end
    if buttonRef then
        buttonRef.Text = "开启"
        buttonRef.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
    end
    print("[全图爆闪] 已停止")
end

local function terminateScript()
    isScriptAlive = false
    stopEffect()
    if uiInstance then
        uiInstance:Destroy()
        uiInstance = nil
    end
    print("[全图爆闪] 脚本已彻底终止")
end

-- UI 函数（保持不变）
local function createUI()
    if not isScriptAlive then return end
    if uiInstance then uiInstance:Destroy() end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "FlashGUI"
    screenGui.Parent = player.PlayerGui
    uiInstance = screenGui

    local panel = Instance.new("Frame")
    panel.Size = UDim2.new(0, 200, 0, 60)
    panel.Position = UDim2.new(0.85, -100, 0.1, 0)
    panel.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    panel.BackgroundTransparency = 0.3
    panel.BorderSizePixel = 0
    panel.Parent = screenGui

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -30, 0.5, 0)
    label.Position = UDim2.new(0, 5, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = "💥 全图爆闪"
    label.TextColor3 = Color3.new(1,1,1)
    label.Font = Enum.Font.SourceSansBold
    label.TextSize = 16
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = panel

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.7, 0, 0.35, 0)
    btn.Position = UDim2.new(0.05, 0, 0.55, 0)
    btn.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
    btn.Text = "开启"
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 18
    btn.BackgroundTransparency = 0.2
    btn.BorderSizePixel = 0
    btn.Parent = panel
    buttonRef = btn

    btn.MouseButton1Click:Connect(function()
        if not isScriptAlive then return end
        if isActive then stopEffect() else startEffect() end
    end)

    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 30, 0, 30)
    closeBtn.Position = UDim2.new(1, -35, 0, 2)
    closeBtn.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
    closeBtn.Text = "✕"
    closeBtn.TextColor3 = Color3.new(1,1,1)
    closeBtn.Font = Enum.Font.SourceSansBold
    closeBtn.TextSize = 18
    closeBtn.BackgroundTransparency = 0.2
    closeBtn.BorderSizePixel = 0
    closeBtn.Parent = panel
    closeBtn.MouseButton1Click:Connect(terminateScript)

    local drag = { dragging = false, startPos = nil, startMouse = nil }
    panel.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            drag.dragging = true
            drag.startMouse = input.Position
            drag.startPos = panel.Position
        end
    end)
    panel.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            drag.dragging = false
        end
    end)
    panel.InputChanged:Connect(function(input)
        if drag.dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - drag.startMouse
            panel.Position = UDim2.new(
                drag.startPos.X.Scale, drag.startPos.X.Offset + delta.X,
                drag.startPos.Y.Scale, drag.startPos.Y.Offset + delta.Y
            )
        end
    end)
end

createUI()
player.CharacterAdded:Connect(function(char)
    if not isScriptAlive then return end
    createUI()
    if isActive then
        createBall(char)
        broadcastSlide(true)
    end
end)

print("[全图爆闪] 已加载，主球尺寸1000，附着相机，穿墙显示，点击「开启」启动")
