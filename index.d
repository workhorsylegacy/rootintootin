
public string render(UserController controller, out int[int] line_translations) {
	// Generate the view as an array of strings
	string[] builder;
	builder ~= "<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Transitional//EN\"\n";
	builder ~= "       \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd\">\n";
	builder ~= "\n";
	builder ~= "<html xmlns=\"http://www.w3.org/1999/xhtml\" xml:lang=\"en\" lang=\"en\">\n";
	builder ~= "	<head>\n";
	builder ~= "		<meta http-equiv=\"content-type\" content=\"text/html;charset=UTF-8\" />\n";
	builder ~= "		<title>Example D View</title>\n";
	builder ~= "	</head>\n";
	builder ~= "	<body>\n";
	builder ~= "		<table border=\"1\">\n";
				foreach(User user ; controller.get_array!(User[])("users")) {
	builder ~= "			<tr>\n";
	builder ~= "				<td>"; builder ~= user.name(); builder ~= "</td>\n";
	builder ~= "			</tr>\n";
				}
	builder ~= "		</table>\n";
	builder ~= "	</body>\n";
	builder ~= "</html>\n";

	// Set the line translations so we can match lines in the blah.html.ed with lines in the blah.html.dll
	line_translations[20] = 10;
	line_translations[22] = 12;
	line_translations[24] = 14;

	return std.string.join(builder, "");
}
