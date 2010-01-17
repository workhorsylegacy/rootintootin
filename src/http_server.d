/*------------------------------------------------------------------------------
#
#    This file is part of the Rootin Tootin web framework and licensed under the
#    GPL version 3 or greater. See the COPYRIGHT file for copyright information.
#    This project is hosted at http://rootin.toot.in .
#
#-----------------------------------------------------------------------------*/


private import tango.text.convert.Integer;
private import tango.text.Util;
private import tango.stdc.stringz;
private import tango.io.device.File;
private import tango.io.Stdout;

private import tango.net.device.Socket;
private import tango.math.random.engines.Twister;
private import tango.text.json.Json;
private import tango.text.xml.Document;

private import tango.time.chrono.Gregorian;
private import tango.time.WallClock;
private import tango.time.Clock;

private import tcp_server;
private import language_helper;
private import helper;

public class Request {
	private bool _has_rendered = false;
	private bool _was_format_specified;
	private string _method = null;
	private string _uri = null;
	private string _format = null;
	private string _http_version = null;
	public string[string] _params;
	public string[string] _fields;
	public string[string] _cookies;
	public string[string] _sessions;
	public uint _content_length = 0;

	public this(string method, string uri, string format, string http_version, string[string] params, string[string] fields, string[string] cookies) {
		_method = method;
		_uri = uri;
		_format = format;
		_http_version = http_version;
		_params = params;
		_fields = fields;
		_cookies = cookies;
	}

	public bool has_rendered() { return _has_rendered; }
	public bool was_format_specified() { return _was_format_specified; }
	public string method() { return _method; }
	public string uri() { return _uri; }
	public string format() { return _format; }
	public string http_version() { return _http_version; }
	public uint content_length() { return _content_length; }

	public void has_rendered(bool value) { _has_rendered = value; }
	public void was_format_specified(bool value) { _was_format_specified = value; }
	public void method(string value) { _method = value; }
	public void uri(string value) { _uri = value; }
	public void format(string value) { _format = value; }
	public void http_version(string value) { _http_version = value; }
	public void content_length(uint value) { _content_length = value; }

	public static Request new_blank() {
		string[string] params, cookies, fields;
		return new Request("", "", "", "", params, fields, cookies);
	}
}

public class HttpServer : TcpServer {
	private int _session_id = 0;
	private string[string][string] _sessions;
	private string _salt;

	public this(ushort port, int max_waiting_clients, string buffer) {
		super(port, max_waiting_clients, buffer);

		// Get a random salt for salting sessions
		Twister* random = new Twister();
		random.seed(Clock.now.span.millis);
		this._salt = to_s(random.next());
		delete random;
	}

	protected void on_started() {
		Stdout.format("Running on http://localhost:{} ...\n", this._port).flush;
	}

	protected void on_request_get(Socket socket, Request request, string raw_header, string raw_body) {
		string text = "200: Okay";
		render_text(socket, request, text, 200);
	}

	protected void on_request_post(Socket socket, Request request, string raw_header, string raw_body) {
		string text = "200: Okay";
		render_text(socket, request, text, 200);
	}

	protected void on_request_put(Socket socket, Request request, string raw_header, string raw_body) {
		string text = "200: Okay";
		render_text(socket, request, text, 200);
	}

	protected void on_request_delete(Socket socket, Request request, string raw_header, string raw_body) {
		string text = "200: Okay";
		render_text(socket, request, text, 200);
	}

	protected void on_request_options(Socket socket, Request request, string raw_header, string raw_body) {
		// Send a basic options header for access control
		// See: https://developer.mozilla.org/En/HTTP_Access_Control
		string response = 
		"HTTP/1.1 200 OK\r\n" ~ 
		"Server: RootinTootin_0.1\r\n" ~ 
		"Status: 200 OK\r\n" ~ 
		"Access-Control-Allow-Origin: *\r\n" ~ 
		"Content-Length: 0\r\n" ~  
		"\r\n";

		socket.write(response);
	}

	protected void trigger_on_request_get(Socket socket, Request request, string raw_header, string raw_body) {
		this.on_request_get(socket, request, raw_header, raw_body);
	}

	protected void trigger_on_request_post(Socket socket, Request request, string raw_header, string raw_body) {
		this.trigger_on_request_put(socket, request, raw_header, raw_body);
	}

	protected void trigger_on_request_put(Socket socket, Request request, string raw_header, string raw_body) {
		// Show an 'HTTP 411 Length Required' error if there is no Content-Length
		if(tango.text.Util.locatePattern(raw_header, "Content-Length: ", 0) == raw_header.length) {
			this.render_text(socket, request, "Content-Length is required for HTTP POST and PUT.", 411);
			return;
		}

		// Get the content length
		request.content_length = to_uint(between(raw_header, "Content-Length: ", "\r\n"));

		// Get the params from the body
		if(("Content-Type" in request._fields) != null) {
			switch(request._fields["Content-Type"]) {
				case "application/x-www-form-urlencoded":
					urlencode_to_params(request._params, raw_body);
					break;
				case "application/json":
					json_to_params(request._params, raw_body);
					break;
				case "application/xml":
					xml_to_params(request._params, raw_body);
					break;
			}
		}

		this.on_request_put(socket, request, raw_header, raw_body);
	}

	protected void trigger_on_request_delete(Socket socket, Request request, string raw_header, string raw_body) {
		this.on_request_delete(socket, request, raw_header, raw_body);
	}

	protected void trigger_on_request_options(Socket socket, Request request, string raw_header, string raw_body) {
		this.on_request_options(socket, request, raw_header, raw_body);
	}

	protected void trigger_on_request(Socket socket, string buffer) {
		Request request = Request.new_blank();
		int buffer_length = socket.input.read(buffer);

		// Return blank for bad requests
		if(buffer_length < 1) {
			return;
		}

		// Show an 'HTTP 413 Request Entity Too Large' if the end of the header was not read
		if(tango.text.Util.locatePattern(buffer[0 .. buffer_length], "\r\n\r\n", 0) == buffer_length) {
			string text = "The end of the HTTP header was not found when reading the first " ~ to_s(buffer.length) ~ " bytes.";
			render_text(socket, request, text, 413);
			return;
		}

		// Get the raw header body and header from the buffer
		string[] buffer_pair = ["", ""];
		int header_end = tango.text.Util.locatePattern(buffer[0 .. buffer_length], "\r\n\r\n", 0);
		string raw_header = buffer[0 .. buffer_length][0 .. header_end];
		string raw_body = buffer[0 .. buffer_length][header_end+4 .. length];
		Stdout.format("raw_header: {}\n", raw_header).flush;
		Stdout.format("raw_body: {}\n", raw_body).flush;

		// Get the header info
		string[] header_lines = tango.text.Util.splitLines(raw_header);
		string[] first_line = split(header_lines[0], " ");
		request.method = first_line[0];
		request.uri = first_line[1];
		request.format = after_last(after_last(request.uri, "/"), ".");
		request.was_format_specified = (request.format != "");
		if(!request.was_format_specified) request.format = "html";
		request.http_version = first_line[2];

		// Get all the fields
		foreach(string line ; header_lines) {
			// Break if we are at the end of the fields
			if(line.length == 0) break;

			string[] pair = split(line, ": ");
			if(pair.length == 2) {
				request._fields[pair[0]] = pair[1];
			}
		}

		// Get the cookies
		if(("Cookie" in request._fields) != null) {
			foreach(string cookie ; split(request._fields["Cookie"], "; ")) {
				string[] pair = split(cookie, "=");
				if(pair.length != 2) {
					Stdout.format("Malformed cookie: {}\n", cookie).flush;
				} else {
					request._cookies[pair[0]] = Helper.unescape_value(pair[1]);
				}
			}
		}

		// Get the HTTP GET params
		if(tango.text.Util.contains(request.uri, '?')) {
			foreach(string param ; split(split(request.uri, "?")[1], "&")) {
				string[] pair = tango.text.Util.split(param, "=");
				request._params[Helper.unescape_value(pair[0])] = Helper.unescape_value(pair[1]);
			}
		}

		// Monkey Patch the http method
		// This lets browsers fake post, put, and delete
		if(("method" in request._params) != null) {
			switch(request._params["method"]) {
				case "GET":
				case "POST":
				case "PUT":
				case "DELETE":
				case "OPTIONS":
					request.method = request._params["method"]; break;
				default: break;
			}
		}

		// Determine if we have a session id in the cookies
		bool has_session = false;
		has_session = (("_appname_session" in request._cookies) != null);

		// Determine if the session id is invalid
		if(has_session && (request._cookies["_appname_session"] in _sessions) == null) {
			string hashed_session_id = request._cookies["_appname_session"];
			Stdout.format("Unknown session id '{}'\n", hashed_session_id).flush;
			has_session = false;
		}

		// Create a new session if we need it
		string hashed_session_id = null;
		if(!has_session) {
			// Get the next session_id and increment the sequence
			int new_session_id = _session_id;
			_session_id++;

			// Create the hashed session id
			hashed_session_id = Helper.hash_and_base64(to_s(new_session_id), _salt);
			request._cookies["_appname_session"] = hashed_session_id;

			// Make the new session blank
			string[string] new_empty_session;
			_sessions[hashed_session_id] = new_empty_session;
			Stdout.format("\nCreated session number '{}' '{}'\n", new_session_id, hashed_session_id).flush;
		} else {
			hashed_session_id = request._cookies["_appname_session"];
			Stdout.format("Using existing session '{}'\n", request._cookies["_appname_session"]).flush;
		}

		// Copy the current session to the request
		request._sessions = _sessions[hashed_session_id];

		// Process the remainder of the request based on its method
		switch(request.method) {
			case "GET":
				this.trigger_on_request_get(socket, request, raw_header, raw_body);
				break;
			case "POST":
				this.trigger_on_request_post(socket, request, raw_header, raw_body);
				break;
			case "PUT":
				this.trigger_on_request_put(socket, request, raw_header, raw_body);
				break;
			case "DELETE":
				this.trigger_on_request_delete(socket, request, raw_header, raw_body);
				break;
			case "OPTIONS":
				this.trigger_on_request_options(socket, request, raw_header, raw_body);
				break;
		}

		// Copy the modified session back to the sessions
		_sessions[hashed_session_id] = request._sessions;

		// FIXME: this prints out all the values we care about
		/*
		Stdout.format("Total params: {}\n", request._params.length).flush;
		foreach(string name, string value ; request._params) {
			Stdout.format("\t{} => {}\n", name, value).flush;
		}

		Stdout.format("Total cookies: {}\n", _cookies.length).flush;
		foreach(string name, string value ; _cookies) {
			Stdout.format("\t{} => {}\n", name, value).flush;
		}
		*/
	}

	protected void redirect_to(Socket socket, Request request, string url) {
		// If we have already rendered, show an error
		if(request.has_rendered) {
			throw new Exception("Something has already been rendered.");
		}

		string status = Helper.get_verbose_status_code(301);

		string header = "HTTP/1.1 " ~ status ~ "\r\n" ~
		"Location: " ~ url ~ "\r\n" ~
		"Content-Type: text/html\r\n" ~
		"Content-Length: 0" ~
		"\r\n";

		socket.write(header);
	}

	protected void render_text(Socket socket, Request request, string text, ushort status_code = 200) {
		string content_type = Helper.mimetype_map[request.format];
		socket.write(generate_text(request, text, status_code, content_type));
	}

	private string generate_text(Request request, string text, ushort status_code, string content_type) {
		// Use a blank request if there was none
		if(request is null) {
			request = Request.new_blank();
		}

		// If we have already rendered, show an error
		if(request.has_rendered) {
			throw new Exception("Something has already been rendered.");
		}

		// Get the status code.
		string status = Helper.get_verbose_status_code(status_code);

		// Get all the new cookie values to send
		// FIXME: This is sending all cookies. It should only send the ones that have changed
		string set_cookies = "";
		foreach(string name, string value ; request._cookies) {
			set_cookies ~= "Set-Cookie: " ~ name ~ "=" ~ Helper.escape_value(value) ~ "\r\n";
		}

		// Add the HTTP headers
		auto now = WallClock.now;
		auto time = now.time;
		auto date = Gregorian.generic.toDate(now);
		string[] reply = [
		"HTTP/1.1 ", status, "\r\n", 
		"Date: ", to_s(date.day), to_s(date.month), to_s(date.year), "\r\n", 
		"Server: RootinTootin_0.1\r\n", 
		set_cookies, 
		"Status: ", status, "\r\n",
		//"X-Runtime: 0.15560\r\n",
		//"ETag: \"53e91025a55dfb0b652da97df0e96e4d\"\r\n",
		"Access-Control-Allow-Origin: *\r\n",
		"Cache-Control: private, max-age=0\r\n",
		"Content-Type: ", content_type, "\r\n",
		"Content-Length: ", to_s(text.length), "\r\n",
		//"Vary: User-Agent\r\n",
		"\r\n",
		text];

		return tango.text.Util.join(reply, "");
	}

	private void urlencode_to_params(ref char[][char[]] collection, string urlencode_in_a_string) {
		foreach(string param ; split(urlencode_in_a_string, "&")) {
			string[] pair = split(param, "=");
			if(pair.length == 2) {
				collection[Helper.unescape_value(pair[0])] = Helper.unescape_value(pair[1]);
			}
		}
	}

	private void xml_to_params(ref char[][char[]] collection, string xml_in_a_string) {
//		public enum XmlNodeType {Element, Data, Attribute, CData, 
//		Comment, PI, Doctype, Document};
		auto doc = new Document!(char);
		doc.parse(xml_in_a_string);

		foreach(noded ; doc.tree.children) {
			Stdout.format("XML name: {} value: {}\n", noded.name, noded.value);
			foreach(child ; noded.children) {
				Stdout.format("XML name: {} value: {}\n", child.name, child.value);
			}
		}
	}

	private void json_to_params(ref char[][char[]] collection, string json_in_a_string) {
		auto json = new Json!(char);
		json.parse(json_in_a_string);
		json_to_params(collection, json.value());
	}

	private void json_to_params(ref char[][char[]] collection, Json!(char).Value value, char[] name = "") {
		switch(value.type) {
			case Json!(char).Type.Null:
				collection[name] = to_s("null");
				break;
			case Json!(char).Type.String:
				collection[name] = to_s(value.toString());
				break;
			case Json!(char).Type.RawString:
				collection[name] = to_s(value.toString());
				break;
			case Json!(char).Type.True:
				collection[name] = to_s(value.toBool());
				break;
			case Json!(char).Type.False:
				collection[name] = to_s(value.toBool());
				break;
			case Json!(char).Type.Number:
				collection[name] = to_s(value.toNumber());
				break;
			case Json!(char).Type.Object:
				foreach(char[] sub_name, Json!(char).Value sub_value ; value.toObject.attributes()) {
					json_to_params(collection, sub_value, sub_name);
				}
				break;
			case Json!(char).Type.Array:
				foreach(Json!(char).Value sub_value ; value.toArray()) {
					json_to_params(collection, sub_value, name);
				}
				break;
		}
	}
}



