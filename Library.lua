--[[
    CLOCK KEY SYSTEM LIBRARY - ENGINE
    Template By Ɛ/Ɛ ʌʌʌʌ/CLOCK
]]

local CLOCK_LIBRARY = {}

function CLOCK_LIBRARY:CreateWindow(config)
    -- Konfigurasi Default & Validasi dari User
    local HubName = config.Name or "CLOCK HUB"
    local HubLogo = config.Logo or "rbxassetid://114917214257743"
    local DiscordLink = config.Discord or "https://discord.gg/your-link"
    local FolderName = config.Folder or "CLOCK"
    local CorrectKey = config.Key or "CLOCK-FREE-2026"
    local SupportedGames = config.SupportedGames or {}
    
    -- AUTHOR / CREDIT YANG DIKUNCI (TIDAK BISA DIUBAH OLEH USER)
    local LockedAuthorText = "Template By Ɛ/Ɛ ʌʌʌʌ/CLOCK"

    -- Services
    local CoreGui = game:GetService("CoreGui")
    local TweenService = game:GetService("TweenService")
    local Players = game:GetService("Players")
    local Lighting = game:GetService("Lighting")
    local LocalPlayer = Players.LocalPlayer

    -- Cleanup UI lama jika ada
    if CoreGui:FindFirstChild("CLOCKKeySystemUI") then
        CoreGui.CLOCKKeySystemUI:Destroy()
    end

    -- Blur Effect
    local Blur = Instance.new("BlurEffect")
    Blur.Name = "CLOCKUIBlur"
    Blur.Size = 16
    Blur.Parent = Lighting

    local KEY_FILE_NAME = FolderName .. "/Save-Key.json"
    local FAILED_KEYS_FILE = FolderName .. "/Failed-Key.json"
    local EXPIRATION_TIME = 24 * 60 * 60
    local maxAttempts = 5
    local remainingAttempts = maxAttempts

    local currentPlaceId = game.PlaceId
    local isGameSupported = SupportedGames[currentPlaceId] ~= nil

    local function loadMainScript()
        local scriptUrl = SupportedGames[currentPlaceId]
        if scriptUrl then
            loadstring(game:HttpGet(scriptUrl))()
        else
            warn("[" .. HubName .. "] Game not supported! Place ID: " .. tostring(currentPlaceId))
        end
    end

    local function ensureFolderExists()
        if makefolder and isfolder then
            pcall(function()
                if not isfolder(FolderName) then
                    makefolder(FolderName)
                end
            end)
        end
    end

    local function isKeyValid()
        local hasFileSystem = (writefile ~= nil and readfile ~= nil and isfile ~= nil)
        local genv = (getgenv and getgenv()) or _G

        if not hasFileSystem then
            return genv.CLOCKKeyVerifiedTime and (os.time() - genv.CLOCKKeyVerifiedTime < EXPIRATION_TIME) or false
        end

        local success, isFileExist = pcall(function() return isfile(KEY_FILE_NAME) end)
        if success and isFileExist then
            local readSuccess, content = pcall(function() return readfile(KEY_FILE_NAME) end)
            if readSuccess and content then
                local jsonSuccess, data = pcall(function() return game:GetService("HttpService"):JSONDecode(content) end)
                if jsonSuccess and data and data.ExpiryTime then
                    return os.time() < data.ExpiryTime
                end
            end
        end
        return false
    end

    local function saveKeySession()
        ensureFolderExists()
        local expiryTime = os.time() + EXPIRATION_TIME
        if writefile then
            pcall(function()
                local data = game:GetService("HttpService"):JSONEncode({ExpiryTime = expiryTime})
                writefile(KEY_FILE_NAME, data)
            end)
        end
    end

    local function isKeyAlreadyFailed(inputKey)
        if not (writefile and readfile and isfile) then return false end
        local success, isFileExist = pcall(function() return isfile(FAILED_KEYS_FILE) end)
        if success and isFileExist then
            local readSuccess, content = pcall(function() return readfile(FAILED_KEYS_FILE) end)
            if readSuccess and content then
                local jsonSuccess, failedList = pcall(function() return game:GetService("HttpService"):JSONDecode(content) end)
                if jsonSuccess and type(failedList) == "table" then
                    for _, key in ipairs(failedList) do
                        if key == inputKey then return true end
                    end
                end
            end
        end
        return false
    end

    local function recordFailedKey(inputKey)
        ensureFolderExists()
        if not (writefile and readfile and isfile) then return end
        local failedList = {}
        local success, isFileExist = pcall(function() return isfile(FAILED_KEYS_FILE) end)
        if success and isFileExist then
            local readSuccess, content = pcall(function() return readfile(FAILED_KEYS_FILE) end)
            if readSuccess and content then
                local jsonSuccess, data = pcall(function() return game:GetService("HttpService"):JSONDecode(content) end)
                if jsonSuccess and type(data) == "table" then failedList = data end
            end
        end
        
        local found = false
        for _, key in ipairs(failedList) do if key == inputKey then found = true break end end
        if not found then
            table.insert(failedList, inputKey)
            pcall(function()
                writefile(FAILED_KEYS_FILE, game:GetService("HttpService"):JSONEncode(failedList))
            end)
        end
    end

    if isKeyValid() then
        if Blur and Blur.Parent then Blur:Destroy() end
        loadMainScript()
        return
    end

    -- UI Construction
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "CLOCKKeySystemUI"
    pcall(function() ScreenGui.Parent = CoreGui end)
    if not ScreenGui.Parent then ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.IgnoreGuiInset = true

    local MainFrame = Instance.new("Frame")
    MainFrame.Size = UDim2.new(0, 360, 0, 310)
    MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    MainFrame.BackgroundColor3 = Color3.fromRGB(24, 28, 38)
    MainFrame.BorderSizePixel = 0
    MainFrame.Parent = ScreenGui

    Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 12)
    local MainStroke = Instance.new("UIStroke", MainFrame)
    MainStroke.Color = Color3.fromRGB(60, 70, 100)
    MainStroke.Thickness = 1.2

    -- BY AUTHOR TEXT (DIKUNCI PAKSA DI SINI)
    local ByText = Instance.new("TextLabel")
    ByText.Size = UDim2.new(0, 160, 0, 15)
    ByText.Position = UDim2.new(0, 12, 0, 10)
    ByText.BackgroundTransparency = 1
    ByText.Text = LockedAuthorText -- Selalu menggunakan teks asli buatanmu!
    ByText.TextSize = 9
    ByText.Font = Enum.Font.GothamMedium
    ByText.TextXAlignment = Enum.TextXAlignment.Left
    ByText.Parent = MainFrame

    -- Proteksi Tambahan: Jika ada yang mencoba mengganti teks author secara diam-diam
    task.spawn(function()
        while task.wait(0.5) do
            if ByText and ByText.Text ~= LockedAuthorText then
                ByText.Text = LockedAuthorText
            end
        end
    end)

    -- Logo Hub
    local HubLogo = Instance.new("ImageLabel", MainFrame)
    HubLogo.Size = UDim2.new(0, 48, 0, 48)
    HubLogo.Position = UDim2.new(0.5, -24, 0, 22)
    HubLogo.BackgroundColor3 = Color3.fromRGB(18, 22, 30)
    HubLogo.Image = HubLogo
    Instance.new("UICorner", HubLogo).CornerRadius = UDim.new(1, 0)

    -- Title
    local Title = Instance.new("TextLabel", MainFrame)
    Title.Size = UDim2.new(1, 0, 0, 20)
    Title.Position = UDim2.new(0, 0, 0, 74)
    Title.BackgroundTransparency = 1
    Title.Text = string.upper(HubName) .. " — KEY SYSTEM"
    Title.TextSize = 14
    Title.Font = Enum.Font.GothamBold
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)

    local DEFAULT_SUBTITLE = "Enter key to continue (Valid for 24h)"
    local Subtitle = Instance.new("TextLabel", MainFrame)
    Subtitle.Size = UDim2.new(1, -40, 0, 15)
    Subtitle.Position = UDim2.new(0, 20, 0, 96)
    Subtitle.BackgroundTransparency = 1
    Subtitle.Text = DEFAULT_SUBTITLE
    Subtitle.TextSize = 10
    Subtitle.Font = Enum.Font.Gotham
    Subtitle.TextColor3 = Color3.fromRGB(200, 200, 200)

    -- Input Box
    local InputContainer = Instance.new("Frame", MainFrame)
    InputContainer.Size = UDim2.new(1, -40, 0, 38)
    InputContainer.Position = UDim2.new(0, 20, 0, 115)
    InputContainer.BackgroundColor3 = Color3.fromRGB(16, 19, 26)
    Instance.new("UICorner", InputContainer).CornerRadius = UDim.new(0, 8)

    local KeyInput = Instance.new("TextBox", InputContainer)
    KeyInput.Size = UDim2.new(1, -28, 1, 0)
    KeyInput.Position = UDim2.new(0, 14, 0, 0)
    KeyInput.BackgroundTransparency = 1
    KeyInput.PlaceholderText = "Enter your key here..."
    KeyInput.PlaceholderColor3 = Color3.fromRGB(120, 130, 150)
    KeyInput.Text = ""
    KeyInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    KeyInput.TextSize = 11
    KeyInput.Font = Enum.Font.Gotham
    KeyInput.ClearTextOnFocus = false

    -- Buttons
    local VerifyBtn = Instance.new("TextButton", MainFrame)
    VerifyBtn.Size = UDim2.new(1, -40, 0, 36)
    VerifyBtn.Position = UDim2.new(0, 20, 0, 160)
    VerifyBtn.Text = "VERIFY KEY"
    VerifyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    VerifyBtn.Font = Enum.Font.GothamBold
    VerifyBtn.BackgroundColor3 = Color3.fromRGB(3, 95, 3)
    Instance.new("UICorner", VerifyBtn).CornerRadius = UDim.new(0, 8)

    local DiscordBtn = Instance.new("TextButton", MainFrame)
    DiscordBtn.Size = UDim2.new(0.5, -24, 0, 32)
    DiscordBtn.Position = UDim2.new(0, 20, 0, 202)
    DiscordBtn.Text = "JOIN DISCORD"
    DiscordBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    DiscordBtn.Font = Enum.Font.GothamBold
    DiscordBtn.BackgroundColor3 = Color3.fromRGB(12, 18, 120)
    Instance.new("UICorner", DiscordBtn).CornerRadius = UDim.new(0, 8)

    local CopyHwidBtn = Instance.new("TextButton", MainFrame)
    CopyHwidBtn.Size = UDim2.new(0.5, -24, 0, 32)
    CopyHwidBtn.Position = UDim2.new(0.5, 4, 0, 202)
    CopyHwidBtn.Text = "COPY HWID"
    CopyHwidBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    CopyHwidBtn.Font = Enum.Font.GothamBold
    CopyHwidBtn.BackgroundColor3 = Color3.fromRGB(38, 42, 58)
    Instance.new("UICorner", CopyHwidBtn).CornerRadius = UDim.new(0, 8)

    local AttemptsText = Instance.new("TextLabel", MainFrame)
    AttemptsText.Size = UDim2.new(1, 0, 0, 16)
    AttemptsText.Position = UDim2.new(0, 0, 0, 242)
    AttemptsText.BackgroundTransparency = 1
    AttemptsText.Text = "Attempts remaining: " .. remainingAttempts
    AttemptsText.TextSize = 10
    AttemptsText.Font = Enum.Font.Gotham
    AttemptsText.TextColor3 = Color3.fromRGB(180, 180, 180)

    -- Button Actions
    CopyHwidBtn.MouseButton1Click:Connect(function()
        if setclipboard then setclipboard("HWID-" .. tostring(math.random(100000, 999999)) .. "-DEVICE") end
        Subtitle.Text = "HWID Copied to Clipboard!"
        task.wait(1.5)
        Subtitle.Text = DEFAULT_SUBTITLE
    end)

    DiscordBtn.MouseButton1Click:Connect(function()
        if setclipboard then setclipboard(DiscordLink) end
        Subtitle.Text = "Discord Link Copied!"
        task.wait(1.5)
        Subtitle.Text = DEFAULT_SUBTITLE
    end)

    VerifyBtn.MouseButton1Click:Connect(function()
        local inputKey = KeyInput.Text
        if string.gsub(inputKey, "%s+", "") == "" then
            Subtitle.Text = "Please enter a key!"
            task.wait(1.5)
            Subtitle.Text = DEFAULT_SUBTITLE
            return
        end

        if isKeyAlreadyFailed(inputKey) then
            Subtitle.Text = "Key already tried and failed!"
            task.wait(1.5)
            Subtitle.Text = DEFAULT_SUBTITLE
            return
        end

        Subtitle.Text = "Connecting to server..."
        task.wait(0.8)

        if inputKey == CorrectKey then
            Subtitle.Text = "Key Verified!"
            saveKeySession()
            task.wait(1)
            if Blur then Blur:Destroy() end
            ScreenGui:Destroy()
            loadMainScript()
        else
            recordFailedKey(inputKey)
            remainingAttempts = remainingAttempts - 1
            AttemptsText.Text = "Attempts remaining: " .. remainingAttempts
            Subtitle.Text = "Invalid Key!"

            if remainingAttempts <= 0 then
                VerifyBtn.Active = false
                LocalPlayer:Kick("[" .. HubName .. " SECURITY] Too many failed key attempts.")
            else
                task.wait(1.5)
                Subtitle.Text = DEFAULT_SUBTITLE
            end
        end
    end)
end

return CLOCK_LIBRARY
