

public class UserController : ControllerBase {
	mixin ControllerBaseMixin!(UserController);

	public User[] _users;
	public User _user;
	public char[] _things;

	public void index() {
		_users = User.find_all();
	}

	public void show() {
		_user = User.find(tango.text.convert.Integer.parse(_request.params["id"]));
	}

	public void New() {
		_user = new User();
	}

	public void create() {
		_user = new User();
		_user.name = _request.params["user[name]"];
		_user.email = _request.params["user[email]"];

		if(_user.save()){
//			_response.redirect_to("show/" ~ tango.text.convert.Integer.parse.toString(_user.id));
		} else {
//			_response.render("new");
		}
	}

	public void edit() {
		_user = User.find(tango.text.convert.Integer.parse(_request.params["id"]));
	}

	public void update() {
	}

	public void destroy() {
		_user = User.find(tango.text.convert.Integer.parse(_request.params["id"]));
	}
}


