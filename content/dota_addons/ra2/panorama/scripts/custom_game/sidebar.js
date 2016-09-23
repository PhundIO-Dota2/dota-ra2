"use strict";

function queueBuilding(name) {
	GameEvents.SendCustomGameEventToServer("building_queued", { name: name });
}

(function () {

	function OnBuildingStarted( data ) {
		$.Msg( "BuildingStarted" );
		var duration = data['duration'];
		var startTime = Game.Time();
		var label = $('#label_' + data['unit']);
		var timer = function() {
			var timeleft = duration - (Game.Time() - startTime);
			if (Game.Time() - startTime >= duration) {
				label.text = '';
				return;
			}
			label.text = parseFloat(Math.round(timeleft * 100) / 100).toFixed(1);
			$.Schedule(0.05, timer);
		};
		timer();
	}
	$.Msg( "SCRIPT LOADED" );

	var handle = GameEvents.Subscribe( "building_start", OnBuildingStarted );
})();
