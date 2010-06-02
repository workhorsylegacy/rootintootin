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

class ChildProcess {
	private File _log = null;
	private char[9] _in_length;
	private char[1] _in_type;

	public void start() {
		_log = new File("log_child", File.WriteCreate);

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
		ins.read(_in_length);
		uint length = to_uint(_in_length);
		char[] request = new char[length];
		ins.read(request);

		// Write to the log
		_log.write(to_s(length) ~ "\n");
		_log.write(_in_type ~ _in_length ~ "\n");
		_log.write(request ~ "\n\n");
		_log.flush();

		return request;
	}

	protected void write_response(char[] type, char[] response) {
		auto outs = Cout.stream;

		// Write the response
		char[] response_length = rjust(to_s(response.length), 9, "0");
		outs.write(type);
		outs.write(response_length);
		outs.flush();
		outs.write(response);
		outs.flush();

		// Write to the log
		_log.write(to_s(response.length) ~ "\n");
		_log.write(type ~ response_length ~ "\n");
		_log.write(response ~ "\n\n");
		_log.flush();
	}

	protected char[] on_stdin(char[] request) {
		throw new Exception("The on_request method of ChildProcess needs to be overloaded on children.");
	}
}


