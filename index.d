
import std.string;

public string render() { 
	// Generate the view as an array of strings
	string[] builder;
	builder ~= "<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Transitional//EN\"
       \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd\">

<html xmlns=\"http://www.w3.org/1999/xhtml\" xml:lang=\"en\" lang=\"en\">
	<head>
		<meta http-equiv=\"content-type\" content=\"text/html;charset=UTF-8\" />
		<title>Example D View</title>
	</head>
	<body>
		<table border=\"1\">
			"; 
	builder ~= "
		</table>
	</body>
</html>
"; 
	return std.string.join(builder, ""); 
}
