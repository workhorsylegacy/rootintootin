/*------------------------------------------------------------------------------
#
#    This file is part of the Rootin Tootin web framework and licensed under the
#    GPL version 3 or greater. See the COPYRIGHT file for copyright information.
#    This project is hosted at http://rootin.toot.in .
#
#-----------------------------------------------------------------------------*/


private import tango.io.Stdout;
private import tango.io.Console;
private import tango.sys.Process;
private import tango.io.device.File;
private import tango.text.json.Json;
private import tango.stdc.stringz;

private import language_helper;
private import file_system;
private import rootintootin;
private import rootintootin_process;
private import app_builder;

/*
class RootinTootinServerProcess : RootinTootinServer {
	private char[] _app_path = null;
	private char[] _app_name = null;
	private Process _app = null;
	private char[] _request_signal = "r";
	private char[1] _response_signal;
	private File _log = null;
	private SharedMemory _shm_request = null;
	private SharedMemory _shm_response = null;

	public this(ushort port, int max_waiting_clients, 
				char[] app_path, char[] app_name, bool start_application) {
		super(port, max_waiting_clients);

		_app_path = app_path;
		_app_name = app_name;
		//_log = new File("log_parent", File.WriteCreate);

		// Create the shared memory
		if(!file_system.file_exist("request"))
			(new File("request", File.WriteCreate)).close();
		if(!file_system.file_exist("response"))
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
		// Write the request to the app
		write_request("r", request);

		// Read the messages and response from the app
		char[] response;
		while(true) {
			response = this.read_response();
			if(_response_signal == "r") {
				break;
			} else if(_response_signal == "m") {
				Stdout(response).flush;
			}
		}

		return response;
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

	protected void on_started() {
//		// Have the builder build the app when it changes
//		auto builder = new AppBuilder(_app_path);
//		builder.on_build_success(&on_build);
//		builder.start();
		this.on_build();//FIXME: Remove! only here to start the process, because we are not building it.

		Stdout.format("Rootin Tootin running on http://localhost:{} ...\n", this._port).flush;
	}

	protected void on_build() {
		this.start_application();
		Stdout("Application running ...\n").flush;
	}

	protected void write_request(char[] type, char[] request) {
		// Send the request to the app
		_shm_request.set_value(toStringz(request));
		_app.stdin.write(_request_signal);
		_app.stdin.flush();

		// Write to the log
		if(_log) {
			_log.write(request ~ "\n\n");
			_log.flush();
		}
	}

	protected char[] read_response() {
		// Get the response from the app
		_app.stdout.read(_response_signal);
		_app.stdout.flush();
		char[] response = fromStringz(_shm_response.get_value());

		// Write to the log
		if(_log) {
			_log.write(response ~ "\n\n");
			_log.flush();
		}

		return response;
	}
}
*/

int main(string[] args) {
	// Make sure the first arg is the application path
//	if(args.length < 2)
//		throw new Exception("The first argument should be the application path.");
//	string app_path = args[1];
	string app_path = "";
/*
	// Read the server config file
	auto file = new File("config/config.json", File.ReadExisting);
	auto content = new char[cast(size_t)file.length];
	file.read(content);
	file.close();
	auto values = (new Json!(char)).parse(content).toObject();

	string[string][string] config;
	foreach(n1, v1; values.attributes()) {
		foreach(n2, v2; v1.toObject().attributes()) {
			config[n2] = null;
			foreach(n3, v3; v2.toObject().attributes()) {
				config[n2][n3] = v3.toString();
			}
		}
	}
*/
	// Create and start the sever
	IOLoop.use_epoll = true;
	ushort port = 3000;//to_ushort(config["server_configuration"]["port"]);
	int max_waiting_clients = 100;//to_int(config["server_configuration"]["max_waiting_clients"]);
	auto server = new RootinTootinServerProcess(
				port, max_waiting_clients, 
				app_path, "./application", false);

	server.start();

	return 0;
}

