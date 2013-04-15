// Main function: idmacs_mkdirs
// Author: Lambert Boskamp
// Created: 2013-04-05
function idmacs_mkdirs(Par) {
    var SCRIPT = "idmacs_mkdirs: ";
    idmacs_trace(SCRIPT + "Par = " + Par);

    var lt_dir_names = Par.keySet().toArray();

    for (var i = 0; i < lt_dir_names.length; ++i) {
        var lv_dir_name = Par.get(lt_dir_names[i]);
        var lo_dir      = new java.io.File(lv_dir_name);
        var lv_path     = lo_dir.getCanonicalPath();
        var lv_error    = null;

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

}//idmacs_mkdirs