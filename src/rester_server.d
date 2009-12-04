
private import tango.net.device.Socket;
private import tango.text.Util;
private import tango.core.Thread;

public import tango.io.Stdout;
public import http_server;
private import language_helper;
private import helper;
private import db;
private import rester;

public class ResterServer : HttpServer {
	private RunnerBase[] _runners = null;

	public this(RunnerBase[] runners, ushort port, int max_waiting_clients, ushort max_threads, size_t buffer_size, 
				char[] db_host, char[] db_user, char[] db_password, char[] db_name) {
		super(port, max_waiting_clients, max_threads, buffer_size);
		_runners = runners;

		// Connect to the database
		db_init(max_threads);
		// FIXME: Move this to be inside db_init
		for(size_t i=0; i<max_threads; i++) {
			db_connect(i, db_host, db_user, db_password, db_name);
		}
	}

	protected void on_started() {
		Stdout.format("Rester running on http://localhost:{} ...\n", this._port).flush;
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

		// Run the action
		size_t thread_id = cast(size_t) to_int(Thread.getThis().name);
		try {
			char[] response = _runners[thread_id].run_action(request, controller, action, id);
			this.render_text(socket, request, response, 200);
		} catch(ManualRenderException err) {
			if(err._response_type == ResponseType.render_text) {
				this.render_text(socket, request, err._payload, 200);
			} else if(err._response_type == ResponseType.redirect_to) {
				this.redirect_to(socket, request, err._payload);
			}
		}
	}
}


