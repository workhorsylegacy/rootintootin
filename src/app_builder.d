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
	private void delegate(AppBuilder) _on_success_func = null;
	private void delegate(char[]) _on_failure_func = null;
	private string _app_path = null;
	private string _mode = null;
	public ushort _port;
	public int _max_waiting_clients;

	public this(string app_path, string mode, void delegate(AppBuilder) on_build_success, void delegate(char[]) on_build_failure) {
		_app_path = app_path;
		_mode = mode;
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

	private string pluralize(string[string] nouns, string noun) {
		foreach(string singular, string plural; nouns) {
			if(noun == singular || noun == plural) {
				return plural;
			} else if(noun == capitalize(singular) || noun == capitalize(plural)) {
				return capitalize(plural);
			}
		}
		throw new Exception("Can't pluralize unknown noun '" ~ noun ~ "'.");
	}

	private void build_loop() {
		char[] compile_error = null;
		bool is_first_loop = true;

		// Loop forever, and rebuild
		while(true) {
			// Rebuild the application
			try {
				compile_error = this.build_method(is_first_loop);
			} catch(Exception err) {
				compile_error = "Unhandled exception while building: '" ~ err.msg ~ "' line: '" ~ to_s(err.line) ~ "' file: '" ~ err.file ~ "'";
				Stdout(compile_error).newline.flush;
			}

			// Show success or failure
			if(compile_error == null) {
				if(_on_success_func)
					_on_success_func(this);
			} else {
				if(_on_failure_func)
					_on_failure_func(compile_error);
			}

			// Wait here and block till files change
			wait_for_changes();

			is_first_loop = false;
		}
	}

	private char[] build_method(bool is_first_loop) {
		char[] compile_error = null;

		// Copy all the app files, and do code generation
		this.run_command("python2.6 /usr/bin/rootintootin_run " ~ _app_path ~ " application " ~ _mode);

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


