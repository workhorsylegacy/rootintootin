
private import rootintootin;
private import user;

public class UserController : ControllerBase {
	public User[] _users;
	public User _user;

	public void index() {
		_users = User.find_all();
		respond_with(_users, "index", 200, ["html", "json"]);
	}

	public void show() {
		_user = User.find(to_ulong(_request._params["id"]));
		respond_with(_user, "show", 200, ["html", "json"]);
	}

	public void New() {
		_user = new User();
		respond_with(_user, "new", 200, ["html", "json"]);
	}

	public void create() {
		_user = new User();
		_user.name = _request._params["user[name]"];
		_user.email = _request._params["user[email]"];

		if(_user.save()) {
			flash_notice("The user was saved.");
			respond_with_redirect(_user, "show", 200, ["html", "json"]);
		} else {
			respond_with(_user, "new", 422, ["html", "json"]);
		}
	}

	public void edit() {
		_user = User.find(to_ulong(_request._params["id"]));
		respond_with(_user, "edit", 200, ["html", "json"]);
	}

	public void update() {
		_user = User.find(to_ulong(_request._params["id"]));
		_user.name = _request._params["user[name]"];
		_user.email = _request._params["user[email]"];

		if(_user.save()) {
			flash_notice("The user was updated.");
			respond_with_redirect(_user, "show", 200, ["html", "json"]);
		} else {
			respond_with(_user, "edit", 200, ["html", "json"]);
		}
	}

	public void destroy() {
		_user = User.find(to_ulong(_request._params["id"]));
		if(_user.destroy()) {
			flash_notice("The user was destroyed.");
			respond_with_redirect("index", 200, ["html", "json"]);
		} else {
			flash_error(_user.errors()[0]);
			respond_with(_user, "index", 422, ["html", "json"]);
		}
	}
}


