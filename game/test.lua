-- Инициализация генератора случайных чисел
math.randomseed(os.time())

-- Класс для игры
Game = {}
Game.__index = Game

-- Цвета для каждого типа кристалла
local colorCodes = {
    A = "\27[31m", -- Красный
    B = "\27[32m", -- Зеленый
    C = "\27[33m", -- Желтый
    D = "\27[34m", -- Синий
    E = "\27[35m", -- Фиолетовый
    F = "\27[36m"  -- Голубой
}
local resetCode = "\27[0m" -- Сброс цвета

-- Инициализация поля
function Game:init()
    self.field = {}
    self.colors = { 'A', 'B', 'C', 'D', 'E', 'F' }

    -- Создание поля 10x10 с случайными кристаллами
    for i = 1, 10 do
        self.field[i] = {}
        for j = 1, 10 do
            self.field[i][j] = self.colors[math.random(1, 6)]
        end
    end
end

-- Вывод поля на экран с цветами
function Game:dump()
    print("Вывод поля:")
    print("    1 2 3 4 5 6 7 8 9 10")
    print("- - - - - - - - - - - -- ")
    for i = 1, 10 do
        if i == 10 then
            io.write(i .. "| ")
        else
            io.write(i .. " | ")
        end
        for j = 1, 10 do
            local crystal = self.field[i][j]
            local color = colorCodes[crystal] or resetCode
            io.write(color .. crystal .. resetCode .. " ")
        end
        print()
    end
end

-- Выполнение тика (проверка на наличие троек и их удаление)
function Game:tick()
    local changed = false
    -- Проверка на вертикальные троики
    for i = 1, 10 do
        for j = 1, 8 do
            if self.field[j][i] == self.field[j + 1][i] and self.field[j][i] == self.field[j + 2][i] then
                self:clearVertical(j, i)
                changed = true
            end
        end
    end
    -- Проверка на горизонтальные троики
    for i = 1, 8 do
        for j = 1, 10 do
            if self.field[i][j] == self.field[i][j + 1] and self.field[i][j] == self.field[i][j + 2] then
                self:clearHorizontal(i, j)
                changed = true
            end
        end
    end
    if changed then
        self:dropDown()
        self:addNewCrystals()
        return true
    else
        return false
    end
end

-- Очистка вертикальной линии
function Game:clearVertical(row, col)
    self.field[row][col] = nil
    self.field[row + 1][col] = nil
    self.field[row + 2][col] = nil
end

-- Очистка горизонтальной линии
function Game:clearHorizontal(row, col)
    self.field[row][col] = nil
    self.field[row][col + 1] = nil
    self.field[row][col + 2] = nil
end

-- Смещение кристаллов вниз
function Game:dropDown()
    for col = 1, 10 do
        for row = 10, 2, -1 do
            if not self.field[row][col] then
                for r = row - 1, 1, -1 do
                    if self.field[r][col] then
                        self.field[row][col] = self.field[r][col]
                        self.field[r][col] = nil
                        break
                    end
                end
            end
        end
    end
end

-- Добавление новых кристаллов
function Game:addNewCrystals()
    for i = 1, 10 do
        for j = 1, 10 do
            if not self.field[i][j] then
                self.field[i][j] = self.colors[math.random(1, 6)]
            end
        end
    end
end

-- Перемещение кристалла
function Game:move(from, to)
    local fromX, fromY = from[1], from[2]
    local toX, toY = to[1], to[2]

    -- Проверяем, что перемещение допустимо
    if math.abs(fromX - toX) + math.abs(fromY - toY) == 1 and
            self.field[toX] and self.field[toX][toY] then
        -- Меняем местами кристаллы
        self.field[toX][toY], self.field[fromX][fromY] = self.field[fromX][fromY], self.field[toX][toY]
        return true
    else
        print("Некорректное перемещение.")
        return false
    end
end


-- Перемешивание поля
function Game:mix()
    self:init()
end

-- Проверка на доступные ходы
function Game:checkForMoves()
    local directions = {
        { 0, 1 }, -- Вправо
        { 1, 0 }, -- Вниз
    }

    for i = 1, 10 do
        for j = 1, 10 do
            local currentCrystal = self.field[i][j]
            if currentCrystal then
                -- Проверяем возможные перемещения
                for _, dir in ipairs(directions) do
                    local ni, nj = i + dir[1], j + dir[2]
                    -- Если перемещение внутри границ
                    if ni <= 10 and nj <= 10 then
                        local targetCrystal = self.field[ni][nj]
                        if targetCrystal then
                            -- Меняем кристаллы местами для проверки
                            self.field[i][j], self.field[ni][nj] = self.field[ni][nj], self.field[i][j]
                            -- Проверяем, образуется ли цепочка
                            if self:hasMatch(i, j) or self:hasMatch(ni, nj) then
                                -- Возвращаем на место
                                self.field[i][j], self.field[ni][nj] = self.field[ni][nj], self.field[i][j]
                                return true
                            end
                            -- Возвращаем на место
                            self.field[i][j], self.field[ni][nj] = self.field[ni][nj], self.field[i][j]
                        end
                    end
                end
            end
        end
    end
    return false
end

-- Метод для проверки, есть ли цепочка из 3+ кристаллов в данной позиции
function Game:hasMatch(i, j)
    local color = self.field[i][j]
    if not color then
        return false
    end

    -- Проверяем горизонталь
    local count = 1
    for dj = -1, 1 do
        if dj ~= 0 then
            local nj = j + dj
            while nj >= 1 and nj <= 10 and self.field[i][nj] == color do
                count = count + 1
                nj = nj + dj
            end
        end
    end
    if count >= 3 then
        return true
    end

    -- Проверяем вертикаль
    count = 1
    for di = -1, 1 do
        if di ~= 0 then
            local ni = i + di
            while ni >= 1 and ni <= 10 and self.field[ni][j] == color do
                count = count + 1
                ni = ni + di
            end
        end
    end
    return count >= 3
end

function main()
    print("Игра началась!")
    local game = setmetatable({}, Game)
    game:init()

    -- Первый вывод поля
    while game:tick() do
        game:tick()
    end
    game:dump()

    while true do
        print("Введите ход (например, 'm x y r' для перемещения или 'q' для выхода):")
        io.flush()
        local input = io.read()

        if input == "q" then
            print("Выход из игры.")
            break
        elseif input:match("m (%d+) (%d+) ([lrud])") then
            local y, x, dir = input:match("m (%d+) (%d+) ([lrud])")
            x, y = tonumber(x), tonumber(y)

            -- Определяем новую позицию в зависимости от направления
            local to
            if dir == 'l' then
                to = { x, y - 1 } -- Влево
            elseif dir == 'r' then
                to = { x, y + 1 } -- Вправо
            elseif dir == 'u' then
                to = { x - 1, y } -- Вверх
            elseif dir == 'd' then
                to = { x + 1, y } -- Вниз
            else
                print("Некорректный ход: выход за границы игрового поля.")
                return
            end

            if to then
                print(string.format("Перемещение с [%d, %d] на [%d, %d]", y, x, to[2], to[1]))
                local validMove = game:move({ x, y }, to)

                if validMove then
                    -- Проверяем наличие совпадений
                    local flagTick = game:tick()
                    while flagTick do
                        flagTick = game:tick()
                    end

                    -- Выводим поле
                    game:dump()

                    -- Проверяем доступные ходы
                    if not game:checkForMoves() then
                        print("Нет возможных ходов, поле перемешано.")
                        game:mix()
                        game:dump()
                    end
                else
                    print("Некорректное перемещение.")
                end
            end
        else
            print("Некорректный ввод.")
        end
    end
end
main()