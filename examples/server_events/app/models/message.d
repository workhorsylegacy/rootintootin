

private import message_base;

public class Message : MessageBase {
	void reset_validation_errors() {
		if(this._text.length == 0)
			this._errors ~= "The text cannot be blank.";
	}
}


