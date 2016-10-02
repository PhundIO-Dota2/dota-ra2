function CDOTAPlayer:Init()

    local pid = self:GetPlayerID()

    self.menu = {
        structure = {
            npc_ra2_soviet_construction_yard = {
                progress = 0,
                paused = false,
                cancelled = false
            },
            npc_ra2_soviet_barracks = {
                progress = 0,
                paused = false,
                cancelled = false
            },
            npc_ra2_tesla_reactor = {
                progress = 0,
                paused = false,
                cancelled = false
            }
        },
        defense = {
            npc_ra2_sentry_gun = {
                progress = 0,
                paused = false,
                cancelled = false
            }
        },
        infantry = {
            npc_ra2_conscript = {
                progress = 0,
                paused = false,
                cancelled = false
            },
            npc_ra2_tesla_trooper = {
                progress = 0,
                paused = false,
                cancelled = false
            }
        }
    }
    self.queue = {
        infantry = {}
    }

    CustomNetTables:SetTableValue("player_tables", "menu_structure_" .. pid, self.menu.structure)
    CustomNetTables:SetTableValue("player_tables", "menu_defense_" .. pid, self.menu.defense)
    CustomNetTables:SetTableValue("player_tables", "menu_infantry_" .. pid, self.menu.infantry)
end

function CDOTAPlayer:StartBuilding( unit, duration, cost )

    local start_time = GameRules:GetGameTime()
    local time = start_time
    local hold_duration = 0
    local spent = 0
    local category = GetUnitKV(unit, "Category", 1)
    local menu_table_name = "menu_" .. category .. "_" .. self:GetPlayerID()
    -- local menu_table = CustomNetTables:GetTableValue("player_tables", menu_table_name)
    local menu_table = self.menu[category]

    if not menu_table[unit] then return end
    if self:CategoryHasBuildingInProgress(category) then return end

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
            return self:CancelBuilding(unit, spent)
        end
        if time >= (start_time + duration + hold_duration) then
            if category == "infantry" or category == "vehicle" then
                menu_table[unit]["progress"] = 0
                self.menu[category] = menu_table
                self:SpawnUnit(unit)
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

function CDOTAPlayer:CancelBuilding( unit, spent )

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

function CDOTAPlayer:CategoryHasBuildingInProgress( category )

	-- local menu_table_name = "menu_" .. category .. "_" .. self:GetPlayerID()
    -- local menu_table = CustomNetTables:GetTableValue("player_tables", menu_table_name)
    local menu_table = self.menu[category]

    for name, building in pairs(menu_table) do 
        if building["progress"] > 0 then return true end
    end

    return false

end

function CDOTAPlayer:SpawnUnit( unit )
    
    local buildings = BuildingHelper:GetBuildings(self:GetPlayerID())

    for key, building in pairs(buildings) do
        local production = GetUnitKV(building:GetUnitName(), "Produces", 1)
        if production == "infantry" then
            local trainAbility = building:FindAbilityByName("train_" .. unit)
            if not trainAbility then
                trainAbility = building:AddAbility("train_" .. unit)
            end
            building:CastAbilityImmediately(trainAbility, self:GetPlayerID())
            self:AdvanceQueue(production)
            break
        end
    end

end

function CDOTAPlayer:AdvanceQueue( category )

    local queue = self.queue[category]
    local next_unit = queue[1]
    table.remove(queue, 1)
    -- CustomNetTables:SetTableValue("player_tables", category .. "_queue_" .. self:GetPlayerID(), queue)
    if next_unit then
        local build_time = GetUnitKV(next_unit, "MenuBuildTime", 1)
        local cost = GetUnitKV(next_unit, "BuildCost", 1)
        self:StartBuilding(next_unit, build_time, cost)
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
    print("ADD " .. unit)
    DeepPrintTable(self.queue[category])
    -- CustomNetTables:SetTableValue("player_tables", category .. "_queue_" .. self:GetPlayerID(), queue)

end

function CDOTAPlayer:RemoveUnitFromQueue( category, unit )

    local queue = self.queue[category]

    if not queue then return end

    for k, v in pairs(queue) do
        if v == unit then
            table.remove(self.queue[category], k)
            DeepPrintTable(self.queue[category])
            break
        end
    end
end