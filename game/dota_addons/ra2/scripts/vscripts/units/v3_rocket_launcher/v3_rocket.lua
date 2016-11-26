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
		rocket:SetModel("models/heroes/rattletrap/rattletrap_rocket.vmdl")
		rocket:SetOrigin(origin)
		rocket:SetAngles(angle.x, angle.y, angle.z)
		rocket.launchOrigin = rocket:GetAbsOrigin()
		rocket.targetOrigin = target:GetAbsOrigin()
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
	local ratio = 1 - (distance / (totalDistance * 0.5))
	direction.z = -ratio * 1.5
	-- DebugDrawLine(rocket:GetAbsOrigin(),rocket:GetAbsOrigin() + direction * 5, 255, 255, 255, false, 5)

	if distance < 10 then
		rocket:ForceKill(false)
	else
		rocket:SetForwardVector(Vector(direction.x/2, direction.y/2, direction.z/2))
		rocket:SetAbsOrigin(rocket:GetAbsOrigin() + direction * 5)
		-- rocket:SetAngles(angle.x, angle.y, angle.z)
	end
end

