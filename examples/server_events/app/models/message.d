

private import message_base;

public class Message : MessageBase {
	void validate() {
		_errors = [];
		if(_text.length == 0)
			_errors ~= "The text cannot be blank.";
	}
}


