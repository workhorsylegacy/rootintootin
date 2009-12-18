/*-------------------------------------------------------------------------------
#
#    This file is part of the Rootin Tootin web framework and licensed under the
#    GPL version 2 or greater. See the COPYRIGHT file for copyright information.
#    This project is hosted at http://rootin.toot.in .
#
#-----------------------------------------------------------------------------*/


private import tango.net.device.Socket;
private import tango.text.Util;

private import tango.core.Thread;
private import tango.core.sync.Semaphore;
private import tango.core.sync.Mutex;

private import tango.io.device.File;
private import Path = tango.io.Path;

public import tango.io.Stdout;
public import http_server;
private import tcp_server;
private import language_helper;
private import helper;
private import db;
private import rootintootin;

public class RootinTootinServer : HttpServer {
	private RunnerBase[] _runners = null;
	private Semaphore[][string] _event_semaphores;
	private Mutex _event_mutex = null;

	public this(RunnerBase[] runners, ushort port, int max_waiting_clients, ushort max_threads, size_t buffer_size, 
				string db_host, string db_user, string db_password, string db_name) {
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

	protected void on_request_get(Socket socket, Request request, string raw_header, string raw_body) {
		this.on_request_all(socket, request, raw_header, raw_body);
	}

	protected void on_request_post(Socket socket, Request request, string raw_header, string raw_body) {
		this.on_request_all(socket, request, raw_header, raw_body);
	}

	protected void on_request_put(Socket socket, Request request, string raw_header, string raw_body) {
		this.on_request_all(socket, request, raw_header, raw_body);
	}

	protected void on_request_delete(Socket socket, Request request, string raw_header, string raw_body) {
		this.on_request_all(socket, request, raw_header, raw_body);
	}

	protected void on_request_all(Socket socket, Request request, string raw_header, string raw_body) {
		// Get the controller, action, and id
		string[] route = split(split(request.uri, "?")[0], "/");
		string controller = route.length > 1 ? route[1] : null;
		string action = route.length > 2 ? route[2] : "index";
		string id = route.length > 3 ? route[3] : null;
		if(id != null) request._params["id"] = id;

		Stdout.format("controller: {}\n", controller).flush;
		Stdout.format("action: {}\n", action).flush;

		// Send any files
		string normalized = Path.normalize(request.uri);
		if(Path.exists("public" ~ normalized)) {
			bool read_file_broke = false;
			File file = null;
			// FIXME: Use the existing buffer instead of creating a new one here
			char[1024 * 200] buf;
			int len = 0;
			try {
				file = new File("public" ~ normalized, File.ReadExisting);
				len = file.read(buf);
			} catch {
				read_file_broke = true;
			} finally {
				if(file) file.close();
			}

			if(read_file_broke) {
				this.render_text(socket, request, "404 Failed to read the file.", 404);
			} else {
				this.render_text(socket, request, buf[0 .. len], 200);
			}
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
		string[] events_to_trigger;
		size_t thread_id = cast(size_t) to_int(Thread.getThis().name);
		try {
			// Run the action and get any event names to trigger
			string response = _runners[thread_id].run_action(request, controller, action, id, events_to_trigger);
			this.render_text(socket, request, response, 200);
		} catch(ManualRenderException err) {
			if(err._response_type == ResponseType.render_text) {
				this.render_text(socket, request, err._payload, 200);
			} else if(err._response_type == ResponseType.redirect_to) {
				this.redirect_to(socket, request, err._payload);
			}
		} catch(ModelException err) {
			this.render_text(socket, request, err.msg, 200);
		}

		// Get all requests that need to be triggered
		Semaphore[] semaphore;
		foreach(string event_name ; events_to_trigger) {
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


