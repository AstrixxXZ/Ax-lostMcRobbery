Config = {}

-- Основни настройки
Config.Debug = true -- Включва debug съобщения в конзолата

-- Настройки за NPC Vendor
Config.Vendor = {
    model = 'g_m_y_lost_01', -- Модел на NPC-то (байкер)
    coords = vector4(-1202.1, -1308.47, 4.92, 114.42), -- Координати и ъгъл на NPC-то
    animation = {
        dict = 'amb@world_human_smoking@male@male_a@idle_a',
        name = 'idle_c'
    },
    --blip = {
    --    sprite = 478, -- Иконка на blip-а
    --    color = 1, -- Цвят на blip-а (червен)
    --    scale = 0.8,
    --    label = 'Информатор'
    --}
}

-- Настройки за цени
Config.Prices = {
    locator = 30000, -- Цена за локатор
    robbery = 60000 -- Цена за стартиране на обир
}

-- Настройки за локатор предмет
Config.Locator = {
    item = 'truck_locator', -- Име на предмета
    removeAfterUse = true -- Дали да се премахва след употреба
}

-- Настройки за lockpick
Config.Lockpick = {
    item = 'lockpick', -- Изисквано за взломяване
    difficulty = 3, -- Трудност (1-5, 1 = лесно)
    removeOnFail = true, -- Премахва lockpick при неуспех
    removeOnSuccess = false, -- Не премахва при успех
    animation = {
        dict = 'anim@amb@clubhouse@tutorial@bkr_tut_ig3@',
        name = 'machinic_loop_mechandplayer',
        flag = 1 -- Повтаря се
    }
}

-- Настройки за буса
Config.Truck = {
    model = 'gburrito2', -- Модел на буса
    spawnCoords = vector4(1328.51, -2565.18, 46.15, 107.0), -- Нови координати за спауване
    shouldMove = true, -- Дали буса да се движи
    speed = 10.0, -- Скорост на движение (15 mph)
    drivingStyle = 786603, -- Стил на шофиране
    
    -- Настройки за шофьора и пасажера
    crew = {
        driver = {
            model = 'g_m_y_lost_02',
            weapon = 'WEAPON_PISTOL',
            accuracy = 85,
            health = 500
        },
        passenger = {
            model = 'g_m_y_lost_01',
            weapon = 'WEAPON_PISTOL',
            accuracy = 80,
            health = 450
        }
    },
    
    -- Настройки за мотори с рокери
    bikers = {
        count = 5, -- Брой мотори (увеличен на 8)
        bikes = {
            'daemon2',
        },
        riders = {
            models = {
                'g_m_y_lost_01',
            },
            weapons = {
                'WEAPON_PISTOL',    -- 1-ви мотор с Pistol .50
                'WEAPON_PISTOL',    -- 2-ри мотор с Pistol .50
                'WEAPON_PISTOL',    -- 3-ти мотор с Pistol .50
                'WEAPON_PISTOL',    -- 4-ти мотор с Pistol .50
                'WEAPON_PISTOL',      -- 5-ти мотор с обикновен пистолет
                'WEAPON_PISTOL',-- 6-ти мотор с combat пистолет
                'WEAPON_PISTOL',   -- 7-ми мотор с SNS пистолет
                'WEAPON_PISTOL'     -- 8-ми мотор с Micro SMG
            },
            accuracy = 75,
            health = 400
        },
        -- Позиции около буса (8 позиции)
        positions = {
            vector3(0.0, 12.0, 0.0),   -- Най-отпред център
            vector3(-4.0, 10.0, 0.0),  -- Отпред лява външна
            vector3(4.0, 10.0, 0.0),   -- Отпред дясна външна
            vector3(-2.0, 8.0, 0.0),   -- Отпред лява вътрешна
            vector3(2.0, 8.0, 0.0),    -- Отпред дясна вътрешна
            vector3(-6.0, 6.0, 0.0),   -- Страна лява далечна
            vector3(6.0, 6.0, 0.0),    -- Страна дясна далечна
            vector3(0.0, 15.0, 0.0)    -- Най-отпред водач
        }
    },
    
    -- Настройки за blip (фиксирани)
    blip = {
        sprite = 477, -- Иконка на blip-а (Crate Drop) - по-видима
        color = 1, -- Цвят (червен)
        scale = 1.0, -- Нормален размер
        label = 'Въоръжен транспорт'
    }
}

-- Настройки за прогрес бар при обиране
Config.ProgressBar = {
    lockpick = {
        duration = 5000, -- 5 секунди за lockpick (намалено за тестване)
        label = 'Взломяване на заключването...',
        useWhileDead = false,
        canCancel = true,
        animation = {
            dict = 'anim@amb@clubhouse@tutorial@bkr_tut_ig3@',
            name = 'machinic_loop_mechandplayer'
        }
    },
    robbery = {
        duration = 40000, -- 40 секунди за обиране
        label = 'Взимане на съдържанието от багажника...',
        useWhileDead = false,
        canCancel = true,
        animation = {
            dict = 'anim@heists@ornate_bank@grab_cash',
            name = 'grab'
        }
    },
    openTrunk = {
        duration = 3000, -- 3 секунди за отваряне
        label = 'Отваряне на багажника...',
        useWhileDead = false,
        canCancel = true,
        animation = {
            dict = 'mini@repair',
            name = 'fixing_a_player'
        }
    }
}

-- Награди от обира
Config.Rewards = {
    {
        item = 'Money',
        amount = 15000, -- Сума мръсни пари
        chance = 100 -- Шанс в проценти (100 = винаги)
    },
    --{
    --    item = 'gold_bar',
    --    amount = 2,
    --    chance = 60 -- 60% шанс
    --},
    {
        item = 'diamond',
        amount = 1,
        chance = 30 -- 30% шанс
    },
    {
        item = 'rolex',
        amount = 1,
        chance = 45 -- 45% шанс
    },
    -- Оръжия
    {
        item = 'WEAPON_PISTOL',
        amount = 1,
        chance = 80 -- 80% шанс за пистолет
    },
    --{
    --    item = 'WEAPON_COMBATPISTOL',
    --    amount = 1,
    --    chance = 70 -- 70% шанс за combat пистолет
    --},
    {
        item = 'WEAPON_SNSPISTOL',
        amount = 1,
        chance = 60 -- 60% шанс за SNS пистолет
    },
    {
        item = 'WEAPON_MICROSMG',
        amount = 1,
        chance = 70 -- 50% шанс за micro SMG
    },
    --{
    --    item = 'WEAPON_MINISMG',
    --    amount = 1,
    --    chance = 45 -- 45% шанс за mini SMG
    --},
    -- Патрони
    {
        item = 'ammo-9',
        amount = 20,
        chance = 90 -- 90% шанс за патрони за пистолет
    },
    {
        item = 'xtcbaggy',
        amount = 10,
        chance = 80 -- 80% шанс за патрони за SMG
    },
    -- Жилетки
    {
        item = 'armour',
        amount = 3,
        chance = 85 -- 85% шанс за жилетки
    },
    -- Наркотици
    {
        item = 'weed_brick',
        amount = 1,
        chance = 100 -- 100% шанс за 5 weed brick
    }
}

-- Cooldown настройки
Config.Cooldown = 60000 -- Cooldown в милисекунди (1 минута вместо 30)
Config.DisableCooldownInDebug = false -- Променяме на false за да работят cooldown-ите винаги

-- Настройки за полицейски алерт
Config.NotifyPolice = true -- Дали да се уведомява полицията
Config.PoliceChance = 85 -- Шанс за полицейски алерт в проценти

-- Локации за спауване на буса (случайно избиране)
Config.TruckSpawnLocations = {
    vector4(1021.67, -967.76, 30.29, 195.07), -- Новата основна локация
    vector4(-1038.4, -2394.9, 14.1, 45.0), -- Близо до летището
    vector4(1175.6, -3113.8, 6.0, 90.0), -- Индустриална зона
    vector4(-543.5, -1637.8, 19.4, 225.0), -- Близо до болницата
    vector4(265.6, -1261.3, 29.1, 270.0) -- Центъра на града
}

-- Настройки за оръжията и екипировката на охраната
Config.Guards = {
    weapons = {
        'WEAPON_CARBINERIFLE',
        'WEAPON_ASSAULTRIFLE',
        'WEAPON_COMBATPISTOL'
    },
    accuracy = {
        min = 65,
        max = 85
    },
    health = {
        min = 300,
        max = 500
    }
}

-- Минимални изисквания
Config.Requirements = {
    minPlayers = 0, -- Минимален брой играчи онлайн
    requiredItems = {}, -- Изисквани предмети за стартиране
    requiredJobs = {} -- Изисквани работи (празно = всички)
}

-- Настройки за уведомления
Config.Notifications = {
    truckSpawned = {
        title = 'Въоръжен транспорт',
        message = 'Въоръжен транспорт се движи в града!',
        type = 'inform',
        duration = 8000
    },
    robberyStarted = {
        title = 'Обир започнат',
        message = 'Някой започна обир на въоръжен транспорт!',
        type = 'error',
        duration = 6000
    },
    robberyCompleted = {
        title = '🎉 Обир завършен! 🎉',
        message = 'Успешно обрахте въоръженият транспорт!',
        type = 'success',
        duration = 10000
    },
    cooldownActive = {
        title = 'Cooldown активен',
        message = 'Трябва да изчакате преди следващия обир.',
        type = 'warning',
        duration = 5000
    }
}

-- Настройки за интеракция
Config.Interaction = {
    distance = 3.0, -- Разстояние за интеракция
    key = 38, -- Клавиш за интеракция (E)
    holdTime = 2000 -- Време за задържане на клавиша
}

-- Звукови ефекти
Config.Sounds = {
    enabled = true,
    robberyStart = 'CHECKPOINT_PERFECT',
    robberyComplete = 'ROBBERY_MONEY_TOTAL',
    purchase = 'PURCHASE'
}

-- Настройки за export функции
Config.Exports = {
    enabled = true,
    functions = {
        'useLocator',
        'startRobbery',
        'getTruckLocation'
    }
}

-- Logging настройки (за Discord webhook)
Config.Logging = {
    enabled = true,
    webhook = 'https://discord.com/api/webhooks/1380592086855974962/mFfVGixpJotc__UGMqV2emIf92PB318bztpvUtrIeXRboc1zfzinmy5IOO9eiXdu55J7', -- Замени с твоя Discord webhook URL
    botName = 'Gun Robbery Logger',
    avatar = 'https://cdn.discordapp.com/attachments/837214588617359380/1380593720067621046/gtav-gtavrp.gif?ex=68447199&is=68432019&hm=6a576bdc2e63b6496f1a3ff8a27f6a0fbf1fd084dffba432da122e226ae0e5cd&',
    color = {
        success = 3066993, -- Green
        error = 15158332,   -- Red
        warning = 15105570, -- Orange
        info = 3447003      -- Blue
    },
    events = {
        robberyStart = true,
        robberyComplete = true,
        locatorPurchase = true,
        locatorUse = true,
        adminCommands = true
    }
}

-- Настройки за автоматично изчистване
Config.AutoCleanup = {
    enabled = true,
    truckTimeout = 1800000, -- 30 минути след спауване
    cleanupInterval = 300000, -- Проверка на всеки 5 минути
    robberyCompleteTimeout = 30000 -- 30 секунди след завършване на обира
}

-- Настройки за завършване на обир
Config.RobberyCompletion = {
    checkInterval = 1000, -- Проверка на всяка секунда
    maxCheckTime = 30000, -- Максимално време за проверка (30 секунди)
    showCompletionMessage = true, -- Показване на съобщение за завършване
    removeTargetOptions = true, -- Премахване на опциите за взаимодействие
    activateCooldown = true, -- Активиране на cooldown след завършване
    cleanupDelay = 30000 -- Време за изчистване на буса (30 секунди)
}

if Config.Debug then
    print('[ax-gunrob] Konфигурацията е заредена успешно!')
end
