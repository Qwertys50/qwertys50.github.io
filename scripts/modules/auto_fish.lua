local plr = game.Players.LocalPlayer

local function StartFishing()
    game:GetService("ReplicatedStorage").Network.Instancing_FireCustomFromClient:FireServer(
        "Fishing",
        "RequestCast",
        Vector3.new(1126.1120605469, 75.914115905762, -3445.1215820312)
    )
end

local function PodFishing()
    game:GetService("ReplicatedStorage").Network.Instancing_FireCustomFromClient:FireServer(
        "Fishing",
        "RequestReel",
        nil
    )
end

local function ClickFishing()
    game:GetService("ReplicatedStorage").Network.Instancing_InvokeCustomFromClient:InvokeServer(
        "Fishing",
        "Clicked"
    )
end

local started = false
local started_fish = false
local started_global = false

if game:GetService("ReplicatedStorage").Network:FindFirstChild("Instancing_FireCustomFromServer") then
    
    game:GetService("ReplicatedStorage").Network.Instancing_FireCustomFromServer.OnClientEvent:Connect(function(a, b, c)
        if not started_global then return end
        if typeof(c) ~= "string" then if c ~= plr then return end end
        if a ~= "Fishing" then return end
    
        if b == "Cast" then
            started_fish = false
        end
    
        if b == "Hook" then
            
            task.wait(0.5)
            PodFishing()
        end
    
        if b == "StartAttemptCatch" then
            started = true
        end
    
        if b == "RemoveCast" then
            started_fish = true
        end
    
        if b == "FishingSuccess" then
            
            started = false
            started_fish = true
            
        end
    
    end)
    
    task.spawn(function()
        
        while task.wait(0.1) do
            if not started_global then continue end
            if started then
                ClickFishing()
            end
    
            if started_fish then
                StartFishing()
            end
        end
    end)
end

return {
    start = (function()
        started_global = true
        started_fish = true
    end),
    stop = (function()
        started_global = false
        started_fish = false
    end)
}
