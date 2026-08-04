local plr = game.Players.LocalPlayer
local ch = plr.Character

local function findBalloon(occupied)
    for _, i in ipairs(workspace:GetChildren()) do
        if i.Name == "BalloonMain" and i.Balloon.CurrentPlayerID.Value == (occupied and plr.UserId or 0) then
            return i
        end
    end
end
local function Start()
    local b = findBalloon(true)

    if not b then

        b = findBalloon(false)

        if not b then return end
        ch:PivotTo(b.Balloon.Seat.CFrame)

        task.wait(0.5)
        fireproximityprompt(b.Balloon.Button.ProximityPrompt)
    end

    ch:PivotTo(b.Balloon.Seat.CFrame)
    task.wait(0.5)

    local function smoothTeleportToPart(pos, duration)
        duration = duration or 0.5
        local startPos, hum = ch:GetPivot().Position, ch.Humanoid
        hum.PlatformStand = true
        local startTime, conn = tick()
        conn = game:GetService("RunService").Heartbeat:Connect(function()
            local alpha = math.min((tick() - startTime) / duration, 1)
            ch:PivotTo(CFrame.new(startPos:Lerp(pos, alpha)) * (ch:GetPivot() - ch:GetPivot().Position))
            if alpha >= 1 then conn:Disconnect() hum.PlatformStand = false end
        end)
        return true
    end

    local t = 0.5

    local my_pos = ch:GetPivot().Position
    smoothTeleportToPart(CFrame.new(my_pos.X, 100000+math.random(30000, 70000), my_pos.Z).Position, t)

    task.wait(t + 0.5)
    replicatesignal(game.Players.LocalPlayer.Kill)
end

return {
    start = Start
}
