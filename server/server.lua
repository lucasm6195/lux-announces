
local Framework = nil

if Config.Framework == "esx" then
    Framework = exports["es_extended"]:getSharedObject()
elseif Config.Framework == "qbcore" then
    Framework = exports["qb-core"]:GetCoreObject()
elseif Config.Framework == "qbox" then
    Framework = exports.qbx_core:GetCoreObject()
else
    print("^1[lux-announces]^7 Framework not found: " .. Config.Framework)
    return
end

local function GetPlayer(playerId)
    if Config.Framework == "esx" then
        return Framework.GetPlayerFromId(playerId)
    elseif Config.Framework == "qbcore" then
        return Framework.Functions.GetPlayer(playerId)
    elseif Config.Framework == "qbox" then
        return exports.qbx_core:GetPlayer(playerId)
    end
    return nil
end

local function GetPlayerJob(player)
    if not player then return nil end
    
    if Config.Framework == "esx" then
        return player.job
    elseif Config.Framework == "qbcore" or Config.Framework == "qbox" then
        return player.PlayerData.job
    end
    return nil
end



local announces = Config.Announces
local jobsCache = {}
local lastCacheUpdate = 0

-- Function to get all available jobs from database with caching
local function getAllJobs()
    local currentTime = GetGameTimer()
    
    -- Check if cache is still valid
    if currentTime - lastCacheUpdate < (Config.JobsCacheDuration or 300000) and #jobsCache > 0 then
        return jobsCache
    end
    
    local jobs = {}
    local tableName = 'jobs'
    
    -- Get jobs from database synchronously
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
        -- Fallback: get jobs from connected players if database query fails
        print("[lux-announces] Warning: Could not fetch jobs from database, using connected players as fallback")
        
        local connectedJobs = {}
        for _, playerId in ipairs(GetPlayers()) do
            local player = GetPlayer(tonumber(playerId))
            if player then
                local job = GetPlayerJob(player)
                if job then
                    local jobName = job.name
                    local jobLabel = job.label
                    
                    if jobName ~= 'unemployed' and not connectedJobs[jobName] then
                        connectedJobs[jobName] = {
                            name = jobName,
                            label = jobLabel
                        }
                    end
                end
            end
        end
        
        for _, job in pairs(connectedJobs) do
            table.insert(jobs, job)
        end
        print(string.format("[lux-announces] Fallback: Found %d jobs from connected players", #jobs))
    end
    
    -- Sort alphabetically by label
    table.sort(jobs, function(a, b)
        return a.label < b.label
    end)
    
    -- Update cache
    jobsCache = jobs
    lastCacheUpdate = currentTime
    
    return jobs
end

-- Command to refresh jobs cache (for administrators)
RegisterCommand('refreshjobs', function(source, args)
    if source == 0 then -- Console only
        jobsCache = {}
        lastCacheUpdate = 0
        local jobs = getAllJobs()
        print(string.format("[lux-announces] Jobs cache refreshed. Found %d jobs:", #jobs))
        for _, job in ipairs(jobs) do
            print(string.format("  - %s (%s)", job.label, job.name))
        end
    end
end, true)

-- Command to list available jobs (for debugging)
RegisterCommand('listjobs', function(source, args)
    if source == 0 then -- Console only
        local jobs = getAllJobs()
        print(string.format("[lux-announces] Available jobs (%d):", #jobs))
        for _, job in ipairs(jobs) do
            print(string.format("  - %s (%s)", job.label, job.name))
        end
    end
end, true)

RegisterCommand(Config.Command, function(source, args)
    local player = GetPlayer(source)
    if not player then
        print("[lux-announces] Error: Could not get player data for source " .. source)
        return
    end
    
    local job = GetPlayerJob(player)
    if not job then
        TriggerClientEvent('ox_lib:notify', source, {
            position = 'bottom-right',
            description = Config.Texts.Notifications.NoPermission,
            type = 'error'
        })
        return
    end
    
    local jobName = job.name
    local jobGrade = job.grade
    local jobInfo = announces[jobName]

    if not jobInfo then
        TriggerClientEvent('ox_lib:notify', source, {
            position = 'bottom-right',
            description = Config.Texts.Notifications.NoPermission,
            type = 'error'
        })
        return
    end

    local minGrade = jobInfo.minGrade or 0
    if jobGrade < minGrade then
        TriggerClientEvent('ox_lib:notify', source, {
            position = 'bottom-right',
            description = Config.Texts.Notifications.InsufficientRank,
            type = 'error'
        })
        return
    end

    local availableJobs = getAllJobs()

    TriggerClientEvent('lux-announces:openCreateInterface', source, {
        jobName = jobInfo.name,
        jobImage = jobInfo.image,
        jobGrade = jobGrade,
        minGrade = minGrade,
        availableJobs = availableJobs,
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

-- Function to determine who can see the announcement
local function getTargetPlayers(source, visibility)
    local players = {}
    
    if visibility == 'all' then
        -- All players
        for _, playerId in ipairs(GetPlayers()) do
            table.insert(players, tonumber(playerId))
        end
    elseif visibility == 'job' then
        -- Only players from the same job
        local sourcePlayer = GetPlayer(source)
        local sourceJob = GetPlayerJob(sourcePlayer)
        if not sourceJob then return players end
        
        local jobName = sourceJob.name
        
        for _, playerId in ipairs(GetPlayers()) do
            local targetPlayer = GetPlayer(tonumber(playerId))
            if targetPlayer then
                local targetJob = GetPlayerJob(targetPlayer)
                if targetJob and targetJob.name == jobName then
                    table.insert(players, tonumber(playerId))
                end
            end
        end
    else
        -- Specific job
        for _, playerId in ipairs(GetPlayers()) do
            local targetPlayer = GetPlayer(tonumber(playerId))
            if targetPlayer then
                local targetJob = GetPlayerJob(targetPlayer)
                if targetJob and targetJob.name == visibility then
                    table.insert(players, tonumber(playerId))
                end
            end
        end
    end
    
    return players
end

-- Function to get category information
local function getCategoryInfo(categoryData)
    if categoryData and categoryData.id == "custom" then
        return categoryData
    end
    return nil
end

-- Event to create announcement from interface
RegisterNetEvent('lux-announces:createAnnounce')
AddEventHandler('lux-announces:createAnnounce', function(data)
    local source = source
    local player = GetPlayer(source)
    
    if not player then
        print("[lux-announces] Error: Could not get player data for source " .. source)
        return
    end
    
    local job = GetPlayerJob(player)
    if not job then
        TriggerClientEvent('ox_lib:notify', source, {
            position = 'bottom-right',
            description = Config.Texts.Notifications.NoPermission,
            type = 'error'
        })
        return
    end
    
    local content = data.content or data
    local duration = data.duration or Config.DefaultDuration
    local visibility = data.visibility or 'all'
    local category = data.category
    
    if not content or content == "" then
        TriggerClientEvent('ox_lib:notify', source, {
            position = 'bottom-right',
            description = Config.Texts.Notifications.NoContent,
            type = 'error'
        })
        return
    end

    local jobName = job.name
    local jobInfo = announces[jobName]

    if not jobInfo then
        TriggerClientEvent('ox_lib:notify', source, {
            position = 'bottom-right',
            description = Config.Texts.Notifications.NoPermission,
            type = 'error'
        })
        return
    end

    local playerCoords = GetEntityCoords(GetPlayerPed(source))
    local adData = {
        type = "anuncio",
        title = jobInfo.name,
        content = content,
        image = jobInfo.image,
        duration = duration,
        coords = { x = playerCoords.x, y = playerCoords.y, z = playerCoords.z },
        gpsText = Config.Texts.Interface.GPSButtonText
    }

    -- Add category if it exists and is enabled
    if Config.EnableCategories and category then
        local categoryInfo = getCategoryInfo(category)
        if categoryInfo then
            adData.category = categoryInfo
        end
    end

    -- Get target players according to visibility
    local targetPlayers = getTargetPlayers(source, visibility)
    
    -- Send announcement only to target players
    for _, playerId in ipairs(targetPlayers) do
        TriggerClientEvent('lux-announces:showAd', playerId, adData)
    end

    -- Confirmation message with visibility and category information
    local visibilityMessage = Config.Texts.Notifications.VisibilityAll
    local categoryMessage = ''
    
    if visibility == 'job' then
        visibilityMessage = Config.Texts.Notifications.VisibilityJob
    elseif visibility ~= 'all' then
        -- Search for the specific job label
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
    
    TriggerClientEvent('ox_lib:notify', source, {
        position = 'bottom-right',
        description = string.format(Config.Texts.Notifications.PublishSuccess, categoryMessage, visibilityMessage),
        type = 'success'
    })
end)

-- Command to filter announcements by category (for future implementations)
RegisterCommand('filterannounce', function(source, args)
    local categoryId = args[1]
    
    if not categoryId then
        TriggerClientEvent('ox_lib:notify', source, {
            position = 'bottom-right',
            description = Config.Texts.Notifications.FilterUsage,
            type = 'info'
        })
        return
    end
    
    local categoryInfo = getCategoryInfo(categoryId)
    if not categoryInfo then
        TriggerClientEvent('ox_lib:notify', source, {
            position = 'bottom-right',
            description = Config.Texts.Notifications.CategoryNotFound,
            type = 'error'
        })
        return
    end
    
    -- Here you can implement the filtering logic
    TriggerClientEvent('ox_lib:notify', source, {
        position = 'bottom-right',
        description = string.format(Config.Texts.Notifications.FilterApplied, categoryInfo.name),
        type = 'success'
    })
end, false)

-- Initialize jobs cache on resource start
Citizen.CreateThread(function()
    Citizen.Wait(5000) -- Wait 5 seconds for database to be ready
    getAllJobs()
end)