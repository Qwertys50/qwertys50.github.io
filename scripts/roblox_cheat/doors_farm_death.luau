local stoped = false
if _G.DEATH_FARM then
    return
end
_G.DEATH_FARM = true

game.Players.PlayerAdded:Connect(function(player)
    if player == game.Players.LocalPlayer then
        
            print(123, "HM")
        player.OnTeleport:Connect(function()

            queue_on_teleport(string.format([[
                loadstring(game:HttpGet("%s"))()
            ]], "https://raw.githubusercontent.com/Qwertys50/Cheat/refs/heads/main/test2.lua"))
        end)

    end
end)

for _, i in ipairs(game.Players:GetPlayers()) do
    
    if i == game.Players.LocalPlayer then
            print(123, "KNIGA")
        i.OnTeleport:Connect(function()

            queue_on_teleport(string.format([[
                loadstring(game:HttpGet("%s"))()
            ]], "https://raw.githubusercontent.com/Qwertys50/Cheat/refs/heads/main/test2.lua"))
        end)
    end
end

task.wait(1)

while not workspace:FindFirstChild("CurrentRooms") do task.wait() end
while not workspace.CurrentRooms:FindFirstChild("0") do task.wait() end
while not workspace.CurrentRooms["0"]:FindFirstChild("StarterElevator") do task.wait() end

local CFrame1 = CFrame.new(249.999954, -0.373500377, -9.99999714, 0.99999994, 0, 0.00037855946, 0, 1, 0, -0.00037855946, 0, 0.99999994)
local CFrame6 = CFrame.new(243.364471, -0.373500377, -50.2721786, 0.066934742, 0, 0.997757375, 0, 1, 0, -0.997757375, 0, 0.066934742)

local plr = game.Players.LocalPlayer

local ended = false
local st = 0


local function hasKey()
    if plr.Character:FindFirstChild("Key") then
        return true
    end
    
    local backpack = plr:FindFirstChild("Backpack")
    if backpack and backpack:FindFirstChild("Key") then
        return true
    end
    
    return false
end

for i=1, 5 do game:GetService("ReplicatedStorage").RemotesFolder.PreRunShop:FireServer({}) end
fireproximityprompt(workspace.CurrentRooms["0"].StarterElevator.Model.Model.SkipButton.SkipPrompt)


workspace.CurrentRooms["0"].Door.AttributeChanged:Connect(function(attributeName)
    if attributeName == "Opened" then
        
        ended = true
        task.wait(0.5)
        replicatesignal(plr.Kill)
        
        task.wait(0.3)
        game:GetService("ReplicatedStorage"):WaitForChild("RemotesFolder"):WaitForChild("PlayAgain"):FireServer()
    end
end)

game:GetService("ReplicatedStorage").RemotesFolder.Statistics.OnClientEvent:Connect(function()
    stoped = true

    print(1)
    if stoped then return end
    print("TEST")
    game:GetService("ReplicatedStorage"):WaitForChild("RemotesFolder"):WaitForChild("PlayAgain"):FireServer()

end)

task.wait(2)

local ch = plr.Character
started =  true
ch:PivotTo(CFrame1)
task.wait(0.5)

while not hasKey() do
            
    ch.PrimaryPart.CFrame = workspace.CurrentRooms["0"].Assets.KeyObtain.Hitbox.CFrame
    fireproximityprompt(workspace.CurrentRooms["0"].Assets.KeyObtain.ModulePrompt)

    task.wait(0)
end

ch:PivotTo(CFrame6)
task.wait(0.5)

while not ended do
            
    ch.PrimaryPart.CFrame = CFrame.new(265.486267, -0.400000364, -48.4754181, 0.999383152, 3.15590509e-09, 0.0351186804, -2.2460569e-09, 1, -2.59472621e-08, -0.0351186804, 2.5852378e-08, 0.999383152)
    fireproximityprompt(workspace.CurrentRooms["0"].Door.Lock.UnlockPrompt)

    task.wait(0)
end
