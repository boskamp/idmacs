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
 * Records the string passed in Par into a persistent trace,
 * if the job variable $IDMACS_TRACE is not empty.
 *
 * All messages will be passed to built-in function uWarning,
 * and also written to a trace file in IdM's working directory.
 *
 * Parameters:
 *   iv_message -
 *     string message; it should be prefixed with the
 *     name of the calling function, followed by a
 *     colon and space, e.g.
 *     "idmacs_test: This is a test message"
 *
 * Returns:
 *   nothing
 */

var go_logger = null;

function idmacs_trace(iv_message){
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
        importClass(Packages.java.util.logging.SimpleFormatter);

        go_logger = Logger.getLogger("org.idmacs");
        go_logger.setLevel(Level.ALL);
        var lo_format = new SimpleFormatter();

	// This developer trace file will be created in the IdM runtime's
	// working directory, typicially "C:\usr\sap\IdM\Identity Center".
	// It will be overwritten by each run of the job.
        var lo_handler = new FileHandler("dev_idmacs_job");
	
        lo_handler.setFormatter(lo_format);
        go_logger.addHandler(lo_handler);
        go_logger.setUseParentHandlers(false);
    }
    // uWarning doesn't generate any messages when called
    // from nested JS function calls. For this reason, log
    // messages are emitted both via uWarning and via Java Logging API.
    uWarning(iv_message);
    go_logger.warning(iv_message);

}//idmacs_trace
