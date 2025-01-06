run MEK.ksm.
run MEKAI.ksm.

MEK_startup("DWF", true).
MEKAI_startup().

until false {
	if ship:unpacked {
		if MEK_update() { MEKAI_update(). }
		wait 0.001.
	} else {
		wait 10.
	}
}
	
	
	