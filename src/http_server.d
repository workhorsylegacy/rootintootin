/*------------------------------------------------------------------------------
#
#    This file is part of the Rootin Tootin web framework and licensed under the
#    GPL version 3 or greater. See the COPYRIGHT file for copyright information.
#    This project is hosted at http://rootin.toot.in .
#
#-----------------------------------------------------------------------------*/

/****h* http_server/http_server.d
 *  NAME
 *    http_server.d
 *  FUNCTION
 *    Contains the code needed for basic HTTP servers and applications.
 ******
 */

private import tango.io.Stdout;
private import tango.core.Thread;
private import tango.net.http.HttpClient;
private import tango.net.http.HttpHeaders;

private import tango.math.random.engines.Twister;
private import tango.time.chrono.Gregorian;
private import tango.time.WallClock;
private import tango.time.Clock;
private import tango.io.device.File;

private import socket;
private import fcgi;
private import tcp_server;
private import dlang_helper;
private import web_helper;


/****c* http_server/Request
 *  NAME
 *    Request
 *  FUNCTION
 *    Contains the request data parsed into the fields:
 *        method:         HTTP request method
 *        uri:            HTTP request URI
 *        format:         HTTP format
 *        http_version:   HTTP version
 *        params:         HTTP GET parameters
 *        fields:         HTTP fields
 *        cookies:        HTTP cookies
 *        sessions:       HTTP sessions
 *        content_length: HTTP request content length
 ******
 */
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
}

/****c* http_server/HttpApp
 *  NAME
 *    HttpApp
 *  FUNCTION
 *    A class used to create a basic HTTP application. It is designed to 
 *    work with HttpServer.
 ******
 */
class HttpApp {
	private int _session_id = 0;
	private string[string][string] _sessions;
	private string _salt;
	private string _server_name;
	protected string _response;
	protected string _buffer;
	protected string _file_buffer;
	private string[] _pair;
	protected bool _is_fcgi = false;
	private int _fd;
	private string _fcgi_raw_body;

	protected void set_fd(int value) {
		_fd = value;
	}

	public this(bool is_fcgi, string server_name) {
		if(server_name == null)
			throw new Exception("The server name is invalid");
		_server_name = server_name;
		_is_fcgi = is_fcgi;
		_pair = new string[2];

		// Get a random salt for salting sessions
		Twister* random = new Twister();
		random.seed(cast(uint)Clock.now.span.millis);
		this._salt = to_s(random.next());
		delete random;
	}

	protected string process_request() {
		this.trigger_on_request();
		return _response;
	}

	protected string on_request_get(Request request) {
		string text = "200: Okay";
		return render_text(request, text, 200);
	}

	protected string on_request_post(Request request) {
		string text = "200: Okay";
		return render_text(request, text, 200);
	}

	protected string on_request_put(Request request) {
		string text = "200: Okay";
		return render_text(request, text, 200);
	}

	protected string on_request_delete(Request request) {
		string text = "200: Okay";
		return render_text(request, text, 200);
	}

	protected string on_request_options(Request request) {
		// Send a basic options header for access control
		// See: https://developer.mozilla.org/En/HTTP_Access_Control
		string response = 
		(_is_fcgi ? "" : "HTTP/1.1 200 OK\r\n") ~ 
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

	protected void write_to_log(string message) {
		Stdout(message).flush;
	}

	protected void trigger_on_request() {
		int len = socket_read(_fd, _buffer.ptr, _buffer.length);
		char[] raw_request = _buffer[0 .. len];

		trigger_on_request(raw_request);
	}

	protected void trigger_on_request(char[] raw_request) {
		write_to_log(raw_request);
		Request request = new Request();
		_response = null;
		_fcgi_raw_body = null;
		int len = 0;

		// Read the request header
		size_t header_end = index(raw_request, "\r\n\r\n");

		// If we have not found the end of the header return a 413 error
		if(header_end == 0) {
			_response = render_text(request, "413 Request Entity Too Large: The HTTP header is bigger than the max header size of " ~ to_s(_buffer.length) ~ " bytes.", 413);
			return;
		}

		// Get the raw header from the buffer
		string raw_header = raw_request[0 .. header_end];

		// Get the header info
		string[] header_lines = split_lines(raw_header);
		string[] first_line = split(header_lines[0], " ");
		request.method = first_line[0];
		request.uri = first_line[1];
		request.format = before(after_last(after_last(request.uri, "/"), "."), "?");
		request.was_format_specified = (request.format != "");
		if(!request.was_format_specified) request.format = "html";
		request.http_version = first_line[2];

		// If the format is unknown, return a 415 error
		if(!(request.format in mimetype_map)) {
			_response = render_text(request, "415 Unsupported Media Type: The server does not understand the '" ~ request.format ~ "' format.", 415, "txt");
			return;
		}

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
					request._cookies[_pair[0]] = unescape(_pair[1]);
				} else {
					this.write_to_log("Malformed cookie: " ~ cookie ~ "\n");
				}
			}
		}

		// Get the HTTP GET params
		if(contains(request.uri, "?")) {
			foreach(string param ; split(after(request.uri, "?"), "&")) {
				if(pair(param, "=", _pair)) {
					request._params[unescape(_pair[0])].value = unescape(_pair[1]);
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

		if(request.method == "POST" || request.method == "PUT") {
			// Make sure the Content-Length field exist
			if(!("Content-Length" in request._fields)) {
				_response = this.render_text(request, "411 Length Required: Content-Length is required for HTTP POST and PUT.", 411);
				return;
			}
			request.content_length = to_uint(request._fields["Content-Length"]);

			// Make sure the Content-Type field exist
			if(!("Content-Type" in request._fields)) {
				_response = this.render_text(request, "415 Unsupported Media Type: A valid Content-Type is required for HTTP POST and PUT.", 415);
				return;
			}

			// For cgi read the body into memory
			// FIXME: Puting the whole body into memory is bad.
			if(_is_fcgi) {
				_fcgi_raw_body = new char[request.content_length];
				fcgi_get_stdin(_fcgi_raw_body);
			// Or normally read the body into a file
			} else {
				int remaining_length = request.content_length;
				File file = new File("raw_body", File.WriteCreate);
				string body_chunk = raw_request[header_end+4 .. length];
				file.write(body_chunk);
				remaining_length -= body_chunk.length;

				while(remaining_length > 0) {
					len = socket_read(_fd, _file_buffer.ptr, _file_buffer.length);
					body_chunk = _file_buffer[0 .. len];
					file.write(body_chunk);
					remaining_length -= body_chunk.length;
				}

				file.close();
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
				hashed_session_id = hash_and_base64(to_s(new_session_id), _salt);
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
				this.respond_to_client(this.trigger_on_request_get(request));
				break;
			case "POST":
				this.respond_to_client(this.trigger_on_request_post(request));
				break;
			case "PUT":
				this.respond_to_client(this.trigger_on_request_put(request));
				break;
			case "DELETE":
				this.respond_to_client(this.trigger_on_request_delete(request));
				break;
			case "OPTIONS":
				this.respond_to_client(this.trigger_on_request_options(request));
				break;
			default:
				throw new Exception("Unknown http request method '" ~ request.method ~ "'.");
		}

		// Copy the modified session back to the sessions
		_sessions[hashed_session_id] = request._sessions;

		// FIXME: this prints out all the values we care about
		/*
		this.write_to_log("Sessions { :\n");
		foreach(string n, string[string] values ; _sessions) {
			this.write_to_log("\t" ~ n ~ "\n");
			foreach(string name, string value ; values) {
				this.write_to_log("\t\t" ~ name ~ " => " ~ value ~ "\n");
			}
		}
		this.write_to_log("}\n");
		*/
	}

	protected string trigger_on_request_get(Request request) {
		return this.on_request_get(request);
	}

	protected string trigger_on_request_post(Request request) {
		return this.trigger_on_request_put(request);
	}

	protected string trigger_on_request_put(Request request) {
		// Get the params from the body
		string content_type = request._fields["Content-Type"];

		string file_body = null;
		if(_is_fcgi) {
			file_body = _fcgi_raw_body;
		} else {
			File file = new File("raw_body", File.ReadExisting);
			file_body = new char[cast(size_t)file.length];
			file.read(file_body);
			file.close();
		}

		switch(before(content_type, ";")) {
			case "application/x-www-form-urlencoded":
				urlencode_to_dict(request._params, file_body);
				break;
			case "application/json":
				json_to_dict(request._params, file_body);
				break;
			case "application/xml":
				xml_to_dict(request._params, file_body);
				break;
			case "multipart/form-data":
				string boundary = after(content_type, "; boundary=");
				multipart_to_dict_and_file(request._params, file_body, boundary);
				break;
			default:
				throw new Exception("Unknown Content-Type '" ~ request._fields["Content-Type"] ~ "'.");
		}

		return this.on_request_put(request);
	}

	protected string trigger_on_request_delete(Request request) {
		return this.on_request_delete(request);
	}

	protected string trigger_on_request_options(Request request) {
		return this.on_request_options(request);
	}

	protected string redirect_to(Request request, string url) {
		// If we have already rendered, show an error
		if(request.has_rendered) {
			throw new Exception("Something has already been rendered.");
		}

		string status = get_verbose_status_code(301);

		string header = 
		(_is_fcgi ? "" : "HTTP/1.1 " ~ status ~ "\r\n") ~ 
		"Location: " ~ url ~ "\r\n" ~
		"Content-Type: text/html\r\n" ~
		"Content-Length: 0\r\n" ~
		"\r\n";

		return header;
	}

	protected string render_text(Request request, string text, ushort status_code = 200, string format = null) {
		if(format==null) format = request.format;
		if(format==null) format = "txt";
		string content_type = mimetype_map[format];

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
			request = new Request();
		}

		// If we have already rendered, show an error
		if(request.has_rendered) {
			throw new Exception("Something has already been rendered.");
		}

		// Get the status code
		string status = get_verbose_status_code(status_code);

		// Add the HTTP headers
		auto now = WallClock.now;
		auto time = now.time;
		auto date = Gregorian.generic.toDate(now);
		auto b = new AutoStringArray(_buffer);
		b ~= (_is_fcgi ? "" : "HTTP/1.1 " ~ status ~ "\r\n");
		b~= "Date: " ;b~= to_s(date.day) ;b~= to_s(date.month) ;b~= to_s(date.year) ;b~= "\r\n" ;b~= 
		"Server: " ;b~= _server_name ;b~= "\r\n" ;

		// Get all the new cookie values to send
		foreach(string name, string value ; request._cookies) {
			b~= "Set-Cookie: " ;b~= name ;b~= "=" ;b~= escape(value) ;b~= "\r\n";
		}

		b~= "Status: " ;b~= status ;b~= "\r\n" ;b~= 
		//"X-Runtime: 0.15560\r\n",
		//"ETag: \"53e91025a55dfb0b652da97df0e96e4d\"\r\n",
		"Access-Control-Allow-Origin: *\r\n" ;b~= 
		"Cache-Control: private, max-age=0\r\n" ;b~= 
		"Content-Type: " ;b~= content_type ;b~= "\r\n" ;b~= 
		"Content-Length: " ;b~= to_s(text.length) ;b~= "\r\n" ;b~=
		//"Vary: User-Agent\r\n",
		"\r\n" ;b~=
		text;

		return b.toString();
	}

	private void urlencode_to_dict(ref Dictionary dict, string urlencode_in_a_string) {
		string data = unescape(urlencode_in_a_string);
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
		// Get the file data from the multipart encoded gibberish
		string content_type = before(after(multipart_in_a_string, "Content-Type: "), "\r\n");
		string file_name = before(after(before(after(multipart_in_a_string, boundary), "Content-Type: "~content_type), "; filename=\""), "\"");
		string file_data = before(after(multipart_in_a_string, "Content-Type: "~content_type~"\r\n\r\n"), "\r\n--"~boundary);

		// Save the info in a dict
		dict["file_name"].value = file_name;
		dict["file_path"].value = "uploads/" ~ file_name;
		dict["file_content_type"].value = content_type;

		// Write the file to disk
		File file = new File(dict["file_path"].value, File.WriteCreate);
		file.write(file_data);
		file.close();
	}
}

/****c* http_server/HttpServer
 *  NAME
 *    HttpServer
 *  FUNCTION
 *    A class used to create a basic HTTP server. It is designed to 
 *    work with HttpApp.
 ******
 */
class HttpServer : TcpServer {
	public this(ushort port, int max_waiting_clients) {
		super(port, max_waiting_clients);
	}

	protected override void on_started(bool is_event_triggered = true) {
		Stdout.format("Running on http://localhost:{} ...", this._port).newline.flush;
	}

	unittest {
		class AppServer : HttpServer {
			public this(ushort port, int max_waiting_clients) {
				super(port, max_waiting_clients);
			}

			protected override void on_started(bool is_event_triggered = true) {
			}

			protected override void on_connection_ready(int fd) {
				socket_write(fd, "HTTP/1.0 200 OK\r\nStatus: 200 OK\r\nContent-Type: text/plain\r\nContent-Length: 4\r\n\r\nblah");
				socket_close(fd);
			}
		}

		describe("HttpServer", 
			it("Should respond to a connection", function() {
				// Start the server
				auto thread = new Thread(function() {
					auto server = new AppServer(3000, 100);

					// Start the server and have it stop after one request
					server.start(delegate(TcpServer server) {
						server._is_running  = false;
					});
				});
				thread.start();
				Thread.sleep(0.01);

				// Make sure the response was HTTP OK
				auto client = new HttpClient(HttpClient.Get, "http://127.0.0.1:3000/");
				client.open();
				assert(client.isResponseOK);

				// Make sure the length is valid
				auto length = client.getResponseHeaders.getInt(HttpHeader.ContentLength);
				assert(length == 4);

				// Make sure the type is valid
				auto type = client.getResponseHeaders.get(HttpHeader.ContentType);
				assert(type == "text/plain");

				// Make sure the body is valid
				client.read(delegate(void[] content) {
					assert(content == "blah");
				}, length);

				client.close();
				thread.join();
			})
		);
	}
}


