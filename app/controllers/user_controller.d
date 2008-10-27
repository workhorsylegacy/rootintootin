

public class UserController : ControllerBase {
	mixin ControllerBaseMixin!(UserController);

	public User[] _users;
	public User _user;
	public char[] _things;

	public void index() {
		User user = new User();
		user.name = "bobrick";

		_users = User.find_all();
		_users ~= user;

		foreach(char[] name, char[] value ; _request.cookies) {
			_things ~= "[" ~ name ~ "]=[" ~ value ~ "], <br />";
		}
	}

	public void New() {
		_user = new User();
	}
}


