/*------------------------------------------------------------------------------
#
#    This file is part of the Rootin Tootin web framework and licensed under the
#    GPL version 3 or greater. See the COPYRIGHT file for copyright information.
#    This project is hosted at http://rootin.toot.in .
#
#-----------------------------------------------------------------------------*/


private import tango.io.Stdout;
private import tango.io.Console;

private import tango.math.random.engines.Twister;
private import tango.time.chrono.Gregorian;
private import tango.time.WallClock;
private import tango.time.Clock;
private import tango.io.device.File;

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
	public Dictionary _params;
	public string[string] _fields;
	public string[string] _cookies;
	public string[string] _sessions;
	public uint _content_length = 0;

	public this(string method, string uri, string format, string http_version, Dictionary params, string[string] fields, string[string] cookies) {
		_method = method;
		_uri = uri;
		_format = format;
		_http_version = http_version;
		_params = params;
		_fields = fields;
		_cookies = cookies;
	}

	public this() {
		_params = new Dictionary();
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
		string[string] cookies, fields;
		Dictionary params = new Dictionary();
		return new Request("", "", "", "", params, fields, cookies);
	}
}

class HttpApp {
	private int _session_id = 0;
	private string[string][string] _sessions;
	private string _salt;
	private string _server_name;
	protected string _response;
	private string[] _pair;

	public this(string server_name) {
		if(server_name == null)
			throw new Exception("The server name is invalid");
		_server_name = server_name;
		_pair = new string[2];

		// Get a random salt for salting sessions
		Twister* random = new Twister();
		random.seed(cast(uint)Clock.now.span.millis);
		this._salt = to_s(random.next());
		delete random;
	}

	protected string process_request(char[] request) {
		try {
			this.trigger_on_request(request);
			return _response;
		} catch(Exception err) {
			return "Error" ~ err.msg ~ " " ~ to_s(err.line) ~ " " ~ err.file;
		}
	}

	protected string on_request_get(Request request, string raw_header, string raw_body) {
		string text = "200: Okay";
		return render_text(request, text, 200);
	}

	protected string on_request_post(Request request, string raw_header, string raw_body) {
		string text = "200: Okay";
		return render_text(request, text, 200);
	}

	protected string on_request_put(Request request, string raw_header, string raw_body) {
		string text = "200: Okay";
		return render_text(request, text, 200);
	}

	protected string on_request_delete(Request request, string raw_header, string raw_body) {
		string text = "200: Okay";
		return render_text(request, text, 200);
	}

	protected string on_request_options(Request request, string raw_header, string raw_body) {
		// Send a basic options header for access control
		// See: https://developer.mozilla.org/En/HTTP_Access_Control
		string response = 
		"HTTP/1.1 200 OK\r\n" ~ 
		"Server: " ~ _server_name ~ "\r\n" ~ 
		"Status: 200 OK\r\n" ~ 
		"Access-Control-Allow-Origin: *\r\n" ~ 
		"Content-Length: 0\r\n" ~  
		"\r\n";

		return response;
	}

	protected void respond_to_client(string response) {
		_response = response;
	}

	protected void write_to_log(string response) {
		Stdout(response).flush;
	}

	protected void trigger_on_request(string raw_request) {
		Request request = new Request();
		_response = null;

		// Get the raw header body and header from the buffer
		size_t header_end = index(raw_request, "\r\n\r\n");
		string raw_header = raw_request[0 .. header_end];
		string raw_body = raw_request[header_end+4 .. length];

		// Get the header info
		string[] header_lines = split_lines(raw_header);

		string[] first_line = split(header_lines[0], " ");
		request.method = first_line[0];
		request.uri = first_line[1];
		request.format = before(after_last(after_last(request.uri, "/"), "."), "?");
		request.was_format_specified = (request.format != "");
		if(!request.was_format_specified) request.format = "html";
		request.http_version = first_line[2];

		// Get all the fields
		foreach(string line ; header_lines) {
			// Break if we are at the end of the fields
			if(line.length == 0) break;

			if(pair(line, ": ", _pair)) {
				request._fields[_pair[0]] = _pair[1];
			}
		}

		// Determine if the client has cookie support
		bool has_cookie_support = true;
		if("User-Agent" in request._fields) {
			has_cookie_support = !contains(request._fields["User-Agent"], "ApacheBench");
		}

		// Get the cookies
		if(has_cookie_support && ("Cookie" in request._fields) != null) {
			foreach(string cookie ; split(request._fields["Cookie"], "; ")) {
				if(pair(cookie, "=", _pair)) {
					request._cookies[_pair[0]] = Helper.unescape(_pair[1]);
				} else {
					this.write_to_log("Malformed cookie: " ~ cookie ~ "\n");
				}
			}
		}

		// Get the HTTP GET params
		if(contains(request.uri, '?')) {
			foreach(string param ; split(after(request.uri, "?"), "&")) {
				if(pair(param, "=", _pair)) {
					request._params[Helper.unescape(_pair[0])].value = Helper.unescape(_pair[1]);
				}
			}
		}

		// Monkey Patch the http method
		// This lets browsers fake http put, and delete
		if(has_cookie_support && request._params.has_key("method")) {
			switch(request._params["method"].value) {
				case "GET":
				case "POST":
				case "PUT":
				case "DELETE":
				case "OPTIONS":
					request.method = request._params["method"].value; break;
				default: break;
			}
		}

		// Determine if we have a session id in the cookies
		bool has_session = false;
		has_session = (("_appname_session" in request._cookies) != null);

		// Determine if the session id is invalid
		if(has_cookie_support && has_session && (request._cookies["_appname_session"] in _sessions) == null) {
			string hashed_session_id = request._cookies["_appname_session"];
			this.write_to_log("Unknown session id '" ~ hashed_session_id ~ "'\n");
			has_session = false;
		}

		// Create a new session if we need it
		string hashed_session_id = null;
		if(!has_session) {
			// Get the next session_id and increment the sequence
			int new_session_id = _session_id++;

			// Create the hashed session id
			// Don't bother hashing or base64ing the session 
			// if it is not going to be used by the client.
			if(has_cookie_support)
				hashed_session_id = Helper.hash_and_base64(to_s(new_session_id), _salt);
			else
				hashed_session_id = to_s(new_session_id);
			request._cookies["_appname_session"] = hashed_session_id;

			this.write_to_log("Created session number '" ~ to_s(new_session_id) ~ "' '" ~ hashed_session_id ~ "'\n");
		} else {
			hashed_session_id = request._cookies["_appname_session"];
			this.write_to_log("Using existing session '" ~ request._cookies["_appname_session"] ~ "'\n");
		}

		// Copy the existing session to the request
		if(hashed_session_id in _sessions)
			request._sessions = _sessions[hashed_session_id];

		// Process the remainder of the request based on its method
		switch(request.method) {
			case "GET":
				this.respond_to_client(this.trigger_on_request_get(request, raw_header, raw_body));
				break;
			case "POST":
				this.respond_to_client(this.trigger_on_request_post(request, raw_header, raw_body));
				break;
			case "PUT":
				this.respond_to_client(this.trigger_on_request_put(request, raw_header, raw_body));
				break;
			case "DELETE":
				this.respond_to_client(this.trigger_on_request_delete(request, raw_header, raw_body));
				break;
			case "OPTIONS":
				this.respond_to_client(this.trigger_on_request_options(request, raw_header, raw_body));
				break;
			default:
				throw new Exception("Unknown http request method '" ~ request.method ~ "'.");
		}

		// Copy the modified session back to the sessions
		if(request._sessions.length > 0)
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

	protected string trigger_on_request_get(Request request, string raw_header, string raw_body) {
		return this.on_request_get(request, raw_header, raw_body);
	}

	protected string trigger_on_request_post(Request request, string raw_header, string raw_body) {
		return this.trigger_on_request_put(request, raw_header, raw_body);
	}

	protected string trigger_on_request_put(Request request, string raw_header, string raw_body) {
		// Show an 'HTTP 411 Length Required' error if there is no Content-Length
		if(tango.text.Util.locatePattern(raw_header, "Content-Length: ", 0) == raw_header.length) {
			return this.render_text(request, "Content-Length is required for HTTP POST and PUT.", 411);
		}

		// Get the content length
		request.content_length = to_uint(between(raw_header, "Content-Length: ", "\r\n"));

		// Get the params from the body
		if(("Content-Type" in request._fields) != null) {
			string content_type = request._fields["Content-Type"];
			switch(before(content_type, ";")) {
				case "application/x-www-form-urlencoded":
					urlencode_to_dict(request._params, raw_body);
					break;
				case "application/json":
					json_to_dict(request._params, raw_body);
					break;
				case "application/xml":
					xml_to_dict(request._params, raw_body);
					break;
				case "multipart/form-data":
					string boundary = after(content_type, "; boundary=");
					multipart_to_dict_and_file(request._params, raw_body, boundary);
					break;
				default:
					throw new Exception("Unknown Content-Type '" ~ request._fields["Content-Type"] ~ "'.");
			}
		}

		return this.on_request_put(request, raw_header, raw_body);
	}

	protected string trigger_on_request_delete(Request request, string raw_header, string raw_body) {
		return this.on_request_delete(request, raw_header, raw_body);
	}

	protected string trigger_on_request_options(Request request, string raw_header, string raw_body) {
		return this.on_request_options(request, raw_header, raw_body);
	}

	protected string redirect_to(Request request, string url) {
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

		return header;
	}

	protected string render_text(Request request, string text, ushort status_code = 200, string format = null) {
		if(format==null) format = request.format;
		string content_type = Helper.mimetype_map[format];

		// If a 404 page is less than 512 bytes, we pad it for Chrome/Chromium
		// Otherwise the "Friendly 404" will show in the browser.
		// https://bugs.launchpad.net/rester/+bug/597049
		if(status_code == 404 && text.length < 512)
			text = ljust(text, 512, " ");

		return generate_text(request, text, status_code, content_type);
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
			set_cookies ~= "Set-Cookie: " ~ name ~ "=" ~ Helper.escape(value) ~ "\r\n";
		}

		// Add the HTTP headers
		auto now = WallClock.now;
		auto time = now.time;
		auto date = Gregorian.generic.toDate(now);
		string reply = 
		"HTTP/1.1 " ~ status ~ "\r\n" ~ 
		"Date: " ~ to_s(date.day) ~ to_s(date.month) ~ to_s(date.year) ~ "\r\n" ~ 
		"Server: " ~ _server_name ~ "\r\n" ~ 
		set_cookies ~ 
		"Status: " ~ status ~ "\r\n" ~ 
		//"X-Runtime: 0.15560\r\n",
		//"ETag: \"53e91025a55dfb0b652da97df0e96e4d\"\r\n",
		"Access-Control-Allow-Origin: *\r\n" ~ 
		"Cache-Control: private, max-age=0\r\n" ~ 
		"Content-Type: " ~ content_type ~ "\r\n" ~ 
		"Content-Length: " ~ to_s(text.length) ~ "\r\n" ~
		//"Vary: User-Agent\r\n",
		"\r\n" ~
		text;

		return reply;
	}

	private void urlencode_to_dict(ref Dictionary dict, string urlencode_in_a_string) {
		string data = Helper.unescape(urlencode_in_a_string);
		foreach(string param ; split(data, "&")) {
			string[] pair = split(param, "=");
			if(pair.length == 2) {
				string start = before(pair[0], "[");
				string middle = after(before(pair[0], "]"), "[");
				if(start.length > 0 && middle.length > 0)
					dict[start][middle].value = pair[1];
				else
					dict[pair[0]].value = pair[1];
			}
		}
	}

	private void multipart_to_dict_and_file(ref Dictionary dict, string multipart_in_a_string, string boundary) {
//		this.write_to_log("length: " ~ to_s(multipart_in_a_string.length) ~ "\n");
//		this.write_to_log("multipart_in_a_string: " ~ multipart_in_a_string ~ "\n");

		char[] data = split(multipart_in_a_string, "--" ~ boundary)[1];
//		this.write_to_log("data: " ~ data ~ "\r\n\r\n");

		char[] header = split(multipart_in_a_string, "\r\n\r\n")[0];
//		this.write_to_log("header: " ~ header ~ "\n\n");

		char[] disposition = split(header, "\n")[1];
//		this.write_to_log("disposition: " ~ disposition ~ "\n\n");

		char[] field_name = between(disposition, "; name=\"", "\"; ");
		char[] file_name = between(disposition, "; filename=\"", "\"");
//		this.write_to_log(field_name ~ ": [" ~ file_name ~ "]\n\n");

		char[] file_content_type = split(header, "Content-Type: ")[1];
//		this.write_to_log("app file_content_type: [" ~ file_content_type ~ "]\n\n");

		char[] file_data = split(data, "\r\n\r\n")[1][0 .. length-3];
//		this.write_to_log("app data length: [" ~ to_s(file_data.length) ~ "]\n\n");
//		this.write_to_log("file_data: [" ~ file_data ~ "]\n\n");

		dict["file_name"].value = file_name;
		dict["file_path"].value = "uploads/" ~ file_name;
		dict["file_content_type"].value = file_content_type;

		// Write the file to disk
		File file = new File(dict["file_path"].value, File.WriteCreate);
		file.write(file_data);
		file.close();
	}
}

class HttpServer : TcpServer {
	public this(ushort port, int max_waiting_clients) {
		super(port, max_waiting_clients);
	}

	protected void on_started() {
		Stdout.format("Running on http://localhost:{} ...\n", this._port).flush;
	}
}


