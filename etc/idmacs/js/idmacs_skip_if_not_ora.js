// Main function: idmacs_skip_if_not_ora
// Author: Lambert Boskamp
// Created: 2013-04-05
function idmacs_skip_if_not_ora(Par){
	var SCRIPT = "idmacs_skip_if_not_ora: ";

	var lv_dbtype = "%$ddm.databasetype%";
	idmacs_trace(SCRIPT + "lv_dbtype = " + lv_dbtype);

	//If database type is not ORA
	if(lv_dbtype != "2")
	{
		//Skip this pass
		uSkip(2);
	}
	return;
}