

public class UserController : ControllerBase {
	mixin ControllerBaseMixin!(UserController);

	public User[] _users;
	public User _user;
	public char[] _things;

	public void index() {
		_users = User.find_all();
	}

	public void show() {
		_user = User.find(to_ulong(_request.params["id"]));
	}

	public void New() {
		_user = new User();
	}

	public void create() {
		_user = new User();
		_user.name = _request.params["user[name]"];
		_user.email = _request.params["user[email]"];

		if(_user.save()) {
			redirect_to("/users/show/" ~ to_s(_user.id));
		} else {
			redirect_to("http://yahoo.com/");
//			_response.render("new");
		}
	}

	public void edit() {
		_user = User.find(to_ulong(_request.params["id"]));
	}

	public void update() {
		_user = User.find(to_ulong(_request.params["id"]));
		_user.name = _request.params["user[name]"];
		_user.email = _request.params["user[email]"];

		if(_user.save()) {
			redirect_to("/users/show/" ~ to_s(_user.id));
		} else {
			redirect_to("http://yahoo.com/");
//			_response.render("edit");
		}
	}

	public void destroy() {
		_user = User.find(to_ulong(_request.params["id"]));
		_user.destroy();

		redirect_to("/users/index");
	}
}


