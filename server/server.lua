local QBCore = exports['qb-core']:GetCoreObject()

local PlayerCooldowns = {}

RegisterNetEvent('qb-admin-itemshow:requestItems', function()
    local src = source
    
    if src == 0 then
        if Config.Debug then
            print("[admin-itemshow] Intento de solicitud desde source inválido")
        end
        return
    end
    
    if not IsPlayerAceAllowed(src, Config.AcePermissionName) then
        if Config.Debug then
            print("[admin-itemshow] Jugador " .. src .. " no tiene permiso ACE para solicitar items")
        end
        TriggerClientEvent('QBCore:Notify', src, "No tienes permisos para usar este comando", "error")
        return
    end
    
    local itemsList = {}
    local itemsCount = 0
    
    for itemName, itemData in pairs(QBCore.Shared.Items) do
        itemsCount = itemsCount + 1
        itemsList[itemsCount] = {
            name = itemName,
            label = itemData.label or itemName,
            description = itemData.description or "",
            weight = itemData.weight or 0,
            type = itemData.type or "item",
            image = itemData.image or "default.png",
            unique = itemData.unique == true,
            useable = itemData.useable or false,
            shouldClose = itemData.shouldClose or false
        }
    end
    
    if Config.Debug then
        print("[admin-itemshow] Enviando " .. #itemsList .. " items al jugador " .. src)
    end
    
    TriggerClientEvent('qb-admin-itemshow:receiveItems', src, itemsList)
end)

RegisterNetEvent('qb-admin-itemshow:tryPickup', function(itemName, quantity)
    local src = source
    
    quantity = tonumber(quantity) or 1
    if quantity < 1 then
        quantity = 1
    end
    if quantity > 9999 then
        quantity = 9999
    end
    
    if QBCore.Shared.Items[itemName] and QBCore.Shared.Items[itemName].unique == true then
        if quantity > 1 then
            if Config.Debug then
                print("[admin-itemshow] Jugador " .. src .. " intentó recoger más de 1 unidad de item único: " .. itemName)
            end
            TriggerClientEvent('QBCore:Notify', src, "Este item es único, solo puedes recibir 1 unidad", "error")
            TriggerClientEvent('qb-admin-itemshow:notifyNUI', src, "error", "Este item es único, solo puedes recibir 1 unidad")
            return
        end
        quantity = 1
    end
    
    if src == 0 then
        if Config.Debug then
            print("[admin-itemshow] Intento de recogida desde source inválido")
        end
        return
    end
    
    if not QBCore.Shared.Items[itemName] then
        if Config.Debug then
            print("[admin-itemshow] Jugador " .. src .. " intentó recoger item inexistente: " .. tostring(itemName))
        end
        TriggerClientEvent('QBCore:Notify', src, "Este item no existe", "error")
        TriggerClientEvent('qb-admin-itemshow:notifyNUI', src, "error", "Este item no existe")
        return
    end
    
    if not IsPlayerAceAllowed(src, Config.AcePermissionName) then
        if Config.Debug then
            print("[admin-itemshow] Jugador " .. src .. " no tiene permiso ACE: " .. Config.AcePermissionName)
        end
        TriggerClientEvent('QBCore:Notify', src, "No tienes permisos para usar este recurso", "error")
        TriggerClientEvent('qb-admin-itemshow:notifyNUI', src, "error", "No tienes permisos para usar este recurso")
        return
    end
    
    local currentTime = os.time()
    local lastPickup = PlayerCooldowns[src]
    
    if lastPickup and (currentTime - lastPickup) < Config.CooldownSecPerAdmin then
        local remainingTime = Config.CooldownSecPerAdmin - (currentTime - lastPickup)
        if Config.Debug then
            print("[admin-itemshow] Jugador " .. src .. " está en cooldown. Tiempo restante: " .. remainingTime .. "s")
        end
        TriggerClientEvent('QBCore:Notify', src, "Debes esperar " .. remainingTime .. " segundos antes de recoger otro item", "error")
        TriggerClientEvent('qb-admin-itemshow:notifyNUI', src, "error", "Debes esperar " .. remainingTime .. " segundos antes de recoger otro item")
        return
    end
    
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then
        if Config.Debug then
            print("[admin-itemshow] No se pudo obtener objeto Player para source: " .. src)
        end
        TriggerClientEvent('QBCore:Notify', src, "Error al obtener datos del jugador", "error")
        TriggerClientEvent('qb-admin-itemshow:notifyNUI', src, "error", "Error al obtener datos del jugador")
        return
    end
    
    local itemData = QBCore.Shared.Items[itemName]
    local itemLabel = itemData.label or itemName
    
    local success = Player.Functions.AddItem(itemName, quantity, false, {})
    
    PlayerCooldowns[src] = currentTime
    
    if success == false then
        if Config.Debug then
            print("[admin-itemshow] Error al agregar item al inventario del jugador " .. src .. " (inventario lleno?)")
        end
        TriggerClientEvent('QBCore:Notify', src, "Error: No se pudo agregar el item (inventario lleno?)", "error")
        TriggerClientEvent('qb-admin-itemshow:notifyNUI', src, "error", "Error: No se pudo agregar el item (inventario lleno?)")
        return
    end
    
    TriggerClientEvent('inventory:client:ItemBox', src, itemData, 'add')
    local quantityText = quantity > 1 and (" x" .. quantity) or ""
    TriggerClientEvent('QBCore:Notify', src, "Has recibido: " .. itemLabel .. quantityText, Config.NotificationType, Config.NotificationDuration)
    TriggerClientEvent('qb-admin-itemshow:notifyNUI', src, "success", "Has recibido: " .. itemLabel .. quantityText)
    
    local playerName = GetPlayerName(src)
    print("[admin-itemshow] " .. playerName .. " (ID: " .. src .. ") recogió el item: " .. itemName .. " (" .. itemLabel .. ") x" .. quantity)
    
    if Config.Debug then
        print("[admin-itemshow] Item entregado exitosamente a jugador " .. src)
    end
end)

AddEventHandler('playerDropped', function()
    local src = source
    if PlayerCooldowns[src] then
        PlayerCooldowns[src] = nil
        if Config.Debug then
            print("[admin-itemshow] Cooldown limpiado para jugador desconectado: " .. src)
        end
    end
end)

if Config.Debug then
    print("[admin-itemshow] Recurso iniciado correctamente")
    print("[admin-itemshow] Permiso ACE requerido: " .. Config.AcePermissionName)
    print("[admin-itemshow] Cooldown configurado: " .. Config.CooldownSecPerAdmin .. " segundos")
end
