/*------------------------------------------------------------------------------
#
#    This file is part of the Rootin Tootin web framework and licensed under the
#    GPL version 3 or greater. See the COPYRIGHT file for copyright information.
#    This project is hosted at http://rootin.toot.in .
#
#-----------------------------------------------------------------------------*/


/****h* ui/ui.d
 *  NAME
 *    ui.d
 *  FUNCTION
 *    Helper functions for html views.
 ******
 */

private import language_helper;
private import web_helper;
private import rootintootin;


/****f* ui/h( string )
 *  FUNCTION
 *    Returns the string filtered by escape_html.
 * SOURCE
 */
public static string h(string value) { return escape_html(value);}
/*******/

/****f* ui/h( int )
 *  FUNCTION
 *    Returns the int converted into a string and filtered by escape_html.
 * SOURCE
 */
public static string h(int value) { return h(to_s(value)); }
/*******/

/****f* ui/h( uint )
 *  FUNCTION
 *    Returns the uint converted into a string and filtered by escape_html.
 * SOURCE
 */
public static string h(uint value) { return h(to_s(value)); }
/*******/

/****f* ui/h( long )
 *  FUNCTION
 *    Returns the long converted into a string and filtered by escape_html.
 * SOURCE
 */
public static string h(long value) { return h(to_s(value)); }
/*******/

/****f* ui/h( ulong )
 *  FUNCTION
 *    Returns the ulong converted into a string and filtered by escape_html.
 * SOURCE
 */
public static string h(ulong value) { return h(to_s(value)); }
/*******/

/****f* ui/h( float )
 *  FUNCTION
 *    Returns the float converted into a string and filtered by escape_html.
 * SOURCE
 */
public static string h(float value) { return h(to_s(value)); }
/*******/

/****f* ui/h( double )
 *  FUNCTION
 *    Returns the double converted into a string and filtered by escape_html.
 * SOURCE
 */
public static string h(double value) { return h(to_s(value)); }
/*******/

/****f* ui/h( bool )
 *  FUNCTION
 *    Returns the bool converted into a string and filtered by escape_html.
 * SOURCE
 */
public static string h(bool value) { return h(to_s(value)); }
/*******/

/****f* ui/h( char )
 *  FUNCTION
 *    Returns the char converted into a string and filtered by escape_html.
 * SOURCE
 */
public static string h(char value) { return h(to_s(value)); }
/*******/

/****f* ui/h( FixedPoint )
 *  FUNCTION
 *    Returns the FixedPoint converted into a string and filtered by escape_html.
 * SOURCE
 */
public static string h(FixedPoint value) { return h(to_s(value)); }
/*******/

/****f* ui/link_to
 *  FUNCTION
 *    Returns a html <a href></a> tag.
 * SOURCE
 */
public static string link_to(string name, string url, string opt="") {
	string real_url = get_real_url(url);
	return "<a href=\"" ~ real_url ~ "\"" ~ opt ~ ">" ~ name ~ "</a>";
}
/*******/

/****f* ui/form_start
 *  FUNCTION
 *    Returns a html <form> tag.
 * SOURCE
 */
public static string form_start(string action, string id, string css_class, string method) {
	string real_url = get_real_url(action);
	return "<form action=\"/" ~ real_url ~ "\" class=\"" ~ css_class ~ "\" id=\"" ~ id ~ "\" method=\"" ~ method ~ "\">";
}
/*******/

/****f* ui/form_end
 *  FUNCTION
 *    Returns a html </form> tag.
 * SOURCE
 */
public static string form_end() {
	return "</form>";
}
/*******/

/****f* ui/errors_for
 *  FUNCTION
 *    Returns the validation errors for a model in html.
 * SOURCE
 */
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
/*******/

/****f* ui/set_controller
 *  FUNCTION
 *    Set the controller that is used by other functions.
 * SOURCE
 */
public static ControllerBase controller = null;
public static void set_controller(ControllerBase value) {
	controller = value;
}
/*******/

/****f* ui/get_real_url
 *  FUNCTION
 *    Returns base_get_real_url with the controller supplied by set_controller.
 * SOURCE
 */
private static string get_real_url(string url) {
	return base_get_real_url(controller, url);
}
/*******/

