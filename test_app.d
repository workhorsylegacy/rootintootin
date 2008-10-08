
// clear; gdc -o test_app test_app.d rail_cannon.d rail_cannon_server.d


import std.stdio;
import std.socket;
import std.regexp;

import rail_cannon;
import rail_cannon_server;

import index;


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

public void routing(string action, Socket socket) {
	int[int] line_translations;
	UserController controller = new UserController();

	if(action == "index") {
		controller.index();
		socket.send(IndexView.render(controller, line_translations));
	}
}

int main() {
	Server.start(&routing);

	return 0;
}


