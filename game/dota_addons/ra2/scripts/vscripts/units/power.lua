require("libraries/keyvalues")

function ConsumePower( event )

	local unit = event.target
	local ability = event.ability
	local caster = event.caster
	local player = caster:GetOwner()

	if not player then return end
	if not player:IsPlayer() then
		player = player:GetPlayerOwner()
	end

	if unit and player then
		local power = unit:GetKeyValue("Power", 1)
		player:ConsumePower(power)
	end

end

function RestorePower( event )

	local unit = event.target
	local ability = event.ability
	local caster = event.caster
	local player = caster:GetOwner()

	if not player then return end
	if not player:IsPlayer() then
		player = player:GetPlayerOwner()
	end

	if unit and player then
		local power = unit:GetKeyValue("Power", 1)
		player:RestorePower(power)
	end

end