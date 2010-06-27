/*------------------------------------------------------------------------------
#
#    This file is part of the Rootin Tootin web framework and licensed under the
#    GPL version 3 or greater. See the COPYRIGHT file for copyright information.
#    This project is hosted at http://rootin.toot.in .
#
#-----------------------------------------------------------------------------*/


private import tango.net.device.Socket;
private import tango.io.model.IConduit;
private import tango.net.InternetAddress;
private import tango.io.Stdout;
private import tango.io.Console;
private import tango.sys.Process;
private import tango.io.device.File;
private import tango.stdc.stringz;

public import dornado.ioloop;
private import file_system;
private import regex;
private import shared_memory;
private import app_builder;
private import rootintootin;
private import rootintootin_server;


class RootinTootinAppProcess : RootinTootinApp {
	private char[3] _request_signal;

	private File _log = null;
	private SharedMemory _shm_request = null;
	private SharedMemory _shm_response = null;

	public this(string server_name, 
				RunnerBase runner, string[Regex][string][string] routes, 
				string db_host, string db_user, string db_password, string db_name) {
		super(server_name, runner, routes, 
			db_host, db_user, db_password, db_name);
	}

	public void start() {
		//_log = new File("log_child", File.WriteCreate);

		// Create the shared memory
		_shm_request = new SharedMemory("request");
		_shm_response = new SharedMemory("response");

		// Read each request, and write the response
		string[] responses = null;
		while(true) {
			string request = this.read_request();
			responses = process_request(request);
			foreach(string response; responses) {
				if(response[0 .. 3] != "R;;")
					if(responses.length == 1)
						response = "R;;" ~ response;
					else
						response = "M;;" ~ response;
				try {
					write_response(response[0 .. 3], response[3 .. length]);
				} catch(Exception err) {
					write_response(response[0 .. 3], err.msg);
				}
			}
		}
	}

	protected char[] read_request() {
		auto ins = Cin.stream;

		// Read the request
		ins.read(_request_signal);
		char[] request = fromStringz(_shm_request.get_value());

		// Write to the log
		if(_log) {
			_log.write(request ~ "\n\n");
			_log.flush();
		}

		return request;
	}

	protected void write_response(char[] response_signal, char[] response) {
		auto outs = Cout.stream;

		// Write to the log
		if(_log) {
			_log.write(response ~ "\n\n");
			_log.flush();
		}

		// Write the response
		_shm_response.set_value(toStringz(response));
		outs.write(response_signal);
		outs.flush();
	}
}

class RootinTootinServerProcess : RootinTootinServer {
	private char[] _app_path = null;
	private char[] _app_name = null;
	private Process _app = null;
	private char[3] _response_signal;
	private File _log = null;
	private SharedMemory _shm_request = null;
	private SharedMemory _shm_response = null;
	private char[] _compile_error = null;

	public this(ushort port, int max_waiting_clients, 
				char[] app_path, char[] app_name, bool start_application) {
		super(port, max_waiting_clients);

		_app_path = app_path;
		_app_name = app_name;
		//_log = new File("log_parent", File.WriteCreate);

		// Create the shared memory
		if(!file_system.file_exist(".", "request"))
			(new File("request", File.WriteCreate)).close();
		if(!file_system.file_exist(".", "response"))
			(new File("response", File.WriteCreate)).close();
		_shm_request = new SharedMemory("request");
		_shm_response = new SharedMemory("response");

		// Start the application if desired
		if(start_application)
			this.start_application();

		// Read any startup messages from the app
//		char[] message;
//		while(true) {
//			message = this.read_response();
//			if(message == "") break;
//			Stdout(message).flush;
//		}
	}

	public char[] process_request(char[] request) {
		// Just return the compile error if there is one
		if(_compile_error)
			return _compile_error;

		// Write the request to the app
		try {
			write_request("R;;", request);
		} catch(Exception err) {
			return err.msg;
		}

		// Read the messages and response from the app
		char[] response;
		while(true) {
			response = this.read_response();
			if(_response_signal == "R;;") {
				break;
			} else if(_response_signal == "M;;") {
				Stdout(response).flush;
			} else {
			}
		}

		return response;
	}

	protected void on_started() {
		// Have the builder build the app when it changes
		auto builder = new AppBuilder(
							_app_path, 
							&on_build_success, 
							&on_build_failure);
		builder.start();

		Stdout.format("Rootin Tootin running on http://localhost:{} ...\n", this._port).flush;
	}

	protected void on_build_success() {
		_compile_error = null;
		this.start_application();
		Stdout("Application running ...\n").flush;
	}

	protected void on_build_failure(char[] compile_error) {
		_compile_error = compile_error;
		this.stop_application();
	}

	public void start_application() {
		// Make sure the application is stopped
		this.stop_application();

		// Start the application
		_app = new Process(_app_name);
		_app.redirect(Redirect.Output | Redirect.Error | Redirect.Input);
		_app.execute();
	}

	public void stop_application() {
		// Just return if it is already not running
		if(_app is null)
			return;

		// Stop the application process
		_app.kill();
		_app = null;
	}

	protected void write_request(char[] request_signal, char[] request) {
		// Write to the log
		if(_log) {
			_log.write(request ~ "\n\n");
			_log.flush();
		}

		// Send the request to the app
		_shm_request.set_value(toStringz(request));
		_app.stdin.write(request_signal);
		_app.stdin.flush();
	}

	protected char[] read_response() {
		char[] response = null;

		// Get the response from the app
		_app.stdout.read(_response_signal);
		_app.stdout.flush();
		response = fromStringz(_shm_response.get_value());

		// Write to the log
		if(_log) {
			_log.write(response ~ "\n\n");
			_log.flush();
		}

		return response;
	}
}


