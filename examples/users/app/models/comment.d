
private import language_helper;
private import comment_base;
private import user;

public class Comment : CommentBase {
	public void validate() {
		_errors = [];
		validates_presence_of(["value"]);

		if(this.parent is null) {
			_errors ~= "The user cannot be null.";
		}
	}
}

unittest {
	describe("Comment", 
		it("Should require the value and user fields to be valid", function() {
			auto comment = new Comment();
			assert(!comment.is_valid);
			
			comment.value = "Likes to eat pie";
			auto user = new User();
			comment.parent = user;
			assert(comment.is_valid);
		})
	);
}
