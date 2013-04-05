import java.io.File;
import java.io.FileOutputStream;
import java.io.PrintWriter;
import java.util.Iterator;
import java.util.Map;
import java.util.Map.Entry;
import java.util.Set;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import org.mozilla.javascript.Context;

import com.sap.idm.ic.ScriptGlobal;

public class Main {
	public static void main(String[] args) throws Exception {
		ScriptGlobal sg = null;
		try {
			Context context = Context.enter();
			sg = new ScriptGlobal(context);
		} finally {
			Context.exit();
		}

		// Check/create working directory
		File dir = null;
		if (args.length > 0) {
			dir = new File(args[0]);
		} else {
			dir = new File(new File(System.getProperty("user.dir")),
					".snippets");
		}
		if (dir.exists()) {
			if (!dir.isDirectory()) {
				System.err
				.println(dir.getCanonicalPath() + ": not a directory");
				System.exit(-1);
			}
		} else {
			dir.mkdirs();
		}

		Map<String, String> m = sg.getAllCallbacks();

		Set<Map.Entry<String, String>> s = m.entrySet();
		Iterator<Entry<String, String>> iter = s.iterator();
		while (iter.hasNext()) {
			Entry<String, String> entry = (Entry<String, String>) iter.next();
			System.out.println("Key: " + entry.getKey() + " Value: "
					+ entry.getValue());

			String snippet_name = entry.getKey();
			File snippet_file = new File(dir, snippet_name.toLowerCase());
			FileOutputStream fos = new FileOutputStream(snippet_file);
			PrintWriter pw = new PrintWriter(fos);
			pw.println("# name: " + snippet_name);
			pw.println("# --");
			Pattern p = Pattern
					.compile("\\(((([<\\[]?\\w+(\\s+\\w+)?,?[>\\]]?),?\\s*)*)\\)\\s*;?\\s*(/\\*.*\\*/)?");
			Matcher matcher = p.matcher(entry.getValue());
			if (matcher.find()) {
				for (int i = 0; i <= matcher.groupCount(); ++i)
					System.err.println("group[" + i + "]=" + matcher.group(i));
				String signature = matcher.group(1);
				System.err.println("signature = " + signature);
				String comment = matcher.group(5);
				System.err.println("comment = " + comment);

				if (comment != null && comment.trim().length() > 0) {
//					pw.println(comment);
				}
				pw.print(snippet_name + "(");
				int num_args = 0;
				if (signature.trim().length() > 0) {
					Pattern arg = Pattern.compile("<?\\[?\\w+(\\s+\\w+)?>?\\]?(,>)?");
					Matcher marg = arg.matcher(signature);
					while(marg.find()) {
						++num_args;
						if (num_args > 1) {
							pw.println();
							pw.print(",");
						}
						String next_arg = marg.group();
						System.out.println("next_arg = " + next_arg);
						pw.print("${" + num_args + ":" + next_arg + "}");
					}// for
				}//if (signature.trim().length() > 0) {
				System.err.println("Total number of arguments: " + num_args);
				if(num_args > 1) {
					pw.println();
				}
				pw.print(")$0");
			}//if (matcher.find()) {
			pw.flush();
			pw.close();
		}// while
	}// main

}// Main
