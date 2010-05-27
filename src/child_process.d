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

	public char[] on_request(char[] request) {
		return "yeah! let's go.";
	}
}


