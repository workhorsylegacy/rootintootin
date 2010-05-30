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

class ParentProcess {
	private Process _child = null;
	private char[] _in_length;
	private char[10] _out_length;
	private char[] _response;
	private File _log;

	public this(char[] child_name) {
		_child = new Process(child_name);
		_child.redirect(Redirect.Output | Redirect.Error | Redirect.Input);
		_child.execute();
		_log = new File("log_parent", File.WriteCreate);
	}

	public char[] process_request(char[] request) {
		// Send the request to the child
		_in_length = rjust(to_s(request.length), 10, "0");
		_child.stdin.write(_in_length);
		_child.stdin.flush();
		_child.stdin.write(request);
		_child.stdin.flush();
		_log.write(_in_length);
		_log.write(request);
		_log.flush();

		// Get the response from the child
		_child.stdout.read(_out_length);
		uint length = to_uint(_out_length);
		_response = new char[length];
		_child.stdout.read(_response);
		_child.stdout.flush();
		_log.write(_out_length);
		_log.write(_response);
		_log.flush();

		return _response;
	}
}



