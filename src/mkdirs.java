import java.io.File;
import java.util.Hashtable;
import java.util.Map;

public class mkdirs {
	public static void main(String[] args) throws Exception {
		Map Par = new Hashtable();

		String SCRIPT = "idmacs_mkdirs: ";
		idmacs_trace(SCRIPT + "Par = " + Par);

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