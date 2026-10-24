local currentRoomID = game:GetService("ReplicatedStorage").GameData.LatestRoom :: IntValue

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RemotesFolder = ReplicatedStorage:WaitForChild("RemotesFolder", 999)
local Crouch = RemotesFolder:WaitForChild("Crouch")
local Motor = game:GetService("ReplicatedStorage").RemotesFolder.MotorReplication

task.spawn(function()
    while task.wait() do 
        Crouch:FireServer(true, true)
        Motor:FireServer(-650)
    end 
end) 

workspace.ChildAdded:Connect(function(a0: Instance)
    if a0.Name == "Alma" then a0:Destroy() end
end)

workspace.Camera.ChildAdded:Connect(function(a0: Instance)
    if a0.Name == "Screech" then a0:Destroy() end
end)

local ch = game.Players.LocalPlayer.Character

game:GetService("ReplicatedStorage").RemotesFolder.RippleStatistics.OnClientEvent:Connect(function(a)
    if a.DeathReason then

        game:GetService("ReplicatedStorage").RemotesFolder.Lobby:FireServer()
    end
        
end)

local function GetAllItems()
    local all_items = {}
    for _, i in ipairs(workspace.Drops:GetChildren()) do
        if i:GetAttribute("Value") then
            table.insert(all_items, i)
        end
    end

    if not workspace.CurrentRooms[tostring(currentRoomID.Value)]:FindFirstChild("SalvageItems") then return end

    for _, i in ipairs(workspace.CurrentRooms[tostring(currentRoomID.Value)].SalvageItems:GetChildren()) do
        if i:GetAttribute("Value") then
            table.insert(all_items, i)
        end
    end
    return all_items
end

local function GetDepot()
    local id = currentRoomID.Value
    while true do
        local assets = workspace.CurrentRooms:FindFirstChild(tostring(id))
        if assets then
            assets =  workspace.CurrentRooms[tostring(id)].Assets
            local nearest, dist = nil, math.huge
            for _, v in ipairs(assets:GetChildren()) do
                if v.Name == "DepotHalloween" then
                    local d = (v:GetPivot().Position - ch:GetPivot().Position).Magnitude
                    if d < dist then nearest, dist = v, d end
                end
            end
            if nearest then return nearest end
        else return nil 
        end
        id -= 1
    end
end

local function FindItemCh(name)
    return ch:FindFirstChild(name)
end

local function solveCandyVault()

    local function findVault()
        local rooms = workspace:FindFirstChild("CurrentRooms")
        if not rooms then return end
        for _, room in ipairs(rooms:GetChildren()) do
            local assets = room:FindFirstChild("Assets")
            if assets then
                for _, m in ipairs(assets:GetChildren()) do
                    if m:GetAttribute("LoadModule") == "CrackableVault" and not m:GetAttribute("Activated") then
                        return m
                    end
                end
            end
        end
    end

    local function hook()
        for _, c in ipairs(getconnections(game:GetService("RunService").RenderStepped)) do
            local f = c.Function
            if f then
                local ok, ups = pcall(debug.getupvalues, f)
                if ok then
                    for _, u in pairs(ups) do
                        if type(u) == "table" and rawget(u, "phase") ~= nil and rawget(u, "onNotch") ~= nil then
                            for _, fn in pairs(ups) do
                                if type(fn) == "function" and debug.info(fn, "l") == 259
                                    and type(debug.getupvalue(fn, 1)) == "number" then
                                    return u, function(d) debug.setupvalue(fn, 1, d) end
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    local vault = findVault()
    if not vault then return false, "no unsolved vault found" end

    if not vault:GetAttribute("_Cracking") then
        local pp = vault:FindFirstChild("UnlockPrompt", true)
        if pp then pcall(fireproximityprompt, pp) end
        local t0 = os.clock()
        while not vault:GetAttribute("_Cracking") and os.clock() - t0 < 6 do task.wait(0.1) end
    end
    task.wait(0.5)

    local t1, setDir = hook()
    if not t1 then return false, "minigame state not found (is the minigame open?)" end

    local extended = {}
    local start = os.clock()
    while vault:GetAttribute("_Cracking") and not vault:GetAttribute("Activated") and os.clock() - start < 120 do
        game:GetService("RunService").RenderStepped:Wait()
        if t1.done or os.clock() < t1.spinUntil then
            setDir(0)
        else
            local remaining = (t1.target - t1.pos) * t1.dir
            if remaining > 0.3 then
                setDir(t1.dir)
            else
                setDir(0)
                if t1.onNotch and t1.hold >= 0.4 and not extended[t1.phase] then
                    extended[t1.phase] = true
                    t1.hold = 0
                end
            end
        end
    end
    pcall(setDir, 0)

    if vault:GetAttribute("Activated") then
        return true, "vault solved"
    end
    return false, "vault not solved (timeout or interrupted)"
end


local function FarmCandy()
    local i_ = GetAllItems()
    if not i_ then return end
    for _, i in i_ do

        local n = i.Name
        
        while task.wait() and i:FindFirstChild("ModulePrompt") do
            fireproximityprompt(i.ModulePrompt)
            ch:PivotTo(i:GetPivot())
        end

        while task.wait() and FindItemCh(n) do
            local d = GetDepot()
            if not d then return end
            ch:PivotTo(d:GetPivot() * CFrame.new(3, 0, 3))
            fireproximityprompt(d.ActivatePrompt)
        end

    end
end

local function OpenDoor(num)

    if tonumber(num) >= 53 then
        return true
    end

    local room = workspace.CurrentRooms[tostring(num)]

    if tonumber(num) == 52 then
        while task.wait() do
            ch:PivotTo(workspace.CurrentRooms["52"].Parts.Door.CFrame)
        end
    end

    if tonumber(num) == 1 then
        if not room.Assets.CandyVault:GetAttribute("Locked") then 
            while task.wait() and not game:GetService("Players").LocalPlayer.PlayerGui.MainUI:FindFirstChild("Frame") do
                fireproximityprompt(room.Assets.CandyVault.Door.Valve.Handle.UnlockPrompt)
                ch:PivotTo(room.Assets.CandyVault.Door.Valve.Handle.CFrame)
            end

            while task.wait() and not room.Assets.CandyVault:GetAttribute("Locked") do
                ch:PivotTo(room.Assets.CandyVault.Door.Valve.Handle.CFrame)
                solveCandyVault()
            end

            task.delay(4, function()
                local a  = os.clock() + 4

                while task.wait(0.5) and a >= os.clock() do
                    game:GetService("ReplicatedStorage").FloorReplicated.ClientRemote.SkipCutscene.Remote:FireServer(
                        1,
                        true
                    )
                end
            end)
        end
    end


    local door = workspace.CurrentRooms[tostring(num)].Door
    while task.wait() and ch:GetAttribute("InCutscene") do end
    while task.wait() and not (door:GetAttribute("Opened") == true) do  
        if rush_moving then continue end
    
        ch:PivotTo(door:GetPivot())
        door.ClientOpen:FireServer()
    end
end


local player = game.Players.LocalPlayer
local NewCharacter = player.Character or player.CharacterAdded:Wait()
local Humanoid = NewCharacter:WaitForChild("Humanoid", math.huge)
local RootPart = NewCharacter:FindFirstChild("HumanoidRootPart")

task.spawn(function()
    while task.wait(0.3) do

        FarmCandy()
        OpenDoor(tostring(currentRoomID.Value))
    end
end)
