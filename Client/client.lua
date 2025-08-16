local Framework = nil
local PlayerData = {}

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

-- Player data initialization based on framework
if Config.Framework == "esx" then
    Citizen.CreateThread(function()
        while Framework.GetPlayerData().job == nil do
            Citizen.Wait(0)
        end
        PlayerData = Framework.GetPlayerData()
    end)
    
    RegisterNetEvent('esx:playerLoaded')
    AddEventHandler('esx:playerLoaded', function(xPlayer)
        PlayerData = xPlayer
    end)
    
    RegisterNetEvent('esx:setJob')
    AddEventHandler('esx:setJob', function(job)
        PlayerData.job = job
    end)
    
elseif Config.Framework == "qbcore" then
    Citizen.CreateThread(function()
        PlayerData = Framework.Functions.GetPlayerData()
        while PlayerData == nil or PlayerData.job == nil do
            Citizen.Wait(100)
            PlayerData = Framework.Functions.GetPlayerData()
        end
    end)
    
    RegisterNetEvent('QBCore:Client:OnPlayerLoaded')
    AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
        PlayerData = Framework.Functions.GetPlayerData()
    end)
    
    RegisterNetEvent('QBCore:Client:OnJobUpdate')
    AddEventHandler('QBCore:Client:OnJobUpdate', function(JobInfo)
        PlayerData.job = JobInfo
    end)
    
elseif Config.Framework == "qbox" then
    PlayerData = exports.qbx_core:GetPlayerData()
    
    RegisterNetEvent('QBCore:Client:OnPlayerLoaded')
    AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
        PlayerData = exports.qbx_core:GetPlayerData()
    end)
    
    RegisterNetEvent('QBCore:Client:OnJobUpdate')
    AddEventHandler('QBCore:Client:OnJobUpdate', function(JobInfo)
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