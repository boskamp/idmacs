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

// GLOBAL DATA ==================================================
/**
 * String returned by built-in function uHelp();
 */
var gv_help = null;

/**
 * Name of function currently being processed as string.
 */
var gv_func_name = null;

/**
 * Signature of function currently being processed as string. This is all
 * characters between opening and closing paren following a function name in
 * uHelp(), e.g.
 *
 * "SQLStatement [RowSeparator], [ColumnSeparator]"
 *
 * for the function name "uSelect".
 */
var gv_func_signature = null;

/**
 * Multi-line comment of function currently being processed as string. The
 * string includes begin and end of comment markers, and line breaks in case
 * the comment spans multiple lines. Due to the included begin and end of
 * comment markers, no 1:1 example can be included here; they would break
 * this comment.
 */
var gv_func_comment = null;

/**
 * java.util.ArrayList of all function names returned by uHelp(); required
 * to add them as symbols to js2-additional-externs
 */
var go_func_names = null;

/**
 * java.util.ArrayList of all argument names of the function currently being
 * processed; any argument names that were not plain words (i.e. didn't
 * match regex \\w+) have already been transformed into plain words.
 */
var go_func_arg_names = null;

/**
 * java.util.ArrayList of java.lang.Boolean, with index equality to
 * go_func_arg_names. Each Boolean indicates whether the corresponding
 * element of go_func_arg_names is an optional argument (true) or a
 * mandatory argument (false).
 */
var go_func_arg_opt = null;

// GLOBAL CONSTANTS: REGULAR EXPRESSIONS ========================
/**
 * A constant string containing the regular expression to match exactly one
 * function argument in the content returned by uHelp(). Uses additional
 * whitespace and comments for improved readability
 *
 * ==> requires flag Pattern.COMMENT when compiled
 */
var GC_REGEX_ONE_ARGUMENT
        = "(                          # begin: one argument \n"
        + "  ( \\w+ ( \\s+\\w+)?   )  # one or two regular argument words \n"
        + "| (   < ([^>]+)     >   )  # OR angle-bracketed optional arg \n"
        + "| ( \\[ ([^\\]]+) \\]   )  # OR square bracketed optional arg \n"
        + ")                          # end: one argument \n"
;

/**
 * A constant string containing the regular expression to match exactly one
 * function, including its name, signature and comment in the content
 * returned by uHelp(). Uses additional whitespace and comments for improved
 * readability
 *
 * ==> requires flag Pattern.COMMENT when compiled
 */
var GC_REGEX_ONE_FUNCTION
        = "(\\w+)                    # function name \n"
        + "\\s* \\*? \\s*            # workaround for buggy uExtEncode \n"
        + "( \\(                     # begin: opt. signature incl. parens \n"
        + "(                         # begin: signature  excl. parens \n"
        + "(                         # begin: zero or more arguments  \n"
        + "\\s* ,? \\s*              # opt. comma surrounded by opt. whitspace \n"
        + GC_REGEX_ONE_ARGUMENT
// TODO: print() doesn't work yet
//      + "\\s* ( \\.{3} )? \\s*     # optional ellipsis for variadic functions \n"
        + "\\s* ,? \\s*              # opt. comma surrounded by opt. whitspace \n"
        + ")*                        # end: zero or more arguments  \n"
        + ")                         # end: signature  excl. parens \n"
        + "  \\){1,2} )?             # end: opt. signature incl. parens, workaround uExpandString \n"
        + "\\s* ;?                   # opt. whitespace and semicolon \n"
        + "( ( \\s* /\\* .*? \\*/ \\s* )+ )? # optional multi-line comment (reluctant quantifier!) \n"
;

/**
 * This is a dummy function. The purpose of this source file
 * is to define the above global variables only.
 *
 * Parameters:
 *   none
 *
 * Returns:
 *   nothing
 */
function idmacs_builtins_define_globals(){}
