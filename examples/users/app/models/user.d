
private import dlang_helper;
private import user_base;

public class User : UserBase {
	public void validate() {
		_errors = [];
		validates_presence_of(["name", "email"]);
	}
}

unittest {
	describe("User", 
		it("Should require the name and email fields to be valid", function() {
			auto user = new User();
			assert(!user.is_valid);
			
			user.name = "tim";
			user.email = "tim@blah.com";
			assert(user.is_valid);
		})
	);
}


