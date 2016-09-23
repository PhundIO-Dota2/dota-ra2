function OnUnitQueued( eventSourceIndex, event )

	local playerID = event.PlayerID
	local unit = event.UnitName
	local player = PlayerResource:GetPlayer(playerID)
	local hero = player:GetAssignedHero()

	print("------------------------------------------------")
	print('build_' .. unit)
	print("------------------------------------------------")
	buildAbility = hero:FindAbilityByName('build_' .. unit)
	print("------------------------------------------------")
	print(buildAbility)
	print("------------------------------------------------")
	if buildAbility then 
		hero:CastAbilityNoTarget(buildAbility, playerID)
	end
	

end

