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
 * Emits an INFO message to the persistent log. The message
 * will be passed to uInfo to be recorded in the regular job log,
 * and to idmacs_trace to be recorded into a developer trace
 * file. See documentation of idmacs_trace.
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

function idmacs_info(iv_message){
    idmacs_trace(iv_message, "i");
    uInfo(iv_message);
}
