


private import regex;


int main() {
	regex_init(2);

	setup_regex(0, "^/users$");
	match_regex(0, "/users");

	setup_regex(1, "^/comments$");
	match_regex(1, "/comments");

	return 0;
}


