require("libraries/keyvalues")

armor_types = {}
armor_types["RA2_ARMOR_NONE"]		= 0
armor_types["RA2_ARMOR_FLAK"]		= 1
armor_types["RA2_ARMOR_PLATE"]		= 2
armor_types["RA2_ARMOR_LIGHT"]		= 3
armor_types["RA2_ARMOR_MEDIUM"]		= 4
armor_types["RA2_ARMOR_HEAVY"]		= 5
armor_types["RA2_ARMOR_WOOD"]		= 6
armor_types["RA2_ARMOR_STEEL"]		= 7
armor_types["RA2_ARMOR_CONCRETE"]	= 8

function CDOTA_BaseNPC:GetArmorType()

	local armorType = self:GetKeyValue("Armor")
	if armor_types[armorType] ~= nil then
		return armorType
	end
    return "RA2_ARMOR_NONE"

end

function CDOTA_BaseNPC:GetDamageMultiplier( armorType )

	local damageTable = self:GetKeyValue("GroundDamageType")
	if damageTable and damageTable[armorType] then
		return damageTable[armorType]
	end
	return 1

end

function CDOTA_BaseNPC:IsAirborn()

    local airborn = self:GetKeyValue("Airborn")
    if airborn and airborn == 1 then
        return true
    end
    return false

end