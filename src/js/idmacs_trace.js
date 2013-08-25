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
 * Records the string passed in Par into a developer trace file,
 * but only if the job variable $IDMACS_TRACE is not empty.
 *
 * Parameters:
 *   iv_message -
 *     string message; it should be prefixed with the
 *     name of the calling function, followed by a
 *     colon and space, e.g.
 *     "idmacs_test: This is a test message"
 *
 *   iv_level -
 *     one character abbreviation for the severity,
 *     or log leve, of the message. Allowed values are:
 *     i : INFO
 *     w : WARNING
 *     e : ERROR
 *
 *   When iv_level is empty or has an illegal value,
 *   INFO will be used. Consequently, just writing:
 *
 *   idmacs_trace("msg")
 *
 *   is OK and equivalent to:
 *
 *   idmacs_info("msg");
 *
 * Returns:
 *   nothing
 */

var go_logger = null;

function idmacs_trace(iv_message, iv_level){
    // If tracing has not been activated via job constant IDMACS_TRACE,
    // do nothing but return immediately.
    if("%$IDMACS_TRACE%" == "") {
        return; //=============================================== EXIT
    }

    // Initialize logging via Java Logging API on first call
    if(go_logger == null) {
        importClass(Packages.java.util.logging.FileHandler);
        importClass(Packages.java.util.logging.Formatter);
        importClass(Packages.java.util.logging.Level);
        importClass(Packages.java.util.logging.Logger);

        // This is the JS function that will be used for
        // overriding java.util.logging.Formatter.format(LogRecord logRecord)
        var lo_format_function = function(io_logrecord) {

            var lt_format_params = java.lang.reflect.Array.newInstance(java.lang.Object, 3);
            lt_format_params[0] = new java.util.Date(io_logrecord.getMillis());
            lt_format_params[1] = io_logrecord.getLevel().getName();
            lt_format_params[2] = io_logrecord.getMessage();

            // The format string syntax used below is documented at
            // http://docs.oracle.com/javase/6/docs/api/java/util/Formatter.html#syntax
            var lv_format_string
                    = "%1$tF"  // first parameter: ISO 8601 complete date
                    + ""       // ... formatted as "%tY-%tm-%td".
                    + " "      // a space
                    + "%1$tT"  // first parameter: Time formatted for the 24-hour clock
                    + ""       // ... as "%tH:%tM:%tS"
                    + "."      // the character '.'
                    + "%1$tL"  // first parameter: Millisecond within the second
                    + ""       // ... formatted as three digits with leading zeros
                    + ""       // ... as necessary, i.e. 000 - 999.
                    + " ; "    // space, semicolon, space
                    + "%2$s"   // second parameter: formatted as String
                    + " ; "    // space, semicolon, space
                    + "%3$s"   // third parameter: formatted as String
                    + "%n"     // line separator
            ;
            return java.lang.String.format(lv_format_string, lt_format_params);
        };

	// This code creates lo_format as a subclass of Formatter,
	// using the above function for the format(LogRecord) method.
	// See https://developer.mozilla.org/en-US/docs/Rhino/Scripting_Java#The_JavaAdapter_Constructor
        var lo_format
                = new JavaAdapter(java.util.logging.Formatter,
                                  {
                                      format: lo_format_function
                                  });

        go_logger = Logger.getLogger("org.idmacs");
        go_logger.setLevel(Level.ALL);

        // This developer trace file will be created in the IdM runtime's
        // working directory, typicially "C:\usr\sap\IdM\Identity Center".
        // It will be overwritten by each run of the job.
        var lo_handler = new FileHandler("dev_idmacs_job");

        lo_handler.setFormatter(lo_format);
        go_logger.addHandler(lo_handler);
        go_logger.setUseParentHandlers(false);

    } //if(go_logger == null)

    if("e" == iv_level) {
        go_logger.error(iv_message);
    }
    else if("w" == iv_level) {
        go_logger.warning(iv_message);
    }
    // use INFO as default, even when iv_level is empty or invalid
    else {
        go_logger.info(iv_message);
    }

}//idmacs_trace
