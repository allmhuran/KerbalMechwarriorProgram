run MEK.ksm.

MEK_startup("DWF").

until false {
	if ship:unpacked {
		MEK_update().
		wait 0.001.
	} else {
		wait 10.
	}
}
	
	
	