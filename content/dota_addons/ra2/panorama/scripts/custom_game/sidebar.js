"use strict";

GameUI.SetCameraYaw(-45);
GameUI.SetCameraPitchMin(60);
GameUI.SetCameraPitchMax(60);
// GameUI.SetCameraDistance(2000);

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
		'airforce',
		'defense',
		'infantry',
		'naval',
		'structure',
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
