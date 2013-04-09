public class exec {
	public static void main(String[] args) throws Exception {
		Runtime r = Runtime.getRuntime();
		Process p = r
				.exec("C:\\emacs-24.1\\bin\\emacsclientw.exe -a DUMMY + \""
						+ args[0] + "\"");
		System.exit(p.waitFor());
	}
}
