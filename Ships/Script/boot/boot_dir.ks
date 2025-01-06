local rot is 0.
local pit is 0.
local sname is 1.

print "bootdir".

for srv in addons:IR:allservos {
	if srv:part:tag = "rot" {
		print "found rot".
		set rot to srv.
	} else if srv:part:tag = "pit" {
		print "found pit".
		set pit to srv.
	}
}


on abort {
	print "dir".
	set ship:name to "director".
	set sname to 1.
	preserve.
}

on ag1 {
	print "scene".
	set ship:name to "" + sname.
	set sname to sname + 1.
	preserve.
}
	

function processYaw {
					
		local ty is ship:control:pilotroll.					
		if abs(ty) > 0.04 {
			set rot:speed to 3 * ty * ty.
			if ty < 0 { rot:moveleft(). } else { rot:moveright(). }
		} else if rot:ismoving {
			rot:stop().
		}			
	}	
	
	
function processPitch {
	local tp is ship:control:pilotpitch.		

	if abs(tp) > 0.04 {
		set pit:speed to 3 * tp * tp. 
		if tp < 0 { 
			pit:moveleft().
		} else {
			pit:moveright().
		}
	} else { 
		if pit:ismoving { pit:stop(). }
	}	
}


until false {
	processYaw().
	wait 0.01.
	processPitch().
	wait 0.01.
}

	
