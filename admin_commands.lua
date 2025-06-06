-- Тестови и admin команди (опционални)
-- Добавете тези команди в server.lua ако искате тестови възможности

if Config.Debug then
    -- Команда за reset на cooldown
    RegisterCommand('resetrobcooldown', function(source, args, rawCommand)
        local Player = QBCore.Functions.GetPlayer(source)
        if Player and QBCore.Functions.HasPermission(source, 'admin') then
            lastRobberyTime = 0
            TriggerClientEvent('ox_lib:notify', source, {
                title = 'Admin',
                description = 'Общият cooldown за обир е resetнат',
                type = 'success'
            })
        end
    end, true)

    -- Нова команда за reset на индивидуален cooldown
    RegisterCommand('resetplayerrobcooldown', function(source, args, rawCommand)
        local Player = QBCore.Functions.GetPlayer(source)
        if Player and QBCore.Functions.HasPermission(source, 'admin') then
            local targetId = tonumber(args[1])
            if not targetId then
                TriggerClientEvent('ox_lib:notify', source, {
                    title = 'Admin',
                    description = 'Използвай: /resetplayerrobcooldown [ID]',
                    type = 'error'
                })
                return
            end
            
            local TargetPlayer = QBCore.Functions.GetPlayer(targetId)
            if not TargetPlayer then
                TriggerClientEvent('ox_lib:notify', source, {
                    title = 'Admin',
                    description = 'Играчът не е намерен',
                    type = 'error'
                })
                return
            end
            
            local citizenId = TargetPlayer.PlayerData.citizenid
            playerCooldowns[citizenId] = nil
            
            TriggerClientEvent('ox_lib:notify', source, {
                title = 'Admin',
                description = 'Индивидуалният cooldown на ' .. TargetPlayer.PlayerData.charinfo.firstname .. ' ' .. TargetPlayer.PlayerData.charinfo.lastname .. ' е resetнат',
                type = 'success'
            })
            
            TriggerClientEvent('ox_lib:notify', targetId, {
                title = 'Admin',
                description = 'Твоят cooldown за обир е resetнат от администратор',
                type = 'inform'
            })
        end
    end, true)

    -- Команда за проверка на cooldown на играч
    RegisterCommand('checkplayerrobcooldown', function(source, args, rawCommand)
        local Player = QBCore.Functions.GetPlayer(source)
        if Player and QBCore.Functions.HasPermission(source, 'admin') then
            local targetId = tonumber(args[1])
            if not targetId then
                TriggerClientEvent('ox_lib:notify', source, {
                    title = 'Admin',
                    description = 'Използвай: /checkplayerrobcooldown [ID]',
                    type = 'error'
                })
                return
            end
            
            local TargetPlayer = QBCore.Functions.GetPlayer(targetId)
            if not TargetPlayer then
                TriggerClientEvent('ox_lib:notify', source, {
                    title = 'Admin',
                    description = 'Играчът не е намерен',
                    type = 'error'
                })
                return
            end
            
            local citizenId = TargetPlayer.PlayerData.citizenid
            local isOnCooldown = IsPlayerOnCooldown(citizenId)
            local timeLeft = GetPlayerCooldownTime(citizenId)
            
            if isOnCooldown then
                local hoursLeft = math.floor(timeLeft / 3600)
                local minutesLeft = math.floor((timeLeft % 3600) / 60)
                
                TriggerClientEvent('ox_lib:notify', source, {
                    title = 'Player Cooldown Info',
                    description = TargetPlayer.PlayerData.charinfo.firstname .. ' ' .. TargetPlayer.PlayerData.charinfo.lastname .. ' има cooldown още ' .. hoursLeft .. ' часа и ' .. minutesLeft .. ' минути',
                    type = 'inform',
                    duration = 8000
                })
            else
                TriggerClientEvent('ox_lib:notify', source, {
                    title = 'Player Cooldown Info',
                    description = TargetPlayer.PlayerData.charinfo.firstname .. ' ' .. TargetPlayer.PlayerData.charinfo.lastname .. ' НЯМА cooldown',
                    type = 'success'
                })
            end
        end
    end, true)

    -- Команда за спауване на тест бус
    RegisterCommand('spawntestruck', function(source, args, rawCommand)
        local Player = QBCore.Functions.GetPlayer(source)
        if Player and QBCore.Functions.HasPermission(source, 'admin') then
            if not activeRobbery then
                activeRobbery = true
                TriggerClientEvent('ax-gunrob:client:spawnTruck', source)
                TriggerClientEvent('ox_lib:notify', source, {
                    title = 'Admin',
                    description = 'Тест бус е спауннат',
                    type = 'success'
                })
            else
                TriggerClientEvent('ox_lib:notify', source, {
                    title = 'Admin',
                    description = 'Вече има активен обир',
                    type = 'error'
                })
            end
        end
    end, true)

    -- Команда за тестване на blip
    RegisterCommand('testtruckblip', function(source, args, rawCommand)
        local Player = QBCore.Functions.GetPlayer(source)
        if Player and QBCore.Functions.HasPermission(source, 'admin') then
            TriggerClientEvent('ax-gunrob:client:testBlip', source)
        end
    end, true)

    -- Команда за форсиране на blip
    RegisterCommand('forcetruckblip', function(source, args, rawCommand)
        local Player = QBCore.Functions.GetPlayer(source)
        if Player and QBCore.Functions.HasPermission(source, 'admin') then
            TriggerClientEvent('ax-gunrob:client:forceCreateBlip', source)
        end
    end, true)

    -- Команда за изчистване на активен обир
    RegisterCommand('clearrobbery', function(source, args, rawCommand)
        local Player = QBCore.Functions.GetPlayer(source)
        if Player and QBCore.Functions.HasPermission(source, 'admin') then
            activeRobbery = false
            TriggerClientEvent('ax-gunrob:client:cleanupRobbery', -1)
            TriggerClientEvent('ox_lib:notify', source, {
                title = 'Admin',
                description = 'Активният обир е изчистен',
                type = 'success'
            })
        end
    end, true)

    -- Команда за даване на локатор
    RegisterCommand('givelocator', function(source, args, rawCommand)
        local Player = QBCore.Functions.GetPlayer(source)
        if Player and QBCore.Functions.HasPermission(source, 'admin') then
            local targetId = tonumber(args[1]) or source
            exports.ox_inventory:AddItem(targetId, Config.Locator.item, 1)
            TriggerClientEvent('ox_lib:notify', source, {
                title = 'Admin',
                description = 'Локатор е даден на играч ' .. targetId,
                type = 'success'
            })
        end
    end, true)

    -- Команда за проверка на статус
    RegisterCommand('robberyinfo', function(source, args, rawCommand)
        local Player = QBCore.Functions.GetPlayer(source)
        if Player and QBCore.Functions.HasPermission(source, 'admin') then
            local cooldownLeft = GetCooldownTime()
            local status = activeRobbery and 'Активен' or 'Неактивен'
            local truckStatus = truckActive and 'Активен' or 'Неактивен'
            local debugStatus = Config.Debug and 'Включен' or 'Изключен'
            local cooldownDisabled = (Config.Debug and Config.DisableCooldownInDebug) and 'Изключен' or 'Активен'
            
            -- Проверка на собствения cooldown
            local citizenId = Player.PlayerData.citizenid
            local playerCooldownLeft = GetPlayerCooldownTime(citizenId)
            local playerHoursLeft = math.floor(playerCooldownLeft / 3600)
            local playerMinutesLeft = math.floor((playerCooldownLeft % 3600) / 60)
            
            TriggerClientEvent('ox_lib:notify', source, {
                title = 'Robbery Info',
                description = 'Статус: ' .. status .. '\nБус: ' .. truckStatus .. '\nОбщ Cooldown: ' .. cooldownLeft .. 's\nТвой Cooldown: ' .. playerHoursLeft .. 'ч ' .. playerMinutesLeft .. 'м\nDebug: ' .. debugStatus .. '\nCooldown система: ' .. cooldownDisabled,
                type = 'inform',
                duration = 10000
            })
        end
    end, true)

    -- Команда за force reset на всичко
    RegisterCommand('resetrobbery', function(source, args, rawCommand)
        local Player = QBCore.Functions.GetPlayer(source)
        if Player and QBCore.Functions.HasPermission(source, 'admin') then
            lastRobberyTime = 0
            activeRobbery = false
            truckActive = false
            truckSpawned = false
            
            TriggerClientEvent('ax-gunrob:client:cleanupRobbery', -1)
            
            TriggerClientEvent('ox_lib:notify', source, {
                title = 'Admin',
                description = 'Всички robbery данни са resetнати',
                type = 'success'
            })
        end
    end, true)
end
