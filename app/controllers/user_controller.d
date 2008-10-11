

public class UserController : ControllerBase {
	mixin ControllerBaseMixin!(UserController);

	public User[] _users;
	public User _user;

	public void index() {
		User user = new User();
		user.name = "bobrick";

		_users = User.find_all();
		_users ~= user;
	}

	public void New() {
		_user = new User();
	}
}


