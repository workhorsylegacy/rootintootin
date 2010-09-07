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

private import file_system;
private import fcgi;
private import regex;
private import socket;
private import app_builder;
private import rootintootin;
private import rootintootin_server;


class RootinTootinAppProcess : RootinTootinApp {
	private File _output = null;
	private int _unix_socket_fd;

	public this(bool is_fcgi, string server_name, 
				RunnerBase runner, string[Regex][string][string] routes, 
				string db_host, string db_user, string db_password, string db_name) {
		super(is_fcgi, server_name, runner, routes, 
			db_host, db_user, db_password, db_name);
	}

	public void start() {
		if(!_is_fcgi) {
			_unix_socket_fd = create_unix_socket_fd("socket");
			_output = new File("log", File.WriteCreate);
		}

		_buffer = new char[1024 * 10];
		_file_buffer = new char[1024 * 10];

		if(_is_fcgi) {
			this.start_fcgi_loop();
		} else {
			this.start_normal_loop();
		}
	}

	protected void start_normal_loop() {
		int fd;
		string response = null;
		while(true) {
			fd = read_client_fd(_unix_socket_fd);
			set_fd(fd);

			// Read the request header into the buffer
			response = process_request();

			socket_write(fd, response.ptr);
			socket_close(fd);
		}
	}

	protected void start_fcgi_loop() {
		string request;
		while(fcgi_accept(request)) {
			// Read the request header into the buffer
			trigger_on_request(request);

			// Send the response
			fcgi_puts(_response);
		}
	}

	protected override void write_to_log(string message) {
		if(_is_fcgi) {
			Stdout(message).flush;
		} else {
			_output.write(message);
		}
	}
}

class RootinTootinServerProcess : RootinTootinServer {
	private char[] _app_path = null;
	private char[] _app_name = null;
	private Process _app = null;
	private char[] _compile_error = null;
	private bool _is_production = false;
	private int _unix_socket_fd;

	public this(ushort port, int max_waiting_clients, 
				char[] app_path, char[] app_name, 
				bool start_application, bool is_production) {
		super(port, max_waiting_clients);

		_app_path = app_path;
		_app_name = app_name;
		_is_production = is_production;
		_unix_socket_fd = connect_unix_socket_fd("socket");

		// Start the application if desired
		if(start_application)
			this.start_application();
	}

	protected override void on_connection_ready(int fd) {
		// If there is an app get it to handle the connection
		if(_app) {
			write_client_fd(_unix_socket_fd, fd);
		// If not, show the compile error
		} else {
			socket_write(fd, _compile_error.ptr);
			socket_close(fd);
		}
	}

	protected override void on_started(bool is_event_triggered = true) {
		string mode = _is_production ? "production" : "development";
		Stdout.format(ljust("Rootin Tootin running in " ~ mode ~ " mode on http://localhost:" ~ to_s(this._port) ~ " ...", 78, " ")).flush;
		Stdout.format(":)\n").flush;

		// Just return if there are no events to trigger
		if(!is_event_triggered) return;

		// In production mode just run the app
		if(_is_production) {
			this.start_application();
			Stdout("Application running ...").newline.newline.flush;
		// In development mode build the app when it changes
		} else {
			auto builder = new AppBuilder(
								_app_path, 
								mode, 
								&on_build_success, 
								&on_build_failure);
			builder.start();
		}
	}

	protected void on_build_success(AppBuilder builder) {
		string mode = _is_production ? "production" : "development";

		// Read the config from the config file
		auto file = new File("config/config.json", File.ReadExisting);
		auto content = new char[cast(size_t)file.length];
		file.read(content);
		file.close();
		auto values = (new Json!(char)).parse(content).toObject();

		string[string][string][string] config;
		foreach(n1, v1; values.attributes()) {
			foreach(n2, v2; v1.toObject().attributes()) {
				foreach(n3, v3; v2.toObject().attributes()) {
					config[n1][n2][n3] = v3.toString();
				}
			}
		}

		ushort port = to_ushort(config[mode]["server"]["port"]);
		int max_waiting_clients = to_ushort(config[mode]["server"]["max_waiting_clients"]);

		// Restart the server if the config changed
		if(port != _port || max_waiting_clients != _max_waiting_clients) {
			// Tell the server to restart
			_port = port;
			_max_waiting_clients = max_waiting_clients;
			_is_configuration_changed = true;

			// Wait for the server to restart
			// FIXME: Polling like this is stupid
			while(_is_configuration_changed == true) {
				Thread.sleep(0.05);
			}
		}

		// Start the application
		_compile_error = null;
		this.start_application();
		Stdout("Application running ...").newline.newline.flush;
	}

	protected void on_build_failure(char[] compile_error) {
		_compile_error = compile_error;
		Stdout(_compile_error).newline.flush;
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
}


