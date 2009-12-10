

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
	render_view, 
	render_text, 
	redirect_to
}

public class Request {
	private bool _has_rendered = false;
	private char[] _method = null;
	private char[] _uri = null;
	private char[] _http_version = null;
	public char[][char[]] _params;
	public char[][char[]] _fields;
	public char[][char[]] _cookies;
	public uint _content_length = 0;

	public this(char[] method, char[] uri, char[] http_version, char[][char[]] params, char[][char[]] fields, char[][char[]] cookies) {
		_method = method;
		_uri = uri;
		_http_version = http_version;
		_params = params;
		_fields = fields;
		_cookies = cookies;
	}

	public bool has_rendered() { return _has_rendered; }
	public char[] method() { return _method; }
	public char[] uri() { return _uri; }
	public char[] http_version() { return _http_version; }
	public uint content_length() { return _content_length; }

	public void has_rendered(bool value) { _has_rendered = value; }
	public void method(char[] value) { _method = value; }
	public void uri(char[] value) { _uri = value; }
	public void http_version(char[] value) { _http_version = value; }
	public void content_length(uint value) { _content_length = value; }

	public static Request new_blank() {
		char[][char[]] params, cookies, fields;
		return new Request("", "", "", params, fields, cookies);
	}
}

public class HttpServer : TcpServer {
	private int _session_id = 0;
	private char[][char[]] _sessions;
	private char[] _salt;

	private Mutex _mutex_session_id = null;
	private Mutex _mutex_sessions = null;

	public this(ushort port, int max_waiting_clients, ushort max_threads, size_t buffer_size = 0) {
		super(port, max_waiting_clients, max_threads, buffer_size);
		this._mutex_session_id = new Mutex();
		this._mutex_sessions = new Mutex();

		// Get a random salt for salting sessions
		Twister* random = new Twister();
		random.seed(Clock.now.span.millis);
		this._salt = to_s(random.next());
		delete random;
	}

	protected void on_started() {
		Stdout.format("Running on http://localhost:{} ...\n", this._port).flush;
	}

	protected void on_respond_too_many_threads(Socket socket) {
		socket.write("503: Service Unavailable - Too many requests in the queue.");
	}

	protected void on_request_get(Socket socket, Request request, char[] raw_header, char[] raw_body) {
		char[] text = "200: Okay";
		render_text(socket, request, text, 200);
	}

	protected void on_request_post(Socket socket, Request request, char[] raw_header, char[] raw_body) {
		char[] text = "200: Okay";
		render_text(socket, request, text, 200);
	}

	protected void on_request_put(Socket socket, Request request, char[] raw_header, char[] raw_body) {
		char[] text = "200: Okay";
		render_text(socket, request, text, 200);
	}

	protected void on_request_delete(Socket socket, Request request, char[] raw_header, char[] raw_body) {
		char[] text = "200: Okay";
		render_text(socket, request, text, 200);
	}

	protected void on_request_options(Socket socket, Request request, char[] raw_header, char[] raw_body) {
		// Send a basic options header for access control
		// See: https://developer.mozilla.org/En/HTTP_Access_Control
		char[] response = 
		"HTTP/1.1 200 OK\r\n" ~ 
		"Server: RootinTootin_0.1\r\n" ~ 
		"Status: 200 OK\r\n" ~ 
		"Access-Control-Allow-Origin: *\r\n" ~ 
		"Content-Length: 0\r\n" ~  
		"\r\n";

		socket.write(response);
	}

	protected void trigger_on_request_get(Socket socket, Request request, char[] raw_header, char[] raw_body) {
		this.on_request_get(socket, request, raw_header, raw_body);
	}

	protected void trigger_on_request_post(Socket socket, Request request, char[] raw_header, char[] raw_body) {
		// Show an 'HTTP 411 Length Required' error if there is no Content-Length
		if(tango.text.Util.locatePattern(raw_header, "Content-Length: ", 0) == raw_header.length) {
			this.render_text(socket, request, "Content-Length is required for HTTP POST and PUT.", 411);
			return;
		}

		// Get the content length
		request.content_length = to_uint(between(raw_header, "Content-Length: ", "\r\n"));

		// Get the params from a url encoded body
		if(("Content-Type" in request._fields) != null) {
			if(request._fields["Content-Type"] == "application/x-www-form-urlencoded") {
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
		if(("Content-Type" in fields) != null) {
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

		this.on_request_post(socket, request, raw_header, raw_body);
	}

	protected void trigger_on_request_put(Socket socket, Request request, char[] raw_header, char[] raw_body) {
		this.on_request_put(socket, request, raw_header, raw_body);
	}

	protected void trigger_on_request_delete(Socket socket, Request request, char[] raw_header, char[] raw_body) {
		this.on_request_delete(socket, request, raw_header, raw_body);
	}

	protected void trigger_on_request_options(Socket socket, Request request, char[] raw_header, char[] raw_body) {
		this.on_request_options(socket, request, raw_header, raw_body);
	}

	protected void trigger_on_read_request(Socket socket, char[] buffer) {
		Request request = Request.new_blank();
		int buffer_length = socket.input.read(buffer);

		// Return blank for bad requests
		if(buffer_length < 1) {
			return;
		}

		// Show an 'HTTP 413 Request Entity Too Large' if the end of the header was not read
		if(tango.text.Util.locatePattern(buffer[0 .. buffer_length], "\r\n\r\n", 0) == buffer_length) {
			char[] text = "The end of the HTTP header was not found when reading the first " ~ to_s(buffer.length) ~ " bytes.";
			render_text(socket, request, text, 413);
			return;
		}

		// Get the raw header body and header from the buffer
		char[][] buffer_pair = ["", ""];
		int header_end = tango.text.Util.locatePattern(buffer[0 .. buffer_length], "\r\n\r\n", 0);
		char[] raw_header = buffer[0 .. buffer_length][0 .. header_end];
		char[] raw_body = buffer[0 .. buffer_length][header_end+4 .. length];

		// Get the header info
		char[][] header_lines = tango.text.Util.splitLines(raw_header);
		char[][] first_line = split(header_lines[0], " ");
		request.method = first_line[0];
		request.uri = first_line[1];
		request.http_version = first_line[2];

		// Get all the fields
		foreach(char[] line ; header_lines) {
			// Break if we are at the end of the fields
			if(line.length == 0) break;

			char[][] pair = split(line, ": ");
			if(pair.length == 2) {
				request._fields[pair[0]] = pair[1];
			}
		}

		// Get the cookies
		if(("Cookie" in request._fields) != null) {
			foreach(char[] cookie ; split(request._fields["Cookie"], "; ")) {
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
			_mutex_sessions.lock();
			bool has_session = !((hashed_session_id in _sessions) == null);
			_mutex_sessions.unlock();
			if(!has_session) {
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
	}

	protected void redirect_to(Socket socket, Request request, char[] url) {
		// If we have already rendered, show an error
		if(request.has_rendered) {
			throw new Exception("Something has already been rendered.");
		}

		char[] status = Helper.get_verbose_status_code(301);

		char[] header = "HTTP/1.1 " ~ status ~ "\r\n" ~
		"Location: " ~ url ~ "\r\n" ~
		"Content-Type: text/html\r\n" ~
		"Content-Length: 0" ~
		"\r\n";

		socket.write(header);
	}

	protected void render_text(Socket socket, Request request, char[] text, ushort status_code) {
		socket.write(generate_text(request, text, status_code));
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
		_mutex_sessions.lock();
		bool has_session = !(("_appname_session" in request._cookies) == null || (request._cookies["_appname_session"] in _sessions) == null);
		_mutex_sessions.unlock();

		char[] set_cookies = "";
		if(!has_session) {
			// Get the next session_id and increment the sequence
			_mutex_session_id.lock();
			int new_session_id = _session_id;
			_session_id++;
			_mutex_session_id.unlock();

			char[] hashed_session_id = Helper.hash_and_base64(to_s(new_session_id), _salt);
			request._cookies["_appname_session"] = hashed_session_id; // ~ "; path=/";
			_mutex_sessions.lock();
			_sessions[hashed_session_id] = [];
			_mutex_sessions.unlock();
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
		"Server: RootinTootin_0.1\r\n", 
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



