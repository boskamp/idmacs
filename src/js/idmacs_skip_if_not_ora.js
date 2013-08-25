// Copyright 2013 Lambert Boskamp
//
// Author: Lambert Boskamp <lambert@boskamp-consulting.com.nospam>
//
// This file is part of IDMacs.
//
// IDMacs is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// IDMacs is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with IDMacs.  If not, see <http://www.gnu.org/licenses/>.

/**
 * Checks whether the current database platform is Oracle.
 * If it is NOT, skips execution of the current pass.
 *
 * Parameters:
 *   none
 *
 * Returns:
 *   nothing
 */
function idmacs_skip_if_not_ora(){
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
}//idmacs_skip_if_not_ora
