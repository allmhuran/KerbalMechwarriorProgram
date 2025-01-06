@lazyglobal off.

local BDA_module is 0.

local pts is 0.
list parts in pts.
for p in pts {
	if p:hasmodule("MissileFire") {
		set BDA_module to p:getmodule("MissileFire").
		break.
	}
}
	
// prevent guard mode turrets from firing so much, since they are super accurate
// since we can't tell if guard mode is on or off from the available fields,
// toggle two different things so that guard mode can only shoot 1/4 of the time.
	
local b is true.
	
until (false) {
	if ship:unpacked and warp = 0 and KUniverse:activevessel:distance < 1200 {
		BDA_module:doaction("toggle guard mode", true). 		
		if b {
			set b to not b.
			BDA_module:doaction("toggle target type", true).
		}
		wait 5.
	} else {
		wait 15.		
	}
}


	
	