var playerID = Game.GetLocalPlayerID(),
	Root = $.GetContextPanel(),
	productionBar = $('#productionBar'),
	warningBar = $('#warningBar'),
	consumptionBar = $('#consumptionBar');

CustomNetTables.SubscribeNetTableListener( 'player_tables', OnPlayerTableChanged );
function OnPlayerTableChanged( table_name, key, data ) {
	if (key === 'power_' + playerID) {
		$.Msg(data);
		var maxHeight = Root.actuallayoutheight,
			highest = Math.max(maxHeight, data['production'], data['consumption']),
			ratio = maxHeight / highest;
		var yellowBarHeight = roundToMultipleOfThree(100 * ratio);
		if (data['value'] < 100) {
			yellowBarHeight = roundToMultipleOfThree(data['value'] * ratio);
		}
		var greenBarHeight = roundToMultipleOfThree(data['value'] - yellowBarHeight  * ratio);
		var redBarHeight = roundToMultipleOfThree(data['consumption'] * ratio);
		productionBar.style.height = greenBarHeight + 'px';
		warningBar.style.height = yellowBarHeight + 'px';
		consumptionBar.style.height = redBarHeight + 'px';
	}
};

function roundToMultipleOfThree( value ) {
	if (value <= 0) { return 0; }
	return (value - 3 - value % 3);
}
