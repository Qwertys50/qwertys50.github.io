local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
local humanoid = character:WaitForChild("Humanoid")

repeat
    wait(0.1)
until character and character.Parent and humanoidRootPart and humanoidRootPart.Parent and humanoid

local SPEED_PROFILE = {
    [30000] = 1000000/2,
    [10000] = 100000,
    [2000] = 1000,
    [100] = 300,
    [10] = 25,
}

local minDistance = math.huge
local sortedDistances = {}

for dist, _ in pairs(SPEED_PROFILE) do
    table.insert(sortedDistances, dist)
    if dist < minDistance then
        minDistance = dist
    end
end

table.sort(sortedDistances, function(a, b) return a > b end)

function GetSpeedForDistance(distance)
    for _, dist in ipairs(sortedDistances) do
        if distance >= dist then
            return SPEED_PROFILE[dist]
        end
    end
    return SPEED_PROFILE[minDistance] or 1
end

function StandUp()
    if humanoid then
        if humanoid.Sit then
            humanoid.Sit = false
        end
        
        local attempts = 0
        while humanoid.Sit and attempts < 10 do
            humanoid.Sit = false
            humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            task.wait(0.1)
            attempts = attempts + 1
        end
    end
    
    local seat = character:FindFirstChild("Seat")
    if seat then
        seat:Destroy()
    end
end

function Jump()
    if not humanoid then
        return false
    end
    
    if humanoid.Sit then
        StandUp()
        task.wait(0.2)
    end
    
    humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    task.wait(0.1)
    humanoid.Jump = true
    task.wait(0.1)
    humanoid.Jump = false
    
    return true
end

function FinishScript()
    local bodyVelocity = humanoidRootPart:FindFirstChildOfClass("BodyVelocity")
    if bodyVelocity then
        local currentVel = bodyVelocity.Velocity
        local steps = 10
        for i = 1, steps do
            local t = 1 - (i / steps)
            bodyVelocity.Velocity = currentVel * t
            task.wait(0.05)
        end
        bodyVelocity.Velocity = Vector3.new(0, 0, 0)
        task.wait(0.1)
        bodyVelocity:Destroy()
    end
    
    local bodyGyro = humanoidRootPart:FindFirstChildOfClass("BodyGyro")
    if bodyGyro then
        bodyGyro:Destroy()
    end
    
    StandUp()
    task.wait(0.3)
    Jump()
    task.wait(0.2)
    
    if gyroConnection then
        gyroConnection:Disconnect()
        gyroConnection = nil
    end
    if flightConnection then
        flightConnection:Disconnect()
        flightConnection = nil
    end
end

function EnableFly()
    local bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    bodyVelocity.Parent = humanoidRootPart
    
    local bodyGyro = Instance.new("BodyGyro")
    bodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
    bodyGyro.D = 5000
    bodyGyro.P = 100000
    bodyGyro.Parent = humanoidRootPart
    
    gyroConnection = game:GetService('RunService').RenderStepped:Connect(function()
        if bodyGyro and bodyGyro.Parent then
            bodyGyro.CFrame = game.Workspace.CurrentCamera.CFrame
        end
    end)
    
    return bodyVelocity, bodyGyro
end

function FlyToTarget()
    local targetPart = workspace.Roads.KTTSBuffers
    
    if not targetPart then
        return
    end
    
    local targetPosition = targetPart:GetPivot().Position
    local startPosition = humanoidRootPart.Position
    local totalDistance = (targetPosition - startPosition).Magnitude
    
    local bodyVelocity, bodyGyro = EnableFly()
    
    local scriptFinished = false
    local lastPrintTime = 0
    
    flightConnection = game:GetService('RunService').Stepped:Connect(function()
        if scriptFinished then return end
        if not bodyVelocity or not bodyVelocity.Parent then
            flightConnection:Disconnect()
            return
        end
        
        local currentPosition = humanoidRootPart.Position
        local directionToTarget = (targetPosition - currentPosition)
        local distanceToTarget = directionToTarget.Magnitude
        
        if distanceToTarget <= minDistance and not scriptFinished then
            scriptFinished = true
            FinishScript()
            if bodyVelocity then bodyVelocity:Destroy() end
            if bodyGyro then bodyGyro:Destroy() end
            if flightConnection then flightConnection:Disconnect() end
            return
        end
        
        if distanceToTarget < 0.5 and not scriptFinished then
            scriptFinished = true
            FinishScript()
            if bodyVelocity then bodyVelocity:Destroy() end
            if bodyGyro then bodyGyro:Destroy() end
            if flightConnection then flightConnection:Disconnect() end
            return
        end
        
        local currentSpeed = GetSpeedForDistance(distanceToTarget)
        
        if distanceToTarget < minDistance * 1.5 then
            local progress = (distanceToTarget - minDistance) / (minDistance * 0.5)
            currentSpeed = currentSpeed * math.max(0.1, progress)
        end
        
        local velocity = directionToTarget.Unit * currentSpeed
        bodyVelocity.Velocity = velocity
        
        if distanceToTarget > 1 then
            local lookAt = CFrame.lookAt(currentPosition, currentPosition + directionToTarget.Unit * 10)
            humanoidRootPart.CFrame = lookAt
        end
        
        local now = tick()
        if now - lastPrintTime > 0.5 then
            lastPrintTime = now
            
            if distanceToTarget - minDistance <= 80 then
                FinishScript()
                if flightConnection then flightConnection:Disconnect() end
            end
        end
    end)
end

return {start=FlyToTarget}
