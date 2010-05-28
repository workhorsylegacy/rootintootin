
private import tango.io.Stdout;
private import TangoRegex = tango.text.Regex;

private import rootintootin;
private import language_helper;
private import tcp_server;
private import http_server;
private import child_process;


public class Runner : RunnerBase {
	private string generate_view(ControllerBase controller, string controller_name, string view_name) {
		return "generate_view";
	}
	public string run_action(Request request, string controller_name, string action_name, string id, out string[] events_to_trigger) {
		return "run_action";
	}
}

public class ExampleServerChild : HttpServerChild {
	public char[] on_request(char[] request) {
		return "yeah! example time.";
	}
}

int main() {
	// Create the routes
	string[TangoRegex.Regex][string][string] routes;
	routes["users"]["index"][new TangoRegex.Regex(r"^/users$")] = "GET";

	RunnerBase runner = new Runner();
	auto server = new ExampleServerChild();
	server.start();

	return 0;
}

