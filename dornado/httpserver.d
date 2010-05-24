/*
# Copyright 2010 Matthew Brennan Jones
# Copyright 2009 Facebook
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#	 http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.
*/
//"""A non-blocking, single-threaded HTTP server."""

module dornado.httpserver;

private import tango.net.device.Socket;
private import tango.net.InternetAddress;
private import IConduit = tango.io.model.IConduit;

private import tango.time.Clock;

private import dornado.ioloop;
private import dornado.iostream;
public import language_helper;
private import helper;


// Start Temporary stub objects
class cgi {
	public static string[][string] parse_qs(string query) {
		string[][string] retval;
		foreach(string param ; split(query, "&")) {
			string[] pair = tango.text.Util.split(param, "=");
			retval[Helper.unescape_value(pair[0])] = [Helper.unescape_value(pair[1])];
		}
		return retval;
	}
}

class SocketError : Exception {
	public this(string text, ushort status) {
		super("");
	}
}

class SocketErrorEWOULDBLOCK : Exception {
	public this(string text, ushort status) {
		super("");
	}
}

class SocketErrorEAGAIN : Exception {
	public this(string text, ushort status) {
		super("");
	}
}
// End Temporary stub objects


class HTTPServer {
	private void delegate(HTTPRequest) request_callback;
	private bool no_keep_alive;
	private IOLoop io_loop;
	private bool xheaders;
	private ServerSocket _socket;

	public ServerSocket socket() { return _socket; }

	public this(void delegate(HTTPRequest) request_callback, bool no_keep_alive=false, IOLoop io_loop=null, bool xheaders=false) {
		this.request_callback = request_callback;
		this.no_keep_alive = no_keep_alive;
		this.io_loop = io_loop ? io_loop : IOLoop.instance();
		this.xheaders = xheaders;
		this._socket = null;
	}

	public void listen(int port) {
		assert(!this._socket);
		int max_waiting_clients = 128;
		bool is_address_reusable = true;
		this._socket = new ServerSocket(new InternetAddress("0.0.0.0", port), max_waiting_clients, is_address_reusable);
		this._socket.socket.blocking(false);
		this.io_loop.add_handler(this._socket.fileHandle, &this._handle_events,
								this.io_loop.READ);
	}

	public void _handle_events(IConduit.ISelectable.Handle fd, uint events) {
		while(true) {
			Socket connection;
			// FIXME: How do we get the address?
			string address = "";
			try {
				connection = this._socket.accept();
			} catch(SocketErrorEWOULDBLOCK e) {
				return;
			} catch(SocketErrorEAGAIN e) {
				return;
			} catch(SocketError e) {
				throw(e);
			}
			try {
				IOStream stream = new IOStream(connection, this.io_loop);
				new HTTPConnection(stream, address, this.request_callback, 
								this.no_keep_alive, this.xheaders);
			} catch {
//				logging.error("Error in connection callback", exc_info=true);
			}
		}
	}
}

class HTTPConnection {
	//"""Handles a connection to an HTTP client, executing HTTP requests.
	//
	//We parse HTTP headers and bodies, and execute the request callback
	//until the HTTP conection is closed.
	//"""
	private IOStream stream;
	private string address;
	private void delegate(HTTPRequest) request_callback;
	private bool no_keep_alive;
	private bool xheaders;
	private HTTPRequest _request;
	private bool _request_finished;

	public this(IOStream stream, string address, void delegate(HTTPRequest) request_callback, bool no_keep_alive=false, bool xheaders=false) {
		this.stream = stream;
		this.address = address;
		this.request_callback = request_callback;
		this.no_keep_alive = no_keep_alive;
		this.xheaders = xheaders;
		this._request = null;
		this._request_finished = false;
		this.stream.read_until("\r\n\r\n", &this._on_headers);
	}

	public void write(string chunk) {
		assert(this._request, "Request closed");
		this.stream.write(chunk, &this._on_write_complete);
	}

	public void finish() {
		assert(this._request, "Request closed");
		this._request_finished = true;
		if(!this.stream.writing())
			this._finish_request();
	}

	public void _on_write_complete() {
		if(this._request_finished)
			this._finish_request();
	}

	public void _finish_request() {
		bool disconnect;
		if(this.no_keep_alive) {
			disconnect = true;
		} else {
			string connection_header = null;
			if(this._request.headers.has_key("Connection"))
				connection_header = this._request.headers["Connection"];
			if(this._request.supports_http_1_1()) {
				disconnect = connection_header == "close";
			} else if(this._request.headers.has_key("Content-Length") || 
				this._request.method == "HEAD" ||
				this._request.method == "GET") {
				disconnect = connection_header != "Keep-Alive";
			} else {
				disconnect = true;
			}
		}
		this._request = null;
		this._request_finished = false;
		if(disconnect) {
			this.stream.close();
			return;
		}
		this.stream.read_until("\r\n\r\n", &this._on_headers);
	}

	public void _on_headers(string data) {
		size_t eol = index(data, "\r\n");
		string start_line = data[0 .. eol];
		string[] split_start_line = split(start_line, " ");
		string method = split_start_line[0];
		string uri = split_start_line[1];
		string version_ = split_start_line[2];
		if(!starts_with(version_, "HTTP/"))
			throw new Exception("Malformed HTTP version in HTTP Request-Line");

		HTTPHeaders headers = HTTPHeaders.parse(data[eol .. length]);
		this._request = new HTTPRequest(method, uri, version_, headers, this.address);

		if(headers.has_key("Content-Length")) {
			int content_length = to_int(headers["Content-Length"]);
			if(content_length > this.stream.max_buffer_size)
				throw new Exception("Content-Length too long");
			if(headers.has_key("Expect") && headers["Expect"] == "100-continue")
				this.stream.write("HTTP/1.1 100 (Continue)\r\n\r\n");
			this.stream.read_bytes(content_length, &this._on_request_body);
			return;
		}

		this.request_callback(this._request);
	}

	public void _on_request_body(string data) {
		this._request.body_ = data;
		string content_type = "";
		if(this._request.headers.has_key("Content-Type"))
			content_type = this._request.headers["Content-Type"];

		if(this._request.method == "POST") {
			if(starts_with(content_type, "application/x-www-form-urlencoded")) {
				string[][string] arguments = cgi.parse_qs(this._request.body_);
				foreach(string name, string[] values ; arguments) {
					string[] cleaned_values;
					foreach(string v ; values)
						if(v.length > 0)
							cleaned_values ~= v;
					if(cleaned_values.length > 0) {
						if((name in this._request.arguments) == null)
							this._request.arguments[name] = [];
						foreach(string cleaned_value ; cleaned_values.reverse)
							this._request.arguments[name] ~= cleaned_value;
					}
				}
			} else if(starts_with(content_type, "multipart/form-data")) {
				string boundary = content_type[30 .. length];
				if(boundary.length > 0)
					this._parse_mime_body(boundary, data);
			}
		}
		this.request_callback(this._request);
	}

	public void _parse_mime_body(string boundary, string data) {
		int footer_length = 0;
		if(ends_with(data, "\r\n")) {
			footer_length = boundary.length + 6;
		} else {
			footer_length = boundary.length + 4;
		}
		string[] parts = split(data[0 .. -footer_length], "--" ~ boundary ~ "\r\n");
		foreach(string part ; parts) {
			if(part is null || part.length == 0)
				continue;
			size_t eoh = index(part, "\r\n\r\n");
			if(eoh == part.length) {
//				logging.warning("multipart/form-data missing headers");
				continue;
			}
			HTTPHeaders headers = HTTPHeaders.parse(part[0 .. eoh]);
			string name_header = "";
			if(headers.has_key("Content-Disposition"))
				name_header = headers["Content-Disposition"];
			if(!starts_with(name_header, "form-data;") || !ends_with(part, "\r\n")) {
//				logging.warning("Invalid multipart/form-data");
				continue;
			}
			string value = part[eoh + 4 .. length-2];
			string[string] name_values;
			foreach(string name_part ; split(name_header[10 .. length], ";")) {
				string[] pair = split(trim(name_part), "=");
				string name = pair[0];
				string name_value = pair[1];
				name_values[name] = strip(name_value, "\""); //.decode("utf-8");
			}
			if(("name" in name_values) == null) {
//				logging.warning("multipart/form-data value missing name");
				continue;
			}
			string name = name_values["name"];
			if("filename" in name_values) {
				string ctype = "application/unknown";
				if(headers.has_key("Content-Type"))
					ctype = headers["Content-Type"];
				string[string] dict;
				dict["filename"] = name_values["filename"];
				dict["body"] = value;
				dict["content_type"] = ctype;
				if((name in this._request.files) == null)
					this._request.files[name] = [];
				this._request.files[name] ~= dict;
			} else {
				if((name in this._request.arguments) == null)
					this._request.arguments[name] = [];
				this._request.arguments[name] ~= value;
			}
		}
	}
}

class HTTPRequest {
	private string method;
	private string _uri;
	private string version_;
	private HTTPHeaders headers;
	private string body_;
	private string remote_ip;
	private string protocol;
	private string host;
	private string path;
	private string query;
	public string[string][][string] files;
	public string[][string] arguments;
	private HTTPConnection connection;
	private float _start_time;
	private float _finish_time;

	public string uri() { return this._uri; }

	public this(string method, string uri, string version_="HTTP/1.0", HTTPHeaders headers=null,
				 string body_=null, string remote_ip=null, string protocol=null, string host=null,
				 string[string][][string] files=null, HTTPConnection connection=null) {
		this.method = method;
		this._uri = uri;
		this.version_ = version_;
		this.headers = headers ? headers : new HTTPHeaders();
		this.body_ = body_ ? body_ : "";
		if(connection && connection.xheaders) {
			if(headers.has_key("X-Real-Ip"))
				this.remote_ip = headers["X-Real-Ip"];
			else
				this.remote_ip = remote_ip;
			if(headers.has_key("X-Scheme"))
				this.protocol = headers["X-Scheme"];
			else if(protocol)
				this.protocol = protocol;
			else
				this.protocol = "http";
		} else {
			this.remote_ip = remote_ip;
			this.protocol = protocol ? protocol : "http";
		}
		if(host)
			this.host = host;
		else if(headers.has_key("Host"))
			this.host = headers["Host"];
		else
			this.host = "127.0.0.1";
		if(files !is null)
			this.files = files;
		this.connection = connection;
		this._start_time = Clock.now.unix.seconds;
		this._finish_time = -1;

//		string[] split_url = urlparse.urlsplit(_uri);
//		string scheme = split_url[0];
//		string netloc = split_url[1];
//		string path = split_url[2];
		string query = tango.text.Util.contains(_uri, '?') ? split(_uri, "?")[1] : "";
//		string fragment = split_url[4];
//		this.path = path;
		this.query = query;
		string[][string] arguments = cgi.parse_qs(query);
		foreach(string name, string[] values ; arguments) {
			string[] clean_values;
			foreach(string value ; values)
				if(value.length > 0)
					clean_values ~= value;
			if(clean_values.length > 0)
				this.arguments[name] = clean_values;
		}
	}

	public bool supports_http_1_1() {
		//"""Returns true if this request supports HTTP/1.1 semantics"""
		return this.version_ == "HTTP/1.1";
	}

	public void write(string chunk) {
		//"""Writes the given chunk to the response stream."""
		this.connection.write(chunk);
	}

	public void finish() {
		//"""Finishes this HTTP request on the open connection."""
		this.connection.finish();
		this._finish_time = Clock.now.unix.seconds;
	}

	public string full_url() {
		//"""Reconstructs the full URL for this request."""
		return this.protocol ~ "://" ~ this.host ~ this._uri;
	}

	public float request_time() {
		//"""Returns the amount of time it took for this request to execute."""
		if(this._finish_time == -1) {
			return Clock.now.unix.seconds - this._start_time;
		} else {
			return this._finish_time - this._start_time;
		}
	}

	// FIXME: Make sure this is correct
	// FIXME: Does this need remote_ip twice?
	public string toString() {
		return "protocol=" ~ this.protocol ~ "\r\n" ~
				"host=" ~ this.protocol ~ "\r\n" ~
				"method=" ~ this.host ~ "\r\n" ~
				"uri=" ~ this._uri ~ "\r\n" ~
				"version=" ~ this.version_ ~ "\r\n" ~
				"remote_ip=" ~ this.remote_ip ~ "\r\n" ~
				"remote_ip=" ~ this.remote_ip ~ "\r\n" ~
				"body=" ~ this.body_ ~ "\r\n";
	}
}

class HTTPHeaders {
	//"""A dictionary that maintains Http-Header-Case for all keys."""
	private string[string] _data;

/*
	// FIXME: This does not work so we do it manually with has_key
	public char[]* opIn(string key) {
		return(key in _data);
	}
*/
	public bool has_key(string key) {
		return(key in _data) != null;
	}

	public string opIndex(string key) {
		return _data[this._normalize_name(key)];
	}

	public string opIndexAssign(string value, string key) {
		return _data[this._normalize_name(key)] = value;
	}

	public string _normalize_name(string name) {
		string[] retval;
		foreach(string w ; split(name, "-"))
			retval ~= capitalize(w);

		return join(retval, "-");
	}

	public static HTTPHeaders parse(string headers_string) {
		auto headers = new HTTPHeaders();
		foreach(string line ; split_lines(headers_string)) {
			if(line !is null) {
				string[] pair = split(line, ": ");
				string name = pair[0];
				string value = pair[1];
				headers[name] = value;
			}
		}
		return headers;
	}
}


