
-- ==================== LOAD VICTUI LIBRARY ====================
local Vict = loadstring(game:HttpGet("https://raw.githubusercontent.com/WhoIsGenn/ui/refs/heads/main/victui.lua"))()

local isFirstLoad = true

-- ==================== CREATE MAIN WINDOW ====================
local Window = Vict:Window({
    Title        = "Victoria | Blade Ball",
    Footer       = " ",
    Color        = Color3.fromRGB(0, 170, 255),
    ["Tab Width"] = 120,
    Version      = "1.0.0",
    Icon         = "rbxassetid://96751490485303",
    Image        = "96751490485303"
})

-- ==================== SERVICES ====================
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local Stats             = game:GetService("Stats")
local UserInputService  = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local Alive   = workspace:FindFirstChild("Alive") or workspace:WaitForChild("Alive")
local Runtime = workspace.Runtime

-- ==================== GLOBALS ====================
getgenv().HitboxEnabled       = false
getgenv().HitboxSize          = 0
getgenv().AutoParryMode       = "Auto"
getgenv().HighSpeedProtection = false
getgenv().CurveHotkeyEnabled  = false
getgenv().skinChangerEnabled  = false
getgenv().swordAnimations     = nil

getgenv().DynamicHitbox = {
    Enabled      = false,
    Part         = nil,
    MinSize      = 5,
    MaxSize      = 40,
    Color        = Color3.fromRGB(255, 255, 255),
    Transparency = 0.7
}

-- ==================== STATE ====================
local revertedRemotes = {}
local Parry_Key = nil

-- ==================== SYSTEM TABLE ====================
local System = {
    __properties = {
        __autoparry_enabled           = false,
        __curve_mode                  = 1,
        __accuracy                    = 1,
        __divisor_multiplier          = 1.1,
        __parried                     = false,
        __training_parried            = false,
        __parries                     = 0,
        __first_parry_done            = false,
        __connections                 = {},
        __grab_animation              = nil,
        __tornado_time                = tick(),
        __infinity_active             = false,
        __deathslash_active           = false,
        __timehole_active             = false,
        __is_mobile                   = UserInputService.TouchEnabled and not UserInputService.MouseEnabled,
        __antidot_parried             = false,
        __triggerbot_enabled          = false,
        __triggerbot_active           = false,
        __triggerbot_working          = false,
        __play_animation              = false,
        __randomized_accuracy_enabled = false,
    },
    __config = {
        __curve_names = {'Camera', 'Random', 'Accelerated', 'Backwards', 'Slow', 'High'},
        __detections  = {
            __infinity   = false,
            __deathslash = false,
            __timehole   = false,
        }
    }
}

-- ==================== DUAL BYPASS SYSTEM ====================
local DualBypassSystem = {
    __properties = {
        __captured_data          = nil,
        __first_parry_done       = false,
        __test_bypass_enabled    = true,
        __use_virtual_input_once = true,
        __virtual_input_used     = false,
        __original_metatables    = {},
        __active_hooks           = {}
    }
}

function DualBypassSystem.isValidRemoteArgs(args)
    return #args == 7 and
        type(args[2]) == "string" and
        type(args[3]) == "number" and
        typeof(args[4]) == "CFrame" and
        type(args[5]) == "table" and
        type(args[6]) == "table" and
        type(args[7]) == "boolean"
end

function DualBypassSystem.hookRemote(remote)
    if not DualBypassSystem.__properties.__original_metatables[getrawmetatable(remote)] then
        DualBypassSystem.__properties.__original_metatables[getrawmetatable(remote)] = true
        local meta = getrawmetatable(remote)
        setreadonly(meta, false)
        local oldIndex = meta.__index
        meta.__index = function(self, key)
            if (key == "FireServer" and self:IsA("RemoteEvent")) or
               (key == "InvokeServer" and self:IsA("RemoteFunction")) then
                return function(obj, ...)
                    local args = {...}
                    if DualBypassSystem.isValidRemoteArgs(args) and not DualBypassSystem.__properties.__captured_data then
                        DualBypassSystem.__properties.__captured_data = {
                            remote = obj,
                            args   = args
                        }
                    end
                    if DualBypassSystem.isValidRemoteArgs(args) and not revertedRemotes[obj] then
                        revertedRemotes[obj] = args
                        Parry_Key = args[2]
                    end
                    return oldIndex(self, key)(obj, unpack(args))
                end
            end
            return oldIndex(self, key)
        end
        setreadonly(meta, true)
    end
end

for _, remote in pairs(ReplicatedStorage:GetChildren()) do
    if remote:IsA("RemoteEvent") or remote:IsA("RemoteFunction") then
        DualBypassSystem.hookRemote(remote)
    end
end

ReplicatedStorage.ChildAdded:Connect(function(child)
    if child:IsA("RemoteEvent") or child:IsA("RemoteFunction") then
        DualBypassSystem.hookRemote(child)
    end
end)

-- ==================== SYSTEM.ANIMATION ====================
System.animation = {}

function System.animation.play_grab_parry()
    if not System.__properties.__play_animation then return end
    local character = LocalPlayer.Character
    if not character then return end
    local humanoid = character:FindFirstChildOfClass('Humanoid')
    local animator = humanoid and humanoid:FindFirstChildOfClass('Animator')
    if not humanoid or not animator then return end
    local sword_name
    if getgenv().skinChangerEnabled then
        sword_name = getgenv().swordAnimations
    else
        sword_name = character:GetAttribute('CurrentlyEquippedSword')
    end
    if not sword_name then return end
    local sword_api = ReplicatedStorage.Shared.SwordAPI.Collection
    local parry_animation = sword_api.Default:FindFirstChild('GrabParry')
    if not parry_animation then return end
    local sword_data = ReplicatedStorage.Shared.ReplicatedInstances.Swords.GetSword:Invoke(sword_name)
    if not sword_data or not sword_data['AnimationType'] then return end
    for _, object in pairs(sword_api:GetChildren()) do
        if object.Name == sword_data['AnimationType'] then
            if object:FindFirstChild('GrabParry') or object:FindFirstChild('Grab') then
                local anim_type = object:FindFirstChild('GrabParry') and 'GrabParry' or 'Grab'
                parry_animation = object[anim_type]
            end
        end
    end
    if System.__properties.__grab_animation and System.__properties.__grab_animation.IsPlaying then
        System.__properties.__grab_animation:Stop()
    end
    System.__properties.__grab_animation = animator:LoadAnimation(parry_animation)
    System.__properties.__grab_animation.Priority = Enum.AnimationPriority.Action4
    System.__properties.__grab_animation:Play()
end

-- ==================== HELPERS ====================
local function update_divisor()
    System.__properties.__divisor_multiplier = 0.59 + (System.__properties.__accuracy - 1) * (3 / 99)
end

local function linear_predict(a, b, t) return a + (b - a) * t end

local function UpdateDynamicHitbox(ball_distance, parry_range)
    local cfg = getgenv().DynamicHitbox
    if not cfg or not cfg.Enabled then
        if cfg and cfg.Part then cfg.Part:Destroy(); cfg.Part = nil end
        return
    end
    if not cfg.Part then
        local p = Instance.new("Part")
        p.Name = "DynamicParryVisual"; p.Shape = Enum.PartType.Ball
        p.CanCollide = false; p.Anchored = true; p.CastShadow = false
        p.Material = Enum.Material.ForceField; p.Parent = workspace
        cfg.Part = p
    end
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        local t  = math.clamp((ball_distance - parry_range) / (100 - parry_range), 0, 1)
        local vs = cfg.MinSize + (cfg.MaxSize - cfg.MinSize) * t
        cfg.Part.Size         = cfg.Part.Size:Lerp(Vector3.new(vs, vs, vs), 0.2)
        cfg.Part.CFrame       = char.HumanoidRootPart.CFrame
        cfg.Part.Color        = cfg.Color
        cfg.Part.Transparency = cfg.Transparency
    end
end

-- ==================== SYSTEM.BALL ====================
System.ball = {}
function System.ball.get()
    local b = workspace:FindFirstChild("Balls"); if not b then return nil end
    for _, ball in pairs(b:GetChildren()) do
        if ball:GetAttribute("realBall") then ball.CanCollide = false; return ball end
    end
end
function System.ball.get_all()
    local t = {}; local b = workspace:FindFirstChild("Balls"); if not b then return t end
    for _, ball in pairs(b:GetChildren()) do
        if ball:GetAttribute("realBall") then ball.CanCollide = false; table.insert(t, ball) end
    end
    return t
end

-- ==================== SYSTEM.PLAYER ====================
System.player = {}
local _CE = nil; local _LC = 0
function System.player.get_closest()
    local now = tick(); if now - _LC < 0.1 then return _CE end; _LC = now
    local md = math.huge; local ce = nil
    if not Alive then return nil end
    for _, e in pairs(Alive:GetChildren()) do
        if e ~= LocalPlayer.Character and e.PrimaryPart then
            local d = LocalPlayer:DistanceFromCharacter(e.PrimaryPart.Position)
            if d < md then md = d; ce = e end
        end
    end
    _CE = ce; return ce
end
function System.player.get_closest_to_cursor()
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return nil end
    local closest = nil; local min_dot = -math.huge; local cam = workspace.CurrentCamera
    if not Alive then return nil end
    local ok, ml = pcall(function() return UserInputService:GetMouseLocation() end); if not ok then return nil end
    local ray = cam:ScreenPointToRay(ml.X, ml.Y)
    local ptr = CFrame.lookAt(ray.Origin, ray.Origin + ray.Direction)
    for _, p in pairs(Alive:GetChildren()) do
        if p == LocalPlayer.Character then continue end
        if not p:FindFirstChild("HumanoidRootPart") then continue end
        local dot = ptr.LookVector:Dot((p.HumanoidRootPart.Position - cam.CFrame.Position).Unit)
        if dot > min_dot then min_dot = dot; closest = p end
    end
    return closest
end

-- ==================== SYSTEM.CURVE ====================
System.curve = {}
function System.curve.get_cframe()
    local cam  = workspace.CurrentCamera
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not root then return cam.CFrame end
    local tp; local cl = System.player.get_closest_to_cursor()
    if cl and cl:FindFirstChild("HumanoidRootPart") then tp = cl.HumanoidRootPart end
    local tpos = tp and tp.Position or (root.Position + cam.CFrame.LookVector * 100)
    local funcs = {
        function() return cam.CFrame end,
        function()
            local dir = (tpos - root.Position).Unit; local off; local att = 0
            repeat
                off = Vector3.new(math.random(-4000,4000), math.random(-4000,4000), math.random(-4000,4000)); att += 1
            until dir:Dot((tpos + off - root.Position).Unit) < 0.95 or att > 10
            return CFrame.new(root.Position, tpos + off)
        end,
        function() return CFrame.new(root.Position, tpos + Vector3.new(0, 5, 0)) end,
        function()
            local d = (root.Position - tpos).Unit
            return CFrame.new(cam.CFrame.Position, root.Position + d * 10000 + Vector3.new(0, 1000, 0))
        end,
        function() return CFrame.new(root.Position, tpos + Vector3.new(0, -9e18, 0)) end,
        function() return CFrame.new(root.Position, tpos + Vector3.new(0,  9e18, 0)) end,
    }
    return funcs[System.__properties.__curve_mode]()
end

-- ==================== SYSTEM.PARRY (FIXED) ====================
System.parry = {}

function System.parry.execute()
    if System.__properties.__parries > 10000 or not LocalPlayer.Character then return end
    local camera = workspace.CurrentCamera
    local success, mouse = pcall(function() return UserInputService:GetMouseLocation() end)
    if not success then return end
    local is_mobile = System.__properties.__is_mobile
    local event_data = {}
    if Alive then
        for _, entity in pairs(Alive:GetChildren()) do
            if entity.PrimaryPart then
                local ok2, sp = pcall(function() return camera:WorldToScreenPoint(entity.PrimaryPart.Position) end)
                if ok2 then event_data[entity.Name] = sp end
            end
        end
    end
    local curve_cframe = System.curve.get_cframe()
    if not System.__properties.__first_parry_done and DualBypassSystem.__properties.__use_virtual_input_once
       and not DualBypassSystem.__properties.__virtual_input_used then
        for _, connection in pairs(getconnections(LocalPlayer.PlayerGui.Hotbar.Block.Activated)) do
            connection:Fire()
        end
        System.__properties.__first_parry_done = true
        DualBypassSystem.__properties.__virtual_input_used = true
        return
    end
    local final_aim_target
    if is_mobile then
        local vp = camera.ViewportSize
        final_aim_target = {vp.X / 2, vp.Y / 2}
    else
        final_aim_target = {mouse.X, mouse.Y}
    end
    for remote, original_args in pairs(revertedRemotes) do
        local modified_args = {
            original_args[1], original_args[2], original_args[3],
            curve_cframe, event_data, final_aim_target, original_args[7]
        }
        pcall(function()
            if remote:IsA('RemoteEvent') then remote:FireServer(unpack(modified_args))
            elseif remote:IsA('RemoteFunction') then remote:InvokeServer(unpack(modified_args)) end
        end)
    end
    if System.__properties.__parries > 10000 then return end
    System.__properties.__parries = System.__properties.__parries + 1
    task.delay(0.5, function()
        if System.__properties.__parries > 0 then System.__properties.__parries = System.__properties.__parries - 1 end
    end)
end

function System.parry.keypress()
    if System.__properties.__parries > 10000 or not LocalPlayer.Character then return end
    local camera = workspace.CurrentCamera
    local curve_cframe = System.curve.get_cframe()
    local event_data = {}
    if Alive then
        for _, entity in pairs(Alive:GetChildren()) do
            if entity.PrimaryPart then
                local ok2, sp = pcall(function() return camera:WorldToScreenPoint(entity.PrimaryPart.Position) end)
                if ok2 then event_data[entity.Name] = sp end
            end
        end
    end
    local is_mobile = System.__properties.__is_mobile
    local final_aim_target
    if is_mobile then
        local vp = camera.ViewportSize
        final_aim_target = {vp.X / 2, vp.Y / 2}
    else
        local ok, mouse = pcall(function() return UserInputService:GetMouseLocation() end)
        final_aim_target = ok and {mouse.X, mouse.Y} or {0, 0}
    end
    for remote, original_args in pairs(revertedRemotes) do
        local modified_args = {
            original_args[1], original_args[2], original_args[3],
            curve_cframe, event_data, final_aim_target, original_args[7]
        }
        pcall(function()
            if remote:IsA('RemoteEvent') then remote:FireServer(unpack(modified_args))
            elseif remote:IsA('RemoteFunction') then remote:InvokeServer(unpack(modified_args)) end
        end)
    end
    if System.__properties.__parries > 10000 then return end
    System.__properties.__parries = System.__properties.__parries + 1
    task.delay(0.5, function()
        if System.__properties.__parries > 0 then System.__properties.__parries = System.__properties.__parries - 1 end
    end)
end

-- ==================== TAMBAHKAN INI (YANG MISSING) ====================
function System.parry.execute_action()
    -- Mainkan animasi dulu (optional)
    if System.__properties.__play_animation and System.animation and System.animation.play_grab_parry then
        System.animation.play_grab_parry()
    end
    -- Baru execute parry
    System.parry.execute()
end

-- ==================== SYSTEM.DETECTION ====================
System.detection = {
    __ball_properties = {
        __last_warping = tick(),
        __lerp_radians = 0,
        __curving      = tick()
    }
}

function System.detection.is_curved()
    local props = System.detection.__ball_properties
    local ball  = System.ball.get(); if not ball then return false end
    local zoom  = ball:FindFirstChild("zoomies"); if not zoom then return false end
    local vel   = zoom.VectorVelocity; local spd = vel.Magnitude; if spd < 1 then return false end
    local char  = LocalPlayer.Character; if not char or not char.PrimaryPart then return false end
    local pos   = char.PrimaryPart.Position
    local dot   = (pos - ball.Position).Unit:Dot(vel.Unit)
    local ping  = Stats.Network.ServerStatsItem["Data Ping"]:GetValue() / 1000
    local dist  = (pos - ball.Position).Magnitude
    local reach = dist / spd - ping
    local dot_th = math.clamp(0.55 - ping * 0.75, -1, 0.45)
    local bdt   = 15 - math.min(dist / 1000, 15) + math.min(spd / 100, 45)
    local rad   = math.asin(math.clamp(dot, -1, 1))
    props.__lerp_radians = linear_predict(props.__lerp_radians, rad, 0.85)
    if props.__lerp_radians < 0.016 then props.__last_warping = tick() end
    if dist < bdt * 0.85 then return false end
    if (tick() - props.__last_warping) < reach / 1.4 then return true end
    if (tick() - props.__curving)     < reach / 1.1 then return true end
    return dot < dot_th
end

ReplicatedStorage.Remotes.ParrySuccessAll.OnClientEvent:Connect(function(a, b)
    local primary = LocalPlayer.Character and LocalPlayer.Character.PrimaryPart
    local ball = System.ball.get(); if not ball or not primary then return end
    local zoom = ball:FindFirstChild("zoomies"); if not zoom then return end
    local spd  = zoom.VectorVelocity.Magnitude
    local dist = (primary.Position - ball.Position).Magnitude
    local pings = Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
    local bdt  = 15 - math.min(dist / 1000, 15) + math.min(spd / 100, 40)
    if spd > 1 and (dist / spd - pings/1000) > pings/10 then bdt = math.max(bdt - 5, 15) end
    if b ~= primary and dist > bdt then System.detection.__ball_properties.__curving = tick() end
end)

-- ==================== SYSTEM.AUTOPARRY ====================
System.autoparry = {}

function System.autoparry.start()
    if System.__properties.__connections.__autoparry then
        System.__properties.__connections.__autoparry:Disconnect()
    end
    System.__properties.__connections.__autoparry = RunService.RenderStepped:Connect(function()
        if not System.__properties.__autoparry_enabled
           or not LocalPlayer.Character
           or not LocalPlayer.Character.PrimaryPart then return end

        local balls    = System.ball.get_all()
        local one_ball = System.ball.get()

        local training_ball = nil
        if workspace:FindFirstChild("TrainingBalls") then
            for _, i in pairs(workspace.TrainingBalls:GetChildren()) do
                if i:GetAttribute("realBall") then training_ball = i; break end
            end
        end

        for _, ball in pairs(balls) do
            if not ball then continue end
            local zoom = ball:FindFirstChild("zoomies"); if not zoom then continue end
            ball:GetAttributeChangedSignal("target"):Once(function()
                System.__properties.__parried = false
                System.__properties.__antidot_parried = false
            end)
            if System.__properties.__parried then continue end

            local bt   = ball:GetAttribute("target")
            local vel  = zoom.VectorVelocity
            local dist = (LocalPlayer.Character.PrimaryPart.Position - ball.Position).Magnitude
            local ping = Stats.Network.ServerStatsItem["Data Ping"]:GetValue() / 10
            local pth  = math.clamp(ping / 10, 5, 17)
            local spd  = vel.Magnitude; if spd <= 0 then continue end

            local csd = math.min(math.max(spd - 9.5, 0), 650)
            local pa  = pth + math.max(spd / ((2.5 + csd * 0.002) * System.__properties.__divisor_multiplier), 9.5)
            if getgenv().HitboxEnabled then pa = pa + (getgenv().HitboxSize or 0) end

            UpdateDynamicHitbox(dist, pa)

            local dtp = (LocalPlayer.Character.PrimaryPart.Position - ball.Position).Unit:Dot(vel.Unit)
            if bt ~= LocalPlayer.Name and dtp < 0.1 then continue end

            if getgenv().HighSpeedProtection and spd > 1500 then
                pa = pa * math.clamp(1 + (spd - 1500) / 1000, 1.5, 3.5)
            elseif spd > 2000 then pa = pa * 2.0 end

            if ball:FindFirstChild("AeroDynamicSlashVFX") then
                ball.AeroDynamicSlashVFX:Destroy(); System.__properties.__tornado_time = tick()
            end
            if Runtime:FindFirstChild("Tornado") then
                if (tick() - System.__properties.__tornado_time) < (Runtime.Tornado:GetAttribute("TornadoTime") or 1) + 0.314159 then continue end
            end
            if one_ball and one_ball:GetAttribute("target") == LocalPlayer.Name and System.detection.is_curved() then continue end
            if ball:FindFirstChild("ComboCounter") then continue end
            if LocalPlayer.Character.PrimaryPart:FindFirstChild("SingularityCape") then continue end
            if System.__config.__detections.__infinity   and System.__properties.__infinity_active   then continue end
            if System.__config.__detections.__deathslash and System.__properties.__deathslash_active then continue end
            if System.__config.__detections.__timehole   and System.__properties.__timehole_active   then continue end

            local cp = System.player.get_closest()
            if cp and not System.__properties.__antidot_parried then
                local pd = (LocalPlayer.Character.PrimaryPart.Position - cp.PrimaryPart.Position).Magnitude
                if pd <= 30 and dtp > 0.75 and bt == LocalPlayer.Name and dist <= 30 then
                    System.parry.execute_action()
                    System.__properties.__parried = true
                    System.__properties.__antidot_parried = true
                end
            end

            if bt == LocalPlayer.Name and dist <= pa then
                if getgenv().AutoParryMode == "Keypress" then
                    System.parry.keypress()
                else
                    System.parry.execute_action()
                end
                System.__properties.__parried = true
            end

            local lp = tick()
            repeat RunService.RenderStepped:Wait() until (tick() - lp) >= 1 or not System.__properties.__parried
            System.__properties.__parried = false
            System.__properties.__antidot_parried = false
        end

        if training_ball then
            local zoom = training_ball:FindFirstChild("zoomies")
            if zoom and not System.__properties.__training_parried then
                training_ball:GetAttributeChangedSignal("target"):Once(function()
                    System.__properties.__training_parried = false
                end)
                local bt   = training_ball:GetAttribute("target")
                local vel  = zoom.VectorVelocity
                local dist = LocalPlayer:DistanceFromCharacter(training_ball.Position)
                local spd  = vel.Magnitude
                local png  = Stats.Network.ServerStatsItem["Data Ping"]:GetValue() / 10
                local pth  = math.clamp(png / 10, 5, 17)
                local csd  = math.min(math.max(spd - 9.5, 0), 650)
                local pa   = pth + math.max(spd / ((2.4 + csd * 0.002) * System.__properties.__divisor_multiplier), 9.5)
                if getgenv().HitboxEnabled then pa = pa + (getgenv().HitboxSize or 0) end
                if spd > 2000 then pa = pa * 2.0 end
                UpdateDynamicHitbox(dist, pa)
                if bt == LocalPlayer.Name and dist <= pa then
                    if getgenv().AutoParryMode == "Keypress" then
                        System.parry.keypress()
                    else
                        System.parry.execute_action()
                    end
                    System.__properties.__training_parried = true
                    local lp = tick()
                    repeat RunService.RenderStepped:Wait() until (tick() - lp) >= 1 or not System.__properties.__training_parried
                    System.__properties.__training_parried = false
                end
            end
        end
    end)
end

function System.autoparry.stop()
    if System.__properties.__connections.__autoparry then
        System.__properties.__connections.__autoparry:Disconnect()
        System.__properties.__connections.__autoparry = nil
    end
end

-- ==================== EVENTS ====================
ReplicatedStorage.Remotes.DeathBall.OnClientEvent:Connect(function(c, d)
    System.__properties.__deathslash_active = d or false
end)
ReplicatedStorage.Remotes.InfinityBall.OnClientEvent:Connect(function(a, b)
    System.__properties.__infinity_active = b or false
end)

local bfolder = workspace:FindFirstChild("Balls")
if bfolder then
    bfolder.ChildAdded:Connect(function()
        System.__properties.__parried = false
        System.__properties.__antidot_parried = false
    end)
    bfolder.ChildRemoved:Connect(function()
        System.__properties.__parries = 0
        System.__properties.__parried = false
        System.__properties.__antidot_parried = false
    end)
end

update_divisor()

-- =====================================================================
-- ============================= UI ====================================
-- =====================================================================

-- ==================== TAB 1: AUTO PARRY ====================
local Tab1 = Window:AddTab({ Name = "Auto Parry", Icon = "crosshair" })

local mainSection = Tab1:AddSection("Main")

mainSection:AddToggle({
    Title   = "Auto Parry",
    Content = "Aktifkan auto parry otomatis",
    Default = false,
    Callback = function(state)
        System.__properties.__autoparry_enabled = state
        if state then
            System.autoparry.start()
        else
            System.autoparry.stop()
        end
        if not isFirstLoad then
            notif("Auto Parry: " .. (state and "Enabled" or "Disabled"), 3,
                state and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0))
        end
    end
})

mainSection:AddDropdown({
    Title   = "Parry Mode",
    Options = {"Auto", "Keypress"},
    Default = "Auto",
    Callback = function(val)
        getgenv().AutoParryMode = val
        if not isFirstLoad then
            notif("Mode: " .. val, 2, Color3.fromRGB(0, 170, 255))
        end
    end
})

mainSection:AddSlider({
    Title     = "Parry Accuracy",
    Content   = "Tinggi = parry lebih awal",
    Min       = 1,
    Max       = 100,
    Default   = 1,
    Increment = 1,
    Callback  = function(val)
        System.__properties.__accuracy = val
        update_divisor()
    end
})

mainSection:AddToggle({
    Title   = "Play Parry Animation",
    Content = "Mainkan animasi grab saat parry",
    Default = false,
    Callback = function(state)
        System.__properties.__play_animation = state
    end
})

mainSection:AddToggle({
    Title   = "Randomized Accuracy",
    Content = "Auto ubah akurasi berdasarkan ping",
    Default = false,
    Callback = function(state)
        System.__properties.__randomized_accuracy_enabled = state
        if state then
            task.spawn(function()
                while System.__properties.__randomized_accuracy_enabled do
                    task.wait(1)
                    local ping_str = Stats.Network.ServerStatsItem["Data Ping"]:GetValueString()
                    local ping = tonumber(ping_str:match("%d+")) or 0
                    if ping >= 90 then
                        System.__properties.__accuracy = 4
                    elseif ping <= 50 then
                        System.__properties.__accuracy = math.random(70, 100)
                    end
                    update_divisor()
                end
            end)
        end
        if not isFirstLoad then
            notif("Randomized Accuracy: " .. (state and "ON" or "OFF"), 2, Color3.fromRGB(0, 170, 255))
        end
    end
})

-- SECTION: Hitbox
local hitboxSection = Tab1:AddSection("Hitbox")

hitboxSection:AddToggle({
    Title   = "Hitbox Extender",
    Content = "Perbesar area parry",
    Default = false,
    Callback = function(state)
        getgenv().HitboxEnabled = state
        if not isFirstLoad then
            notif("Hitbox Extender: " .. (state and "ON" or "OFF"), 2,
                state and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0))
        end
    end
})

hitboxSection:AddSlider({
    Title     = "Hitbox Size",
    Content   = "Tambahan radius hitbox (studs)",
    Min       = 0,
    Max       = 50,
    Default   = 0,
    Increment = 1,
    Callback  = function(val)
        getgenv().HitboxSize = val
    end
})

hitboxSection:AddToggle({
    Title   = "High Speed Protection",
    Content = "Scale accuracy saat bola sangat cepat",
    Default = false,
    Callback = function(state)
        getgenv().HighSpeedProtection = state
        if not isFirstLoad then
            notif("HS Protection: " .. (state and "ON" or "OFF"), 2, Color3.fromRGB(0, 170, 255))
        end
    end
})

-- SECTION: Detections
local detectionSection = Tab1:AddSection("Detections")

detectionSection:AddToggle({
    Title   = "Ignore Infinity Ball",
    Content = "Skip parry saat Infinity Ball aktif",
    Default = false,
    Callback = function(state)
        System.__config.__detections.__infinity = state
    end
})

detectionSection:AddToggle({
    Title   = "Ignore Death Slash",
    Content = "Skip parry saat Death Slash aktif",
    Default = false,
    Callback = function(state)
        System.__config.__detections.__deathslash = state
    end
})

detectionSection:AddToggle({
    Title   = "Ignore Time Hole",
    Content = "Skip parry saat Time Hole aktif",
    Default = false,
    Callback = function(state)
        System.__config.__detections.__timehole = state
    end
})

-- ==================== TAB 2: CURVE ====================
local Tab2 = Window:AddTab({ Name = "Curve", Icon = "loop" })

local curveSection = Tab2:AddSection("Curve Mode")

curveSection:AddDropdown({
    Title   = "Curve Mode",
    Options = System.__config.__curve_names,
    Default = "Camera",
    Callback = function(val)
        for i, name in ipairs(System.__config.__curve_names) do
            if name == val then System.__properties.__curve_mode = i; break end
        end
        if not isFirstLoad then
            notif("Curve: " .. val, 2, Color3.fromRGB(0, 170, 255))
        end
    end
})

curveSection:AddParagraph({
    Title   = "Mode Info",
    Content = "Camera: arah kamera\nRandom: arah acak\nAccelerated: ke atas sedikit\nBackwards: arah balik\nSlow: bawah ekstrem\nHigh: atas ekstrem"
})

-- SECTION: Hotkey
local hotkeySection = Tab2:AddSection("Curve Hotkeys")

hotkeySection:AddToggle({
    Title   = "Enable Curve Hotkeys",
    Content = "Tekan 1-6 untuk ganti curve mode",
    Default = false,
    Callback = function(state)
        getgenv().CurveHotkeyEnabled = state
        if not isFirstLoad then
            notif("Curve Hotkeys: " .. (state and "ON" or "OFF"), 2, Color3.fromRGB(0, 170, 255))
        end
    end
})

hotkeySection:AddParagraph({
    Title   = "Hotkey Map",
    Content = "1=Camera | 2=Random | 3=Accelerated\n4=Backwards | 5=Slow | 6=High"
})

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe or not getgenv().CurveHotkeyEnabled then return end
    local keys = {
        [Enum.KeyCode.One]   = 1, [Enum.KeyCode.Two]   = 2,
        [Enum.KeyCode.Three] = 3, [Enum.KeyCode.Four]  = 4,
        [Enum.KeyCode.Five]  = 5, [Enum.KeyCode.Six]   = 6,
    }
    if keys[input.KeyCode] then
        local idx = keys[input.KeyCode]
        System.__properties.__curve_mode = idx
        notif("Curve: " .. System.__config.__curve_names[idx], 2, Color3.fromRGB(0, 170, 255))
    end
end)

-- ==================== TAB 3: VISUALS ====================
local Tab3 = Window:AddTab({ Name = "Visuals", Icon = "eyes" })

local visualSection = Tab3:AddSection("Dynamic Hitbox Visual")

visualSection:AddToggle({
    Title   = "Dynamic Hitbox",
    Content = "Tampilkan sphere hitbox di karakter",
    Default = false,
    Callback = function(state)
        getgenv().DynamicHitbox.Enabled = state
        if not state and getgenv().DynamicHitbox.Part then
            getgenv().DynamicHitbox.Part:Destroy()
            getgenv().DynamicHitbox.Part = nil
        end
        if not isFirstLoad then
            notif("Dynamic Hitbox: " .. (state and "ON" or "OFF"), 2,
                state and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0))
        end
    end
})

visualSection:AddSlider({
    Title     = "Max Size",
    Content   = "Ukuran sphere saat bola jauh",
    Min       = 5,
    Max       = 80,
    Default   = 40,
    Increment = 1,
    Callback  = function(val)
        getgenv().DynamicHitbox.MaxSize = val
    end
})

visualSection:AddSlider({
    Title     = "Min Size",
    Content   = "Ukuran sphere saat bola dekat",
    Min       = 1,
    Max       = 20,
    Default   = 5,
    Increment = 1,
    Callback  = function(val)
        getgenv().DynamicHitbox.MinSize = val
    end
})

visualSection:AddSlider({
    Title     = "Transparency",
    Content   = "0 = solid | 9 = hampir tak terlihat",
    Min       = 0,
    Max       = 9,
    Default   = 7,
    Increment = 1,
    Callback  = function(val)
        getgenv().DynamicHitbox.Transparency = val / 10
    end
})

-- ==================== TAB 4: MISC ====================
local Tab4 = Window:AddTab({ Name = "Misc", Icon = "settings" })

local miscSection = Tab4:AddSection("Controls")

miscSection:AddButton({
    Title    = "Stop All",
    Callback = function()
        System.__properties.__autoparry_enabled = false
        System.autoparry.stop()
        getgenv().DynamicHitbox.Enabled = false
        if getgenv().DynamicHitbox.Part then
            getgenv().DynamicHitbox.Part:Destroy()
            getgenv().DynamicHitbox.Part = nil
        end
        notif("Semua fitur dimatikan!", 3, Color3.fromRGB(255, 0, 0))
    end
})

-- ==================== FINAL ====================
task.delay(1, function()
    isFirstLoad = false
end)

task.delay(1.5, function()
    notif("Victoria Blade Ball loaded!", 4, Color3.fromRGB(0, 170, 255))
end)

return Window
