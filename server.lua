local QBX = exports.qbx_core

-- Глобални променливи
local activeRobbery = false
local lastGlobalRobberyTime = 0 -- Глобално време за всички играчи (30 мин)
local playerCooldowns = {} -- Индивидуални cooldown-и за играчите (12+ часа)
local truckActive = false
local truckCompletelyRobbed = false
local truckInventoryCreated = {} -- Списък на създадени инвентари
local activeInventories = {} -- Списък на активни инвентари за проследяване
local truckSpawnInProgress = false -- Нова променлива за проследяване на спаун процеса
local currentTruckNetId = nil -- Проследяване на текущия truck

-- Конфигурация за cooldown времена
local GLOBAL_COOLDOWN = 30 * 60 * 1000 -- 30 минути за всички играчи
local PLAYER_COOLDOWN = 12 * 60 * 60 * 1000 -- 12 часа за играча който завърши обира

-- Функция за проверка дали инвентар е празен
local function IsInventoryEmpty(inventoryId)
    local inventory = exports.ox_inventory:GetInventory(inventoryId)
    
    if not inventory or not inventory.items then
        if Config.Debug then
            print('[ax-gunrob] Inventory ' .. inventoryId .. ' not found or has no items table')
        end
        return true
    end
    
    local itemCount = 0
    for slot, item in pairs(inventory.items) do
        if item and item.count and item.count > 0 then
            itemCount = itemCount + item.count
            if Config.Debug then
                print('[ax-gunrob] Found item in ' .. inventoryId .. ': ' .. (item.name or 'unknown') .. ' x' .. item.count)
            end
        end
    end
    
    if Config.Debug then
        print('[ax-gunrob] Total items in ' .. inventoryId .. ': ' .. itemCount)
    end
    
    return itemCount == 0
end

-- Функция за принудително задаване на cooldown (игнорира debug настройки)
local function ForceCooldowns(source)
    local currentTime = GetGameTimer()
    
    -- Задаваме глобален cooldown
    lastGlobalRobberyTime = currentTime
    
    -- Задаваме индивидуален cooldown на играча
    local Player = QBX:GetPlayer(source)
    if Player then
        local identifier = Player.PlayerData.citizenid
        playerCooldowns[identifier] = currentTime
        
        if Config.Debug then
            print('[ax-gunrob] FORCED cooldowns set:')
            print('  Global: ' .. lastGlobalRobberyTime)
            print('  Player (' .. identifier .. '): ' .. playerCooldowns[identifier])
            
            -- Веднага проверяваме дали cooldown-ите работят
            local globalCheck = IsGlobalOnCooldown()
            local playerCheck = IsPlayerOnCooldown(source)
            print('  Global cooldown active: ' .. tostring(globalCheck))
            print('  Player cooldown active: ' .. tostring(playerCheck))
        end
        
        return true
    end
    
    return false
end

-- Функция за проверка на глобален cooldown (30 минути за всички)
local function IsGlobalOnCooldown()
    -- НЕ проверяваме Config.DisableCooldownInDebug тук за да принудим cooldown
    
    if lastGlobalRobberyTime == 0 then
        if Config.Debug then
            print('[ax-gunrob] No global robbery time set')
        end
        return false
    end
    
    local currentTime = GetGameTimer()
    local timeSince = currentTime - lastGlobalRobberyTime
    local onCooldown = timeSince < GLOBAL_COOLDOWN
    
    if Config.Debug then
        print('[ax-gunrob] Global cooldown check:')
        print('  Current time: ' .. currentTime)
        print('  Last robbery: ' .. lastGlobalRobberyTime) 
        print('  Time since: ' .. timeSince)
        print('  Cooldown period: ' .. GLOBAL_COOLDOWN)
        print('  On cooldown: ' .. tostring(onCooldown))
    end
    
    return onCooldown
end

-- Функция за проверка на индивидуален cooldown (12+ часа за конкретен играч)
local function IsPlayerOnCooldown(source)
    -- НЕ проверяваме Config.DisableCooldownInDebug тук за да принудим cooldown
    
    local Player = QBX:GetPlayer(source)
    if not Player then 
        if Config.Debug then
            print('[ax-gunrob] Player not found for cooldown check')
        end
        return false 
    end
    
    local identifier = Player.PlayerData.citizenid
    if not playerCooldowns[identifier] then
        if Config.Debug then
            print('[ax-gunrob] No cooldown set for player: ' .. identifier)
        end
        return false
    end
    
    local currentTime = GetGameTimer()
    local timeSince = currentTime - playerCooldowns[identifier]
    local onCooldown = timeSince < PLAYER_COOLDOWN
    
    if Config.Debug then
        print('[ax-gunrob] Player cooldown check for ' .. identifier .. ':')
        print('  Current time: ' .. currentTime)
        print('  Last robbery: ' .. playerCooldowns[identifier])
        print('  Time since: ' .. timeSince)
        print('  Cooldown period: ' .. PLAYER_COOLDOWN)
        print('  On cooldown: ' .. tostring(onCooldown))
    end
    
    return onCooldown
end

-- Функция за получаване на глобален cooldown време
local function GetGlobalCooldownTime()
    -- НЕ проверяваме Config.DisableCooldownInDebug тук
    
    if lastGlobalRobberyTime == 0 then
        return 0
    end
    
    local remaining = GLOBAL_COOLDOWN - (GetGameTimer() - lastGlobalRobberyTime)
    return math.max(0, math.ceil(remaining / 1000))
end

-- Функция за получаване на индивидуален cooldown време
local function GetPlayerCooldownTime(source)
    -- НЕ проверяваме Config.DisableCooldownInDebug тук
    
    local Player = QBX:GetPlayer(source)
    if not Player then return 0 end
    
    local identifier = Player.PlayerData.citizenid
    if not playerCooldowns[identifier] then
        return 0
    end
    
    local remaining = PLAYER_COOLDOWN - (GetGameTimer() - playerCooldowns[identifier])
    return math.max(0, math.ceil(remaining / 1000))
end

-- Функция за форматиране на време
local function FormatTime(seconds)
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    local secs = seconds % 60
    
    if hours > 0 then
        return string.format("%d ч. %d мин.", hours, minutes)
    elseif minutes > 0 then
        return string.format("%d мин. %d сек.", minutes, secs)
    else
        return string.format("%d сек.", secs)
    end
end

-- Функция за проверка на стартиране (все още използва debug настройки)
local function CanStartRobbery(source)
    if Config.Debug and Config.DisableCooldownInDebug then
        return true, nil
    end
    
    -- Проверяваме индивидуален cooldown
    if IsPlayerOnCooldown(source) then
        local timeLeft = GetPlayerCooldownTime(source)
        local formattedTime = FormatTime(timeLeft)
        return false, 'Трябва да изчакаш още ' .. formattedTime .. ' (индивидуален cooldown)'
    end

    -- Проверяваме глобален cooldown
    if IsGlobalOnCooldown() then
        local timeLeft = GetGlobalCooldownTime()
        local formattedTime = FormatTime(timeLeft)
        return false, 'Доставчикът се крие от полицията! Изчакай още ' .. formattedTime
    end
    
    return true, nil
end

-- Функция за получаване на информация за играч (опростена и бърза)
local function GetPlayerInfo(source)
    local Player = QBX:GetPlayer(source)
    local playerName = GetPlayerName(source) or 'Unknown'
    
    if not Player then
        return {
            steamName = playerName,
            rpName = 'Unknown',
            citizenid = 'Unknown',
            license = 'Unknown',
            avatar = 'https://cdn.discordapp.com/embed/avatars/0.png' -- Default Discord avatar
        }
    end
    
    return {
        steamName = playerName,
        rpName = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname,
        citizenid = Player.PlayerData.citizenid,
        license = Player.PlayerData.license or 'Unknown',
        avatar = 'https://cdn.discordapp.com/embed/avatars/' .. math.random(0, 5) .. '.png' -- Random default avatar
    }
end

-- Функция за изпращане на Discord webhook (опростена и бърза)
local function SendDiscordLog(source, title, description, color, fields)
    if not Config.Logging.enabled or not Config.Logging.webhook or Config.Logging.webhook == 'https://discord.com/api/webhooks/YOUR_WEBHOOK_URL_HERE' then
        return
    end
    
    -- Използваме CreateThread за да не блокираме основния thread
    CreateThread(function()
        local playerInfo = GetPlayerInfo(source)
        
        -- Добавяме информация към полетата
        local updatedFields = fields or {}
        table.insert(updatedFields, 1, {name = 'Играч', value = playerInfo.steamName, inline = true})
        table.insert(updatedFields, 2, {name = 'RP име', value = playerInfo.rpName, inline = true})
        
        local embed = {
            {
                title = title,
                description = description,
                color = color or Config.Logging.color.info,
                fields = updatedFields,
                timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
                thumbnail = {
                    url = playerInfo.avatar
                },
                footer = {
                    text = "Gun Robbery System",
                    icon_url = Config.Logging.avatar
                }
            }
        }
        
        local payload = {
            username = Config.Logging.botName,
            avatar_url = Config.Logging.avatar,
            embeds = embed
        }
        
        PerformHttpRequest(Config.Logging.webhook, function(err, text, headers)
            if err ~= 200 and Config.Debug then
                print('[ax-gunrob] Discord webhook error: ' .. tostring(err))
            end
        end, 'POST', json.encode(payload), {['Content-Type'] = 'application/json'})
    end)
end

-- Покупка на локатор
lib.callback.register('ax-gunrob:server:buyLocator', function(source)
    local Player = QBX:GetPlayer(source)
    if not Player then 
        return false
    end

    local playerMoney = Player.PlayerData.money.cash
    if playerMoney >= Config.Prices.locator then
        Player.Functions.RemoveMoney('cash', Config.Prices.locator, 'truck-locator-purchase')
        exports.ox_inventory:AddItem(source, Config.Locator.item, 1)
        
        -- Discord log за покупка на локатор (бърз)
        if Config.Logging.events.locatorPurchase then
            SendDiscordLog(source,
                '🛒 Локатор закупен',
                'Играч закупи GPS локатор',
                Config.Logging.color.success,
                {
                    {name = 'ID', value = tostring(source), inline = true},
                    {name = 'Цена', value = '$' .. Config.Prices.locator, inline = true},
                    {name = 'Остатъчни пари', value = '$' .. (playerMoney - Config.Prices.locator), inline = true}
                }
            )
        end
        
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Покупка успешна',
            description = 'Закупихте локатор за $' .. Config.Prices.locator,
            type = 'success'
        })
        return true
    else
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Недостатъчно средства',
            description = 'Нужни са $' .. Config.Prices.locator,
            type = 'error'
        })
        return false
    end
end)

-- Нова функция за валидиране на спаун на truck
local function ValidateTruckSpawn(source, retryCount)
    retryCount = retryCount or 0
    
    CreateThread(function()
        Wait(2000) -- Изчакваме 2 секунди за спаун
        
        -- Проверяваме дали truck-а е спауннат успешно
        lib.callback('ax-gunrob:client:validateTruckExists', source, function(exists, netId)
            if exists and netId then
                currentTruckNetId = netId
                truckSpawnInProgress = false
                
                TriggerClientEvent('ox_lib:notify', source, {
                    title = 'Успешно',
                    description = 'Въоръженият транспорт е спауннат и маркиран на картата',
                    type = 'success',
                    duration = 5000
                })
                
                if Config.Debug then
                    print('[ax-gunrob] Truck spawned successfully with NetId: ' .. netId)
                end
            else
                -- Truck не е спауннат успешно
                if retryCount < 3 then
                    if Config.Debug then
                        print('[ax-gunrob] Truck spawn failed, retrying... (attempt ' .. (retryCount + 1) .. '/3)')
                    end
                    
                    TriggerClientEvent('ox_lib:notify', source, {
                        title = 'Опит ' .. (retryCount + 1),
                        description = 'Повторен опит за спаунване на транспорта...',
                        type = 'inform'
                    })
                    
                    -- Повторен опит за спаунване
                    TriggerClientEvent('ax-gunrob:client:spawnTruck', source)
                    ValidateTruckSpawn(source, retryCount + 1)
                else
                    -- Неуспешен спаун след 3 опита
                    truckSpawnInProgress = false
                    activeRobbery = false
                    truckActive = false
                    
                    -- Връщаме парите на играча
                    local Player = QBX:GetPlayer(source)
                    if Player then
                        Player.Functions.AddMoney('cash', Config.Prices.robbery, 'truck-spawn-failed-refund')
                    end
                    
                    TriggerClientEvent('ox_lib:notify', source, {
                        title = 'Грешка при спаунване',
                        description = 'Не успяхме да спаунем транспорта. Парите са върнати.',
                        type = 'error',
                        duration = 8000
                    })
                    
                    if Config.Debug then
                        print('[ax-gunrob] Failed to spawn truck after 3 attempts for player: ' .. source)
                    end
                end
            end
        end)
    end)
end

-- Стартиране на обир
lib.callback.register('ax-gunrob:server:startRobbery', function(source)
    local Player = QBX:GetPlayer(source)
    if not Player then 
        return {success = false, message = 'Грешка при намиране на играч'}
    end

    if Config.Debug then
        print('[ax-gunrob] Start robbery attempt by player: ' .. source)
        print('[ax-gunrob] Current states - activeRobbery: ' .. tostring(activeRobbery) .. ', truckActive: ' .. tostring(truckActive) .. ', truckSpawnInProgress: ' .. tostring(truckSpawnInProgress))
        print('[ax-gunrob] truckCompletelyRobbed: ' .. tostring(truckCompletelyRobbed))
    end

    -- Използваме новата функция за проверка
    local canStart, reason = CanStartRobbery(source)
    if not canStart then
        if Config.Debug then
            print('[ax-gunrob] Robbery blocked by cooldown: ' .. reason)
        end
        return {success = false, message = reason}
    end

    if activeRobbery or truckActive or truckSpawnInProgress then
        if Config.Debug then
            print('[ax-gunrob] Robbery blocked - activeRobbery: ' .. tostring(activeRobbery) .. ', truckActive: ' .. tostring(truckActive) .. ', truckSpawnInProgress: ' .. tostring(truckSpawnInProgress))
        end
        return {success = false, message = 'В момента има активен обир или спаунване в процес'}
    end

    local playerMoney = Player.PlayerData.money.cash
    
    if playerMoney >= Config.Prices.robbery then
        Player.Functions.RemoveMoney('cash', Config.Prices.robbery, 'truck-robbery-start')
        
        activeRobbery = true
        truckActive = true
        truckSpawnInProgress = true
        truckCompletelyRobbed = false
        currentTruckNetId = nil
        
        -- Discord log за стартиране на обир (бърз)
        if Config.Logging.events.robberyStart then
            SendDiscordLog(source,
                '🚛 Lost MC Обир | Стартиран!',
                'Играч стартира обир на въоръжен транспорт',
                Config.Logging.color.warning,
                {
                    {name = 'ID', value = tostring(source), inline = true},
                    {name = 'Платена сума', value = '$' .. Config.Prices.robbery, inline = true},
                    {name = 'Оставащи пари', value = '$' .. (playerMoney - Config.Prices.robbery), inline = true},
                    {name = 'Час на обира', value = os.date('%H:%M:%S'), inline = true}
                }
            )
        end
        
        if Config.Debug then
            print('[ax-gunrob] Robbery started successfully by player: ' .. source)
        end
        
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Обир стартиран',
            description = 'Платихте $' .. Config.Prices.robbery .. ' за информация. Спаунваме транспорта...',
            type = 'success'
        })
        
        -- Спаунваме truck-а и валидираме
        TriggerClientEvent('ax-gunrob:client:spawnTruck', source)
        ValidateTruckSpawn(source)
        
        return {success = true, message = 'Обирът е стартиран успешно'}
    else
        return {success = false, message = 'Нужни са $' .. Config.Prices.robbery}
    end
end)

-- Опростена функция за завършване на обира
local function CompleteRobbery(source)
    if truckCompletelyRobbed then
        if Config.Debug then
            print('[ax-gunrob] Robbery already completed, ignoring duplicate call')
        end
        return
    end
    
    if Config.Debug then
        print('[ax-gunrob] Completing robbery for player: ' .. source)
    end
    
    truckCompletelyRobbed = true
    activeRobbery = false
    truckActive = false
    truckSpawnInProgress = false
    
    -- Задаваме cooldown-ите
    local currentTime = GetGameTimer()
    lastGlobalRobberyTime = currentTime
    
    local Player = QBX:GetPlayer(source)
    if Player then
        local identifier = Player.PlayerData.citizenid
        playerCooldowns[identifier] = currentTime
        
        if Config.Debug then
            print('[ax-gunrob] Cooldowns set - Global: ' .. lastGlobalRobberyTime .. ', Player (' .. identifier .. '): ' .. playerCooldowns[identifier])
        end
    end
    
    -- Discord log за завършване на обир (бърз)
    if Config.Logging.events.robberyComplete then
        local rewardsList = {}
        
        -- Вземаме информация за наградите от config-а
        for _, reward in pairs(Config.Rewards) do
            if math.random(100) <= reward.chance then
                table.insert(rewardsList, reward.item .. ' x' .. reward.amount)
            end
        end
        
        SendDiscordLog(source,
            '✅ Обир завършен успешно',
            'Играч завърши обир на въоръжен транспорт',
            Config.Logging.color.success,
            {
                {name = 'ID', value = tostring(source), inline = true},
                {name = 'Време на завършване', value = os.date('%H:%M:%S'), inline = true},
                {name = 'Cooldown активен', value = '12 часа (индивидуален)\n30 минути (глобален)', inline = false},
                {name = 'Възможни награди', value = table.concat(rewardsList, '\n') or 'Няма налични награди', inline = false}
            }
        )
    end
    
    -- Показваме completion съобщение
    TriggerClientEvent('ax-gunrob:client:robberyCompleted', source)
    
    TriggerClientEvent('ox_lib:notify', source, {
        title = '🎉 Обир успешно завършен! 🎉',
        description = 'Получихте 12 часа cooldown. Другите играчи могат да обират след 30 минути.',
        type = 'success',
        duration = 8000
    })
    
    
    -- Почистваме всички активни инвентари
    for inventoryId, data in pairs(activeInventories) do
        if truckInventoryCreated[inventoryId] then
            truckInventoryCreated[inventoryId] = nil
        end
    end
    activeInventories = {}
    
    if Config.Debug then
        print('[ax-gunrob] Robbery completed successfully')
    end
end

-- Премахваме старите event handlers за проверка на статус
-- RegisterNetEvent('ax-gunrob:server:checkInventoryStatus', function(inventoryId)

-- Добавяме ox_inventory event handler за detectване на взети items
AddEventHandler('ox_inventory:removedItem', function(playerId, inventoryId, item, count)
    if Config.Debug then
        print('[ax-gunrob] ox_inventory:removedItem triggered - Player: ' .. tostring(playerId) .. ', Inventory: ' .. tostring(inventoryId) .. ', Item: ' .. tostring(item.name or 'unknown'))
    end
    
    if not inventoryId or not string.match(inventoryId, '^truck_') then
        if Config.Debug then
            print('[ax-gunrob] Not a truck inventory, ignoring')
        end
        return
    end
    
    if not activeInventories[inventoryId] then
        if Config.Debug then
            print('[ax-gunrob] Inventory not in active list, ignoring')
        end
        return
    end
    
    if Config.Debug then
        print('[ax-gunrob] Item removed from ' .. inventoryId .. ': ' .. (item.name or 'unknown') .. ' x' .. count)
        print('[ax-gunrob] truckCompletelyRobbed status: ' .. tostring(truckCompletelyRobbed))
    end
    
    -- Веднага завършваме обира когато се вземе item
    local data = activeInventories[inventoryId]
    if data and data.source and not truckCompletelyRobbed then
        if Config.Debug then
            print('[ax-gunrob] Item taken, completing robbery immediately for player: ' .. data.source)
        end
        
        -- Малко delay за да се процесира item-а първо
        CreateThread(function()
            Wait(100)
            CompleteRobbery(data.source)
        end)
    else
        if Config.Debug then
            print('[ax-gunrob] Not completing robbery - data: ' .. tostring(data ~= nil) .. ', source: ' .. tostring(data and data.source) .. ', already completed: ' .. tostring(truckCompletelyRobbed))
        end
    end
end)

-- Алтернативни event handlers за различни версии на ox_inventory
AddEventHandler('ox_inventory:itemRemoved', function(playerId, inventoryId, item, count)
    if Config.Debug then
        print('[ax-gunrob] ox_inventory:itemRemoved triggered (alternative event)')
    end
    
    if not inventoryId or not string.match(inventoryId, '^truck_') then
        return
    end
    
    if not activeInventories[inventoryId] then
        return
    end
    
    local data = activeInventories[inventoryId]
    if data and data.source and not truckCompletelyRobbed then
        if Config.Debug then
            print('[ax-gunrob] Alternative event - completing robbery for player: ' .. data.source)
        end
        
        CreateThread(function()
            Wait(100)
            CompleteRobbery(data.source)
        end)
    end
end)

-- Още един алтернативен event
AddEventHandler('ox_inventory:itemTaken', function(playerId, inventoryId, item, count)
    if Config.Debug then
        print('[ax-gunrob] ox_inventory:itemTaken triggered')
    end
    
    if not inventoryId or not string.match(inventoryId, '^truck_') then
        return
    end
    
    if not activeInventories[inventoryId] then
        return
    end
    
    local data = activeInventories[inventoryId]
    if data and data.source and not truckCompletelyRobbed then
        CompleteRobbery(data.source)
    end
end)

-- Event за когато играч взима item от truck инвентар
RegisterNetEvent('ax-gunrob:server:playerTookItem', function(inventoryId, itemName, count)
    local source = source
    
    if Config.Debug then
        print('[ax-gunrob] Player took item event - Player: ' .. source .. ', Inventory: ' .. inventoryId .. ', Item: ' .. itemName .. ' x' .. count)
    end
    
    if not string.match(inventoryId, '^truck_') then
        return
    end
    
    if not activeInventories[inventoryId] then
        return
    end
    
    -- Ако това е периодична проверка, проверяваме дали инвентарът е празен
    if itemName == 'check' then
        CreateThread(function()
            Wait(100)
            
            if IsInventoryEmpty(inventoryId) and not truckCompletelyRobbed then
                if Config.Debug then
                    print('[ax-gunrob] Periodic check found empty inventory, completing robbery')
                end
                CompleteRobbery(source)
            elseif Config.Debug then
                print('[ax-gunrob] Periodic check - inventory still has items')
            end
        end)
    else
        -- Директно завършваме обира ако е взет конкретен item
        if not truckCompletelyRobbed then
            if Config.Debug then
                print('[ax-gunrob] Completing robbery because player took item: ' .. itemName)
            end
            CompleteRobbery(source)
        end
    end
end)

-- Debug event за проследяване на всички inventory събития
AddEventHandler('ox_inventory:*', function(eventName, ...)
    local args = {...}
    if Config.Debug then
        print('[ax-gunrob] ox_inventory event: ' .. eventName)
        for i, arg in ipairs(args) do
            print('  Arg ' .. i .. ': ' .. tostring(arg))
        end
    end
end)

-- Admin команди
if Config.Debug then
    RegisterCommand('spawntestruck', function(source, args, rawCommand)
        local Player = QBX:GetPlayer(source)
        if Player and QBX.HasPermission(source, 'admin') then
            if truckSpawnInProgress then
                TriggerClientEvent('ox_lib:notify', source, {
                    title = 'Admin',
                    description = 'Спаунване вече е в процес',
                    type = 'error'
                })
                return
            end
            
            activeRobbery = true
            truckActive = true
            truckCompletelyRobbed = false
            truckSpawnInProgress = true
            currentTruckNetId = nil
            truckInventoryCreated = {}
            
            -- Discord log за админ команда (бърз)
            if Config.Logging.events.adminCommands then
                SendDiscordLog(source,
                    '⚠️ Админ команда използвана',
                    'Администратор използва spawntestruck команда',
                    Config.Logging.color.warning,
                    {
                        {name = 'ID', value = tostring(source), inline = true},
                        {name = 'Команда', value = 'spawntestruck', inline = true},
                        {name = 'Време', value = os.date('%H:%M:%S'), inline = true}
                    }
                )
            end
            
            TriggerClientEvent('ax-gunrob:client:spawnTruck', source)
            ValidateTruckSpawn(source)
            
            TriggerClientEvent('ox_lib:notify', source, {
                title = 'Admin',
                description = 'Тест бус се спаунва...',
                type = 'success'
            })
        end
    end, true)
    
    RegisterCommand('clearrobbery', function(source, args, rawCommand)
        local Player = QBX:GetPlayer(source)
        if Player and QBX.HasPermission(source, 'admin') then
            activeRobbery = false
            truckActive = false
            truckCompletelyRobbed = false
            truckSpawnInProgress = false
            currentTruckNetId = nil
            truckInventoryCreated = {}
            activeInventories = {}
            lastGlobalRobberyTime = 0 -- Изчистваме глобален cooldown
            playerCooldowns = {} -- Изчистваме всички индивидуални cooldown-и
            
            -- Discord log за админ команда (бърз)
            if Config.Logging.events.adminCommands then
                SendDiscordLog(source,
                    '🔄 Обир изчистен',
                    'Администратор изчисти активния обир и cooldown-ите',
                    Config.Logging.color.info,
                    {
                        {name = 'ID', value = tostring(source), inline = true},
                        {name = 'Команда', value = 'clearrobbery', inline = true},
                        {name = 'Действие', value = 'Изчистени всички състояния и cooldown-и', inline = false}
                    }
                )
            end
            
            TriggerClientEvent('ox_lib:notify', source, {
                title = 'Admin',
                description = 'Обирът е изчистен напълно. Всички cooldown-и са премахнати.',
                type = 'success'
            })
        end
    end, true)
    
    RegisterCommand('forcecomplete', function(source, args, rawCommand)
        local Player = QBX:GetPlayer(source)
        if Player and QBX.HasPermission(source, 'admin') then
            -- Discord log за админ команда (бърз)
            if Config.Logging.events.adminCommands then
                SendDiscordLog(source,
                    '⚡ Принудително завършване',
                    'Администратор принудително завърши обира',
                    Config.Logging.color.warning,
                    {
                        {name = 'ID', value = tostring(source), inline = true},
                        {name = 'Команда', value = 'forcecomplete', inline = true}
                    }
                )
            end
            
            CompleteRobbery(source)
            
            TriggerClientEvent('ox_lib:notify', source, {
                title = 'Admin',
                description = 'Обирът е завършен принудително',
                type = 'success'
            })
        end
    end, true)
    
    RegisterCommand('checkcooldown', function(source, args, rawCommand)
        local Player = QBX:GetPlayer(source)
        if Player and QBX.HasPermission(source, 'admin') then
            local globalTimeLeft = GetGlobalCooldownTime()
            local playerTimeLeft = GetPlayerCooldownTime(source)
            local isGlobalOnCooldown = IsGlobalOnCooldown()
            local isPlayerOnCooldown = IsPlayerOnCooldown(source)
            
            local message = string.format(
                'Глобален cooldown: %s (%s)\nВашия cooldown: %s (%s)', 
                isGlobalOnCooldown and 'Активен' or 'Неактивен',
                FormatTime(globalTimeLeft),
                isPlayerOnCooldown and 'Активен' or 'Неактивен',
                FormatTime(playerTimeLeft)
            )
            
            TriggerClientEvent('ox_lib:notify', source, {
                title = 'Cooldown Status',
                description = message,
                type = 'inform',
                duration = 8000
            })
        end
    end, true)
    
    -- Нова админ команда за ръчно задаване на cooldown за тестване
    RegisterCommand('setcooldown', function(source, args, rawCommand)
        local Player = QBX:GetPlayer(source)
        if Player and QBX.HasPermission(source, 'admin') then
            local identifier = Player.PlayerData.citizenid
            
            -- Задаваме глобален cooldown
            lastGlobalRobberyTime = GetGameTimer()
            
            -- Задаваме индивидуален cooldown
            playerCooldowns[identifier] = GetGameTimer()
            
            TriggerClientEvent('ox_lib:notify', source, {
                title = 'Admin',
                description = 'Cooldown-ите са задени ръчно за тестване',
                type = 'success'
            })
            
            print('[ax-gunrob] Manual cooldowns set:')
            print('  Global: ' .. lastGlobalRobberyTime)
            print('  Player (' .. identifier .. '): ' .. playerCooldowns[identifier])
        end
    end, true)
    
    -- Нова команда за показване на всички cooldown-и
    RegisterCommand('listcooldowns', function(source, args, rawCommand)
        local Player = QBX:GetPlayer(source)
        if Player and QBX.HasPermission(source, 'admin') then
            print('[ax-gunrob] Current cooldowns:')
            print('  Global last robbery: ' .. lastGlobalRobberyTime)
            print('  Player cooldowns:')
            for identifier, time in pairs(playerCooldowns) do
                print('    ' .. identifier .. ': ' .. time)
            end
            
            TriggerClientEvent('ox_lib:notify', source, {
                title = 'Admin',
                description = 'Cooldown информацията е изпратена в конзолата',
                type = 'inform'
            })
        end
    end, true)
    
    -- Нова админ команда за изчистване на индивидуален cooldown
    RegisterCommand('clearplayercooldown', function(source, args, rawCommand)
        local Player = QBX:GetPlayer(source)
        if Player and QBX.HasPermission(source, 'admin') then
            if args[1] then
                local targetId = tonumber(args[1])
                local targetPlayer = QBX:GetPlayer(targetId)
                if targetPlayer then
                    local identifier = targetPlayer.PlayerData.citizenid
                    playerCooldowns[identifier] = nil
                    
                    TriggerClientEvent('ox_lib:notify', source, {
                        title = 'Admin',
                        description = 'Cooldown-а на играч ' .. targetId .. ' е изчистен',
                        type = 'success'
                    })
                else
                    TriggerClientEvent('ox_lib:notify', source, {
                        title = 'Admin',
                        description = 'Играч не е намерен',
                        type = 'error'
                    })
                end
            else
                -- Изчистваме собствения cooldown
                local identifier = Player.PlayerData.citizenid
                playerCooldowns[identifier] = nil
                
                TriggerClientEvent('ox_lib:notify', source, {
                    title = 'Admin',
                    description = 'Вашия cooldown е изчистен',
                    type = 'success'
                })
            end
        end
    end, true)
end

-- Изчистване на завършени инвентари
RegisterNetEvent('ax-gunrob:server:cleanupInventory', function(netId)
    local inventoryId = 'truck_' .. netId
    if truckInventoryCreated[inventoryId] then
        truckInventoryCreated[inventoryId] = nil
    end
    if activeInventories[inventoryId] then
        activeInventories[inventoryId] = nil
    end
    
    -- Изчистваме текущия truck ако е същия
    if currentTruckNetId == netId then
        currentTruckNetId = nil
    end
    
    if Config.Debug then
        print('[ax-gunrob] Cleaned up truck inventory: ' .. inventoryId)
    end
end)

-- Нов event за известяване на успешен спаун от клиента
RegisterNetEvent('ax-gunrob:server:truckSpawned', function(netId)
    local source = source
    currentTruckNetId = netId
    truckSpawnInProgress = false
    
    if Config.Debug then
        print('[ax-gunrob] Truck spawn confirmed by client with NetId: ' .. netId)
    end
end)

-- Създаване на truck инвентар
lib.callback.register('ax-gunrob:server:createTruckInventory', function(source, netId)
    local inventoryId = 'truck_' .. netId
    
    if truckInventoryCreated[inventoryId] then
        if Config.Debug then
            print('[ax-gunrob] Inventory already exists: ' .. inventoryId)
        end
        return inventoryId
    end
    
    -- Създаваме stash инвентар
    exports.ox_inventory:RegisterStash(inventoryId, 'Въоръжен транспорт', 20, 100000)
    
    -- Добавяме награди в инвентаря
    for _, reward in pairs(Config.Rewards) do
        if math.random(100) <= reward.chance then
            if reward.item == 'Money' then
                -- За пари използваме специален метод
                exports.ox_inventory:AddItem(inventoryId, 'money', reward.amount)
            else
                -- За обикновени предмети
                exports.ox_inventory:AddItem(inventoryId, reward.item, reward.amount)
            end
            
            if Config.Debug then
                print('[ax-gunrob] Added to ' .. inventoryId .. ': ' .. reward.item .. ' x' .. reward.amount)
            end
        end
    end
    
    truckInventoryCreated[inventoryId] = true
    activeInventories[inventoryId] = {
        source = source,
        netId = netId,
        created = GetGameTimer()
    }
    
    if Config.Debug then
        print('[ax-gunrob] Created truck inventory: ' .. inventoryId)
    end
    
    return inventoryId
end)

-- Отваряне на truck инвентар
lib.callback.register('ax-gunrob:server:openTruckInventory', function(source, netId)
    local inventoryId = 'truck_' .. netId
    
    if not truckInventoryCreated[inventoryId] then
        if Config.Debug then
            print('[ax-gunrob] Inventory does not exist, creating: ' .. inventoryId)
        end
        
        -- Създаваме инвентаря ако не съществува
        exports.ox_inventory:RegisterStash(inventoryId, 'Въоръжен транспорт', 20, 100000)
        
        -- Добавяме награди в инвентаря
        for _, reward in pairs(Config.Rewards) do
            if math.random(100) <= reward.chance then
                if reward.item == 'Money' then
                    exports.ox_inventory:AddItem(inventoryId, 'money', reward.amount)
                else
                    exports.ox_inventory:AddItem(inventoryId, reward.item, reward.amount)
                end
                
                if Config.Debug then
                    print('[ax-gunrob] Added to ' .. inventoryId .. ': ' .. reward.item .. ' x' .. reward.amount)
                end
            end
        end
        
        truckInventoryCreated[inventoryId] = true
        activeInventories[inventoryId] = {
            source = source,
            netId = netId,
            created = GetGameTimer()
        }
    else
        -- Актуализираме source-а ако инвентарът вече съществува
        if activeInventories[inventoryId] then
            activeInventories[inventoryId].source = source
        end
    end
    
    if Config.Debug then
        print('[ax-gunrob] Opening truck inventory: ' .. inventoryId .. ' for player: ' .. source)
    end
    
    return inventoryId
end)

-- Event за създаване на truck инвентар (алтернативен метод)
RegisterNetEvent('ax-gunrob:server:createTruckInventory', function(netId)
    local source = source
    local inventoryId = 'truck_' .. netId
    
    if truckInventoryCreated[inventoryId] then
        if Config.Debug then
            print('[ax-gunrob] Inventory already exists: ' .. inventoryId)
        end
        return
    end
    
    -- Създаваме stash инвентар
    exports.ox_inventory:RegisterStash(inventoryId, 'Въоръжен транспорт', 20, 100000)
    
    -- Добавяме награди в инвентаря
    for _, reward in pairs(Config.Rewards) do
        if math.random(100) <= reward.chance then
            if reward.item == 'Money' then
                exports.ox_inventory:AddItem(inventoryId, 'money', reward.amount)
            else
                exports.ox_inventory:AddItem(inventoryId, reward.item, reward.amount)
            end
            
            if Config.Debug then
                print('[ax-gunrob] Added to ' .. inventoryId .. ': ' .. reward.item .. ' x' .. reward.amount)
            end
        end
    end
    
    truckInventoryCreated[inventoryId] = true
    activeInventories[inventoryId] = {
        source = source,
        netId = netId,
        created = GetGameTimer()
    }
    
    if Config.Debug then
        print('[ax-gunrob] Created truck inventory via event: ' .. inventoryId)
    end
end)

print('[ax-gunrob] Server loaded successfully with QBX Core')