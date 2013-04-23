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
 * Reads the content of a file containing the names, signatures and
 * documentation of built-in functions, and creates snippet files
 * for each of these functions. It will also create one dictionary
 * file containing all built-in function names.
 *
 * This function is designed to be invoked ONLY ONCE. It will process
 * the complete content of HELP_FILE (see below) in one step.
 *
 * Parameters:
 *   Par - java.util.List containing the following data:
 *         Key:   SNIPPETS_DIR
 *         Value: Directory path as string where to create snippet files;
 *                will be created if it doesn't exist yet
 *
 *         Key:   DICTIONARY_FILE
 *         Value: File name of dictionary file as string
 *
 *         Key:   HELP_FILE
 *         Value: Name of file into which the built-in function descriptions
 *                have been exported before
 *
 * Returns:
 *   nothing
 */
function idmacs_builtins_next_entry(Par){
    var LC_SCRIPT = "idmacs_builtins_next_entry: ";
    idmacs_trace(LC_SCRIPT + "Par = " + Par);

    // Define all global variables
    idmacs_builtins_define_globals();

    // Create/verify all required directories
    var lv_snippets_dir = Par.get("SNIPPETS_DIR");
    var lv_dictionary_file = Par.get("DICTIONARY_FILE");

    var lo_dirs = new java.util.HashMap();
    lo_dirs.put("DIR0", lv_snippets_dir);
    idmacs_mkdirs(lo_dirs);

    // Read help file content into global variable gv_help
    idmacs_builtins_read_help_file(Par.get("HELP_FILE"));
    
    var lo_help_pattern
	    = java.util.regex.Pattern.compile(GC_REGEX_ONE_FUNCTION,
                                              java.util.regex.Pattern.COMMENTS
					      | java.util.regex.Pattern.DOTALL);

    var lo_help_matcher = lo_help_pattern.matcher(gv_help);

    var lv_match_number = 0;

    // Initialize global list of function names.
    // Used by idmacs_builtins_create_dictionary after loop.
    go_func_names = new java.util.ArrayList();

    // Process all functions in gv_help
    while (lo_help_matcher.find()) {
        var lv_whole_match = lo_help_matcher.group(0);
        idmacs_trace("START PROCESSING \"" + lv_whole_match + "\"");

        gv_func_name = lo_help_matcher.group(1);
        gv_func_signature = lo_help_matcher.group(3);
        gv_func_comment = lo_help_matcher.group(13);

        if (lv_whole_match.trim().equals(gv_func_name)) {
            idmacs_trace("Ignoring this match"
                         + " (doesn't look like a function definition)");
            continue; // ====================== with next function
        }
        // Keep track of number of real matches, ignoring odd ones
        lv_match_number++;

        idmacs_trace("gv_func_name      = \"" + gv_func_name + "\"");
        idmacs_trace("gv_func_signature = \"" + gv_func_signature + "\"");
        idmacs_trace("gv_func_comment   = \"" + gv_func_comment + "\"");

        // Note that group 0 always exists, and is not included in the
        // value returned by groupCount. Therefore, termination condition
        // must be "less than or equal" (<=), not "less than" (<)
        for (var i = 0; i <= lo_help_matcher.groupCount(); ++i) {
            idmacs_trace("Match " + lv_match_number
                         + ": lo_help_matcher.group(" + i + ")=\""
                         + lo_help_matcher.group(i) + "\"");
        }
        // Cleaning up the global argument list objects is done inside
        // ==> must always be invoked, even for empty (null) signatures
        idmacs_builtins_parse_signature();

        // Now that all information about one function has been collected
        // into global variables, write the corresponding snippet file
        idmacs_builtins_write_snippet(lv_snippets_dir);

        // Collect function names for building dictionary out of loop
        go_func_names.add(gv_func_name);

    }// while (lo_help_matcher.find())

    // Create dictionary file containing all function names
    idmacs_builtins_create_dictionary(lv_dictionary_file);

    idmacs_trace("Total number of functions successfully parsed: "
                 + lv_match_number);
}//idmacs_builtins_next_entry