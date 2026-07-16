--// KeyUI Library \\--
--// Simple key-system UI library for Roblox \\--

local Players         = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService    = game:GetService("TweenService")
local RunService      = game:GetService("RunService")
local CoreGui         = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

local KeyUI = {}
KeyUI.__index = KeyUI

--// Util \\--
local function tween(obj, props, t)
    TweenService:Create(obj, TweenInfo.new(t or 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props):Play()
end

local function new(class, props)
    local inst = Instance.new(class)
    for k, v in pairs(props) do
        inst[k] = v
    end
    return inst
end

--// Theme \\--
local Theme = {
    BG          = Color3.fromRGB(18, 18, 18),
    Surface     = Color3.fromRGB(28, 28, 28),
    SurfaceHov  = Color3.fromRGB(36, 36, 36),
    Accent      = Color3.fromRGB(110, 80, 220),
    AccentHov   = Color3.fromRGB(130, 100, 240),
    Outline     = Color3.fromRGB(50, 50, 50),
    OutlineStr  = Color3.fromRGB(70, 70, 70),
    Text        = Color3.fromRGB(230, 230, 230),
    TextDim     = Color3.fromRGB(130, 130, 130),
    Success     = Color3.fromRGB(60, 180, 100),
    Error       = Color3.fromRGB(210, 55, 55),
}

--// ScreenGui \\--
local ScreenGui = new("ScreenGui", {
    Name           = "KeyUI",
    DisplayOrder   = 999,
    ResetOnSpawn   = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
})
pcall(function() ScreenGui.Parent = CoreGui end)
if not ScreenGui.Parent then
    ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

--// Dragging helper \\--
local function makeDraggable(frame, handle)
    local dragging, dragStart, startPos = false, nil, nil

    handle.InputBegan:Connect(function(inp)
        if inp.UserInputType ~= Enum.UserInputType.MouseButton1 and
           inp.UserInputType ~= Enum.UserInputType.Touch then return end
        dragging  = true
        dragStart = inp.Position
        startPos  = frame.Position
    end)

    handle.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or
           inp.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    UserInputService.InputChanged:Connect(function(inp)
        if not dragging then return end
        if inp.UserInputType ~= Enum.UserInputType.MouseMovement and
           inp.UserInputType ~= Enum.UserInputType.Touch then return end
        local delta = inp.Position - dragStart
        frame.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end)
end

--// ────────────────────────────────────────────────────────
--//  KeyUI:CreateWindow
--// ────────────────────────────────────────────────────────
function KeyUI:CreateWindow(opts)
    opts = opts or {}
    local title    = opts.Title    or "KeyUI"
    local width    = opts.Width    or 420
    local position = opts.Position or UDim2.fromOffset(
        math.floor(workspace.CurrentCamera.ViewportSize.X / 2 - width / 2),
        math.floor(workspace.CurrentCamera.ViewportSize.Y / 2 - 160)
    )

    --// Root frame \\--
    local Root = new("Frame", {
        Name              = "Root",
        BackgroundColor3  = Theme.BG,
        BorderSizePixel   = 0,
        Position          = position,
        Size              = UDim2.fromOffset(width, 52),
        ClipsDescendants  = true,
        Parent            = ScreenGui,
    })
    new("UICorner",  { CornerRadius = UDim.new(0, 8),  Parent = Root })
    new("UIStroke",  { Color = Theme.Outline, Thickness = 1, Parent = Root })

    --// Top bar \\--
    local TopBar = new("Frame", {
        Name             = "TopBar",
        BackgroundColor3 = Theme.Surface,
        BorderSizePixel  = 0,
        Size             = UDim2.new(1, 0, 0, 52),
        Parent           = Root,
    })
    new("UICorner", { CornerRadius = UDim.new(0, 8), Parent = TopBar })
    -- cover bottom corners so they don't show through
    new("Frame", {
        BackgroundColor3 = Theme.Surface,
        BorderSizePixel  = 0,
        Position         = UDim2.fromOffset(0, 40),
        Size             = UDim2.new(1, 0, 0, 12),
        Parent           = TopBar,
    })

    --// Title label \\--
    local TitleLabel = new("TextLabel", {
        BackgroundTransparency = 1,
        Position               = UDim2.fromOffset(14, 0),
        Size                   = UDim2.new(1, -60, 1, 0),
        Font                   = Enum.Font.GothamBold,
        Text                   = title,
        TextColor3             = Theme.Text,
        TextSize               = 15,
        TextXAlignment         = Enum.TextXAlignment.Left,
        Parent                 = TopBar,
    })

    --// Tab buttons row \\--
    local TabRow = new("Frame", {
        Name             = "TabRow",
        BackgroundColor3 = Theme.BG,
        BorderSizePixel  = 0,
        Position         = UDim2.fromOffset(0, 52),
        Size             = UDim2.new(1, 0, 0, 38),
        Parent           = Root,
    })
    new("UIListLayout", {
        FillDirection      = Enum.FillDirection.Horizontal,
        HorizontalFlex     = Enum.UIFlexAlignment.Fill,
        SortOrder          = Enum.SortOrder.LayoutOrder,
        Parent             = TabRow,
    })
    new("Frame", {  -- bottom divider
        BackgroundColor3 = Theme.Outline,
        BorderSizePixel  = 0,
        AnchorPoint      = Vector2.new(0, 1),
        Position         = UDim2.fromScale(0, 1),
        Size             = UDim2.new(1, 0, 0, 1),
        Parent           = TabRow,
    })

    --// Content area \\--
    local ContentArea = new("Frame", {
        Name             = "ContentArea",
        BackgroundTransparency = 1,
        Position         = UDim2.fromOffset(0, 90),
        Size             = UDim2.new(1, 0, 1, -90),
        ClipsDescendants = true,
        Parent           = Root,
    })

    makeDraggable(Root, TopBar)

    --// Window object \\--
    local Window = {
        Root        = Root,
        TabRow      = TabRow,
        ContentArea = ContentArea,
        Tabs        = {},
        ActiveTab   = nil,
        _tabOrder   = 0,
    }

    --// Expand root height whenever a tab is shown \\--
    function Window:_recalcHeight(page)
        local list = page:FindFirstChildOfClass("UIListLayout")
        local h = list and list.AbsoluteContentSize.Y or 0
        tween(Root, { Size = UDim2.fromOffset(width, 90 + h + 16) }, 0.2)
    end

    --// AddTab \\--
    function Window:AddTab(tabOpts)
        tabOpts = tabOpts or {}
        local tabName = tabOpts.Name or ("Tab " .. (self._tabOrder + 1))
        self._tabOrder += 1
        local order = self._tabOrder

        --// Tab button \\--
        local TabBtn = new("TextButton", {
            Name                  = tabName,
            BackgroundColor3      = Theme.BG,
            BackgroundTransparency = 0,
            BorderSizePixel       = 0,
            Size                  = UDim2.fromOffset(0, 38), -- width handled by flex
            Font                  = Enum.Font.Gotham,
            Text                  = tabName,
            TextColor3            = Theme.TextDim,
            TextSize              = 13,
            AutoButtonColor       = false,
            LayoutOrder           = order,
            Parent                = TabRow,
        })
        -- accent underline
        local Underline = new("Frame", {
            BackgroundColor3 = Theme.Accent,
            BackgroundTransparency = 1,
            BorderSizePixel  = 0,
            AnchorPoint      = Vector2.new(0, 1),
            Position         = UDim2.fromScale(0, 1),
            Size             = UDim2.new(1, 0, 0, 2),
            Parent           = TabBtn,
        })

        --// Tab page \\--
        local Page = new("ScrollingFrame", {
            Name                    = tabName .. "Page",
            BackgroundTransparency  = 1,
            BorderSizePixel         = 0,
            Position                = UDim2.fromScale(0, 0),
            Size                    = UDim2.fromScale(1, 1),
            CanvasSize              = UDim2.fromScale(0, 0),
            AutomaticCanvasSize     = Enum.AutomaticSize.Y,
            ScrollBarThickness      = 2,
            ScrollBarImageColor3    = Theme.Outline,
            Visible                 = false,
            Parent                  = ContentArea,
        })
        local PageList = new("UIListLayout", {
            Padding     = UDim.new(0, 8),
            SortOrder   = Enum.SortOrder.LayoutOrder,
            Parent      = Page,
        })
        new("UIPadding", {
            PaddingLeft   = UDim.new(0, 12),
            PaddingRight  = UDim.new(0, 12),
            PaddingTop    = UDim.new(0, 10),
            PaddingBottom = UDim.new(0, 10),
            Parent        = Page,
        })

        PageList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            if self.ActiveTab == Tab then
                self:_recalcHeight(Page)
            end
        end)

        --// Tab object \\--
        local Tab = { Page = Page, Button = TabBtn, Window = self, _elemOrder = 0 }

        local function activate()
            -- deactivate previous
            if self.ActiveTab and self.ActiveTab ~= Tab then
                self.ActiveTab.Page.Visible = false
                tween(self.ActiveTab.Button, { TextColor3 = Theme.TextDim }, 0.12)
                tween(self.ActiveTab._underline, { BackgroundTransparency = 1 }, 0.12)
            end
            -- activate
            Tab.Page.Visible = true
            tween(TabBtn,    { TextColor3 = Theme.Text }, 0.12)
            tween(Underline, { BackgroundTransparency = 0 }, 0.12)
            self.ActiveTab  = Tab
            self:_recalcHeight(Page)
        end

        Tab._underline = Underline

        TabBtn.MouseButton1Click:Connect(activate)
        TabBtn.MouseEnter:Connect(function()
            if self.ActiveTab ~= Tab then
                tween(TabBtn, { TextColor3 = Theme.Text }, 0.1)
            end
        end)
        TabBtn.MouseLeave:Connect(function()
            if self.ActiveTab ~= Tab then
                tween(TabBtn, { TextColor3 = Theme.TextDim }, 0.1)
            end
        end)

        -- auto-show first tab
        if not self.ActiveTab then
            activate()
        end

        --// ── Elements ──────────────────────────────────────

        --// AddLabel \\--
        function Tab:AddLabel(text)
            local lbl = new("TextLabel", {
                BackgroundTransparency = 1,
                Size                   = UDim2.new(1, 0, 0, 18),
                Font                   = Enum.Font.Gotham,
                Text                   = text or "",
                TextColor3             = Theme.TextDim,
                TextSize               = 13,
                TextXAlignment         = Enum.TextXAlignment.Left,
                LayoutOrder            = self._elemOrder,
                Parent                 = Page,
            })
            self._elemOrder += 1

            local Lbl = {}
            function Lbl:SetText(t) lbl.Text = t end
            function Lbl:SetColor(c) lbl.TextColor3 = c end
            return Lbl
        end

        --// AddInput + Button side-by-side \\--
        -- opts.ButtonText   — label on the button (default "Submit")
        -- opts.Placeholder  — placeholder text
        -- opts.Callback     — function(text) called on button click or Enter
        -- opts.Password     — bool, masks input with dots
        function Tab:AddInputButton(opts2)
            opts2 = opts2 or {}
            local btnText   = opts2.ButtonText  or "Submit"
            local placeholder = opts2.Placeholder or ""
            local onSubmit  = opts2.Callback     or function() end
            local isPass    = opts2.Password      or false

            local ROW_H = 36

            local Holder = new("Frame", {
                BackgroundTransparency = 1,
                Size                   = UDim2.new(1, 0, 0, ROW_H),
                LayoutOrder            = self._elemOrder,
                Parent                 = Page,
            })
            self._elemOrder += 1

            -- measure button text width
            local textSvc = game:GetService("TextService")
            local params = Instance.new("GetTextBoundsParams")
            params.Text  = btnText
            params.Font  = Font.fromEnum(Enum.Font.GothamBold)
            params.Size  = 13
            params.Width = 400
            local bw = math.max(textSvc:GetTextBoundsAsync(params).X + 24, 72)

            --// Input box \\--
            local InputFrame = new("Frame", {
                BackgroundColor3 = Theme.Surface,
                BorderSizePixel  = 0,
                Size             = UDim2.new(1, -(bw + 6), 1, 0),
                Parent           = Holder,
            })
            new("UICorner", { CornerRadius = UDim.new(0, 6), Parent = InputFrame })
            new("UIStroke", { Color = Theme.Outline, Thickness = 1, Parent = InputFrame })

            local TextBox = new("TextBox", {
                BackgroundTransparency = 1,
                BorderSizePixel        = 0,
                Position               = UDim2.fromOffset(10, 0),
                Size                   = UDim2.new(1, -10, 1, 0),
                Font                   = Enum.Font.Gotham,
                PlaceholderText        = placeholder,
                PlaceholderColor3      = Theme.TextDim,
                Text                   = "",
                TextColor3             = Theme.Text,
                TextSize               = 13,
                TextXAlignment         = Enum.TextXAlignment.Left,
                ClearTextOnFocus       = false,
                Parent                 = InputFrame,
            })

            if isPass then
                -- mask with bullets on change
                local realText = ""
                TextBox:GetPropertyChangedSignal("Text"):Connect(function()
                    local raw = TextBox.Text
                    if #raw < #realText then
                        realText = realText:sub(1, #raw)
                    else
                        realText = realText .. raw:sub(#realText + 1)
                    end
                    TextBox.Text = string.rep("•", #realText)
                    -- move cursor to end
                    TextBox.CursorPosition = #TextBox.Text + 1
                end)

                -- override getValue to return real text
                TextBox._getRealText = function() return realText end
            end

            -- focus highlight
            TextBox.Focused:Connect(function()
                tween(InputFrame, { BackgroundColor3 = Theme.SurfaceHov }, 0.12)
                tween(InputFrame:FindFirstChildOfClass("UIStroke"), { Color = Theme.OutlineStr }, 0.12)
            end)
            TextBox.FocusLost:Connect(function(enter)
                tween(InputFrame, { BackgroundColor3 = Theme.Surface }, 0.12)
                tween(InputFrame:FindFirstChildOfClass("UIStroke"), { Color = Theme.Outline }, 0.12)
                if enter then
                    local val = TextBox._getRealText and TextBox._getRealText() or TextBox.Text
                    onSubmit(val)
                end
            end)

            --// Button \\--
            local Btn = new("TextButton", {
                AnchorPoint      = Vector2.new(1, 0),
                BackgroundColor3 = Theme.Accent,
                BorderSizePixel  = 0,
                Position         = UDim2.fromScale(1, 0),
                Size             = UDim2.fromOffset(bw, ROW_H),
                Font             = Enum.Font.GothamBold,
                Text             = btnText,
                TextColor3       = Color3.new(1, 1, 1),
                TextSize         = 13,
                AutoButtonColor  = false,
                Parent           = Holder,
            })
            new("UICorner", { CornerRadius = UDim.new(0, 6), Parent = Btn })

            Btn.MouseEnter:Connect(function()
                tween(Btn, { BackgroundColor3 = Theme.AccentHov }, 0.1)
            end)
            Btn.MouseLeave:Connect(function()
                tween(Btn, { BackgroundColor3 = Theme.Accent }, 0.1)
            end)
            Btn.MouseButton1Click:Connect(function()
                local val = TextBox._getRealText and TextBox._getRealText() or TextBox.Text
                onSubmit(val)
            end)

            --// Return object \\--
            local Elem = {}
            function Elem:GetText()
                return TextBox._getRealText and TextBox._getRealText() or TextBox.Text
            end
            function Elem:SetText(t)
                if isPass then
                    TextBox._getRealText = function() return t end
                    TextBox.Text = string.rep("•", #t)
                else
                    TextBox.Text = t
                end
            end
            function Elem:SetButtonText(t) Btn.Text = t end
            function Elem:SetButtonColor(c) Btn.BackgroundColor3 = c end
            function Elem:SetEnabled(v)
                Btn.Active = v
                tween(Btn, { BackgroundTransparency = v and 0 or 0.5 }, 0.12)
                TextBox.TextEditable = v
            end
            return Elem
        end

        --// AddButton (standalone) \\--
        function Tab:AddButton(opts2)
            opts2 = opts2 or {}
            local text2  = opts2.Text     or "Button"
            local cb     = opts2.Callback or function() end
            local risky  = opts2.Risky    or false

            local Btn = new("TextButton", {
                BackgroundColor3 = risky and Theme.Error or Theme.Surface,
                BorderSizePixel  = 0,
                Size             = UDim2.new(1, 0, 0, 36),
                Font             = Enum.Font.GothamBold,
                Text             = text2,
                TextColor3       = Theme.Text,
                TextSize         = 13,
                AutoButtonColor  = false,
                LayoutOrder      = self._elemOrder,
                Parent           = Page,
            })
            new("UICorner", { CornerRadius = UDim.new(0, 6), Parent = Btn })
            new("UIStroke",  { Color = risky and Theme.Error or Theme.Outline, Thickness = 1, Parent = Btn })
            self._elemOrder += 1

            local normColor = risky and Theme.Error or Theme.Surface
            local hovColor  = risky
                and Color3.fromRGB(170, 40, 40)
                or Theme.SurfaceHov

            Btn.MouseEnter:Connect(function()
                tween(Btn, { BackgroundColor3 = hovColor }, 0.1)
            end)
            Btn.MouseLeave:Connect(function()
                tween(Btn, { BackgroundColor3 = normColor }, 0.1)
            end)
            Btn.MouseButton1Click:Connect(function()
                cb()
            end)

            local Elem = {}
            function Elem:SetText(t)  Btn.Text = t end
            function Elem:SetEnabled(v)
                Btn.Active = v
                tween(Btn, { BackgroundTransparency = v and 0 or 0.5 }, 0.12)
            end
            return Elem
        end

        --// AddDivider \\--
        function Tab:AddDivider(label)
            local h = label and 22 or 10
            local Holder = new("Frame", {
                BackgroundTransparency = 1,
                Size                   = UDim2.new(1, 0, 0, h),
                LayoutOrder            = self._elemOrder,
                Parent                 = Page,
            })
            self._elemOrder += 1

            new("Frame", {
                BackgroundColor3 = Theme.Outline,
                AnchorPoint      = Vector2.new(0, 0.5),
                Position         = label and UDim2.fromScale(0, 0.5) or UDim2.new(0, 0, 0.5, 0),
                Size             = label and UDim2.new(0.35, 0, 0, 1) or UDim2.new(1, 0, 0, 1),
                Parent           = Holder,
            })
            if label then
                new("TextLabel", {
                    AnchorPoint            = Vector2.new(0.5, 0.5),
                    BackgroundTransparency = 1,
                    Position               = UDim2.fromScale(0.5, 0.5),
                    Size                   = UDim2.fromOffset(120, h),
                    Font                   = Enum.Font.Gotham,
                    Text                   = label,
                    TextColor3             = Theme.TextDim,
                    TextSize               = 12,
                    Parent                 = Holder,
                })
                new("Frame", {
                    BackgroundColor3 = Theme.Outline,
                    AnchorPoint      = Vector2.new(1, 0.5),
                    Position         = UDim2.fromScale(1, 0.5),
                    Size             = UDim2.new(0.35, 0, 0, 1),
                    Parent           = Holder,
                })
            end
        end

        self.Tabs[tabName] = Tab
        return Tab
    end

    --// Destroy \\--
    function Window:Destroy()
        ScreenGui:Destroy()
    end

    return Window
end

--// ────────────────────────────────────────────────────────
--//  KeyUI:CreateKeySystem
--//  Shows a modal overlay for key verification before
--//  calling onSuccess().
--// ────────────────────────────────────────────────────────
function KeyUI:CreateKeySystem(opts)
    opts = opts or {}
    local title      = opts.Title       or "Key Required"
    local subtitle   = opts.Subtitle    or "Enter your access key to continue."
    local validKey   = opts.Key         or "FREE"
    local onSuccess  = opts.OnSuccess   or function() end
    local onFail     = opts.OnFail      or function() end
    local btnText    = opts.ButtonText  or "Verify"
    local link       = opts.Link        or nil   -- optional "Get key" link label

    local W = workspace.CurrentCamera.ViewportSize

    --// Overlay \\--
    local Overlay = new("Frame", {
        BackgroundColor3     = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 0.5,
        BorderSizePixel      = 0,
        Size                 = UDim2.fromScale(1, 1),
        ZIndex               = 100,
        Parent               = ScreenGui,
    })

    --// Card \\--
    local CARD_W, CARD_H = 360, 220
    local Card = new("Frame", {
        AnchorPoint      = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Theme.BG,
        BorderSizePixel  = 0,
        Position         = UDim2.fromScale(0.5, 0.5),
        Size             = UDim2.fromOffset(CARD_W, CARD_H),
        ZIndex           = 101,
        Parent           = Overlay,
    })
    new("UICorner", { CornerRadius = UDim.new(0, 10), Parent = Card })
    new("UIStroke",  { Color = Theme.OutlineStr, Thickness = 1, Parent = Card })

    makeDraggable(Card, Card)

    --// Header strip \\--
    local Header = new("Frame", {
        BackgroundColor3 = Theme.Surface,
        BorderSizePixel  = 0,
        Size             = UDim2.new(1, 0, 0, 56),
        ZIndex           = 101,
        Parent           = Card,
    })
    new("UICorner", { CornerRadius = UDim.new(0, 10), Parent = Header })
    new("Frame", {  -- cover bottom corners
        BackgroundColor3 = Theme.Surface,
        BorderSizePixel  = 0,
        Position         = UDim2.fromOffset(0, 44),
        Size             = UDim2.new(1, 0, 0, 12),
        ZIndex           = 101,
        Parent           = Header,
    })

    -- accent dot
    new("Frame", {
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel  = 0,
        Position         = UDim2.fromOffset(14, 20),
        Size             = UDim2.fromOffset(8, 8),
        ZIndex           = 102,
        Parent           = Header,
    }):FindFirstChildOfClass("UICorner") or new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = Header:FindFirstChild("Frame") or Header })
    -- fix: attach corner to the dot
    do
        local dot = Header:GetChildren()[3]  -- third child is dot
        if dot then
            new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = dot })
        end
    end

    new("TextLabel", {
        BackgroundTransparency = 1,
        Position               = UDim2.fromOffset(30, 10),
        Size                   = UDim2.new(1, -44, 0, 20),
        Font                   = Enum.Font.GothamBold,
        Text                   = title,
        TextColor3             = Theme.Text,
        TextSize               = 15,
        TextXAlignment         = Enum.TextXAlignment.Left,
        ZIndex                 = 102,
        Parent                 = Header,
    })
    new("TextLabel", {
        BackgroundTransparency = 1,
        Position               = UDim2.fromOffset(30, 30),
        Size                   = UDim2.new(1, -44, 0, 16),
        Font                   = Enum.Font.Gotham,
        Text                   = subtitle,
        TextColor3             = Theme.TextDim,
        TextSize               = 12,
        TextXAlignment         = Enum.TextXAlignment.Left,
        ZIndex                 = 102,
        Parent                 = Header,
    })

    --// Input row \\--
    local ROW_H = 36
    local BW    = 80

    local InputFrame = new("Frame", {
        BackgroundColor3 = Theme.Surface,
        BorderSizePixel  = 0,
        Position         = UDim2.fromOffset(14, 72),
        Size             = UDim2.fromOffset(CARD_W - 28 - BW - 6, ROW_H),
        ZIndex           = 102,
        Parent           = Card,
    })
    new("UICorner", { CornerRadius = UDim.new(0, 6), Parent = InputFrame })
    local InStroke = new("UIStroke", { Color = Theme.Outline, Thickness = 1, Parent = InputFrame })

    local KeyBox = new("TextBox", {
        BackgroundTransparency = 1,
        BorderSizePixel        = 0,
        Position               = UDim2.fromOffset(10, 0),
        Size                   = UDim2.new(1, -10, 1, 0),
        Font                   = Enum.Font.Code,
        PlaceholderText        = "Enter key…",
        PlaceholderColor3      = Theme.TextDim,
        Text                   = "",
        TextColor3             = Theme.Text,
        TextSize               = 13,
        ClearTextOnFocus       = false,
        ZIndex                 = 103,
        Parent                 = InputFrame,
    })
    KeyBox.Focused:Connect(function()
        tween(InputFrame, { BackgroundColor3 = Theme.SurfaceHov }, 0.12)
        tween(InStroke,   { Color = Theme.OutlineStr }, 0.12)
    end)
    KeyBox.FocusLost:Connect(function()
        tween(InputFrame, { BackgroundColor3 = Theme.Surface }, 0.12)
        tween(InStroke,   { Color = Theme.Outline }, 0.12)
    end)

    --// Verify button \\--
    local VerifyBtn = new("TextButton", {
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel  = 0,
        Position         = UDim2.fromOffset(CARD_W - 14 - BW, 72),
        Size             = UDim2.fromOffset(BW, ROW_H),
        Font             = Enum.Font.GothamBold,
        Text             = btnText,
        TextColor3       = Color3.new(1, 1, 1),
        TextSize         = 13,
        AutoButtonColor  = false,
        ZIndex           = 102,
        Parent           = Card,
    })
    new("UICorner", { CornerRadius = UDim.new(0, 6), Parent = VerifyBtn })
    VerifyBtn.MouseEnter:Connect(function()
        tween(VerifyBtn, { BackgroundColor3 = Theme.AccentHov }, 0.1)
    end)
    VerifyBtn.MouseLeave:Connect(function()
        tween(VerifyBtn, { BackgroundColor3 = Theme.Accent }, 0.1)
    end)

    --// Status label \\--
    local StatusLabel = new("TextLabel", {
        BackgroundTransparency = 1,
        Position               = UDim2.fromOffset(14, 118),
        Size                   = UDim2.fromOffset(CARD_W - 28, 20),
        Font                   = Enum.Font.Gotham,
        Text                   = "",
        TextColor3             = Theme.TextDim,
        TextSize               = 12,
        TextXAlignment         = Enum.TextXAlignment.Left,
        ZIndex                 = 102,
        Parent                 = Card,
    })

    --// Optional "Get key" hint \\--
    if link then
        new("TextLabel", {
            BackgroundTransparency = 1,
            Position               = UDim2.fromOffset(14, 142),
            Size                   = UDim2.fromOffset(CARD_W - 28, 16),
            Font                   = Enum.Font.Gotham,
            Text                   = link,
            TextColor3             = Theme.TextDim,
            TextSize               = 11,
            TextXAlignment         = Enum.TextXAlignment.Left,
            ZIndex                 = 102,
            Parent                 = Card,
        })
    end

    --// Verify logic \\--
    local verified = false
    local function doVerify()
        if verified then return end
        local entered = KeyBox.Text

        if entered == validKey then
            verified = true
            tween(StatusLabel, { TextColor3 = Theme.Success }, 0.1)
            StatusLabel.Text = "✓  Access granted"
            tween(VerifyBtn,   { BackgroundColor3 = Theme.Success }, 0.15)

            task.delay(0.8, function()
                -- fade out overlay
                tween(Overlay, { BackgroundTransparency = 1 }, 0.3)
                tween(Card,    { BackgroundTransparency = 1 }, 0.3)
                task.wait(0.35)
                Overlay:Destroy()
                onSuccess()
            end)
        else
            tween(StatusLabel, { TextColor3 = Theme.Error }, 0.1)
            StatusLabel.Text = "✗  Invalid key — try again"
            -- shake card
            local origPos = Card.Position
            local ox = origPos.X.Offset
            for _, dx in ipairs({ 6, -6, 4, -4, 2, -2, 0 }) do
                Card.Position = UDim2.fromOffset(ox + dx, origPos.Y.Offset)
                task.wait(0.04)
            end
            onFail(entered)
        end
    end

    VerifyBtn.MouseButton1Click:Connect(doVerify)
    KeyBox.FocusLost:Connect(function(enter)
        if enter then doVerify() end
    end)

    return {
        Overlay = Overlay,
        Card    = Card,
        Dismiss = function()
            Overlay:Destroy()
        end,
    }
end

return KeyUI
