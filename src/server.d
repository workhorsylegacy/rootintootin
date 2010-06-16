/*------------------------------------------------------------------------------
#
#    This file is part of the Rootin Tootin web framework and licensed under the
#    GPL version 3 or greater. See the COPYRIGHT file for copyright information.
#    This project is hosted at http://rootin.toot.in .
#
#-----------------------------------------------------------------------------*/


private import tango.text.convert.Integer;
private import tango.text.Util;
private import tango.io.Stdout;
private import tango.core.Thread;
private import tango.sys.Process;
private import tango.io.device.File;
private import tango.text.json.Json;

private import language_helper;
private import rootintootin;
private import rootintootin_server;
private import inotify = inotify;
private import file_system;


class Builder {
	private Thread _thread = null;
	public bool _is_ready = false;

	public void start() {
		_thread = new Thread(&builder_method);
		_thread.start();
	}

	private bool wait_for_changes() {
		inotify.file_change[] changes;
		// FIXME: This needs to be the project directory
		changes = inotify.fs_watch("./");
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
		throw new Exception("Can't singularize unknown noun '" ~ noun ~ "'.");
	}

	private void builder_method() {
		// Rebuild if there are changes
//		if(wait_for_changes()) {
//			_is_ready = false;

		// Read the routes from the config file
		auto file = new File("config/routes.json", File.ReadExisting);
		auto content = new char[cast(size_t)file.length];
		file.read(content);
		file.close();
		auto values = (new Json!(char)).parse(content).toObject();

		string[string][string][string] routes;
		foreach(n1, v1; values.attributes()) {
			//Stdout.format("name: {}", n1).newline.flush;
			foreach(n2, v2; v1.toObject().attributes()) {
				//Stdout.format("	name: {}", n2).newline.flush;
				routes[n2] = null;
				foreach(n3, v3; v2.toObject().attributes()) {
					//Stdout.format("		name: {}", n3).newline.flush;
					routes[n2][n3] = null;
					foreach(n4, v4; v3.toObject().attributes()) {
						//Stdout.format("			name: {} value: {}", n4, v4.toString()).newline.flush;
						routes[n2][n3][n4] = v4.toString();
					}
				}
			}
		}

		// Read the nouns from the config file
		file = new File("config/nouns.json", File.ReadExisting);
		content = new char[cast(size_t)file.length];
		file.read(content);
		file.close();
		values = (new Json!(char)).parse(content).toObject();

		string[string] nouns;
		foreach(n1, v1; values.attributes()) {
			//Stdout.format("name: {}", n1).newline.flush;
			foreach(n2, v2; v1.toObject().attributes()) {
				//Stdout.format("	name: {} value: {}", n2, v2.toString()).newline.flush;
				nouns[n2] = v2.toString();
			}
		}

		// Read the config from the config file
		file = new File("config/config.json", File.ReadExisting);
		content = new char[cast(size_t)file.length];
		file.read(content);
		file.close();
		values = (new Json!(char)).parse(content).toObject();

		string[string][string] config;
		foreach(n1, v1; values.attributes()) {
			//Stdout.format("name: {}", n1).newline.flush;
			foreach(n2, v2; v1.toObject().attributes()) {
				//Stdout.format("	name: {}", n2).newline.flush;
				config[n2] = null;
				foreach(n3, v3; v2.toObject().attributes()) {
					//Stdout.format("			name: {} value: {}", n3, v3.toString()).newline.flush;
					config[n2][n3] = v3.toString();
				}
			}
		}

		// Get the names of all the models
		string[] model_names;
		string name = "app/models/";
		entry_type type = entry_type.file;
		foreach(string entry; dir_entries(name, type)) {
//			Stdout.format("model name: {}", entry).newline.flush;
			if(ends_with(entry, ".d")) {
				model_names ~= entry[0 .. length-2];
			}
		}

		// Get the names of all the views
		string[] view_names;
		foreach(string controller_name, string[string][string] route_maps; routes) {
			name = "app/views/" ~ controller_name;
			foreach(string entry; dir_entries(name, type)) {
//				Stdout.format("view name: {}", entry).newline.flush;
				if(ends_with(entry, ".html.ed")) {
					view_names ~= "view_" ~ controller_name ~ "_" ~ split(entry, ".html.ed")[0];
				}
			}
		}

		// Get all the app's files to compile
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

		// Build the app
		try {
			string CORELIB = "-I /usr/include/d/ldc/ -L /usr/lib/d/libtango-user-ldc.a";
			string ROOTINLIB = "language_helper.d helper.d rootintootin.d ui.d rootintootin_server.d http_server.d tcp_server.d server_process.d app_process.d db.d db.a inotify.d inotify.a shared_memory.d shared_memory.a file_system.d file_system.a regex.d regex.a dornado/ioloop.d -L=\"-lmysqlclient\" -L=\"-lpcre\"";
			string command = "ldc -g -w -of application application.d " ~ tango.text.Util.join(files, " ") ~ " " ~ CORELIB ~ " " ~ ROOTINLIB;
//			Stdout.format("view_names: {}", tango.text.Util.join(view_names, " ")).newline.flush;
//			Stdout.format("model_names: {}", tango.text.Util.join(model_names, " ")).newline.flush;
//			Stdout.format("files: {}", tango.text.Util.join(files, " ")).newline.flush;
			Stdout("Rebuilding application ...").newline.flush;
			this.run_command(command);

			// Make sure the application was built
			bool has_app = false;
			foreach(string n; file_system.dir_entries(".", entry_type.file)) {
				if(n == "application")
					has_app = true;
			}
			if(has_app) {
				Stdout("Application build successful!").newline.flush;
			} else {
				Stdout("Application build failed!").newline.flush;
				Stdout("Press ctrl+c to exit ...").newline.flush;
				return;
			}

			// Create and start the sever
			IOLoop.use_epoll = true;
			ushort port = to_ushort(config["server_configuration"]["port"]);
			int max_waiting_clients = to_int(config["server_configuration"]["max_waiting_clients"]);
			auto server = new RootinTootinServer(
						port, max_waiting_clients, "./application");

			server.start();
		} catch {

		}
//			_is_ready = true;
//		}
	}

	private void run_command(char[] command) {
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

	return 0;
}

