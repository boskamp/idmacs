/**
 * Reads the whole content of file idmacs_uhelp.txt from the current working
 * directory into the global string variable gv_help.
 *
 * Preconditions: File whose name is passed in iv_help_file  exists
 * in current working directory and contains the string returned by uHelp().
 */
function idmacs_builtins_read_help_file(iv_help_file){
    var LC_SCRIPT = "idmacs_builtins_read_help_file: ";
    idmacs_trace(LC_SCRIPT + "iv_help_file = " + iv_help_file);
    
    //define all global variables used by this pass
    idmacs_builtins_define_globals();

    var lo_help = new java.util.ArrayList();
    var lo_help_sb = new java.lang.StringBuffer();
    var lo_help_reader
	    = new java.io.BufferedReader(
		new java.io.FileReader(iv_help_file));

    var lv_line = null;

    do {
        lv_line = lo_help_reader.readLine();
        if (lv_line == null) {
            break; // ======================================= EXIT
        }
        lo_help.add(lv_line);
        lo_help_sb.append(lv_line);
    } while (true);

    lo_help_reader.close();

    gv_help = lo_help_sb.toString();
}//idmacs_builtins_read_help_file