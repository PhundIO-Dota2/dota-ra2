function OnUnitQueued( eventSourceIndex, event )

	local playerID = event.PlayerID
	local unit = event.UnitName
	local player = PlayerResource:GetPlayer(playerID)
	local hero = player:GetAssignedHero()

	buildAbility = hero:FindAbilityByName('build_' .. unit)
	if buildAbility then 
		hero:CastAbilityNoTarget(buildAbility, playerID)
	end
	

end

