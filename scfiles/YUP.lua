local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")
local SoundService = game:GetService("SoundService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local Obsidian = loadstring(game:HttpGet("https://raw.githubusercontent.com/deividcomsono/Obsidian/refs/heads/main/obsidian.lua"))()

local CONFIG = {
    FONT_URL = "https://www.netfontes.com.br/dow.php?cod=yellow_submarine",
    VOLUME = 0.8,
    LYRICS_DURATION = 4.5,
    PARTICLE_COUNT = 120,
    MAX_VISIBLE_LYRICS = 3,
    EQ_BARS = 32,
    EQ_ENABLED = true,
    PARTICLES_ENABLED = true,
    DEFAULT_MUSIC = {
        URL = "https://github.com/Msdoors/Msdoors.gg/raw/refs/heads/main/Scripts/Msdoors/INIT_SOUND.mp3",
        TITLE = "WASTED (NIGHTCORE)",
        ARTIST = "JUICE WRLD, LilStoic",
        IMAGE = "https://raw.githubusercontent.com/RhyanXG7/host-de-imagens/refs/heads/BetterStar/imagens-Host/download.jpeg"
    }
}

local currentMusicData = CONFIG.DEFAULT_MUSIC
local fontLoaded = false
local localMusicList = {}

print("🎵 Inicializando Ultimate Music Player...")

local function LoadCustomFont()
    if not fontLoaded then
        local fontSuccess, fontData = pcall(function()
            return game:HttpGet(CONFIG.FONT_URL)
        end)
        if fontSuccess then
            writefile("yellow_submarine_font.ttf", fontData)
            fontLoaded = true
            print("✅ Fonte personalizada carregada!")
        else
            print("⚠️ Falha ao carregar fonte personalizada")
        end
    end
end

local function DownloadAsset(url, fileName, fileType)
    local success, data = pcall(function()
        return game:HttpGet(url)
    end)
    if success then
        writefile(fileName, data)
        return (getcustomasset or getsynasset)(fileName)
    end
    warn("Falha ao baixar: " .. url)
    return nil
end

local function ScanLocalMusic()
    print("🔍 Escaneando músicas locais...")
    localMusicList = {}
    
    local musicsFolderExists = pcall(function()
        return isfolder("musics")
    end)
    
    if not musicsFolderExists then
        makefolder("musics")
        print("📁 Pasta 'musics' criada!")
        return {}
    end
    
    local folders = listfiles("musics")
    for _, folderPath in pairs(folders) do
        local folderName = folderPath:match("musics[\\/](.+)")
        if folderName and isfolder(folderPath) then
            local hasAudio = isfile(folderPath .. "/audio.mp3")
            local hasLyrics = isfile(folderPath .. "/letras.txt")
            local hasImage = isfile(folderPath .. "/capa.png")
            local hasInfo = isfile(folderPath .. "/infos.json")
            
            if hasAudio then
                local musicInfo = {
                    name = folderName,
                    path = folderPath,
                    hasLyrics = hasLyrics,
                    hasImage = hasImage,
                    hasInfo = hasInfo
                }
                
                if hasInfo then
                    local infoContent = readfile(folderPath .. "/infos.json")
                    local success, info = pcall(function()
                        return HttpService:JSONDecode(infoContent)
                    end)
                    if success then
                        musicInfo.title = info.title or folderName
                        musicInfo.artist = info.artist or "Artista Desconhecido"
                        musicInfo.colors = info.colors or {}
                    end
                end
                
                table.insert(localMusicList, musicInfo)
                print("🎵 Encontrada: " .. folderName)
            end
        end
    end
    
    print("📊 Total de músicas locais encontradas: " .. #localMusicList)
    return localMusicList
end

local function ParseLyrics(content)
    if not content then
        return {{time = 0, text = "♪ Música sem letras disponíveis ♪", endTime = 999}}
    end
    
    local parsedLyrics = {}
    for line in content:gmatch("[^\r\n]+") do
        if line:match("%S") then
            local timePattern = "%[(%d+):(%d+)%.(%d+)%](.+)"
            local minutes, seconds, centiseconds, text = line:match(timePattern)
            
            if minutes and seconds and centiseconds and text then
                local totalTime = tonumber(minutes) * 60 + tonumber(seconds) + tonumber(centiseconds) / 100
                local cleanText = text:gsub("^%s*(.-)%s*$", "%1")
                if cleanText ~= "" then
                    table.insert(parsedLyrics, {
                        time = totalTime,
                        text = cleanText,
                        endTime = totalTime + CONFIG.LYRICS_DURATION
                    })
                end
            end
        end
    end
    
    if #parsedLyrics == 0 then
        return {{time = 0, text = "♪ Música sem letras disponíveis ♪", endTime = 999}}
    end
    
    table.sort(parsedLyrics, function(a, b) return a.time < b.time end)
    return parsedLyrics
end

local function CreateProtectedGUI()
    for _, gui in pairs(CoreGui:GetChildren()) do
        if gui.Name == "UltimateMusicPlayer" then
            gui:Destroy()
        end
    end
    
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "UltimateMusicPlayer"
    screenGui.ResetOnSpawn = false
    screenGui.IgnoreGuiInset = true
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    pcall(function()
        screenGui.Parent = CoreGui
    end)
    
    if not screenGui.Parent then
        screenGui.Parent = player:WaitForChild("PlayerGui")
    end
    
    return screenGui
end

local function CreateLyricsDisplay(parent)
    local lyricsFrame = Instance.new("Frame")
    lyricsFrame.Name = "LyricsDisplay"
    lyricsFrame.Size = UDim2.new(1, 0, 1, 0)
    lyricsFrame.Position = UDim2.new(0, 0, 0, 0)
    lyricsFrame.BackgroundTransparency = 1
    lyricsFrame.Parent = parent
    
    return lyricsFrame
end

local function CreateEqualizer(parent)
    if not CONFIG.EQ_ENABLED then return nil, {} end
    
    local eqFrame = Instance.new("Frame")
    eqFrame.Name = "Equalizer"
    eqFrame.Size = UDim2.new(0, 200, 1, 0)
    eqFrame.Position = UDim2.new(1, 200, 0, 0)
    eqFrame.BackgroundTransparency = 1
    eqFrame.BorderSizePixel = 0
    eqFrame.Parent = parent
    
    local bars = {}
    local barWidth = 180 / CONFIG.EQ_BARS
    local screenHeight = workspace.CurrentCamera.ViewportSize.Y
    
    for i = 1, CONFIG.EQ_BARS do
        local bar = Instance.new("Frame")
        bar.Name = "Bar" .. i
        bar.Size = UDim2.new(0, barWidth - 1, 0, 8)
        bar.Position = UDim2.new(0, (i-1) * barWidth + 10, 0.5, -4)
        bar.BackgroundColor3 = Color3.fromHSV((i-1) / CONFIG.EQ_BARS * 0.9, 0.8, 0.9)
        bar.BorderSizePixel = 0
        bar.Parent = eqFrame
        
        local barCorner = Instance.new("UICorner")
        barCorner.CornerRadius = UDim.new(0, 2)
        barCorner.Parent = bar
        
        local glow = Instance.new("UIStroke")
        glow.Color = bar.BackgroundColor3
        glow.Thickness = 1
        glow.Transparency = 0.5
        glow.Parent = bar
        
        table.insert(bars, {frame = bar, glow = glow, baseHeight = 8})
    end
    
    local slideInTween = TweenService:Create(eqFrame,
        TweenInfo.new(1.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Position = UDim2.new(1, -200, 0, 0)}
    )
    slideInTween:Play()
    
    return eqFrame, bars
end

local function CreateMusicSelector(parent)
    local selectorFrame = Instance.new("Frame")
    selectorFrame.Name = "MusicSelector"
    selectorFrame.Size = UDim2.new(0, 300, 0, 80)
    selectorFrame.Position = UDim2.new(0, 30, 0, 30)
    selectorFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
    selectorFrame.BorderSizePixel = 0
    selectorFrame.Parent = parent
    
    local selectorCorner = Instance.new("UICorner")
    selectorCorner.CornerRadius = UDim.new(0, 12)
    selectorCorner.Parent = selectorFrame
    
    local selectorGlow = Instance.new("UIStroke")
    selectorGlow.Color = Color3.fromRGB(100, 150, 255)
    selectorGlow.Thickness = 2
    selectorGlow.Transparency = 0.4
    selectorGlow.Parent = selectorFrame
    
    local dropdownBtn = Instance.new("TextButton")
    dropdownBtn.Name = "DropdownButton"
    dropdownBtn.Size = UDim2.new(0, 180, 0, 35)
    dropdownBtn.Position = UDim2.new(0, 10, 0, 10)
    dropdownBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 40)
    dropdownBtn.Text = "Selecionar Música Local ▼"
    dropdownBtn.TextColor3 = Color3.new(1, 1, 1)
    dropdownBtn.TextScaled = true
    dropdownBtn.Font = Enum.Font.JosefinSans
    dropdownBtn.BorderSizePixel = 0
    dropdownBtn.Parent = selectorFrame
    
    local dropCorner = Instance.new("UICorner")
    dropCorner.CornerRadius = UDim.new(0, 8)
    dropCorner.Parent = dropdownBtn
    
    local loadBtn = Instance.new("TextButton")
    loadBtn.Name = "LoadButton"
    loadBtn.Size = UDim2.new(0, 80, 0, 35)
    loadBtn.Position = UDim2.new(0, 200, 0, 10)
    loadBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 100)
    loadBtn.Text = "Carregar"
    loadBtn.TextColor3 = Color3.new(1, 1, 1)
    loadBtn.TextScaled = true
    loadBtn.Font = Enum.Font.JosefinSans
    loadBtn.BorderSizePixel = 0
    loadBtn.Parent = selectorFrame
    
    local loadCorner = Instance.new("UICorner")
    loadCorner.CornerRadius = UDim.new(0, 8)
    loadCorner.Parent = loadBtn
    
    local refreshBtn = Instance.new("TextButton")
    refreshBtn.Name = "RefreshButton"
    refreshBtn.Size = UDim2.new(0, 280, 0, 25)
    refreshBtn.Position = UDim2.new(0, 10, 0, 50)
    refreshBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 80)
    refreshBtn.Text = "🔄 Atualizar Lista"
    refreshBtn.TextColor3 = Color3.new(1, 1, 1)
    refreshBtn.TextScaled = true
    refreshBtn.Font = Enum.Font.JosefinSans
    refreshBtn.BorderSizePixel = 0
    refreshBtn.Parent = selectorFrame
    
    local refreshCorner = Instance.new("UICorner")
    refreshCorner.CornerRadius = UDim.new(0, 6)
    refreshCorner.Parent = refreshBtn
    
    local dropdownMenu = Instance.new("ScrollingFrame")
    dropdownMenu.Name = "DropdownMenu"
    dropdownMenu.Size = UDim2.new(0, 180, 0, 0)
    dropdownMenu.Position = UDim2.new(0, 10, 0, 45)
    dropdownMenu.BackgroundColor3 = Color3.fromRGB(20, 20, 35)
    dropdownMenu.BorderSizePixel = 0
    dropdownMenu.Visible = false
    dropdownMenu.ScrollBarThickness = 4
    dropdownMenu.Parent = selectorFrame
    
    local menuCorner = Instance.new("UICorner")
    menuCorner.CornerRadius = UDim.new(0, 6)
    menuCorner.Parent = dropdownMenu
    
    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.Name
    layout.Parent = dropdownMenu
    
    local selectedMusic = nil
    
    local function UpdateDropdown()
        for _, child in pairs(dropdownMenu:GetChildren()) do
            if child:IsA("TextButton") then
                child:Destroy()
            end
        end
        
        for i, music in pairs(localMusicList) do
            local option = Instance.new("TextButton")
            option.Name = "Option" .. i
            option.Size = UDim2.new(1, -8, 0, 30)
            option.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
            option.Text = music.title or music.name
            option.TextColor3 = Color3.new(1, 1, 1)
            option.TextScaled = true
            option.Font = Enum.Font.JosefinSans
            option.BorderSizePixel = 0
            option.Parent = dropdownMenu
            
            local optCorner = Instance.new("UICorner")
            optCorner.CornerRadius = UDim.new(0, 4)
            optCorner.Parent = option
            
            option.MouseButton1Click:Connect(function()
                selectedMusic = music
                dropdownBtn.Text = music.title or music.name
                dropdownMenu.Visible = false
                dropdownMenu.Size = UDim2.new(0, 180, 0, 0)
            end)
            
            option.MouseEnter:Connect(function()
                option.BackgroundColor3 = Color3.fromRGB(50, 50, 80)
            end)
            
            option.MouseLeave:Connect(function()
                option.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
            end)
        end
        
        dropdownMenu.CanvasSize = UDim2.new(0, 0, 0, #localMusicList * 30)
    end
    
    dropdownBtn.MouseButton1Click:Connect(function()
        dropdownMenu.Visible = not dropdownMenu.Visible
        if dropdownMenu.Visible then
            dropdownMenu.Size = UDim2.new(0, 180, 0, math.min(150, #localMusicList * 30))
            dropdownBtn.Text = "Fechar Lista ▲"
        else
            dropdownMenu.Size = UDim2.new(0, 180, 0, 0)
            dropdownBtn.Text = "Selecionar Música Local ▼"
        end
    end)
    
    refreshBtn.MouseButton1Click:Connect(function()
        ScanLocalMusic()
        UpdateDropdown()
        print("🔄 Lista de músicas atualizada!")
    end)
    
    return selectorFrame, loadBtn, selectedMusic, UpdateDropdown
end

local function CreateModernUI(parent)
    local mainContainer = Instance.new("Frame")
    mainContainer.Name = "MainContainer"
    mainContainer.Size = UDim2.new(0, 500, 0, 220)
    mainContainer.Position = UDim2.new(0, 30, 1, -260)
    mainContainer.BackgroundColor3 = Color3.fromRGB(8, 8, 15)
    mainContainer.BackgroundTransparency = 0.05
    mainContainer.BorderSizePixel = 0
    mainContainer.Parent = parent
    
    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 20)
    mainCorner.Parent = mainContainer
    
    local glowEffect = Instance.new("UIStroke")
    glowEffect.Color = Color3.fromRGB(120, 0, 255)
    glowEffect.Thickness = 3
    glowEffect.Transparency = 0.3
    glowEffect.Parent = mainContainer
    
    local gradientBg = Instance.new("UIGradient")
    gradientBg.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(25, 25, 45)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(15, 15, 30)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(35, 25, 55))
    }
    gradientBg.Rotation = 135
    gradientBg.Parent = mainContainer
    
    local albumArt = Instance.new("ImageLabel")
    albumArt.Name = "AlbumArt"
    albumArt.Size = UDim2.new(0, 160, 0, 160)
    albumArt.Position = UDim2.new(0, 20, 0.5, -80)
    albumArt.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
    albumArt.BorderSizePixel = 0
    albumArt.ScaleType = Enum.ScaleType.Crop
    albumArt.Parent = mainContainer
    
    local artCorner = Instance.new("UICorner")
    artCorner.CornerRadius = UDim.new(0, 15)
    artCorner.Parent = albumArt
    
    local artGlow = Instance.new("UIStroke")
    artGlow.Color = Color3.fromRGB(255, 100, 200)
    artGlow.Thickness = 3
    artGlow.Transparency = 0.4
    artGlow.Parent = albumArt
    
    local infoContainer = Instance.new("Frame")
    infoContainer.Name = "InfoContainer"
    infoContainer.Size = UDim2.new(0, 300, 0, 160)
    infoContainer.Position = UDim2.new(0, 190, 0.5, -80)
    infoContainer.BackgroundTransparency = 1
    infoContainer.Parent = mainContainer
    
    local songTitle = Instance.new("TextLabel")
    songTitle.Name = "SongTitle"
    songTitle.Size = UDim2.new(1, 0, 0, 40)
    songTitle.Position = UDim2.new(0, 0, 0, 10)
    songTitle.BackgroundTransparency = 1
    songTitle.Text = currentMusicData.TITLE or "Música Desconhecida"
    songTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    songTitle.TextScaled = true
    songTitle.Font = fontLoaded and Enum.Font.SpecialElite or Enum.Font.GothamBold
    songTitle.TextXAlignment = Enum.TextXAlignment.Left
    songTitle.Parent = infoContainer
    
    local artistLabel = Instance.new("TextLabel")
    artistLabel.Name = "ArtistLabel"
    artistLabel.Size = UDim2.new(1, 0, 0, 25)
    artistLabel.Position = UDim2.new(0, 0, 0, 55)
    artistLabel.BackgroundTransparency = 1
    artistLabel.Text = "🎤 " .. (currentMusicData.ARTIST or "Artista Desconhecido")
    artistLabel.TextColor3 = Color3.fromRGB(180, 180, 220)
    artistLabel.TextScaled = true
    artistLabel.Font = fontLoaded and Enum.Font.SpecialElite or Enum.Font.JosefinSans
    artistLabel.TextXAlignment = Enum.TextXAlignment.Left
    artistLabel.Parent = infoContainer
    
    local progressBg = Instance.new("Frame")
    progressBg.Name = "ProgressBackground"
    progressBg.Size = UDim2.new(0.75, 0, 0, 8)
    progressBg.Position = UDim2.new(0, 0, 0, 90)
    progressBg.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
    progressBg.BorderSizePixel = 0
    progressBg.Parent = infoContainer
    
    local progBgCorner = Instance.new("UICorner")
    progBgCorner.CornerRadius = UDim.new(0, 4)
    progBgCorner.Parent = progressBg
    
    local progressBar = Instance.new("Frame")
    progressBar.Name = "ProgressBar"
    progressBar.Size = UDim2.new(0, 0, 1, 0)
    progressBar.Position = UDim2.new(0, 0, 0, 0)
    progressBar.BorderSizePixel = 0
    progressBar.Parent = progressBg
    
    local progGradient = Instance.new("UIGradient")
    progGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 50, 150)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(100, 200, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 100, 255))
    }
    progGradient.Parent = progressBar
    
    local progCorner = Instance.new("UICorner")
    progCorner.CornerRadius = UDim.new(0, 4)
    progCorner.Parent = progressBar
    
    local timeDisplay = Instance.new("TextLabel")
    timeDisplay.Name = "TimeDisplay"
    timeDisplay.Size = UDim2.new(0.25, 0, 0, 25)
    timeDisplay.Position = UDim2.new(0.75, 5, 0, 80)
    timeDisplay.BackgroundTransparency = 1
    timeDisplay.Text = "00:00"
    timeDisplay.TextColor3 = Color3.fromRGB(150, 150, 180)
    timeDisplay.TextScaled = true
    timeDisplay.Font = fontLoaded and Enum.Font.SpecialElite or Enum.Font.JosefinSans
    timeDisplay.TextXAlignment = Enum.TextXAlignment.Right
    timeDisplay.Parent = infoContainer
    
    local controlsFrame = Instance.new("Frame")
    controlsFrame.Name = "Controls"
    controlsFrame.Size = UDim2.new(1, 0, 0, 35)
    controlsFrame.Position = UDim2.new(0, 0, 0, 115)
    controlsFrame.BackgroundTransparency = 1
    controlsFrame.Parent = infoContainer
    
    local playBtn = Instance.new("TextButton")
    playBtn.Name = "PlayButton"
    playBtn.Size = UDim2.new(0, 45, 0, 35)
    playBtn.Position = UDim2.new(0, 0, 0, 0)
    playBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 100)
    playBtn.Text = "▶"
    playBtn.TextColor3 = Color3.new(1, 1, 1)
    playBtn.TextScaled = true
    playBtn.Font = fontLoaded and Enum.Font.SpecialElite or Enum.Font.JosefinSans
    playBtn.BorderSizePixel = 0
    playBtn.Parent = controlsFrame
    
    local playCorner = Instance.new("UICorner")
    playCorner.CornerRadius = UDim.new(0, 8)
    playCorner.Parent = playBtn
    
    local stopBtn = Instance.new("TextButton")
    stopBtn.Name = "StopButton"
    stopBtn.Size = UDim2.new(0, 40, 0, 35)
    stopBtn.Position = UDim2.new(0, 55, 0, 0)
    stopBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    stopBtn.Text = "■"
    stopBtn.TextColor3 = Color3.new(1, 1, 1)
    stopBtn.TextScaled = true
    stopBtn.Font = fontLoaded and Enum.Font.SpecialElite or Enum.Font.JosefinSans
    stopBtn.BorderSizePixel = 0
    stopBtn.Parent = controlsFrame
    
    local stopCorner = Instance.new("UICorner")
    stopCorner.CornerRadius = UDim.new(0, 8)
    stopCorner.Parent = stopBtn
    
    local hideBtn = Instance.new("TextButton")
    hideBtn.Name = "HideButton"
    hideBtn.Size = UDim2.new(0, 40, 0, 35)
    hideBtn.Position = UDim2.new(0, 105, 0, 0)
    hideBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 140)
    hideBtn.Text = "−"
    hideBtn.TextColor3 = Color3.new(1, 1, 1)
    hideBtn.TextScaled = true
    hideBtn.Font = fontLoaded and Enum.Font.SpecialElite or Enum.Font.JosefinSans
    hideBtn.BorderSizePixel = 0
    hideBtn.Parent = controlsFrame
    
    local hideCorner = Instance.new("UICorner")
    hideCorner.CornerRadius = UDim.new(0, 8)
    hideCorner.Parent = hideBtn
    
    local eqToggleBtn = Instance.new("TextButton")
    eqToggleBtn.Name = "EQToggleButton"
    eqToggleBtn.Size = UDim2.new(0, 40, 0, 35)
    eqToggleBtn.Position = UDim2.new(0, 155, 0, 0)
    eqToggleBtn.BackgroundColor3 = CONFIG.EQ_ENABLED and Color3.fromRGB(0, 150, 255) or Color3.fromRGB(80, 80, 80)
    eqToggleBtn.Text = "♫"
    eqToggleBtn.TextColor3 = Color3.new(1, 1, 1)
    eqToggleBtn.TextScaled = true
    eqToggleBtn.Font = fontLoaded and Enum.Font.SpecialElite or Enum.Font.JosefinSans
    eqToggleBtn.BorderSizePixel = 0
    eqToggleBtn.Parent = controlsFrame
    
    local eqToggleCorner = Instance.new("UICorner")
    eqToggleCorner.CornerRadius = UDim.new(0, 8)
    eqToggleCorner.Parent = eqToggleBtn
    
    local particleToggleBtn = Instance.new("TextButton")
    particleToggleBtn.Name = "ParticleToggleButton"
    particleToggleBtn.Size = UDim2.new(0, 40, 0, 35)
    particleToggleBtn.Position = UDim2.new(0, 205, 0, 0)
    particleToggleBtn.BackgroundColor3 = CONFIG.PARTICLES_ENABLED and Color3.fromRGB(255, 150, 0) or Color3.fromRGB(80, 80, 80)
    particleToggleBtn.Text = "✦"
    particleToggleBtn.TextColor3 = Color3.new(1, 1, 1)
    particleToggleBtn.TextScaled = true
    particleToggleBtn.Font = fontLoaded and Enum.Font.SpecialElite or Enum.Font.JosefinSans
    particleToggleBtn.BorderSizePixel = 0
    particleToggleBtn.Parent = controlsFrame
    
    local particleToggleCorner = Instance.new("UICorner")
    particleToggleCorner.CornerRadius = UDim.new(0, 8)
    particleToggleCorner.Parent = particleToggleBtn
    
    return mainContainer, albumArt, songTitle, artistLabel, progressBar, timeDisplay, playBtn, stopBtn, hideBtn, eqToggleBtn, particleToggleBtn
end

local lyricEffects = {
    "typewriter", "fade", "scale", "bounce", "spin", "glow", "wave", "slide", "rainbow", "pulse"
}

local function GetRandomPosition()
    local viewportSize = workspace.CurrentCamera.ViewportSize
    local margin = 120
    
    local x = math.random(margin, viewportSize.X - margin - 450) / viewportSize.X
    local y = math.random(margin, viewportSize.Y - margin - 100) / viewportSize.Y
    
    return UDim2.new(x, 0, y, 0)
end

local function CreateLyricElement(text, container, intensity, isActive)
    local lyricContainer = Instance.new("Frame")
    lyricContainer.Name = "LyricContainer_" .. tostring(math.random(1000, 9999))
    lyricContainer.Size = UDim2.new(0, 450, 0, 90)
    lyricContainer.Position = GetRandomPosition()
    lyricContainer.BackgroundTransparency = 1
    lyricContainer.Parent = container
    
    local lyric = Instance.new("TextLabel")
    lyric.Name = "Lyric"
    lyric.Size = UDim2.new(1, 0, 1, 0)
    lyric.BackgroundTransparency = 1
    lyric.Text = text
    lyric.TextScaled = true
    lyric.Font = fontLoaded and Enum.Font.SpecialElite or Enum.Font.GothamBold
    lyric.TextStrokeTransparency = 0.1
    lyric.TextStrokeColor3 = Color3.new(0, 0, 0)
    lyric.Parent = lyricContainer
    
    local underline = Instance.new("Frame")
    underline.Name = "Underline"
    underline.Size = UDim2.new(0, 0, 0, 5)
    underline.Position = UDim2.new(0, 0, 0.88, 0)
    underline.BorderSizePixel = 0
    underline.Parent = lyricContainer
    
    local underCorner = Instance.new("UICorner")
    underCorner.CornerRadius = UDim.new(0, 3)
    underCorner.Parent = underline
    
    local hue = (tick() * 0.4 + math.random()) % 1
    local mainColor = Color3.fromHSV(hue, 0.95, intensity)
    lyric.TextColor3 = mainColor
    underline.BackgroundColor3 = mainColor
    
    local glow = Instance.new("UIStroke")
    glow.Color = Color3.fromHSV(hue, 1, intensity)
    glow.Thickness = math.floor(intensity * 8)
    glow.Transparency = 0.2
    glow.Parent = lyric
    
    local effect = lyricEffects[math.random(1, #lyricEffects)]
    
    if effect == "typewriter" then
        lyric.Text = ""
        local fullText = text
        spawn(function()
            for i = 1, #fullText do
                lyric.Text = fullText:sub(1, i)
                wait(0.025)
            end
        end)
    elseif effect == "fade" then
        lyric.TextTransparency = 1
        local fadeTween = TweenService:Create(lyric,
            TweenInfo.new(1.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
            {TextTransparency = 0}
        )
        fadeTween:Play()
    elseif effect == "scale" then
        lyricContainer.Size = UDim2.new(0, 0, 0, 90)
        local scaleTween = TweenService:Create(lyricContainer,
            TweenInfo.new(0.9, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out),
            {Size = UDim2.new(0, 450, 0, 90)}
        )
        scaleTween:Play()
    elseif effect == "bounce" then
        local originalPos = lyricContainer.Position
        lyricContainer.Position = UDim2.new(originalPos.X.Scale, originalPos.X.Offset, -0.2, originalPos.Y.Offset)
        local bounceTween = TweenService:Create(lyricContainer,
            TweenInfo.new(0.8, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out),
            {Position = originalPos}
        )
        bounceTween:Play()
    elseif effect == "spin" then
        lyric.Rotation = -360
        local spinTween = TweenService:Create(lyric,
            TweenInfo.new(1.5, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out),
            {Rotation = 0}
        )
        spinTween:Play()
    elseif effect == "glow" then
        glow.Thickness = 0
        local glowTween = TweenService:Create(glow,
            TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
            {Thickness = intensity * 12}
        )
        glowTween:Play()
    elseif effect == "wave" then
        spawn(function()
            for i = 1, 15 do
                lyric.Position = UDim2.new(0, math.sin(i * 0.8) * 8, 0, math.cos(i * 0.6) * 3)
                wait(0.08)
            end
            lyric.Position = UDim2.new(0, 0, 0, 0)
        end)
    elseif effect == "slide" then
        local originalPos = lyricContainer.Position
        lyricContainer.Position = UDim2.new(-0.6, 0, originalPos.Y.Scale, originalPos.Y.Offset)
        local slideTween = TweenService:Create(lyricContainer,
            TweenInfo.new(1.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
            {Position = originalPos}
        )
        slideTween:Play()
    elseif effect == "rainbow" then
        spawn(function()
            for i = 1, 30 do
                local rainbowHue = (i * 0.1) % 1
                lyric.TextColor3 = Color3.fromHSV(rainbowHue, 0.9, 0.95)
                glow.Color = Color3.fromHSV(rainbowHue, 1, 1)
                wait(0.1)
            end
        end)
    elseif effect == "pulse" then
        spawn(function()
            for i = 1, 8 do
                local scale = 1 + math.sin(i) * 0.2
                lyric.Size = UDim2.new(scale, 0, scale, 0)
                lyric.Position = UDim2.new((1-scale)/2, 0, (1-scale)/2, 0)
                wait(0.15)
            end
            lyric.Size = UDim2.new(1, 0, 1, 0)
            lyric.Position = UDim2.new(0, 0, 0, 0)
        end)
    end
    
    if isActive then
        local underlineTween = TweenService:Create(underline,
            TweenInfo.new(2, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out),
            {Size = UDim2.new(1, 0, 0, 5)}
        )
        underlineTween:Play()
        
        spawn(function()
            for i = 1, 20 do
                local pulseIntensity = 1 + math.sin(i * 0.5) * 0.3
                glow.Thickness = intensity * 10 * pulseIntensity
                wait(0.2)
            end
        end)
    end
    
    return lyricContainer, lyric, underline
end

local function CreateParticleSystem(parent)
    if not CONFIG.PARTICLES_ENABLED then return {}, nil end
    
    local particleContainer = Instance.new("Frame")
    particleContainer.Name = "ParticleSystem"
    particleContainer.Size = UDim2.new(1, 0, 1, 0)
    particleContainer.BackgroundTransparency = 1
    particleContainer.Parent = parent
    
    local particles = {}
    
    for i = 1, CONFIG.PARTICLE_COUNT do
        local particle = Instance.new("Frame")
        particle.Size = UDim2.new(0, math.random(3, 8), 0, math.random(3, 8))
        particle.Position = UDim2.new(math.random(), 0, math.random(), 0)
        particle.BackgroundColor3 = Color3.fromHSV(math.random(), 0.9, 1)
        particle.BorderSizePixel = 0
        particle.BackgroundTransparency = math.random(0.2, 0.7)
        particle.Parent = particleContainer
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(1, 0)
        corner.Parent = particle
        
        local particleGlow = Instance.new("UIStroke")
        particleGlow.Color = particle.BackgroundColor3
        particleGlow.Thickness = 1
        particleGlow.Transparency = 0.6
        particleGlow.Parent = particle
        
        table.insert(particles, {
            frame = particle,
            glow = particleGlow,
            velX = (math.random() - 0.5) * 0.003,
            velY = (math.random() - 0.5) * 0.003,
            life = math.random(200, 500),
            maxLife = math.random(200, 500),
            rotSpeed = (math.random() - 0.5) * 5
        })
    end
    
    return particles, particleContainer
end

local function CreateMusicPlayer()
    print("🎨 Carregando fonte personalizada...")
    LoadCustomFont()
    
    print("📁 Escaneando músicas locais...")
    ScanLocalMusic()
    
    print("🖼️ Criando interface...")
    local gui = CreateProtectedGUI()
    local lyricsDisplay = CreateLyricsDisplay(gui)
    local musicSelector, loadBtn, selectedMusic, updateDropdown = CreateMusicSelector(gui)
    local uiContainer, albumArt, songTitle, artistLabel, progressBar, timeDisplay, playBtn, stopBtn, hideBtn, eqToggleBtn, particleToggleBtn = CreateModernUI(gui)
    local eqFrame, eqBars = CreateEqualizer(gui)
    local particles, particleContainer = CreateParticleSystem(gui)
    
    updateDropdown()
    
    local currentSound = nil
    local currentLyrics = {}
    local isPlaying = false
    local isHidden = false
    local activeLyrics = {}
    local connections = {}
    local cleanupTasks = {}
    local eqEnabled = CONFIG.EQ_ENABLED
    local particlesEnabled = CONFIG.PARTICLES_ENABLED
    
    print("🎵 Carregando música padrão...")
    if currentMusicData.IMAGE then
        local imageId = DownloadAsset(currentMusicData.IMAGE, "default_cover.jpg", "image")
        if imageId then
            albumArt.Image = imageId
        end
    end
    
    local function FormatTime(seconds)
        local mins = math.floor(seconds / 60)
        local secs = math.floor(seconds % 60)
        return string.format("%02d:%02d", mins, secs)
    end
    
    local function CleanupLyrics()
        for _, lyricData in ipairs(activeLyrics) do
            if lyricData.container and lyricData.container.Parent then
                lyricData.container:Destroy()
            end
        end
        activeLyrics = {}
        
        for _, task in ipairs(cleanupTasks) do
            if task then task:Disconnect() end
        end
        cleanupTasks = {}
    end
    
    local function UpdateEqualizer(volume, frequency)
        if not eqEnabled or not eqFrame.Visible then return end
        
        for i, barData in ipairs(eqBars) do
            local bar = barData.frame
            local glow = barData.glow
            
            local heightMultiplier = 1 + math.sin(tick() * (i * 0.5 + 2)) * 0.3
            local height = (math.random(10, 80) * (volume + 0.4) * heightMultiplier)
            local colorHue = ((i-1) / CONFIG.EQ_BARS * 0.9 + tick() * 0.1) % 1
            
            local tween = TweenService:Create(bar,
                TweenInfo.new(0.05, Enum.EasingStyle.Sine),
                {
                    Size = UDim2.new(0, bar.Size.X.Offset, 0, height),
                    BackgroundColor3 = Color3.fromHSV(colorHue, 0.8, 0.8 + volume * 0.2)
                }
            )
            tween:Play()
            
            glow.Color = Color3.fromHSV(colorHue, 1, 1)
            glow.Thickness = 1 + volume * 2
        end
    end
    
    local function UpdateParticles()
        if not particlesEnabled or not particleContainer.Visible then return end
        
        for i, particle in ipairs(particles) do
            if particle.frame.Parent then
                local pos = particle.frame.Position
                local newX = pos.X.Scale + particle.velX
                local newY = pos.Y.Scale + particle.velY
                
                if newX > 1 then 
                    newX = 0 
                    particle.frame.BackgroundColor3 = Color3.fromHSV(math.random(), 0.9, 1)
                    particle.glow.Color = particle.frame.BackgroundColor3
                elseif newX < 0 then 
                    newX = 1 
                    particle.frame.BackgroundColor3 = Color3.fromHSV(math.random(), 0.9, 1)
                    particle.glow.Color = particle.frame.BackgroundColor3
                end
                
                if newY > 1 then 
                    newY = 0 
                elseif newY < 0 then 
                    newY = 1 
                end
                
                particle.frame.Position = UDim2.new(newX, 0, newY, 0)
                particle.frame.Rotation = particle.frame.Rotation + particle.rotSpeed
                particle.life = particle.life - 1
                
                local alpha = particle.life / particle.maxLife
                particle.frame.BackgroundTransparency = 1 - (alpha * 0.8)
                particle.glow.Transparency = 0.4 + (1 - alpha) * 0.4
                
                if particle.life <= 0 then
                    particle.frame.BackgroundColor3 = Color3.fromHSV(math.random(), 0.9, 1)
                    particle.glow.Color = particle.frame.BackgroundColor3
                    particle.life = particle.maxLife
                    particle.frame.Position = UDim2.new(math.random(), 0, math.random(), 0)
                end
            end
        end
    end
    
    local function UpdateLyrics()
        if not isPlaying or not currentSound then return end
        
        local currentTime = currentSound.TimePosition
        local duration = currentSound.TimeLength or 1
        
        timeDisplay.Text = FormatTime(currentTime)
        
        local progress = math.min(currentTime / duration, 1)
        progressBar.Size = UDim2.new(progress, 0, 1, 0)
        
        local audioVolume = (currentSound.Volume or 0) + math.random() * 0.3
        UpdateEqualizer(audioVolume, currentTime)
        
        if #currentLyrics == 0 then return end
        
        local newActiveLyrics = {}
        local displayCount = 0
        
        for _, lyricData in ipairs(currentLyrics) do
            if currentTime >= lyricData.time and currentTime <= lyricData.endTime then
                displayCount = displayCount + 1
                if displayCount <= CONFIG.MAX_VISIBLE_LYRICS then
                    local intensity = displayCount == 1 and 1 or (0.7 - (displayCount - 1) * 0.1)
                    local isActive = displayCount == 1
                    
                    local existingLyric = nil
                    for _, existing in ipairs(activeLyrics) do
                        if existing.text == lyricData.text then
                            existingLyric = existing
                            break
                        end
                    end
                    
                    if not existingLyric then
                        local container, lyric, underline = CreateLyricElement(lyricData.text, lyricsDisplay, intensity, isActive)
                        table.insert(newActiveLyrics, {
                            container = container,
                            lyric = lyric,
                            underline = underline,
                            text = lyricData.text,
                            endTime = lyricData.endTime,
                            isActive = isActive,
                            created = tick()
                        })
                    else
                        table.insert(newActiveLyrics, existingLyric)
                    end
                end
            end
        end
        
        for _, oldLyric in ipairs(activeLyrics) do
            local stillActive = false
            for _, newLyric in ipairs(newActiveLyrics) do
                if oldLyric.text == newLyric.text then
                    stillActive = true
                    break
                end
            end
            
            if not stillActive and oldLyric.container.Parent then
                local fadeDirection = math.random(1, 4)
                local targetPos
                
                if fadeDirection == 1 then
                    targetPos = UDim2.new(-0.8, 0, oldLyric.container.Position.Y.Scale, 0)
                elseif fadeDirection == 2 then
                    targetPos = UDim2.new(1.2, 0, oldLyric.container.Position.Y.Scale, 0)
                elseif fadeDirection == 3 then
                    targetPos = UDim2.new(oldLyric.container.Position.X.Scale, 0, -0.3, 0)
                else
                    targetPos = UDim2.new(oldLyric.container.Position.X.Scale, 0, 1.2, 0)
                end
                
                local fadeOut = TweenService:Create(oldLyric.container,
                    TweenInfo.new(2, Enum.EasingStyle.Quint, Enum.EasingDirection.In),
                    {
                        Position = targetPos,
                        Size = UDim2.new(0, 0, 0, 90)
                    }
                )
                
                local transparencyTween = TweenService:Create(oldLyric.lyric,
                    TweenInfo.new(1.5, Enum.EasingStyle.Quad),
                    {TextTransparency = 1}
                )
                
                local rotateTween = TweenService:Create(oldLyric.lyric,
                    TweenInfo.new(2, Enum.EasingStyle.Quint),
                    {Rotation = math.random(-180, 180)}
                )
                
                fadeOut:Play()
                transparencyTween:Play()
                rotateTween:Play()
                
                local cleanup = fadeOut.Completed:Connect(function()
                    if oldLyric.container.Parent then
                        oldLyric.container:Destroy()
                    end
                end)
                table.insert(cleanupTasks, cleanup)
            end
        end
        
        activeLyrics = newActiveLyrics
    end
    
    local function LoadMusic(musicData, isLocal)
        print("🎵 Carregando música: " .. (musicData.title or musicData.name or "Música"))
        
        if currentSound then
            currentSound:Destroy()
            currentSound = nil
        end
        
        CleanupLyrics()
        isPlaying = false
        playBtn.Text = "▶"
        playBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 100)
        
        if isLocal then
            currentSound = Instance.new("Sound")
            currentSound.SoundId = (getcustomasset or getsynasset)(musicData.path .. "/audio.mp3")
            currentSound.Volume = CONFIG.VOLUME
            currentSound.Parent = workspace
            
            songTitle.Text = musicData.title or musicData.name
            artistLabel.Text = "🎤 " .. (musicData.artist or "Artista Desconhecido")
            
            if musicData.hasImage then
                albumArt.Image = (getcustomasset or getsynasset)(musicData.path .. "/capa.png")
            end
            
            if musicData.hasLyrics then
                local lyricsContent = readfile(musicData.path .. "/letras.txt")
                currentLyrics = ParseLyrics(lyricsContent)
            else
                currentLyrics = ParseLyrics(nil)
            end
            
            print("✅ Música local carregada!")
        else
            local soundId = DownloadAsset(musicData.URL, "current_song.mp3", "audio")
            if soundId then
                currentSound = Instance.new("Sound")
                currentSound.SoundId = soundId
                currentSound.Volume = CONFIG.VOLUME
                currentSound.Parent = workspace
                
                songTitle.Text = musicData.TITLE
                artistLabel.Text = "🎤 " .. musicData.ARTIST
                
                if musicData.IMAGE then
                    local imageId = DownloadAsset(musicData.IMAGE, "current_cover.jpg", "image")
                    if imageId then
                        albumArt.Image = imageId
                    end
                end
                
                currentLyrics = ParseLyrics(nil)
                print("✅ Música padrão carregada!")
            end
        end
        
        if currentSound then
            currentSound.Ended:Connect(function()
                isPlaying = false
                playBtn.Text = "▶"
                playBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 100)
                progressBar.Size = UDim2.new(0, 0, 1, 0)
                timeDisplay.Text = "00:00"
                CleanupLyrics()
                
                if eqEnabled then
                    for _, barData in ipairs(eqBars) do
                        local resetTween = TweenService:Create(barData.frame,
                            TweenInfo.new(0.8, Enum.EasingStyle.Quint),
                            {Size = UDim2.new(0, barData.frame.Size.X.Offset, 0, barData.baseHeight)}
                        )
                        resetTween:Play()
                    end
                end
            end)
        end
    end
    
    local function PlayMusic()
        if currentSound and currentSound.IsPlaying then
            return
        end
        
        if currentSound then
            currentSound:Play()
            isPlaying = true
            
            playBtn.Text = "⏸"
            playBtn.BackgroundColor3 = Color3.fromRGB(255, 140, 0)
            print("▶️ Reproduzindo música...")
        end
    end
    
    local function StopMusic()
        if currentSound then
            currentSound:Stop()
        end
        isPlaying = false
        playBtn.Text = "▶"
        playBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 100)
        progressBar.Size = UDim2.new(0, 0, 1, 0)
        timeDisplay.Text = "00:00"
        CleanupLyrics()
        
        if eqEnabled then
            for _, barData in ipairs(eqBars) do
                local resetTween = TweenService:Create(barData.frame,
                    TweenInfo.new(0.8, Enum.EasingStyle.Quint),
                    {Size = UDim2.new(0, barData.frame.Size.X.Offset, 0, barData.baseHeight)}
                )
                resetTween:Play()
            end
        end
        print("⏹️ Música parada.")
    end
    
    local function ToggleUI()
        isHidden = not isHidden
        local mainTargetPos = isHidden and UDim2.new(0, 30, 1, 50) or UDim2.new(0, 30, 1, -260)
        local selectorTargetPos = isHidden and UDim2.new(0, 30, 0, -90) or UDim2.new(0, 30, 0, 30)
        local targetText = isHidden and "+" or "−"
        
        hideBtn.Text = targetText
        
        local mainTween = TweenService:Create(uiContainer,
            TweenInfo.new(0.8, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
            {Position = mainTargetPos}
        )
        mainTween:Play()
        
        local selectorTween = TweenService:Create(musicSelector,
            TweenInfo.new(0.8, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
            {Position = selectorTargetPos}
        )
        selectorTween:Play()
        
        if eqEnabled then
            local eqTargetPos = isHidden and UDim2.new(1, 200, 0, 0) or UDim2.new(1, -200, 0, 0)
            local eqTween = TweenService:Create(eqFrame,
                TweenInfo.new(0.8, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
                {Position = eqTargetPos}
            )
            eqTween:Play()
        end
        
        if isHidden then
            local restoreBtn = Instance.new("TextButton")
            restoreBtn.Name = "RestoreButton"
            restoreBtn.Size = UDim2.new(0, 45, 0, 35)
            restoreBtn.Position = UDim2.new(0, 30, 1, -45)
            restoreBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 140)
            restoreBtn.Text = "+"
            restoreBtn.TextColor3 = Color3.new(1, 1, 1)
            restoreBtn.TextScaled = true
            restoreBtn.Font = fontLoaded and Enum.Font.SpecialElite or Enum.Font.JosefinSans
            restoreBtn.BorderSizePixel = 0
            restoreBtn.Parent = gui
            
            local restoreCorner = Instance.new("UICorner")
            restoreCorner.CornerRadius = UDim.new(0, 8)
            restoreCorner.Parent = restoreBtn
            
            local restoreGlow = Instance.new("UIStroke")
            restoreGlow.Color = Color3.fromRGB(150, 150, 200)
            restoreGlow.Thickness = 2
            restoreGlow.Transparency = 0.5
            restoreGlow.Parent = restoreBtn
            
            restoreBtn.MouseButton1Click:Connect(function()
                ToggleUI()
                restoreBtn:Destroy()
            end)
        end
    end
    
    local function ToggleEqualizer()
        eqEnabled = not eqEnabled
        CONFIG.EQ_ENABLED = eqEnabled
        eqFrame.Visible = eqEnabled
        
        eqToggleBtn.BackgroundColor3 = eqEnabled and Color3.fromRGB(0, 150, 255) or Color3.fromRGB(80, 80, 80)
        
        if eqEnabled then
            local slideInTween = TweenService:Create(eqFrame,
                TweenInfo.new(0.8, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
                {Position = UDim2.new(1, -200, 0, 0)}
            )
            slideInTween:Play()
        else
            local slideOutTween = TweenService:Create(eqFrame,
                TweenInfo.new(0.6, Enum.EasingStyle.Quint, Enum.EasingDirection.In),
                {Position = UDim2.new(1, 200, 0, 0)}
            )
            slideOutTween:Play()
            
            for _, barData in ipairs(eqBars) do
                local resetTween = TweenService:Create(barData.frame,
                    TweenInfo.new(0.5, Enum.EasingStyle.Quad),
                    {Size = UDim2.new(0, barData.frame.Size.X.Offset, 0, barData.baseHeight)}
                )
                resetTween:Play()
            end
        end
        
        print(eqEnabled and "🎚️ Equalizador ativado!" or "🎚️ Equalizador desativado!")
    end
    
    local function ToggleParticles()
        particlesEnabled = not particlesEnabled
        CONFIG.PARTICLES_ENABLED = particlesEnabled
        particleContainer.Visible = particlesEnabled
        
        particleToggleBtn.BackgroundColor3 = particlesEnabled and Color3.fromRGB(255, 150, 0) or Color3.fromRGB(80, 80, 80)
        
        print(particlesEnabled and "✨ Partículas ativadas!" or "✨ Partículas desativadas!")
    end
    
    playBtn.MouseButton1Click:Connect(function()
        if currentSound and currentSound.IsPlaying then
            currentSound:Pause()
            isPlaying = false
            playBtn.Text = "▶"
            playBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 100)
            print("⏸️ Música pausada.")
        elseif currentSound and not currentSound.IsPlaying then
            currentSound:Resume()
            isPlaying = true
            playBtn.Text = "⏸"
            playBtn.BackgroundColor3 = Color3.fromRGB(255, 140, 0)
            print("▶️ Música retomada.")
        else
            PlayMusic()
        end
    end)
    
    loadBtn.MouseButton1Click:Connect(function()
        local currentSelection = nil
        for _, music in pairs(localMusicList) do
            if songTitle.Text:find(music.title or music.name) or songTitle.Text:find(music.name) then
                currentSelection = music
                break
            end
        end
        
        if currentSelection then
            LoadMusic(currentSelection, true)
        else
            print("⚠️ Nenhuma música selecionada!")
        end
    end)
    
    stopBtn.MouseButton1Click:Connect(StopMusic)
    hideBtn.MouseButton1Click:Connect(ToggleUI)
    eqToggleBtn.MouseButton1Click:Connect(ToggleEqualizer)
    particleToggleBtn.MouseButton1Click:Connect(ToggleParticles)
    
    connections.particles = RunService.Heartbeat:Connect(UpdateParticles)
    connections.lyrics = RunService.Heartbeat:Connect(UpdateLyrics)
    
    local glowTween = TweenService:Create(glowEffect,
        TweenInfo.new(5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
        {Color = Color3.fromRGB(255, 100, 200)}
    )
    glowTween:Play()
    
    local artTween = TweenService:Create(artGlow,
        TweenInfo.new(4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
        {Color = Color3.fromRGB(100, 255, 200)}
    )
    artTween:Play()
    
    local selectorGlowTween = TweenService:Create(musicSelector:FindFirstChild("UIStroke"),
        TweenInfo.new(3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
        {Color = Color3.fromRGB(255, 150, 100)}
    )
    selectorGlowTween:Play()
    
    spawn(function()
        while gui.Parent do
            for i, barData in ipairs(eqBars) do
                if eqEnabled and not isPlaying then
                    local idleHeight = barData.baseHeight + math.sin(tick() * 2 + i) * 3
                    local idleTween = TweenService:Create(barData.frame,
                        TweenInfo.new(0.3, Enum.EasingStyle.Sine),
                        {Size = UDim2.new(0, barData.frame.Size.X.Offset, 0, idleHeight)}
                    )
                    idleTween:Play()
                end
            end
            wait(0.1)
        end
    end)
    
    if eqEnabled then
        eqFrame.Visible = true
    else
        eqFrame.Visible = false
    end
    
    if particlesEnabled then
        particleContainer.Visible = true
    else
        particleContainer.Visible = false
    end
    
    LoadMusic(CONFIG.DEFAULT_MUSIC, false)
    
    gui.AncestryChanged:Connect(function()
        if not gui.Parent then
            CleanupLyrics()
            for _, connection in pairs(connections) do
                if connection then connection:Disconnect() end
            end
            if currentSound then
                currentSound:Destroy()
            end
            print("🔌 Music Player desconectado.")
        end
    end)
    
    print("🎉 Ultimate Music Player carregado com sucesso!")
    print("📖 Instruções:")
    print("   • Use o dropdown para selecionar músicas locais")
    print("   • Clique em 'Atualizar Lista' para recarregar músicas")
    print("   • Organize suas músicas em: musics/{nome_da_musica}/")
    print("   • Arquivos necessários: audio.mp3, letras.txt, capa.png, infos.json")
    print("   • Use os controles para reproduzir, parar e configurar efeitos")
end

CreateMusicPlayer()