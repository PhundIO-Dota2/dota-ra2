require("team_colors")

function SetColor( event )

	local unit = event.target

	if unit and not unit:IsNull() then
		if TeamColors and TeamColors[unit:GetTeamNumber()] then
			unit:SetRenderColor(unpack(TeamColors[unit:GetTeamNumber()]))
		end
	end

end