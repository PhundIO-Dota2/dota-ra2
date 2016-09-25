"use strict";

function leftClickItem( name ) {
	var menu_structures = CustomNetTables.GetTableValue( 'player_tables', 'menu_structures_' + Players.GetLocalPlayer()),
		event = 'building_queued';

	if (menu_structures[name] && menu_structures[name]['paused']) {
		event = 'building_resumed';
	}
	GameEvents.SendCustomGameEventToServer(event, { name: name });
}

function rightClickItem( name ) {
	var menu_structures = CustomNetTables.GetTableValue( 'player_tables', 'menu_structures_' + Players.GetLocalPlayer());

	if (menu_structures[name]) {
		var paused = menu_structures[name]['paused'],
			finished = menu_structures[name]['progress'] == 1,
			event = 'building_cancelled';
		if (!paused && !finished) {
			event = 'building_paused';
		}
		GameEvents.SendCustomGameEventToServer(event, { name: name });
	}
}

function showTab( id ) {
	var tabs = $('#menu-tab-body').Children();

	tabs.forEach(function (tab) {
		tab.style.visibility = 'collapse';
	});
	var tab = $(id);
	if (tab) {
		tab.style.visibility = 'visible';
	}
}

(function () {

	CustomNetTables.SubscribeNetTableListener( 'player_tables', OnPlayerTableChanged );

	var tabs = $('#menu-tab-body').Children();

	tabs.forEach(function (tab) {
		tab.style.visibility = 'collapse';
	});
	showTab('#tab-structure');

	function OnPlayerTableChanged( table_name, key, data )
	{
		if (key === 'menu_structures_' + Players.GetLocalPlayer()) {
			for (var unit in data) {
				var label = $('#label_' + unit);
				label.text = Math.floor(parseFloat(data[unit]['progress']) * 100);
			}
		}
	}

})();
