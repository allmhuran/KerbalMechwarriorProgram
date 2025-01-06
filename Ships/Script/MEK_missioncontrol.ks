function runBriefing {
	parameter briefing.
	local j is briefing:length.
	for i in range(j) {
		hudtext(briefing[i], (2.2*j-i)*2.2, 1, 28, white, true).
		wait 2.2.
	}			
}


global msn1 is list(
	"Operation Raindance. Mission Type: Assault",
	" ",
	"Situation:",
	"  A heavily defended chemical plant is located at approximate bearing 179 for 3km.",
	"  It is composed of several small structures and would be very time consuming to destroy by direct fire.",
	"  You will perform a ranged saturation bombardment with long range missiles.",
	"  Warning: You are not equipped for a firefight with enemy mechs.",
	"  Friendly units have been sent ahead to cover your approach and distract the defenders while you perform your attack.",
	" ",	
	"Objectives:",
	"  1) Destroy chemical plant bearing 179 for 3km.",
	"  2) Fall back to dropship for extraction."
).

runBriefing(msn1).
	
	
	