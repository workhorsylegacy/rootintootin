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


class ChildProcess {
	public void start() {
		auto ins = Cin.stream;
		auto outs = Cout.stream;

		while(true) {
			// Read the request
			char[10] raw_length;
			ins.read(raw_length);
			uint length = to_uint(raw_length);
			char[] request = new char[length];
			ins.read(request);
			char[] response = on_request(request);

			// Write the response
			char[] response_length = rjust(to_s(response.length), 10, "0");
			outs.write(response_length);
			outs.write(response);
			outs.flush();
		}
	}

	protected char[] on_request(char[] request) {
		throw new Exception("The on_request method of ChildProcess needs to be overloaded on children.");
	}
}


