/*-------------------------------------------------------------------------------
#
#    This file is part of the Rootin Tootin web framework and licensed under the
#    GPL version 2 or greater. See the COPYRIGHT file for copyright information.
#    This project is hosted at http://rootin.toot.in .
#
#-----------------------------------------------------------------------------*/


private import tango.net.device.Socket;
private import tango.text.Util;

private import tango.io.device.File;
private import Path = tango.io.Path;

public import tango.io.Stdout;
public import http_server;
private import language_helper;
private import helper;
private import db;
private import rootintootin;

public class RootinTootinServer : HttpServer {
	private RunnerBase _runner = null;

	public this(RunnerBase runner, ushort port, int max_waiting_clients, string buffer, 
				string db_host, string db_user, string db_password, string db_name) {
		super(port, max_waiting_clients, buffer);
		_runner = runner;

		// Connect to the database
		db_connect(db_host, db_user, db_password, db_name);
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
			string mimetype = null;
			// FIXME: Use the existing buffer instead of creating a new one here
			char[1024 * 200] buf;
			int len = 0;
			try {
				file = new File("public" ~ normalized, File.ReadExisting);
				len = file.read(buf);
				mimetype = Helper.mimetype_map[split(normalized, ".")[length-1]];
			} catch {
				read_file_broke = true;
			} finally {
				if(file) file.close();
			}

			if(read_file_broke) {
				this.render_text(socket, request, "404 Failed to read the file.", 404);
			} else {
				this.render_text(socket, request, buf[0 .. len], 200, mimetype);
			}
			return;
		}

		// Generate and send the request
		string[] events_to_trigger;
		try {
			// Run the action and get any event names to trigger
			string response = _runner.run_action(request, controller, action, id, events_to_trigger);
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

		// FIXME: Here we need to trigger all the events in events_to_trigger
	}
}


