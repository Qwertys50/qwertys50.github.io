local plr = game.Players.LocalPlayer
local EncodingService = cloneref(game:GetService("EncodingService"))
local ht = game:GetService("HttpService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PresentRainUtil = require(ReplicatedStorage.Shared.Utils.PresentRainUtil)
local MarkerFolder = PresentRainUtil.MarkerFolder

local render = workspace.Rendered
local sell_obj = workspace.Worlds["The Overworld"].Sell

local remoteEvent = ReplicatedStorage.Shared.Framework.Network.Remote.RemoteEvent
local Remote = require(ReplicatedStorage.Shared.Framework.Network.Remote)

local HatchEggModule = require(ReplicatedStorage.Client.Effects.HatchEgg)
local Eggs = require(game.ReplicatedStorage.Shared.Data.Eggs)
local ItemUtil = require(ReplicatedStorage.Shared.Utils.Stats.ItemUtil)
local Shops = require(ReplicatedStorage.Shared.Data.Shops)

local Time = require(game:GetService("ReplicatedStorage").Shared.Framework.Utilities.Math.Time)
local Minigames = require(game:GetService("ReplicatedStorage").Shared.Data.Minigames)

local originalPlay = nil
local disable_egg_animation = false

local LocalData = require(ReplicatedStorage.Client.Framework.Services.LocalData)
local ShopUtil = require(ReplicatedStorage.Shared.Utils.ShopUtil)

local MainEvent = game:GetService("ReplicatedStorage").Shared.Framework.Network.Remote.RemoteEvent

local status_text = "None"


local is_path = {
    auto_buy = false,
    auto_rebirth = false,
    auto_claim_chest = false,
    auto_play_mini_game = false,
    auto_blow_bubble = false,
    auto_open_egg = false
}

local function getMinigameCooldown(name)
    local data = LocalData:Get()
    if not data then return nil end
    local left = math.max((data.Cooldowns[name] or 0) - Time.now(), 0)
    return left
end


local PRIORITY_NAMES = {
    auto_play_mini_game = "Mini Game",
    auto_rebirth = "Auto Rebirth",
    auto_buy = "Auto Buy Shop",
    auto_open_egg = "Open Eggs",
    auto_blow_bubble = "Blow Bubble",
}

local DEFAULT_PRIORITY = {
    "auto_play_mini_game",
    "auto_rebirth",
    "auto_buy",
    "auto_open_egg",
    "auto_blow_bubble",
}

local priority_order = table.clone(DEFAULT_PRIORITY)

local function IsPathTr(ignore)
    if ignore == "auto_claim_chest" then return false end
    if is_path.auto_claim_chest then return true end

    local idx = table.find(priority_order, ignore)
    if not idx then
        for k, v in is_path do
            if k ~= ignore and v then return true end
        end
        return false
    end

    for i = 1, idx - 1 do
        if is_path[priority_order[i]] then return true end
    end
    return false
end


local meta = getmetatable(HatchEggModule) or HatchEggModule
if meta and meta.Play then
    originalPlay = meta.Play
    meta.Play = function(...)
        if disable_egg_animation then
            return nil
        else
            return originalPlay(...)
        end
    end
end

local opened_egg_value = ""

local if_open_egg = false
local if_bubble = false
local auto_sell_bubble = false
local auto_collect_coin = false
local auto_collect_event_chest = false
local auto_play_mini_game = false

local auto_best_event_egg = false

local best_event_egg = "Creaking Egg"

local auto_house = false

local is_sell = false
local last_sell_time = 0

local auto_rebirth = false
local rebirth_ready_since = nil
local is_rebirthing = false
local pickupChunker

local all_coins = {}

local shops = {["dice-shop"]="Dice Shop", ["alien-shop"]="Alien Shop", ["shard-shop"]="Blackmarket"}
local mini_games = {"Pet Match", "Robot Claw", "Hyper Darts", "Cart Escape"}
local mini_games_ = {"Easy", "Medium", "Hard", "Insane"}

local selected_minigame = nil
local last_connected_game = os.clock()
local selected_minigame_ = "Easy"

local ended_minigame = os.time()
local selected_shop = {}

local is_selling = false

local function findChunkers(folder)
    local chunker = nil
    
    for _, child in ipairs(folder:GetChildren()) do

        if child.Name:match("%x+-%x+-%x+-%x+-%x+") then
            return child.Parent
        end
        
        if child:IsA("Model") or child:IsA("Folder") then
            local nestedFound = findChunkers(child)
            if nestedFound then return nestedFound end
        end
    end
    
    return chunker
end

local function getPickupChunker()
    if pickupChunker then return pickupChunker end
    local folder = findChunkers(workspace.Rendered)
    if not folder then return nil end
    for _, t in ipairs(getgc(true)) do
        if type(t) == "table"
            and type(rawget(t, "_chunks")) == "table"
            and rawget(t, "_folder") == folder then
            pickupChunker = t
            return t
        end
    end
end

local function pickupChunker()
    for _, t in ipairs(getgc(true)) do
        if type(t) == "table" and type(rawget(t, "_chunks")) == "table" and rawget(t, "_chunkSize") and rawget(t, "Loaded") then
            local ok, conns = pcall(getconnections, t.Loaded._bindable.Event)
            local f = ok and conns[1] and conns[1].Function

            if f and table.find(debug.getconstants(f), "Animated") then return t end
        end
    end
end

print(1)

local function GetChunkEgg()
    for _, t in ipairs(getgc(true)) do
        if type(t) == "table" and type(rawget(t, "_chunks")) == "table" and rawget(t, "_chunkSize") and rawget(t, "Loaded") then
            local ok, conns = pcall(getconnections, t.Loaded._bindable.Event)
            local f = ok and conns[1] and conns[1].Function
            if f and table.find(debug.getconstants(f), "Coming Soon") then return t end
        end
    end
end

local e_ = GetChunkEgg()

local function eggPos(name)
    for _, l in pairs(e_._chunks) do
        for _, m in pairs(l) do
            if typeof(m) == "Instance" and m.Name == name then
                return m:GetPivot().Position
            end
        end
    end
end

local chunk_money = pickupChunker()._folder
print(chunk_money)

local function SellBubble()
    if is_selling then return end
    is_selling = true

    local last_pos = plr.Character.PrimaryPart.CFrame

    plr.Character.PrimaryPart.CFrame = sell_obj:GetPivot()

    is_sell = false
    while not is_sell and task.wait(0.1) do
        remoteEvent:FireServer("SellBubble")
    end

    plr.Character.PrimaryPart.CFrame = last_pos

    is_sell = false
    is_selling = false
end

local function BlowBubble() 
    ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Framework"):WaitForChild("Network"):WaitForChild("Remote"):WaitForChild("RemoteEvent"):FireServer(unpack({[1] = "BlowBubble"})) 
end

local function getBubbleMax()
    local label = game:GetService("Players").LocalPlayer.PlayerGui.ScreenGui.HUD.Left.Currency.Bubble.Frame.Label
    local text = label.Text

    local cleanText = text:gsub("<[^>]*>", "")
    local numStr = cleanText:match("/%s*([%d,]+)")

    if numStr then
        local withoutCommas = numStr:gsub(",", "")
        return tonumber(withoutCommas)
    end

    return 0
end

local function GetMyBubble()

    return ht:JSONDecode(plr:GetAttribute("Bubble"))["Amount"]
end

local function GetAllEggs()
    local seen = {}
    for _, l in pairs(e_._chunks) do
        for _, m in pairs(l) do
            if typeof(m) == "Instance" and type(Eggs[m.Name]) == "table" then seen[m.Name] = true end
        end
    end
    local n = {} for k in pairs(seen) do n[#n + 1] = k end table.sort(n)
    return n

end


local function getRebirthProgress()
    local ok, fill = pcall(function()
        return game:GetService("Players").LocalPlayer.PlayerGui.ScreenGui.HalloweenRebirth.Frame.Inner.Frame.Progress.Fill
    end)

    if ok and fill then
        return fill.Size.X.Scale
    end

    return nil
end

local function DoRebirth()
    ReplicatedStorage.Shared.Framework.Network.Remote.RemoteEvent:FireServer("HalloweenRebirth")
end

local function FindEggsFolder()

    for _, i in ipairs(render:GetChildren()) do

        if i.Name == "Chunker" then

            for _, q in ipairs(i:GetChildren()) do

                if string.find(q.Name, "Egg") then

                    return i
                end
            end
        end
    end
end

local chunk_egg = FindEggsFolder()

local function GetEggs()
    local s = {}

    for _, i in ipairs(chunk_egg:GetChildren()) do
        if i.Name == "Coming Soon" then continue end

        if not table.find(s, i) then
            table.insert(s, i.Name)
        end
    end

    return s
end

local function deepEqual(a, b)
    if a == b then return true end
    if type(a) ~= "table" or type(b) ~= "table" then
        return false
    end
    for k, v in pairs(a) do
        if not deepEqual(v, b[k]) then
            return false
        end
    end
    for k in pairs(b) do
        if a[k] == nil then
            return false
        end
    end
    return true
end

local function silenceMinigameUI()
    local t2
    for _, v in ipairs(debug.getupvalues(Remote.Event)) do
        if type(v) == "table" then
            t2 = v
            break
        end
    end
    if not t2 then
        warn("[CartEscape] не нашёл таблицу событий Remote")
        return
    end

    for _, name in ipairs({ "StartMinigame", "FinishMinigame", "MinigameStateChanged" }) do
        local bindable = t2[name]
        if bindable then
            for _, c in ipairs(getconnections(bindable.Event)) do
                local src = tostring(debug.info(c.Function, "s"))
                if src:find("Gui.Frames.Minigames", 1, true) then
                    c:Disable()
                end
            end
        end
    end
end

local function isInMinigame(name)
    local env = getgenv()
    if not env.MinigameTracker then
        local Remote = require(game:GetService("ReplicatedStorage").Shared.Framework.Network.Remote)
        local T = {active = nil}
        env.MinigameTracker = T
        Remote.Event("StartMinigame"):Connect(function(info) T.active = info end)
        Remote.Event("FinishMinigame"):Connect(function() T.active = nil end)
    end
    local a = env.MinigameTracker.active
    if not a then return false end
    return name == nil or a.Name == name
end

silenceMinigameUI()


Remote.Event("BubbleSold"):Connect(function(f)
    if plr.Name == f then
        is_sell = true
    end
end)

chunk_money.ChildAdded:Connect(function(i)
	if auto_collect_coin then
		table.insert(all_coins, i)
	end
end)

local is_collected = false


MarkerFolder.ChildAdded:Connect(function(child)

    if is_collected then return end
    is_collected = true
    
    task.wait(1)

    for _, p1 in ipairs(MarkerFolder:GetChildren()) do

        task.wait(0.1)
        ReplicatedStorage.Shared.Framework.Network.Remote.RemoteEvent:FireServer(
            "CollectPresentRain", p1.Name
        )
    end

    is_collected = false

end)

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/deividcomsono/Obsidian/refs/heads/main/Library.lua"))()
Options = Library.Options

local Window = Library:CreateWindow({
    Title = "mspaint",
    Footer = "version: example",
    Icon = 95816097006870,
    NotifySide = "Right",
    ToggleKeybind = Enum.KeyCode.LeftControl
})
local Tab = Window:AddTab("Main", "user")
local PetsTab = Window:AddTab("Pets", "paw-print")
local SettingsTab = Window:AddTab("Settings", "settings")

local EggBrowser = loadstring(game:HttpGet("https://raw.githubusercontent.com/Qwertys50/qwertys50.github.io/refs/heads/mains/scripts/modules/bubble_pe_search.luau"))()
EggBrowser.Mount(Library, PetsTab)


local GroupboxDebug = Tab:AddLeftGroupbox("Debug", "console")
local GroupboxPriority = SettingsTab:AddRightGroupbox("Priority", "list-ordered")
local GroupboxMain = Tab:AddLeftGroupbox("Main", "house")
local GroupboxEggs = Tab:AddLeftGroupbox("Eggs", "egg")
local GroupboxBubble = Tab:AddRightGroupbox("Bubble", "shell")
local GroupboxEvent = Tab:AddRightGroupbox("Event", "party-popper")
local GroupboxMiniGames = Tab:AddRightGroupbox("Mini Games", "party-popper")

local AntiAfk
AntiAfk = GroupboxMain:AddCheckbox("AntiAfk", {
    Text = "Enable Anti Afk",
    Default = false,
    Callback = function()
        AntiAfk:SetDisabled(true)
        local GC = getconnections or get_signal_cons
        if GC then
            for i,v in pairs(GC(plr.Idled)) do
                if v["Disable"] then
                    v["Disable"](v)
                elseif v["Disconnect"] then
                    v["Disconnect"](v)
                end
            end
        else
            plr.Idled:Connect(function()
                local VirtualUser = game:GetService("VirtualUser")
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new())
            end)
        end
    end
})

GroupboxMain:AddDropdown("AutoBuyShop", {
    Values = shops,
    Multi = true,
    Text = "Auto buy shop",
    AllowNull = true,
    Callback = function(value)
        local a_ = {}
        for _, i in value do
            table.insert(a_, _)
        end
        selected_shop = a_
    end
})

GroupboxMain:AddCheckbox("AutoCollectCoin", {
	Text = "Auto Collect Coin",
    Callback = function(state)
        auto_collect_coin = state

		table.clear(all_coins)
        local v_ = 0

		for _, i in ipairs(chunk_money:GetChildren()) do
            if i:GetChildren()[1] then 
			    table.insert(all_coins, i)
                v_ += 1
            end
		end
    end
})

local all_eggs = GetAllEggs()

local Dropdown = GroupboxEggs:AddDropdown("EggSelect", {
    Text = "Eggs",
    Values = all_eggs,
    Multi = false,
    Callback = function(value)

        opened_egg_value = value
    end,
})

GroupboxEggs:AddCheckbox("OpenEggs", {
	Text = "Open Eggs",
    Callback = function(state)
        if_open_egg = state
    end
})

GroupboxEggs:AddCheckbox("DisableEggAnimation", {
	Text = "Disable Egg Animation",
    Callback = function(state)
        disable_egg_animation = state
    end
})

GroupboxBubble:AddCheckbox("BlowBubble", {
	Text = "Blow Bubble",
    Callback = function(state)
        if_bubble = state
    end
})
GroupboxBubble:AddCheckbox("AutoSellBubble", {
	Text = "Auto Sell Bubble",
    Callback = function(state)
        auto_sell_bubble = state
    end
})


GroupboxEvent:AddCheckbox("AutoRebirth", {
	Text = "Auto Rebirth",
    Callback = function(state)
        auto_rebirth = state
        rebirth_ready_since = nil
    end
})

GroupboxEvent:AddCheckbox("AutoHouse", {
	Text = "Auto Collect House",
    Callback = function(state)
        auto_house = state
    end
})

GroupboxEvent:AddCheckbox("AutoBestEgg", {
	Text = "Auto Best Egg",
    Callback = function(state)
        auto_best_event_egg = state
    end
})

GroupboxEvent:AddCheckbox("AutoChestHell", {
	Text = "Auto Open Chest Hell",
    Callback = function(state)
        auto_collect_event_chest = state
    end
})


GroupboxMiniGames:AddDropdown("MinigameSelect", {
    Text = "Selected Mini Games",
    Values = mini_games,
    Multi = false,
    Callback = function(value)
        selected_minigame = value
    end,
})

GroupboxMiniGames:AddDropdown("MinigameDifficulty", {
    Text = "Game Difficulty",
    Values = mini_games_,
    Multi = false,
    Default = "Easy",
    Callback = function(value)
        selected_minigame_ = value
    end,
})

GroupboxMiniGames:AddButton("Finish Mini Game", function()
    
    if not isInMinigame() then return end
    while task.wait(0.1) and isInMinigame() do
        MainEvent:FireServer("FinishMinigame")
    end

    is_path.auto_play_mini_game = false
    status_text = "Finished Minigame"
end)

GroupboxMiniGames:AddCheckbox("AutoPlayMinigame", {
	Text = "Auto Play Mini Game",
    Callback = function(state)
        auto_play_mini_game = state
    end
})

local priority_label
local selected_priority = priority_order[1]

local function priorityText()
    local t = {}
    for i, k in ipairs(priority_order) do
        t[#t + 1] = i .. ". " .. PRIORITY_NAMES[k]
    end
    return table.concat(t, "\n")
end

local function movePriority(dir)
    local i = table.find(priority_order, selected_priority)
    if not i then return end
    local j = i + dir
    if j < 1 or j > #priority_order then return end
    priority_order[i], priority_order[j] = priority_order[j], priority_order[i]
    priority_label:SetText(priorityText())
    if Options.PriorityOrder then
        Options.PriorityOrder:SetValue(table.concat(priority_order, ","))
    end
end

local priority_names_list = {}
for _, k in ipairs(DEFAULT_PRIORITY) do
    table.insert(priority_names_list, PRIORITY_NAMES[k])
end

GroupboxPriority:AddDropdown("PrioritySelect", {
    Text = "Task",
    Values = priority_names_list,
    Multi = false,
    Default = "Mini Game",
    Callback = function(value)
        for k, name in pairs(PRIORITY_NAMES) do
            if name == value then
                selected_priority = k
                break
            end
        end
    end,
})

GroupboxPriority:AddButton("Move Up", function() movePriority(-1) end)
GroupboxPriority:AddButton("Move Down", function() movePriority(1) end)
GroupboxPriority:AddButton("Reset Order", function()
    priority_order = table.clone(DEFAULT_PRIORITY)
    priority_label:SetText(priorityText())
    if Options.PriorityOrder then
        Options.PriorityOrder:SetValue(table.concat(priority_order, ","))
    end
end)

priority_label = GroupboxPriority:AddLabel(priorityText(), true)

local function applyOrderString(str)
    local new, seen = {}, {}
    for key in tostring(str):gmatch("[^,%s]+") do
        if PRIORITY_NAMES[key] and not seen[key] then
            seen[key] = true
            table.insert(new, key)
        end
    end
    if #new ~= #DEFAULT_PRIORITY then return false end
    priority_order = new
    return true
end

GroupboxPriority:AddInput("PriorityOrder", {
    Text = "Order (saved in config)",
    Default = table.concat(DEFAULT_PRIORITY, ","),
    Finished = true,
    Callback = function(text)
        if applyOrderString(text) then
            priority_label:SetText(priorityText())
        end
    end,
})

local debug_text = GroupboxDebug:AddLabel("Loading...", true)

Library.ShowCustomCursor = false


local ok, err = pcall(function()
    local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/Qwertys50/qwertys50.github.io/refs/heads/mains/scripts/modules/obsidian_saved"))()

    SaveManager:SetLibrary(Library)
    SaveManager:IgnoreThemeSettings()
    SaveManager:SetIgnoreIndexes({ "PrioritySelect" })
    SaveManager:SetFolder("BubbleScript")
    SaveManager:BuildConfigSection(SettingsTab, "Left")
    SaveManager:LoadAutoloadConfig()
end)
if not ok then
    warn("[SaveManager] " .. tostring(err))
end


task.spawn(function()

	while task.wait() do

		if auto_collect_coin then

			for _, i in all_coins do

                local is1_ =getPickupChunker()
                if not is1_ then continue end

				ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Pickups"):WaitForChild("CollectPickup"):FireServer(unpack({[1] = i.Name}))

                is1_:Remove(i:GetPivot().Position, i)
                i:Destroy()
			end

            table.clear(all_coins)
		end

	end
end)


task.spawn(function()
    while task.wait(0.2) do
        if auto_rebirth and not is_rebirthing and not IsPathTr("auto_rebirth") then
            local progress = getRebirthProgress()

            if progress and progress >= 1 then
                if not rebirth_ready_since then
                    rebirth_ready_since = tick()
                end

                if tick() - rebirth_ready_since >= 1 then
                    is_rebirthing = true
                    
                    is_path.auto_rebirth = true
                    DoRebirth()
                    rebirth_ready_since = nil

                    while task.wait(1) and getRebirthProgress() >= 1 do DoRebirth() end
                    is_rebirthing = false
                    is_path.auto_rebirth = false
                end
            else
                rebirth_ready_since = nil
            end
        else
            rebirth_ready_since = nil
        end

        if auto_collect_event_chest and not IsPathTr("auto_claim_chest") then

            if workspace.Rendered.Generic:FindFirstChild("Halloween Chest") and not workspace.Rendered.Generic["Halloween Chest"].Countdown.BillboardGui.Enabled then

                auto_collect_event_chest = true
                is_path.auto_claim_chest = true

                while task.wait(0.5) and not workspace.Rendered.Generic["Halloween Chest"].Countdown.BillboardGui.Enabled do
                    
                    MainEvent:FireServer(
                        "ClaimChest",
                        "Halloween Chest"
                    )
                end

                auto_collect_event_chest = false
                is_path.auto_claim_chest = false
            end
        end

    end
end)

task.spawn(function()

    while task.wait() do
        if not auto_house then continue end

            for _, i in ipairs(workspace.HalloweenEvent.Houses:GetChildren()) do

                if i.Activation.Active.Value then

                    plr.Character:PivotTo(i.Activation:GetPivot())
                    
                    MainEvent:FireServer(
                        "TrickOrTreat",
                        i
                    )
                    break
                end
            end
    end

end)

task.spawn(function()

    while task.wait(0.5) do
        if IsPathTr("auto_buy") then
            is_path.auto_buy = false
            continue
        end
        local a = 0

        for _, name_shop in ipairs(selected_shop) do

            local data = LocalData:Get()
            local v16 = data and data.Shops[name_shop]
            if not v16 then continue end

            local ItemsData, ItemsData_2 = ShopUtil:GetItemsData(name_shop, plr, data)
            local UnlockedSlots = ShopUtil:GetUnlockedSlots(data, #ItemsData)

            local buyAll = false
            for _, up in ipairs(data.MasteryUpgrades) do
                if up.Type == "BuyAll" then buyAll = true break end
            end

            for i14 = 1, #ItemsData do
                if i14 > UnlockedSlots then continue end

                local left = math.max(0, ItemsData_2[i14] - (v16.Bought[i14] or 0))
                if left <= 0 then continue end

                if not ItemUtil:CanAfford(data, ItemsData[i14].Cost) then continue end

                is_path.auto_buy = true
                local item_ = ItemsData[i14]
                local item_name = tostring(item_.Name or item_.Item or item_.Id or ("slot " .. i14))
                status_text = "Buying Item: " .. item_name .. " from " .. tostring(name_shop) .. " (" .. i14 .. "/" .. #ItemsData .. ")"
                a += 1
                MainEvent:FireServer("BuyShopItem", name_shop, i14, buyAll)
                task.wait(0.5)
            end

            local fresh = LocalData:Get()
            local cfg = Shops[name_shop]
            if fresh and cfg and cfg.Rerollable
                and ShopUtil:GetMaxFreeRerolls(fresh) - fresh.ShopFreeRerolls.Used > 0 then
                status_text = "Use Free Reroll"
                MainEvent:FireServer("ShopFreeReroll", name_shop)
            end
        end
        if a == 0 then is_path.auto_buy = false end
    end
end)

game.RunService.Heartbeat:Connect(function(deltaTime)

    is_path.auto_open_egg = if_open_egg and not IsPathTr("auto_open_egg")

    if is_path.auto_open_egg then
        do
            local model_egg = eggPos(opened_egg_value)

            if model_egg then
                
                if (plr.Character:GetPivot().Position - model_egg).Magnitude >= 20 then
                    plr.Character:PivotTo(CFrame.new(model_egg) * CFrame.new(0, 3, 5))
                end
            end

            status_text = "Opened Egg: "..opened_egg_value
            remoteEvent:FireServer("HatchEgg", opened_egg_value, math.huge)
        end
    end

    is_path.auto_blow_bubble = if_bubble and not IsPathTr("auto_blow_bubble")

    if is_path.auto_blow_bubble then
        status_text = "Blow Bubble"
        BlowBubble()
    end

    if auto_sell_bubble and not is_selling and not IsPathTr("auto_blow_bubble") then
        if GetMyBubble() >= getBubbleMax() and tick() - last_sell_time > 0.5 then

            
            status_text = "Selling Bubble"
            SellBubble()
        end
    end

    local eg_ = GetAllEggs()

    if not deepEqual(all_eggs, eg_) then

        all_eggs = eg_
        Dropdown:SetValues(eg_)
    end

    if auto_best_event_egg then

        local b_

        for _, i in all_eggs do
            if string.find(i, "Luck") and string.find(i, best_event_egg) then b_ = i break end
        end
        if not b_ then
            for _, i in all_eggs do
                if  string.find(i, best_event_egg) then b_ = i break end
            end
        end

        Dropdown:SetValue(b_)

    end

end)



task.spawn(function()
    while task.wait() do
        
        if not auto_play_mini_game then
            if not isInMinigame() then  
                is_path.auto_play_mini_game = false
            end
            continue end
        if not selected_minigame then continue end

        if IsPathTr("auto_play_mini_game") then
            is_path.auto_play_mini_game = false
            continue
        end


        is_path.auto_play_mini_game = true
        if getMinigameCooldown(selected_minigame) > 0 then

            MainEvent:FireServer("SkipMinigameCooldown", selected_minigame)
            status_text = "Skipped Minigame Cooldown for "..selected_minigame
            continue
        else
            if not isInMinigame() then
                MainEvent:FireServer("StartMinigame", selected_minigame, selected_minigame_)
                continue
            end
        end

        if isInMinigame() then
            status_text = "Finished Minigame"
            MainEvent:FireServer("FinishMinigame")
         end
    end
end)

local C = {
    ok = "rgb(73, 230, 133)",
    warn = "rgb(255, 196, 77)",
    dim = "rgb(150, 150, 150)",
    info = "rgb(110, 180, 255)",
}

local function col(c, t)
    return '<font color="' .. c .. '">' .. tostring(t) .. "</font>"
end

local function fmtNum(n)
    if type(n) ~= "number" then return "?" end
    local units = { "", "K", "M", "B", "T", "Qa", "Qi" }
    local i = 1
    while math.abs(n) >= 1000 and i < #units do
        n = n / 1000
        i += 1
    end
    if i == 1 then return tostring(math.floor(n)) end
    return string.format("%.2f%s", n, units[i])
end

local function fmtTime(s)
    s = math.max(0, math.floor(s))
    if s >= 3600 then
        return string.format("%d:%02d:%02d",
            math.floor(s / 3600),
            math.floor((s % 3600) / 60),
            s % 60)
    end
    return string.format("%d:%02d", math.floor(s / 60), s % 60)
end

local session_start = os.clock()
local last_seen_status = status_text
local last_status_change = os.clock()

local function BuildStatus()
    local now = os.clock()

    if status_text ~= last_seen_status then
        last_seen_status = status_text
        last_status_change = now
    end
    local age = now - last_status_change

    local enabled_map = {
        auto_play_mini_game = auto_play_mini_game,
        auto_rebirth = auto_rebirth,
        auto_buy = #selected_shop > 0,
        auto_open_egg = if_open_egg,
        auto_blow_bubble = if_bubble,
    }


    local active = {}
    for _, key in ipairs(priority_order) do
        if enabled_map[key] then
            local name = PRIORITY_NAMES[key]
            if IsPathTr(key) then
                name = col(C.dim, name .. " (paused)")
            end
            table.insert(active, name)
        end
    end

    if auto_sell_bubble then table.insert(active, "Sell") end
    if auto_collect_coin then table.insert(active, "Coins") end
    if auto_house then table.insert(active, "House") end
    if auto_best_event_egg then table.insert(active, "BestEgg") end
    if auto_collect_event_chest or is_path.auto_claim_chest then table.insert(active, "Chest") end

    local action
    if #active == 0 and not is_rebirthing and not is_selling then
        action = col(C.dim, "Idle")
    else
        action = col(C.ok, status_text)
        if age >= 3 then
            action = action .. col(C.dim, " (" .. math.floor(age) .. "s)")
        end
    end

    local lines = {}
    table.insert(lines, "[" .. col(C.ok, "Status") .. "] " .. action)
    table.insert(lines, "[" .. col(C.info, "Active") .. "] " ..
        (#active > 0 and table.concat(active, ", ") or col(C.dim, "none")))

    local okB, cur, max = pcall(function() return GetMyBubble(), getBubbleMax() end)
    if okB and max and max > 0 then
        local pct = math.clamp(cur / max * 100, 0, 100)
        local color = pct >= 100 and C.warn or C.ok
        table.insert(lines, "[" .. col(C.info, "Bubble") .. "] " ..
            col(color, fmtNum(cur) .. " / " .. fmtNum(max)) .. " (" .. math.floor(pct) .. "%)")
    end

    local okR, prog = pcall(getRebirthProgress)
    if okR and prog then
        local pct = math.floor(math.clamp(prog, 0, 1) * 100)
        local text = pct >= 100 and col(C.warn, "READY") or (pct .. "%")
        table.insert(lines, "[" .. col(C.info, "Rebirth") .. "] " .. text)
    end

    if opened_egg_value ~= "" then
        table.insert(lines, "[" .. col(C.info, "Egg") .. "] " .. opened_egg_value ..
            (disable_egg_animation and col(C.dim, " (no anim)") or ""))
    end

    if selected_minigame then
        local mg
        if isInMinigame() then
            mg = col(C.warn, "playing")
        else
            local okC, cd = pcall(getMinigameCooldown, selected_minigame)
            if okC and cd and cd > 0 then
                mg = col(C.dim, "cooldown " .. fmtTime(cd))
            else
                mg = col(C.ok, "ready")
            end
        end
        table.insert(lines, "[" .. col(C.info, "Minigame") .. "] " ..
            selected_minigame .. " / " .. selected_minigame_ .. " - " .. mg)
    end

    table.insert(lines, "[" .. col(C.info, "Uptime") .. "] " .. fmtTime(now - session_start))

    return table.concat(lines, "\n")
end

task.spawn(function()
    while task.wait(0.3) do
        pcall(function()
            local ok, text = pcall(BuildStatus)
            debug_text:SetText(ok and text or ("[" .. col("rgb(255, 90, 90)", "Status error") .. "] " .. tostring(text)))        
        end)

    end
end)
