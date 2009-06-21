

public class File : FileModelBase {
	void reset_validation_errors() {
		if(this._name.length == 0)
			this._errors ~= "The name cannot be blank.";
	}
}


