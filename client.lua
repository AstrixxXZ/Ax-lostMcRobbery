local QBX = exports.qbx_core

-- Глобални променливи
local vendorPed = nil
local truckEntity = nil
local truckCrew = {}
local bikerEntities = {}
local truckBlip = nil
local robberyInProgress = false
local truckLocked = true
local truckRobbed = false
local robberyCompleted = false

-- Функция за зареждане на модел
local function LoadModel(model)
    local modelHash = GetHashKey(model)
    RequestModel(modelHash)
    while not HasModelLoaded(modelHash) do
        Wait(100)
    end
    return modelHash
end

-- Функция за показване на информационно меню (преработена)
local function ShowInformationMenu()
    lib.registerContext({
        id = 'gunrob_info_main',
        title = '📋 Информация за обири',
        menu = 'gunrob_vendor_menu',
        options = {
            {
                title = '🎯 Как работи системата?',
                description = 'Основна информация за обирите',
                icon = 'fa-solid fa-question-circle',
                onSelect = function()
                    lib.alertDialog({
                        header = '🎯 Как работи системата?',
                        content = [[
**1️⃣ Стартирай обир**
Плати $]] .. Config.Prices.robbery .. [[ за информация за въоръжен транспорт

**2️⃣ Намери транспорта**
Транспортът се спаунва с червен блип на картата

**3️⃣ Взломи заключването**
Използвай lockpick за да отключиш буса

**4️⃣ Обери багажника**
Вземи предметите от багажника за да завършиш обира

**⚠️ Внимание:**
Транспортът е охраняван от въоръжени рокери!
                        ]],
                        centered = true,
                        cancel = true
                    })
                end
            },
            {
                title = '⏰ Cooldown информация',
                description = 'Информация за времето на изчакване',
                icon = 'fa-solid fa-clock',
                onSelect = function()
                    lib.alertDialog({
                        header = '⏰ Cooldown информация',
                        content = [[
**🕐 Индивидуален cooldown: 12 часа**
Играчът който завърши обира трябва да изчака 12 часа

**🌍 Глобален cooldown: 30 минути**
Всички останали играчи могат да стартират обир след 30 минути

**💡 Съвет:**
Можеш да използваш локатор за да намериш активен транспорт който друг играч е стартирал

**📍 GPS Локатор:**
Показва местоположението на активен транспорт (ако има такъв)
                        ]],
                        centered = true,
                        cancel = true
                    })
                end
            },
            {
                title = '⚠️ Предупреждения и съвети',
                description = 'Важна информация за безопасност',
                icon = 'fa-solid fa-exclamation-triangle',
                onSelect = function()
                    lib.alertDialog({
                        header = '⚠️ Предупреждения и съвети',
                        content = [[
**🔫 Въоръжена охрана:**
Транспортът е охраняван от много добре въоръжени рокери на мотори!

**🚔 Полицейски алерт:**
]] .. Config.PoliceChance .. [[% шанс полицията да бъде уведомена при завършване

**🔒 Изисквания:**
Трябва ти lockpick за да взломиш транспорта

**💊 Препоръки за екипировка:**
• Носи бронежилетки
• Вземи достатъчно боеприпаси
• Използвай добри оръжия
• Играй с приятели за по-голям шанс за успех

**🎯 Стратегия:**
Елиминирай първо мотористите, след това екипажа на буса
                        ]],
                        centered = true,
                        cancel = true
                    })
                end
            },
            {
                title = '◀️ Назад',
                description = 'Връщане към главното меню',
                icon = 'fa-solid fa-arrow-left',
                onSelect = function()
                    lib.showContext('gunrob_vendor_menu')
                end
            }
        }
    })
    
    lib.showContext('gunrob_info_main')
end

-- Функция за показване на vendor меню
local function ShowVendorMenu()
    lib.registerContext({
        id = 'gunrob_vendor_menu',
        title = '🔫 Доставчик на информация',
        options = {
            {
                title = '📋 Информация',
                description = 'Научи как работи системата за обири',
                icon = 'fa-solid fa-info-circle',
                onSelect = function()
                    ShowInformationMenu()
                end
            },
            {
                title = '💰 Купи локатор',
                description = 'Купи GPS локатор за $' .. Config.Prices.locator,
                icon = 'fa-solid fa-location-dot',
                onSelect = function()
                    lib.callback('ax-gunrob:server:buyLocator', false, function(success) end)
                end
            },
            {
                title = '💀 Стартирай обир',
                description = 'Плати $' .. Config.Prices.robbery .. ' за информация за въоръжен транспорт',
                icon = 'fa-solid fa-mask',
                onSelect = function()
                    lib.callback('ax-gunrob:server:startRobbery', false, function(result)
                        if not result.success then
                            lib.notify({
                                title = 'Грешка',
                                description = result.message,
                                type = 'error'
                            })
                        end
                    end)
                end
            },
            {
                title = '❌ Затвори',
                description = 'Затвори менюто',
                icon = 'fa-solid fa-times',
                onSelect = function()
                    lib.hideContext()
                end
            }
        }
    })
    
    lib.showContext('gunrob_vendor_menu')
end

-- Създаване на NPC vendor
local function CreateVendorPed()
    if vendorPed then return end
    
    local modelHash = LoadModel(Config.Vendor.model)
    vendorPed = CreatePed(4, modelHash, Config.Vendor.coords.x, Config.Vendor.coords.y, Config.Vendor.coords.z - 1.0, Config.Vendor.coords.w, false, true)
    
    SetEntityHeading(vendorPed, Config.Vendor.coords.w)
    FreezeEntityPosition(vendorPed, true)
    SetEntityInvincible(vendorPed, true)
    SetBlockingOfNonTemporaryEvents(vendorPed, true)
    
    -- Създаване на blip
    if Config.Vendor.blip then
        local blip = AddBlipForEntity(vendorPed)
        SetBlipSprite(blip, Config.Vendor.blip.sprite)
        SetBlipColour(blip, Config.Vendor.blip.color)
        SetBlipScale(blip, Config.Vendor.blip.scale)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(Config.Vendor.blip.label)
        EndTextCommandSetBlipName(blip)
    end
    
    -- ox_target опции за vendor - отваря ox_lib меню
    exports.ox_target:addLocalEntity(vendorPed, {
        {
            name = 'talk_to_vendor',
            icon = 'fas fa-comments',
            label = 'Разговаряй с доставчика',
            onSelect = function()
                ShowVendorMenu()
            end
        }
    })
    
    print('[ax-gunrob] Vendor NPC е успешно създаден!')
end

-- Спауване на бус
RegisterNetEvent('ax-gunrob:client:spawnTruck', function()
    print('[ax-gunrob] Спаунване на камиона...')
    
    CleanupTruckEntities()
    Wait(1000)
    
    local modelHash = LoadModel(Config.Truck.model)
    truckEntity = CreateVehicle(modelHash, Config.Truck.spawnCoords.x, Config.Truck.spawnCoords.y, Config.Truck.spawnCoords.z, Config.Truck.spawnCoords.w, true, false)
    
    if not DoesEntityExist(truckEntity) then
        print('[ax-gunrob] Неуспешно създаване на камиона!')
        return
    end
    
    SetVehicleEngineOn(truckEntity, true, true, false)
    SetVehicleDoorsLocked(truckEntity, 2)
    SetEntityAsMissionEntity(truckEntity, true, true)
    
    SpawnTruckCrew()
    SpawnBikers()
    
    -- Движение на буса
    if Config.Truck.shouldMove and truckCrew.driver then
        TaskVehicleDriveWander(truckCrew.driver, truckEntity, Config.Truck.speed, Config.Truck.drivingStyle)
    end
    
    -- Създаване на blip - поправено
    Wait(1000) -- Изчакваме буса да се създаде напълно
    
    if DoesEntityExist(truckEntity) then
        truckBlip = AddBlipForEntity(truckEntity)
        if truckBlip then
            SetBlipSprite(truckBlip, Config.Truck.blip.sprite or 477)
            SetBlipColour(truckBlip, Config.Truck.blip.color or 1)
            SetBlipScale(truckBlip, Config.Truck.blip.scale or 0.8)
            SetBlipAsShortRange(truckBlip, false)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString(Config.Truck.blip.label or "Truck Robbery")
            EndTextCommandSetBlipName(truckBlip)
            
            if Config.Debug then
                print('[ax-gunrob] Блипа на камиона е успешно създаден ID: ' .. truckBlip)
            end
        else
            print('[ax-gunrob] Неуспешно създаване на блип за камиона')
        end
    else
        print('[ax-gunrob] Неуспешно създаване на камиона')
    end

    -- ox_target
    exports.ox_target:addLocalEntity(truckEntity, {
        {
            name = 'lockpick_truck',
            icon = 'fas fa-key',
            label = 'Взломи заключването',
            distance = 3.0,
            onSelect = function() LockpickTruck() end,
            canInteract = function() return truckLocked and not robberyInProgress and not robberyCompleted end
        },
        {
            name = 'rob_truck',
            icon = 'fas fa-hand-holding-usd',
            label = 'Обери багажника',
            distance = 3.0,
            onSelect = function() RobTruck() end,
            canInteract = function() return not truckLocked and not robberyInProgress and not truckRobbed and not robberyCompleted end
        },
        {
            name = 'open_trunk',
            icon = 'fas fa-box-open',
            label = 'Отвори багажника',
            distance = 3.0,
            onSelect = function() OpenTruckInventory() end,
            canInteract = function() return not truckLocked and not robberyInProgress and truckRobbed and not robberyCompleted end
        }
    })
    
    lib.notify({
        title = 'Рокери пренасят оръжия',
        description = 'Пренос на оръжия потегли!!!',
        type = 'success'
    })
    
    print('[ax-gunrob] Буса е успешно спаунат!')
end)

-- Функция за спауване на екипажа
function SpawnTruckCrew()
    truckCrew = {}
    
    local driverHash = LoadModel(Config.Truck.crew.driver.model)
    truckCrew.driver = CreatePedInsideVehicle(truckEntity, 26, driverHash, -1, true, false)
    
    if DoesEntityExist(truckCrew.driver) then
        SetupCrewMember(truckCrew.driver, Config.Truck.crew.driver)
    end
    
    local passengerHash = LoadModel(Config.Truck.crew.passenger.model)
    truckCrew.passenger = CreatePedInsideVehicle(truckEntity, 26, passengerHash, 0, true, false)
    
    if DoesEntityExist(truckCrew.passenger) then
        SetupCrewMember(truckCrew.passenger, Config.Truck.crew.passenger)
    end
end

-- Настройка на член от екипажа
function SetupCrewMember(ped, config)
    SetEntityAsMissionEntity(ped, true, true)
    SetPedFleeAttributes(ped, 0, 0)
    SetPedCombatAttributes(ped, 46, 1)
    SetPedAccuracy(ped, config.accuracy)
    SetEntityMaxHealth(ped, config.health)
    SetEntityHealth(ped, config.health)
    GiveWeaponToPed(ped, GetHashKey(config.weapon), 250, false, true)
    SetPedRelationshipGroupHash(ped, GetHashKey('HATES_PLAYER'))
end

-- Функция за зареждане на анимация
local function LoadAnimDict(dict)
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do
        Wait(10)
    end
end

-- Взломяване на буса
function LockpickTruck()
    if robberyInProgress or not truckLocked then return end
    
    exports['ps-dispatch']:VanRobbery()
    robberyInProgress = true
    
    -- Зареждаме и играем анимацията (с проверка за наличие)
    local playerPed = PlayerPedId()
    if Config.Lockpick and Config.Lockpick.animation then
        LoadAnimDict(Config.Lockpick.animation.dict)
        TaskPlayAnim(playerPed, Config.Lockpick.animation.dict, Config.Lockpick.animation.name, 8.0, -8.0, -1, Config.Lockpick.animation.flag, 0, false, false, false)
    end
    
    local success = exports.bl_ui:MineSweeper(3, {
        grid = 6, -- grid 6x6
        duration = 10000, -- 10sec to fail
        target = 5, --target you need to remember
        previewDuration = 2000 --preview duration (time for red mines preview to hide)
    })
    
    -- Спираме анимацията
    ClearPedTasks(playerPed)
    
    if success then
        truckLocked = false
        SetVehicleDoorsLocked(truckEntity, 1)
        SetVehicleDoorOpen(truckEntity, 5, false, false) -- Багажник
        
        lib.notify({
            title = 'Успешно взломяване',
            description = 'Буса е отключен!',
            type = 'success'
        })
    else
        if Config.Lockpick.removeOnFail then
            TriggerServerEvent('ax-gunrob:server:removeLockpick')
        end
        
        lib.notify({
            title = 'Неуспешно взломяване',
            description = 'Lockpick-ът се счупи!',
            type = 'error'
        })
    end
    
    robberyInProgress = false
end

-- Обиране на буса
function RobTruck()
    if robberyInProgress or truckLocked or truckRobbed then return end
    
    robberyInProgress = true
    
    -- Зареждаме и играем анимацията за обиране
    local playerPed = PlayerPedId()
    if Config.ProgressBar and Config.ProgressBar.robbery and Config.ProgressBar.robbery.animation then
        LoadAnimDict(Config.ProgressBar.robbery.animation.dict)
        TaskPlayAnim(playerPed, Config.ProgressBar.robbery.animation.dict, Config.ProgressBar.robbery.animation.name, 8.0, -8.0, -1, 1, 0, false, false, false)
    end
    
    local success = lib.progressBar({
        duration = Config.ProgressBar.robbery.duration,
        label = Config.ProgressBar.robbery.label,
        useWhileDead = false,
        canCancel = true,
        disable = { move = true, car = true, combat = true }
    })
    
    -- Спираме анимацията
    ClearPedTasks(playerPed)
    
    if success then
        truckRobbed = true
        local netId = NetworkGetNetworkIdFromEntity(truckEntity)
        TriggerServerEvent('ax-gunrob:server:createTruckInventory', netId)
        TriggerServerEvent('ax-gunrob:server:completeRobbery')
        
        lib.notify({
            title = 'Обир завършен',
            description = 'Можете да отворите багажника!',
            type = 'success'
        })
    end
    
    robberyInProgress = false
end

-- Отваряне на инвентаря
function OpenTruckInventory()
    if not truckEntity or robberyInProgress or robberyCompleted then return end
    
    local netId = NetworkGetNetworkIdFromEntity(truckEntity)
    
    lib.callback('ax-gunrob:server:openTruckInventory', false, function(inventoryId)
        if inventoryId then
            exports.ox_inventory:openInventory('stash', inventoryId)
            
            lib.notify({
                title = 'Багажник отворен',
                description = 'Вземете предметите от багажника. Обирът ще се завърши автоматично когато вземете item.',
                type = 'inform',
                duration = 5000
            })
            
            -- Опростена проверка - периодично уведомяваме сървъра
            CreateThread(function()
                local checkCount = 0
                
                while checkCount < 30 and not robberyCompleted do -- 30 секунди максимум
                    Wait(2000) -- Проверяваме на всеки 2 секунди
                    checkCount = checkCount + 1
                    
                    if not robberyCompleted then
                        if Config.Debug then
                            print('[ax-gunrob] Периодична проверка - sending item taken event')
                        end
                        
                        -- Уведомяваме сървъра че може да е взет item
                        TriggerServerEvent('ax-gunrob:server:playerTookItem', inventoryId, 'check', 1)
                    end
                end
            end)
        else
            lib.notify({
                title = 'Грешка',
                description = 'Не може да се отвори багажникът',
                type = 'error'
            })
        end
    end, netId)
end

-- Спауване на мотори
function SpawnBikers()
    bikerEntities = {}
    local truckCoords = GetEntityCoords(truckEntity)
    
    for i = 1, Config.Truck.bikers.count do
        local bikeModel = Config.Truck.bikers.bikes[math.random(#Config.Truck.bikers.bikes)]
        local riderModel = Config.Truck.bikers.riders.models[math.random(#Config.Truck.bikers.riders.models)]
        local weapon = Config.Truck.bikers.riders.weapons[i] or 'WEAPON_PISTOL'
        
        local bikeHash = LoadModel(bikeModel)
        local riderHash = LoadModel(riderModel)
        
        local offset = Config.Truck.bikers.positions[i] or vector3(math.random(-10, 10), math.random(5, 15), 0.0)
        local bikeCoords = truckCoords + offset
        
        local bike = CreateVehicle(bikeHash, bikeCoords.x, bikeCoords.y, bikeCoords.z, 0.0, true, false)
        
        if DoesEntityExist(bike) then
            local rider = CreatePedInsideVehicle(bike, 26, riderHash, -1, true, false)
            
            if DoesEntityExist(rider) then
                SetEntityAsMissionEntity(bike, true, true)
                SetEntityAsMissionEntity(rider, true, true)
                SetPedAccuracy(rider, Config.Truck.bikers.riders.accuracy)
                SetEntityMaxHealth(rider, Config.Truck.bikers.riders.health)
                SetEntityHealth(rider, Config.Truck.bikers.riders.health)
                GiveWeaponToPed(rider, GetHashKey(weapon), 250, false, true)
                SetPedRelationshipGroupHash(rider, GetHashKey('HATES_PLAYER'))
                
                TaskVehicleEscort(rider, bike, truckEntity, -1, 15.0, 786603, 8.0 + i * 2.0, 0, 15.0)
                
                table.insert(bikerEntities, {bike = bike, rider = rider})
            else
                DeleteEntity(bike)
            end
        end
        
        Wait(100)
    end
end

-- Завършване на обира
RegisterNetEvent('ax-gunrob:client:robberyCompleted', function()
    robberyCompleted = true
    
    -- Премахваме всички ox_target опции веднага
    if truckEntity then
        exports.ox_target:removeLocalEntity(truckEntity, {'lockpick_truck', 'rob_truck', 'open_trunk'})
        
        -- Добавяме само опция за преглед (без възможност за отваряне)
        exports.ox_target:addLocalEntity(truckEntity, {
            {
                name = 'truck_robbed',
                icon = 'fas fa-check-circle',
                label = 'Обирът е завършен',
                distance = 3.0,
                onSelect = function() 
                    lib.notify({
                        title = 'Обир завършен',
                        description = 'Този транспорт е вече обран напълно.',
                        type = 'inform'
                    })
                end
            }
        })
    end
    
    lib.notify({
        title = '🎉 МИСИЯ ЗАВЪРШЕНА! 🎉',
        description = 'Обрахте въоръженият транспорт! Cooldown е активиран. Буса ще изчезне скоро.',
        type = 'success',
        duration = 8000
    })
    
    -- Изчакваме 30 секунди и изчистваме всичко
    SetTimeout(30000, function()
        CleanupTruckEntities()
    end)
end)

-- Изчистване
function CleanupTruckEntities()
    if truckBlip and DoesBlipExist(truckBlip) then
        RemoveBlip(truckBlip)
        truckBlip = nil
    end
    
    if truckEntity then
        local netId = NetworkGetNetworkIdFromEntity(truckEntity)
        TriggerServerEvent('ax-gunrob:server:cleanupInventory', netId)
        
        exports.ox_target:removeLocalEntity(truckEntity, {'lockpick_truck', 'rob_truck', 'open_trunk', 'truck_robbed'})
        DeleteEntity(truckEntity)
        truckEntity = nil
    end
    
    for _, member in pairs(truckCrew) do
        if DoesEntityExist(member) then
            DeleteEntity(member)
        end
    end
    truckCrew = {}
    
    for _, biker in pairs(bikerEntities) do
        if DoesEntityExist(biker.rider) then DeleteEntity(biker.rider) end
        if DoesEntityExist(biker.bike) then DeleteEntity(biker.bike) end
    end
    bikerEntities = {}
    
    truckRobbed = false
    robberyCompleted = false
    truckLocked = true
end

-- Показване на локацията
RegisterNetEvent('ax-gunrob:client:showTruckLocation', function()
    if truckEntity and DoesEntityExist(truckEntity) then
        local coords = GetEntityCoords(truckEntity)
        SetNewWaypoint(coords.x, coords.y)
        
        lib.notify({
            title = 'Локатор активиран',
            description = 'Локацията е маркирана на картата',
            type = 'success'
        })
    end
end)

-- Callback за валидиране на спауване на truck
lib.callback.register('ax-gunrob:client:validateTruckExists', function()
    if truckEntity and DoesEntityExist(truckEntity) then
        local netId = NetworkGetNetworkIdFromEntity(truckEntity)
        if Config.Debug then
            print('[ax-gunrob] Truck validation - exists: true, NetId: ' .. netId)
        end
        return true, netId
    else
        if Config.Debug then
            print('[ax-gunrob] Truck validation - exists: false')
        end
        return false, nil
    end
end)

-- Инициализация
CreateThread(function()
    Wait(2000)
    CreateVendorPed()
end)

print('[ax-gunrob] Клиента успешно зареден!')
-- Регистрация на събития