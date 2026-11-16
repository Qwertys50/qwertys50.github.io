local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local env = (getgenv and getgenv()) or _G
if env._EggOnPartInstances then
    for _, inst in env._EggOnPartInstances do
        pcall(function() inst.Delete() end)
    end
end
env._EggOnPartInstances = {}

local LocalPlayer = Players.LocalPlayer

local CFG = {
    MaxLives             =  3,
    LaneCount            = 3,
    StartLane            = 2,
    EggStartY            = 0,
    EggBreakY            = 0.9,
    CatchMinY            = 0.7,
    CatchMaxY            = 0.8,
    BrokenYMin           = 0.865,
    BrokenYMax           = 1.0,
    BrokenXVariance      = 0.09,
    StepTimeStart        = 0.30,
    StepTimePerRound     = 0.03,
    StepTimeMin          = 0.15,
    SpawnGapStartSecs    = 2.0,
    SpawnGapPerRoundSecs = 0.25,
    SpawnGapMinSecs      = 1.0,
    EggsRound1           = 4,
    EggsRound2           = 7,
    EggsPerRoundAfter    = 2,
    IntermissionSecs     = 2.0,
    GameOverFreezeSecs   = 2.5,
    CatcherRunSecs       = 0.25,
    PointNotifSteps      = 8,
    PointNotifStepSecs   = 0.08,
    PointNotifRiseY      = 0.03,
    RoundLabelSecs       = 2.0,
    MaxFrameSecs         = 0.25,
    ScoreDigits          = 10,
    RottenCatchCostsHeart = true,
    RottenBreakCostsHeart = false,
    LanePositions        = {0.25, 0.5, 0.75},
    CatcherY             = 0.8,
    EggTypes = {
        { name="Regular", weight=65, points= 100, img="rbxassetid://118664385061919" },
        { name="Gold",    weight=15, points= 200, img="rbxassetid://121131760777357" },
        { name="Rotten",  weight=25, points=-100, img="rbxassetid://93022523624286"  },
    },
    ScriptedRounds = {
        [1] = {"Regular","Regular","Gold","Regular"},
        [2] = {"Rotten","Regular","Rotten","Regular","Gold","Regular","Rotten"},
    },
}

local rng = Random.new()

local function stepTime(round)
    return math.max(CFG.StepTimeMin, CFG.StepTimeStart - CFG.StepTimePerRound * (round - 1))
end
local function spawnGapTicks(round)
    local st   = stepTime(round)
    local secs = math.max(CFG.SpawnGapMinSecs, CFG.SpawnGapStartSecs - CFG.SpawnGapPerRoundSecs * (round - 1))
    return math.max(1, math.floor(secs / st + 0.5))
end
local function eggCount(round)
    if round == 1 then return CFG.EggsRound1 end
    if round == 2 then return CFG.EggsRound2 end
    return CFG.EggsRound2 + (round - 2) * CFG.EggsPerRoundAfter
end
local function formatScore(n)
    local s = string.format("%.0f", math.max(0, math.floor(n + 0.5)))
    return string.rep("0", CFG.ScoreDigits - #s) .. s
end
local function roundLabel(round)
    if round <= 3 then return string.format("ROUND %d / 3", round) end
    return string.format("ROUND %d", round)
end
local function resolvePart(target)
    if typeof(target) ~= "Instance" then return nil end
    if target:IsA("BasePart") then return target end
    if target:IsA("Model") then
        return target.PrimaryPart or target:FindFirstChildWhichIsA("BasePart", true)
    end
    return nil
end
local function canvasFor(part, face)
    local s = part.Size
    local w, h
    if face == Enum.NormalId.Front or face == Enum.NormalId.Back then
        w, h = s.X, s.Y
    elseif face == Enum.NormalId.Left or face == Enum.NormalId.Right then
        w, h = s.Z, s.Y
    else
        w, h = s.X, s.Z
    end
    w, h = math.max(w, 0.05), math.max(h, 0.05)
    local long = 800
    if w >= h then return Vector2.new(long, math.max(100, math.floor(long * h / w))) end
    return Vector2.new(math.max(100, math.floor(long * w / h)), long)
end
local function rollType(scripted)
    if scripted then return scripted end
    local total = 0
    for _, t in CFG.EggTypes do total += t.weight end
    local r = rng:NextNumber() * total
    for _, t in CFG.EggTypes do
        r -= t.weight
        if r < 0 then return t.name end
    end
    return CFG.EggTypes[1].name
end
local function typeInfo(name)
    for _, t in CFG.EggTypes do
        if t.name == name then return t end
    end
    return CFG.EggTypes[1]
end

local function buildGUI(parent)
    local Screen = Instance.new("Frame")
    Screen.Name = "Screen"
    Screen.AnchorPoint = Vector2.new(0.5, 1)
    Screen.BackgroundColor3 = Color3.new(1,1,1)
    Screen.BackgroundTransparency = 0.7
    Screen.BorderSizePixel = 0
    Screen.Position = UDim2.new(0.5,0,1,0)
    Screen.Size = UDim2.new(1,0,1,0)
    Screen.ClipsDescendants = false
    Screen.Parent = parent

    local GameHolder = Instance.new("Frame")
    GameHolder.Name = "GameHolder"
    GameHolder.BackgroundTransparency = 1
    GameHolder.BorderSizePixel = 0
    GameHolder.Size = UDim2.new(1,0,1,0)
    GameHolder.ClipsDescendants = true
    GameHolder.Visible = false
    GameHolder.Parent = Screen

    local Background = Instance.new("ImageLabel")
    Background.AnchorPoint = Vector2.new(0,1)
    Background.BackgroundTransparency = 1
    Background.Position = UDim2.new(0,0,1,0)
    Background.Size = UDim2.new(1,0,1,0)
    Background.Image = "rbxassetid://132417261587721"
    Background.ImageColor3 = Color3.fromRGB(149,149,149)
    Background.ScaleType = Enum.ScaleType.Stretch
    Background.ResampleMode = Enum.ResamplerMode.Pixelated
    Background.ZIndex = 1
    Background.Parent = GameHolder

    local CloudWrap = Instance.new("ImageLabel")
    CloudWrap.Name = "CloudWrap"
    CloudWrap.AnchorPoint = Vector2.new(0,1)
    CloudWrap.BackgroundTransparency = 1
    CloudWrap.Position = UDim2.new(0,0,1,0)
    CloudWrap.Size = UDim2.new(1,0,1,0)
    CloudWrap.Image = "rbxassetid://102170227076166"
    CloudWrap.ImageColor3 = Color3.fromRGB(149,149,149)
    CloudWrap.ScaleType = Enum.ScaleType.Stretch
    CloudWrap.ResampleMode = Enum.ResamplerMode.Pixelated
    CloudWrap.ZIndex = 2
    CloudWrap.Parent = GameHolder

    local CloudSide = Instance.new("ImageLabel")
    CloudSide.AnchorPoint = Vector2.new(0,0)
    CloudSide.BackgroundTransparency = 1
    CloudSide.Position = UDim2.new(1,0,0,0)
    CloudSide.Size = UDim2.new(1,0,1,0)
    CloudSide.Image = "rbxassetid://102170227076166"
    CloudSide.ImageColor3 = Color3.fromRGB(149,149,149)
    CloudSide.ScaleType = Enum.ScaleType.Stretch
    CloudSide.ResampleMode = Enum.ResamplerMode.Pixelated
    CloudSide.ZIndex = 2
    CloudSide.Parent = CloudWrap

    local Lanes = Instance.new("Frame")
    Lanes.BackgroundTransparency = 1
    Lanes.BorderSizePixel = 0
    Lanes.Size = UDim2.new(1,0,1,0)
    Lanes.ZIndex = 1
    Lanes.Parent = GameHolder

    local laneColors = {
        Color3.fromRGB(255,197,197),
        Color3.fromRGB(225,255,220),
        Color3.fromRGB(209,203,255),
    }
    local catcherPositioners = {}
    for i = 1, CFG.LaneCount do
        local lane = Instance.new("Frame")
        lane.Name = "Lane"..i
        lane.AnchorPoint = Vector2.new(0.5, 0)
        lane.BackgroundColor3 = laneColors[i]
        lane.BackgroundTransparency = 1
        lane.BorderSizePixel = 0
        lane.Position = UDim2.new(CFG.LanePositions[i], 0, 0, 0)
        lane.Size = UDim2.new(0.25, 0, 1, 0)
        lane.ZIndex = 1
        lane.LayoutOrder = i
        lane.Parent = Lanes
        local cp = Instance.new("Frame")
        cp.Name = "CatcherPositioner"
        cp.AnchorPoint = Vector2.new(0.5, 0.5)
        cp.BackgroundTransparency = 1
        cp.Position = UDim2.new(0.5, 0, 0.8, 0)
        cp.Size = UDim2.new(0, 2, 0, 2)
        cp.ZIndex = 1
        cp.Parent = lane
        catcherPositioners[i] = cp
    end

    local ScoreFont = Font.new("rbxassetid://12187371840", Enum.FontWeight.Regular, Enum.FontStyle.Normal)

    local InGameScore = Instance.new("TextLabel")
    InGameScore.Name = "InGameScore"
    InGameScore.AnchorPoint = Vector2.new(0.5, 0)
    InGameScore.BackgroundTransparency = 1
    InGameScore.Position = UDim2.new(0.5,0,0,0)
    InGameScore.Size = UDim2.new(0.6,0,0.075,0)
    InGameScore.FontFace = ScoreFont
    InGameScore.Text = "0000000000"
    InGameScore.TextColor3 = Color3.fromRGB(11,15,11)
    InGameScore.TextSize = 16
    InGameScore.TextXAlignment = Enum.TextXAlignment.Center
    InGameScore.TextYAlignment = Enum.TextYAlignment.Center
    InGameScore.TextScaled = true
    InGameScore.ZIndex = 3
    Instance.new("UIStroke", InGameScore).Color = Color3.fromRGB(62,83,59)
    InGameScore.Parent = GameHolder

    local RoundDisplay = Instance.new("TextLabel")
    RoundDisplay.Name = "RoundDisplay"
    RoundDisplay.AnchorPoint = Vector2.new(0.5, 0)
    RoundDisplay.BackgroundTransparency = 1
    RoundDisplay.Position = UDim2.new(0.5,0,0.325,0)
    RoundDisplay.Size = UDim2.new(0.6,0,0.075,0)
    RoundDisplay.FontFace = ScoreFont
    RoundDisplay.Text = "ROUND 1 / 3"
    RoundDisplay.TextColor3 = Color3.fromRGB(11,15,11)
    RoundDisplay.TextSize = 16
    RoundDisplay.TextXAlignment = Enum.TextXAlignment.Center
    RoundDisplay.TextYAlignment = Enum.TextYAlignment.Center
    RoundDisplay.TextScaled = true
    RoundDisplay.ZIndex = 3
    RoundDisplay.Visible = false
    Instance.new("UIStroke", RoundDisplay).Color = Color3.fromRGB(62,83,59)
    RoundDisplay.Parent = GameHolder

    local Hearts = Instance.new("Frame")
    Hearts.Name = "Hearts"
    Hearts.AnchorPoint = Vector2.new(0.5,0.5)
    Hearts.BackgroundTransparency = 1
    Hearts.Position = UDim2.new(0.5,0,0.175,0)
    Hearts.Size = UDim2.new(0.375,0,0.125,0)
    Hearts.ZIndex = 4
    Hearts.Parent = GameHolder
    local HeartsLayout = Instance.new("UIListLayout")
    HeartsLayout.FillDirection = Enum.FillDirection.Horizontal
    HeartsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    HeartsLayout.Padding = UDim.new(0.025, 0)
    HeartsLayout.SortOrder = Enum.SortOrder.LayoutOrder
    HeartsLayout.VerticalAlignment = Enum.VerticalAlignment.Top
    HeartsLayout.Parent = Hearts

    local heartFull, heartBroke = {}, {}
    for i = 1, CFG.MaxLives do
        local h = Instance.new("ImageLabel")
        h.AnchorPoint = Vector2.new(0.5, 0.5)
        h.BackgroundTransparency = 1
        h.Position = UDim2.new(0.5,0,0.5,0)
        h.Size = UDim2.new(1,0,1,0)
        h.Image = "rbxassetid://106268095967166"
        h.ResampleMode = Enum.ResamplerMode.Pixelated
        h.ZIndex = 4
        h.LayoutOrder = i
        h.Parent = Hearts
        Instance.new("UIAspectRatioConstraint", h).AspectRatio = 1
        heartFull[i] = h

        local hb = Instance.new("ImageLabel")
        hb.AnchorPoint = Vector2.new(0.5, 0.5)
        hb.BackgroundTransparency = 1
        hb.Position = UDim2.new(0.5,0,0.5,0)
        hb.Size = UDim2.new(1,0,1,0)
        hb.Image = "rbxassetid://102022950350273"
        hb.ResampleMode = Enum.ResamplerMode.Pixelated
        hb.Visible = false
        hb.ZIndex = 4
        hb.LayoutOrder = i
        hb.Parent = Hearts
        Instance.new("UIAspectRatioConstraint", hb).AspectRatio = 1
        heartBroke[i] = hb
    end

    local Catcher = Instance.new("Frame")
    Catcher.Name = "Catcher"
    Catcher.AnchorPoint = Vector2.new(0.5, 0.5)
    Catcher.BackgroundTransparency = 1
    Catcher.Position = UDim2.new(0.5,0,0.7,0)
    Catcher.Size = UDim2.new(0.4,0,0.4,0)
    Catcher.ZIndex = 6
    Catcher.Parent = GameHolder
    Instance.new("UIAspectRatioConstraint", Catcher).AspectRatio = 1

    local CatcherIdle = Instance.new("ImageLabel")
    CatcherIdle.Name = "CatcherIdle"
    CatcherIdle.AnchorPoint = Vector2.new(0.5, 0.5)
    CatcherIdle.BackgroundTransparency = 1
    CatcherIdle.Position = UDim2.new(0.5,0,0.5,0)
    CatcherIdle.Size = UDim2.new(1,0,1,0)
    CatcherIdle.Image = "rbxassetid://89554983468545"
    CatcherIdle.ResampleMode = Enum.ResamplerMode.Pixelated
    CatcherIdle.ZIndex = 6
    CatcherIdle.Parent = Catcher

    local CatcherRun = Instance.new("ImageLabel")
    CatcherRun.Name = "CatcherRun"
    CatcherRun.AnchorPoint = Vector2.new(0.5, 0.5)
    CatcherRun.BackgroundTransparency = 1
    CatcherRun.Position = UDim2.new(0.5,0,0.5,0)
    CatcherRun.Size = UDim2.new(1,0,1,0)
    CatcherRun.Image = "rbxassetid://118914225966819"
    CatcherRun.ResampleMode = Enum.ResamplerMode.Pixelated
    CatcherRun.Visible = false
    CatcherRun.ZIndex = 6
    CatcherRun.Parent = Catcher

    local BrokenEggTemplate = Instance.new("Frame")
    BrokenEggTemplate.Name = "BrokenEggTemplate"
    BrokenEggTemplate.AnchorPoint = Vector2.new(0.5, 0.5)
    BrokenEggTemplate.BackgroundTransparency = 1
    BrokenEggTemplate.Position = UDim2.new(0.5,0,0.925,0)
    BrokenEggTemplate.Size = UDim2.new(0.125,0,0.125,0)
    BrokenEggTemplate.Visible = false
    BrokenEggTemplate.ZIndex = 4
    BrokenEggTemplate.Parent = GameHolder
    local bARC = Instance.new("UIAspectRatioConstraint", BrokenEggTemplate)
    bARC.AspectRatio = 2.375
    bARC.AspectType = Enum.AspectType.FitWithinMaxSize
    bARC.DominantAxis = Enum.DominantAxis.Width
    local bImg = Instance.new("ImageLabel", BrokenEggTemplate)
    bImg.AnchorPoint = Vector2.new(0.5,0.5)
    bImg.BackgroundTransparency = 1
    bImg.Position = UDim2.new(0.5,0,0.5,0)
    bImg.Size = UDim2.new(1,0,1,0)
    bImg.Image = "rbxassetid://73542634757267"
    bImg.ResampleMode = Enum.ResamplerMode.Pixelated
    bImg.ZIndex = 4

    local PointNotifTemplate = Instance.new("Frame")
    PointNotifTemplate.Name = "PointNotifTemplate"
    PointNotifTemplate.AnchorPoint = Vector2.new(0.5, 0.5)
    PointNotifTemplate.BackgroundTransparency = 1
    PointNotifTemplate.Position = UDim2.new(0.5,0,0.45,0)
    PointNotifTemplate.Size = UDim2.new(0.1,0,0.1,0)
    PointNotifTemplate.Visible = false
    PointNotifTemplate.ZIndex = 4
    PointNotifTemplate.Parent = GameHolder
    local pTL = Instance.new("TextLabel", PointNotifTemplate)
    pTL.AnchorPoint = Vector2.new(0,0)
    pTL.BackgroundTransparency = 1
    pTL.Position = UDim2.new(0,0,0,0)
    pTL.Size = UDim2.new(1,0,1,0)
    pTL.FontFace = Font.new("rbxasset://fonts/families/PressStart2P.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
    pTL.Text = "+100"
    pTL.TextColor3 = Color3.fromRGB(17,47,24)
    pTL.TextSize = 12
    pTL.TextXAlignment = Enum.TextXAlignment.Center
    pTL.TextYAlignment = Enum.TextYAlignment.Center
    pTL.TextScaled = true
    pTL.ZIndex = 5
    Instance.new("UIStroke", pTL).Color = Color3.fromRGB(62,83,59)

    local MainScreen = Instance.new("Frame")
    MainScreen.Name = "MainScreen"
    MainScreen.BackgroundTransparency = 1
    MainScreen.Size = UDim2.new(1,0,1,0)
    MainScreen.ZIndex = 1
    MainScreen.Parent = Screen

    local MenuBG = Instance.new("ImageLabel", MainScreen)
    MenuBG.AnchorPoint = Vector2.new(0,1)
    MenuBG.BackgroundTransparency = 1
    MenuBG.Position = UDim2.new(0,0,1,0)
    MenuBG.Size = UDim2.new(1,0,1,0)
    MenuBG.Image = "rbxassetid://95568316105284"
    MenuBG.ImageColor3 = Color3.fromRGB(149,149,149)
    MenuBG.ScaleType = Enum.ScaleType.Stretch
    MenuBG.ResampleMode = Enum.ResamplerMode.Pixelated
    MenuBG.ZIndex = 0

    local Title = Instance.new("ImageLabel", MainScreen)
    Title.AnchorPoint = Vector2.new(0.5,0.5)
    Title.BackgroundTransparency = 1
    Title.Position = UDim2.new(0.5,0,0.33,0)
    Title.Size = UDim2.new(0.7,0,0.7,0)
    Title.Image = "rbxassetid://109787429652059"
    Title.ScaleType = Enum.ScaleType.Stretch
    Title.ResampleMode = Enum.ResamplerMode.Pixelated
    Title.ZIndex = 8
    Instance.new("UIAspectRatioConstraint", Title).AspectRatio = 1

    for _, vfx in {
        {name="EggVFX1", pos=UDim2.new(0.15,0,0.8,0)},
        {name="EggVFX2", pos=UDim2.new(0.85,0,0.8,0)},
    } do
        local f = Instance.new("Frame", MainScreen)
        f.Name = vfx.name
        f.AnchorPoint = Vector2.new(0.5,0.5)
        f.BackgroundTransparency = 1
        f.Position = vfx.pos
        f.Size = UDim2.new(0.2,0,0.2,0)
        f.ZIndex = 7
        local arc = Instance.new("UIAspectRatioConstraint", f)
        arc.AspectRatio = 0.8
        arc.AspectType = Enum.AspectType.FitWithinMaxSize
        arc.DominantAxis = Enum.DominantAxis.Width
        local img = Instance.new("ImageLabel", f)
        img.AnchorPoint = Vector2.new(0.5,0.5)
        img.BackgroundTransparency = 1
        img.Position = UDim2.new(0.5,0,0.5,0)
        img.Size = UDim2.new(1,0,1,0)
        img.Image = "rbxassetid://118664385061919"
        img.ResampleMode = Enum.ResamplerMode.Pixelated
        img.ZIndex = 8
    end

    local PlayLabel = Instance.new("TextLabel", MainScreen)
    PlayLabel.Name = "PlayAgainLabel"
    PlayLabel.AnchorPoint = Vector2.new(0.5,0.5)
    PlayLabel.BackgroundTransparency = 1
    PlayLabel.Position = UDim2.new(0.5,0,0.775,0)
    PlayLabel.Size = UDim2.new(0.666,0,0.333,0)
    PlayLabel.FontFace = Font.new("rbxassetid://12187371840", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
    PlayLabel.Text = "PRESS\nPLAY"
    PlayLabel.TextColor3 = Color3.fromRGB(11,15,11)
    PlayLabel.TextSize = 20
    PlayLabel.TextWrapped = true
    PlayLabel.TextScaled = true
    PlayLabel.TextXAlignment = Enum.TextXAlignment.Center
    PlayLabel.TextYAlignment = Enum.TextYAlignment.Center
    PlayLabel.ZIndex = 3
    Instance.new("UIStroke", PlayLabel).Color = Color3.fromRGB(62,83,59)

    local TransitionFrame = Instance.new("Frame", Screen)
    TransitionFrame.Name = "TransitionFrame"
    TransitionFrame.BackgroundColor3 = Color3.fromRGB(10,47,12)
    TransitionFrame.BackgroundTransparency = 1
    TransitionFrame.BorderSizePixel = 0
    TransitionFrame.Size = UDim2.new(1,0,1,0)
    TransitionFrame.ZIndex = 9

    return {
        Screen             = Screen,
        GameHolder         = GameHolder,
        MainScreen         = MainScreen,
        PlayLabel          = PlayLabel,
        InGameScore        = InGameScore,
        RoundDisplay       = RoundDisplay,
        Hearts             = Hearts,
        heartFull          = heartFull,
        heartBroke         = heartBroke,
        Catcher            = Catcher,
        CatcherIdle        = CatcherIdle,
        CatcherRun         = CatcherRun,
        BrokenEggTemplate  = BrokenEggTemplate,
        PointNotifTemplate = PointNotifTemplate,
        CloudWrap          = CloudWrap,
        TransitionFrame    = TransitionFrame,
        catcherPositioners = catcherPositioners,
    }
end

local Game = {}
Game.__index = Game

function Game.new(part, options)
    options = options or {}
    local self = setmetatable({}, Game)
    self.part = part
    self.on   = true
    self.dead = false

    self._transitioning = false

    local face = options.Face or Enum.NormalId.Front
    local gui = Instance.new("SurfaceGui")
    gui.Name           = "EggGameSurface"
    gui.ResetOnSpawn   = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.SizingMode     = Enum.SurfaceGuiSizingMode.FixedSize
    gui.CanvasSize     = options.Canvas or canvasFor(part, face)
    gui.Face           = face
    gui.LightInfluence = 0
    gui.Brightness     = options.Brightness or 1.2
    gui.AlwaysOnTop    = false
    gui.Adornee        = part

    local root = Instance.new("Frame")
    root.Size = UDim2.new(1,0,1,0)
    root.BackgroundTransparency = 1
    root.BorderSizePixel = 0
    root.Parent = gui

    gui.Parent = LocalPlayer:WaitForChild("PlayerGui")

    self.gui = gui
    self.ui  = buildGUI(root)

    self.eggs         = {}
    self.popups       = {}
    self.brokenFrames = {}
    self.nextId       = 1
    self.cloudX       = 0
    self.catcherX     = CFG.LanePositions[CFG.StartLane]
    self.catcherLane  = CFG.StartLane
    self.catcherRunT  = 0

    self:_toMenu()

    self._heartbeat = RunService.Heartbeat:Connect(function(dt)
        self:step(dt)
    end)
    self._destroyConn = part.Destroying:Connect(function()
        self:_destroy()
    end)

    return self
end

function Game:_refreshScore()
    self.ui.InGameScore.Text = formatScore(self.score)
end
function Game:_refreshHearts()
    for i = 1, CFG.MaxLives do
        self.ui.heartFull[i].Visible  = i <= self.lives
        self.ui.heartBroke[i].Visible = i >  self.lives
    end
end
function Game:_showRound(visible)
    self.ui.RoundDisplay.Visible = visible
    if visible then self.ui.RoundDisplay.Text = roundLabel(self.round) end
end
function Game:_setCatcherRunning(running)
    self.ui.CatcherIdle.Visible = not running
    self.ui.CatcherRun.Visible  = running
end

function Game:_spawnEggFrame(egg)
    local info = typeInfo(egg.type)
    local f = Instance.new("Frame")
    f.Name = "Egg"..egg.id
    f.AnchorPoint = Vector2.new(0.5, 0.5)
    f.BackgroundTransparency = 1
    f.Position = UDim2.new(CFG.LanePositions[egg.lane], 0, egg.y, 0)
    f.Size = UDim2.new(0.2,0,0.2,0)
    f.ZIndex = 7
    f.Parent = self.ui.GameHolder
    local arc = Instance.new("UIAspectRatioConstraint", f)
    arc.AspectRatio = 0.8
    arc.AspectType = Enum.AspectType.FitWithinMaxSize
    arc.DominantAxis = Enum.DominantAxis.Width
    local img = Instance.new("ImageLabel", f)
    img.AnchorPoint = Vector2.new(0.5,0.5)
    img.BackgroundTransparency = 1
    img.Position = UDim2.new(0.5,0,0.5,0)
    img.Size = UDim2.new(1,0,1,0)
    img.Image = info.img
    img.ResampleMode = Enum.ResamplerMode.Pixelated
    img.ZIndex = 8
    egg.frame = f
end
function Game:_destroyEggFrame(egg)
    if egg.frame then egg.frame:Destroy(); egg.frame = nil end
end
function Game:_spawnBroken(lane, xOff, y)
    local f = self.ui.BrokenEggTemplate:Clone()
    f.Position = UDim2.new(CFG.LanePositions[lane] + xOff, 0, y, 0)
    f.Visible = true
    f.Parent = self.ui.GameHolder
    table.insert(self.brokenFrames, f)
    while #self.brokenFrames > 60 do table.remove(self.brokenFrames, 1):Destroy() end
end
function Game:_spawnNotif(lane, y, text)
    local f = self.ui.PointNotifTemplate:Clone()
    f.Visible = true
    f.Position = UDim2.new(CFG.LanePositions[lane], 0, y, 0)
    f.Parent = self.ui.GameHolder
    local tl = f:FindFirstChildOfClass("TextLabel")
    tl.Text = text
    local stroke = tl:FindFirstChildOfClass("UIStroke")
    table.insert(self.popups, {
        frame=f, label=tl, stroke=stroke,
        startY=y, laneX=CFG.LanePositions[lane],
        step=0, timer=CFG.PointNotifStepSecs,
    })
    self:_applyNotif(self.popups[#self.popups])
end
function Game:_applyNotif(n)
    local t = n.step / CFG.PointNotifSteps
    n.frame.Position = UDim2.new(n.laneX, 0, n.startY - CFG.PointNotifRiseY * n.step, 0)
    n.label.TextTransparency = t
    if n.stroke then n.stroke.Transparency = t end
end
function Game:_updateNotifs(dt)
    for i = #self.popups, 1, -1 do
        local n = self.popups[i]
        n.timer -= dt
        while n.timer <= 0 and n.step < CFG.PointNotifSteps do
            n.timer += CFG.PointNotifStepSecs
            n.step  += 1
        end
        if n.step >= CFG.PointNotifSteps then
            n.frame:Destroy()
            table.remove(self.popups, i)
        else
            self:_applyNotif(n)
        end
    end
end

function Game:_clearEggs()
    for _, egg in self.eggs do if egg.frame then egg.frame:Destroy() end end
    self.eggs = {}
    for _, f in self.brokenFrames do f:Destroy() end
    self.brokenFrames = {}
    for _, n in self.popups do n.frame:Destroy() end
    self.popups = {}
end

function Game:_doTransition(callback)
    if self._transitioning then return end
    self._transitioning = true
    local tf = self.ui.TransitionFrame
    local t1 = TweenService:Create(tf, TweenInfo.new(0.2), {BackgroundTransparency=0})
    t1:Play()
    t1.Completed:Wait()
    if not self.dead then
        callback()
    end
    local t2 = TweenService:Create(tf, TweenInfo.new(0.2), {BackgroundTransparency=1})
    t2:Play()
    t2.Completed:Wait()
    self._transitioning = false
end

function Game:_toMenu()
    self.state = "Menu"
    self:_clearEggs()
    self.score = 0
    self.lives = CFG.MaxLives
    self.round = 1
    self.catcherLane = CFG.StartLane
    self.catcherX = CFG.LanePositions[CFG.StartLane]
    self:_refreshScore()
    self:_refreshHearts()
    self:_showRound(false)
    self:_setCatcherRunning(false)
    self.ui.PlayLabel.Text = "PRESS\nPLAY"
    self.ui.GameHolder.Visible = false
    self.ui.MainScreen.Visible = true
end
function Game:_toGame()
    self.ui.MainScreen.Visible = false
    self.ui.GameHolder.Visible = true
    self:_beginRound(1, false)
end
function Game:_beginRound(n, refill)
    self.round = n
    if refill then self.lives = CFG.MaxLives; self:_refreshHearts() end
    local scripted = CFG.ScriptedRounds[n]
    local count = eggCount(n)
    if scripted then count = math.max(count, #scripted) end
    local plan = {}
    for i = 1, count do plan[i] = rollType(scripted and scripted[i] or nil) end
    self.plan       = plan
    self.planIdx    = 1
    self.gapTicks   = spawnGapTicks(n)
    self.sinceSpawn = self.gapTicks
    self.tickAcc    = 0
    self.state      = "Intermission"
    self.interTimer = CFG.IntermissionSecs
    self.roundLabelTimer = CFG.RoundLabelSecs
    self:_showRound(true)
    self:_refreshScore()
end
function Game:_gameOver()
    self.state = "GameOver"
    self.goTimer = CFG.GameOverFreezeSecs
    self:_clearEggs()

    self.ui.PlayLabel.Text = formatScore(self.score)
end

function Game:_spawnEgg()
    if self.planIdx > #self.plan then return end
    local t = self.plan[self.planIdx]; self.planIdx += 1
    local egg = {
        id=self.nextId, type=t,
        lane=rng:NextInteger(1, CFG.LaneCount),
        y=CFG.EggStartY, step=0, alive=true, frame=nil,
    }
    self.nextId += 1
    table.insert(self.eggs, egg)
    self:_spawnEggFrame(egg)
end
local EggStepY = 0.08
function Game:_tick()
    for i = #self.eggs, 1, -1 do
        local egg = self.eggs[i]
        if egg.alive then
            egg.y += EggStepY
            if egg.frame then
                egg.frame.Position = UDim2.new(CFG.LanePositions[egg.lane], 0, egg.y, 0)
            end
            if egg.lane == self.catcherLane
                and egg.y >= CFG.CatchMinY and egg.y <= CFG.CatchMaxY + EggStepY then
                table.remove(self.eggs, i)
                self:_destroyEggFrame(egg)
                self:_onCatch(egg)
                if self.state ~= "Playing" then return end
            elseif egg.y >= CFG.EggBreakY then
                table.remove(self.eggs, i)
                self:_destroyEggFrame(egg)
                self:_onBreak(egg)
                if self.state ~= "Playing" then return end
            end
        end
    end
    self.sinceSpawn += 1
    if self.planIdx <= #self.plan and self.sinceSpawn >= self.gapTicks then
        self.sinceSpawn = 0; self:_spawnEgg()
    end
    if self.planIdx > #self.plan and #self.eggs == 0 then
        self:_beginRound(self.round + 1, true)
    end
end
function Game:_onCatch(egg)
    local info = typeInfo(egg.type)
    local pts = info.points * self.round
    self.score = math.max(0, self.score + pts)
    self:_refreshScore()
    self:_spawnNotif(egg.lane, egg.y, string.format("%+.0f", pts))
    if egg.type == "Rotten" and CFG.RottenCatchCostsHeart then self:_loseLife() end
end
function Game:_onBreak(egg)
    local xOff = rng:NextNumber() * CFG.BrokenXVariance * 2 - CFG.BrokenXVariance
    local y    = rng:NextNumber() * (CFG.BrokenYMax - CFG.BrokenYMin) + CFG.BrokenYMin
    self:_spawnBroken(egg.lane, xOff, y)
    if egg.type ~= "Rotten" or CFG.RottenBreakCostsHeart then self:_loseLife() end
end
function Game:_loseLife()
    if self.state ~= "Playing" then return end
    self.lives = math.max(0, self.lives - 1)
    self:_refreshHearts()
    if self.lives <= 0 then self:_gameOver() end
end

function Game:step(dt)
    if self.dead or not self.on then return end
    dt = math.min(dt, CFG.MaxFrameSecs)

    self.catcherX += (CFG.LanePositions[self.catcherLane] - self.catcherX) * math.min(1, dt * 16)
    self.ui.Catcher.Position = UDim2.new(self.catcherX, 0, CFG.CatcherY, 0)
    if self.catcherRunT > 0 then
        self.catcherRunT -= dt
        if self.catcherRunT <= 0 then self:_setCatcherRunning(false) end
    end

    self.cloudX = self.cloudX + dt / 60
    if self.cloudX > 1 then self.cloudX -= 1 end
    self.ui.CloudWrap.Position = UDim2.new(-self.cloudX, 0, 1, 0)

    self:_updateNotifs(dt)

    if self.roundLabelTimer then
        self.roundLabelTimer -= dt
        if self.roundLabelTimer <= 0 then
            self.roundLabelTimer = nil
            self:_showRound(false)
        end
    end

    local s = self.state
    if s == "GameOver" then
        self.goTimer -= dt
        if self.goTimer <= 0 then
            self.ui.GameHolder.Visible = false
            self.ui.MainScreen.Visible = true
        end
    elseif s == "Intermission" then
        self.interTimer -= dt
        if self.interTimer <= 0 then self.state = "Playing" end
    elseif s == "Playing" then
        local st = stepTime(self.round)
        self.tickAcc += dt
        while self.tickAcc >= st and self.state == "Playing" do
            self.tickAcc -= st
            self:_tick()
        end
    end
end

function Game:_destroy()
    if self.dead then return end
    self.dead = true
    if self._heartbeat   then self._heartbeat:Disconnect();   self._heartbeat   = nil end
    if self._destroyConn then self._destroyConn:Disconnect(); self._destroyConn = nil end
    self.gui:Destroy()
end

local EggOnPart = {}

function EggOnPart.new(target, options)
    local part = resolvePart(target)
    if not part then
        warn("[EggOnPart] нужен BasePart (или Model с PrimaryPart)")
        return nil
    end

    local g = Game.new(part, options or {})
    local api = { game = g }

    function api.Move()
        if g.dead or g._transitioning then return end
        local s = g.state
        if s == "Menu" then
            task.spawn(function()
                g:_doTransition(function() g:_toGame() end)
            end)
        elseif s == "Playing" or s == "Intermission" then
            g.catcherLane = g.catcherLane % CFG.LaneCount + 1
            g.catcherRunT = CFG.CatcherRunSecs
            g:_setCatcherRunning(true)
        elseif s == "GameOver" and g.goTimer <= 0 then
            task.spawn(function()
                g:_doTransition(function()
                    g:_toMenu()
                end)
            end)
        end
    end

    function api.Toggle()
        if g.dead then return end
        g.on = not g.on
        g.gui.Enabled = g.on
    end

    function api.Delete()
        g:_destroy()
        local list = env._EggOnPartInstances
        if list then
            for i = #list, 1, -1 do
                if list[i] == api then table.remove(list, i) end
            end
        end
    end

    table.insert(env._EggOnPartInstances, api)
    return api
end

return EggOnPart
