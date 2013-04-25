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
 * Get value of global constant. If the constant does not exist,
 * return a default value optionally supplied by the caller.
 *
 * Parameters:
 *   Par - constant_name[!!default_value]
 *         The default value is optional; an empty will be
 *         used if no default is provided.
 * 
 * Returns:
 * Value of global constant constant_name, or default_value
 * if that constant does not exist.
 */
function idmacs_get_global_constant(Par){
    var lt_args = Par.split("!!");
    var lv_constant_name = lt_args[0];
    var lv_default_value = lt_args.length > 1 ? lt_args[1] : "";
    var lv_return = uGetConstant(lv_constant_name);
    if(lv_return == "") {
        lv_return = lv_default_value;
    }

    return lv_return;
}
