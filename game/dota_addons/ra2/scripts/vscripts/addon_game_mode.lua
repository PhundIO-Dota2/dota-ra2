require("libraries/buildinghelper")
require("libraries/keyvalues")
require("libraries/timers")
require("player")
require("sidebar")

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

    BuildingHelper:NewGridType("ALLOWED")
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
    ListenToGameEvent('npc_spawned', Dynamic_Wrap(RedAlert2, 'OnNPCSpawned'), self)
	CustomGameEventManager:RegisterListener( "building_queued", Dynamic_Wrap(RedAlert2, 'OnBuildingQueued') )
    CustomGameEventManager:RegisterListener( "building_paused", Dynamic_Wrap(RedAlert2, 'OnBuildingPaused') )
    CustomGameEventManager:RegisterListener( "building_resumed", Dynamic_Wrap(RedAlert2, 'OnBuildingResumed') )
    CustomGameEventManager:RegisterListener( "building_cancelled", Dynamic_Wrap(RedAlert2, 'OnBuildingCancelled') )
end

function RedAlert2:OnConnectFull( args )
    local pid = args['PlayerID']
	CustomNetTables:SetTableValue("player_tables", "menu_structure_" .. pid, {
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
	})
    CustomNetTables:SetTableValue("player_tables", "menu_defense_" .. pid, {
        npc_ra2_sentry_gun = {
            progress = 0,
            paused = false,
            cancelled = false
        }
    })

end

function RedAlert2:OnNPCSpawned(keys)

    local npc = EntIndexToHScript(keys.entindex)

    if npc:IsRealHero() then
        local ability = npc:FindAbilityByName("hide_hero")
        ability:UpgradeAbility(true)
        npc:SetAbilityPoints(0)
        npc:AddNoDraw()
    end

end

function RedAlert2:OnBuildingQueued( args )

	local pid = args.PlayerID
    local unit = args.name
    local build_time = GetUnitKV(unit, "MenuBuildTime", 1)
    local cost = GetUnitKV(unit, "BuildCost", 1)
    local player = PlayerResource:GetPlayer(pid)
    local category = GetUnitKV(unit, "Category", 1)
    local menu_table_name = "menu_" .. category .. "_" .. pid
    local menu_table = CustomNetTables:GetTableValue("player_tables", menu_table_name)

    if not menu_table[unit] then return end

    if menu_table[unit]['progress'] == 0 then
        CustomGameEventManager:Send_ServerToPlayer(player, "building_start", { unit = unit, duration = build_time, cost = cost })
        player:StartBuilding(unit, build_time, cost)
    elseif menu_table[unit]['progress'] == 1 then
        local hero = player:GetAssignedHero()

        local buildAbility = hero:FindAbilityByName('build_' .. unit)
        if not buildAbility then 
            buildAbility = hero:AddAbility('build_' .. unit)
        end
        hero:CastAbilityNoTarget(buildAbility, pid)
    else
        CustomGameEventManager:Send_ServerToPlayer(player, "building_in_progress", { unit = unit })
    end

end

function RedAlert2:OnBuildingPaused( args )

    local pid = args.PlayerID
    local unit = args.name
    local category = GetUnitKV(unit, "Category", 1)
    local menu_table_name = "menu_" .. category .. "_" .. pid
    local menu_table = CustomNetTables:GetTableValue("player_tables", menu_table_name)

    if not menu_table[unit] then return end

    -- Checks if the building has started and is not yet finished, otherwise we don't pause
    if menu_table[unit]['progress'] == 0 or menu_table[unit]['progress'] == 1 then
        return
    end
    menu_table[unit]['paused'] = true
    CustomNetTables:SetTableValue("player_tables", menu_table_name, menu_table)

end

function RedAlert2:OnBuildingResumed( args )

    local pid = args.PlayerID
    local unit = args.name
    local category = GetUnitKV(unit, "Category", 1)
    local menu_table_name = "menu_" .. category .. "_" .. pid
    local menu_table = CustomNetTables:GetTableValue("player_tables", menu_table_name)

    if not menu_table[unit] then return end

    menu_table[unit]['paused'] = false
    CustomNetTables:SetTableValue("player_tables", menu_table_name, menu_table)

end

function RedAlert2:OnBuildingCancelled( args )

    local pid = args.PlayerID
    local unit = args.name
    local cost = GetUnitKV(unit, "BuildCost", 1)
    local category = GetUnitKV(unit, "Category", 1)
    local menu_table_name = "menu_" .. category .. "_" .. pid
    local menu_table = CustomNetTables:GetTableValue("player_tables", menu_table_name)

    if not menu_table[unit] then return end

    if menu_table[unit]['progress'] >= 1 then
        menu_table[unit] = {
            progress = 0,
            paused = 0,
            cancelled = 0
        }
        CustomNetTables:SetTableValue("player_tables", menu_table_name, menu_table)
        PlayerResource:SpendGold(pid, -cost, DOTA_ModifyGold_GameTick) 
    elseif menu_table[unit]['progress'] > 0 then
        menu_table[unit]['cancelled'] = 1
        CustomNetTables:SetTableValue("player_tables", menu_table_name, menu_table)
    end

end