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
private import tango.io.FilePath;
private import tango.text.json.Json;

private import language_helper;
private import file_system;


public class AppBuilder {
	private Thread _thread = null;
	private void delegate() _on_success_func = null;
	private void delegate(char[]) _on_failure_func = null;
	private string _app_path = null;

	public this(string app_path, void delegate() on_build_success=null, void delegate(char[]) on_build_failure=null) {
		_app_path = app_path;
		_on_success_func = on_build_success;
		_on_failure_func = on_build_failure;
	}

	public void start() {
		_thread = new Thread(&build_loop);
		_thread.start();
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
		char[] compile_error = null;

		// Loop forever, and rebuild
		do {
			// Rebuild the application
			compile_error = this.build_method();
			if(compile_error == null) {
				Stdout("\nApplication build successful!").newline.flush;
				if(_on_success_func)
					_on_success_func();
			} else {
				Stdout("\nApplication build failed!").newline.flush;
				if(_on_failure_func)
					_on_failure_func(compile_error);
			}

			// Wait here and block till files change
			wait_for_changes();

		} while(true);
	}

	private char[] build_method() {
		char[] compile_error = null;

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
		char[] c_stdout, c_stderr;
		try {
			string CORELIB = "-I /usr/include/d/ldc/ -L /usr/lib/d/libtango-user-ldc.a";

			string command = 
				"ldc -g -w -of application_new application.d " ~ 
				tango.text.Util.join(files, " ") ~ 
				" -L rootintootin.a -L rootintootin_clibs.a -L=\"-lmysqlclient\" -L=\"-lpcre\" " ~ CORELIB;

//			Stdout.format("view_names: {}", tango.text.Util.join(view_names, " ")).newline.flush;
//			Stdout.format("model_names: {}", tango.text.Util.join(model_names, " ")).newline.flush;
//			Stdout.format("files: {}", tango.text.Util.join(files, " ")).newline.flush;
			Stdout("\nRebuilding application ...").newline.flush;
			this.run_command(command, c_stdout, c_stderr);

			// Make sure the application was built
			if(file_system.file_exist("application_new")) {
				// Replace the old app with the new one
				if(file_system.file_exist("application"))
					(new FilePath("application")).remove();
				(new FilePath("application_new")).rename("application");
			} else {
				compile_error = c_stdout ~ c_stderr;
				Stdout(c_stdout).flush;
				Stdout(c_stderr).flush;
			}

			// FIXME: Run the app
		} catch {

		}

		return compile_error;
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


