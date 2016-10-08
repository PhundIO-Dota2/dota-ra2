"use strict";

GameUI.SetCameraYaw(-45);
GameUI.SetCameraPitchMin(60);
GameUI.SetCameraPitchMax(60);
// GameUI.SetCameraDistance(2000);

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
	var menuItems = {};

	tabs.forEach(function (tab) {
		tab.style.visibility = 'collapse';
	});
	showTab('#tab-structure');

	var categories = [
		'structure',
		'defense',
		'infantry',
		'vehicle'
	]

	function OnPlayerTableChanged( table_name, key, data ) {
		categories.forEach(function(category) {
			if (key === 'menu_' + category + '_' + Players.GetLocalPlayer()) {
				for (var unit in data) {
					var panel = menuItems[unit];
					if (!panel) {
						panel = createItemPanel(category, unit);
					}
				}
			} 
		});
	}

	function createItemPanel( category, unit ) 
	{
		var menu_tab = category === 'naval' || category === 'airforce' ? 'vehicle' : category;
		var menuItem = $.CreatePanel('Panel', $('#tab-' + menu_tab), 'item-' + unit);
		
		menuItem.category = category;
		menuItem.unit = unit;
		menuItem.BLoadLayout('file://{resources}/layout/custom_game/menu_item.xml', false, false);

		menuItems[unit] = menuItem;
		
		return menuItem;

	}

})();
