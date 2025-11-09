local QBCore = exports['qb-core']:GetCoreObject()

local isMenuOpen = false
local itemsList = {}

local function OpenItemsMenu()
    if isMenuOpen then
        CloseItemsMenu()
        return
    end
    
    TriggerServerEvent('qb-admin-itemshow:requestItems')
end

local function CloseItemsMenu()
    if not isMenuOpen then
        return
    end
    
    isMenuOpen = false
    SetNuiFocus(false, false)
    
    SendNUIMessage({
        action = 'close'
    })
    
    itemsList = {}
    
    if Config.Debug then
        print("[admin-itemshow] Menú cerrado")
    end
end

RegisterNetEvent('qb-admin-itemshow:receiveItems', function(items)
    itemsList = items
    
    if Config.Debug then
        print("[admin-itemshow] Recibidos " .. #items .. " items del servidor")
    end
    
    SetNuiFocus(true, true)
    isMenuOpen = true
    
    SendNUIMessage({
        action = 'setItems',
        items = items
    })
end)

RegisterNetEvent('qb-admin-itemshow:notifyNUI', function(type, message)
    SendNUIMessage({
        action = 'notify',
        type = type,
        message = message
    })
end)

RegisterCommand('showitems', function()
    OpenItemsMenu()
end, false)

RegisterNUICallback('close', function(data, cb)
    CloseItemsMenu()
    cb('ok')
end)

RegisterNUICallback('pickup', function(data, cb)
    local itemName = data.itemName
    local quantity = data.quantity or 1
    
    if not itemName then
        if Config.Debug then
            print("[admin-itemshow] Error: itemName no proporcionado en callback")
        end
        cb('error')
        return
    end
    
    quantity = tonumber(quantity) or 1
    if quantity < 1 then
        quantity = 1
    end
    if quantity > 9999 then
        quantity = 9999
    end
    
    if Config.Debug then
        print("[admin-itemshow] Intentando recoger item: " .. itemName .. " x" .. quantity)
    end
    
    TriggerServerEvent('qb-admin-itemshow:tryPickup', itemName, quantity)
    cb('ok')
end)

CreateThread(function()
    while true do
        if isMenuOpen then
            Wait(0)
            DisableControlAction(0, 24, true)
            DisableControlAction(0, 25, true)
            DisableControlAction(0, 142, true)
            DisableControlAction(0, 106, true)
            
            if IsControlJustPressed(0, 322) then
                CloseItemsMenu()
            end
        else
            Wait(500)
        end
    end
end)

if Config.Debug then
    print("[admin-itemshow] Cliente iniciado correctamente")
    print("[admin-itemshow] Comando registrado: /showitems")
end
