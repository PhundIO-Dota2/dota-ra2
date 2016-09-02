conscript_attack = class ({})

function ApplyAttackSpeedBoost( event )
	local caster = event.caster
	local ability = event.ability
	local attack_count = ability:GetLevelSpecialValueFor("attack_count", ability:GetLevel() - 1)

	caster:SetModifierStackCount("modifier_burst_attack", ability, attack_count)
	ability:ApplyDataDrivenModifier(caster, caster, "modifier_attack_speed_boost", {})
end

function BurstAttack( event )
	local caster = event.caster
	local target = event.target
	local ability = event.ability
	local attack_count = ability:GetLevelSpecialValueFor("attack_count", ability:GetLevel() - 1)
	local rate = ability:GetSpecialValueFor("rate")
	local stacks = caster:GetModifierStackCount("modifier_burst_attack", ability)

	if stacks > 1 and target:IsAlive() then
		caster:SetModifierStackCount("modifier_burst_attack", ability, stacks - 1)
		ability:ApplyDataDrivenModifier(caster, caster, "modifier_attack_speed_boost", {})
	else
		caster:RemoveModifierByName("modifier_attack_speed_boost")
		caster:SetModifierStackCount("modifier_burst_attack", ability, attack_count)
	end
	
end