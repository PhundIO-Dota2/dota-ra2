"use strict";

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

	var categories = [
		'airforce',
		'defense',
		'infantry',
		'naval',
		'structure',
		'vehicle'
	],
		menuItems = {};

	function Initialize() {

		// Camera setup
		GameUI.SetCameraYaw(-45);
		GameUI.SetCameraPitchMin(60);
		GameUI.SetCameraPitchMax(60);
		// GameUI.SetCameraDistance(2000);

		// Fill in the menu when reloading
		categories.forEach(function(category) {
			var key = 'menu_' + category + '_' + Players.GetLocalPlayer(),
				data = CustomNetTables.GetTableValue('player_tables', key);
			createItemPanels(category, data);
		});
		CustomNetTables.SubscribeNetTableListener( 'player_tables', OnPlayerTableChanged );
		showTab('#tab-structure');

	}
 
	function OnPlayerTableChanged( table_name, key, data ) {

		categories.forEach(function(category) {
			if (key === 'menu_' + category + '_' + Players.GetLocalPlayer()) {
				createItemPanels(category, data);
			}
		});

	}

	function createItemPanels(category, custom_nettable_data) {

		for (var unit in custom_nettable_data) {
			var panel = menuItems[unit];
			if (!panel) {
				panel = createItemPanel(category, unit);
			}
		}
		removeLockedItems(category, custom_nettable_data);

	}

	function createItemPanel( category, unit ) {

		var menu_tab = category === 'naval' || category === 'airforce' ? 'vehicle' : category;
		var menuItem = $.CreatePanel('Panel', $('#tab-' + menu_tab), 'item-' + unit);
		
		menuItem.category = category;
		menuItem.unit = unit;
		menuItem.BLoadLayout('file://{resources}/layout/custom_game/menu_item.xml', false, false);

		menuItems[unit] = menuItem;
		
		return menuItem;

	}

	function removeLockedItems( category, custom_nettable_data ) {

		for (var unit in menuItems) {
			if (menuItems[unit].category === category && !custom_nettable_data[unit]) {
				CustomNetTables.UnsubscribeNetTableListener(menuItems[unit].subscriber);
				menuItems[unit].DeleteAsync(0);
				delete menuItems[unit];
			}
		}

	}

	Initialize();

})();
