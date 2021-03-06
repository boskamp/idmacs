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
 * Write the snippet file for function currently being processed.
 *
 * Preconditions:
 *   1. Global gv_func_name contains function name
 *
 *   2. Global go_func_arg_names contains java.util.List
 *      of argument names, or is null for functions
 *      with empty signature.
 *
 *   3. Global go_func_arg_opt contains java.util.List
 *      of java.lang.Boolean flags indicating whether
 *      the index-corresponding element of go_func_arg_names
 *      is optional (true) or mandatory (false) argument.
 *
 * Parameters:
 *   iv_snippets_dir
 *     - string name of directory where to generate snippet file
 *
 * Returns:
 *   nothing
 */
function idmacs_builtins_write_snippet(iv_snippets_dir) {
    var LC_SCRIPT = "idmacs_builtins_write_snippet: ";
    idmacs_trace(LC_SCRIPT + "iv_snippets_dir = " + iv_snippets_dir);
    
    var lo_snippets_dir = new java.io.File(iv_snippets_dir);
    var lo_snippet_file = new java.io.File(lo_snippets_dir, gv_func_name);
    var lo_snippet_fos = new java.io.FileOutputStream(lo_snippet_file);
    var lo_snippet_writer = new java.io.PrintWriter(lo_snippet_fos);

    lo_snippet_writer.println("# name: " + gv_func_name);
    lo_snippet_writer.println("# --");
    lo_snippet_writer.print(gv_func_name + "(");

    // Process arguments only if function really has arguments
    if (go_func_arg_names != null) {
        // Overall number of arguments in signature
        var lv_args_count = go_func_arg_names.size();

        for (var i = 0; i < lv_args_count; ++i) {
            // The number of the current argument, starting with 1
            var lv_func_arg_num = i + 1;
            var lv_func_arg_name = go_func_arg_names.get(i);
            var lv_func_arg_opt = go_func_arg_opt.get(i).booleanValue();

            if (lv_args_count > 1) {
                lo_snippet_writer.println();
            }

            if (lv_func_arg_opt) {
                lo_snippet_writer.print("/*");
            }
            if (lv_func_arg_num > 1) {
                lo_snippet_writer.print(",");
            }
            if (!lv_func_arg_opt) {
                lo_snippet_writer.print("${" + lv_func_arg_num + ":");
            }

            lo_snippet_writer.print(lv_func_arg_name);

            if (!lv_func_arg_opt) {
                lo_snippet_writer.print("}");
            } else {
                lo_snippet_writer.print("*/");
            }

        }// for (var i = 0; i < lv_args_count; ++i)

        // Put closing paren on a separate line,
        // but only for multi-argument functions
        if (lv_args_count > 1) {
            lo_snippet_writer.println();
        }
    }// if(gt_func_arg_names != null) {

    // Always add closing signature paren,
    // followed by "end of snippet" marker
    lo_snippet_writer.print(")$0");

    // Finalize current snippet file
    lo_snippet_writer.flush();
    lo_snippet_writer.close();

}//idmacs_builtins_write_snippet
