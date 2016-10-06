"use strict";

function leftClickItem( name, category ) {
	var menu_table = CustomNetTables.GetTableValue( 'player_tables', 'menu_' + category + '_' + Players.GetLocalPlayer()),
		event = 'building_queued';

	if (menu_table[name] && menu_table[name]['paused']) {
		event = 'building_resumed';
	}
	GameEvents.SendCustomGameEventToServer(event, { name: name });
}

function rightClickItem( name, category ) {
	var menu_table = CustomNetTables.GetTableValue( 'player_tables', 'menu_' + category + '_' + Players.GetLocalPlayer());

	if (menu_table[name]) {
		var paused = menu_table[name]['paused'],
			finished = menu_table[name]['progress'] == 1,
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

	var categories = ['structure', 'defense', 'infantry', 'vehicle', 'naval', 'airforce'];
	categories.forEach(function(category) {
		var menu_table = CustomNetTables.GetTableValue('player_tables', 'menu_' + category + '_' + Players.GetLocalPlayer());
		for (var unit in menu_table) {
			var menu_tab = category === 'naval' || category === 'airforce' ? 'vehicle' : category;
			var menuItem = $.CreatePanel('Panel', $('#tab-' + menu_tab), 'item-' + unit);
			menuItem.category = category;
			menuItem.unit = unit;
			menuItem.BLoadLayout('file://{resources}/layout/custom_game/menu_item.xml', false, false);
		}
	});

	function OnPlayerTableChanged( table_name, key, data )
	{
		if (key === 'menu_structure_' + Players.GetLocalPlayer()) {
			for (var unit in data) {
				var label = $('#label_' + unit);
				if (label) {
					label.text = Math.floor(parseFloat(data[unit]['progress']) * 100);
				}
			}
		} 
		else if (key === 'menu_defense_' + Players.GetLocalPlayer()) {
			for (var unit in data) {
				var label = $('#label_' + unit);
				if (label) {
					label.text = Math.floor(parseFloat(data[unit]['progress']) * 100);
				}
			}
		}
		else if (key === 'menu_infantry_' + Players.GetLocalPlayer()) {
			for (var unit in data) {
				var label = $('#label_' + unit);
				if (label) {
					label.text = Math.floor(parseFloat(data[unit]['progress']) * 100);
				}
			}
		}
		else if (key === 'queue_' + Players.GetLocalPlayer()) {
			var counts = {};
			for (var key in data.infantry) {
				if(!counts[data.infantry[key]]) {
					counts[data.infantry[key]] = 0;
				}
				++counts[data.infantry[key]];
			}
			for (var unit in counts) {
				var label = $('#queue_' + unit);
				if (label) {
					label.text = counts[unit];
				}
			}
		}
	}

})();
