@lazyglobal off.
{

	// don't use until BD Armory is updated
	local weaponRanges is lexicon(
		"MGUN", 	270,
		"ERSLAS", 	400,
		"SRM",		500,
		"ERMLAS", 	600,
		"MRM",	 	700,
		"UAC",		600,
		"ERLLAS", 	1000,
		"ERPPC", 	1200,
		"GAUSS",    1200,
		"NONE",		-1
	).
	
	local maxRange is 2500.
	
	
	//{ mech components -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	
	local cockpit        			is 0.
	local BDA_module     			is 0.
	local hips						is 0.
	local WA_servo					is 0.
	local RS_servo					is 0.
	local LS_servo					is 0.
	local myTeam         			is 0.

	//}
	
	local target_selected  			is false.
	local target_ship				is 0.
	local target_list				is 0.
	local target_check				is 0.
	local target_inrange			is false.
	local target_range				is 0.
	local target_position			is 0.
	local target_pitch   			is 0.
	local target_yaw     			is 0.
	
	local first_weapon				is "".
	local current_weapon			is "".

	local targeting_error  			is 2.
	local rockets_to_fire			is 0.
	
	local ship_altitude 			is 0.
	local feeler					is 0.		
	local steer_angle				is 0.
	local steer_direction			is ship:facing.
	local abs_steer_angle 			is 0.
	
	local time_last_collision_check is 0.	
	local time_last_switch			is 0.
	local time_last_weapon_switch	is 0.
	local time_soft_wait_end		is 0.
	local time_last_shot			is 0.
	
	local max_reactor				is 0.
	
	//{ current state vars -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	
	local process 						is 0.
	local process_index					is 0.
	local desired_wheelThrottle			is 0.
	local desired_reactorThrottle		is 0.
	local desired_targetBearing			is 0.
	local collision_throttleFraction 	is 0.
	local collision_angleOffset 		is 0.
	
	//}
	
	
	//{ dogfight state -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
		
	local process_dogfight is list (
		checkTarget@,	
		checkSwitchWeapon@,
		switchWeapon@,
		getTargetAngles@,
		chaseTargetAngles@,			
		getSteeringAngle@,		
		checkAvoidCollision@,
		getShipAltitude@,
		avoidCollision@,
		correctSteeringAngle@,
		steer@,
		getTargetAngles@,
		chaseTargetAngles@,
		shoot@,
		switchTactics@,
		goto@						:bind(0):bind(15)
	).
	
	//}
		
		
	//{ snipe state - precise aiming ---------------------------------------------------------------------------------------------------------------------------------------------------------------
	
	local process_snipe is list (
		checkTarget@,
		getTargetAngles@,
		chaseTargetAngles@,
		shoot@,
		//setSoftWait@				:bind(0.5),
		//softWait@,
		goto@						:bind(0):bind(4)
	).
			
	//}
	
	
	 //{ guard state - no target -------------------------------------------------------------------------------------------------------------------------------------------------------------------
	
	local process_guard is list (
		getAllTargets@,
		hardWait@		:bind(1),
		selectTarget@,
		hardWait@		:bind(1),
		randomLook@,
		hardWait@		:bind(3),			// do nothing for a while.
		goto@			:bind(0):bind(6)	// loop
	
	).
	
	//}
	
	
	//{ state switching ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	
	// engine "antigravity" throttle based on kerbin planet mass until kOS body() function is updated
	function state_dogfight {
		lights off.
		set process 					to process_dogfight.
		set	process_index 				to 0.
		set desired_wheelThrottle		to 0.
		set desired_reactorThrottle		to 0.
		set max_reactor				    to ship:body:mass / body("kerbin"):mass.
	}	
	
	function state_guard {
		lights on.
		set process 				   to process_guard.
		set	process_index 			   to 0.
		set desired_wheelThrottle	   to 0.
		set desired_reactorThrottle	   to 0.
		set ship:control:mainthrottle  to 0.
		set ship:control:wheelthrottle to 0.
		set max_reactor				   to ship:body:mass / body("kerbin"):mass. 
		MEK_recenter().	
	}	
	
	function state_snipe {
		lights off.
		set process 					to process_snipe.
		set process_index 				to 0.
		set desired_wheelThrottle		to 0.
		set desired_reactorThrottle		to 0.		
		set ship:control:mainthrottle   to 0.
		set ship:control:wheelthrottle  to 0.
	}
	//}
	
	
	//{ functions used in process lists ------------------------------------------------------------------------------------------------------------------------------------------------------------
	
	function goto {
		parameter pIndex.
		parameter pCurrent.
		return pIndex - pCurrent.
	}
	
	function randomLook {
		WA_servo:moveto(round((random() - 0.5), 1) * 120, 1).
		return 1.
	}
	
	function hardWait {
		parameter p is 1.
		wait p.
		return 1.
	}		
		
	function setSoftWait {
		parameter p.
		set time_soft_wait_end to time:seconds + p.
		return 1.
	}
	
	function softWait {
		if time:seconds > time_soft_wait_end { return 1. }
		else { return 0. }
	}

	// if current target is dead or out of range then switch state to guard
	// otherwise refresh target info	
	function checkTarget {
		if target_selected and (target_ship:isdead or target_ship:distance > maxRange or target_ship:mass <= 0.4) { // mass below 0.4 indicates target probably destroyed
			BDA_module:doaction("fire guns (toggle)", false).
			set target_selected to false.
			state_guard().
			return 0.
		} else {
			set target_range to target_ship:distance.
			set target_position to target_ship:position.
			return 1.
		}
	}
	
	function getAllTargets {
		set target_selected to false.
		list targets in target_list.
		set target_check to target_list:length - 1.		
		return 1.
	}
	
	// get nearest target within range on opposing team
	// iteration is one target check per frame. This only happens during guard() so no need to worry about animation.
	function selectTarget {	
		if target_check = -1 { 
			if not target_selected {
				return 1.
			} else {
				state_dogfight().
				return 0.
			}
		} else {
			local t is target_list[target_check].
			local tt is getTeam(t).			
			if getTeam(t) <> myTeam {
				if t:mass > 0.4 and ((not target_selected and t:distance < maxRange) or (target_selected and t:distance < target_ship:distance)) {
					set target_ship to t.
					set target_selected to true.
				}
			}
			set target_check to target_check - 1.
			return 0.
		}
	}
		
	function getSteeringAngle {
		set steer_angle to target_ship:bearing - desired_targetBearing.
		return 1.			
	}	
	
	// correct for collisions detected in desired movement vector
	function correctSteeringAngle {
		local a is steer_angle + collision_angleOffset.
		//if a > 180 { set a to a - 360. }
		//else if a < -180 { set a to a + 360. }
		set abs_steer_angle to abs(a).
		set steer_direction to angleaxis(a, ship:facing:topvector) * ship:facing.
		return 1.
	}	

	// adjust engine and throttle based on sharpness of turn
	function steer {
		if abs_steer_angle < 10 {
			unlock steering.
			brakes on.
			set ship:control:mainthrottle to desired_reactorThrottle * max_reactor.
			set ship:control:wheelthrottle to desired_wheelThrottle * collision_throttleFraction.			
			return 1.
		} else if abs_steer_angle > 140 {
			set ship:control:mainthrottle to 0.8 * max_reactor.
			set ship:control:wheelthrottle to 0.3 * collision_throttleFraction.
			brakes off. // off
		} else if abs_steer_angle > 60 {
			set ship:control:mainthrottle to 0.6 * max_reactor.
			set ship:control:wheelthrottle to min(0.4, desired_wheelThrottle * collision_throttleFraction). 
			brakes on. 
		} else {
			set ship:control:mainthrottle to 0.2 * max_reactor.
			set ship:control:wheelthrottle to min(0.5, desired_wheelThrottle * collision_throttleFraction).		
			brakes on.
		}
		lock steering to steer_direction.
		return 1.
	}
	
	// time for a collision check? If not jump past the rest of the collision detection instructions
	function checkAvoidCollision {
		if time:seconds - time_last_collision_check > 3 {
			set time_last_collision_check to time:seconds.
			if (collision_angleOffset > 0) { 
				set collision_angleOffset to collision_angleOffset - 10. 
			}
			set feeler to 25 * (angleaxis(steer_angle, ship:facing:topvector) * ship:facing:forevector:normalized).
			return 1.
		} else {
			return 3.
		}
	}
	
	function getShipAltitude {
		set ship_altitude to ship:geoposition:terrainheight.
		return 1.
	}	
			
	// very simple collision detection determined by a single feeler that sweeps for a clear path.
	// start the feeler in the desired direction of movement, then advance it 20 degrees until a clear path is found.
	function avoidCollision {	
		local talt is ship:body:geopositionof(feeler):terrainheight.
		if abs(talt - ship_altitude) > 5 {
			if (collision_throttleFraction <> 0) {
				set collision_throttleFraction to 0.15.			
				set ship:control:wheelthrottle to 0.15.	
				set ship:control:mainthrottle to 0.1.				
				MEK_walk_processThrottle().
			} 
			set collision_angleOffset to collision_angleOffset + 20.			
			set feeler to angleaxis(collision_angleOffset, up:vector) * feeler.			
			return 0.
		} else {
			set collision_throttleFraction to 1.
			return 1.
		}
	}
	
	// get angles for torso aiming
	function getTargetAngles {	
		set target_yaw to target_ship:bearing.		
		if vdot(cockpit:facing:forevector, target_position) > 0 {
			set target_pitch to vang(cockpit:facing:forevector, vxcl(cockpit:facing:starvector, target_position)).			
			if target_pitch > 80 { set target_pitch to 0. }
			else if vdot(ship:facing:upvector, target_position) < 0 { set target_pitch to -target_pitch. }
		} else {
			set target_pitch to 0.
		}		
		return 1.
	}	
	
	// rotate and pitch torso towards target
	function chaseTargetAngles {	
		local ty is abs(target_yaw - WA_servo:position).
		local tp is abs(target_pitch - LS_servo:position).
		if ty > 0.4 { WA_servo:moveto(target_yaw, 0.4 + ty/45). }
		if tp > 0.4 {
			RS_servo:moveto(target_pitch, 0.4 + tp/45).
			LS_servo:moveto(target_pitch, 0.4 + tp/45).
		}
		set targeting_error to ((ty + (tp/3)) * target_range) / 2500.
		return 1.
	}	

	// rudiementary weapon selection algorithm until BD armory mod is updated for kOS integration
	function checkSwitchWeapon {	
		if time:seconds - time_last_weapon_switch < 12 or time:seconds - time_last_shot < 4 {		
			return 2.
		} else {			
			set time_last_weapon_switch to time:seconds.
			set target_inrange to false.
			set first_weapon to BDA_module:getfield("weapon").
			BDA_module:doaction("next weapon", true).
			return 1.
		}
	}
	
	function switchWeapon {
		set current_weapon to BDA_module:getfield("weapon").		
		if weaponRanges[current_weapon] > target_range {
			set target_inrange to true.
			return 1.
		} else if current_weapon = first_weapon {
			return 1.
		} else {
			BDA_module:doaction("next weapon", true).
			return 0.
		}
	}		
	      	
	// shoot if within weapons envelope
	function shoot {
		local t is time:seconds.
		if t - time_last_shot > 6 and target_inrange {
			set time_last_shot to t.
			local rnd is random().			
			if rnd > targeting_error {
				BDA_module:doaction("fire guns (toggle)", true).				
				set rockets_to_fire to round(rnd * 4, 1).				
			}
		} else if t - time_last_shot > 3.5 {
			BDA_module:doaction("fire guns (toggle)", false).
		} else if rockets_to_fire > 0 {
			BDA_module:doaction("fire missile", true).
			set rockets_to_fire to rockets_to_fire - 1.
		}
		return 1.
	}
	
	// range-weighted random behaviour switch
	function switchTactics {
		if time:seconds - time_last_switch > 20 {
			set time_last_switch to time:seconds.
			if target_selected {
				local rnd is random().
				
				if target_range < 100 {
					if 		rnd > 0.7 			{ tactic_withdraw(). 	}
					else if rnd > 0.4			{ tactic_beam().		}
					else if rnd > 0.2			{ tactic_extend().		}
					else 						{ tactic_retreat().   	}
				} else if target_range < 300 {    
					if		rnd > 0.5			{ tactic_beam().		}
					else if rnd > 0.4			{ tactic_snipe().		}
					else if rnd > 0.3			{ tactic_withdraw().	}
					else if rnd > 0.2			{ tactic_flank().		}
					else						{ tactic_extend().		}
				} else if target_range < 600 {    
					if		rnd > 0.8			{ tactic_charge().		}
					else if rnd > 0.4			{ tactic_flank().		}
					else if rnd > 0.2			{ tactic_snipe().		}
					else						{ tactic_beam().		}
				} else if target_range < 900 {    
					if		rnd > 0.5			{ tactic_charge().		}
					else if rnd > 0.2			{ tactic_flank().		}
					else						{ tactic_snipe().		}
				} else if target_range < maxRange {   
					if		rnd > 0.2			{ tactic_charge().		}
					else						{ tactic_snipe().		}
				} else							{ state_guard().		}
			} else {
				state_guard().
			}										
		}
		return 1.
	}

	function tactic_withdraw {
		set desired_targetBearing to 0.
		set desired_wheelThrottle to -0.6.
		set desired_reactorThrottle to 0.2.
	}
	
	function tactic_beam {
		//print ("beam            ") at (20, 8).
		if random() < 0.5 { set desired_targetBearing to -90. }
		else { set desired_targetBearing to 90. }
		set desired_wheelThrottle to 0.7.
		set desired_reactorThrottle to 0.2 * max_reactor.
	}
	
	function tactic_extend {
		//print ("extend          ") at (20, 8).
		if random() < 0.5 { set desired_targetBearing to -135. }
		else { set desired_targetBearing to 135. }
		set desired_wheelThrottle to 0.7.
		set desired_reactorThrottle to 0.2 * max_reactor.
	}
	
	function tactic_retreat {
		//print ("retreat         ") at (20, 8).
		//MEK_recenter().
		set desired_targetBearing to 180.
		set desired_wheelThrottle to 0.9.
		set desired_reactorThrottle to 0.2 * max_reactor.
	}
	
	function tactic_snipe {
		//print ("snipe           ") at (20, 8).
		set desired_targetBearing to target_ship:bearing.
		set desired_wheelThrottle to 0.
		set desired_reactorThrottle to 0.2 * max_reactor.
	}
	
	function tactic_flank {
		//print ("flank           ") at (20, 8).
		if random() < 0.5 { set desired_targetBearing to -45. }
		else { set desired_targetBearing to 45. }
		set desired_wheelThrottle to 0.8.
		set desired_reactorThrottle to 0.2 * max_reactor.
	}
	
	function tactic_charge {
		//print("charge           ") at (20, 8).
		set desired_targetBearing to 0.
		set desired_wheelThrottle to 0.9.
		set desired_reactorThrottle to 0.2 * max_reactor.
	}	
		
	
	function dlog {
		parameter p.
		print(p).
	}
	
	//{ functions used during startup -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	
	function startup {	
		wait 1.		
		clearscreen.		
		set cockpit 		to MEK_get_cockpit().
		set hips			to MEK_get_hips().
		set RS_servo		to MEK_get_RS_servo().
		set LS_servo		to MEK_get_LS_servo().
		set WA_servo		to MEK_get_WA_servo().		
		set BDA_module 		to MEK_get_BDA():getmodule("MissileFire").
		
		sas off.
		set sasmode to "stabilityassist".
		sas on.
		BDA_module:doaction("next weapon", true).
		
		set myTeam to getTeam(ship).
		
		state_guard().
	}

	function getTeam {
		parameter pVessel.
		local t is 0.		
		for p in pVessel:parts {
			if p:hasmodule("MissileFire") {
				set t to p:getmodule("MissileFire"):getfield("team").
				print "IFF " + pVessel + " is " + t.						
				return t.
			}
		}
		set t to myTeam.
		return t.
	}	

	//}
	
	// run the current process index delegate and advance the process in the amount of the returned value
	function update {
		set process_index to process_index + process[process_index]().
	}
		
	// expose callable interface to external librariers
	global MEKAI_startup is startup@.
	global MEKAI_update is update@.
}

