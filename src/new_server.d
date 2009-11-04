
private import tango.net.device.Socket;
private import tango.text.Util;

public import tango.io.Stdout;
public import http_server;
private import language_helper;
private import helper;
private import db;
private import rester;

public class ResterServer : HttpServer {
	private RunnerBase _runner = null;

	public this(RunnerBase runner, ushort port, ushort max_waiting_clients, ushort max_threads, size_t buffer_size, 
				char[] db_host, char[] db_user, char[] db_password, char[] db_name) {
		super(port, max_waiting_clients, max_threads, buffer_size);
		_runner = runner;

		// FIXME: This is bad because each thread will use the same database connection
		// change each thread to have its own runner and db connection
		// Connect to the database
		db_connect(db_host, db_user, db_password, db_name);
	}

	protected void on_respond_too_many_threads(Socket socket) {
		socket.write("503: Service Unavailable - Too many requests in the queue.");
	}

	protected void on_request_get(Socket socket, Request request, char[] raw_header, char[] raw_body) {
		this.run_action(socket, request, raw_header, raw_body);
	}

	protected void on_request_post(Socket socket, Request request, char[] raw_header, char[] raw_body) {
		this.run_action(socket, request, raw_header, raw_body);
	}

	protected void on_request_put(Socket socket, Request request, char[] raw_header, char[] raw_body) {
		this.run_action(socket, request, raw_header, raw_body);
	}

	protected void on_request_delete(Socket socket, Request request, char[] raw_header, char[] raw_body) {
		this.run_action(socket, request, raw_header, raw_body);
	}

	protected void run_action(Socket socket, Request request, char[] raw_header, char[] raw_body) {
		// Get the controller, action, and id
		char[][] route = split(split(request.uri, "?")[0], "/");
		char[] controller = route.length > 1 ? route[1] : null;
		char[] action = route.length > 2 ? route[2] : "index";
		char[] id = route.length > 3 ? route[3] : null;
		if(id != null) request._params["id"] = id;

		Stdout.format("controller: {}\n", controller).flush;
		Stdout.format("action: {}\n", action).flush;
		Stdout.format("response_type: {}\n", to_s(cast(int)request.response_type)).flush;

		// Run the action
		char[] response = _runner.run_action(request, controller, action, id);
		if(response is null) {
			render_text(socket, request, "404: no controller found", 404);
			return;
		}

		if(request.response_type == ResponseType.normal) {
			this.render_text(socket, request, response);
		} else if(request.response_type == ResponseType.redirect_to) {
			this.redirect_to(socket, request, request.redirect_to_url);
		} else if(request.response_type == ResponseType.render_view) {
			response = _runner.render_view(controller, request.render_view_name);
			this.render_text(socket, request, response, 200);
		} else if(request.response_type == ResponseType.render_text) {
			this.render_text(socket, request, request.render_text_text, 200);
		}
	}
}


