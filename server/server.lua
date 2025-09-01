local announces = Config.Announces
local jobsCache = {}
local lastCacheUpdate = 0
local ESX = nil
local QBCore = nil

if Config.Framework == 'esx' then
    ESX = exports['es_extended']:getSharedObject()
elseif Config.Framework == 'qbcore' then
    QBCore = exports['qb-core']:GetCoreObject()
end

local function getPlayerData(source)
    if Config.Framework == 'esx' then
        return ESX.GetPlayerFromId(source)
    elseif Config.Framework == 'qbcore' then
        return QBCore.Functions.GetPlayer(source)
    end
end

local function getPlayerJob(playerData)
    if Config.Framework == 'esx' then
        return playerData.job.name, playerData.job.grade, playerData.job.label
    elseif Config.Framework == 'qbcore' then
        return playerData.PlayerData.job.name, playerData.PlayerData.job.grade.level, playerData.PlayerData.job.label
    end
end

local function sendNotification(source, message, type)
    if Config.Framework == 'esx' then
        TriggerClientEvent('ox_lib:notify', source, {
            position = 'bottom-right',
            description = message,
            type = type
        })
    elseif Config.Framework == 'qbcore' then
        TriggerClientEvent('QBCore:Notify', source, message, type)
    end
end

local function getAllJobs()
    local currentTime = GetGameTimer()
    
    if currentTime - lastCacheUpdate < (Config.JobsCacheDuration or 300000) and #jobsCache > 0 then
        return jobsCache
    end
    
    local jobs = {}
    local tableName = Config.JobsTableName or 'jobs'
    
    local success, dbJobs = pcall(function()
        return MySQL.Sync.fetchAll('SELECT name, label FROM ' .. tableName .. ' WHERE name != ?', {'unemployed'})
    end)
    
    if success and dbJobs then
        for _, row in ipairs(dbJobs) do
            table.insert(jobs, {
                name = row.name,
                label = row.label
            })
        end
        print(string.format("^5[^7DATABASE^5]^7 Loaded ^2%d^7 jobs from database", #jobs))
    else
        print("Warning: Could not fetch jobs from database, using connected players as fallback")
        
        local connectedJobs = {}
        for _, playerId in ipairs(GetPlayers()) do
            local playerData = getPlayerData(tonumber(playerId))
            if playerData then
                local jobName, jobGrade, jobLabel = getPlayerJob(playerData)
                
                if jobName ~= 'unemployed' and not connectedJobs[jobName] then
                    connectedJobs[jobName] = {
                        name = jobName,
                        label = jobLabel
                    }
                end
            end
        end
        
        for _, job in pairs(connectedJobs) do
            table.insert(jobs, job)
        end
        print(string.format("Fallback: Found %d jobs from connected players", #jobs))
    end
    
    table.sort(jobs, function(a, b)
        return a.label < b.label
    end)
    
    jobsCache = jobs
    lastCacheUpdate = currentTime
    
    return jobs
end

RegisterCommand('refreshjobs', function(source, args)
    if source == 0 then
        jobsCache = {}
        lastCacheUpdate = 0
        local jobs = getAllJobs()
        print(string.format("[lux-announces] Jobs cache refreshed. Found %d jobs:", #jobs))
        for _, job in ipairs(jobs) do
            print(string.format("  - %s (%s)", job.label, job.name))
        end
    end
end, true)

RegisterCommand('listjobs', function(source, args)
    if source == 0 then
        local jobs = getAllJobs()
        print(string.format("[lux-announces] Available jobs (%d):", #jobs))
        for _, job in ipairs(jobs) do
            print(string.format("  - %s (%s)", job.label, job.name))
        end
    end
end, true)

RegisterCommand(Config.Command, function(source, args)
    local playerData = getPlayerData(source)
    if not playerData then return end
    
    local jobName, jobGrade, jobLabel = getPlayerJob(playerData)
    local jobInfo = announces[jobName]

    if not jobInfo then
        sendNotification(source, Config.Texts.Notifications.NoPermission, 'error')
        return
    end

    local minGrade = jobInfo.minGrade or 0
    if jobGrade < minGrade then
        sendNotification(source, Config.Texts.Notifications.InsufficientRank, 'error')
        return
    end

    local availableJobs = getAllJobs()

    TriggerClientEvent('lux-announces:openCreateInterface', source, {
        jobName = jobInfo.name,
        jobImage = jobInfo.image,
        jobGrade = jobGrade,
        minGrade = minGrade,
        availableJobs = availableJobs,
        shareLocation = jobInfo.shareLocation or false,
        canModifyLocation = jobInfo.canModifyLocation or false,
        config = {
            enableCategories = Config.EnableCategories,
            enableDurationSelection = Config.EnableDurationSelection,
            enableVisibilitySelection = Config.EnableVisibilitySelection,
            defaultDuration = Config.DefaultDuration,
            durationOptions = Config.DurationOptions,
            texts = Config.Texts
        }
    })
end, false)

local function getTargetPlayers(source, visibility)
    local players = {}
    
    if visibility == 'all' then
        for _, playerId in ipairs(GetPlayers()) do
            table.insert(players, tonumber(playerId))
        end
    elseif visibility == 'job' then
        local sourcePlayerData = getPlayerData(source)
        local sourceJobName = getPlayerJob(sourcePlayerData)
        
        for _, playerId in ipairs(GetPlayers()) do
            local targetPlayerData = getPlayerData(tonumber(playerId))
            if targetPlayerData then
                local targetJobName = getPlayerJob(targetPlayerData)
                if targetJobName == sourceJobName then
                    table.insert(players, tonumber(playerId))
                end
            end
        end
    else
        for _, playerId in ipairs(GetPlayers()) do
            local targetPlayerData = getPlayerData(tonumber(playerId))
            if targetPlayerData then
                local targetJobName = getPlayerJob(targetPlayerData)
                if targetJobName == visibility then
                    table.insert(players, tonumber(playerId))
                end
            end
        end
    end
    
    return players
end

local function getCategoryInfo(categoryData)
    if categoryData and categoryData.id == "custom" then
        return categoryData
    end
    return nil
end

RegisterNetEvent('lux-announces:createAnnounce')
AddEventHandler('lux-announces:createAnnounce', function(data)
    local source = source
    local playerData = getPlayerData(source)
    
    local content = data.content or data
    local duration = data.duration or Config.DefaultDuration
    local visibility = data.visibility or 'all'
    local category = data.category
    
    if not content or content == "" then
        sendNotification(source, Config.Texts.Notifications.NoContent, 'error')
        return
    end

    local jobName = getPlayerJob(playerData)
    local jobInfo = announces[jobName]

    if not jobInfo then
        sendNotification(source, Config.Texts.Notifications.NoPermission, 'error')
        return
    end

    local playerCoords = GetEntityCoords(GetPlayerPed(source))
    local adData = {
        type = "anuncio",
        title = jobInfo.name,
        content = content,
        image = jobInfo.image,
        duration = duration,
		shareLocation = jobInfo.shareLocation or false,
        coords = { x = playerCoords.x, y = playerCoords.y, z = playerCoords.z },
        gpsText = Config.Texts.Interface.GPSButtonText
    }

    if Config.EnableCategories and category then
        local categoryInfo = getCategoryInfo(category)
        if categoryInfo then
            adData.category = categoryInfo
        end
    end

    local targetPlayers = getTargetPlayers(source, visibility)
    
    for _, playerId in ipairs(targetPlayers) do
        TriggerClientEvent('lux-announces:showAd', playerId, adData)
    end

    local visibilityMessage = Config.Texts.Notifications.VisibilityAll
    local categoryMessage = ''
    
    if visibility == 'job' then
        visibilityMessage = Config.Texts.Notifications.VisibilityJob
    elseif visibility ~= 'all' then
        local allJobs = getAllJobs()
        for _, job in ipairs(allJobs) do
            if job.name == visibility then
                visibilityMessage = job.label
                break
            end
        end
    end
    
    if Config.EnableCategories and category then
        categoryMessage = string.format(Config.Texts.Notifications.PublishSuccessWithCategory, category.name)
    end
    
    sendNotification(source, string.format(Config.Texts.Notifications.PublishSuccess, categoryMessage, visibilityMessage), 'success')
end)

RegisterCommand('filterannounce', function(source, args)
    local categoryId = args[1]
    
    if not categoryId then
        sendNotification(source, Config.Texts.Notifications.FilterUsage, 'info')
        return
    end
    
    local categoryInfo = getCategoryInfo(categoryId)
    if not categoryInfo then
        sendNotification(source, Config.Texts.Notifications.CategoryNotFound, 'error')
        return
    end
    
    sendNotification(source, string.format(Config.Texts.Notifications.FilterApplied, categoryInfo.name), 'success')
end, false)

Citizen.CreateThread(function()
    Citizen.Wait(5000)
    getAllJobs()
end)