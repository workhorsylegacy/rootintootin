

private import file_base;

public class File : FileBase {
	void validate() {
		_errors = [];
		if(_path.length == 0)
			_errors ~= "The path cannot be blank.";
	}
}


