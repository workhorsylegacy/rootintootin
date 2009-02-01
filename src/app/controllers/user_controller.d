

public class UserController : ControllerBase {
	mixin ControllerBaseMixin!(UserController);

	public User[] _users;
	public User _user;
	public char[] _things;

	public void index() {
		_users = User.find_all();

		foreach(char[] name, char[] value ; _request.cookies) {
			_things ~= "[" ~ name ~ "]=[" ~ value ~ "], <br />";
		}
	}

	public void show() {
		_user = User.find(tango.text.convert.Integer.parse(_request.params["id"]));
	}

	public void New() {
		_user = new User();
	}

	public void create() {
		_user = new User();
		_user.name = _request.params["name"];
		_user.email = _request.params["email"];

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

	public void Delete() {
		_user = User.find(tango.text.convert.Integer.parse(_request.params["id"]));
	}
}


