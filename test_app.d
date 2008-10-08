
// clear; gdc -o test_app test_app.d rail_cannon.d rail_cannon_server.d


import std.stdio;
import std.socket;
import std.regexp;

import rail_cannon;
import rail_cannon_server;


public class User : ModelBase {
	mixin ModelBaseMixin!(User, "user");

	public Field!(string) name = null;
	public Field!(bool) hide_email_address = null;

	public this() {
		name = new Field!(string)("name");
		hide_email_address = new Field!(bool)("hide_email_address");
	}
}

public class UserController {
	mixin ControllerBaseMixin!(UserController);

	public void index() {
		User[] users = User.find_all();
		User user = new User();
		user.name = "bobrick";
		users ~= user;

		set_array!(User[])("users", users);
		set!(User)("user", user);


		users = get_array!(User[])("users");
		user = get!(User)("user");
	}
}

public string render(UserController controller, out int[int] line_translations) { 
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
	 foreach(User user ; controller.get_array!(User[])("users")) { 
	builder ~= "
			<tr>
				<td>"; 
	builder ~=  user.name() ; 
	builder ~= "</td>
				<td>
					"; 
	builder ~= 
						std.string.toString(user.hide_email_address())
					; 
	builder ~= "
				</td>
			</tr>
			"; 
	 } 
	builder ~= "
		</table>
	</body>
</html>
"; 
	return std.string.join(builder, ""); 
}

public void routing(string action, Socket socket) {
	int[int] line_translations;
	UserController controller = new UserController();
	if(action == "index") {
		controller.index();
		socket.send(render(controller, line_translations));
	}
}

int main() {
	Server.start(&routing);

	return 0;
}


