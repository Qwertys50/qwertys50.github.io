local plr =  game.Players.LocalPlayer

local function hasItem(item)
    if plr.Character:FindFirstChild(item) then
        return true
    end
    
    local backpack = plr:FindFirstChild("Backpack")
    if backpack and backpack:FindFirstChild(item) then
        return true
    end
    
    return false
end

local function GetItem(item)
    if plr.Character:FindFirstChild(item) then
        return plr.Character[item]
    end
    
    local backpack = plr:FindFirstChild("Backpack")
    if backpack and backpack:FindFirstChild(item) then
        return backpack[item]
    end
    
    return nil
end
  
local function GetMyMarsLander()
    for _, i in ipairs(workspace:GetChildren()) do
        
        if i.Name ~= "MarsLander" then continue end

        print(i.CurrentPlayer.Value, plr)
        if i.CurrentPlayer.Value ~= plr then continue end
        return i
    end return nil
end

return {start=function()

    pcall(function()
        local Part = game:GetService("Players").LocalPlayer.Character.HumanoidRootPart
        local OtherPart = workspace.PyramidEasterEgg.Touch.Touch
        local Touching = 0 
        firetouchinterest(Part, OtherPart, Touching)
    end)
    
    while not hasItem("Gem of Mars") and task.wait(1) do
        game.Players.LocalPlayer.Character:PivotTo(workspace.PyramidEasterEgg.Pyramid.GemOfMars.CFrame)
        fireproximityprompt(workspace.PyramidEasterEgg.Pyramid.GemOfMars.StealGem)
    end

    while hasItem("Gem of Mars") and task.wait() do

        local item = GetItem("Gem of Mars")
        if item and item.Parent and item.Parent ~= "Character" then
            plr.Character.Humanoid:EquipTool(item)
        end

        print(item)

        if item then
            local c = GetMyMarsLander()
            print(c)
            if not c then return end

            plr.Character:PivotTo(c.MidUpperStage.Deposit.CFrame)
            fireproximityprompt(c.MidUpperStage.Deposit.ProximityPrompt)
        else
            return
        end
    end
end}
