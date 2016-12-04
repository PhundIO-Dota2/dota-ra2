var playerID = Game.GetLocalPlayerID(),
	label = $('#power');

CustomNetTables.SubscribeNetTableListener( 'player_tables', OnPlayerTableChanged );
function OnPlayerTableChanged( table_name, key, data ) {
	$.Msg(key);
	if (key === 'power_' + playerID) {
		label.text = data.value;
	}
};