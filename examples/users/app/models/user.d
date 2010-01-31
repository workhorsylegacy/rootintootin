
private import user_base;

public class User : UserBase {
	public void validate() {
		_errors = [];
		if(_name == null || _name.length == 0)
			_errors ~= "The name cannot be blank.";
		if(_email == null || _email.length == 0)
			_errors ~= "The email cannot be blank.";
	}
}


