# Настройки за ox_inventory

## Добавяне на item в ox_inventory

### Метод 1: Използване на data/items.lua файл
Копирайте съдържанието от `data/items.lua` файла в items.lua конфигурацията на ox_inventory.

### Метод 2: Използване на exports в server.lua
Добавете следния код в server.lua на ox_inventory:

```lua
-- Регистриране на truck_locator item
exports.ox_inventory:registerItem('truck_locator', {
    label = 'Локатор за транспорт',
    weight = 500,
    stack = false,
    close = true,
    description = 'Устройство за проследяване на въоръжени транспорти',
    client = {
        image = 'truck_locator.png',
        usetime = 2500,
        export = 'ax-gunrob.useLocator'
    }
})
```

## Изображение за item-а

Поставете изображение с име `truck_locator.png` в папката:
`ox_inventory/web/images/`

Препоръчителен размер: 100x100 пиксела в PNG формат.

## Алтернативни item имена

Ако искате да промените името на item-а, редактирайте:
- `Config.Locator.item` в config.lua
- Името на item-а в data/items.lua
- Export функцията в client.lua

## Тестване на item-а

За тестване може да използвате следните команди (ако имате админ права):

```
/giveitem [playerId] truck_locator 1
```

Или чрез ox_inventory:
```
/ox give [playerId] truck_locator 1
```
