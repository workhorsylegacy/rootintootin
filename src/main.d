
import tango.io.Stdout;
import regex;

void main() {
	Regex.init(14);
	Regex[] routes = [
					new Regex("^/users$"),
					new Regex("^/users/\\d+$"), 
					new Regex("^/users/\\d+;edit$"), 
					new Regex("^/users$"), 
					new Regex("^/users/\\d+$"), 
					new Regex("^/users/\\d+$"), 
					new Regex("^/users/new$")
	];

	Stdout.format("{}", routes[1].is_match("/users/2")).newline.flush;
}

