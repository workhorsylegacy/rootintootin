
import language_helper;
import native_rest_cannon;

public class UI {
	// FIXME: This should not need the named passed in.
	// FIXME: This should say updated for already saved models
	public static char[] errors_for(ModelBase model, char[] name) {
		// Just return a blank if there were no errors
		if(model.errors.length == 0)
			return "";

		// Return an error box if there are errors
		char[] retval = "";
		retval ~= "<div id=\"error_explanation\">\n";
		retval ~= "<h2>" ~ to_s(model.errors.length) ~ " errors prohibited this " ~ name ~ " from being saved</h2>\n";
		retval ~= "<p>There were problems with the following fields:</p>\n";
		retval ~= "	<ul>\n";

		foreach(char[] error; model.errors) {
			retval ~= "		<li>" ~ error ~ "</li>\n";
		}

		retval ~= "	</ul>\n";
		retval ~= "</div>\n";
		return retval;
	}
}
