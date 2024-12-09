math.randomseed(os.time()) -- Инициализация генератора случайных чисел

-- Класс для игры
Game = {}
Game.__index = Game

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

-- Вывод поля на экран
function Game:dump()
    print("Вывод поля:")
    print("    1 2 3 4 5 6 7 8 9 10")
    print("- - - - - - - - - - - -- ")
    for i = 1, 10 do
        if i == 10
        then
            io.write(i .. "| ")
        else
            io.write(i .. " | ")
        end
        -- Для вывода индексов с 0
        for j = 1, 10 do
            io.write(self.field[i][j] .. " ")
        end
        print()
    end
end

-- Выполнение тика (проверка на наличие троек и их удаление)
function Game:tick()
    print("Выполнение тика...")  -- Добавим отладочную печать
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
        local emptyRows = {}
        -- Собираем пустые строки
        for row = 1, 10 do
            if not self.field[row][col] then
                table.insert(emptyRows, row)
            end
        end
        -- Перемещаем кристаллы вниз
        for _, row in ipairs(emptyRows) do
            for r = row, 2, -1 do
                self.field[r][col] = self.field[r - 1][col]
                self.field[r - 1][col] = nil
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
    else
        print("Некорректное перемещение.")
    end
end

-- Перемешивание поля
function Game:mix()
    self:init()
end

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
    print("Игра началась!")  -- Выводим сообщение
    local game = setmetatable({}, Game)
    game:init()

    -- Первый вывод поля

    while game:tick() do
        game:tick() -- Выполняем первый тик
    end
    game:dump()

    while true do
        print("Введите ход (например, 'm x y r' для перемещения или 'q' для выхода):")
        io.flush()  -- Принудительно сбрасываем буфер перед чтением
        local input = io.read()

        if input == "q" then
            print("Выход из игры.")
            break
        elseif input:match("m (%d+) (%d+) ([lrud])") then
            local x, y, dir = input:match("m (%d+) (%d+) ([lrud])")
            x, y = tonumber(x), tonumber(y)
            -- Определяем новую позицию в зависимости от направления
            local to
            if dir == 'l' and x > 1 then
                to = { x - 1, y }  -- Влево
            elseif dir == 'r' and x <= 10 then
                to = { x + 1, y }  -- Вправо
            elseif dir == 'u' and y > 1 then
                to = { x, y - 1 }  -- Вверх
            elseif dir == 'd' and y <= 10 then
                to = { x, y + 1 }  -- Вниз
            else
                print("Некорректный ход: выход за границы игрового поля.")
                return
            end

            if to then
                print(string.format("Перемещение с [%d, %d] на [%d, %d]", x, y, to[1], to[2]))
                game:move({ x, y }, to)
                -- Выполняем тик
                while game:tick() do
                    game:tick() -- Выполняем первый тик
                end

                -- Выводим поле
                game:dump()

                -- Если поле без изменений, перемешиваем
                if not game:checkForMoves() then
                    print("Нет возможных ходов, поле перемешано.")
                    game:mix()
                    game:dump()
                end
            end
        else
            print("Некорректный ввод.")
        end
    end
end

main()


