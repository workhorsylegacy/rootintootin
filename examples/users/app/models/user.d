
private import user_base;

public class User : UserBase {
	public void validate() {
		_errors = [];
		validates_presence_of(["name", "email"]);
	}
}


