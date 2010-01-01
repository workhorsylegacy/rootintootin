/*------------------------------------------------------------------------------
#
#    This file is part of the Rootin Tootin web framework and licensed under the
#    GPL version 3 or greater. See the COPYRIGHT file for copyright information.
#    This project is hosted at http://rootin.toot.in .
#
#-----------------------------------------------------------------------------*/


private import language_helper;
private import rootintootin;

public class UI {
	// FIXME: This should not need the named passed in.
	// FIXME: This should say updated for already saved models
	public static string errors_for(ModelBase model, string name) {
		// Just return a blank if there were no errors
		if(model.errors.length == 0)
			return "";

		// Return an error box if there are errors
		string retval = "";
		retval ~= "<div id=\"error_explanation\">\n";
		retval ~= "<h2>" ~ to_s(model.errors.length) ~ " errors prohibited this " ~ name ~ " from being saved</h2>\n";
		retval ~= "<p>There were problems with the following fields:</p>\n";
		retval ~= "	<ul>\n";

		foreach(string error; model.errors) {
			retval ~= "		<li>" ~ error ~ "</li>\n";
		}

		retval ~= "	</ul>\n";
		retval ~= "</div>\n";
		return retval;
	}
}
