require("libraries/keyvalues")

function UpdatePower( event )

	local unit = event.target
	local ability = event.ability
	local caster = event.caster
	local player = caster:GetOwner()

	if unit and player then
		local power = unit:GetKeyValue("Power", 1)
		player:ConsumePower(power)
	end

end