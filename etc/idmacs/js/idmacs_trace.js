// Main function: idmacs_trace
// Author: Lambert Boskamp
function idmacs_trace(Par){
    if("%$IDMACS_TRACE%" != "")
    {
	// TODO: for some reasons, this logging approach
	// doesn't generate any messages in the most complex pass:
	//
	// Parse Built-In Functions Help File
	//
	// Think about switching to java.util.logging
        uWarning(Par);
    }
}