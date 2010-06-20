/*------------------------------------------------------------------------------
#
#    This file is part of the Rootin Tootin web framework and licensed under the
#    GPL version 3 or greater. See the COPYRIGHT file for copyright information.
#    This project is hosted at http://rootin.toot.in .
#
#-----------------------------------------------------------------------------*/


private import tango.io.Stdout;
private import tango.core.Thread;
private import tango.sys.Process;
private import tango.io.device.File;
private import tango.text.json.Json;

private import language_helper;
private import file_system;


public class AppBuilder {
	private Thread _thread = null;
	private void delegate() _on_build_func = null;
	private string _app_path = null;

	public this(string app_path) {
		_app_path = app_path;
	}

	public void start() {
		_thread = new Thread(&build_loop);
		_thread.start();
	}

	public void on_build_success(void delegate() func) {
		_on_build_func = func;
	}

	private void wait_for_changes() {
		string command = "inotifywait -r -q -c -e modify -e create -e attrib -e move -e delete " ~ _app_path;
		string c_stdout, c_stderr;
		this.run_command(command, c_stdout, c_stderr);
		//string dir = split(c_stdout, "/ ")[0];

		//Stdout(c_stdout).flush;
		//Stdout(c_stderr).flush;
		//Stdout.format("length: {}\n", to_s(c_stdout.length)).flush;
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

	private void build_loop() {
		// Loop forever, and rebuild
		do {
			// Rebuild the application
			this.build_method();

			if(_on_build_func)
				_on_build_func();

			// Wait here and block till files change
			wait_for_changes();

		} while(true);
	}

	private void build_method() {
		// Copy all the app files, and do code generation
		this.run_command("python /usr/bin/rootintootin_run " ~ _app_path ~ " application");

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
		EntryType type = EntryType.file;
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
			string ROOTINLIB = "language_helper.d helper.d rootintootin.d ui.d rootintootin_server.d http_server.d tcp_server.d server_process.d app_process.d app_builder.d db.d db.a shared_memory.d shared_memory.a file_system.d file_system.a regex.d regex.a dornado/ioloop.d -L=\"-lmysqlclient\" -L=\"-lpcre\"";
			string command = "ldc -g -w -of application application.d " ~ tango.text.Util.join(files, " ") ~ " " ~ CORELIB ~ " " ~ ROOTINLIB;
//			Stdout.format("view_names: {}", tango.text.Util.join(view_names, " ")).newline.flush;
//			Stdout.format("model_names: {}", tango.text.Util.join(model_names, " ")).newline.flush;
//			Stdout.format("files: {}", tango.text.Util.join(files, " ")).newline.flush;
			Stdout("\nRebuilding application ...").newline.flush;
			this.run_command(command);

			// Make sure the application was built
			bool has_app = false;
			foreach(string n; file_system.dir_entries(".", EntryType.file)) {
				if(n == "application")
					has_app = true;
			}
			if(has_app) {
				Stdout("\nApplication build successful!").newline.flush;
			} else {
				Stdout("\nApplication build failed!").newline.flush;
				Stdout("Press ctrl+c to exit ...").newline.flush;
				return;
			}

			// FIXME: Run the app
		} catch {

		}
	}

	private void run_command(string command) {
		string stdout_message, stderr_message;
		this.run_command(command, stdout_message, stderr_message);
		Stdout(stdout_message).flush;
		Stdout(stderr_message).flush;
	}

	private void run_command(string command, out string c_stdout, out string c_stderr) {
		// Run the command
		auto child = new Process(true, command);
		child.redirect(Redirect.Output | Redirect.Error | Redirect.Input);
		child.execute();

		// Throw if the child returned an error code
		Process.Result result = child.wait();
		if(Process.Result.Exit != result.reason) {
			throw new Exception("Process '" ~ child.programName ~ "' (" ~ 
				to_s(child.pid) ~ ") exited with reason " ~ to_s(result.reason) ~ 
				", status " ~ to_s(result.status) ~ "");
		}

		// Get the output
		c_stdout = [];
		c_stderr = [];
		char[1] buffer;
		int len = -1;
		while((len = child.stdout.read(buffer)) > 0) {
			c_stdout ~= buffer;
		}
		c_stdout = trim(c_stdout);

		while((len = child.stderr.read(buffer)) > 0) {
			c_stderr ~= buffer;
		}
		c_stderr = trim(c_stderr);
	}
}


