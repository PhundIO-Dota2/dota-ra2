function LaunchRocket( event )

	local ability = event.ability
	local caster = event.caster
	local target = event.target

	local attachment = caster:ScriptLookupAttachment("attach_attack1")
	local origin = caster:GetAttachmentOrigin(attachment)
	local angle = caster:GetAttachmentAngles(attachment)
	local rocket = CreateUnitByName("npc_dota_creature", origin, false, caster, nil, caster:GetTeam())

	if rocket then
		ability:ApplyDataDrivenModifier(caster, rocket, "modifier_v3_rocket", {})
		rocket:SetModel("models/ra2_v3_rocket.vmdl")
		rocket:SetOrigin(origin)
		rocket:SetAngles(angle.x, angle.y, angle.z)
		rocket.launchOrigin = rocket:GetAbsOrigin()
		rocket.targetOrigin = target:GetAbsOrigin()
		rocket.launchTime = 0
	end

end

function MoveRocket( event )

	local ability = event.ability
	local caster = event.caster
	local rocket = event.target
	local totalDistance = (rocket.targetOrigin - rocket.launchOrigin):Length2D()
	local vectorDistance = rocket.targetOrigin - rocket:GetAbsOrigin()
	local distance = (vectorDistance):Length2D()
	local direction = (vectorDistance):Normalized()
	local curveRatio = 1 - (distance / (totalDistance * 0.5))
	direction.z = -curveRatio * 1.5
	local interval = 0.02
	local accelerationDuration = 1.5
	rocket.launchTime = rocket.launchTime + interval
	local speedRatio = 0

	speedRatio = math.min(1, math.pow(rocket.launchTime, 2) / accelerationDuration)

	if distance < 10 then
		rocket:ForceKill(false)
	else
		rocket:SetForwardVector(Vector(direction.x/2, direction.y/2, direction.z/2))
		rocket:SetAbsOrigin(rocket:GetAbsOrigin() + direction * 10 * speedRatio)
		-- rocket:SetAngles(angle.x, angle.y, angle.z)
	end
end

