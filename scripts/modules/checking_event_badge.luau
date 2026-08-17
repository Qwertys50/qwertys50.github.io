local HttpService = game:GetService("HttpService")
local CHECK_INTERVAL = 10

if not _G then rawset(getfenv(0), "_G", {}) end
if not _G.hasBadge then _G.hasBadge = {} end

local ids = {}

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
            if not _G.hasBadge[id] then _G.hasBadge[id] = {} end
            if not _G.hasBadge[id][player.UserId] then
                _G.hasBadge[id][player.UserId] = true
                BadgeReceived:Fire(player, id)
            end
        end
    end
end

game.Players.PlayerRemoving:Connect(function(player)
    for _, id in ids do
        if _G.hasBadge[id] then
            _G.hasBadge[id][player.UserId] = nil
        end
    end
end)

return {
    Start = function(id)
        table.insert(ids, id)
        task.spawn(function()
            while true do
                for _, player in ipairs(game.Players:GetPlayers()) do
                    task.spawn(checkPlayer, player, id)
                end
                task.wait(CHECK_INTERVAL)
            end
        end)
    end,
    Event = BadgeReceived
}
