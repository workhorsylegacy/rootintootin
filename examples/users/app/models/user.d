

public class User : UserModelBase {
	void reset_validation_errors() {
		if(this._name.length == 0)
			this._errors ~= "The name cannot be blank.";
		if(this._email.length == 0)
			this._errors ~= "The email cannot be blank.";
	}
}


