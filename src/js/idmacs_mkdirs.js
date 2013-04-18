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
 * Creates directories specified in io_list. If required, any
 * intermediate subdirectories that don't exit yet will be
 * created automatically.
 *
 * If any of the directories in io_list cannot be created,
 * THIS SCRIPT WILL CALL uStop() to stop the currently
 * executing job.
 *
 * Parameters:
 *   io_list -
 *     java.util.List whose values will be iterated
 *     and used as directory names to create. The
 *     key names don't matter. You may want to use
 *     something like 'DIR1', 'DIR2', 'DIR3' etc,
 *     but anything else will work as well. Note
 *     that the order in which directories in io_list
 *     will be created is undefined.
 *
 * Returns:
 *   Nothing
 */
function idmacs_mkdirs(io_list) {
    var SCRIPT = "idmacs_mkdirs: ";
    idmacs_trace(SCRIPT + "io_list = " + io_list);

    var lt_dir_names = io_list.keySet().toArray();

    for (var i = 0; i < lt_dir_names.length; ++i) {
        var lv_dir_name = io_list.get(lt_dir_names[i]);
        var lo_dir      = new java.io.File(lv_dir_name);
        var lv_path     = lo_dir.getCanonicalPath();
        var lv_error    = null;

        if (!lo_dir.exists()) {
            if (lo_dir.mkdirs()) {
                idmacs_trace("Successfully created " + lv_path);
            } else {
                lv_error = "Error creating directory " + lv_path;
            }
        } else {
            if (!lo_dir.isDirectory()) {
                lv_error = lv_path
                    + " is a file, but must be directory."
                    + " Specify different directory or delete conflicting file.";
            }
        }

        if (lv_error != null) {
            uError(lv_error);
            uStop(lv_error); //========================= EXIT JOB
        }
    }// for

}//idmacs_mkdirs
