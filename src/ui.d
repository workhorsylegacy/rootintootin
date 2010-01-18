/*------------------------------------------------------------------------------
#
#    This file is part of the Rootin Tootin web framework and licensed under the
#    GPL version 3 or greater. See the COPYRIGHT file for copyright information.
#    This project is hosted at http://rootin.toot.in .
#
#-----------------------------------------------------------------------------*/


private import language_helper;
private import helper;
private import rootintootin;

public static ControllerBase controller = null;
public static void set_controller(ControllerBase value) {
	controller = value;
}

public static string h(string value) { return Helper.html_escape(value); }
public static string h(int value) { return h(to_s(value)); }
public static string h(uint value) { return h(to_s(value)); }
public static string h(long value) { return h(to_s(value)); }
public static string h(ulong value) { return h(to_s(value)); }
public static string h(float value) { return h(to_s(value)); }
public static string h(double value) { return h(to_s(value)); }
public static string h(bool value) { return h(to_s(value)); }
public static string h(char value) { return h(to_s(value)); }

public static string link_to(string name, string url, string opt="") {
	string format = "";
	if(controller.request.was_format_specified)
		format = "." ~ controller.request.format;
	string uri_before = before(url, "?");
	string uri_after = after(url, "?");
	if(uri_after.length > 0)
		uri_after = "?" ~ uri_after;
	return "<a href=\"" ~ uri_before ~ format ~ uri_after ~ "\"" ~ opt ~ ">" ~ name ~ "</a>";
}

// FIXME: remove the  UI class. Just have everything dumped into the namespace.
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


