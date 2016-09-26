function CDOTAPlayer:StartBuilding( unit, duration, cost )

    local start_time = GameRules:GetGameTime()
    local time = start_time
    local hold_duration = 0
    local spent = 0
    local category = GetUnitKV(unit, "Category", 1)
    local menu_table_name = "menu_" .. category .. "_" .. self:GetPlayerID()
    local menu_table = CustomNetTables:GetTableValue("player_tables", menu_table_name)

    if not menu_table[unit] then return end
    if self:CategoryHasBuildingInProgress(category) then return end

    menu_table[unit]['cancelled'] = 0
    CustomNetTables:SetTableValue("player_tables", menu_table_name, menu_table)

    Timers:CreateTimer(function()

        local prev_time = time
        time = GameRules:GetGameTime()
        local elapsed = time - prev_time
        menu_table = CustomNetTables:GetTableValue("player_tables", menu_table_name)
        local paused = menu_table[unit]['paused'] ~= 0
        if menu_table[unit]['cancelled'] == 1 then
            return self:CancelBuilding(unit, spent)
        end
        if time >= (start_time + duration + hold_duration) then
        	menu_table[unit]['progress'] = 1
            CustomNetTables:SetTableValue("player_tables", menu_table_name, menu_table)
            PlayerResource:SpendGold(self:GetPlayerID(), cost - spent, DOTA_ModifyGold_GameTick)
            CustomGameEventManager:Send_ServerToPlayer(self, "building_done", { unit = unit })
            return nil
        end
        local ratio = elapsed / duration
        local gold_tick = ratio * cost
        if gold_tick - math.floor(gold_tick) < 0.5 then
            gold_tick = math.floor(gold_tick)
        else
            gold_tick = math.ceil(gold_tick)
        end
        local enough_gold = PlayerResource:GetGold(self:GetPlayerID()) >= gold_tick
        if enough_gold and not paused then
            PlayerResource:SpendGold(self:GetPlayerID(), gold_tick, DOTA_ModifyGold_GameTick)
            spent = spent + gold_tick
        else
            hold_duration = hold_duration + elapsed
        end
        menu_table[unit]['progress'] = (time - (start_time + hold_duration)) / duration
        CustomNetTables:SetTableValue("player_tables", menu_table_name, menu_table)

        return 0.05

    end)

end

function CDOTAPlayer:CancelBuilding( unit, spent )

	local category = GetUnitKV(unit, "Category", 1)
	local menu_table_name = "menu_" .. category .. "_" .. self:GetPlayerID()
    local menu_table = CustomNetTables:GetTableValue("player_tables", menu_table_name)

    menu_table[unit] = {
        progress = 0,
        paused = 0,
        cancelled = 0
    }
    CustomNetTables:SetTableValue("player_tables", menu_table_name, menu_table)
    PlayerResource:SpendGold(self:GetPlayerID(), -spent, DOTA_ModifyGold_GameTick)

    BuildingHelper:CancelCommand({ PlayerID = self:GetPlayerID() })

    return nil

end

function CDOTAPlayer:CategoryHasBuildingInProgress( category )

	local menu_table_name = "menu_" .. category .. "_" .. self:GetPlayerID()
    local menu_table = CustomNetTables:GetTableValue("player_tables", menu_table_name)

    for name, building in pairs(menu_table) do 
        if building['progress'] > 0 then return true end
    end

    return false

end