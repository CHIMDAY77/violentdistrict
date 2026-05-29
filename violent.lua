repeat wait() until game:IsLoaded() and game.Players.LocalPlayer

-- ── SERVICES ──────────────────────────────────────────────────────────────
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace        = game:GetService("Workspace")
local Camera           = workspace.CurrentCamera
local LocalPlayer      = Players.LocalPlayer
local Mouse            = LocalPlayer:GetMouse()

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