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


class ParentProcess {
	private Process _child = null;
	private char[] in_length;
	private char[10] out_length;
	private char[] response;

	public void start(char[] child_name) {
		_child = new Process(child_name);
		_child.redirect(Redirect.Output | Redirect.Error | Redirect.Input);
		_child.execute();
	}

	public void process_request() {
		char[] request = "do you want to go to san diego?";

		// Send the requet to the child
		in_length = rjust(to_s(request.length), 10, "0");
		_child.stdin.write(in_length);
		_child.stdin.flush();
		_child.stdin.write(request);
		_child.stdin.flush();

		// Get the response from the child
		_child.stdout.read(out_length);
		uint length = to_uint(out_length);
		response = new char[length];
		_child.stdout.read(response);
		_child.stdout.flush();
	}
}



