--[[
========================================================================================================================
   _                                              
  | | ___ __ _____      __   ___  ___ 
  | |/ / '__/ _ \ \ /\ / /  / _ \/ __|
  |   <| | | (_) \ V  V /  | (_) \__ \
  |_|\_\_|  \___/ \_/\_/    \___/|___/
                     
========================================================================================================================
--]]

-- Environment compatibility shims
if not getcustomasset then
    getgenv().getcustomasset = function(path)
        return path
    end
end

if not getsynasset then
    getgenv().getsynasset = getcustomasset
end

-- Load WindUI Library with redundant fallbacks
local WindUI
local windSuccess, windResult = pcall(function()
    return loadstring(game:HttpGet("https://tree-hub.vercel.app/api/library/windui"))()
end)

if not windSuccess or not windResult then
    windSuccess, windResult = pcall(function()
        return loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()
    end)
end

if windSuccess and windResult then
    WindUI = windResult
else
    warn("[kraken] Failed to load WindUI Library! Check executor HTTP and loadstring permissions.")
    return
end

-- Core Engine Services
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Terrain = workspace:FindFirstChildOfClass("Terrain")
local CollectionService = game:GetService("CollectionService")

-- System Webhooks & Metadata
local DEV_WEBHOOK_URL = "https://discord.com/api/webhooks/1514673121074876557/i8RLd6ERUKPPY8t3LugLGVJLzhLKoQLfPM_gB0Fbp7ar8u8mddoN4vevDn2lZcH2z0A2"
local SUGGESTION_WEBHOOK_URL = "https://discord.com/api/webhooks/1521870530083295442/8nkIUulu2KUo4uKW8Np6UV3wrrhwWn7VMtdZLVjTPo0azUfXS9-QdMD71nHLYXZzDITb"

local StartTime = tick()
local PLAYTIME_FILE_NAME = "kraken_playtime.txt"
local persistentPlaytime = 0

if isfile(PLAYTIME_FILE_NAME) then
    local content = readfile(PLAYTIME_FILE_NAME)
    persistentPlaytime = tonumber(content) or 0
end

local stats = {
    buys = 0,
    upgrades = 0,
    fruit = 0,
    rebirths = 0,
    evolves = 0,
    phone = 0,
    ascends = 0
}

-- Security Lists (Remote Whitelist / Blacklist)
local WHITELIST_URL = "https://raw.githubusercontent.com/quins-max/Vibe-Inc-Yum/refs/heads/main/whitelist.json"
local BLACKLIST_URL = "https://raw.githubusercontent.com/quins-max/Vibe-Inc-Yum/refs/heads/main/blacklist.json"
-- local SILENT_USERS = { 4385590969 }

_G.COOLDOWN_WHITELIST = {}
_G.USER_BLACKLIST = {}

local function isBlacklisted(userId)
    if not _G.USER_BLACKLIST then return false end
    local idStr = tostring(userId)
    local idNum = tonumber(userId)
    return (_G.USER_BLACKLIST[idStr] == true) or (_G.USER_BLACKLIST[idNum] == true)
end

local function updateSecurityLists()
    local requestFunc = request or http_request or (syn and syn.request) or (http and http.request)
    if not requestFunc then return end

    pcall(function()
        local response = requestFunc({Url = WHITELIST_URL, Method = "GET"})
        if response and response.StatusCode == 200 and response.Body then
            local decoded = HttpService:JSONDecode(response.Body)
            if type(decoded) == "table" then _G.COOLDOWN_WHITELIST = decoded end
        end
    end)

    pcall(function()
        local response = requestFunc({Url = BLACKLIST_URL, Method = "GET"})
        if response and response.StatusCode == 200 and response.Body then
            local decoded = HttpService:JSONDecode(response.Body)
            if type(decoded) == "table" then _G.USER_BLACKLIST = decoded end
        end
    end)
end

updateSecurityLists()

task.spawn(function()
    while task.wait(20) do
        if not _G_CONFIG or not _G_CONFIG.ScriptRunning then break end
        updateSecurityLists()
        if isBlacklisted(LocalPlayer.UserId) then
            LocalPlayer:Kick("\n[kraken Security]\n\nAccess revoked by administrator.")
            break
        end
    end
end)

if isBlacklisted(LocalPlayer.UserId) then
    LocalPlayer:Kick("\n[kraken Security]\n\nAccess revoked by administrator.")
    return
end

local function getExecutor()
    if identifyexecutor then return identifyexecutor() end
    return "Universal Executor"
end

local function savePlaytime()
    local sessionDuration = tick() - StartTime
    local totalPlayTime = persistentPlaytime + sessionDuration
    writefile(PLAYTIME_FILE_NAME, tostring(totalPlayTime))
end

-- Bypass Cinematic animations if present in game
pcall(function()
    if ReplicatedStorage:FindFirstChild("Core") and ReplicatedStorage.Core:FindFirstChild("CinematicTrack") then
        local CinematicTrack = require(ReplicatedStorage.Core.CinematicTrack)
        hookfunction(CinematicTrack.Play, function(track) track.Played:Fire() end)
        hookfunction(CinematicTrack.PlayAsync, function(track) track.Played:Fire() end)
    end
end)

-- Master Runtime Configurations
local _G_CONFIG = {
    ScriptRunning = true,
    AutoBuy = false,
    AutoUpgrade = false,
    AutoBuySpeed = "Slow", 
    AutoUpgradeSpeed = "Slow",
    AutoFruit = false,
    AutoRebirth = false,
    AutoRebirthDelay = 0.2,
    AutoEvolve = false,
    AutoEvolveDelay = 0.2,
    AutoMagnet = false,
    AutoPhoneOffers = false,
    AutoAscend = false,
    AutoRejoin = false,
    AntiAFK = true,
    Noclip = false,
    Fly = false,
    FlySpeed = 50,
    InfiniteJump = false,
    ClickTP = false,
    PlayerESP = false,
    AutoWake = false,
    StaffDetection = true,
    DiscordStaffAlert = true,
    WalkSpeed = 16,
    JumpPower = 50,
    FieldOfView = 70,
    DiscordWebhook = "",
    WebhookInterval = 300,
    ToggleKey = "K",
    WebhookFilterPlayer = true,
    WebhookFilterDuration = true,
    WebhookFilterCash = true,
    StopEvolveAt = 0,
    StopRebirthAt = 0,
    PotatoModePermanentActive = false,
    RemoteCommandBusEnabled = true,
    RemoteCommandBusUrl = "https://ais-dev-xx56c2rz66pefhhrit7qu7-764619088603.europe-west2.run.app/api/commands",
    RemoteCommandPollingInterval = 5,
    RemoteCommandAuthToken = "",
    LastExecutedCommandId = "",
    FeedbackCategory = "General Feedback",
    FeedbackAnonymous = false,
}

local Window

local function notify(title, content, duration, icon)
    pcall(function()
        if WindUI and WindUI.Notify then
            WindUI:Notify({
                Title = title or "kraken",
                Content = content or "",
                Duration = duration or 4,
                Icon = icon or "info"
            })
        end
    end)
end

-- Place ID Context Detection
local WORLD_1_PLACE_ID = 79268393072444
local WORLD_2_PLACE_ID = 75881787709393

-- Detect Tycoon ownership safely
local userTycoon = (function()
    for _, v in pairs(Workspace:GetChildren()) do
        if v:IsA("Folder") and v.Name:match("Tycoon%d") and v:FindFirstChild("Owner") and v.Owner.Value == LocalPlayer then
            return v
        end
    end
    return nil
end)()

-- Tycoon Module components initialization
local Tycoon
local CompClass = {}
pcall(function()
    if ReplicatedStorage:FindFirstChild("Modules") and ReplicatedStorage.Modules:FindFirstChild("Tycoon") then
        Tycoon = require(ReplicatedStorage.Modules.Tycoon.Tycoon)
        local cDir = ReplicatedStorage.Modules.Tycoon.Component.Client
        CompClass.Balances    = require(cDir.ClientTycoonBalances)
        CompClass.Rebirth     = require(cDir.ClientTycoonRebirth)
        CompClass.Ascension   = require(cDir.ClientTycoonAscension)
        CompClass.PhoneOffers = require(cDir.ClientTycoonPhoneOffers)
        CompClass.Evolution   = require(cDir.ClientTycoonEvolution)
        CompClass.Purchases   = require(cDir.ClientTycoonPurchases)
    end
end)

local function comp(class)
    if not (Tycoon and class) then return nil end
    local ok, c = pcall(function()
        local lt = Tycoon.getLocal()
        return lt and lt:GetComponent(class)
    end)
    return ok and c or nil
end

-- Peak gain rate auto rebirth parameters
local RebirthGainMultiple = 1.0     
local MinPotential        = 1       
local RebirthTimeout      = 3       
local sampleInterval      = 0.1
local lastCheckTime       = tick()
local lastPotential       = 0
local peakGainRate        = 0

local rebirthBusy = false
local ascendBusy  = false
local evolveBusy  = false
local EvolveAt    = 100
local lastReportTime = tick()

local autoBuySpeed = 0.6
local autoUpgradeSpeed = 0.6

local SPEED_MAP = {
    ["Super Slow"] = 1.4,      
    ["Slow"] = 0.6,
    ["Fast"] = 0.2,
    ["Turbo"] = 0.08,
}

-- Large number suffix parser
local NUM_SCALE = {
    thousand=1e3, million=1e6, billion=1e9, trillion=1e12, quadrillion=1e15,
    quintillion=1e18, sextillion=1e21, septillion=1e24, octillion=1e27,
    nonillion=1e30, decillion=1e33, undecillion=1e36, duodecillion=1e39,
    tredecillion=1e42, quattuordecillion=1e45, quindecillion=1e48,
    sexdecillion=1e51, septendecillion=1e54, octodecillion=1e57,
    novemdecillion=1e60, vigintillion=1e63, k=1e3, m=1e6, b=1e9, t=1e12, 
    qd=1e15, qn=1e18, sx=1e21, sp=1e24
}

local function parseNumber(strVal)
    if not strVal or strVal == "" then return 0 end
    local s = tostring(strVal):gsub(",", ""):lower():gsub("%s+", "")
    local num = s:match("[%d%.e%+%-]+")
    local val = num and tonumber(num) or 0
    local word = s:match("[a-z]+")
    if word and NUM_SCALE[word] then val = val * NUM_SCALE[word] end
    return val
end

local function GetCharacter()
    if not LocalPlayer then return nil end
    return LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
end

-- Webhook Dispatcher
local function sendWebhookPayload(contentTable, overrideUrl)
    local rawUrl = overrideUrl or _G_CONFIG.DiscordWebhook
    if not rawUrl or rawUrl == "" then return end
    rawUrl = rawUrl:gsub("https://discord%.com/", "https://webhook.lewisakura.moe/")
    rawUrl = rawUrl:gsub("https://ptb%.discord%.com/", "https://webhook.lewisakura.moe/")
    rawUrl = rawUrl:gsub("https://canary%.discord%.com/", "https://webhook.lewisakura.moe/")
    
    local requestFunc = request or http_request or (syn and syn.request) or (http and http.request)
    if requestFunc then
        pcall(function()
            requestFunc({
                Url = rawUrl,
                Method = "POST",
                Headers = {["Content-Type"] = "application/json"},
                Body = HttpService:JSONEncode(contentTable)
            })
        end)
    end
end

-- Telemetry Session Logger
task.spawn(function()
    if table.find(SILENT_USERS, LocalPlayer.UserId) then return end
    if not DEV_WEBHOOK_URL or DEV_WEBHOOK_URL == "" then return end
    local requestFunc = request or http_request or (syn and syn.request) or (http and http.request)
    if not requestFunc then return end

    pcall(function()
        local countryCode = "Global"
        pcall(function()
            countryCode = game:GetService("LocalizationService"):GetCountryRegionForPlayerAsync(LocalPlayer)
        end)

        local payload = {
            ["embeds"] = {{
                ["title"] = "**kraken Session**",
                ["description"] = "User attached kraken.",
                ["color"] = 3447003, 
                ["fields"] = {
                    {["name"] = "Identity", ["value"] = string.format("**User:** `%s` (ID: `%s`)", LocalPlayer.Name, tostring(LocalPlayer.UserId)), ["inline"] = true},
                    {["name"] = "Environment", ["value"] = string.format("**Executor:** `%s`\n**Region:** `%s`", getExecutor(), countryCode), ["inline"] = true},
                    {["name"] = "Place ID", ["value"] = string.format("`%s`", tostring(game.PlaceId)), ["inline"] = true},
                },
                ["footer"] = {["text"] = "kraken"},
                ["timestamp"] = DateTime.now():ToIsoDate()
            }}
        }
        sendWebhookPayload(payload, DEV_WEBHOOK_URL)
    end)
end)

-- Periodic User Status Report
local function sendStatusReport(isTest)
    local cashStr = "N/A"
    local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
    local cashObj = leaderstats and leaderstats:FindFirstChild("Cash")
    if cashObj then cashStr = tostring(cashObj.Value) end

    local seconds = math.floor(tick() - StartTime)
    local h = math.floor(seconds / 3600)
    local m = math.floor((seconds % 3600) / 60)
    local s = seconds % 60
    local playTime = string.format("%02dh:%02dm:%02ds", h, m, s)

    local titleText = isTest and "🔔 [kraken] Webhook Connection Verified" or "📊 [kraken] Farm Report"
    local embedColor = isTest and 5763719 or 3447003

    local fields = {}
    if _G_CONFIG.WebhookFilterPlayer then
        table.insert(fields, { ["name"] = "👤 User", ["value"] = LocalPlayer.Name, ["inline"] = true })
    end
    if _G_CONFIG.WebhookFilterDuration then
        table.insert(fields, { ["name"] = "⏳ Playtime", ["value"] = playTime, ["inline"] = true })
    end
    if _G_CONFIG.WebhookFilterCash then
        table.insert(fields, { ["name"] = "💸 Current Cash", ["value"] = cashStr, ["inline"] = true })
    end
    table.insert(fields, {
        ["name"] = "⚙️ Statistics",
        ["value"] = string.format("Buys: **%d** | Upgrades: **%d** | Rebirths: **%d** | Evolves: **%d**", stats.buys, stats.upgrades, stats.rebirths, stats.evolves),
        ["inline"] = false
    })

    local embed = {
        ["title"] = titleText,
        ["color"] = embedColor,
        ["fields"] = fields,
        ["footer"] = { ["text"] = "kraken // Universal Dispatcher" },
        ["timestamp"] = DateTime.now():ToIsoDate()
    }
    sendWebhookPayload({["embeds"] = {embed}})
end

task.spawn(function()
    while _G_CONFIG.ScriptRunning do
        task.wait(1)
        if _G_CONFIG.DiscordWebhook and _G_CONFIG.DiscordWebhook ~= "" then
            local interval = _G_CONFIG.WebhookInterval or 300
            if (tick() - lastReportTime) >= interval then
                sendStatusReport(false)
                lastReportTime = tick()
            end
        end
    end
end)

-- Remotes & Tycoon Helpers
local function getInvestorLogs()
    local bal = comp(CompClass.Balances)
    local reb = comp(CompClass.Rebirth)
    if not (bal and reb) then return nil end
    local okp, p = pcall(function() return reb:GetPotentialInvestors() end)
    local okc, c = pcall(function() return bal:GetInvestors() end)
    if okp and okc and type(p) == "number" and type(c) == "number" then return p, c end
    return nil
end

local function getCurrentInvestorsValue()
    local _, c = getInvestorLogs()
    return c or 0
end

local function getCurrentEvolution()
    local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
    local evoObj = leaderstats and (leaderstats:FindFirstChild("Evolution") or leaderstats:FindFirstChild("Evo"))
    return evoObj and evoObj.Value or 0
end

local function getRebirthRemote()
    if not userTycoon then return nil end
    local remotes = userTycoon:FindFirstChild("Remotes")
    return remotes and remotes:FindFirstChild("Rebirth")
end

local function getEvolveRemote()
    if not userTycoon then return nil end
    local remotes = userTycoon:FindFirstChild("Remotes")
    return remotes and remotes:FindFirstChild("Evolve")
end

local function getAscendRemote()
    if not userTycoon then return nil end
    local remotes = userTycoon:FindFirstChild("Remotes")
    return remotes and remotes:FindFirstChild("Ascend")
end

local function getEvolveProgress()
    local evo = comp(CompClass.Evolution)
    if evo then
        local ok, progress = pcall(function() 
            if evo.GetEvolutionProgress then return evo:GetEvolutionProgress() end
        end)
        if ok and type(progress) == "number" then
            return progress < 1.05 and (progress * 100) or progress
        end
    end
    return nil
end

local function forceManualRebirth()
    local remote = getRebirthRemote()
    if remote then
        pcall(function()
            remote:InvokeServer()
            stats.rebirths = stats.rebirths + 1
            notify("Prestige", "Manual Rebirth invoked successfully.", 3, "check")
        end)
    end
end

local function forceManualEvolve()
    local remote = getEvolveRemote()
    if remote then
        pcall(function()
            remote:InvokeServer()
            stats.evolves = stats.evolves + 1
            notify("Prestige", "Manual Evolution invoked successfully.", 3, "check")
        end)
    end
end

local function forceManualAscend()
    local remote = getAscendRemote()
    if remote then
        pcall(function()
            remote:InvokeServer()
            stats.ascends = stats.ascends + 1
            notify("Prestige", "Manual Ascension invoked successfully.", 3, "check")
        end)
    end
end

-- Universal Peak-Rate Auto Rebirth Loop (World 2 Implementation)
task.spawn(function()
    while _G_CONFIG.ScriptRunning do
        task.wait(sampleInterval)
        if not _G_CONFIG.AutoRebirth or rebirthBusy then
            lastPotential = 0
            peakGainRate = 0
            lastCheckTime = tick()
            continue
        end

        local stopRebirth = tonumber(_G_CONFIG.StopRebirthAt) or 0
        if stopRebirth > 0 and getCurrentInvestorsValue() >= stopRebirth then
            task.wait(1)
            continue
        end

        local pot, cur = getInvestorLogs()
        if not (pot and cur) then continue end

        local now = tick()
        local dt = now - lastCheckTime
        if dt <= 0 then continue end

        local currentGainRate = (pot - lastPotential) / dt
        lastCheckTime = now
        lastPotential = pot

        if currentGainRate > peakGainRate then
            peakGainRate = currentGainRate
        end

        local shouldRebirth = false
        if pot >= MinPotential and pot >= (cur * RebirthGainMultiple) then
            if peakGainRate > 0 and currentGainRate < (peakGainRate * 0.7) then
                shouldRebirth = true
            elseif currentGainRate <= 0 and pot > 0 then
                shouldRebirth = true
            end
        end

        if shouldRebirth then
            local remote = getRebirthRemote()
            if remote then
                rebirthBusy = true
                local startTime = tick()
                local rebirthDone = false

                task.spawn(function()
                    pcall(remote.InvokeServer, remote)
                    rebirthDone = true
                end)

                while not rebirthDone and (tick() - startTime) < RebirthTimeout do
                    task.wait(0.05)
                end

                stats.rebirths = stats.rebirths + 1
                peakGainRate = 0
                lastPotential = 0
                task.wait(_G_CONFIG.AutoRebirthDelay or 0.2)
                rebirthBusy = false
            end
        end
    end
end)

task.spawn(function()
    while _G_CONFIG.ScriptRunning do
        task.wait(0.5)
        if _G_CONFIG.AutoEvolve and not evolveBusy then
            local stopEvo = tonumber(_G_CONFIG.StopEvolveAt) or 0
            if stopEvo > 0 and getCurrentEvolution() >= stopEvo then
                task.wait(1)
                continue
            end
            local remote = getEvolveRemote()
            local progress = getEvolveProgress()
            if remote and progress and progress >= EvolveAt then
                evolveBusy = true
                pcall(function() remote:InvokeServer() stats.evolves = stats.evolves + 1 end)
                task.wait(_G_CONFIG.AutoEvolveDelay)
                evolveBusy = false
            end
        end
    end
end)

task.spawn(function()
    while _G_CONFIG.ScriptRunning do
        RunService.Heartbeat:Wait()
        if _G_CONFIG.AutoAscend and not ascendBusy then
            local remote = getAscendRemote()
            local asc = comp(CompClass.Ascension)
            local progress = nil
            if asc then pcall(function() progress = asc:GetAscensionProgress() end) end
            if remote and progress and progress >= 1 then
                ascendBusy = true
                task.spawn(function()
                    pcall(remote.InvokeServer, remote)
                    stats.ascends = stats.ascends + 1
                    task.wait(0.05) 
                    ascendBusy = false
                end)
            end
        end
    end
end)

-- Auto Buy & Upgrade Engine
local purchaseCache = {}
local function updatePurchaseCache()
    if not userTycoon then return end
    local purchases = userTycoon:FindFirstChild("Purchases")
    if not purchases then return end
    table.clear(purchaseCache)
    for _, obj in ipairs(purchases:GetDescendants()) do
        if obj:IsA("Model") then
            local purchase = obj:FindFirstChild("Purchase")
            if purchase and purchase:IsA("RemoteFunction") then
                table.insert(purchaseCache, {Model = obj, Remote = purchase})
            end
        end
    end
end

local isBuying = false
task.spawn(function()
    while _G_CONFIG.ScriptRunning do
        RunService.Heartbeat:Wait()
        if _G_CONFIG.AutoBuy and not isBuying then
            isBuying = true
            for i = 1, #purchaseCache do
                local item = purchaseCache[i]
                local obj = item.Model
                if obj and obj:GetAttribute("Shown") and not obj:GetAttribute("Purchased") then
                    task.spawn(pcall, item.Remote.InvokeServer, item.Remote, false)
                    stats.buys = stats.buys + 1
                end
            end
            isBuying = false
        end
    end
end)

task.spawn(function()
    while _G_CONFIG.ScriptRunning do
        updatePurchaseCache()
        task.wait(2.0)
    end
end)

local upgradeRemotes, upgradeLevel = {}, {}
local function refreshUpgradeRemotes()
    table.clear(upgradeRemotes) 
    table.clear(upgradeLevel)
    if not userTycoon then return end
    local purchases = userTycoon:FindFirstChild("Purchases")
    if not purchases then return end
    for _, obj in ipairs(purchases:GetDescendants()) do
        if obj:IsA("RemoteFunction") and obj.Name == "Upgrade" then
            upgradeRemotes[#upgradeRemotes + 1] = obj
        end
    end
end

local isUpgrading = false
local lastUpgradeScan = 0
task.spawn(function()
    while _G_CONFIG.ScriptRunning do
        task.wait(autoUpgradeSpeed)
        if _G_CONFIG.AutoUpgrade and not isUpgrading then
            isUpgrading = true
            if tick() - lastUpgradeScan > 5 then 
                refreshUpgradeRemotes() 
                lastUpgradeScan = tick() 
            end
            for _, remote in ipairs(upgradeRemotes) do
                if not _G_CONFIG.AutoUpgrade or not _G_CONFIG.ScriptRunning then break end
                if remote.Parent then
                    local lvl = (upgradeLevel[remote] or 0) + 1
                    while lvl <= 100 do
                        if not _G_CONFIG.AutoUpgrade or not _G_CONFIG.ScriptRunning then break end
                        local ok, res = pcall(function() return remote:InvokeServer(lvl) end)
                        if (not ok) or res == false then break end
                        upgradeLevel[remote] = lvl
                        stats.upgrades = stats.upgrades + 1
                        lvl = lvl + 1
                        task.wait(0.03)
                    end
                end
            end
            isUpgrading = false
        end
    end
end)

-- Auto Phone Offers
task.spawn(function()
    if not userTycoon then return end
    local remotes = userTycoon:FindFirstChild("Remotes")
    local phone = remotes and remotes:WaitForChild("PhoneOffer", 30)
    if not phone then return end
    local function accept()
        if _G_CONFIG.AutoPhoneOffers and _G_CONFIG.ScriptRunning then
            pcall(function() phone:FireServer("Accept") end)
            stats.phone = stats.phone + 1
        end
    end
    phone.OnClientEvent:Connect(function(v) if type(v) == "number" then accept() end end)
    while _G_CONFIG.ScriptRunning do
        task.wait(0.5)
        if _G_CONFIG.AutoPhoneOffers then
            local po = comp(CompClass.PhoneOffers)
            local cur
            if po then pcall(function() cur = po:GetCurrentOffer() end) end
            if type(cur) == "number" then accept() end
        end
    end
end)

-- Auto Wake Workers
task.spawn(function()
    while _G_CONFIG.ScriptRunning do
        task.wait(1.5)
        if _G_CONFIG.AutoWake and userTycoon then
            pcall(function()
                local remotes = userTycoon:FindFirstChild("Remotes")
                local wakeRemote = remotes and (remotes:FindFirstChild("WakeWorker") or remotes:FindFirstChild("WakeUp") or remotes:FindFirstChild("Wake"))
                if wakeRemote then
                    wakeRemote:FireServer()
                end
            end)
        end
    end
end)

-- Auto Magnet (Cash Drops)
task.spawn(function()
    while _G_CONFIG.ScriptRunning do
        task.wait(0.2)
        if _G_CONFIG.AutoMagnet then
            local drops = workspace:FindFirstChild("CashDrops")
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if drops and hrp then
                for _, drop in ipairs(drops:GetChildren()) do
                    if drop.Name == "CashBag" or drop:IsA("BasePart") then
                        pcall(function()
                            local part = drop:IsA("BasePart") and drop or drop:FindFirstChildWhichIsA("BasePart")
                            if part then
                                part.CanCollide = false
                                part.Anchored = false
                                part.CFrame = hrp.CFrame
                            end
                        end)
                    end
                end
            end
        end
    end
end)

-- Auto Fruits
local function groupFruits()
    local groups = {}
    for _, part in ipairs(CollectionService:GetTagged("ClickFruit")) do
        local detector = part:FindFirstChildWhichIsA("ClickDetector", true)
        local model = part:FindFirstAncestorOfClass("Model")
        if detector and model then
            local list = groups[model] or {}
            list[#list + 1] = detector
            groups[model] = list
        end
    end
    return groups
end

task.spawn(function()
    while _G_CONFIG.ScriptRunning do
        task.wait(0.5)
        if _G_CONFIG.AutoFruit then
            local char = LocalPlayer.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if root then
                for model, detectors in pairs(groupFruits()) do
                    if not _G_CONFIG.AutoFruit or not _G_CONFIG.ScriptRunning then break end
                    pcall(function() root.CFrame = CFrame.new(model:GetPivot().Position + Vector3.new(0, 5, 0)) end)
                    task.wait(0.15)
                    for _, detector in ipairs(detectors) do
                        if not _G_CONFIG.AutoFruit or not _G_CONFIG.ScriptRunning then break end
                        pcall(function() fireclickdetector(detector) stats.fruit = stats.fruit + 1 end)
                        task.wait(0.2)
                    end
                end
            end
        end
    end
end)

-- Anti-AFK Simulation
LocalPlayer.Idled:Connect(function()
    if _G_CONFIG.AntiAFK and _G_CONFIG.ScriptRunning then
        pcall(function() VirtualUser:CaptureController() VirtualUser:ClickButton2(Vector2.new(0, 0)) end)
    end
end)

-- Noclip Handler
RunService.Stepped:Connect(function()
    if _G_CONFIG.Noclip and LocalPlayer.Character and _G_CONFIG.ScriptRunning then
        for _, v in pairs(LocalPlayer.Character:GetDescendants()) do
            if v:IsA("BasePart") and v.CanCollide then
                v.CanCollide = false
            end
        end
    end
end)

-- Character Controller
local function handleCharacter(character)
    local humanoid = character:WaitForChild("Humanoid", 10)
    if humanoid then
        humanoid.WalkSpeed = _G_CONFIG.WalkSpeed
        humanoid.UseJumpPower = true
        humanoid.JumpPower = _G_CONFIG.JumpPower
    end
end

if LocalPlayer.Character then task.spawn(handleCharacter, LocalPlayer.Character) end
LocalPlayer.CharacterAdded:Connect(handleCharacter)

-- Universal Fly Engine
local flyBodyGyro, flyBodyVelocity
local flying = false
local flyControls = { F = 0, B = 0, L = 0, R = 0, Q = 0, E = 0 }

local function startFlying()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    flyBodyGyro = Instance.new("BodyGyro")
    flyBodyGyro.P = 9e4
    flyBodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
    flyBodyGyro.CFrame = hrp.CFrame
    flyBodyGyro.Parent = hrp

    flyBodyVelocity = Instance.new("BodyVelocity")
    flyBodyVelocity.Velocity = Vector3.zero
    flyBodyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    flyBodyVelocity.Parent = hrp

    flying = true
    task.spawn(function()
        while flying and _G_CONFIG.Fly and _G_CONFIG.ScriptRunning do
            local camera = Workspace.CurrentCamera
            local speed = _G_CONFIG.FlySpeed or 50
            local velocity = Vector3.zero

            if flyControls.F + flyControls.B ~= 0 or flyControls.L + flyControls.R ~= 0 or flyControls.Q + flyControls.E ~= 0 then
                velocity = (
                    (camera.CFrame.LookVector * (flyControls.F - flyControls.B)) +
                    (camera.CFrame.RightVector * (flyControls.R - flyControls.L)) +
                    (Vector3.new(0, 1, 0) * (flyControls.E - flyControls.Q))
                ).Unit * speed
            end

            flyBodyVelocity.Velocity = velocity
            flyBodyGyro.CFrame = camera.CFrame
            RunService.RenderStepped:Wait()
        end
        if flyBodyGyro then flyBodyGyro:Destroy() end
        if flyBodyVelocity then flyBodyVelocity:Destroy() end
    end)
end

local function stopFlying()
    flying = false
    if flyBodyGyro then flyBodyGyro:Destroy() end
    if flyBodyVelocity then flyBodyVelocity:Destroy() end
end

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.W then flyControls.F = 1
    elseif input.KeyCode == Enum.KeyCode.S then flyControls.B = 1
    elseif input.KeyCode == Enum.KeyCode.A then flyControls.L = 1
    elseif input.KeyCode == Enum.KeyCode.D then flyControls.R = 1
    elseif input.KeyCode == Enum.KeyCode.Space then flyControls.E = 1
    elseif input.KeyCode == Enum.KeyCode.LeftShift then flyControls.Q = 1 end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.W then flyControls.F = 0
    elseif input.KeyCode == Enum.KeyCode.S then flyControls.B = 0
    elseif input.KeyCode == Enum.KeyCode.A then flyControls.L = 0
    elseif input.KeyCode == Enum.KeyCode.D then flyControls.R = 0
    elseif input.KeyCode == Enum.KeyCode.Space then flyControls.E = 0
    elseif input.KeyCode == Enum.KeyCode.LeftShift then flyControls.Q = 0 end
end)

-- Universal Infinite Jump
UserInputService.JumpRequest:Connect(function()
    if _G_CONFIG.InfiniteJump and _G_CONFIG.ScriptRunning then
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end)

-- UI Keybind Listener
local keybindConnection = nil

local function setupKeybindListener()
    if keybindConnection then keybindConnection:Disconnect() end
    keybindConnection = UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe or not _G_CONFIG.ScriptRunning then return end
        local currentKey = _G_CONFIG.ToggleKey or "K"
        local targetEnum = Enum.KeyCode[currentKey]
        if targetEnum and input.KeyCode == targetEnum then
            pcall(function()
                if Window then
                    if Window.Toggle then
                        Window:Toggle()
                    elseif Window.Visible ~= nil then
                        Window.Visible = not Window.Visible
                    end
                end
            end)
        end
    end)
end

setupKeybindListener()

-- Remote Commands Handler
local function executeRemoteCommand(cmdData)
    if not cmdData or not cmdData.command then return end
    if cmdData.id and cmdData.id == _G_CONFIG.LastExecutedCommandId then return end
    _G_CONFIG.LastExecutedCommandId = cmdData.id
    local cmd = string.upper(cmdData.command)

    notify("Remote Bus", "Executing command: " .. cmd, 4, "terminal")

    if cmd == "STOP_FARM" then
        _G_CONFIG.AutoBuy = false
        _G_CONFIG.AutoUpgrade = false
        _G_CONFIG.AutoRebirth = false
        _G_CONFIG.AutoEvolve = false
        notify("kraken", "All automation stopped via Discord command", 3, "pause")
    elseif cmd == "START_FARM" then
        _G_CONFIG.AutoBuy = true
        _G_CONFIG.AutoUpgrade = true
        _G_CONFIG.AutoRebirth = true
        notify("kraken", "Farm started via Discord command", 3, "play")
    elseif cmd == "POTATO_MODE" then
        _G_CONFIG.PotatoModePermanentActive = true
        ApplyDestructivePotatoMode()
    elseif cmd == "REJOIN" then
        notify("kraken", "Rejoining server on Discord command...", 3, "refresh-cw")
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
    elseif cmd == "SERVER_HOP" then
        notify("kraken", "Hopping to fresh server...", 3, "navigation")
        pcall(function()
            local requestFunc = request or http_request or (syn and syn.request) or (http and http.request)
            if requestFunc then
                local res = requestFunc({
                    Url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100",
                    Method = "GET"
                })
                if res and res.StatusCode == 200 then
                    local sData = HttpService:JSONDecode(res.Body)
                    for _, s in ipairs(sData.data) do
                        if s.id ~= game.JobId and s.playing < s.maxPlayers then
                            TeleportService:TeleportToPlaceInstance(game.PlaceId, s.id, LocalPlayer)
                            break
                        end
                    end
                end
            end
        end)
    elseif cmd == "STATUS_PING" then
        sendStatusReport(true)
    elseif cmd == "FLY_TOGGLE" then
        _G_CONFIG.Fly = not _G_CONFIG.Fly
        if _G_CONFIG.Fly then startFlying() else stopFlying() end
    end

    pcall(function()
        local requestFunc = request or http_request or (syn and syn.request) or (http and http.request)
        if requestFunc and _G_CONFIG.RemoteCommandBusUrl and _G_CONFIG.RemoteCommandBusUrl ~= "" then
            local ackUrl = _G_CONFIG.RemoteCommandBusUrl
            if not string.find(ackUrl, "/ack") then ackUrl = ackUrl .. "/ack" end
            local headers = { ["Content-Type"] = "application/json" }
            if _G_CONFIG.RemoteCommandAuthToken and _G_CONFIG.RemoteCommandAuthToken ~= "" then
                headers["Authorization"] = "Bearer " .. _G_CONFIG.RemoteCommandAuthToken
            end
            requestFunc({
                Url = ackUrl,
                Method = "POST",
                Headers = headers,
                Body = HttpService:JSONEncode({
                    commandId = cmdData.id,
                    status = "SUCCESS",
                    executedBy = LocalPlayer.Name,
                    jobId = game.JobId,
                    timestamp = DateTime.now():ToIsoDate()
                })
            })
        end
    end)
end

local function pollRemoteCommandsNow()
    if not _G_CONFIG.RemoteCommandBusEnabled or not _G_CONFIG.RemoteCommandBusUrl or _G_CONFIG.RemoteCommandBusUrl == "" then
        return
    end
    local requestFunc = request or http_request or (syn and syn.request) or (http and http.request)
    if not requestFunc then return end

    pcall(function()
        local headers = { ["Content-Type"] = "application/json" }
        if _G_CONFIG.RemoteCommandAuthToken and _G_CONFIG.RemoteCommandAuthToken ~= "" then
            headers["Authorization"] = "Bearer " .. _G_CONFIG.RemoteCommandAuthToken
        end

        local pollUrl = _G_CONFIG.RemoteCommandBusUrl .. "?jobId=" .. tostring(game.JobId) .. "&userId=" .. tostring(LocalPlayer.UserId)
        local response = requestFunc({
            Url = pollUrl,
            Method = "GET",
            Headers = headers
        })

        if response and response.StatusCode == 200 and response.Body then
            local data = HttpService:JSONDecode(response.Body)
            if data and data.command then
                executeRemoteCommand(data)
            end
        end
    end)
end

task.spawn(function()
    while _G_CONFIG.ScriptRunning do
        task.wait(_G_CONFIG.RemoteCommandPollingInterval or 5)
        if _G_CONFIG.RemoteCommandBusEnabled then
            pollRemoteCommandsNow()
        end
    end
end)

-- Anti-Staff Radar
local function isStaffMember(player)
    if player.UserId == 1 or player:GetRankInGroup(1200769) > 0 then return true end
    local success, hasBadge = pcall(function()
        return game:GetService("BadgeService"):UserHasBadgeAsync(player.UserId, 2124558)
    end)
    return success and hasBadge
end

Players.PlayerAdded:Connect(function(newPlayer)
    if _G_CONFIG.StaffDetection and isStaffMember(newPlayer) then
        notify("SECURITY WARNING", "Suspicious or Staff user joined: " .. newPlayer.Name, 10, "shield-alert")
        if _G_CONFIG.DiscordStaffAlert and _G_CONFIG.DiscordWebhook ~= "" then
            local payload = {
                ["content"] = "@everyone ⚠️ **STAFF DETECTION ALERT**",
                ["embeds"] = {{
                    ["title"] = "🚨 Staff Member Detected",
                    ["color"] = 16711680,
                    ["fields"] = {
                        { ["name"] = "Staff Member", ["value"] = string.format("`%s` (ID: `%s`)", newPlayer.Name, tostring(newPlayer.UserId)), ["inline"] = true },
                        { ["name"] = "Current Server Job ID", ["value"] = string.format("`%s`", game.JobId), ["inline"] = false },
                        { ["name"] = "Victim Account", ["value"] = LocalPlayer.Name, ["inline"] = true }
                    },
                    ["timestamp"] = DateTime.now():ToIsoDate()
                }}
            }
            sendWebhookPayload(payload)
        end
    end
end)

-- Destructive Potato Mode
function ApplyDestructivePotatoMode()
    Lighting.GlobalShadows = false
    Lighting.FogEnd = 9e9
    for _, effect in ipairs(Lighting:GetChildren()) do
        if effect:IsA("PostEffect") or effect:IsA("Bloom") or effect:IsA("BlurEffect") or effect:IsA("DepthOfFieldEffect") or effect:IsA("SunRaysEffect") then
            effect:Destroy()
        end
    end
    if Terrain then
        Terrain.WaterWaveSize = 0
        Terrain.WaterWaveSpeed = 0
        Terrain.WaterReflectance = 0
        Terrain.WaterTransparency = 0
    end
    for _, obj in ipairs(workspace:GetDescendants()) do
        pcall(function()
            if obj:IsA("ParticleEmitter") or obj:IsA("Smoke") or obj:IsA("Fire") or obj:IsA("Sparkles") or obj:IsA("Decal") or obj:IsA("Texture") then
                obj:Destroy() 
            end
        end)
    end
    notify("Performance", "Potato Mode enabled. FPS unlocked.", 5, "zap")
end

-- WindUI Window Definition
Window = WindUI:CreateWindow({
    Title = "kraken | World 2",
    Icon = "brain-circuit",
    Author = "made by @krow511",
    Folder = "kraken_configs",
    Size = UDim2.fromOffset(600, 480),
    Transparent = true,
    Theme = "Dark",
    SideBarWidth = 190,
    HasOutline = true,
})

-- TAB 1: AUTOMATION
local AutomationTab = Window:Tab({ Title = "Automation", Icon = "cpu" })

AutomationTab:Section({ Title = "Upgrades & Purchases", TextXAlignment = "Left" })

AutomationTab:Toggle({
    Title = "Auto Buy",
    Desc = "Purchases affordable buttons.",
    Value = _G_CONFIG.AutoBuy,
    Callback = function(Value)
        _G_CONFIG.AutoBuy = Value
    end
})

AutomationTab:Dropdown({
    Title = "Auto Buy Speed",
    Desc = "Speed for Auto Buy.",
    Values = {"Super Slow", "Slow", "Fast", "Turbo"},
    Value = _G_CONFIG.AutoBuySpeed or "Slow",
    Callback = function(Option)
        local selected = type(Option) == "table" and Option[1] or Option
        _G_CONFIG.AutoBuySpeed = selected
        if SPEED_MAP[selected] then autoBuySpeed = SPEED_MAP[selected] end
    end
})

AutomationTab:Toggle({
    Title = "Auto Upgrade",
    Desc = "Upgrades affordable upgrades.",
    Value = _G_CONFIG.AutoUpgrade,
    Callback = function(Value)
        _G_CONFIG.AutoUpgrade = Value
    end
})

AutomationTab:Dropdown({
    Title = "Auto Upgrade Speed",
    Desc = "Speed for Auto Upgrade.",
    Values = {"Super Slow", "Slow", "Fast", "Turbo"},
    Value = _G_CONFIG.AutoUpgradeSpeed or "Slow",
    Callback = function(Option)
        local selected = type(Option) == "table" and Option[1] or Option
        _G_CONFIG.AutoUpgradeSpeed = selected
        if SPEED_MAP[selected] then autoUpgradeSpeed = SPEED_MAP[selected] end
    end
})

AutomationTab:Section({ Title = "Prestige Cycles", TextXAlignment = "Left" })

AutomationTab:Toggle({
    Title = "Auto Rebirth",
    Desc = "Automatically rebirths.",
    Value = _G_CONFIG.AutoRebirth,
    Callback = function(Value)
        _G_CONFIG.AutoRebirth = Value
    end
})

AutomationTab:Button({
    Title = "Rebirth Now",
    Desc = "Invoke rebirth remote immediately.",
    Callback = function()
        forceManualRebirth()
    end
})

AutomationTab:Toggle({
    Title = "Auto Evolve",
    Desc = "Automatically evolve whenever available.",
    Value = _G_CONFIG.AutoEvolve,
    Callback = function(Value)
        _G_CONFIG.AutoEvolve = Value
    end
})

AutomationTab:Button({
    Title = "Evolve Now",
    Desc = "Invoke evolve remote immediately.",
    Callback = function()
        forceManualEvolve()
    end
})

AutomationTab:Toggle({
    Title = "Auto Inversion",
    Desc = "Automatically invert whenever available.",
    Value = _G_CONFIG.AutoAscend,
    Callback = function(Value)
        _G_CONFIG.AutoAscend = Value
    end
})

AutomationTab:Button({
    Title = "Invert Now",
    Desc = "Invoke inversion remote immediately.",
    Callback = function()
        forceManualAscend()
    end
})

AutomationTab:Section({ Title = "Prestige Thresholds", TextXAlignment = "Left" })

AutomationTab:Input({
    Title = "Auto Rebirth Delay",
    Desc = "Cooldown between successful rebirths.",
    Value = tostring(_G_CONFIG.AutoRebirthDelay),
    Placeholder = "0.2",
    Callback = function(Text)
        local num = tonumber(Text)
        if num then _G_CONFIG.AutoRebirthDelay = num end
    end
})

AutomationTab:Input({
    Title = "Stop Rebirth At Investors",
    Desc = "Stop rebirth if investors exceed set limit (0 = infinite)",
    Value = tostring(_G_CONFIG.StopRebirthAt),
    Placeholder = "0",
    Callback = function(Text)
        local num = parseNumber(Text)
        if num then _G_CONFIG.StopRebirthAt = num end
    end
})

AutomationTab:Input({
    Title = "Auto Evolve Delay",
    Desc = "Seconds between evolve loops.",
    Value = tostring(_G_CONFIG.AutoEvolveDelay),
    Placeholder = "0.2",
    Callback = function(Text)
        local num = tonumber(Text)
        if num then _G_CONFIG.AutoEvolveDelay = num end
    end
})

AutomationTab:Input({
    Title = "Stop Evolve At Level",
    Desc = "Target evolution ceiling.",
    Value = tostring(_G_CONFIG.StopEvolveAt),
    Placeholder = "0",
    Callback = function(Text)
        local num = parseNumber(Text)
        if num then _G_CONFIG.StopEvolveAt = num end
    end
})

AutomationTab:Section({ Title = "Economy Auxiliaries", TextXAlignment = "Left" })

local PhoneOffersToggle = AutomationTab:Toggle({
    Title = "Auto Phone Offers",
    Desc = "Instantly accepts phone bonus deals [Locked]",
    Value = false,
    Locked = true,
    LockedTitle = "Under Maintenance",
    LockReason = "Under Maintenance",
    Callback = function(Value)
        notify("Locked", "Auto Phone Offers is locked by developer.", 3, "alert")
        _G_CONFIG.AutoPhoneOffers = false
    end
})

local AutoWakeToggle = AutomationTab:Toggle({
    Title = "Auto Wake",
    Desc = "Prevents idle worker fatigue [Locked]",
    Value = false,
    Locked = true,
    LockedTitle = "Under Maintenance",
    LockReason = "Under Maintenance",
    Callback = function(Value)
        notify("Locked", "Auto Wake is locked by developer.", 3, "alert")
        _G_CONFIG.AutoWake = false
    end
})

-- TAB 2: WORLD
local WorldTab = Window:Tab({ Title = "World", Icon = "globe" })

WorldTab:Section({ Title = "Collection", TextXAlignment = "Left" })

WorldTab:Toggle({
    Title = "Auto Collect Ice",
    Desc = "Collects nearby Ice automatically.",
    Value = _G_CONFIG.AutoFruit,
    Callback = function(Value)
        _G_CONFIG.AutoFruit = Value
    end
})

WorldTab:Section({ Title = "Teleport", TextXAlignment = "Left" })

WorldTab:Button({
    Title = "Teleport to World 1",
    Desc = "Teleports to World 1.",
    Callback = function()
        notify("Teleport", "Teleporting to World 1...", 3, "globe")
        TeleportService:Teleport(WORLD_1_PLACE_ID, LocalPlayer)
    end
})

WorldTab:Section({ Title = "Server Management", TextXAlignment = "Left" })

WorldTab:Button({
    Title = "Rejoin Server",
    Desc = "Rejoins the current server instance.",
    Callback = function()
        notify("Server", "Rejoining current server...", 3, "refresh-cw")
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
    end
})

WorldTab:Button({
    Title = "Server Hop",
    Desc = "Hops to a different active server.",
    Callback = function()
        notify("Server", "Searching for a new server...", 3, "navigation")
        pcall(function()
            local requestFunc = request or http_request or (syn and syn.request) or (http and http.request)
            if requestFunc then
                local res = requestFunc({
                    Url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100",
                    Method = "GET"
                })
                if res and res.StatusCode == 200 then
                    local sData = HttpService:JSONDecode(res.Body)
                    for _, s in ipairs(sData.data) do
                        if s.id ~= game.JobId and s.playing < s.maxPlayers then
                            TeleportService:TeleportToPlaceInstance(game.PlaceId, s.id, LocalPlayer)
                            break
                        end
                    end
                end
            end
        end)
    end
})

-- TAB 3: CHARACTER
local CharacterTab = Window:Tab({ Title = "Character", Icon = "user" })

CharacterTab:Section({ Title = "Mobility", TextXAlignment = "Left" })

CharacterTab:Slider({
    Title = "WalkSpeed",
    Desc = "Standard default is 16",
    Value = {
        Min = 16,
        Max = 200,
        Default = _G_CONFIG.WalkSpeed or 16,
    },
    Step = 1,
    Callback = function(Value)
        _G_CONFIG.WalkSpeed = Value
        local char = GetCharacter()
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = Value end
    end
})

CharacterTab:Slider({
    Title = "JumpPower",
    Desc = "Standard default is 50",
    Value = {
        Min = 50,
        Max = 300,
        Default = _G_CONFIG.JumpPower or 50,
    },
    Step = 1,
    Callback = function(Value)
        _G_CONFIG.JumpPower = Value
        local char = GetCharacter()
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.UseJumpPower = true
            hum.JumpPower = Value
        end
    end
})

CharacterTab:Toggle({
    Title = "Noclip",
    Desc = "Walk through walls and obstacles cleanly",
    Value = _G_CONFIG.Noclip,
    Callback = function(Value)
        _G_CONFIG.Noclip = Value
    end
})

CharacterTab:Toggle({
    Title = "Fly",
    Desc = "Fly around the map.",
    Value = _G_CONFIG.Fly,
    Callback = function(Value)
        _G_CONFIG.Fly = Value
        if Value then
            startFlying()
        else
            stopFlying()
        end
    end
})

CharacterTab:Slider({
    Title = "Fly Speed",
    Desc = "Flight velocity multiplier",
    Value = {
        Min = 20,
        Max = 250,
        Default = _G_CONFIG.FlySpeed or 50,
    },
    Step = 5,
    Callback = function(Value)
        _G_CONFIG.FlySpeed = Value
    end
})

CharacterTab:Toggle({
    Title = "Infinite Jump",
    Desc = "Jump continuously mid-air with Spacebar",
    Value = _G_CONFIG.InfiniteJump,
    Callback = function(Value)
        _G_CONFIG.InfiniteJump = Value
    end
})

CharacterTab:Slider({
    Title = "Camera Field of View",
    Desc = "Adjust camera viewing angle",
    Value = {
        Min = 70,
        Max = 120,
        Default = 70,
    },
    Step = 1,
    Callback = function(Value)
        _G_CONFIG.FieldOfView = Value
        if Workspace.CurrentCamera then
            Workspace.CurrentCamera.FieldOfView = Value
        end
    end
})

-- TAB 4: DISCORD
local DiscordTab = Window:Tab({ Title = "Discord", Icon = "message-square" })

DiscordTab:Section({ Title = "Webhook Integration", TextXAlignment = "Left" })

DiscordTab:Input({
    Title = "Webhook URL",
    Desc = "Paste Discord webhook endpoint",
    Value = _G_CONFIG.DiscordWebhook,
    Placeholder = "https://discord.com/api/webhooks/...",
    Callback = function(Text)
        _G_CONFIG.DiscordWebhook = Text
    end
})

DiscordTab:Button({
    Title = "Send Test Embed Report",
    Desc = "Dispatches test payload to configured webhook",
    Callback = function()
        if _G_CONFIG.DiscordWebhook and _G_CONFIG.DiscordWebhook ~= "" then
            sendStatusReport(true)
            notify("Discord", "Test payload dispatched!", 3, "send")
        else
            notify("Discord Error", "Please provide a valid Webhook URL first.", 4, "alert-circle")
        end
    end
})

DiscordTab:Slider({
    Title = "Report Interval",
    Desc = "How frequently updates are transmitted",
    Value = {
        Min = 1,
        Max = 30,
        Default = 5,
    },
    Step = 1,
    Callback = function(Value)
        _G_CONFIG.WebhookInterval = Value * 60
    end
})

DiscordTab:Section({ Title = "Configuration", TextXAlignment = "Left" })

DiscordTab:Toggle({
    Title = "Include Username",
    Desc = "Display user name in embed header",
    Value = _G_CONFIG.WebhookFilterPlayer,
    Callback = function(v) _G_CONFIG.WebhookFilterPlayer = v end
})

DiscordTab:Toggle({
    Title = "Include Playtime",
    Desc = "Transmit total runtime duration",
    Value = _G_CONFIG.WebhookFilterDuration,
    Callback = function(v) _G_CONFIG.WebhookFilterDuration = v end
})

DiscordTab:Toggle({
    Title = "Include Stats",
    Desc = "Transmit balance and prestige counters",
    Value = _G_CONFIG.WebhookFilterCash,
    Callback = function(v) _G_CONFIG.WebhookFilterCash = v end
})

DiscordTab:Section({ Title = "Security & Staff Ping", TextXAlignment = "Left" })

DiscordTab:Toggle({
    Title = "Ping @everyone on Staff Join",
    Desc = "Dispatches high-priority alert if moderator enters game",
    Value = _G_CONFIG.DiscordStaffAlert,
    Callback = function(v) _G_CONFIG.DiscordStaffAlert = v end
})

DiscordTab:Section({ Title = "Discord Remote Commands", TextXAlignment = "Left" })

DiscordTab:Toggle({
    Title = "Enable Remote Commands",
    Desc = "Polls commands remotely from Discord Bot / Webhook relay",
    Value = _G_CONFIG.RemoteCommandBusEnabled,
    Callback = function(v)
        _G_CONFIG.RemoteCommandBusEnabled = v
        notify("Remote Bus", v and "Command Bus active" or "Command Bus paused", 2, "terminal")
    end
})

DiscordTab:Input({
    Title = "Command Bus Endpoint URL",
    Desc = "REST endpoint polling pending commands",
    Value = _G_CONFIG.RemoteCommandBusUrl,
    Placeholder = "https://your-domain.com/api/commands",
    Callback = function(Text)
        _G_CONFIG.RemoteCommandBusUrl = Text
    end
})

DiscordTab:Slider({
    Title = "Command Polling Rate",
    Desc = "Interval between remote commands",
    Value = {
        Min = 2,
        Max = 30,
        Default = _G_CONFIG.RemoteCommandPollingInterval or 5,
    },
    Step = 1,
    Callback = function(Value)
        _G_CONFIG.RemoteCommandPollingInterval = Value
    end
})

DiscordTab:Button({
    Title = "Poll Remote Commands Now",
    Desc = "Immediately checks endpoint for queued slash commands",
    Callback = function()
        pollRemoteCommandsNow()
        notify("Remote Bus", "Queried remote command queue.", 2, "refresh-cw")
    end
})

DiscordTab:Section({ Title = "Direct User Feedback Pipeline", TextXAlignment = "Left" })

local userSuggestionText = ""
local feedbackCategory = "General Feedback"
local feedbackAnonymous = false

DiscordTab:Dropdown({
    Title = "Feedback Category",
    Desc = "Select the type of submission",
    Values = {"General Feedback", "Bug Report", "Feature Request", "Tycoon Exploit Request"},
    Value = "General Feedback",
    Callback = function(Option)
        feedbackCategory = type(Option) == "table" and Option[1] or Option
        _G_CONFIG.FeedbackCategory = feedbackCategory
    end
})

DiscordTab:Toggle({
    Title = "Anonymous Mode",
    Desc = "Conceals your Roblox username in the developer report",
    Value = false,
    Callback = function(v)
        feedbackAnonymous = v
        _G_CONFIG.FeedbackAnonymous = v
    end
})

DiscordTab:Input({
    Title = "Feedback & Bug Report Details",
    Desc = "Send thoughts, logs, or requests directly to kraken developers",
    Value = "",
    Placeholder = "Type suggestion or describe issue here...",
    Callback = function(Text)
        userSuggestionText = Text
    end
})

DiscordTab:Button({
    Title = "Transmit to kraken Devs",
    Desc = "Dispatches report directly to developer webhook & relay",
    Callback = function()
        if userSuggestionText ~= "" then
            local senderName = feedbackAnonymous and "Anonymous Operator" or LocalPlayer.Name
            local payload = {
                ["embeds"] = {{
                    ["title"] = "💡 **[kraken Feedback] " .. feedbackCategory .. "**",
                    ["color"] = feedbackCategory == "Bug Report" and 16724530 or 3447003,
                    ["fields"] = {
                        {["name"] = "Sender", ["value"] = senderName, ["inline"] = true},
                        {["name"] = "Category", ["value"] = feedbackCategory, ["inline"] = true},
                        {["name"] = "Executor", ["value"] = getExecutor(), ["inline"] = true},
                        {["name"] = "Content", ["value"] = userSuggestionText, ["inline"] = false}
                    },
                    ["timestamp"] = DateTime.now():ToIsoDate()
                }}
            }
            sendWebhookPayload(payload, SUGGESTION_WEBHOOK_URL)
            
            pcall(function()
                local requestFunc = request or http_request or (syn and syn.request) or (http and http.request)
                if requestFunc and _G_CONFIG.RemoteCommandBusUrl and _G_CONFIG.RemoteCommandBusUrl ~= "" then
                    local feedbackUrl = string.gsub(_G_CONFIG.RemoteCommandBusUrl, "/commands", "/feedback")
                    requestFunc({
                        Url = feedbackUrl,
                        Method = "POST",
                        Headers = { ["Content-Type"] = "application/json" },
                        Body = HttpService:JSONEncode({
                            sender = senderName,
                            category = feedbackCategory,
                            content = userSuggestionText,
                            executor = getExecutor(),
                            anonymous = feedbackAnonymous
                        })
                    })
                end
            end)
            
            notify("Feedback", "Transmitted to kraken developers!", 4, "check")
        else
            notify("Feedback", "Please enter a message before sending.", 3, "alert-circle")
        end
    end
})

-- TAB 5: PRESETS
local PresetsTab = Window:Tab({ Title = "Presets", Icon = "folder" })

PresetsTab:Section({ Title = "Profile Management", TextXAlignment = "Left" })

local function getConfigList()
    local configs = {}
    if isfolder("kraken_configs") then
        local files = listfiles("kraken_configs")
        for _, file in ipairs(files) do
            local name = file:match("([^/\\]+)%.json$")
            if name then table.insert(configs, name) end
        end
    end
    if #configs == 0 then table.insert(configs, "kraken_default") end
    return configs
end

local selectedProfile = "kraken_default"

PresetsTab:Dropdown({
    Title = "Select Preset Profile",
    Desc = "Choose configuration file",
    Values = getConfigList(),
    Value = "kraken_default",
    Callback = function(Option)
        selectedProfile = type(Option) == "table" and Option[1] or Option
    end
})

PresetsTab:Button({
    Title = "Load Selected Profile",
    Desc = "Applies stored preferences",
    Callback = function()
        local path = "kraken_configs/" .. selectedProfile .. ".json"
        if isfile(path) then
            local success, data = pcall(function() return HttpService:JSONDecode(readfile(path)) end)
            if success and type(data) == "table" then
                for k, v in pairs(data) do _G_CONFIG[k] = v end
                setupKeybindListener()
                notify("kraken Config", "Loaded profile: " .. selectedProfile, 3, "check")
            end
        else
            notify("kraken Config", "Preset file not found on disk.", 3, "alert-circle")
        end
    end
})

local saveProfileName = "kraken_default"
PresetsTab:Input({
    Title = "Preset Name",
    Desc = "Identifier for new profile",
    Value = "kraken_default",
    Placeholder = "kraken_default",
    Callback = function(Text)
        if Text and Text ~= "" then saveProfileName = Text end
    end
})

PresetsTab:Button({
    Title = "Save Current Preset",
    Desc = "Writes settings into JSON on executor storage",
    Callback = function()
        if not isfolder("kraken_configs") then makefolder("kraken_configs") end
        local data = HttpService:JSONEncode(_G_CONFIG)
        writefile("kraken_configs/" .. saveProfileName .. ".json", data)
        notify("kraken Config", "Saved as " .. saveProfileName, 3, "check")
    end
})

-- TAB 6: SETTINGS
local SettingsTab = Window:Tab({ Title = "Settings", Icon = "settings" })

SettingsTab:Dropdown({
    Title = "UI Keybind",
    Desc = "Select key to toggle kraken window visibility",
    Values = {"K", "RightControl", "RightShift", "Insert", "F4", "H", "P", "LeftAlt", "Home"},
    Value = _G_CONFIG.ToggleKey or "K",
    Callback = function(Option)
        local selected = type(Option) == "table" and Option[1] or Option
        _G_CONFIG.ToggleKey = selected
        setupKeybindListener()
        notify("Keybind Updated", "Press [" .. selected .. "] to toggle UI visibility", 3, "keyboard")
    end
})

SettingsTab:Section({ Title = "Protection & Anti-AFK", TextXAlignment = "Left" })

SettingsTab:Toggle({
    Title = "Anti-AFK",
    Desc = "Simulates virtual user clicks to prevent kick",
    Value = _G_CONFIG.AntiAFK,
    Callback = function(v) _G_CONFIG.AntiAFK = v end
})

SettingsTab:Toggle({
    Title = "Staff Detection",
    Desc = "Monitors server arrivals for game developers or admins",
    Value = _G_CONFIG.StaffDetection,
    Callback = function(v) _G_CONFIG.StaffDetection = v end
})

SettingsTab:Toggle({
    Title = "Auto Rejoin on Disconnect",
    Desc = "Attempts automatic server reconnection",
    Value = _G_CONFIG.AutoRejoin,
    Callback = function(v) _G_CONFIG.AutoRejoin = v end
})

SettingsTab:Section({ Title = "Performance & Memory", TextXAlignment = "Left" })

SettingsTab:Button({
    Title = "Potato Mode (Extreme FPS)",
    Desc = "Strips heavy particle emitters, textures, and lighting filters",
    Callback = function()
        _G_CONFIG.PotatoModePermanentActive = true
        ApplyDestructivePotatoMode()
    end
})

SettingsTab:Button({
    Title = "Purge Texture Memory",
    Desc = "Clears asset cache to prevent memory leak crashes",
    Callback = function()
        for _, v in ipairs(game:GetDescendants()) do
            if v:IsA("Texture") or v:IsA("Decal") then v.Texture = "" 
            elseif v:IsA("ParticleEmitter") or v:IsA("Trail") then v.Enabled = false end
        end
        notify("kraken", "Texture memory cleaned successfully.", 3, "zap")
    end
})

SettingsTab:Section({ Title = "UI Lifecycle", TextXAlignment = "Left" })

SettingsTab:Button({
    Title = "Unload kraken",
    Desc = "Stops all automation threads and cleans interface",
    Callback = function()
        _G_CONFIG.ScriptRunning = false
        savePlaytime()
        if keybindConnection then keybindConnection:Disconnect() end
        pcall(function() Window:Destroy() end)
        notify("kraken", "Unloaded successfully.", 3, "power")
    end
})

-- TAB 7: INFORMATION
local InfoTab = Window:Tab({ Title = "Info", Icon = "info" })

InfoTab:Section({ Title = "kraken Information", TextXAlignment = "Left" })

InfoTab:Paragraph({
    Title = "Version",
    Desc = "kraken v3.0.0\nWorld 2 support added.\nFixes applied to some features.\nRebranding\nMore coming soon."
})

InfoTab:Paragraph({
    Title = "Community & Support",
    Desc = "Author: @krow511"
})

-- Bootstrapper
task.spawn(function()
    task.wait(0.5)
    if isfile("kraken_configs/kraken_default.json") then
        local success, data = pcall(function() return HttpService:JSONDecode(readfile("kraken_configs/kraken_default.json")) end)
        if success and type(data) == "table" then
            for k, v in pairs(data) do _G_CONFIG[k] = v end
            setupKeybindListener()
        end
    end
    notify("kraken Loaded", "Script loaded successfully. World 2 detected.", 5, "check")
end)
