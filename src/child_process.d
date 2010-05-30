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
	private File _log;

	public void start() {
		auto ins = Cin.stream;
		auto outs = Cout.stream;
		_log = new File("log_child", File.WriteCreate);

		while(true) {
			// Read the request
			char[10] raw_length;
			ins.read(raw_length);
			uint length = to_uint(raw_length);
			char[] request = new char[length];
			ins.read(request);
			_log.write(to_s(length) ~ "\n");
			_log.write(raw_length ~ "\n");
			_log.write(request ~ "\n\n");
			_log.flush();

			// Write the response
			char[] response = on_stdin(request);
			char[] response_length = rjust(to_s(response.length), 10, "0");
			outs.write(response_length);
			outs.flush();
			outs.write(response);
			outs.flush();
			_log.write(to_s(response.length) ~ "\n");
			_log.write(response_length ~ "\n");
			_log.write(response ~ "\n\n");
			_log.flush();
		}
	}

	protected char[] on_stdin(char[] request) {
		throw new Exception("The on_request method of ChildProcess needs to be overloaded on children.");
	}
}


