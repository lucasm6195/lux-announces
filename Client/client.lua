Citizen.CreateThread(function()
    while ESX.GetPlayerData().job == nil do
        Citizen.Wait(0)
    end
    PlayerData = ESX.GetPlayerData()
end)

local lastCoords = nil
local hasMarked = false

RegisterNetEvent('lux-announces:showAd')
AddEventHandler('lux-announces:showAd', function(adData)
    lastCoords = adData.coords
    hasMarked = false

    SendNUIMessage({
        type = adData.type,
        title = adData.title,
        content = adData.content,
        image = adData.image,
        coords = adData.coords,
        category = adData.category,
        gpsText = adData.gpsText or Config.Texts.Interface.GPSButtonText
    })
end)

RegisterNetEvent('lux-announces:hideAd')
AddEventHandler('lux-announces:hideAd', function()
    lastCoords = nil 
    hasMarked = false
end)

-- New event to open creation interface
RegisterNetEvent('lux-announces:openCreateInterface')
AddEventHandler('lux-announces:openCreateInterface', function(jobData)
    SetNuiFocus(true, true)
    SendNUIMessage({
        type = "openCreateInterface",
        jobData = jobData
    })
end)

RegisterNUICallback('marcarGPS', function(data, cb)
    MarkAnnouncementGPS()
    cb({})
end)

-- Callback to close creation interface
RegisterNUICallback('closeCreateInterface', function(data, cb)
    SetNuiFocus(false, false)
    cb({})
end)

-- Callback to create announcement - FIXED to send all data
RegisterNUICallback('createAnnounce', function(data, cb)
    TriggerServerEvent('lux-announces:createAnnounce', data)
    SetNuiFocus(false, false)
    cb({})
end)

function MarkAnnouncementGPS()
    if lastCoords then
        if hasMarked then
            lib.notify({
                description = Config.Texts.GPS.AlreadyMarked,
                type = 'error',
                position = 'bottom-right',
            })
            return
        end
        
        SetNewWaypoint(lastCoords.x, lastCoords.y)
        hasMarked = true
        lib.notify({
            description = Config.Texts.GPS.LocationMarked,
            type = 'success',
            position = 'bottom-right',
        })
    end
end

RegisterCommand("markGPS", function()
    MarkAnnouncementGPS()
end, false)

RegisterKeyMapping('markGPS', Config.Texts.GPS.KeyMappingDescription, 'keyboard', 'H')