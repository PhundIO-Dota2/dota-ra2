'use strict';

var footprintParticle;
var scheduled;
var gridPosition;
var isPlacing = false;
var unit;

function StartPlacement( event ) {
	isPlacing = true;
	unit = event['unit'];
	footprintParticle = Particles.CreateParticle('particles/building_footprint.vpcf', ParticleAttachment_t.PATTACH_CUSTOMORIGIN, 0);
	UpdateParticlePosition();
}

function UpdateParticlePosition() {
	var worldPosition = GameUI.GetScreenWorldPosition(GameUI.GetCursorPosition());
	if (worldPosition) {
		gridPosition = [
			SnapToGrid(worldPosition[0], 64),
			SnapToGrid(worldPosition[1], 64),
			worldPosition[2]
		];
		Particles.SetParticleControl(footprintParticle, 0, gridPosition);
	}
	if (isPlacing) {
		scheduled = $.Schedule(1/30, UpdateParticlePosition);
	}
}

function MouseCallback( eventName, arg ) {
	var CONSUME_EVENT = true;
	var CONTINUE_PROCESSING_EVENT = false;
	var LEFT_CLICK = (arg === 0)
	var RIGHT_CLICK = (arg === 1)

	if ( GameUI.GetClickBehaviors() !== CLICK_BEHAVIORS.DOTA_CLICK_BEHAVIOR_NONE ) {
		return CONTINUE_PROCESSING_EVENT;
	}

	if ( eventName == 'pressed' ) {
		Particles.DestroyParticleEffect(footprintParticle, true);
		Particles.ReleaseParticleIndex(footprintParticle);
		isPlacing = false;
		if (scheduled) { $.CancelScheduled(scheduled); }
		if (LEFT_CLICK) {
			GameEvents.SendCustomGameEventToServer('place_building_at_position', { unit: unit, x: gridPosition[0], y: gridPosition[1] } );
		}

		return CONSUME_EVENT;
	}
	return CONTINUE_PROCESSING_EVENT;
}

function SnapToGrid( position, size ) {
	return Math.floor((position) / size) * size + size * 0.5;
}

GameEvents.Subscribe('start_building_placement', StartPlacement);
GameUI.SetMouseCallback(MouseCallback);