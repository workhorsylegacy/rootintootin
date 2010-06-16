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
	private Process _app = null;
	private char[1] _in_type;
	private char[] _out_type = "r";
	private File _log;
	private SharedMemory _shm;

	public this(char[] app_name) {
		//_log = new File("log_parent", File.WriteCreate);
		_shm = new SharedMemory("rootin.shared");

		_app = new Process(app_name);
		_app.redirect(Redirect.Output | Redirect.Error | Redirect.Input);
		_app.execute();

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
			if(_in_type == "r") {
				break;
			} else if(_in_type == "m") {
				Stdout(response).flush;
			}
		}

		return response;
	}

	protected void write_request(char[] type, char[] request) {
		// Send the request to the app
		_shm.set_value(toStringz(request));
		_app.stdin.write(_out_type);
		_app.stdin.flush();

		// Write to the log
		if(_log) {
			_log.write(request ~ "\n\n");
			_log.flush();
		}
	}

	protected char[] read_response() {
		// Get the response from the app
		_app.stdout.read(_in_type);
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



