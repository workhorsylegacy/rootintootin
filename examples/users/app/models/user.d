

public class User : UserModelBase {
	void reset_validation_errors() {
		if(this._name == "bobrick") {
			this._errors ~= "bobrick is too awesome to use";
		}
	}
}


