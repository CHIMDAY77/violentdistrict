repeat wait() until game:IsLoaded() and game.Players.LocalPlayer

-- ── SERVICES ──────────────────────────────────────────────────────────────
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace        = game:GetService("Workspace")
local Camera           = workspace.CurrentCamera
local LocalPlayer      = Players.LocalPlayer
local Mouse            = LocalPlayer:GetMouse()
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting         = game:GetService("Lighting")

-- ── SETTINGS ──────────────────────────────────────────────────────────────
local Settings = {
    ESP_Players = false,
    ESP_Tracers = false,
    Color_Team = Color3.fromRGB(0, 255, 100),
    Color_Enemy = Color3.fromRGB(0, 255, 0), -- Màu xanh lá (Green)
    FOV_Enabled       = true,
    AimBot_Enabled    = true,
    AimBot_FOV        = 90,
    Aimbot_TeamCheck  = false,
    Aimbot_AimPart    = "HumanoidRootPart",
    Aiming            = false,
    SpeedHack_Enabled = false,
    SpeedHack_Speed   = 50,
    InfJump_Enabled   = false,
    
    RageHack_Enabled  = false,
    RageHack_Distance = 1,
    RageHack_Height   = 4,
    RageHack_ActiveTarget = nil
}

local VDConfig = {
    Generator = { AntiFailEnabled = false },
    Healing = { AntiFailEnabled = false },
    Visual = { FullbrightEnabled = false },
    Vault = { AuraEnabled = false },
    HBE = { Enabled = false, Size = 15 }
}

local VaultAuraSystem = {}
local HBESystem = {
    Connections = {},
    PlayerAddedConn = nil,
    PlayerRemovingConn = nil,
    CharParent = nil
}

local originalLighting = {
    Brightness = Lighting.Brightness,
    ClockTime = Lighting.ClockTime,
    FogEnd = Lighting.FogEnd,
    FogStart = Lighting.FogStart,
    GlobalShadows = Lighting.GlobalShadows,
    OutdoorAmbient = Lighting.OutdoorAmbient,
    Ambient = Lighting.Ambient,
    ColorShift_Top = Lighting.ColorShift_Top,
    ColorShift_Bottom = Lighting.ColorShift_Bottom,
    FogColor = Lighting.FogColor,
    Atmosphere = {},
    Blur = {},
    ColorCorrection = {},
    SunRays = {}
}

for _, v in pairs(Lighting:GetChildren()) do
    if v:IsA("Atmosphere") then
        originalLighting.Atmosphere.Density = v.Density
        originalLighting.Atmosphere.Offset = v.Offset
        originalLighting.Atmosphere.Glare = v.Glare
        originalLighting.Atmosphere.Haze = v.Haze
    elseif v:IsA("BlurEffect") then
        originalLighting.Blur.Size = v.Size
    elseif v:IsA("ColorCorrectionEffect") then
        originalLighting.ColorCorrection.Enabled = v.Enabled
    elseif v:IsA("SunRaysEffect") then
        originalLighting.SunRays.Enabled = v.Enabled
    end
end



-- ── GUI ───────────────────────────────────────────────────────────────────
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "ESP & Aim Bot",
    LoadingTitle = "Đang khởi tạo...",
    LoadingSubtitle = "by K2PN",
    ConfigurationSaving = { Enabled = true, FileName = "ESP_AimBot_Config" },
    Discord = { Enabled = false },
    KeySystem = false
})

local ESPTab = Window:CreateTab("ESP", "eye")
ESPTab:CreateToggle({ Name = "ESP Players (Box 3D)", CurrentValue = Settings.ESP_Players, Flag = "ESP_Players", Callback = function(v) Settings.ESP_Players = v end })
ESPTab:CreateToggle({ Name = "ESP Tracers", CurrentValue = Settings.ESP_Tracers, Flag = "ESP_Tracers", Callback = function(v) Settings.ESP_Tracers = v end })
ESPTab:CreateToggle({ Name = "Team Check (ESP)", CurrentValue = Settings.TeamCheck, Flag = "ESP_TeamCheck", Callback = function(v) Settings.TeamCheck = v end })



local LocalTab = Window:CreateTab("Local Player", "user")
LocalTab:CreateToggle({ Name = "Hack Speed", CurrentValue = Settings.SpeedHack_Enabled, Flag = "SpeedHack", Callback = function(v) Settings.SpeedHack_Enabled = v end })
LocalTab:CreateSlider({ Name = "Tốc độ chạy", Range = {16, 60}, Increment = 1, Suffix = "Speed", CurrentValue = Settings.SpeedHack_Speed, Flag = "SpeedSlider", Callback = function(v) Settings.SpeedHack_Speed = v end })
LocalTab:CreateToggle({ Name = "Infinity Jump", CurrentValue = Settings.InfJump_Enabled, Flag = "InfJump", Callback = function(v) Settings.InfJump_Enabled = v end })

local AntiFailTab = Window:CreateTab("Anti Fail", "shield")
AntiFailTab:CreateToggle({ Name = "Anti Fail (Gen & Heal)", CurrentValue = VDConfig.Generator.AntiFailEnabled, Flag = "AntiFail", Callback = function(v) 
    VDConfig.Generator.AntiFailEnabled = v
    VDConfig.Healing.AntiFailEnabled = v
end })

local RemoveFogTab = Window:CreateTab("Remove Fog", "sun")
RemoveFogTab:CreateToggle({ Name = "Remove Fog", CurrentValue = VDConfig.Visual.FullbrightEnabled, Flag = "RemoveFog", Callback = function(v) 
    VDConfig.Visual.FullbrightEnabled = v
end })

local VaultAuraTab = Window:CreateTab("Vault Aura", "scan")
VaultAuraTab:CreateToggle({ Name = "Enable Vault Aura", CurrentValue = VDConfig.Vault.AuraEnabled, Flag = "VaultAura", Callback = function(v)
    VDConfig.Vault.AuraEnabled = v
    if VaultAuraSystem.Toggle then
        VaultAuraSystem.Toggle(v)
    end
end })

local HBETab = Window:CreateTab("Hitbox Expander", "crosshair")
HBETab:CreateToggle({ Name = "Enable HBE", CurrentValue = VDConfig.HBE.Enabled, Flag = "HBE_Toggle", Callback = function(v)
    VDConfig.HBE.Enabled = v
    if HBESystem.Toggle then
        HBESystem.Toggle(v)
    end
end })
HBETab:CreateSlider({ Name = "Hitbox Size", Range = {2, 50}, Increment = 1, Suffix = "Studs", CurrentValue = VDConfig.HBE.Size, Flag = "HBE_Size", Callback = function(v)
    VDConfig.HBE.Size = v
end })



Rayfield:LoadConfiguration()


--[[
-- ===== HÀM HỖ TRỢ AIMBOT =====
local function getPart(character, partName)
    if not character then return nil end
    -- Rayfield dropdown trả về table chứa mảng các giá trị được chọn (vd: {"Head"})
    local name = type(partName) == "table" and partName[1] or partName
    if type(name) ~= "string" then return nil end
    return character:FindFirstChild(name)
end

local function isVisible(targetPart)
    if not targetPart then return false end
    
    local origin = Camera.CFrame.Position
    local direction = targetPart.Position - origin
    
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character, targetPart.Parent}
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    raycastParams.IgnoreWater = true

    local result = Workspace:Raycast(origin, direction, raycastParams)
    
    -- Nếu không có vật cản (result là nil), trả về true
    return result == nil
end

-- ===== AIM BOT THEO CODE MẪU =====
local GameRegistry = {
    {
        Name = "CHAMBERED",
        PlaceIds = {89772838187511},
        GetButton = function(playerGui)
            for _, ui in ipairs(playerGui:GetDescendants()) do
                if ui.Name == "FireButton" and ui:IsA("TextButton") and ui.Parent and ui.Parent.Name == "MobileButtons" then
                    return ui
                end
            end
            return nil
        end
    },
    {
        Name = "Pistol-Arena",
        PlaceIds = {87018676608089},
        GetButton = function(playerGui)
            for _, ui in ipairs(playerGui:GetDescendants()) do
                if ui.Name == "ShootButton" and ui:IsA("TextButton") and ui.Parent and ui.Parent.Name == "Buttons" then
                    return ui
                end
            end
            return nil
        end
    },
    {
        Name = "OneTap",
        PlaceIds = {90568084448279},
        GetButton = function(playerGui)
            for _, ui in ipairs(playerGui:GetDescendants()) do
                if ui.Name == "Attack" and ui:IsA("ImageButton") and ui.Parent and ui.Parent.Name == "Buttons" then
                    return ui
                end
            end
            return nil
        end
    }
}

local isMobile = UserInputService.TouchEnabled and not UserInputService.MouseEnabled

local TargetMobileButton = nil

if isMobile then
    local function InitializeMobileAimbot()
        local player = game.Players.LocalPlayer
        local playerGui = player:WaitForChild("PlayerGui")
        local fireBtn = nil

        -- Duyệt qua Registry để tìm game hiện tại
        for _, registryData in ipairs(GameRegistry) do
            if table.find(registryData.PlaceIds, game.PlaceId) then
                print("[Log] Đã nhận diện game: " .. registryData.Name)
                fireBtn = registryData.GetButton(playerGui)
                TargetMobileButton = fireBtn
                break
            end
        end

        if fireBtn then
            print("[Log] Đã tìm thấy nút bắn cho game hiện tại! Tiến hành hook aimbot...")
            fireBtn.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
                    Settings.Aiming = true
                end
            end)

            fireBtn.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
                    Settings.Aiming = false
                end
            end)
        else
            warn("[Lỗi] Game này không có nút bắn trong Registry hoặc UI mobile chưa load đầy đủ!")
        end
    end

    task.spawn(InitializeMobileAimbot)
else
    local inputCount = 0

    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or
           input.UserInputType == Enum.UserInputType.MouseButton2 then
            inputCount = inputCount + 1
            Settings.Aiming = true
        end
    end)

    UserInputService.InputEnded:Connect(function(input, gameProcessed)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or
           input.UserInputType == Enum.UserInputType.MouseButton2 then
            inputCount = math.max(0, inputCount - 1)
            if inputCount == 0 then
                Settings.Aiming = false
            end
        end
    end)
end

local fovGui = Instance.new("ScreenGui")
fovGui.Name = "FOVCircleGui"
fovGui.IgnoreGuiInset = true
local success, err = pcall(function()
    fovGui.Parent = game:GetService("CoreGui")
end)
if not success then
    fovGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
end

local fovFrame = Instance.new("Frame")
fovFrame.Name = "FOVFrame"
fovFrame.BackgroundTransparency = 1
fovFrame.AnchorPoint = Vector2.new(0.5, 0.5)
fovFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
fovFrame.Visible = false
fovFrame.Parent = fovGui

local fovStroke = Instance.new("UIStroke")
fovStroke.Color = Color3.fromRGB(255, 255, 255)
fovStroke.Thickness = 1.5
fovStroke.Parent = fovFrame

local fovCorner = Instance.new("UICorner")
fovCorner.CornerRadius = UDim.new(1, 0)
fovCorner.Parent = fovFrame

RunService.RenderStepped:Connect(function()
    -- Cập nhật hình vẽ FOV trên màn hình
    if Settings.FOV_Enabled then
        local fovDiameter = Settings.AimBot_FOV * 2
        fovFrame.Size = UDim2.new(0, fovDiameter, 0, fovDiameter)
        fovStroke.Color = Color3.fromHSV(tick() % 5 / 5, 1, 1)
        fovFrame.Visible = true
    else
        fovFrame.Visible = false
    end

    if not Settings.AimBot_Enabled then return end

    local dist = math.huge
    local closest_char = nil

    if Settings.Aiming then
        for _, v in next, Players:GetPlayers() do
            if v ~= LocalPlayer and v.Character then
                local humanoid = v.Character:FindFirstChild("Humanoid")
                local aimPart = getPart(v.Character, Settings.Aimbot_AimPart) or v.Character:FindFirstChild("HumanoidRootPart")
                if aimPart and humanoid and humanoid.Health > 0 then
                    if Settings.Aimbot_TeamCheck == true and v.Team == LocalPlayer.Team then
                        -- skip
                    else
                        if isVisible(aimPart) then
                            local partPos, isOnScreen = Camera:WorldToViewportPoint(aimPart.Position)
                            if isOnScreen then
                                local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
                                local mag = (center - Vector2.new(partPos.X, partPos.Y)).Magnitude
                                -- Kiểm tra xem mục tiêu có nằm trong vòng tròn FOV không
                                if mag < dist and mag <= Settings.AimBot_FOV then
                                    dist = mag
                                    closest_char = v.Character
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    if closest_char ~= nil then
        local aimPart = getPart(closest_char, Settings.Aimbot_AimPart) or closest_char:FindFirstChild("HumanoidRootPart")
        local humanoid = closest_char:FindFirstChild("Humanoid")
        -- Đảm bảo vẫn nhìn thấy target (chưa bị che khuất) thì mới tiếp tục aim
        if aimPart and humanoid and humanoid.Health > 0 and isVisible(aimPart) then
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, aimPart.Position)
        end
    end
end)
]]






-------------------------------------------------------------------
-- [CORE] HÀM VẼ BOX (CHỈ DÀNH CHO NGƯỜI CHƠI)
-------------------------------------------------------------------
-- ESP STORAGE
local ESPCache = {}

-- CREATE ESP
local function CreateESP(player,character)

    if player == LocalPlayer then return end

    local root = character:WaitForChild("HumanoidRootPart",5)
    local humanoid = character:FindFirstChildOfClass("Humanoid")

    if not root or not humanoid then return end

    -- GUI (3D Highlight ôm sát nhân vật)
    local hl = Instance.new("Highlight")
    hl.Name = "ESP_3D"
    hl.Adornee = character
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.FillTransparency = 1 -- Xoá màu nền để chỉ còn viền mảnh
    hl.OutlineTransparency = 0
    hl.Parent = character

    -- Tracer Line (Drawing API)
    local tracer = Drawing.new("Line")
    tracer.Visible = false
    tracer.Thickness = 1
    tracer.Color = Color3.fromRGB(0, 150, 255)

    local connection
    connection = RunService.RenderStepped:Connect(function()
        if not character.Parent or humanoid.Health <= 0 or not player.Parent then
            hl:Destroy()
            tracer:Remove()
            if connection then connection:Disconnect() end
            return
        end

        -- Nhận diện team: Nếu game không có team, mặc định coi là kẻ địch (isTeammate = false)
        local isTeammate = false
        if LocalPlayer.Team ~= nil and player.Team ~= nil then
            isTeammate = (player.Team == LocalPlayer.Team)
        end

        -- Logic hiển thị: Nếu bật TeamCheck và là đồng đội thì ẩn, ngược lại thì hiện
        local shouldShow = true
        if Settings.TeamCheck and isTeammate then
            shouldShow = false
        end

        -- Đồng đội màu xanh lá, kẻ địch màu đỏ
        local drawColor = isTeammate and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)

        -- Cập nhật ESP 3D
        if Settings.ESP_Players and shouldShow then
            hl.Enabled = true
            hl.OutlineColor = drawColor
        else
            hl.Enabled = false
        end

        -- Cập nhật Tracers
        if Settings.ESP_Tracers and shouldShow then
            local targetPos, onScreen = Camera:WorldToViewportPoint(root.Position)
            if onScreen then
                -- Điểm giữa cạnh trên cùng của màn hình
                tracer.From = Vector2.new(Camera.ViewportSize.X / 2, 0)
                tracer.To = Vector2.new(targetPos.X, targetPos.Y)
                tracer.Color = drawColor
                tracer.Visible = true
            else
                tracer.Visible = false
            end
        else
            tracer.Visible = false
        end
    end)

    ESPCache[player] = {hl = hl, tracer = tracer, conn = connection}

end

-- PLAYER HANDLER
local function SetupPlayer(player)

    player.CharacterAdded:Connect(function(char)
        task.wait(1)
        CreateESP(player,char)
    end)

    if player.Character then
        CreateESP(player,player.Character)
    end

end

-- INIT
for _,p in ipairs(Players:GetPlayers()) do
    SetupPlayer(p)
end

Players.PlayerAdded:Connect(SetupPlayer)

Players.PlayerRemoving:Connect(function(player)
    if ESPCache[player] then
        local cache = ESPCache[player]
        if type(cache) == "table" then
            if cache.hl then cache.hl:Destroy() end
            if cache.tracer then cache.tracer:Remove() end
            if cache.conn then cache.conn:Disconnect() end
        else
            cache:Destroy()
        end
        ESPCache[player] = nil
    end
end)
-- ===== LOCAL PLAYER HACKS =====
UserInputService.JumpRequest:Connect(function()
    if Settings.InfJump_Enabled then
        if LocalPlayer.Character then
            local humanoid = LocalPlayer.Character:FindFirstChild("Humanoid")
            if humanoid and humanoid:GetState() ~= Enum.HumanoidStateType.Dead then
                humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end
    end
end)

RunService.RenderStepped:Connect(function()
    if Settings.SpeedHack_Enabled then
        if LocalPlayer.Character then
            local humanoid = LocalPlayer.Character:FindFirstChild("Humanoid")
            if humanoid and humanoid.Health > 0 then
                humanoid.WalkSpeed = Settings.SpeedHack_Speed
            end
        end
    end
end)

--[[
local function FireWeapon()
    if isMobile and TargetMobileButton then
        for _, conn in ipairs(getconnections(TargetMobileButton.MouseButton1Click) or {}) do
            conn:Fire()
        end
        for _, conn in ipairs(getconnections(TargetMobileButton.MouseButton1Down) or {}) do
            conn:Fire()
        end
        for _, conn in ipairs(getconnections(TargetMobileButton.TouchTap) or {}) do
            conn:Fire()
        end
    else
        mouse1press()
        task.wait()
        mouse1release()
    end
end

task.spawn(function()
    while true do
        task.wait(0.05)
        
        if Settings.RageHack_Enabled and LocalPlayer.Character then
            local myRoot = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            local myHumanoid = LocalPlayer.Character:FindFirstChild("Humanoid")
            
            if myRoot and myHumanoid and myHumanoid.Health > 0 then
                for _, v in ipairs(Players:GetPlayers()) do
                    if v ~= LocalPlayer and v.Character then
                        local enemyRoot = v.Character:FindFirstChild("HumanoidRootPart")
                        local enemyHead = v.Character:FindFirstChild("Head")
                        local enemyHumanoid = v.Character:FindFirstChild("Humanoid")
                        
                        if enemyRoot and enemyHead and enemyHumanoid and enemyHumanoid.Health > 0 then
                            if Settings.Aimbot_TeamCheck and v.Team == LocalPlayer.Team then
                                continue
                            end
                            
                            Settings.RageHack_ActiveTarget = v
                            
                            while Settings.RageHack_Enabled and enemyHumanoid.Health > 0 and myHumanoid.Health > 0 do
                                -- Dịch chuyển ra sau lưng (enemyRoot.CFrame.LookVector) và trên không (enemyHead.Position + Độ cao)
                                local backwardOffset = -enemyRoot.CFrame.LookVector * Settings.RageHack_Distance
                                local targetPosition = enemyHead.Position + Vector3.new(0, Settings.RageHack_Height, 0) + backwardOffset
                                
                                myRoot.CFrame = CFrame.new(targetPosition)
                                
                                -- Aim Camera từ trên xuống đầu địch (phong cách legacy V41)
                                Camera.CFrame = CFrame.new(Camera.CFrame.Position, enemyHead.Position)
                                
                                FireWeapon()
                                
                                task.wait(0.05)
                            end
                            
                            Settings.RageHack_ActiveTarget = nil
                        end
                    end
                end
            end
        end
    end
end)
]]

Rayfield:Notify({
    Title   = "Loaded",
    Content = "Free script nokey",
    Duration = 3
})

--// ═══════════════════════════════════════════════════════
--// ANTI-FAIL SYSTEM (UNIFIED - FIXED!)
--// ═══════════════════════════════════════════════════════
local AntiFailHooked = false

local function setupUnifiedAntiFail()
    if AntiFailHooked then return end
    
    task.spawn(function()
        local success = pcall(function()
            -- Wait for remotes
            local Remotes = ReplicatedStorage:WaitForChild("Remotes", 10)
            if not Remotes then 
                warn("⚠️ Remotes not found")
                return 
            end
            
            -- Wait for Events folder (FIXED PATH!)
            local EventsFolder = ReplicatedStorage:WaitForChild("Events", 10)
            if not EventsFolder then
                warn("⚠️ Events folder not found")
            end
            
            -- Generator remotes
            local GenRemotes = Remotes:WaitForChild("Generator", 5)
            local GenResultEvent = GenRemotes and GenRemotes:WaitForChild("SkillCheckResultEvent", 5)
            local GenFailEvent = GenRemotes and GenRemotes:FindFirstChild("SkillCheckFailEvent")
            
            -- Healing remotes (FIXED PATH: Events -> Healing)
            local Healing = EventsFolder and EventsFolder:FindFirstChild("Healing")
            local HealResultEvent = Healing and Healing:FindFirstChild("SkillCheckResultEvent")
            local HealFailEvent = Healing and Healing:FindFirstChild("SkillCheckFailEvent")
            
            -- Hook metamethod
            local oldNamecall
            oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
                local method = getnamecallmethod()
                local args = {...}
                
                -- GENERATOR ANTI-FAIL
                if GenResultEvent and VDConfig.Generator.AntiFailEnabled then
                    -- Block fail event
                    if GenFailEvent and self == GenFailEvent and method == "FireServer" then
                        return nil
                    end
                    
                    -- Force success on generator
                    if self == GenResultEvent and method == "FireServer" then
                        if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
                            args[1] = true
                            return oldNamecall(self, unpack(args))
                        else
                            return nil
                        end
                    end
                end
                
                -- HEALING ANTI-FAIL
                if HealResultEvent and VDConfig.Healing.AntiFailEnabled then
                    -- Block fail event
                    if HealFailEvent and self == HealFailEvent and method == "FireServer" then
                        return nil
                    end
                    
                    -- Force success on healing
                    if self == HealResultEvent and method == "FireServer" then
                        args[1] = true
                        return oldNamecall(self, unpack(args))
                    end
                end
                
                return oldNamecall(self, ...)
            end)
            
            AntiFailHooked = true
            print("✅ Unified Anti-Fail System hooked successfully!")
            if GenResultEvent then print("  ✅ Generator Anti-Fail ready") end
            if HealResultEvent then print("  ✅ Healing Anti-Fail ready") end
        end)
        
        if not success then
            warn("⚠️ Anti-Fail System hook failed")
        end
    end)
end

-- Initialize anti-fail system
setupUnifiedAntiFail()

--// ═══════════════════════════════════════════════════════
--// REMOVE FOG
--// ═══════════════════════════════════════════════════════
task.spawn(function()
    while true do
        if VDConfig.Visual.FullbrightEnabled then
            Lighting.Brightness = 2
            Lighting.ClockTime = 14
            Lighting.GlobalShadows = false
            Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
            
            Lighting.FogStart = 0
            Lighting.FogEnd = 100000
            
            for _, v in pairs(Lighting:GetChildren()) do
                if v:IsA("Atmosphere") then
                    v.Density = 0
                    v.Offset = 0
                    v.Glare = 0
                    v.Haze = 0
                end
                
                if v:IsA("BlurEffect") then
                    v.Size = 0
                end
                
                if v:IsA("ColorCorrectionEffect") then
                    v.Enabled = false
                end
                
                if v:IsA("SunRaysEffect") then
                    v.Enabled = false
                end
            end
        else
            Lighting.Brightness = originalLighting.Brightness
            Lighting.ClockTime = originalLighting.ClockTime
            Lighting.FogEnd = originalLighting.FogEnd
            Lighting.FogStart = originalLighting.FogStart or 0
            Lighting.GlobalShadows = originalLighting.GlobalShadows
            Lighting.OutdoorAmbient = originalLighting.OutdoorAmbient
            
            for _, v in pairs(Lighting:GetChildren()) do
                if v:IsA("Atmosphere") and originalLighting.Atmosphere then
                    v.Density = originalLighting.Atmosphere.Density or 0.3
                    v.Offset = originalLighting.Atmosphere.Offset or 0.25
                    v.Glare = originalLighting.Atmosphere.Glare or 0
                    v.Haze = originalLighting.Atmosphere.Haze or 0
                end
                
                if v:IsA("BlurEffect") and originalLighting.Blur then
                    v.Size = originalLighting.Blur.Size or 0
                end
                
                if v:IsA("ColorCorrectionEffect") and originalLighting.ColorCorrection then
                    v.Enabled = originalLighting.ColorCorrection.Enabled or false
                end
                
                if v:IsA("SunRaysEffect") and originalLighting.SunRays then
                    v.Enabled = originalLighting.SunRays.Enabled or false
                end
            end
        end
        task.wait(0.5)
    end
end)

--// ═══════════════════════════════════════════════════════
--// VAULT AURA SYSTEM (CENTRALIZED MANAGEMENT)
--// ═══════════════════════════════════════════════════════

local VAULT_CONFIG = {
    VAULT_COLOR = Color3.fromRGB(255, 255, 0),
    WORLD_COLOR = Color3.fromRGB(255, 255, 255),
    KEYWORDS = {["pallet"] = true, ["window"] = true, ["vault"] = true}
}

local TrackedObjects = {} 
local MapFolder = Workspace:FindFirstChild("Map") or Workspace:FindFirstChild("Ingame") or Workspace

local function isValidType(obj)
    if obj:IsA("BasePart") then
        return not obj:IsA("Terrain")
    elseif obj:IsA("Model") then
        return obj.PrimaryPart ~= nil
    end
    return false
end

local function shouldHighlight(obj)
    local objName = obj.Name:lower()
    if VAULT_CONFIG.KEYWORDS[objName] then return true end
    
    local parent = obj.Parent
    if parent then
        local parentName = parent.Name:lower()
        if VAULT_CONFIG.KEYWORDS[parentName] then return true end
    end
    
    return false
end

local function processObject(obj)
    if TrackedObjects[obj] then return end
    if not isValidType(obj) then return end
    if LocalPlayer.Character and obj:IsDescendantOf(LocalPlayer.Character) then return end
    
    if shouldHighlight(obj) then
        local hl = Instance.new("Highlight")
        hl.Name = "VaultAura"
        hl.FillColor = VAULT_CONFIG.VAULT_COLOR
        hl.FillTransparency = 0.8
        hl.OutlineColor = VAULT_CONFIG.VAULT_COLOR
        hl.OutlineTransparency = 0.5
        hl.OutlineThickness = 1
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        hl.Parent = obj
        
        TrackedObjects[obj] = hl
    end
end

local function setWorldColor(color)
    pcall(function()
        Lighting.Ambient = color
        Lighting.OutdoorAmbient = color
        Lighting.ColorShift_Top = color
        Lighting.ColorShift_Bottom = color
        Lighting.FogColor = color
        Lighting.FogEnd = 5000
    end)
end

local function initSystem()
    setWorldColor(VAULT_CONFIG.WORLD_COLOR)
    
    local targets = MapFolder:GetDescendants()
    for i = 1, #targets do
        processObject(targets[i])
    end
end

task.spawn(function()
    while true do
        task.wait(5)
        if VDConfig.Vault.AuraEnabled then
            for obj, hl in pairs(TrackedObjects) do
                if not obj or not obj:IsDescendantOf(Workspace) then
                    if hl then hl:Destroy() end
                    TrackedObjects[obj] = nil
                end
            end
        end
    end
end)

function VaultAuraSystem.Toggle(state)
    if state then
        initSystem()
        VaultAuraSystem.childAddedConnection = MapFolder.DescendantAdded:Connect(function(obj)
            processObject(obj)
        end)
        print("👑 [Absolute Hyper-Optimized] Centralized System Loaded Successfully!")
    else
        if VaultAuraSystem.childAddedConnection then
            VaultAuraSystem.childAddedConnection:Disconnect()
            VaultAuraSystem.childAddedConnection = nil
        end
        for obj, hl in pairs(TrackedObjects) do
            if hl then hl:Destroy() end
            TrackedObjects[obj] = nil
        end
        
        pcall(function()
            Lighting.Ambient = originalLighting.Ambient
            Lighting.ColorShift_Top = originalLighting.ColorShift_Top
            Lighting.ColorShift_Bottom = originalLighting.ColorShift_Bottom
            Lighting.FogColor = originalLighting.FogColor
            if not VDConfig.Visual.FullbrightEnabled then
                Lighting.OutdoorAmbient = originalLighting.OutdoorAmbient
                Lighting.FogEnd = originalLighting.FogEnd
            end
        end)
    end
end

--// ═══════════════════════════════════════════════════════
--// HITBOX EXPANDER (HBE) SYSTEM
--// ═══════════════════════════════════════════════════════
pcall(function()
    local mt = getrawmetatable(game)
    setreadonly(mt, false)
    local old = mt.__index
    mt.__index = function(Self, Key)
        if tostring(Self) == "HumanoidRootPart" and tostring(Key) == "Size" then
            return Vector3.new(2,2,1)
        end
        return old(Self, Key)
    end
    setreadonly(mt, true)
end)

local function GetCharParentHBE()
    local charParent
    if not LocalPlayer.Character then
        LocalPlayer.CharacterAdded:Wait()
    end
    for _, char in pairs(workspace:GetDescendants()) do
        if string.find(char.Name, LocalPlayer.Name) and char:FindFirstChild("Humanoid") then
            charParent = char.Parent
            break
        end
    end
    return charParent
end

local function AssignHitboxesHBE(player)
    if player == LocalPlayer then return end

    if HBESystem.Connections[player] then
        HBESystem.Connections[player]:Disconnect()
        HBESystem.Connections[player] = nil
    end

    local hitbox_connection
    hitbox_connection = RunService.RenderStepped:Connect(function()
        if not HBESystem.CharParent then return end

        local char = HBESystem.CharParent:FindFirstChild(player.Name)
        if VDConfig.HBE.Enabled then
            local hitboxSize = Vector3.new(VDConfig.HBE.Size, VDConfig.HBE.Size, VDConfig.HBE.Size)
            local hitboxColor = Color3.fromRGB(255,0,0)
            if char and char:FindFirstChild("HumanoidRootPart") and (char.HumanoidRootPart.Size ~= hitboxSize or char.HumanoidRootPart.Color ~= hitboxColor) then
                char.HumanoidRootPart.Size = hitboxSize
                char.HumanoidRootPart.Color = hitboxColor
                char.HumanoidRootPart.CanCollide = false
                char.HumanoidRootPart.Transparency = 0.5
            end
        else
            hitbox_connection:Disconnect()
            HBESystem.Connections[player] = nil
            if char and char:FindFirstChild("HumanoidRootPart") then
                char.HumanoidRootPart.Size = Vector3.new(2,2,1)
                char.HumanoidRootPart.Transparency = 1
            end
        end
    end)
    HBESystem.Connections[player] = hitbox_connection
end

function HBESystem.Toggle(state)
    VDConfig.HBE.Enabled = state
    
    if state then
        task.spawn(function()
            if not HBESystem.CharParent then
                HBESystem.CharParent = GetCharParentHBE()
            end
            
            if not VDConfig.HBE.Enabled then return end
            
            for _, player in ipairs(Players:GetPlayers()) do
                AssignHitboxesHBE(player)
            end
            
            if not HBESystem.PlayerAddedConn then
                HBESystem.PlayerAddedConn = Players.PlayerAdded:Connect(function(player)
                    if VDConfig.HBE.Enabled then
                        AssignHitboxesHBE(player)
                    end
                end)
            end
            if not HBESystem.PlayerRemovingConn then
                HBESystem.PlayerRemovingConn = Players.PlayerRemoving:Connect(function(player)
                    if HBESystem.Connections[player] then
                        HBESystem.Connections[player]:Disconnect()
                        HBESystem.Connections[player] = nil
                    end
                end)
            end
        end)
    else
        if HBESystem.PlayerAddedConn then
            HBESystem.PlayerAddedConn:Disconnect()
            HBESystem.PlayerAddedConn = nil
        end
        if HBESystem.PlayerRemovingConn then
            HBESystem.PlayerRemovingConn:Disconnect()
            HBESystem.PlayerRemovingConn = nil
        end
    end
end
