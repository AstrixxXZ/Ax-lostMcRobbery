-- SQL за добавяне на item в базата данни (ако се използва)
-- Този файл е опционален и зависи от начина, по който ox_inventory управлява items

-- За ox_inventory с database items:
INSERT INTO `items` (`name`, `label`, `weight`, `rare`, `can_remove`) VALUES 
('truck_locator', 'Локатор за транспорт', 500, 0, 1);

-- Алтернативно за други inventory системи:
-- INSERT INTO `items` (`item`, `label`, `limit`, `can_remove`, `type`, `usable`, `image`) VALUES
-- ('truck_locator', 'Локатор за транспорт', 50, 1, 'item', 1, 'truck_locator.png');
