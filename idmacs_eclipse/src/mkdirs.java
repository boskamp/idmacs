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

import java.io.File;
import java.util.Hashtable;
import java.util.Map;

public class mkdirs {
	public static void main(String[] args) throws Exception {
		Map Par = new Hashtable();

		String LC_SCRIPT = "idmacs_mkdirs: ";
		idmacs_trace(LC_SCRIPT + "Par = " + Par);

		String lt_dir_names[] = (String[])Par.keySet().toArray(new String[] {});
		for (int i = 0; i < lt_dir_names.length; ++i) {
			String lv_dir_name = (String)Par.get(lt_dir_names[i]);
			File lo_dir = new File(lv_dir_name);
			String lv_path = lo_dir.getCanonicalPath();
			String lv_error = null;

			if (!lo_dir.exists()) {
				if (lo_dir.mkdirs()) {
					idmacs_trace("Successfully created " + lv_path);
				} else {
					lv_error = "Error creating directory " + lv_path;
				}
			} else {
				if (!lo_dir.isDirectory()) {
					lv_error = lv_path
							+ " is a file, but must be directory."
							+ " Specify different directory or delete conflicting file.";
				}
			}
			if (lv_error != null) {
				uError(lv_error);
				uStop(lv_error); //========================= EXIT JOB
			}
		}// for
	}

	private static void uError(String m) {
		System.err.println(m);
	}

	private static void uStop(String m) {
		System.err.println(m);
	}

	private static void idmacs_trace(String m) {
		System.err.println(m);
	}
}