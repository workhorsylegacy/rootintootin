

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


