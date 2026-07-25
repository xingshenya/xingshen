--!native
-- https://github.com/78n/SimpleSpy 50/50 this breaks but it's a beta for a reason!

if getgenv().SimpleSpyExecuted and type(getgenv().SimpleSpyShutdown) == "function" then
    getgenv().SimpleSpyShutdown()
end

local realconfigs = {
    logcheckcaller = false,
    autoblock = false,
    funcEnabled = true,
    advancedinfo = false,
    --logreturnvalues = false,
    supersecretdevtoggle = false
}

local configs = newproxy(true)
local configsmetatable = getmetatable(configs)

configsmetatable.__index = function(self,index)
    return realconfigs[index]
end

local oth = syn and syn.oth
local unhook = oth and oth.unhook
local hook = oth and oth.hook

local lower = string.lower
local byte = string.byte
local round = math.round
local running = coroutine.running
local resume = coroutine.resume
local status = coroutine.status
local yield = coroutine.yield
local create = coroutine.create
local close = coroutine.close
local OldDebugId = game.GetDebugId
local info = debug.info

local IsA = game.IsA
local tostring = tostring
local tonumber = tonumber
local delay = task.delay
local spawn = task.spawn
local clear = table.clear
local clone = table.clone

local function blankfunction(...)
    return ...
end

local get_thread_identity = (syn and syn.get_thread_identity) or getidentity or getthreadidentity
local set_thread_identity = (syn and syn.set_thread_identity) or setidentity
local islclosure = islclosure or is_l_closure
local threadfuncs = (get_thread_identity and set_thread_identity and true) or false

local getinfo = getinfo or blankfunction
local getupvalues = getupvalues or debug.getupvalues or blankfunction
local getconstants = getconstants or debug.getconstants or blankfunction

local getcustomasset = getsynasset or getcustomasset
local getcallingscript = getcallingscript or blankfunction
local newcclosure = newcclosure or blankfunction
local clonefunction = clonefunction or blankfunction
local cloneref = cloneref or blankfunction
local request = request or syn and syn.request
local makewritable = makewriteable or function(tbl)
    setreadonly(tbl,false)
end
local makereadonly = makereadonly or function(tbl)
    setreadonly(tbl,true)
end
local isreadonly = isreadonly or table.isfrozen

local setclipboard = setclipboard or toclipboard or set_clipboard or (Clipboard and Clipboard.set) or function(...)
    return ErrorPrompt("尝试写入剪贴板："..(...),true)
end

local hookmetamethod = hookmetamethod or (makewriteable and makereadonly and getrawmetatable) and function(obj: object, metamethod: string, func: Function)
    local old = getrawmetatable(obj)

    if hookfunction then
        return hookfunction(old[metamethod],func)
    else
        local oldmetamethod = old[metamethod]
        makewriteable(old)
        old[metamethod] = func
        makereadonly(old)
        return oldmetamethod
    end
end

local function Create(instance, properties, children)
    local obj = Instance.new(instance)

    for i, v in next, properties or {} do
        obj[i] = v
        for _, child in next, children or {} do
            child.Parent = obj;
        end
    end

    return obj
end

local function rawtostring(userdata)
    local rawmetatable = getrawmetatable(userdata)
    if rawmetatable and rawmetatable.__tostring then
        local cachedstring = rawmetatable.__tostring
        rawset(rawmetatable, "__tostring", nil)
        local safestring = tostring(userdata)
        rawset(rawmetatable, "__tostring", cachedstring)
        return safestring
    end
    return tostring(userdata)
end

local methods = {
    "FindFirstChild",
    "FindFirstChildWhichIsA",
    "FindFirstChildOfClass",
    "IsA"
}

local function gettype(data)
    return typeof(data)
end

local function safeString(obj)
    local ok, result = pcall(rawtostring, obj)
    return ok and result or "?"
end

local function GetFullName(instance)
    local path = {}
    local current = instance

    while current and current ~= game do
        table.insert(path, 1, current.Name)
        current = current.Parent
    end

    return table.concat(path, ".")
end

local function ErrorPrompt(message,setup)
    warn("ERROR: ",message)
end

local function GetDebugId(instance)
    if OldDebugId then
        local ok,id = pcall(OldDebugId,instance)
        if ok then
            return id
        end
    end
    return tostring(instance):sub(#("Instance")+2,-2)
end

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local TextService = game:GetService("TextService")
local CoreGui = game:GetService("CoreGui")
local StarterGui = game:GetService("StarterGui")

local Storage = Instance.new("Folder")
Storage.Name = "SimpleSpy"
Storage.Parent = CoreGui

local function protectgui(obj)
    if syn and syn.protect_gui then
        syn.protect_gui(obj)
        obj.Parent = CoreGui
    elseif gethui then
        obj.Parent = gethui()
    else
        obj.Parent = CoreGui
    end
end

local function randomString()
    local length = math.random(10,20)
    local array = {}
    for i = 1, length do
        array[i] = string.char(math.random(32, 126))
    end
    return table.concat(array)
end

local function Tooltip(value)
    return value
end

local function newButton(name,description,onClick)
    local Button = Instance.new("TextButton")
    Button.Name = randomString()
    Button.Size = UDim2.new(1, 0, 0, 30)
    Button.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    Button.BorderSizePixel = 0
    Button.TextColor3 = Color3.fromRGB(255, 255, 255)
    Button.TextSize = 14
    Button.Font = Enum.Font.SourceSans
    Button.Text = name
    Button.AutoButtonColor = true
    Button.Parent = Sidebar

    local Desc = Instance.new("TextLabel")
    Desc.Name = "Desc"
    Desc.Size = UDim2.new(1, -10, 0, 0)
    Desc.Position = UDim2.new(0, 5, 0, 30)
    Desc.BackgroundTransparency = 1
    Desc.TextColor3 = Color3.fromRGB(200, 200, 200)
    Desc.TextSize = 12
    Desc.Font = Enum.Font.SourceSans
    Desc.TextWrapped = true
    Desc.Text = description and description(Button) or ""
    Desc.Parent = Button

    local function updateDesc()
        Desc.Text = description and description(Button) or ""
        Desc.Size = UDim2.new(1, -10, 0, TextService:GetTextSize(Desc.Text, 12, Enum.Font.SourceSans, Vector2.new(Desc.AbsoluteSize.X, math.huge)).Y)
    end

    Button.MouseButton1Click:Connect(function()
        local success, err = pcall(onClick, Button)
        if not success then
            ErrorPrompt("按钮点击错误："..tostring(err))
        end
        updateDesc()
    end)

    return Button
end

local function newTextbox()
    local TextBox = Instance.new("TextBox")
    TextBox.Name = randomString()
    TextBox.Size = UDim2.new(1, -10, 1, -10)
    TextBox.Position = UDim2.new(0, 5, 0, 5)
    TextBox.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    TextBox.BorderSizePixel = 0
    TextBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    TextBox.TextSize = 14
    TextBox.Font = Enum.Font.Code
    TextBox.TextXAlignment = Enum.TextXAlignment.Left
    TextBox.TextYAlignment = Enum.TextYAlignment.Top
    TextBox.TextWrapped = true
    TextBox.ClearTextOnFocus = false
    TextBox.MultiLine = true
    TextBox.Parent = CodeFrame

    return TextBox
end

local Sidebar = Create("Frame", {
    Name = "Sidebar",
    Size = UDim2.new(0, 150, 1, -50),
    Position = UDim2.new(0, 0, 0, 50),
    BackgroundColor3 = Color3.fromRGB(35, 35, 35),
    BorderSizePixel = 0
})

local CodeFrame = Create("Frame", {
    Name = "CodeFrame",
    Size = UDim2.new(1, -150, 1, -50),
    Position = UDim2.new(0, 150, 0, 50),
    BackgroundColor3 = Color3.fromRGB(30, 30, 30),
    BorderSizePixel = 0
})

local TopBar = Create("Frame", {
    Name = "TopBar",
    Size = UDim2.new(1, 0, 0, 50),
    BackgroundColor3 = Color3.fromRGB(25, 25, 25),
    BorderSizePixel = 0
})

local Title = Create("TextLabel", {
    Name = "Title",
    Size = UDim2.new(1, -100, 1, 0),
    Position = UDim2.new(0, 10, 0, 0),
    BackgroundTransparency = 1,
    TextColor3 = Color3.fromRGB(255, 255, 255),
    TextSize = 20,
    Font = Enum.Font.SourceSansBold,
    Text = "SimpleSpy (rspy 修复版)",
    TextXAlignment = Enum.TextXAlignment.Left
})

local TextLabel = Create("TextLabel", {
    Name = "Status",
    Size = UDim2.new(1, -160, 0, 20),
    Position = UDim2.new(0, 10, 1, -25),
    BackgroundTransparency = 1,
    TextColor3 = Color3.fromRGB(200, 200, 200),
    TextSize = 12,
    Font = Enum.Font.SourceSans,
    Text = "就绪",
    TextXAlignment = Enum.TextXAlignment.Left
})

local Main = Create("Frame", {
    Name = randomString(),
    Size = UDim2.new(0, 800, 0, 500),
    Position = UDim2.new(0.5, -400, 0.5, -250),
    BackgroundColor3 = Color3.fromRGB(30, 30, 30),
    BorderSizePixel = 0,
    Active = true,
    Draggable = true
}, {TopBar, Sidebar, CodeFrame, TextLabel})

protectgui(Main)

local codebox = newTextbox()

local function codeboxSetRaw(text)
    codebox.Text = text
end

codebox.setRaw = codeboxSetRaw

local selected = nil
local blocklist = {}
local DecompiledScripts = {}

local function v2s(obj, numSpacing, manualSpacing, typeofstr, rawFirst, explicitInstance)
    return tostring(obj)
end

local function v2p(obj, typeofstr)
    return typeofstr or typeof(obj), tostring(obj)
end

local remoteEvent = Instance.new("RemoteEvent")
local remoteFunction = Instance.new("RemoteFunction")
local unreliableRemoteEvent = Instance.new("UnreliableRemoteEvent")

local NamecallHandler = Instance.new("BindableEvent",Storage)
local originalEvent = remoteEvent.FireServer
local originalUnreliableEvent = unreliableRemoteEvent.FireServer
local originalFunction = remoteFunction.InvokeServer

local function newindex(method, original, ...)
    local args = {...}
    local remote = args[1]
    table.remove(args, 1)

    if configs.autoblock then
        if blocklist[remote] then
            return
        end
    end

    local calling = getcallingscript()
    local info = {
        Remote = remote,
        Method = method,
        Args = args,
        Source = calling,
        returnvalue = nil
    }

    NamecallHandler:Fire(info)

    if method == "InvokeServer" then
        local ok, ret = pcall(original, remote, unpack(args))
        info.returnvalue = {ok, ret}
        return ret
    else
        return original(remote, unpack(args))
    end
end

local newnamecall = newcclosure(function(...)
    local args = {...}
    local self = args[1]
    table.remove(args, 1)
    local method = getnamecallmethod()

    if method and (method == "FireServer" or method == "fireServer" or method == "InvokeServer" or method == "invokeServer") then
        if typeof(self) == "Instance" and (self:IsA("RemoteEvent") or self:IsA("RemoteFunction") or self:IsA("UnreliableRemoteEvent")) then
            local calling = getcallingscript()
            local info = {
                Remote = self,
                Method = method,
                Args = args,
                Source = calling,
                returnvalue = nil
            }

            NamecallHandler:Fire(info)

            if method == "InvokeServer" or method == "invokeServer" then
                local ok, ret = pcall(self[method], self, unpack(args))
                info.returnvalue = {ok, ret}
                return ret
            else
                return self[method](self, unpack(args))
            end
        end
    end

    return self[method](self, unpack(args))
end)

local newFireServer = newcclosure(function(...)
    return newindex("FireServer",originalEvent,...)
end)

local newUnreliableFireServer = newcclosure(function(...)
    return newindex("FireServer",originalUnreliableEvent,...)
end)

local newInvokeServer = newcclosure(function(...)
    return newindex("InvokeServer",originalFunction,...)
end)

function SimpleSpyShutdown()
    if oth and unhook then
        unhook(getrawmetatable(game).__namecall,originalnamecall)
        unhook(Instance.new("RemoteEvent").FireServer, originalEvent)
        unhook(Instance.new("RemoteFunction").InvokeServer, originalFunction)
        unhook(Instance.new("UnreliableRemoteEvent").FireServer, originalUnreliableEvent)
    elseif hookmetamethod then
        if originalnamecall then
            hookmetamethod(game,"__namecall",originalnamecall)
        end
        if originalEvent then
            hookfunction(Instance.new("RemoteEvent").FireServer, originalEvent)
        end
        if originalFunction then
            hookfunction(Instance.new("RemoteFunction").InvokeServer, originalFunction)
        end
        if originalUnreliableEvent then
            hookfunction(Instance.new("UnreliableRemoteEvent").FireServer, originalUnreliableEvent)
        end
    end
    if Main then
        Main:Destroy()
    end
    getgenv().SimpleSpyExecuted = false
end

local oldnamecall
local originalnamecall = getrawmetatable(game).__namecall

if oth and hook then
    oldnamecall = hook(getrawmetatable(game).__namecall,clonefunction(newnamecall))
    originalEvent = hook(Instance.new("RemoteEvent").FireServer, clonefunction(newFireServer))
    originalFunction = hook(Instance.new("RemoteFunction").InvokeServer, clonefunction(newInvokeServer))
    originalUnreliableEvent = hook(Instance.new("UnreliableRemoteEvent").FireServer, clonefunction(newUnreliableFireServer))
else
    if hookmetamethod then
        oldnamecall = hookmetamethod(game, "__namecall", clonefunction(newnamecall))
    else
        oldnamecall = hookfunction(getrawmetatable(game).__namecall,clonefunction(newnamecall))
    end
    originalEvent = hookfunction(Instance.new("RemoteEvent").FireServer, clonefunction(newFireServer))
    originalFunction = hookfunction(Instance.new("RemoteFunction").InvokeServer, clonefunction(newInvokeServer))
    originalUnreliableEvent = hookfunction(Instance.new("UnreliableRemoteEvent").FireServer, clonefunction(newUnreliableFireServer))
end

getgenv().SimpleSpyShutdown = SimpleSpyShutdown
getgenv().SimpleSpyExecuted = true

local Logs = {}
local LogFrame = Create("ScrollingFrame", {
    Name = "LogFrame",
    Size = UDim2.new(0, 150, 1, -50),
    Position = UDim2.new(0, 0, 0, 50),
    BackgroundColor3 = Color3.fromRGB(35, 35, 35),
    BorderSizePixel = 0,
    ScrollBarThickness = 4,
    CanvasSize = UDim2.new(0, 0, 0, 0)
})

NamecallHandler.Event:Connect(function(info)
    local Remote = info.Remote
    local Method = info.Method
    local Args = info.Args

    local logButton = Instance.new("TextButton")
    logButton.Size = UDim2.new(1, -10, 0, 30)
    logButton.Position = UDim2.new(0, 5, 0, #Logs * 35)
    logButton.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    logButton.BorderSizePixel = 0
    logButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    logButton.TextSize = 12
    logButton.Font = Enum.Font.SourceSans
    logButton.Text = (Remote and Remote.Name or "?") .. " | " .. Method
    logButton.Parent = LogFrame

    logButton.MouseButton1Click:Connect(function()
        selected = info
        local sourceName = info.Source and info.Source.Name or "未知"
        codebox:setRaw("-- 远程: " .. tostring(Remote) .. "\n-- 方法: " .. Method .. "\n-- 来源: " .. sourceName .. "\n-- 参数:\n" .. v2s(Args))
        TextLabel.Text = "已选择: " .. tostring(Remote)
    end)

    table.insert(Logs, info)
    LogFrame.CanvasSize = UDim2.new(0, 0, 0, #Logs * 35 + 10)
end)

newButton("清拦截表",
    function() return "清空拦截列表。\n清空后，之前被拦截的远程对象会恢复发送。" end,
    function()
        blocklist = {}
        TextLabel.Text = "拦截列表已清空！"
    end
)

--- Attempts to decompile the source script
newButton("反编译",
    function()
        return "反编译触发来源脚本并保存到本地文件"
    end,function()
        if not decompile then
            TextLabel.Text = "缺少反编译函数（decompile）"
            return
        end
        if not selected or not selected.Source then
            TextLabel.Text = "没有找到来源！"
            return
        end
        if not writefile then
            TextLabel.Text = "当前注入器不支持 writefile，无法保存文件"
            return
        end

        local Source = selected.Source
        local fileName = "SimpleSpy_Decompiled_" .. tostring(tick()):gsub("%.", "_") .. ".lua"
        local filePath = "SimpleSpy/" .. fileName

        if DecompiledScripts[Source] then
            pcall(function()
                writefile(filePath, DecompiledScripts[Source])
                setclipboard(filePath)
            end)
            codebox:setRaw("-- 已保存到:\n-- " .. filePath .. "\n-- 路径已复制到剪贴板")
            TextLabel.Text = "已保存到文件！"
            return
        end

        codebox:setRaw("--[[正在反编译到本地文件...]]")
        TextLabel.Text = "正在反编译，请等待..."

        task.spawn(function()
            local success, result = xpcall(function()
                local decompiledsource = decompile(Source):gsub("-- Decompiled with the Synapse X Luau decompiler.","")
                local Sourcev2s = v2s(Source)
                local finalSource = "-- Decompiled source saved to file\n"
                if (decompiledsource):find("script") and Sourcev2s then
                    finalSource = ("local script = %s\n%s"):format(Sourcev2s, decompiledsource)
                else
                    finalSource = decompiledsource
                end

                local size = #finalSource
                local sizeKB = math.round(size / 1024)
                local LIMIT = 1 * 1024 * 1024 -- 1MB

                -- 确保目录存在
                pcall(function()
                    if not isfolder("SimpleSpy") then
                        makefolder("SimpleSpy")
                    end
                end)

                if size > LIMIT then
                    -- 超过1MB：分块写入文件，限制速度避免卡死
                    local CHUNK = 200 * 1024 -- 每次200KB
                    local written = 0
                    codebox:setRaw("--[[内容超过1MB，正在保存到本地文件...]]")

                    while written < size do
                        local chunk = finalSource:sub(written + 1, math.min(written + CHUNK, size))
                        if written == 0 then
                            writefile(filePath, chunk)
                        else
                            appendfile(filePath, chunk)
                        end
                        written = written + #chunk
                        TextLabel.Text = string.format("正在保存... %d/%d KB", math.round(written / 1024), sizeKB)
                        task.wait(0.05)
                    end

                    DecompiledScripts[Source] = finalSource
                    pcall(function() setclipboard(filePath) end)

                    codebox:setRaw("-- 内容超过1MB，已保存到本地文件\n-- 路径: " .. filePath .. "\n-- 大小: " .. tostring(sizeKB) .. " KB\n-- 路径已复制到剪贴板")
                    TextLabel.Text = "完成！已保存 " .. tostring(sizeKB) .. " KB"
                else
                    -- 不超过1MB：正常显示在UI里
                    DecompiledScripts[Source] = finalSource
                    codebox:setRaw(finalSource)
                    TextLabel.Text = "完成！"
                end
            end, function(err)
                return err
            end)

            if not success then
                codebox:setRaw(("--[[\n反编译出错\n%s\n]]"):format(tostring(result)))
                TextLabel.Text = "反编译失败！"
            end
        end)
    end
)

newButton(
    configs.funcEnabled and "函数信息：开" or "函数信息：关",
    function() return string.format("当前：%s｜函数信息开关（某些游戏里会比较卡）", configs.funcEnabled and "开启" or "关闭") end,
    function(FunctionTemplate)
        configs.funcEnabled = not configs.funcEnabled
        local label = FunctionTemplate:FindFirstChild("Text")
        if label then
            label.Text = configs.funcEnabled and "函数信息：开" or "函数信息：关"
        end
        TextLabel.Text = string.format("当前：%s｜函数信息开关（某些游戏里会比较卡）", configs.funcEnabled and "开启" or "关闭")
    end
)

newButton(
    configs.autoblock and "自动排除：开" or "自动排除：关",
    function() return string.format("当前：%s｜自动识别刷屏远程调用，并从日志里排除（测试）", configs.autoblock and "开启" or "关闭") end,
    function(FunctionTemplate)
        configs.autoblock = not configs.autoblock
        local label = FunctionTemplate:FindFirstChild("Text")
        if label then
            label.Text = configs.autoblock and "自动排除：开" or "自动排除：关"
        end
        TextLabel.Text = string.format("当前：%s｜自动识别刷屏远程调用，并从日志里排除（测试）", configs.autoblock and "开启" or "关闭")
    end
)

TextLabel.Text = "SimpleSpy 已加载"
