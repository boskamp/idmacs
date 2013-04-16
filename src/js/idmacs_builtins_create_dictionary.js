/**
 * Create a dictionary file of all built-in function names, i.e. a file that
 * contains the name of each built-in function on a separate line.
 *
 * This file will be used inside Emacs to populate the variable
 * js2-additional-externs, which will make js2-mode recognize these function
 * names as externally declared, and not produce any syntax warnings for
 * them.
 */
function idmacs_builtins_create_dictionary(iv_snippets_dir) {
    var LC_SCRIPT = "idmacs_builtins_create_dictionary: ";
    idmacs_trace(LC_SCRIPT + "iv_snippets_dir = " + iv_snippets_dir);
    
    var lo_dictionary_dir
	    = new java.io.File(iv_snippets_dir);
    var lo_dictionary_file
	    = new java.io.File(lo_dictionary_dir, "js2-mode");
    var lo_dictionary_fos
	    = new java.io.FileOutputStream(lo_dictionary_file);
    var lo_dictionary_writer
	    = new java.io.PrintWriter(lo_dictionary_fos);

    for (var i = 0; i < go_func_names.size(); ++i) {
        var lv_func_name = go_func_names.get(i);
        lo_dictionary_writer.println(lv_func_name);
    }// for

    lo_dictionary_writer.flush();
    lo_dictionary_writer.close();
}//idmacs_builtins_create_dictionary