
private import tango.text.convert.Integer;
private import tango.text.Util;
private import tango.time.chrono.Gregorian;
private import tango.time.WallClock;
private import tango.io.Stdout;
private import tango.io.Console;
private import tango.io.device.File;
private import tango.stdc.stringz;

private import language_helper;
private import helper;
private import regex;
private import rootintootin;
private import http_server;
private import rootintootin_process;

/*
class RootinTootinAppProcess : RootinTootinApp {
	private char[1] _request_signal;
	private char[] _response_signal = "r";

	private File _log = null;
	private SharedMemory _shm_request = null;
	private SharedMemory _shm_response = null;

	public this(RunnerBase runner, string[Regex][string][string] routes, 
				string db_host, string db_user, string db_password, string db_name) {
		super(runner, routes, 
			db_host, db_user, db_password, db_name);
	}

	public void start() {
		//_log = new File("log_child", File.WriteCreate);

		// Create the shared memory
		_shm_request = new SharedMemory("request");
		_shm_response = new SharedMemory("response");

		// Read each request, and write the response
		char[] response = null;
		while(true) {
			char[] request = this.read_request();
			response = process_request(request);
			write_response("r", response);
		}
	}

	protected char[] read_request() {
		auto ins = Cin.stream;

		// Read the request
		ins.read(_request_signal);
		char[] request = fromStringz(_shm_request.get_value());

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
		_shm_response.set_value(toStringz(response));
		outs.write(_response_signal);
		outs.flush();

		// Write to the log
		if(_log) {
			_log.write(response ~ "\n\n");
			_log.flush();
		}
	}
}
*/
class Runner : RunnerBase {
	public string run_action(Request request, string controller_name, string action_name, string id, out string[] events_to_trigger) {
		return "da action";
	}
}

int main() {
	// Create the routes
	string[Regex][string][string] routes;

	// Create and start the app
	RunnerBase runner = new Runner();
	auto app = new RootinTootinAppProcess(
				runner, routes, 
				"localhost", "root", 
				"letmein", "users");
	app.start();

	return 0;
}

