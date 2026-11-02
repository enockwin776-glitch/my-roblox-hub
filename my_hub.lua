-- Загрузка библиотеки интерфейса Rayfield
local Rayfield = loadstring(game:HttpGet('https://sirius.menu'))()

-- Создание главного окна
local Window = Rayfield:CreateWindow({
   Name = "Universal Visuals HUB",
   LoadingTitle = "Синхронизация визуальных модулей...",
   LoadingSubtitle = "by Разработчики",
   ConfigurationSaving = { Enabled = false }
})

-- Создаем вкладку для красивых визуалов
local VisualsTab = Window:CreateTab("Визуалы (Универсальные)", 4483345998)

-- Глобальные настройки (таблица состояний чит-хаба)
local Settings = {
    WallhackEnabled = false,
    BoxesEnabled = false,
    FillColor = Color3.fromRGB(255, 0, 100),    -- Неоново-розовый цвет
    OutlineColor = Color3.fromRGB(0, 255, 255)  -- Неоново-бирюзовая обводка
}

-- УНИВЕРСАЛЬНАЯ ФУНКЦИЯ ДЛЯ ПОИСКА ЧАСТЕЙ ТЕЛА
local function getCharacterCore(character)
    if not character then return nil end
    return character:FindFirstChild("HumanoidRootPart") 
        or character:FindFirstChild("UpperTorso") 
        or character:FindFirstChild("Torso") 
        or character:FindFirstChildWhichIsA("BasePart")
end

-- ==========================================
-- МОДУЛЬ 1: КРАСИВАЯ ПОДСВЕТКА (HIGHLIGHT ESP)
-- ==========================================
local function applyHighlight(character)
    if not character or not Settings.WallhackEnabled then return end
    
    local player = game.Players:GetPlayerFromCharacter(character)
    if player == game.Players.LocalPlayer then return end -- Игнорируем себя

    -- Проверяем дубликаты
    local oldHl = character:FindFirstChild("UniversalHighlight")
    if oldHl then oldHl:Destroy() end

    local hl = Instance.new("Highlight")
    hl.Name = "UniversalHighlight"
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop -- Видно сквозь стены
    hl.FillColor = Settings.FillColor
    hl.FillTransparency = 0.5
    hl.OutlineColor = Settings.OutlineColor
    hl.OutlineTransparency = 0
    hl.Parent = character
end

-- ==========================================
-- МОДУЛЬ 2: НИКИ И ДИСТАНЦИЯ (BILLBOARD ESP)
-- ==========================================
local function applyBillboard(character)
    if not character or not Settings.BoxesEnabled then return end
    
    local player = game.Players:GetPlayerFromCharacter(character)
    if player == game.Players.LocalPlayer then return end

    local core = getCharacterCore(character)
    if not core then return end

    local oldBb = core:FindFirstChild("UniversalBillboard")
    if oldBb then oldBb:Destroy() end

    local bb = Instance.new("BillboardGui")
    bb.Name = "UniversalBillboard"
    bb.Size = UDim2.new(0, 200, 0, 50)
    bb.Unclipped = true
    bb.AlwaysOnTop = true -- Поверх текстур

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = player.DisplayName or player.Name
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextSize = 14
    label.Font = Enum.Font.GothamBold
    label.TextStrokeTransparency = 0 -- Обводка букв
    label.Parent = bb
    
    bb.Parent = core
end

-- ==========================================
-- СИСТЕМА ОБНОВЛЕНИЯ ИГРОКОВ В РЕАЛЬНОМ ВРЕМЕНИ
-- ==========================================
local function refreshVisualsForCharacter(character)
    task.spawn(function()
        task.wait(0.5) -- Ожидание полной загрузки персонажа игрой
        if Settings.WallhackEnabled then applyHighlight(character) end
        if Settings.BoxesEnabled then applyBillboard(character) end
    end)
end

-- Постоянный пересчет дистанции в реальном времени
task.spawn(function()
    while task.wait(0.5) do
        if Settings.BoxesEnabled then
            for _, p in ipairs(game.Players:GetPlayers()) do
                if p.Character and p ~= game.Players.LocalPlayer then
                    local core = getCharacterCore(p.Character)
                    local myCore = getCharacterCore(game.Players.LocalPlayer.Character)
                    if core and myCore then
                        local bb = core:FindFirstChild("UniversalBillboard")
                        if bb and bb:FindFirstChild("TextLabel") then
                            local distance = math.floor((myCore.Position - core.Position).Magnitude)
                            bb.TextLabel.Text = string.format("%s [%d studs]", p.DisplayName or p.Name, distance)
                        end
                    end
                end
            end
        end
    end
end)

-- ==========================================
-- ИНТЕРФЕЙС УПРАВЛЕНИЯ (КНОПКИ В МЕНЮ)
-- ==========================================

-- Переключатель 1: Силуэты сквозь стены
VisualsTab:CreateToggle({
   Name = "Красивая подсветка силуэта (Neon Wallhack)",
   CurrentValue = false,
   Callback = function(Value)
       Settings.WallhackEnabled = Value
       if Value then
           for _, p in ipairs(game.Players:GetPlayers()) do
               if p.Character then refreshVisualsForCharacter(p.Character) end
           end
       else
           for _, p in ipairs(game.Players:GetPlayers()) do
               if p.Character then
                   local hl = p.Character:FindFirstChild("UniversalHighlight")
                   if hl then hl:Destroy() end
               end
           end
       end
   end,
})

-- Переключатель 2: Ники и Дистанция над головой
VisualsTab:CreateToggle({
   Name = "Отображать Ники и Дистанцию",
   CurrentValue = false,
   Callback = function(Value)
       Settings.BoxesEnabled = Value
       if Value then
           for _, p in ipairs(game.Players:GetPlayers()) do
               if p.Character then refreshVisualsForCharacter(p.Character) end
           end
       else
           for _, p in ipairs(game.Players:GetPlayers()) do
               if p.Character then
                   local core = getCharacterCore(p.Character)
                   if core then
                       local bb = core:FindFirstChild("UniversalBillboard")
                       if bb then bb:Destroy() end
                   end
               end
           end
       end
   end,
})

-- Подключение слежения за новыми игроками
game.Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(refreshVisualsForCharacter)
end)

for _, player in ipairs(game.Players:GetPlayers()) do
    player.CharacterAdded:Connect(refreshVisualsForCharacter)
end

-- Уведомление
Rayfield:Notify({
   Title = "Визуалы Активны",
   Content = "Универсальный модуль успешно запущен.",
   Duration = 4,
   Image = 4483345998,
})
