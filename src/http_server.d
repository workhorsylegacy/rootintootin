

private import tango.text.convert.Integer;
private import tango.text.Util;
private import tango.stdc.stringz;
private import tango.io.device.File;
private import tango.io.Stdout;

private import tango.net.device.Socket;
private import tango.math.random.engines.Twister;
private import tango.core.sync.Mutex;

private import tango.text.Regex;
private import tango.time.chrono.Gregorian;
private import tango.time.WallClock;
private import tango.time.Clock;

private import tcp_server;
private import language_helper;
private import helper;

public enum ResponseType {
	normal,
	render_view, 
	render_text, 
	redirect_to
}

public class Request {
	private bool _has_rendered = false;
	private char[] _method = null;
	private char[] _uri = null;
	private char[] _http_version = null;
	private char[] _controller = null;
	private char[] _action = null;
	private char[] _id = null;
	public char[][char[]] _params;
	public char[][char[]] _cookies;

	private ResponseType _response_type;
	private char[] _redirect_to_url = null;
	private char[] _render_view_name = null;
	private char[] _render_text_text = null;
	public char[][] events_to_trigger;

	public this(char[] method, char[] uri, char[] http_version, char[] controller, char[] action, char[][char[]] params, char[][char[]] cookies) {
		_method = method;
		_uri = uri;
		_http_version = http_version;
		_controller = controller;
		this.action = action;
		_params = params;
		_cookies = cookies;
	}

	public bool has_rendered() { return _has_rendered; }
	public char[] method() { return _method; }
	public char[] uri() { return _uri; }
	public char[] http_version() { return _http_version; }
	public char[] controller() { return _controller; }
	public char[] action() { return _action; }
	public char[] id() { return _id; }
	public char[][char[]] params() { return _params; }

	public ResponseType response_type() { return _response_type; }
	public char[] redirect_to_url() { return _redirect_to_url; }
	public char[] render_view_name() { return _render_view_name; }
	public char[] render_text_text() { return _render_text_text; }

	public void has_rendered(bool value) { _has_rendered = value; }
	public void method(char[] value) { _method = value; }
	public void controller(char[] value) { _controller = value; }
	public void action(char[] value) { _action = (value=="new" ? capitalize(value) : value); }
	public void id(char[] value) { _id = value; }
	public void uri(char[] value) { _uri = value; }
	public void http_version(char[] value) { _http_version = value; }
	public void response_type(ResponseType value) { _response_type = value; }
	public void redirect_to_url(char[] value) { _redirect_to_url = value; }
	public void render_view_name(char[] value) { _render_view_name = value; }
	public void render_text_text(char[] value) { _render_text_text = value; }

	public static Request new_blank() {
		char[][char[]] params, cookies;
		return new Request("", "", "", "", "", params, cookies);
	}
}

public class HttpServer : TcpServer {
	private uint _header_max_size = 0;
	private int _session_id = 0;
	private Mutex _mutex_session_id = null;
	private char[][char[]] _sessions;
	private char[] _salt;

	public this(ushort port, uint header_max_size, ushort max_waiting_clients) {
		super(port, max_waiting_clients);
		this._header_max_size = header_max_size;
		this._mutex_session_id = new Mutex();

		// Get a random salt for salting sessions
		Twister* random = new Twister();
		random.seed(Clock.now.span.millis);
		this._salt = to_s(random.next());
		delete random;
	}

	public void on_started() {
		Stdout.format("Running on http://localhost:{} ...\n", this._port).flush;
	}

	public void on_respond_normal(Socket socket) {
		Request request = Request.new_blank();
		char[] buffer = new char[_header_max_size];
		int buffer_length = socket.input.read(buffer);

		// Return blank for bad requests
		if(buffer_length < 1) {
			return;
		}

		// Show an 'HTTP 413 Request Entity Too Large' if the end of the header was not read
		if(tango.text.Util.locatePattern(buffer[0 .. buffer_length], "\r\n\r\n", 0) == buffer_length) {
			char[] text = "The end of the HTTP header was not found when reading the first " ~ to_s(_header_max_size) ~ " bytes.";
			render_text(socket, request, text, 413);
			return;
		}

		// Clone the buffer segments into the raw header and body
		char[][] buffer_pair = ["", ""];
		int header_end = tango.text.Util.locatePattern(buffer[0 .. buffer_length], "\r\n\r\n", 0);
		buffer_pair[0] = buffer[0 .. buffer_length][0 .. header_end];
		buffer_pair[1] = buffer[0 .. buffer_length][header_end+4 .. length];
		char[] raw_header = "" ~ buffer_pair[0];

		// Get the header info
		char[][] header_lines = tango.text.Util.splitLines(raw_header);
		char[][] first_line = split(header_lines[0], " ");
		request.method = first_line[0];
		request.uri = first_line[1];
		request.http_version = first_line[2];

		// Get the content length and body
		int content_length = 0;
		File body_file = null;

		if(request.method == "POST" || request.method == "PUT") {
			// Show an 'HTTP 411 Length Required' error if there is no Content-Length
			if(tango.text.Util.locatePattern(raw_header, "Content-Length: ", 0) == raw_header.length) {
				this.render_text(socket, request, "Content-Length is required for HTTP POST and PUT.", 411);
				return;
			}

			// Get the content length
			content_length = to_int(between(raw_header, "Content-Length: ", "\r\n"));

			// Write the request body into a file
			if(content_length > 0) {
				// Write any left-over body from when we read the header into the file
				int remaining_length = content_length;
				body_file = new File("raw_body", File.WriteCreate);
				if(buffer_pair.length == 2 && buffer_pair[1].length > 0) {
					remaining_length -= buffer_pair[1].length;
					body_file.output.write(buffer_pair[1]);
				}

				// Write the remaining body into the file
				while(remaining_length > 0) {
					// FIXME: check for errors after receive like above
					buffer_length = socket.input.read(buffer);
					if(buffer_length > 0) {
						body_file.output.write(buffer[0 .. buffer_length]);
					}
					remaining_length -= buffer_length;
				}
			}
		}

		//Stdout.format("GOT \"{}\": LENGTH: {}\n", raw_header, raw_header.length).flush;
		//Stdout.format("GOT \"{}\": LENGTH: {}\n", raw_body, raw_body.length).flush;

		// Get all the fields
		char[][char[]] fields;
		foreach(char[] line ; header_lines) {
			// Break if we are at the end of the fields
			if(line.length == 0) break;

			char[][] pair = split(line, ": ");
			if(pair.length == 2) {
				fields[pair[0]] = pair[1];
			}
		}

		// Get the cookies
		if(("Cookie" in fields) != null) {
			foreach(char[] cookie ; split(fields["Cookie"], "; ")) {
				char[][] pair = split(cookie, "=");
				if(pair.length != 2) {
					Stdout.format("Malformed cookie: {}\n", cookie).flush;
				} else {
					request._cookies[pair[0]] = Helper.unescape_value(pair[1]);
				}
			}
		}

		// Make sure the session id is one we created
		if(("_appname_session" in request._cookies) != null) {
			char[] hashed_session_id = request._cookies["_appname_session"];
			if((hashed_session_id in _sessions) == null) {
				Stdout.format("Unknown session id '{}'\n", hashed_session_id).flush;
			}
		}

		// Get the HTTP GET params
		if(tango.text.Util.contains(request.uri, '?')) {
			foreach(char[] param ; split(split(request.uri, "?")[1], "&")) {
				char[][] pair = tango.text.Util.split(param, "=");
				request._params[Helper.unescape_value(pair[0])] = Helper.unescape_value(pair[1]);
			}
		}

		// Get the params from a url encoded body
		// FIXME: This will put the whole post body into ram. It should put the params into a file
		if((request.method == "POST" || request.method == "PUT") && ("Content-Type" in fields) != null) {
			if(fields["Content-Type"] == "application/x-www-form-urlencoded") {
				File raw_body_file = new File("raw_body", File.ReadExisting);
				char[] raw_body = "";
				char[100] buf;
				int len = 0;
				while((len = raw_body_file.read(buf)) > 0) {
					raw_body ~= buf[0 .. len];
				}
				foreach(char[] param ; split(raw_body, "&")) {
					char[][] pair = split(param, "=");
					if(pair.length == 2) {
						request._params[Helper.unescape_value(pair[0])] = Helper.unescape_value(pair[1]);
					}
				}
			}
		}

/*
		// Get the file from a miltipart encoded body
		// FIXME: This will put the whole post body into ram. It should put the body into a file
		if((method == "POST" || method == "PUT") && ("Content-Type" in fields) != null) {
			char[] content_type = fields["Content-Type"];
			if(tango.text.Util.locatePattern(content_type, "multipart/form-data; boundary=", 0) == 0) {
				char[] boundary = split(content_type, "; boundary=")[1];
				Stdout.format("Boundary [[{}]]\n", boundary).flush;

				File raw_body_file = new File("raw_body", File.ReadExisting);
				char[] raw_body = "";
				char[100] buf;
				int len = 0;
				while((len = raw_body_file.read(buf)) > 0) {
					raw_body ~= buf[0 .. len];
				}

				// Add any params
				foreach(char[] part ; split(raw_body, boundary)) {
					if(tango.text.Util.locatePattern(part, "Content-Disposition: form-data; ", 0) == 0) {
						char[] data = between("Content-Disposition: form-data; ", "\r\n");
						foreach(char[] variable ; split(data, "; ")) {
							char[] pair = split(variable, "=");
							if(pair[0] == "name")
								request._params[pair[1]] = pair[1];
						}
					}
				}
				//char[] meta = split(parts[1], "\r\n\r\n")[0];
				//char[] file = split(parts[1], "\r\n\r\n")[1][0 .. length-2];
			}
		}
*/
		// Get the controller and action
		char[][] route = split(split(request.uri, "?")[0], "/");
		request.controller = route.length > 1 ? route[1] : null;
		request.action = route.length > 2 ? route[2] : "index";
		request.id = route.length > 3 ? route[3] : null;
		if(request.id != null) request._params["id"] = request.id;

		// FIXME: this prints out all the values we care about
		/*
		Stdout.format("Total params: {}\n", request._params.length).flush;
		foreach(char[] name, char[] value ; request._params) {
			Stdout.format("\t{} => {}\n", name, value).flush;
		}

		Stdout.format("Total cookies: {}\n", _cookies.length).flush;
		foreach(char[] name, char[] value ; _cookies) {
			Stdout.format("\t{} => {}\n", name, value).flush;
		}
		*/

		Stdout("Route :\n").flush;
		Stdout.format("\tController Name: {}\n", request.controller).flush;
		Stdout.format("\tAction Name: {}\n", request.action).flush;
		Stdout.format("\tID: {}\n", request.id).flush;

		// Send a basic options header for access control
		// See: https://developer.mozilla.org/En/HTTP_Access_Control
		if(request.method == "OPTIONS") {
			char[] response =
			"HTTP/1.1 200 OK\r\n" ~ 
			"Server: Rester_0.1\r\n" ~ 
			"Status: 200 OK\r\n" ~ 
			"Access-Control-Allow-Origin: *\r\n" ~ 
			"Content-Length: 0\r\n" ~  
			"\r\n";

			socket.output.write(response);
			return request;
		}

		// Send any files
		// FIXME: Make this only work on existing files
		// FIXME: Make this only work on files inside public
		if(request.controller == "jquery.js" || request.controller == "favicon.ico" || request.controller == "glossasy.json") {
			char[] content_type = "";
			switch(request.controller) {
				case "jquery.js" : content_type = "application/javascript"; break;
				case "favicon.ico" : content_type = "image/vnd.microsoft.icon"; break;
				case "glossasy.json" : content_type = "application/json"; break;
			}
			File file = new File("public/" ~ request.controller, File.ReadExisting);
			char[1024 * 200] buf;
			int len = file.read(buf);

			socket.output.write(
			"HTTP/1.1 200 OK\r\n" ~ 
			"Status: 200\r\n" ~ 
			"Access-Control-Allow-Origin: *\r\n" ~ 
			"Content-Type: " ~ content_type ~ "\r\n" ~ 
			"Content-Length: " ~ to_s(len) ~ "\r\n" ~ 
			"\r\n");

			socket.output.write(buf[0 .. len]);
			file.close();
			return request;
		}

		// Send the response
		socket.write("200 da normal response");
	}

	public void on_respond_too_many_threads(Socket socket) {
		socket.write("503: Service Unavailable - Too many requests in the queue.");
	}

	private void render_text(Socket socket, Request request, char[] text, ushort status_code = 200) {
		socket.output.write(generate_text(request, text, status_code));
	}

	private char[] generate_text(Request request, char[] text, ushort status_code = 200) {
		// Use a blank request if there was none
		if(request is null) {
			request = Request.new_blank();
		}

		// If we have already rendered, show an error
		if(request.has_rendered) {
			throw new Exception("Something has already been rendered.");
		}

		// Get the status code.
		char[] status = Helper.get_verbose_status_code(status_code);

		// If there is no session add one to the cookies
		char[] set_cookies = "";
		if(("_appname_session" in request._cookies) == null || (request._cookies["_appname_session"] in _sessions) == null) {
			int new_session_id;
			_mutex_session_id.lock();
			new_session_id = _session_id;
			_session_id++;
			_mutex_session_id.unlock();

			char[] hashed_session_id = Helper.hash_and_base64(to_s(new_session_id), _salt);
			request._cookies["_appname_session"] = hashed_session_id; // ~ "; path=/";
			_sessions[hashed_session_id] = [];
			Stdout.format("\nCreated session number '{}' '{}'\n", new_session_id, hashed_session_id).flush;
		} else {
			Stdout.format("Using existing session '{}'\n", request._cookies["_appname_session"]).flush;
		}

		// Get all the new cookie values to send
		// FIXME: This is sending all cookies. It should only send the ones that have changed
		foreach(char[] name, char[] value ; request._cookies) {
			set_cookies ~= "Set-Cookie: " ~ name ~ "=" ~ Helper.escape_value(value) ~ "\r\n";
		}

		// Add the HTTP headers
		auto now = WallClock.now;
		auto time = now.time;
		auto date = Gregorian.generic.toDate(now);
		char[][] reply = [
		"HTTP/1.1 ", status, "\r\n", 
		"Date: ", to_s(date.day), to_s(date.month), to_s(date.year), "\r\n", 
		"Server: Rester_0.1\r\n", 
		set_cookies, 
		"Status: ", status, "\r\n",
		//"X-Runtime: 0.15560\r\n",
		//"ETag: \"53e91025a55dfb0b652da97df0e96e4d\"\r\n",
		"Access-Control-Allow-Origin: *\r\n",
		"Cache-Control: private, max-age=0\r\n",
		"Content-Type: text/html; charset=utf-8\r\n",
		"Content-Length: ", to_s(text.length), "\r\n",
		//"Vary: User-Agent\r\n",
		"\r\n",
		text];

		return tango.text.Util.join(reply, "");
	}
}

void main() {
	ushort port = 3000;
	ushort max_waiting_clients = 1000;
	uint header_max_size = 8192;

	auto server = new HttpServer(port, header_max_size, max_waiting_clients);
	server.start();
}


