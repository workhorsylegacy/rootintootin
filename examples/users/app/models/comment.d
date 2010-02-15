
private import comment_base;

public class Comment : CommentBase {
	public void validate() {
		_errors = [];
		validates_presence_of(["value"]);

		if(this.parent is null) {
			_errors ~= "The user cannot be null.";
		}
	}
}



