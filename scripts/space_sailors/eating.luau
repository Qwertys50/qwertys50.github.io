local activateEating = true
local plr = game.Players.LocalPlayer
local isProcessing = false
local VirtualUser = game:GetService("VirtualUser")

local foodItems = {
    "Spinach", "Chocolate", "Almonds", "Beef", "Crackers", 
    "Peanuts", "Cookies", "Pretzels", "Cheese", "Cereal", 
    "Bacon", "Cashews", "Mashed Potato"
}

local function clearAllEatenAttributes()
    for _, item in ipairs(plr.Backpack:GetChildren()) do
        if item:IsA("Tool") then
            item:SetAttribute("Eaten", nil)
        end
    end
    print("Все атрибуты очищены")
end

local function EatItem(child)
    if not activateEating or isProcessing then return end
    if not child:IsA("Tool") then return end
    if not table.find(foodItems, child.Name) then return end
    if child:GetAttribute("Eaten") == true then return end
    
    isProcessing = true
    
    local char = plr.Character
    if not char then 
        isProcessing = false
        return 
    end
    
    local hum = char.Humanoid
    
    local timeout = 0
    while child.Parent ~= plr.Backpack and timeout < 30 do
        task.wait(0.02)
        timeout = timeout + 1
    end
    
    if child.Parent ~= plr.Backpack then
        isProcessing = false
        return
    end
    
    hum:EquipTool(child)
    
    timeout = 0
    while child.Parent ~= char and timeout < 10 do
        task.wait(0.02)
        timeout = timeout + 1
    end
    
    if child.Parent == char then
        child:Activate()
        
        pcall(function()
            VirtualUser:Button1Down(Vector2.new(0, 0))
            task.wait(0.02)
            VirtualUser:Button1Up(Vector2.new(0, 0))
        end)
        
        task.wait(0.05)
        hum:UnequipTools()
        
        child:SetAttribute("Eaten", true)
        print("Съеден:", child.Name)
    end
    
    isProcessing = false
end

local childAddedConnection = nil
local scanThread = nil
local foodGiverThread = nil

local function Start()
    if activateEating then
        print("Уже запущено")
        return
    end
    
    activateEating = true
    
    childAddedConnection = plr.Backpack.ChildAdded:Connect(function(child)
        task.wait(0.05)
        EatItem(child)
    end)
    
    scanThread = task.spawn(function()
        while activateEating do
            task.wait(0.3)
            
            for _, item in ipairs(plr.Backpack:GetChildren()) do
                if not activateEating then break end
                if item:IsA("Tool") and table.find(foodItems, item.Name) then
                    if not item:GetAttribute("Eaten") then
                        EatItem(item)
                    end
                end
            end
        end
    end)
    
    foodGiverThread = coroutine.wrap(function()
        while activateEating do
            task.wait()
            
            local char = plr.Character
            if not char then continue end
            
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if not hrp then continue end
            
            local toolgivers = workspace:FindFirstChild("Toolgivers")
            if not toolgivers then continue end
            
            for _, giver in ipairs(toolgivers:GetChildren()) do
                if not activateEating then break end
                
                if giver.Name == "FoodGiver" then
                    local prompt = giver:FindFirstChildWhichIsA("ProximityPrompt", true)
                    if prompt and prompt.Enabled then
                        local parentPart = prompt.Parent:IsA("BasePart") and prompt.Parent 
                            or giver:FindFirstChildWhichIsA("BasePart", true)
                        
                        if parentPart then
                            local dist = (hrp.Position - parentPart.Position).Magnitude
                            if dist <= prompt.MaxActivationDistance then
                                if fireproximityprompt then
                                    fireproximityprompt(prompt)
                                elseif fireprompt then
                                    fireprompt(prompt)
                                end
                                task.wait(0.1)
                            end
                        end
                    end
                end
            end
        end
    end)
    foodGiverThread()
end

local function Stop()
    if not activateEating then
        print("Уже остановлено")
        return
    end
    
    activateEating = false
    
    if childAddedConnection then
        childAddedConnection:Disconnect()
        childAddedConnection = nil
    end
    
    if scanThread then
        task.cancel(scanThread)
        scanThread = nil
    end
    
    if foodGiverThread then
        foodGiverThread = nil
    end
    
    local char = plr.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum:UnequipTools()
        end
    end
    
    isProcessing = false
end

return {
    Start = Start,
    Stop = Stop,
    isRunning = function() return activateEating end
}
