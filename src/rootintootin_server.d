
private import tango.net.device.Socket;
private import tango.text.Util;

private import tango.core.Thread;
private import tango.core.sync.Semaphore;
private import tango.core.sync.Mutex;

private import tango.io.device.File;
public import tango.io.Stdout;
public import http_server;
private import tcp_server;
private import language_helper;
private import helper;
private import db;
private import rootintootin;

public class RootinTootinServer : HttpServer {
	private RunnerBase[] _runners = null;
	private Semaphore[][char[]] _event_semaphores;
	private Mutex _event_mutex = null;

	public this(RunnerBase[] runners, ushort port, int max_waiting_clients, ushort max_threads, size_t buffer_size, 
				char[] db_host, char[] db_user, char[] db_password, char[] db_name) {
		super(port, max_waiting_clients, max_threads, buffer_size);
		_runners = runners;
		_event_mutex = new Mutex();

		// Connect to the database
		db_init(max_threads);
		// FIXME: Move this to be inside db_init
		for(size_t i=0; i<max_threads; i++) {
			db_connect(i, db_host, db_user, db_password, db_name);
		}
	}

	protected void on_started() {
		Stdout.format("Rootin Tootin running on http://localhost:{} ...\n", this._port).flush;
	}

	protected void on_request_get(Socket socket, Request request, char[] raw_header, char[] raw_body) {
		this.on_request_all(socket, request, raw_header, raw_body);
	}

	protected void on_request_post(Socket socket, Request request, char[] raw_header, char[] raw_body) {
		this.on_request_all(socket, request, raw_header, raw_body);
	}

	protected void on_request_put(Socket socket, Request request, char[] raw_header, char[] raw_body) {
		this.on_request_all(socket, request, raw_header, raw_body);
	}

	protected void on_request_delete(Socket socket, Request request, char[] raw_header, char[] raw_body) {
		this.on_request_all(socket, request, raw_header, raw_body);
	}

	protected void on_request_all(Socket socket, Request request, char[] raw_header, char[] raw_body) {
		// Get the controller, action, and id
		char[][] route = split(split(request.uri, "?")[0], "/");
		char[] controller = route.length > 1 ? route[1] : null;
		char[] action = route.length > 2 ? route[2] : "index";
		char[] id = route.length > 3 ? route[3] : null;
		if(id != null) request._params["id"] = id;

		Stdout.format("controller: {}\n", controller).flush;
		Stdout.format("action: {}\n", action).flush;

		// Send any files
		if(controller == "jquery.js" || controller == "favicon.ico") {
			auto file = new File("public/" ~ controller, File.ReadExisting);
			// FIXME: Use the existing buffer instead of creating a new one here
			char[1024 * 200] buf;
			int len = file.read(buf);
			file.close();
			this.render_text(socket, request, buf[0 .. len], 200);
			return;
		}

		// If this is an event, have this thread wait to be triggered
		if(action.length >= 3 && action[0 .. 3] == "on_") {
			SocketThread t = cast(SocketThread)Thread.getThis();
			try {
				_event_mutex.lock();
				this._event_semaphores[action] ~= t.public_semaphore;
			} finally {
				_event_mutex.unlock();
			}
			Stdout.format("thread is now waiting: {}\n", t.name).flush;
			t.public_semaphore.wait();
			Stdout.format("thread is now rendering: {}\n", t.name).flush;
		}

		// Generate and send the request
		char[][] events_to_trigger;
		size_t thread_id = cast(size_t) to_int(Thread.getThis().name);
		try {
			// Run the action and get any event names to trigger
			char[] response = _runners[thread_id].run_action(request, controller, action, id, events_to_trigger);
			this.render_text(socket, request, response, 200);
		} catch(ManualRenderException err) {
			if(err._response_type == ResponseType.render_text) {
				this.render_text(socket, request, err._payload, 200);
			} else if(err._response_type == ResponseType.redirect_to) {
				this.redirect_to(socket, request, err._payload);
			}
		}

		// Get all requests that need to be triggered
		Semaphore[] semaphore;
		foreach(char[] event_name ; events_to_trigger) {
			Stdout.format("triggering: {}\n", event_name).flush;
			try {
				_event_mutex.lock();
				for(size_t i=0; i<this._event_semaphores[event_name].length; i++) {
					semaphore ~= this._event_semaphores[event_name][i];
				}
				this._event_semaphores[event_name] = [];
			} finally {
				_event_mutex.unlock();
			}
		}

		// Trigger each request
		for(size_t i=0; i<semaphore.length; i++) {
			semaphore[i].notify();
		}
	}
}


