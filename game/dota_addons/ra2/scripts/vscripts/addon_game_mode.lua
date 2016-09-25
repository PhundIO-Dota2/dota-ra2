require("libraries/buildinghelper")
require("libraries/keyvalues")
require("libraries/timers")
require("sidebar")

-- Generated from template

if RedAlert2 == nil then
	RedAlert2 = class({})
end

function Precache( context )
	--[[
		Precache things we know we'll use.  Possible file types include (but not limited to):
			PrecacheResource( "model", "*.vmdl", context )
			PrecacheResource( "soundfile", "*.vsndevts", context )
			PrecacheResource( "particle", "*.vpcf", context )
			PrecacheResource( "particle_folder", "particles/folder", context )
	]]
	PrecacheResource("particle_folder", "particles/buildinghelper", context)
end

-- Create the game mode when we activate
function Activate()
	GameRules.RedAlert2 = RedAlert2()
	GameRules.RedAlert2:InitGameMode()
end

function RedAlert2:InitGameMode()
	print( "Red Alert 2 addon is loaded." )
	GameRules:GetGameModeEntity():SetThink( "OnThink", self, "GlobalThink", 2 )
	self:InitListeners()
    GameRules:SetStartingGold(10000)
    GameRules:SetGoldPerTick(0)
    GameRules:SetPreGameTime(0)
end

-- Evaluate the state of the game
function RedAlert2:OnThink()
	if GameRules:State_Get() == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
		--print( "Template addon script is running." )
	elseif GameRules:State_Get() >= DOTA_GAMERULES_STATE_POST_GAME then
		return nil
	end
	return 1
end

function RedAlert2:InitListeners()
	ListenToGameEvent('player_connect_full', Dynamic_Wrap(RedAlert2, 'OnConnectFull'), self)
	CustomGameEventManager:RegisterListener( "building_queued", Dynamic_Wrap(RedAlert2, 'OnBuildingQueued') )
    CustomGameEventManager:RegisterListener( "building_paused", Dynamic_Wrap(RedAlert2, 'OnBuildingPaused') )
    CustomGameEventManager:RegisterListener( "building_resumed", Dynamic_Wrap(RedAlert2, 'OnBuildingResumed') )
    CustomGameEventManager:RegisterListener( "building_cancelled", Dynamic_Wrap(RedAlert2, 'OnBuildingCancelled') )
end

function RedAlert2:OnConnectFull( args )
    local pid = args['PlayerID']
	CustomNetTables:SetTableValue("player_tables", "menu_structures_" .. pid, {
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
	})

end

function RedAlert2:OnBuildingQueued( args )

	local pid = args.PlayerID
    local unit = args.name
    local build_time = GetUnitKV(unit, "MenuBuildTime", 1)
    local cost = GetUnitKV(unit, "BuildCost", 1)
    local player = PlayerResource:GetPlayer(pid)
    local menu_structures = CustomNetTables:GetTableValue("player_tables", "menu_structures_" .. pid)
    
    if not menu_structures[unit] then return end

    if menu_structures[unit]['progress'] == 0 then
        CustomGameEventManager:Send_ServerToPlayer(player, "building_start", { unit = unit, duration = build_time, cost = cost })
        player:StartBuilding(unit, build_time, cost)
    elseif menu_structures[unit]['progress'] == 1 then
        local hero = player:GetAssignedHero()

        buildAbility = hero:FindAbilityByName('build_' .. unit)
        if buildAbility then 
            hero:CastAbilityNoTarget(buildAbility, pid)
        end
    else
        CustomGameEventManager:Send_ServerToPlayer(player, "building_in_progress", { unit = unit })
    end

end

function RedAlert2:OnBuildingPaused( args )

    local pid = args.PlayerID
    local unit = args.name
    local menu_structures = CustomNetTables:GetTableValue("player_tables", "menu_structures_" .. pid)

    if not menu_structures[unit] then return end

    -- Checks if the building has started and is not yet finished, otherwise we don't pause
    if menu_structures[unit]['progress'] == 0 or menu_structures[unit]['progress'] == 1 then
        return
    end
    menu_structures[unit]['paused'] = true
    CustomNetTables:SetTableValue("player_tables", "menu_structures_" .. pid, menu_structures)

end

function RedAlert2:OnBuildingResumed( args )

    local pid = args.PlayerID
    local unit = args.name
    local menu_structures = CustomNetTables:GetTableValue("player_tables", "menu_structures_" .. pid)

    if not menu_structures[unit] then return end

    menu_structures[unit]['paused'] = false
    CustomNetTables:SetTableValue("player_tables", "menu_structures_" .. pid, menu_structures)

end

function RedAlert2:OnBuildingCancelled( args )

    local pid = args.PlayerID
    local unit = args.name
    local cost = GetUnitKV(unit, "BuildCost", 1)
    local menu_structures = CustomNetTables:GetTableValue("player_tables", "menu_structures_" .. pid)

    if not menu_structures[unit] then return end

    if menu_structures[unit]['progress'] >= 1 then
        menu_structures[unit] = {
            progress = 0,
            paused = 0,
            cancelled = 0
        }
        CustomNetTables:SetTableValue("player_tables", "menu_structures_" .. pid, menu_structures)
        PlayerResource:SpendGold(pid, -cost, DOTA_ModifyGold_GameTick) 
    elseif menu_structures[unit]['progress'] > 0 then
        menu_structures[unit]['cancelled'] = 1
        CustomNetTables:SetTableValue("player_tables", "menu_structures_" .. pid, menu_structures)
    end

end

function CDOTAPlayer:StartBuilding( unit, duration, cost )

    local start_time = GameRules:GetGameTime()
    local time = start_time
    local hold_duration = 0
    local spent = 0
    local menu_structures = CustomNetTables:GetTableValue("player_tables", "menu_structures_" .. self:GetPlayerID())

    if not menu_structures[unit] then return end
    if self:HasStructureInProgress() then return end

    menu_structures[unit]['cancelled'] = 0
    CustomNetTables:SetTableValue("player_tables", "menu_structures_" .. self:GetPlayerID(), menu_structures)

    Timers:CreateTimer(function()

        local prev_time = time
        time = GameRules:GetGameTime()
        local elapsed = time - prev_time
        menu_structures = CustomNetTables:GetTableValue("player_tables", "menu_structures_" .. self:GetPlayerID())
        local paused = menu_structures[unit]['paused'] ~= 0
        if menu_structures[unit]['cancelled'] == 1 then
            return self:CancelBuilding(unit, spent)
        end
        if time >= (start_time + duration + hold_duration) then
        	menu_structures[unit]['progress'] = 1
            CustomNetTables:SetTableValue("player_tables", "menu_structures_" .. self:GetPlayerID(), menu_structures)
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
        menu_structures[unit]['progress'] = (time - (start_time + hold_duration)) / duration
        CustomNetTables:SetTableValue("player_tables", "menu_structures_" .. self:GetPlayerID(), menu_structures)

        return 0.05

    end)

end

function CDOTAPlayer:CancelBuilding( unit, spent )

    local menu_structures = CustomNetTables:GetTableValue("player_tables", "menu_structures_" .. self:GetPlayerID())

    menu_structures[unit] = {
        progress = 0,
        paused = 0,
        cancelled = 0
    }
    CustomNetTables:SetTableValue("player_tables", "menu_structures_" .. self:GetPlayerID(), menu_structures)
    PlayerResource:SpendGold(self:GetPlayerID(), -spent, DOTA_ModifyGold_GameTick)

    return nil

end

function CDOTAPlayer:HasStructureInProgress()

    local menu_structures = CustomNetTables:GetTableValue("player_tables", "menu_structures_" .. self:GetPlayerID())

    for name, building in pairs(menu_structures) do 
        if building['progress'] > 0 then return true end
    end

    return false

end