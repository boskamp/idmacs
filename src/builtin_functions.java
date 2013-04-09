import java.io.BufferedReader;
import java.io.File;
import java.io.FileOutputStream;
import java.io.FileReader;
import java.io.PrintWriter;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

public class builtin_functions {
	private static String[] gt_help = null;
	private static String gv_help = null;
	private static Map Par = null;
	private final static String SNIPPETS_DIR = "SNIPPETS_DIR";
	private final static String DICTIONARY_DIR = "DICTIONARY_DIR";
	private final static String HELP_FILE = "HELP_FILE";

	private static void idmacs_trace(String m) {
		System.err.println(m);
	}

	private static void idmacs_builtins_open_datasource() throws Exception {
		List lo_help = new ArrayList();
		StringBuffer lo_help_sb = new StringBuffer();
		BufferedReader lo_help_reader = new BufferedReader(new FileReader(
				"idmacs_uhelp.txt"));

		String lv_line = null;
		int lv_num_lines = 0;

		do {
			lv_line = lo_help_reader.readLine();
			if (lv_line == null) {
				break;
			}
			lv_num_lines++;
			lo_help.add(lv_line);
			lo_help_sb.append(lv_line);
		} while (lv_num_lines < 1000);

		lo_help_reader.close();

		gt_help = (String[]) lo_help.toArray(new String[] {});
		Arrays.sort(gt_help);

		gv_help = lo_help_sb.toString();
	}// idmacs_builtins_open_datasource

	public static void idmacs_create_builtin_functions_snippets()
			throws Exception {

		File lo_snippets_dir = mkdirs((String) Par.get(SNIPPETS_DIR));
		Pattern lo_help_pattern = Pattern
				.compile(
						"(\\w+)                                                   # function name                                         \n"
								+ "\\s* \\*? \\s*                                 # workaround for buggy uExtEncode * (...)               \n"
								+ "( \\(                                          # begin: optinal signature                              \n"
								+ "(                                              # begin group: whole argument list (wihtout parens)     \n"
								+ "("
								+ "[<\\[]?                                        # optional starting symbols of an optional argument     \n"
								+ "\\w+(\\s+\\w+)?                                # one or two argument words                             \n"
								+ ",?                                             # workaround for buggy args like <int aRemoveFlag,>     \n"
								+ "[>\\]]?"
								+ ",?                                             # optional comma separating multiple arguments          \n"
								+ "\\s*" 
								+ ")*"
								+ ")                                              # end group: whole argument list (without parens)       \n"
								+ "  \\){1,2} )?                                  # end: optional signature                               \n"
								+ "\\s* ;?                                        # optional whitespace and ;                             \n"
								+ "( ( \\s* /\\* .*? \\*/ \\s* )+ )?              # optional multi-line comment, note .* must be made reluctant via ?",
						Pattern.COMMENTS | Pattern.DOTALL);

		// for (int i = 0; i < gt_help.length; ++i) {
		// String lv_help = gt_help[i];
		// idmacs_trace("Processing line " + lv_help);

		Matcher lo_help_matcher = lo_help_pattern.matcher(gv_help);
		int lv_match_number = 0;
		while (lo_help_matcher.find()) {
			String lv_whole_match = lo_help_matcher.group(0);
			String lv_func_name = lo_help_matcher.group(1);

			if (lv_whole_match.trim().equals(lv_func_name)) {
				idmacs_trace("Ignoring odd-looking match " + lv_whole_match);
				continue;
			}

			lv_match_number++;

			// Note that group 0 always exists, and is not included in the
			// value
			// returned by groupCount. Therefore, termination condition is
			// <=, not <.
			for (int j = 0; j <= lo_help_matcher.groupCount(); ++j) {
				idmacs_trace("Match number " + lv_match_number + ", group " + j
						+ ": \"" + lo_help_matcher.group(j) + "\"");
			}
		}
		// else {
		// idmacs_trace("Skipping non-matching line " + lv_help);
		// }
		// }// for
		return;

		// String lv_func_name = gt_callbacks_keys[i];
		// String lv_func_sigcom = (String)
		// go_callbacks_map.get(lv_func_name);
		//
		// idmacs_trace("lv_func_name: " + lv_func_name +
		// " lv_func_sigcom: "
		// + lv_func_sigcom);
		//
		// File lo_snippet_file = new File(lo_snippets_dir, lv_func_name);
		// FileOutputStream lo_snippet_fos = new FileOutputStream(
		// lo_snippet_file);
		// PrintWriter lo_snippet_writer = new PrintWriter(lo_snippet_fos);
		//
		// lo_snippet_writer.println("# name: " + lv_func_name);
		// lo_snippet_writer.println("# --");
		//
		// Pattern lo_sigcom_pattern = Pattern
		// .compile("\\(((([<\\[]?\\w+(\\s+\\w+)?,?[>\\]]?),?\\s*)*)\\)\\s*;?\\s*(/\\*.*\\*/)?");
		// Matcher lo_sigcom_matcher = lo_sigcom_pattern
		// .matcher(lv_func_sigcom);
		// if (lo_sigcom_matcher.find()) {
		// for (int j = 0; j <= lo_sigcom_matcher.groupCount(); ++j) {
		// idmacs_trace("lo_sigcom_matcher.group[" + j + "]="
		// + lo_sigcom_matcher.group(j));
		// }
		// String lv_signature = lo_sigcom_matcher.group(1);
		// idmacs_trace("lv_signature = " + lv_signature);
		//
		// String lv_comment = lo_sigcom_matcher.group(5);
		// idmacs_trace("lv_comment = " + lv_comment);
		//
		// // if (lv_comment != null && lv_comment.trim().length() > 0) {
		// // lo_snippet_writer.println(lv_comment);
		// // }
		// lo_snippet_writer.print(lv_func_name + "(");
		// int lv_num_args = 0;
		// boolean lv_is_optional_arg = false;
		// if (lv_signature.trim().length() > 0) {
		// Pattern lo_one_arg_pattern = Pattern
		// .compile("<?\\[?(\\w+(\\s+\\w+)?)>?\\]?(,>)?");
		//
		// Matcher lo_one_arg_matcher = lo_one_arg_pattern
		// .matcher(lv_signature);
		//
		// if (!lo_one_arg_matcher.find()) {
		// idmacs_trace("lo_one_arg_matcher.find() returns false");
		// } else {
		// do {
		// for (int k = 0; k <= lo_one_arg_matcher
		// .groupCount(); ++k) {
		// idmacs_trace("lo_one_arg_matcher.group[" + k
		// + "]=" + lo_one_arg_matcher.group(k));
		// }
		// ++lv_num_args;
		//
		// String lv_next_arg = lo_one_arg_matcher.group(1);
		//
		// // Replace sequences of white space
		// // in argument names with one underscore
		// lv_next_arg = lv_next_arg.replaceAll("\\s+", "_");
		// idmacs_trace("lv_next_arg = " + lv_next_arg);
		//
		// // Argument is considered optional if it's
		// // surrounded
		// // by angle brackets, e.g. <arg>,
		// // or square brackets, e.g. [arg]
		// lv_is_optional_arg = lo_one_arg_matcher.group()
		// .matches("[<\\[]?[^>\\]]+[>\\]]");
		// idmacs_trace("lv_is_optional_arg = "
		// + lv_is_optional_arg);
		//
		// if (lv_num_args > 1) {
		// lo_snippet_writer.println();
		// }
		// if (lv_is_optional_arg) {
		// lo_snippet_writer.print("/*");
		// }
		// if (lv_num_args > 1) {
		// lo_snippet_writer.print(",");
		// }
		// if (!lv_is_optional_arg) {
		// lo_snippet_writer.print("${" + lv_num_args
		// + ":");
		// }
		//
		// lo_snippet_writer.print(lv_next_arg);
		//
		// if (!lv_is_optional_arg) {
		// lo_snippet_writer.print("}");
		// } else {
		// lo_snippet_writer.print("*/");
		// }
		//
		// } while (lo_one_arg_matcher.find());
		// }// else
		// }// if (lv_signature.trim().length() > 0) {
		// idmacs_trace("Total number of arguments: " + lv_num_args);
		// if (lv_num_args > 1) {
		// lo_snippet_writer.println();
		// }
		// lo_snippet_writer.print(")$0");
		// }// if (lo_sigcom_matcher.find()) {
		//
		// // Flush and close current snippet file
		// lo_snippet_writer.flush();
		// lo_snippet_writer.close();

		// }// for(int i = 0; i < gt_callbacks_keys.length; ++i) {

	}// idmacs_create_builtin_functions_snippets

	private static void idmacs_create_builtin_functions_dictionary()
			throws Exception {
		// File lo_dictionary_dir = mkdirs((String) Par.get(DICTIONARY_DIR));
		// File lo_dictionary_file = new File(lo_dictionary_dir, "js2-mode");
		// FileOutputStream lo_dictionary_fos = new FileOutputStream(
		// lo_dictionary_file);
		// PrintWriter lo_dictionary_writer = new
		// PrintWriter(lo_dictionary_fos);
		//
		// for (int i = 0; i < gt_callbacks_keys.length; ++i) {
		// String lv_func_name = gt_callbacks_keys[i];
		// lo_dictionary_writer.println(lv_func_name);
		// }// for
		//
		// lo_dictionary_writer.flush();
		// lo_dictionary_writer.close();
	}

	private static File mkdirs(String iv_dir_name) throws Exception {
		File lo_dir = null;
		lo_dir = new File(iv_dir_name);

		if (lo_dir.exists()) {
			if (!lo_dir.isDirectory()) {
				idmacs_trace(lo_dir.getCanonicalPath() + ": not a directory");
				System.exit(-1); // ============================= EXIT
			}
		} else {
			lo_dir.mkdirs();
		}

		return lo_dir;
	}

	private static void idmacs_builtins_close_datasource() {
		gt_help = null;
	}

	public static void main(String[] args) throws Exception {
		Par = new HashMap();

		String lv_snippets_dir = args.length > 0 ? args[0] : ".snippets";
		Par.put(SNIPPETS_DIR, lv_snippets_dir);

		String lv_dictionary_dir = args.length > 1 ? args[1] : ".dictionary";
		Par.put(DICTIONARY_DIR, lv_dictionary_dir);

		String lv_help_file = args.length > 2 ? args[2] : "idmacs_uhelp.txt";
		Par.put(HELP_FILE, lv_help_file);

		idmacs_builtins_open_datasource();

		idmacs_create_builtin_functions_snippets();
		idmacs_create_builtin_functions_dictionary();

		idmacs_builtins_close_datasource();
	}// main

}// Main
