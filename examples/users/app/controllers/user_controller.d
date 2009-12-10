
import rootintootin;
import user;

public class UserController : ControllerBase {
	public User[] _users;
	public User _user;

	public void index() {
		_users = User.find_all();
	}

	public void show() {
		_user = User.find(to_ulong(_request._params["id"]));
	}

	public void New() {
		_user = new User();
	}

	public void create() {
		_user = new User();
		_user.name = _request._params["user[name]"];
		_user.email = _request._params["user[email]"];

		if(_user.save()) {
			flash_notice("The user was saved.");
			redirect_to("/users/show/" ~ to_s(_user.id));
		} else {
			render_view("new");
		}
	}

	public void edit() {
		_user = User.find(to_ulong(_request._params["id"]));
	}

	public void update() {
		_user = User.find(to_ulong(_request._params["id"]));
		_user.name = _request._params["user[name]"];
		_user.email = _request._params["user[email]"];

		if(_user.save()) {
			flash_notice("The user was updated.");
			redirect_to("/users/show/" ~ to_s(_user.id));
		} else {
			render_view("edit");
		}
	}

	public void destroy() {
		_user = User.find(to_ulong(_request._params["id"]));
		if(_user.destroy()) {
			redirect_to("/users/index");
		} else {
			flash_error(_user.errors()[0]);
			render_view("index");
		}
	}
}


