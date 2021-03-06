@LAZYGLOBAL OFF.
RUN ONCE lib_basis.

GLOBAL axisdraw_config IS LEXICON(
	"colors", LIST(red, green, blue, white, white, white, yellow, cyan, magenta, white),
	"text", "rad+ nrm+ pro+ x+ y+ z+ up north east hvel":SPLIT(" "),
	"mult", 100,
	"scale", 1,
	"width", 0.5
).
// Dummies that get replaced by delegates.
GLOBAL axisdraw_start IS 0.
GLOBAL axisdraw_stop IS 0.
GLOBAL axisdraw_tick IS 0.
{
	LOCAL mult IS 0.
	LOCAL draws IS LIST().
	
	LOCAL FUNCTION _start {
		PARAMETER origin IS ship.
		PARAMETER callable IS false.
		PARAMETER config IS axisdraw_config.
		PARAMETER draworb IS true.
		PARAMETER drawxyz IS false.
		PARAMETER drawune IS true.
		
		SET mult TO config["mult"].
		FOR d IN draws { SET d:show TO false. }
		draws:clear().
		IF NOT (drawxyz OR draworb) {
			RETURN.
		}
		LOCAL xform IS LIST().
		
		LOCAL FUNCTION update {
			IF draws:length = 0 { RETURN FALSE. }.
			LOCAL o IS origin.
			IF callable {
				SET o TO o().
			}.
			LOCAL x IS o:position.
			FOR d IN xform { SET d:start TO o. }.
			IF draworb {
				LOCAL b IS basis_mvr(o).
				FOR i IN RANGE(3) { SET draws[i]:vec TO x+(b[i]*mult). }
			}.
			IF drawxyz {
				FOR i IN RANGE(3) { SET draws[i+3]:vec TO x+(basis_xyz[i]*mult). }
			}.
			IF drawune {
				LOCAL b IS basis_une(o).
				FOR i IN RANGE(3) { SET draws[i+6]:vec TO x+(b[i]*mult). }
			}.
			SET draws[9]:vec TO x+VXCL(-origin:body:position, origin:velocity:orbit):normalized*mult.
			RETURN true.
		}
		
		FOR ix IN RANGE(10) {
			LOCAL show IS (draworb AND ix < 3) OR (drawxyz AND ix > 2 AND ix < 6) OR (drawune AND ix > 5 AND ix < 9) OR ix > 8.
			draws:add(VECDRAW(V(0,0,0), V(0,0,0), config["colors"][ix], config["text"][ix], config["scale"], show, config["width"])).
			IF show AND (callable OR origin <> ship) {
				xform:add(draws[ix]).
			}
		}
		UPDATE().
		SET axisdraw_tick TO update@.
		// If we don't do transforms, we can cheat a little since x/y/z will never need to be redrawn.
		IF xform:length = 0 { SET drawxyz TO FALSE. }
		// If we do transforms or have orbital axes on, we need to do stuff every physics tick.
		ON time {
			IF axisdraw_tick() { preserve. }
		}
	}
	FUNCTION f { RETURN FALSE. }
	FUNCTION _stop {
		SET axisdraw_tick TO f@.
		FOR d IN draws { SET d:show TO false. }
	}
	SET axisdraw_start TO _start@.
	SET axisdraw_stop TO _stop@.
	axisdraw_stop().
}

axisdraw_start().
WAIT UNTIL ship:control:pilotyaw<>0 OR ship:control:pilotpitch<>0 OR ship:control:pilotroll<>0.
axisdraw_stop().

