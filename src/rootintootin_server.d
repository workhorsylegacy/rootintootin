/*------------------------------------------------------------------------------
#
#    This file is part of the Rootin Tootin web framework and licensed under the
#    GPL version 3 or greater. See the COPYRIGHT file for copyright information.
#    This project is hosted at http://rootin.toot.in .
#
#-----------------------------------------------------------------------------*/


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

public class RootinTootinChild : HttpServerChild {
	private RunnerBase _runner = null;
	private string[TangoRegex.Regex][string][string] _routes = null;

	public this(RunnerBase runner, string[TangoRegex.Regex][string][string] routes, 
				string db_host, string db_user, string db_password, string db_name) {
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
							if(split(regex.pattern, r"\d*").length > 1 || split(regex.pattern, r"\d+").length > 1)
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

	protected string on_request_get(Request request, string raw_header, string raw_body) {
		return this.on_request_all(request, raw_header, raw_body);
	}

	protected string on_request_post(Request request, string raw_header, string raw_body) {
		return this.on_request_all(request, raw_header, raw_body);
	}

	protected string on_request_put(Request request, string raw_header, string raw_body) {
		return this.on_request_all(request, raw_header, raw_body);
	}

	protected string on_request_delete(Request request, string raw_header, string raw_body) {
		return this.on_request_all(request, raw_header, raw_body);
	}

	protected string on_request_all(Request request, string raw_header, string raw_body) {
		// Get the controller, action, and id
		string controller, action, id;
		bool has_valid_request = get_route_info(request, controller, action, id);

		// Send any files
		string normalized = Path.normalize(request.uri);
		if(normalized != "/" && Path.exists("public" ~ normalized)) {
			Stdout.format("file: {}\n", normalized).flush;
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
				return this.render_text(request, "404 Failed to read the file.", 404, "html");
			} else {
				return this.render_text(request, buf[0 .. len], 200);
			}
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
			return this.render_text(request, response, 200);
		} catch(RenderTextException e) {
			return this.render_text(request, e._text, e._status);
		} catch(RenderRedirectException e) {
			return this.redirect_to(request, e._url);
		} catch(RenderNoActionException e) {
			return this.render_text(request, e.msg, 404);
		} catch(RenderNoControllerException e) {
			string response = "<h1>404 Unknown Resource</h1>\n<ul>\n";
			response ~= "<p>Resources we know about:</p>";
			foreach(string controller_name ; e._controllers) {
				response ~= "	<li><a href=\"/" ~ controller_name ~ "\">" ~ controller_name ~ "</a></li>\n";
			}
			response ~= "</ul>\n";
			return this.render_text(request, response, 404, "html");
		}

		// FIXME: Here we need to trigger all the events in events_to_trigger
	}
}

public class RootinTootinServer : HttpServerParent {
	public this(ushort port, int max_waiting_clients, char[] child_name) {
		super(port, max_waiting_clients, child_name);
	}

	protected void on_started() {
		Stdout.format("Rootin Tootin running on http://localhost:{} ...\n", this._port).flush;
	}
}


