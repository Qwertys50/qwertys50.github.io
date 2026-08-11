local sell_pos = CFrame.new(413.873138, 27.7830868, -501.715851, -0.333443046, -5.72362175e-08, 0.942770243, -7.44215853e-08, 1, 3.43889255e-08, -0.942770243, -5.86957114e-08, -0.333443046)

local plr = game.Players.LocalPlayer
local ch = plr.Character

local function FindItemBackpack(name_)
    for _, i in ipairs(plr.Backpack:GetChildren()) do
        if string.find(i.Name, name_) then
            return true
        end
    end
    for _, i in ipairs(plr.Character:GetChildren()) do
        if string.find(i.Name, name_) and i:IsA("Tool") then
            return true
        end
    end
    return false
end

return {stars=function()
    local sell_prompt = workspace.MoonDorm3.CargoDropOffs:GetChildren()[4].ProximityPrompt

    for _, i in ipairs(workspace.CargoLLAMA.CargoLLAMA:GetDescendants()) do
        
        if i.Name == "ShowerBag" then

            local prompt = i.ProximityPrompt
            ch:PivotTo(i.CFrame)

            while prompt.Parent and task.wait() do
                fireproximityprompt(prompt)
            end

            fireproximityprompt(prompt)

            ch:PivotTo(sell_pos)
            while FindItemBackpack("Container") and task.wait() do fireproximityprompt(sell_prompt) end
        end    
    end
end}
