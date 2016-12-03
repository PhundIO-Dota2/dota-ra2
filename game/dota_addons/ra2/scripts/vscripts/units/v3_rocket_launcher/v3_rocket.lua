function SpawnRocket( event )

	local ability = event.ability
	local caster = event.caster

	local attachment = caster:ScriptLookupAttachment("attach_attack1")
	local origin = caster:GetAttachmentOrigin(attachment)
	local angle = caster:GetAttachmentAngles(attachment)

	if caster.rocket and not caster.rocket:IsNull() and caster.rocket:IsAlive() then return end -- Rocket already spawned

	if caster:AttackReady() == false then return end -- Launcher not ready, check again later

	caster.rocket = CreateUnitByName("npc_dota_creature", origin, false, caster, nil, caster:GetTeam())

	if caster.rocket then
		ability:ApplyDataDrivenModifier(caster, caster.rocket, "modifier_v3_rocket", {})
		caster.rocket:SetModel("models/ra2_v3_rocket.vmdl")
		caster.rocket:SetOrigin(origin)
		caster.rocket:SetAngles(angle.x, angle.y, angle.z)
		caster.rocket:SetParent(caster, "attach_attack1")
		caster.rocket:SetOwner(caster)
	end

end

function RaiseRocket( event )

	local ability = event.ability
	local caster = event.caster
	local target = event.target

	local attachment = caster:ScriptLookupAttachment("attach_attack1")
	local origin = caster:GetAttachmentOrigin(attachment)
	local angle = caster:GetAttachmentAngles(attachment)

	SpawnRocket(event) -- In case the attack is launched before the missile spawned 

	if caster.rocket and caster.rocket:IsAlive() then
		-- caster.rocket.launchOrigin = caster.rocket:GetAbsOrigin()
		caster.rocket.targetOrigin = target:GetAbsOrigin()
	end

end

function LaunchRocket( event )

	local ability = event.ability
	local caster = event.caster
	local target = event.target

	local attachment = caster:ScriptLookupAttachment("attach_attack1")
	local origin = caster:GetAttachmentOrigin(attachment)
	local angle = caster:GetAttachmentAngles(attachment)

	if caster.rocket and caster.rocket:IsAlive() then
		ability:ApplyDataDrivenModifier(caster, caster.rocket, "modifier_v3_rocket_launch", {})
		caster.rocket:SetModel("models/ra2_v3_rocket.vmdl")
		caster.rocket:SetParent(nil, nil)
		caster.rocket.launchTime = 0
		caster.rocket.launchOrigin = caster.rocket:GetAbsOrigin()
		if not caster.rocket.targetOrigin then
			caster.rocket.targetOrigin = target:GetAbsOrigin()
		end
		caster.rocket = nil
	end

end

function MoveRocket( event )

	local ability = event.ability
	local caster = event.caster
	local rocket = event.target

	if not rocket or not rocket:IsAlive() then return end

	local totalDistance = (rocket.targetOrigin - rocket.launchOrigin):Length2D()
	local vectorDistance = rocket.targetOrigin - rocket:GetAbsOrigin()
	local distance = (vectorDistance):Length2D()
	local direction = (vectorDistance):Normalized()
	local curveRatio = 1 - (distance / (totalDistance * 0.5))
	direction.z = -curveRatio
	local interval = 0.03
	local accelerationDuration = 1.5
	rocket.launchTime = rocket.launchTime + interval
	local speedRatio = 0
	local baseSpeed = 256
	speedRatio = math.min(1, math.pow(rocket.launchTime, 2) / accelerationDuration)

	if distance < 10 then
		rocket:ForceKill(false)
	else
		rocket:SetForwardVector(Vector(direction.x/2, direction.y/2, direction.z/2))
		rocket:SetAbsOrigin(rocket:GetAbsOrigin() + direction * baseSpeed * interval * speedRatio)

		-- DebugDrawLine(rocket:GetAbsOrigin(),rocket:GetAbsOrigin() + direction * 10 * speedRatio,255,255,255,false,1)
		-- rocket:SetAngles(angle.x, angle.y, angle.z)
	end
end

