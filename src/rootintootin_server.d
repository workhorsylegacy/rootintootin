/*------------------------------------------------------------------------------
#
#    This file is part of the Rootin Tootin web framework and licensed under the
#    GPL version 3 or greater. See the COPYRIGHT file for copyright information.
#    This project is hosted at http://rootin.toot.in .
#
#-----------------------------------------------------------------------------*/


private import tango.net.device.Socket;
private import tango.text.Util;
private import TangoRegex = tango.text.Regex;

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
	private string[TangoRegex.Regex][string][string] _routes = null;

	public this(RunnerBase runner, string[TangoRegex.Regex][string][string] routes, 
				ushort port, int max_waiting_clients, string buffer, 
				string db_host, string db_user, string db_password, string db_name) {
		super(port, max_waiting_clients, buffer);
		_routes = routes;
		_runner = runner;

		// Connect to the database
		db_connect(db_host, db_user, db_password, db_name);
	}

	private bool get_route_info(Request request, out string controller, out string action, out string id) {
		// Get the controller, action, and id
		string[] route = split(before(request.uri, "?"), "/");
		string raw_uri = before(before(request.uri, "?"), ".");
		route[length-1] = before(route[length-1], ".");
		string new_controller = route.length > 1 ? route[1] : null;
		string new_action, new_id;

		// Make sure the route exists
		bool has_valid_request = false;
		foreach(string route_controller, string[TangoRegex.Regex][string] routes_maps ; _routes) {
			foreach(string route_action, string[TangoRegex.Regex] routes_map ; routes_maps) {
				foreach(TangoRegex.Regex regex, string method ; routes_map) {
					if(request.method == method) {
						if(regex.test(raw_uri)) {
							Stdout.format("regex: {}\n", regex.pattern).flush;
							new_action = route_action;
							if(split(regex.pattern, r"\d*").length > 1)
								new_id = before(after_last(raw_uri, "/"), ";");
							has_valid_request = true;
						}
					}
				}
			}
		}

		// Set the out return values
		if(has_valid_request) {
			controller = new_controller;
			action = new_action;
			id = new_id;
		}
		return has_valid_request;
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
		string controller, action, id;
		bool has_valid_request = get_route_info(request, controller, action, id);

		// Send any files
		string normalized = Path.normalize(request.uri);
		if(normalized != "/" && Path.exists("public" ~ normalized)) {
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

		// Add the id to the params if we have one
		if(id != null) request._params["id"].value = to_s(id);

		Stdout.format("uri: {}\n", request.uri).flush;
		Stdout.format("format: {}\n", request.format).flush;
		Stdout.format("controller: {}\n", controller).flush;
		Stdout.format("action: {}\n", action).flush;

		// Generate and send the request
		string[] events_to_trigger;
		try {
			// Run the action and get any event names to trigger
			string response = _runner.run_action(request, controller, action, id, events_to_trigger);
			this.render_text(socket, request, response, 200);
		} catch(RenderTextException e) {
			this.render_text(socket, request, e._text, e._status);
		} catch(RenderRedirectException e) {
			this.redirect_to(socket, request, e._url);
		} catch(RenderNoActionException e) {
			this.render_text(socket, request, e.msg, 404);
		} catch(RenderNoControllerException e) {
			string response = "<h1>Unknown Controller</h1>\n<ul>\n";
			foreach(string controller_name ; e._controllers) {
				response ~= "	<li><a href=\"/" ~ controller_name ~ "\">" ~ controller_name ~ "</a></li>\n";
			}
			response ~= "</ul>\n";
			this.render_text(socket, request, response, 404);
		}

		// FIXME: Here we need to trigger all the events in events_to_trigger
	}
}


