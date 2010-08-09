/*------------------------------------------------------------------------------
#
#    This file is part of the Rootin Tootin web framework and licensed under the
#    GPL version 3 or greater. See the COPYRIGHT file for copyright information.
#    This project is hosted at http://rootin.toot.in .
#
#-----------------------------------------------------------------------------*/


private import tango.io.device.File;
private import Path = tango.io.Path;

public import tango.io.Stdout;
public import http_server;
private import language_helper;
private import helper;
private import db;
private import regex;
private import rootintootin;


public class RootinTootinApp : HttpApp {
	private RunnerBase _runner = null;
	private string[Regex][string][string] _routes = null;

	public this(string server_name, 
				RunnerBase runner, string[Regex][string][string] routes, 
				string db_host, string db_user, string db_password, string db_name) {
		super(server_name);
		_routes = routes;
		_runner = runner;

		// Connect to the database
		Db.connect(db_host, db_user, db_password, db_name);
	}

	private bool get_route_info(Request request, out string controller, out string action, out string id) {
		// Get the controller, action, and id
		string raw_uri = before(before(request.uri, "?"), ".");

		// Make sure the route exists
		bool has_valid_request = false;
		foreach(string route_controller, string[Regex][string] routes_maps ; _routes) {
			foreach(string route_action, string[Regex] routes_map ; routes_maps) {
				foreach(Regex regex, string method ; routes_map) {
					if(request.method == method && regex.is_match(raw_uri)) {
						this.write_to_log("regex: " ~ regex.pattern ~ "\n");
						controller = route_controller;
						action = route_action;
						if(starts_with(after_last(regex.pattern, "/"), r"\d"))
							id = before(after_last(raw_uri, "/"), ";");
						has_valid_request = true;
					}
					if(has_valid_request) break;
				}
				if(has_valid_request) break;
			}
			if(has_valid_request) break;
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
			this.write_to_log("file: " ~ normalized ~ "\n\n");
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
		if(id) request._params["id"].value = id;

		this.write_to_log("uri: " ~ request.uri ~ "\n");
		this.write_to_log("format: " ~ request.format ~ "\n");
		this.write_to_log("controller: " ~ controller ~ "\n");
		this.write_to_log("action: " ~ action ~ "\n\n");

		// Generate and send the request
		string[] events_to_trigger;
		string retval = null;
		try {
			// Run the action and get any event names to trigger
			string response = _runner.run_action(request, controller, action, id, events_to_trigger);

			retval = this.render_text(request, response, 200);
		} catch(RenderTextException e) {
			retval = this.render_text(request, e._text, e._status);
		} catch(RenderRedirectException e) {
			retval = this.redirect_to(request, e._url);
		} catch(RenderNoActionException e) {
			retval = this.render_text(request, e.msg, 404);
		} catch(RenderNoControllerException e) {
			string response = 
`<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
	"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">

<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
	<head>
		<meta http-equiv="content-type" content="text/html;charset=UTF-8" />
		<title>404 Unknown Resource</title>
	</head>
	<body>
		<h1>404 Unknown Resource</h1>
			<p>Resources we know about:</p>
				<ul>`;
			foreach(string controller_name ; e._controllers) {
				response ~= "	<li><a href=\"/" ~ controller_name ~ "\">" ~ controller_name ~ "</a></li>\n";
			}
			response ~= 
`		</ul>
	</body>
</html>`;

			retval = this.render_text(request, response, 404, "html");
		}

		return retval;
		// FIXME: Here we need to trigger all the events in events_to_trigger
	}
}

public class RootinTootinServer : HttpServer {
	public this(ushort port, int max_waiting_clients) {
		super(port, max_waiting_clients);
	}

	protected void on_started() {
		Stdout.format("Rootin Tootin running on http://localhost:{} ...\n", this._port).flush;
	}
}


