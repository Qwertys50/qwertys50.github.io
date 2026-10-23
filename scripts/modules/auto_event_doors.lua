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

local entitys = {"RushMoving", "AmbushMoving"}
local rush_moving = false


local ch = game.Players.LocalPlayer.Character
local function IsGenerator()
    for _, i in ipairs(workspace.CurrentRooms[tostring(currentRoomID.Value)]:GetDescendants()) do
        if i.Name == "MinesGenerator" then return i end
    end return nil
end

local function IsGateButton()
    for _, i in ipairs(workspace.CurrentRooms[tostring(currentRoomID.Value)]:GetDescendants()) do
        if i.Name == "MinesGateButton" then return i end
    end return nil
end

local function FindFuse(r)
    for _, i in ipairs(r:GetDescendants()) do
        if i.Name == "FusesPrompt" then return i end
    end return nil
end

local function GetPosition(p)
    if p:IsA("Model") then return p:GetPivot().Position end
    return p.Position
end

local function findClosestLight(folder, target)
    local closest = nil
    local minDistance = math.huge
    
    for _, child in ipairs(folder:GetChildren()) do
        if child.Name == "IndustrialLight" then
            local distance = (GetPosition(child).Position - GetPosition(target).Position).Magnitude
            if distance < minDistance then
                minDistance = distance
                closest = child
            end
        end
    end
    
    return closest
end

local function Go50Door()

    local w = false

    game:GetService("ReplicatedStorage").RemotesFolder.Teleport.OnClientEvent:Connect(function(c)
        local p = c.Position
        
        w = true
        if workspace.CurrentRooms["50"].TeleportAfterCutscene.Position == p then
            local closestLight = findClosestLight(
                workspace.CurrentRooms["50"].Assets.Light_Fixtures, workspace.CurrentRooms["50"]._NestHandler.Console.Button
            )

            local a__ = os.clock() + 15
            while task.wait() and a__ >= os.clock() do
                
                ch:PivotTo(closestLight:GetPivot())
            end 

        end
    end)
    
    while task.wait() and workspace.CurrentRooms["50"]._NestHandler.ConsoleScreen.SurfaceGui.Progress.Text ~= "100%" and not w do
        if rush_moving then continue end
        fireproximityprompt(workspace.CurrentRooms["50"]._NestHandler.Console.Button.ActivateEventPrompt)
        ch:PivotTo(workspace.CurrentRooms["50"]._NestHandler.Console.Button.CFrame)

    end
end

local function GoGenerator() 

    local function GoFuse()

        for _, i in ipairs(workspace.CurrentRooms[tostring(currentRoomID.Value)]:GetDescendants()) do
            if i.Name == "FuseObtain" then

                while (i:GetAttribute("CanTouch") ~= nil and i:GetAttribute("CanTouch") == false) and task.wait() do
                    if rush_moving then continue end

                    ch:PivotTo(i:GetPivot())

                    if i.Parent.Parent:FindFirstChild("Metal") and #i.Parent.Parent.Metal:GetChildren() > 0 then
                        fireproximityprompt(i.Parent.Parent.Metal.ActivateEventPrompt)
                    end
                    if i.Parent.Parent.Name == "Toolbox" then
                        fireproximityprompt(i.Parent.Parent.ActivateEventPrompt)
                    end
                    if i.Parent.Parent ~= workspace.CurrentRooms[tostring(currentRoomID.Value)] and i.Parent.Parent:FindFirstChild("Door") then
                        fireproximityprompt(i.Parent.Parent.Door.ActivateEventPrompt)
                    end

                end
                
                while not i:GetAttribute("ItemPicked") and task.wait() do
                    if rush_moving then continue end

                    ch:PivotTo(i:GetPivot())
                    fireproximityprompt(i.ModulePrompt)
                end
            end
        end
    end

    local g = IsGenerator()
    if g then
        
        local function Checking()
            if g.Fuses["1"].Fuse.Transparency == 0 and 
                g.Fuses["2"].Fuse.Transparency == 0 and
                g.Fuses["3"].Fuse.Transparency == 0 then

                return true
            end return false
        end

        local function GoStage1()

            while task.wait() do
                if rush_moving then continue end

                local ended = Checking()

                if ended then break end
                ch:PivotTo(g.Fuses:GetPivot())
                pcall(function()
                
                fireproximityprompt(FindFuse(g.Fuses))
                end)
            end

            local gl = IsGateButton()

            while task.wait() and gl and gl.Light.Transparency == 1 do            
                if rush_moving then continue end
                if not Checking() then break end

                ch:PivotTo(g.Lever.CFrame)
                fireproximityprompt(g.Lever.LeverPrompt)            
            end
            
        end

        GoFuse()
        GoStage1()

        print(workspace.CurrentRooms[tostring(currentRoomID.Value)].Door:GetAttribute("Gatekept"), 345)
        local gl = IsGateButton()
        while task.wait() and workspace.CurrentRooms[tostring(currentRoomID.Value)].Door:GetAttribute("Gatekept") == true do
            if rush_moving then continue end
            
            GoFuse()
            GoStage1()
            ch:PivotTo(gl:GetPivot())
            fireproximityprompt(gl.Button.ActivateEventPrompt)
        end
    end

end

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
            while task.wait() and not room.Assets.CandyVault:GetAttribute("Occupied") do
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


local NewCharacter = game.Players.LocalPlayer.Character
local Humanoid = NewCharacter.Humanoid
local RootPart = NewCharacter:FindFirstChild("HumanoidRootPart")

task.spawn(function()
    while task.wait(0.3) do

        FarmCandy()
        OpenDoor(tostring(currentRoomID.Value))
    end
end)
