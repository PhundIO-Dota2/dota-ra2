require("libraries/keyvalues")
require("team_colors")

local PRODUCTION_TIME_MULTIPLIER = 0
local PRODUCTION_COST_MULTIPLIER = 0
local CHEAT_UNLOCK_ALL = true

function CDOTAPlayer:Init()

    local pid = self:GetPlayerID()

    self.power = 0

    self.unitCategories = {
        airforce = true,
        infantry = true, 
        naval = true, 
        vehicle = true
    }
    self.menu = {
        airforce = {},
        defense = {},
        infantry = {},
        naval = {},
        structure = {},
        vehicle = {}
    }
    for category, values in pairs(self.menu) do
        CustomNetTables:SetTableValue("player_tables", "menu_" .. category .. "_" .. pid, self.menu[category])
    end

    self.queue = {
        airforce = {},
        infantry = {},
        naval = {},
        vehicle = {}
    }
    CustomNetTables:SetTableValue("player_tables", "queue_" .. pid, self.queue)

    CustomNetTables:SetTableValue("player_tables", "power_" .. pid, { value = self.power })

    ListenToGameEvent("npc_spawned", Dynamic_Wrap(CDOTAPlayer, "OnNPCSpawned"), self)
    ListenToGameEvent("entity_killed", Dynamic_Wrap(CDOTAPlayer, "OnEntityKilled"), self)

    self.unitCount = 0

end

function CDOTAPlayer:ConsumePower( power )

    if not power then return end

    self.power = self.power + power
    CustomNetTables:SetTableValue("player_tables", "power_" .. self:GetPlayerID(), { value = self.power })    

end

function CDOTAPlayer:OnNPCSpawned( keys )

    local npc = EntIndexToHScript(keys.entindex)

    if npc:IsRealHero() then
        Timers:CreateTimer(function() 
            local ability = npc:FindAbilityByName("spawn_soviet_mcv")
            ability:UpgradeAbility(true)
            ability = npc:FindAbilityByName("hide_hero")
            ability:UpgradeAbility(true)
            npc:SetAbilityPoints(0)
            npc:AddNoDraw()
        end)
    end

end

function CDOTAPlayer:OnEntityKilled( keys )

    local entityKilled = EntIndexToHScript(keys.entindex_killed)
    local teamID = entityKilled:GetTeam()

    if entityKilled:GetClassname() == "npc_dota_creature" and teamID == self:GetTeam() then
        -- self.unitCount = self.unitCount - 1
    end
    if self.unitCount <= 0 then
        GameRules:MakeTeamLose(self:GetTeam())
    end

end

function CDOTAPlayer:OnProductionRequest( unit )

    local pid = self:GetPlayerID()
    local category = GetUnitKV(unit, "Category", 1)
    local menu_table_name = "menu_" .. category .. "_" .. pid
    -- local menu_table = CustomNetTables:GetTableValue("player_tables", menu_table_name)
    local menu_table = self.menu[category]

    if not menu_table[unit] or not self:HasRequiredBuildings(unit) then return end

    if self.unitCategories[category] and self:CategoryHasProductionInProgress(category) then
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

    if self.unitCategories[category] and self:HasUnitQueued(category, unit) then
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

    local duration = GetUnitKV(unit, "MenuBuildTime", 1) * PRODUCTION_TIME_MULTIPLIER
    local cost = GetUnitKV(unit, "BuildCost", 1) * PRODUCTION_COST_MULTIPLIER
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
            if self.unitCategories[category] then
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
    self:AdvanceQueue(category)

    return nil

end

function CDOTAPlayer:OnBuildingPlaced( building )

    self.unitCount = self.unitCount + 1
    self:UnlockUnits()
    self:ResetProductionState(building:GetUnitName())

end

function CDOTAPlayer:UnlockUnits()

    local units = KeyValues.UnitKV

    for unit, kv in pairs(units) do
        local category = kv["Category"]
        if category then
            local menu_table_name = "menu_" .. category .. "_" .. self:GetPlayerID()
            if self:HasRequiredBuildings(unit) then
                self.menu[category][unit] = {
                    progress = 0, 
                    paused = 0, 
                    cancelled = 0 
                }
            elseif self.menu[category][unit] then
                self.menu[category][unit] = nil
            end
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
            self.unitCount = self.unitCount + 1
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

    if CHEAT_UNLOCK_ALL then return true end

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
    if not queue then return end
    
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

function CDOTAPlayer:GetTeamColor()

    if TeamColors then
        return unpack(TeamColors[self:GetTeam()]);
    end

    return 255, 255, 255 -- Default to white

end