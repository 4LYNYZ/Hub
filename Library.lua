--[[
    CLOCK KEY SYSTEM LIBRARY - FULL ENGINE
    Template By Ɛ/Ɛ ʌʌʌʌ/CLOCK
]]

local CLOCK_LIBRARY = {}

function CLOCK_LIBRARY:CreateWindow(config)
    -- Konfigurasi dari User dengan Fallback Default
    local HubName = config.Name or "CLOCK"
    local DiscordLink = config.Discord or "https://discord.gg/your-link"
    local HubLogoId = config.Logo or "rbxassetid://114917214257743"
    local ExactKey = config.Key or "CLOCK-FREE-2026"
    local FolderName = config.Folder or "CLOCK"
    local SupportedGames = config.SupportedGames or {}

    -- AUTHOR / CREDIT YANG DIKUNCI (TIDAK BISA DIUBAH)
    local LOCKED_AUTHOR_TEXT = "Template By Ɛ/Ɛ ʌʌʌʌ/CLOCK"

    local CoreGui = game:GetService("CoreGui")
    local TweenService = game:GetService("TweenService")
    local Players = game:GetService("Players")
    local Lighting = game:GetService("Lighting")
    local LocalPlayer = Players.LocalPlayer

    -- Cleanup UI lama
    if CoreGui:FindFirstChild("CLOCKKeySystemUI") then
        CoreGui.CLOCKKeySystemUI:Destroy()
    end

    -- Blur Effect
    local Blur = Instance.new("BlurEffect")
    Blur.Name = "CLOCKUIBlur"
    Blur.Size = 16
    Blur.Parent = Lighting

    local ICON_VERIFY  = "rbxassetid://124547549008939" 
    local ICON_DISCORD = "rbxassetid://83278450537116"  
    local ICON_HWID    = "rbxassetid://80934710831288" 

    local maxAttempts = 5
    local remainingAttempts = maxAttempts

    local KEY_FILE_NAME = FolderName .. "/Save-Key.json"
    local FAILED_KEYS_FILE = FolderName .. "/Failed-Key.json"
    local EXPIRATION_TIME = 24 * 60 * 60

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
        local hasFileSystem = (writefile ~= nil)
        local genv = (getgenv and getgenv()) or _G

        if hasFileSystem then
            pcall(function()
                local data = game:GetService("HttpService"):JSONEncode({ExpiryTime = expiryTime})
                writefile(KEY_FILE_NAME, data)
            end)
        else
            genv.CLOCKKeyVerifiedTime = os.time()
        end
    end

    local function isKeyAlreadyFailed(inputKey)
        local hasFileSystem = (writefile ~= nil and readfile ~= nil and isfile ~= nil)
        if not hasFileSystem then return false end

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
        local hasFileSystem = (writefile ~= nil and readfile ~= nil and isfile ~= nil)
        if not hasFileSystem then return end

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

    local function removeBlur()
        if Lighting:FindFirstChild("CLOCKUIBlur") then Lighting.CLOCKUIBlur:Destroy() end
    end

    -- UI Construction
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "CLOCKKeySystemUI"
    if not pcall(function() ScreenGui.Parent = CoreGui end) then
        ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.IgnoreGuiInset = true

    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
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

    local waveTweenInfo = TweenInfo.new(2.5, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1, false)

    local function applyWaveEffect(guiObject, baseColor, shineColor)
        baseColor = baseColor or Color3.fromRGB(130, 135, 145) 
        shineColor = shineColor or Color3.fromRGB(235, 240, 250)    
        if guiObject:IsA("TextLabel") or guiObject:IsA("TextBox") then
            guiObject.TextColor3 = Color3.fromRGB(255, 255, 255)
        elseif guiObject:IsA("ImageLabel") then
            guiObject.ImageColor3 = Color3.fromRGB(255, 255, 255)
        end
        local gradient = Instance.new("UIGradient")
        gradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0.0, baseColor),   
            ColorSequenceKeypoint.new(0.5, shineColor), 
            ColorSequenceKeypoint.new(1.0, baseColor)    
        })
        gradient.Offset = Vector2.new(-1, 0)
        gradient.Parent = guiObject
        TweenService:Create(gradient, waveTweenInfo, {Offset = Vector2.new(1, 0)}):Play()
    end

    local function applyCalmButtonPulse(btn, darkColor, lightColor)
        btn.AutoButtonColor = false
        btn.BackgroundColor3 = darkColor
        local corner = Instance.new("UICorner", btn)
        corner.CornerRadius = UDim.new(0, 8)
        task.spawn(function()
            local info = TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
            TweenService:Create(btn, info, {BackgroundColor3 = lightColor}):Play()
        end)
    end

    local function createBtnWithIcon(btn, text, textSize, iconAssetId)
        btn.Text = "" 
        local container = Instance.new("Frame", btn)
        container.Size = UDim2.new(1, 0, 1, 0)
        container.BackgroundTransparency = 1

        local layout = Instance.new("UIListLayout", container)
        layout.FillDirection = Enum.FillDirection.Horizontal
        layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        layout.VerticalAlignment = Enum.VerticalAlignment.Center
        layout.Padding = UDim.new(0, 8)

        if iconAssetId and iconAssetId ~= "" then
            local icon = Instance.new("ImageLabel", container)
            icon.Size = UDim2.new(0, textSize + 6, 0, textSize + 6)
            icon.BackgroundTransparency = 1
            icon.Image = iconAssetId
            icon.ScaleType = Enum.ScaleType.Fit
            applyWaveEffect(icon, Color3.fromRGB(140, 145, 155), Color3.fromRGB(240, 245, 255))
        end

        local textLabel = Instance.new("TextLabel", container)
        textLabel.Size = UDim2.new(0, 0, 1, 0)
        textLabel.AutomaticSize = Enum.AutomaticSize.X
        textLabel.BackgroundTransparency = 1
        textLabel.Text = text
        textLabel.TextSize = textSize
        textLabel.Font = Enum.Font.GothamBold
        applyWaveEffect(textLabel, Color3.fromRGB(140, 145, 155), Color3.fromRGB(240, 245, 255))
    end

    -- UI Elements & Locked Author Text
    local ByText = Instance.new("TextLabel", MainFrame)
    ByText.Size = UDim2.new(0, 160, 0, 15)
    ByText.Position = UDim2.new(0, 12, 0, 10)
    ByText.BackgroundTransparency = 1
    ByText.Text = LOCKED_AUTHOR_TEXT -- Dikunci mutlak!
    ByText.TextSize = 9
    ByText.Font = Enum.Font.GothamMedium
    ByText.TextXAlignment = Enum.TextXAlignment.Left
    applyWaveEffect(ByText, Color3.fromRGB(130, 145, 175), Color3.fromRGB(255, 255, 255))

    -- Anti-tamper author check
    task.spawn(function()
        while task.wait(0.5) do
            if ByText and ByText.Text ~= LOCKED_AUTHOR_TEXT then
                ByText.Text = LOCKED_AUTHOR_TEXT
            end
        end
    end)

    local HubLogo = Instance.new("ImageLabel", MainFrame)
    HubLogo.Size = UDim2.new(0, 48, 0, 48)
    HubLogo.Position = UDim2.new(0.5, -24, 0, 22)
    HubLogo.BackgroundColor3 = Color3.fromRGB(18, 22, 30)
    HubLogo.Image = HubLogoId
    Instance.new("UICorner", HubLogo).CornerRadius = UDim.new(1, 0)

    local Title = Instance.new("TextLabel", MainFrame)
    Title.Size = UDim2.new(1, 0, 0, 20)
    Title.Position = UDim2.new(0, 0, 0, 74)
    Title.BackgroundTransparency = 1
    Title.Text = string.upper(HubName) .. " — KEY SYSTEM"
    Title.TextSize = 14
    Title.Font = Enum.Font.GothamBold
    applyWaveEffect(Title, Color3.fromRGB(180, 200, 240), Color3.fromRGB(255, 255, 255))

    local DEFAULT_SUBTITLE = "Enter key to continue (Valid for 24h)"
    local Subtitle = Instance.new("TextLabel", MainFrame)
    Subtitle.Size = UDim2.new(1, -40, 0, 15)
    Subtitle.Position = UDim2.new(0, 20, 0, 96)
    Subtitle.BackgroundTransparency = 1
    Subtitle.Text = DEFAULT_SUBTITLE
    Subtitle.TextSize = 10
    Subtitle.Font = Enum.Font.Gotham
    Subtitle.TextXAlignment = Enum.TextXAlignment.Left
    applyWaveEffect(Subtitle, Color3.fromRGB(140, 155, 185), Color3.fromRGB(255, 255, 255))

    local InputContainer = Instance.new("Frame", MainFrame)
    InputContainer.Size = UDim2.new(1, -40, 0, 38)
    InputContainer.Position = UDim2.new(0, 20, 0, 115)
    InputContainer.BackgroundColor3 = Color3.fromRGB(16, 19, 26)
    InputContainer.BorderSizePixel = 0
    Instance.new("UICorner", InputContainer).CornerRadius = UDim.new(0, 8)

    local InputStroke = Instance.new("UIStroke", InputContainer)
    InputStroke.Color = Color3.fromRGB(60, 75, 110)
    InputStroke.Thickness = 1

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

    local VerifyBtn = Instance.new("TextButton", MainFrame)
    VerifyBtn.Size = UDim2.new(1, -40, 0, 36)
    VerifyBtn.Position = UDim2.new(0, 20, 0, 160)

    local DiscordBtn = Instance.new("TextButton", MainFrame)
    DiscordBtn.Size = UDim2.new(0.5, -24, 0, 32)
    DiscordBtn.Position = UDim2.new(0, 20, 0, 202)

    local CopyHwidBtn = Instance.new("TextButton", MainFrame)
    CopyHwidBtn.Size = UDim2.new(0.5, -24, 0, 32)
    CopyHwidBtn.Position = UDim2.new(0.5, 4, 0, 202)

    applyCalmButtonPulse(VerifyBtn, Color3.fromRGB(3, 95, 3), Color3.fromRGB(5, 140, 5))
    applyCalmButtonPulse(DiscordBtn, Color3.fromRGB(12, 18, 120), Color3.fromRGB(22, 32, 175))
    applyCalmButtonPulse(CopyHwidBtn, Color3.fromRGB(38, 42, 58), Color3.fromRGB(58, 64, 88))

    createBtnWithIcon(VerifyBtn, "VERIFY KEY", 12, ICON_VERIFY)
    createBtnWithIcon(DiscordBtn, "JOIN DISCORD", 11, ICON_DISCORD)
    createBtnWithIcon(CopyHwidBtn, "COPY HWID", 11, ICON_HWID)

    local AttemptsText = Instance.new("TextLabel", MainFrame)
    AttemptsText.Size = UDim2.new(1, 0, 0, 16)
    AttemptsText.Position = UDim2.new(0, 0, 0, 242)
    AttemptsText.BackgroundTransparency = 1
    AttemptsText.Text = "Attempts remaining: " .. remainingAttempts
    AttemptsText.TextSize = 10
    AttemptsText.Font = Enum.Font.Gotham
    applyWaveEffect(AttemptsText, Color3.fromRGB(150, 165, 195), Color3.fromRGB(255, 255, 255))

    -- Footer Profile & Status
    local UserAvatar = Instance.new("ImageLabel", MainFrame)
    UserAvatar.Size = UDim2.new(0, 26, 0, 26)
    UserAvatar.Position = UDim2.new(0, 15, 1, -34)
    UserAvatar.BackgroundColor3 = Color3.fromRGB(18, 22, 30)
    Instance.new("UICorner", UserAvatar).CornerRadius = UDim.new(1, 0)
    pcall(function()
        UserAvatar.Image = Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
    end)

    local UserNameLabel = Instance.new("TextLabel", MainFrame)
    UserNameLabel.Size = UDim2.new(0, 150, 0, 26)
    UserNameLabel.Position = UDim2.new(0, 48, 1, -34)
    UserNameLabel.BackgroundTransparency = 1
    UserNameLabel.Text = "@" .. LocalPlayer.Name
    UserNameLabel.TextSize = 10
    UserNameLabel.Font = Enum.Font.GothamMedium
    UserNameLabel.TextXAlignment = Enum.TextXAlignment.Left
    applyWaveEffect(UserNameLabel, Color3.fromRGB(150, 165, 195), Color3.fromRGB(255, 255, 255))

    local GameStatusLabel = Instance.new("TextLabel", MainFrame)
    GameStatusLabel.Size = UDim2.new(0, 140, 0, 26)
    GameStatusLabel.Position = UDim2.new(1, -155, 1, -34)
    GameStatusLabel.BackgroundTransparency = 1
    GameStatusLabel.Text = isGameSupported and "Game: Supported" or "Game: Unsupported"
    GameStatusLabel.TextSize = 10
    GameStatusLabel.Font = Enum.Font.GothamBold
    GameStatusLabel.TextXAlignment = Enum.TextXAlignment.Right
    applyWaveEffect(GameStatusLabel, isGameSupported and Color3.fromRGB(80, 220, 110) or Color3.fromRGB(255, 90, 90), Color3.fromRGB(255, 255, 255))

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

        if inputKey == ExactKey then
            Subtitle.Text = "Key Verified!"
            saveKeySession()
            task.wait(1)
            if Blur then
                TweenService:Create(Blur, TweenInfo.new(0.4), {Size = 0}):Play()
                task.wait(0.4)
                removeBlur()
            end
            ScreenGui:Destroy()
            loadMainScript()
        else
            recordFailedKey(inputKey)
            remainingAttempts = remainingAttempts - 1
            AttemptsText.Text = "Attempts remaining: " .. remainingAttempts
            Subtitle.Text = "Invalid Key!"

            if remainingAttempts <= 0 then
                VerifyBtn.Active = false
                Subtitle.Text = "Too many failed attempts!"
                task.wait(0.8)
                LocalPlayer:Kick("[" .. HubName .. " SECURITY] Too many failed key attempts.")
            else
                task.wait(1.5)
                Subtitle.Text = DEFAULT_SUBTITLE
            end
        end
    end)
end

return CLOCK_LIBRARY
