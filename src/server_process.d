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
public import dornado.ioloop;

private import tango.io.device.File;
private import tango.stdc.stringz;
private import shared_memory;


class ServerProcess {
	private char[] _app_name = null;
	private Process _app = null;
	private char[] _request_signal = "r";
	private char[1] _response_signal;
	private File _log = null;
	private SharedMemory _shm = null;

	public this(char[] app_name, bool start_application) {
		_app_name = app_name;
		//_log = new File("log_parent", File.WriteCreate);
		_shm = new SharedMemory("rootin.shared");

		// Start the application if desired
		if(start_application)
			this.start_application();

		// Read any startup messages from the app
/*
		char[] message;
		while(true) {
			message = this.read_response();
			if(message == "") break;
			Stdout(message).flush;
		}
*/
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

	protected void write_request(char[] type, char[] request) {
		// Send the request to the app
		_shm.set_value(toStringz(request));
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
		char[] response = fromStringz(_shm.get_value());

		// Write to the log
		if(_log) {
			_log.write(response ~ "\n\n");
			_log.flush();
		}

		return response;
	}
}



