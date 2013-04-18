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
 * Reads the whole content of the file name passed via iv_help_file
 * into the global string variable gv_help.
 *
 * Preconditions: 
 * 1. Function idmacs_builtins_define_globals() has been called
 *    so that global variable gv_help really exists.
 *
 * Parameters:
 *   iv_help_file - string name of file to read
 *
 * Returns:
 *   nothing
 */
function idmacs_builtins_read_help_file(iv_help_file){
    var LC_SCRIPT = "idmacs_builtins_read_help_file: ";
    idmacs_trace(LC_SCRIPT + "iv_help_file = " + iv_help_file);
    
    var lo_help = new java.util.ArrayList();
    var lo_help_sb = new java.lang.StringBuffer();
    var lo_help_reader
	    = new java.io.BufferedReader(
		new java.io.FileReader(iv_help_file));

    var lv_line = null;

    do {
        lv_line = lo_help_reader.readLine();
        if (lv_line == null) {
            break; // ======================================= EXIT
        }
        lo_help.add(lv_line);
        lo_help_sb.append(lv_line);
    } while (true);

    lo_help_reader.close();

    gv_help = lo_help_sb.toString();
}//idmacs_builtins_read_help_file
