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
 * Parses the signature string of the current function, and stores the
 * argument names found in the global list go_func_arg_names. For each
 * argument found, a flag will be stored in go_func_arg_opt, indicating
 * whether the argument is optional or not.
 *
 * Preconditions:
 *   1. Global gv_func_name contains current function name (for tracing)
 * 
 *   2. Global gv_func_signature contains that functions signature
 *      as a string, but without any surrounding parentheses
 *
 * Parameters:
 *   none
 *
 * Returns:
 *   nothing
 */
function idmacs_builtins_parse_signature()  {
    // If current function doesn't have any arguments, we're done
    if (gv_func_signature == null) {
        go_func_arg_names = null;
        go_func_arg_opt = null;
        return; // ========================================== EXIT
    }

    // Reset global list of argument names to empty list
    go_func_arg_names = new java.util.ArrayList();

    // Reset global list of "is optional" flags to empty list
    go_func_arg_opt = new java.util.ArrayList();

    var lo_one_arg_pattern
            = java.util.regex.Pattern.compile(GC_REGEX_ONE_ARGUMENT,
                                              java.util.regex.Pattern.COMMENTS);
    var lo_one_arg_matcher = lo_one_arg_pattern
            .matcher(gv_func_signature);

    while (lo_one_arg_matcher.find()) {
        for (var i = 0; i <= lo_one_arg_matcher.groupCount(); ++i) {
            idmacs_trace(gv_func_name + ": lo_one_arg_matcher.group(" + i
                         + ")=\"" + lo_one_arg_matcher.group(i) + "\"");
        }

        // A regular argument e.g. "arg_name" or "arg_type arg_name"
        var lv_regular_arg_name = lo_one_arg_matcher.group(2);
        idmacs_trace(gv_func_name + ": lv_regular_arg_name=\""
                     + lv_regular_arg_name + "\"");

        // An optional argument surrounded by angle brackets , e.g.
        // <arg_name>
        var lv_angle_arg_name = lo_one_arg_matcher.group(5);
        idmacs_trace(gv_func_name + ": lv_angle_arg_name=\""
                     + lv_angle_arg_name + "\"");

        // An optional argument surrounded by square brackets , e.g.
        // [arg_name]
        var lv_square_arg_name = lo_one_arg_matcher.group(7);
        idmacs_trace(gv_func_name + ": lv_square_arg_name=\""
                     + lv_square_arg_name + "\"");

        var lv_argument_name
                = lv_regular_arg_name != null ? lv_regular_arg_name
                : lv_angle_arg_name != null ? lv_angle_arg_name
                : lv_square_arg_name
        ;

        // Replace sequences of white space in argument names with one
        // underscore
        lv_argument_name = lv_argument_name.replaceAll("\\s+", "_");

        // Remove any ill-positioned commas from argument names
        lv_argument_name = lv_argument_name.replaceAll(",", "");

        idmacs_trace(gv_func_name + ": lv_argument_name=\""
                     + lv_argument_name + "\"");

        var lv_argument_opt = lv_angle_arg_name != null
                || lv_square_arg_name != null;

        idmacs_trace(gv_func_name + ": lv_argument_opt=\""
                     + lv_argument_opt + "\"");

        go_func_arg_names.add(lv_argument_name);
        go_func_arg_opt.add(new java.lang.Boolean(lv_argument_opt));
    }// while(lo_one_arg_matcher.find())

    idmacs_trace(gv_func_name + ": go_func_arg_names = "
                 + go_func_arg_names);
    idmacs_trace(gv_func_name + ": go_func_arg_opt   = " + go_func_arg_opt);

}//idmacs_builtins_parse_signature
