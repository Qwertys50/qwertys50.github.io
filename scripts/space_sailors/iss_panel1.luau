local RunService = game:GetService("RunService")

local function startProximityPromptSpam(prompt, a_)
    local connections = {}
    
    for i = 1, a_ do
        local conn
        conn = RunService.Heartbeat:Connect(function()
            if not prompt.Enabled then 
                conn:Disconnect() 
                return 
            end
            fireproximityprompt(prompt)
        end)
        table.insert(connections, conn)
    end
    
    return connections
end

return {Start=function(a_)
    for _, i in ipairs(workspace.SolarArrayMain.SolarArrayIndividual:GetChildren()) do

        for _, q in ipairs(i.DebrisHoles:GetChildren()) do
            
            if q.ProximityPrompt.Enabled then
                
                game.Players.LocalPlayer.Character.PrimaryPart.CFrame = q.CFrame
                task.wait(0.5)
                startProximityPromptSpam(q.ProximityPrompt, a_)
            end
        end
    end    
end}
