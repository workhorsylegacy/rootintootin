
private import tango.io.Stdout;
private import TangoRegex = tango.text.Regex;

private import rootintootin;
private import language_helper;
private import rootintootin_server;


public class Runner : RunnerBase {
	private string generate_view(ControllerBase controller, string controller_name, string view_name) {
		return "generate_view";
	}
	public string run_action(Request request, string controller_name, string action_name, string id, out string[] events_to_trigger) {
		return "run_action";
	}
}

int main() {
	// Create the routes
	string[TangoRegex.Regex][string][string] routes;
	routes["users"]["index"][new TangoRegex.Regex(r"^/users$")] = "GET";

	RunnerBase runner = new Runner();
	auto server = new RootinTootinChild(runner, routes, 
							"localhost", "root", "letmein", "users");
	server.start();

	return 0;
}

