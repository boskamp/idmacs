function main() {
    var lv_cmd = "C:\\emacs-24.1\\bin\\emacsclientw.exe -a DUMMY";
    var lo_enumerator = new Enumerator(WScript.Arguments);
    while(!lo_enumerator.atEnd()) {
        lv_cmd += (" " + lo_enumerator.item());
        lo_enumerator.moveNext();
    }
    WScript.Echo("lv_cmd = " + lv_cmd);
    var lo_shell = WScript.CreateObject("WScript.Shell");
    var lv_return_code  = lo_shell.Run(lv_cmd, 1, true);
    WScript.Quit(lv_return_code);
}

main();
