local plr = game.Players.LocalPlayer

local function Dig(coord)
    game:GetService("ReplicatedStorage").Network.Instancing_FireCustomFromClient:FireServer(
        "Digsite",
        "DigBlock",
        coord
    )
end

local function DigChest(coord)

    game:GetService("ReplicatedStorage").Network.Instancing_FireCustomFromClient:FireServer(
        "Digsite",
        "DigChest",
        coord
    )
end

local coordinate = Vector3.new(1,1,1)

local function FindBlock(X, Y, Z)
    
    workspace.__THINGS.__INSTANCE_CONTAINER.Active:WaitForChild("Digsite", math.huge):WaitForChild("Important", math.huge)
    for _, i in ipairs(workspace.__THINGS.__INSTANCE_CONTAINER.Active.Digsite.Important.ActiveBlocks:GetChildren()) do
        if i:GetAttribute("Coord") then
            local coord = i:GetAttribute("Coord")
            if coord.X == X and coord.Z == Z then

                if coord.Y == Y then
                    return i
                end
                
            end
        end
    end
    return nil
end

local function getBottomXZ(X, Z, max_size)
    
    local Y = 0
    local block = nil

    for i=1, max_size+1 do
        local block_ = FindBlock(X, i, Z)
        if block_ then
            return block_
        end
    end

    return nil
end

local started_global = false
local started_chest = false

if game:GetService("ReplicatedStorage").Network:FindFirstChild("Instancing_FireCustomFromServer") then

    
    game:GetService("ReplicatedStorage").Network.Instancing_FireCustomFromServer.OnClientEvent:Connect(function(a, b, c)
        if not started_global then return end
        if a ~= "Digsite" then return end
    end)
    
    local x, z = 1, 1
    local max_size = 15
    
    task.spawn(function()
        
        while task.wait(0.1) do
            if not started_global then continue end
    
            workspace.__THINGS.__INSTANCE_CONTAINER.Active:WaitForChild("Digsite", math.huge):WaitForChild("Important", math.huge)
            if #workspace.__THINGS.__INSTANCE_CONTAINER.Active.Digsite.Important.ActiveChests:GetChildren() > 0 then
                for _, i in ipairs(workspace.__THINGS.__INSTANCE_CONTAINER.Active.Digsite.Important.ActiveChests:GetChildren()) do
                    started_chest = true
                    plr.Character.PrimaryPart.CFrame = i:GetPivot()
                    task.wait(0.1)
                    DigChest(i:GetAttribute("Coord"))
                end
            else 
                if started_chest then 
                    task.wait(0.5)
                    started_chest = false
                end
            end
    
            if not started_chest then
                
                local block = getBottomXZ(x, z, max_size)
                if not block then
                    x += 1
                    
                    if x > 8 then
                        x = 0
                        z += 1
                        
                        if z > 8 then
                            z = 0
                            max_size += 1
                        end
                    end
                else
                    plr.Character.PrimaryPart.CFrame = block.CFrame
                    Dig(block:GetAttribute("Coord"))
                end
            end
        end
    end)
end
return {
    start = (function()
        started_global = true
    end),
    stop = (function()
        started_global = false
    end)
}
