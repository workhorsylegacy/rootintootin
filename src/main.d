
private import tango.text.convert.Integer;
private import tango.text.Util;
private import tango.io.Stdout;
private import tango.time.chrono.Gregorian;
private import tango.time.WallClock;
private import tango.core.Thread;
private import TangoRegex = tango.text.Regex;

private import language_helper;
private import helper;
private import rootintootin;
private import rootintootin_server;
private import inotify = inotify;
private import ui;
private import parent_process;

public class Runner : RunnerBase {
	private string generate_view(ControllerBase controller, string controller_name, string view_name) {
		return "generate_view";
	}
	public string run_action(Request request, string controller_name, string action_name, string id, out string[] events_to_trigger) {
		return "run_action";
	}
}

class Builder : ParentProcess {
	private Thread _thread = null;
	public bool _is_ready = false;

	private void builder_method() {
		inotify.file_change[] changes;
		size_t len=0;
		while(true) {
			changes = inotify.fs_watch("/home/matt", len);
			Stdout.format("len: {}", len).newline.flush;

			size_t i=0;
			for(i=0; i<len; i++) {
				Stdout.format("changes[i].name: {}", changes[i].name).newline.flush;
				Stdout.format("status: {}", inotify.to_s(changes[i].status)).newline.flush;
			}
			Stdout.newline.flush;
		}
	}

	public void start() {
		_thread = new Thread(&builder_method);
		_thread.start();
	}
}

int main() {
	// Create the builder
	auto builder = new Builder();
	builder.start();

	// Create the routes
	string[TangoRegex.Regex][string][string] routes;
	routes["users"]["index"][new TangoRegex.Regex(r"^/users$")] = "GET";

	// Create and start the sever
	IOLoop.use_epoll = true;
	ushort port = 3000;
	int max_waiting_clients = 100;
	RunnerBase runner = new Runner();
	auto server = new RootinTootinServer(
				runner, routes, 
				port, max_waiting_clients, 
				"localhost", "root", 
				"letmein", "users");
	server.start();

	return 0;
}
