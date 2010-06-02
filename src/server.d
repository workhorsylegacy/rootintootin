
private import tango.text.convert.Integer;
private import tango.text.Util;
private import tango.io.Stdout;
private import tango.core.Thread;
private import tango.sys.Process;

private import language_helper;
private import helper;
private import rootintootin;
private import rootintootin_server;
private import tcp_server;
private import inotify = inotify;
private import ui;

class Builder {
	private Thread _thread = null;
	public bool _is_ready = false;

	public void start() {
		_thread = new Thread(&builder_method);
		_thread.start();
	}

	private bool wait_for_changes() {
		inotify.file_change[] changes;
		changes = inotify.fs_watch("/home/matt/Projects/rootintootin/examples/users");
		return changes.length > 0;
	}

	private void builder_method() {
		// Rebuild if there are changes
//		if(wait_for_changes()) {
//			_is_ready = false;

		// FIXME: These are hard coded routes. Load the read ones from json
		string[string[string[string]]] routes;
		routes["users"] = null;
		routes["users"]["index"] = null;
		routes["users"]["create"] = "^/users$";
		routes["users"]["new"] = "^/users/new$";
		routes["users"]["show"] = "^/users/\d+$";
		routes["users"]["update"] = "^/users/\d+$";
		routes["users"]["edit"] = "^/users/\d+;edit$";
		routes["users"]["destroy"] = "^/users/\d+$";
		routes["users"]["index"]["^/users$"] = "GET";
		routes["users"]["create"]["^/users$"] = "POST";
		routes["users"]["new"]["^/users/new$"] = "GET";
		routes["users"]["show"]["^/users/\d+$"] = "GET";
		routes["users"]["update"]["^/users/\d+$"] = "PUT";
		routes["users"]["edit"]["^/users/\d+;edit$"] = "GET";
		routes["users"]["destroy"]["^/users/\d+$"] = "DELETE";

		routes["comments"] = null;
		routes["comments"]["index"] = null;
		routes["comments"]["create"] = "^/comments$";
		routes["comments"]["new"] = "^/comments/new$";
		routes["comments"]["show"] = "^/comments/\d+$";
		routes["comments"]["update"] = "^/comments/\d+$";
		routes["comments"]["edit"] = "^/comments/\d+;edit$";
		routes["comments"]["destroy"] = "^/comments/\d+$";
		routes["comments"]["index"]["^/comments$"] = "GET";
		routes["comments"]["create"]["^/comments$"] = "POST";
		routes["comments"]["new"]["^/comments/new$"] = "GET";
		routes["comments"]["show"]["^/comments/\d+$"] = "GET";
		routes["comments"]["update"]["^/comments/\d+$"] = "PUT";
		routes["comments"]["edit"]["^/comments/\d+;edit$"] = "GET";
		routes["comments"]["destroy"]["^/comments/\d+$"] = "DELETE";

		// Get the names of all the models
		string[] model_names;
		auto path = new FilePath("/home/matt/Projects/rootintootin/examples/users/app/models/");
		foreach(string entry; path.toList) {
			if(ends_with(entry, ".d")) {
				model_names ~= entry[0 .. length-2];
			}
		}

		// Get the names of all the views
		string[] view_names;
		foreach(string controller_name, route_maps; routes) {
			path = new FilePath("/home/matt/Projects/rootintootin/examples/users/app/views/" ~ controller_name);
			foreach(string entry; path.toList) {
				if(ends_with(entry, ".html.ed")) {
					view_names ~= "view_" ~ controller_name ~ "_" ~ split(entry, ".html.ed")[0]);
				}
			}
		}

		string[] files;
		foreach(string model_name; model_names)
			files ~= model_name ~ "_base.d";
		foreach(string model_name; model_names)
			files ~= model_name ~ ".d";
		foreach(string controller_name, route_maps; routes)
			files ~= generator.singularize(controller_name) ~ "_controller.d";
		foreach(string view_name; view_names)
			files ~= view_name ~ ".d";
		files ~= "view_layouts_default.d";

		try {
			string CORELIB = "-I /usr/include/d/ldc/ -L /usr/lib/d/libtango-user-ldc.a";
			string ROOTINLIB = "language_helper.d helper.d rootintootin.d ui.d rootintootin_server.d http_server.d tcp_server.d parent_process.d child_process.d db.d db.a inotify.d inotify.a dornado/ioloop.d -L=\"-lmysqlclient\"";
			string command = "ldc -g -of child child.d " ~ files ~ " " ~ CORELIB ~ " " ~ ROOTINLIB;
			this.run_command(command);
		} catch {

		}
//			_is_ready = true;
//		}
	}

	private void run_command(char[] command) {
		Stdout(command).newline.flush;

		// Run the command
		auto child = new Process(true, command);
		child.redirect(Redirect.Output | Redirect.Error | Redirect.Input);
		child.execute();

		// Get its output and if it was successful
		Stdout.copy(child.stdout).flush;
		Stdout.copy(child.stderr).flush;
		Process.Result result = child.wait();
		if(Process.Result.Exit != result.reason) {
			throw new Exception("Process '" ~ child.programName ~ "' (" ~ 
				to_s(child.pid) ~ ") exited with reason " ~ to_s(result.reason) ~ 
				", status " ~ to_s(result.status) ~ "");
		}
	}
}

int main() {
	// Create the builder
	auto builder = new Builder();
	builder.start();

	// Create and start the sever
	IOLoop.use_epoll = true;
	ushort port = 3000;
	int max_waiting_clients = 100;
//	auto server = new RootinTootinParent(
//				port, max_waiting_clients, "./child");

//	server.start();

	return 0;
}

