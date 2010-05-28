
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
private import tcp_server;
private import inotify = inotify;
private import ui;


class ExampleServerParent : TcpServerParent {
	public this(ushort port, int max_waiting_clients) {
		super(port, max_waiting_clients, "./app");
	}

	protected void on_started() {
		Stdout.format("Example server running on http://localhost:{}\n", this._port).flush;
	}
}

public class Runner : RunnerBase {
	private string generate_view(ControllerBase controller, string controller_name, string view_name) {
		return "generate_view";
	}
	public string run_action(Request request, string controller_name, string action_name, string id, out string[] events_to_trigger) {
		return "run_action";
	}
}

class Builder {
	private Thread _thread = null;
	public bool _is_ready = false;

	public void start() {
		_thread = new Thread(&builder_method);
		_thread.start();
	}

	private bool wait_for_changes() {
		inotify.file_change[] changes;
		changes = inotify.fs_watch("/home/matt");
		return changes.length > 0;
	}

	private void builder_method() {
		// Rebuild if there are changes
		if(wait_for_changes()) {
			_is_ready = false;

			

			_is_ready = true;
		}
	}
}

class Server {
	public this() {
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
		auto server = new ExampleServerParent(
					port, max_waiting_clients);
		//auto server = new RootinTootinServer(
		//			runner, routes, 
		//			port, max_waiting_clients, 
		//			"localhost", "root", 
		//			"letmein", "users");
		server.start();
	}
}

int main() {
	auto server = new Server();

	return 0;
}

