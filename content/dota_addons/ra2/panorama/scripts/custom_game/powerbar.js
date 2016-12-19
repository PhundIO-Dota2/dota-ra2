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
			ratio = maxHeight / highest,
			positivePower = Math.max(data['value'], 0);
		var yellowBarHeight = roundToMultipleOfThree(100 * ratio);
		if (positivePower < 100) {
			yellowBarHeight = roundToMultipleOfThree(positivePower * ratio);
		}
		var greenBarHeight = roundToMultipleOfThree(positivePower - yellowBarHeight  * ratio);
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
