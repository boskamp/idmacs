import System;

function main() {
    var lv_cmd = "C:\\emacs-24.1\\bin\\emacsclientw.exe -a DUMMY";

    var lt_args = System.Environment.GetCommandLineArgs();
    lv_cmd += (" " + lt_args[1]);
    
    // for (var i=0; i < lt_args.length; ++i) {
    //     lv_cmd += (" " + lt_args[i]);
    // }

    var lo_shell = new ActiveXObject("WScript.Shell");
    var lv_return_code  = lo_shell.Run(lv_cmd, 0, true);
}

main();
