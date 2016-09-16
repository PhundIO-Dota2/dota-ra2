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
end

function RedAlert2:OnConnectFull( args )
    local pid = args['PlayerID']
	CustomNetTables:SetTableValue("player_tables", "menu_structures_" .. pid, {
		npc_ra2_soviet_barracks = 0	
	})

end

function RedAlert2:OnBuildingQueued( args )

	local pid = args.PlayerID
    local unit = args.name
    local build_time = GetUnitKV(unit, "MenuBuildTime", 1)
    local cost = GetUnitKV(unit, "BuildCost", 1)
    local player = PlayerResource:GetPlayer(pid)
    local menu_structures = CustomNetTables:GetTableValue("player_tables", "menu_structures_" .. pid)
    
    print(menu_structures[unit])
    if menu_structures[unit] == 0 then
        PlayerResource:SetGold(pid, 10000, true)
        CustomGameEventManager:Send_ServerToPlayer(player, "building_start", { unit = unit, duration = build_time, cost = cost })
        player:StartBuilding(unit, build_time, cost)
    elseif menu_structures[unit] == 1 then
        local hero = player:GetAssignedHero()

        buildAbility = hero:FindAbilityByName('build_' .. unit)
        if buildAbility then 
            hero:CastAbilityNoTarget(buildAbility, pid)
        end
    else
        CustomGameEventManager:Send_ServerToPlayer(player, "building_in_progress", { unit = unit })
    end

end

function CDOTAPlayer:StartBuilding( unit, duration, cost )

    local start_time = GameRules:GetGameTime()
    local time = start_time
    local hold_duration = 0
    local spent = 0

    Timers:CreateTimer(function()

        local prev_time = time
        time = GameRules:GetGameTime()
        local elapsed = time - prev_time
        local menu_structures = CustomNetTables:GetTableValue("player_tables", "menu_structures_" .. self:GetPlayerID())
        if time >= (start_time + duration + hold_duration) then
        	menu_structures[unit] = 1
            CustomNetTables:SetTableValue("player_tables", "menu_structures_" .. self:GetPlayerID(), menu_structures)
            PlayerResource:SpendGold(self:GetPlayerID(), cost - spent, DOTA_ModifyGold_GameTick)
            CustomGameEventManager:Send_ServerToPlayer(self, "building_done", { unit = unit })
            return nil
        end
        local ratio = elapsed / (duration + hold_duration)
        local gold_tick = ratio * cost
        local enough_gold = PlayerResource:GetGold(self:GetPlayerID()) >= gold_tick
        if enough_gold then
            PlayerResource:SpendGold(self:GetPlayerID(), gold_tick, DOTA_ModifyGold_GameTick)
            spent = spent + gold_tick
        else
            hold_duration = hold_duration + elapsed
        end
        menu_structures[unit] = time / (start_time + duration + hold_duration)
        CustomNetTables:SetTableValue("player_tables", "menu_structures_" .. self:GetPlayerID(), menu_structures)

        return 0.1

    end)

end