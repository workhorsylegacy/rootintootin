

private import file_base;

public class File : FileBase {
	void validate() {
		_errors = [];
		if(_name.length == 0)
			_errors ~= "The name cannot be blank.";
	}
}


