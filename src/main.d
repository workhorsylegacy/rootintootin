


private import regex;
private import tango.io.Stdout;


int main() {
	Regex.init(2);

	auto a = new Regex("^/users$");
	auto b = new Regex("^/comments$");

	if(a.is_match("/users"))
		Stdout("a matched").newline.flush;
	else
		Stdout("a did not match").newline.flush;

	if(b.is_match("/comments"))
		Stdout("b matched").newline.flush;
	else
		Stdout("b did not match").newline.flush;

	return 0;
}


