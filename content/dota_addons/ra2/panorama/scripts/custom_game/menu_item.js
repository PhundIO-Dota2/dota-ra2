"use strict";

var Root = $.GetContextPanel();
var unit = Root.unit;
var category = Root.category;
var playerID = Game.GetLocalPlayerID();

$('#label').text = unit;
$('#cameo').style.backgroundImage = 'url("file://{images}/custom_game/structures/' + unit + '.png");';

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

CustomNetTables.SubscribeNetTableListener( 'player_tables', OnPlayerTableChanged );
function OnPlayerTableChanged( table_name, key, data )
{
	if (key === 'menu_' + category + '_' + playerID) {
		var label = $('#progress');
		label.text = Math.floor(parseFloat(data[unit]['progress']) * 100);
	}
	else if (key === 'queue_' + playerID) {
		var counts = {};
		for (var key in data.infantry) {
			if(!counts[data.infantry[key]]) {
				counts[data.infantry[key]] = 0;
			}
			++counts[data.infantry[key]];
		}
		var label = $('#queue');
		label.text = counts[unit] || "";
	}
}