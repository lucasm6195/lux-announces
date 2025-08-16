local ESX = nil
local QBCore = nil
local PlayerData = {}

if Config.Framework == 'esx' then
    ESX = exports['es_extended']:getSharedObject()
    
    Citizen.CreateThread(function()
        while ESX.GetPlayerData().job == nil do
            Citizen.Wait(0)
        end
        PlayerData = ESX.GetPlayerData()
    end)
elseif Config.Framework == 'qbcore' then
    QBCore = exports['qb-core']:GetCoreObject()
    
    RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
        PlayerData = QBCore.Functions.GetPlayerData()
    end)
    
    RegisterNetEvent('QBCore:Client:OnJobUpdate', function(JobInfo)
        PlayerData.job = JobInfo
    end)
end

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

RegisterNUICallback('closeCreateInterface', function(data, cb)
    SetNuiFocus(false, false)
    cb({})
end)

RegisterNUICallback('createAnnounce', function(data, cb)
    TriggerServerEvent('lux-announces:createAnnounce', data)
    SetNuiFocus(false, false)
    cb({})
end)

function MarkAnnouncementGPS()
    if lastCoords then
        if hasMarked then
            if Config.Framework == 'esx' then
                lib.notify({
                    description = Config.Texts.GPS.AlreadyMarked,
                    type = 'error',
                    position = 'bottom-right',
                })
            elseif Config.Framework == 'qbcore' then
                QBCore.Functions.Notify(Config.Texts.GPS.AlreadyMarked, 'error')
            end
            return
        end
        
        SetNewWaypoint(lastCoords.x, lastCoords.y)
        hasMarked = true
        
        if Config.Framework == 'esx' then
            lib.notify({
                description = Config.Texts.GPS.LocationMarked,
                type = 'success',
                position = 'bottom-right',
            })
        elseif Config.Framework == 'qbcore' then
            QBCore.Functions.Notify(Config.Texts.GPS.LocationMarked, 'success')
        end
    end
end

RegisterCommand("markGPS", function()
    MarkAnnouncementGPS()
end, false)

RegisterKeyMapping('markGPS', Config.Texts.GPS.KeyMappingDescription, 'keyboard', 'H')