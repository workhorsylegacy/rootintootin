/*------------------------------------------------------------------------------
#
#    This file is part of the Rootin Tootin web framework and licensed under the
#    GPL version 3 or greater. See the COPYRIGHT file for copyright information.
#    This project is hosted at http://rootin.toot.in .
#
#-----------------------------------------------------------------------------*/


private import tango.io.Stdout;
private import tango.io.Console;
private import language_helper;

private import tango.io.device.File;
private import tango.stdc.stringz;
private import shared_memory;

class ChildProcess {
	private char[1] _in_type;
	private char[] _out_type = "r";
	private File _log = null;
	private SharedMemory _shm;

	public void start() {
		_log = new File("log_child", File.WriteCreate);
		_shm = new SharedMemory("/program.shared");

		while(true) {
			char[] request = this.read_request();
			char[] response = on_stdin(request);
			write_response("r", response);
		}
	}

	protected char[] read_request() {
		auto ins = Cin.stream;

		// Read the request
		ins.read(_in_type);
		char[] request = fromStringz(_shm.get_value());

		// Write to the log
		if(_log) {
			_log.write(request ~ "\n\n");
			_log.flush();
		}

		return request;
	}

	protected void write_response(char[] type, char[] response) {
		auto outs = Cout.stream;

		// Write the response
		_shm.set_value(toStringz(response));
		outs.write(_out_type);
		outs.flush();

		// Write to the log
		if(_log) {
			_log.write(response ~ "\n\n");
			_log.flush();
		}
	}

	protected char[] on_stdin(char[] request) {
		throw new Exception("The on_request method of ChildProcess needs to be overloaded on children.");
	}
}


