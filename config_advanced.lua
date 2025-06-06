-- Допълнителна конфигурация за advanced опции

Config.Advanced = {
    -- Звукови ефекти
    sounds = {
        robberyStart = 'HEIST_PREP_IMPACT_SOUNDS',
        robberyComplete = 'ROBBERY_MONEY_TOTAL',
        purchaseSuccess = 'PURCHASE'
    },
    
    -- Парaметри за NPC шофьор
    driverBehavior = {
        fightBack = true,        -- Бори ли се шофьорът
        callBackup = false,      -- Извиква ли подкрепления
        fleeDamage = 50,         -- На колко % здраве бяга
        aggressionLevel = 2      -- Ниво на агресия (0-3)
    },
    
    -- Условия за метео и време
    weatherRestrictions = {
        enabled = false,         -- Активиране на ограничения
        allowedWeather = {       -- Разрешени времена
            'CLEAR',
            'CLOUDS', 
            'OVERCAST',
            'SMOG'
        },
        timeRestrictions = {     -- Времеви ограничения 
            startHour = 20,      -- От 20:00
            endHour = 6          -- До 06:00
        }
    },
    
    -- Анти-експлойт мерки
    antiExploit = {
        maxDistance = 10.0,      -- Макс разстояние до vendor
        checkVehicle = true,     -- Проверка дали играчът е във возило
        checkWeapons = false,    -- Проверка за оръжия
        minimumPlayers = 0       -- Минимален брой играчи онлайн
    },
    
    -- Възможности за стилизиране
    customization = {
        truckMods = {
            engine = 3,          -- Ниво на двигател
            brakes = 2,          -- Ниво на спирачки
            armor = 4            -- Ниво на броня
        },
        vendorOutfit = {
            enabled = false,
            components = {}      -- Компоненти за облекло
        }
    },
    
    -- Статистики и логове
    logging = {
        enabled = true,
        logPurchases = true,
        logRobberies = true,
        logItemUse = true,
        webhook = ''             -- Discord webhook URL
    }
}

-- Функция за проверка на времето
function Config.IsValidTime()
    if not Config.Advanced.weatherRestrictions.enabled then
        return true
    end
    
    local hour = GetClockHours()
    local weather = GetCurrentWeatherType()
    
    -- Проверка за време
    local timeValid = false
    if Config.Advanced.weatherRestrictions.timeRestrictions.startHour > Config.Advanced.weatherRestrictions.timeRestrictions.endHour then
        -- Нощно време (напр. 20:00 - 06:00)
        timeValid = hour >= Config.Advanced.weatherRestrictions.timeRestrictions.startHour or hour <= Config.Advanced.weatherRestrictions.timeRestrictions.endHour
    else
        -- Дневно време (напр. 08:00 - 18:00)
        timeValid = hour >= Config.Advanced.weatherRestrictions.timeRestrictions.startHour and hour <= Config.Advanced.weatherRestrictions.timeRestrictions.endHour
    end
    
    -- Проверка за време
    local weatherValid = false
    for _, allowedWeather in pairs(Config.Advanced.weatherRestrictions.allowedWeather) do
        if weather == allowedWeather then
            weatherValid = true
            break
        end
    end
    
    return timeValid and weatherValid
end
