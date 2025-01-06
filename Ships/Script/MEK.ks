@lazyglobal off.

// expose control parameters to external librariers 
global MEK_INVERT_PITCH 	is false.					
global MEK_LOCK_THROTTLE	is false.
global MEK_action_recenter is false.
global MEK_action_recentering is false.
{
	//{ global configuration constants ----------------------------------------------------------------------------------------------------------------------------------------

	local LEG_ACCELERATION 		is 300.							// higher values create a more accurate animation but cause larger momentum shifts. Stick within 100 - 500
	
	local FRAME_TIMES is lexicon (								// heavier mechs have slower animation speeds
		"MDG", 0.25,
		"HBR", 0.25,
		"SMN", 0.27,
		"TBR", 0.27,
		"DWF", 0.28
	).	
	
	local YIELD_TO_TRANSFER		is 0.85.							// how long (seconds) before the end of the frame an animation resumes control to transfer balance
	local YIELD_TO_MOVE			is 0.95.						// how long (seconds) before the end of the frame an animation resumes control to move servos
	local ERROR_MARGIN			is 0.15.						// how far a servo is allowed to move beyond the target position (%) in order to avoid coming to a stop. Results in a smoother animation.
	
	//} 
	

	
	//{ constant position matrices for walking, idling and docking. A mech will choose a set of these at startup depending on which boot file is chosen.
	
	local matrix is lexicon (
		"TBR", lexicon (
			"WALK", list ( 					
					//ldm	lb1	 lb2	lbu	  lu	lfu	  lf1	lf2
				list(+000, -012, -015, -024, +013, +045, +041, +018),					// HIP LEFT
				list(+000, -006, -022, +019, +024, -014, -021, -005),		            // KNEE LEFT
				list(+090, +072, +053, +083, +118, +120, +110, +103),                   // ANKLE LEFT
																						
				list(-013, -045, -041, -018, +000, +012, +015, +024),                   // HIP RIGHT
				list(-024, +014, +021, +005, +000, +006, +022, -019),                   // KNEE RIGHT
				list(+118, +120, +110, +103, +090, +072, +053, +083)					// ANKLE RIGHT	
			),
			"IDLE", list ( 					
				list(+000),
				list(+000),
				list(+090),
				list(+000),
				list(+000),
				list(+090)
			),
			"SLEEP", list (
				list(-015),
				list(+020),
				list(+095),
				list(+015),
				list(-020),
				list(+095)
			)
		),
		"SMN", lexicon (
			"WALK", list ( 					
					//ldm	lb1		lb2		lbu	  	lu		lfu	  	lf1		lf2						
				list(+000, 	-014, 	-029, 	-020, 	+005, 	+024, 	+013, 	+009),		// HL
				list(+000, 	+004, 	+015, 	-008, 	-030, 	+007, 	+016, 	+003),		// KNEE LEFT
				list(+000, 	+010, 	+014, 	+028, 	+025, 	-031, 	-027, 	-012),		// ANKLE LEFT
				
				list(-005, 	-024, 	-013, 	-009, 	+000, 	+014, 	+029, 	+020),		// HIP RIGHT
				list(+030, 	-007, 	-016, 	-003, 	+000, 	-004, 	-015, 	+008),		// KNEE RIGHT
				list(-025, 	+031, 	+027, 	+012, 	+000, 	-010, 	-014, 	-028)		// ANKLE RIGHT		
			),
			"IDLE", list ( 					
				list(0),
				list(0),
				list(0),
				list(0),
				list(0),
				list(0)
			),
			//"SLEEP", list (
			//	list(+020),
			//	list(-035),
			//	list(+015),
			//	list(-020),
			//	list(+035),
			//	list(-015)
			//)
			"SLEEP", list (
				list(+030),
				list(-060),
				list(+030),
				list(-030),
				list(+060),
				list(-030)
			)			
		),
		"DWF", lexicon (
			"WALK", list ( 					
					//ldm	lb1		lb2		lbu	  	lu		lfu	  	lf1		lf2						
				list(+000, 	-014,	-023, 	-032, 	-005, 	+038, 	+036, 	+018),		// HL
				list(+000, 	-002, 	-009, 	+005, 	+020, 	-008, 	-013, 	-004),		// KNEE LEFT
				list(+000, 	+016, 	+032, 	+027, 	-015, 	-030, 	-023, 	-014),		// ANKLE LEFT

				list(+005, 	-038, 	-036, 	-018, 	+000, 	+014,	+023, 	+032),		// HIP RIGHT
				list(-020, 	+008, 	+013, 	+004, 	+000, 	+002, 	+009, 	-005),		// KNEE RIGHT
				list(+015, 	+030, 	+023, 	+014, 	+000, 	-016, 	-032, 	-027)		// ANKLE RIGHT
			),
			"IDLE", list ( 					
				list(0),
				list(0),
				list(0),
				list(0),
				list(0),
				list(0)
			),
			"SLEEP", list (
				list(-015),
				list(+015),
				list(+000),
				list(+015),
				list(-015),
				list(+000)	
			)
		)						
	). 
	
	//}
	

	
	//{ mech components -------------------------------------------------------------------------------------------------------------------------------------------------------
	
	local LH_servo          	is 0.
	local LK_servo          	is 0.
	local LA_servo          	is 0.
	local RH_servo          	is 0.
	local RK_servo          	is 0.
	local RA_servo          	is 0.
	local LS_servo          	is 0.
	local RS_servo          	is 0.
	local WA_servo          	is 0.
	local left_foot_part    	is 0.
	local right_foot_part   	is 0.
	local reactor_part      	is 0.
	local cockpit_part      	is 0.
	local rightshoulder_part	is 0.
	local leftshoulder_part 	is 0.
	local waist_part        	is 0.
	local BDA_part          	is 0.
	local torso_part			is 0.
	local hips_part				is 0.
	local docked				is false.
	
	local last_servo_count is 0.
	

	local LA_part_ID			is 0.
	local RA_part_ID			is 0.
	local LK_part_id			is 0.
	local RK_part_id			is 0.
	local LH_part_id			is 0.
	local RH_part_id			is 0.
	local LS_part_id			is 0.
	local RS_part_id			is 0.
	local WA_part_id			is 0.

	
	
	//} 
	

	
	//{ operational variables -------------------------------------------------------------------------------------------------------------------------------------------------
	
	local LH_smooth_target 			is 0.
	local LK_smooth_target 			is 0.
	local LA_smooth_target 			is 0.
	local RH_smooth_target 			is 0.
	local RK_smooth_target 			is 0.
	local RA_smooth_target 			is 0.

	local LH_raw_target 			is 0.
	local LK_raw_target 			is 0.
	local LA_raw_target 			is 0.
	local RH_raw_target 			is 0.
	local RK_raw_target 			is 0.
	local RA_raw_target 			is 0.

	local all_leg_servos is list(0,0,0,0,0,0).
	
	local last_move_time 			is 0.
	local last_energy_check_time	is 0.
	local last_throttle 			is 0.
	local next_frame_duration 		is 0.
	local next_speed_multiplier 	is 0.
			
	local warn_energy_amount		is 0.
	local min_energy_amount			is 0.
	
	local rebooting					is false.
	local animation_yielded			is false.	
	local process_yielded			is false.
	local ai 						is false.
	
	local transferLeft 				is 0.								
	local transferRight 			is 0.
	local transferBalanced 			is 0.
	local walk_process				is 0.
	local idle_process				is 0.
	
	local electric_charge			is 0.

	//} 	
	

	
	//{ CURRENT state "class" ------------------------------------------------------------------------------------------------------------------------------------------------------------
	
	local animation 				is 0.					// a list of function pointers called in sequence for the current animation
	local animation_index			is 0.					// next animation function that will be called			
	local smooth_targets 			is 0.					// will point to walk smooth, idle, or reverse smooth, depending on the current animation
	local raw_targets 				is 0.					// will point to walk, idle or reverse targets, depending on the current animation
	local frame_time 				is 0.	
	local getThrottle				is processYield@.
	local secondary_process			is 0.
	local process_index				is 0.
	
	//} 
	


	
	//{ WALK state "class", also includes reverse info since they behave the same way -----------------------------------------------------------------------------------------------------
	
	function walk_processThrottle {
		if MEK_LOCK_THROTTLE { return 1. }
		
		local t is 0.
		if ai { set t to round(ship:control:wheelthrottle, 1). }
		else { set t to round(ship:control:pilotwheelthrottle, 1). }
		
		if t <> last_throttle {
			if t = 0 or t * last_throttle < 0 { idle(). }
			else {
				set next_frame_duration to frame_time / abs(t).
				set next_speed_multiplier to 1 / (20 * next_frame_duration).			
			}
			set last_throttle to t.
		}
		return 1.
	}	
	local walk_frame_time 			is 0.					// time servos should take to move between positions when walking. Different for each mech, set at mech startup.
	local reverse_frame_time		is 0.					// 
	local walk_targets 				is 0.					// constant matrix defined per mech, initialized at startup
	local walk_smooth_targets 		is 0.					// constant matrix calculated from walk targets, smooths out animation by setting the target one ahead if moving in
	local reverse_targets 			is 0.					// constant matrix calculated from walk targets
	local reverse_smooth_targets 	is 0.					// constant matrix calculated from reverse targets		
	local walk_animation 			is list (				//{
		stopServos@,
		shiftMassLeft@,
		getSmoothTargets@			:bind(0),
		getRawTargets@				:bind(0),
		moveServos@,
		// cycle restarts here		
		getSmoothTargets@			:bind(1),
		getRawTargets@				:bind(1),
		yieldAnimation@	    		:bind(YIELD_TO_MOVE),
		moveServos@,		
		getSmoothTargets@			:bind(2),
		getRawTargets@				:bind(2),
		yieldAnimation@	    		:bind(YIELD_TO_MOVE),
		moveServos@,		
		getSmoothTargets@			:bind(3),
		getRawTargets@				:bind(3),
		yieldAnimation@	    		:bind(YIELD_TO_TRANSFER),		
		shiftMassRight@,			
		yieldAnimation@	    		:bind(YIELD_TO_MOVE),		
		moveServos@,		
		getSmoothTargets@			:bind(4),
		getRawTargets@				:bind(4),
		yieldAnimation@	    		:bind(YIELD_TO_MOVE),		
		moveServos@,		
		getSmoothTargets@			:bind(5),
		getRawTargets@				:bind(5),
		yieldAnimation@	    		:bind(YIELD_TO_MOVE),
		moveServos@,			
		getSmoothTargets@			:bind(6),
		getRawTargets@				:bind(6),
		yieldAnimation@	    		:bind(YIELD_TO_MOVE),
		moveServos@,			
		getSmoothTargets@			:bind(7),
		getRawTargets@				:bind(7),
		yieldAnimation@	    		:bind(YIELD_TO_TRANSFER),
		shiftMassLeft@,			
		yieldAnimation@	    		:bind(YIELD_TO_MOVE),
		moveServos@,			
		getSmoothTargets@			:bind(0),
		getRawTargets@				:bind(0),
		yieldAnimation@	    		:bind(YIELD_TO_MOVE),
		moveServos@,					
		goto@						:bind(5):bind(42)
	). //}	
	local player_walk_process 		is list (				//{
		walk_processThrottle@,
		processYield@,
		processYaw@,
		processYield@,
		processPitch@,
		processYield@,
		processEnergyLevel@,
		processYield@,
		processDocked@,
		processYield@,		
		processActive@,
		processYield@,
		goto@						:bind(0):bind(12)
	).														//}
	
	local ai_walk_process 			is list (				//{
		walk_processThrottle@,
		processYield@,
		processYield@,
		processEnergyLevel@,
		processYield@,
		processYield@,
		processActive@,
		processYield@,
		processYield@,
		goto@						:bind(0):bind(9)
	).														//}
		
	//} 

	
	
	//{ IDLE state "class" ------------------------------------------------------------------------------------------------------------------------------------------------------------

	function idle_processThrottle {		
		if animation_index = idle_animation:length - 1 {
			local t is 0.
			if ai { set t to round(ship:control:wheelthrottle, 1). }
			else { set t to round(ship:control:pilotwheelthrottle, 1). }
			if t <> 0 {
				if t > 0 { walk(). }
				else { reverse(). }
				set next_frame_duration to frame_time / abs(t).
				set next_speed_multiplier to 1 / (20 * next_frame_duration).	
			}
		}
		return 1.
	}		
	local idle_frame_time			is 0.					// time servos should take to move between positions when idling. Different for each mech, set at mech startup.	
	local idle_targets 				is 0.					// constant matrix defined per mech, initialized at startup				
	local idle_animation 			is list (				//{
		stopServos@,
		setThrottle@				:bind(0.5),
		getSmoothTargets@			:bind(0),
		getRawTargets@				:bind(0),
		moveServos@,			
		yieldAnimation@				:bind(YIELD_TO_MOVE),
		shiftMassLeft@,
		shiftMassBalanced@,
		endAnimation@
	).														//}		
	local player_idle_process 		is list (				//{
		idle_processThrottle@,
		processYield@,
		processYaw@,
		processYield@,
		processPitch@,
		processYield@,
		processEnergyLevel@,
		processYield@,
		processActive@,
		processYield@,
		goto@						:bind(0):bind(10)
	).														//}
	
	local ai_idle_process			is list (				//{
		idle_processThrottle@,
		processYield@,
		processYield@,
		processEnergyLevel@,
		processYield@,
		processYield@,
		processActive@,
		processYield@,
		processYield@,
		goto@						:bind(0):bind(9)
	).														//}
	
	//} 

	
	
	//{ SLEEP state "class"  ---------------------------------------------------------------------------------------------------------------------------------------------------------
	
	local sleep_targets 			is 0.
	local sleep_animation 			is list (				//{
		stopServos@,
		recenterTorso@,
		setThrottle@				:bind(0.6),
		getSmoothTargets@			:bind(0),
		getRawTargets@				:bind(0),
		moveServos@,
		yieldAnimation@				:bind(next_frame_duration*2),
		shiftMassLeft@,
		shiftMassBalanced@,		
		shiftMassSleep@,
		yieldAnimation@				:bind(1),
		endAnimation@
	). //}
	local sleep_process is list (							//{
		processReboot@,	
		hardWait@					:bind(1),
		processYield@,
		processUndocked@,
		hardWait@					:bind(1),
		processYield@,
		processActive@,
		processYield@,
		goto@						:bind(0):bind(8)
	). 														//}
	
	//} 

	
	
	//{ ANIMATION functions -----------------------------------------------------------------------------------------------------------------------------------------
	
	function moveServos  {
		LH_servo:moveto(LH_smooth_target, abs(LH_raw_target - LH_servo:position) * next_speed_multiplier).
		RH_servo:moveto(RH_smooth_target, abs(RH_raw_target - RH_servo:position) * next_speed_multiplier).
		LK_servo:moveto(LK_smooth_target, abs(LK_raw_target - LK_servo:position) * next_speed_multiplier).
		RK_servo:moveto(RK_smooth_target, abs(RK_raw_target - RK_servo:position) * next_speed_multiplier).
		LA_servo:moveto(LA_smooth_target, abs(LA_raw_target - LA_servo:position) * next_speed_multiplier).
		RA_servo:moveto(RA_smooth_target, abs(RA_raw_target - RA_servo:position) * next_speed_multiplier).
		set last_move_time to time:seconds.
		return 1.
	}		
	
	// if we don't need to animate allow other processing to occur
	function yieldAnimation {
		parameter pFraction.
		if (time:seconds - last_move_time) >= (next_frame_duration * pFraction) {
			set animation_yielded to false.
			return 1. 
		}
		else { 
			set animation_yielded to true.
			return 0. 
		}
	}	

	function endAnimation {
		set animation_yielded to true.
		return 0.
	}	
	
	function stopServos { 		
		LH_servo:stop().
		LK_servo:stop().
		LA_servo:stop().
		RH_servo:stop().
		RK_servo:stop().
		RA_servo:stop().
		return 1.
	}

	function getSmoothTargets {
		parameter i.
		set LH_smooth_target to smooth_targets[0][i].
		set LK_smooth_target to smooth_targets[1][i].
		set LA_smooth_target to smooth_targets[2][i].
		set RH_smooth_target to smooth_targets[3][i].
		set RK_smooth_target to smooth_targets[4][i].
		set RA_smooth_target to smooth_targets[5][i].
		return 1.
	}
	
	function getRawTargets {
		parameter i.
		set LH_raw_target to raw_targets[0][i].
		set LK_raw_target to raw_targets[1][i].
		set LA_raw_target to raw_targets[2][i].
		set RH_raw_target to raw_targets[3][i].
		set RK_raw_target to raw_targets[4][i].
		set RA_raw_target to raw_targets[5][i].
		return 1.	
	}	
	
	function shiftMassLeft {
		set transferLeft:active to true.
		return 1.
	}

	function shiftMassRight {
		set transferRight:active to true.
		return 1.
	}

	function shiftMassBalanced {	
		if transferLeft:active { 
			return 0.
		} else {
			set transferBalanced to transfer("MEKBalancingFluid", left_foot_part, right_foot_part, 1).
			set transferBalanced:active to true.
			return 1.
		}
	}	
	
	function shiftMassSleep {
		wait 0.2.
		local t1 is transfer("MEKBalancingFluid", left_foot_part, torso_part, 0.5).
		local t2 is transfer("MEKBalancingFluid", right_foot_part, torso_part, 0.5).
		set t1:active to true.
		set t2:active to true.
		wait 0.2.
		return 1.
	}
	
	function shiftMassWake {
		local t1 is transfer("MEKBalancingFluid", torso_part, left_foot_part, 0.5).
		local t2 is transfer("MEKBalancingFluid", torso_part, right_foot_part, 0.5).
		set t1:active to true.
		set t2:active to true.
		wait 0.3.
		return 1.
	}
	
	function setThrottle {
		parameter t.		
		set next_frame_duration to frame_time / abs(t).
		set next_speed_multiplier to 1 / (20 * next_frame_duration).
		return 1.
	}	
	
	function goto {
		parameter pIndex.
		parameter pCurrent.
		return pIndex - pCurrent.
	}
	
	function hardWait {	
		parameter pwait.
		wait pwait.
		return 1.
	}
	
	//} 

	
	
	//{ PROCESSING functions -----------------------------------------------------------------------------------------------------------------------------------------
	
	function processYaw {
		if ai { return 1. } // decided to let the ai control torso directly
		if MEK_action_recenter {
			if not MEK_action_recentering {
				recenterTorso().
				set MEK_action_recentering to true.
			} else if (WA_servo:ismoving or LS_servo:ismoving or RS_servo:ismoving) {
				return 1.
			} else {
				set MEK_action_recentering to false.
				set MEK_action_recenter to false.
			}
		}
				
					
		local ty is ship:control:pilotroll.					
		if abs(ty) > 0.04 {
			set WA_servo:speed to 3 * ty * ty.
			if ty < 0 { WA_servo:moveleft(). } else { WA_servo:moveright(). }
		} else if WA_servo:ismoving {
			WA_servo:stop().
		}			
		return 1.
	}	
	
	function processPitch {
		if (ai or MEK_action_recenter) { return 1. } // decided to let the ai control torso directly
		local tp is ship:control:pilotpitch.		

		if abs(tp) > 0.04 {
			// sensitivity curves are quadratic
			set LS_servo:speed to 3 * tp * tp. 
			set RS_servo:speed to 3 * tp * tp.
			if tp < 0 { 
				if LS_servo:position > -30 {
					LS_servo:moveleft(). 
					RS_servo:moveleft().
				} else {
					LS_servo:stop().
					RS_servo:stop().
				}
			} else { 
				if LS_servo:position < 30 {
					LS_servo:moveright(). 
					RS_servo:moveright().
				} else {
					LS_servo:stop().
					RS_servo:stop().
				}
			}
		} else { 
			if LS_servo:ismoving { LS_servo:stop(). }
			if RS_servo:ismoving { RS_servo:stop(). }
		}
		return 1.
	}

	function processYield {
		set process_yielded to true.
		return 1.
	}
	
	function processDocked {
		if cockpit_part:uid <> ship:rootpart:uid { 
			set docked to true.		
			sleep(). 			
			return 0.
		} else {
			return 1.
		}
	}
	
	function processUndocked {
		if cockpit_part:uid = ship:rootpart:uid and docked { 
			set docked to false.
			wait 0.2.
			idle(). 
			return 0.
		} else {
			return 1.
		}
	}
	
	function processReboot {
		if rebooting { 
			wait 3.
			reboot. 
			return 0. // not really necessary!
		} else {
			return 1.
		}
	}
	
	function processEnergyLevel {	
		if rebooting { return 1. }
		if time:seconds - last_energy_check_time < 2 { return 1. }
		
		set last_energy_check_time to time:seconds.
		set electric_charge to ship:electriccharge.	
		if electric_charge < min_energy_amount { 	
			set rebooting to true.		
			statusMessage("BELOW MINIMUM SAFE ENERGY LEVEL. SHUTTING DOWN.", 3).
			sleep().
			return 0.
		} else if electric_charge < warn_energy_amount {
			statusMessage("ENERGY LEVEL CRITICAL. GYROS DISABLED.", 2).		
			sas off.
			return 1.
		} else {			
			return 1.
		}
	}	
	
	function processActive {
		if warp = 0 and ship:unpacked and (ship = KUniverse:activevessel or ai or MEK_LOCK_THROTTLE) {
			return 1.
		} else {
			wait 2.
			return 0.
		}	
	}
	
	//}

	
	
	//{ STARTUP functions -----------------------------------------------------------------------------------------------------------------------------------------
			
	function startup {
		parameter pMech.
		parameter pAI is false.
		
		set ai to pAI.

		clearscreen.
				
		statusMessage("STARTUP SEQUENCE INITIATED", 1.5).	
		wait 0.5.
		
		findParts().
		findServos().				
		checkShoulderOrientation(LS_servo).
		checkShoulderOrientation(RS_servo).				
		setAccelerations().		
			
		set rebooting 				to false.						
		set transferLeft 			to transferall("MEKBalancingFluid", right_foot_part, left_foot_part).
		set transferRight 			to transferall("MEKBalancingFluid", left_foot_part, right_foot_part).				
		
		set walk_frame_time 		to FRAME_TIMES[pMech].
		
		if pMech = "MDG" 			{ set pMech to "TBR". } 	// shared legs
		else if pMech = "HBR" 		{ set pMech to "SMN". }	 	// shared legs

		set walk_targets 			to matrix[pMech]["WALK"].
		set idle_targets 			to matrix[pMech]["IDLE"].
		set sleep_targets			to matrix[pMech]["SLEEP"].		

		set reverse_frame_time 		to walk_frame_time * 1.6.
		set idle_frame_time			to walk_frame_time * 2.
		set walk_smooth_targets 	to createSmoothTargets(walk_targets). 
		set reverse_targets 		to createReverseTargets(walk_targets).
		set reverse_smooth_targets 	to createSmoothTargets(reverse_targets).
				
		if ai {
			set walk_process to ai_walk_process.
			set idle_process to ai_idle_process.
		} else {
			set walk_process to player_walk_process.
			set idle_process to player_idle_process.
		}
		
		until (ship:electriccharge >= warn_energy_amount) { 		
			statusMessage("ENERGY LEVEL BELOW THRESHHOLD: " + (round(ship:electriccharge / warn_energy_amount, 2) * 100) + "%", 1). 
			wait 1.
		}
						
		idle().					
									
		wait 0.1.
		statusMessage("Reactor online.", 2).
		statusMessage("Sensors online.", 2).  
		statusMessage("Weapons online.", 2).  
		wait 2.2.
		brakes on.
		sas on.
		statusMessage("All systems nominal.", 1.5).		
	}
	
	//-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	
	function findParts {
		// ONE FUNCTION TO RULE THEM ALL! Ugly but meh, it's a setup routine, it only gets called once.	
		print "RUNNING SYSTEM CHECK...".
		local lft 		is false.
		local rgt 		is false.
		local eng 		is false.
		local pit 		is false.
		local hip 		is false.
		local bda 		is false.
		local torso 	is false.
		local allparts 	is 0.
		list parts in allparts.
		for p in allparts {
		
			if p:hasmodule("MissileFire") {
			
				set BDA_part to p.
				set bda to true.
				
			} else if hasResource(p, "MEKBalancingFluid") and p:name:contains("-BALANCE") {
			
				if vdot(ship:facing:starvector, p:position) < 0 {
					set left_foot_part to p.
					set lft to true.					
				} else {				
					set right_foot_part to p.
					set rgt to true.					
				}
				
			} else if p:name = ("MEK-REACTOR") {
			
				set reactor_part to p.
				set eng to true.
				
			} else if p:name:startswith("MEK-COCKPIT") {
			
				set cockpit_part to p.
				set min_energy_amount to getResourceCapacity(cockpit_part, "ElectricCharge").
				
				if ship:rootpart <> cockpit_part { error("STRUCTURAL DEFECT FOUND: MEK-COCKPIT is not the root of the vessel"). }
				if min_energy_amount > 0 { set pit to true. }	
				set torso_part to cockpit_part:children[0].
				
				if getResourceCapacity(torso_part, "MEKBalancingFluid") = 1 {					
					set warn_energy_amount to getResourceCapacity(torso_part, "ElectricCharge") * 0.2.
					if warn_energy_amount > 0 { set torso to true.}					
				}
				
			} else if p:hasmodule("ModuleCommand") and p:name:endswith("-HIPS") {
			
				set hips_part to p.
				p:getmodule("ModuleCommand"):doevent("control from here").
				set hip to true.
				
			} 
			
			if lft and rgt and eng and pit and hip and bda and torso { break. }
		}
		
		set warn_energy_amount to min_energy_amount + warn_energy_amount.
		
		print ("LEFT GYRO"  	 :padright(20) + lft).
		print ("RIGHT GYRO"      :padright(20) + rgt).
		print ("REACTOR"         :padright(20) + eng).
		print ("BACKUP POWER"    :padright(20) + pit).
		print ("MAIN GYRO"       :padright(20) + hip).
		print ("WEAPONS MANAGER" :padright(20) + bda).
		print ("CENTER TORSO"    :padright(20) + torso).
		print ("MIN CHARGE"      :padright(20) + min_energy_amount).
		print ("WARN CHARGE"     :padright(20) + warn_energy_amount).
		
		if not (lft and rgt and eng and pit and hip and bda and torso) { error("SYSTEM CHECK FAILED"). }
	}	
	
	
	//function checkServosExist {
	//	local s is addons:IR:allservos.
	//	if (s:length <> last_servo_count) {
	//		set last_servo_count to s:length.
	///		local ids is list().
	//		for srv in s {
	//			ids:add(srv:part:uid).
	//		}
	//		if not ids:contains(LA_part_id) { set LA_part_id to 0. }
	//		if not ids:contains(RA_part_id) { set RA_part_id to 0. }
	//		if not ids:contains(LK_part_id) { set LK_part_id to 0. }
	//		if not ids:contains(RK_part_id) { set RK_part_id to 0. }
	//		if not ids:contains(LH_part_id) { set LH_part_id to 0. }
	//		if not ids:contains(RH_part_id) { set RH_part_id to 0. }
	//		if not ids:contains(WA_part_id) { set WA_part_id to 0. }
	//		if not ids:contains(LS_part_id) { set LS_part_id to 0. }
	//		if not ids:contains(RS_part_id) { set RS_part_id to 0. }
	//	}							
	//}
		
	
	//-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	
	function findServos {
		print "RUNNING SERVO CHECK...".
		
		set last_servo_count to addons:IR:allservos:length.
		
		local s is sortServosByHeight().	
		if s:length <> 9 error("Found " + s:length + " out of 9 expected servos").
		for srv in s {
			print ("   " + srv:part:name + " OK").
		}

		if vdot(ship:facing:starvector, s[0]:part:position) < 0 {
			set LA_servo to s[0].
			set RA_servo to s[1].
		} else {
			set LA_servo to s[1].
			set RA_servo to s[0].
		}
		
		if vdot(ship:facing:starvector, s[2]:part:position) < 0 {
			set LK_servo to s[2].
			set RK_servo to s[3].
		} else {
			set LK_servo to s[3].
			set RK_servo to s[2].
		}	
		
		if vdot(ship:facing:starvector, s[4]:part:position) < 0 {
			set LH_servo to s[4].
			set RH_servo to s[5].
		} else {
			set LH_servo to s[5].
			set RH_servo to s[4].
		}	
		
		set WA_servo to s[6].
		
		if vdot(ship:facing:starvector, s[7]:part:position) < 0 {
			set LS_servo to s[7].
			set RS_servo to s[8].
		} else {
			set LS_servo to s[7].
			set RS_servo to s[8].
		}			
		
		set rightshoulder_part to RS_servo:part.
		set leftshoulder_part to LS_servo:part.
		set waist_part to WA_servo:part.

		set all_leg_servos[0] to LH_servo.
		set all_leg_servos[1] to LK_servo.
		set all_leg_servos[2] to LA_servo.
		set all_leg_servos[3] to RH_servo.
		set all_leg_servos[4] to RK_servo.
		set all_leg_servos[5] to RA_servo.
		for srv in all_leg_servos { 
			if srv:configspeed <> 20 {
				error("SERVO " + srv:part:tag + " CONFIG SPEED != 20").
			}
		}
		
		set LA_part_ID to LA_servo:part:uid.
		set RA_part_ID to RA_servo:part:uid.
		set LK_part_id to LK_servo:part:uid.
		set RK_part_id to RK_servo:part:uid.
		set LH_part_id to LH_servo:part:uid.
		set RH_part_id to RH_servo:part:uid.
		set LS_part_id to LS_servo:part:uid.
		set RS_part_id to RS_servo:part:uid.
		set WA_part_id to WA_servo:part:uid.
		
		
	}
	
	
	//-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	
	// move the arms a little bit to make sure that pitch input direction is not inverted
	function checkShoulderOrientation {
		parameter s.
		print "CONFIGURING SHOULDER ACTUATOR...".
		set s:acceleration to 20.
		set s:speed to 10.
		wait 0.01.
		s:movecenter().
		wait 0.6.
		s:stop().
		wait 0.2.
		local idot is vdot(hips_part:facing:forevector, s:part:facing:topvector).
		set s:speed to 2.
		wait 0.01.
		s:moveleft().
		wait 0.2.
		s:stop().
		wait 0.01.
		local ndot is vdot(hips_part:facing:forevector, s:part:facing:topvector).
		print "ndot " + round(ndot, 3) + " idot " + round(idot, 3).
		if ndot < idot {
			set s:inverted to not s:inverted.
		}
		
		if MEK_INVERT_PITCH { set s:inverted to not s:inverted. }
		set s:speed to 20.
		wait 0.01.
		s:movecenter().
		wait 0.4.
		set s:speed to 1.
		print "SHOULDER ACTUATOR CONFIGURATION COMPLETE".
		
	}
	
	function setAccelerations {
		for s in all_leg_servos { set s:acceleration to LEG_ACCELERATION. }
		set WA_servo:acceleration to 6.
		set LS_servo:acceleration to 6.
		set RS_servo:acceleration to 6.
	}
	
	//-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	// helper function used to find balance parts
	function hasResource {
		parameter p, resourceName.
		local hr is false.
		for res in p:resources {
			if res:name = resourceName {
				set hr to true.
				break.
			}
		}
		return hr.
	}

	//-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	// helper function used to find balance parts
	function getResourceCapacity {
		parameter p, rname.
		local rlist is 0.
		local c is 0.
		set rname to rname:toupper().
		for res in p:resources {
			if res:name:toupper() = rname {
				print "Found capacity " + res:capacity.
				set c to res:capacity.
				break.
			}
		}		
		return c.
	}	
	
	//-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	// round off the hard vertices of the animation keyframe endpoints. Can cause inaccuracy but also prevents servos from jerking
	function createSmoothTargets {			
		parameter keyframePositions.
		//parameter offsetAmount = -1.
		local result is list().		
		local sc is keyframePositions:length.
		local pc is keyframePositions[0]:length.
		local lastpos is 0.
		local thispos is 0.		
		
		for i in range(sc) {
			result:add(list()).			
			for j in range(pc) {				
				set lastpos to keyframePositions[i][offset(pc, j, -1)].				
				set thispos to keyframePositions[i][j].
				result[i]:add(thispos + ((thispos - lastpos) * ERROR_MARGIN)).
			}
		}
		return result.
	}
	
	function createReverseTargets {
		parameter KeyframePositions.
		local result is list().
		local sc is keyframePositions:length.
		local pc is keyframePositions[0]:length.
		
		for i in range(sc) {
			result:add(list(keyframePositions[i][0])).
			for j in range(pc-1, 0) {
				result[i]:add(keyframePositions[i][j]).
			}
		}
		return result.
	}	
	
	//-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	// parts dont have geocordinates, only vessels do, so use vectors to determine which of two parts is higher
	function p2isHigher {
		parameter p1, p2.	
		return vdot(ship:facing:topvector, p1) >= vdot(ship:facing:topvector, p2).
	}

	//-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	// by sorting the servos we can tell which ones are the ankles, knees, hips, waist and shoulders without having to specify them during construction
	// ignore tagged parts
	
	function sortServosByHeight {
		//local s is addons:IR:allservos:copy.
		local s is list().
		
		for srv in addons:IR:allservos {
			if srv:part:tag = "" {
				s:add(srv).
			}
		}
				
		local t is 0.
		local j is 0.
		
		for i in range(1, s:length) {
			set t to s[i].
			set j to i - 1.
			until j < 0 or p2isHigher(t:part:position, s[j]:part:position) {
				set s[j+1] to s[j].
				set j to j - 1.
			}
			set s[j + 1] to t.	
		}
		
		return s.
	}
	
	function offset { 
		parameter pArrayLength. parameter pOriginIndex. parameter pDisplacement.
		return mod((abs(pDisplacement) * pArrayLength) + pOriginIndex + pDisplacement, pArrayLength).	
	}
	
	//} ----------------------------------------------------------------------------------------------------------------------------------------------
		

	
	//{ state switching  ------------------------------------------------------------------------------------------------------------------------------
	
	function walk {
		set animation_yielded 	to false.
		set animation 	   		to walk_animation.
		set smooth_targets 		to walk_smooth_targets.
		set raw_targets    		to walk_targets.
		set animation_index    	to 0.
		set frame_time     		to walk_frame_time.
		set secondary_process	to walk_process.
		set process_index		to 0.
		set last_throttle  		to 0.
		set last_move_time 		to time:seconds.
		return 1.
	}
	
	function idle {
		set animation_yielded 	to false.
		set animation  			to idle_animation.
		set smooth_targets  	to idle_targets.
		set raw_targets     	to idle_targets.
		set animation_index     to 0.
		set frame_time      	to idle_frame_time.
		set secondary_process	to idle_process.
		set last_throttle   	to 0.
		set last_move_time  	to time:seconds.
		shiftMassWake().		
		reactor_part:activate.		
		return 1.
	}
		
	function reverse {
		set animation_yielded 	to false.
		set animation   		to walk_animation.
		set smooth_targets  	to reverse_smooth_targets.
		set raw_targets     	to reverse_targets.
		set animation_index     to 0.
		set frame_time      	to reverse_frame_time.
		set secondary_process	to walk_process.
		set last_throttle   	to 0.
		set last_move_time  	to time:seconds.
		return 1.
	}

	function sleep {
		BDA_part:getmodule("MissileFire"):doaction("fire guns (toggle)", false).	
		set animation_yielded 	to false.
		set secondary_process	to sleep_process.
		set process_index		to 0.		
		set animation			to sleep_animation.
		set animation_index		to 0.		
		set smooth_targets		to sleep_targets.
		set raw_targets			to sleep_targets.
		set frame_time			to 0.8.
		set last_throttle		to 0.
		reactor_part:shutdown.
		return 1.
	}

	//} 
	

	
	//{ random crap ---------------------------------------------------------------------------------------------------------------------------------------------
	
	function error {
		parameter txt.
		print "ERROR: " + txt.
		shutdown.
	}
		
	function recenterTorso {
		WA_servo:stop().
		LS_servo:stop().
		RS_servo:stop().
		wait 0.01.
		WA_servo:moveto(0, 5).
		LS_servo:moveto(0, 5).
		RS_servo:moveto(0, 5).		
		return 1.
	}

	function statusMessage {
		parameter msg, duration.
		if not ai and KUniverse:activevessel = ship { hudtext(msg, duration, 4, 30, green, false). }
	}.			

	//}
	
	// animation gets priority
	// if the animation wasn't busy then use the frame to run other stuff and advance the other-stuff process index
	function update {			
		set animation_index to animation_index + animation[animation_index]().		
		if animation_yielded { 
			set process_yielded to false.
			set process_index to process_index + secondary_process[process_index](). 
		}
		return animation_yielded and process_yielded and not rebooting.
	}
	
	
	//{ public methods -------------------------------------------------------------------------------------------------------------------------

	global MEK_update is update@.
	global MEK_startup is startup@.
	global MEK_recenter is recenterTorso@.
	global MEK_walk_processThrottle is walk_processThrottle@.
	global MEK_sleep is sleep@.
	global MEK_idle is idle@.
	
	function get_cockpit 		{ return cockpit_part.	} 			global MEK_get_cockpit 			is get_cockpit@.
	function get_BDA 			{ return BDA_part. }				global MEK_get_BDA 				is get_BDA@.	
	function get_WA_servo		{ return WA_servo. }				global MEK_get_WA_servo			is get_WA_servo@.
	function get_LS_servo		{ return LS_servo. }				global MEK_get_LS_servo			is get_LS_servo@.
	function get_RS_servo		{ return RS_servo. }				global MEK_get_RS_servo			is get_RS_servo@.
	function get_hips			{ return hips_part. } 				global MEK_get_hips				is get_hips@.
	function get_reactor		{ return reactor_part. } 			global MEK_get_reactor			is get_reactor@.


	//}
}

ON ABORT {
	set MEK_LOCK_THROTTLE to not MEK_LOCK_THROTTLE.
	preserve.
}
