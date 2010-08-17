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

private import file_system;
private import regex;
private import socket;
private import app_builder;
private import rootintootin;
private import rootintootin_server;


class RootinTootinAppProcess : RootinTootinApp {
	private File _output = null;
	private int _unix_socket_fd;

	public this(string server_name, 
				RunnerBase runner, string[Regex][string][string] routes, 
				string db_host, string db_user, string db_password, string db_name) {
		super(server_name, runner, routes, 
			db_host, db_user, db_password, db_name);
	}

	public void start() {
		_output = new File("log", File.WriteCreate);
		_unix_socket_fd = create_unix_socket_fd("socket");

		string request;
		string response = null;
		_buffer = new char[1024 * 10];
		_file_buffer = new char[1024 * 10];

		int fd;
		while(true) {
			fd = read_client_fd(_unix_socket_fd);

			// Read the request header into the buffer
			response = process_request(fd);

			socket_write(fd, response.ptr);
			socket_close(fd);
		}
	}

	protected override void write_to_log(string message) {
		_output.write(message);
	}
}

class RootinTootinServerProcess : RootinTootinServer {
	private char[] _app_path = null;
	private char[] _app_name = null;
	private Process _app = null;
	private char[] _compile_error = null;
	private int _unix_socket_fd;

	public this(ushort port, int max_waiting_clients, 
				char[] app_path, char[] app_name, bool start_application) {
		super(port, max_waiting_clients);

		_app_path = app_path;
		_app_name = app_name;
		_unix_socket_fd = connect_unix_socket_fd("socket");

		// Start the application if desired
		if(start_application)
			this.start_application();
	}

	protected override void on_connection_ready(int fd) {
		write_client_fd(_unix_socket_fd, fd);
	}

	protected override void on_started(bool is_event_triggered = true) {
		// Have the builder build the app when it changes
		if(is_event_triggered) {
			auto builder = new AppBuilder(
								_app_path, 
								&on_build_success, 
								&on_build_failure);
			builder.start();
		}

		Stdout.format("Rootin Tootin running on http://localhost:{} ...", this._port).newline.flush;
	}

	protected void on_build_success(AppBuilder builder) {
		// Restart the server if the config changed
		if(builder._port != _port || builder._max_waiting_clients != _max_waiting_clients) {
			Stdout("Server restarting ...").newline.flush;

			// Tell the server to restart
			_port = builder._port;
			_max_waiting_clients = builder._max_waiting_clients;
			_is_configuration_changed = true;

			// Wait for the server to restart
			// FIXME: Polling like this is stupid
			while(_is_configuration_changed == true) {
				Thread.sleep(0.05);
			}

			Stdout("Server restart successful!").newline.flush;
		}

		// Start the application
		_compile_error = null;
		this.start_application();
		Stdout("Application running ...").newline.newline.flush;
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
}


