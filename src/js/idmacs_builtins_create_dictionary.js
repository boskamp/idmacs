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
 * Create a dictionary file of all built-in function names, i.e. a file that
 * contains the name of each built-in function on a separate line.
 *
 * This file will be used inside Emacs to populate the variable
 * js2-additional-externs, which will make js2-mode recognize these function
 * names as externally declared, and not produce any syntax warnings for
 * them.
 *
 * Parameters:
 *   iv_dictionary_file - name of dictionary file as string
 *
 * Returns:
 *   nothing
 */
function idmacs_builtins_create_dictionary(iv_dictionary_file) {
    var LC_SCRIPT = "idmacs_builtins_create_dictionary: ";
    idmacs_trace(LC_SCRIPT + "iv_dictionary_file = " + iv_dictionary_file);
    
    var lo_dictionary_file
	    = new java.io.File(iv_dictionary_file);
    var lo_dictionary_fos
	    = new java.io.FileOutputStream(lo_dictionary_file);
    var lo_dictionary_writer
	    = new java.io.PrintWriter(lo_dictionary_fos);

    for (var i = 0; i < go_func_names.size(); ++i) {
        var lv_func_name = go_func_names.get(i);
        lo_dictionary_writer.println(lv_func_name);
    }// for

    lo_dictionary_writer.flush();
    lo_dictionary_writer.close();
}//idmacs_builtins_create_dictionary