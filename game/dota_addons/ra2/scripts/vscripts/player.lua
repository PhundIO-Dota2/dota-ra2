require('libraries/keyvalues')

function CDOTAPlayer:Init()

    local pid = self:GetPlayerID()

    self.menu = {
        structure = {},
        defense = {},
        infantry = {},
        vehicle = {},
        naval = {},
        airforce = {}
    }
    for category, values in pairs(self.menu) do
        CustomNetTables:SetTableValue("player_tables", "menu_" .. category .. "_" .. pid, self.menu[category])
    end

    self.queue = {
        infantry = {},
        vehicle = {},
        naval = {},
        airforce = {}
    }
    CustomNetTables:SetTableValue("player_tables", "queue_" .. pid, self.queue)

end

function CDOTAPlayer:OnProductionRequest( unit )

    local pid = self:GetPlayerID()
    local category = GetUnitKV(unit, "Category", 1)
    local menu_table_name = "menu_" .. category .. "_" .. pid
    -- local menu_table = CustomNetTables:GetTableValue("player_tables", menu_table_name)
    local menu_table = self.menu[category]

    if not menu_table[unit] or not self:HasRequiredBuildings(unit) then return end

    if (category == "infantry" or category == "vehicle") and self:CategoryHasProductionInProgress(category) then
        self:AddUnitToQueue(category, unit)
        return
    end

    -- If the unit is not in production and is not already queued
    if menu_table[unit]['progress'] == 0 and not self:HasUnitQueued(category, unit) then
        self:StartProduction(unit)
    -- If the production is finished and it's a building, then start building placement
    elseif menu_table[unit]['progress'] == 1 and (category == "structure" or category == "defense") then
        self:StartBuildingPlacement(unit)
    end

end

function CDOTAPlayer:OnProductionPaused( unit )

    local pid = self:GetPlayerID()
    local category = GetUnitKV(unit, "Category", 1)
    local menu_table_name = "menu_" .. category .. "_" .. pid
    -- local menu_table = CustomNetTables:GetTableValue("player_tables", menu_table_name)
    local menu_table = self.menu[category]

    if not menu_table[unit] then return end

    -- Checks if the production is actually in progress (0 means not started, 1 means finished)
    if menu_table[unit]['progress'] > 0 and menu_table[unit]['progress'] < 1 then
        menu_table[unit]['paused'] = true
        self.menu[category] = menu_table
        CustomNetTables:SetTableValue("player_tables", menu_table_name, menu_table)
    end

end

function CDOTAPlayer:OnProductionResumed( unit )

    local pid = self:GetPlayerID()
    local category = GetUnitKV(unit, "Category", 1)
    local menu_table_name = "menu_" .. category .. "_" .. pid
    local menu_table = self.menu[category]

    if not menu_table[unit] then return end

    menu_table[unit]['paused'] = false
    self.menu[category] = menu_table
    CustomNetTables:SetTableValue("player_tables", menu_table_name, menu_table)

end

function CDOTAPlayer:OnProductionCancelled( unit )

    local pid = self:GetPlayerID()
    local cost = GetUnitKV(unit, "BuildCost", 1)
    local category = GetUnitKV(unit, "Category", 1)
    local menu_table = self.menu[category]

    if not menu_table[unit] then return end

    if category == "infantry" and self:HasUnitQueued(category, unit) then
        self:RemoveUnitFromQueue(category, unit)
        return
    end

    if menu_table[unit]['progress'] >= 1 then
        self:CancelProduction(unit, cost)
    elseif menu_table[unit]['progress'] > 0 then
        local menu_table_name = "menu_" .. category .. "_" .. pid

        menu_table[unit]['cancelled'] = 1
        self.menu[category] = menu_table
        CustomNetTables:SetTableValue("player_tables", menu_table_name, menu_table)
    end

end

function CDOTAPlayer:StartBuildingPlacement( unit )

    local hero = self:GetAssignedHero()
    local buildAbility = hero:FindAbilityByName('build_' .. unit)

    if not buildAbility then 
        buildAbility = hero:AddAbility('build_' .. unit)
    end
    hero:CastAbilityImmediately(buildAbility, self:GetPlayerID())

end

function CDOTAPlayer:StartProduction( unit )

    local duration = GetUnitKV(unit, "MenuBuildTime", 1)
    local cost = GetUnitKV(unit, "BuildCost", 1)
    local start_time = GameRules:GetGameTime()
    local time = start_time
    local hold_duration = 0
    local spent = 0
    local category = GetUnitKV(unit, "Category", 1)
    local menu_table_name = "menu_" .. category .. "_" .. self:GetPlayerID()
    local menu_table = self.menu[category]

    if not menu_table[unit] then return end
    if self:CategoryHasProductionInProgress(category) then return end

    menu_table[unit]["cancelled"] = 0
    self.menu[category] = menu_table
    CustomNetTables:SetTableValue("player_tables", menu_table_name, menu_table)

    Timers:CreateTimer(function()

        local prev_time = time
        time = GameRules:GetGameTime()
        local elapsed = time - prev_time
        menu_table = CustomNetTables:GetTableValue("player_tables", menu_table_name)
        local paused = menu_table[unit]["paused"] ~= 0
        if menu_table[unit]["cancelled"] == 1 then
            return self:CancelProduction(unit, spent)
        end
        if time >= (start_time + duration + hold_duration) then
            if category == "infantry" or category == "vehicle" then
                menu_table[unit]["progress"] = 0
                self.menu[category] = menu_table
                self:SpawnUnit(unit, category)
            else
                menu_table[unit]["progress"] = 1
            end
            self.menu[category] = menu_table
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
        menu_table[unit]["progress"] = (time - (start_time + hold_duration)) / duration
        self.menu[category] = menu_table
        CustomNetTables:SetTableValue("player_tables", menu_table_name, menu_table)

        return 0.05

    end)

end

function CDOTAPlayer:CancelProduction( unit, spent )

	local category = GetUnitKV(unit, "Category", 1)
	local menu_table_name = "menu_" .. category .. "_" .. self:GetPlayerID()
    -- local menu_table = CustomNetTables:GetTableValue("player_tables", menu_table_name)
    local menu_table = self.menu[category]

    menu_table[unit] = {
        progress = 0,
        paused = 0,
        cancelled = 0
    }
    self.menu[category] = menu_table
    CustomNetTables:SetTableValue("player_tables", menu_table_name, menu_table)
    PlayerResource:SpendGold(self:GetPlayerID(), -spent, DOTA_ModifyGold_GameTick)

    BuildingHelper:CancelCommand({ PlayerID = self:GetPlayerID() })

    return nil

end

function CDOTAPlayer:OnBuildingPlaced( building )

    self:UnlockUnits(building)
    self:ResetProductionState(building)

end

function CDOTAPlayer:UnlockUnits( unit )

    local units = KeyValues.UnitKV

    for unit, kv in pairs(units) do
        if kv["Category"] and self:HasRequiredBuildings(unit) then
            local category = kv["Category"]
            local menu_table_name = "menu_" .. category .. "_" .. self:GetPlayerID()
            local menu_table = self.menu[category]
            self.menu[category][unit] = {
                progress = 0, 
                paused = 0, 
                cancelled = 0 
            }
            CustomNetTables:SetTableValue("player_tables", menu_table_name, self.menu[category])
        end
    end


end

function CDOTAPlayer:ResetProductionState( unit )

    local category = GetUnitKV(unit, "Category", 1)
    if not category then return end
    local menu_table_name = "menu_" .. category .. "_" .. self:GetPlayerID()
    local menu_table = self.menu[category]

    if menu_table[unit] then
        menu_table[unit]['progress'] = 0
        self.menu[category] = menu_table
        CustomNetTables:SetTableValue("player_tables", menu_table_name, menu_table)
    end

end

function CDOTAPlayer:CategoryHasProductionInProgress( category )

    local menu_table = self.menu[category]

    for name, building in pairs(menu_table) do 
        if building["progress"] > 0 then return true end
    end

    return false

end

function CDOTAPlayer:SpawnUnit( unit, category )
    
    local buildings = BuildingHelper:GetBuildings(self:GetPlayerID())

    for key, building in pairs(buildings) do
        local production = GetUnitKV(building:GetUnitName(), "Produces", 1)
        if production == category then
            local trainAbility = building:FindAbilityByName("train_" .. unit)
            if not trainAbility then
                trainAbility = building:AddAbility("train_" .. unit)
            end
            building:CastAbilityImmediately(trainAbility, self:GetPlayerID())
            self:AdvanceQueue(category)
            break
        end
    end

end

function CDOTAPlayer:HasRequiredBuildings( unit )

    local buildings = BuildingHelper:GetBuildings(self:GetPlayerID())
    local i = 1
    local requiredUnit = GetUnitKV(unit, "Requirement" .. i, 1)
    local result = true

    while requiredUnit do
        local found = false
        for key, building in pairs(buildings) do
            if building:GetUnitName() == requiredUnit then
                found = true
                break
            end
        end
        result = result and found
        i = i + 1
        requiredUnit = GetUnitKV(unit, "Requirement" .. i, 1)
    end

    return result

end

function CDOTAPlayer:AdvanceQueue( category )

    local queue = self.queue[category]
    local next_unit = queue[1]

    table.remove(queue, 1)
    CustomNetTables:SetTableValue("player_tables", "queue_" .. self:GetPlayerID(), self.queue)
    if next_unit then
        local build_time = GetUnitKV(next_unit, "MenuBuildTime", 1)
        local cost = GetUnitKV(next_unit, "BuildCost", 1)
        self:StartProduction(next_unit, build_time, cost)
    end

end

function CDOTAPlayer:HasUnitQueued( category, unit )

    local queue = self.queue[category]

    if not queue or #queue == 0 then return false end

    for key, value in pairs(queue) do
        if value == unit then
            return true
        end
    end

    return false

end

function CDOTAPlayer:AddUnitToQueue( category, unit )
    
    local queue = self.queue[category]

    table.insert(self.queue[category], unit)
    CustomNetTables:SetTableValue("player_tables", "queue_" .. self:GetPlayerID(), self.queue)

end

function CDOTAPlayer:RemoveUnitFromQueue( category, unit )

    local queue = self.queue[category]

    if not queue then return end

    for k, v in pairs(queue) do
        if v == unit then
            table.remove(self.queue[category], k)
            break
        end
    end
    CustomNetTables:SetTableValue("player_tables", "queue_" .. self:GetPlayerID(), self.queue)

end