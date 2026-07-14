local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local localPlayer = Players.LocalPlayer

local Events = ReplicatedStorage:WaitForChild("Events")
local GameRemoteFunction = Events:WaitForChild("GameRemoteFunction")

local ATTACK_DISTANCE = 90
local DAMAGE = 100
local ATTACK_COOLDOWN = 0.1

local isEnabled = true
local isRunning = true

local weaponDefinition = {
    attackCycle = {
        ["1"] = { knockbackMul = 1, slowMult = 0.2, attackTime = 0.65, lungeMul = 1, slowTime = 1.5 },
        ["4"] = { lungeMult = 2.25, attackTime = 0.9833333333333333, slowMult = 0.2, hitboxOffsetAdd = vector.create(0,0,-1.5), hitboxSizeAdd = vector.create(0,0,3), knockbackMult = 2.25, slowTime = 1.5 },
        ["3"] = { lungeMult = 0.75, slowMult = 0.2, attackTime = 0.7166666666666667, knockbackMult = 1.5, slowTime = 1.5 },
        ["2"] = { lungeMult = 1, slowMult = 0.2, attackTime = 0.65, knockbackMult = 1, slowTime = 1.5 }
    },
    attackOrder = { "1", "2", "3", "4" }
}

local function getPlayerTool()
    local char = localPlayer.Character
    if char then
        local tool = char:FindFirstChildOfClass("Tool")
        if tool then return tool end
    end
    local backpack = localPlayer:FindFirstChild("Backpack")
    if backpack then
        for _, child in ipairs(backpack:GetChildren()) do
            if child:IsA("Tool") then return child end
        end
    end
    local fakeTool = Instance.new("Tool")
    fakeTool.Name = "FakeWeapon"
    return fakeTool
end

local function attackPlayer(targetPlayer)
    if not targetPlayer or not targetPlayer.Character then return end
    local myChar = localPlayer.Character
    local targetChar = targetPlayer.Character
    if not myChar or not targetChar then return end
    
    local myRoot = myChar:FindFirstChild("HumanoidRootPart")
    local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
    if not myRoot or not targetRoot then return end
    
    local origin = myRoot.Position
    local targetPos = targetRoot.Position
    local direction = (targetPos - origin).Unit
    local distance = (targetPos - origin).Magnitude
    if distance > ATTACK_DISTANCE then return end
    
    local tool = getPlayerTool()
    
    local attackParams = {
        attackCycleData = {
            lungeMult = 2.25,
            attackTime = 0.9833333333333333,
            slowMult = 0.2,
            hitboxOffsetAdd = vector.create(0,0,-1.5),
            hitboxSizeAdd = vector.create(0,0,3),
            knockbackMult = 2.25,
            slowTime = 1.5
        },
        knockback = 112.5,
        shouldLock = true,
        shouldLunge = true,
        hitboxOffset = vector.create(0,0,-3),
        isCritical = false,
        shouldSlow = true,
        attackCooldown = 0,
        damage = DAMAGE,
        lungeKnockback = 123.75,
        cycleIndex = 4,
        slowMult = 0.2,
        hitboxSize = vector.create(9,14,11),
        weaponDefinition = weaponDefinition,
        tool = tool,
        slowTime = 1.5
    }
    
    local hits = {
        {
            knockback = 112.5,
            isClosestEnemy = true,
            origin = origin,
            enemyModel = targetChar,
            distance = distance,
            direction = direction
        }
    }
    
    local args = { "AttemptWeaponHit", attackParams, hits }
    GameRemoteFunction:InvokeServer(unpack(args))
end

local function scanAndAttackAll()
    if not isEnabled then return end
    local myChar = localPlayer.Character
    if not myChar then return end
    local myRoot = myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= localPlayer then
            local targetChar = player.Character
            if targetChar then
                local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
                if targetRoot then
                    local dist = (myRoot.Position - targetRoot.Position).Magnitude
                    if dist <= ATTACK_DISTANCE then
                        attackPlayer(player)
                    end
                end
            end
        end
    end
end

local function createUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "KillAuraGUI"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = localPlayer:WaitForChild("PlayerGui")
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 200, 0, 100)
    frame.Position = UDim2.new(0, 10, 0, 10)
    frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    frame.BackgroundTransparency = 0.2
    frame.BorderSizePixel = 1
    frame.BorderColor3 = Color3.fromRGB(255, 255, 255)
    frame.Active = true
    frame.Draggable = true
    frame.Parent = screenGui
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 25)
    title.Position = UDim2.new(0, 0, 0, 0)
    title.Text = "杀戮光环控制"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.SourceSansBold
    title.TextSize = 16
    title.Parent = frame
    
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Size = UDim2.new(0.6, 0, 0, 30)
    statusLabel.Position = UDim2.new(0.1, 0, 0.4, 0)
    statusLabel.Text = "状态: 启用"
    statusLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Font = Enum.Font.SourceSans
    statusLabel.TextSize = 14
    statusLabel.TextXAlignment = Enum.TextXAlignment.Left
    statusLabel.Parent = frame
    
    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size = UDim2.new(0.3, 0, 0, 30)
    toggleBtn.Position = UDim2.new(0.65, 0, 0.4, 0)
    toggleBtn.Text = "禁用"
    toggleBtn.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
    toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggleBtn.Font = Enum.Font.SourceSans
    toggleBtn.TextSize = 14
    toggleBtn.BorderSizePixel = 0
    toggleBtn.Parent = frame
    
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0.4, 0, 0, 30)
    closeBtn.Position = UDim2.new(0.3, 0, 0.75, 0)
    closeBtn.Text = "关闭脚本"
    closeBtn.BackgroundColor3 = Color3.fromRGB(200, 30, 30)
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.Font = Enum.Font.SourceSans
    closeBtn.TextSize = 14
    closeBtn.BorderSizePixel = 0
    closeBtn.Parent = frame
    
    toggleBtn.MouseButton1Click:Connect(function()
        isEnabled = not isEnabled
        if isEnabled then
            statusLabel.Text = "状态: 启用"
            statusLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
            toggleBtn.Text = "禁用"
            toggleBtn.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
        else
            statusLabel.Text = "状态: 禁用"
            statusLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
            toggleBtn.Text = "启用"
            toggleBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
        end
    end)
    
    closeBtn.MouseButton1Click:Connect(function()
        isRunning = false
        screenGui:Destroy()
        print("杀戮光环脚本已关闭")
    end)
    
    return screenGui
end

createUI()

while isRunning do
    if isEnabled then
        scanAndAttackAll()
    end
    wait(ATTACK_COOLDOWN)
end

print("杀戮光环循环已停止")
