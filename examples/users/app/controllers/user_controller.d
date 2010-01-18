
private import rootintootin;
private import user;

public class UserController : ControllerBase {
	public User[] _users;
	public User _user;

	public void index() {
		_users = User.find_all();
		respond_with("users", _users, "index", 200, ["html", "json", "xml"]);
	}

	public void show() {
		_user = User.find(to_ulong(_request._params["id"].value));
		respond_with(_user, "show", 200, ["html", "json", "xml"]);
	}

	public void New() {
		_user = new User();
		respond_with(_user, "new", 200, ["html", "json", "xml"]);
	}

	public void create() {
		_user = new User();
		_user.name = _request._params["user"]["name"].value;
		_user.email = _request._params["user"]["email"].value;

		if(_user.save()) {
			flash_notice("The user was saved.");
			respond_with_redirect(_user, "/users/" ~ to_s(_user.id), 200, ["html", "json", "xml"]);
		} else {
			respond_with(_user, "new", 422, ["html", "json", "xml"]);
		}
	}

	public void edit() {
		_user = User.find(to_ulong(_request._params["id"].value));
		respond_with(_user, "edit", 200, ["html", "json", "xml"]);
	}

	public void update() {
		_user = User.find(to_ulong(_request._params["id"].value));
		_user.name = _request._params["user"]["name"].value;
		_user.email = _request._params["user"]["email"].value;

		if(_user.save()) {
			flash_notice("The user was updated.");
			respond_with_redirect(_user, "/users/" ~ to_s(_user.id), 200, ["html", "json", "xml"]);
		} else {
			respond_with(_user, "edit", 200, ["html", "json", "xml"]);
		}
	}

	public void destroy() {
		_user = User.find(to_ulong(_request._params["id"].value));
		if(_user.destroy()) {
			flash_notice("The user was destroyed.");
			respond_with_redirect("/users", 200, ["html", "json", "xml"]);
		} else {
			flash_error(_user.errors()[0]);
			_users = User.find_all();
			respond_with("users", _users, "index", 422, ["html", "json", "xml"]);
		}
	}
}


