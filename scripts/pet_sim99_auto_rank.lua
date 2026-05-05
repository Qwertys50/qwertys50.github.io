local ht = game:GetService("HttpService")

local Items = require(game.ReplicatedStorage.Library.Items)
local container = require(game.ReplicatedStorage.Library.Client.InventoryCmds).Container()
local Zones = require(game.ReplicatedStorage.Library.Client.ZoneCmds)

local v_u_6 = require(game.ReplicatedStorage.Library.Client.QuestCmds)
local v_u_8 = require(game.ReplicatedStorage.Library.Client.GUI)
local v = require(game:GetService("ReplicatedStorage").Library.Types.Quests)

local v_u_40 = v_u_8.Rank().Frame.Side.Middle.Goals
local v_u_47 = {
	v_u_40.Easy,
	v_u_40.Medium,
	v_u_40.Hard,
	v_u_40.Extreme
}

local activeThreads = {}

local player = game.Players.LocalPlayer
local character = player.Character

local function GetBestLocation()
    return Zones.GetMaximumZone().ZoneFolder
end

local function _GetEggOnChanged(eggId)

    for _, i in ipairs(game:GetService("ReplicatedStorage").__DIRECTORY.Eggs:GetDescendants()) do
        
        if string.find(i.Name, "Egg") and i:IsA("ModuleScript") and string.find(i.Name, tostring(eggId)) then
            
            return i
        end
    end
    return nil
end

local function BreakableOBJ(id)
    game:GetService("ReplicatedStorage").Network.Breakables_PlayerDealDamage:FireServer(
        tostring(id)
    )
end

local function GetBestLegendaryPetsOnEgg()
    local eggsData = {}
    
    for _, egg in ipairs(workspace.__THINGS.ZoneEggs["World" .. Zones.GetMaximumZone().WorldNumber]:GetChildren()) do
        local id = tonumber(egg.Name:match("^(%d+)"))
        if id then
            table.insert(eggsData, {id = id, object = egg})
        end
    end
    
    table.sort(eggsData, function(a, b)
        return a.id > b.id
    end)
    
    for _, data in ipairs(eggsData) do
        local eggModule = _GetEggOnChanged(data.id)
        if eggModule then
            
            local egg_ = require(eggModule)
            for _, i in pairs(egg_.pets) do    
				if i[3] and i[3] == "Great" then

					return data.object, i[1]
				end
			end
        end

    end
	return nil
end

local function GetBestEgg()

    for _, egg in ipairs(workspace.__THINGS.ZoneEggs["World" .. Zones.GetMaximumZone().WorldNumber]:GetChildren()) do

        if tostring(egg:GetAttribute("ZoneNumber")) == tostring(Zones.GetMaximumZone().ZoneNumber) then
            
            return egg
        end
    end
end

local function GetItem(itemName, info)

    for className, itemClass in pairs(Items.Types) do
        local items = container:All(itemClass)
        for uid, item in pairs(items) do
            if item:GetName() == itemName then
                
                if not info then
                    return uid, item._data._am
                else
                    return uid
                end
            end
        end
    end

    return nil
end

local function GetGolfPet(itemName)

    for className, itemClass in pairs(Items.Types) do
        if className == "Pet" then
            local items = container:All(itemClass)
            for uid, item in pairs(items) do
                if item._data.id == itemName then
                    if item._data.pt and item._data.pt == 1 and not item._data.sh then
                        return uid, item._data._am
                    end
                end
            end
        end
    end

    return nil
end


local function GetPotionTier(tier)

    local max = 0
    local id = nil

    for className, itemClass in pairs(Items.Types) do
        if className == "Potion" then

            for uid, item in pairs(container:All(itemClass)) do
                if item._data.tn and item._data.tn >= tier then
                    
                    if max <= (item._data._am or 1) then
                        
                        max = (item._data._am or 1)
                        id = uid
                    end
                end
            end
        end
    end


    return id
end

local function GetBestEnchant()

    local max = 0
    local id = nil
    local name = ""

    
    for className, itemClass in pairs(Items.Types) do
        if className == "Enchant" then

            for uid, item in pairs(container:All(itemClass)) do
                    
                if max <= (item._data._am or 1) then
                    
                    name = item:GetName()
                    max = (item._data._am or 1)
                    id = uid
                end
            end
        end
    end

    return id
end


local function GetBestPotion()

    local max = 0
    local id = nil
    local name = ""

    
    for className, itemClass in pairs(Items.Types) do
        print(className)
        if className == "Potion" then

            for uid, item in pairs(container:All(itemClass)) do
                    
                if max <= (item._data._am or 1) then
                    
                    name = item:GetName()
                    max = (item._data._am or 1)
                    id = uid
                end
            end
        end
    end

    return id
end

local function GetBestPets()

    local egg = GetBestEgg()
    local id =  egg.Tier.SurfaceGui.TierNum.Text

    local egg_ = require(_GetEggOnChanged(id))
    local _i = {}
    for _, i in pairs(egg_.pets) do    
		if i[1] then

            local id, kol = GetItem(i[1])
            if id then
                _i[i[1]] = {id=id, c=kol or 1}
            end
		end
	end

    return _i
end

local function CraftBestPetGold(kolvo)

    local pets = GetBestPets()
    
    local bestPetName = nil
    local bestPetC = -math.huge
    local id = ""
    
    for namePet, info in pairs(pets) do
        local kol = info.c
        
        if kol > bestPetC then
            bestPetC = kol
            bestPetName = namePet
            id = info.id
        end
    end


    game:GetService("ReplicatedStorage").Network.GoldMachine_Activate:InvokeServer(
        id, kolvo
    )
end

local function CraftBestPetRainbow(kolvo)
    local pets = GetBestPets()
    
    local bestPetName = nil
    local bestPetC = -math.huge
    local id = ""
    
    for namePet, info in pairs(pets) do

        local pet, kol = GetGolfPet(namePet)
        if pet then
            
            if kol > bestPetC then
                bestPetC = kol
                bestPetName = namePet
                id = pet
            end
        end
    end

    print(bestPetC, bestPetName)
    game:GetService("ReplicatedStorage").Network.RainbowMachine_Activate:InvokeServer(
        id, kolvo
    )
end

local function GetCurrentMapWorld()
    for _, i in ipairs(workspace:GetChildren()) do
        
        if string.find(i.Name, "Map") then return i end
    end
end

local function TouchedBlockPlr(block) 
    
    local playerPos = character.PrimaryPart.Position
    local cframe = block.CFrame
    local size = block.Size
                
    local halfX = size.X / 2
    local halfY = size.Y / 2
    local halfZ = size.Z / 2
                
    local localCorners = {
        Vector3.new(-halfX, -halfY, -halfZ),
        Vector3.new( halfX, -halfY, -halfZ),
        Vector3.new( halfX, -halfY,  halfZ),
        Vector3.new(-halfX, -halfY,  halfZ),
        Vector3.new(-halfX,  halfY, -halfZ),
        Vector3.new( halfX,  halfY, -halfZ),
        Vector3.new( halfX,  halfY,  halfZ),
        Vector3.new(-halfX,  halfY,  halfZ)
    }
                
    local minX, maxX = math.huge, -math.huge
    local minZ, maxZ = math.huge, -math.huge
                
    for _, corner in ipairs(localCorners) do
        local worldCorner = cframe:PointToWorldSpace(corner)
        if worldCorner.X < minX then minX = worldCorner.X end
        if worldCorner.X > maxX then maxX = worldCorner.X end
        if worldCorner.Z < minZ then minZ = worldCorner.Z end
        if worldCorner.Z > maxZ then maxZ = worldCorner.Z end
    end
                
    local epsilon = 5
    return  playerPos.X >= (minX - epsilon) and playerPos.X <= (maxX + epsilon) and
            playerPos.Z >= (minZ - epsilon) and playerPos.Z <= (maxZ + epsilon)
                
end

local function GetMyLocation()
    

    for _, i in ipairs(GetCurrentMapWorld():GetChildren()) do
        if i:FindFirstChild("PARTS_LOD") and i.PARTS_LOD:FindFirstChild("GROUND") and i.PARTS_LOD.GROUND:FindFirstChild("Ground") then
            local ground = i.PARTS_LOD.GROUND.Ground
            if ground then
                
                if TouchedBlockPlr(ground) then
                    return i, ground
                end
            end
        end
    end
    
    return nil
end

local function QuestsINFO()

    local info_ = {}

    local v_u_11 = require(game.ReplicatedStorage.Library.Client.Save)
    local v161 = v_u_11.Get()
    local function _get(id)
        for _, i in pairs(v.Goals) do

            if i == id then return _ end
        end
    end
    for _, v166 in v_u_11.Get().Goals do
        local v167 = v_u_47[v166.Stars]
        local a = v_u_6.MissingGoal(v166)
        
        info_[tostring(v166.Stars)] = {Type =_get(a.Type), T = a.Amount - a.Progress}
        if a.PotionTier then
            info_[tostring(v166.Stars)].PotionTier = a.PotionTier
        end
    end

    return info_
end

local function SpawnedComet()
    return game:GetService("ReplicatedStorage").Network.Comet_Spawn:InvokeServer(
        GetItem("Comet", true)
    )
end

local function SpawnedJar()
    return game:GetService("ReplicatedStorage").Network.CoinJar_Spawn:InvokeServer(
        GetItem("Basic Coin Jar", true)
    )
end

local function SpawnedPinata()
    return game:GetService("ReplicatedStorage").Network.MiniPinata_Consume:InvokeServer(
        GetItem("Piñata", true)
    )
end

local function SpawnedLuckyBlock()
    return game:GetService("ReplicatedStorage").Network.MiniLuckyBlock_Consume:InvokeServer(
        GetItem("Lucky Block", true)
    )
end

local function FindObjectBreakable(Type)
    for _, i in ipairs(workspace.__THINGS.Breakables:GetChildren()) do
        
        if i:GetAttribute("BreakableID") == Type then
            
            return tonumber(i.Name), i
        end
    end
end

print("\n\n\n\n\n\n")

--print()
--print(GetBestLocation())

local function KillAllThreads()
    for i = #activeThreads, 1, -1 do
        local thread = activeThreads[i]
        if thread and coroutine.status(thread) ~= "dead" then
            task.cancel(thread)
        end
        table.remove(activeThreads, i)
    end
end

while true do
    local statuses = {}
    local used_ = {}

    for _i=4, 1, -1 do
        

        for id, i in QuestsINFO() do
            
            if _i == tonumber(id) then
                
                print(ht:JSONEncode(i))

                if i.Type == "USE_POTION" then
                    
                    if not table.find(statuses, "UsePotion") then 
                        table.insert(statuses, "UsePotion")  
                        used_["UsePotion"] = {c = i.PotionTier, k = i.T}
                    end
                end
                

                if i.Type == "COLLECT_ENCHANT" then
                    
                    if not table.find(statuses, "CollectEnchant") then 
                        table.insert(statuses, "CollectEnchant")  
                        used_["CollectEnchant"] = {k = i.T}
                    end
                end

                if i.Type == "COLLECT_POTION" then
                    
                    if not table.find(statuses, "CollectPotion") then 
                        table.insert(statuses, "CollectPotion")  
                        used_["CollectPotion"] = {k = i.T}
                    end
                end

                if i.Type == "BEST_RAINBOW_PET" then
                    
                    if not table.find(statuses, "RainbowPet") then 
                        table.insert(statuses, "RainbowPet")  
                        used_["RainbowPet"] = {k = i.T}
                    end
                end

                if i.Type == "BEST_GOLD_PET" then
                    
                    if not table.find(statuses, "GoldPet") then 
                        table.insert(statuses, "GoldPet")  
                        used_["GoldPet"] = {k = i.T}
                    end
                end

                if i.Type == "HATCH_RARE_PET" then
                    if not table.find(statuses, "HatchRareEgg") then table.insert(statuses, "HatchRareEgg") end
                end

                if i.Type == "BEST_EGG" then
                    if not table.find(statuses, "BestEgg") then table.insert(statuses, "BestEgg") end
                end


                if i.Type == "BEST_SUPERIOR_MINI_CHEST" then
                    if not table.find(statuses, "BestLocation") then
                        
                        table.insert(statuses, "BestLocation")
                    end
                end

                if i.Type == "CURRENCY" then
                    if not table.find(statuses, "BestLocation") then
                        
                        table.insert(statuses, "BestLocation")
                    end
                end

                if i.Type == "BEST_LUCKYBLOCK" then
                    if not table.find(statuses, "BestLocationLuckyBlock") then
                        
                        table.insert(statuses, "BestLocationLuckyBlock")
                    end
                end

                if i.Type == "BEST_COIN_JAR" then
                    if not table.find(statuses, "BestLocationCoinJar") then
                        
                        table.insert(statuses, "BestLocationCoinJar")
                    end
                end


                if i.Type == "BEST_PINATA" then
                    if not table.find(statuses, "BestLocationPinata") then
                        
                        table.insert(statuses, "BestLocationPinata")
                    end
                end

                if i.Type == "CURRENT_BREAKABLE" then
                    if not table.find(statuses, "BestLocation") then table.insert(statuses, "BestLocation") end
                end
                
                if i.Type == "BEST_COMET" then
                    if not table.find(statuses, "BestLocationComet") then
                        
                        table.insert(statuses, "BestLocationComet")
                    end
                end

                break
            end
        end
    end  


    for _, i in statuses do

        if i == "CollectPotion" then
                    
            game:GetService("ReplicatedStorage").Network.UpgradePotionsMachine_ActivateBulk:InvokeServer(
                {
                [GetBestPotion()] = used_["CollectPotion"]["k"]
                }
            )

        end

        if i == "CollectEnchant" then

            local Event = game:GetService("ReplicatedStorage").Network.UpgradeEnchantsMachine_Activate
            Event:InvokeServer(
                GetBestEnchant(),
                used_["CollectEnchant"]["k"]
            )

        end

        if i == "UsePotion" then
            
            game:GetService("ReplicatedStorage").Network["Potions: Consume"]:FireServer(
                GetPotionTier(used_["UsePotion"]["c"]),
                used_["UsePotion"]["k"]
            )
        end

        if i == "RainbowPet" then
            

            CraftBestPetRainbow(used_["RainbowPet"]["k"])
        end

        if i == "GoldPet" then
            
            CraftBestPetGold(used_["GoldPet"]["k"])
        end

        if i == "HatchRareEgg" then
                
            local egg, _ = GetBestLegendaryPetsOnEgg()
            player.Character.PrimaryPart.CFrame = egg:GetPivot()

            task.wait(0.5)

            local name = _GetEggOnChanged(egg.Name:match("%d+")).Name:match("%d+ | (.+)")
            print(name)
            game:GetService("ReplicatedStorage").Network.Eggs_RequestPurchase:InvokeServer(
                name, 72
            )
            break
        end

        if i == "BestEgg" then
            
            local egg = GetBestEgg()
            player.Character.PrimaryPart.CFrame = egg:GetPivot()

            task.wait(0.5)
            local name = _GetEggOnChanged(egg.Name:match("%d+")).Name:match("%d+ | (.+)")

            game:GetService("ReplicatedStorage").Network.Eggs_RequestPurchase:InvokeServer(
                name, 72
            )
            break
        end

        if i == "BestLocation" or i == "BestLocationLuckyBlock" or i == "BestLocationComet" or i == "BestLocationPinata" then
                
            local bestLoc = GetBestLocation()

            if bestLoc ~= GetMyLocation() then
                    
                player.Character.PrimaryPart.CFrame = bestLoc.PERSISTENT.Teleport.CFrame
                task.wait(0.5)
            end

            if not TouchedBlockPlr(bestLoc.INTERACT.BREAK_ZONES.BREAK_ZONE) then
                
                player.Character.PrimaryPart.CFrame = bestLoc.INTERACT.BREAK_ZONES.BREAK_ZONE.CFrame
            end
        end
        if i == "BestLocationLuckyBlock" then
            SpawnedLuckyBlock()

            table.insert(activeThreads, task.spawn(function()
                local function BreakAllOfType(blockType)
                    while true do
                        local a, obj = FindObjectBreakable(blockType)
                        while not a do a, _ = FindObjectBreakable(blockType) task.wait(0.5) end
                        while (obj and obj.Parent) do
                            BreakableOBJ(a)
                            task.wait()
                            a, obj = FindObjectBreakable(blockType)
                            if not a then break end
                        end
                    end
                end
                table.insert(activeThreads, task.spawn(function() BreakAllOfType("Lucky Block Large") end))
                table.insert(activeThreads, task.spawn(function() BreakAllOfType("Lucky Block Medium") end))
                table.insert(activeThreads, task.spawn(function() BreakAllOfType("Lucky Block Small") end))
            end))
        end

        if i == "BestLocationComet" then
            SpawnedComet()
            table.insert(activeThreads, task.spawn(function()
                local a, _ = FindObjectBreakable("Comet")
                while not a do a, _ = FindObjectBreakable("Comet") task.wait(0) end

                while _.Parent do
                    BreakableOBJ(a) task.wait()
                end
            end))
        end

        if i == "BestLocationPinata" then
            SpawnedPinata()
            table.insert(activeThreads, task.spawn(function()
                local a, _ = FindObjectBreakable("Pinata")
                print(a)
                while not a do a, _ = FindObjectBreakable("Pinata") task.wait(0) end

                print(a)
                while _.Parent do
                    

                    print(_.Parent)
                    BreakableOBJ(a) task.wait(0)
                    a, _ = FindObjectBreakable("Pinata")
                end

                print(_, _.Parent, FindObjectBreakable("Pinata"))
            end))
        end

        if i == "BestLocationCoinJar" then
            SpawnedJar()
        end
    end

    KillAllThreads()
    task.wait(0.1)
end

print("DIE")
