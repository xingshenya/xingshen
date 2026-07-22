--[[
    Watermark: 星神3756288324优化
    Dex Explorer TX Fixed - Enhanced (Anti-Crash) - 大文本落盘修复版
--]]

local OriginalUrl = "https://raw.githubusercontent.com/JsYb666/Developer-Tool/refs/heads/main/Dex-Explorer-TX-Fixed.lua"

local success, source = pcall(function()
    return game:HttpGet(OriginalUrl)
end)
if not success or type(source) ~= "string" or #source < 100000 then
    warn("[DexEnhance] 下载失败: " .. tostring(source))
    return
end

source = source:gsub(
    "\t\t\tNotebook = Apps.Notebook\n\t\tend",
    "\t\t\tNotebook = Apps.Notebook\n\t\t\t_G.DexExplorer = Explorer\n\t\t\t_G.DexProperties = Properties\n\t\tend",
    1
)

loadstring(source)()

-- =================== 汉化映射表 ===================
local PropCN = {
    Name = "名称", Parent = "父对象", ClassName = "类名", Archivable = "可存档",
    Position = "位置", Orientation = "朝向", Rotation = "旋转", CFrame = "坐标框架",
    Size = "大小", Scale = "缩放", Color = "颜色", Color3 = "颜色3",
    BackgroundColor3 = "背景颜色", BackgroundTransparency = "背景透明度",
    BorderColor3 = "边框颜色", BorderSizePixel = "边框大小", BorderMode = "边框模式",
    Transparency = "透明度", Reflectance = "反射率", Material = "材质", Texture = "纹理",
    Anchored = "锚定", CanCollide = "可碰撞", CanQuery = "可查询", CanTouch = "可触碰",
    Locked = "锁定", Visible = "可见性", Enabled = "已启用", Active = "激活",
    Text = "文本", Font = "字体", FontFace = "字体样式", TextSize = "文本大小",
    TextColor3 = "文本颜色", TextTransparency = "文本透明度", TextStrokeColor3 = "描边颜色",
    TextStrokeTransparency = "描边透明度", TextScaled = "文本自适应", TextWrapped = "自动换行",
    TextTruncate = "文本截断", TextXAlignment = "水平对齐", TextYAlignment = "垂直对齐",
    RichText = "富文本", LineHeight = "行高", MaxVisibleGraphemes = "最大可见字符",
    Image = "图像", ImageColor3 = "图像颜色", ImageTransparency = "图像透明度",
    ImageRectOffset = "图像矩形偏移", ImageRectSize = "图像矩形大小",
    SliceCenter = "切片中心", SliceScale = "切片缩放", AutoButtonColor = "自动按钮颜色",
    Modal = "模态", Selected = "已选择", Selectable = "可选择", Style = "样式",
    LayoutOrder = "布局顺序", ZIndex = "层级", ZIndexBehavior = "层级行为",
    ClipsDescendants = "裁剪子代", AutoLocalize = "自动本地化", IgnoreGuiInset = "忽略边距",
    ResetOnSpawn = "重生重置", DisplayOrder = "显示顺序", ScreenOrientation = "屏幕方向",
    Velocity = "速度", RotVelocity = "旋转速度", AssemblyLinearVelocity = "线速度",
    AssemblyAngularVelocity = "角速度", Mass = "质量", Density = "密度", Friction = "摩擦力",
    Elasticity = "弹性", FormFactor = "形状因子", Shape = "形状",
    SoundId = "声音ID", Volume = "音量", PlaybackSpeed = "播放速度", Pitch = "音调",
    Looped = "循环", Playing = "播放中", TimePosition = "时间位置", TimeLength = "时长",
    IsPlaying = "是否播放", RollOffMode = "衰减模式", RollOffMaxDistance = "最大衰减距离",
    RollOffMinDistance = "最小衰减距离",
    Brightness = "亮度", ColorShift_Top = "顶部颜色偏移", ColorShift_Bottom = "底部颜色偏移",
    Ambient = "环境光", OutdoorAmbient = "室外环境光", TimeOfDay = "时间",
    GeographicLatitude = "地理纬度", FogColor = "雾颜色", FogStart = "雾起始", FogEnd = "雾结束",
    CameraType = "相机类型", FieldOfView = "视野", Focus = "焦点", HeadLocked = "头部锁定",
    HeadScale = "头部缩放", ViewportSize = "视口大小",
    Health = "生命值", MaxHealth = "最大生命值", WalkSpeed = "行走速度", JumpPower = "跳跃力",
    HipHeight = "臀部高度", AutoRotate = "自动旋转", Sit = "坐下", PlatformStand = "平台站立",
    Value = "数值", Adornee = "被装饰对象", AlwaysOnTop = "始终置顶", SizeOffset = "大小偏移",
    StudsOffset = "螺柱偏移", StudsOffsetWorldSpace = "世界螺柱偏移",
    PlayerToHideFrom = "要隐藏的玩家", TeamColor = "队伍颜色", Neutral = "中立",
    WalkDirection = "行走方向", Jump = "跳跃", MoveDirection = "移动方向",
    CameraMode = "相机模式", MouseBehavior = "鼠标行为", MouseIconEnabled = "鼠标图标",
    UserInputType = "输入类型", KeyCode = "按键代码", Delta = "增量",
    Hit = "命中点", Target = "目标", TargetSurface = "目标表面",
    ToolTip = "工具提示", RequiresHandle = "需要手柄", CanBeDropped = "可丢弃",
    ManualActivationOnly = "仅手动激活", Grip = "握持", GripPos = "握持位置",
    LeftGripAttachment = "左握附件", RightGripAttachment = "右握附件",
    PrimaryPart = "主部件", PivotOffset = "枢轴偏移", WorldPivot = "世界枢轴",
    CurrentCamera = "当前相机", StreamingMode = "流式模式", StreamingEnabled = "流式启用",
    Gravity = "重力", FallenPartsDestroyHeight = "掉落销毁高度",
    MeshId = "网格ID", TextureID = "纹理ID", RenderingParams = "渲染参数",
    Priority = "优先级", AnimationId = "动画ID",
    EasingDirection = "缓动方向", EasingStyle = "缓动样式", Time = "时间",
    DelayTime = "延迟", RepeatCount = "重复次数", Reverses = "反转",
    Offset = "偏移", DampingRatio = "阻尼比", Frequency = "频率",
    AspectRatio = "宽高比", AspectType = "比例类型", DominantAxis = "主轴",
    CellPadding = "单元格边距", CellSize = "单元格大小", FillDirection = "填充方向",
    FillDirectionMaxCells = "最大填充单元", SortOrder = "排序顺序",
    Padding = "边距", HorizontalAlignment = "水平对齐", VerticalAlignment = "垂直对齐",
    AbsoluteContentSize = "绝对内容大小", AbsolutePosition = "绝对位置", AbsoluteSize = "绝对大小",
    AutomaticSize = "自动大小", MinTextSize = "最小文本大小", MaxTextSize = "最大文本大小",
    TweenTime = "补间时间", MaxSize = "最大尺寸", MinSize = "最小尺寸",
    PaddingBottom = "底部边距", PaddingLeft = "左边距", PaddingRight = "右边距", PaddingTop = "顶部边距",
    ApplyStrokeMode = "描边应用模式", LineJoinMode = "线条连接模式", Thickness = "厚度",
    CornerRadius = "圆角半径", SweepAngle = "扫描角度", Clockwise = "顺时针",
    Content = "内容", ReferenceImage = "参考图像", TileSize = "平铺大小",
    SpriteOffset = "精灵偏移", SpriteSize = "精灵大小", CanvasSize = "画布大小",
    CanvasPosition = "画布位置", AutomaticCanvasSize = "自动画布大小",
    ScrollingDirection = "滚动方向", ScrollBarImageColor3 = "滚动条颜色",
    ScrollBarImageTransparency = "滚动条透明度", ScrollBarThickness = "滚动条厚度",
    MidImage = "中间图像", TopImage = "顶部图像", BottomImage = "底部图像",
    VerticalScrollBarPosition = "垂直滚动条位置", VerticalScrollBarInset = "垂直滚动条嵌入",
    HorizontalScrollBarInset = "水平滚动条嵌入", ScrollingEnabled = "滚动启用",
    ElasticBehavior = "弹性行为", Tension = "张力", Circular = "循环", CurrentPage = "当前页",
    Part0 = "部件0", Part1 = "部件1", C0 = "C0", C1 = "C1", D = "距离",
    LowerAngle = "最小角度", UpperAngle = "最大角度", LimitsEnabled = "限制启用",
    MotorMaxAcceleration = "电机最大加速度", MotorMaxForce = "电机最大力",
    Speed = "速度", ServoMaxForce = "伺服最大力", TargetPosition = "目标位置",
    Restitution = "恢复", Stiffness = "刚度", Damping = "阻尼", MaxForce = "最大力",
    MaxTorque = "最大扭矩", MaxFrictionTorque = "最大摩擦力矩", Tolerance = "容差",
    Scope = "范围", Key = "键", DataStore = "数据存储", MaxItems = "最大项目数",
    ExclusiveStartKey = "独占起始键", Ascending = "升序", Filter = "过滤器",
    Limit = "限制", UpdateInterval = "更新间隔", CharacterAppearanceId = "外观ID",
    SandboxEnabled = "沙盒启用", Source = "源码", Disabled = "已禁用", LinkedSource = "链接源",
    RunContext = "运行上下文", Attributes = "属性", Tags = "标签",
    Face = "面", TopSurface = "顶面", BottomSurface = "底面", LeftSurface = "左面",
    RightSurface = "右面", FrontSurface = "前面", BackSurface = "后面",
    CastShadow = "投射阴影", ReceiveShadows = "接收阴影",
    Range = "范围", Angle = "角度", Shadows = "阴影",
    Rate = "速率", Lifetime = "生命周期", SpreadAngle = "扩散角度", RotSpeed = "旋转速度",
    Min = "最小值", Max = "最大值", Increment = "增量",
    DecalTexture = "贴图", MeshType = "网格类型",
    BodyColors = "身体颜色", LeftArmColor = "左臂颜色", RightArmColor = "右臂颜色",
    LeftLegColor = "左腿颜色", RightLegColor = "右腿颜色", TorsoColor = "躯干颜色", HeadColor = "头部颜色",
    -- Player 特有
    UserId = "用户ID", AccountAge = "账号年龄", DisplayName = "显示名称", Character = "角色",
    DevEnableMouseLock = "鼠标锁定", DevComputerCameraMode = "电脑相机模式",
    DevTouchCameraMode = "触摸相机模式", DevComputerMovementMode = "电脑移动模式",
    DevTouchMovementMode = "触摸移动模式", AutoJumpEnabled = "自动跳跃",
    CameraMaxZoomDistance = "最大缩放距离", CameraMinZoomDistance = "最小缩放距离",
    CameraMode = "相机模式", CharacterWalkSpeed = "角色行走速度",
    CharacterJumpPower = "角色跳跃力", ReplicationFocus = "复制焦点",
    RespawnLocation = "重生位置", DevCameraOcclusionMode = "相机遮挡模式",
    HealthDisplayDistance = "生命显示距离", NameDisplayDistance = "名称显示距离",
    CanLoadCharacterAppearance = "可加载角色外观", GameplayPaused = "游戏暂停",
    FollowUserId = "关注用户ID", HasVerifiedBadge = "已验证徽章", MembershipType = "会员类型",
    Team = "队伍", IsLoaded = "已加载", OsPlatform = "操作系统", LocaleId = "区域语言",
}

local ClassCN = {
    Part = "部件", WedgePart = "楔形部件", CornerWedgePart = "角楔部件",
    TrussPart = "桁架", MeshPart = "网格部件", UnionOperation = "联合体",
    Model = "模型", Folder = "文件夹", Script = "脚本", LocalScript = "本地脚本",
    ModuleScript = "模块脚本", ScreenGui = "界面", SurfaceGui = "表面界面",
    BillboardGui = "公告板界面", Frame = "框架", TextLabel = "文本标签",
    TextButton = "文本按钮", ImageLabel = "图像标签", ImageButton = "图像按钮",
    ScrollingFrame = "滚动框", ViewportFrame = "视口框", VideoFrame = "视频框",
    Sound = "声音", Animation = "动画", AnimationController = "动画控制器",
    Humanoid = "人形", HumanoidDescription = "人形描述",
    Tool = "工具", HopperBin = "工具包", Backpack = "背包",
    Camera = "相机", Lighting = "光照", Workspace = "工作区",
    ReplicatedStorage = "复制存储", ServerStorage = "服务器存储",
    StarterGui = "初始界面", StarterPack = "初始背包",
    StarterPlayer = "初始玩家", Players = "玩家服务",
    RunService = "运行服务", UserInputService = "用户输入服务",
    ContextActionService = "上下文动作服务", TweenService = "补间服务",
    HttpService = "网络服务", TeleportService = "传送服务",
    MarketplaceService = "市场服务", MessagingService = "消息服务",
    DataStoreService = "数据存储服务", PhysicsService = "物理服务",
    SoundService = "声音服务", Chat = "聊天服务",
    Debris = "碎片服务", Teams = "队伍服务", InsertService = "插入服务",
    BadgeService = "徽章服务", CollectionService = "集合服务",
    PathfindingService = "寻路服务", TextService = "文本服务",
    LocalizationService = "本地化服务", GuiService = "界面服务",
    Player = "玩家",
}

-- =================== 工具函数：剪贴板 & 写文件 ===================
local function getClipboardFunc()
    local funcs = {"setclipboard", "toclipboard", "Clipboard", "set_clipboard"}
    for _, name in pairs(funcs) do
        local ok, fn = pcall(function()
            return _G[name] or getfenv()[name]
        end)
        if ok and type(fn) == "function" then
            return fn
        end
    end
    if type(env) == "table" and type(env.setclipboard) == "function" then
        return env.setclipboard
    end
    return nil
end

local function getWriteFileFunc()
    local funcs = {"writefile", "write_file", "WriteFile"}
    for _, name in ipairs(funcs) do
        local ok, fn = pcall(function()
            return _G[name] or getfenv()[name]
        end)
        if ok and type(fn) == "function" then
            return fn
        end
    end
    return nil
end

local clipboardFn = getClipboardFunc()
local writefileFn = getWriteFileFunc()

local function toClipboard(text)
    if clipboardFn then
        local ok = pcall(clipboardFn, text)
        return ok
    else
        warn("[DexEnhance] 剪贴板内容:\n" .. text)
        return false
    end
end

-- 智能保存：大文本落盘，小文本走剪贴板
local function saveLargeText(text, btn, count, defaultLabel)
    local FILE_THRESHOLD = 300000 -- 300KB 以上直接写文件
    local saved = false

    if #text > FILE_THRESHOLD and writefileFn then
        local filename = "DexExport_" .. tostring(math.floor(tick())) .. ".txt"
        local fileOk = pcall(function()
            writefileFn(filename, text)
        end)
        if fileOk then
            btn.Text = "✓ 已存文件"
            -- 把文件名复制到剪贴板，方便用户定位
            if clipboardFn then
                pcall(clipboardFn, filename)
            end
            saved = true
        end
    end

    if not saved then
        -- 如果文本极大且没有 writefile，强制截断防止剪贴板崩溃
        if #text > FILE_THRESHOLD and not writefileFn then
            text = text:sub(1, FILE_THRESHOLD)
            btn.Text = "✓ 已截断"
            toClipboard(text)
        else
            local clipOk = toClipboard(text)
            btn.Text = clipOk and ("✓ " .. count .. "个") or "已输出"
        end
    end

    text = nil
    task.delay(1.5, function() btn.Text = defaultLabel end)
end

_G.DexTranslate = false

-- =================== 核心：获取对象全部属性名 ===================
local function getAllPropNames(obj)
    local names = {}
    local seen = {}

    -- 1. getproperties() (执行器API，通常最完整)
    pcall(function()
        local props = getproperties(obj)
        if type(props) == "table" then
            for _, name in ipairs(props) do
                if type(name) == "string" and not seen[name] then
                    seen[name] = true
                    table.insert(names, name)
                end
            end
        end
    end)

    -- 2. Dex Properties 模块（同时兼容数组/字典返回格式）
    if _G.DexProperties and _G.DexProperties.GetProps then
        pcall(function()
            local props = _G.DexProperties.GetProps(obj)
            if type(props) == "table" then
                for _, prop in ipairs(props) do
                    local name = type(prop) == "string" and prop or (type(prop) == "table" and prop.Name)
                    if type(name) == "string" and not seen[name] then
                        seen[name] = true
                        table.insert(names, name)
                    end
                end
                for key, prop in pairs(props) do
                    local name = type(key) == "string" and key or (type(prop) == "table" and prop.Name)
                    if type(name) == "string" and not seen[name] then
                        seen[name] = true
                        table.insert(names, name)
                    end
                end
            end
        end)
    end

    -- 3. 兜底：验证常用属性
    local fallback = {
        "Name","Parent","ClassName","Archivable",
        "Position","Rotation","Orientation","CFrame","Size","Scale",
        "Color","Color3","BrickColor","Material","Texture","Reflectance","Transparency",
        "Anchored","CanCollide","CanQuery","CanTouch","Locked","CastShadow","ReceiveShadows",
        "Mass","Density","Friction","Elasticity","FormFactor","Shape","MeshId","TextureID",
        "Velocity","RotVelocity","AssemblyLinearVelocity","AssemblyAngularVelocity",
        "CollisionGroupId","CustomPhysicalProperties","RootPriority",
        "Text","Font","FontFace","TextSize","TextColor3","TextTransparency","TextStrokeColor3",
        "TextStrokeTransparency","TextScaled","TextWrapped","TextTruncate","TextXAlignment","TextYAlignment",
        "RichText","LineHeight","MaxVisibleGraphemes",
        "Image","ImageColor3","ImageTransparency","ImageRectOffset","ImageRectSize",
        "SliceCenter","SliceScale","AutoButtonColor","Modal","Selected","Selectable","Style",
        "LayoutOrder","ZIndex","ZIndexBehavior","ClipsDescendants","AutoLocalize","IgnoreGuiInset",
        "ResetOnSpawn","DisplayOrder","ScreenOrientation",
        "BackgroundColor3","BackgroundTransparency","BorderColor3","BorderSizePixel","BorderMode",
        "Active","AnchorPoint","AutomaticSize","Draggable","Rotation","Visible",
        "AbsolutePosition","AbsoluteSize","AbsoluteRotation","AbsoluteContentSize",
        "SoundId","Volume","PlaybackSpeed","Pitch","Looped","Playing","TimePosition","TimeLength",
        "IsPlaying","RollOffMode","RollOffMaxDistance","RollOffMinDistance",
        "Brightness","ColorShift_Top","ColorShift_Bottom","Ambient","OutdoorAmbient","TimeOfDay",
        "GeographicLatitude","FogColor","FogStart","FogEnd",
        "CameraType","FieldOfView","Focus","HeadLocked","HeadScale",
        "ViewportSize","CurrentCamera",
        "Health","MaxHealth","WalkSpeed","JumpPower","HipHeight","AutoRotate","Sit","PlatformStand",
        "UserId","AccountAge","DisplayName","Character","CharacterAppearanceId","Team",
        "DevEnableMouseLock","DevComputerCameraMode","DevTouchCameraMode",
        "DevComputerMovementMode","DevTouchMovementMode","AutoJumpEnabled",
        "CameraMaxZoomDistance","CameraMinZoomDistance","CameraMode",
        "CharacterWalkSpeed","CharacterJumpPower","ReplicationFocus","RespawnLocation",
        "DevCameraOcclusionMode","HealthDisplayDistance","NameDisplayDistance",
        "CanLoadCharacterAppearance","GameplayPaused",
        "FollowUserId","HasVerifiedBadge","MembershipType","IsLoaded","OsPlatform","LocaleId",
        "Value","Adornee","AlwaysOnTop","SizeOffset","StudsOffset","StudsOffsetWorldSpace",
        "PlayerToHideFrom","TeamColor","Neutral","WalkDirection","Jump","MoveDirection",
        "MouseBehavior","MouseIconEnabled","UserInputType","KeyCode","Delta",
        "Hit","Target","TargetSurface","ToolTip","RequiresHandle","CanBeDropped",
        "ManualActivationOnly","Grip","GripPos","LeftGripAttachment","RightGripAttachment",
        "PrimaryPart","PivotOffset","WorldPivot","StreamingMode","StreamingEnabled",
        "Gravity","FallenPartsDestroyHeight","RenderingParams","Priority","AnimationId",
        "EasingDirection","EasingStyle","Time","DelayTime","RepeatCount","Reverses",
        "Offset","DampingRatio","Frequency","AspectRatio","AspectType","DominantAxis",
        "CellPadding","CellSize","FillDirection","FillDirectionMaxCells","SortOrder",
        "Padding","HorizontalAlignment","VerticalAlignment",
        "MinTextSize","MaxTextSize","TweenTime","MaxSize","MinSize",
        "PaddingBottom","PaddingLeft","PaddingRight","PaddingTop",
        "ApplyStrokeMode","LineJoinMode","Thickness","CornerRadius","SweepAngle","Clockwise",
        "Content","ReferenceImage","TileSize","SpriteOffset","SpriteSize",
        "CanvasSize","CanvasPosition","AutomaticCanvasSize","ScrollingDirection",
        "ScrollBarImageColor3","ScrollBarImageTransparency","ScrollBarThickness",
        "MidImage","TopImage","BottomImage","VerticalScrollBarPosition",
        "VerticalScrollBarInset","HorizontalScrollBarInset","ScrollingEnabled",
        "ElasticBehavior","Tension","Circular","CurrentPage",
        "Part0","Part1","C0","C1","D","LowerAngle","UpperAngle","LimitsEnabled",
        "MotorMaxAcceleration","MotorMaxForce","Speed","ServoMaxForce","TargetPosition",
        "Restitution","Stiffness","Damping","MaxForce","MaxTorque","MaxFrictionTorque","Tolerance",
        "Scope","Key","DataStore","MaxItems","ExclusiveStartKey","Ascending","Filter","Limit","UpdateInterval",
        "SandboxEnabled","Source","Disabled","LinkedSource","RunContext","Attributes","Tags",
        "Face","TopSurface","BottomSurface","LeftSurface","RightSurface","FrontSurface","BackSurface",
        "Range","Angle","Shadows","Rate","Lifetime","SpreadAngle","RotSpeed","Min","Max","Increment",
        "DecalTexture","MeshType","BodyColors","LeftArmColor","RightArmColor","LeftLegColor","RightLegColor","TorsoColor","HeadColor",
    }
    for _, name in ipairs(fallback) do
        if not seen[name] then
            local ok = pcall(function() return obj[name] end)
            if ok then
                seen[name] = true
                table.insert(names, name)
            end
        end
    end

    return names
end

-- =================== 查找 Dex 内部 API（获取真实分类） ===================
local DexAPI = nil
local function findDexAPI()
    if DexAPI then return DexAPI end
    for _, v in pairs(getgc(true)) do
        if type(v) == "table" then
            local catOrder = rawget(v, "CategoryOrder")
            local classes = rawget(v, "Classes")
            if catOrder and classes and type(classes) == "table" then
                local basePart = classes["BasePart"]
                if basePart and type(basePart) == "table" and basePart.Properties then
                    DexAPI = v
                    return DexAPI
                end
            end
        end
    end
    return nil
end

-- =================== 分类（对齐 Dex 原生面板） ===================
local function getCategory(name, objClass)
    -- 1. 优先从 Dex API 获取真实分类
    if objClass then
        local api = findDexAPI()
        if api and api.Classes then
            local classData = api.Classes[objClass]
            while classData do
                local props = classData.Properties
                if props then
                    for i = 1, #props do
                        if props[i].Name == name then
                            local cat = props[i].Category
                            if cat then return cat end
                        end
                    end
                end
                classData = api.Classes[classData.Superclass]
            end
        end
    end

    -- 2. 回退到启发式分类（基于 Roblox RMD 规则与 Dex 实际表现）

    -- Team: 队伍（最优先，避免 TeamColor 被 Appearance 截胡）
    if name == "Team" or name == "TeamColor" or name == "Neutral" then
        return "Team"
    end

    -- Transform: 空间变换（Dex/Studio 中独立于 Physics）
    if name == "Position" or name == "Rotation" or name == "Orientation"
       or name == "CFrame" or name == "Size" or name == "Scale"
       or name == "PivotOffset" or name == "WorldPivot"
       or name == "PrimaryPart" then
        return "Transform"
    end

    -- Behavior: 行为与状态（含碰撞开关、可见性、存档等）
    if name == "Archivable" or name == "CanLoadCharacterAppearance"
       or name == "GameplayPaused" or name == "AutoRotate" or name == "Sit"
       or name == "PlatformStand" or name == "Health" or name == "MaxHealth"
       or name == "WalkSpeed" or name == "JumpPower" or name == "HipHeight"
       or name == "Anchored" or name == "CanCollide" or name == "CanQuery"
       or name == "CanTouch" or name == "Locked"
       or name == "Visible" or name == "Enabled"
       or name == "CastShadow" or name == "ReceiveShadows"
       or name == "StreamingMode" or name == "StreamingEnabled"
       or name == "AutoJumpEnabled"
       or name == "SandboxEnabled" or name == "Disabled"
       or name == "ManualActivationOnly" or name == "RequiresHandle"
       or name == "CanBeDropped" or name == "Looped" or name == "Playing" then
        return "Behavior"
    end

    -- Camera: 相机与视角
    if name == "CameraMaxZoomDistance" or name == "CameraMinZoomDistance"
       or name == "CameraMode" or name == "DevCameraOcclusionMode"
       or name == "DevComputerCameraMode" or name == "DevTouchCameraMode"
       or name == "DevEnableMouseLock" or name == "FieldOfView"
       or name == "Focus" or name == "HeadLocked" or name == "HeadScale"
       or name == "ViewportSize" or name == "CurrentCamera"
       or name == "CameraType" then
        return "Camera"
    end

    -- Control: 输入与移动控制
    if name == "DevComputerMovementMode" or name == "DevTouchMovementMode"
       or name == "MouseBehavior" or name == "MouseIconEnabled"
       or name == "WalkDirection" or name == "MoveDirection" or name == "Jump"
       or name == "HealthDisplayDistance" or name == "NameDisplayDistance" then
        return "Control"
    end

    -- Physics: 物理属性（不含空间变换）
    if name == "Velocity" or name == "RotVelocity"
       or name == "AssemblyLinearVelocity" or name == "AssemblyAngularVelocity"
       or name == "Mass" or name == "Density" or name == "Friction"
       or name == "Elasticity" or name == "FormFactor" or name == "Shape"
       or name == "Gravity" or name == "FallenPartsDestroyHeight"
       or name == "CollisionGroupId" or name == "CustomPhysicalProperties"
       or name == "RootPriority" then
        return "Physics"
    end

    -- Appearance: 外观材质（严格排除 GUI 颜色/文本相关）
    if (name == "Color" or name == "Color3" or name == "BrickColor"
       or name == "Material" or name == "Texture" or name == "Reflectance"
       or name == "Transparency" or name == "MeshId" or name == "TextureID"
       or name == "DecalTexture" or name == "MeshType"
       or name == "BodyColors" or name == "LeftArmColor" or name == "RightArmColor"
       or name == "LeftLegColor" or name == "RightLegColor"
       or name == "TorsoColor" or name == "HeadColor"
       or name:match("Color$"))
       and not name:match("^Text") and not name:match("^Background")
       and not name:match("^Border") and not name:match("^Image")
       and not name:match("^ScrollBar") then
        return "Appearance"
    end

    -- GUI: 界面相关
    if name == "Active" or name == "AnchorPoint" or name == "AutomaticSize"
       or name == "ClipsDescendants" or name == "Draggable"
       or name == "LayoutOrder" or name == "ZIndex" or name == "ZIndexBehavior"
       or name == "ResetOnSpawn" or name == "DisplayOrder" or name == "ScreenOrientation"
       or name == "IgnoreGuiInset" or name == "AutoLocalize" or name == "Modal"
       or name == "Selectable" or name == "Selected" or name == "Style"
       or name == "AutoButtonColor" or name == "SliceCenter" or name == "SliceScale"
       or name:match("^Text") or name:match("^Font") or name:match("^Image")
       or name:match("^Background") or name:match("^Border") or name:match("^Layout")
       or name:match("^Padding") or name:match("^Canvas") or name:match("^Scroll")
       or name:match("^Absolute") or name:match("^Horizontal") or name:match("^Vertical")
       or name == "AspectRatio" or name == "AspectType" or name == "DominantAxis"
       or name == "CellPadding" or name == "CellSize" or name == "FillDirection"
       or name == "FillDirectionMaxCells" or name == "SortOrder"
       or name == "MinTextSize" or name == "MaxTextSize" or name == "TweenTime"
       or name == "MaxSize" or name == "MinSize"
       or name == "ApplyStrokeMode" or name == "LineJoinMode" or name == "Thickness"
       or name == "CornerRadius" or name == "SweepAngle" or name == "Clockwise"
       or name == "Content" or name == "ReferenceImage" or name == "TileSize"
       or name == "SpriteOffset" or name == "SpriteSize"
       or name == "ElasticBehavior" or name == "Tension" or name == "Circular"
       or name == "CurrentPage" then
        return "GUI"
    end

    -- Sound: 音频
    if name == "SoundId" or name == "Volume" or name == "PlaybackSpeed"
       or name == "Pitch" or name == "Looped" or name == "Playing"
       or name == "TimePosition" or name == "TimeLength" or name == "IsPlaying"
       or name == "RollOffMode" or name == "RollOffMaxDistance"
       or name == "RollOffMinDistance" then
        return "Sound"
    end

    -- Lighting: 光照
    if name == "Brightness" or name == "ColorShift_Top" or name == "ColorShift_Bottom"
       or name == "Ambient" or name == "OutdoorAmbient" or name == "TimeOfDay"
       or name == "GeographicLatitude" or name == "FogColor"
       or name == "FogStart" or name == "FogEnd" then
        return "Lighting"
    end

    -- Part: 关节与约束
    if name == "Part0" or name == "Part1" or name == "C0" or name == "C1"
       or name == "D" or name == "LowerAngle" or name == "UpperAngle"
       or name == "LimitsEnabled" or name == "MotorMaxAcceleration"
       or name == "MotorMaxForce" or name == "Speed" or name == "ServoMaxForce"
       or name == "TargetPosition" or name == "Restitution" or name == "Stiffness"
       or name == "Damping" or name == "MaxForce" or name == "MaxTorque"
       or name == "MaxFrictionTorque" or name == "Tolerance" then
        return "Part"
    end

    -- Surface Inputs: 表面（Dex 原生叫 Surface Inputs）
    if name == "Face" or name == "TopSurface" or name == "BottomSurface"
       or name == "LeftSurface" or name == "RightSurface"
       or name == "FrontSurface" or name == "BackSurface" then
        return "Surface Inputs"
    end

    -- Particle: 粒子
    if name == "Rate" or name == "Lifetime" or name == "SpreadAngle"
       or name == "RotSpeed" or name == "Range" or name == "Angle" or name == "Shadows" then
        return "Particle"
    end

    -- Value: 数值对象
    if name == "Value" or name == "Min" or name == "Max" or name == "Increment" then
        return "Value"
    end

    -- 默认 Data（与 Dex 原生面板保持一致）
    return "Data"
end

-- =================== 核心：按分类获取属性 ===================
local function getCategorizedProps(obj)
    local categories = {}

    local allProps = {}
    local propNames = getAllPropNames(obj)
    local objClass = nil
    pcall(function() objClass = obj.ClassName end)

    for _, name in ipairs(propNames) do
        local ok, val = pcall(function() return obj[name] end)
        if ok then
            allProps[name] = val
        end
    end

    -- 提取 Attributes
    local attrs = {}
    pcall(function()
        for name, val in pairs(obj:GetAttributes()) do
            attrs[name] = val
            allProps[name] = nil
        end
    end)
    if next(attrs) then
        categories["Attributes"] = attrs
    end

    -- 提取 Tags
    local tags = {}
    pcall(function()
        for _, tag in ipairs(obj:GetTags()) do
            tags[tag] = true
        end
    end)
    if next(tags) then
        categories["Tags"] = tags
    end

    -- 全部走启发式分类（默认 Data，不会再有漂浮属性）
    for name, val in pairs(allProps) do
        local cat = getCategory(name, objClass)
        if not categories[cat] then
            categories[cat] = {}
        end
        categories[cat][name] = val
    end

    return categories
end

-- =================== 格式化属性值 ===================
local function formatPropValue(val)
    local t = type(val)
    if t == "boolean" then
        return val and "[✓]" or "[ ]"
    elseif t == "number" then
        if val == math.floor(val) then
            return tostring(math.floor(val))
        else
            return tostring(val)
        end
    elseif t == "string" then
        if #val > 120 then
            return val:sub(1, 120) .. "..."
        end
        return val
    elseif t == "nil" then
        return "nil"
    elseif typeof(val) == "EnumItem" then
        return val.Name
    elseif typeof(val) == "BrickColor" then
        return val.Name
    elseif typeof(val) == "Color3" then
        return string.format("RGB(%d,%d,%d)", math.floor(val.R*255), math.floor(val.G*255), math.floor(val.B*255))
    elseif typeof(val) == "Vector3" then
        return string.format("(%.2f, %.2f, %.2f)", val.X, val.Y, val.Z)
    elseif typeof(val) == "Vector2" then
        return string.format("(%.2f, %.2f)", val.X, val.Y)
    elseif typeof(val) == "CFrame" then
        local pos = val.Position
        return string.format("Pos(%.2f, %.2f, %.2f)", pos.X, pos.Y, pos.Z)
    elseif typeof(val) == "UDim" then
        return string.format("Scale:%.3f Offset:%d", val.Scale, val.Offset)
    elseif typeof(val) == "UDim2" then
        return string.format("X{%s} Y{%s}", tostring(val.X), tostring(val.Y))
    elseif typeof(val) == "Rect" then
        return string.format("(%.1f,%.1f,%.1f,%.1f)", val.Min.X, val.Min.Y, val.Max.X, val.Max.Y)
    else
        local s = tostring(val)
        if #s > 120 then s = s:sub(1, 120) .. "..." end
        return s
    end
end

-- =================== 分类显示顺序（与 Dex 原生面板对齐） ===================
local CAT_ORDER = {
    "Transform", "Data", "Behavior", "Camera", "Control", "Team",
    "Replication", "Physics", "Appearance", "GUI",
    "Sound", "Lighting", "Part", "Surface Inputs", "Particle", "Value",
    "Attributes", "Tags", "Other"
}

-- =================== 构建复制文本 ===================
local function buildPropText(obj, objName, objClass)
    local categories = getCategorizedProps(obj)
    local lines = {}
    table.insert(lines, "对象: " .. tostring(objName) .. "  |  类: " .. tostring(objClass))
    table.insert(lines, string.rep("=", 52))

    local printed = {}

    for _, cat in ipairs(CAT_ORDER) do
        local props = categories[cat]
        if props and next(props) then
            table.insert(lines, "")
            table.insert(lines, "▼ " .. cat)
            local sortedNames = {}
            for name in pairs(props) do
                table.insert(sortedNames, name)
            end
            table.sort(sortedNames)
            for _, name in ipairs(sortedNames) do
                local val = props[name]
                local displayName = _G.DexTranslate and (PropCN[name] or name) or name
                local valStr = formatPropValue(val)
                table.insert(lines, "    " .. displayName .. ": " .. valStr)
            end
            printed[cat] = true
        end
    end

    for cat, props in pairs(categories) do
        if not printed[cat] and next(props) then
            table.insert(lines, "")
            table.insert(lines, "▼ " .. cat)
            local sortedNames = {}
            for name in pairs(props) do
                table.insert(sortedNames, name)
            end
            table.sort(sortedNames)
            for _, name in ipairs(sortedNames) do
                local val = props[name]
                local displayName = _G.DexTranslate and (PropCN[name] or name) or name
                local valStr = formatPropValue(val)
                table.insert(lines, "    " .. displayName .. ": " .. valStr)
            end
        end
    end

    return table.concat(lines, "\n")
end

task.defer(function()
    local CoreGui = game:GetService("CoreGui")
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    local UserInputService = game:GetService("UserInputService")
    local RunService = game:GetService("RunService")

    local sg = Instance.new("ScreenGui")
    sg.Name = "DexEnhanceFloat"
    sg.ResetOnSpawn = false
    sg.DisplayOrder = 10000

    pcall(function()
        sg.Parent = CoreGui
    end)
    if not sg.Parent then
        sg.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end

    -- =================== 主窗口加高到 132，容纳新按钮 ===================
    local main = Instance.new("Frame")
    main.Name = "Main"
    main.Size = UDim2.new(0, 160, 0, 132)
    main.Position = UDim2.new(0.5, -80, 0, 10)
    main.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    main.BorderColor3 = Color3.fromRGB(80, 80, 80)
    main.BorderSizePixel = 1
    main.Active = true
    main.Parent = sg

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = main

    local titleBar = Instance.new("Frame")
    titleBar.Size = UDim2.new(1, 0, 0, 22)
    titleBar.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    titleBar.BorderSizePixel = 0
    titleBar.Active = true
    titleBar.Parent = main

    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 6)
    titleCorner.Parent = titleBar

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -110, 1, 0)
    title.Position = UDim2.new(0, 5, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "Dex 增强"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.Font = Enum.Font.SourceSansBold
    title.TextSize = 13
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = titleBar

    local watermark = Instance.new("TextLabel")
    watermark.Size = UDim2.new(0, 75, 1, 0)
    watermark.Position = UDim2.new(1, -95, 0, 0)
    watermark.BackgroundTransparency = 1
    watermark.Text = "星神3756288324优化"
    watermark.TextColor3 = Color3.fromRGB(180, 180, 180)
    watermark.Font = Enum.Font.SourceSans
    watermark.TextSize = 10
    watermark.TextXAlignment = Enum.TextXAlignment.Right
    watermark.Parent = titleBar

    local minimizeBtn = Instance.new("TextButton")
    minimizeBtn.Size = UDim2.new(0, 20, 0, 20)
    minimizeBtn.Position = UDim2.new(1, -20, 0, 1)
    minimizeBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
    minimizeBtn.BorderColor3 = Color3.fromRGB(120, 120, 120)
    minimizeBtn.BorderSizePixel = 1
    minimizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    minimizeBtn.Font = Enum.Font.SourceSansBold
    minimizeBtn.TextSize = 14
    minimizeBtn.Text = "—"
    minimizeBtn.Parent = titleBar

    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 4)
    btnCorner.Parent = minimizeBtn

    -- =================== 五角星悬浮窗 ===================
    local starButton = Instance.new("TextButton")
    starButton.Name = "StarFloat"
    starButton.Size = UDim2.new(0, 38, 0, 38)
    starButton.Position = UDim2.new(0.5, -19, 0, 10)
    starButton.AnchorPoint = Vector2.new(0.5, 0.5)
    starButton.BackgroundTransparency = 1
    starButton.Text = "★"
    starButton.Font = Enum.Font.SourceSansBold
    starButton.TextSize = 34
    starButton.TextColor3 = Color3.fromRGB(255, 0, 0)
    starButton.TextStrokeTransparency = 0.7
    starButton.TextStrokeColor3 = Color3.fromRGB(20, 20, 20)
    starButton.Visible = false
    starButton.Parent = sg

    local starRotation = 0
    local hue = 0
    RunService.Heartbeat:Connect(function(dt)
        if starButton.Visible and starButton.Parent then
            starRotation = (starRotation + dt * 144) % 360
            starButton.Rotation = starRotation
            hue = (hue + dt * 0.6) % 1
            starButton.TextColor3 = Color3.fromHSV(hue, 1, 1)
        end
    end)

    local minimized = false

    minimizeBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        if minimized then
            local absPos = main.AbsolutePosition
            local absSize = main.AbsoluteSize
            starButton.Position = UDim2.new(0, absPos.X + absSize.X/2, 0, absPos.Y + absSize.Y/2)
            main.Visible = false
            starButton.Visible = true
        else
            main.Visible = true
            starButton.Visible = false
        end
    end)

    starButton.MouseButton1Click:Connect(function()
        minimized = false
        local starAbsPos = starButton.AbsolutePosition
        local starAbsSize = starButton.AbsoluteSize
        main.Position = UDim2.new(
            0, starAbsPos.X + starAbsSize.X/2 - main.Size.X.Offset/2,
            0, starAbsPos.Y + starAbsSize.Y/2 - main.Size.Y.Offset/2
        )
        main.Visible = true
        starButton.Visible = false
    end)

    -- =================== 按钮创建（高度微调以容纳第五行） ===================
    local copyTreeBtn = Instance.new("TextButton")
    copyTreeBtn.Size = UDim2.new(0, 45, 0, 28)
    copyTreeBtn.Position = UDim2.new(0, 4, 0, 28)
    copyTreeBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 180)
    copyTreeBtn.BorderColor3 = Color3.fromRGB(0, 150, 255)
    copyTreeBtn.BorderSizePixel = 1
    copyTreeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    copyTreeBtn.Font = Enum.Font.SourceSansBold
    copyTreeBtn.TextSize = 11
    copyTreeBtn.Text = "复制树"
    copyTreeBtn.Parent = main
    Instance.new("UICorner", copyTreeBtn).CornerRadius = UDim.new(0, 4)

    local copyPropsBtn = Instance.new("TextButton")
    copyPropsBtn.Size = UDim2.new(0, 45, 0, 28)
    copyPropsBtn.Position = UDim2.new(0, 53, 0, 28)
    copyPropsBtn.BackgroundColor3 = Color3.fromRGB(0, 140, 60)
    copyPropsBtn.BorderColor3 = Color3.fromRGB(0, 200, 80)
    copyPropsBtn.BorderSizePixel = 1
    copyPropsBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    copyPropsBtn.Font = Enum.Font.SourceSansBold
    copyPropsBtn.TextSize = 11
    copyPropsBtn.Text = "复制属性"
    copyPropsBtn.Parent = main
    Instance.new("UICorner", copyPropsBtn).CornerRadius = UDim.new(0, 4)

    local translateToggleBtn = Instance.new("TextButton")
    translateToggleBtn.Size = UDim2.new(0, 45, 0, 28)
    translateToggleBtn.Position = UDim2.new(0, 102, 0, 28)
    translateToggleBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
    translateToggleBtn.BorderColor3 = Color3.fromRGB(120, 120, 120)
    translateToggleBtn.BorderSizePixel = 1
    translateToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    translateToggleBtn.Font = Enum.Font.SourceSansBold
    translateToggleBtn.TextSize = 11
    translateToggleBtn.Text = "汉译:关"
    translateToggleBtn.Parent = main
    Instance.new("UICorner", translateToggleBtn).CornerRadius = UDim.new(0, 4)

    local viewPropsBtn = Instance.new("TextButton")
    viewPropsBtn.Size = UDim2.new(0, 152, 0, 26)
    viewPropsBtn.Position = UDim2.new(0, 4, 0, 60)
    viewPropsBtn.BackgroundColor3 = Color3.fromRGB(120, 60, 120)
    viewPropsBtn.BorderColor3 = Color3.fromRGB(180, 100, 180)
    viewPropsBtn.BorderSizePixel = 1
    viewPropsBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    viewPropsBtn.Font = Enum.Font.SourceSansBold
    viewPropsBtn.TextSize = 12
    viewPropsBtn.Text = "查看全部属性"
    viewPropsBtn.Parent = main
    Instance.new("UICorner", viewPropsBtn).CornerRadius = UDim.new(0, 4)

    -- =================== 新增：一键复制整个世界树 ===================
    local copyWorldBtn = Instance.new("TextButton")
    copyWorldBtn.Size = UDim2.new(0, 152, 0, 26)
    copyWorldBtn.Position = UDim2.new(0, 4, 0, 90)
    copyWorldBtn.BackgroundColor3 = Color3.fromRGB(180, 100, 0)
    copyWorldBtn.BorderColor3 = Color3.fromRGB(255, 160, 40)
    copyWorldBtn.BorderSizePixel = 1
    copyWorldBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    copyWorldBtn.Font = Enum.Font.SourceSansBold
    copyWorldBtn.TextSize = 12
    copyWorldBtn.Text = "复制世界树"
    copyWorldBtn.Parent = main
    Instance.new("UICorner", copyWorldBtn).CornerRadius = UDim.new(0, 4)

    -- =================== 拖动修复 ===================
    local dragging = false
    local dragStart, startPos
    local starDragging = false
    local starDragStart, starStartPos

    -- 新增 copyWorldBtn 到屏蔽列表
    local dragBlockButtons = {minimizeBtn, copyTreeBtn, copyPropsBtn, translateToggleBtn, viewPropsBtn, copyWorldBtn}

    UserInputService.InputBegan:Connect(function(input)
        if not main.Visible then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            local pos = input.Position
            local mainPos = main.AbsolutePosition
            local mainSize = main.AbsoluteSize

            if pos.X >= mainPos.X and pos.X <= mainPos.X + mainSize.X
               and pos.Y >= mainPos.Y and pos.Y <= mainPos.Y + mainSize.Y then

                local onButton = false
                for _, btn in ipairs(dragBlockButtons) do
                    if btn and btn.Parent then
                        local bPos = btn.AbsolutePosition
                        local bSize = btn.AbsoluteSize
                        if pos.X >= bPos.X and pos.X <= bPos.X + bSize.X
                           and pos.Y >= bPos.Y and pos.Y <= bPos.Y + bSize.Y then
                            onButton = true
                            break
                        end
                    end
                end

                if not onButton then
                    dragging = true
                    dragStart = input.Position
                    startPos = main.Position
                end
            end
        end
    end)

    starButton.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            starDragging = true
            starDragStart = input.Position
            starStartPos = starButton.Position
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
            starDragging = false
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
        if starDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - starDragStart
            starButton.Position = UDim2.new(starStartPos.X.Scale, starStartPos.X.Offset + delta.X, starStartPos.Y.Scale, starStartPos.Y.Offset + delta.Y)
        end
    end)

    -- 等待 Dex 模块
    local maxWait = 100
    local Explorer, Properties = nil, nil
    for i = 1, maxWait do
        Explorer = _G.DexExplorer
        Properties = _G.DexProperties
        if Explorer and Properties then
            break
        end
        task.wait(0.1)
    end

    if not Explorer then
        for _, v in pairs(getgc(true)) do
            if type(v) == "table" and rawget(v, "Selection") and rawget(v, "Refresh") then
                Explorer = v
                break
            end
        end
    end

    if not Properties then
        for _, v in pairs(getgc(true)) do
            if type(v) == "table" and rawget(v, "GetProps") and rawget(v, "Refresh") then
                Properties = v
                break
            end
        end
    end

    -- 汉译开关
    translateToggleBtn.MouseButton1Click:Connect(function()
        _G.DexTranslate = not _G.DexTranslate
        if _G.DexTranslate then
            translateToggleBtn.Text = "汉译:开"
            translateToggleBtn.BackgroundColor3 = Color3.fromRGB(180, 120, 0)
        else
            translateToggleBtn.Text = "汉译:关"
            translateToggleBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
        end
    end)

    -- =================== 复制树（分块缓冲 + 大文本落盘） ===================
    copyTreeBtn.MouseButton1Click:Connect(function()
        if not Explorer then
            copyTreeBtn.Text = "无模块"
            task.delay(1, function() copyTreeBtn.Text = "复制树" end)
            return
        end

        local sList = Explorer.Selection.List
        if #sList == 0 then
            toClipboard("未选中对象")
            copyTreeBtn.Text = "无选中"
            task.delay(0.8, function() copyTreeBtn.Text = "复制树" end)
            return
        end

        copyTreeBtn.Text = "遍历中..."
        task.spawn(function()
            local CHUNK_SIZE = 5000
            local chunks = {}
            local buffer = {}
            local bufIdx = 0

            local stackNode = {}
            local stackDepth = {}
            local top = 0
            for i = #sList, 1, -1 do
                local ok, node = pcall(function() return sList[i] end)
                if ok and node then
                    top = top + 1
                    stackNode[top] = node
                    stackDepth[top] = 0
                end
            end

            local count = 0
            local YIELD_EVERY = 200

            while top > 0 do
                local node = stackNode[top]
                local depth = stackDepth[top]
                top = top - 1

                local ok, obj = pcall(function() return node.Obj end)
                if ok and obj then
                    local ok2, name = pcall(function() return obj.Name end)
                    local ok3, className = pcall(function() return obj.ClassName end)
                    if not ok2 then name = "?" end
                    if not ok3 then className = "?" end

                    if _G.DexTranslate then
                        className = ClassCN[className] or className
                    end

                    count = count + 1
                    bufIdx = bufIdx + 1
                    buffer[bufIdx] = string.rep("  ", depth) .. name .. " [" .. className .. "]"

                    if count % CHUNK_SIZE == 0 then
                        table.insert(chunks, table.concat(buffer, "\n"))
                        buffer = {}
                        bufIdx = 0
                    end

                    if count % YIELD_EVERY == 0 then
                        copyTreeBtn.Text = "遍历中 " .. count
                        task.wait(0.05)
                    end
                end

                local ok4, childCount = pcall(function()
                    if type(node) ~= "table" then return 0 end
                    return #node
                end)
                if ok4 and childCount > 0 then
                    for i = childCount, 1, -1 do
                        local ok5, child = pcall(function() return node[i] end)
                        if ok5 and child then
                            top = top + 1
                            stackNode[top] = child
                            stackDepth[top] = depth + 1
                        end
                    end
                end
            end

            stackNode = nil
            stackDepth = nil

            if bufIdx > 0 then
                table.insert(chunks, table.concat(buffer, "\n"))
                buffer = nil
            end

            copyTreeBtn.Text = "拼接中..."
            task.wait(0.1)

            local ok, text = pcall(function()
                return table.concat(chunks, "\n")
            end)

            chunks = nil

            if not ok then
                copyTreeBtn.Text = "拼接失败"
                task.delay(1.5, function() copyTreeBtn.Text = "复制树" end)
                return
            end

            -- 大文本落盘，防止剪贴板 API 崩溃
            saveLargeText(text, copyTreeBtn, count, "复制树")
        end)
    end)

    -- 复制属性（分类版）
    copyPropsBtn.MouseButton1Click:Connect(function()
        if not Explorer then
            copyPropsBtn.Text = "无模块"
            task.delay(1, function() copyPropsBtn.Text = "复制属性" end)
            return
        end

        local sList = Explorer.Selection.List
        if #sList == 0 then
            toClipboard("未选中对象")
            copyPropsBtn.Text = "无选中"
            task.delay(0.8, function() copyPropsBtn.Text = "复制属性" end)
            return
        end

        local ok, obj = pcall(function() return sList[1].Obj end)
        if not ok or not obj then
            copyPropsBtn.Text = "错误"
            task.delay(0.8, function() copyPropsBtn.Text = "复制属性" end)
            return
        end

        local ok2, objName = pcall(function() return obj.Name end)
        local ok3, objClass = pcall(function() return obj.ClassName end)
        if not ok2 then objName = "?" end
        if not ok3 then objClass = "?" end

        if _G.DexTranslate then
            objClass = ClassCN[objClass] or objClass
        end

        local text = buildPropText(obj, objName, objClass)
        local ok = toClipboard(text)
        copyPropsBtn.Text = ok and "✓ 已复制" or "已输出"
        task.delay(1.2, function() copyPropsBtn.Text = "复制属性" end)
    end)

    -- =================== 复制世界树（分块缓冲 + 大文本落盘） ===================
    copyWorldBtn.MouseButton1Click:Connect(function()
        copyWorldBtn.Text = "遍历中..."
        task.spawn(function()
            local CHUNK_SIZE = 5000
            local chunks = {}
            local buffer = {}
            local bufIdx = 0

            local stackInst = {game}
            local stackDepth = {0}
            local top = 1

            local count = 0
            local YIELD_EVERY = 200

            while top > 0 do
                local inst = stackInst[top]
                local depth = stackDepth[top]
                top = top - 1

                if typeof(inst) == "Instance" then
                    local ok1, name = pcall(function() return inst.Name end)
                    local ok2, className = pcall(function() return inst.ClassName end)
                    if not ok1 then name = "?" end
                    if not ok2 then className = "?" end

                    if _G.DexTranslate then
                        className = ClassCN[className] or className
                    end

                    count = count + 1
                    bufIdx = bufIdx + 1
                    buffer[bufIdx] = string.rep("  ", depth) .. name .. " [" .. className .. "]"

                    if count % CHUNK_SIZE == 0 then
                        table.insert(chunks, table.concat(buffer, "\n"))
                        buffer = {}
                        bufIdx = 0
                        copyWorldBtn.Text = "遍历中 " .. count
                        task.wait(0.05)
                    elseif count % YIELD_EVERY == 0 then
                        copyWorldBtn.Text = "遍历中 " .. count
                        task.wait(0.05)
                    end

                    local ok3, children = pcall(function() return inst:GetChildren() end)
                    if ok3 and children then
                        local n = #children
                        for i = n, 1, -1 do
                            local child = children[i]
                            if typeof(child) == "Instance" then
                                top = top + 1
                                stackInst[top] = child
                                stackDepth[top] = depth + 1
                            end
                        end
                        children = nil
                    end
                end
            end

            stackInst = nil
            stackDepth = nil

            if bufIdx > 0 then
                table.insert(chunks, table.concat(buffer, "\n"))
                buffer = nil
            end

            copyWorldBtn.Text = "拼接中..."
            task.wait(0.1)

            local ok, text = pcall(function()
                return table.concat(chunks, "\n")
            end)

            chunks = nil

            if not ok then
                copyWorldBtn.Text = "拼接失败"
                task.delay(1.5, function() copyWorldBtn.Text = "复制世界树" end)
                return
            end

            -- 大文本落盘，防止剪贴板 API 崩溃
            saveLargeText(text, copyWorldBtn, count, "复制世界树")
        end)
    end)

    -- 查看全部属性窗口（分类版 + 5px 彩色边框拖动）
    viewPropsBtn.MouseButton1Click:Connect(function()
        if not Explorer then
            viewPropsBtn.Text = "无模块"
            task.delay(1, function() viewPropsBtn.Text = "查看全部属性" end)
            return
        end

        local sList = Explorer.Selection.List
        if #sList == 0 then
            viewPropsBtn.Text = "无选中"
            task.delay(0.8, function() viewPropsBtn.Text = "查看全部属性" end)
            return
        end

        local ok, obj = pcall(function() return sList[1].Obj end)
        if not ok or not obj then
            viewPropsBtn.Text = "错误"
            task.delay(0.8, function() viewPropsBtn.Text = "查看全部属性" end)
            return
        end

        local viewGui = Instance.new("ScreenGui")
        viewGui.Name = "DexPropViewer"
        viewGui.ResetOnSpawn = false
        viewGui.DisplayOrder = 10001
        pcall(function() viewGui.Parent = CoreGui end)
        if not viewGui.Parent then
            viewGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
        end

        -- =================== 外层：5px 彩色边框（拖动区域） ===================
        local outerFrame = Instance.new("Frame")
        outerFrame.Name = "ColorBorder"
        outerFrame.Size = UDim2.new(0, 350, 0, 450)
        outerFrame.Position = UDim2.new(0.5, -175, 0.5, -225)
        outerFrame.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
        outerFrame.BorderSizePixel = 0
        outerFrame.Active = true
        outerFrame.Parent = viewGui
        Instance.new("UICorner", outerFrame).CornerRadius = UDim.new(0, 8)

        -- 彩虹色流动动画
        task.spawn(function()
            local hue = 0
            while outerFrame and outerFrame.Parent do
                hue = (hue + 0.008) % 1
                outerFrame.BackgroundColor3 = Color3.fromHSV(hue, 0.75, 1)
                task.wait(0.04)
            end
        end)

        -- =================== 内层：实际内容窗口（内缩 5px） ===================
        local window = Instance.new("Frame")
        window.Name = "Content"
        window.Size = UDim2.new(1, -10, 1, -10)
        window.Position = UDim2.new(0, 5, 0, 5)
        window.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        window.BorderColor3 = Color3.fromRGB(80, 80, 80)
        window.BorderSizePixel = 1
        window.Active = true
        window.Parent = outerFrame
        Instance.new("UICorner", window).CornerRadius = UDim.new(0, 6)

        local winTitleBar = Instance.new("Frame")
        winTitleBar.Size = UDim2.new(1, 0, 0, 24)
        winTitleBar.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        winTitleBar.BorderSizePixel = 0
        winTitleBar.Active = true
        winTitleBar.Parent = window
        Instance.new("UICorner", winTitleBar).CornerRadius = UDim.new(0, 6)

        local winTitle = Instance.new("TextLabel")
        winTitle.Size = UDim2.new(1, -90, 1, 0)
        winTitle.Position = UDim2.new(0, 8, 0, 0)
        winTitle.BackgroundTransparency = 1
        winTitle.Text = "全部属性"
        winTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
        winTitle.Font = Enum.Font.SourceSansBold
        winTitle.TextSize = 13
        winTitle.TextXAlignment = Enum.TextXAlignment.Left
        winTitle.Parent = winTitleBar

        local wm = Instance.new("TextLabel")
        wm.Size = UDim2.new(0, 75, 1, 0)
        wm.Position = UDim2.new(1, -85, 0, 0)
        wm.BackgroundTransparency = 1
        wm.Text = "星神3756288324优化"
        wm.TextColor3 = Color3.fromRGB(160, 160, 160)
        wm.Font = Enum.Font.SourceSans
        wm.TextSize = 9
        wm.TextXAlignment = Enum.TextXAlignment.Right
        wm.Parent = winTitleBar

        local closeBtn = Instance.new("TextButton")
        closeBtn.Size = UDim2.new(0, 20, 0, 20)
        closeBtn.Position = UDim2.new(1, -22, 0, 2)
        closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        closeBtn.BorderSizePixel = 0
        closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        closeBtn.Font = Enum.Font.SourceSansBold
        closeBtn.TextSize = 14
        closeBtn.Text = "×"
        closeBtn.Parent = winTitleBar
        Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 4)
        closeBtn.MouseButton1Click:Connect(function()
            viewGui:Destroy()
        end)

        -- =================== 拖动逻辑（边框 + 标题栏） ===================
        local winDragging = false
        local winDragStart, winStartPos

        winTitleBar.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                winDragging = true
                winDragStart = input.Position
                winStartPos = outerFrame.Position
            end
        end)

        outerFrame.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                local pos = input.Position
                local contentPos = window.AbsolutePosition
                local contentSize = window.AbsoluteSize

                local insideContent = pos.X >= contentPos.X and pos.X <= contentPos.X + contentSize.X
                    and pos.Y >= contentPos.Y and pos.Y <= contentPos.Y + contentSize.Y

                if not insideContent then
                    winDragging = true
                    winDragStart = input.Position
                    winStartPos = outerFrame.Position
                end
            end
        end)

        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                winDragging = false
            end
        end)

        UserInputService.InputChanged:Connect(function(input)
            if winDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                local delta = input.Position - winDragStart
                outerFrame.Position = UDim2.new(
                    winStartPos.X.Scale, winStartPos.X.Offset + delta.X,
                    winStartPos.Y.Scale, winStartPos.Y.Offset + delta.Y
                )
            end
        end)

        -- =================== 属性列表 ===================
        local scroll = Instance.new("ScrollingFrame")
        scroll.Size = UDim2.new(1, -8, 1, -32)
        scroll.Position = UDim2.new(0, 4, 0, 28)
        scroll.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        scroll.BorderSizePixel = 0
        scroll.ScrollBarThickness = 6
        scroll.Parent = window
        local layout = Instance.new("UIListLayout", scroll)
        layout.Padding = UDim.new(0, 2)

        local categories = getCategorizedProps(obj)
        local printed = {}
        local yCount = 0

        local function addCategoryHeader(catName)
            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(1, -4, 0, 22)
            frame.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
            frame.BorderSizePixel = 0
            frame.Parent = scroll

            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1, -8, 1, 0)
            label.Position = UDim2.new(0, 6, 0, 0)
            label.BackgroundTransparency = 1
            label.Text = "▼ " .. catName
            label.TextColor3 = Color3.fromRGB(255, 255, 255)
            label.Font = Enum.Font.SourceSansBold
            label.TextSize = 12
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.Parent = frame
            yCount = yCount + 1
        end

        local function addPropRow(name, val)
            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(1, -4, 0, 26)
            frame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
            frame.BorderSizePixel = 0
            frame.Parent = scroll

            local displayName = _G.DexTranslate and (PropCN[name] or name) or name
            local valStr = formatPropValue(val)
            local valColor = Color3.fromRGB(255, 255, 255)

            if type(val) == "boolean" then
                valColor = val and Color3.fromRGB(0, 255, 100) or Color3.fromRGB(255, 80, 80)
            end

            local nameLabel = Instance.new("TextLabel")
            nameLabel.Size = UDim2.new(0, 140, 1, 0)
            nameLabel.Position = UDim2.new(0, 6, 0, 0)
            nameLabel.BackgroundTransparency = 1
            nameLabel.Text = displayName
            nameLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
            nameLabel.Font = Enum.Font.SourceSans
            nameLabel.TextSize = 11
            nameLabel.TextXAlignment = Enum.TextXAlignment.Left
            nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
            nameLabel.Parent = frame

            local valLabel = Instance.new("TextLabel")
            valLabel.Size = UDim2.new(1, -150, 1, 0)
            valLabel.Position = UDim2.new(0, 150, 0, 0)
            valLabel.BackgroundTransparency = 1
            valLabel.Text = valStr
            valLabel.TextColor3 = valColor
            valLabel.Font = Enum.Font.SourceSans
            valLabel.TextSize = 11
            valLabel.TextXAlignment = Enum.TextXAlignment.Left
            valLabel.TextTruncate = Enum.TextTruncate.AtEnd
            valLabel.Parent = frame
            yCount = yCount + 1
        end

        for _, cat in ipairs(CAT_ORDER) do
            local props = categories[cat]
            if props and next(props) then
                addCategoryHeader(cat)
                local sortedNames = {}
                for name in pairs(props) do
                    table.insert(sortedNames, name)
                end
                table.sort(sortedNames)
                for _, name in ipairs(sortedNames) do
                    addPropRow(name, props[name])
                end
                printed[cat] = true
            end
        end

        for cat, props in pairs(categories) do
            if not printed[cat] and next(props) then
                addCategoryHeader(cat)
                local sortedNames = {}
                for name in pairs(props) do
                    table.insert(sortedNames, name)
                end
                table.sort(sortedNames)
                for _, name in ipairs(sortedNames) do
                    addPropRow(name, props[name])
                end
            end
        end

        scroll.CanvasSize = UDim2.new(0, 0, 0, yCount * 28 + 10)
    end)

    -- =================== 给 Dex 原生窗口加 5px 彩色边框（不改 Parent，安全同步） ===================
    local function addColorBorderToWindow(tabFrame)
        if not tabFrame or tabFrame:FindFirstChild("ColorBorderSync") then return end

        local parent = tabFrame.Parent
        local outer = Instance.new("Frame")
        outer.Name = "ColorBorderSync"
        outer.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
        outer.BorderSizePixel = 0
        outer.Active = true
        outer.Parent = parent

        local origZIndex = tabFrame.ZIndex
        tabFrame.ZIndex = origZIndex + 1
        outer.ZIndex = origZIndex

        task.spawn(function()
            local hue = 0
            while outer and outer.Parent do
                hue = (hue + 0.008) % 1
                outer.BackgroundColor3 = Color3.fromHSV(hue, 0.75, 1)
                task.wait(0.04)
            end
        end)

        local syncConn
        syncConn = RunService.Heartbeat:Connect(function()
            if not outer or not outer.Parent then
                syncConn:Disconnect()
                return
            end
            if not tabFrame or not tabFrame.Parent then
                outer:Destroy()
                syncConn:Disconnect()
                return
            end

            outer.Position = UDim2.new(
                tabFrame.Position.X.Scale, tabFrame.Position.X.Offset - 5,
                tabFrame.Position.Y.Scale, tabFrame.Position.Y.Offset - 5
            )
            outer.Size = UDim2.new(
                tabFrame.Size.X.Scale, tabFrame.Size.X.Offset + 10,
                tabFrame.Size.Y.Scale, tabFrame.Size.Y.Offset + 10
            )
        end)

        local dragging = false
        local dragStart, startPos

        outer.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                dragStart = input.Position
                local absPos = tabFrame.AbsolutePosition
                startPos = Vector2.new(absPos.X, absPos.Y)
            end
        end)

        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = false
            end
        end)

        UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                local delta = input.Position - dragStart
                tabFrame.Position = UDim2.new(0, startPos.X + delta.X, 0, startPos.Y + delta.Y)
            end
        end)
    end

    -- 注入水印 + 给 Explorer / Properties 加彩色边框
    task.spawn(function()
        local attempts = 0
        while attempts < 20 do
            attempts = attempts + 1
            local dexGui = nil
            for _, gui in pairs(CoreGui:GetChildren()) do
                if gui:IsA("ScreenGui") and (gui.Name == "DexExplorer" or gui.Name == "SynapseX") then
                    dexGui = gui
                    break
                end
            end
            if not dexGui then
                task.wait(1)
                continue
            end

            local notebook = dexGui:FindFirstChild("Notebook") or dexGui:FindFirstChild("Main")
            if not notebook then
                task.wait(1)
                continue
            end

            local function processTab(tabName)
                local tab = nil
                for _, child in pairs(notebook:GetChildren()) do
                    if child:IsA("Frame") and (child.Name == tabName or child:FindFirstChild("TopBar") or child:FindFirstChild("Title")) then
                        tab = child
                        break
                    end
                end
                if tab then
                    addColorBorderToWindow(tab)

                    local header = tab:FindFirstChild("TopBar") or tab:FindFirstChild("Title") or tab:FindFirstChild("Header")
                    if not header then
                        header = Instance.new("Frame")
                        header.Name = "WatermarkHeader"
                        header.Size = UDim2.new(1, 0, 0, 18)
                        header.BackgroundTransparency = 1
                        header.Parent = tab
                    end
                    if not header:FindFirstChild("WatermarkLabel") then
                        local label = Instance.new("TextLabel")
                        label.Name = "WatermarkLabel"
                        label.Size = UDim2.new(0, 100, 1, 0)
                        label.Position = UDim2.new(1, -105, 0, 0)
                        label.BackgroundTransparency = 1
                        label.Text = "星神3756288324优化"
                        label.TextColor3 = Color3.fromRGB(160, 160, 160)
                        label.Font = Enum.Font.SourceSans
                        label.TextSize = 10
                        label.TextXAlignment = Enum.TextXAlignment.Right
                        label.Parent = header
                    end
                end
            end

            processTab("Explorer")
            processTab("Properties")
            break
        end
    end)
end)
