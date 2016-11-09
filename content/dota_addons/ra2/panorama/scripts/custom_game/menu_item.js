"use strict";

var Root = $.GetContextPanel(),
	unit = Root.unit,
	category = Root.category,
	playerID = Game.GetLocalPlayerID(),
	overlay = $('#progressOverlay'),
	statusLabel = $('#status');

function startProduction() {

	var menu_table = CustomNetTables.GetTableValue( 'player_tables', 'menu_' + category + '_' + Players.GetLocalPlayer()),
		event = 'building_queued';

	if (menu_table[unit] && menu_table[unit]['paused']) {
		event = 'building_resumed';
	}
	GameEvents.SendCustomGameEventToServer(event, { name: unit });
}

function pauseProduction() {

	var menu_table = CustomNetTables.GetTableValue( 'player_tables', 'menu_' + category + '_' + Players.GetLocalPlayer());

	if (menu_table[unit]) {
		var paused = menu_table[unit]['paused'],
			finished = menu_table[unit]['progress'] == 1,
			event = 'building_cancelled';
		if (!paused && !finished) {
			event = 'building_paused';
		}
		GameEvents.SendCustomGameEventToServer(event, { name: unit });
	}

}

(function () {

	$('#label').text = $.Localize(unit);
	$('#cameo').style.backgroundImage = 'url("file://{images}/custom_game/units/' + unit + '.png");';

	function getStatusText(status) {

		if (status['paused']) { return '#on_hold'; }
		if (status['progress'] === 1) { return '#ready'; }

		return '';

	}

	Root.subscriber = CustomNetTables.SubscribeNetTableListener( 'player_tables', OnPlayerTableChanged );
	function OnPlayerTableChanged( table_name, key, data ) {

		if (key === 'menu_' + category + '_' + playerID) {
			if (!data[unit]) { return; }
			var progress = parseFloat(data[unit]['progress'])
			overlay.style.visibility = data[unit]['progress'] > 0 ? 'visible' : 'collapse';
			overlay.style.clip = 'radial(50.0% 50.0%, 0.0deg, ' + ((1 - progress) * -360) + 'deg);';
			statusLabel.text = $.Localize(getStatusText(data[unit]));
			statusLabel.style.visibility = statusLabel.text ? 'visible' : 'collapse';
		}
		else if (key === 'queue_' + playerID) {
			var counts = {};
			for (var key in data[category]) {
				if(!counts[data[category][key]]) {
					counts[data[category][key]] = 0;
				}
				++counts[data[category][key]];
			}
			var queueLabel = $('#queue');
			queueLabel.text = counts[unit] || "";
			queueLabel.style.visibility = queueLabel.text ? 'visible' : 'collapse';
		}

	}

})();