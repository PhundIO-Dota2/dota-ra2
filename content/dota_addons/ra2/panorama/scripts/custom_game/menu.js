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
		menuItems = {};

	function Initialize() {

		// Camera setup
		GameUI.SetCameraYaw(45);
		GameUI.SetCameraPitchMin(0);
		GameUI.SetCameraPitchMax(0);
		GameUI.SetRenderTopInsetOverride(0);
		GameUI.SetRenderBottomInsetOverride(0);
		GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_TOP_TIMEOFDAY, false );      //Time of day (clock).
		GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_TOP_HEROES, false );     //Heroes and team score at the top of the HUD.
		GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_FLYOUT_SCOREBOARD, false );      //Lefthand flyout scoreboard.
		GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_ACTION_PANEL, false );     //Hero actions UI.
		GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_ACTION_MINIMAP, false );     //Minimap.
		GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_INVENTORY_PANEL, false );      //Entire Inventory UI
		GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_INVENTORY_SHOP, false );     //Shop portion of the Inventory. 
		GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_INVENTORY_ITEMS, false );      //Player items.
		GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_INVENTORY_QUICKBUY, false );     //Quickbuy.
		GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_INVENTORY_COURIER, false );      //Courier controls.
		GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_INVENTORY_PROTECT, false );      //Glyph.
		GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_INVENTORY_GOLD, false );     //Gold display.
		GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_SHOP_SUGGESTEDITEMS, false );      //Suggested items shop panel.
		GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_HERO_SELECTION_TEAMS, false );     //Hero selection Radiant and Dire player lists.
		//GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_HERO_SELECTION_GAME_NAME, false );     //Hero selection game mode name display.
		//GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_HERO_SELECTION_CLOCK, false );     //Hero selection clock.
		GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_TOP_MENU_BUTTONS, false );     //Top-left menu buttons in the HUD.
		//GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_ENDGAME, false );      //Endgame scoreboard.    
		GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_TOP_BAR_BACKGROUND, false );     //Top-left menu buttons in the HUD.

		GameUI.CustomUIConfig().team_colors = {}
		GameUI.CustomUIConfig().team_colors[DOTATeam_t.DOTA_TEAM_GOODGUYS] = "#3dd296;"; // { 61, 210, 150 }	--		Teal
		GameUI.CustomUIConfig().team_colors[DOTATeam_t.DOTA_TEAM_BADGUYS ] = "#F3C909;"; // { 243, 201, 9 }	--		Yellow
		GameUI.CustomUIConfig().team_colors[DOTATeam_t.DOTA_TEAM_CUSTOM_1] = "#c54da8;"; // { 197, 77, 168 }	--		Pink
		GameUI.CustomUIConfig().team_colors[DOTATeam_t.DOTA_TEAM_CUSTOM_2] = "#FF6C00;"; // { 255, 108, 0 }	--		Orange
		GameUI.CustomUIConfig().team_colors[DOTATeam_t.DOTA_TEAM_CUSTOM_3] = "#8c2af4;"; // { 140, 42, 244 }	--		Purple
		GameUI.CustomUIConfig().team_colors[DOTATeam_t.DOTA_TEAM_CUSTOM_4] = "#3455FF;"; // { 52, 85, 255 }	--		Blue
		GameUI.CustomUIConfig().team_colors[DOTATeam_t.DOTA_TEAM_CUSTOM_5] = "#c7e40d;"; // { 199, 228, 13 }	--		Olive
		GameUI.CustomUIConfig().team_colors[DOTATeam_t.DOTA_TEAM_CUSTOM_6] = "#815336;"; // { 129, 83, 54 }	--		Brown
		GameUI.CustomUIConfig().team_colors[DOTATeam_t.DOTA_TEAM_CUSTOM_7] = "#1bc0d8;"; // { 27, 192, 216 }	--		Light Blue
		GameUI.CustomUIConfig().team_colors[DOTATeam_t.DOTA_TEAM_CUSTOM_8] = "#65d413;"; // { 101, 212, 19 }	--		Dark Green

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
