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
 * Currently, all messages will be passed to uWarning if the
 * trace is on. However, this approach doesn't work for all
 * scripts, so some trace messages are currently just lost.
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
function idmacs_trace(iv_message){
    if("%$IDMACS_TRACE%" != "") {
	// TODO: for some reasons, this logging approach
	// doesn't generate any messages in the most complex pass:
	//
	// Parse Built-In Functions Help File
	//
	// Think about switching to java.util.logging
        uWarning(iv_message);
    }
}//idmacs_trace
