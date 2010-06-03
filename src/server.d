
private import tango.text.convert.Integer;
private import tango.text.Util;
private import tango.io.Stdout;
private import tango.core.Thread;
private import tango.sys.Process;
private import tango.io.FilePath;
//private import tango.io.FileScan;
private import TangoPath = tango.io.Path;

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

	private string singularize(string[string] nouns, string noun) {
		foreach(string singular, string plural; nouns) {
			if(noun == singular || noun == plural) {
				return singular;
			} else if(noun == capitalize(singular) || noun == capitalize(plural)) {
				return capitalize(singular);
			}
		}
	}

	private void builder_method() {
		// Rebuild if there are changes
//		if(wait_for_changes()) {
//			_is_ready = false;

		// FIXME: These are hard coded routes. Load the read ones from json
		string[string][string][string] routes;
		routes["users"] = null;
		routes["users"]["index"] = null;
		routes["users"]["create"] = null;
		routes["users"]["new"] = null;
		routes["users"]["show"] = null;
		routes["users"]["update"] = null;
		routes["users"]["edit"] = null;
		routes["users"]["destroy"] = null;
		routes["users"]["index"][r"^/users$"] = "GET";
		routes["users"]["create"][r"^/users$"] = "POST";
		routes["users"]["new"][r"^/users/new$"] = "GET";
		routes["users"]["show"][r"^/users/\d+$"] = "GET";
		routes["users"]["update"][r"^/users/\d+$"] = "PUT";
		routes["users"]["edit"][r"^/users/\d+;edit$"] = "GET";
		routes["users"]["destroy"][r"^/users/\d+$"] = "DELETE";

		routes["comments"] = null;
		routes["comments"]["index"] = null;
		routes["comments"]["create"] = null;
		routes["comments"]["new"] = null;
		routes["comments"]["show"] = null;
		routes["comments"]["update"] = null;
		routes["comments"]["edit"] = null;
		routes["comments"]["destroy"] = null;
		routes["comments"]["index"][r"^/comments$"] = "GET";
		routes["comments"]["create"][r"^/comments$"] = "POST";
		routes["comments"]["new"][r"^/comments/new$"] = "GET";
		routes["comments"]["show"][r"^/comments/\d+$"] = "GET";
		routes["comments"]["update"][r"^/comments/\d+$"] = "PUT";
		routes["comments"]["edit"][r"^/comments/\d+;edit$"] = "GET";
		routes["comments"]["destroy"][r"^/comments/\d+$"] = "DELETE";

		// FIXME: These are hard coded nouns. Load the read ones from json
		string[string] nouns;
		nouns["user"] = "users";
		nouns["comment"] = "comments";

            bool filter(FilePath p, bool isDir) {
                char[] name = p.name;
                if(isDir && name[0] != '.')
                    return true;
                return false;
            }
            scope dir = new FilePath("file:///home/matt/");
            foreach(p; dir.toList(&filter)) {
                Stdout(p.name);
            }

		// Get the names of all the models
		string[] model_names;
		auto path = new FilePath("/home/matt/Projects/rootintootin/examples/users/app/models/");
		Stdout.format("length: {}", path.toList()).newline.flush;
		foreach(FilePath entry; path.toList()) {
			auto name = entry.toString();
			Stdout.format("model name: {}", name).newline.flush;
			if(ends_with(name, ".d")) {
				model_names ~= name[0 .. length-2];
			}
		}

		// Get the names of all the views
		string[] view_names;
		foreach(string controller_name, string[string][string] route_maps; routes) {
			path = new FilePath("/home/matt/Projects/rootintootin/examples/users/app/views/" ~ controller_name);
			foreach(FilePath entry; path.toList()) {
				auto name = entry.toString();
				Stdout.format("view name: {}", name).newline.flush;
				if(ends_with(name, ".html.ed")) {
					view_names ~= "view_" ~ controller_name ~ "_" ~ split(name, ".html.ed")[0];
				}
			}
		}

		string[] files;
		foreach(string model_name; model_names)
			files ~= model_name ~ "_base.d";
		foreach(string model_name; model_names)
			files ~= model_name ~ ".d";
		foreach(string controller_name, string[string][string] route_maps; routes)
			files ~= singularize(nouns, controller_name) ~ "_controller.d";
		foreach(string view_name; view_names)
			files ~= view_name ~ ".d";
		files ~= "view_layouts_default.d";

		try {
			string CORELIB = "-I /usr/include/d/ldc/ -L /usr/lib/d/libtango-user-ldc.a";
			string ROOTINLIB = "language_helper.d helper.d rootintootin.d ui.d rootintootin_server.d http_server.d tcp_server.d parent_process.d child_process.d db.d db.a inotify.d inotify.a dornado/ioloop.d -L=\"-lmysqlclient\"";
			string command = "ldc -g -of child child.d " ~ tango.text.Util.join(files, " ") ~ " " ~ CORELIB ~ " " ~ ROOTINLIB;
			Stdout.format("view_names: {}", tango.text.Util.join(view_names, " ")).newline.flush;
			Stdout.format("model_names: {}", tango.text.Util.join(model_names, " ")).newline.flush;
			Stdout.format("files: {}", tango.text.Util.join(files, " ")).newline.flush;
			//this.run_command(command);
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

