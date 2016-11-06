"use strict";

function showTab( idButton, idTab ) {

	var tabs = $('#menu-tab-body').Children();
	var buttons = $('#menu-tab-header').Children();

	buttons.forEach(function (button) {
		button.RemoveClass('active');
	});
	var button = $(idButton);
	if (button) {
		button.AddClass('active');
	}

	tabs.forEach(function (tab) {
		tab.style.visibility = 'collapse';
	});
	var tab = $(idTab);
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
		menuItems = {},
		menuTabs = {};

	function Initialize() {

		// Camera Setup
		GameUI.SetCameraYaw(45);
		GameUI.SetCameraPitchMin(0);
		GameUI.SetCameraPitchMax(0);
		GameUI.SetRenderTopInsetOverride(0);
		GameUI.SetRenderBottomInsetOverride(0);

		// Fill in the menu when reloading
		categories.forEach(function(category) {
			var key = 'menu_' + category + '_' + Players.GetLocalPlayer(),
				data = CustomNetTables.GetTableValue('player_tables', key);
			createItemPanels(category, data);
		});
		CustomNetTables.SubscribeNetTableListener( 'player_tables', OnPlayerTableChanged );
		showTab('#bt-tab-structure', '#tab-structure');
		UpdateOreDisplay();
	}

	function UpdateOreDisplay() {
		$('#ore').text = Players.GetGold(Players.GetLocalPlayer());
		$.Schedule(0.1, UpdateOreDisplay);
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
				createItemPanel(category, unit);
			}
		}
		removeLockedItems(category, custom_nettable_data);

	}

	function createItemPanel( category, unit ) {

		var tabName = category === 'naval' || category === 'airforce' ? 'vehicle' : category;
		var menuItem = $.CreatePanel('Panel', $('#tab-' + tabName), 'item-' + unit);

		var tabButton = $('#bt-tab-' + tabName);
		if (tabButton && tabButton.BHasClass('disabled')) {
			tabButton.RemoveClass('disabled');
		}
		
		menuItem.category = category;
		menuItem.tabName = tabName;
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
