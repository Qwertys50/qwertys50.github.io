local RS = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local Eggs = require(RS.Shared.Data.Eggs)
local PetsData = require(RS.Shared.Data.Pets)
local Constants = require(RS.Shared.Constants)
local okXL, XLEggUtil = pcall(require, RS.Shared.Utils.XLEggUtil)
local okPU, PetUtil = pcall(require, RS.Shared.Utils.Stats.PetUtil)
local okCur, Currency = pcall(require, RS.Shared.Data.Currency)

local M = {}

local Suffixes = { "", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc" }

local function abbr(n)
    local i = 0
    while n >= 1000 and i < #Suffixes - 1 do
        n = n / 1000
        i += 1
    end
    n = math.floor(n * 100 + 0.5) / 100
    if n >= 1000 and i < #Suffixes - 1 then
        n = n / 1000
        i += 1
    end
    local s = ("%.2f"):format(n):gsub("%.?0+$", "")
    return s .. Suffixes[i + 1]
end

local function fmtChance(pct)
    if pct <= 0 then return "0%" end
    if pct >= 1 then
        return ("%g"):format(pct) .. "%"
    end
    return "1/" .. abbr(100 / pct)
end

local function eggInfo(name)
    local egg = Eggs[name]
    if type(egg) ~= "table" then return nil, "egg not found" end
    local info = {
        name = name, world = egg.World, island = egg.Island, event = egg.Event,
        cost = egg.Cost, image = egg.Image, pets = {},
    }
    for _, entry in ipairs(egg.Pool or {}) do
        local item = entry.Item
        if item and item.Type == "Pet" then
            local p = PetsData[item.Name] or {}
            table.insert(info.pets, {
                name = item.Name,
                chance = entry.Chance,
                rarity = p.Rarity,
                image = p.Images and p.Images.Normal,
                shinyImage = p.Images and p.Images.Shiny,
            })
        end
    end
    return info
end

local EggList = {}
for name, e in pairs(Eggs) do
    if type(name) == "string" and type(e) == "table" then
        table.insert(EggList, {
            name = name, image = e.Image, order = e.LayoutOrder or 0,
            world = e.World, sub = e.World or e.Event or "",
        })
    end
end
table.sort(EggList, function(a, b)
    local wa, wb = a.world or "~", b.world or "~"
    if wa ~= wb then return wa < wb end
    if a.order ~= b.order then return a.order < b.order end
    return a.name < b.name
end)

local PetIndex, PetList = {}, {}
for _, e in ipairs(EggList) do
    local info = eggInfo(e.name)
    if info then
        for _, p in ipairs(info.pets) do
            local rec = PetIndex[p.name]
            if not rec then
                rec = { name = p.name, rarity = p.rarity, image = p.image, eggs = {} }
                PetIndex[p.name] = rec
            end
            table.insert(rec.eggs, { egg = e.name, image = e.image, chance = p.chance, sub = e.sub })
        end
    end
end
for name, d in pairs(PetsData) do
    if type(name) == "string" and type(d) == "table" and not PetIndex[name] then
        PetIndex[name] = {
            name = name, rarity = d.Rarity,
            image = d.Images and d.Images.Normal, eggs = {},
        }
    end
end
for _, rec in pairs(PetIndex) do
    table.sort(rec.eggs, function(a, b)
        if a.chance ~= b.chance then return a.chance > b.chance end
        return a.egg < b.egg
    end)
    table.insert(PetList, rec)
end
table.sort(PetList, function(a, b) return a.name < b.name end)

local function petStats(name, shiny, xl)
    if okPU then
        local ok, st = pcall(function()
            return PetUtil:GetStats({ Name = name, Shiny = shiny or nil, XL = xl or nil })
        end)
        if ok and type(st) == "table" then return st end
    end
    local base = PetsData[name] and PetsData[name].Stats or {}
    return base
end

function M.Mount(Library, PetsTab)
    local RarityColors = Constants.RarityColors
    local DefaultRarity = Color3.new(1, 1, 1)

    local RarityOverride = {
        Legendary = Color3.fromRGB(255, 200, 60),
    }
    local function RarityColor(r)
        return RarityOverride[r] or RarityColors[r] or DefaultRarity
    end

    local Scheme = Library.Scheme or {}
    local CardColor = Scheme.MainColor or Color3.fromRGB(28, 28, 32)
    local TextColor = Scheme.FontColor or Color3.new(1, 1, 1)
    local OutlineColor = Scheme.OutlineColor or Color3.fromRGB(70, 70, 80)
    local AccentColor = Scheme.AccentColor or Color3.fromRGB(125, 85, 255)
    local XLColor = Color3.fromRGB(255, 200, 60)

    local function Round(inst, radius)
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, radius)
        c.Parent = inst
    end

    local function Outline(inst, color, thickness, transparency)
        local s = Instance.new("UIStroke")
        s.Color = color
        s.Thickness = thickness
        s.Transparency = transparency
        s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        s.Parent = inst
        return s
    end

    local function Label(parent, props)
        local l = Instance.new("TextLabel")
        l.BackgroundTransparency = 1
        l.Font = Enum.Font.GothamBold
        l.TextSize = 12
        l.TextColor3 = TextColor
        l.TextTruncate = Enum.TextTruncate.AtEnd
        for k, v in pairs(props) do l[k] = v end
        l.Parent = parent
        return l
    end

    local Root = Instance.new("Frame")
    Root.Size = UDim2.fromScale(1, 1)
    Root.BackgroundTransparency = 1
    Root.BorderSizePixel = 0

    local Header = Instance.new("Frame")
    Header.Size = UDim2.new(1, 0, 0, 30)
    Header.BackgroundTransparency = 1
    Header.Parent = Root

    local Title = Label(Header, {
        Position = UDim2.fromOffset(4, 0),
        Size = UDim2.new(1, -234, 1, 0),
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
    })

    local function HeaderButton(text, width, rightOffset)
        local B = Instance.new("TextButton")
        B.AnchorPoint = Vector2.new(1, 0.5)
        B.Position = UDim2.new(1, -rightOffset, 0.5, 0)
        B.Size = UDim2.fromOffset(width, 24)
        B.BackgroundColor3 = CardColor
        B.AutoButtonColor = true
        B.Font = Enum.Font.GothamBold
        B.Text = text
        B.TextSize = 12
        B.TextColor3 = TextColor
        B.Visible = false
        B.Parent = Header
        Round(B, 6)
        Outline(B, OutlineColor, 1, 0.2)
        return B
    end

    local CloseBtn = HeaderButton("Close", 100, 2)
    local XLBtn = HeaderButton("XL", 56, 108)
    local ShinyBtn = HeaderButton("Shiny", 70, 170)

    local Search = Instance.new("TextBox")
    Search.AnchorPoint = Vector2.new(1, 0.5)
    Search.Position = UDim2.new(1, -2, 0.5, 0)
    Search.Size = UDim2.fromOffset(220, 24)
    Search.BackgroundColor3 = CardColor
    Search.BorderSizePixel = 0
    Search.ClearTextOnFocus = false
    Search.Font = Enum.Font.Gotham
    Search.PlaceholderText = "Search eggs or pets..."
    Search.PlaceholderColor3 = TextColor:Lerp(CardColor, 0.5)
    Search.Text = ""
    Search.TextSize = 12
    Search.TextColor3 = TextColor
    Search.Parent = Header
    Round(Search, 6)
    Outline(Search, OutlineColor, 1, 0.2)

    local Content = Instance.new("Frame")
    Content.Position = UDim2.fromOffset(0, 34)
    Content.Size = UDim2.new(1, 0, 1, -34)
    Content.BackgroundTransparency = 1
    Content.ClipsDescendants = true
    Content.Parent = Root

    local function MakeScroll(cellSize)
        local S = Instance.new("ScrollingFrame")
        S.Size = UDim2.fromScale(1, 1)
        S.BackgroundTransparency = 1
        S.BorderSizePixel = 0
        S.ScrollBarThickness = 4
        S.AutomaticCanvasSize = Enum.AutomaticSize.Y
        S.CanvasSize = UDim2.new()
        S.Parent = Content

        local P = Instance.new("UIPadding")
        P.PaddingTop = UDim.new(0, 4)
        P.PaddingBottom = UDim.new(0, 4)
        P.PaddingLeft = UDim.new(0, 2)
        P.PaddingRight = UDim.new(0, 2)
        P.Parent = S

        local G = Instance.new("UIGridLayout")
        G.CellSize = cellSize
        G.CellPadding = UDim2.fromOffset(8, 8)
        G.SortOrder = Enum.SortOrder.LayoutOrder
        G.HorizontalAlignment = Enum.HorizontalAlignment.Center
        G.Parent = S
        return S
    end

    local EggScroll = Instance.new("ScrollingFrame")
    EggScroll.Size = UDim2.fromScale(1, 1)
    EggScroll.BackgroundTransparency = 1
    EggScroll.BorderSizePixel = 0
    EggScroll.ScrollBarThickness = 4
    EggScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    EggScroll.CanvasSize = UDim2.new()
    EggScroll.Parent = Content

    do
        local P = Instance.new("UIPadding")
        P.PaddingTop = UDim.new(0, 4)
        P.PaddingBottom = UDim.new(0, 4)
        P.PaddingLeft = UDim.new(0, 2)
        P.PaddingRight = UDim.new(0, 2)
        P.Parent = EggScroll

        local L = Instance.new("UIListLayout")
        L.Padding = UDim.new(0, 8)
        L.SortOrder = Enum.SortOrder.LayoutOrder
        L.Parent = EggScroll
    end

    local function MakeSection(order, size_)
        local Bar = Instance.new("Frame")
        Bar.Size = UDim2.new(1, 0, 0, 24)
        Bar.BackgroundColor3 = CardColor
        Bar.BackgroundTransparency = 0.15
        Bar.BorderSizePixel = 0
        Bar.LayoutOrder = order * 2 - 1
        Bar.Visible = false
        Bar.Parent = EggScroll
        Round(Bar, 6)
        Outline(Bar, OutlineColor, 1, 0.3)

        local Text = Label(Bar, {
            Position = UDim2.fromOffset(10, 0),
            Size = UDim2.new(1, -20, 1, 0),
            TextXAlignment = Enum.TextXAlignment.Left,
        })

        local Grid = Instance.new("Frame")
        Grid.Size = UDim2.new(1, 0, 0, 0)
        Grid.AutomaticSize = Enum.AutomaticSize.Y
        Grid.BackgroundTransparency = 1
        Grid.BorderSizePixel = 0
        Grid.LayoutOrder = order * 2
        Grid.Parent = EggScroll

        local G = Instance.new("UIGridLayout")
        G.CellSize = size_ or UDim2.fromOffset(108, 122)
        G.CellPadding = UDim2.fromOffset(8, 8)
        G.SortOrder = Enum.SortOrder.LayoutOrder
        G.HorizontalAlignment = Enum.HorizontalAlignment.Center
        G.Parent = Grid

        return Bar, Text, Grid
    end

    local EggBar, EggBarText, EggGrid = MakeSection(1)
    local PetBar, PetBarText, PetGrid = MakeSection(2, UDim2.fromOffset(108, 108))
    local PetScroll = MakeScroll(UDim2.fromOffset(96, 118))
    PetScroll.Visible = false
    local PetEggScroll = MakeScroll(UDim2.fromOffset(108, 122))
    PetEggScroll.Visible = false

    local EmptyLabel = Label(Content, {
        Size = UDim2.fromScale(1, 1),
        Text = "This egg has no pets in its pool",
        Font = Enum.Font.Gotham,
        TextTransparency = 0.4,
        Visible = false,
    })

    local TipGui = Library.ScreenGui
    if not TipGui then
        TipGui = Instance.new("ScreenGui")
        TipGui.ResetOnSpawn = false
        TipGui.DisplayOrder = 1000
        TipGui.Parent = (gethui and gethui()) or game:GetService("CoreGui")
    end

    local Tip = Instance.new("Frame")
    Tip.Visible = false
    Tip.Active = false
    Tip.ZIndex = 200
    Tip.BackgroundColor3 = CardColor
    Tip.BackgroundTransparency = 0.03
    Tip.BorderSizePixel = 0
    Tip.Size = UDim2.fromOffset(190, 0)
    Tip.AutomaticSize = Enum.AutomaticSize.Y
    Tip.Parent = TipGui
    Round(Tip, 8)
    Outline(Tip, OutlineColor, 1.5, 0)

    local TipPad = Instance.new("UIPadding")
    TipPad.PaddingTop = UDim.new(0, 8)
    TipPad.PaddingBottom = UDim.new(0, 8)
    TipPad.PaddingLeft = UDim.new(0, 10)
    TipPad.PaddingRight = UDim.new(0, 10)
    TipPad.Parent = Tip

    local TipList = Instance.new("UIListLayout")
    TipList.Padding = UDim.new(0, 3)
    TipList.SortOrder = Enum.SortOrder.LayoutOrder
    TipList.Parent = Tip

    local TipTitle = Label(Tip, {
        Size = UDim2.new(1, 0, 0, 18), TextSize = 13, LayoutOrder = 0,
        TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 201,
    })
    local TipSub = Label(Tip, {
        Size = UDim2.new(1, 0, 0, 14), Font = Enum.Font.Gotham, TextSize = 11, LayoutOrder = 1,
        TextTransparency = 0.35, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 201,
    })

    local StatOrder = { Bubbles = 1, Coins = 2, Gems = 3, Pearls = 4 }

    local StatIconFallback = {
        Bubbles = "rbxassetid://139415836850114",
    }

    local function statName(k)
        local cur = okCur and type(Currency) == "table" and Currency[k]
        if type(cur) == "table" and type(cur.Display) == "string" then return cur.Display end
        return (tostring(k):gsub("(%l)(%u)", "%1 %2"))
    end

    local function statIcon(k)
        local cur = okCur and type(Currency) == "table" and Currency[k]
        if type(cur) == "table" and type(cur.Image) == "string" and cur.Image ~= "" then
            return cur.Image
        end
        return StatIconFallback[k]
    end

    local function statColor(k)
        local cur = okCur and type(Currency) == "table" and Currency[k]
        if type(cur) == "table" and typeof(cur.Color) == "Color3" then return cur.Color end
        return TextColor
    end

    local function MoveTip()
        local inset = TipGui:IsA("ScreenGui") and not TipGui.IgnoreGuiInset
            and GuiService:GetGuiInset() or Vector2.zero
        local m = UserInputService:GetMouseLocation() - inset
        local origin = TipGui.AbsolutePosition
        local vp = TipGui.AbsoluteSize
        if vp.X <= 0 or vp.Y <= 0 then vp = Vector2.new(1920, 1080) end
        local w, h = Tip.AbsoluteSize.X, Tip.AbsoluteSize.Y
        local x, y = m.X + 16, m.Y + 16
        if x + w > vp.X then x = m.X - w - 16 end
        if y + h > vp.Y then y = vp.Y - h - 4 end
        Tip.Position = UDim2.fromOffset(x - origin.X, y - origin.Y)
    end

    local function HideTip()
        Tip.Visible = false
    end

    local ShinyOn, XLOn = false, false

    local okRem, Remote = pcall(require, RS.Shared.Framework.Network.Remote)
    local ExistIcon = "rbxassetid://133716117246651"
    local ExistColor = Color3.fromRGB(255, 209, 101)
    local ExistCache = {}
    local ExistTTL = 60
    local TipToken = 0

    local function variantName(name, shiny, xl)
        if okPU then
            local ok, n = pcall(function()
                return PetUtil:GetName({ Name = name, Shiny = shiny or nil, XL = xl or nil })
            end)
            if ok and type(n) == "string" then return n end
        end
        return (xl and "XL " or "") .. (shiny and "Shiny " or "") .. name
    end

    local function existText(n)
        n = tonumber(n) or 0
        if n >= 10000 then return abbr(n) .. " Exist" end
        return tostring(math.floor(n)) .. " Exist"
    end

    local function ShowTip(p)
        TipToken += 1
        local myToken = TipToken
        for _, c in ipairs(Tip:GetChildren()) do
            if c:IsA("Frame") then c:Destroy() end
        end

        TipTitle.Text = (XLOn and "XL " or "") .. (ShinyOn and "Shiny " or "") .. p.name
        TipTitle.TextColor3 = RarityColors[p.rarity] or DefaultRarity
        TipSub.Text = tostring(p.rarity or "?")

        local stats = petStats(p.name, ShinyOn, XLOn)
        local keys = {}
        for k in pairs(stats) do table.insert(keys, k) end
        table.sort(keys, function(a, b)
            local oa, ob = StatOrder[a] or 100, StatOrder[b] or 100
            if oa ~= ob then return oa < ob end
            return tostring(a) < tostring(b)
        end)

        if #keys == 0 then
            local Row = Instance.new("Frame")
            Row.BackgroundTransparency = 1
            Row.Size = UDim2.new(1, 0, 0, 18)
            Row.LayoutOrder = 2
            Row.ZIndex = 201
            Row.Parent = Tip
            Label(Row, { Size = UDim2.fromScale(1, 1), Text = "No stats", Font = Enum.Font.Gotham,
                TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 201 })
        end

        for i, k in ipairs(keys) do
            local Row = Instance.new("Frame")
            Row.BackgroundTransparency = 1
            Row.Size = UDim2.new(1, 0, 0, 18)
            Row.LayoutOrder = 1 + i
            Row.ZIndex = 201
            Row.Parent = Tip

            local icon = statIcon(k)
            local textX = 0
            if icon then
                local Ico = Instance.new("ImageLabel")
                Ico.AnchorPoint = Vector2.new(0, 0.5)
                Ico.Position = UDim2.new(0, 0, 0.5, 0)
                Ico.Size = UDim2.fromOffset(18, 18)
                Ico.BackgroundTransparency = 1
                Ico.ScaleType = Enum.ScaleType.Fit
                Ico.Image = icon
                Ico.ZIndex = 201
                Ico.Parent = Row
                textX = 24
            end

            if not icon then
                Label(Row, {
                    Size = UDim2.fromScale(0.58, 1), Text = statName(k), TextColor3 = statColor(k),
                    TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 201,
                })
            end

            Label(Row, {
                Position = icon and UDim2.fromOffset(textX, 0) or UDim2.fromScale(0.58, 0),
                Size = icon and UDim2.new(1, -textX, 1, 0) or UDim2.fromScale(0.42, 1),
                Text = abbr(tonumber(stats[k]) or 0), Font = Enum.Font.GothamBold,
                TextColor3 = icon and statColor(k) or TextColor,
                TextXAlignment = icon and Enum.TextXAlignment.Left or Enum.TextXAlignment.Right,
                ZIndex = 201,
            })
        end

        if okRem then
            local key = variantName(p.name, ShinyOn, XLOn)

            local Row = Instance.new("Frame")
            Row.BackgroundTransparency = 1
            Row.Size = UDim2.new(1, 0, 0, 20)
            Row.LayoutOrder = 100
            Row.ZIndex = 201
            Row.Parent = Tip

            local Ico = Instance.new("ImageLabel")
            Ico.AnchorPoint = Vector2.new(0, 0.5)
            Ico.Position = UDim2.new(0, 0, 0.5, 0)
            Ico.Size = UDim2.fromOffset(18, 18)
            Ico.BackgroundTransparency = 1
            Ico.ScaleType = Enum.ScaleType.Fit
            Ico.Image = ExistIcon
            Ico.ZIndex = 201
            Ico.Parent = Row

            local cached = ExistCache[key]
            local fresh = cached and (os.clock() - cached.t) < ExistTTL
            local ExistLabel = Label(Row, {
                Position = UDim2.fromOffset(24, 0),
                Size = UDim2.new(1, -24, 1, 0),
                Text = cached and existText(cached.value) or "Loading...",
                TextColor3 = ExistColor,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 201,
            })

            if not fresh then
                task.spawn(function()
                    local ok, v = pcall(function() return Remote:InvokeServer("GetExisting", key) end)
                    if not ok then v = nil end
                    local n = tonumber(v) or 0
                    if ok then ExistCache[key] = { value = n, t = os.clock() } end
                    if myToken == TipToken and ExistLabel.Parent then
                        ExistLabel.Text = ok and existText(n) or "—"
                    end
                end)
            end
        end

        Tip.Visible = true
        MoveTip()
        task.defer(MoveTip)
    end

    local ShowEgg, ShowEggList, ShowPet
    local EggCards = {}

    local function BuildEggList()
        for order, e in ipairs(EggList) do
            local Card = Instance.new("Frame")
            Card.BackgroundColor3 = CardColor
            Card.BackgroundTransparency = 0.15
            Card.BorderSizePixel = 0
            Card.LayoutOrder = order
            Card.Parent = EggGrid
            Round(Card, 8)
            local Stroke = Outline(Card, OutlineColor, 1.5, 0.5)

            local Img = Instance.new("ImageLabel")
            Img.AnchorPoint = Vector2.new(0.5, 0)
            Img.Position = UDim2.new(0.5, 0, 0, 8)
            Img.Size = UDim2.fromOffset(64, 64)
            Img.BackgroundTransparency = 1
            Img.ScaleType = Enum.ScaleType.Fit
            Img.Image = e.image or ""
            Img.Parent = Card

            Label(Card, {
                Position = UDim2.fromOffset(4, 76),
                Size = UDim2.new(1, -8, 0, 18),
                Text = e.name,
            })
            Label(Card, {
                Position = UDim2.fromOffset(4, 94),
                Size = UDim2.new(1, -8, 0, 16),
                Text = e.sub,
                Font = Enum.Font.Gotham,
                TextSize = 10,
                TextTransparency = 0.4,
            })

            local Btn = Instance.new("TextButton")
            Btn.Size = UDim2.fromScale(1, 1)
            Btn.BackgroundTransparency = 1
            Btn.Text = ""
            Btn.Parent = Card
            Btn.MouseEnter:Connect(function() Stroke.Transparency = 0 end)
            Btn.MouseLeave:Connect(function() Stroke.Transparency = 0.5 end)
            Btn.MouseButton1Click:Connect(function() ShowEgg(e.name) end)

            table.insert(EggCards, { key = e.name:lower(), frame = Card })
        end
    end

    local PetResultCards = {}
    local PetCardsBuilt = false
    local ApplyFilter

    local function BuildPetResults()
        if PetCardsBuilt then return end
        PetCardsBuilt = true

        for i, rec in ipairs(PetList) do
            if not PetGrid.Parent then return end
            local Accent = RarityColor(rec.rarity)

            local Card = Instance.new("Frame")
            Card.BackgroundColor3 = CardColor
            Card.BackgroundTransparency = 0.15
            Card.BorderSizePixel = 0
            Card.LayoutOrder = 100000 + i
            Card.Visible = false
            Card.Parent = PetGrid
            Round(Card, 8)
            local Stroke = Outline(Card, Accent, 1.5, 0.35)

            local Img = Instance.new("ImageLabel")
            Img.AnchorPoint = Vector2.new(0.5, 0)
            Img.Position = UDim2.new(0.5, 0, 0, 8)
            Img.Size = UDim2.fromOffset(64, 64)
            Img.BackgroundTransparency = 1
            Img.ScaleType = Enum.ScaleType.Fit
            Img.Image = rec.image or ""
            Img.Parent = Card

            Label(Card, {
                Position = UDim2.fromOffset(4, 76),
                Size = UDim2.new(1, -8, 0, 18),
                Text = rec.name,
            })

            local Btn = Instance.new("TextButton")
            Btn.Size = UDim2.fromScale(1, 1)
            Btn.BackgroundTransparency = 1
            Btn.Text = ""
            Btn.Parent = Card
            Btn.MouseEnter:Connect(function() Stroke.Transparency = 0; ShowTip(rec) end)
            Btn.MouseMoved:Connect(MoveTip)
            Btn.MouseLeave:Connect(function() Stroke.Transparency = 0.35; HideTip() end)
            Btn.MouseButton1Click:Connect(function() ShowPet(rec.name) end)

            table.insert(PetResultCards, { key = rec.name:lower(), frame = Card })

            if i % 6 == 0 then task.wait() end
        end

        if Search.Text ~= "" then ApplyFilter() end
    end

    function ApplyFilter()
        HideTip()
        local q = Search.Text:lower():match("^%s*(.-)%s*$")

        local eggs, pets = 0, 0
        for _, c in ipairs(EggCards) do
            local v = q == "" or c.key:find(q, 1, true) ~= nil
            c.frame.Visible = v
            if v then eggs += 1 end
        end

        for _, c in ipairs(PetResultCards) do
            local v = q ~= "" and c.key:find(q, 1, true) ~= nil
            c.frame.Visible = v
            if v then pets += 1 end
        end

        Title.Text = ("All eggs (%d)"):format(#EggList)

        EggBar.Visible = pets > 0 and eggs > 0
        PetBar.Visible = pets > 0
        EggBarText.Text = ("Eggs (%d)"):format(eggs)
        PetBarText.Text = ("Pets (%d)"):format(pets)

        EmptyLabel.Text = "Nothing found"
        EmptyLabel.Visible = (eggs + pets) == 0
        EggScroll.CanvasPosition = Vector2.zero
    end

    local FilterToken = 0
    Search:GetPropertyChangedSignal("Text"):Connect(function()
        FilterToken += 1
        local my = FilterToken
        task.delay(0.15, function()
            if my == FilterToken then ApplyFilter() end
        end)
    end)

    local CurrentEgg

    local function ClearPets()
        HideTip()
        for _, c in ipairs(PetScroll:GetChildren()) do
            if c:IsA("Frame") then c:Destroy() end
        end
    end

    local function RefreshToggles()
        ShinyBtn.BackgroundColor3 = ShinyOn and AccentColor or CardColor
        XLBtn.BackgroundColor3 = XLOn and AccentColor or CardColor
    end

    local function RenderPets()
        local info = eggInfo(CurrentEgg)
        if not info then return end

        ClearPets()

        local pets = {}
        for _, p in ipairs(info.pets) do
            local chance = p.chance
            if ShinyOn then chance = chance * (Constants.ShinyChance / 100) end
            if XLOn then chance = chance * ((Constants.XLChances[p.rarity] or 100) / 100) end
            table.insert(pets, {
                name = p.name,
                rarity = p.rarity,
                chance = chance,
                chanceText = fmtChance(chance),
                image = (ShinyOn and p.shinyImage) or p.image,
            })
        end

        table.sort(pets, function(a, b)
            if a.chance ~= b.chance then return a.chance > b.chance end
            return a.name > b.name
        end)

        for order, p in ipairs(pets) do
            local Accent = RarityColor(p.rarity)

            local Card = Instance.new("Frame")
            Card.BackgroundColor3 = CardColor
            Card.BackgroundTransparency = 0.15
            Card.BorderSizePixel = 0
            Card.LayoutOrder = order
            Card.Parent = PetScroll
            Round(Card, 8)
            Outline(Card, Accent, 1.5, 0.35)

            local Img = Instance.new("ImageLabel")
            Img.AnchorPoint = Vector2.new(0.5, 0)
            Img.Position = UDim2.new(0.5, 0, 0, 8)
            Img.Size = UDim2.fromOffset(60, 60)
            Img.BackgroundTransparency = 1
            Img.ScaleType = Enum.ScaleType.Fit
            Img.Image = p.image or ""
            Img.Parent = Card

            if XLOn then
                Label(Card, {
                    Position = UDim2.fromOffset(6, 4),
                    Size = UDim2.fromOffset(24, 14),
                    Text = "XL",
                    TextSize = 11,
                    TextColor3 = XLColor,
                    TextXAlignment = Enum.TextXAlignment.Left,
                })
            end

            Label(Card, {
                Position = UDim2.fromOffset(4, 72),
                Size = UDim2.new(1, -8, 0, 18),
                Text = p.name,
            })
            Label(Card, {
                Position = UDim2.fromOffset(4, 92),
                Size = UDim2.new(1, -8, 0, 18),
                Text = p.chanceText,
                TextColor3 = Accent,
            })

            local Hover = Instance.new("TextButton")
            Hover.Size = UDim2.fromScale(1, 1)
            Hover.BackgroundTransparency = 1
            Hover.Text = ""
            Hover.Parent = Card
            Hover.MouseEnter:Connect(function() ShowTip(p) end)
            Hover.MouseMoved:Connect(MoveTip)
            Hover.MouseLeave:Connect(HideTip)
        end

        Title.Text = CurrentEgg

        EmptyLabel.Text = "This egg has no pets in its pool"
        EmptyLabel.Visible = #pets == 0
    end

    function ShowEgg(eggName)
        if not eggInfo(eggName) then return end
        CurrentEgg = eggName
        Title.TextColor3 = TextColor
        ShinyOn, XLOn = false, false
        RefreshToggles()
        RenderPets()

        Title.Size = UDim2.new(1, -246, 1, 0)
        PetScroll.CanvasPosition = Vector2.zero
        EggScroll.Visible = false
        PetEggScroll.Visible = false
        PetScroll.Visible = true
        Search.Visible = false
        CloseBtn.Visible = true
        ShinyBtn.Visible = true
        XLBtn.Visible = true
    end

    function ShowPet(petName)
        local rec = PetIndex[petName]
        if not rec then return end
        HideTip()
        ShinyOn, XLOn = false, false

        for _, c in ipairs(PetEggScroll:GetChildren()) do
            if c:IsA("Frame") then c:Destroy() end
        end

        local Accent = RarityColor(rec.rarity)
        for order, r in ipairs(rec.eggs) do
            local Card = Instance.new("Frame")
            Card.BackgroundColor3 = CardColor
            Card.BackgroundTransparency = 0.15
            Card.BorderSizePixel = 0
            Card.LayoutOrder = order
            Card.Parent = PetEggScroll
            Round(Card, 8)
            local Stroke = Outline(Card, OutlineColor, 1.5, 0.5)

            local Img = Instance.new("ImageLabel")
            Img.AnchorPoint = Vector2.new(0.5, 0)
            Img.Position = UDim2.new(0.5, 0, 0, 8)
            Img.Size = UDim2.fromOffset(64, 64)
            Img.BackgroundTransparency = 1
            Img.ScaleType = Enum.ScaleType.Fit
            Img.Image = r.image or ""
            Img.Parent = Card

            Label(Card, {
                Position = UDim2.fromOffset(4, 76),
                Size = UDim2.new(1, -8, 0, 18),
                Text = r.egg,
            })
            Label(Card, {
                Position = UDim2.fromOffset(4, 94),
                Size = UDim2.new(1, -8, 0, 16),
                Text = fmtChance(r.chance),
                TextColor3 = Accent,
            })

            local Btn = Instance.new("TextButton")
            Btn.Size = UDim2.fromScale(1, 1)
            Btn.BackgroundTransparency = 1
            Btn.Text = ""
            Btn.Parent = Card
            Btn.MouseEnter:Connect(function() Stroke.Transparency = 0 end)
            Btn.MouseLeave:Connect(function() Stroke.Transparency = 0.5 end)
            Btn.MouseButton1Click:Connect(function() ShowEgg(r.egg) end)
        end

        Title.TextColor3 = Accent
        Title.Text = #rec.eggs > 0
            and ("%s  •  drops from %d eggs"):format(rec.name, #rec.eggs)
            or ("%s  •  not dropped by any egg"):format(rec.name)
        Title.Size = UDim2.new(1, -112, 1, 0)

        EmptyLabel.Text = "This pet is not dropped by any egg"
        EmptyLabel.Visible = #rec.eggs == 0

        PetEggScroll.CanvasPosition = Vector2.zero
        EggScroll.Visible = false
        PetScroll.Visible = false
        PetEggScroll.Visible = true
        Search.Visible = false
        CloseBtn.Visible = true
        ShinyBtn.Visible = false
        XLBtn.Visible = false
    end

    function ShowEggList()
        HideTip()
        ShinyOn, XLOn = false, false
        Title.TextColor3 = TextColor
        EmptyLabel.Visible = false
        PetScroll.Visible = false
        PetEggScroll.Visible = false
        EggScroll.Visible = true
        CloseBtn.Visible = false
        ShinyBtn.Visible = false
        XLBtn.Visible = false
        Search.Visible = true
        Title.Size = UDim2.new(1, -234, 1, 0)
        ApplyFilter()
    end

    CloseBtn.MouseButton1Click:Connect(ShowEggList)
    ShinyBtn.MouseButton1Click:Connect(function()
        ShinyOn = not ShinyOn
        RefreshToggles()
        RenderPets()
    end)
    XLBtn.MouseButton1Click:Connect(function()
        XLOn = not XLOn
        RefreshToggles()
        RenderPets()
    end)

    BuildEggList()
    ShowEggList()

    task.spawn(function()
        task.wait(1)
        BuildPetResults()
    end)

    local function MakeFullWidth(T)
        local Left, Right = T.Sides[1], T.Sides[2]
        Right.Visible = false

        local function Apply()
            local S = Left.Size
            if S.X.Scale ~= 1 or S.X.Offset ~= 0 then
                Left.Size = UDim2.new(1, 0, S.Y.Scale, S.Y.Offset)
            end
        end

        Apply()
        Left:GetPropertyChangedSignal("Size"):Connect(Apply)
    end

    MakeFullWidth(PetsTab)

    local Groupbox = PetsTab:AddGroupbox({ Side = 1, Name = "List" })
    local Passthrough = Groupbox:AddUIPassthrough("MyScroll", {
        Instance = Root,
        Height = 300,
    })

    local Left = PetsTab.Sides[1]
    local LastHeight

    local function FitHeight()
        local DPI = Library.DPIScale or 1
        local Avail = Left.AbsoluteSize.Y / DPI
        if Avail <= 0 then return end

        local HeaderH = (Groupbox.Container.AbsolutePosition.Y - Groupbox.Holder.AbsolutePosition.Y) / DPI
        local Chrome = HeaderH + 14

        local Height = math.max(60, math.floor(Avail - Chrome - 12))
        if Height ~= LastHeight then
            LastHeight = Height
            Passthrough:SetHeight(Height)
        end
    end

    Left:GetPropertyChangedSignal("AbsoluteSize"):Connect(FitHeight)
    task.defer(FitHeight)

    M.ShowEgg = ShowEgg
    M.ShowPet = ShowPet
    M.ShowEggList = ShowEggList
    M.ApplyFilter = ApplyFilter
    M.Root = Root

    return M
end

return M
