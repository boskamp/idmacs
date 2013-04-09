import java.io.BufferedReader;
import java.io.File;
import java.io.FileOutputStream;
import java.io.FileReader;
import java.io.PrintWriter;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

public class builtin_functions {
	// Global data
	private static Map Par = null;
	private static String gv_help = null;
	private static String gv_func_name = null;
	private static String gv_func_signature = null;
	private static ArrayList gt_func_arg_names = null;
	private static ArrayList gt_func_arg_opt = null;
	private static String gv_func_comment = null;

	// General Constants
	private final static String SNIPPETS_DIR = "SNIPPETS_DIR";
	private final static String DICTIONARY_DIR = "DICTIONARY_DIR";
	private final static String HELP_FILE = "HELP_FILE";

	// Regular Expression Constants
	private static final String GC_REGEX_ONE_ARGUMENT = "([<\\[])?  # group: optional opening brackets for optional argument       \n"
			+ "( \\w+(\\s+\\w+)? )                                # group: one or two argument words                             \n"
			+ "(,>)?                                              # workaround for buggy args like <int aRemoveFlag,>     \n"
			+ "[>\\]]?                                            # optional closing brackts for optional argument        \n";

	private static final String GC_REGEX_ONE_FUNCTION = "(\\w+)   # function name                                         \n"
			+ "\\s* \\*? \\s*                                 # workaround for buggy uExtEncode * (...)               \n"
			+ "( \\(                                          # begin: optional signature                             \n"
			+ "(                                              # begin group: whole argument list (without parens)     \n"
			+ "(                                              # begin group: one arg + opt. comma + opt. whitespace   \n"
			+ GC_REGEX_ONE_ARGUMENT
			+ ",?                                             # optional comma separating multiple arguments          \n"
			+ "\\s*                                           # optional whitespace                                   \n"
			+ ")*                                             # end of group: one arg + opt. comma + opt. whitespace  \n"
			+ ")                                              # end group: whole argument list (without parens)       \n"
			+ "  \\){1,2} )?                                  # end: optional signature                               \n"
			+ "\\s* ;?                                        # optional whitespace and ;                             \n"
			+ "( ( \\s* /\\* .*? \\*/ \\s* )+ )?              # optional multi-line comment (note reluctance!)        \n";

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

		gv_help = lo_help_sb.toString();
	}// idmacs_builtins_open_datasource

	public static void idmacs_create_builtin_functions_snippets()
			throws Exception {

		Pattern lo_help_pattern = Pattern.compile(GC_REGEX_ONE_FUNCTION,
				Pattern.COMMENTS | Pattern.DOTALL);

		Matcher lo_help_matcher = lo_help_pattern.matcher(gv_help);
		int lv_match_number = 0;
		while (lo_help_matcher.find()) {
			String lv_whole_match = lo_help_matcher.group(0);
			gv_func_name = lo_help_matcher.group(1);
			gv_func_signature = lo_help_matcher.group(3);
			gv_func_comment = lo_help_matcher.group(6);

			if (lv_whole_match.trim().equals(gv_func_name)) {
				idmacs_trace("Ignoring odd-looking match " + lv_whole_match);
				continue;
			}
			// Keep track of number of real matches, ignoring odd ones
			lv_match_number++;

			idmacs_trace("gv_func_name:      \"" + gv_func_name + "\"");
			idmacs_trace("gv_func_signature: \"" + gv_func_signature + "\"");
			idmacs_trace("gv_func_comment:   \"" + gv_func_comment + "\"");

			// Note that group 0 always exists, and is not included in the
			// value returned by groupCount. Therefore, termination condition
			// must be "less than or equal" (<=), not "less than" (<)
			for (int i = 0; i <= lo_help_matcher.groupCount(); ++i) {
				idmacs_trace("Match number " + lv_match_number + ", group " + i
						+ ": \"" + lo_help_matcher.group(i) + "\"");
			}
			// Cleaning up the global argument list objects is done inside
			// ==> must always be invoked, even for empty (null) signatures
			idmacs_builtins_parse_signature();
			
			idmacs_builtins_write_snippet();

		}// while (lo_help_matcher.find())
	}// idmacs_create_builtin_functions_snippets

	private static void idmacs_builtins_parse_signature() throws Exception {
		if (gv_func_signature == null) {
			gt_func_arg_names = null;
			gt_func_arg_opt = null;
			return; // ========================================== EXIT
		}
		gt_func_arg_names = new ArrayList();
		gt_func_arg_opt = new ArrayList();
		Pattern lo_one_arg_pattern = Pattern.compile(GC_REGEX_ONE_ARGUMENT,
				Pattern.COMMENTS);
		Matcher lo_one_arg_matcher = lo_one_arg_pattern
				.matcher(gv_func_signature);
		while (lo_one_arg_matcher.find()) {
			for (int i = 0; i <= lo_one_arg_matcher.groupCount(); ++i) {
				idmacs_trace("lo_one_arg_matcher.group(" + i + "): \""
						+ lo_one_arg_matcher.group(i) + "\"");
			}
			String lv_argument_name = lo_one_arg_matcher.group(2);
			boolean lv_argument_opt = lo_one_arg_matcher.group(1) != null;

			// Replace sequences of white space
			// in argument names with one underscore
			lv_argument_name = lv_argument_name.replaceAll("\\s+", "_");

			idmacs_trace("Next argument name:     \"" + lv_argument_name + "\"");
			idmacs_trace("Next argument optional: \"" + lv_argument_opt + "\"");
			gt_func_arg_names.add(lv_argument_name);
			gt_func_arg_opt.add(new Boolean(lv_argument_opt));
		}// while(lo_one_arg_matcher.find())

		idmacs_trace("gt_func_arg_names = " + gt_func_arg_names);
		idmacs_trace("gt_func_arg_opt   = " + gt_func_arg_opt);
	}

	private static void idmacs_builtins_write_snippet() throws Exception {
		File lo_snippets_dir = mkdirs((String) Par.get(SNIPPETS_DIR));
		File lo_snippet_file = new File(lo_snippets_dir, gv_func_name);
		FileOutputStream lo_snippet_fos = new FileOutputStream(lo_snippet_file);
		PrintWriter lo_snippet_writer = new PrintWriter(lo_snippet_fos);

		lo_snippet_writer.println("# name: " + gv_func_name);
		lo_snippet_writer.println("# --");
		lo_snippet_writer.print(gv_func_name + "(");
		
		//Process arguments only if function really has arguments
		if (gt_func_arg_names != null) {
			//Overall number of arguments in signature
			int lv_args_count = gt_func_arg_names.size();

			for (int i = 0; i < lv_args_count; ++i) {
				//The number of the current argument, starting with 1
				int lv_func_arg_num = i + 1;
				String lv_func_arg_name = (String) gt_func_arg_names.get(i);
				boolean lv_func_arg_opt = ((Boolean) gt_func_arg_opt.get(i))
						.booleanValue();

				if (lv_args_count > 1) {
					lo_snippet_writer.println();
				}

				if (lv_func_arg_opt) {
					lo_snippet_writer.print("/*");
				}
				if (lv_func_arg_num > 1) {
					lo_snippet_writer.print(",");
				}
				if (!lv_func_arg_opt) {
					lo_snippet_writer.print("${" + lv_func_arg_num + ":");
				}

				lo_snippet_writer.print(lv_func_arg_name);

				if (!lv_func_arg_opt) {
					lo_snippet_writer.print("}");
				} else {
					lo_snippet_writer.print("*/");
				}

			}// for

			//Put closing parenthesis on a separate line,
			//but only for multi-argument functions
			if (lv_args_count > 1) {
				lo_snippet_writer.println();
			}
		}// if(gt_func_arg_names != null) {

		//Always close signature parens
		lo_snippet_writer.print(")$0");
		
		// Flush and close current snippet file
		lo_snippet_writer.flush();
		lo_snippet_writer.close();
	}

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
		// String gv_func_name = gt_callbacks_keys[i];
		// lo_dictionary_writer.println(gv_func_name);
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
