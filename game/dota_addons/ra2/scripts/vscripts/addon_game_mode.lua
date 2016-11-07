require("libraries/selection")
require("libraries/buildinghelper")
require("libraries/keyvalues")
require("libraries/timers")
require("player")

if RedAlert2 == nil then
	RedAlert2 = class({})
end

function Precache( context )

	--[[
		Precache things we know we"ll use.  Possible file types include (but not limited to):
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
    GameRules:SetStartingGold(20000)
    GameRules:SetGoldPerTick(0)
    GameRules:SetPreGameTime(0)
    GameRules:SetSameHeroSelectionEnabled(true)

    local teamMaxPlayer = math.max(1, (PlayerResource:GetPlayerCount() - 1))
    GameRules:SetCustomGameTeamMaxPlayers(DOTA_TEAM_GOODGUYS, teamMaxPlayer)
    GameRules:SetCustomGameTeamMaxPlayers(DOTA_TEAM_BADGUYS, teamMaxPlayer)
    GameRules:SetCustomGameTeamMaxPlayers(DOTA_TEAM_CUSTOM_1, teamMaxPlayer)
    GameRules:SetCustomGameTeamMaxPlayers(DOTA_TEAM_CUSTOM_2, teamMaxPlayer)
    GameRules:SetCustomGameTeamMaxPlayers(DOTA_TEAM_CUSTOM_3, teamMaxPlayer)
    GameRules:SetCustomGameTeamMaxPlayers(DOTA_TEAM_CUSTOM_4, teamMaxPlayer)
    GameRules:SetCustomGameTeamMaxPlayers(DOTA_TEAM_CUSTOM_5, teamMaxPlayer)
    GameRules:SetCustomGameTeamMaxPlayers(DOTA_TEAM_CUSTOM_6, teamMaxPlayer)
    GameRules:SetCustomGameTeamMaxPlayers(DOTA_TEAM_CUSTOM_7, teamMaxPlayer)
    GameRules:SetCustomGameTeamMaxPlayers(DOTA_TEAM_CUSTOM_8, teamMaxPlayer)

    local mode = GameRules:GetGameModeEntity()
    mode:SetUnseenFogOfWarEnabled(true)
    mode:SetCameraDistanceOverride(1400)
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

	ListenToGameEvent("player_connect_full", Dynamic_Wrap(RedAlert2, "OnConnectFull"), self)
    ListenToGameEvent("npc_spawned", Dynamic_Wrap(RedAlert2, "OnNPCSpawned"), self)

	CustomGameEventManager:RegisterListener( "building_queued", Dynamic_Wrap(RedAlert2, "OnBuildingQueued") )
    CustomGameEventManager:RegisterListener( "building_paused", Dynamic_Wrap(RedAlert2, "OnBuildingPaused") )
    CustomGameEventManager:RegisterListener( "building_resumed", Dynamic_Wrap(RedAlert2, "OnBuildingResumed") )
    CustomGameEventManager:RegisterListener( "building_cancelled", Dynamic_Wrap(RedAlert2, "OnBuildingCancelled") )

end

function RedAlert2:OnConnectFull( args )

    local player = PlayerResource:GetPlayer(args["PlayerID"])

    if player then player:Init() end

end

function RedAlert2:OnNPCSpawned(keys)

    local npc = EntIndexToHScript(keys.entindex)

    if npc:IsRealHero() then
        Timers:CreateTimer(function() 
            local ability = npc:FindAbilityByName("spawn_soviet_mcv")
            ability:UpgradeAbility(true)
            -- npc:CastAbilityImmediately(ability, npc:GetPlayerOwnerID())
            ability = npc:FindAbilityByName("hide_hero")
            ability:UpgradeAbility(true)
            npc:SetAbilityPoints(0)
            npc:AddNoDraw()
        end)
    end

end

function RedAlert2:OnBuildingQueued( args )

	local pid = args.PlayerID
    local player = PlayerResource:GetPlayer(pid)
    local unit = args.name

    if player and unit then 
        player:OnProductionRequest(unit)
    end

end

function RedAlert2:OnBuildingPaused( args )

    local pid = args.PlayerID
    local player = PlayerResource:GetPlayer(pid)
    local unit = args.name

    if player and unit then
        player:OnProductionPaused(unit)
    end

end

function RedAlert2:OnBuildingResumed( args )

    local pid = args.PlayerID
    local player = PlayerResource:GetPlayer(pid)
    local unit = args.name

    if player and unit then
        player:OnProductionResumed(unit)
    end

end

function RedAlert2:OnBuildingCancelled( args )

    local pid = args.PlayerID
    local player = PlayerResource:GetPlayer(pid)
    local unit = args.name

    if player and unit then
        player:OnProductionCancelled(unit)
    end

end