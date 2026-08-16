local HttpService = game:GetService("HttpService")
local CHECK_INTERVAL = 10
_G.hasBadge = {}

local BadgeReceived = Instance.new("BindableEvent")

local function checkPlayer(player, id)
    local res = http_request({
        Url = "https://inventory.roblox.com/v1/users/" .. player.UserId .. "/items/Badge/" .. id,
        Method = "GET",
        Headers = { ["Accept"] = "application/json" }
    })

    if res.StatusCode == 200 then
        local ok, data = pcall(HttpService.JSONDecode, HttpService, res.Body)
        if ok and data.data and #data.data > 0 then
            if not _G.hasBadge[player.UserId] then
                _G.hasBadge[player.UserId] = true
                BadgeReceived:Fire(player)
            end
        end
    end
end

game.Players.PlayerRemoving:Connect(function(player)
    _G.hasBadge[player.UserId] = nil
end)

return {Start=function(id)
    task.spawn(function()
        while true do
            for _, player in ipairs(game.Players:GetPlayers()) do
                task.spawn(checkPlayer, player, id)
            end
            task.wait(CHECK_INTERVAL)
        end
    end)

end, Event=BadgeReceived}
