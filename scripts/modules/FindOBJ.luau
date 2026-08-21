local WaypointFinder = {}

local PathfindingService = game:GetService("PathfindingService")
local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer

local function getCharacter()
    local char = localPlayer.Character
    if not char or not char.Parent then
        char = localPlayer.CharacterAdded:Wait()
    end
    return char
end

local function getRootPart()
    local char = getCharacter()
    return char:WaitForChild("HumanoidRootPart")
end

local function isPointOnGround(position)
    local raycastParams = RaycastParams.new()
    raycastParams.Filtertypeof = Enum.RaycastFiltertypeof.Blacklist
    raycastParams.FilterDescendantsInstances = {getCharacter()}
    
    local ray = workspace:Raycast(position + Vector3.new(0, 2, 0), Vector3.new(0, -5, 0), raycastParams)
    return ray ~= nil
end

local function findWalkableNearby(position, rootPart)
    local offsets = {
        Vector3.new(2, 0, 0),
        Vector3.new(-2, 0, 0),
        Vector3.new(0, 0, 2),
        Vector3.new(0, 0, -2),
        Vector3.new(3, 0, 0),
        Vector3.new(-3, 0, 0),
        Vector3.new(0, 0, 3),
        Vector3.new(0, 0, -3),
        Vector3.new(4, 0, 0),
        Vector3.new(-4, 0, 0),
        Vector3.new(0, 0, 4),
        Vector3.new(0, 0, -4),
        Vector3.new(2, 0, 2),
        Vector3.new(-2, 0, 2),
        Vector3.new(2, 0, -2),
        Vector3.new(-2, 0, -2),
        Vector3.new(3, 0, 3),
        Vector3.new(-3, 0, 3),
        Vector3.new(3, 0, -3),
        Vector3.new(-3, 0, -3),
        Vector3.new(1.5, 0, 1.5),
        Vector3.new(-1.5, 0, 1.5),
        Vector3.new(1.5, 0, -1.5),
        Vector3.new(-1.5, 0, -1.5),
    }

    local groundHeight = rootPart.Position.Y
    
    for _, off in ipairs(offsets) do
        local testPos = Vector3.new(position.X + off.X, groundHeight, position.Z + off.Z)
        
        local raycastParams = RaycastParams.new()
        raycastParams.Filtertypeof = Enum.RaycastFiltertypeof.Blacklist
        raycastParams.FilterDescendantsInstances = {getCharacter()}
        
        local ray = workspace:Raycast(testPos + Vector3.new(0, 2, 0), Vector3.new(0, -5, 0), raycastParams)
        if ray then
            testPos = ray.Position + Vector3.new(0, 2, 0)
        else
            testPos = Vector3.new(position.X + off.X, groundHeight, position.Z + off.Z)
        end
        
        local path = PathfindingService:CreatePath({ 
            AgentHeight = 5, 
            AgentRadius = 2,
            AgentCanJump = false
        })
        
        local ok = pcall(function()
            path:ComputeAsync(rootPart.Position, testPos)
        end)
        
        if ok and path.Status == Enum.PathStatus.Success then
            return testPos
        end
    end

    local doorPos = Vector3.new(position.X, rootPart.Position.Y, position.Z)
    local path = PathfindingService:CreatePath({ 
        AgentHeight = 5, 
        AgentRadius = 2,
        AgentCanJump = false
    })
    
    local ok = pcall(function()
        path:ComputeAsync(rootPart.Position, doorPos)
    end)
    
    if ok and path.Status == Enum.PathStatus.Success then
        return doorPos
    end

    return nil
end

function WaypointFinder.GetWaypointsToObject(targetObject, options)
    options = options or {}
    local allowJumps = options.allowJumps ~= false
    
    local rootPart = getRootPart()
    local targetPosition
    
    if typeof(targetObject) == "Instance" then
        if targetObject:IsA("BasePart") or targetObject:IsA("MeshPart") then
            targetPosition = targetObject.Position
        elseif targetObject:IsA("Model") and targetObject.PrimaryPart then
            targetPosition = targetObject.PrimaryPart.Position
        else
            local parts = targetObject:GetDescendants()
            for _, part in ipairs(parts) do
                if part:IsA("BasePart") then
                    targetPosition = part.Position
                    break
                end
            end
        end
    elseif typeof(targetObject) == "Vector3" then
        targetPosition = targetObject
    else
        warn("WaypointFinder: Некорректный объект")
        return nil
    end
    
    if not targetPosition then
        warn("WaypointFinder: Не удалось определить позицию цели")
        return nil
    end
    
    local walkablePoint = findWalkableNearby(targetPosition, rootPart)
    if not walkablePoint then
        warn("WaypointFinder: Не найдено доступной точки рядом с объектом")
        return nil
    end
    
    local path = PathfindingService:CreatePath({
        AgentHeight = 5,
        AgentRadius = 2,
        AgentCanJump = allowJumps,
        AgentCanUseLadders = false,
    })
    
    local ok = pcall(function()
        path:ComputeAsync(rootPart.Position, walkablePoint)
    end)
    
    if not ok or path.Status ~= Enum.PathStatus.Success then
        warn("WaypointFinder: Путь не найден:", path.Status)
        return nil
    end
    
    local waypoints = path:GetWaypoints()
    
    return {
        Waypoints = waypoints,
        TargetPosition = targetPosition,
        WalkablePoint = walkablePoint,
        PathStatus = path.Status,
        HasJumps = function(self)
            for _, wp in ipairs(self.Waypoints) do
                if wp.Action == Enum.PathWaypointAction.Jump then
                    return true
                end
            end
            return false
        end,
        GetWaypointPositions = function(self)
            local positions = {}
            for _, wp in ipairs(self.Waypoints) do
                table.insert(positions, wp.Position)
            end
            return positions
        end,
        GetJumpWaypoints = function(self)
            local jumps = {}
            for _, wp in ipairs(self.Waypoints) do
                if wp.Action == Enum.PathWaypointAction.Jump then
                    table.insert(jumps, wp)
                end
            end
            return jumps
        end
    }
end

function WaypointFinder.VisualizeWaypoints(waypointData, parent)
    parent = parent or workspace
    
    local oldVisuals = parent:FindFirstChild("WaypointVisuals")
    if oldVisuals then
        oldVisuals:ClearAllChildren()
        oldVisuals:Destroy()
    end
    
    local folder = Instance.new("Folder")
    folder.Name = "WaypointVisuals"
    folder.Parent = parent
    
    local function spawnNode(position, isJump)
        local p = Instance.new("Part")
        p.Size = Vector3.new(0.4, 0.4, 0.4)
        p.Shape = Enum.Parttypeof.Ball
        p.Material = Enum.Material.Neon
        p.BrickColor = isJump and BrickColor.new("Bright red") or BrickColor.new("Cyan")
        p.Position = position
        p.Anchored = true
        p.CanCollide = false
        p.CastShadow = false
        p.Parent = folder
    end
    
    local function spawnLine(a, b)
        local dist = (b - a).Magnitude
        if dist < 0.1 then return end
        local p = Instance.new("Part")
        p.Size = Vector3.new(0.1, 0.1, dist)
        p.CFrame = CFrame.lookAt(a, b) * CFrame.new(0, 0, -dist / 2)
        p.Material = Enum.Material.Neon
        p.BrickColor = BrickColor.new("White")
        p.Anchored = true
        p.CanCollide = false
        p.CastShadow = false
        p.Parent = folder
    end
    
    local waypoints = waypointData.Waypoints
    for i, wp in ipairs(waypoints) do
        local isJump = wp.Action == Enum.PathWaypointAction.Jump
        spawnNode(wp.Position, isJump)
        if i > 1 then
            spawnLine(waypoints[i-1].Position, wp.Position)
        end
    end
    
    local goalPart = Instance.new("Part")
    goalPart.Size = Vector3.new(1, 0.5, 1)
    goalPart.Shape = Enum.Parttypeof.Cylinder
    goalPart.Material = Enum.Material.Neon
    goalPart.BrickColor = BrickColor.new("Bright green")
    goalPart.Position = waypointData.WalkablePoint
    goalPart.Anchored = true
    goalPart.CanCollide = false
    goalPart.CastShadow = false
    goalPart.Transparency = 0.3
    goalPart.Parent = folder
end

function WaypointFinder.GetWaypointPositions(targetObject, allowJumps)
    local data = WaypointFinder.GetWaypointsToObject(targetObject, {allowJumps = allowJumps})
    if data then
        return data:GetWaypointPositions()
    end
    return nil
end

return WaypointFinder
