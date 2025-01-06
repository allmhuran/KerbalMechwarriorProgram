@lazyglobal off.
global actor_scene is 0.
global actor_process_index is 0.
{

	
	// mech components -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	
	local cockpit        			is 0.
	local BDA_module     			is 0.
	local hips						is 0.
	local WA_servo					is 0.
	local RS_servo					is 0.
	local LS_servo					is 0.
	local L_elbow					is 0.
	local director is ship.
	local vwalk is 0.
	local vtorso is 0.
	local vcockpit is 0.
	local steervec is 0.
	local jumpjet1 is 0.
	local jumpjet2 is 0.
	local sparkies is list().
	local srmpod is 0.
	local shoulderpivot is 0.
	local smnUAC is 0.

	
	local target_selected  			is false.
	local target_ship				is 0.
	local target_list				is 0.
	local target_check				is 0.
	local target_inrange			is false.
	local target_range				is 0.
	local target_position			is 0.
	local target_pitch   			is 0.
	local target_yaw     			is 0.
	
	local time_soft_wait_end 		is 0.
	local first_weapon				is "".
	local current_weapon			is "".
	
	local max_reactor				is 0.
	
	// current state vars -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	
	local process 						is 0.
	
	
	local process_TBR1 is list (
		waitForScene@		:bind(1),
		walkTowardsAt@		:bind(0):bind(0.3),
		setSoftWait@		:bind(0.5),
		softWait@,
		walkTowardsAt@		:bind(0):bind(1.0),
		setSoftWait@		:bind(9),
		softWait@,
		turnTorsoAt@		:bind(-40):bind(1.2),
		setSoftWait@		:bind(3),
		softWait@,
		turnTorsoAt@		:bind(40):bind(1.2),
		setSoftWait@		:bind(4),
		softWait@,
		halt@,
		setSoftWait@		:bind(2),
		softWait@,
		waitForScene@		:bind(2),						//--------------------------------------------------------
		turnTorsoAt@		:bind(15):bind(1),
		walkTowardsAt@		:bind(0):bind(0.6),				
		setSoftWait@		:bind(6),
		softWait@,
		walkTowardsAt@		:bind(30):bind(0.5),
		turnTorsoAt@		:bind(-40):bind(0.6),
		setSoftWait@		:bind(7),
		softwait@,
		halt@,
		setSoftWait@		:bind(2),
		softWait@,
		waitforScene@		:bind(3),						//--------------------------------------------------------		
		turnTorsoAt@		:bind(6):bind(2),
		setSoftWait@		:bind(0.5),
		softWait@,
		turnTorsoAt@		:bind(-17):bind(0.9),
		setSoftWait@		:bind(3),
		softWait@,
		turnTorsoAt@		:bind(5):bind(1),
		pointArmsAt@		:bind(20):bind(2),
		setSoftWait@		:bind(5),
		softWait@,
		doNothing@	
	).
	
	local process_TBR2 is list ( // perfect 20170204 7 pm
		getTBR2Parts@,
		getDirector@,
		waitForScene@		:bind(1),
		setSoftWait@		:bind(2),
		softWait@,
		turnTorsoAt@		:bind(75):bind(2.7),
		pointArmsAt@		:bind(15):bind(0.8),
		doSparks@			:bind(0),
		setSoftWait@		:bind(1.2),
		softWait@,
		doSparks@			:bind(1),
		setSoftWait@		:bind(0.9),
		softWait@,
		turnTorsoAt@		:bind(-90):bind(2.8),
		pointArmsAt@		:bind(-25):bind(1),		
		doSparks@			:bind(0),
		setSoftWait@		:bind(2),
		softWait@,
		turnTorsoAt@		:bind(5):bind(1),		
		pointArmsAt@		:bind(5):bind(1),	
		setSoftWait@		:bind(0.4),
		softWait@,
		walkTowardsAt@		:bind(0):bind(0.5),			
		doSparks@			:bind(2),		
		doSparks@			:bind(3),
		setSoftWait@		:bind(1),
		softWait@,
		doSparks@			:bind(0),	
		setSoftWait@		:bind(0.5),		
		softWait@,
		halt@,
		setSoftWait@		:bind(1.9),
		softWait@,
		turnTorsoAt@		:bind(60):bind(1.9), // behind me...
		doSparks@			:bind(1),		
		pointArmsAt@		:bind(20):bind(0.9),						
		setSoftWait@		:bind(1.6),
		softWait@,
		doSparks@			:bind(1),			
		turnTorsoAt@		:bind(-60):bind(1.9),
		pointArmsAt@		:bind(-20):bind(0.9),	
		doSparks@			:bind(2),	
		setSoftWait@		:bind(8),
		softWait@,		
		doNothing@			
	).
	
	local process_SMN1 is list ( // perfect 20170204 7 pm
		getSMN1Parts@,
		setSoftWait@		:bind(1),
		softWait@,		
		getDirector@,
		MEK_sleep@,	
		waitForScene@		:bind(1),
		setSoftWait@		:bind(3.3),
		softWait@,
		MEK_idle@,
		setSoftWait@		:bind(1),
		softWait@,
		walkTowardsAt@		:bind(0):bind(0.7),
		setSoftWait@		:bind(4),
		softWait@,
		halt@,
		setSoftWait@		:bind(2),
		softWait@,
		jumpjet@,
		setSoftWait@		:bind(1),
		softWait@,
		doNothing@			
	).
	
	local process_SMN2 is list (
		getSMN2Parts@,		
		MEK_idle@,
		// waitForScene@		:bind(2),	
		// fireSRM@,
		// setSoftWait@		:bind(5),
		// softWait@,
		// walkTowardsAt@		:bind(20):bind(0.6),
		// setSoftWait@		:bind(2.5),
		// softWait@,
		// turnTorsoAt@		:bind(-45):bind(1),
		// setSoftWait@		:bind(0.5),
		// softWait@,
		// halt@,
		// setSoftWait@		:bind(2.2),
		// softWait@,
		// turnTorsoAt@		:bind(55):bind(8),		
		// setSoftWait@		:bind(1),
		// softWait@,
		// walkTowardsAt@		:bind(0):bind(0.8),
		// turnTorsoAt@		:bind(-15):bind(3),
		// setSoftWait@		:bind(0.5),
		// softWait@,
		// turnTorsoAt@		:bind(-30):bind(1.5),
		// setSoftWait@		:bind(0.5),
		// softWait@,
		// walkTowardsAt@		:bind(0):bind(0.4),
		// setSoftWait@		:bind(0.2),
		// softWait@,
		// walkTowardsAt@		:bind(-35):bind(0.8),
		// setSoftWait@		:bind(1),
		// softWait@,
		// walkTowardsAt@		:bind(-35):bind(0.8),		
		// turnTorsoAt@		:bind(30):bind(0.5),
		// setSoftWait@		:bind(4),
		// softWait@,
		// halt@,
		// setSoftWait@		:bind(2),
		// softWait@,
		// waitForScene@		:bind(1),					// scene 2, exterior -----------------------------------
		// setSoftWait@		:bind(7),
		// softWait@,
		// walkTowardsAt@		:bind(0):bind(0.7),
		// setSoftWait@		:bind(3),
		// softWait@,
		// halt@,
		// turnTorsoAt@		:bind(-100):bind(8),				
		// backhandUp@,
		// setSoftWait@		:bind(1.3),
		// softWait@,
		// fireUAC@,
		// turnTorsoAt@		:bind(100):bind(7),
		// backhandDown@,
		// setSoftWait@		:bind(0.5),
		// softWait@,
		// walkTowardsAt@		:bind(0):bind(0.6),
		// setSoftWait@		:bind(4),
		// softWait@,
		// halt@,
		// setSoftWait@		:bind(2),
		// softWait@,
		// waitForScene@		:bind(1),				// ready killing blow
		// walkTowardsAt@		:bind(0):bind(0.6),
		// setSoftWait@		:bind(5.6),
		// softWait@,
		// halt@,
		// setSoftWait@		:bind(0.5),
		// softWait@,
		// turnTorsoAt@		:bind(90):bind(2.5),
		// setSoftWait@		:bind(0.6),
		// softWait@,
		// forehandUp@,
		// doNothing@,
		waitForScene@		:bind(1),
		turnTorsoAt@		:bind(45):bind(3),
		setSoftWait@		:bind(6),
		softWait@,
		forehandUp@,
		fireUAC@,
		setSoftWait@		:bind(7),
		softWait@,
		doNothing@			
	).
	
	
		
	function state_act {
		parameter pActor.
		lights off.
		
		if pActor = "TBR1" { set process to process_TBR1. }
		else if pActor = "TBR2" { set process to process_TBR2. }
		else if pActor = "SMN1" { set process to process_SMN1. }
		else if pActor = "SMN2" { set process to process_SMN2. }
		
		set	actor_process_index 	   to 0.
		set ship:control:mainthrottle  to 0.
		set ship:control:wheelthrottle to 0.
		set max_reactor				   to ship:body:mass / body("kerbin"):mass. 
		MEK_recenter().	
	}	
		
		
	function getDirector {
		local tgts is list().
		list targets in tgts.
		for t in tgts {
			if t:name = "director" {
				print "found director.".
				set director to t.
				return 1.
			}
		}
		print "no director!".
		wait 2.
		return 0.	
	}
	
	function waitForScene {
		parameter pScene.
		
		unlock steering.
		MEK_recenter().	
		wait 0.5.
		if director:name = pScene or actor_scene = pScene {
			print "starting scene " +  pScene.
			return 1.
		} else {
			wait 0.2.
			return 0.
		}
	}
	
	function walkTowardsAt {
		parameter pAngle.
		parameter pThrottle.
		set ship:control:wheelthrottle to pThrottle.		
		unlock steering.		
		set steervec to angleaxis(pAngle, ship:facing:topvector) * ship:facing.
		lock steering to steervec.
		return 1.
	}
	
	function turnTorsoAt {	
		parameter pAngle.
		parameter pSpeed.
		WA_servo:stop().
		print "turn torso to " + (WA_servo:position + pAngle).
		WA_servo:moveto(WA_servo:position + pAngle, pSpeed).
		return 1.
	}
	
	function pointArmsAt {
		parameter pAngle.
		parameter pSpeed.
		LS_servo:moveto(LS_servo:position + pAngle, pSpeed).
		RS_servo:moveto(RS_servo:position + pAngle, pSpeed).
		return 1.
	}
			
	function backhandUp {
		shoulderpivot:moveto(-80, 9).	
		LS_servo:moveto(40, 8).
		L_elbow:moveto(-40, 8).
		
		return 1.
	}
	
	function backhandDown {
		shoulderpivot:moveto(0, 8).
		LS_servo:moveto(0, 8).
		L_elbow:moveto(0, 8).
		return 1.
	}
	
	function fireUAC {
		print "fireuac".
		smnUAC:doaction("fire (toggle)", true).
		wait 0.2.
		smnUAC:doaction("fire (toggle)", false).
		return 1.
	}
	
	function forehandUp {
		set LS_servo:acceleration to 6.
		set L_elbow:acceleration to 6.
		LS_servo:moveto(45, 1.5).
		L_elbow:moveto(20, 5).
		wait 0.5.
		L_elbow:moveto(-45, 5).
		wait 2.
		return 1.		
	}
	
		
	
	function fireSRM {
		srmpod:doevent("fire").
		return 1.
	}
		
	function halt {
		set ship:control:wheelthrottle to 0.
		return 1.
	}
	
	function doNothing {
		wait 1.
		reboot.
	}

	function sasoff {
		sas off.
		return 1.
	}
	
	function sason {
		sas on.
		return 1.
	}
	
	function jumpjet {
		set ship:control:mainthrottle to 0.68.
		rcs on.		
		sas on.
		turnTorsoAt(25, 0.6).
		jumpjet1:activate.
		jumpjet2:activate.		
		set ship:control:top to 1.
		wait 0.1.
		set ship:control:fore to 1.
		wait 1.7.
		set ship:control:fore to -1.
		wait 1.7.
		set ship:control:fore to 0.
		set ship:control:top to 0.
		wait 0.2.		
		set ship:control:top to 1.
		wait 0.1.			
		set ship:control:top to 0.
		wait 0.2.
		set ship:control:top to 1.
		wait 0.1.
		set ship:control:top to 0.
		wait 1.
		set ship:control:top to 1.
		wait 1.
		set ship:control:top to 0.		
		wait 1.
		set ship:control:top to 1.
		wait 0.4.
		set ship:control:top to 0.
		wait 0.7.
		jumpjet1:shutdown.
		jumpjet2:shutdown.
		rcs off.
		set ship:control:mainthrottle to 0.1.
		MEK_recenter().	
		return 1.
	}
	
	function doSparks {
		parameter pSparky.
		if pSparky >= sparkies:length {
			print "no such sparky".
		} else {
			sparkies[pSparky]:activate.
			wait 0.1.
			sparkies[pSparky]:shutdown.
		}
		return 1.
	}
	
	function goto {
		parameter pIndex.
		parameter pCurrent.
		return pIndex - pCurrent.
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
		
	function getTBR2Parts {
		local engs is list().
		list engines in engs.
		for eng in engs {
			if eng:tag = "sparky" { sparkies:add(eng). }
		}
		return 1.
	}
	
	function getSMN1Parts {
		local jets is ship:partsnamed("MW2JJ2").
		if (jets:length > 0) {
			set jumpjet1 to jets[0].
			set jumpjet2 to jets[1].
		}
		return 1.	
	}
	
	function getSMN2Parts {
		set srmpod to ship:partsdubbed("MW2 SRM Pod")[0]:getmodule("RocketLauncher").		
		local srvs is addons:IR:allservos.
		
		for srv in srvs {
			if srv:part:tag = "shoulderpivot" {
				set shoulderpivot to srv.			
				shoulderpivot:moveto(0, 4).
				set shoulderpivot:acceleration to 8.
			} else if srv:part:tag = "L_elbow" {
				set L_elbow to srv.
				set L_elbow:acceleration to 8.
			}
		}					 
		set smnUAC to ship:partstagged("UAC")[0]:getmodule("ModuleWeapon").
		smnUAC:doevent("toggle").
		set LS_servo:acceleration to 8.
		set WA_servo:acceleration to 7.
		set ship:control:mainthrottle to 0.3.
		return 1.
		
	}		
	
	
	function startup {	
		parameter pActor.
		wait 0.5.		
		clearscreen.		
		set cockpit 		to MEK_get_cockpit().
		set hips			to MEK_get_hips().
		set RS_servo		to MEK_get_RS_servo().
		set LS_servo		to MEK_get_LS_servo().
		set WA_servo		to MEK_get_WA_servo().		
		set BDA_module 		to MEK_get_BDA():getmodule("MissileFire").
		MEK_idle().
		wait 1.
		sas off.
		set sasmode to "stabilityassist".
		sas on.
		MEK_get_reactor():activate.
		set ship:control:mainthrottle to 0.2.
		//BDA_module:doaction("next weapon", true).
		
		
		
		state_act(pActor).
	}

	
	// run the current process index delegate and advance the process in the amount of the returned value
	function update {
		set actor_process_index to actor_process_index + process[actor_process_index]().
	}
		
		
	// expose callable interface to external librariers -----------------------------------------------------------------------------------------------------------
	global MEKAI_startup is startup@.
	global MEKAI_update is update@.
}

on ag1 {
	set actor_scene to actor_scene + 1.
	preserve.
}

on ag3 {
	set actor_scene to 0.
	set actor_process_index to 0.
	preserve.
}

on ag5 {
	set actor_scene to 2.
	set actor_process_index to 15.
	preserve.
}

on ag6 {
	set actor_scene to 3.
	set actor_process_index to 27.
	preserve.
}