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
 * Returns names, signatures and documentation of built-in
 * functions by calling uHelp()
 *
 * Parameters:
 *   iv_include_undocumented -
 *     Optional boolean value indicating whether internal
 *     functions that are supposed to remain undocumented
 *     should be included in the result or not. Take
 *     care of not relying on these functions for production.
 *
 * Returns:
 *   Multi-line string containing the documentation
 */

function idmacs_return_uhelp(iv_include_undocumented){
    return uHelp(iv_include_undocumented);
}//idmacs_return_uhelp
